-- REQ 5.1, 5.3, 6.7 a 6.10: Pruebas de esquema - COMMIT/ROLLBACK, C1, C7
-- Script que verifica que las transacciones funcionen correctamente y que las restricciones
-- del esquema (C7: cantidad 0, producto inexistente, tipo inválido en STRICT) funcionen como se espera.

-- --- Bloque ROLLBACK: todas las inserciones deben deshacerse ---
BEGIN TRANSACTION;
    INSERT INTO producto_cache (producto_id, nombre, precio_centavos, stock_visto, disponible_visto, eliminado, capturado_en)
        VALUES (999, 'test_rollback', 10000, 50, 1, 0, '2026-01-01T00:00:00Z');
    INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago, creado_en)
        VALUES ('00000000-0000-4000-8000-000000000001', 1, 'EFECTIVO', '2026-01-01T00:00:00Z');
    INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
        VALUES ('00000000-0000-4000-8000-000000000001', 999, 1, 10000);
    INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo, creada_en, evaluada_en)
        VALUES ('c9999999-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000001', 'PENDIENTE', NULL, '2026-01-01T00:00:00Z', NULL);
ROLLBACK;
-- Verificamos que no quedaron filas nuevas
SELECT 'Después ROLLBACK:' AS etapa,
       (SELECT COUNT(*) FROM producto_cache WHERE nombre = 'test_rollback') AS prod_en_cache,
       (SELECT COUNT(*) FROM pedido_borrador WHERE id_local = '00000000-0000-4000-8000-000000000001') AS borrador_en_pedido,
       (SELECT COUNT(*) FROM item_borrador WHERE id_local = '00000000-0000-4000-8000-000000000001') AS items_en_tabla,
       (SELECT COUNT(*) FROM cola_sync WHERE solicitud_uuid = 'c9999999-0000-4000-8000-000000000001') AS cola_en_tabla;

-- --- Prueba C1: catálogo disponible sin conexión ---
-- Con los datos de la instantánea cargada, v_catalogo_disponible debe devolver 13 productos
-- (16 productos totales menos 3, 15, 16 que están dados de baja o no disponibles)
SELECT 'C1 - v_catalogo_disponible:' AS etapa,
       COUNT(*) AS productos_en_catalogo
FROM v_catalogo_disponible;

-- --- Prueba C7: restricciones CHECK y FOREIGN KEY ---
-- 1) Insertar ítem con cantidad 0 debe fallar por CHECK
BEGIN TRANSACTION;
    INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
        VALUES ('00000000-0000-4000-8000-000000000002', 1, 0, 10000);
    SELECT 'C7 - ERROR: cantidad 0 debería haber sido rechazada' AS resultado;
    ROLLBACK;

-- 2) Insertar ítem con producto_id inexistente debe fallar por FOREIGN KEY
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;
    INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
        VALUES ('00000000-0000-4000-8000-000000000003', 9999, 1, 10000);
    SELECT 'C7 - ERROR: producto inexistente debería haber sido rechazado' AS resultado;
    ROLLBACK;

-- 3) Insertar valor de tipo incorrecto en columna INTEGER de tabla STRICT debe fallar
BEGIN TRANSACTION;
    INSERT INTO producto_cache (producto_id, nombre, precio_centavos, stock_visto, disponible_visto, eliminado, capturado_en)
        VALUES (999, 'test_tipo_invalido', 'no_es_numero', 50, 1, 0, '2026-01-01T00:00:00Z');
    SELECT 'C7 - ERROR: tipo de dato inválido debería haber sido rechazado' AS resultado;
    ROLLBACK;