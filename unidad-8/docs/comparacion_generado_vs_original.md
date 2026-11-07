# Comparación: SQLite generado con OpenCode vs. versión original (Objetivo 11)

Estado: 2026-11-07. Secciones 1 a 8. Sin pendientes de redacción; los puntos que no se pudieron verificar están declarados como tales (secciones 1 y 8.3).

## 1. Qué se hizo y con qué herramientas

| Paso | Herramienta | Fecha | Quién |
|---|---|---|---|
| Spec revisada en Kiro (Requisitos 4, 9.8, 10.6 y 11 agregados) y commit **antes** de generar | Kiro | 2026-11-06 | Mariano |
| Corrida 1: generación de `schema_sqlite.sql`, `cargar_catalogo.sql`, `semaforo.sql`, `casos.sql` en `movil_opencode/` | OpenCode, agente Nemotron 3.5 Lightning Free | 2026-11-06 | Mariano |
| Ejecución en base nueva, diagnóstico de errores y corrección | Claude (chat), revisado y ejecutado por Mariano | 2026-11-06 | Mariano |
| Comparación de `movil_opencode/` contra `movil/` y detección de dos lagunas de la spec (REQ 6.12 y 6.13) | Claude (chat), ejecutado y verificado por Mariano en Windows | 2026-11-07 | Mariano |
| Spec ampliada (REQ 6.12 y 6.13) y esquema corregido, en ese orden, cada uno con su commit | Kiro (spec), edición manual (esquema) | 2026-11-07 | Mariano |
| Corrida 2: generación sin editar en carpeta aislada (sin `movil/`) en `movil_opencode_v2/`, y ejecución con evidencia 28 | OpenCode, agente Nemotron 3.5 Lightning Free; ejecución en Windows | 2026-11-07 (09:39 a 09:50) | Mariano |
| Verificación adicional de la corrida 2 (evidencia 29) | SQLite 3.54.1 en Windows; script revisado con Claude (chat), ejecutado por Mariano | 2026-11-07 (14:55) | Mariano |

Registro completo de la corrida 1 (modelo, prompt y respuesta cruda): `docs/registro_opencode_corrida1.txt`.
Registro de la corrida 2: `docs/registro_opencode_corrida2.txt` (resultado y análisis en la sección 8).

**Declaración honesta:** los scripts que ejecutan correctamente hoy fueron en su mayor parte
reescritos con Claude a partir de los errores de la corrida 1. De OpenCode quedan la estructura general
(5 tablas, vista, CTE, orden de ejecución) y las ideas de varios casos. La corrida 1, por sí sola, **no**
produjo una base funcional.

**Límite declarado:** no se puede verificar si OpenCode leyó `unidad-8/movil/` durante la corrida 1. El prompt lo prohibía, pero no hay
forma de comprobarlo. Por eso se hizo la corrida 2 en una carpeta aislada que no contenía `movil/` (sección 8).

## 2. Resultado de la corrida 1 (sin editar)

Evidencia: `evidencias/22_corrida1_con_errores.txt` (y salidas intermedias).
El esquema no se creó, y por eso fallaron en cascada la carga, el semáforo y los casos.

## 3. Fallas de OpenCode y corrección aplicada

| Archivo | Falla en la corrida 1 | Corrección |
|---|---|---|
| `schema_sqlite.sql` | `STRICT` escrito dentro de las columnas (error de sintaxis en las 5 tablas) | `STRICT` como opción de tabla: `) STRICT;` |
| `schema_sqlite.sql` | `UNIQUE (id_local) WHERE estado = 'PENDIENTE'` dentro del `CREATE TABLE` (no existe) | `CREATE UNIQUE INDEX ux_cola_una_pendiente ... WHERE estado = 'PENDIENTE'` |
| `schema_sqlite.sql` | `motivo NOT NULL` junto con un `CHECK` que lo exige solo en `CONFLICTO`/`RECHAZADO`: impedía insertar solicitudes `PENDIENTE` | `motivo` nullable; el `CHECK` queda a nivel de tabla |
| `cargar_catalogo.sql` | `INSERT ... SELECT ... ON CONFLICT` sin `WHERE` (error de sintaxis) | Se agregó `WHERE true` |
| `cargar_catalogo.sql` | `DELETE FROM producto_cache` previo: contradice REQ 3.4 y 8.3 (no se borran filas referenciadas por borradores) | Se eliminó el `DELETE`; queda solo el UPSERT |
| `semaforo.sql` | `no such column: i.cantidad` (alias fuera de alcance): el semáforo no evaluaba nada | Reescrito con CTE de causas (`R` = rojo, `A` = amarillo) |
| `semaforo.sql` | Para un producto inexistente el motivo salía `NULL` (se concatenaba el nombre, que es `NULL`) | Motivo `producto N no existe en el servidor` con el id (REQ 9.3) |
| `casos.sql` | UUID de menos de 36 caracteres, datos inventados que no coinciden con `servidor_snapshot.csv`, `ROLLBACK` sin `BEGIN`, C6 y F2-6 comentados | Reescrito con datos reales del CSV, UUID de 36 caracteres, `BEGIN … ROLLBACK`, C6 y F2-6 ejecutables y comparación automática `OK`/`FALLA` |

