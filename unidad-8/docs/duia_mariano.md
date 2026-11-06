# Declaración de Uso de IA (DUIA) — Mariano Chirino

**Integrante:** Mariano Chirino (Grupo 10)
**Materia:** Base de Datos II (UTN) — Unidad 8, TP N.º 8
**Proyecto Integrador:** Food Store
**Alcance:** consignas 1 y 2 (base de la tablet en SQLite, instantánea, semáforo, casos C2 a C6), spec en Kiro (4.a), armado del repositorio y revisión de los pull requests de Andrés y Facundo
**Herramientas:** Claude (versión web, claude.ai), NotebookLM y Kiro. No usé OpenCode: el code review de la consigna 3.c con OpenCode lo hizo Facundo (`duia_facundo.md`).

> Esta declaración cubre únicamente lo que hice y usé yo. Andrés Fabre y Facundo Quiroga
> declaran su propio uso de IA en `duia_andres.md` y `duia_facundo.md`.

---

## Registro de interacciones y decisiones con IA

### Consignas 1 y 2 — base de la tablet y sincronización

| Herramienta | Para qué se usó | Se aceptó / se descartó — por qué |
|---|---|---|
| NotebookLM | Resumir el apunte y pedir el código del `kit_u8_campus`, que no estaba en el campus | **Aceptado:** el SQL del esquema SQLite, `v_snapshot_movil` y la transacción del borrador, después de contrastarlos con las paradas 3, 4 y 5 del apunte: coincidían. **Descartado:** `simulador_sync.py`. Comparaba el resultado de `fetchone()` (una tupla) con el texto `'PENDIENTE'`, así que nunca habría evaluado nada; importaba `psycopg2` sin usarlo y nombraba una tabla `registro_sync` que no existe en el esquema. La IA lo había reconstruido, porque ese archivo no estaba en el campus. El semáforo se escribió en SQL puro. |
| Claude | Clasificar qué scripts de las Unidades 1 a 7 se reutilizan y armar la estructura del repo | **Aceptado:** `heredado/` con los scripts sin modificar. **Descartado:** ejecutar `pedidos_de_prueba.sql` y `carga_masiva.sql` (cambiarían el stock de los casos C3 y C5). Se cambió el usuario con nombre real de `data.sql` por uno inventado. |
| Claude | Borrador de `schema_sqlite.sql`, `cargar_catalogo.sql`, `pruebas_sqlite.sql`, `semaforo.sql` y los casos C2 a C6 | **Aceptado**, después de leerlo y correrlo. Alternativas que se evaluaron y se dejaron de lado (decisiones de diseño, no propuestas de la IA): `INSERT OR REPLACE` para recargar el catálogo (borra la fila y falla con la clave foránea activa) y un `UNIQUE` simple sobre `cola_sync.id_local` (impediría reenviar tras un `CONFLICTO`). Se aceptó el `UPSERT` y el índice parcial `ux_cola_una_pendiente`. Se aceptó el tratamiento explícito del producto inexistente en el `LEFT JOIN` (con `NULL`, un producto que no existe pasaría como verde). |
| Claude | Guiar la corrida en mi máquina con PowerShell | `sqlite3` no se reconocía después de instalarlo con `winget`: no creó el acceso directo en `WinGet\Links`. Se resolvió agregando al PATH la carpeta real del paquete. Se descartó la contraseña de `postgres` escrita en pantalla: se cambió a entrada oculta. |

### Consigna 4.a — spec en Kiro

| Herramienta | Para qué se usó | Se aceptó / se descartó — por qué |
|---|---|---|
| Kiro | Generar `requirements.md`, `design.md` y `tasks.md` | **Se escribió después de los scripts, no antes** (el enunciado pide lo contrario). **Corregido en `requirements.md`:** el criterio 4 del Requisito 3 decía que el semáforo marca `eliminado = 1` en `producto_cache`; eso lo hace la recarga del catálogo, no el semáforo. **Corregido en `design.md`:** exportaba con `COPY producto` en lugar de la vista `v_snapshot_movil`; inventaba un transporte "llave USB / correo"; tenía invertida la fila de los booleanos y decía que la transacción hace rollback sola. **Descartado:** las pruebas de propiedades con Hypothesis (alcance de más: el TP no exige Python) y el límite de 255 caracteres en `motivo`, que el semáforo no impone. **No consta** el prompt exacto ni el modelo que usó Kiro: no se registraron. Fecha: los archivos de `.kiro/specs/` entraron al repo en el commit `ec9a60b` del 03/11/2026 (fecha del commit, no de creación). |
| Claude | Revisar lo que generó Kiro contra los scripts y las evidencias | Detectó los errores anteriores y que la tabla de pruebas del diseño no mencionaba `pruebas_sqlite.sql` (C1 y C7). Se corrigió. |

