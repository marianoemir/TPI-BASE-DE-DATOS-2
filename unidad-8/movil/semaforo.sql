-- ============================================================
-- FOOD STORE · TP8 · semaforo.sql   (consigna 2.b)
-- Compara cada solicitud PENDIENTE con snapshot_servidor (la instantánea NUEVA)
-- y guarda estado y motivo en cola_sync. No toca PostgreSQL.
--
--   Rojo     RECHAZADO          producto inexistente, no disponible, dado de baja,
--                               sin stock suficiente (o borrador sin ítems)
--   Amarillo CONFLICTO          no hay rojo, pero cambió algún precio
--   Verde    SIMULADO_APROBADO  todo coincide  (NO es una venta confirmada)
--
-- Si hay rojo y amarillo en el mismo borrador, gana el rojo.
-- Solo se evalúan las PENDIENTE: repetir la simulación no cambia nada (C6).
--     sqlite3 -header -column movil/foodstore_movil.db ".read movil/semaforo.sql"
-- ============================================================
PRAGMA foreign_keys = ON;

WITH detalle AS (
    -- Un renglón por (solicitud, ítem). LEFT JOIN: si el producto no existe en la
    -- instantánea, s.* queda NULL y hay que detectarlo a mano (con NULL, las
    -- comparaciones dan NULL y el producto inexistente pasaría como verde).
    SELECT c.solicitud_uuid,
           CASE
               WHEN i.producto_id IS NULL
                    THEN 'R|borrador sin ítems'
               WHEN s.producto_id IS NULL
                    THEN 'R|producto ' || i.producto_id || ' no existe en el servidor'
               WHEN s.eliminado = 't'
                    THEN 'R|producto ' || i.producto_id || ' (' || s.nombre || ') dado de baja'
               WHEN s.disponible = 'f'
                    THEN 'R|producto ' || i.producto_id || ' (' || s.nombre || ') no disponible'
               WHEN i.cantidad > s.stock
                    THEN 'R|stock insuficiente de ' || s.nombre
                         || ' (pide ' || i.cantidad || ', hay ' || s.stock || ')'
               WHEN i.precio_centavos_visto <> s.precio_centavos
                    THEN 'A|precio de ' || s.nombre || ' cambió de '
                         || i.precio_centavos_visto || ' a ' || s.precio_centavos || ' centavos'
           END AS problema                       -- NULL = el ítem coincide
    FROM cola_sync c
    LEFT JOIN item_borrador     i ON i.id_local     = c.id_local
    LEFT JOIN snapshot_servidor s ON s.producto_id  = i.producto_id
    WHERE c.estado = 'PENDIENTE'
),
resumen AS (
    SELECT solicitud_uuid,
           sum(substr(problema, 1, 1) = 'R') AS rojos,
           sum(substr(problema, 1, 1) = 'A') AS amarillos,
           -- group_concat ignora los NULL: junta solo los motivos de cada color
           group_concat(CASE WHEN substr(problema, 1, 1) = 'R' THEN substr(problema, 3) END, '; ') AS motivo_rojo,
           group_concat(CASE WHEN substr(problema, 1, 1) = 'A' THEN substr(problema, 3) END, '; ') AS motivo_amarillo
    FROM detalle
    GROUP BY solicitud_uuid
)
UPDATE cola_sync
SET estado = CASE WHEN r.rojos > 0     THEN 'RECHAZADO'
                  WHEN r.amarillos > 0 THEN 'CONFLICTO'
                  ELSE 'SIMULADO_APROBADO' END,
    motivo = CASE WHEN r.rojos > 0     THEN r.motivo_rojo      -- el rojo gana
                  WHEN r.amarillos > 0 THEN r.motivo_amarillo
                  ELSE NULL END,
    evaluada_en = strftime('%Y-%m-%dT%H:%M:%SZ', 'now')
FROM resumen r
WHERE cola_sync.solicitud_uuid = r.solicitud_uuid
  AND cola_sync.estado = 'PENDIENTE';

SELECT changes() AS solicitudes_evaluadas;          -- en la 2.ª corrida: 0 (C6)

-- Resultado: lo que ve el vendedor
SELECT solicitud_uuid, estado, motivo, evaluada_en
FROM cola_sync
ORDER BY solicitud_uuid;
