# Code review con IA de los scripts (objetivo 13)

Autor: Mariano Chirino (la tarea estaba asignada a Facundo Quiroga y la hizo Mariano a partir del 08/11/2026; ver «Declaraciones»).
Rama: `review-final`. Etiqueta de scripts congelados: `pre-review` (`351ddb9`, sobre `main`).
Tabla completa: `docs/auditoria_codigo/hallazgos.md`. Respuestas crudas: `docs/auditoria_codigo/tanda_*.md`. Evidencia: `docs/auditoria_codigo/evidencias/`.

## 1. Qué se hizo

Se pasó el código del repositorio por OpenCode (modo Plan) en 11 tandas, con el mismo prompt base (`prompt_base.md`) y guardando la respuesta cruda de cada una. Cada hallazgo devuelto se cargó como una fila de `hallazgos.md` con archivo y línea, resumen, severidad informada por la IA, autor, decisión, motivo y prueba.

| Tanda | Contenido | Filas |
|---|---|---|
| 01 | `heredado/base_heredada` (la primera corrida falló por un marcador sin reemplazar y se repitió) | 48 |
| 02 | unidad-4 | 16 |
| 03 | unidad-4/migracion | 14 |
| 04 | unidad-5, roles | 16 |
| 05 | unidad-5, pruebas | 27 |
| 06 | unidad-6, scripts PowerShell | 17 |
| 07 | unidad-6, SQL | 11 |
| 08 | unidad-7, consultas | 11 |
| 09 | unidad-7, benchmark | 11 |
| 10 | unidad-8, móvil y PostgreSQL | 9 |
| 11 | unidad-8, móvil generado por OpenCode (corrida 2) | 16 |
| | **Total** | **196** |

Las 27 filas de la tanda 05 se armaron después, a partir de la prosa de la respuesta, porque esa corrida no devolvió ids ni severidad.

Severidad informada por la IA (no validada por nosotros): 2 críticas, 33 altas, 73 medias, 61 bajas y 27 sin informar.

## 2. Resultado de la revisión

Se decidió sobre **42 de las 196 filas**: las 35 de severidad alta o crítica y 7 de severidad menor que se tocaron al reproducir o al leer lo vecino (`T06-H-17` y `T11-H-11` a `T11-H-16`). Las otras **154 quedan «No evaluado»**: no se reprodujeron ni se verificaron contra el código por el plazo de entrega, y lo que devolvió OpenCode queda en la columna Resumen sin validar.

| Decisión | Filas | De ellas, altas o críticas |
|---|---|---|
| Confirmado | 31 | 25 |
| Confirmado en parte | 6 | 6 |
| Parcial | 2 | 2 |
| Descartado | 2 | 1 |
| Descartado en lo central | 1 | 1 |
| No evaluado | 154 | 0 |
| **Total** | **196** | **35** |

«Confirmado» incluye filas que dicen «parcial», «por lectura» o «con simulación» en su Decisión: el conteo no separa cómo se confirmó. La separación correcta es esta:

- **Con ejecución (14):** `T06-H-01`, `T06-H-02` (con un archivo de prueba, no con el script real), `T06-H-17` (comprobación de la versión de Pester), `T01-H-34` (el comando solo, no el archivo) y `T11-H-01` a `T11-H-06`, `T11-H-08` a `T11-H-11`. `T11-H-08` y `T11-H-09` se probaron con el paso 6 del README simulado, no con el real de PostgreSQL; `T11-H-06` es parcial (no se probó el valor de `changes()`).
- **Por lectura de código (28):** el resto de las 42. Una confirmación por lectura dice que el código hace lo que el hallazgo afirma, no que el efecto se haya observado.

## 3. Lo que la revisión corrigió de OpenCode

Tres hallazgos de severidad alta no se sostienen o cambian de sentido:

- **`T06-H-02` (descartado).** El hallazgo decía que la tarea de mantenimiento sigue tras errores SQL y reporta éxito. `maintenance.sql:33` tiene `\set ON_ERROR_STOP on` antes de cualquier sentencia y la tarea termina con `exit $LASTEXITCODE`. Con un archivo de prueba, `psql -f` se detiene en el primer error y sale con código 3. No se corrió el `maintenance.sql` real con un error forzado.
- **`T07-H-01` (descartado en lo central).** El rol de respaldo se crea sin contraseña a propósito (lo dice el script) y la contraseña se fijó aparte; la bitácora de la U6 registra que `pg_dump` corrió con ese rol. Queda que el paso manual no está en el script.
- **`T06-H-17` (descartado, severidad baja).** `Should Be` es la sintaxis válida en el Pester 3.4.0 del entorno y las 8 pruebas pasan; la deprecación es de Pester 5, que no está instalado.

Y otros cambian de formulación, de alcance o de gravedad:

