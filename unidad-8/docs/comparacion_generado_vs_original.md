# Comparación: SQLite generado con OpenCode vs. versión original (Objetivo 11)

Estado: borrador, 2026-11-06. Los puntos `[COMPLETAR]` todavía no se hicieron.

## 1. Qué se hizo y con qué herramientas

| Paso | Herramienta | Fecha | Quién |
|---|---|---|---|
| Spec revisada en Kiro (Requisitos 4, 9.8, 10.6 y 11 agregados) y commit **antes** de generar | Kiro | 2026-11-06 | Mariano |
| Corrida 1: generación de `schema_sqlite.sql`, `cargar_catalogo.sql`, `semaforo.sql`, `casos.sql` en `movil_opencode/` | OpenCode, agente Nemotron 3.5 Lightning Free | 2026-11-06 | Mariano |
| Ejecución en base nueva, diagnóstico de errores y corrección | Claude (chat), revisado y ejecutado por Mariano | 2026-11-06 | Mariano |

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

## 5. Resultado final

Evidencia: `evidencias/25_casos_opencode.txt`, ejecutada en base nueva con SQLite real de Windows.

- C1: 13 productos, `OK`.
- C2, C3 (incluido stock 0), C4, C5, C8 (A y B), F2-1 a F2-5: todos `OK`.
- C2 con reenvío de UUID distinto tras `CONFLICTO` (REQ 1.3): `SIMULADO_APROBADO`, y el original sigue `CONFLICTO`.
- F2-6: la segunda solicitud `PENDIENTE` del mismo borrador falla por `ux_cola_una_pendiente`.
- C6: el reenvío de UUID duplicado falla por clave primaria y la fila original queda intacta; el semáforo sin pendientes reporta 0.
- C7: las tres inserciones inválidas fallan y los conteos no cambian (0 / 0 / 0).
- C8: `stock_visto` del Tiramisú sigue en 6.
- Recarga de `cargar_catalogo.sql` sobre la misma base: sin errores, 17 filas (16 de la instantánea + producto 99 de F2-2).

## 6. Comparación contra los originales (`unidad-8/movil/`)

`[COMPLETAR]` Diferencias entre `movil_opencode/` (versión corregida) y `movil/` (original, hecha con Claude y
NotebookLM): esquema, carga, semáforo, casos. Qué es igual, qué difiere y por qué.

`[COMPLETAR]` Correr los casos originales (evidencias 01 a 21) contra la versión corregida y registrar si los resultados coinciden.

## 7. Versión final y límites

`[COMPLETAR]` Cuál queda como versión final y por qué. Los originales **no se borran**.

Límites conocidos:
- La spec se revisó antes de generar, pero la versión funcional salió de una corrección posterior a la corrida 1.
- `casos.sql` no es re-ejecutable sobre la misma base (usa UUID fijos); la spec pide base nueva (REQ 11.2).
- `[COMPLETAR]` Una corrida 2 de OpenCode con la spec corregida, si se hace, va como sección aparte con su modelo, fecha y prompt.
