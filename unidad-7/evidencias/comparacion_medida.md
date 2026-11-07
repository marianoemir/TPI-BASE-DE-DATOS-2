# Comparacion medida - MongoDB vs PostgreSQL (objetivo 10)

**Fecha:** 2026-11-07. **Equipo:** PostgreSQL 17.11 local, MongoDB Server 9.0.4 local y mongosh 2.14.1.
**Muestra:** 5.000 pedidos vigentes, seleccionados por `pedido.id` ascendente en ambos motores.

## Verificacion de equivalencia

| Control | PostgreSQL | MongoDB | Resultado |
|---|---:|---:|---|
| Pedidos/documentos | 5.000 | 5.000 | Coincide |
| `SUM(total)` | 68.818.099,92 | 68.818.099,92 | Coincide |
| Usuarios inexistentes en la fuente | 0 | Exportado desde la misma fuente | Sin diferencia detectada |
| Productos inexistentes en la fuente | 0 | Exportado desde la misma fuente | Sin diferencia detectada |
| Ventas por categoria | 5 categorias | 5 categorias | Coinciden importe por importe |

Los importes por categoria coincidentes son: Bebidas 13.703.741,60; Empanadas 13.539.880,52; Hamburguesas 13.815.749,62; Pizzas 13.976.191,88; Postres 13.782.536,30.

## Consulta por producto

La consulta se ejecuto sobre el producto objetivo 1, elegido como el de mayor frecuencia en la muestra. MongoDB uso el indice multikey `lineas.producto_id_1`: devolvio 1 documento, examino 1 clave y 1 documento, con `executionTimeMillis: 0` en la ultima corrida. PostgreSQL ejecuto la misma seleccion logica con `EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)`; el nodo superior informo 1 fila, 141,212 ms, 5.524 bloques compartidos en cache y 8.558 leidos.

No se presenta esta diferencia como un benchmark absoluto: los planes no tienen la misma forma, PostgreSQL incluyo la CTE de muestra y hubo lectura de bloques, mientras que MongoDB uso el indice y una coleccion ya cargada. La evidencia sirve para demostrar los planes y el uso del indice, no para afirmar que un motor sea universalmente mas rapido.

## Analitica por categoria

PostgreSQL resuelve la categoria con `JOIN` entre pedido, detalle, producto y categoria. En la coleccion benchmark se embebio `categoria_nombre` por linea, de modo que MongoDB la agrupa sin `$lookup`.

Para contrastar esa decision, se genero solo dentro de `foodstore_nosql_benchmark` la coleccion auxiliar `productos_benchmark`, con 10.001 productos distintos derivados de las lineas ya cargadas. La variante con `$lookup` contra esa coleccion devolvio exactamente los mismos cinco importes por categoria. Su `explain("executionStats")` recorrio 5.000 documentos de pedidos y el `$lookup` uso el indice `_id_` de la coleccion auxiliar (10.002 claves/documentos examinados); la corrida informo 540 ms. No se compara ese valor con el agregado embebido como un benchmark absoluto: el pipeline con `$lookup` hace un join adicional. Si demuestra el costo y la equivalencia funcional de ambas opciones sobre la misma muestra.

`productos_benchmark` no es parte del modelo documental entregado originalmente: existe solo para esta comparacion aislada. La coleccion original sigue siendo `foodstore_nosql.pedidos`.

## Export de ejemplo

El exportador original `modelo/exportar_pedidos.sql` ahora recibe los parametros `ids` y `origen`. Para evitar datos con el nombre de un integrante, se lo ejecuto con `-v ids=1,2,3,6,7,8 -v origen=ejemplo_regenerado`; el resultado local es `modelo/pedidos_export_ejemplo_regenerado.json`.

## Evidencia cruda

- `obj10_mongo_benchmark_20261107.txt`
- `obj10_postgres_benchmark_20261107.txt`
- `obj10_verificacion_mongo_20261107.txt`
- `obj10_verificacion_postgres_20261107.txt`

Documentacion consultada: MongoDB `executionStats` y multikey indexes: https://www.mongodb.com/docs/manual/reference/method/cursor.explain/ y https://www.mongodb.com/docs/manual/core/indexes/index-types/index-multikey/.
