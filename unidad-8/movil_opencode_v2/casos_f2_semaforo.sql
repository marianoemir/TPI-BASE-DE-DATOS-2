-- REQ 9.2 a 9.6: Casos borde F2-1 a F2-6 — Reglas de prioridad del semáforo
-- F2-1: rojo + amarillo juntos → RECHAZADO (rojo gana)
-- F2-2: producto fuera de la instantánea → rojo con "producto N no existe en el servidor"
-- F2-3: borrador sin ítems → RECHAZADO con motivo "borrador sin ítems"
-- F2-4: disponible = 'f' → RECHAZADO con causa "no disponible"
-- F2-5: control — todos OK → SIMULADO_APROBADO
-- F2-6: impedir dos solicitudes PENDIENTE para el mismo borrador (índice parcial ux_cola_una_pendiente)

-- --- Preparación de datos de prueba ---
-- Suponemos que ya existen: producto_cache, pedido_borrador, item_borrador, cola_sync, snapshot_servidor

-- F2-1: Solicitud con condición roja y amarilla combinadas
-- Usamos producto 3 (Fugazzeta), que está eliminado (rojo) y precio que diferencia del visto (amarillo)
-- El rojo gana → resultado RECHAZADO, motivo solo incluye fragmentos rojos

-- Primero, asegurémonos de que el producto 3 esté en producto_cache con eliminado = 1
-- (ya debería estarlo después de la recarga con lápida en la secuencia de ejecución)
-- Y créemos un borrador con precio_centavos_visto distinto al de la instantánea

-- F2-1: producto 3 eliminado + conflicto de precio → RECHAZADO (solo motivo rojo)
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago, creado_en)
    VALUES ('f2000001-0000-4000-8000-00000000000b', 1, 'EFECTIVO', '2026-11-03T08:00:00Z');

INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
    VALUES ('f2000001-0000-4000-8000-00000000000b', 3, 1, 500000); -- precio distinto al de la sombra

INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo, creada_en, evaluada_en)
    VALUES ('f2000001-0000-4000-8000-00000000000b', 'f2000001-0000-4000-8000-00000000000b', 'PENDIENTE', NULL, '2026-11-03T08:00:00Z', NULL);

-- F2-2: Producto que no aparece en la instantánea (NULL del LEFT JOIN debe ser rojo, no verde)
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago, creado_en)
    VALUES ('f2000002-0000-4000-8000-00000000000b', 1, 'TARJETA', '2026-11-03T08:00:00Z');

INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
    VALUES ('f2000002-0000-4000-8000-00000000000b', 9999, 1, 100000); -- producto_id que no está en snapshot

INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo, creada_en, evaluada_en)
    VALUES ('f2000002-0000-4000-8000-00000000000b', 'f2000002-0000-4000-8000-00000000000b', 'PENDIENTE', NULL, '2026-11-03T08:00:00Z', NULL);

-- F2-3: Borrador sin ítems (no hay fila en item_borrador para este id_local)
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago, creado_en)
    VALUES ('f2000003-0000-4000-8000-00000000000b', 1, 'EFECTIVO', '2026-11-03T08:00:00Z');

-- NOTA: no inserto item_borrador para este pedido, simulando un borrador vacío

INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo, creada_en, evaluada_en)
    VALUES ('f2000003-0000-4000-8000-00000000000b', 'f2000003-0000-4000-8000-00000000000b', 'PENDIENTE', NULL, '2026-11-03T08:00:00Z', NULL);

-- F2-4: Producto con disponible = 'f' en la instantánea → RECHAZADO con "no disponible"
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago, creado_en)
    VALUES ('f2000004-0000-4000-8000-00000000000b', 1, 'TRANSFERENCIA', '2026-11-03T08:00:00Z');

-- Producto 15 (Jugo de naranja 500ml) tiene disponible = 'f' en el CSV original
INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
    VALUES ('f2000004-0000-4000-8000-00000000000b', 15, 1, 100000);

INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo, creada_en, evaluada_en)
    VALUES ('f2000004-0000-4000-8000-00000000000b', 'f2000004-0000-4000-8000-00000000000b', 'PENDIENTE', NULL, '2026-11-03T08:00:00Z', NULL);

-- F2-5: Control — todos los ítems coinciden en precio, hay stock y productos activos/disponibles → SIMULADO_APROBADO
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago, creado_en)
    VALUES ('f2000005-0000-4000-8000-00000000000b', 1, 'EFECTIVO', '2026-11-03T08:00:00Z');

-- Producto 2 (Napolitana) está disponible, stock suficiente, precio coincide
INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
    VALUES ('f2000005-0000-4000-8000-00000000000b', 2, 1, 420000);

INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo, creada_en, evaluada_en)
    VALUES ('f2000005-0000-4000-8000-00000000000b', 'f2000005-0000-4000-8000-00000000000b', 'PENDIENTE', NULL, '2026-11-03T08:00:00Z', NULL);

-- F2-6: Intentar insertar segunda solicitud PENDIENTE para el mismo borrador → falla por ux_cola_una_pendiente
-- Primer, insertamos una solicitud PENDIENTE para este borrador
INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo, creada_en, evaluada_en)
    VALUES ('f2000006-0000-4000-8000-00000000000b', 'f2000006-0000-4000-8000-00000000000b', 'PENDIENTE', NULL, '2026-11-03T08:00:00Z', NULL);

-- Ahora intentamos insertar otra solicitud PENDIENTE para el mismo id_local
-- Esto debería fallar con UNIQUE constraint failed en el índice parcial
BEGIN TRY;
    INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo, criada_en, evaluada_en)
        VALUES ('f2000007-0000-4000-8000-00000000000b', 'f2000006-0000-4000-8000-00000000000b', 'PENDIENTE', NULL, '2026-11-03T08:00:00Z', NULL);
    SELECT 'ERROR: segunda PENDIENTE para mismo borrador debería haber sido rechazada' AS resultado;
END TRY;
BEGIN CATCH;
    SELECT 'C2-6 - OK: segunda PENDIENTE correctamente bloqueada por índice parcial' AS resultado;
END CATCH;

-- Verificar el estado actual de las solicitudes F2
SELECT '--- Estados de solicitudes F2 despues de semáforo ---' AS etiqueta,
       solicitud_uuid, id_local, estado, motivo
FROM cola_sync
WHERE solicitud_uuid LIKE 'f200000%';