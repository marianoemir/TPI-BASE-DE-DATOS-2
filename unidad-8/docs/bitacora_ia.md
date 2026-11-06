# Bitácora de uso de IA — TP N.º 8 (unificada)

Unifica las tres bitácoras individuales, que se conservan en `docs/bitacoras/` (`bitacora_mariano.md`, `bitacora_andres.md`, `bitacora_facundo.md`).
Cada declaración personal está en `docs/duia_<nombre>.md`.
**Criterio:** cada entrada dice **quién** la hizo. Lo que un compañero afirma sin evidencia se registra como «según lo que dejó escrito, no hay logs adjuntos».
Las mediciones citan el archivo de `evidencias/` que las respalda.

Formato de cada entrada: **qué se pidió · qué se aceptó · qué se descartó y por qué · cómo se comprobó**.

## Entradas

### 1 · Mariano — NotebookLM: kit de la cátedra
- **Qué se pidió:** el código del `kit_u8_campus` mencionado en el apunte (esquema, instantánea, simulador).
- **Qué se aceptó:** el SQL del esquema SQLite, la vista `v_snapshot_movil` y la transacción del borrador, después de contrastarlos con las paradas 3, 4 y 5 del apunte: coincidían.
- **Qué se descartó y por qué:** `simulador_sync.py`. Comparaba el resultado de `fetchone()` (una tupla) con el texto `'PENDIENTE'`, así que nunca evaluaba nada; importaba `psycopg2` sin usarlo y nombraba una tabla `registro_sync` que no existe. Ese archivo no estaba en el campus: la IA lo había reconstruido. El semáforo se escribió en SQL puro.
- **Cómo se comprobó:** lectura del código contra la parada 6 y contra las tablas del esquema.

### 2 · Mariano — Claude (web): armado del repo, esquema, semáforo y casos
- **Qué se pidió:** clasificar qué scripts de las Unidades 1 a 7 se reutilizan y armar el repo; borrador de `schema_sqlite.sql`, `cargar_catalogo.sql`, `pruebas_sqlite.sql`, `semaforo.sql` y los casos C2 a C6.
- **Qué se aceptó:** el esquema con los agregados (CHECK de motivo, `evaluada_en`, tabla de paso `snapshot_servidor`); el semáforo con `LEFT JOIN` y tratamiento explícito del producto inexistente; la recarga con `ON CONFLICT DO UPDATE`; `heredado/` sin modificar, salvo el usuario con nombre real de `data.sql`, reemplazado por uno inventado.
- **Qué se descartó y por qué:** `pedidos_de_prueba.sql` y `carga_masiva.sql` (cambiarían el stock de C3 y C5). Alternativas evaluadas, que son decisiones de diseño y no propuestas de la IA: `INSERT OR REPLACE` (borra la fila y perdería la lápida de C4) y un `UNIQUE` simple sobre `cola_sync.id_local` (impediría reenviar tras un CONFLICTO).
- **Cómo se comprobó:** según el borrador original de esta bitácora, la IA probó los scripts en un entorno propio (PostgreSQL 16, SQLite 3.45); no hay logs de eso en el repo. Mariano repitió todo en su máquina (PostgreSQL 17.10, SQLite 3.54.1): C1 a C7 en `evidencias/01` a `12` y `verificar_no_cambio.sql` con la misma huella `89f8351d0162e23ef1473f32b05ce221` antes y después.

### 3 · Mariano — Kiro y Claude (web): spec de la consigna 4.a
- **Qué se pidió:** `requirements.md`, `design.md` y `tasks.md` con requisitos en notación EARS, y después revisar lo que generó Kiro contra los scripts y las evidencias.
- **Qué se aceptó:** los cuatro requisitos con su caso (C2, C3, C4, C6) y un diseño y tareas breves en `docs/kiro/`.
- **Qué se descartó y por qué:** las pruebas de propiedades con Hypothesis (el TP no exige Python) y el límite de 255 caracteres en `motivo` (el semáforo no lo impone). Se corrigió que el semáforo marcara `eliminado` (lo hace la recarga), que el diseño exportara con `COPY producto` en vez de `v_snapshot_movil`, un transporte «llave USB / correo» inventado, la fila de booleanos invertida y la afirmación de que la transacción hace rollback sola. Más tarde se corrigió REQ-04: decía «devolver el resultado ya guardado» y el script no devuelve nada; ahora dice que conserva la fila original.
- **Cómo se comprobó:** contra los scripts y las evidencias 05 a 11. **Declarado:** la spec se escribió **después** del código, no antes como pide el enunciado. **No consta** el prompt exacto ni el modelo de Kiro. Fecha del commit con la spec: 03/11/2026 (`ec9a60b`). La carpeta `.kiro/steering/` entró el 02/11/2026 (`66392be`, «Estructura preliminar») y no consta con qué herramienta se escribió.

