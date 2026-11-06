-- ============================================================
-- FOOD STORE · TP8 · verificar_vistas_tablet.sql
-- Paso 5 del protocolo de seguridad, del lado SQLite. Solo LEE.
--     sqlite3 -header -column movil/foodstore_movil.db ".read movil/verificar_vistas_tablet.sql"
-- Correr después de cargar_catalogo.sql. Los conteos coinciden y el resto da 0 filas.
-- ============================================================
PRAGMA foreign_keys = ON;

-- A. producto_cache quedó igual que la instantánea (t/f -> 1/0)
SELECT (SELECT count(*) FROM snapshot_servidor) AS en_snapshot,
       (SELECT count(*) FROM producto_cache)    AS en_cache;

SELECT 'falta en la cache' AS problema, * FROM (
    SELECT producto_id, nombre, precio_centavos, stock, (disponible = 't'), (eliminado = 't') FROM snapshot_servidor
    EXCEPT
    SELECT producto_id, nombre, precio_centavos, stock_visto, disponible_visto, eliminado FROM producto_cache)
UNION ALL
SELECT 'sobra en la cache' AS problema, * FROM (
    SELECT producto_id, nombre, precio_centavos, stock_visto, disponible_visto, eliminado FROM producto_cache
    EXCEPT
    SELECT producto_id, nombre, precio_centavos, stock, (disponible = 't'), (eliminado = 't') FROM snapshot_servidor);

-- B. v_catalogo_disponible equivale a la consulta manual sobre producto_cache
SELECT (SELECT count(*) FROM v_catalogo_disponible)                                         AS en_vista,
       (SELECT count(*) FROM producto_cache WHERE eliminado = 0 AND disponible_visto = 1) AS manual;

SELECT 'falta en la vista' AS problema, * FROM (
    SELECT producto_id, nombre, precio_centavos / 100.0, stock_visto FROM producto_cache
    WHERE eliminado = 0 AND disponible_visto = 1
    EXCEPT
    SELECT producto_id, nombre, precio, stock_visto FROM v_catalogo_disponible)
UNION ALL
SELECT 'sobra en la vista' AS problema, * FROM (
    SELECT producto_id, nombre, precio, stock_visto FROM v_catalogo_disponible
    EXCEPT
    SELECT producto_id, nombre, precio_centavos / 100.0, stock_visto FROM producto_cache
    WHERE eliminado = 0 AND disponible_visto = 1);