## 4. Errores encontrados en la propia spec o en la corrección

- **REQ 5.3 decía 14 productos en `v_catalogo_disponible`.** Con el CSV real son **13**: se ocultan el 3
  (baja), el 15 (no disponible) y el 16 (ambos). Se corrige la spec, con commit y fecha.
- **Error de la corrección:** durante la sesión se cambió la vista para devolver `precio_centavos` sin dividir,
  por una suposición. El REQ 5.2 pide `precio_centavos / 100.0`. Se restauró.
- **La spec no pedía dos cosas que el original sí tenía** (hallazgo del 07/11 al comparar con `movil/`): un valor por defecto en
  `pedido_borrador.creado_en` y la clave foránea `cola_sync.id_local → pedido_borrador`. OpenCode no las generó porque la spec no las pedía.
  Se agregaron como REQ 6.12 y 6.13 (commit de la spec primero, esquema después). Detalle en la sección 6.

## 5. Resultado final

Evidencia: `evidencias/25_casos_opencode.txt`, ejecutada en base nueva con SQLite real de Windows.
Se repitió con el esquema corregido (REQ 6.12 y 6.13) en `evidencias/27_casos_opencode_tras_6_12_6_13.txt`: mismos resultados, todos `OK`.

- C1: 13 productos, `OK`.
- C2, C3 (incluido stock 0), C4, C5, C8 (A y B), F2-1 a F2-5: todos `OK`.
- C2 con reenvío de UUID distinto tras `CONFLICTO` (REQ 1.3): `SIMULADO_APROBADO`, y el original sigue `CONFLICTO`.
- F2-6: la segunda solicitud `PENDIENTE` del mismo borrador falla por `ux_cola_una_pendiente`.
- C6: el reenvío de UUID duplicado falla por clave primaria y la fila original queda intacta; el semáforo sin pendientes reporta 0.
- C7: las tres inserciones inválidas fallan y los conteos no cambian (0 / 0 / 0).
- C8: `stock_visto` del Tiramisú sigue en 6.
- Recarga de `cargar_catalogo.sql` sobre la misma base: sin errores, 17 filas (16 de la instantánea + producto 99 de F2-2).

## 6. Comparación contra los originales (`unidad-8/movil/`)

**Cómo se comparó.** Se leyeron los cuatro scripts de `movil_opencode/` contra los de `movil/` y se
corrió el flujo completo (esquema → carga de `servidor_snapshot.csv` → carga del catálogo → casos F2
originales → semáforo) sobre ambas versiones, con una base en memoria y SQLite 3.45.1 (Python),
asistido por Claude. La corrida se repitió en SQLite de Windows con el esquema corregido y los casos F2 originales: `evidencias/26_comparacion_originales.txt`.

### 6.1 Qué es igual

- Las cinco tablas, todas `STRICT`, con los mismos `CHECK` (precios ≥ 0, cantidad > 0, UUID de 36
  caracteres, `forma_pago`, estados de la cola, `motivo` obligatorio en `CONFLICTO` y `RECHAZADO`).
- El índice parcial `ux_cola_una_pendiente` y la clave primaria de `cola_sync.solicitud_uuid`.
- La carga por `INSERT … ON CONFLICT DO UPDATE` con `WHERE true`, sin `DELETE` ni `INSERT OR REPLACE`.
- La lógica del semáforo: se evalúan solo las `PENDIENTE`, el rojo gana sobre el amarillo, un producto
  ausente de la instantánea es rojo, y repetir la corrida da `solicitudes_evaluadas = 0`.
