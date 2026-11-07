-- Ejemplo: psql -v limite=5000 -f verificar_benchmark_postgresql.sql -d foodstore
\if :{?limite}
\else
  \set limite 5000
\endif

WITH muestra AS (
  SELECT id, usuario_id, total
  FROM pedido
  WHERE eliminado = FALSE
  ORDER BY id
  LIMIT :limite
)
SELECT 'RESUMEN_POSTGRES' AS seccion,
       count(*) AS documentos,
       round(sum(total), 2) AS total
FROM muestra;

WITH muestra AS (
  SELECT id, usuario_id
  FROM pedido
  WHERE eliminado = FALSE
  ORDER BY id
  LIMIT :limite
), lineas AS (
  SELECT d.producto_id
  FROM detalle_pedido d JOIN muestra m ON m.id = d.pedido_id
  WHERE d.eliminado = FALSE
)
SELECT 'REFERENCIAS_POSTGRES' AS seccion,
       (SELECT count(*) FROM muestra m WHERE NOT EXISTS (SELECT 1 FROM usuario u WHERE u.id = m.usuario_id)) AS usuarios_inexistentes,
       (SELECT count(*) FROM lineas l WHERE NOT EXISTS (SELECT 1 FROM producto p WHERE p.id = l.producto_id)) AS productos_inexistentes;

WITH muestra AS (
  SELECT id FROM pedido WHERE eliminado = FALSE ORDER BY id LIMIT :limite
)
SELECT 'VENTAS_POR_CATEGORIA_POSTGRES' AS seccion,
       c.nombre AS categoria,
       round(sum(d.subtotal), 2) AS ventas
FROM muestra m
JOIN detalle_pedido d ON d.pedido_id = m.id AND d.eliminado = FALSE
JOIN producto p ON p.id = d.producto_id AND p.eliminado = FALSE
JOIN categoria c ON c.id = p.categoria_id AND c.eliminado = FALSE
GROUP BY c.nombre
ORDER BY c.nombre;
