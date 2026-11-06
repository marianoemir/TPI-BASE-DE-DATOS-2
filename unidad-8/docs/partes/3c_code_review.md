# 3.c Code review con IA de los scripts de la cursada

> Versión corregida por Mariano Chirino (05/11/2026) sobre el borrador de Facundo Quiroga (PR #2).
> Los cambios y lo que no pudo comprobarse están en la sección «Revisión de Mariano» al final.

## Contexto y metodología

El análisis se hizo en la rama `review-final` con **OpenCode** en el **agente Plan** (solo lectura, no modifica archivos).
Ningún hallazgo de la IA se dio por cierto sin comprobarlo en el motor. Las comprobaciones que respaldan esta tabla
las repitió Mariano en **PostgreSQL 17.10** y **SQLite 3.54.1** y están guardadas en `evidencias/15` a `17`.
Decisiones posibles (enunciado): **aceptado**, **corregido** o **descartado**.

## Hallazgos y decisiones

| ID | Archivo (unidad) | Qué dijo la IA | Cómo se comprobó en la base | Decisión y motivo |
|---|---|---|---|---|
| **H36** | `movil/pruebas_sqlite.sql` (U8) | El CLI de SQLite no hace `ROLLBACK` solo ante un error de restricción, así que un `COMMIT` posterior dejaría un borrador a medias (borrador sin ítems). | Se corrió el script completo en una base limpia (`evidencias/17`). Los tres errores de C7 (`CHECK`, `FOREIGN KEY`, `STRICT`) ocurren, pero los conteos de borradores / ítems quedan en **1 / 2 antes y después de C7**, y la cola en 1. Cada bloque de C7 termina en `ROLLBACK`: no hay ningún `COMMIT` después de un error. | **DESCARTADO.** El comportamiento general del CLI es cierto (sin `-bail` un error no aborta la transacción), pero **este script no lo sufre**: C7 está escrito con `BEGIN … ROLLBACK` y no deja filas. No hay nada que corregir. |
| **H01** | `postgresql/10_snapshot_catalogo.sql` vs `heredado/base_heredada/objects.sql` (base heredada) | La vista `v_snapshot_movil` marca como baja los productos de una categoría eliminada (`p.eliminado OR c.eliminado`), pero `sp_crear_pedido` solo valida `producto.eliminado`. | Copia de la base: `UPDATE categoria SET eliminado = TRUE WHERE id = 5`. La vista sigue devolviendo 16 filas, 4 con `eliminado = t` (lápida). Luego `CALL sp_crear_pedido(...)` con el producto 12: **aceptó el pedido** (stock 24 → 23, pedido 7). Script: `postgresql/verificar_hallazgos_3c.sql`; salida: `evidencias/16`. | **ACEPTADO.** La asimetría es real. La tablet es más estricta que el servidor (el semáforo daría RECHAZADO), y es el servidor el que deja pasar una categoría dada de baja; la propia vista heredada de `objects.sql` (línea 20) sí exige `c.eliminado = FALSE`. No se toca el procedimiento heredado: se documenta para el informe. |
| **H04** | `heredado/base_heredada/schema.sql` (base heredada) | Falta un índice por `producto_id` en `detalle_pedido`: el único índice útil es el compuesto `UNIQUE (pedido_id, producto_id)`. | `EXPLAIN SELECT * FROM detalle_pedido WHERE producto_id = 1` da *Seq Scan* (costo 20.50) con 13 filas. Con `SET enable_seqscan = off` el compuesto **sí se usa** (*Bitmap Index Scan*, costo 22.91), recorriéndolo entero (`evidencias/15`). | **DESCARTADO con fundamento.** (1) Con 13 filas el plan secuencial es el más barato: un índice nuevo no mejora nada medible. (2) La sección «Índices existentes (referencia; no se agregan índices en este TP)» de `.kiro/steering/conventions.md` lo prohíbe y `heredado/` se entrega sin modificar. Con volumen real convendría un índice que empiece por `producto_id`: queda como mejora futura. |
| **R1** | `heredado/base_heredada/objects.sql`, `sp_crear_pedido` (base heredada) | Un `producto_id` repetido en `p_items` rompe con un error de clave única, sin mensaje de negocio. | Se llamó al procedimiento con el producto 4 dos veces: `SQLSTATE=23505`, violación de `detalle_pedido_pedido_id_producto_id_key` (`evidencias/16`). | **ACEPTADO.** El error es genérico y no dice qué hizo mal quien llama; la transacción se revierte entera, así que no queda nada a medias. Se documenta; no se modifica el procedimiento heredado. |

## Resumen frente al enunciado

- **Hallazgos desarrollados:** 4, de la Unidad 8 y de la base heredada (Unidades 1 a 6): más de dos unidades distintas.
- **Descartados con fundamento:** 2 (H36, porque la comprobación lo desmiente; H04, por volumen y convención).
- **Aceptados:** 2 (H01, R1), ambos comprobados en la base.
- **Corregidos:** ninguno: no se modificó código heredado.

## Revisión de Mariano (05/11/2026)

Correcciones respecto del borrador de Facundo:

- **H36** figuraba como aceptado con «1 fila en `pedido_borrador` y `cola_sync`, 0 en `item_borrador`». No se reproduce (ver evidencia 17); pasó a descartado.
- **H01**: la vista se llama `v_snapshot_movil` (no `v_snapshot_catalogo`) y no «descarta» filas: las exporta con `eliminado = t`.
- **H04**: decía que el índice compuesto no podía usarse; con `enable_seqscan = off` se usa. Se reformuló y se corrigió la cita de `conventions.md`, que no era textual.
- **R1** no estaba en el borrador. Lo comprobó Mariano.
- Las decisiones se llevaron a las tres del enunciado (antes: «aceptado / documentado»).

**No consta por escrito** (lo sabe solo Facundo): modelo y proveedor de OpenCode, el prompt, la fecha de la corrida y cuántos hallazgos produjo en total la IA (los números H01, H04 y H36 sugieren una lista más larga). Tampoco hay logs de las comprobaciones de Facundo: las salidas que respaldan esta tabla son las de Mariano.
Además, H01 y R1 coinciden con candidatos que el equipo había anotado antes de la corrida de Facundo, y en esta revisión no se pudo confirmar cuál de los dos salió de OpenCode y cuál de otra fuente. Facundo debe declararlo en su bitácora.
