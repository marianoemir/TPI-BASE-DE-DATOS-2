-- Exporta una muestra local para la coleccion pedidos_benchmark.
-- Ejemplo: psql -v limite=5000 -t -A -f modelo/exportar_pedidos_benchmark.sql -o modelo/pedidos_benchmark.json
\if :{?limite}
\else
  \set limite 5000
\endif

WITH muestra AS (
  SELECT id
  FROM pedido
  WHERE eliminado = FALSE
  ORDER BY id
  LIMIT :limite
)
SELECT jsonb_pretty(jsonb_agg(doc ORDER BY id))
FROM (
  SELECT p.id,
    jsonb_build_object(
      '_id', p.id,
      'fecha', to_char(p.fecha, 'YYYY-MM-DD'),
      'estado', p.estado,
      'forma_pago', p.forma_pago,
      'total', p.total::text,
      'cliente', jsonb_build_object('usuario_id', u.id, 'nombre', u.nombre, 'apellido', u.apellido, 'mail', u.mail),
      'lineas', (
        SELECT jsonb_agg(jsonb_build_object(
          'detalle_id', d.id, 'producto_id', d.producto_id, 'nombre', pr.nombre,
          'categoria_id', c.id, 'categoria_nombre', c.nombre,
          'cantidad', d.cantidad, 'precio_unitario', d.precio_unitario::text, 'subtotal', d.subtotal::text
        ) ORDER BY d.id)
        FROM detalle_pedido d
        JOIN producto pr ON pr.id = d.producto_id
        JOIN categoria c ON c.id = pr.categoria_id
        WHERE d.pedido_id = p.id AND d.eliminado = FALSE
      ),
      'origen', 'benchmark'
    ) AS doc
  FROM pedido p
  JOIN muestra m ON m.id = p.id
  JOIN usuario u ON u.id = p.usuario_id
) t;
