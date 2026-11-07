# Bitácora personal — Mariano Chirino

Registro de lo que hice y por qué, para poder volver a consultarlo. Se unifica al final en `docs/bitacora_ia.md`.

## Mi parte

Según `DIVISION_DE_TRABAJO.md`:

- Consigna 1: esquema SQLite (`schema_sqlite.sql`, `cargar_catalogo.sql`) y pruebas (`pruebas_sqlite.sql`).
- Consigna 2: instantánea y CSV, semáforo (`semaforo.sql`), casos C2 a C6 y verificación de que PostgreSQL no cambió.
- Requisitos y diseño en Kiro (4.a), integración del repo.
- Al final: `informe.pdf`, `README.md`, unificación de bitácoras y etiqueta `tp8` (pendiente).
- Además: revisión del PR #1 de Andrés (1.a, 3.a y 3.b) e integración al repo.

## Mi entorno (H0)

| Servidor y versión | Conteos de `usuario`, `producto`, `pedido` | Problemas y cómo se resolvieron |
|---|---|---|
| PostgreSQL 17.10 (`foodstore_u8`), SQLite 3.54.1, Windows con PowerShell 5.1 | 6 / 16 / 6 (el pedido 4 está dado de baja) | `python` apuntaba a un acceso directo falso: se usa `py`. `psql` no está en el PATH: se usa la ruta completa. En consola los acentos de los mensajes de `psql` salen rotos; es solo la consola, no el dato ni el CSV. |

## Interacciones con IA (Kiro y Claude)

| Prompt enviado a la IA | Respuesta relevante recibida (resumida) | Validación o corrección humana aplicada |
|---|---|---|
| Kiro: generar `requirements.md`, `design.md` y `tasks.md` | Spec completa, pero escrita **después** de los scripts (el enunciado pide lo contrario; está declarado). | Corregí `requirements.md` (el semáforo no marca `eliminado` en `producto_cache`; eso lo hace la recarga) y `design.md` (exportaba con `COPY producto` en vez de `v_snapshot_movil`, inventaba un transporte, tenía invertida la fila de booleanos y decía que la transacción hace rollback sola). Descarté las pruebas de propiedades con Hypothesis y el límite de 255 caracteres en `motivo`. |
| Claude: revisar lo que generó Kiro contra los scripts y las evidencias | Detectó los errores anteriores y que la tabla de pruebas del diseño no mencionaba `pruebas_sqlite.sql` (C1 y C7). | Se corrigió el diseño. |
| Claude: revisar el PR #1 de Andrés (clonar la rama, leer y probar) | Sus 1.a, 3.a y 3.b tenían columnas inexistentes en `producto`, la cola ubicada en PostgreSQL, MongoDB descripto como metadatos de productos y SQLite con «autoridad local». El PR traía además `sqlite/`, dos `tp8_database.db` y un `foodstore_movil.db` vacío. | Verifiqué cada dato contra `schema.sql` y `esquema_documental.md`. Descarté `sqlite/`, los `.db` de ejemplo y el `.db` vacío (habría pisado la base con la evidencia de C2 a C6). Reescribí las tres partes. |
| Claude: qué decirle a Andrés sobre la fila de MongoDB de la 3.a | Propuso la fila (colección `pedidos` de `foodstore_nosql`, copia de lectura, PostgreSQL manda, no viaja a la tablet) y avisó que MongoDB tiene 7 pedidos y `foodstore_u8` tiene 6. | Usé la fila como base de la `3a`. |
| Claude: revisar mi `3a` corregida | Detectó que seguía diciendo «5 pedidos migrados» (valor arrastrado del borrador de Andrés) cuando `esquema_documental.md` dice 7: 1, 2, 3, 5 y 6 de `data.sql` más el 7 y el 8 de prueba. | Corregido a 7 y subido en un commit aparte (`5f073d6`). Mi propia corrección había arrastrado el error: lo verifiqué recién después. |
| Claude: pasos para integrar el PR #1 y cerrar el push rechazado | Plan: mergear desde la web de GitHub, corregir en un commit y, cuando el push fue rechazado, registrar el merge remoto con `git merge -s ours`. Primero pidió comprobar con `git diff --stat main origin/main` que la diferencia era solo lo que se quería descartar. | Lo comprobé y apliqué. Resultado: `main` quedó sin `sqlite/` ni `.db` vacío, con el `.db` en 16 y 6. |
| Claude: comandos para las evidencias 13 y 14 | Función `Ev` con contraseña oculta (`-AsSecureString`) y salida guardada en `evidencias/`. | Corrí los comandos, comparé con lo esperado y recién después los subí. |
| OpenCode (Nemotron 3.5 Lightning Free), corrida 1, 06/11 16:10: generar el esquema, la carga, el semáforo y los casos desde `AGENTS.md` y la spec | Cuatro scripts; el esquema no se pudo crear (`STRICT` dentro de las columnas, `UNIQUE … WHERE` dentro del `CREATE TABLE`) y fallaron en cascada la carga, el semáforo y los casos | Conservé los originales sin editar (`original_opencode/`, commit `e9dd9f8`). Corregí con Claude lo mínimo para que corra y lo declaré; evidencias 22 a 25 |
| Claude: comparar `movil_opencode/` con `movil/` (07/11) | Faltaban `DEFAULT` en `creado_en` y la clave foránea de `cola_sync.id_local`; la spec no los pedía | Los agregué a la spec (REQ 6.12 y 6.13, commit `772536a`) y después al esquema; evidencias 26 y 27 |
| OpenCode, corrida 2, 07/11 09:39 a 09:50, carpeta aislada sin `movil/` | Nueve defectos: mismo error de sintaxis en la carga, ninguna tabla `STRICT`, sin `CHECK` de `motivo`, sin `PRAGMA` en seis scripts, `criada_en`, `BEGIN TRY/CATCH`, `SELECT` sin `FROM`, sin `casos.sql`, mensajes de C7 siempre impresos. Afirmó «5 tablas STRICT» y «sintaxis revisada» sin haber ejecutado nada | No lo edité: `movil_opencode_v2/` queda como evidencia (commits `dc1ead0` y `55cb059`). Ejecuté y guardé la salida (evidencia 28) |
| Claude: analizar la evidencia 28 y proponer la evidencia 29 | Script con tres pruebas (A: `motivo` `NULL`; B: clave foránea con y sin `PRAGMA`; C: `typeof` y `STRICT`) | Lo corrí desde un `.ps1` en SQLite 3.54.1: confirmó los defectos 2, 6 y 7. Commit `229c018` |

