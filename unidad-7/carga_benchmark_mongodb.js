// Carga aislada de la muestra U7. Requiere modelo/pedidos_benchmark.json local.
const fs = require('fs');
db = db.getSiblingDB('foodstore_nosql_benchmark');
db.pedidos_benchmark.drop();

const crudos = JSON.parse(fs.readFileSync('modelo/pedidos_benchmark.json', 'utf8'));
const docs = crudos.map(d => ({
  ...d,
  fecha: new Date(d.fecha),
  total: NumberDecimal(d.total),
  lineas: d.lineas.map(l => ({
    ...l,
    cantidad: NumberInt(l.cantidad),
    precio_unitario: NumberDecimal(l.precio_unitario),
    subtotal: NumberDecimal(l.subtotal)
  }))
}));

const resultadoInsert = db.pedidos_benchmark.insertMany(docs);
print('Insertados: ' + Object.keys(resultadoInsert.insertedIds).length);
print('Documentos: ' + db.pedidos_benchmark.countDocuments());
printjson(db.pedidos_benchmark.createIndex({ 'lineas.producto_id': 1 }));

const productoObjetivo = db.pedidos_benchmark.aggregate([
  { $unwind: '$lineas' },
  { $group: { _id: '$lineas.producto_id', pedidos: { $addToSet: '$_id' } } },
  { $project: { cantidad: { $size: '$pedidos' } } },
  { $sort: { cantidad: -1, _id: 1 } }, { $limit: 1 }
]).toArray()[0]._id;

print('Producto objetivo: ' + productoObjetivo);
printjson(db.pedidos_benchmark.find({ 'lineas.producto_id': productoObjetivo })
  .explain('executionStats'));
printjson(db.pedidos_benchmark.aggregate([
  { $unwind: '$lineas' },
  { $group: { _id: '$lineas.categoria_nombre', ventas: { $sum: '$lineas.subtotal' } } },
  { $sort: { _id: 1 } }
]).toArray());
