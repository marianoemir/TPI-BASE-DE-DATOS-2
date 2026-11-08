-- =============================================================================
-- unidad-4/migracion/up.sql
-- Migración de la U4: descomposición sin pérdida de control_lote_almacen a FNBC.
--
--   Dependencia violatoria: ResponsableControlID -> DepositoID   (R -> D)
--   S1 = {R, D}  -> responsable_deposito
--   S2 = {L, R}  -> control_lote
--
-- Patrón expandir - migrar - verificar - contraer: se crean las tablas nuevas,
-- se copian los datos SIN tocar control_lote_almacen y se verifica. La tabla
-- original se conserva (el paso "contraer" queda fuera de esta migración).
--
-- Transaccional: si cualquier paso o verificación falla, no queda nada a medias.
-- Precondición: haber ejecutado setup_previo.sql (existe control_lote_almacen).
-- Reversión: down.sql.
-- =============================================================================
BEGIN;

-- 0. Precondiciones: la regla de negocio R -> D debe cumplirse en los datos.
--    Si no se cumple, se resuelve con el negocio; nunca se fuerza el script.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM control_lote_almacen
        GROUP BY responsable_control_id
        HAVING COUNT(DISTINCT deposito_id) > 1
    ) THEN
        RAISE EXCEPTION 'Precondición violada: hay responsables asignados a más de un depósito (R -> D no se cumple).';
    END IF;
END $$;

-- 1. EXPANDIR: tablas nuevas (sin IF NOT EXISTS: si ya existen, es señal de que
--    el up ya se aplicó y debe fallar en lugar de quedar a medias)
CREATE TABLE responsable_deposito (
    responsable_control_id  BIGINT PRIMARY KEY REFERENCES usuario(id),
    deposito_id             BIGINT NOT NULL REFERENCES deposito(id)
);

CREATE TABLE control_lote (
    lote_id                 BIGINT NOT NULL REFERENCES lote(id),
    responsable_control_id  BIGINT NOT NULL REFERENCES responsable_deposito(responsable_control_id),
    PRIMARY KEY (lote_id, responsable_control_id)
);

-- 2. MIGRAR: copia de datos (la original no se modifica ni se borra)
INSERT INTO responsable_deposito (responsable_control_id, deposito_id)
SELECT DISTINCT responsable_control_id, deposito_id
FROM control_lote_almacen;

INSERT INTO control_lote (lote_id, responsable_control_id)
SELECT DISTINCT lote_id, responsable_control_id
FROM control_lote_almacen;

-- 3. Vista de compatibilidad: reconstruye la relación original
CREATE VIEW v_control_lote_almacen AS
SELECT lote_id, deposito_id, responsable_control_id
FROM control_lote
NATURAL JOIN responsable_deposito;

-- 4. VERIFICAR dentro de la transacción, en los dos sentidos más el conteo.
--    Si algo no coincide, la excepción hace que NO se confirme nada.
DO $$
DECLARE
    perdidas  INT;
    espurias  INT;
    n_antes   INT;
    n_despues INT;
BEGIN
    SELECT COUNT(*) INTO perdidas FROM (
        SELECT lote_id, deposito_id, responsable_control_id FROM control_lote_almacen
        EXCEPT
        SELECT lote_id, deposito_id, responsable_control_id FROM v_control_lote_almacen
    ) x;

    SELECT COUNT(*) INTO espurias FROM (
        SELECT lote_id, deposito_id, responsable_control_id FROM v_control_lote_almacen
        EXCEPT
        SELECT lote_id, deposito_id, responsable_control_id FROM control_lote_almacen
    ) x;

    SELECT COUNT(*) INTO n_antes   FROM control_lote_almacen;
    SELECT COUNT(*) INTO n_despues FROM v_control_lote_almacen;

    IF perdidas <> 0 OR espurias <> 0 OR n_antes <> n_despues THEN
        RAISE EXCEPTION 'Verificación fallida: perdidas=%, espurias=%, antes=%, despues=%',
            perdidas, espurias, n_antes, n_despues;
    END IF;

    RAISE NOTICE 'Verificación OK: perdidas=0, espurias=0, filas antes=% / despues=%', n_antes, n_despues;
END $$;

COMMIT;
