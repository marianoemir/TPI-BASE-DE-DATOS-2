-- Medicion repetida U7 (objetivo 10). Solo lectura.
-- Uso: psql -d foodstore -v limite=5000 -v producto=1 -f medicion_repetida_postgresql.sql
-- Se ejecuta varias veces desde el script correr_correcciones_obj10.ps1 (la primera es calentamiento).
-- \timing mide la consulta completa en el cliente, sin EXPLAIN. La consulta por producto recibe el
-- producto ya elegido (no lo calcula), igual que en MongoDB.
\if :{?limite}
\else
  \set limite 5000
\endif
\if :{?producto}
\else
  \set producto 1
\endif
\timing on

\echo CONSULTA_PRODUCTO
WITH muestra AS MATERIALIZED (
  SELECT id FROM pedido WHERE eliminado = FALSE ORDER BY id LIMIT :limite
)
SELECT DISTINCT p.id, p.estado, p.fecha, p.total
FROM pedido p
JOIN muestra m ON m.id = p.id
JOIN detalle_pedido dp ON dp.pedido_id = p.id AND dp.eliminado = FALSE
WHERE dp.producto_id = :producto;

\echo CONSULTA_CATEGORIA
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
