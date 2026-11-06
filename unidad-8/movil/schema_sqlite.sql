-- ============================================================
-- FOOD STORE · TP8 · schema_sqlite.sql  (base de la tablet)
-- Correr sobre una base NUEVA:
--     sqlite3 movil/foodstore_movil.db ".read movil/schema_sqlite.sql"
-- Requiere SQLite 3.37 o superior (tablas STRICT).
-- ============================================================
PRAGMA foreign_keys = ON;   -- vale solo para esta conexión: va en TODOS los scripts

-- La lista de precios: copia del catálogo del servidor, con fecha.
-- Precio en centavos (entero): las cuentas son exactas.
CREATE TABLE producto_cache (
    producto_id      INTEGER PRIMARY KEY,                       -- el mismo id que en el servidor
    nombre           TEXT    NOT NULL,
    precio_centavos  INTEGER NOT NULL CHECK (precio_centavos >= 0),
    stock_visto      INTEGER NOT NULL CHECK (stock_visto >= 0), -- solo orientativo
    disponible_visto INTEGER NOT NULL CHECK (disponible_visto IN (0,1)),
    eliminado        INTEGER NOT NULL DEFAULT 0 CHECK (eliminado IN (0,1)),  -- lápida
    capturado_en     TEXT    NOT NULL                           -- cuándo se copió
) STRICT;

-- El ticket: pedido anotado sin conexión. Todavía NO es una venta.
CREATE TABLE pedido_borrador (
    id_local            TEXT    PRIMARY KEY CHECK (length(id_local) = 36),  -- UUID creado en la tablet
    usuario_id_servidor INTEGER NOT NULL CHECK (usuario_id_servidor > 0),
    forma_pago          TEXT    NOT NULL
                        CHECK (forma_pago IN ('EFECTIVO','TARJETA','TRANSFERENCIA')),
    creado_en           TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
) STRICT;

-- Los renglones del ticket, con el precio que vio el cliente.
CREATE TABLE item_borrador (
    id_local              TEXT    NOT NULL
                          REFERENCES pedido_borrador(id_local) ON DELETE CASCADE,
    producto_id           INTEGER NOT NULL REFERENCES producto_cache(producto_id),
    cantidad              INTEGER NOT NULL CHECK (cantidad > 0),
    precio_centavos_visto INTEGER NOT NULL CHECK (precio_centavos_visto >= 0),
    PRIMARY KEY (id_local, producto_id)
) STRICT;

-- La lista de pendientes de enviar, con su resultado.
CREATE TABLE cola_sync (
    solicitud_uuid TEXT PRIMARY KEY CHECK (length(solicitud_uuid) = 36),   -- no cambia si se reintenta
    id_local       TEXT NOT NULL REFERENCES pedido_borrador(id_local),
    estado         TEXT NOT NULL DEFAULT 'PENDIENTE'
                   CHECK (estado IN ('PENDIENTE','CONFLICTO','RECHAZADO','SIMULADO_APROBADO')),
    motivo         TEXT,
    creada_en      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    evaluada_en    TEXT,
    CHECK (estado NOT IN ('CONFLICTO','RECHAZADO') OR motivo IS NOT NULL)
) STRICT;

-- Un borrador puede reenviarse (ej.: el cliente acepta el precio nuevo), pero
-- nunca puede tener dos envíos PENDIENTES a la vez. Un UNIQUE simple sobre
-- id_local impediría el reenvío; este índice parcial solo mira las PENDIENTE.
CREATE UNIQUE INDEX ux_cola_una_pendiente ON cola_sync (id_local) WHERE estado = 'PENDIENTE';

-- Lo que ve el vendedor en pantalla (C1)
CREATE VIEW v_catalogo_disponible AS
SELECT producto_id, nombre, precio_centavos / 100.0 AS precio, stock_visto, capturado_en
FROM producto_cache
WHERE eliminado = 0 AND disponible_visto = 1;

-- Tabla de paso (staging) para importar el CSV de psql tal cual viene:
-- los booleanos llegan como t / f. Se vacía y se vuelve a llenar en cada instantánea nueva.
CREATE TABLE snapshot_servidor (
    producto_id     INTEGER PRIMARY KEY,
    nombre          TEXT    NOT NULL,
    precio_centavos INTEGER NOT NULL CHECK (precio_centavos >= 0),
    stock           INTEGER NOT NULL CHECK (stock >= 0),
    disponible      TEXT    NOT NULL CHECK (disponible IN ('t','f')),
    eliminado       TEXT    NOT NULL CHECK (eliminado  IN ('t','f')),
    capturado_en    TEXT    NOT NULL
) STRICT;
