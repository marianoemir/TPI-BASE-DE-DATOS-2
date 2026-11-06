-- REQ 5, 6.7-6.10, 1, 2, 3, 4, 7, 9, 10 | Casos C1 a C8 y F2-1 a F2-6
-- Reescrito a mano sobre la version de OpenCode (UUID de 36 caracteres, datos reales de
-- servidor_snapshot.csv, C6/F2-6 ejecutables, C7 con BEGIN...ROLLBACK).
-- Orden (base nueva, desde la carpeta de trabajo):
--   .read schema_sqlite.sql
--   .import --csv --skip 1 ..\movil\servidor_snapshot.csv snapshot_servidor
--   .read cargar_catalogo.sql
--   .read casos.sql          (este script ejecuta semaforo.sql dos veces)
-- Los "Error: ..." de C6, C7 y F2-6 son ESPERADOS: son los rechazos que se prueban.
PRAGMA foreign_keys = ON;

-- ============================================================ C1 (REQ 5)
-- NOTA: el REQ 5.3 dice 14, pero el CSV real oculta 3 productos (3 baja, 15 no disponible,
-- 16 ambos), asi que el valor correcto con este CSV es 13.
SELECT 'C1' AS caso, count(*) AS obtenido, 13 AS esperado,
       CASE WHEN count(*) = 13 THEN 'OK' ELSE 'FALLA' END AS resultado
FROM v_catalogo_disponible;
SELECT producto_id, nombre, precio FROM v_catalogo_disponible WHERE producto_id = 1;

-- ============================================================ C7 (REQ 6.7-6.10)
SELECT 'C7 antes' AS momento,
       (SELECT count(*) FROM pedido_borrador) AS borradores,
       (SELECT count(*) FROM item_borrador)   AS items,
       (SELECT count(*) FROM cola_sync)       AS cola;
BEGIN;
INSERT INTO pedido_borrador VALUES ('c7000000-0000-4000-8000-0000000000b1', 1, 'EFECTIVO', '2026-11-06 10:00:00');
-- 6.7: cantidad 0 -> debe fallar por CHECK
INSERT INTO item_borrador VALUES ('c7000000-0000-4000-8000-0000000000b1', 1, 0, 400000);
-- 6.8: producto inexistente en producto_cache -> debe fallar por FOREIGN KEY
INSERT INTO item_borrador VALUES ('c7000000-0000-4000-8000-0000000000b1', 9999, 1, 100);
-- 6.9: texto en columna INTEGER de tabla STRICT -> debe fallar
INSERT INTO producto_cache VALUES (500, 'x', 'no_numero', 1, 1, 0, '2026-11-06');
ROLLBACK;
SELECT 'C7 despues' AS momento,
       (SELECT count(*) FROM pedido_borrador) AS borradores,
       (SELECT count(*) FROM item_borrador)   AS items,
       (SELECT count(*) FROM cola_sync)       AS cola;

-- ============================================================ Preparacion de borradores
-- Producto 99: la tablet lo conocia pero ya no esta en la instantanea (para F2-2).
INSERT INTO producto_cache VALUES (99, 'Producto retirado', 100, 5, 1, 0, '2026-11-01 00:00:00');

-- Cada caso: borrador (b1), items y solicitud PENDIENTE (a1)
-- C2: precio visto 399999 vs servidor 400000 (producto 1, Muzzarella)
INSERT INTO pedido_borrador VALUES ('c2000000-0000-4000-8000-0000000000b1', 1, 'EFECTIVO', '2026-11-06 10:00:00');
INSERT INTO item_borrador   VALUES ('c2000000-0000-4000-8000-0000000000b1', 1, 2, 399999);
INSERT INTO cola_sync(solicitud_uuid, id_local) VALUES ('c2000000-0000-4000-8000-0000000000a1', 'c2000000-0000-4000-8000-0000000000b1');

