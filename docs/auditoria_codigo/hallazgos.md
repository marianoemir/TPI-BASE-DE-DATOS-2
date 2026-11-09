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
- La tanda 05 se corrió en una sesión nueva, pero OpenCode igual citó `unidad-5/AGENTS.md` y sus reglas (el agente lo carga por su cuenta). No siguió el formato pedido: devolvió prosa por archivo, sin ids ni severidad. Las filas T05 las armó Mariano con Claude a partir de los puntos que la IA marcó como «Problemas»; los ids y la partición en filas no son de la IA, y la severidad queda como «no informada». Se descartó como hallazgo lo que la IA marcó como «Bien» y las duplicaciones entre archivos se agruparon en una sola fila.
- Desde la tanda 06 el prompt lleva una línea final: «Devolvé exactamente el formato indicado: un id H-nn y una severidad por hallazgo, sin resumen por archivo.» La tanda 06 respondió en ese formato.
- `T06-H-15` cita `backend_foodstore.ps1`, un nombre que no está en la lista: se toma como error de tipeo de la IA por `backup_foodstore.ps1`, a confirmar al reproducir.

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

## Tanda 05 — `unidad-5/sql/` simulacro, auditoría y pruebas (`tanda_05_unidad5_pruebas.md`)

Autoría: scripts de la U5 de Mariano (según la división de trabajo); confirmar archivo por archivo. Severidad no informada por la IA (ver límites del proceso).

