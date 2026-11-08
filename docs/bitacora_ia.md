# Bitácora unificada de uso de IA — TPI «Food Store» (U4 a U8)

Consolida las bitácoras y DUIA de cada unidad. Cada fila es una interacción registrada por su autor; no se agrega nada que no figure en la fuente. Lo que no dejó escrito su autor figura como **«no consta»** y no se completa de memoria. Las fuentes originales se conservan en su unidad (indicadas en cada sección).

Reglas que se declararon y se respetaron en todas las unidades: nada generado se ejecutó sin leerlo y probarlo en una copia o transacción reversible; no se enviaron datos reales ni hashes a una IA; la decisión de aceptar, corregir o descartar fue siempre humana.

## 1. Herramientas por integrante

| Integrante | Herramientas declaradas | Dónde |
|---|---|---|
| Mariano Chirino | Claude (chat), Kiro, OpenCode (Nemotron 3.5 Lightning Free), NotebookLM | `unidad-4/duia/`, `unidad-5/BITACORA.md`, `unidad-7/BITACORA.md`, `unidad-8/docs/` |
| Andrés Fabre | Gemini (U4, U8), OpenCode / Muse Spark (U5, U7), OpenCode / «GPT-5.6 Terra» para la revisión del 05/11 (U8, sin logs) y para las ampliaciones U6/U7 del 07/11 | ídem; U6 queda detallada en la sección 4 |
| Facundo Quiroga | Gemini (U4, U5; «a confirmar por Facundo»), Claude (U7), OpenCode agente Plan (U8; modelo y proveedor «no consta») | ídem |

## 2. Unidad 4 — normalización y desnormalización (objetivos 1 a 3)

Fuentes: `unidad-4/duia/duia_mariano.md`, `duia_andres.md`, `duia_facundo.md`. Fechas: no constan en las DUIA.

| Quién | Herramienta | Qué se pidió | Decisión y motivo |
|---|---|---|---|
| Facundo | Gemini | Script completo de la Parte 1 (FNBC) en un solo prompt, sin las columnas ni los datos del enunciado | **Descartado.** Inventó un esquema propio (`almacenero`). El grupo rehízo el script sobre el esquema exacto del enunciado (commit `f583fd1`); se aprovechó la estructura en fases |
| Andrés | Gemini | Diagnóstico teórico de FNBC y esquema objetivo para la spec | **Aceptado.** Correcto y coincidente con las demás versiones; dejaba sin decidir la vista de compatibilidad, y el grupo eligió la vista aparte |
| Mariano | Claude | Primera versión de la Parte 1 | **Descartada**: el mismo esquema inventado. Se rehízo con la instancia exacta del punto 4.1 |
| Mariano | Claude | Dependencias, clausuras, claves y descomposición | **Aceptado y revisado a mano**: F1 `{L,D}→R`, F2 `R→D`; claves `{L,D}` y `{L,R}`; viola FNBC por F2. Se agregó la limitación de que no se preserva `{L,D}→R` |
| Mariano | Claude | Medir la consulta de la Parte 2 con `EXPLAIN ANALYZE` | **Primera versión descartada** (fecha fija, caché fría, 2 categorías, 1301 ms). Versión final con 406 pedidos y caché caliente: 6,546 ms |
| Mariano | Claude | Elegir el patrón y generar el DDL | **Aceptada** la vista materializada `mv_ventas_categoria_dia` (0,106 ms); se corrigió la clave de agrupación |
| Mariano | Claude | Auditoría de desincronización | **Error detectado:** el `JOIN` interno daba un falso negativo. Se reemplazó por `FULL OUTER JOIN … IS DISTINCT FROM` y se probó con `ROLLBACK` |

**Límites declarados.** Mariano indica «OpenCode/Kiro en las primeras versiones del grupo», pero ninguna fila de su tabla los registra (**no consta** qué se hizo con ellos). La DUIA de Facundo conserva una nota pendiente; la de Andrés declara «no consta» donde no hay registro. La Parte 1 se probó en `copia_fnbc` y la Parte 2 en `copia_trabajo`, ambas en PostgreSQL 18.

## 3. Unidad 5 — roles, auditoría y simulacro (objetivos 4 a 6)

Fuente: `unidad-5/BITACORA.md` (esta unidad no tiene DUIA propia).

