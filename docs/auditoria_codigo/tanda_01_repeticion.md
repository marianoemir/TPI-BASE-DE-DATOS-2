# Tanda 01 — heredado/base_heredada (repetición con lista real)

Herramienta: OpenCode (modo Plan, solo lectura)
Modelo: Croutou Alpha Free
Fecha y hora: 8/11/2026, 22:57
Archivos (10):
- heredado/base_heredada/schema.sql
- heredado/base_heredada/objects.sql
- heredado/base_heredada/views.sql
- heredado/base_heredada/materializadas.sql
- heredado/base_heredada/indices.sql
- heredado/base_heredada/indices_semana3.sql
- heredado/base_heredada/queries.sql
- heredado/base_heredada/transacciones.sql
- heredado/base_heredada/data.sql
- heredado/base_heredada/carga_masiva.sql
Prompt: ver prompt_base.md (solo cambia la lista de archivos)
Estado: corrida completa. Repite la corrida fallida de tanda_01_heredado.md (marcador sin reemplazar).
Total de hallazgos devueltos: 48 (12 alta / 20 media / 16 baja)
Estado del repo: rama review-final, etiqueta pre-review (351ddb9)

---

Revisión estática, sin ejecutar código — no puedo afirmar que probé nada. Revisé únicamente los 10 archivos indicados, en modo solo lectura.

> Si un archivo no tiene hallazgos, lo indico explícitamente: **ninguno de los 10 está limpio**, todos tienen al menos un hallazgo.

# Hallazgos

## `heredado/base_heredada/schema.sql`

**H-01 — schema.sql:45 — `mail UNIQUE` incluye usuarios eliminados. Severidad: alta.**
No podés reutilizar el mail de un usuario con `eliminado=TRUE`. El borrado es lógico, pero la unicidad es total (`UNIQUE` simple).
*Corrección:* índice único parcial `CREATE UNIQUE INDEX … ON usuario(mail) WHERE eliminado=FALSE` y sacar el `UNIQUE` de la columna.

**H-02 — schema.sql:16 — `categoria.nombre UNIQUE` incluye eliminadas. Severidad: media.**
Mismo problema que H-01: no se puede recrear una categoría con un nombre que quedó en baja lógica.
*Corrección:* único parcial `WHERE eliminado=FALSE`, o reutilizar la fila eliminada.

**H-03 — schema.sql:27 — `producto.nombre` no es único, pero otros archivos lo usan como clave. Severidad: media.**
`queries.sql:80` y `data.sql:53` hacen `WHERE nombre=…`. Con duplicados, el `UPDATE` afectaría varias filas.
*Corrección:* si el nombre debe identificar, hacerlo `UNIQUE` (o parcial); si no, buscar siempre por `id`.

**H-04 — schema.sql:61 — `CHECK (fecha <= CURRENT_DATE)` depende del momento de ejecución. Severidad: media.**
Impide pedidos con fecha futura legítima (reserva/venta futura) y hace que `carga_masiva.sql` falle si se corre antes de que la fecha generada sea "pasada". No estoy seguro al 100% de si la intención es "no futuro" o solo de prueba.
*Corrección:* sacar el check o reemplazarlo por una validación de negocio explícita (ej. `fecha >= DATE '2025-01-01'`).

**H-05 — schema.sql:46, 28, 76, 63 — Validaciones incompletas e inconsistentes. Severidad: baja.**
`mail` tiene regex (línea 51-53), pero `celular`, `nombre`, `apellido` aceptan `''` o espacios. `precio/precio_unitario/total >= 0` aceptan `0` mientras `cantidad > 0`. No es un crash, pero deja datos basura.
*Corrección:* `CHECK (btrim(nombre)<>'')`, validar `celular`, y decidir si precio 0 es válido (`>0` si no).

**H-06 — schema.sql:78 — `ON DELETE RESTRICT` solo en `detalle_pedido`. Severidad: baja.**
El resto de FK usa el default (`NO ACTION`) sin explicitarlo. Inconsistencia que confunde ante un borrado físico.
*Corrección:* explicitar `ON DELETE RESTRICT` en todas las FK, o documentar que el borrado es siempre lógico.

