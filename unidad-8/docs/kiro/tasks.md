# Tareas

- [x] **T1** `postgresql/10_snapshot_catalogo.sql`: vista `v_snapshot_movil` (centavos, lápida, fecha) y exportar a CSV (`11_exportar_snapshot.sql`).
- [x] **T2** `movil/schema_sqlite.sql`: cuatro tablas STRICT, `PRAGMA foreign_keys = ON`, índice parcial, vista del catálogo, tabla de paso `snapshot_servidor`.
- [x] **T3** `movil/cargar_catalogo.sql`: cargar `producto_cache` desde `snapshot_servidor` con UPSERT.
- [x] **T4** `movil/pruebas_sqlite.sql`: borrador con COMMIT, operación con ROLLBACK, C1 (catálogo sin servidor), C7 (cantidad 0 y producto inexistente).
- [x] **T5** `movil/semaforo.sql`: rojo / amarillo / verde sobre las solicitudes PENDIENTE (REQ-01, REQ-02, REQ-03).
- [x] **T6** Casos C2 a C6: borradores, cambios en el servidor (`postgresql/casos/`), instantánea nueva, semáforo, resolución de C2, reenvío de C6 (REQ-04).
- [x] **T7** `postgresql/verificar_no_cambio.sql`: pedidos y stock sin cambios antes y después.
- [x] **T8** Informe (mapa, plan de mantenimiento, code review), bitácora de IA, DUIA y README.

> Marcadas como hechas: se escribieron **después** del código, no antes (el enunciado pide lo contrario; está declarado en la DUIA y la bitácora).