-- C3: pedir 12 de Flan casero (stock 11)
INSERT INTO pedido_borrador VALUES ('c3000000-0000-4000-8000-0000000000b1', 1, 'TARJETA', '2026-11-06 10:00:00');
INSERT INTO item_borrador   VALUES ('c3000000-0000-4000-8000-0000000000b1', 10, 12, 150000);
INSERT INTO cola_sync(solicitud_uuid, id_local) VALUES ('c3000000-0000-4000-8000-0000000000a1', 'c3000000-0000-4000-8000-0000000000b1');

-- C3 (REQ 2.4): producto con stock 0 (14, Pizza especial)
INSERT INTO pedido_borrador VALUES ('c3000001-0000-4000-8000-0000000000b1', 1, 'TARJETA', '2026-11-06 10:00:00');
INSERT INTO item_borrador   VALUES ('c3000001-0000-4000-8000-0000000000b1', 14, 1, 500000);
INSERT INTO cola_sync(solicitud_uuid, id_local) VALUES ('c3000001-0000-4000-8000-0000000000a1', 'c3000001-0000-4000-8000-0000000000b1');

-- C4: producto dado de baja (3, Fugazzeta)
INSERT INTO pedido_borrador VALUES ('c4000000-0000-4000-8000-0000000000b1', 1, 'TRANSFERENCIA', '2026-11-06 10:00:00');
INSERT INTO item_borrador   VALUES ('c4000000-0000-4000-8000-0000000000b1', 3, 1, 450000);
INSERT INTO cola_sync(solicitud_uuid, id_local) VALUES ('c4000000-0000-4000-8000-0000000000a1', 'c4000000-0000-4000-8000-0000000000b1');

-- C5 control: 3 empanadas de carne, precio vigente
INSERT INTO pedido_borrador VALUES ('c5000000-0000-4000-8000-0000000000b1', 1, 'EFECTIVO', '2026-11-06 10:00:00');
INSERT INTO item_borrador   VALUES ('c5000000-0000-4000-8000-0000000000b1', 4, 3, 90000);
INSERT INTO cola_sync(solicitud_uuid, id_local) VALUES ('c5000000-0000-4000-8000-0000000000a1', 'c5000000-0000-4000-8000-0000000000b1');

-- C8: dos borradores piden 4 + 4 de Tiramisu (11), stock 6
INSERT INTO pedido_borrador VALUES ('c8000000-0000-4000-8000-0000000000b1', 1, 'EFECTIVO', '2026-11-06 10:00:00');
INSERT INTO item_borrador   VALUES ('c8000000-0000-4000-8000-0000000000b1', 11, 4, 220000);
INSERT INTO cola_sync(solicitud_uuid, id_local) VALUES ('c8000000-0000-4000-8000-0000000000a1', 'c8000000-0000-4000-8000-0000000000b1');
INSERT INTO pedido_borrador VALUES ('c8000000-0000-4000-8000-0000000000b2', 1, 'EFECTIVO', '2026-11-06 10:00:00');
INSERT INTO item_borrador   VALUES ('c8000000-0000-4000-8000-0000000000b2', 11, 4, 220000);
INSERT INTO cola_sync(solicitud_uuid, id_local) VALUES ('c8000000-0000-4000-8000-0000000000a2', 'c8000000-0000-4000-8000-0000000000b2');

-- F2-1: rojo (stock) y amarillo (precio) juntos -> RECHAZADO, sin mencionar el precio
INSERT INTO pedido_borrador VALUES ('f1000000-0000-4000-8000-0000000000b1', 1, 'EFECTIVO', '2026-11-06 10:00:00');
INSERT INTO item_borrador   VALUES ('f1000000-0000-4000-8000-0000000000b1', 1, 1, 399999);
INSERT INTO item_borrador   VALUES ('f1000000-0000-4000-8000-0000000000b1', 10, 12, 150000);
INSERT INTO cola_sync(solicitud_uuid, id_local) VALUES ('f1000000-0000-4000-8000-0000000000a1', 'f1000000-0000-4000-8000-0000000000b1');

