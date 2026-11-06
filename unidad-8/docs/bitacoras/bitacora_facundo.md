# Bitácora individual de trabajo (TP8) — Facundo Quiroga

**Integrante:** Facundo Quiroga
**Rama de trabajo:** `review-final`
**Entorno:** PostgreSQL `foodstore_u8` (servidor) y SQLite `foodstore_movil.db` (móvil)

> Texto de Facundo (PR #2) con correcciones de Mariano Chirino del 05/11/2026. Lo corregido está marcado con *[corregido]*;
> lo que no consta por escrito está en la sección «Nota de revisión» al final.

---

## 1. Verificación del entorno e hito H0

- Se verificó la versión de SQLite con `python -c "import sqlite3; print(sqlite3.sqlite_version)"`: **3.54.1**, mayor que la 3.37 que exige `STRICT`.
  *[corregido]* Eso mide la librería de Python; la del CLI `sqlite3` es otra medición (el README avisa que pueden diferir).
- Se creó `foodstore_movil.db` en `movil/` con `schema_sqlite.sql` y se importó el catálogo desde `servidor_snapshot.csv` con `cargar_catalogo.sql`.
- Se corrió `pruebas_sqlite.sql`: `integrity_check` dio `ok` y aparecieron los tres errores esperados de C7
  (`CHECK constraint failed`, `FOREIGN KEY constraint failed`, `cannot store TEXT value in INTEGER column`), sin dejar filas nuevas.

## 2. Code review de scripts (consigna 3.c)

- Se creó la rama `review-final` y se revisó el conjunto de scripts con el agente Plan de **OpenCode**.
- Cada observación se llevó al motor antes de decidir. Detalle en `docs/partes/3c_code_review.md`; evidencias `15` a `17`.

*[corregido]* Resultado final de los hallazgos (el borrador tenía H36 como aceptado):

1. **H36** (U8, `movil/pruebas_sqlite.sql`) — la IA dijo que un `COMMIT` tras un error dejaría un borrador a medias. **Descartado:** el script da 1/2/1 antes y después de C7 y cada bloque de C7 termina en `ROLLBACK`.
2. **H01** (base heredada, vista `v_snapshot_movil` contra `sp_crear_pedido`) — **aceptado:** el procedimiento acepta pedidos de una categoría dada de baja.
3. **H04** (base heredada, `detalle_pedido`) — **descartado con fundamento:** con 13 filas no hay mejora y `conventions.md` no permite agregar índices.
4. **R1** (base heredada, `sp_crear_pedido`) — **aceptado:** un producto repetido en `p_items` falla con `SQLSTATE 23505` sin mensaje de negocio.

## 3. Revisión del semáforo y casos propios (tarea F2)

- Se revisó `movil/semaforo.sql` sobre los casos C2 a C6. *[corregido]* Los estados que produce son `CONFLICTO` (amarillo: cambió un precio),
  `RECHAZADO` (rojo: producto inexistente, no disponible, dado de baja o sin stock) y `SIMULADO_APROBADO` (verde). `PENDIENTE` es el estado de entrada:
  solo se evalúan las solicitudes pendientes.
- Caso propio: se insertó un borrador de prueba y la base rechazó `item_borrador.precio_centavos_visto` nulo con `NOT NULL constraint failed`.
  *[corregido]* Esto verifica el esquema (`STRICT` y `NOT NULL`), no la lógica del semáforo: **no cuenta como caso del semáforo**.

**Casos borde del semáforo (ejecutados por Mariano, 05/11/2026, no por Facundo).** Para cubrir lo que el caso propio no probaba, Mariano corrió
`movil/casos_f2_semaforo.sql` sobre una copia de la base de la tablet (salidas en `evidencias/18` y `19`):

| Caso | Qué se probó | Resultado del semáforo |
|---|---|---|
| F2-1 | Rojo y amarillo en el mismo borrador (cambió el precio de la Muzzarella y piden 10 Tiramisú, quedan 6) | `RECHAZADO`, motivo solo del rojo: gana el rojo |
| F2-2 | Producto que no está en la instantánea (id 99) | `RECHAZADO`: el producto no existe en el servidor (no pasa como verde) |
| F2-3 | Borrador sin ítems | `RECHAZADO`: borrador sin ítems |
| F2-4 | Producto no disponible (id 15) | `RECHAZADO`: no disponible |
| F2-5 | Control: todo coincide | `SIMULADO_APROBADO` (no es una venta) |
| F2-6 | Segunda solicitud `PENDIENTE` del mismo borrador | Error `UNIQUE constraint failed: cola_sync.id_local` (índice parcial `ux_cola_una_pendiente`) |

En la misma corrida `solicitudes_evaluadas` dio 5: las solicitudes de C2 a C5 conservaron su `evaluada_en` anterior, es decir, el semáforo evalúa solo las `PENDIENTE`.

## 4. Próximos pasos *[corregido]*

La DUIA ya está en `docs/duia_facundo.md`. Queda completar los datos de OpenCode (ver nota) y la unificación de la bitácora de IA, que hace Mariano al final.

---

## Nota de revisión del equipo (Mariano Chirino, 05/11/2026)

Esta nota la agrega Mariano al integrar el PR #2. El resto del texto es de Facundo, con las correcciones señaladas.

- **Comprobaciones.** Mariano repitió H36, H01, H04 y R1 en su máquina (PostgreSQL 17.10, SQLite 3.54.1); las salidas están en `evidencias/15`, `16` y `17`.
  El script de H01 y R1 es `postgresql/verificar_hallazgos_3c.sql`.
- **Lo que no consta por escrito**, según lo que dejó Facundo, y no hay logs adjuntos: modelo y proveedor de OpenCode, el prompt, la fecha de la corrida,
  cuántos hallazgos propuso en total la IA, cuáles de H01 y R1 salieron de OpenCode y cuáles de otra fuente, la versión de PostgreSQL con la que corrió
  (la 3.c borrador decía 16) y las salidas de C2 a C6 de su revisión F2. Si Facundo los aporta, se agregan firmados por él; hasta entonces no se completan.
