-- REQ 1, 2, 3, 9.1 a 9.7: Semáforo de sincronización
-- Evalúa todas las solicitudes PENDIENTE contra snapshot_servidor en una sola pasada
-- Lógica: LEFT JOIN entre cola_sync → item_borrador → snapshot_servidor
-- Por cada ítem, se evalúa en orden: rojo (rechazo) gana sobre amarillo (conflicto)
-- Al final: si hay rojos → RECHAZADO, si solo amarillos → CONFLICTO, si ninguno → SIMULADO_APROBADO
-- Actualiza estado, motivo y evaluada_en solo para filas PENDIENTE
-- Termina con SELECT changes() AS solicitudes_evaluadas; en la misma conexión

-- CTE: item_evaluacion — por cada par (solicitud, ítem) asigna condición y color
WITH item_evaluacion AS (
    SELECT
        c.solicitud_uuid,
        -- i.producto_id IS NULL cuando el borrador tiene ningún ítem (LEFT JOIN devuelve NULL)
        i.producto_id,
        i.cantidad,
        i.precio_centavos_visto,
        -- Datos del snapshot del servidor (pueden ser NULL por LEFT JOIN)
        s.eliminado,
        s.disponible,
        s.precio_centavos,
        s.stock,
        -- Nivel de condición: 0 = rojo más alto, ..., 6 = verde (ninguna condición cumple)
        -- Orden según el diseño: 0=sin ítems, 1=no existe, 2=dado de baja, 3=no disponible,
        -- 4=stock insuficiente, 5=conflicto de precio, 6=sin diferencias (verde)
        CASE
            WHEN i.producto_id IS NULL THEN 0
            WHEN s.producto_id IS NULL THEN 1
            WHEN s.eliminado = 't' THEN 2
            WHEN s.disponible = 'f' THEN 3
            WHEN i.cantidad > s.stock THEN 4
            WHEN i.precio_centavos_visto != s.precio_centavos THEN 5
            ELSE 6
        END AS cond_rank,
        -- Color: R=rojo (condiciones 0-4), A=amarillo (condición 5), NULL=verde (6)
        CASE
            WHEN i.producto_id IS NULL THEN 'R'
            WHEN s.producto_id IS NULL THEN 'R'
            WHEN s.eliminado = 't' THEN 'R'
            WHEN s.disponible = 'f' THEN 'R'
            WHEN i.cantidad > s.stock THEN 'R'
            WHEN i.precio_centavos_visto != s.precio_centavos THEN 'A'
            ELSE NULL
        END AS color,
        -- Fragmento de motivo para este ítem
        CASE
            WHEN i.producto_id IS NULL THEN 'borrador sin ítems'
            WHEN s.producto_id IS NULL THEN 'producto ' || COALESCE(i.producto_id || '', '') || ' no existe en el servidor'
            WHEN s.eliminado = 't' THEN 'dado de baja'
            WHEN s.disponible = 'f' THEN 'no disponible'
            WHEN i.cantidad > s.stock THEN 'pedido ' || i.cantidad || ', stock ' || s.stock
            WHEN i.precio_centavos_visto != s.precio_centavos THEN
                'producto ' || i.producto_id || ': borrador ' || i.precio_centavos_visto ||
                ' centavos, servidor ' || s.precio_centavos || ' centavos'
            ELSE NULL
        END AS motivo_fragmento
    FROM cola_sync c
    LEFT JOIN item_borrador i ON c.id_local = i.id_local
    LEFT JOIN snapshot_servidor s ON i.producto_id = s.producto_id
),

-- CTE: agregado — por solicitud_uuid, determina el estado y motivo ganador
agregado AS (
    SELECT
        solicitud_uuid,
        -- Prioridad: si hay algún Rojo → RECHAZADO (ignora amarillos)
        -- Si no hay Rojo pero hay algún Amarillo → CONFLICTO
        -- Si no hay Rojo ni Amarillo → SIMULADO_APROBADO
        CASE WHEN MAX(CASE WHEN color = 'R' THEN 1 ELSE 0 END) > 0 THEN 'RECHAZADO'
             WHEN MAX(CASE WHEN color = 'A' THEN 1 ELSE 0 END) > 0 THEN 'CONFLICTO'
             ELSE 'SIMULADO_APROBADO' END AS nuevo_estado,

        -- Concatenar fragmentos de motivo del color ganador, separados por '; '
        -- GROUP_CONCAT ignora automáticamente los valores NULL
        CASE WHEN MAX(CASE WHEN color = 'R' THEN 1 ELSE 0 END) > 0 THEN
            GROUP_CONCAT(CASE WHEN color = 'R' THEN motivo_fragmento END, '; ')
        WHEN MAX(CASE WHEN color = 'A' THEN 1 ELSE 0 END) > 0 THEN
            GROUP_CONCAT(CASE WHEN color = 'A' THEN motivo_fragmento END, '; ')
        ELSE NULL END AS nuevo_motivo
    FROM item_evaluacion
    GROUP BY solicitud_uuid
)

-- UPDATE final: solo filas PENDIENTE; registra evaluada_en
UPDATE cola_sync
SET
    estado = a.nuevo_estado,
    motivo = a.nuevo_motivo,
    evaluada_en = datetime('now')
FROM agregado a
WHERE cola_sync.solicitud_uuid = a.solicitud_uuid
  AND cola_sync.estado = 'PENDIENTE';

-- Reportar cantidad de solicitudes que cambiaron de estado
SELECT changes() AS solicitudes_evaluadas;