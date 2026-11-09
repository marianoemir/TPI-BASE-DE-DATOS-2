# Hallazgos del code review (T9, objetivo 13)

Fuente: respuestas crudas de OpenCode (modo Plan) guardadas en `docs/auditoria_codigo/tanda_NN_*.md`.
Repo congelado: etiqueta `pre-review` (`351ddb9`), rama `review-final`.

**Cómo se completa**
- Severidad = la que dio la IA (no se modifica).
- Archivo y línea = como los citó la IA, **sin verificar** hasta reproducir.
- Autor del script: `<completar>` (quien escribió el archivo; no fue consultado).
- Decisión: aceptado, corregido o descartado. Motivo y prueba (ruta en `docs/auditoria_codigo/evidencias/`) se completan al reproducir el hallazgo en una copia. Si no se llega a reproducir: «aceptado/descartado, no reproducido» más el motivo.

## Tanda 01 — `heredado/base_heredada/` (`tanda_01_repeticion.md`)

| ID | Archivo:línea | Resumen | Severidad (IA) | Autor | Decisión | Motivo | Prueba |
|---|---|---|---|---|---|---|---|
| H-01 | schema.sql:45 | `mail UNIQUE` incluye usuarios eliminados lógicamente | alta | `<completar>` | | | |
| H-02 | schema.sql:16 | `categoria.nombre UNIQUE` incluye categorías eliminadas | media | `<completar>` | | | |
| H-03 | schema.sql:27 | `producto.nombre` no es único pero otros archivos lo usan como clave | media | `<completar>` | | | |
| H-04 | schema.sql:61 | `CHECK (fecha <= CURRENT_DATE)` depende del momento de ejecución | media | `<completar>` | | | |
| H-05 | schema.sql:46, 28, 76, 63 | Validaciones incompletas e inconsistentes (vacíos, precio 0) | baja | `<completar>` | | | |
| H-06 | schema.sql:78 | `ON DELETE RESTRICT` solo en `detalle_pedido`; resto implícito | baja | `<completar>` | | | |
| H-07 | schema.sql:82, 90-96 | Falta índice por `producto_id` en `detalle_pedido`; índice de nombre solapado | media | `<completar>` | | | |
| H-08 | schema.sql:7-14 | No idempotente (sin `IF NOT EXISTS`) | baja | `<completar>` | | | |
| H-09 | objects.sql:60-65 | `fn_set_subtotal()` no congela el precio (acepta `precio_unitario` manual) | alta | `<completar>` | | | |
| H-10 | objects.sql:61-62 | Producto inexistente: sin error de negocio, falla por `NOT NULL` | media | `<completar>` | | | |
| H-11 | objects.sql:90-96 | Falta trigger de `DELETE` para recalcular `pedido.total` | alta | `<completar>` | | | |
| H-12 | objects.sql:99-107 | Máquina de estados incompleta (solo bloquea `CONFIRMADO → PENDIENTE`) | media | `<completar>` | | | |
| H-13 | objects.sql:118-143 | `sp_crear_pedido` acepta pedido vacío (`'[]'`) | alta | `<completar>` | | | |
| H-14 | objects.sql:142-143 | Sin validación de `cantidad`/`producto_id` nulos o inválidos | media | `<completar>` | | | |
| H-15 | objects.sql:141-164 | Productos duplicados en `p_items` violan `UNIQUE` con error críptico | media | `<completar>` | | | |
| H-16 | objects.sql:43-172 | Funciones y procedure sin `SET search_path` | media | `<completar>` | | | |
| H-17 | objects.sql:22-28, 30-36 | Vistas muestran estado actual (total denormalizado, nombre actual), no histórico | baja | `<completar>` | | | |
| H-18 | views.sql:21-31 | `v_usuario_seguro` no filtra eliminados y expone `celular` y `mail` | media | `<completar>` | | | |
| H-19 | views.sql:5-12 | Referencia a ruta externa que no es parte del repo | baja | `<completar>` | | | |
| H-20 | materializadas.sql:13 | La MV no filtra `detalle_pedido.eliminado` (facturación inflada) | alta | `<completar>` | | | |
| H-21 | materializadas.sql:13 | La MV solo cuenta `CONFIRMADO`; otros archivos usan `CONFIRMADO` y `TERMINADO` | media | `<completar>` | | | |
| H-22 | materializadas.sql:15-20 | `ORDER BY` en la MV y sin política de `REFRESH` | baja | `<completar>` | | | |
| H-23 | materializadas.sql:8 | `SUM(cantidad*precio_unitario)` en vez de `SUM(subtotal)` | baja | `<completar>` | | | |
| H-24 | indices.sql:24-26 | Índice de nombre redundante con `schema.sql:96` | media | `<completar>` | | | |
| H-25 | indices_semana3.sql:11-13 | Orden de columnas `(fecha, estado)` subóptimo | media | `<completar>` | | | |
| H-26 | indices_semana3.sql:17-19 | Índice compuesto vuelve redundante `idx_pedido_usuario_id` | baja | `<completar>` | | | |
| H-27 | queries.sql:28-41 | El archivo muta el seed y no es re-ejecutable | media | `<completar>` | | | |
| H-28 | queries.sql:52-62 | No filtra `c.eliminado`; diverge de `v_productos_vigentes` | media | `<completar>` | | | |
| H-29 | queries.sql:72-75 | `COALESCE(NULL, stock)` es un no-op confuso | baja | `<completar>` | | | |
| H-30 | queries.sql:94-96 | Contraseñas de ejemplo en claro (`'hash_diego'`) | media | `<completar>` | | | |
| H-31 | queries.sql:159-187 | Analíticas incluyen cancelados/pendientes y eliminados | alta | `<completar>` | | | |
| H-32 | queries.sql:148-151 | `BEGIN…COMMIT` puede cerrar una transacción ajena del cliente | baja | `<completar>` | | | |
| H-33 | transacciones.sql:30-41 | «Dos sesiones» simuladas con `BEGIN` anidados en un solo archivo | alta | `<completar>` | | | |
| H-34 | transacciones.sql:45 | `SET TRANSACTION ISOLATION LEVEL` fuera de transacción (ignorado) | alta | `<completar>` | | | |
| H-35 | transacciones.sql:63-69 | Escenario `FOR UPDATE` en una sola sesión: no prueba el bloqueo | alta | `<completar>` | | | |
| H-36 | transacciones.sql:5-6 | Escenario 1 sin verificación de atomicidad | baja | `<completar>` | | | |
| H-37 | data.sql:23-108 | IDs implícitos por orden de inserción | media | `<completar>` | | | |
| H-38 | data.sql:53, 68 | Baja lógica por `INSERT` + `UPDATE` en vez de insertar con `eliminado=TRUE` | baja | `<completar>` | | | |
| H-39 | data.sql:58-68 | Placeholders de contraseña `hash_…` | baja | `<completar>` | | | |
| H-40 | data.sql:111-113 | `PENDIENTE → TERMINADO` directo (usa la máquina de estados permisiva) | baja | `<completar>` | | | |
| H-41 | carga_masiva.sql:10-114 | Todo en una sola transacción gigante | alta | `<completar>` | | | |
| H-42 | carga_masiva.sql:66 | `usuario_id` por aritmética, no por `RETURNING` | alta | `<completar>` | | | |
| H-43 | carga_masiva.sql:91 | `producto_id` por módulo sobre un rango asumido (1..50000) | alta | `<completar>` | | | |
| H-44 | carga_masiva.sql:71 | `TEMP TABLE pedidos_nuevos` sin `DROP` / `ON COMMIT DROP` | media | `<completar>` | | | |
| H-45 | carga_masiva.sql:78, 98 | `DISABLE TRIGGER trg_total_ins` puede quedar deshabilitado si se aborta | media | `<completar>` | | | |
| H-46 | carga_masiva.sql:62 | `fecha` generada puede violar `CHECK (fecha <= CURRENT_DATE)` | media | `<completar>` | | | |
| H-47 | carga_masiva.sql:103-112 | `UPDATE` de totales no cubre pedidos sin detalles vigentes | baja | `<completar>` | | | |
| H-48 | carga_masiva.sql:128-133 | Conteos esperados de verificación incorrectos (`50018` vs `50016`) | baja | `<completar>` | | | |

