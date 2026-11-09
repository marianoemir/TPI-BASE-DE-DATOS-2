# Hallazgos del code review (T9, objetivo 13)

Fuente: respuestas crudas de OpenCode (modo Plan) guardadas en `docs/auditoria_codigo/tanda_NN_*.md`.
Repo congelado: etiqueta `pre-review` (`351ddb9`), rama `review-final`.

**Cómo se lee**
- **ID**: `T<tanda>-H-<n>`. OpenCode reinicia la numeración en cada tanda, por eso se antepone la tanda.
- **Severidad**: la que dio la IA (no se modifica).
- **Archivo:línea**: como los citó la IA, sin verificar hasta reproducir.
- **Autor**: quien escribió el script; no fue consultado. `<completar>` = falta confirmarlo.
- **Decisión**: aceptado, corregido o descartado. **Motivo** y **Prueba** (ruta en `docs/auditoria_codigo/evidencias/`) se completan al reproducir en una copia. Si no se llega a reproducir: «aceptado/descartado, no reproducido» más el motivo.
- Varios hallazgos se repiten entre archivos (mismo patrón en seeds y scripts). Se reproduce una vez y los duplicados remiten a ese.

**Límites del proceso (declarar en `codereview.md`)**
- Las tandas se corrieron en la misma sesión de OpenCode: las respuestas citan `AGENTS.md`, reglas del proyecto y archivos de tandas anteriores. No se le adelantaron hallazgos, pero tuvo contexto que no estaba en la lista de archivos.
- La tanda 01 tuvo una corrida fallida previa (marcador sin reemplazar), guardada en `tanda_01_heredado.md`.

## Tanda 01 — `heredado/base_heredada/` (`tanda_01_repeticion.md`)

