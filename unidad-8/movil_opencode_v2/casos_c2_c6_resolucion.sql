-- REQ 1.3, 4.1, 4.2, 4.4, 7.2: Resolución de C2 y control de duplicados C6
-- Después de ejecutar semáforo.sql (primera corrida), C2 → CONFLICTO, C3 → RECHAZADO, C4 → RECHAZADO, C5 → SIMULADO_APROBADO
-- Luego: reenviar C2 con UUID nuevo, probar C6 (UUID duplicado), y nueva corrida de semáforo

-- --- 1. Reenviar C2 con UUID distinto (la solicitud anterior ya no está PENDIENTE, ya es CONFLICTO) ---
--    El índice parcial ux_cola_una_pendiente permite este nuevo INSERT porque la anterior
--    solicitud PENDIENTE ya no existe (ya es CONFLICTO).
INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo, creada_en, evaluada_en)
    VALUES ('c2000000-0000-4000-8000-00000000000c', 'c2000000-0000-4000-8000-00000000000b', 'PENDIENTE', NULL, '2026-11-03T08:05:00Z', NULL);

-- --- 2. Probar C6: intentar insertar UUID duplicado c5000000-0000-4000-8000-00000000000b ---
--    Ya está registrado desde el paso inicial. Debe fallar con UNIQUE constraint failed
--    y la fila original debe conservar su estado, motivo y evaluada_en sin modificaciones.
BEGIN TRANSACTION;
    INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo, criada_en, evaluada_en)
        VALUES ('c5000000-0000-4000-8000-00000000000b', 'c5000000-0000-4000-8000-00000000000b', 'PENDIENTE', 'test_duplicado', '2026-11-03T08:05:00Z', NULL);
    SELECT 'ERROR: INSERT duplicado debería haber fallado' AS resultado;
    ROLLBACK;
-- Verificamos que la fila original conserve su estado después del intento fallido
SELECT 'C6 - estado fila original después de intento fallido:' AS etapa,
       estado, motivo, evaluada_en
FROM cola_sync
WHERE solicitud_uuid = 'c5000000-0000-4000-8000-00000000000b';

-- --- 3. Nueva corrida del semáforo: solo debe evaluar la solicitud nueva (000c) ---
--    Las solicitudes ya evaluadas (000b = CONFLICTO, 000c = PENDIENTE pero no evaluada aún)
--    No deben modificarse. Se espera: solicitudes_evaluadas = 1 (solo la 000c pasa a su estado final).
SELECT '--- Tercera corrida semáforo (después de C6) ---';
-- Nota: esto solo se ejecuta manualmente o como siguiente paso en la secuencia