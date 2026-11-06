-- REQ 5.1, 5.2, 5.3, 6.7-6.10, 1, 2, 3, 7, 9.1-9.7, 10.1-10.6
-- Script de casos de prueba: C1 a C8 y F2-1 a F2-6
-- Ejecutar después de schema_sqlite.sql y cargar_catalogo.sql
PRAGMA foreign_keys = ON;

-- ============================================================
-- DATA INIT: 16 productos de la instantánea 1 (estado inicial)
-- Productos 1-10: activos y disponibles
-- Producto 11: Tiramisú, stock 6 (caso C8)
-- Producto 12: Leche, disponible = 'f' (caso F2-4)
-- Productos 13-14: dados de baja (caso C4)
-- Productos 15-16: control (C5/F2-5)
-- ============================================================
-- Note: snapshot_servidor ya debería estar cargado desde schema.sql
-- Si la base está nueva, descomentar la siguiente línea:
-- INSERT OR REPLACE INTO snapshot_servidor (producto_id, nombre, precio_centavos, stock, disponible, eliminado, capturado_en) VALUES
--(1, 'Empanada', 1200, 10, 't', 'f', '2026-11-06'),
--(2, 'Factura', 850, 5, 't', 'f', '2026-11-06'),
--(3, 'Torta', 1500, 8, 't', 'f', '2026-11-06'),
--(4, 'Pan', 300, 20, 't', 'f', '2026-11-06'),
--(5, ' medialuna', 400, 15, 't', 'f', '2026-11-06'),
--(6, 'Croissant', 600, 7, 't', 'f', '2026-11-06'),
--(7, 'Bizcocho', 900, 3, 't', 'f', '2026-11-06'),
--(8, 'Cucharon', 250, 25, 't', 'f', '2026-11-06'),
--(9, 'Taza', 350, 12, 't', 'f', '2026-11-06'),
--(10, 'Plato', 500, 18, 't', 'f', '2026-11-06'),
--(11, 'Tiramisú', 2200, 6, 't', 'f', '2026-11-06'),
--(12, 'Leche', 1000, 10, 'f', 'f', '2026-11-06'),
--(13, 'Alfajor', 750, 4, 't', 't', '2026-11-06'),
--(14, 'Dulce de leche', 900, 3, 't', 't', '2026-11-06'),
--(15, 'Muffin', 350, 8, 't', 'f', '2026-11-06'),
--(16, 'Galletita', 200, 15, 't', 'f', '2026-11-06');

-- ============================================================
-- C1: Catálogo disponible sin conexión
-- Esperado: v_catalogo_disponible devuelve 14 productos
-- (16 totales - productos 13, 14 (eliminado) - producto 12 (no disponible))
-- ============================================================
SELECT '--- C1: Catálogo disponible ---' AS label;
SELECT count(*) AS productos_disponibles FROM v_catalogo_disponible;
-- Esperado: 14

-- ============================================================
-- C7: Validaciones del esquema (CHECK, FK, STRICT)
-- ============================================================

-- Prueba 1: INSERT de ítem con cantidad 0 → debe fallar CHECK
-- (Ejecutar este INSERT y verificar error de constraint; luego hacer rollback)
-- INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
-- VALUES ('c7item001-0000-4000-8000-00000000001', 1, 0, 100);
-- Expected: CHECK constraint failed, no rows inserted

-- Si la anterior no falla (modo sin STRICT estricto), hacer rollback:
ROLLBACK;

-- Prueba 2: INSERT de ítem con producto_id inexistente → debe fallar FK
-- (Ejecutar este INSERT y verificar error de constraint FK; luego hacer rollback)
-- INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
-- VALUES ('c7item002-0000-4000-8000-00000000002', 999, 1, 100);
-- Expected: FK constraint failed, no rows inserted

-- ROLLBACK;

-- Prueba 3: INSERT con tipo inválido en columna STRICT de producto_cache
-- (Ejecutar este INSERT y verificar error de STRICT table; luego hacer rollback)
-- INSERT INTO producto_cache (producto_id, nombre, precio_centavos, stock_visto, disponible_visto, eliminado, capturado_en)
-- VALUES ('no_entero', 'Test', 'no_es_numero', 10, 1, 0, '2026-11-06');
-- Expected: STRICT table rejects: expected error

-- ROLLBACK;

-- ============================================================
-- C2: Precio visto difiere del servidor → CONFLICTO
-- Usando producto 1 con precio visto artificialmente distinto
-- ============================================================
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago, creado_en)
VALUES ('c2000000-0000-4000-8000-00000000000b', 1, 'EFECTIVO', '2026-11-06');

INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES ('c2000000-0000-4000-8000-00000000000b', 1, 2, 1500); -- visto 1500, servidor 1200

INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo, creada_en)
VALUES ('c2000000-0000-4000-8000-00000000000b', 'c2000000-0000-4000-8000-00000000000b', 'PENDIENTE', NULL, '2026-11-06');

