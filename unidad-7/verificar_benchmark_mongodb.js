// Verificacion posterior a la carga aislada del benchmark U7.
db = db.getSiblingDB('foodstore_nosql_benchmark');

const resumen = db.pedidos_benchmark.aggregate([
  { $group: { _id: null, documentos: { $sum: 1 }, total: { $sum: '$total' } } },
  { $project: { _id: 0, documentos: 1, total: 1 } }
]).toArray();

const categorias = db.pedidos_benchmark.aggregate([
  { $unwind: '$lineas' },
  { $group: { _id: '$lineas.categoria_nombre', ventas: { $sum: '$lineas.subtotal' } } },
  { $project: { _id: 0, categoria: '$_id', ventas: 1 } },
  { $sort: { categoria: 1 } }
]).toArray();

print('RESUMEN_MONGO');
printjson(resumen);
print('VENTAS_POR_CATEGORIA_MONGO');
printjson(categorias);
