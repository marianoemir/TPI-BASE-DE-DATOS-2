-- REQ 3.4, 8.1, 8.3, 8.4, 8.5
-- Carga del catálogo desde la instantánea a producto_cache con UPSERT
PRAGMA foreign_keys = ON;

-- Vaciar producto_cache antes de recargar (solo para esta operación de inicialización/recarga)
-- Se conserva el capturado_en cuando ya existe la fila (ON CONFLICT UPDATE)
DELETE FROM producto_cache;

INSERT INTO producto_cache (producto_id, nombre, precio_centavos, stock_visto, disponible_visto, eliminado, capturado_en)
SELECT
    producto_id,
    nombre,
    precio_centavos,
    stock,
    CASE WHEN disponible = 't' THEN 1 ELSE 0 END,
    CASE WHEN eliminado = 't' THEN 1 ELSE 0 END,
    capturado_en
FROM snapshot_servidor
WHERE true ON CONFLICT (producto_id) DO UPDATE SET
    nombre = EXCLUDED.nombre,
    precio_centavos = EXCLUDED.precio_centavos,
    stock_visto = EXCLUDED.stock_visto,
    disponible_visto = EXCLUDED.disponible_visto,
    eliminado = EXCLUDED.eliminado,
    capturado_en = EXCLUDED.capturado_en;

-- Devolver resumen de la carga
SELECT
    count(*) AS productos,
    strftime('%Y-%m-%d %H:%M:%S','now') AS fecha_de_la_copia
FROM producto_cache;