-- F2-2: producto fuera de la instantanea (99)
INSERT INTO pedido_borrador VALUES ('f2000000-0000-4000-8000-0000000000b1', 1, 'TARJETA', '2026-11-06 10:00:00');
INSERT INTO item_borrador   VALUES ('f2000000-0000-4000-8000-0000000000b1', 99, 1, 100);
INSERT INTO cola_sync(solicitud_uuid, id_local) VALUES ('f2000000-0000-4000-8000-0000000000a1', 'f2000000-0000-4000-8000-0000000000b1');

-- F2-3: borrador sin items
INSERT INTO pedido_borrador VALUES ('f3000000-0000-4000-8000-0000000000b1', 1, 'EFECTIVO', '2026-11-06 10:00:00');
INSERT INTO cola_sync(solicitud_uuid, id_local) VALUES ('f3000000-0000-4000-8000-0000000000a1', 'f3000000-0000-4000-8000-0000000000b1');

-- F2-4: producto no disponible (15)
INSERT INTO pedido_borrador VALUES ('f4000000-0000-4000-8000-0000000000b1', 1, 'EFECTIVO', '2026-11-06 10:00:00');
INSERT INTO item_borrador   VALUES ('f4000000-0000-4000-8000-0000000000b1', 15, 1, 200000);
INSERT INTO cola_sync(solicitud_uuid, id_local) VALUES ('f4000000-0000-4000-8000-0000000000a1', 'f4000000-0000-4000-8000-0000000000b1');

-- F2-5: control, todo OK (Coca-Cola x2 a precio vigente)
INSERT INTO pedido_borrador VALUES ('f5000000-0000-4000-8000-0000000000b1', 1, 'EFECTIVO', '2026-11-06 10:00:00');
INSERT INTO item_borrador   VALUES ('f5000000-0000-4000-8000-0000000000b1', 7, 2, 120000);
INSERT INTO cola_sync(solicitud_uuid, id_local) VALUES ('f5000000-0000-4000-8000-0000000000a1', 'f5000000-0000-4000-8000-0000000000b1');

-- Resultados esperados (se cargan en una tabla temporal para comparar automaticamente)
CREATE TEMP TABLE esperado (caso TEXT, solicitud_uuid TEXT, estado TEXT, motivo TEXT);
INSERT INTO esperado VALUES
 ('C2',   'c2000000-0000-4000-8000-0000000000a1', 'CONFLICTO',         'Muzzarella: borrador 399999 centavos, servidor 400000 centavos'),
 ('C3',   'c3000000-0000-4000-8000-0000000000a1', 'RECHAZADO',         'Flan casero: pedido 12, stock 11'),
 ('C3-0', 'c3000001-0000-4000-8000-0000000000a1', 'RECHAZADO',         'Pizza especial (sin stock): pedido 1, stock 0'),
 ('C4',   'c4000000-0000-4000-8000-0000000000a1', 'RECHAZADO',         'Fugazzeta: dado de baja'),
 ('C5',   'c5000000-0000-4000-8000-0000000000a1', 'SIMULADO_APROBADO', NULL),
 ('C8-A', 'c8000000-0000-4000-8000-0000000000a1', 'SIMULADO_APROBADO', NULL),
 ('C8-B', 'c8000000-0000-4000-8000-0000000000a2', 'SIMULADO_APROBADO', NULL),
 ('F2-1', 'f1000000-0000-4000-8000-0000000000a1', 'RECHAZADO',         'Flan casero: pedido 12, stock 11'),
 ('F2-2', 'f2000000-0000-4000-8000-0000000000a1', 'RECHAZADO',         'producto 99 no existe en el servidor'),
 ('F2-3', 'f3000000-0000-4000-8000-0000000000a1', 'RECHAZADO',         'borrador sin ítems'),
 ('F2-4', 'f4000000-0000-4000-8000-0000000000a1', 'RECHAZADO',         'Producto temporalmente no disponible: no disponible'),
 ('F2-5', 'f5000000-0000-4000-8000-0000000000a1', 'SIMULADO_APROBADO', NULL);

-- ============================================================ Semaforo, 1.a ejecucion
.read semaforo.sql

