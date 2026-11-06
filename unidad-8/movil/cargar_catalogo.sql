-- ============================================================
-- FOOD STORE · TP8 · cargar_catalogo.sql   (consigna 2.a)
-- Carga producto_cache desde snapshot_servidor.
-- Se usa UPSERT y NO "INSERT OR REPLACE" ni borrar y recargar: REPLACE borra la
-- fila, y con claves foráneas activas fallaría si un borrador la usa. Así la
-- lápida (eliminado = 1) queda en la fila y el producto sale del catálogo (C4).
-- ============================================================
PRAGMA foreign_keys = ON;

BEGIN;
INSERT INTO producto_cache
       (producto_id, nombre, precio_centavos, stock_visto, disponible_visto, eliminado, capturado_en)
SELECT  producto_id, nombre, precio_centavos, stock,
        (disponible = 't'),          -- t/f de PostgreSQL -> 1/0
        (eliminado  = 't'),
        capturado_en
FROM snapshot_servidor
WHERE true                           -- SQLite lo exige para usar ON CONFLICT con un SELECT
ON CONFLICT (producto_id) DO UPDATE SET
        nombre           = excluded.nombre,
        precio_centavos  = excluded.precio_centavos,
        stock_visto      = excluded.stock_visto,
        disponible_visto = excluded.disponible_visto,
        eliminado        = excluded.eliminado,
        capturado_en     = excluded.capturado_en;
COMMIT;

-- Fecha de la copia (se anota en el informe)
SELECT capturado_en AS fecha_de_la_copia, count(*) AS productos
FROM producto_cache
GROUP BY capturado_en;