**Carpeta `.kiro/steering/`** (`conventions.md`, `project-overview.md`, `objects-and-patterns.md`): entró al repo en el commit `66392be` del 02/11/2026 («Estructura preliminar»). **No consta** con qué herramienta se escribió ni quién la redactó; se usa como referencia de convenciones del proyecto (por ejemplo, en el hallazgo H04 de la 3.c).

### Revisión del trabajo de un compañero (PR #1 de Andrés Fabre)

| Herramienta | Para qué se usó | Se aceptó / se descartó — por qué |
|---|---|---|
| Claude | Revisar el pull request: clonar la rama, leer los archivos y probar los scripts | **Descartado del PR:** la carpeta `sqlite/` y los dos `tp8_database.db` (un esquema de ejemplo con `precio REAL`, sin `STRICT` ni centavos, que acepta texto como precio: no es el esquema del TP), y el `movil/foodstore_movil.db` vacío, que habría pisado la base con la evidencia de los casos. **Corregido:** 1.a, 3.a y 3.b tenían columnas inexistentes, ubicaban la cola en PostgreSQL, describían MongoDB como metadatos de productos y daban autoridad local a SQLite; se reescribieron contra el esquema real y `v_snapshot_movil`, y cada archivo lo aclara. Se verificó cada dato contra `schema.sql` y `esquema_documental.md`. |

### Revisión del trabajo de un compañero (PR #2 de Facundo Quiroga)

| Herramienta | Para qué se usó | Se aceptó / se descartó — por qué |
|---|---|---|
| Claude (web) | Revisar el pull request (code review 3.c, bitácora y DUIA) y contrastar cada afirmación con los scripts del repo y con lo que ejecuté en mi máquina | **Descartado (H36):** la IA de Facundo afirmaba que `pruebas_sqlite.sql` dejaba un borrador a medias; lo corrí en una base limpia y da 1/2/1 antes y después de C7 (cada bloque de C7 termina en `ROLLBACK`): `evidencias/17`. **Descartado con fundamento (H04):** el índice compuesto sí se usa si se fuerza (`enable_seqscan = off`) y con 13 filas no mejora nada: `evidencias/15`. **Aceptado, comprobado en una copia de la base:** H01 (`sp_crear_pedido` acepta un pedido de un producto de categoría eliminada) y el producto repetido en `p_items` (`SQLSTATE 23505`): `evidencias/16`. **Corregido:** nombre de la vista (`v_snapshot_movil`), estados del semáforo, sigla DUIA, versiones. Lo que Facundo no dejó escrito (modelo de OpenCode, prompt, fecha) se declaró como «no consta», sin completarlo. |
| Claude (web) | Armar casos borde del semáforo para la revisión cruzada (F2), porque el caso propio de Facundo verificaba el esquema y no el semáforo | **Aceptado después de correrlo yo:** `movil/casos_f2_semaforo.sql` (rojo + amarillo, producto fuera de la instantánea, sin ítems, no disponible, control, dos pendientes): `evidencias/18` y `19`. Quedan atribuidos a mí, no a Facundo. |

---

## Verificación sobre el motor real

Todo se probó en mi máquina (Windows PowerShell 5.1): PostgreSQL 17.10 con la base de pruebas `foodstore_u8`, armada desde cero con los scripts de `heredado/`, y SQLite 3.54.1.

1. Corrida completa de C1 a C7 con las salidas guardadas en `evidencias/01` a `12`.
2. Prueba de que PostgreSQL no cambió: `verificar_no_cambio.sql` antes y después, con la misma huella de stock `89f8351d0162e23ef1473f32b05ce221`.
3. Paso 5 del protocolo de seguridad: `postgresql/verificar_vista_snapshot.sql` y `movil/verificar_vistas_tablet.sql`, con las salidas en `evidencias/13` y `14`.
4. Comprobación de los hallazgos de la 3.c de Facundo (H36, H01, H04 y R1) sobre una copia de la base: salidas en `evidencias/15` a `17` y script `postgresql/verificar_hallazgos_3c.sql`.

5. Casos borde del semáforo (F2): `movil/casos_f2_semaforo.sql`, con las salidas en `evidencias/18` y `19`.

Ninguna propuesta de la IA se incorporó sin leerla y correrla.

## Resumen de decisiones

| Aspecto | Resultado |
|---|---|
| Semáforo | SQL puro: rojo gana sobre amarillo; solo evalúa `PENDIENTE`; el producto que falta en la instantánea es rojo |
| Recarga del catálogo | `INSERT … ON CONFLICT DO UPDATE`; la lápida conserva la fila |
| Reenvío de una solicitud | `UUID` como clave primaria; índice parcial para permitir reenviar solo tras un `CONFLICTO` |
| Código de la cátedra | No se usó: el `kit_u8_campus` no estaba disponible |
| Spec de Kiro | Posterior al código; declarado |
