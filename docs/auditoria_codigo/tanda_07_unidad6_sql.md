# Tanda 07 — unidad-6 (mantenimiento, chequeo de salud, rol de respaldo e integridad)

Herramienta: OpenCode (modo Plan, solo lectura)
Modelo: Croutou Alpha Free
Fecha y hora: 8/11/2026, 23:34
Sesión: nueva
Archivos (4, 355 líneas):
- unidad-6/maintenance.sql (183)
- unidad-6/health_check.sql (91)
- unidad-6/crear_rol_respaldo.sql (42)
- unidad-6/validar_integridad.sql (39)
Prompt: ver prompt_base.md, más la línea final: «Devolvé exactamente el formato indicado: un id H-nn y una severidad por hallazgo, sin resumen por archivo.»
Estado: Corrida Completa.
Total de hallazgos devueltos: 11 (2 Alta  / 7  Media / 2 Baja)
Estado del repo: rama review-final, etiqueta pre-review (351ddb9)

---

H-01 [ALTA] unidad-6/crear_rol_respaldo.sql:10-17 — `operador_respaldo` se crea como `LOGIN` sin contraseña ni `ALTER ROLE` documentado; `pgpass.conf` solo aporta la clave del cliente, sin hash en `pg_authid` la autenticación SCRAM no puede verificarse y el flujo de respaldo queda roto.
H-02 [ALTA] unidad-6/crear_rol_respaldo.sql:20-22 — `GRANT SELECT ON ALL TABLES` otorga lectura completa de `usuario` (contraseña hasheada, mail, celular) sin máscara ni RLS; el rol supera el mínimo privilegio para operar y permite exfiltrar datos personales.
H-03 [MEDIA] unidad-6/crear_rol_respaldo.sql:21,26-29 — El `GRANT` es una foto del momento y `ALTER DEFAULT PRIVILEGES` carece de `FOR ROLE`; objetos futuros creados por otro dueño no quedan cubiertos y el respaldo puede ser incompleto.
H-04 [MEDIA] unidad-6/maintenance.sql:49,86 — `\connect foodstore` y `\connect foodstore_restore_test` sin verificación `current_database()` antes de `FASE 0` y de las fases de escritura; no se cumple el patrón de la Regla 8 de verificar destino antes de actuar.
H-05 [MEDIA] unidad-6/maintenance.sql:48,70-76 — La decisión prioriza `VACUUM recomendado` sobre `ANALYZE recomendado` cuando ambos umbrales se superan y descarta `reloptions` por tabla; el resultado puede ocultar un `ANALYZE` necesario.
H-06 [MEDIA] unidad-6/maintenance.sql:118,121,161 — `FASE 2` hace `UPDATE producto SET precio=precio` sobre todas las filas sin lote, conteo ni límite, y depende solo de `pg_sleep(2)` para reflejar `n_dead_tup`; la estadística puede ser anterior o el autovacuum puede intervenir durante el ensayo.
H-07 [BAJA] unidad-6/maintenance.sql:1-183 — No deja registro fechado de operación y resultado `OK`/`ERROR` (Regla 16); depende por completo del `-o` de `psql` invocado en el encabezado.
H-08 [MEDIA] unidad-6/health_check.sql:16,91 — `BEGIN READ ONLY` sin `\set ON_ERROR_STOP on`; un error en un control deja continuar, hace `COMMIT` y puede entregar salida parcial sin señal de falla (Regla 16).
H-09 [BAJA] unidad-6/health_check.sql:3,66-71 — `CONTROL 4` expone `left(query,120)`, que puede contener literales con datos personales, y contradice el encabezado “sin datos personales”.
H-10 [MEDIA] unidad-6/validar_integridad.sql:1-5 — Indica ejecución solo sobre `foodstore_restore_test` pero no impone `current_database()`; puede correrse sobre `foodstore` y producir un cero no comparable tras restauración.
H-11 [MEDIA] unidad-6/validar_integridad.sql:7-39 — Huérfanos e inválidos se cuentan sin `eliminado=FALSE` en `JOIN`; filas con borrado lógico heredadas de la base pueden contar como inválidas y no se verifica conteo previo/posterior al respaldo (condición de éxito de restauración).
