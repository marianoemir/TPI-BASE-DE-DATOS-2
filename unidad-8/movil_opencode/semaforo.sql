-- REQ 1, 2, 3, 9, 10
-- Semaforo: evalua solo solicitudes PENDIENTE contra snapshot_servidor.
-- Reescrito a mano: la version de OpenCode fallaba (alias i fuera de alcance) y usaba
-- prod_nombre NULL para productos inexistentes. Rojo gana sobre amarillo (REQ 9.2).
-- No suma ni reserva stock entre solicitudes (REQ 10.2) y no toca producto_cache (REQ 10.3).
PRAGMA foreign_keys = ON;

WITH pend AS (
    SELECT solicitud_uuid, id_local FROM cola_sync WHERE estado = 'PENDIENTE'
),
det AS (
    SELECT p.solicitud_uuid,
           i.producto_id, i.cantidad, i.precio_centavos_visto,
           s.producto_id AS s_id, s.nombre, s.precio_centavos, s.stock,
           s.disponible, s.eliminado
    FROM pend p
    LEFT JOIN item_borrador     i ON i.id_local = p.id_local
    LEFT JOIN snapshot_servidor s ON s.producto_id = i.producto_id
),
causas AS (
    -- R = rojo (rechazo), A = amarillo (conflicto de precio)
    SELECT solicitud_uuid, 'R' AS color, 0 AS orden, 'borrador sin ítems' AS texto
      FROM det WHERE producto_id IS NULL
    UNION ALL
    SELECT solicitud_uuid, 'R', 1, 'producto ' || producto_id || ' no existe en el servidor'
      FROM det WHERE producto_id IS NOT NULL AND s_id IS NULL
    UNION ALL
    SELECT solicitud_uuid, 'R', 2, nombre || ': dado de baja'
      FROM det WHERE s_id IS NOT NULL AND eliminado = 't'
    UNION ALL
    SELECT solicitud_uuid, 'R', 3, nombre || ': no disponible'
      FROM det WHERE s_id IS NOT NULL AND disponible = 'f'
    UNION ALL
    SELECT solicitud_uuid, 'R', 4, nombre || ': pedido ' || cantidad || ', stock ' || stock
      FROM det WHERE s_id IS NOT NULL AND cantidad > stock
    UNION ALL
    SELECT solicitud_uuid, 'A', 5,
           nombre || ': borrador ' || precio_centavos_visto || ' centavos, servidor ' || precio_centavos || ' centavos'
      FROM det WHERE s_id IS NOT NULL AND precio_centavos_visto <> precio_centavos
),
est AS (
    SELECT p.solicitud_uuid,
           CASE
             WHEN EXISTS (SELECT 1 FROM causas c WHERE c.solicitud_uuid = p.solicitud_uuid AND c.color = 'R') THEN 'RECHAZADO'
             WHEN EXISTS (SELECT 1 FROM causas c WHERE c.solicitud_uuid = p.solicitud_uuid AND c.color = 'A') THEN 'CONFLICTO'
             ELSE 'SIMULADO_APROBADO'
           END AS nuevo_estado
    FROM pend p
),
resultado AS (
    SELECT e.solicitud_uuid, e.nuevo_estado,
           (SELECT group_concat(texto, '; ')
              FROM (SELECT c.texto FROM causas c
                     WHERE c.solicitud_uuid = e.solicitud_uuid
                       AND c.color = CASE e.nuevo_estado WHEN 'RECHAZADO' THEN 'R'
                                                         WHEN 'CONFLICTO' THEN 'A' END
                     ORDER BY c.orden, c.texto)) AS nuevo_motivo
    FROM est e
)
UPDATE cola_sync
SET estado      = r.nuevo_estado,
    motivo      = r.nuevo_motivo,
    evaluada_en = strftime('%Y-%m-%d %H:%M:%S','now')
FROM resultado r
WHERE cola_sync.solicitud_uuid = r.solicitud_uuid
  AND cola_sync.estado = 'PENDIENTE';

SELECT changes() AS solicitudes_evaluadas;
