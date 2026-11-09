-- =============================================================================
-- unidad-4/migracion/setup_previo.sql
-- Estado PREVIO a la migración de la U4 (FNBC sobre control_lote_almacen).
--
-- Qué hace: crea lote, deposito, los responsables 801-803 y la tabla
-- control_lote_almacen con la instancia de ejemplo del enunciado (sección 1 de
-- tp_fnbc_control_lote.sql). Es el punto de partida que up.sql necesita.
--
-- Requisitos: base con schema.sql, objects.sql y data.sql ya cargados
-- (por ejemplo, la base copia_u4).
--
-- SOLO PARA COPIAS DE TRABAJO: al principio borra las tablas de la U4 para
-- poder re-ejecutarse. No correr sobre una base con datos que importen.
-- =============================================================================
BEGIN;

-- 0. Limpieza (orden inverso de dependencias)
DROP VIEW  IF EXISTS v_control_lote_almacen;
DROP TABLE IF EXISTS control_lote;
DROP TABLE IF EXISTS responsable_deposito;
DROP TABLE IF EXISTS control_lote_almacen;
DROP TABLE IF EXISTS lote;
DROP TABLE IF EXISTS deposito;
DELETE FROM usuario WHERE id IN (801, 802, 803);

-- 1. Tablas maestras mínimas, con los ids EXACTOS del enunciado
CREATE TABLE lote (
    id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo  VARCHAR(50) NOT NULL
);

CREATE TABLE deposito (
    id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre  VARCHAR(100) NOT NULL
);

INSERT INTO lote (id, codigo) OVERRIDING SYSTEM VALUE VALUES
    (501, 'LOTE-501'),
    (502, 'LOTE-502'),
    (503, 'LOTE-503');

INSERT INTO deposito (id, nombre) OVERRIDING SYSTEM VALUE VALUES
    (30, 'Depósito 30'),
    (31, 'Depósito 31'),
    (32, 'Depósito 32');

INSERT INTO usuario (id, nombre, apellido, mail, contrasena) OVERRIDING SYSTEM VALUE VALUES
    (801, 'Responsable', 'Control 801', 'resp801@foodstore.com', 'hash_resp801'),
    (802, 'Responsable', 'Control 802', 'resp802@foodstore.com', 'hash_resp802'),
    (803, 'Responsable', 'Control 803', 'resp803@foodstore.com', 'hash_resp803');

-- 2. Esquema a migrar, exacto al del enunciado, con su instancia de ejemplo
CREATE TABLE control_lote_almacen (
    lote_id                 BIGINT NOT NULL REFERENCES lote(id),
    deposito_id             BIGINT NOT NULL REFERENCES deposito(id),
    responsable_control_id  BIGINT NOT NULL REFERENCES usuario(id),
    PRIMARY KEY (lote_id, deposito_id)
);

INSERT INTO control_lote_almacen VALUES
    (501, 30, 801),
    (502, 30, 801),
    (503, 31, 802);

COMMIT;
