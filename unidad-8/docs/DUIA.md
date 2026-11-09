# Declaración de Uso de IA (DUIA) — TP N.º 8 Food Store

Declaración del equipo (Grupo 10). **Cada integrante declara su propio uso de IA**, con el formato de la cátedra, y firma su parte:
el texto de cada uno está completo más abajo y también en su archivo individual (`docs/duia_<nombre>.md`), que se conserva.
El registro detallado de las interacciones (qué se pidió, qué se aceptó y qué se descartó) está en [`bitacora_ia.md`](bitacora_ia.md);
las bitácoras individuales, en `docs/bitacoras/`.

| Integrante | Declaración individual | Resumen |
|---|---|---|
| Mariano Chirino | [`duia_mariano.md`](duia_mariano.md) | Claude (versión web), NotebookLM, Kiro y OpenCode (Nemotron 3.5, objetivo 11) |
| Andrés Fabre | [`duia_andres.md`](duia_andres.md) | Gemini (1.a, 3.a, 3.b y diagnóstico de errores) y, según declara, OpenCode / GPT-5.6 Terra para la revisión A4 completa y el contraste de 3.c (05/11) |
| Facundo Quiroga | [`duia_facundo.md`](duia_facundo.md) | OpenCode (agente Plan) para el code review de la 3.c |

**Criterio de este documento:** lo que cada integrante no dejó escrito (por ejemplo, el modelo y el prompt de OpenCode, o los logs de una corrida)
figura como «no consta», sin completarlo. Las notas de revisión de Mariano Chirino sobre los textos de sus compañeros están firmadas y fechadas.

---

## Declaración de Mariano Chirino

### Declaración de Uso de IA (DUIA) — Mariano Chirino

**Integrante:** Mariano Chirino (Grupo 10)
**Materia:** Base de Datos II (UTN) — Unidad 8, TP N.º 8
**Proyecto Integrador:** Food Store
**Alcance:** consignas 1 y 2 (base de la tablet en SQLite, instantánea, semáforo, casos C2 a C6), spec en Kiro (4.a), regeneración de la base de la tablet con OpenCode a partir de la spec (objetivo 11), armado del repositorio y revisión de los pull requests de Andrés y Facundo
**Herramientas:** Claude (versión web, claude.ai), NotebookLM, Kiro y OpenCode (agente Nemotron 3.5 Lightning Free, solo para regenerar la base de la tablet en el objetivo 11: dos corridas, 06/11 y 07/11). El code review de la consigna 3.c con OpenCode lo hizo Facundo (`duia_facundo.md`).

> Esta declaración cubre únicamente lo que hice y usé yo. Andrés Fabre y Facundo Quiroga
> declaran su propio uso de IA en `duia_andres.md` y `duia_facundo.md`.

---

#### Registro de interacciones y decisiones con IA

##### Consignas 1 y 2 — base de la tablet y sincronización

| Herramienta | Para qué se usó | Se aceptó / se descartó — por qué |
|---|---|---|
| NotebookLM | Resumir el apunte y pedir el código del `kit_u8_campus`, que no estaba en el campus | **Aceptado:** el SQL del esquema SQLite, `v_snapshot_movil` y la transacción del borrador, después de contrastarlos con las paradas 3, 4 y 5 del apunte: coincidían. **Descartado:** `simulador_sync.py`. Comparaba el resultado de `fetchone()` (una tupla) con el texto `'PENDIENTE'`, así que nunca habría evaluado nada; importaba `psycopg2` sin usarlo y nombraba una tabla `registro_sync` que no existe en el esquema. La IA lo había reconstruido, porque ese archivo no estaba en el campus. El semáforo se escribió en SQL puro. |
| Claude | Clasificar qué scripts de las Unidades 1 a 7 se reutilizan y armar la estructura del repo | **Aceptado:** `heredado/` con los scripts sin modificar. **Descartado:** ejecutar `pedidos_de_prueba.sql` y `carga_masiva.sql` (cambiarían el stock de los casos C3 y C5). Se cambió el usuario con nombre real de `data.sql` por uno inventado. |
| Claude | Borrador de `schema_sqlite.sql`, `cargar_catalogo.sql`, `pruebas_sqlite.sql`, `semaforo.sql` y los casos C2 a C6 | **Aceptado**, después de leerlo y correrlo. Alternativas que se evaluaron y se dejaron de lado (decisiones de diseño, no propuestas de la IA): `INSERT OR REPLACE` para recargar el catálogo (borra la fila y falla con la clave foránea activa) y un `UNIQUE` simple sobre `cola_sync.id_local` (impediría reenviar tras un `CONFLICTO`). Se aceptó el `UPSERT` y el índice parcial `ux_cola_una_pendiente`. Se aceptó el tratamiento explícito del producto inexistente en el `LEFT JOIN` (con `NULL`, un producto que no existe pasaría como verde). |
| Claude | Guiar la corrida en mi máquina con PowerShell | `sqlite3` no se reconocía después de instalarlo con `winget`: no creó el acceso directo en `WinGet\Links`. Se resolvió agregando al PATH la carpeta real del paquete. Se descartó la contraseña de `postgres` escrita en pantalla: se cambió a entrada oculta. |