| ID | Archivo:línea | Resumen | Severidad (IA) | Autor | Decisión | Motivo | Prueba |
|---|---|---|---|---|---|---|---|
| T01-H-01 | schema.sql:45 | `mail UNIQUE` incluye usuarios eliminados lógicamente | alta | `<completar>` | | | |
| T01-H-02 | schema.sql:16 | `categoria.nombre UNIQUE` incluye categorías eliminadas | media | `<completar>` | | | |
| T01-H-03 | schema.sql:27 | `producto.nombre` no es único pero otros archivos lo usan como clave | media | `<completar>` | | | |
| T01-H-04 | schema.sql:61 | `CHECK (fecha <= CURRENT_DATE)` depende del momento de ejecución | media | `<completar>` | | | |
| T01-H-05 | schema.sql:46, 28, 76, 63 | Validaciones incompletas e inconsistentes (vacíos, precio 0) | baja | `<completar>` | | | |
| T01-H-06 | schema.sql:78 | `ON DELETE RESTRICT` solo en `detalle_pedido`; resto implícito | baja | `<completar>` | | | |
| T01-H-07 | schema.sql:82, 90-96 | Falta índice por `producto_id` en `detalle_pedido`; índice de nombre solapado | media | `<completar>` | | | |
| T01-H-08 | schema.sql:7-14 | No idempotente (sin `IF NOT EXISTS`) | baja | `<completar>` | | | |
| T01-H-09 | objects.sql:60-65 | `fn_set_subtotal()` no congela el precio (acepta `precio_unitario` manual) | alta | `<completar>` | | | |
| T01-H-10 | objects.sql:61-62 | Producto inexistente: sin error de negocio, falla por `NOT NULL` | media | `<completar>` | | | |
| T01-H-11 | objects.sql:90-96 | Falta trigger de `DELETE` para recalcular `pedido.total` | alta | `<completar>` | | | |
| T01-H-12 | objects.sql:99-107 | Máquina de estados incompleta (solo bloquea `CONFIRMADO → PENDIENTE`) | media | `<completar>` | | | |
| T01-H-13 | objects.sql:118-143 | `sp_crear_pedido` acepta pedido vacío (`'[]'`) | alta | `<completar>` | | | |
| T01-H-14 | objects.sql:142-143 | Sin validación de `cantidad`/`producto_id` nulos o inválidos | media | `<completar>` | | | |
| T01-H-15 | objects.sql:141-164 | Productos duplicados en `p_items` violan `UNIQUE` con error críptico | media | `<completar>` | | | |
| T01-H-16 | objects.sql:43-172 | Funciones y procedure sin `SET search_path` | media | `<completar>` | | | |
| T01-H-17 | objects.sql:22-28, 30-36 | Vistas muestran estado actual (total denormalizado, nombre actual), no histórico | baja | `<completar>` | | | |
| T01-H-18 | views.sql:21-31 | `v_usuario_seguro` no filtra eliminados y expone `celular` y `mail` | media | `<completar>` | | | |
| T01-H-19 | views.sql:5-12 | Referencia a ruta externa que no es parte del repo | baja | `<completar>` | | | |
| T01-H-20 | materializadas.sql:13 | La MV no filtra `detalle_pedido.eliminado` (facturación inflada) | alta | `<completar>` | | | |
| T01-H-21 | materializadas.sql:13 | La MV solo cuenta `CONFIRMADO`; otros archivos usan `CONFIRMADO` y `TERMINADO` | media | `<completar>` | | | |
| T01-H-22 | materializadas.sql:15-20 | `ORDER BY` en la MV y sin política de `REFRESH` | baja | `<completar>` | | | |
| T01-H-23 | materializadas.sql:8 | `SUM(cantidad*precio_unitario)` en vez de `SUM(subtotal)` | baja | `<completar>` | | | |
| T01-H-24 | indices.sql:24-26 | Índice de nombre redundante con `schema.sql:96` | media | `<completar>` | | | |
| T01-H-25 | indices_semana3.sql:11-13 | Orden de columnas `(fecha, estado)` subóptimo | media | `<completar>` | | | |
| T01-H-26 | indices_semana3.sql:17-19 | Índice compuesto vuelve redundante `idx_pedido_usuario_id` | baja | `<completar>` | | | |
| T01-H-27 | queries.sql:28-41 | El archivo muta el seed y no es re-ejecutable | media | `<completar>` | | | |
| T01-H-28 | queries.sql:52-62 | No filtra `c.eliminado`; diverge de `v_productos_vigentes` | media | `<completar>` | | | |
| T01-H-29 | queries.sql:72-75 | `COALESCE(NULL, stock)` es un no-op confuso | baja | `<completar>` | | | |
| T01-H-30 | queries.sql:94-96 | Contraseñas de ejemplo en claro (`'hash_diego'`) | media | `<completar>` | | | |
| T01-H-31 | queries.sql:159-187 | Analíticas incluyen cancelados/pendientes y eliminados | alta | `<completar>` | | | |
| T01-H-32 | queries.sql:148-151 | `BEGIN…COMMIT` puede cerrar una transacción ajena del cliente | baja | `<completar>` | | | |
| T01-H-33 | transacciones.sql:30-41 | «Dos sesiones» simuladas con `BEGIN` anidados en un solo archivo | alta | `<completar>` | | | |
| T01-H-34 | transacciones.sql:45 | `SET TRANSACTION ISOLATION LEVEL` fuera de transacción (ignorado) | alta | `<completar>` | | | |
| T01-H-35 | transacciones.sql:63-69 | Escenario `FOR UPDATE` en una sola sesión: no prueba el bloqueo | alta | `<completar>` | | | |
| T01-H-36 | transacciones.sql:5-6 | Escenario 1 sin verificación de atomicidad | baja | `<completar>` | | | |
| T01-H-37 | data.sql:23-108 | IDs implícitos por orden de inserción | media | `<completar>` | | | |
| T01-H-38 | data.sql:53, 68 | Baja lógica por `INSERT` + `UPDATE` en vez de insertar con `eliminado=TRUE` | baja | `<completar>` | | | |
| T01-H-39 | data.sql:58-68 | Placeholders de contraseña `hash_…` | baja | `<completar>` | | | |
| T01-H-40 | data.sql:111-113 | `PENDIENTE → TERMINADO` directo (usa la máquina de estados permisiva) | baja | `<completar>` | | | |
| T01-H-41 | carga_masiva.sql:10-114 | Todo en una sola transacción gigante | alta | `<completar>` | | | |
| T01-H-42 | carga_masiva.sql:66 | `usuario_id` por aritmética, no por `RETURNING` | alta | `<completar>` | | | |
| T01-H-43 | carga_masiva.sql:91 | `producto_id` por módulo sobre un rango asumido (1..50000) | alta | `<completar>` | | | |
| T01-H-44 | carga_masiva.sql:71 | `TEMP TABLE pedidos_nuevos` sin `DROP` / `ON COMMIT DROP` | media | `<completar>` | | | |
| T01-H-45 | carga_masiva.sql:78, 98 | `DISABLE TRIGGER trg_total_ins` puede quedar deshabilitado si se aborta | media | `<completar>` | | | |
| T01-H-46 | carga_masiva.sql:62 | `fecha` generada puede violar `CHECK (fecha <= CURRENT_DATE)` | media | `<completar>` | | | |
| T01-H-47 | carga_masiva.sql:103-112 | `UPDATE` de totales no cubre pedidos sin detalles vigentes | baja | `<completar>` | | | |
| T01-H-48 | carga_masiva.sql:128-133 | Conteos esperados de verificación incorrectos (`50018` vs `50016`) | baja | `<completar>` | | | |