Totales de la tanda 01 (según la IA): 48 hallazgos; 12 de severidad alta, 20 media, 16 baja, ninguno crítico.

## Sección aparte — origen «Claude, no OpenCode»

Candidatos que salieron de revisiones hechas en el chat con Claude. Se declara el origen y se reproducen en copia.

| ID | Archivo | Resumen | Origen | Decisión | Motivo | Prueba |
|---|---|---|---|---|---|---|
| C-01 | unidad-5/sql/ | `PUBLIC` con `EXECUTE` en rutinas viejas | Claude, no OpenCode | | | |
| C-02 | unidad-6/restore_test.ps1 | La restauración pierde dueños y permisos | Claude, no OpenCode | | | |
| C-03 | unidad-6/backup_foodstore.ps1 | El respaldo no verificaba su SHA-256 (corregido el 07/11) | Claude, no OpenCode | | | |
| C-04 | unidad-6/ | Conteos comparados a mano | Claude, no OpenCode | | | |
| C-05 | unidad-7/correr_correcciones_obj10.ps1 | El encabezado nombra `$env:PGPASSWORD` (va contra la regla de la U6); falta ver si el script lo usa | Claude, no OpenCode | | | |
| C-06 | unidad-6/maintenance.sql | El «sin acción» original pudo deberse a estadísticas en cero tras `createdb -T` | Claude, no OpenCode | | | |
