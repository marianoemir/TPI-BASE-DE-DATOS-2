-- Cantidad y suma de ids distintos de la muestra, para comparar con la salida de
-- medicion_repetida_mongodb.js (MONGO_USUARIOS_DISTINTOS y MONGO_PRODUCTOS_DISTINTOS).
-- Uso: psql -d foodstore -v limite=5000 -f verificar_referencias_postgresql.sql
\if :{?limite}
\else
  \set limite 5000
\endif

WITH muestra AS (
  SELECT id, usuario_id FROM pedido WHERE eliminado = FALSE ORDER BY id LIMIT :limite
)
SELECT 'PG_USUARIOS_DISTINTOS' AS seccion,
       count(DISTINCT usuario_id) AS distintos,
       sum(DISTINCT usuario_id) AS suma_ids
FROM muestra;

WITH muestra AS (
  SELECT id FROM pedido WHERE eliminado = FALSE ORDER BY id LIMIT :limite
), prod AS (
  SELECT DISTINCT d.producto_id
  FROM detalle_pedido d JOIN muestra m ON m.id = d.pedido_id
  WHERE d.eliminado = FALSE
)
SELECT 'PG_PRODUCTOS_DISTINTOS' AS seccion,
       count(*) AS distintos,
       sum(producto_id) AS suma_ids
FROM prod;
