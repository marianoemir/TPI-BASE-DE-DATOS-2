-- Ejemplo: psql -v limite=5000 -f consultas_benchmark_postgresql.sql -d foodstore
\if :{?limite}
\else
  \set limite 5000
\endif

-- Consulta c, misma muestra y producto mas frecuente dentro de ella.
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
WITH muestra AS MATERIALIZED (
  SELECT id FROM pedido WHERE eliminado = FALSE ORDER BY id LIMIT :limite
), objetivo AS (
  SELECT dp.producto_id
  FROM detalle_pedido dp JOIN muestra m ON m.id = dp.pedido_id
  WHERE dp.eliminado = FALSE
  GROUP BY dp.producto_id
  ORDER BY count(DISTINCT dp.pedido_id) DESC, dp.producto_id
  LIMIT 1
)
SELECT DISTINCT p.id, p.estado, p.fecha, p.total
FROM pedido p
JOIN muestra m ON m.id = p.id
JOIN detalle_pedido dp ON dp.pedido_id = p.id AND dp.eliminado = FALSE
JOIN objetivo o ON o.producto_id = dp.producto_id;

-- Ventas por categoria sobre exactamente la misma muestra.
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
WITH muestra AS MATERIALIZED (
  SELECT id FROM pedido WHERE eliminado = FALSE ORDER BY id LIMIT :limite
)
SELECT c.nombre AS categoria, round(sum(dp.subtotal), 2) AS ventas
FROM muestra m
JOIN detalle_pedido dp ON dp.pedido_id = m.id AND dp.eliminado = FALSE
JOIN producto pr ON pr.id = dp.producto_id AND pr.eliminado = FALSE
JOIN categoria c ON c.id = pr.categoria_id AND c.eliminado = FALSE
GROUP BY c.nombre
ORDER BY c.nombre;
