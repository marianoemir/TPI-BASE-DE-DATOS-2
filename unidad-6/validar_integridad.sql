-- validar_integridad.sql
-- Ejecutar solo sobre foodstore_restore_test despues de una restauracion.
-- Cada control debe devolver cantidad = 0.

\set ON_ERROR_STOP on
\pset tuples_only on
\pset format unaligned
\pset fieldsep '|'

SELECT 'producto_categoria_huerfanos' AS control,
       count(*) AS cantidad
FROM producto p
LEFT JOIN categoria c ON c.id = p.categoria_id
WHERE c.id IS NULL
UNION ALL
SELECT 'pedido_usuario_huerfanos',
       count(*)
FROM pedido p
LEFT JOIN usuario u ON u.id = p.usuario_id
WHERE u.id IS NULL
UNION ALL
SELECT 'detalle_pedido_huerfanos',
       count(*)
FROM detalle_pedido d
LEFT JOIN pedido p ON p.id = d.pedido_id
WHERE p.id IS NULL
UNION ALL
SELECT 'detalle_producto_huerfanos',
       count(*)
FROM detalle_pedido d
LEFT JOIN producto p ON p.id = d.producto_id
WHERE p.id IS NULL
UNION ALL
SELECT 'productos_invalidos',
       count(*)
FROM producto
WHERE precio < 0 OR stock < 0
UNION ALL
SELECT 'detalles_invalidos',
       count(*)
FROM detalle_pedido
WHERE cantidad <= 0 OR precio_unitario < 0;