## Tanda 02 — `unidad-4/` (`tanda_02_unidad4.md`)

| ID | Archivo:línea | Resumen | Severidad (IA) | Autor | Decisión | Motivo | Prueba |
|---|---|---|---|---|---|---|---|
| T02-H-01 | tp_fnbc_control_lote.sql:25 | `DELETE FROM usuario` físico en la limpieza del demo (duplica T03-H-01) | media | `<completar>` | | | |
| T02-H-02 | tp_fnbc_control_lote.sql:49-64 | `OVERRIDING SYSTEM VALUE` no avanza la secuencia (duplica T03-H-02) | media | `<completar>` | | | |
| T02-H-03 | tp_fnbc_control_lote.sql:41, 47 | `lote.codigo` y `deposito.nombre` sin `UNIQUE` (duplica T03-H-04) | baja | `<completar>` | | | |
| T02-H-04 | tp_fnbc_control_lote.sql:67-72 | FK `responsable_control_id` sin índice ni acción referencial explícita (duplica T03-H-06) | baja | `<completar>` | | | |
| T02-H-05 | tp_fnbc_control_lote.sql:62-64 | Contraseñas de ejemplo `hash_resp801` (duplica T03-H-03, T01-H-30) | media | `<completar>` | | | |
| T02-H-06 | tp_fnbc_control_lote.sql:159-176, 283-292, 303-309 | Pruebas y `down` dentro de `/* */`: al correr el archivo completo no se ejecutan | baja | `<completar>` | | | |
| T02-H-07 | tp_fnbc_control_lote.sql:227-230 | `NATURAL JOIN` frágil en la vista (duplica T03-H-05) | baja | `<completar>` | | | |
| T02-H-08 | tp_fnbc_control_lote.sql:198-202, 270-282 | La PK nueva no preserva `{L,D} → R` (limitación que el archivo reconoce, sin trigger) | media | `<completar>` | | | |
| T02-H-09 | tp_desnormalizacion_top_categorias.sql:25 | `UPDATE pedido SET fecha = CURRENT_DATE` sin transacción: destructivo y reproducible solo el mismo día | alta | `<completar>` | | | |
| T02-H-10 | tp_desnormalizacion_top_categorias.sql:36-48, 122-123 | Baseline y MV sin `pr.eliminado` ni `c.eliminado` | media | `<completar>` | | | |
| T02-H-11 | tp_desnormalizacion_top_categorias.sql:46, 157 | `GROUP BY c.nombre` y `LIMIT 5` sin desempate | baja | `<completar>` | | | |
| T02-H-12 | tp_desnormalizacion_top_categorias.sql:103-107 | Cambio estructural sin `pg_dump` previo (desvío que el archivo declara) | media | `<completar>` | | | |
| T02-H-13 | tp_desnormalizacion_top_categorias.sql:111-125 | La MV materializa todo el historial y el reporte lee solo el día | media | `<completar>` | | | |
| T02-H-14 | tp_desnormalizacion_top_categorias.sql:130-131, 139 | Orden del índice único y afirmación de que `REFRESH CONCURRENTLY` no puede ir en transacción (a verificar) | baja | `<completar>` | | | |
| T02-H-15 | tp_desnormalizacion_top_categorias.sql:140-141, 165-177 | Costo-beneficio no demostrado (6,8 s de refresh vs 6 ms de ahorro) | media | `<completar>` | | | |
| T02-H-16 | tp_desnormalizacion_top_categorias.sql:192-206 | La auditoría compara solo `total_vendido` y usa los mismos filtros que la MV | media | `<completar>` | | | |

