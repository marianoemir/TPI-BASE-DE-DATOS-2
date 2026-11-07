\set ON_ERROR_STOP on
SELECT proname, prosecdef FROM pg_proc WHERE proname = 'sp_crear_pedido';

BEGIN;
SELECT (SELECT id FROM usuario  WHERE NOT eliminado ORDER BY id LIMIT 1) AS uid,
       (SELECT id FROM producto WHERE NOT eliminado AND disponible AND stock > 0 ORDER BY id LIMIT 1) AS pid \gset
SET LOCAL ROLE app_web;
SELECT current_user AS ejecuta_como;
CALL sp_crear_pedido(:uid, 'EFECTIVO', format('[{"producto_id":%s,"cantidad":1}]', :pid)::jsonb);
RESET ROLE;
SELECT current_user AS lee_como;
SELECT id, total FROM pedido ORDER BY id DESC LIMIT 1;
ROLLBACK;
