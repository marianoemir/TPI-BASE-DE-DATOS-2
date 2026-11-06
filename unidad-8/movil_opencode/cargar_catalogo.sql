-- REQ 8.3, 8.4, 8.5, 3.4 (criterio 4 del Requisito 3: lapida, nunca DELETE)
-- Recarga de producto_cache desde snapshot_servidor con UPSERT.
-- Corregido a mano sobre la version de OpenCode: se quito el DELETE FROM producto_cache,
-- que contradice REQ 3.4 y 8.3 (las filas referenciadas por borradores no se borran).
PRAGMA foreign_keys = ON;

INSERT INTO producto_cache
    (producto_id, nombre, precio_centavos, stock_visto, disponible_visto, eliminado, capturado_en)
SELECT
    producto_id,
    nombre,
    precio_centavos,
    stock,
    CASE WHEN disponible = 't' THEN 1 ELSE 0 END,
    CASE WHEN eliminado  = 't' THEN 1 ELSE 0 END,
    capturado_en
FROM snapshot_servidor
WHERE true
ON CONFLICT (producto_id) DO UPDATE SET
    nombre           = excluded.nombre,
    precio_centavos  = excluded.precio_centavos,
    stock_visto      = excluded.stock_visto,
    disponible_visto = excluded.disponible_visto,
    eliminado        = excluded.eliminado,
    capturado_en     = excluded.capturado_en;

SELECT count(*) AS productos,
       strftime('%Y-%m-%d %H:%M:%S','now') AS fecha_de_la_copia
FROM producto_cache;