-- ============================================================
-- C3: Cantidad mayor que stock → RECHAZADO
-- Producto 2: stock 5 en la instantánea, pedir 8
-- ============================================================
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago, creado_en)
VALUES ('c3000000-0000-4000-8000-00000000000b', 1, 'TARJETA', '2026-11-06');

INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES ('c3000000-0000-4000-8000-00000000000b', 2, 8, 850);

INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo, creada_en)
VALUES ('c3000000-0000-4000-8000-00000000000b', 'c3000000-0000-4000-8000-00000000000b', 'PENDIENTE', NULL, '2026-11-06');

-- ============================================================
-- C4: Producto dado de baja → RECHAZADO
-- Producto 13: Alfajor, eliminado = 't' en la instantánea
-- ============================================================
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago, creado_en)
VALUES ('c4000000-0000-4000-8000-00000000000b', 1, 'TRANSFERENCIA', '2026-11-06');

INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES ('c4000000-0000-4000-8000-00000000000b', 13, 1, 750);

INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo, creada_en)
VALUES ('c4000000-0000-4000-8000-00000000000b', 'c4000000-0000-4000-8000-00000000000b', 'PENDIENTE', NULL, '2026-11-06');

-- ============================================================
-- C5: Control, sin diferencias → SIMULADO_APROBADO
-- Producto 4: Pan, stock 20, cantidad 3, precio igual
-- ============================================================
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago, creado_en)
VALUES ('c5000000-0000-4000-8000-00000000000b', 1, 'EFECTIVO', '2026-11-06');

INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES ('c5000000-0000-4000-8000-00000000000b', 4, 3, 300);

INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo, creada_en)
VALUES ('c5000000-0000-4000-8000-00000000000b', 'c5000000-0000-4000-8000-00000000000b', 'PENDIENTE', NULL, '2026-11-06');

-- ============================================================
-- C8: Dos borradores compiten por el mismo stock
-- Producto 11 (Tiramisú): stock 6, pedir 4 + pedir 4
-- Cada uno evaluado por separado da SIMULADO_APROBADO
-- ============================================================
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago, creado_en)
VALUES ('c8000000-0000-4000-8000-00000000000a', 1, 'EFECTIVO', '2026-11-06');

INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES ('c8000000-0000-4000-8000-00000000000a', 11, 4, 2200);

INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo, creada_en)
VALUES ('c8000000-0000-4000-8000-00000000000a', 'c8000000-0000-4000-8000-00000000000a', 'PENDIENTE', NULL, '2026-11-06');

INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago, creado_en)
VALUES ('c8000000-0000-4000-8000-00000000000b', 1, 'EFECTIVO', '2026-11-06');

INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES ('c8000000-0000-4000-8000-00000000000b', 11, 4, 2200);

INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo, creada_en)
VALUES ('c8000000-0000-4000-8000-00000000000b', 'c8000000-0000-4000-8000-00000000000b', 'PENDIENTE', NULL, '2026-11-06');

-- F2-6: Dos solicitudes PENDIENTE del mismo borrador fallan por ux_cola_una_pendiente
-- (Esto se probaría intentando un INSERT duplicado de id_local con estado PENDIENTE)
-- INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo, creada_en)
-- VALUES ('dup0000k-0000-4000-8000-00000000000b', 'c8000000-0000-4000-8000-00000000000a', 'PENDIENTE', NULL, '2026-11-06');
-- Expected: UNIQUE constraint failed en el índice parcial ux_cola_una_pendiente

-- ============================================================
-- F2: Casos borde del semáforo
-- ============================================================

-- F2-1: Rojo y amarillo juntos → RECHAZADO (rojo gana)
-- Un ítem con conflicto de precio Y otro ítem con stock insuficiente en la misma solicitud
-- Insertar una nueva solicitud con un ítem que tenga conflicto de precio Y otro ítem que exceda stock
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago, creado_en)
VALUES ('f2000001-0000-4000-8000-00000000001', 1, 'EFECTIVO', '2026-11-06');

INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES ('f2000001-0000-4000-8000-00000000001', 1, 2, 1500); -- producto 1: conflicto de precio (1500 vs 1200)

INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES ('f2000001-0000-4000-8000-00000000001', 2, 8, 850); -- producto 2: stock insuficiente (8 > 5)

-- Cada borrador necesita su propia entrada en cola_sync, pero F2-1 prueba un solo borrador
-- con múltiples ítems que desencadenan ambas condiciones. Como hay rojo (stock insuficiente),
-- el resultado debe ser RECHAZADO a pesar de tener también conflicto (amarillo).
-- Nota: El índice parcial ux_cola_una_pendiente permite esto porque solo restringe dos PENDIENTE
-- para el MISMO id_local. Podemos usar un UUID distinto para probar, o encolar solo una vez.
-- Para F2-1, probaremos con un solo UUID y múltiples ítems en el mismo borrador.
-- Pero item_borrador con misma PK (id_local, producto_id) solo puede tener una fila por producto.
-- Para probar F2-1 realmente, necesitamos dos ítems distintos en el mismo borrador con diferentes productos.
-- El diseño permite múltiplos ítems por borrador (misma PK pero distinto producto_id).