**H-07 — schema.sql:82, 90-96 — Indexación incompleta / redundante. Severidad: media.**
`UNIQUE(pedido_id, producto_id)` cubre `pedido_id` pero no hay índice solo por `producto_id` — lo usan `queries.sql:160` (Top 5) y `materializadas.sql:11`. A la vez, `idx_producto_nombre_vigente` (línea 96) se solapa con `idx_producto_nombre_lower_vigente` de `indices.sql`.
*Corrección:* agregar `CREATE INDEX … ON detalle_pedido(producto_id)` y quedarte con un solo índice de nombre según el tipo de búsqueda.

**H-08 — schema.sql:7-14 — No idempotente. Severidad: baja.**
`CREATE TYPE/TABLE/INDEX` sin `IF NOT EXISTS` ni `DROP IF EXISTS`: re-ejecutar el archivo falla. No es bug si el script es de "una sola vez", pero debe documentarse.
*Corrección:* documentar "correr una vez sobre BD vacía" o hacerlo idempotente.

## `heredado/base_heredada/objects.sql`

**H-09 — objects.sql:60-65 — `fn_set_subtotal()` no congela de verdad el precio. Severidad: alta.**
Solo completa `precio_unitario` si es `NULL` (línea 60). Un `INSERT/UPDATE` directo puede poner `precio_unitario=0` y el trigger lo acepta: `subtotal = cantidad * 0 = 0`. La "foto del precio" no se impone.
*Corrección:* en `INSERT` forzar siempre `NEW.precio_unitario := (SELECT precio FROM producto …)`, o validar `NEW.precio_unitario = precio actual`.

**H-10 — objects.sql:61-62 — Si el producto no existe, no hay error amable. Severidad: media.**
El `SELECT … INTO` deja `NULL`, luego `subtotal = NULL` y el error final es un genérico de `NOT NULL`. No estoy seguro de si el FK salta antes que el trigger en tu PG, pero el trigger no debería depender de eso.
*Corrección:* `IF NOT FOUND THEN RAISE EXCEPTION 'Producto % inexistente', NEW.producto_id; END IF;`

**H-11 — objects.sql:90-96 — Falta trigger de `DELETE` para recalcular `pedido.total`. Severidad: alta.**
Solo hay trigger de `INSERT` y `UPDATE`. Un `DELETE FROM detalle_pedido` deja `pedido.total` inflado/stale. El baja lógica (`UPDATE eliminado=TRUE`) sí está cubierta porque es un `UPDATE`, pero el físico no.
*Corrección:* agregar `CREATE TRIGGER … AFTER DELETE … REFERENCING OLD TABLE AS afectados`.

**H-12 — objects.sql:99-107 — Máquina de estados incompleta. Severidad: media.**
Solo bloquea `CONFIRMADO → PENDIENTE` (línea 102). Todo lo demás pasa: `TERMINADO → PENDIENTE`, `CANCELADO → CONFIRMADO`, `PENDIENTE → TERMINADO`, etc.
*Corrección:* tabla de transiciones permitidas y `RAISE` para cualquier otra.

**H-13 — objects.sql:118-143 — `sp_crear_pedido` acepta un pedido vacío. Severidad: alta.**
Si `p_items` es `'[]'::jsonb` o `NULL`, `jsonb_array_elements` devuelve 0 filas: crea un `pedido` con `total=0` y retorna OK (línea 137 inserta antes de validar). No estoy seguro de si `jsonb_array_elements(NULL)` devuelve 0 filas o error según tu PG, pero el `'[]'` seguro pasa.
*Corrección:* validar al inicio: `IF p_items IS NULL OR jsonb_array_length(p_items)=0 THEN RAISE …`.

