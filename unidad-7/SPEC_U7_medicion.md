# SPEC_U7_medicion — Comparación medida MongoDB vs PostgreSQL

**Estado:** ejecutada el 2026-11-07 (resultados en `evidencias/comparacion_medida.md`); repetida el mismo día sobre una base propia con 5 corridas por consulta (sección «Repetición del 07/11»).

## Objetivo

Completar el objetivo 10 con una comparación reproducible y honesta entre PostgreSQL y MongoDB sobre una muestra de **5.000 pedidos vigentes**. Esta ampliación no reemplaza la migración didáctica de 7 documentos ni altera sus evidencias; utiliza scripts, archivos de exportación y una base MongoDB separados.

## Alcance y seguridad

- PostgreSQL `foodstore` es solo lectura durante exportación y medición.
- La muestra se define de igual modo en ambos motores: los primeros 5.000 `pedido.id` vigentes, ordenados por id.
- Se conserva el precio histórico de `detalle_pedido.precio_unitario`; no se recalculan importes.
- El JSON resultante se genera localmente, no se versiona ni se comparte con una IA. No exporta contraseñas, celulares ni roles.
- MongoDB utiliza `foodstore_nosql_benchmark.pedidos_benchmark`, independiente de `foodstore_nosql.pedidos` (los 7 documentos de la entrega original).

## Cambios previstos

| Archivo | Propósito |
|---|---|
| `modelo/exportar_pedidos_benchmark.sql` | Exportar la muestra parametrizada desde PostgreSQL, con categoría embebida en cada línea. |
| `carga_benchmark_mongodb.js` | Crear la colección benchmark, cargar el JSON, crear el índice multikey de `lineas.producto_id` y emitir `explain("executionStats")`. |
| `consultas_benchmark_postgresql.sql` | Ejecutar `EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)` para la consulta por producto y la analítica de ventas por categoría sobre la misma muestra. |
| `evidencias/comparacion_medida.md` | Registrar versiones, tamaño de muestra, índices, salidas crudas, métricas y conclusión; no inventar tiempos. |
| `docs/informe/u7.md` | Justificar la elección tecnológica y declarar límites de la medición. |

## Consultas a medir

1. **Consulta c: pedidos que contienen un producto.**
   - MongoDB: `find({ "lineas.producto_id": productoObjetivo })` con `explain("executionStats")` y el índice multikey `lineas.producto_id`.
   - PostgreSQL: `pedido JOIN detalle_pedido`, limitado a la misma CTE de muestra y con `EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)`.
   - Se registra `nReturned`, documentos/filas examinados, claves/buffers examinados, plan ganador y tiempo informado por cada motor. Los tiempos no se comparan como benchmark absoluto: los planificadores y formatos de salida son distintos.

2. **Ventas por categoría.**
   - MongoDB agrupa `lineas.categoria_nombre` embebida en la muestra; no usa `$lookup` porque la variante medida representa una copia de lectura autocontenida.
   - PostgreSQL une `pedido`, `detalle_pedido`, `producto` y `categoria` sobre la misma muestra.
   - Se comparan categorías e importe total con redondeo a dos decimales. Si difieren, se detiene la conclusión hasta identificar la causa.

## Índices y decisiones

MongoDB crea explícitamente `{ "lineas.producto_id": 1 }`; MongoDB lo maneja como índice multikey por estar dentro de un arreglo. No se agrega un índice nuevo a PostgreSQL: se mide con los índices heredados ya existentes y se declara esa diferencia. La categoría se embebe solo en la colección benchmark para medir la lectura analítica sin `$lookup`; es una decisión de desnormalización de lectura, no una nueva fuente de verdad.

## Evidencia y criterios de aceptación

La ejecución queda lista solo si se guardan:

1. versiones de PostgreSQL, MongoDB y `mongosh`;
2. el conteo y los IDs límite de la muestra en PostgreSQL y MongoDB;
3. suma de `pedido.total` en PostgreSQL y de `total` en MongoDB, iguales a dos decimales;
4. la verificación de que cada `usuario_id` y `producto_id` del export existe en PostgreSQL;
5. salidas crudas de ambos `EXPLAIN` y ambas consultas de categoría;
6. una tabla de métricas con fecha, equipo, tamaño e índices;
7. una conclusión que no extrapole los resultados del equipo local a producción.

No se afirma ninguna métrica que no esté respaldada por una salida cruda guardada en `evidencias/`.