| Parte | Quién | Herramienta | Qué pasó | Decisión y motivo |
|---|---|---|---|---|
| A | Mariano | Kiro (3 prompts) | Spec de roles. El orden de `roles.sql` tenía errores graves: `ALTER … OWNER` antes de crear el rol, `GRANT` sobre funciones inexistentes, funciones `SECURITY DEFINER` a nombre de `postgres`, limpieza con `DROP OWNED BY` que borraba las tablas | **Corregido en tres rondas** tras leer línea por línea. Un error fue de Claude, que armó la lista de correcciones y pidió excluir `PUBLIC` de las consultas 4c y 4e |
| A | Mariano | Kiro | Consulta 4e con una columna inexistente (`routine_type`); 4c sin vistas materializadas; prueba con `fn_autenticar` que daría `true` | Cada una se corrigió al ejecutarla |
| A | Mariano | Claude | Borrador de `roles.sql` y de `verificacion_roles.sql` (T01–T23) | 21 de 23 en la primera corrida. **T22 mal diseñada por la IA** (`SET ROLE` siempre funciona para `postgres`); **T23** mostró que el filtro `rol <> 'ADMIN'` no estaba aplicado (solo había corrido el ensayo con `ROLLBACK`). Tras re-ejecutar: 23/23 |
| A | Mariano | OpenCode | Auditoría original de `roles.sql`: 10 hallazgos. La primera sesión abrió otro proyecto y se descartó | **H1 (crítico) incorrecto.** Se aplicó solo H2 y H7; H4 y H6 descartados, H3 y H5 descartados (cuál es cuál, no consta); H8 a H10 sin decisión registrada. **La respuesta cruda no se conserva** |
| B | Andrés | Muse Spark (OpenCode) | Guía de la auditoría; `ALTER SYSTEM` juntos fallaron (`25001`); parámetros que no quedaban | Diagnóstico con `pg_settings`; se verificó recién con `on/on/all` |
| B | Mariano | Claude | `auditoria_test.ps1` (marcas y conexión fallida) | **Imprecisión de la IA:** dio por activa una auditoría que no lo estaba; se detectó porque el log no tenía marcas. `Get-Content -Encoding UTF8` dañó 33 caracteres del fragmento; se restauraron y se declaró |
| C | Mariano | Claude | Script del simulacro | 5 fallidos, 1 exitoso, 20007 filas, 3 escalamientos denegados: sin hallazgo sobre `roles.sql` |
| C | Andrés | Muse Spark | Anonimización del log | Criterio en `criterio_anonimizacion_log.md` |
| C | Andrés | OpenCode, 1.ª corrida | Reconstrucción del log | **Descartada como evidencia:** el log incluía un encabezado con el mapa de valores y la IA lo usó |
| C | Mariano | OpenCode, 2.ª corrida | Mismo prompt con el log sin encabezado (70 líneas) | Es la que se contrasta; 4 afirmaciones sin sustento detectadas |
| C | Facundo | Gemini | Contraste y contención (primera versión) | **Reemplazada** por la de Mariano (con Claude); se conservó la idea de `NOLOGIN` |
| D | Mariano | OpenCode | Consulta gemela sobre `usuario` | La primera respuesta citó un archivo del repo: leyó el archivo en vez de derivar la consulta. Se ejecutó y se comparó con `EXCEPT` |
| D | Facundo | Gemini | «Paquete B» con los resultados esperados dentro del prompt | **Afirmó haber ejecutado consultas que no ejecutó.** Reemplazado por la versión que sí ejecuta y compara (commit `cfb577e`) |

**Caso más significativo:** la primera spec de Kiro para `roles.sql`, que parecía correcta y de haberse ejecutado habría causado daño.
**Límite de Git declarado en la fuente:** commits directos a `main` en la Parte A y mensajes poco descriptivos.

### 3.1 Cierre del objetivo 6 (07/11/2026, Mariano)

| Qué | Herramienta | Resultado |
|---|---|---|
| Repetición de la auditoría de `roles.sql` (la sesión original no se conserva) | OpenCode, Nemotron 3.5 Lightning, modo Plan, carpeta aislada | 5 hallazgos, en 3 partes por 2 interrupciones; los mensajes de las interrupciones los redactó Claude. Horas de las partes 2 y 3: no constan |
| Reproducción de cada hallazgo en `copia_u5` | Scripts con `psql -f` | **H1 y H3 aceptados y corregidos** (eran de base sucia: la copia limpia no los mostraba); **H2, H4 y H5 descartados** con prueba |
| Revisión adicional | Claude | **H4b** (`EXECUTE` para `PUBLIC` en cuatro rutinas viejas): no salió de OpenCode; se reprodujo, se corrigió y T01–T23 dio 23/23 |
| Redacción de `auditoria_roles_opencode.md`, `u5.md`, el README raíz y la introducción del informe | Claude | Revisados contra las evidencias |
| Cinco evidencias de H3/H4b | — | Generadas en UTF-16 con `Tee-Object` y reencodeadas a UTF-8 sin cambiar el contenido (commit `6346e09`) |

## 4. Unidad 6 — respaldo, restauración y mantenimiento (objetivos 7 y 8)

