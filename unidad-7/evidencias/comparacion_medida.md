# ComparaciÃ³n medida â€” MongoDB vs PostgreSQL (objetivo 10)

**Fecha:** 2026-11-07. **Equipo:** PostgreSQL 17.11 local, MongoDB Server 9.0 local y mongosh 2.14.1.
**Muestra:** 5.000 pedidos vigentes, seleccionados por `pedido.id` ascendente en ambos motores.

## VerificaciÃ³n de equivalencia

| Control | PostgreSQL | MongoDB | Resultado |
|---|---:|---:|---|
| Pedidos/documentos | 5.000 | 5.000 | Coincide |
| `SUM(total)` | 68.818.099,92 | 68.818.099,92 | Coincide |
| Usuarios inexistentes en la fuente | 0 | Exportado desde la misma fuente | Sin diferencia detectada |
| Productos inexistentes en la fuente | 0 | Exportado desde la misma fuente | Sin diferencia detectada |
| Ventas por categorÃ­a | 5 categorÃ­as | 5 categorÃ­as | Coinciden importe por importe |

Los importes por categorÃ­a coincidentes son: Bebidas 13.703.741,60; Empanadas 13.539.880,52; Hamburguesas 13.815.749,62; Pizzas 13.976.191,88; Postres 13.782.536,30.

## Consulta por producto

La consulta se ejecutÃ³ sobre el producto objetivo 1, elegido como el de mayor frecuencia en la muestra. MongoDB usÃ³ el Ã­ndice multikey `lineas.producto_id_1`: devolviÃ³ 1 documento, examinÃ³ 1 clave y 1 documento, con `executionTimeMillis: 10` en esa corrida. PostgreSQL ejecutÃ³ la misma selecciÃ³n lÃ³gica con `EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)`; el nodo superior informÃ³ 1 fila, 141,212 ms, 5.524 bloques compartidos en cachÃ© y 8.558 leÃ­dos.

No se presenta esta diferencia como un benchmark absoluto: los planes no tienen la misma forma, PostgreSQL incluyÃ³ la CTE de muestra y hubo lectura de bloques, mientras que MongoDB usÃ³ el Ã­ndice y una colecciÃ³n ya cargada. La evidencia sirve para demostrar los planes y el uso del Ã­ndice, no para afirmar que un motor sea universalmente mÃ¡s rÃ¡pido.

## AnalÃ­tica por categorÃ­a

PostgreSQL resuelve la categorÃ­a con `JOIN` entre pedido, detalle, producto y categorÃ­a. En la colecciÃ³n benchmark se embebiÃ³ `categoria_nombre` por lÃ­nea, de modo que MongoDB la agrupa sin `$lookup`. La segunda alternativa reduce lecturas para esta copia de consulta, a costa de duplicar un dato que solo PostgreSQL puede actualizar como fuente de verdad.

## Evidencia cruda

- `obj10_mongo_benchmark_20261107.txt`
- `obj10_postgres_benchmark_20261107.txt`
- `obj10_verificacion_mongo_20261107.txt`
- `obj10_verificacion_postgres_20261107.txt`

DocumentaciÃ³n consultada: MongoDB `executionStats` y multikey indexes: https://www.mongodb.com/docs/manual/reference/method/cursor.explain/ y https://www.mongodb.com/docs/manual/core/indexes/index-types/index-multikey/.
