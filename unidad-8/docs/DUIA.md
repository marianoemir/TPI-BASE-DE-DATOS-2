# Declaración de Uso de IA (DUIA) — TP N.º 8 Food Store

Declaración del equipo (Grupo 10). **Cada integrante declara su propio uso de IA**, con el formato de la cátedra, y firma su parte:
el texto de cada uno está completo más abajo y también en su archivo individual (`docs/duia_<nombre>.md`), que se conserva.
El registro detallado de las interacciones (qué se pidió, qué se aceptó y qué se descartó) está en [`bitacora_ia.md`](bitacora_ia.md);
las bitácoras individuales, en `docs/bitacoras/`.

| Integrante | Declaración individual | Resumen |
|---|---|---|
| Mariano Chirino | [`duia_mariano.md`](duia_mariano.md) | Claude (versión web), NotebookLM y Kiro. No usó OpenCode |
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
**Alcance:** consignas 1 y 2 (base de la tablet en SQLite, instantánea, semáforo, casos C2 a C6), spec en Kiro (4.a), armado del repositorio y revisión de los pull requests de Andrés y Facundo
**Herramientas:** Claude (versión web, claude.ai), NotebookLM y Kiro. No usé OpenCode: el code review de la consigna 3.c con OpenCode lo hizo Facundo (`duia_facundo.md`).

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

Ninguna propuesta de la IA se incorporó sin leerla y correrla.

#### Resumen de decisiones

| Aspecto | Resultado |
|---|---|
| Semáforo | SQL puro: rojo gana sobre amarillo; solo evalúa `PENDIENTE`; el producto que falta en la instantánea es rojo |
| Recarga del catálogo | `INSERT … ON CONFLICT DO UPDATE`; la lápida conserva la fila |
| Reenvío de una solicitud | `UUID` como clave primaria; índice parcial para permitir reenviar solo tras un `CONFLICTO` |
| Código de la cátedra | No se usó: el `kit_u8_campus` no estaba disponible |
| Spec de Kiro | Posterior al código; declarado |

---

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