##### Consigna 4.a — spec en Kiro

| Herramienta | Para qué se usó | Se aceptó / se descartó — por qué |
|---|---|---|
| Kiro | Generar `requirements.md`, `design.md` y `tasks.md` | **Se escribió después de los scripts, no antes** (el enunciado pide lo contrario). **Corregido en `requirements.md`:** el criterio 4 del Requisito 3 decía que el semáforo marca `eliminado = 1` en `producto_cache`; eso lo hace la recarga del catálogo, no el semáforo. **Corregido en `design.md`:** exportaba con `COPY producto` en lugar de la vista `v_snapshot_movil`; inventaba un transporte "llave USB / correo"; tenía invertida la fila de los booleanos y decía que la transacción hace rollback sola. **Descartado:** las pruebas de propiedades con Hypothesis (alcance de más: el TP no exige Python) y el límite de 255 caracteres en `motivo`, que el semáforo no impone. **No consta** el prompt exacto ni el modelo que usó Kiro: no se registraron. Fecha: los archivos de `.kiro/specs/` entraron al repo en el commit `ec9a60b` del 03/11/2026 (fecha del commit, no de creación). |
| Claude | Revisar lo que generó Kiro contra los scripts y las evidencias | Detectó los errores anteriores y que la tabla de pruebas del diseño no mencionaba `pruebas_sqlite.sql` (C1 y C7). Se corrigió. |

**Carpeta `.kiro/steering/`** (`conventions.md`, `project-overview.md`, `objects-and-patterns.md`): entró al repo en el commit `66392be` del 02/11/2026 («Estructura preliminar»). **No consta** con qué herramienta se escribió ni quién la redactó; se usa como referencia de convenciones del proyecto (por ejemplo, en el hallazgo H04 de la 3.c).

##### Objetivo 11 — regeneración de la base de la tablet con OpenCode desde la spec

| Herramienta | Para qué se usó | Se aceptó / se descartó — por qué |
|---|---|---|
| Claude (borrador) y Kiro (edición de la spec) | Ampliar la spec **antes** de generar: casos C1, C7, C8 y F2, esquema `STRICT`, recarga del catálogo y reglas del semáforo (Requisitos 5 a 10) | **Los Requisitos 5 a 10 los redactó Claude** como borrador y se pegaron en Kiro casi sin cambios (103 de 113 líneas idénticas); se leyeron y se aceptaron. El Requisito 11 (entregables, ejecución y evidencia) y el historial de revisiones no provienen de ese borrador. **No consta** con qué herramienta se redactaron; no se completa por memoria. Commit `be854e4` del 06/11/2026 15:38, anterior a la generación (`e9dd9f8`, 16:10). Después se corrigió el REQ 5.3 (13 productos visibles y no 14, tras ejecutar contra el CSV real, commit `a088c03`) y se agregaron el REQ 6.12 y el 6.13 el 07/11 (commit `772536a`). |
| OpenCode (agente Nemotron 3.5 Lightning Free) | Generar `schema_sqlite.sql`, `cargar_catalogo.sql`, `semaforo.sql` y `casos.sql` en `movil_opencode/` dándole solo `AGENTS.md` y la spec | **La corrida 1 no produjo una base funcional**: el esquema no se creó y por eso fallaron en cascada la carga, el semáforo y los casos (`evidencias/22_corrida1_con_errores.txt`). Se conservan los originales sin editar en `movil_opencode/original_opencode/` y el registro en `docs/registro_opencode_corrida1.txt` (commit `e9dd9f8`). **No consta** si OpenCode leyó `movil/` durante la corrida, aunque el prompt lo prohibía. |
| Claude (web) | Diagnosticar los errores de la corrida 1 y corregirlos; después comparar la versión corregida con los originales de `movil/` | **Aceptado, ejecutado y verificado por mí:** `STRICT` como opción de tabla, índice parcial fuera del `CREATE TABLE`, `motivo` nullable, `WHERE true` en el `UPSERT`, sin `DELETE` previo y semáforo reescrito con una CTE de causas; `casos.sql` reescrito con datos reales del CSV. **Descartado:** un cambio que Claude hizo en la vista (precio sin dividir por 100) por una suposición, contrario al REQ 5.2; se restauró. **Hallazgo de la comparación:** faltaban un valor por defecto en `pedido_borrador.creado_en` y la clave foránea de `cola_sync.id_local`; la spec no los pedía, así que se agregaron a la spec (REQ 6.12 y 6.13) y después al esquema. Evidencias `22` a `27` y `docs/comparacion_generado_vs_original.md`. |
| OpenCode (agente Nemotron 3.5 Lightning Free), corrida 2 | Repetir la generación, sin editar, en una carpeta aislada (`C:\corrida2_opencode`) que no contenía `movil/`, `docs/` ni `evidencias/`; se le dieron `AGENTS.md`, la spec (REQ 5 a 13), `.kiro/steering/` y `servidor_snapshot.csv`. 07/11/2026, de 09:39 a 09:50 | **Tampoco produjo una base funcional.** Se conserva sin editar en `movil_opencode_v2/` (commits `dc1ead0` y `55cb059`) y el registro (prompt y respuesta cruda) en `docs/registro_opencode_corrida2.txt`. Nueve defectos (`docs/comparacion_generado_vs_original.md`, sección 8): `cargar_catalogo.sql` con el mismo error de sintaxis de la corrida 1; ninguna tabla es `STRICT`; falta el `CHECK` de `motivo`; falta el `PRAGMA foreign_keys = ON;` en seis scripts; `criada_en` mal escrito; `BEGIN TRY/CATCH` de otro motor; un `SELECT` sin `FROM`; no existe `casos.sql`; mensajes de C7 que se imprimen siempre. **Descartado:** las afirmaciones de su respuesta («5 tablas STRICT», «sintaxis revisada», «`PRAGMA` en cada script»), que son falsas; el propio agente dijo no haber ejecutado nada. **Aceptado como evidencia, sin corregir:** `semaforo.sql` y los `DEFAULT` y la clave foránea del esquema. No se agrega ningún requisito por esta corrida: los incumplimientos son contra REQ ya escritos. La versión final sigue siendo `movil_opencode/`. Evidencias `28` y `29`. |
| Claude (web) | Analizar la evidencia 28 contra la spec, redactar la sección 8 de la comparación y proponer el script de la evidencia 29 (motivo `NULL`, clave foránea con y sin `PRAGMA`, modo `STRICT`) | **Aceptado, después de leer el script y correrlo yo** en SQLite 3.54.1 (Windows): confirmó por ejecución los defectos 2, 6 y 7 (`evidencias/29_corrida2_motivo_fk_strict.txt`, commit `229c018`). **Corregido:** un primer intento falló porque pegué las líneas con el prompt `PS` y PowerShell las ejecutó como `Get-Process`; se rehízo desde un `.ps1`. **Declarado como límite, sin tocar la spec:** `v_catalogo_disponible` sin `capturado_en` y la falta de un criterio `OK`/`FALLA` en el REQ 11. |
| Kiro | Se tocó la spec solo para el registro: al abrirla, Kiro cambió el encabezado `## Glosario` por `## Glossary` en `requirements.md` | **Descartado** con `git checkout` (sin contenido nuevo). Comportamiento observado, no un cambio pedido. |

