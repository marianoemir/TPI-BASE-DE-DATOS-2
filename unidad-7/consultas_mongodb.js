// ============================================================================
// consultas_mongodb.js - TP Unidad 7 - Food Store (pedidos y detalle -> MongoDB)
//
// Requisito previo: generar modelo/pedidos_export.json desde PostgreSQL
//   psql -U postgres -d foodstore -t -A -f modelo/exportar_pedidos.sql -o modelo/pedidos_export.json
//
// Ejecucion (desde la raiz del repo):
//   mongosh --file consultas_mongodb.js
//
// El script es repetible: borra SOLO la coleccion 'pedidos' y la vuelve a crear.
// ============================================================================
const fs = require('fs');

// 'use' no funciona dentro de un .js: se usa getSiblingDB
db = db.getSiblingDB('foodstore_nosql');

function mostrar(titulo, docs) {
  console.log('\n--- ' + titulo + ' ---');
  printjson(docs);
}

// ----------------------------------------------------------------------------
// 1) CREACION DE LA COLECCION (con validador de esquema: regla de integridad)
// ----------------------------------------------------------------------------
db.pedidos.drop();
db.createCollection('pedidos', {
  validator: { $jsonSchema: {
    bsonType: 'object',
    required: ['_id', 'fecha', 'estado', 'forma_pago', 'total', 'cliente', 'lineas', 'origen'],
    properties: {
      fecha:      { bsonType: 'date' },
      estado:     { enum: ['PENDIENTE', 'CONFIRMADO', 'TERMINADO', 'CANCELADO'] },
      forma_pago: { enum: ['TARJETA', 'TRANSFERENCIA', 'EFECTIVO'] },
      total:      { bsonType: 'decimal' },
      cliente: {
        bsonType: 'object',
        required: ['usuario_id', 'nombre', 'apellido', 'mail']
      },
      lineas: {
        bsonType: 'array', minItems: 1,
        items: {
          bsonType: 'object',
          required: ['detalle_id', 'producto_id', 'nombre', 'cantidad', 'precio_unitario', 'subtotal'],
          properties: {
            cantidad:        { bsonType: 'int', minimum: 1 },
            precio_unitario: { bsonType: 'decimal' },
            subtotal:        { bsonType: 'decimal' }
          }
        }
      }
    }
  } }
});

// ----------------------------------------------------------------------------
// 2) MIGRACION con insertMany() (JSON generado desde PostgreSQL, sin tipear datos)
// ----------------------------------------------------------------------------
const crudos = JSON.parse(fs.readFileSync('modelo/pedidos_export.json', 'utf8'));

const docs = crudos.map(d => ({
  ...d,
  fecha: new Date(d.fecha),                 // 'YYYY-MM-DD' -> medianoche UTC
  total: NumberDecimal(d.total),            // NUMERIC(12,2) -> Decimal128
  lineas: d.lineas.map(l => ({
    ...l,
    cantidad: NumberInt(l.cantidad),        // INTEGER -> int32
    precio_unitario: NumberDecimal(l.precio_unitario),   // precio HISTORICO
    subtotal: NumberDecimal(l.subtotal)
  }))
}));

const res = db.pedidos.insertMany(docs);
console.log('Insertados: ' + Object.keys(res.insertedIds).length);
console.log('countDocuments: ' + db.pedidos.countDocuments());

// ----------------------------------------------------------------------------
// 3) VERIFICACION DE INTEGRIDAD POSTERIOR A LA MIGRACION (las tres deben dar [])
// ----------------------------------------------------------------------------
// Regla 1: total = suma de subtotales
mostrar('Regla 1 - total distinto de la suma de subtotales (esperado: [])',
  db.pedidos.aggregate([
    { $addFields: { suma: { $sum: '$lineas.subtotal' } } },
    { $match: { $expr: { $ne: ['$suma', '$total'] } } },
    { $project: { total: 1, suma: 1 } }
  ]).toArray());

// Regla 1b: cada subtotal = cantidad x precio_unitario
mostrar('Regla 1b - lineas con subtotal distinto de cantidad x precio_unitario (esperado: [])',
  db.pedidos.aggregate([
    { $unwind: '$lineas' },
    { $match: { $expr: { $ne: ['$lineas.subtotal', { $multiply: ['$lineas.cantidad', '$lineas.precio_unitario'] }] } } },
    { $project: { 'lineas.detalle_id': 1, 'lineas.subtotal': 1 } }
  ]).toArray());

// Regla 2: lineas con cantidad no positiva
mostrar('Regla 2 - lineas con cantidad <= 0 (esperado: [])',
  db.pedidos.find({ 'lineas.cantidad': { $lte: 0 } }).toArray());

// ----------------------------------------------------------------------------
// 4) CONSULTAS (consigna 4)
// ----------------------------------------------------------------------------
// a) Todos los pedidos: solo _id y estado
mostrar('a) Todos los pedidos (_id y estado)',
  db.pedidos.find({}, { estado: 1 }).sort({ _id: 1 }).toArray());

// b) Por estado existente en los datos migrados
mostrar('b) Pedidos en estado PENDIENTE',
  db.pedidos.find({ estado: 'PENDIENTE' }).sort({ _id: 1 }).toArray());
console.log('b) ids: ' + JSON.stringify(
  db.pedidos.find({ estado: 'PENDIENTE' }, { _id: 1 }).sort({ _id: 1 }).toArray().map(d => d._id)));

// c) Por producto dentro del arreglo de lineas (producto_id 1 = Muzzarella)
mostrar('c) Pedidos que contienen el producto 1 (Muzzarella)',
  db.pedidos.find({ 'lineas.producto_id': 1 }).sort({ _id: 1 }).toArray());
console.log('c) ids: ' + JSON.stringify(
  db.pedidos.find({ 'lineas.producto_id': 1 }, { _id: 1 }).sort({ _id: 1 }).toArray().map(d => d._id)));

// c) variante con $elemMatch: varias condiciones sobre la MISMA linea
mostrar('c) variante: producto 1 con cantidad >= 2',
  db.pedidos.find({ lineas: { $elemMatch: { producto_id: 1, cantidad: { $gte: 2 } } } }).toArray());

// d) Total mayor a un umbral.
//    UMBRAL = 10000.00 (queda por encima del promedio de los 7 totales
//    migrados (9200), asi que separa los pedidos "grandes" de los chicos).
mostrar('d) Pedidos con total > 10000.00',
  db.pedidos.find({ total: { $gt: NumberDecimal('10000.00') } }).sort({ _id: 1 }).toArray());
