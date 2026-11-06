-- REQ 5.1, 6.1-6.6, 6.11, 7.1, 7.3, 8.2
-- Esquema SQLite de la tablet con tablas STRICT, centavos, restricciones, índice parcial y vista
PRAGMA foreign_keys = ON;

-- Tabla producto_cache: catálogo local consultado por el vendedor
CREATE TABLE producto_cache (
    producto_id     INTEGER PRIMARY KEY STRICT,
    nombre          TEXT    NOT NULL STRICT,
    precio_centavos INTEGER NOT NULL CHECK (precio_centavos >= 0) STRICT,
    stock_visto     INTEGER NOT NULL CHECK (stock_visto >= 0) STRICT,
    disponible_visto INTEGER NOT NULL CHECK (disponible_visto IN (0,1)) STRICT,
    eliminado       INTEGER NOT NULL DEFAULT 0 CHECK (eliminado IN (0,1)) STRICT,
    capturado_en    TEXT    NOT NULL STRICT
);

-- Tabla pedido_borrador: encabezado de un pedido sin conexión
CREATE TABLE pedido_borrador (
    id_local        TEXT PRIMARY KEY STRICT CHECK (length(id_local) = 36),
    usuario_id_servidor INTEGER NOT NULL CHECK (usuario_id_servidor > 0) STRICT,
    forma_pago      TEXT    NOT NULL CHECK (forma_pago IN ('EFECTIVO','TARJETA','TRANSFERENCIA')) STRICT,
    creado_en       TEXT    NOT NULL STRICT
);

-- Tabla item_borrador: ítems dentro de un borrador
CREATE TABLE item_borrador (
    id_local            TEXT NOT NULL STRICT,
    producto_id         INTEGER NOT NULL STRICT,
    cantidad            INTEGER NOT NULL CHECK (cantidad > 0) STRICT,
    precio_centavos_visto INTEGER NOT NULL CHECK (precio_centavos_visto >= 0) STRICT,
    PRIMARY KEY (id_local, producto_id) STRICT,
    FOREIGN KEY (id_local) REFERENCES pedido_borrador(id_local) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES producto_cache(producto_id) STRICT
);

-- Tabla cola_sync: solicitudes de sincronización pendientes
CREATE TABLE cola_sync (
    solicitud_uuid    TEXT PRIMARY KEY STRICT CHECK (length(solicitud_uuid) = 36),
    id_local          TEXT NOT NULL STRICT,
    estado            TEXT    NOT NULL DEFAULT 'PENDIENTE' CHECK (estado IN ('PENDIENTE','CONFLICTO','RECHAZADO','SIMULADO_APROBADO')) STRICT,
    motivo            TEXT    NOT NULL CHECK (estado NOT IN ('CONFLICTO','RECHAZADO') OR motivo IS NOT NULL) STRICT,
    creada_en         TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%d %H:%M:%S','now')) STRICT,
    evaluada_en       TEXT STRICT,
    UNIQUE (id_local) WHERE estado = 'PENDIENTE' -- índice parcial ux_cola_una_pendiente
);

-- Tabla snapshot_servidor: instantánea traída del servidor ( staging )
CREATE TABLE snapshot_servidor (
    producto_id    INTEGER PRIMARY KEY STRICT,
    nombre         TEXT    NOT NULL STRICT,
    precio_centavos INTEGER NOT NULL CHECK (precio_centavos >= 0) STRICT,
    stock          INTEGER NOT NULL CHECK (stock >= 0) STRICT,
    disponible     TEXT    NOT NULL CHECK (disponible IN ('t','f')) STRICT,
    eliminado      TEXT    NOT NULL CHECK (eliminado IN ('t','f')) STRICT,
    capturado_en   TEXT    NOT NULL STRICT
);

-- Vista catálogo disponible: productos que el vendedor ve en pantalla
CREATE VIEW v_catalogo_disponible AS
SELECT producto_id,
       nombre,
       precio_centavos / 100.0 AS precio,
       stock_visto,
       disponible_visto
FROM producto_cache
WHERE eliminado = 0 AND disponible_visto = 1;