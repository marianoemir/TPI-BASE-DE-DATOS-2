-- ============================================================
-- FOOD STORE · TP8 · verificar_hallazgos_3c.sql
-- Reproduce las comprobaciones de los hallazgos H01 y R1 del code review (3.c).
-- Salida guardada en evidencias/16_h01_categoria_baja_y_repetido.txt
--
-- CORRER SOLO EN UNA COPIA: modifica categoria y crea un pedido.
--   CREATE DATABASE foodstore_u8_rev TEMPLATE foodstore_u8;   -- sin conexiones abiertas a foodstore_u8
--   psql -U postgres -d foodstore_u8_rev -f postgresql/verificar_hallazgos_3c.sql
--   DROP DATABASE foodstore_u8_rev WITH (FORCE);
-- ============================================================
\echo === H01 ===
-- Se da de baja la categoría 5 (Hamburguesas: productos 12 y 13).
UPDATE categoria SET eliminado = TRUE WHERE id = 5;
-- La vista de la tablet exporta la baja como lápida: 16 filas, 4 con eliminado = t.
SELECT count(*) AS filas, count(*) FILTER (WHERE eliminado) AS con_baja FROM v_snapshot_movil;
SELECT stock AS stock_antes FROM producto WHERE id = 12;
-- sp_crear_pedido solo mira producto.eliminado, no la categoría: acepta el pedido.
DO $$
DECLARE u BIGINT;
BEGIN
  SELECT id INTO u FROM usuario WHERE eliminado = FALSE ORDER BY id LIMIT 1;
  CALL sp_crear_pedido(u, (enum_range(NULL::forma_pago))[1], '[{"producto_id":12,"cantidad":1}]'::jsonb);
  RAISE NOTICE 'H01: el servidor ACEPTO un pedido de un producto de categoria eliminada';
END $$;
SELECT stock AS stock_despues FROM producto WHERE id = 12;
SELECT d.pedido_id, d.producto_id, d.cantidad FROM detalle_pedido d ORDER BY d.id DESC LIMIT 1;

\echo === PRODUCTO REPETIDO ===
-- Mismo producto dos veces en p_items: el error es de UNIQUE(pedido_id, producto_id), sin mensaje de negocio.
DO $$
DECLARE u BIGINT;
BEGIN
  SELECT id INTO u FROM usuario WHERE eliminado = FALSE ORDER BY id LIMIT 1;
  CALL sp_crear_pedido(u, (enum_range(NULL::forma_pago))[1], '[{"producto_id":4,"cantidad":1},{"producto_id":4,"cantidad":1}]'::jsonb);
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'SQLSTATE=% | MENSAJE=%', SQLSTATE, SQLERRM;
END $$;
