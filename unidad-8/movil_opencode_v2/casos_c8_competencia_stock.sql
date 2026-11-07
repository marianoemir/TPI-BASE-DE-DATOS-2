-- REQ 10.1 a 10.6: Caso C8 — Dos borradores compiten por el mismo stock
-- Borradores A y B piden 4 unidades cada uno del producto 11 (Tiramisú, stock 6 en la instantánea)
-- Cada uno evaluado por separado pasa (4 ≤ 6), juntos piden 8 > 6
-- El semáforo evalúa cada solicitud de forma independiente → ambos queden SIMULADO_APROBADO
-- El sistema NO suma cantidades entre solicitudes distintas
-- stock_visto en producto_cache y stock de PostgreSQL sin cambios
-- La resolución real corresponde solo al servidor, con sp_crear_pedido y SELECT FOR UPDATE

-- --- Preparación de datos: producto 11 (Tiramisú) en producto_cache ---
-- El producto 11 ya debería estar en producto_cache desde la carga del catálogo
-- Con stock_visto = 6 (o el valor de la instantánea actual) y disponible_visto = 1

-- --- Borrador A: pide 4 unidades ---
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago, creado_en)
    VALUES ('c8000000-0000-4000-8000-00000000000a', 1, 'EFECTIVO', '2026-11-03T08:00:00Z');

INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
    VALUES ('c8000000-0000-4000-8000-00000000000a', 11, 4, 220000);

INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo, creada_en, evaluada_en)
    VALUES ('c8000000-0000-4000-8000-00000000000a', 'c8000000-0000-4000-8000-00000000000a', 'PENDIENTE', NULL, '2026-11-03T08:00:00Z', NULL);

-- --- Borrador B: pide 4 unidades (distinto UUID, mismo producto) ---
INSERT INTO pedido_borrador (id_local, usuario_id_servidor, forma_pago, creado_en)
    VALUES ('c8000000-0000-4000-8000-00000000000b', 1, 'TARJETA', '2026-11-03T08:00:00Z');

INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
    VALUES ('c8000000-0000-4000-8000-00000000000b', 11, 4, 220000);

INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo, creada_en, evaluada_en)
    VALUES ('c8000000-0000-4000-8000-00000000000b', 'c8000000-0000-4000-8000-00000000000b', 'PENDIENTE', NULL, '2026-11-03T08:00:00Z', NULL);

-- --- Ejecutar semáforo.sql ---
-- Se evalúa cada solicitud de forma independiente contra la instantánea
-- Resultado esperado:
--   - Solicitud A (c8000000-...0a): SIMULADO_APROBADO, motivo NULL
--   - Solicitud B (c8000000-...0b): SIMULADO_APROBADO, motivo NULL
--   - solicitudes_evaluadas = 2 (ambas pasaron de PENDIENTE a otro estado)
--   - producto_cache.stock_visto sin cambios (sigue siendo 6)
--   - snapshot_servidor stock sin cambios

-- --- Verificación de resultados ---
SELECT '--- Resultados después de semáforo C8 ---' AS etapa,
       s1.solicitud_uuid, s1.estado AS estado_a, s1.motivo AS motivo_a,
       s2.estado AS estado_b, s2.motivo AS motivo_b,
       changes() AS solicitudes_evaluadas;

-- Verificar que stock_visto no cambió en producto_cache
SELECT 'stock_visto producto 11 después de semáforo:' AS etiqueta,
       stock_visto
FROM producto_cache
WHERE producto_id = 11;