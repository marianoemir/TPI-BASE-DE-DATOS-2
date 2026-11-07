-- ============================================================
-- exportar_pedidos.sql  (TP U7 - Food Store)
-- Genera desde PostgreSQL el JSON de los pedidos a migrar.
-- Solo LEE: no modifica la base.
--
-- Uso (desde la raiz del repo):
--   psql -U postgres -d foodstore -t -A -f modelo/exportar_pedidos.sql -o modelo/pedidos_export.json
--
-- IDs y origen parametrizables. Por defecto conserva los siete pedidos originales.
-- Ejemplo sin un integrante del equipo: -v ids=1,2,3,6,7,8 -v origen=ejemplo_regenerado
-- Nunca se exporta contrasena, celular ni rol.
-- ============================================================
\if :{?ids}
\else
  \set ids 1,2,3,5,6,7,8
\endif
\if :{?origen}
\else
  \set origen migracion_u7
\endif

SELECT jsonb_pretty(jsonb_agg(doc ORDER BY id)) FROM (
  SELECT p.id,
    jsonb_build_object(
      '_id', p.id,
      'fecha', to_char(p.fecha, 'YYYY-MM-DD'),
      'estado', p.estado,
      'forma_pago', p.forma_pago,
      'total', p.total::text,
      'cliente', jsonb_build_object(
          'usuario_id', u.id, 'nombre', u.nombre,
          'apellido', u.apellido, 'mail', u.mail),
      'lineas', (SELECT jsonb_agg(jsonb_build_object(
                    'detalle_id', d.id,
                    'producto_id', d.producto_id,
                    'nombre', pr.nombre,
                    'cantidad', d.cantidad,
                    'precio_unitario', d.precio_unitario::text,
                    'subtotal', d.subtotal::text) ORDER BY d.id)
                 FROM detalle_pedido d
                 JOIN producto pr ON pr.id = d.producto_id
                 WHERE d.pedido_id = p.id AND d.eliminado = FALSE),
      'origen', :'origen'
    ) AS doc
  FROM pedido p
  JOIN usuario u ON u.id = p.usuario_id
  WHERE p.eliminado = FALSE
    AND p.id = ANY (string_to_array(:'ids', ',')::bigint[])
) t;
