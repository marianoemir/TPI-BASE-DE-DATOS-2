# Tanda 08 — unidad-7 (consultas, exportación, correcciones y pruebas)

Herramienta: OpenCode (modo Plan, solo lectura)
Modelo: Croutou Alpha Free
Fecha y hora: 8/11/2026, 23:46
Sesión: nueva
Archivos (6, 346 líneas):
- unidad-7/consultas_mongodb.js (126)
- unidad-7/consultas_postgresql.sql (29)
- unidad-7/correr_correcciones_obj10.ps1 (80)
- unidad-7/modelo/exportar_pedidos.sql (49)
- unidad-7/modelo/pedidos_de_prueba.sql (5)
- unidad-7/tests/medicion.Tests.ps1 (57)
Prompt: ver prompt_base.md, más la línea final: «Devolvé exactamente el formato indicado: un id H-nn y una severidad por hallazgo, sin resumen por archivo.»
Estado: Corrida Completa
Total de hallazgos devueltos: 11 (2 Alta  / 7  Media / 2 Baja)
Estado del repo: rama review-final, etiqueta pre-review (351ddb9)

---

H-01 [MEDIA] unidad-7/consultas_mongodb.js:5-8,58 — La lectura `modelo/pedidos_export.json` es relativa al cwd mientras el encabezado ordena ejecutar desde la raíz del repo con el script en `unidad-7/`; `mongosh --file consultas_mongodb.js` y la ruta del JSON no coinciden con `unidad-7/modelo/`.
H-02 [MEDIA] unidad-7/consultas_mongodb.js:26-53,60-70 — El validador `$jsonSchema` solo tipa `fecha`, `estado`, `forma_pago`, `total`, `cantidad`, `precio_unitario`, `subtotal`; `cliente.usuario_id/nombre/apellido/mail` y `lineas.detalle_id/producto_id/nombre` quedan sin `bsonType` y `_id`, `usuario_id`, `producto_id`, `detalle_id` no se convierten con `NumberInt` (Regla 11).
H-03 [BAJA] unidad-7/consultas_mongodb.js:25,72 — `db.pedidos.drop()` e `insertMany()` incondicionales sin verificar nombre de base/colección ni manejar duplicados o lote parcial `ordered`; un fallo de validador deja la migración incompleta sin rollback.
H-04 [MEDIA] unidad-7/modelo/exportar_pedidos.sql:40-47 — `JOIN producto pr` y `JOIN usuario u` sin `eliminado = FALSE` (Regla 6: en cada tabla del `JOIN`); exporta cliente/producto con borrado lógico y falsea el subconjunto vigente.
H-05 [MEDIA] unidad-7/modelo/exportar_pedidos.sql:1-49, unidad-7/consultas_postgresql.sql:1-29, unidad-7/modelo/pedidos_de_prueba.sql:1-5 — Ninguno define `\set ON_ERROR_STOP on`; un error SQL en `psql -f` puede no cambiar el código de salida y `correr_correcciones_obj10.ps1` lo da por éxito (Regla 16).
H-06 [ALTA] unidad-7/modelo/pedidos_de_prueba.sql:4-5 — Dos `CALL sp_crear_pedido(...)` sin guarda de conteo, transacción ni idempotencia; una segunda ejecución crea pedidos `9` y `10` y rompe los `id IN (1,2,3,5,6,7,8)` de comparación (Regla 12: una sola vez sobre base recién armada).
H-07 [BAJA] unidad-7/consultas_postgresql.sql:15,28 — `id IN (1,2,3,5,6,7,8)` hardcodeado sin parámetro; deriva si cambia el subconjunto migrado o se re-ejecutan pedidos de prueba (Regla 13: comparación honesta).
H-08 [ALTA] unidad-7/correr_correcciones_obj10.ps1:3,32,43-44,52-53,68 — Requiere `$env:PGPASSWORD` definido y llama a `psql` sin `-w` ni `-X`; `PGPASSWORD` queda en el entorno/historial y `psql` puede esperar una clave en vez de fallar (Reglas 9 y 14).
H-09 [MEDIA] unidad-7/correr_correcciones_obj10.ps1:19-20,29,38 — Resuelve la raíz con `git rev-parse --show-toplevel` y luego depende de `Get-Location`; si `git` no está en `PATH` o hay un worktree distinto, `modelo/` y `evidencias/` quedan erróneos, en vez de usar `$PSScriptRoot`; asume además `mongosh` en `PATH`.
H-10 [MEDIA] unidad-7/correr_correcciones_obj10.ps1:23-27,45-48 — `Ejecutar` mezcla `2>&1` en stdout y solo decide por `LASTEXITCODE`; la salida de error contamina las evidencias y el chequeo de nombres reales (`Chirino|Fabre|Quiroga`) solo advierte y no aborta si el JSON de ejemplo trae datos sensibles.
H-11 [MEDIA] unidad-7/tests/medicion.Tests.ps1:13-56 — Los tests solo hacen `Should Match` sobre tokens literales (`:limite`, `'benchmark'`, `EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)`) sin ejecutar consultas ni verificar resultados, usan sintaxis Pester 3 (`Should Be/Should Match`, incompatible con Pester 5 `Should -Be`) y `Should Not Match 'contrasena'` choca con el comentario `exportar_pedidos.sql:11` en vez de validar columnas.