**H-14 — objects.sql:142-143 — Sin validación de `cantidad`/`producto_id` nulos o inválidos. Severidad: media.**
`(v_item->>'cantidad')::INTEGER` con `NULL`, `"abc"` o `-1` tira un cast/constraint error genérico en lugar de un mensaje de negocio. `cantidad=-1` pasa el check de stock (`v_stock < -1` es falso) y recién falla en el `INSERT`.
*Corrección:* `IF v_cantidad IS NULL OR v_cantidad<=0 THEN RAISE …`; lo mismo para `producto_id`.

**H-15 — objects.sql:141-164 — Productos duplicados en `p_items` rompen con error críptico. Severidad: media.**
`[{"producto_id":1,"cantidad":1},{"producto_id":1,"cantidad":2}]` inserta dos filas con el mismo `(pedido_id, producto_id)` y viola el `UNIQUE` de schema.sql:82.
*Corrección:* agregar por `producto_id` (`GROUP BY producto_id` / `ON CONFLICT … DO UPDATE`) antes de insertar.

**H-16 — objects.sql:43-172 — Sin `SET search_path`. Severidad: media.**
Funciones, triggers y el procedure usan nombres sin schema (`detalle_pedido`, `producto`, `pedido`). Con `search_path` manipulable es un riesgo de hijack (clásico en revisión).
*Corrección:* `SET search_path TO public, pg_temp` en cada función/procedure o calificar con `public.`.

**H-17 — objects.sql:22-28, 30-36 — Las vistas exponen "foto actual", no histórica. Severidad: baja.**
`v_pedidos_resumen` muestra `ped.total` denormalizado (si el total quedó stale, la vista miente) y `v_pedido_detalle` muestra el `producto.nombre` actual — si renombrás un producto, cambia el historial.
*Corrección:* documentarlo como decisión, o congelar `producto_nombre` en `detalle_pedido`.

## `heredado/base_heredada/views.sql`

**H-18 — views.sql:21-31 — `v_usuario_seguro` no filtra eliminados y expone PII. Severidad: media.**
No tiene `WHERE eliminado=FALSE` y expone `celular` + `mail` de todos los usuarios (incluidos dados de baja) "para reportes generales". El nombre "seguro" solo oculta la contraseña.
*Corrección:* filtrar eliminados, decidir si `celular` debe estar, y/o agregar `security_invoker` + `GRANT/REVOKE` explícitos.

**H-19 — views.sql:5-12 — Referencia externa no resuelta. Severidad: baja.**
Comenta que 3 vistas viven en `'Archivos necesarios para la BD/objects.sql'`, ruta que no es parte de esta lista del repo. Mantenimiento/confusión de dependencia.
*Corrección:* referenciar `heredado/base_heredada/objects.sql` y el orden de carga.

## `heredado/base_heredada/materializadas.sql`

**H-20 — materializadas.sql:13 — No filtra `detalle_pedido.eliminado`. Severidad: alta.**
El `WHERE` filtra `p.estado` y `p.eliminado`, pero suma `SUM(dp.cantidad*…)` y `COUNT(DISTINCT p.id)` de detalles dados de baja (`dp.eliminado=TRUE`). La facturación queda inflada. También faltan `pr.eliminado` y `c.eliminado`.
*Corrección:* agregar `AND dp.eliminado=FALSE AND pr.eliminado=FALSE AND c.eliminado=FALSE`.

**H-21 — materializadas.sql:13 — Solo cuenta `CONFIRMADO`, no `TERMINADO`. Severidad: media.**
`queries.sql` y `indices_semana3.sql` usan `IN ('CONFIRMADO','TERMINADO')` (línea 19), pero acá `TERMINADO` se excluye: la MV subestima ventas completadas. O es un error o hay dos definiciones de "facturado".
*Corrección:* unificar la definición en todos los archivos.

**H-22 — materializadas.sql:15-20 — `ORDER BY` en la MV y sin política de `REFRESH`. Severidad: baja.**
El `ORDER BY` de la MV no garantiza orden al leer. Y ninguna parte del archivo define cuándo se refresca: la MV queda stale tras cada `INSERT`.
*Corrección:* quitar el `ORDER BY` o documentarlo como no-garantizado; agregar `REFRESH MATERIALIZED VIEW CONCURRENTLY` (el índice único ya lo permite).