**Declaración honesta:** los scripts que funcionan hoy en `movil_opencode/` son en su mayor parte reescrituras hechas con Claude a partir de los errores de la corrida 1. De OpenCode quedan la estructura general y algunas ideas de casos. La corrida 2 (sin editar, sin `movil/` a la vista) tampoco funcionó; se conserva como evidencia.

##### Revisión del trabajo de un compañero (PR #1 de Andrés Fabre)

| Herramienta | Para qué se usó | Se aceptó / se descartó — por qué |
|---|---|---|
| Claude | Revisar el pull request: clonar la rama, leer los archivos y probar los scripts | **Descartado del PR:** la carpeta `sqlite/` y los dos `tp8_database.db` (un esquema de ejemplo con `precio REAL`, sin `STRICT` ni centavos, que acepta texto como precio: no es el esquema del TP), y el `movil/foodstore_movil.db` vacío, que habría pisado la base con la evidencia de los casos. **Corregido:** 1.a, 3.a y 3.b tenían columnas inexistentes, ubicaban la cola en PostgreSQL, describían MongoDB como metadatos de productos y daban autoridad local a SQLite; se reescribieron contra el esquema real y `v_snapshot_movil`, y cada archivo lo aclara. Se verificó cada dato contra `schema.sql` y `esquema_documental.md`. |

##### Revisión del trabajo de un compañero (PR #2 de Facundo Quiroga)

| Herramienta | Para qué se usó | Se aceptó / se descartó — por qué |
|---|---|---|
| Claude (web) | Revisar el pull request (code review 3.c, bitácora y DUIA) y contrastar cada afirmación con los scripts del repo y con lo que ejecuté en mi máquina | **Descartado (H36):** la IA de Facundo afirmaba que `pruebas_sqlite.sql` dejaba un borrador a medias; lo corrí en una base limpia y da 1/2/1 antes y después de C7 (cada bloque de C7 termina en `ROLLBACK`): `evidencias/17`. **Descartado con fundamento (H04):** el índice compuesto sí se usa si se fuerza (`enable_seqscan = off`) y con 13 filas no mejora nada: `evidencias/15`. **Aceptado, comprobado en una copia de la base:** H01 (`sp_crear_pedido` acepta un pedido de un producto de categoría eliminada) y el producto repetido en `p_items` (`SQLSTATE 23505`): `evidencias/16`. **Corregido:** nombre de la vista (`v_snapshot_movil`), estados del semáforo, sigla DUIA, versiones. Lo que Facundo no dejó escrito (modelo de OpenCode, prompt, fecha) se declaró como «no consta», sin completarlo. |
| Claude (web) | Armar casos borde del semáforo para la revisión cruzada (F2), porque el caso propio de Facundo verificaba el esquema y no el semáforo | **Aceptado después de correrlo yo:** `movil/casos_f2_semaforo.sql` (rojo + amarillo, producto fuera de la instantánea, sin ítems, no disponible, control, dos pendientes): `evidencias/18` y `19`. Quedan atribuidos a mí, no a Facundo. |

