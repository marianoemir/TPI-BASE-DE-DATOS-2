-- REQ 1, 2, 3, 9.1-9.7
-- Semáforo de sincronización: evalúa solicitudes PENDIENTE contra la instantánea
PRAGMA foreign_keys = ON;

-- CTE detalle: evalúa cada ítem de cada solicitud contra la instantánea
WITH detalle AS (
    SELECT
        c.solicitud_uuid,
        c.id_local,
        i.producto_id,
        i.cantidad,
        i.precio_centavos_visto,
        s.precio_centavos,
        s.eliminado,
        s.disponible,
        s.stock,
        s.nombre AS prod_nombre,
        -- Detectar si el producto no existe en la instantánea (LEFT JOIN produce NULL)
        CASE WHEN i.producto_id IS NULL THEN 1 ELSE 0 END AS producto_inexistente,
        -- Borrador sin ítems: cuando el LEFT JOIN no encuentra ítems para la solicitud
        CASE WHEN i.producto_id IS NULL THEN 1 ELSE 0 END AS sin_items,
        -- Cuando el producto está dado de baja
        CASE WHEN s.eliminado = 't' THEN 1 ELSE 0 END AS dado_baja,
        -- Cuando el producto no está disponible
        CASE WHEN s.disponible = 'f' THEN 1 ELSE 0 END AS no_disponible,
        -- Cuando la cantidad supera el stock
        CASE WHEN i.cantidad > s.stock THEN 1 ELSE 0 END AS stock_insuficiente,
        -- Cuando hay conflicto de precio
        CASE WHEN i.precio_centavos_visto != s.precio_centavos THEN 1 ELSE 0 END AS conflicto_precio
    FROM cola_sync c
    LEFT JOIN item_borrador i ON c.id_local = i.id_local
    LEFT JOIN snapshot_servidor s ON i.producto_id = s.producto_id
    WHERE c.estado = 'PENDIENTE'
),

-- CTE resumen: por solicitud, determina el estado y concatena motivos
resumen AS (
    SELECT
        solicitud_uuid,
        -- Prioridad: rojo gana sobre amarillo; se evalúa en orden por cada ítem
        CASE WHEN
            -- Criterio 0 (borrador sin ítems) o 1 (producto inexistente) o 2 (dado de baja) o 3 (no disponible) o 4 (stock insuficiente) → ROJO
            MAX(producto_inexistente) = 1 OR
            MAX(dado_baja) = 1 OR
            MAX(no_disponible) = 1 OR
            MAX(stock_insuficiente) = 1 OR
            MAX(sin_items) = 1
            THEN 'RECHAZADO'
            -- Si no rojos, pero hay amarillos (conflicto de precio) → CONFLICTO
            WHEN MAX(conflicto_precio) = 1 THEN 'CONFLICTO'
            -- Si no rojos ni amarillos → SIMULADO_APROBADO
            ELSE 'SIMULADO_APROBADO'
        END AS nuevo_estado,
        -- Construir motivo: concatenar fragmentos de una misma color; rojos tienen prioridad
        -- Empezar con cadena vacía, luego agregar fragmentos
        -- Para rojos: cada causa es un fragmento; los de mismo color se unen con "; "
        -- Producto inexistente
        (CASE WHEN MAX(producto_inexistente) = 1 THEN 'producto ' || prod_nombre || ' no existe en el servidor' ELSE '' END)
        -- Dado de baja
        || CASE WHEN MAX(dado_baja) = 1 AND MAX(producto_inexistente) = 0 THEN '; ' ELSE '' END
        || CASE WHEN MAX(dado_baja) = 1 AND MAX(producto_inexistente) = 1 THEN '' END
        || CASE WHEN MAX(dado_baja) = 1 THEN prod_nombre || ': dado de baja' ELSE '' END
        -- No disponible
        || CASE WHEN MAX(no_disponible) = 1 AND MAX(producto_inexistente) = 0 AND MAX(dado_baja) = 0 THEN '; ' ELSE '' END
        || CASE WHEN MAX(no_disponible) = 1 AND (MAX(producto_inexistente) = 1 OR MAX(dado_baja) = 1) THEN '' END
        || CASE WHEN MAX(no_disponible) = 1 THEN prod_nombre || ': no disponible' ELSE '' END
        -- Stock insuficiente
        || CASE WHEN MAX(stock_insuficiente) = 1 AND MAX(producto_inexistente) = 0 AND MAX(dado_baja) = 0 AND MAX(no_disponible) = 0 THEN '; ' ELSE '' END
        || CASE WHEN MAX(stock_insuficiente) = 1 AND (MAX(producto_inexistente) = 1 OR MAX(dado_baja) = 1 OR MAX(no_disponible) = 1) THEN '' END
        || CASE WHEN MAX(stock_insuficiente) = 1 THEN prod_nombre || ': pedido ' || MAX(CASE WHEN i.producto_id IS NOT NULL THEN i.cantidad ELSE 0 END) || ', stock ' || MAX(s.stock) ELSE '' END
        -- Conflicto de precio (solo si no hay rojos)
        || CASE WHEN MAX(conflicto_precio) = 1 AND MAX(producto_inexistente) = 0 AND MAX(dado_baja) = 0 AND MAX(no_disponible) = 0 AND MAX(stock_insuficiente) = 0 THEN '; ' ELSE '' END
        || CASE WHEN MAX(conflicto_precio) = 1 THEN prod_nombre || ': borrador ' || MAX(i.precio_centavos_visto) || ' centavos, servidor ' || MAX(s.precio_centavos) || ' centavos' ELSE '' END
        AS nuevo_motivo,
        -- Contar cuántos ítems tienen cada condición (para determinar prioridad)
        SUM(producto_inexistente + dado_baja + no_disponible + stock_insuficiente + sin_items) AS total_rojos,
        SUM(conflicto_precio) AS total_amarillos
    FROM detalle
    GROUP BY solicitud_uuid
)

-- Actualizar cola_sync: solo las filas que aún están PENDIENTE
UPDATE cola_sync
SET
    estado = r.nuevo_estado,
    motivo = CASE WHEN r.total_rojos > 0 THEN r.nuevo_motivo ELSE NULL END,
    evaluada_en = strftime('%Y-%m-%d %H:%M:%S','now')
FROM resumen r
WHERE cola_sync.solicitud_uuid = r.solicitud_uuid
  AND cola_sync.estado = 'PENDIENTE';

-- Reportar cantidad de solicitudes evaluadas (que pasaron de PENDIENTE a otro estado)
SELECT changes() AS solicitudes_evaluadas;