**H-23 — materializadas.sql:8 — `SUM(cantidad*precio_unitario)` en vez de `SUM(subtotal)`. Severidad: baja.**
Si alguien escribe `subtotal` distinto a `cantidad*precio` (corrupción directa), la MV diverge del total real.
*Corrección:* usar `SUM(dp.subtotal)` para ser consistente con `calcular_total_pedido`.

## `heredado/base_heredada/indices.sql`

**H-24 — indices.sql:24-26 — Índice redundante con schema.sql:96. Severidad: media.**
`idx_producto_nombre_vigente ON producto(nombre)` (schema) y `idx_producto_nombre_lower_vigente ON producto(lower(nombre) text_pattern_ops)` hacen casi lo mismo. Doble mantenimiento en cada `INSERT` y el optimizador debe elegir.
*Corrección:* conservar solo el que usa tu búsqueda real (`lower(nombre) LIKE` vs `nombre =`).

## `heredado/base_heredada/indices_semana3.sql`

**H-25 — indices_semana3.sql:11-13 — Orden de columnas subóptimo. Severidad: media.**
`(fecha, estado)` con rango en `fecha` y igualdad en `estado` es menos eficiente que `(estado, fecha)` (igualdad primero, rango después).
*Corrección:* `ON pedido(estado, fecha) WHERE eliminado=FALSE`.

**H-26 — indices_semana3.sql:17-19 — La consuta 3 hace redundante `idx_pedido_usuario_id` de schema.sql:93. Severidad: baja.**
El compuesto `(usuario_id, total)` ya cubre el prefijo `usuario_id`. Dos índices donde basta uno.
*Corrección:* eliminar el simple o justificar que queda por compatibilidad.

## `heredado/base_heredada/queries.sql`

**H-27 — queries.sql:28-41 — El archivo muta el seed y no es re-ejecutable. Severidad: media.**
Renombra la categoría 1 a `'Pizzas Artesanales'` y luego crea/elimina `'Vegano'`. La segunda corrida falla por `UNIQUE` o modifica datos ya usados por `data.sql`.
*Corrección:* envolver las demo-mutaciones en `BEGIN…ROLLBACK` o separar "consultas SELECT" de "mutaciones de prueba".

**H-28 — queries.sql:52-62 — Divergencia con `v_productos_vigentes`. Severidad: media.**
Filtra `p.eliminado=FALSE` pero no `c.eliminado=FALSE`. `objects.sql:20` sí filtra la categoría. Esta query lista productos de categorías eliminadas.
*Corrección:* agregar `AND c.eliminado=FALSE` o usar la vista.

**H-29 — queries.sql:72-75 — `COALESCE(NULL, stock)` es un no-op confuso. Severidad: baja.**
Segunda columna no hace nada, parece una demo de "update parcial" incompleta.
*Corrección:* usar variables (`NULL` conserva) comentadas, o `SET stock = COALESCE($1, stock)`.

**H-30 — queries.sql:94-96 — Contraseñas de ejemplo en claro. Severidad: media.**
`'hash_diego'` no es un hash; si se copia el patrón, se normaliza guardar contraseñas débiles.
*Corrección:* generar con `pgcrypto`/`bcrypt` real o marcar claramente "solo seed de desarrollo".

**H-31 — queries.sql:159-187 — Analíticas inconsistentes: incluyen pedidos cancelados/pendientes y eliminados. Severidad: alta.**
A) Top 5 solo filtra `dp.eliminado`; B) suma `facturado` de todos los estados; C) rankea gasto de todos los estados. No filtran `ped.estado` ni `pr.eliminado`/`c.eliminado`. Cancelados (`data.sql:113`) inflan "ventas" y "gasto".
*Corrección:* filtrar `ped.estado IN ('CONFIRMADO','TERMINADO') AND ped.eliminado=FALSE AND pr.eliminado=FALSE`.