- Resultados: `v_catalogo_disponible` devuelve 13 productos en las dos versiones, y los estados de los
  cinco borradores F2 coinciden (`RECHAZADO` ×4 y `SIMULADO_APROBADO` ×1).

### 6.2 Qué difiere

| Aspecto | Original (`movil/`) | OpenCode corregido (`movil_opencode/`) | Efecto |
|---|---|---|---|
| `cola_sync.id_local` | `REFERENCES pedido_borrador(id_local)` | **sin clave foránea** | Permite encolar una solicitud de un borrador que no existe; el semáforo la rechaza como «borrador sin ítems» |
| `pedido_borrador.creado_en` | `DEFAULT` (fecha UTC ISO) | `NOT NULL` **sin default** | Los scripts originales de F2 (que no informan `creado_en`) fallan contra esta versión |
| Formato de fechas | `2026-11-07T10:03:58Z` | `2026-11-07 10:03:58` | Solo cosmético; cambia el aspecto de `creada_en` y `evaluada_en` |
| Columnas de `v_catalogo_disponible` | incluye `capturado_en` | incluye `disponible_visto` | La vista original muestra de qué instantánea viene cada precio |
| Mensajes del `motivo` | `stock insuficiente de Tiramisú (pide 10, hay 6)` | `Tiramisú: pedido 10, stock 6` | Mismo contenido, otro texto |
| Un ítem con varias causas | un solo problema por ítem (`CASE`) | lista todas las causas del color ganador | El de OpenCode es más informativo (REQ 3.5) |
| Cierre de `cargar_catalogo.sql` | `BEGIN … COMMIT` y devuelve la fecha de la instantánea | sin transacción explícita y devuelve la hora de la carga | La fecha de la copia es la de `capturado_en`; en la versión de OpenCode se pierde ese dato |

Nota: la tabla describe la comparación hecha **antes** de agregar los REQ 6.12 y 6.13; las dos primeras filas quedaron resueltas (sección 6.4).

### 6.3 Resultado de correr los casos originales contra la versión corregida

- **Tal cual**, los casos originales de F2 **no corren** contra `movil_opencode/`: fallan por
  `NOT NULL constraint failed: pedido_borrador.creado_en`, y como la cola no tiene clave foránea, las
  solicitudes igual entran y salen todas `RECHAZADO` por «borrador sin ítems».
- **Con dos líneas agregadas** al esquema (`DEFAULT` en `creado_en` y `REFERENCES` en
  `cola_sync.id_local`), los cinco casos dan el mismo estado que el original y el único error esperado
  es el de F2-6 (`UNIQUE constraint failed: cola_sync.id_local`).
- **Causa en la spec.** El REQ 6 no pedía ninguna de las dos cosas, así que la omisión de OpenCode fue
  coherente con la spec. Es una laguna de la spec, no solo un error del modelo.

### 6.4 Qué se hace con esto

Hecho el 07/11: se agregaron a la spec el REQ 6.12 (`creado_en` con valor por defecto en UTC) y el REQ 6.13
(`cola_sync.id_local` con clave foránea a `pedido_borrador`), con su commit, y después se corrigió
`schema_sqlite.sql`. Con el esquema corregido, los casos F2 originales dan el mismo estado que `movil/`
(`evidencias/26`) y `casos.sql` sigue en `OK` (`evidencias/27`).

Diferencia declarada, sin resolver: `v_catalogo_disponible` no muestra `capturado_en` como la original. No cambia ningún resultado de C1 a C8 ni de F2, así que no se agrega al REQ 5.2.

## 7. Versión final y límites

**Versión final propuesta:** `movil_opencode/` con los cambios de 6.4, porque cumple la
spec ampliada y pasa C1 a C8 y F2 (evidencias 25, 26 y 27). `movil/` queda como referencia y no se borra.

Límites conocidos:
- La spec se completó antes de generar, pero la versión que funciona salió de correcciones hechas con
  Claude después de la corrida 1 (sección 3), y no de la generación sin editar.