---

#### Verificación sobre el motor real

Todo se probó en mi máquina (Windows PowerShell 5.1): PostgreSQL 17.10 con la base de pruebas `foodstore_u8`, armada desde cero con los scripts de `heredado/`, y SQLite 3.54.1.

1. Corrida completa de C1 a C7 con las salidas guardadas en `evidencias/01` a `12`.
2. Prueba de que PostgreSQL no cambió: `verificar_no_cambio.sql` antes y después, con la misma huella de stock `89f8351d0162e23ef1473f32b05ce221`.
3. Paso 5 del protocolo de seguridad: `postgresql/verificar_vista_snapshot.sql` y `movil/verificar_vistas_tablet.sql`, con las salidas en `evidencias/13` y `14`.
4. Comprobación de los hallazgos de la 3.c de Facundo (H36, H01, H04 y R1) sobre una copia de la base: salidas en `evidencias/15` a `17` y script `postgresql/verificar_hallazgos_3c.sql`.

5. Casos borde del semáforo (F2): `movil/casos_f2_semaforo.sql`, con las salidas en `evidencias/18` y `19`.
6. Versión de OpenCode (objetivo 11): corrida 1 sin editar (`evidencias/22`), versión corregida (`23` a `25`), casos F2 originales contra la versión corregida (`26`) y `casos.sql` tras los REQ 6.12 y 6.13 (`27`).

7. Corrida 2 de OpenCode, sin editar (`evidencias/28`) y verificación adicional de los defectos de motivo, clave foránea y `STRICT` en SQLite 3.54.1 (`evidencias/29`).

Ninguna propuesta de la IA se incorporó sin leerla y correrla.

#### Resumen de decisiones

| Aspecto | Resultado |
|---|---|
| Semáforo | SQL puro: rojo gana sobre amarillo; solo evalúa `PENDIENTE`; el producto que falta en la instantánea es rojo |
| Recarga del catálogo | `INSERT … ON CONFLICT DO UPDATE`; la lápida conserva la fila |
| Reenvío de una solicitud | `UUID` como clave primaria; índice parcial para permitir reenviar solo tras un `CONFLICTO` |
| Código de la cátedra | No se usó: el `kit_u8_campus` no estaba disponible |
| Spec de Kiro | Primera versión (03/11): posterior al código; declarado. Objetivo 11: revisada y con commit antes de generar con OpenCode (06/11, `be854e4`) |
| Regeneración con OpenCode | Las corridas 1 y 2 no funcionaron sin editar; la versión final (`movil_opencode/`) se corrigió con Claude y se declara; originales (`original_opencode/`, `movil_opencode_v2/`) conservados |

#### Declaraciones del 07/11/2026 (cierre de la segunda entrega)

##### 1. Merges a `main` sin revisión cruzada
Todos los merges del 07/11 los hizo Mariano Chirino sin revisión cruzada (Facundo Quiroga no respondió y no hay ninguna rama suya). Se pide una lectura posterior a Andrés Fabre.

| PR | Rama | Contenido | Hora |
|---|---|---|---|
| #6 | `m/obj-11` | Objetivo 11: SQLite con OpenCode, comparación y evidencias | 15:12 |
| #7 | `m/informe-u8` | `docs/informe/u8.md` | 15:52 |
| #8 | `m/obj-06` | Objetivo 6: auditoría de `roles.sql`, correcciones H1, H3 y H4b | 18:16 |
| #9 | `m/docs-cierre` | README raíz, `u5.md`, introducción, bitácora unificada | 18:42 |
| #10 | `m/bitacora-cierre` | Parte F de la bitácora de la U5 | 18:51 |
| #5 | `a/obj-10` | Objetivo 10, de Andrés Fabre; lo mergeó Mariano | 19:00 |
| #11 | `m/fix-obj-10` | Correcciones de Mariano a `a/obj-10` y repetición de la medición | 19:09 |
| #12 | `m/limpieza-u7` | Datos de ejemplo de la U7 regenerados sin nombres reales | 19:32 |
| #13 | `m/fix-obj-07` | `a/obj-07` de Andrés Fabre (objetivo 7) con correcciones de Mariano | 20:06 |

##### 2. Trabajo de Mariano sobre archivos de Andrés
- **`a/obj-10` (U7):** se corrigió `u7.md` contra la evidencia (MongoDB figuraba con 10 ms y la salida dice `executionTimeMillis: 0`; se quitó una afirmación sobre el `$lookup` que no estaba medida), se repitió la medición con base propia y se verificaron las referencias en ambos motores. Los límites están declarados en `comparacion_medida.md`.
- **`a/obj-07` (U6):** se leyeron línea por línea `backup_foodstore.ps1`, `restore_test.ps1`, `crear_rol_respaldo.sql`, `programar_tareas.ps1` y `validar_integridad.sql`. Se corrigió `restore_test.ps1` para que exija y registre los 6 controles de integridad. Se repitieron respaldo, simulacro, roles (T01 a T23, 23 de 23), Programador de tareas, mantenimiento y Pester. `docs/informe/u6.md` se amplió con la repetición y los límites.

