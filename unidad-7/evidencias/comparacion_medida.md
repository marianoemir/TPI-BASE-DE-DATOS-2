# Comparacion medida - MongoDB vs PostgreSQL (objetivo 10)

**Fecha:** 2026-11-07. **Equipo:** PostgreSQL 17.11 local, MongoDB Server 9.0.4 local y mongosh 2.14.1.
**Muestra:** 5.000 pedidos vigentes, seleccionados por `pedido.id` ascendente en ambos motores.

## Verificacion de equivalencia

| Control | PostgreSQL | MongoDB | Resultado |
|---|---:|---:|---|
| Pedidos/documentos | 5.000 | 5.000 | Coincide |
| `SUM(total)` | 68.818.099,92 | 68.818.099,92 | Coincide |
| Usuarios inexistentes en la fuente | 0 | No verificado en esta medición (ver «Repetición del 07/11») | Solo PostgreSQL |
| Productos inexistentes en la fuente | 0 | No verificado en esta medición (ver «Repetición del 07/11») | Solo PostgreSQL |
| Ventas por categoria | 5 categorias | 5 categorias | Coinciden importe por importe |

Los importes por categoria coincidentes son: Bebidas 13.703.741,60; Empanadas 13.539.880,52; Hamburguesas 13.815.749,62; Pizzas 13.976.191,88; Postres 13.782.536,30.

## Consulta por producto

La consulta se ejecuto sobre el producto objetivo 1, elegido como el de mayor frecuencia en la muestra. MongoDB uso el indice multikey `lineas.producto_id_1`: devolvio 1 documento, examino 1 clave y 1 documento, con `executionTimeMillis: 0` en la ultima corrida. PostgreSQL ejecuto la misma seleccion logica con `EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)`; el nodo superior informo 1 fila, 141,212 ms, 5.524 bloques compartidos en cache y 8.558 leidos.

No se presenta esta diferencia como un benchmark absoluto: los planes no tienen la misma forma, PostgreSQL incluyo la CTE de muestra y hubo lectura de bloques, mientras que MongoDB uso el indice y una coleccion ya cargada. La evidencia sirve para demostrar los planes y el uso del indice, no para afirmar que un motor sea universalmente mas rapido.

Limites adicionales de esta corrida: fue una sola corrida, sin repeticiones; el `EXPLAIN` de PostgreSQL incluye elegir el producto mas frecuente (con un recorrido secuencial de 400.011 filas de `detalle_pedido`), mientras que en MongoDB ese producto se calculo antes y fuera de la medicion; y PostgreSQL leyo bloques de disco (8.558) frente a una coleccion ya cargada en MongoDB.

## Analitica por categoria

PostgreSQL resuelve la categoria con `JOIN` entre pedido, detalle, producto y categoria. En la coleccion benchmark se embebio `categoria_nombre` por linea, de modo que MongoDB la agrupa sin `$lookup`.

Para contrastar esa decision, se genero solo dentro de `foodstore_nosql_benchmark` la coleccion auxiliar `productos_benchmark`, con 10.001 productos distintos derivados de las lineas ya cargadas. La variante con `$lookup` contra esa coleccion devolvio exactamente los mismos cinco importes por categoria. Su `explain("executionStats")` recorrio 5.000 documentos de pedidos y el `$lookup` uso el indice `_id_` de la coleccion auxiliar (10.002 claves/documentos examinados); la corrida informo 540 ms. En esta corrida no se midio la variante embebida con `explain`, asi que no se cuantifica la diferencia entre ambas; si se demuestra la equivalencia funcional sobre la misma muestra. La comparacion de tiempos esta en la seccion «Repetición del 07/11».

`productos_benchmark` no es parte del modelo documental entregado originalmente: existe solo para esta comparacion aislada. La coleccion original sigue siendo `foodstore_nosql.pedidos`.

## Export de ejemplo

El exportador original `modelo/exportar_pedidos.sql` ahora recibe los parametros `ids` y `origen`. Para evitar datos con el nombre de un integrante, se lo ejecuto con `-v ids=1,2,3,6,7,8 -v origen=ejemplo_regenerado`; el resultado es `modelo/pedidos_export_ejemplo_regenerado.json`, que se versiona porque contiene solo datos inventados (se regenero el 07/11 en UTF-8). En cambio, `modelo/pedidos_benchmark.json` (la muestra grande) no se versiona.

## Evidencia cruda

- `obj10_mongo_benchmark_20261107.txt`
- `obj10_postgres_benchmark_20261107.txt`
- `obj10_verificacion_mongo_20261107.txt`
- `obj10_verificacion_postgres_20261107.txt`