- `casos.sql` no es re-ejecutable sobre la misma base (usa UUID fijos); la spec pide base nueva (REQ 11.2).
- La corrida 2 (sección 8) tampoco produjo una base funcional sin editar; no cambia la versión final, y `movil_opencode_v2/` se conserva como evidencia sin editar.

## 8. Corrida 2 de OpenCode (sin editar)

**Datos.** Mismo modelo que la corrida 1 (OpenCode, agente Nemotron 3.5 Lightning Free), el 2026-11-07 de 09:39 a 09:50,
en una carpeta aislada (`C:\corrida2_opencode`) que no contenía `movil/`, `docs/` ni `evidencias/`. Fuentes entregadas:
`AGENTS.md`, la spec (con los REQ 5 a 13), `.kiro/steering/` y `servidor_snapshot.csv`. Prompt y respuesta cruda:
`docs/registro_opencode_corrida2.txt`. Resultado, sin ninguna edición: `movil_opencode_v2/` (commits `dc1ead0` y `55cb059`).
Ejecución: `evidencias/28_corrida2_sin_editar.txt`. Como la carpeta no tenía `movil/`, en esta corrida el agente no pudo
leer los originales (lo que sigue sin poder verificarse, sección 1, es la corrida 1).

**Cómo se ejecutó.** Siguiendo el orden del README de `movil_opencode_v2/`, sobre una base nueva, con SQLite de Windows y un
`sqlite3 base ".read …"` por script: cada script es una conexión nueva. Ningún archivo se editó antes de correrlo.

### 8.1 Defectos encontrados

| # | Archivo y línea | Defecto | Lo exigía | Qué muestra la evidencia |
|---|---|---|---|---|
| 1 | `cargar_catalogo.sql:15-16` | `INSERT … SELECT … ON CONFLICT` sin `WHERE` | REQ 8 (recarga del catálogo) | Evidencia 28: `Parse error near line 6 … near "DO": syntax error`. `producto_cache` queda con 0 filas y C1 da 0 (esperado 13). Es el mismo defecto de la corrida 1 (sección 3) |
| 2 | `schema_sqlite.sql:16, 24, 35, 47, 61` | Las cinco tablas cierran con `);` sin `STRICT`; la palabra aparece solo en comentarios (líneas 1 y 2) | REQ 6.1 | Evidencias 28 y 29: `pragma_table_list` informa `strict = 0` en las cinco, y un texto en `precio_centavos` se acepta (`typeof` = `text`) |
| 3 | `casos_c2_c6_resolucion.sql:15`, `casos_f2_semaforo.sql:79` | `criada_en` en lugar de `creada_en` (`schema_sqlite.sql:44`) | — (error de tipeo) | Evidencia 28: `table cola_sync has no column named criada_en`, dos veces |
| 4 | `casos_f2_semaforo.sql:78-85` | `BEGIN TRY;`, `END TRY;`, `BEGIN CATCH;`, `END CATCH;` (T-SQL, no existen en SQLite) | — | Evidencia 28: cuatro `Parse error`. El `SELECT` del bloque `CATCH` se ejecuta igual: la salida trae a la vez `ERROR: segunda PENDIENTE … debería haber sido rechazada` y `C2-6 - OK: … bloqueada por índice parcial` (rotulado C2-6 en lugar de F2-6). Es un falso `OK`: el `INSERT` falló por `criada_en`, no por `ux_cola_una_pendiente` (que existe en `schema_sqlite.sql:50` pero no llegó a probarse) |
| 5 | `casos_c8_competencia_stock.sql:43-46` | `SELECT` con los alias `s1` y `s2` sin `FROM` | REQ 10 (C8) | Evidencia 28: `no such column: s1.solicitud_uuid`; el script no imprime los estados de A y B. El segundo `SELECT` (stock del Tiramisú, líneas 49-52) devuelve cero filas porque `producto_cache` está vacía (defecto 1). Los dos estados solo se ven en el listado final de la cola (`SIMULADO_APROBADO` ×2) |
| 6 | `schema_sqlite.sql:43` | `motivo TEXT,` sin `CHECK` | REQ 6.11 (`motivo` no nulo en `CONFLICTO` y `RECHAZADO`) | Evidencia 29, prueba A: las dos filas con `motivo` NULL entran (2 filas) |
| 7 | `cargar_catalogo.sql`, `semaforo.sql` y los cuatro `casos_*.sql` | Sin `PRAGMA foreign_keys = ON;`. Solo lo traen `schema_sqlite.sql:5` y `pruebas_sqlite.sql:39` (este recién después de C1 y del primer caso de C7) | REQ 6.3 (en cada script). El prompt lo nombró solo para el esquema (tarea 1) | Evidencia 28: los ítems de C2 a C5, C8 y F2 se insertaron aunque `producto_cache` tenía 0 filas. Evidencia 29, pruebas B1 y B2: sin `PRAGMA` entra un ítem de producto inexistente; con `PRAGMA ON` falla con `FOREIGN KEY constraint failed` |
| 8 | (conjunto) | No existe `casos.sql`: se entregaron cuatro `casos_*.sql` más `pruebas_sqlite.sql` | Prompt, tarea 4; REQ 11.2 (orden documentado) | El README de `movil_opencode_v2/` documenta el orden con esos cinco archivos |
| 9 | `pruebas_sqlite.sql:35, 43, 50` | Cada `INSERT` de C7 va seguido de un `SELECT 'C7 - ERROR: … debería haber sido rechazado…'` que se ejecuta siempre | REQ 6.7 a 6.10 | Evidencia 28: la salida trae los tres mensajes aunque solo dos `INSERT` fallaron (líneas 33 y 41): no distingue un rechazo correcto de un fallo |