| ID | Archivo:línea | Resumen | Severidad (IA) | Autor | Decisión | Motivo | Prueba |
|---|---|---|---|---|---|---|---|
| T05-H-01 | simulacro_incidente.ps1:27-28 | `$PassSoporte='Sim-Soporte-2026'` es una clave inventada versionada; el SQL fija otra distinta (`simulacro_incidente.sql:39`, `ClaveSimulacro-2026`) | no informada | Mariano (U5) | | | |
| T05-H-02 | simulacro_incidente.ps1:57; simulacro_incidente.sql:44-48 | La clave de `rol_soporte` viaja en la línea de comandos de `psql` (`-v`) y `CREATE ROLE … PASSWORD` la deja en texto claro en el log | no informada | Mariano (U5) | | | |
| T05-H-03 | simulacro_incidente.ps1:81 | No valida `log_statement='all'`; solo deja un recordatorio y, si se olvida, la evidencia queda incompleta | no informada | Mariano (U5) | | | |
| T05-H-04 | simulacro_incidente.ps1:107 | El Paso 3 exige `>= 20000` filas: depende de haber cargado `carga_masiva.sql` y reporta `REVISAR` aunque el mecanismo funcione | no informada | Mariano (U5) | | | |
| T05-H-05 | simulacro_incidente.ps1:57-59 | `-f ('"{0}"' -f $sql)` es frágil con rutas con espacios en PowerShell 5 | no informada | Mariano (U5) | | | |
| T05-H-06 | simulacro_incidente.sql (sin línea) | No tiene guard de base; todo el resguardo está en el `.ps1` y a mano se podría correr contra la plantilla | no informada | Mariano (U5) | | | |
| T05-H-07 | simulacro_incidente.sql:106 | `DELETE FROM usuario` contra la regla de baja lógica, sin documentar la excepción de la limpieza del fixture | no informada | Mariano (U5) | | | |
| T05-H-08 | auditoria_test.ps1:43-45 | `Marca()` interpola `$texto` dentro de `SELECT '$texto'`: seguro con las constantes actuales, no por construcción | no informada | Mariano (U5) | | | |
| T05-H-09 | auditoria_test.ps1:51, 53-56 | Sin `$ErrorActionPreference='Stop'` ni chequeo de `LASTEXITCODE`: si falla el Paso 1 igual corre el Paso 2 | no informada | Mariano (U5) | | | |
| T05-H-10 | auditoria_test.sql:26-40 | Corre como `postgres`, no como `app_web`, aunque el comentario dice lo contrario: la evidencia del log no prueba mínimo privilegio | no informada | Mariano (U5) | | | |
| T05-H-11 | auditoria_test.sql / .ps1 (sin línea) | No advierte anonimizar el log; `fn_autenticar` con claves de prueba queda textual | no informada | Mariano (U5) | | | |
| T05-H-12 | prueba_h1_correccion.ps1:4 | Sin guard de base ni `PGPASSWORD`; ruta `unidad-5\sql\roles.sql` hardcodeada que asume el directorio actual | no informada | Mariano (U5) | | | |
| T05-H-13 | prueba_h1_correccion.ps1:6 | `Q()` mezcla `2>&1` en stdout: no distingue error de éxito | no informada | Mariano (U5) | | | |
| T05-H-14 | prueba_h1_correccion.ps1:34 | No crea `unidad-5/evidencias/` si no existe; `WriteAllLines` falla | no informada | Mariano (U5) | | | |
| T05-H-15 | prueba_h1_correccion.ps1:19 | Verifica con `has_schema_privilege` pero sin aserción programática; hay que leer `f`/`t` a ojo | no informada | Mariano (U5) | | | |
| T05-H-16 | prueba_h2b_hash.ps1 (varias) | Mismas fragilidades que H1: ruta de PostgreSQL 17 hardcodeada, sin guard, sin password, ruta relativa | no informada | Mariano (U5) | | | |
| T05-H-17 | prueba_h2b_hash.ps1:16 | `clave_historica_prueba` es otra clave versionada (descartable) | no informada | Mariano (U5) | | | |
| T05-H-18 | prueba_h3_correccion.ps1 (varias) | Mismo patrón frágil que H1 (sin guard, rutas relativas, salida solo textual) | no informada | Mariano (U5) | | | |
| T05-H-19 | prueba_h3_correccion.ps1:19 | La consulta de membresías filtra `LIKE 'rol_%'` y el «esperado: solo 3» no se puede verificar sin leer `roles.sql` | no informada | Mariano (U5) | | | |
| T05-H-20 | prueba_h3_correccion.ps1:21 | `has_function_privilege` sobre `sp_crear_pedido` depende de si es `SECURITY DEFINER`; el script no lo asegura | no informada | Mariano (U5) | | | |
| T05-H-21 | prueba_h3_h4b.sql:18-31 | Revoca todas las membresías grupo→grupo, no solo la de H3: el antes/después puede interpretarse mal | no informada | Mariano (U5) | | | |
| T05-H-22 | prueba_h3_h4b.sql / correccion_h4b.sql / prueba_h4b_trigger.sql | Los nombres confunden el rol de cada archivo (diagnóstico, corrección y prueba) | no informada | Mariano (U5) | | | |
| T05-H-23 | prueba_h4b_trigger.sql:5-6 | Exige un usuario y un producto con stock; en base vacía `:uid`/`:pid` quedan `NULL` y falla por dato, no por permiso | no informada | Mariano (U5) | | | |
| T05-H-24 | prueba_h4b_trigger.sql:7, 10 | `SET LOCAL ROLE` + `RESET ROLE` dentro de la transacción: `current_user` posterior debe leerse con cuidado | no informada | Mariano (U5) | | | |
| T05-H-25 | correccion_h4b.sql:5-6 | Revoca `EXECUTE` a `PUBLIC` sin `GRANT` compensatorio ni verificación posterior | no informada | Mariano (U5) | | | |
| T05-H-26 | correccion_h4b.sql (alcance) | No cubre `sp_crear_pedido`, `fn_autenticar` ni `fn_resetear_password`: lista de rutinas incompleta | no informada | Mariano (U5) | | | |
| T05-H-27 | correccion_h4b.sql (cita) | Cita `unidad-5/evidencias/h2b_h4b_prueba.txt` sin el prefijo `obj6_` que usan H1, H2b y H3: trazabilidad inconsistente | no informada | Mariano (U5) | | | |

## Tanda 06 — `unidad-6/` scripts PowerShell (`tanda_06_unidad6_ps1.md`)

Autoría: scripts de Andrés; correcciones de Mariano con Claude en el PR #13 (6 controles en `restore_test.ps1`, entre otras). Confirmar archivo por archivo. Andrés no fue consultado.

