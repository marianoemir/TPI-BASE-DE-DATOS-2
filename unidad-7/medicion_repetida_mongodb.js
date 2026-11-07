// Medicion repetida U7 (objetivo 10). Solo lectura sobre foodstore_nosql_benchmark.
// Uso (desde unidad-7): mongosh <uri> --quiet --file medicion_repetida_mongodb.js
// Los tiempos son de reloj (Date.now) alrededor de la consulta completa, con resolucion de 1 ms;
// incluyen el viaje de ida y vuelta al servidor. No son comparables 1 a 1 con EXPLAIN ANALYZE.
db = db.getSiblingDB('foodstore_nosql_benchmark');
const REP = 5;
const colP = db.pedidos_benchmark;

print('DOCUMENTOS: ' + colP.countDocuments());
print('PRODUCTOS_AUX: ' + db.productos_benchmark.countDocuments());

function medir(nombre, fn) {
  fn(); // calentamiento: no se registra
  const t = [];
  for (let i = 0; i < REP; i++) {
    const t0 = Date.now();
    fn();
    t.push(Date.now() - t0);
  }
  const ord = t.slice().sort((a, b) => a - b);
  print(nombre + ' | ms por corrida: ' + t.join(', ') + ' | mediana: ' + ord[Math.floor(REP / 2)]);
}

// Los tres productos con mas pedidos dentro de la muestra (para saber que tan selectiva es la consulta).
const top = colP.aggregate([
  { $unwind: '$lineas' },
  { $group: { _id: '$lineas.producto_id', pedidos: { $addToSet: '$_id' } } },
  { $project: { pedidos: { $size: '$pedidos' } } },
  { $sort: { pedidos: -1, _id: 1 } },
  { $limit: 3 }
]).toArray();
print('TOP3_PRODUCTOS_POR_PEDIDOS');
printjson(top);
const productoObjetivo = top[0]._id;
print('PRODUCTO_OBJETIVO: ' + productoObjetivo);

const pipelineEmbebida = [
  { $unwind: '$lineas' },
  { $group: { _id: '$lineas.categoria_nombre', ventas: { $sum: '$lineas.subtotal' } } },
  { $sort: { _id: 1 } }
];
const pipelineLookup = [
  { $unwind: '$lineas' },
  { $lookup: { from: 'productos_benchmark', localField: 'lineas.producto_id', foreignField: '_id', as: 'producto' } },
  { $unwind: '$producto' },
  { $group: { _id: '$producto.categoria_nombre', ventas: { $sum: '$lineas.subtotal' } } },
  { $sort: { _id: 1 } }
];

print('MEDICION_REPETIDA (' + REP + ' corridas tras 1 de calentamiento)');
medir('POR_PRODUCTO_indice_multikey', () => colP.find({ 'lineas.producto_id': productoObjetivo }).toArray());
medir('CATEGORIA_embebida', () => colP.aggregate(pipelineEmbebida).toArray());
medir('CATEGORIA_lookup', () => colP.aggregate(pipelineLookup).toArray());

print('EXPLAIN_CATEGORIA_EMBEBIDA');
printjson(colP.explain('executionStats').aggregate(pipelineEmbebida));

// Verificacion de referencias del lado MongoDB: se compara con verificar_referencias_postgresql.sql.
const u = colP.distinct('cliente.usuario_id');
const p = colP.distinct('lineas.producto_id');
print('MONGO_USUARIOS_DISTINTOS: ' + u.length + ' | suma_ids: ' + u.reduce((a, b) => a + Number(b), 0));
print('MONGO_PRODUCTOS_DISTINTOS: ' + p.length + ' | suma_ids: ' + p.reduce((a, b) => a + Number(b), 0));
