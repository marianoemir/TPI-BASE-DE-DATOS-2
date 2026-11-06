-- Pedidos de prueba opcionales para enriquecer las consultas b) y c)
-- Se utiliza el procedimiento almacenado sp_crear_pedido según las reglas de negocio de Food Store.

CALL sp_crear_pedido(2, 'TARJETA', '[{"producto_id":1,"cantidad":1},{"producto_id":8,"cantidad":1}]'::jsonb);
CALL sp_crear_pedido(3, 'EFECTIVO', '[{"producto_id":1,"cantidad":3},{"producto_id":7,"cantidad":1}]'::jsonb);