| ID | Archivo:línea | Resumen | Severidad (IA) | Autor | Decisión | Motivo | Prueba |
|---|---|---|---|---|---|---|---|
| T06-H-01 | tests/ampliacion.Tests.ps1:27-33 | La prueba de orden usa `IndexOf('Verificar-Hash')`, que encuentra la definición de la función (`restore_test.ps1:45`) y no la llamada: pasa aunque se elimine la verificación previa a `createdb` | alta | Andrés (+ Mariano, PR #13) | | | |
| T06-H-02 | programar_tareas.ps1:50 | La tarea de mantenimiento no usa `-v ON_ERROR_STOP=1`: `psql -f` sigue tras errores SQL y sale con código 0, así que la tarea reporta éxito aunque el mantenimiento falle | alta | Andrés (+ Mariano, PR #13) | | | |
| T06-H-03 | backup_foodstore.ps1:123-139 | Si falla `pg_dumpall` o su hash tras mover `datosFinal`, el `catch` solo borra los `.parcial` y deja un `.dump` y `.sha256` huérfanos sin globales que la retención nunca limpia | media | Andrés (+ Mariano, PR #13) | | | |
| T06-H-04 | restore_test.ps1:136-158 | El «último respaldo» se elige ordenando alfabéticamente cualquier `*.dump` sin filtrar `foodstore_*.dump`: un archivo ajeno mayor lexicográficamente provoca error | media | Andrés (+ Mariano, PR #13) | | | |
| T06-H-05 | programar_tareas.ps1:14-15, 50 | `$Base` de mantenimiento no se valida como en respaldo y restauración: cambiar el parámetro corre `maintenance.sql` contra otra base | media | Andrés (+ Mariano, PR #13) | | | |
| T06-H-06 | programar_tareas.ps1:43-45 | `LogonType Interactive`: las tareas solo corren con sesión iniciada (límite ya declarado en el informe de la U6) | media | Andrés (+ Mariano, PR #13) | | | |
| T06-H-07 | tests/ampliacion.Tests.ps1:20-64 | Toda la suite son regex sobre el texto fuente: pasa con código comentado o muerto y no verifica invariantes reales (límite ya declarado: Pester solo busca texto) | media | Andrés (+ Mariano, PR #13) | | | |
| T06-H-08 | restore_test.ps1:290, 298, 335 | Sin `$ErrorActionPreference` global y tres llamadas nativas sin el bloque `Continue`/`$LASTEXITCODE` del resto: con `Stop` la redirección `2>&1` lanza antes del chequeo | media | Andrés (+ Mariano, PR #13) | | | |
| T06-H-09 | programar_tareas.ps1:50 | El `psql` de mantenimiento omite `-h` y `-p`, a diferencia de respaldo y restauración | baja | Andrés (+ Mariano, PR #13) | | | |
| T06-H-10 | programar_tareas.ps1:49-51 | Las tres tareas usan `-ExecutionPolicy Bypass` sin `-NonInteractive` ni `-StartWhenAvailable`; un horario perdido no se recupera | baja | Andrés (+ Mariano, PR #13) | | | |
| T06-H-11 | restore_test.ps1:41 | `Escribir-Log` usa `Add-Content -Path` en vez de `-LiteralPath`: rutas con `[`, `]` o `*` se interpretan como patrón | baja | Andrés (+ Mariano, PR #13) | | | |
| T06-H-12 | restore_test.ps1:72, 85 | `Consultar-Psql` mezcla `stderr` con el resultado (`2>&1`): un aviso de `psql` contamina el escalar que se compara | baja | Andrés (+ Mariano, PR #13) | | | |
| T06-H-13 | backup_foodstore.ps1:99-101 | `Remove-Item` de retención sin guarda de existencia: si falta un archivo, un respaldo exitoso se reporta como `ERROR` (salida 1) | baja | Andrés (+ Mariano, PR #13) | | | |
| T06-H-14 | backup_foodstore.ps1:35, 112-123 | Marca de tiempo con granularidad de segundo: dos ejecuciones en el mismo segundo colisionan | baja | Andrés (+ Mariano, PR #13) | | | |
| T06-H-15 | backend_foodstore.ps1:132 (sic) | El log solo registra la ruta final, sin tamaño ni hash (nombre de archivo a confirmar, ver límites) | baja | Andrés (+ Mariano, PR #13) | | | |
| T06-H-16 | restore_test.ps1:355 | Exige exactamente 6 controles de integridad hardcodeados: cambiar `validar_integridad.sql` rompe el simulacro sin indicar la causa | baja | Andrés (+ Mariano, PR #13) | | | |
| T06-H-17 | tests/ampliacion.Tests.ps1:12-63 | Sintaxis `Should Be`/`Should Match` (Pester 4), deprecada en Pester 5 a favor de `Should -Be` (el entorno usa Pester 3.4.0) | baja | Andrés (+ Mariano, PR #13) | | | |

## Totales (según la IA)

| Tanda | Hallazgos | Alta | Media | Baja | Crítica |
|---|---|---|---|---|---|
| 01 | 48 | 12 | 20 | 16 | 0 |
| 02 | 16 | 1 | 9 | 6 | 0 |
| 03 | 14 | 1 | 4 | 9 | 0 |
| 04 | 16 | 2 | 7 | 7 | 0 |
| 05 | 27 | n/i | n/i | n/i | n/i |
| 06 | 17 | 2 | 6 | 9 | 0 |
| **Total** | **138** | **18** | **46** | **47** | — |

n/i = no informada. Los totales por severidad cubren las tandas 01 a 04 y 06 (111 hallazgos); los 27 de la tanda 05 no traen severidad.

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
