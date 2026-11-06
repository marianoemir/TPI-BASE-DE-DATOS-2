-- ============================================================
-- FOOD STORE · TP8 · casos_c2_c5_borradores.sql
-- Paso 1 de los casos C2 a C5: se anotan los borradores con la lista de precios
-- ACTUAL de la tablet (todavía el servidor no cambió nada).
-- El prefijo del UUID identifica el caso: c2..., c3..., c4..., c5...
--     sqlite3 -header -column movil/foodstore_movil.db ".read movil/casos_c2_c5_borradores.sql"
-- ============================================================
PRAGMA foreign_keys = ON;

-- C2 · Juan pide 1 Muzzarella a $3.500. Después el servidor la va a subir.
BEGIN;
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago)
VALUES ('c2000000-0000-4000-8000-00000000000a', 2, 'TARJETA');
INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES ('c2000000-0000-4000-8000-00000000000a', 1, 1, 350000);
INSERT INTO cola_sync (solicitud_uuid, id_local)
VALUES ('c2000000-0000-4000-8000-00000000000b', 'c2000000-0000-4000-8000-00000000000a');
COMMIT;

-- C3 · Lucía pide 10 Tiramisú, pero en el servidor quedan 6.
BEGIN;
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago)
VALUES ('c3000000-0000-4000-8000-00000000000a', 3, 'EFECTIVO');
INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES ('c3000000-0000-4000-8000-00000000000a', 11, 10, 220000);
INSERT INTO cola_sync (solicitud_uuid, id_local)
VALUES ('c3000000-0000-4000-8000-00000000000b', 'c3000000-0000-4000-8000-00000000000a');
COMMIT;

-- C4 · Ana pide 1 Fugazzeta. Después el servidor la va a dar de baja.
BEGIN;
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago)
VALUES ('c4000000-0000-4000-8000-00000000000a', 1, 'TRANSFERENCIA');
INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES ('c4000000-0000-4000-8000-00000000000a', 3, 1, 450000);
INSERT INTO cola_sync (solicitud_uuid, id_local)
VALUES ('c4000000-0000-4000-8000-00000000000b', 'c4000000-0000-4000-8000-00000000000a');
COMMIT;

-- C5 · Sofía pide 6 empanadas de carne y 2 Coca-Cola. Nada va a cambiar.
BEGIN;
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago)
VALUES ('c5000000-0000-4000-8000-00000000000a', 5, 'EFECTIVO');
INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES ('c5000000-0000-4000-8000-00000000000a', 4, 6,  90000),
       ('c5000000-0000-4000-8000-00000000000a', 7, 2, 120000);
INSERT INTO cola_sync (solicitud_uuid, id_local)
VALUES ('c5000000-0000-4000-8000-00000000000b', 'c5000000-0000-4000-8000-00000000000a');
COMMIT;

SELECT solicitud_uuid, estado FROM cola_sync WHERE solicitud_uuid LIKE 'c%' ORDER BY solicitud_uuid;
