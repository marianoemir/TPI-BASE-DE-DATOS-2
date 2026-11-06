-- ============================================================
-- FOOD STORE · TP8 · casos_c2_c6_resolucion.sql
-- Paso 3, DESPUÉS de bajar la instantánea nueva, recargar producto_cache y
-- correr el semáforo por primera vez.
--     sqlite3 -header -column movil/foodstore_movil.db ".read movil/casos_c2_c6_resolucion.sql"
-- ============================================================
PRAGMA foreign_keys = ON;

-- C2 (segunda parte) · el cliente ACEPTA el precio nuevo: se actualiza el precio
-- del borrador con el de la lista ya recargada y se hace una SOLICITUD NUEVA.
-- El índice parcial ux_cola_una_pendiente lo permite porque la anterior ya no
-- está PENDIENTE (quedó en CONFLICTO).
BEGIN;
UPDATE item_borrador
SET precio_centavos_visto = (SELECT pc.precio_centavos
                             FROM producto_cache pc
                             WHERE pc.producto_id = item_borrador.producto_id)
WHERE id_local = 'c2000000-0000-4000-8000-00000000000a';

INSERT INTO cola_sync (solicitud_uuid, id_local)
VALUES ('c2000000-0000-4000-8000-00000000000c', 'c2000000-0000-4000-8000-00000000000a');
COMMIT;

SELECT solicitud_uuid, estado FROM cola_sync WHERE solicitud_uuid LIKE 'c2%' ORDER BY solicitud_uuid;

-- C6 · Se reenvía la MISMA solicitud (el UUID de C5, ya evaluada).
-- Error esperado: UNIQUE constraint failed: cola_sync.solicitud_uuid
INSERT INTO cola_sync (solicitud_uuid, id_local)
VALUES ('c5000000-0000-4000-8000-00000000000b', 'c5000000-0000-4000-8000-00000000000a');

-- Sigue habiendo UNA sola fila con ese UUID, con su resultado anterior
SELECT solicitud_uuid, estado, evaluada_en
FROM cola_sync
WHERE solicitud_uuid = 'c5000000-0000-4000-8000-00000000000b';