### 4 · Mariano — Claude (web): revisión del PR #1 de Andrés
- **Qué se pidió:** clonar la rama, leer los archivos y probar los scripts del pull request.
- **Qué se aceptó:** la fila de MongoDB propuesta para la `3a` (colección `pedidos` de `foodstore_nosql`, copia de lectura, PostgreSQL manda).
- **Qué se descartó y por qué:** la carpeta `sqlite/`, los dos `tp8_database.db` (esquema de ejemplo con `precio REAL`, sin `STRICT`) y el `foodstore_movil.db` vacío, que pisaba la evidencia de C2 a C6. Las `1a`, `3a` y `3b` de Andrés tenían columnas inexistentes, la cola en PostgreSQL, MongoDB como metadatos de productos y SQLite con «autoridad local»: se reescribieron contra el esquema real. La `3a` arrastró «5 pedidos migrados»; el dato correcto es 7 (`esquema_documental.md`).
- **Cómo se comprobó:** cada dato contra `schema.sql` y `esquema_documental.md`; las frecuencias de la `3b` contra `SPEC_U6.md` de la Unidad 6 (respaldo diario, restauración de prueba semanal). Hubo un error intermedio: se había quitado la «prueba semanal» sin ver la spec.

### 5 · Mariano — Claude (web): revisión del PR #2 de Facundo y casos borde de F2
- **Qué se pidió:** contrastar la 3.c, la bitácora y la DUIA de Facundo con los scripts del repo y con corridas en la máquina de Mariano; armar casos borde del semáforo.
- **Qué se aceptó:** H01 (`sp_crear_pedido` acepta un pedido de un producto de categoría eliminada aunque `v_snapshot_movil` ya la exporta como lápida) y el producto repetido en `p_items` (`SQLSTATE 23505` sin mensaje de negocio). Los 6 casos de `casos_f2_semaforo.sql`, que dieron lo esperado.
- **Qué se descartó y por qué:** **H36**, porque no se reproduce: tras C7 los conteos siguen en 1 borrador, 2 ítems y 1 solicitud, y cada bloque de C7 termina en `ROLLBACK`. **H04**, porque con 13 filas un índice nuevo no mejora nada, `conventions.md` no permite agregar índices y, forzando `enable_seqscan = off`, el índice compuesto sí se usa. Se corrigió además el nombre de la vista, los estados del semáforo y la sigla DUIA.
- **Cómo se comprobó:** en copias de las bases, con scripts en el repo: `evidencias/15` (H04), `16` (H01 y producto repetido, `postgresql/verificar_hallazgos_3c.sql`), `17` (H36), `18` y `19` (casos de F2).

### 6 · Facundo — OpenCode (agente Plan): code review de la consigna 3.c
- **Qué se pidió:** revisar los scripts de la cursada en la rama `review-final`.
- **Qué se aceptó:** H01 y el producto repetido, que se comprobaron después en la base (entrada 5).
- **Qué se descartó y por qué:** H36 (falso) y H04 (irrelevante con 13 filas); ver entrada 5.
- **Cómo se comprobó:** las comprobaciones que respaldan la decisión son las de Mariano. **Según lo que dejó escrito, no hay logs adjuntos** de las corridas de Facundo, y **no consta** el modelo ni el proveedor de OpenCode, el prompt, la fecha, cuántos hallazgos devolvió en total la IA ni cuáles de H01 y del producto repetido salieron de OpenCode.

