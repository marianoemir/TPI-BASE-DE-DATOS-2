# Tanda 11 — unidad-8 (movil_opencode y movil_opencode_v2, sin original_opencode)

Herramienta: OpenCode (modo Plan, solo lectura)
Modelo: Crouton Alpha Free
Fecha y hora: 9/11/2026 00:05
Sesión: nueva
Archivos (12, 797 líneas):
- unidad-8/movil_opencode/cargar_catalogo.sql (29)
- unidad-8/movil_opencode/casos.sql (170)
- unidad-8/movil_opencode/schema_sqlite.sql (63)
- unidad-8/movil_opencode/semaforo.sql (68)
- unidad-8/movil_opencode_v2/cargar_catalogo.sql (22)
- unidad-8/movil_opencode_v2/casos_c2_c5_borradores.sql (55)
- unidad-8/movil_opencode_v2/casos_c2_c6_resolucion.sql (29)
- unidad-8/movil_opencode_v2/casos_c8_competencia_stock.sql (52)
- unidad-8/movil_opencode_v2/casos_f2_semaforo.sql (91)
- unidad-8/movil_opencode_v2/pruebas_sqlite.sql (51)
- unidad-8/movil_opencode_v2/schema_sqlite.sql (73)
- unidad-8/movil_opencode_v2/semaforo.sql (94)
Prompt: ver prompt_base.md, más la línea final: «Devolvé exactamente el formato indicado: un id H-nn y una severidad por hallazgo, sin resumen por archivo.»
Estado: Corrida completa
Total de hallazgos devueltos: 16 (2 crítica / 8 alta / 4 media / 2 baja)
Estado del repo: rama review-final, etiqueta pre-review (351ddb9)

---