**H-32 — queries.sql:148-151 — `COMMIT` implícito puede cerrar una transacción ajena. Severidad: baja.**
`BEGIN;…COMMIT;` dentro de un script que puede estar ya envuelto en una transacción por la herramienta cliente.
*Corrección:* documentar que debe correr fuera de otra transacción.

## `heredado/base_heredada/transacciones.sql`

**H-33 — transacciones.sql:30-41 — "Dos sesiones" simuladas con `BEGIN` anidados en un solo archivo. Severidad: alta.**
En PG, un segundo `BEGIN` dentro de una transacción ya abierta es ignorado (warning "already in transaction"). No hay dos sesiones reales: el `COMMIT` de la línea 37 cierra la transacción de A. La prueba de aislamiento no prueba nada.
*Corrección:* correr dos `psql`/`pgAdmin` en paralelo, o `dblink`.

**H-34 — transacciones.sql:45 — `SET TRANSACTION ISOLATION LEVEL` fuera de transacción. Severidad: alta.**
El `SET TRANSACTION` debe ir antes del primer comando del bloque. Acá se ejecuta tras el `COMMIT` anterior y fuera de un `BEGIN`, por lo que queda ignorado (warning) y el bloque `SERIALIZABLE` de las líneas 47-55 corre en el nivel por defecto.
*Corrección:* `SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;` inmediatamente después de cada `BEGIN`.

**H-35 — transacciones.sql:63-69 — Escenario `FOR UPDATE` en una sola sesión. Severidad: alta.**
Ambos `CALL sp_crear_pedido` corren en la misma transacción de A. El segundo no se bloquea esperando a B: ve el stock ya descontado por el primero (misma sesión) y falla por "stock insuficiente" local. No demuestra el bloqueo entre sesiones.
*Corrección:* misma corrección que H-33: dos conexiones reales (B espera, luego A hace `COMMIT`).

**H-36 — transacciones.sql:5-6 — Escenario 1 sin verificación de atomicidad. Severidad: baja.**
Intenta `cantidad=999` pero no verifica que no quedó `pedido` ni que el stock quedó intacto (`SELECT * FROM pedido` sin filtro no aserta nada).
*Corrección:* consultar `stock` antes/después y contar filas del pedido, con comentarios de "esperado: …".

## `heredado/base_heredada/data.sql`

**H-37 — data.sql:23-108 — IDs implícitos por orden de inserción. Severidad: media.**
Asume que `categoria 1..5`, `producto 1..13`, `usuario 1..5` sin `RETURNING`. Cualquier dato previo o rerun rompe el mapeo silenciosamente.
*Corrección:* capturar con `CTE … RETURNING` o `SETVAL`/IDs explícitos.

**H-38 — data.sql:53, 68 — Baja lógica por `INSERT` + `UPDATE` en vez de `INSERT … eliminado=TRUE`. Severidad: baja.**
Inconsistente con `data.sql:17` (categoría eliminada directo). Dos statements donde basta uno; ensucia la historia.
*Corrección:* insertar directamente con `eliminado=TRUE`.

**H-39 — data.sql:58-68 — Placeholders de contraseña `hash_…`. Severidad: baja.**
Mismo riesgo que H-30, acá en el seed. `hash_inactivo` también.
*Corrección:* idem H-30.

**H-40 — data.sql:111-113 — `PENDIENTE → TERMINADO` directo. Severidad: baja.**
Muestra que la máquina de estados permisiva (H-12) ya se usa: `UPDATE pedido SET estado='TERMINADO' WHERE id=2` salta `CONFIRMADO`.
*Corrección:* pasar por `CONFIRMADO` o endurecer el trigger.

## `heredado/base_heredada/carga_masiva.sql`

**H-41 — carga_masiva.sql:10-114 — Todo en una sola transacción gigante (70k + 200k + 400k filas). Severidad: alta.**
Un `BEGIN` para 4 inserts masivos + `ALTER TABLE` + `UPDATE` masivo bloquea, infla WAL y si falla al final se descarta todo el trabajo.
*Corrección:* `COMMIT` por pasos (usuarios, productos, pedidos, detalles), o `INSERT` por lotes.

