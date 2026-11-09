-- =============================================================================
-- unidad-4/migracion/verificar_migracion.sql
-- Consultas de solo lectura para comprobar el estado (úsese después de up y
-- después de down). Para las capturas, ejecutar cada consulta por separado.
-- =============================================================================

-- V1. ¿Qué objetos de la migración existen? (tras up: 3 filas; tras down: 0)
SELECT c.relname AS objeto, c.relkind AS tipo   -- r = tabla, v = vista
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname IN ('responsable_deposito', 'control_lote', 'v_control_lote_almacen')
ORDER BY c.relname;

-- V2. Pérdida de datos (solo tras up). Debe devolver 0 filas.
SELECT lote_id, deposito_id, responsable_control_id FROM control_lote_almacen
EXCEPT
SELECT lote_id, deposito_id, responsable_control_id FROM v_control_lote_almacen;

-- V3. Filas espurias (solo tras up). Debe devolver 0 filas.
SELECT lote_id, deposito_id, responsable_control_id FROM v_control_lote_almacen
EXCEPT
SELECT lote_id, deposito_id, responsable_control_id FROM control_lote_almacen;

-- V4. Conteos (solo tras up). Esperado con la instancia del enunciado:
--     original 3, vista 3, responsable_deposito 2, control_lote 3.
SELECT (SELECT COUNT(*) FROM control_lote_almacen)   AS original,
       (SELECT COUNT(*) FROM v_control_lote_almacen) AS vista,
       (SELECT COUNT(*) FROM responsable_deposito)   AS responsable_deposito,
       (SELECT COUNT(*) FROM control_lote)           AS control_lote;

-- V5. La tabla original sigue intacta (siempre). Esperado: 3 filas.
SELECT * FROM control_lote_almacen ORDER BY lote_id, deposito_id;
