-- ============================================================
-- FOOD STORE · TP8 · 10_snapshot_catalogo.sql
-- Vista que el servidor le da a la tablet (parada 5 del apunte).
-- Correr en la base de PRUEBAS, después de schema + objects + data + views.
-- ============================================================
CREATE OR REPLACE VIEW v_snapshot_movil AS
SELECT p.id                         AS producto_id,
       p.nombre,
       (p.precio * 100)::INTEGER    AS precio_centavos,  -- la conversión a centavos se hace acá, una vez
       p.stock,
       p.disponible,
       (p.eliminado OR c.eliminado) AS eliminado,        -- la baja viaja como dato (lápida)
       now()                        AS capturado_en      -- la fecha de la lista
FROM producto p
JOIN categoria c ON c.id = p.categoria_id;

COMMENT ON VIEW v_snapshot_movil IS
  'Instantánea del catálogo para la tablet: precio en centavos, lápida (eliminado) y fecha de captura. No incluye usuarios ni datos personales.';