### 7 · Andrés — Gemini y OpenCode: documentos 1.a, 3.a y 3.b, y revisión cruzada A4
- **Qué se pidió:** redactar los entregables 1.a, 3.a y 3.b; diagnosticar el error `table producto_cache already exists`; interpretar el hash MD5 de `verificar_no_cambio.sql`.
- **Qué se aceptó:** según su bitácora, el borrador de los tres documentos («aceptado totalmente»), el consejo de borrar el `.db` antes de recrear la tabla y la explicación del hash.
- **Qué se descartó y por qué:** los tres documentos no sobrevivieron a la revisión contra el esquema real (ver entrada 4): quedaron reescritos por Mariano. Su carpeta `sqlite/` no se integró.
- **Cómo se comprobó:** según lo que dejó escrito, corrió `verificar_vista_snapshot.sql` (16 contra 16) y `verificar_no_cambio.sql` (6 pedidos, 13 detalles, stock 454, misma huella): coincide con las mediciones de Mariano. **Actualización del 05/11 (PR #3):** completó la revisión A4 desde cero en una copia (`evidencias/20`: pruebas de la tablet, C2 a C6, vistas y no cambio) y revisó la 3.c (`evidencias/21`: H36 y H04 descartados, H01 y R1 aceptados). Los resultados coinciden con los de Mariano. Según su declaración lo hizo con OpenCode (asistente GPT-5.6 Terra); no hay logs de la conversación con la IA adjuntos, solo las salidas de los comandos.

## Mediciones

| Dato | Valor | Fuente |
|---|---|---|
| Conteos `usuario` / `producto` / `pedido` | 6 / 16 / 6 | `evidencias/01` |
| `verificar_no_cambio.sql` | 6 pedidos, 13 detalles, stock 454, huella `89f8351d0162e23ef1473f32b05ce221`, igual antes y después | `evidencias/01` y `12` |
| Casos C2 a C6 | CONFLICTO y luego SIMULADO_APROBADO; RECHAZADO por stock; RECHAZADO por baja; SIMULADO_APROBADO; error de clave primaria y 0 solicitudes evaluadas | `evidencias/05` a `11` |
| Vista `v_snapshot_movil` | 16 contra 16, 0 diferencias, 0 precios con fracción de centavo, 7 columnas sin datos de usuarios | `evidencias/13` |
| Catálogo de la tablet | 16 contra 16 en la copia y 13 contra 13 en el catálogo disponible | `evidencias/14` |
| H04 | `Seq Scan` costo 20.50; con `enable_seqscan = off`, `Bitmap Index Scan` costo 22.91; 13 filas | `evidencias/15` |
| H01 y producto repetido | Stock 24 a 23 con la categoría en baja; `SQLSTATE 23505` | `evidencias/16` |
| H36 | 1 / 2 / 1 antes y después de C7 | `evidencias/17` |
| Casos borde del semáforo | 4 RECHAZADO y 1 SIMULADO_APROBADO; error por segunda pendiente | `evidencias/18` y `19` |

## Errores de la IA y del proceso que se detectaron

- Un script reconstruido por la IA que nunca evaluaba nada (entrada 1).
- Una spec de Kiro con errores de diseño (entrada 3), y un requisito (REQ-04) que prometía más de lo que hace el script.
- Documentos de Andrés con datos que no existen en el esquema (entrada 4) y un hallazgo de OpenCode que no se reproduce (entrada 5).
- Un error de Claude: se afirmó que unos archivos modificados en `.kiro/` eran los suyos, no era así y se pisó la spec corta de `docs/kiro/`; se detectó con el `diff` y se revirtió (`af24034`).
- Un error propio de Mariano: se afirmó una frecuencia de la `3b` sin ver `SPEC_U6.md`, y se escribió «5 pedidos» en la `3a` sin contrastarlo.

## Qué haríamos distinto

1. Escribir la spec en Kiro **antes** del código y generar el esquema con OpenCode, como pide el enunciado.
2. Que cada integrante guarde en `evidencias/` el log de lo que corre en su máquina, para no depender de la corrida de uno solo.
3. Contrastar cada afirmación con la fuente (la spec de la Unidad 6, el esquema, `objects.sql`) antes de escribirla.
4. Registrar desde el principio modelo, prompt y fecha de cada consulta a la IA.
5. Integrar los cambios del equipo con `git` desde el inicio y no copiando archivos a mano.