Fuente: `unidad-6/BITACORA.md`, sección «Ampliación del objetivo 7».

| Quién | Herramienta, modelo y fecha | Qué se pidió | Decisión, corrección y prueba |
|---|---|---|---|
| Andrés | OpenCode, proveedor OpenAI, modelo GPT-5.6 Terra; 07/11/2026 | Completar solo el objetivo 7 asignado: primero redactar y commitear `SPEC_U6_ampliacion.md`; después generar rol limitado de respaldo, backup de globales sin hashes de claves, retención, hashes previos, `pg_amcheck`, controles de integridad, comparación de conteos y tareas de Windows. | **Aceptado tras lectura y prueba:** la spec se confirmó en `cfb6f0a`; los scripts y pruebas se revisaron antes de usarlos. **Corregido tras ejecución:** se añadió `--install-missing` porque `amcheck` faltaba en la copia restaurada, y se ajustó la lectura de `psql` a `-t -A -F '|' -q` porque los mensajes de formato se interpretaban como controles. **Descartado:** restaurar automáticamente los roles globales, porque afecta todo el clúster; se preservan y verifican los globales, y los roles se aplican manualmente sobre la copia. Se probó en PostgreSQL 17 local: `foodstore` solo como origen y `foodstore_restore_test` como destino descartable. |

**Respuesta cruda de OpenCode:** no consta. Solo se conserva el resumen de prompts, decisiones y resultados en `unidad-6/BITACORA.md`; no se reconstruye una respuesta de memoria.

## 5. Unidad 7 — MongoDB (objetivos 9 y 10)

Fuente: `unidad-7/BITACORA.md` (unificada por Mariano el 01/11/2026 contra los archivos del repo).

| Quién | Herramienta | Qué se pidió | Decisión y motivo |
|---|---|---|---|
| Mariano | Claude | Export, migración, esquema, consultas, informe y revisión de los repos | **Funcionó a la primera** (declarado); los valores esperados se calcularon a mano y coincidieron |
| Andrés | OpenCode | Consultas de PostgreSQL y tabla de verificación | Consultas correctas. **La tabla no se contrastó con las salidas:** decía 3 y 3 y la evidencia mostraba 4 y 3 (PostgreSQL) y 2 y 1 (MongoDB); los pedidos 7 y 8 no estaban migrados. Se rehízo con 7 documentos |
| Facundo | Claude | Comparación PostgreSQL / MongoDB (consigna 6) | Se contrastaron dos afirmaciones: «MongoDB no valida esquemas» es falsa; que el embebido elimine el costo de los JOIN no está respaldado. Mariano hizo 4 correcciones al contraste |
| Mariano | Claude | Revisión final del repo | Se agregó la verificación subtotal = cantidad × precio |

**Pendientes declarados en la fuente:** salida guardada de la ejecución de Facundo y comprobación de que su contraste quedó fiel.
**Límite:** `pedidos_export.json` y la evidencia de Mongo conservan el nombre de un integrante en un usuario de ejemplo (base anterior a la limpieza); se regeneran con la tarea del objetivo 10.

**Revisión posterior de Andrés (08/11/2026):** se leyó `unidad-7/informe_u7.pdf`: tiene 4 páginas y los resultados de la migración original (7 documentos; consultas b y c; reglas de integridad; contraste de IA) coinciden con las evidencias citadas. El PDF corresponde a la entrega original de U7; la medición adicional de 5.000 pedidos se documenta separadamente en `docs/informe/u7.md` y no reemplaza esas cuatro páginas. El conteo local de Andrés para la migración original no tiene salida guardada, por lo que queda como **no consta**; no se usa como evidencia.

## 6. Unidad 8 — SQLite y sincronización (objetivos 11 a 14)

Fuentes: `unidad-8/docs/DUIA.md`, `duia_*.md`, `bitacoras/`.