**H-42 — carga_masiva.sql:66 — `usuario_id` por aritmética, no por `RETURNING`. Severidad: alta.**
`((i % 20000)+1)` asume que los usuarios ocupan los IDs 1..20006 en ese orden. Si el seed cambia (otro conteo), asigna pedidos a usuarios equivocados/eliminados o viola FK. El comentario (líneas 55-57) dice que se capturan "IDs reales", pero solo captura IDs de *pedido*, no de usuario.
*Corrección:* `RETURNING id` de usuarios y mapear desde esa tabla temporal.

**H-43 — carga_masiva.sql:91 — `producto_id` por módulo sobre un rango asumido. Severidad: alta.**
`((pn.id*7+k) % 50000)+1` asume productos 1..50000. En realidad los bulk son 17..50016, así que los últimos productos nunca se venden y los seed/productos eliminados sí aparecen. Mismo fragilidad que H-42.
*Corrección:* mapear contra `id` reales capturados con `RETURNING`, excluyendo `eliminado=TRUE`.

**H-44 — carga_masiva.sql:71 — `TEMP TABLE pedidos_nuevos` sin `DROP` / `ON COMMIT DROP`. Severidad: media.**
Si se re-ejecuta en la misma sesión, `SELECT … INTO TEMP TABLE` falla con "relation already exists".
*Corrección:* `DROP TABLE IF EXISTS pedidos_nuevos` antes, o `CREATE TEMP TABLE … ON COMMIT DROP`.

**H-45 — carga_masiva.sql:78, 98 — `DISABLE TRIGGER trg_total_ins` como optimización. Severidad: media.**
Queda deshabilitado hasta la línea 98; si el script se aborta/killea en el medio (fuera de la transacción o en una versión por pasos tras H-41), los `INSERT` futuros no recalculan `total` en silencio. Además requiere ser dueño de la tabla.
*Corrección:* no deshabilitar (el trigger ya está en H-11 con el bug de re-cálculo), o envolver `DISABLE…ENABLE` en `SAVEPOINT`. Documentar el riesgo.

**H-46 — carga_masiva.sql:62 — `fecha` generada puede violar `CHECK (fecha <= CURRENT_DATE)`. Severidad: media.**
`'2025-01-01' + (i%500)` llega a ~mayo 2026. Si se corre antes de esa fecha, todo el bloque falla (H-04).
*Corrección:* generar fechas acotadas a `min(…, CURRENT_DATE)` o quitar el check.

**H-47 — carga_masiva.sql:103-112 — `UPDATE` de totales no crea filas para pedidos sin detalles vigentes. Severidad: baja.**
Un pedido con todos sus detalles en `eliminado=TRUE` no aparece en `subtotales`, así que su `total` queda stale (hoy no se nota porque el trigger lo dejó en 0, pero el patrón es frágil).
*Corrección:* `LEFT JOIN` + `COALESCE(total_calculado,0)`.

**H-48 — carga_masiva.sql:128-133 — Verificación con conteos esperados incorrectos. Severidad: baja.**
Dice `50018` productos esperados, pero `data.sql` siembra 16, no 18: lo correcto sería `50016`. `400000+` es ambiguo (físico 400013, vigentes 400011).
*Corrección:* corregir el comentario o reemplazarlo por conteos relativos (`COUNT(*) = 50000 + (SELECT COUNT(*) FROM … seed)`).

---

### Archivos sin hallazgos

Ninguno. Los 10 archivos tienen al menos un hallazgo.

### Incertidumbres declaradas (sin ejecutar)

- Si `jsonb_array_elements(NULL)` devuelve 0 filas o error depende de tu PG, pero el caso `'[]'` sí crea pedido vacío bajo cualquier versión razonable.
- El orden exacto trigger vs. `NOT NULL` sobre `precio_unitario` no lo verifiqué ejecutando; si el FK salta antes, H-10 se manifiesta como error de FK en vez de `NULL`, pero H-09 sigue abierto (precio inyectable).