### 8.2 Afirmaciones del agente que no eran ciertas

El agente declaró en su respuesta que no ejecutó nada (`registro_opencode_corrida2.txt`, línea 94) y, aun así, afirmó lo siguiente:

| Afirmación | Dónde | Qué se comprobó |
|---|---|---|
| Cinco tablas en modo `STRICT` | registro, línea 101; `README.md:61` | Falso: `strict = 0` en las cinco (evidencias 28 y 29, defecto 2) |
| La sintaxis SQL fue revisada | registro, línea 102 | Falso: cuatro de los ocho scripts dan errores inesperados (`cargar_catalogo`, `casos_c2_c6`, `casos_f2`, `casos_c8`) |
| `PRAGMA foreign_keys = ON;` al inicio de cada script | `README.md:62` | Falso: lo traen 2 de los 8 scripts (defecto 7) |
| Todos los scripts son ejecutables sobre una base nueva vacía | registro, línea 88 | Sin sustento: contradice la línea 94 del mismo registro, donde dice que no ejecutó nada |

### 8.3 Lo que sí funcionó

- **`semaforo.sql`** (93 líneas) corre sin errores. Evaluó las solicitudes pendientes en una pasada (`solicitudes_evaluadas` = 4 la
  primera vez y 9 la segunda). Estados observados en la cola final: C3 `RECHAZADO` («pedido 7, stock 6»), C4 `RECHAZADO` («dado de baja»),
  C5 (control) y C8 (A y B) `SIMULADO_APROBADO`, y en F2 «producto 9999 no existe en el servidor», «no disponible», «borrador sin ítems» y un
  `SIMULADO_APROBADO`. Coinciden con lo que piden los REQ 2, 3 y 10. Lee `snapshot_servidor` y no `producto_cache`, por eso clasificó bien
  aunque el catálogo estaba vacío.
- **C2 (`CONFLICTO`) no se ejercitó.** Requiere subir el precio en PostgreSQL y recargar (paso 6 del README de `movil_opencode_v2/`) y esa
  parte no figura en la evidencia 28; las dos solicitudes C2 quedaron `SIMULADO_APROBADO`, que es lo esperable sin cambio de precio.
  No consta que el paso 6 se haya corrido; C2 queda sin ejercitar en la corrida 2.
- **`schema_sqlite.sql`** trae `pedido_borrador.creado_en` con `DEFAULT` en UTC (línea 23), `cola_sync.creada_en` con `DEFAULT` (línea 44), la clave
  foránea `cola_sync.id_local → pedido_borrador` (línea 46) y el índice parcial `ux_cola_una_pendiente` (línea 50). La spec de esta corrida
  ya incluía los REQ 6.12 y 6.13 (agregados antes de generar) y se cumplieron: confirma que esas dos omisiones de la corrida 1 eran lagunas
  de la spec y no solo errores del modelo.

### 8.4 Verificación adicional (evidencia 29)