##### 3. Asistencia de Claude
Con asistencia de Claude se redactaron y se verificaron contra las salidas crudas: los scripts de repetición de la U6 y la U7, la corrección de `u7.md` y `u6.md`, `docs/informe/u5.md`, `unidad-5/docs/auditoria_roles_opencode.md`, `docs/informe/00_introduccion_uso_ia_limitaciones.md` y el `README.md` raíz. El hallazgo H4b salió de una revisión con Claude, no de OpenCode.

##### 4. Auditoría de `roles.sql` con OpenCode
La sesión original no se conserva. La auditoría del 07/11 es una repetición (Nemotron 3.5 Lightning, modo Plan, carpeta `C:\auditoria_roles`) que salió en 3 partes por 2 interrupciones; los mensajes de las interrupciones los redactó Claude. Hora de la parte 1: 16:38, a verificar; partes 2 y 3: no consta. Registro: `unidad-5/docs/registro_opencode_auditoria_roles_corrida2.txt`.

##### 5. Evidencias con tratamiento especial
- Cinco evidencias de H3 y H4b se generaron en UTF-16 y se convirtieron a UTF-8 sin cambiar el contenido (commit `6346e09`).
- `unidad-6/evidencias/obj7_repeticion2_mariano_restore_20261107_194601.txt` quedó interrumpido durante `pg_restore`; la causa no consta. Se conserva sin editar, con su nota.
- Las salidas de `psql` en español traen `ï¿½` en algunas líneas por codificación de la consola; no se editaron.
- Las evidencias conservan rutas locales y el nombre del equipo (`host` en salidas de `explain`); no se editaron para no alterar lo que prueban.
- La prueba de H1 en base sucia se corrió en consola y no se guardó.

##### 6. Límites del entorno de Mariano
- El `pg_hba.conf` usa `trust`: las pruebas verifican permisos, no autenticación.
- Las tareas del Programador se registraron, se dispararon a mano y se desregistraron; no se observó ninguna ejecución por horario.
- Se ejecutó un `ANALYZE` manual sobre la copia `foodstore` (la copia por plantilla no traía estadísticas).
- `log_statement = all` sigue activo en el servidor local; las contraseñas de prueba de T04 y T14 quedan en ese log, que no está en el repositorio.

##### 7. Datos en el historial de Git
El repositorio es público. Un correo y un apellido de un integrante estuvieron en `unidad-7/modelo/pedidos_export.json` y en dos archivos más; se regeneraron, pero siguen en el historial. No se reescribió el historial.

##### 8. Otros
- Requisito 11 de la spec de la U8: no consta con qué herramienta se redactó.
- `roles.sql` cambió tres veces en `m/obj-06` (H1, H3, H4b); quien lo edite debe partir de `main` actual.
- Las preguntas al profesor sobre el objetivo 11 y el formato del repo no se enviaron; se resolvió con criterio propio y se declara. Tampoco hubo defensa oral en las entregas anteriores.

---

#### Declaraciones del 09/11/2026 (cierre del objetivo 13 y declaraciones pendientes del 08/11)

