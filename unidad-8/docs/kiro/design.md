# Diseño

**Motores.** PostgreSQL (`foodstore_u8`, pruebas) es la fuente de verdad. La tablet es un archivo SQLite
(`movil/foodstore_movil.db`). La sincronización es una simulación: no hay conexión entre los dos motores.

**Flujo.** `v_snapshot_movil` (PostgreSQL) → `servidor_snapshot.csv` → tabla `snapshot_servidor` (SQLite, paso
intermedio con los booleanos t/f) → `producto_cache` (UPSERT). El semáforo compara `cola_sync` con
`snapshot_servidor`.

**Tablas SQLite (todas STRICT, claves foráneas activas).** `producto_cache`, `pedido_borrador`, `item_borrador`,
`cola_sync`, más la vista `v_catalogo_disponible` y `snapshot_servidor`. Precio en centavos enteros.

**Decisiones.**
- Borrador + ítems + solicitud se graban en **una transacción** (todo o nada).
- Índice único **parcial** `ux_cola_una_pendiente`: un borrador puede reenviarse tras un CONFLICTO, pero nunca
  tiene dos envíos pendientes a la vez (alternativa descartada: `UNIQUE` simple sobre `id_local`).
- Recarga del catálogo con `ON CONFLICT DO UPDATE`: la lápida conserva la fila (alternativa descartada:
  `INSERT OR REPLACE`, que borra la fila y rompe la clave foránea).
- Semáforo en SQL puro; solo evalúa `PENDIENTE`, por eso repetirlo no cambia nada (idempotencia local).
- La protección real contra duplicados está en el servidor (tabla con clave única sobre el UUID, en la misma
  transacción que crea el pedido); el TP solo la menciona.

**Fuera de alcance.** App móvil, interfaz, escritura en PostgreSQL desde la tablet, venta confirmada.
