-- ============================================================
-- FOOD STORE · TP8 · casos_f2_semaforo.sql   (revisión cruzada del semáforo, F2)
-- Casos borde del semáforo, además de C2 a C6. CORRER SOLO EN UNA COPIA de la tablet:
-- agrega un producto de prueba (id 99) y varios borradores.
--
--   Copy-Item movil/foodstore_movil.db $env:TEMP\f2.db
--   sqlite3 -header -column $env:TEMP\f2.db ".read movil/casos_f2_semaforo.sql"
--   sqlite3 -header -column $env:TEMP\f2.db ".read movil/semaforo.sql"
--
-- Resultado esperado de semaforo.sql sobre estos casos (UUID f2...):
--   f2000000-...-00000000001b  RECHAZADO          stock insuficiente de Tiramisú (pide 10, hay 6)      <- rojo + amarillo: gana el rojo
--   f2000000-...-00000000002b  RECHAZADO          producto 99 no existe en el servidor                 <- producto que no está en la instantánea
--   f2000000-...-00000000003b  RECHAZADO          borrador sin ítems
--   f2000000-...-00000000004b  RECHAZADO          producto 15 (Producto temporalmente no disponible) no disponible
--   f2000000-...-00000000005b  SIMULADO_APROBADO  (control: 2 Empanadas de carne al precio vigente)
-- y el caso F2-6 falla al encolar con "UNIQUE constraint failed: cola_sync.id_local" (índice parcial: dos PENDIENTES del mismo borrador).
-- Corrido en la máquina de Mariano (SQLite 3.54.1): salidas en evidencias/18_f2_casos_borde_pre.txt y evidencias/19_f2_casos_borde_semaforo.txt.
-- ============================================================
PRAGMA foreign_keys = ON;

-- Producto que existe en la tablet pero NO en la instantánea nueva (para F2-2)
INSERT INTO producto_cache (producto_id, nombre, precio_centavos, stock_visto, disponible_visto, eliminado, capturado_en)
VALUES (99, 'Producto solo de la tablet', 100000, 5, 1, 0, '2026-11-03 00:00:00');

-- F2-1 · Rojo y amarillo en el MISMO borrador: la Muzzarella cambió de precio (amarillo) y piden 10 Tiramisú, quedan 6 (rojo).
BEGIN;
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago) VALUES ('f2000000-0000-4000-8000-00000000001a', 1, 'EFECTIVO');
INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto) VALUES ('f2000000-0000-4000-8000-00000000001a', 1, 1, 350000);
INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto) VALUES ('f2000000-0000-4000-8000-00000000001a', 11, 10, 220000);
INSERT INTO cola_sync (solicitud_uuid, id_local) VALUES ('f2000000-0000-4000-8000-00000000001b', 'f2000000-0000-4000-8000-00000000001a');
COMMIT;

-- F2-2 · Producto que no está en la instantánea (el LEFT JOIN da NULL: no tiene que pasar como verde).
BEGIN;
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago) VALUES ('f2000000-0000-4000-8000-00000000002a', 1, 'EFECTIVO');
INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto) VALUES ('f2000000-0000-4000-8000-00000000002a', 99, 1, 100000);
INSERT INTO cola_sync (solicitud_uuid, id_local) VALUES ('f2000000-0000-4000-8000-00000000002b', 'f2000000-0000-4000-8000-00000000002a');
COMMIT;

-- F2-3 · Borrador sin ítems.
BEGIN;
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago) VALUES ('f2000000-0000-4000-8000-00000000003a', 1, 'EFECTIVO');
INSERT INTO cola_sync (solicitud_uuid, id_local) VALUES ('f2000000-0000-4000-8000-00000000003b', 'f2000000-0000-4000-8000-00000000003a');
COMMIT;

-- F2-4 · Producto no disponible (producto 15, disponible = f en el servidor).
BEGIN;
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago) VALUES ('f2000000-0000-4000-8000-00000000004a', 1, 'EFECTIVO');
INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
SELECT 'f2000000-0000-4000-8000-00000000004a', producto_id, 1, precio_centavos FROM producto_cache WHERE producto_id = 15;
INSERT INTO cola_sync (solicitud_uuid, id_local) VALUES ('f2000000-0000-4000-8000-00000000004b', 'f2000000-0000-4000-8000-00000000004a');
COMMIT;

-- F2-5 · Control: todo coincide.
BEGIN;
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago) VALUES ('f2000000-0000-4000-8000-00000000005a', 1, 'EFECTIVO');
INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
SELECT 'f2000000-0000-4000-8000-00000000005a', producto_id, 2, precio_centavos FROM producto_cache WHERE producto_id = 4;
INSERT INTO cola_sync (solicitud_uuid, id_local) VALUES ('f2000000-0000-4000-8000-00000000005b', 'f2000000-0000-4000-8000-00000000005a');
COMMIT;

-- F2-6 · Una segunda solicitud PENDIENTE del mismo borrador: error del índice parcial ux_cola_una_pendiente.
INSERT INTO cola_sync (solicitud_uuid, id_local) VALUES ('f2000000-0000-4000-8000-00000000006b', 'f2000000-0000-4000-8000-00000000005a');