H-01 [ALTA] unidad-8/movil_opencode_v2/schema_sqlite.sql:8,19,27,38,53 — Falta `STRICT` en las 5 tablas pese a que el encabezado lo promete; la prueba C7 de tipo inválido en columna `INTEGER` no puede rechazar texto.
H-02 [ALTA] unidad-8/movil_opencode_v2/schema_sqlite.sql:38-47 — Falta el `CHECK` que exige `motivo IS NOT NULL` en `CONFLICTO`/`RECHAZADO` (presente en unidad-8/movil_opencode/schema_sqlite.sql:40); admite estados incoherentes.
H-03 [CRÍTICA] unidad-8/movil_opencode_v2/casos_f2_semaforo.sql:78-85 — `BEGIN TRY` / `BEGIN CATCH` es sintaxis de T-SQL, inexistente en SQLite; F2-6 aborta con error de sintaxis.
H-04 [ALTA] unidad-8/movil_opencode_v2/casos_f2_semaforo.sql:73-74 — F2-6 inserta en `cola_sync` un `id_local` (`f2000006-...`) sin crear su `pedido_borrador` previo; con `foreign_keys = ON` falla por FK antes de probar el índice parcial.
H-05 [ALTA] unidad-8/movil_opencode_v2/casos_f2_semaforo.sql:34-35 — F2-2 inserta un ítem con `producto_id` 9999 sin insertarlo antes en `producto_cache`; con FK activa falla y nunca llega al semáforo para probar ausencia en `snapshot_servidor` (correcto en unidad-8/movil_opencode/casos.sql:41 con el producto 99).
H-06 [CRÍTICA] unidad-8/movil_opencode_v2/casos_c8_competencia_stock.sql:43-46 — El `SELECT` de verificación referencia `s1`/`s2` sin cláusula `FROM` y el archivo nunca ejecuta `semaforo.sql`; `changes()` tras los `INSERT` no puede valer 2 ni mostrar `SIMULADO_APROBADO`.
H-07 [ALTA] unidad-8/movil_opencode_v2/casos_f2_semaforo.sql:87-91 — El archivo no ejecuta `semaforo.sql` ni aserta estados/motivos esperados; solo vuelca `cola_sync` todavía en `PENDIENTE`, por lo que F2-1 a F2-5 quedan sin probar.
H-08 [ALTA] unidad-8/movil_opencode_v2/casos_c2_c6_resolucion.sql:8-9,25-29 — El reenvío `000c` no corrige `precio_centavos_visto` (a diferencia de unidad-8/movil_opencode/casos.sql:133-136), por lo que la nueva corrida vuelve a dar `CONFLICTO` y no `SIMULADO_APROBADO`; además no ejecuta el semáforo ni aserta el estado final.
H-09 [ALTA] unidad-8/movil_opencode_v2/casos_c2_c5_borradores.sql:12-19 — C2 se describe como conflicto tras cambiar precio en PostgreSQL y recargar, pero el script inserta precio igual al snapshot y no modifica `snapshot_servidor` ni ejecuta el semáforo; aislado produce `SIMULADO_APROBADO`, no `CONFLICTO`.
H-10 [ALTA] unidad-8/movil_opencode_v2/pruebas_sqlite.sql:32-44 — C7-1 y C7-2 insertan ítems con `id_local` inexistente (`0002`/`0003` sin `pedido_borrador`), por lo que el rechazo puede provenir de la FK de `id_local` y no aislar `CHECK(cantidad > 0)` ni la FK de producto; tampoco hay aserción que identifique la causa.
H-11 [MEDIA] unidad-8/movil_opencode_v2/pruebas_sqlite.sql:39; unidad-8/movil_opencode_v2/cargar_catalogo.sql:1; unidad-8/movil_opencode_v2/semaforo.sql:1; unidad-8/movil_opencode_v2/casos_c2_c5_borradores.sql:1; unidad-8/movil_opencode_v2/casos_c2_c6_resolucion.sql:1; unidad-8/movil_opencode_v2/casos_c8_competencia_stock.sql:1; unidad-8/movil_opencode_v2/casos_f2_semaforo.sql:1 — `PRAGMA foreign_keys = ON` aparece a mitad de `pruebas_sqlite.sql` y falta al inicio en el resto de v2; en una sesión nueva el primer bloque corre con FK en `OFF` por defecto y el enforcement no queda garantizado.
H-12 [MEDIA] unidad-8/movil_opencode_v2/semaforo.sql:10-59 — `item_evaluacion` no filtra `estado = 'PENDIENTE'` y evalúa todo el historial de `cola_sync`, contra el contrato anunciado; solo el `UPDATE` posterior filtra.
H-13 [MEDIA] unidad-8/movil_opencode_v2/semaforo.sql:25-55,74-78 — El `CASE` por ítem emite una sola causa (la de mayor prioridad) y pierde causas rojas adicionales del mismo ítem, y el `GROUP_CONCAT` sin `ORDER BY` deja el orden del motivo indeterminado; en v1 cada causa es una fila ordenada por `orden, texto`.
H-14 [MEDIA] unidad-8/movil_opencode_v2/semaforo.sql:48-53 — Los fragmentos de motivo omiten el nombre del producto (`'dado de baja'`, `'no disponible'`, `'pedido ..., stock ...'`) respecto al formato de v1 (`'Fugazzeta: dado de baja'` etc. en unidad-8/movil_opencode/casos.sql:105-115), rompiendo la comparación exacta de motivos.
H-15 [BAJA] unidad-8/movil_opencode_v2/schema_sqlite.sql:65-73 — `v_catalogo_disponible` agrega la columna `eliminado` que la vista de v1 no expone, alterando el contrato de 5 columnas sin justificación.
H-16 [BAJA] unidad-8/movil_opencode/schema_sqlite.sql:19,38; unidad-8/movil_opencode_v2/semaforo.sql:88 — Formatos de fecha inconsistentes entre columnas de tiempo (`%Y-%m-%dT%H:%M:%SZ` en `pedido_borrador` frente a `%Y-%m-%d %H:%M:%S` en `cola_sync`/`evaluada_en`), que dificultan comparar y auditar `creado`/`creada`/`evaluada`.