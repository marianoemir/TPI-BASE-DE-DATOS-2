-- ============================================================
-- FOOD STORE · TP8 · verificar_vista_snapshot.sql
-- Paso 5 del protocolo de seguridad: equivalencia de una vista nueva.
-- Solo LEE. Todo tiene que dar 0 filas (o 0), salvo los conteos, que coinciden.
-- ============================================================

-- 1. Conteo: la vista tiene una fila por producto (los dados de baja viajan como lápida)
SELECT (SELECT count(*) FROM producto)         AS filas_producto,
       (SELECT count(*) FROM v_snapshot_movil) AS filas_vista;

-- 2. Equivalencia con una consulta manual escrita aparte (round + EXISTS en lugar de cast + JOIN),
--    con EXCEPT en los DOS sentidos. capturado_en queda afuera porque es now() y cambia en cada lectura.
WITH manual AS (
    SELECT p.id AS producto_id, p.nombre,
           round(p.precio * 100)::integer AS precio_centavos,
           p.stock, p.disponible,
           (p.eliminado OR EXISTS (SELECT 1 FROM categoria c
                                   WHERE c.id = p.categoria_id AND c.eliminado)) AS eliminado
    FROM producto p
),
vista AS (
    SELECT producto_id, nombre, precio_centavos, stock, disponible, eliminado FROM v_snapshot_movil
)
SELECT 'falta en la vista' AS problema, * FROM (SELECT * FROM manual EXCEPT SELECT * FROM vista) a
UNION ALL
SELECT 'sobra en la vista' AS problema, * FROM (SELECT * FROM vista EXCEPT SELECT * FROM manual) b;

-- 3. El cast a entero no trunca nada: ningún precio tiene fracciones de centavo
SELECT count(*) AS precios_con_fraccion_de_centavo
FROM producto WHERE precio * 100 <> round(precio * 100);

-- 4. La vista no expone datos de usuarios ni credenciales: estas son todas sus columnas
SELECT column_name FROM information_schema.columns
WHERE table_name = 'v_snapshot_movil' ORDER BY ordinal_position;
