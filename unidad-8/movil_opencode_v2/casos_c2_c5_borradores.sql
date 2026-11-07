-- REQ 1, 2, 3: Casos C2 a C5 — Creación de borradores y encolado en cola_sync
-- Orden de ejecución: después de schema y carga del catálogo
-- C2: conflicto de precio (detectado después de cambiar precio en PostgreSQL y recargar snapshot)
-- C3: stock insuficiente (cantidad pedida > stock en instantánea)
-- C4: producto dado de baja/inexistente/no disponible
-- C5: control — sin diferencias, debería ser SIMULADO_APROBADO

-- --- C2: producto 1 (Muzzarella) con precio del borrador igual a la instantánea 1 ---
--    UUID: c2000000-0000-4000-8000-00000000000b
--    Después de cambiar precio en PostgreSQL y recargar snapshot, el semáforo
--    detectará CONFLICTO por diferencia de precio.
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago, creado_en)
    VALUES ('c2000000-0000-4000-8000-00000000000b', 1, 'EFECTIVO', '2026-11-03T08:00:00Z');

INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
    VALUES ('c2000000-0000-4000-8000-00000000000b', 1, 1, 400000);

INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo, creada_en, evaluada_en)
    VALUES ('c2000000-0000-4000-8000-00000000000b', 'c2000000-0000-4000-8000-00000000000b', 'PENDIENTE', NULL, '2026-11-03T08:00:00Z', NULL);

-- --- C3: producto 11 (Tiramisú) cantidad 7, stock en instantánea es 6 ---
--    UUID: c3000000-0000-4000-8000-00000000000b
--    Solicitud de 7 unidades cuando el stock es 6 → RECHAZADO por stock insuficiente
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago, creado_en)
    VALUES ('c3000000-0000-4000-8000-00000000000b', 1, 'TARJETA', '2026-11-03T08:00:00Z');

INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
    VALUES ('c3000000-0000-4000-8000-00000000000b', 11, 7, 220000);

INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo, creada_en, evaluada_en)
    VALUES ('c3000000-0000-4000-8000-00000000000b', 'c3000000-0000-4000-8000-00000000000b', 'PENDIENTE', NULL, '2026-11-03T08:00:00Z', NULL);

-- --- C4: producto 3 (Fugazzeta), estado eliminado = t en la instantánea ---
--    UUID: c4000000-0000-4000-8000-00000000000b
--    El producto Fugazzeta tiene eliminado = 't' en el servidor → RECHAZADO por dado de baja
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago, creado_en)
    VALUES ('c4000000-0000-4000-8000-00000000000b', 1, 'EFECTIVO', '2026-11-03T08:00:00Z');

INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
    VALUES ('c4000000-0000-4000-8000-00000000000b', 3, 1, 450000);

INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo, creada_en, evaluada_en)
    VALUES ('c4000000-0000-4000-8000-00000000000b', 'c4000000-0000-4000-8000-00000000000b', 'PENDIENTE', NULL, '2026-11-03T08:00:00Z', NULL);

-- --- C5: control — producto 2 (Napolitana), precio y stock coinciden ---
--    UUID: c5000000-0000-4000-8000-00000000000b
--    Sin diferencias entre borrador y instantánea → SIMULADO_APROBADO
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago, creado_en)
    VALUES ('c5000000-0000-4000-8000-00000000000b', 1, 'TRANSFERENCIA', '2026-11-03T08:00:00Z');

INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
    VALUES ('c5000000-0000-4000-8000-00000000000b', 2, 1, 420000);

INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo, creada_en, evaluada_en)
    VALUES ('c5000000-0000-4000-8000-00000000000b', 'c5000000-0000-4000-8000-00000000000b', 'PENDIENTE', NULL, '2026-11-03T08:00:00Z', NULL);