## Tanda 03 — `unidad-4/migracion/` (`tanda_03_migracion.md`)

Autoría según PR #18: `setup_previo.sql`, `up.sql`, `down.sql` y `verificar_migracion.sql` de Facundo; `pruebas_falla.sql` de Mariano con Claude (`ca2bbf8`). Facundo no fue consultado.

| ID | Archivo:línea | Resumen | Severidad (IA) | Autor | Decisión | Motivo | Prueba |
|---|---|---|---|---|---|---|---|
| T03-H-01 | setup_previo.sql:24 | `DELETE` físico de usuarios 801-803 contra la regla de baja lógica | media | Facundo (PR #18) | | | |
| T03-H-02 | setup_previo.sql:37-50 | `OVERRIDING SYSTEM VALUE` sin `setval` (sospecha; la IA no verificó) | media | Facundo (PR #18) | | | |
| T03-H-03 | setup_previo.sql:47-50 | Contraseñas de ejemplo `hash_resp801` | baja | Facundo (PR #18) | | | |
| T03-H-04 | setup_previo.sql:27-35 | `codigo` y `nombre` sin `UNIQUE` ni control de vacío | baja | Facundo (PR #18) | | | |
| T03-H-05 | up.sql:56-59 | `NATURAL JOIN` frágil en la vista de compatibilidad | baja | Facundo (PR #18) | | | |
| T03-H-06 | up.sql:35-44 | FK `responsable_deposito.deposito_id` sin índice | baja | Facundo (PR #18) | | | |
| T03-H-07 | up.sql:17-31 | No verifica que exista `control_lote_almacen` antes de migrar | baja | Facundo (PR #18) | | | |
| T03-H-08 | down.sql:13-15 | `DROP IF EXISTS` en silencio: asimetría con `up.sql` | baja | Facundo (PR #18) | | | |
| T03-H-09 | down.sql:6-9 | Avisa de pérdida de datos pero no respalda | media | Facundo (PR #18) | | | |
| T03-H-10 | verificar_migracion.sql:8-13 | V1 solo enumera 3 objetos; no ve la tabla de origen | baja | Facundo (PR #18) | | | |
| T03-H-11 | verificar_migracion.sql:16-23 | V2/V3 dan error si se corren después del `down` | baja | Facundo (PR #18) | | | |
| T03-H-12 | pruebas_falla.sql:27 | `INSERT` sin comentar en un archivo que dice «no se corre entera» | alta | Mariano con Claude (`ca2bbf8`) | | | |
| T03-H-13 | pruebas_falla.sql:7-9 | Procedimiento dependiente de pestañas de pgAdmin; no reproducible por consola | media | Mariano con Claude (`ca2bbf8`) | | | |
| T03-H-14 | pruebas_falla.sql:23-30 | La prueba B no verifica antes que el par `(502,31)` no exista | baja | Mariano con Claude (`ca2bbf8`) | | | |

## Tanda 04 — `unidad-5/sql/` roles y verificaciones (`tanda_04_unidad5_roles.md`)

Autoría: scripts de la U5 de Mariano (según la división de trabajo); confirmar archivo por archivo.

| ID | Archivo:línea | Resumen | Severidad (IA) | Autor | Decisión | Motivo | Prueba |
|---|---|---|---|---|---|---|---|
| T04-H-01 | roles.sql:20 | Protección por lista de bases excluidas, no por `copia_u5`; la cabecera dice otra cosa | media | Mariano (U5) | | | |
| T04-H-02 | roles.sql:64, 68 | `admin_datos` y `app_web` con la misma contraseña marcador `cambiar_en_produccion` | alta | Mariano (U5) | | | |
| T04-H-03 | roles.sql:240-243 | `ALTER DEFAULT PRIVILEGES` solo `FOR ROLE admin_datos`; objetos nuevos de `postgres` vuelven a dar `EXECUTE` a `PUBLIC` | alta | Mariano (U5) | | | |
| T04-H-04 | roles.sql:108-111 | Cuatro funciones de trigger sin `SET search_path` | media | Mariano (U5) | | | |
| T04-H-05 | roles.sql:141-147 | `fn_autenticar` no maneja hashes ficticios: `crypt()` con sal inválida | media | Mariano (U5) | | | |
| T04-H-06 | roles.sql:154-166 | `fn_resetear_password` sin validar la clave nueva ni que el usuario exista | media | Mariano (U5) | | | |
| T04-H-07 | roles.sql:248-249 | Efecto de revocar `EXECUTE` sobre funciones de trigger no demostrado (especulativo) | baja | Mariano (U5) | | | |
| T04-H-08 | verificacion_roles.sql:30-41 | `probar()` ejecuta SQL dinámico sin `USING` (arnés de prueba) | media | Mariano (U5) | | | |
| T04-H-09 | verificacion_roles.sql:17-18, 86, 103 | Contraseña de prueba `NuevaClave123` en texto plano | baja | Mariano (U5) | | | |
| T04-H-10 | verificacion_roles.sql:60-104 | Sin pruebas de `CREATE` ni de `EXECUTE` sobre rutinas públicas (parte puede estar en los `prueba_h*` de la tanda 05) | media | Mariano (U5) | | | |
| T04-H-11 | verificacion_roles.sql:75-77 | T07 verifica que la función no falle, no que el login funcione | baja | Mariano (U5) | | | |
| T04-H-12 | usuario_anon.sql:16-25 | `CREATE TABLE AS` pierde `NOT NULL`, `UNIQUE`, `CHECK` y parte de los tipos | media | Mariano (U5) | | | |
| T04-H-13 | usuario_anon.sql:14 | `DROP` y `CTAS` sin transacción | baja | Mariano (U5) | | | |
| T04-H-14 | usuario_anon.sql:10-11 | La cabecera promete menos columnas de las que crea | baja | Mariano (U5) | | | |
| T04-H-15 | verificacion_equivalencia.sql:30-31, 48-51 | `FULL JOIN` con `=` no compara `NULL` | baja | Mariano (U5) | | | |
| T04-H-16 | verificacion_equivalencia.sql:6-52 | Muestra resultados pero no asevera (sin `RAISE EXCEPTION`) | baja | Mariano (U5) | | | |

## Totales (según la IA)

| Tanda | Hallazgos | Alta | Media | Baja | Crítica |
|---|---|---|---|---|---|
| 01 | 48 | 12 | 20 | 16 | 0 |
| 02 | 16 | 1 | 9 | 6 | 0 |
| 03 | 14 | 1 | 4 | 9 | 0 |
| 04 | 16 | 2 | 7 | 7 | 0 |
| **Total** | **94** | **16** | **40** | **38** | **0** |

## Sección aparte — origen «Claude, no OpenCode»

Candidatos que salieron de revisiones hechas en el chat con Claude. Se declara el origen y se reproducen en copia.

| ID | Archivo | Resumen | Origen | Decisión | Motivo | Prueba |
|---|---|---|---|---|---|---|
| C-01 | unidad-5/sql/ | `PUBLIC` con `EXECUTE` en rutinas viejas (OpenCode lo halló por su cuenta en T04-H-03) | Claude, no OpenCode | | | |
| C-02 | unidad-6/restore_test.ps1 | La restauración pierde dueños y permisos | Claude, no OpenCode | | | |
| C-03 | unidad-6/backup_foodstore.ps1 | El respaldo no verificaba su SHA-256 (corregido el 07/11) | Claude, no OpenCode | | | |
| C-04 | unidad-6/ | Conteos comparados a mano | Claude, no OpenCode | | | |
| C-05 | unidad-7/correr_correcciones_obj10.ps1 | El encabezado nombra `$env:PGPASSWORD` (va contra la regla de la U6); falta ver si el script lo usa | Claude, no OpenCode | | | |
| C-06 | unidad-6/maintenance.sql | El «sin acción» original pudo deberse a estadísticas en cero tras `createdb -T` | Claude, no OpenCode | | | |