SELECT e.caso, c.estado, c.motivo,
       CASE WHEN c.estado = e.estado AND c.motivo IS e.motivo THEN 'OK' ELSE 'FALLA' END AS resultado
FROM esperado e JOIN cola_sync c USING (solicitud_uuid)
ORDER BY e.caso;

-- C8 (REQ 10.3): el semaforo no toco stock_visto del Tiramisu (sigue 6)
SELECT 'C8 stock_visto' AS caso, stock_visto AS obtenido, 6 AS esperado,
       CASE WHEN stock_visto = 6 THEN 'OK' ELSE 'FALLA' END AS resultado
FROM producto_cache WHERE producto_id = 11;

-- ============================================================ F2-6 y reenvio tras CONFLICTO (REQ 7, 1.3)
-- El cliente confirma el nuevo precio: se corrige el item y se reenvia con UUID distinto.
UPDATE item_borrador SET precio_centavos_visto = 400000
 WHERE id_local = 'c2000000-0000-4000-8000-0000000000b1' AND producto_id = 1;
-- 7.2: la anterior ya no esta PENDIENTE, se permite una nueva
INSERT INTO cola_sync(solicitud_uuid, id_local) VALUES ('c2000000-0000-4000-8000-0000000000a2', 'c2000000-0000-4000-8000-0000000000b1');
-- 7.1: una segunda PENDIENTE del mismo borrador debe fallar (ux_cola_una_pendiente)
INSERT INTO cola_sync(solicitud_uuid, id_local) VALUES ('c2000000-0000-4000-8000-0000000000a3', 'c2000000-0000-4000-8000-0000000000b1');
SELECT 'F2-6 pendientes del borrador' AS caso, count(*) AS obtenido, 1 AS esperado,
       CASE WHEN count(*) = 1 THEN 'OK' ELSE 'FALLA' END AS resultado
FROM cola_sync WHERE id_local = 'c2000000-0000-4000-8000-0000000000b1' AND estado = 'PENDIENTE';

-- Guardar fila de C5 para comprobar C6
CREATE TEMP TABLE c5_antes AS
SELECT estado, motivo, evaluada_en FROM cola_sync WHERE solicitud_uuid = 'c5000000-0000-4000-8000-0000000000a1';

-- ============================================================ C6 (REQ 4): reenvio de UUID duplicado
-- 4.1: debe fallar por clave primaria
INSERT INTO cola_sync(solicitud_uuid, id_local, estado, motivo)
VALUES ('c5000000-0000-4000-8000-0000000000a1', 'c5000000-0000-4000-8000-0000000000b1', 'RECHAZADO', 'reenvio');

-- ============================================================ Semaforo, 2.a ejecucion
-- Solo evalua la nueva (a2): 1 solicitud. El resto ya no esta PENDIENTE (REQ 9.1).
.read semaforo.sql

SELECT 'C2 reenvio (a2)' AS caso, estado, motivo,
       CASE WHEN estado = 'SIMULADO_APROBADO' AND motivo IS NULL THEN 'OK' ELSE 'FALLA' END AS resultado
FROM cola_sync WHERE solicitud_uuid = 'c2000000-0000-4000-8000-0000000000a2';
SELECT 'C2 original (a1) sigue CONFLICTO' AS caso, estado,
       CASE WHEN estado = 'CONFLICTO' THEN 'OK' ELSE 'FALLA' END AS resultado
FROM cola_sync WHERE solicitud_uuid = 'c2000000-0000-4000-8000-0000000000a1';

-- C6 4.2: la fila original de C5 quedo intacta
SELECT 'C6 fila original intacta' AS caso,
       CASE WHEN c.estado IS a.estado AND c.motivo IS a.motivo AND c.evaluada_en IS a.evaluada_en
            THEN 'OK' ELSE 'FALLA' END AS resultado
FROM cola_sync c, c5_antes a WHERE c.solicitud_uuid = 'c5000000-0000-4000-8000-0000000000a1';

-- C6 4.3: 3.a ejecucion sin PENDIENTES -> solicitudes_evaluadas = 0
.read semaforo.sql