-- F2-2: Producto fuera de la instantánea → rojo con "producto N no existe en el servidor"
-- Referenciar un producto_id que NO existe en snapshot_servidor en absoluto
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago, creado_en)
VALUES ('f2000002-0000-4000-8000-00000000002', 1, 'TARJETA', '2026-11-06');

INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES ('f2000002-0000-4000-8000-00000000002', 9999, 1, 100); -- producto 9999 no existe en la instantánea

INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo, creada_en)
VALUES ('f2000002-0000-4000-8000-00000000002', 'f2000002-0000-4000-8000-00000000002', 'PENDIENTE', NULL, '2026-11-06');

-- F2-3: Borrador sin ítems → RECHAZADO con motivo "borrador sin ítems"
-- Solicitud en cola_sync sin ítems asociados en item_borrador para ese id_local
-- El LEFT JOIN i.producto_id produce NULL al no haber filas en item_borrador
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago, creado_en)
VALUES ('f2000003-0000-4000-8000-00000000003', 1, 'EFECTIVO', '2026-11-06');
-- INTENTENAMENTE sin INSERTAR filas en item_borrador para este id_local

INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo, creada_en)
VALUES ('f2000003-0000-4000-8000-00000000003', 'f2000003-0000-4000-8000-00000000003', 'PENDIENTE', NULL, '2026-11-06');

-- F2-4: disponible = 'f' → RECHAZADO con "no disponible"
-- Producto 12 (Leche) ya está cargado con disponible = 'f' en la instantánea
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago, creado_en)
VALUES ('f2000004-0000-4000-8000-00000000004', 1, 'EFECTIVO', '2026-11-06');

INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES ('f2000004-0000-4000-8000-00000000004', 12, 1, 1000); -- producto Leche, disponible_visto debería ser 0

INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo, creada_en)
VALUES ('f2000004-0000-4000-8000-00000000004', 'f2000004-0000-4000-8000-00000000004', 'PENDIENTE', NULL, '2026-11-06');

-- F2-5: Control SIMULADO_APROBADO (todos los ítems OK)
-- Ya probado con C5, pero podemos agregar una solicitud adicional de control
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago, creado_en)
VALUES ('f2000005-0000-4000-8000-00000000005', 1, 'EFECTIVO', '2026-11-06');

INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES ('f2000005-0000-4000-8000-00000000005', 4, 3, 300); -- Producto Pan, stock 20, precio OK

INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo, creada_en)
VALUES ('f2000005-0000-4000-8000-00000000005', 'f2000005-0000-4000-8000-00000000005', 'PENDIENTE', NULL, '2026-11-06');

-- ============================================================
-- Ejecutar semáforo
-- ============================================================
-- Ejecutar: . semaforo.sql
-- Esto evaluará todas las solicitudes PENDIENTE y actualizará sus estados.

-- ============================================================
-- Verificar resultados DESPUÉS de ejecutar semáforo
-- ============================================================

-- C2: Debería ser CONFLICTO (precio visto 1500 vs servidor 1200)
SELECT '--- C2 resultado ---' AS label;
SELECT solicitud_uuid, estado, motivo FROM cola_sync WHERE solicitud_uuid = 'c2000000-0000-4000-8000-00000000000b';
-- Esperado: CONFLICTO, motivo incluye nombre del producto y precios

-- C3: Debería ser RECHAZADO por stock insuficiente
SELECT '--- C3 resultado ---' AS label;
SELECT solicitud_uuid, estado, motivo FROM cola_sync WHERE solicitud_uuid = 'c3000000-0000-4000-8000-00000000000b';
-- Esperado: RECHAZADO, motivo: producto Factura: pedido 8, stock 5

-- C4: Debería ser RECHAZADO por producto dado de baja
SELECT '--- C4 resultado ---' AS label;
SELECT solicitud_uuid, estado, motivo FROM cola_sync WHERE solicitud_uuid = 'c4000000-0000-4000-8000-00000000000b';
-- Esperado: RECHAZADO, motivo: producto Alfajor: dado de baja

-- C5: Debería ser SIMULADO_APROBADO
SELECT '--- C5 resultado ---' AS label;
SELECT solicitud_uuid, estado, motivo FROM cola_sync WHERE solicitud_uuid = 'c5000000-0000-4000-8000-00000000000b';
-- Esperado: SIMULADO_APROBADO, motivo NULL

-- C8: Ambas solicitudes deberían ser SIMULADO_APROBADO (evaluadas independently)
SELECT '--- C8 resultado ---' AS label;
SELECT solicitud_uuid, estado, motivo FROM cola_sync WHERE solicitud_uuid IN ('c8000000-0000-4000-8000-00000000000a', 'c8000000-0000-4000-8000-00000000000b');
-- Esperado: ambas SIMULADO_APROBADO, motivo NULL
-- Nota: el stock_visto en producto_cache no debe cambiar

-- F2-1 a F2-5: Verificar estados después del semáforo
-- Estos serían verificados después de correr semaforo.sql con diferentes escenarios