- **`T01-H-09`:** la función sí toma el precio de `producto` cuando falta; lo que acepta es un precio manual.
- **`T01-H-31`:** ninguna de las tres consultas filtra por estado; el filtrado de eliminados es parcial (la A no une `pedido`, la C no filtra `usuario`).
- **`T01-H-41`:** es cierto que la carga es una sola transacción; eso da atomicidad y no se probó que sea un defecto. Severidad a revisar.
- **`T07-H-02`:** un `pg_dump` completo necesita leer todas las tablas; lo que queda es proteger el archivo de respaldo.
- **`T08-H-08` y `C-05`:** el script no usa `$env:PGPASSWORD` (solo la nombra en un comentario); lo que falta son `-w` y `-X` en las llamadas a `psql`.
- **`T09-H-02` y `T09-H-03`:** el hecho es cierto; como defecto es discutible (un pedido histórico conserva su producto y su cliente aunque hoy estén dados de baja).
- **`T11-H-16`:** el resumen de OpenCode es incorrecto para v2: `creada_en` y `creado_en` usan el mismo formato; la inconsistencia es con `evaluada_en`.
- **`T01-H-33` y `T01-H-35`:** son guías escritas para dos sesiones; corridas en una sola no prueban aislamiento ni bloqueo, y el archivo no lo advierte.

### Lo que sí confirma la revisión sobre el código generado por OpenCode (tanda 11, unidad-8/movil_opencode_v2)

Las dos corridas de OpenCode para el móvil no entregaron nada ejecutable sin correcciones (ver T1). En la corrida 2 se reprodujo, entre otros: que las tablas no son `STRICT` aunque el encabezado y el README lo afirman (`T11-H-01`); que un script usa sintaxis de T-SQL inexistente en SQLite (`T11-H-03`); que un script de pruebas no ejecuta el semáforo y deja los seis casos F2 en `PENDIENTE` (`T11-H-07`); y que `PRAGMA foreign_keys` falta en casi todos los scripts (`T11-H-11`).

## 4. Hallazgos propios (no de OpenCode)

Las filas `C-01` a `C-09` registran lo que Mariano y Claude encontraron por su cuenta y no figura en la salida de OpenCode. `C-05` está decidida (confirmado en parte); el resto sigue pendiente de cargar o de decisión. Entre ellos: la restauración pierde dueños y permisos (`C-02`), el respaldo no verificaba su SHA-256 antes del 07/11 (`C-03`), y el «sin acción» original del mantenimiento pudo deberse a estadísticas en cero tras `createdb -T` (`C-06`).

## 5. Límites

1. **154 de 196 hallazgos no se evaluaron.** El informe no afirma nada sobre ellos más que la severidad que informó la IA.
2. **Las altas y críticas se decidieron en su mayoría por lectura.** Solo 14 filas tienen ejecución propia.
3. **Tres hallazgos dependen de lo que pide el enunciado y no se contrastaron con él:** `T01-H-01`, `T01-H-31` y `T09-H-01`.
4. **Las pruebas con paso 6 simulado** (`T11-H-08`, `T11-H-09`) no equivalen a correr el paso 6 real en PostgreSQL.
5. **Una sola IA revisora** (OpenCode con un modelo gratuito); no hubo una segunda revisión independiente. `[CONFIRMAR: nombre exacto del modelo; las cabeceras de las tandas usan dos grafías, «Croutou» y «Crouton»]`.
6. **No se corrigió código a partir de la revisión** en esta etapa: ningún script de `main` fue modificado por este trabajo (`pre-review` sigue siendo la referencia).
7. **Las decisiones se cargaron por lote** y no con un commit por hallazgo; la evidencia sí está separada por grupo.

## 6. Declaraciones

- La tarea T9 se reasignó de Facundo a Mariano el 08/11 y se ejecutó entre el 08 y el 09/11/2026.
- Las respuestas de OpenCode se guardaron crudas. El 09/11 se completaron los campos Modelo, Fecha, Estado y Total en las cabeceras de las tandas 01 a 06 (commit `e815760`); las respuestas no se editaron.
- La preparación de las reproducciones, el armado de las filas de `hallazgos.md` y los scripts de carga se hicieron con Claude (Anthropic); Mariano ejecutó cada comando y revisó las salidas.
- La evidencia `T06-H-01_pester_sin_llamada.txt` es un `Start-Transcript` y trae usuario, equipo y ruta locales en su cabecera. `T06-H-17_version_pester.txt` quedó en UTF-16 por estar ya commiteada; el resto de la evidencia nueva está en UTF-8.
- Los acentos rotos de algunas salidas vienen de la consola de PowerShell 5.1 y no se editaron.
- `T11-H-11_f2_huerfanas.txt` se conserva pero no se usa como prueba de `T11-H-11`: `producto_cache` estaba vacío en esa corrida.