## Revisión cruzada que hice

| Qué revisé | En qué servidor lo ejecuté | Qué encontré |
|---|---|---|
| `1a`, `3a` y `3b` de Andrés (PR #1) | Contra `schema.sql` y `esquema_documental.md` (lectura y comparación, sin motor) | Los errores de la fila anterior; corregidos por mí. Las frecuencias de la `3b` las contrasté después con el informe de la Unidad 6 (ver la fila siguiente). |
| Resultados de la A4 de Andrés | PostgreSQL 17.10 (`foodstore_u8`) | Coinciden con los míos: 16/16 en la vista y 6 pedidos, 13 detalles, stock 454 y la misma huella antes y después. No corrió las pruebas de la tablet, C2 a C6 ni `verificar_vistas_tablet.sql`; los cubren mis evidencias. |
| `3b` contra `SPEC_U6.md`, `informe_u6.pdf` y `protocolo_seguridad.md` | Lectura | Las frecuencias del borrador de Andrés (respaldo diario, restauración de prueba semanal) coinciden con la spec de la U6. Agregué lo que el informe aporta: al 21/10/2026 el respaldo era manual (sin tarea programada) y `pg_dump` no incluye roles ni permisos. |

## Mediciones (valores observados, no estimados)

| Dato | Valor | Cómo se midió |
|---|---|---|
| Conteos `usuario` / `producto` / `pedido` | 6 / 16 / 6 | Consulta en `foodstore_u8` |
| `verificar_no_cambio.sql` | 6 pedidos, 13 detalles, stock total 454, huella `89f8351d0162e23ef1473f32b05ce221`, igual antes y después | Evidencias 01 y 12 |
| Vista `v_snapshot_movil` | 16 filas contra 16 de `producto`, 0 diferencias, 0 precios con fracción de centavo, 7 columnas sin datos de usuarios | `verificar_vista_snapshot.sql` (evidencia 13) |
| Catálogo en la tablet | 16 contra 16 en la copia; 13 contra 13 en el catálogo disponible; 0 diferencias | `verificar_vistas_tablet.sql` (evidencia 14) |
| Base de la tablet tras la integración | 16 filas en `producto_cache` y 6 en `cola_sync` | `sqlite3 movil/foodstore_movil.db` |
| Resultado de los casos | C2 CONFLICTO y luego SIMULADO_APROBADO; C3 RECHAZADO (pide 10 Tiramisú, hay 6); C4 RECHAZADO (Fugazzeta dada de baja); C5 SIMULADO_APROBADO; C6 error de clave primaria y 0 solicitudes evaluadas en la repetición | Evidencias 05 a 11 |
| Corrida 2, ejecución sin editar | `cargar_catalogo.sql` con error de sintaxis; `producto_cache` en 0 filas; C1 da 0 (esperado 13); `criada_en` y `BEGIN TRY` fallan | Evidencia 28 |
| Evidencia 29 (SQLite 3.54.1) | A: 2 filas con `motivo` `NULL`; B1: ítem de producto inexistente entra sin `PRAGMA` (`producto_cache` en 0); B2: `FOREIGN KEY constraint failed` con `PRAGMA` activo; C: `typeof` = `text` y `strict = 0` en las cinco tablas | `evidencias/29_corrida2_motivo_fk_strict.txt` |

## Problemas encontrados y cómo se resolvieron

| Fecha | Problema | Causa | Solución |
|---|---|---|---|
| 04/11/2026 | Primer intento de merge del PR #1 por línea de comandos falló | No se determinó | Se mergeó desde la web de GitHub y se corrigió después |
| 04/11/2026 | `git status` mostraba modificados `.gitattributes`, `.kiro/.../.config.kiro` y 13 archivos de `evidencias/` | Cambios de fin de línea de Windows (en `.gitattributes` la regla quedó con un `\r`). Comprobé con `git diff --ignore-space-at-eol --stat` que en `evidencias/` no había diferencias de contenido | `git restore` de esos archivos; no se commitearon |
| 04/11/2026 | `git push` rechazado (`fetch first`) | El merge hecho desde la web creó en GitHub un commit que yo no tenía, con el `.db` vacío, `sqlite/` y los borradores de Andrés | `git merge -s ours origin/main` para registrar ese commit sin traer sus archivos; luego push |
| 04/11/2026 | La `3a` decía 5 pedidos migrados a MongoDB | Arrastré el valor del borrador de Andrés sin contrastarlo con `esquema_documental.md` | Corregido a 7 y subido |
| 04/11/2026 | Dudé de las frecuencias de la `3b` (respaldo diario, prueba semanal) porque el plan de la U6 no estaba en el repo | Revisé primero solo el informe y el protocolo, que no las fijan. En un primer ajuste quité la «prueba semanal» y escribí que el plan no fijaba frecuencia: era un error, porque `SPEC_U6.md` sí la fija | Con `SPEC_U6.md` a la vista: diario para el respaldo y semanal para la restauración de prueba, igual que el borrador de Andrés. Restauré el «semanal» en la `3b` |
| 07/11/2026 | El primer intento de la evidencia 29 falló: `Get-Process` en cada línea y `Out-File` sin ruta | Pegué las líneas con el prompt `PS C:\...>` incluido (en PowerShell `ps` es alias de `Get-Process`), con la ruta de ejemplo `C:\RUTA\A\...` sin ajustar y con `>>` dentro de los `.sql` | Guardé el script en un `.ps1` con mis rutas y lo ejecuté desde cero; la salida válida es la de las 14:55 |
| 07/11/2026 | `git status` mostraba `requirements.md` modificado | Solo cambió `## Glosario` por `## Glossary` (cambio hecho por Kiro, sin contenido nuevo); lo verifiqué con `git diff` | `git checkout --` sobre ese archivo; no se commiteó |
| 07/11/2026 | Duda sobre quién escribió el Requisito 11 | No quedó registro de la herramienta | Declarado como «no consta» en la DUIA; no se completa por memoria |

## Decisiones tomadas

| Decisión | Alternativas | Por qué |
|---|---|---|
| No integrar `sqlite/`, los `tp8_database.db` ni el `.db` vacío del PR | Integrarlos como «versión alternativa» | Es un esquema de ejemplo (`precio REAL`, sin `STRICT` ni centavos) que no es el del TP, y el `.db` vacío pisaba la evidencia de C2 a C6 |
| Reescribir yo las `1a`, `3a` y `3b` de Andrés y dejar su texto intacto en su bitácora y su DUIA con una nota firmada | Pedirle que las rehaga; reescribir también su bitácora | Prefiero no depender del tiempo del equipo; la nota solo dice lo comprobable y no afirma nada que Andrés no haya declarado |
| Integrar el PR desde la web y corregir en un commit aparte | Resolver el merge por línea de comandos | El intento por línea de comandos había fallado y quería conservar su autoría en la historia |
| Índice parcial `ux_cola_una_pendiente` | `UNIQUE` simple sobre `id_local` | Un `UNIQUE` simple impediría reenviar una solicitud después de un CONFLICTO |
| Carga del catálogo con `ON CONFLICT DO UPDATE` | `INSERT OR REPLACE` | `REPLACE` borra la fila y se perdería la lápida |
| Spec de Kiro escrita después del código, declarándolo | Reescribirla como si fuera anterior | El trabajo se hizo en ese orden; se declara en lugar de ocultarlo |
| Corrida 2 en carpeta aislada y sin editar | Corregirla como la corrida 1 | Una segunda corrida sin `movil/` a la vista mide qué genera el modelo a partir de la spec; editarla borraría esa evidencia |
| No agregar requisitos por la corrida 2 | Agregar REQ por cada defecto | Los incumplimientos son contra REQ ya escritos (6.1, 6.3, 6.11) o errores de escritura; las dos lagunas reales ya se habían cerrado (6.12 y 6.13) |
| `capturado_en` en `v_catalogo_disponible` y criterio `OK`/`FALLA` en el REQ 11 | Agregarlos a la spec y regenerar | No cambian ningún resultado de C1 a C8 ni de F2; se declaran como límites en `comparacion_generado_vs_original.md` |
| Descartar el cambio de Kiro `Glosario` → `Glossary` | Commitearlo | Sin contenido nuevo; mantiene la spec igual a la usada en las corridas |

## Declaraciones del 07/11/2026 (cierre de la segunda entrega)

### 1. Merges a `main` sin revisión cruzada
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

### 2. Trabajo de Mariano sobre archivos de Andrés
- **`a/obj-10` (U7):** se corrigió `u7.md` contra la evidencia (MongoDB figuraba con 10 ms y la salida dice `executionTimeMillis: 0`; se quitó una afirmación sobre el `$lookup` que no estaba medida), se repitió la medición con base propia y se verificaron las referencias en ambos motores. Los límites están declarados en `comparacion_medida.md`.
- **`a/obj-07` (U6):** se leyeron línea por línea `backup_foodstore.ps1`, `restore_test.ps1`, `crear_rol_respaldo.sql`, `programar_tareas.ps1` y `validar_integridad.sql`. Se corrigió `restore_test.ps1` para que exija y registre los 6 controles de integridad. Se repitieron respaldo, simulacro, roles (T01 a T23, 23 de 23), Programador de tareas, mantenimiento y Pester. `docs/informe/u6.md` se amplió con la repetición y los límites.

### 3. Asistencia de Claude
Con asistencia de Claude se redactaron y se verificaron contra las salidas crudas: los scripts de repetición de la U6 y la U7, la corrección de `u7.md` y `u6.md`, `docs/informe/u5.md`, `unidad-5/docs/auditoria_roles_opencode.md`, `docs/informe/00_introduccion_uso_ia_limitaciones.md` y el `README.md` raíz. El hallazgo H4b salió de una revisión con Claude, no de OpenCode.

### 4. Auditoría de `roles.sql` con OpenCode
La sesión original no se conserva. La auditoría del 07/11 es una repetición (Nemotron 3.5 Lightning, modo Plan, carpeta `C:\auditoria_roles`) que salió en 3 partes por 2 interrupciones; los mensajes de las interrupciones los redactó Claude. Hora de la parte 1: 16:38, a verificar; partes 2 y 3: no consta. Registro: `unidad-5/docs/registro_opencode_auditoria_roles_corrida2.txt`.

### 5. Evidencias con tratamiento especial
- Cinco evidencias de H3 y H4b se generaron en UTF-16 y se convirtieron a UTF-8 sin cambiar el contenido (commit `6346e09`).
- `unidad-6/evidencias/obj7_repeticion2_mariano_restore_20261107_194601.txt` quedó interrumpido durante `pg_restore`; la causa no consta. Se conserva sin editar, con su nota.
- Las salidas de `psql` en español traen `ï¿½` en algunas líneas por codificación de la consola; no se editaron.
- Las evidencias conservan rutas locales y el nombre del equipo (`host` en salidas de `explain`); no se editaron para no alterar lo que prueban.
- La prueba de H1 en base sucia se corrió en consola y no se guardó.

### 6. Límites del entorno de Mariano
- El `pg_hba.conf` usa `trust`: las pruebas verifican permisos, no autenticación.
- Las tareas del Programador se registraron, se dispararon a mano y se desregistraron; no se observó ninguna ejecución por horario.
- Se ejecutó un `ANALYZE` manual sobre la copia `foodstore` (la copia por plantilla no traía estadísticas).
- `log_statement = all` sigue activo en el servidor local; las contraseñas de prueba de T04 y T14 quedan en ese log, que no está en el repositorio.

### 7. Datos en el historial de Git
El repositorio es público. Un correo y un apellido de un integrante estuvieron en `unidad-7/modelo/pedidos_export.json` y en dos archivos más; se regeneraron, pero siguen en el historial. No se reescribió el historial.

### 8. Otros
- Requisito 11 de la spec de la U8: no consta con qué herramienta se redactó.
- `roles.sql` cambió tres veces en `m/obj-06` (H1, H3, H4b); quien lo edite debe partir de `main` actual.
- Las preguntas al profesor sobre el objetivo 11 y el formato del repo no se enviaron; se resolvió con criterio propio y se declara. Tampoco hubo defensa oral en las entregas anteriores.
