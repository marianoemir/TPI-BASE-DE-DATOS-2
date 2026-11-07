-- REQ 3.4, 8.1, 8.3, 8.4, 8.5: Carga idempotente del catálogo desde snapshot_servidor a producto_cache
-- Usa INSERT ... ON CONFLICT DO UPDATE (nunca INSERT OR REPLACE)
-- Mapea booleanos t/f de PostgreSQL a 1/0 en SQLite; conserva lápidas (fila conservada)
-- Actualiza todas las columnas incluyendo eliminado y stock

INSERT INTO producto_cache (producto_id, nombre, precio_centavos, stock_visto, disponible_visto, eliminado, capturado_en)
SELECT
    s.producto_id,
    s.nombre,
    s.precio_centavos,
    s.stock,
    CASE WHEN s.disponible = 't' THEN 1 ELSE 0 END,
    CASE WHEN s.eliminado = 't' THEN 1 ELSE 0 END,
    s.capturado_en
FROM snapshot_servidor s
ON CONFLICT (producto_id) DO UPDATE SET
    nombre        = EXCLUDED.nombre,
    precio_centavos = EXCLUDED.precio_centavos,
    stock_visto     = EXCLUDED.stock_visto,
    disponible_visto = EXCLUDED.disponible_visto,
    eliminado       = EXCLUDED.eliminado,
    capturado_en    = EXCLUDED.capturado_en;