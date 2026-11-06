-- ============================================================
-- FOOD STORE · TP8 · pruebas_sqlite.sql   (consigna 1.c)
-- Correr DESPUÉS de schema_sqlite.sql y cargar_catalogo.sql:
--     sqlite3 -header -column movil/foodstore_movil.db ".read movil/pruebas_sqlite.sql"
-- Los errores esperados aparecen en pantalla y el script sigue (comportamiento
-- normal del CLI). En DBeaver, elegir "ignorar" cuando pregunte por un error.
-- ============================================================
PRAGMA foreign_keys = ON;

-- 0 · Entorno
SELECT sqlite_version() AS version_sqlite;          -- debe ser >= 3.37
PRAGMA foreign_keys;                                -- debe dar 1
PRAGMA integrity_check;                             -- debe dar ok

-- ------------------------------------------------------------
-- 1.a · Un borrador completo (borrador + ítems + solicitud) con BEGIN ... COMMIT
-- Ana (usuario 1) pide 2 Coca-Cola ($1.200) y 1 Agua ($700), en efectivo.
-- ------------------------------------------------------------
BEGIN;
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago)
VALUES ('a0000000-0000-4000-8000-00000000000a', 1, 'EFECTIVO');

INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES ('a0000000-0000-4000-8000-00000000000a', 7, 2, 120000),
       ('a0000000-0000-4000-8000-00000000000a', 8, 1,  70000);

INSERT INTO cola_sync (solicitud_uuid, id_local)
VALUES ('a0000000-0000-4000-8000-00000000000b', 'a0000000-0000-4000-8000-00000000000a');
COMMIT;

SELECT 'tras COMMIT' AS momento,
       (SELECT count(*) FROM pedido_borrador) AS borradores,
       (SELECT count(*) FROM item_borrador)   AS items,
       (SELECT count(*) FROM cola_sync)       AS solicitudes;

-- ------------------------------------------------------------
-- 1.b · Otra operación, deshecha con ROLLBACK: no deja nada
-- ------------------------------------------------------------
BEGIN;
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago)
VALUES ('a1000000-0000-4000-8000-00000000000a', 2, 'TARJETA');
INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES ('a1000000-0000-4000-8000-00000000000a', 1, 1, 350000);
INSERT INTO cola_sync (solicitud_uuid, id_local)
VALUES ('a1000000-0000-4000-8000-00000000000b', 'a1000000-0000-4000-8000-00000000000a');

SELECT 'dentro, antes del ROLLBACK' AS momento,
       (SELECT count(*) FROM pedido_borrador) AS borradores,
       (SELECT count(*) FROM item_borrador)   AS items,
       (SELECT count(*) FROM cola_sync)       AS solicitudes;
ROLLBACK;

SELECT 'tras ROLLBACK' AS momento,
       (SELECT count(*) FROM pedido_borrador) AS borradores,
       (SELECT count(*) FROM item_borrador)   AS items,
       (SELECT count(*) FROM cola_sync)       AS solicitudes;

-- ------------------------------------------------------------
-- C1 · Catálogo disponible SIN conexión al servidor
-- Esta consulta solo toca el archivo foodstore_movil.db: PostgreSQL puede estar
-- apagado. No aparecen el producto 15 (no disponible) ni el 16 (dado de baja).
-- ------------------------------------------------------------
SELECT * FROM v_catalogo_disponible ORDER BY producto_id;

-- ------------------------------------------------------------
-- C7 · Datos inválidos: dan error y no dejan filas nuevas
-- ------------------------------------------------------------
SELECT 'antes de C7' AS momento,
       (SELECT count(*) FROM pedido_borrador) AS borradores,
       (SELECT count(*) FROM item_borrador)   AS items;

-- C7.a · cantidad en 0  -> Error: CHECK constraint failed: cantidad > 0
BEGIN;
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago)
VALUES ('a7000000-0000-4000-8000-00000000000a', 1, 'EFECTIVO');
INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES ('a7000000-0000-4000-8000-00000000000a', 7, 0, 120000);
ROLLBACK;

-- C7.b · producto inexistente -> Error: FOREIGN KEY constraint failed
BEGIN;
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago)
VALUES ('a7000000-0000-4000-8000-00000000000c', 1, 'EFECTIVO');
INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES ('a7000000-0000-4000-8000-00000000000c', 999, 1, 100000);
ROLLBACK;

-- C7.c · (extra) texto en una columna entera -> Error: cannot store TEXT value in INTEGER column
--        Esto lo controla STRICT; en una tabla común se guardaría el texto.
BEGIN;
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago)
VALUES ('a7000000-0000-4000-8000-00000000000d', 1, 'EFECTIVO');
INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES ('a7000000-0000-4000-8000-00000000000d', 7, 'diez', 120000);
ROLLBACK;

SELECT 'después de C7' AS momento,
       (SELECT count(*) FROM pedido_borrador) AS borradores,
       (SELECT count(*) FROM item_borrador)   AS items;   -- los mismos números que antes