Documentacion consultada: MongoDB `executionStats` y multikey indexes: https://www.mongodb.com/docs/manual/reference/method/cursor.explain/ y https://www.mongodb.com/docs/manual/core/indexes/index-types/index-multikey/.

## Repetición del 07/11 con base propia

**Que es:** una repeticion hecha por Mariano, con fecha y datos propios, para cubrir tres limites de la primera medicion: una sola corrida, variante embebida sin medir y verificacion de referencias solo en PostgreSQL. **No reemplaza** la medicion anterior; los numeros de ambas no se mezclan.

**Entorno:** base nueva `foodstore_u7_bench` (esquema, objetos, datos, vistas y `carga_masiva.sql` de `heredado/base_heredada/`; sin `indices.sql` ni `indices_semana3.sql`), PostgreSQL 17.10, MongoDB Server 9.0.4, mongosh 2.14.0. Conteos de carga: 6 / 20.006 / 50.016 / 200.006 / 400.013 (categoria / usuario / producto / pedido / detalle_pedido). `carga_masiva.sql` usa `random()` sin semilla, por eso los importes difieren de la medicion de Andrés (total de la muestra 68.802.975,31 contra 68.818.099,92).

**Equivalencia (misma muestra de 5.000 pedidos, primeros por id):**

| Control | PostgreSQL | MongoDB | Resultado |
|---|---:|---:|---|
| Pedidos/documentos | 5.000 | 5.000 | Coincide |
| `SUM(total)` | 68.802.975,31 | 68.802.975,31 | Coincide |
| Usuarios distintos (cantidad / suma de ids) | 4.996 / 12.482.506 | 4.996 / 12.482.506 | Coincide |
| Productos distintos (cantidad / suma de ids) | 10.001 / 175.129.775 | 10.001 / 175.129.775 | Coincide |
| Usuarios y productos inexistentes en PostgreSQL | 0 / 0 | - | Sin referencias huerfanas |

Ventas por categoria (iguales en PostgreSQL, MongoDB con categoria embebida y MongoDB con `$lookup`): Bebidas 13.726.345,52; Empanadas 13.986.172,80; Hamburguesas 13.691.566,43; Pizzas 13.667.204,73; Postres 13.731.685,83.

**Tiempos (ms, 5 corridas tras 1 de calentamiento, tiempo de reloj medido desde el cliente):**

| Consulta | Corridas | Mediana |
|---|---|---:|
| MongoDB, por producto (indice multikey) | 1, 1, 2, 1, 1 | 1 |
| MongoDB, categoria embebida | 12, 13, 12, 12, 12 | 12 |
| MongoDB, categoria con `$lookup` | 607, 508, 508, 509, 524 | 509 |
| PostgreSQL, por producto (producto ya elegido) | 45,2; 54,3; 66,0; 65,9; 58,6 | 58,6 |
| PostgreSQL, categoria con JOINs | 74,2; 74,7; 91,6; 89,4; 79,4 | 79,4 |

La corrida de calentamiento de PostgreSQL (59,6 y 75,8 ms) no se incluye en las medianas.

**Lectura y limites:**
- Los tiempos de MongoDB tienen resolucion de 1 ms y todos incluyen el viaje al servidor; los de PostgreSQL son los que informa `\timing` de `psql` (sin `EXPLAIN`). No son comparables 1 a 1 con `executionTimeMillis` ni con `EXPLAIN ANALYZE`.
- En esta muestra ningun producto aparece en mas de un pedido (los tres con mas pedidos tienen 1), de modo que la consulta por producto es una busqueda puntual que devuelve un solo pedido.
- No se capturo el plan de PostgreSQL en esta repeticion; no se afirma si uso o no un indice sobre `detalle_pedido.producto_id`.
- Es una sola maquina, una sola muestra y 5 corridas; no se extrapola a produccion.
- Lo que si respaldan los numeros: en MongoDB, resolver la categoria con `$lookup` fue unas 40 veces mas lento que tenerla embebida (509 contra 12 ms) y mas lento que los JOINs de PostgreSQL (79,4 ms); embeber la categoria elimina ese costo a cambio de duplicarla en cada linea (desnormalizacion de lectura).

**Evidencia cruda:** `obj10_carga_mongo_20261107.txt`, `obj10_medicion_repetida_mongo_20261107.txt`, `obj10_medicion_repetida_postgres_20261107.txt` y `obj10_referencias_postgres_20261107.txt`; la equivalencia de totales y categorias se obtuvo con `verificar_benchmark_postgresql.sql` y `verificar_benchmark_mongodb.js` sobre esta base. Scripts: `medicion_repetida_mongodb.js`, `medicion_repetida_postgresql.sql`, `verificar_referencias_postgresql.sql` y `correr_correcciones_obj10.ps1`.
