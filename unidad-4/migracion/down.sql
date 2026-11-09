-- =============================================================================
-- unidad-4/migracion/down.sql
-- Reversión de up.sql: elimina la vista y las dos tablas descompuestas.
-- control_lote_almacen, lote, deposito y usuario NO se tocan.
--
-- Atención: descarta los datos cargados en responsable_deposito y control_lote
-- DESPUÉS de aplicar el up. Como el up conserva la tabla original, no se
-- pierde el estado previo, pero sí lo escrito solo en las tablas nuevas.
-- Si se necesitara conservarlo, respaldar esas tablas antes de revertir.
-- =============================================================================
BEGIN;

DROP VIEW  IF EXISTS v_control_lote_almacen;
DROP TABLE IF EXISTS control_lote;            -- primero: tiene FK a responsable_deposito
DROP TABLE IF EXISTS responsable_deposito;

COMMIT;
