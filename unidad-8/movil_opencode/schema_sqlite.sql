-- REQ 5.1, 6.1-6.6, 6.11, 7.1, 7.3, 8.2
-- Esquema SQLite de la tablet (corregido a mano sobre la version generada por OpenCode)
PRAGMA foreign_keys = ON;

CREATE TABLE producto_cache (
    producto_id      INTEGER PRIMARY KEY,
    nombre           TEXT    NOT NULL,
    precio_centavos  INTEGER NOT NULL CHECK (precio_centavos >= 0),
    stock_visto      INTEGER NOT NULL CHECK (stock_visto >= 0),
    disponible_visto INTEGER NOT NULL CHECK (disponible_visto IN (0,1)),
    eliminado        INTEGER NOT NULL DEFAULT 0 CHECK (eliminado IN (0,1)),
    capturado_en     TEXT    NOT NULL
) STRICT;

CREATE TABLE pedido_borrador (
    id_local            TEXT PRIMARY KEY CHECK (length(id_local) = 36),
    usuario_id_servidor INTEGER NOT NULL CHECK (usuario_id_servidor > 0),
    forma_pago          TEXT    NOT NULL CHECK (forma_pago IN ('EFECTIVO','TARJETA','TRANSFERENCIA')),
    creado_en           TEXT    NOT NULL
) STRICT;

CREATE TABLE item_borrador (
    id_local              TEXT    NOT NULL,
    producto_id           INTEGER NOT NULL,
    cantidad              INTEGER NOT NULL CHECK (cantidad > 0),
    precio_centavos_visto INTEGER NOT NULL CHECK (precio_centavos_visto >= 0),
    PRIMARY KEY (id_local, producto_id),
    FOREIGN KEY (id_local) REFERENCES pedido_borrador(id_local) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES producto_cache(producto_id)
) STRICT;

CREATE TABLE cola_sync (
    solicitud_uuid TEXT PRIMARY KEY CHECK (length(solicitud_uuid) = 36),
    id_local       TEXT NOT NULL,
    estado         TEXT NOT NULL DEFAULT 'PENDIENTE'
                   CHECK (estado IN ('PENDIENTE','CONFLICTO','RECHAZADO','SIMULADO_APROBADO')),
    motivo         TEXT,
    creada_en      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d %H:%M:%S','now')),
    evaluada_en    TEXT,
    CHECK (estado NOT IN ('CONFLICTO','RECHAZADO') OR motivo IS NOT NULL)
) STRICT;

CREATE UNIQUE INDEX ux_cola_una_pendiente
    ON cola_sync (id_local) WHERE estado = 'PENDIENTE';

CREATE TABLE snapshot_servidor (
    producto_id     INTEGER PRIMARY KEY,
    nombre          TEXT    NOT NULL,
    precio_centavos INTEGER NOT NULL CHECK (precio_centavos >= 0),
    stock           INTEGER NOT NULL CHECK (stock >= 0),
    disponible      TEXT    NOT NULL CHECK (disponible IN ('t','f')),
    eliminado       TEXT    NOT NULL CHECK (eliminado IN ('t','f')),
    capturado_en    TEXT    NOT NULL
) STRICT;

CREATE VIEW v_catalogo_disponible AS
SELECT producto_id,
       nombre,
       precio_centavos / 100.0 AS precio,
       stock_visto,
       disponible_visto
FROM producto_cache
WHERE eliminado = 0 AND disponible_visto = 1;