| Quién | Herramienta | Qué pasó | Decisión y motivo |
|---|---|---|---|
| Mariano | NotebookLM | Reconstruyó el `kit_u8_campus` (no estaba en el campus) | **Aceptado** el SQL (contrastado con el apunte); **descartado** `simulador_sync.py` (comparaba una tupla con un texto, importaba una librería sin usarla y nombraba una tabla inexistente) |
| Mariano | Claude | Borrador de esquema, semáforo y casos C2 a C6 | Aceptado tras leerlo y correrlo. Se prefirió `UPSERT` a `INSERT OR REPLACE` y un índice parcial a un `UNIQUE` simple |
| Mariano | Kiro | Spec (`requirements`, `design`, `tasks`) | **Escrita después del código** (declarado). Errores corregidos (semáforo vs. recarga, `COPY producto`, transporte inventado, booleanos invertidos). Prompt y modelo: no constan |
| Mariano | Claude / Kiro | Ampliar la spec antes de generar (REQ 5 a 10) | Los redactó Claude como borrador y se pegaron casi sin cambios. **REQ 11: no consta con qué herramienta se redactó.** Commit `be854e4` (06/11 15:38), anterior a la generación |
| Mariano | OpenCode, corrida 1 (06/11) | Esquema, carga, semáforo y casos desde la spec | **No produjo una base funcional.** Originales conservados en `original_opencode/` (`e9dd9f8`). No consta si leyó `movil/` |
| Mariano | Claude | Corregir la corrida 1 y comparar con `movil/` | Se corrigió; la comparación detectó dos lagunas de la spec (REQ 6.12 y 6.13), cerradas con commit propio. Se descartó un cambio de Claude por suposición (precio sin dividir por 100) |
| Mariano | OpenCode, corrida 2 (07/11, carpeta aislada) | Misma tarea sin `movil/` | **Tampoco funciona:** error de sintaxis, ninguna tabla `STRICT`, `criada_en`, `BEGIN TRY` de SQL Server, sin `casos.sql`. **Afirmó «5 tablas STRICT» y «sintaxis revisada» sin ejecutar nada.** Guardada sin editar; evidencias 28 y 29 |
| Mariano | Claude | Revisión del PR #1 de Andrés | Descartados `sqlite/` y los `.db`; reescritas 1.a, 3.a y 3.b (columnas inexistentes, cola en PostgreSQL, SQLite con «autoridad local») |
| Mariano | Claude | Revisión del PR #2 de Facundo | **H36 y H04 descartados** con ejecución; **H01 y R1 aceptados** con prueba en copia; casos F2 armados por Mariano |
| Andrés | Gemini | Redacción de 1.a, 3.a y 3.b; diagnóstico de errores en Windows | Aceptado tras verificación **según su declaración**; la revisión de Mariano mostró que esa verificación no detectó los errores |
| Andrés | OpenCode / «GPT-5.6 Terra» (05/11) | Revisión A4 completa y contraste de 3.c | Resultados aceptados solo si salían del motor; **sin logs de la conversación** |
| Facundo | OpenCode, agente Plan | Code review de los scripts (3.c) | Aceptados H01 y R1, descartados H36 y H04. **Modelo, proveedor, prompt, fecha y total de hallazgos: no constan**; no hay logs de sus comprobaciones |

**Declaración honesta de la fuente:** los scripts que funcionan en `movil_opencode/` son en su mayor parte reescrituras hechas con Claude a partir de los errores de la corrida 1; de OpenCode quedan la estructura general y algunas ideas de casos.

## 7. Errores de la IA que cambiaron decisiones (para la defensa)

| Unidad | Qué afirmó o hizo la IA | Cómo se detectó |
|---|---|---|
| U4 | Esquema inventado (`almacenero`), dos veces | Contraste con el punto 4.1 del enunciado |
| U4 | Auditoría con `JOIN` interno: falso negativo | Prueba con `ROLLBACK` |
| U5 | Spec de roles con orden de ejecución dañino | Lectura línea por línea en el orden de ejecución |
| U5 | T22 mal diseñada | `SET ROLE` siempre funciona para `postgres` |
| U5 | «H1 crítico» (un `REVOKE` rompería la corrida) | Ejecución real: 8 avisos, sin error |
| U5 | «Ejecutamos las consultas» sin haber ejecutado nada | Los números venían del prompt |
| U5 | H2, H4 y H5 con premisas falsas | Reproducción en `copia_u5` |
| U5 | La copia limpia no mostraba H1 ni H3 | Había que sembrar el residuo de una base sucia |
| U7 | Tabla de verificación sin respaldo | Comparación con las salidas guardadas |
| U8 | `simulador_sync.py` que nunca habría evaluado nada | Lectura del código |
| U8 | «5 tablas STRICT», «sintaxis revisada» | Ejecución: `strict = 0` en las cinco |
| U8 | Cada `sqlite3` es un proceso nuevo y `foreign_keys` arranca en OFF | Evidencia 29 |

**Lección común:** una afirmación de una IA no vale hasta ejecutarla; una prueba que pasa no prueba lo que se cree hasta verificar qué mide.

## 8. Huecos que solo puede completar su autor

- U6 completa (Andrés).
- Facundo, U4: nota `confirmá…` de su DUIA.
- Facundo, U8: modelo, proveedor, prompt, fecha y total de hallazgos de OpenCode; qué salió de OpenCode y qué de otra fuente.
- Facundo, U7: salida guardada de su ejecución.
- Andrés, U5: qué parte del recorte del log y de la guía de la Parte B cambió respecto de lo declarado.
- Code review del objetivo 13 y migración del objetivo 2: sin registro hasta que se hagan.