##### 1. Revisión del PR #18 y trabajo sobre la rama de Facundo (08/11)
- El PR #18 (`f/obj-02-u4-migration`, objetivo 2, de Facundo Quiroga) lo revisó Mariano con Claude, sin revisión independiente de Andrés Fabre. Mariano además aportó commits a esa rama (PR #20 y PR #21, de `m/fix-pr18-revision`). El #18 se mergeó el 08/11.
- Se revisaron `up.sql`, `down.sql`, `setup_previo.sql` y `verificar_migracion.sql`: sin errores de código. Lo corregido fue de texto y evidencia (informe y DUIA se contradecían sobre Gemini; faltaban citas de `migracion_up.png` y `migracion_down.png`; se agregaron límites del objetivo 2).
- Los caminos de falla de `up.sql` (repetido y datos que violan `R -> D`) se reprodujeron en pgAdmin sobre `copia_u4`, una copia local (PostgreSQL 17), con cuatro capturas `migracion_falla_*` en `unidad-4/capturas/`. El `down.sql` repetido no tiene captura propia.
- **Sin confirmar por Facundo** (no respondió; Mariano decidió no esperar el 08/11): si el primer borrador fue de Gemini, si se ejecutó en pgAdmin y quién sacó `migracion_up.png` y `migracion_down.png` (PostgreSQL 18, subidas por la cuenta `Buhonero009`, commit `5a2472f`). El informe y la DUIA dicen «sin confirmar».
- La frase de la DUIA de Facundo sobre credenciales la actualizó Mariano (commit `a3ad2d5`).
- El script `corregir_pr18_parte2.ps1` y los bloques de PowerShell de esa revisión se redactaron con Claude y no se editaron en Kiro.
- En `unidad-7/AGENTS.md` (archivo de Andrés) se quitó el nombre de un integrante (commit `4969ce3`, PR #23).
- La introducción (`docs/informe/00_introduccion_uso_ia_limitaciones.md`) se redactó con Claude.
- Búsqueda de credenciales en el repositorio (08/11): tres comprobaciones (palabras clave, hashes, archivos tipo `pgpass`, `.env` y claves); solo se encontraron marcadores y contraseñas de prueba. No se revisó el contenido de los PDF.

##### 2. Objetivo 13 (code review con IA): quién lo hizo y cómo
- La tarea T9 estaba asignada a Facundo Quiroga y la hizo Mariano (reasignación del 08/11), entre el 08 y el 09/11.
- Herramienta: OpenCode en modo Plan (solo lectura). El modelo figura en las cabeceras de las tandas como «Croutou Alpha Free» (01, 07 y 08) y «Crouton Alpha Free» (09, 10 y 11); no se pudo verificar cuál es el nombre exacto.
- 11 tandas; cada respuesta se guardó cruda en `docs/auditoria_codigo/tanda_NN_*.md`. La primera corrida de la tanda 01 salió con el marcador de la lista de archivos sin reemplazar: se guardó como corrida fallida y se repitió en `tanda_01_repeticion.md`.
- La tanda 05 no siguió el formato (sin ids ni severidad): sus 27 filas de `hallazgos.md` las armó Mariano con Claude a partir de la prosa de OpenCode.
- El 09/11 se completaron los campos Modelo, Fecha, Estado y Total en las cabeceras de las tandas 01 a 06 (commit `e815760`). Las respuestas de OpenCode no se editaron.
- `hallazgos.md` tiene 196 filas. Se decidió sobre 42 (las 35 altas y críticas y 7 más); 154 quedan «No evaluado». Solo 14 decisiones tienen ejecución propia (`T06-H-01`, `T06-H-02` con un archivo de prueba y no con el script real, `T06-H-17`, `T01-H-34` con el comando solo y `T11-H-01` a `-06` y `-08` a `-11`); el resto se decidió por lectura de código.
- Las decisiones se cargaron por lote, con scripts de PowerShell redactados con Claude y ejecutados por Mariano; los motivos de las filas se redactaron con Claude contra las salidas que pegó Mariano. Los commits están separados por grupo y no hay un commit por hallazgo.
- No se corrigió ningún script: `git diff pre-review main` sobre `unidad-4` a `unidad-8` salió vacío el 09/11.
- `codereview.md` se redactó con Claude.
- Las filas «Claude, no OpenCode»: solo `C-05` tiene decisión; `C-01` a `C-04` y `C-06` no la tienen.
- El merge de `review-final` a `main` (PR #24, `4313ac5`, 09/11) lo hizo Mariano sin revisión cruzada.

##### 3. Evidencias del objetivo 13 con tratamiento especial
- `T06-H-01_pester_sin_llamada.txt` es un `Start-Transcript` y trae usuario, equipo y ruta locales en la cabecera; se conserva sin editar.
- Para esa prueba se modificó temporalmente la copia de trabajo de `unidad-6/restore_test.ps1` (se reemplazaron las llamadas a `Verificar-Hash`); quedó sin cambios respecto de `HEAD` (`git status` vacío).
- `T06-H-17_version_pester.txt` está en UTF-16 porque ya estaba commiteado; el resto de la evidencia nueva se convirtió de UTF-16 a UTF-8 sin cambiar el contenido (copia de respaldo en `%TEMP%`, commit `bd8d271`).
- `T11-H-11_f2_huerfanas.txt` se conserva pero no se usa como prueba de `T11-H-11`: `producto_cache` estaba vacío en esa corrida.
- `T11-H-08` y `T11-H-09` se probaron con el paso 6 del README simulado, no con el paso real de PostgreSQL.
- Los acentos rotos de algunas salidas (por ejemplo `├¡`) vienen de la consola de PowerShell 5.1 y no se editaron.
- La prueba de `T06-H-02` se hizo con un archivo de ejemplo en la carpeta temporal (ya borrado) y la de `T01-H-34` sobre la base `postgres` del servidor local; ninguna modificó datos.

## Declaración de Andrés Fabre

### Declaración de Uso de Inteligencia Artificial (DUIA)

**Estudiante:** Andrés Fabre  
**Proyecto / Trabajo Práctico:** TP N.º 8 — Food Store (Capa de datos y entorno móvil)  
**Asignación individual:** Entregables 1.a (datos que viajan), 3.a (mapa de la capa de datos), 3.b (plan de mantenimiento) y revisión cruzada de consignas 1 y 2 (A4).

---

#### 1. Herramientas de IA Utilizadas

| Herramienta / Modelo | Versión / Plataforma | Propósito principal |
|---|---|---|
| **Gemini** | Gemini 3 Flash / Web (Free Tier) | Asistencia en estructuración de Markdown, redacción de documentos técnicos (1.a, 3.a, 3.b), diagnóstico de errores CLI en Windows 11 e interpretación de hashes de verificación. |

---

#### 2. Declaración de Prompts e Interacciones Clave

##### Interacción 1: Redacción de entregables documentales (1.a, 3.a, 3.b)
* **Objetivo:** Generar borradores claros y concisos en formato Markdown para los entregables asignados en `docs/partes/`.
* **Prompt representativo:** 
  > *"Ayúdame a redactar los documentos 1.a (qué datos de producto viajan a la tablet y fuente de verdad), 3.a (mapa de la capa de datos integrando PostgreSQL, MongoDB y SQLite) y 3.b (plan de mantenimiento extendido de la U6)."*
* **Resultado / Aceptación:** Se aceptaron las tablas y justificaciones conceptuales previa verificación contra la arquitectura del proyecto y las restricciones del enunciado.

##### Interacción 2: Diagnóstico de error en SQLite (`schema_sqlite.sql`)
* **Objetivo:** Resolver error `Parse error: table producto_cache already exists` al intentar ejecutar los scripts de revisión cruzada en Windows 11.
* **Prompt representativo:**
  > *"Al ejecutar `sqlite3 movil/foodstore_movil.db .read movil/schema_sqlite.sql` me tira error de que las tablas ya existen."*
* **Resultado / Aceptación:** Se aceptó la sugerencia de la IA de eliminar el archivo local preexistente (`del movil\foodstore_movil.db`) antes de recrear el esquema, solucionando el problema inmediatamente.

##### Interacción 3: Interpretación de resultados de verificación (`verificar_no_cambio.sql`)
* **Objetivo:** Confirmar el significado de los valores obtenidos durante la prueba de no modificación de PostgreSQL.
* **Prompt representativo:**
  > *"Al ejecutar `postgresql/verificar_no_cambio.sql` me dio 6 pedidos, 13 detalles, 454 stock total y el hash MD5 `89f8351d0162e23ef1473f32b05ce221`, ¿es normal?"*
* **Resultado / Aceptación:** Se aceptó la explicación de la IA que confirmó el cumplimiento de la prueba de integridad mediante la preservación del estado inicial.

##### Interacción 4: Revisión completa A4 y contraste de 3.c
* **Fecha:** 05/11/2026.
* **Herramienta:** OpenCode / asistente GPT-5.6 Terra.
* **Objetivo:** Completar la revisión cruzada pendiente: reproducir el flujo desde cero (H0, C1, C7 y C2 a C6), verificar las dos vistas y revisar los hallazgos de 3.c con sus evidencias.
* **Prompt representativo:**
  > *"Revisá mi parte del TP8 contra la división, ejecutá la revisión cruzada pendiente desde cero sobre una copia y verificá los hallazgos documentados de 3.c sin modificar los scripts funcionales."*
* **Resultado / Aceptación:** Se aceptaron únicamente los resultados obtenidos en los motores: H0 dio 6 / 16 / 6; C2 a C6 y C1/C7 dieron los resultados esperados; las vistas no tuvieron diferencias; pedidos y stock no cambiaron. H36 y H04 se descartaron con fundamento; H01 y R1 se confirmaron como hallazgos documentados. Las salidas se guardaron en `evidencias/20_andres_revision_a4_completa.txt` y `evidencias/21_andres_revision_3c.txt`.

---

#### 3. Metodología de Verificación y Control Humano

1. **Lectura y revisión de código/texto:** Ninguna propuesta redactada por la IA se incorporó al repositorio sin una lectura y edición previa para garantizar consistencia con los requerimientos específicos de la materia.
2. **Prueba directa en motor de base de datos:** Las consultas de verificación y comandos CLI fueron ejecutados manualmente en la consola de Windows 11 sobre PostgreSQL 17.11 y SQLite 3.54.1, asegurando que las salidas (`0 filas` en diferencias y hashes idénticos) comprobaran empíricamente el correcto funcionamiento del sistema.
3. **Actualización del 05/11/2026:** La corrida completa se hizo en copias descartables: PostgreSQL 17.11 y SQLite CLI 3.54.1 (biblioteca Python 3.50.4). No se modificó la base de trabajo del equipo ni scripts funcionales.

---

#### 4. Compromiso Ético y Firma

Declaro haber utilizado la Inteligencia Artificial de forma transparente y colaborativa como apoyo pedagógico y técnico, asumiendo la responsabilidad total sobre los contenidos, validaciones y conclusiones presentadas en mis entregables individuales del TP 8.

**Firma:** Andrés Fabre
**Fecha:** 04 de Noviembre de 2026

---

#### Nota de revisión del equipo (Mariano Chirino, 04/11/2026)

Esta nota la agrega Mariano al integrar el PR #1. La declaración anterior es de Andrés y no se modificó.

- Las aceptaciones de la Interacción 1 se refieren a los borradores originales de 1.a, 3.a y 3.b. Esos documentos tenían errores contra el esquema
  real (columnas inexistentes, la cola ubicada en PostgreSQL, MongoDB descripto como metadatos de productos y SQLite con «autoridad local») y
  fueron corregidos por Mariano en `docs/partes/`. La verificación que se declara en la sección 3 no detectó esos errores.
- La carpeta `sqlite/` y los archivos `tp8_database.db` no son parte de la entrega: eran un esquema de ejemplo distinto del esquema del TP.
- Las interacciones 2 y 3 (error de `already exists` e interpretación de la huella) se corresponden con la revisión cruzada A4, cuyos resultados
  coinciden con los de Mariano.

---

#### Actualización firmada — 05/11/2026

La Interacción 4 completa y evidencia la revisión A4 que antes estaba documentada solo de manera parcial. Mantengo la nota de Mariano para distinguir con transparencia los borradores originales de 1.a, 3.a y 3.b de sus versiones corregidas presentes en el repositorio.

**Firma:** Andrés Fabre
**Fecha de actualización:** 05 de Noviembre de 2026

---

## Declaración de Facundo Quiroga

### Declaración de Uso de IA (DUIA) — Facundo Quiroga

**Integrante:** Facundo Quiroga
**Materia:** Base de Datos II (UTN) — Unidad 8, TP N.º 8
**Proyecto Integrador:** Food Store
**Alcance:** code review de los scripts con IA (3.c), verificación del entorno (H0) y revisión del semáforo (F2)
**Herramientas:** OpenCode, agente Plan (solo lectura). *Modelo y proveedor: dato pendiente de Facundo.*

> Texto de Facundo (PR #2) con correcciones de Mariano Chirino del 05/11/2026, marcadas con *[corregido]*.
> Esta declaración cubre únicamente lo que usó y decidió Facundo.

---

#### 1. Registro del uso de IA

| Herramienta | Para qué se usó | Se aceptó / se descartó — por qué |
|---|---|---|
| OpenCode (agente Plan) | Revisar los scripts de la cursada y proponer hallazgos | **Aceptado, después de comprobarlo en la base:** H01 (`sp_crear_pedido` no mira la categoría eliminada) y R1 (producto repetido en `p_items`). **Descartado:** H36 (la IA dijo que habría un commit parcial en `pruebas_sqlite.sql`; el script da los mismos conteos antes y después de C7 y cada bloque termina en `ROLLBACK`) y H04 (un índice por `producto_id` no mejora nada con 13 filas y `conventions.md` no permite agregarlos). |

*Prompt, fecha y cantidad total de hallazgos propuestos por la IA: dato pendiente de Facundo (no consta por escrito).*

#### 2. Análisis técnico: PostgreSQL y SQLite

1. **Tipado.** PostgreSQL controla los tipos desde su definición. SQLite usa *type affinity* por defecto; la directiva `STRICT` del esquema móvil
   (`schema_sqlite.sql`) hace que un texto en una columna entera se rechace en la tablet antes de sincronizar.
2. **Transacciones en el CLI.** En PostgreSQL, un error dentro de un bloque inhabilita lo siguiente hasta el `ROLLBACK`. En el CLI de SQLite, un error en una sentencia
   no aborta la transacción salvo con `-bail`. *[corregido]* Eso se pensó como riesgo en `pruebas_sqlite.sql` (hallazgo H36), pero se comprobó que el script no lo sufre:
   cada bloque de C7 termina en `ROLLBACK`.
3. **Claves foráneas.** En SQLite hay que activarlas con `PRAGMA foreign_keys = ON;` en cada conexión; sin eso, C7.b no daría error.

#### 3. Evaluación del semáforo (F2)

- **Evaluación local.** El semáforo clasifica con la instantánea guardada (`producto_cache` y `snapshot_servidor`) sin conexión al servidor.
- **Casos borde.** La precedencia y los demás casos de borde (producto fuera de la instantánea, borrador sin ítems, producto no disponible, dos pendientes del mismo borrador) los ejecutó Mariano en `movil/casos_f2_semaforo.sql` (`evidencias/18` y `19`); no figuran logs de Facundo.
- **Precedencia.** El rojo gana sobre el amarillo. *[corregido]* Son rojos (`RECHAZADO`): producto inexistente, no disponible, dado de baja o sin stock suficiente.
  Es amarillo (`CONFLICTO`): un precio que cambió, **sin umbral** (cualquier diferencia cuenta). Verde: `SIMULADO_APROBADO`, que **no es una venta**.
- **Asimetría H01.** *[corregido]* La vista `v_snapshot_movil` exporta como lápida (`eliminado = t`) los productos de categorías eliminadas, así que la tablet los rechaza; el procedimiento
  `sp_crear_pedido` del servidor no mira la categoría y acepta el pedido. Es una inconsistencia entre piezas heredadas y se documenta, sin modificar el código heredado.

#### 4. Conclusión personal

Usar un agente de IA acelera la lectura de muchos scripts, pero sus afirmaciones no valen hasta correrlas: de los hallazgos comprobados, dos eran ciertos y dos no se sostenían
(H36 era falso para este script; H04 era cierto pero irrelevante con este volumen). La verificación en el motor real es lo que separa un hallazgo de una suposición.

---

#### Nota de revisión del equipo (Mariano Chirino, 05/11/2026)

- Se corrigió el nombre de la sigla (Declaración de Uso de IA) y los puntos marcados *[corregido]*. Se quitaron las afirmaciones sin respaldo del texto original
  (planes de ejecución y «pruebas unitarias» sobre cada hallazgo; solo H04 usó `EXPLAIN`).
- Quedan pendientes de Facundo los datos que solo él conoce: modelo y proveedor de OpenCode, prompt, fecha, total de hallazgos de la IA y qué salió de OpenCode y qué de otra fuente.
  Según lo que dejó escrito, no hay logs adjuntos de sus comprobaciones; las salidas que respaldan las decisiones son las de Mariano (`evidencias/15` a `17`).
