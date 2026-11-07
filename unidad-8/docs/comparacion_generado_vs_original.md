# Comparación: SQLite generado con OpenCode vs. versión original (Objetivo 11)

Estado: borrador, 2026-11-07. Quedan `[COMPLETAR]` solo en lo que no se puede verificar (sección 1) y en la corrida 2 opcional (sección 7).

## 1. Qué se hizo y con qué herramientas

| Paso | Herramienta | Fecha | Quién |
|---|---|---|---|
| Spec revisada en Kiro (Requisitos 4, 9.8, 10.6 y 11 agregados) y commit **antes** de generar | Kiro | 2026-11-06 | Mariano |
| Corrida 1: generación de `schema_sqlite.sql`, `cargar_catalogo.sql`, `semaforo.sql`, `casos.sql` en `movil_opencode/` | OpenCode, agente Nemotron 3.5 Lightning Free | 2026-11-06 | Mariano |
| Ejecución en base nueva, diagnóstico de errores y corrección | Claude (chat), revisado y ejecutado por Mariano | 2026-11-06 | Mariano |
| Comparación de `movil_opencode/` contra `movil/` y detección de dos lagunas de la spec (REQ 6.12 y 6.13) | Claude (chat), ejecutado y verificado por Mariano en Windows | 2026-11-07 | Mariano |
| Spec ampliada (REQ 6.12 y 6.13) y esquema corregido, en ese orden, cada uno con su commit | Kiro (spec), edición manual (esquema) | 2026-11-07 | Mariano |

Registro completo de la corrida 1 (modelo, prompt y respuesta cruda): `docs/registro_opencode_corrida1.txt`.

**Declaración honesta:** los scripts que ejecutan correctamente hoy fueron en su mayor parte
reescritos con Claude a partir de los errores de la corrida 1. De OpenCode quedan la estructura general
(5 tablas, vista, CTE, orden de ejecución) y las ideas de varios casos. La corrida 1, por sí sola, **no**
produjo una base funcional.

`[COMPLETAR]` Si OpenCode leyó `unidad-8/movil/` durante la corrida (el prompt lo prohibía): no consta.
Revisar el historial de la sesión si se conserva, o declarar que no se puede verificar.

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

Sin resolver: `v_catalogo_disponible` no muestra `capturado_en` como la original. [COMPLETAR] Decidir si se agrega
al REQ 5.2 o se deja como diferencia declarada.

## 7. Versión final y límites

**Versión final propuesta:** `movil_opencode/` con los cambios de 6.4, porque cumple la
spec ampliada y pasa C1 a C8 y F2 (evidencias 25, 26 y 27). `movil/` queda como referencia y no se borra.

Límites conocidos:
- La spec se completó antes de generar, pero la versión que funciona salió de correcciones hechas con
  Claude después de la corrida 1 (sección 3), y no de la generación sin editar.
- `casos.sql` no es re-ejecutable sobre la misma base (usa UUID fijos); la spec pide base nueva (REQ 11.2).
- [COMPLETAR] Si se hace una corrida 2 de OpenCode, va como sección aparte con modelo, fecha y prompt.