Se ejecutó `schema_sqlite.sql` sin editar sobre una base temporal (SQLite 3.54.1, Windows, 2026-11-07 14:55) y, en conexiones separadas como en la evidencia 28, se probaron tres puntos que esa evidencia no cubre. Las pruebas corrieron en el orden A, B1, B2, C sobre la misma base. Salida completa: `evidencias/29_corrida2_motivo_fk_strict.txt`.

- **(A) Defecto 6.** Con `PRAGMA foreign_keys = ON`, se insertaron una solicitud `CONFLICTO` y una `RECHAZADO` con `motivo` NULL. Ambas entraron (2 filas): el esquema no tiene el `CHECK` que exige el REQ 6.11.
- **(B) Defecto 7.** Sin `PRAGMA`, un ítem de un producto inexistente se insertó con `producto_cache` en 0 filas (1 fila en `item_borrador`). Con `PRAGMA foreign_keys = ON`, otro ítem de producto inexistente falló con `FOREIGN KEY constraint failed` y el conteo quedó en 1. La clave foránea existe; lo que falta es el `PRAGMA` en cada script (REQ 6.3).
- **(C) Defecto 2.** Un texto (`'no_es_numero'`) insertado en `precio_centavos` se aceptó y `typeof()` devolvió `text`. `pragma_table_list` informa `strict = 0` en las cinco tablas (`snapshot_servidor`, `cola_sync`, `producto_cache`, `pedido_borrador`, `item_borrador`).

Los defectos 2, 6 y 7 quedan confirmados por ejecución, no solo por lectura. La versión de SQLite difiere de la usada en la sección 6 (3.45.1, Python); no afecta lo observado, porque `STRICT` existe desde la 3.37.

### 8.5 Causa: spec, prompt o modelo

| # | ¿Estaba en la spec? | Atribución |
|---|---|---|
| 1 | No (es sintaxis de SQLite) | Modelo; se repite desde la corrida 1 |
| 2 | Sí, REQ 6.1 | Modelo: incumple la spec |
| 3, 4, 5 | No aplica (errores de escritura o de otro motor) | Modelo: no ejecutó nada |
| 6 | Sí, REQ 6.11 | Modelo: incumple la spec |
| 7 | Sí, REQ 6.3 | Modelo; el prompt solo lo pidió para el esquema |
| 8 | No por nombre; sí en el prompt (tarea 4) | Modelo |
| 9 | La spec pide el rechazo (REQ 6.7 a 6.10), no cómo informarlo | Modelo; posible mejora de la spec |

A diferencia de la corrida 1, donde la comparación con `movil/` mostró dos lagunas de la spec (REQ 6.12 y 6.13, sección 4), en la corrida 2
los incumplimientos son contra requisitos ya escritos (6.1, 6.3, 6.11) o errores de escritura. No se agrega ningún requisito por esta corrida.
Límite declarado: la spec dice qué debe rechazarse, pero no que el script de casos informe `OK` o `FALLA` según el resultado real (defecto 9), y no se agrega ahora un criterio al REQ 11.

### 8.6 Comparación con la corrida 1

| | Corrida 1 | Corrida 2 |
|---|---|---|
| Base funcional sin editar | No | No |
| `cargar_catalogo.sql` | `INSERT … ON CONFLICT` sin `WHERE` | El mismo error |
| `STRICT` | Escrito dentro de las columnas (sintaxis inválida) | Ausente en las cinco tablas |
| `semaforo.sql` | `no such column: i.cantidad`: no evaluaba nada | Funciona |
| Casos | UUID de menos de 36 caracteres, datos que no coinciden con el CSV, `ROLLBACK` sin `BEGIN` | `criada_en`, `BEGIN TRY`, `SELECT` sin `FROM` |

### 8.7 Conclusión

La corrida 2 tampoco produjo una base funcional sin editar: cuatro de los ocho scripts dan errores inesperados, el esquema incumple los
REQ 6.1 y 6.11, seis scripts incumplen el 6.3, y la salida de los casos incluye resultados que no se pueden tomar por buenos (el falso `OK` de
F2-6 y los mensajes de C7 que se imprimen siempre). Lo que sirve es `semaforo.sql` y los `DEFAULT` y la clave foránea del esquema.
La versión final sigue siendo `movil_opencode/` con las correcciones declaradas (sección 7); `movil_opencode_v2/` queda como evidencia sin editar.
