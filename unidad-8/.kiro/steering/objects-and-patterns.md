# Food Store — Objetos del Esquema y Patrones

## Triggers — NO MODIFICAR

Funcionan de forma automática; no se tocan, reescriben ni reemplazan.

| Trigger | Tabla | Evento | Función | Qué hace |
|---|---|---|---|---|
| `trg_subtotal` | `detalle_pedido` | `BEFORE INSERT OR UPDATE` (fila) | `fn_set_subtotal()` | Copia `precio` de `producto` a `precio_unitario` si llega `NULL`; calcula `subtotal` |
| `trg_total_ins` | `detalle_pedido` | `AFTER INSERT` (sentencia) | `fn_recalcular_total()` | Recalcula `pedido.total` |
| `trg_total_upd` | `detalle_pedido` | `AFTER UPDATE` (sentencia) | `fn_recalcular_total()` | Ídem para `UPDATE` |
| `trg_validar_estado_pedido` | `pedido` | `BEFORE UPDATE OF estado` (fila) | `fn_validar_estado_pedido()` | Bloquea `CONFIRMADO → PENDIENTE` |

**Consecuencia para los permisos:** las funciones de trigger no son
`SECURITY DEFINER`, así que corren con los privilegios de quien dispara la
operación. Para insertar en `detalle_pedido`, el rol necesita además
`SELECT` sobre `producto` (lo lee `fn_set_subtotal`) y `UPDATE` sobre `pedido`
(lo escribe `fn_recalcular_total`).

## Procedimiento `sp_crear_pedido` — único camino para altas de pedidos

```sql
CALL sp_crear_pedido(
    p_usuario_id BIGINT,
    p_forma_pago forma_pago,
    p_items      JSONB   -- [{"producto_id": N, "cantidad": N}, ...]
);
```

Nunca `INSERT INTO pedido` + `INSERT INTO detalle_pedido` a mano. Garantiza:
usuario vigente, producto vigente y disponible, stock suficiente, descuento de
stock en la misma transacción, `FOR UPDATE` sobre el producto y rollback si
falla un ítem. Errores: usuario inexistente o eliminado; producto inexistente,
eliminado o no disponible; stock insuficiente.

**Consecuencia para los permisos:** es `SECURITY INVOKER` y, además de
insertar en `pedido` y `detalle_pedido`, **lee `usuario`**, hace `SELECT …
FOR UPDATE` sobre `producto` (requiere privilegio `UPDATE` sobre al menos una
columna) y **actualiza `producto.stock`**. Quien la ejecute necesita esos
privilegios, o la función debe cambiar de modelo. Es una decisión de diseño de
la Parte A (ver `AGENTS.md`); no se resuelve "a ojo".

## Vistas — usar en vez de reescribir el filtro a mano

| Vista | Para qué sirve | Archivo |
|---|---|---|
| `v_categorias_vigentes` | Categorías con `eliminado = FALSE` | `objects.sql` |
| `v_productos_vigentes` | Productos + categoría, ambos vigentes | `objects.sql` |
| `v_pedidos_resumen` | Pedidos vigentes + nombre completo del usuario | `objects.sql` |
| `v_pedido_detalle` | Líneas de detalle vigentes + nombre del producto | `objects.sql` |
| `v_usuario_seguro` | Usuarios **sin** `contrasena`; para listar/exponer usuarios, nunca `SELECT * FROM usuario` fuera de la autenticación | `views.sql` |

## Vista materializada `mv_facturacion_categoria_mes` (`materializadas.sql`)

Facturación por categoría y mes (pedidos `CONFIRMADO` vigentes). No se
actualiza sola: `REFRESH MATERIALIZED VIEW CONCURRENTLY
mv_facturacion_categoria_mes;`. El índice único `idx_mv_facturacion_cat_mes_pk`
`(categoria_id, mes)` es lo que permite el `CONCURRENTLY`: no borrarlo.

## Patrones de consulta heredados

- Preferir las vistas vigentes antes que reescribir `eliminado = FALSE`.
- Filtrar `eliminado = FALSE` en todas las tablas participantes.
- `SUM` con `COALESCE(..., 0)` para evitar `NULL`.
- Productos sin ventas: `LEFT JOIN … WHERE fk IS NULL`, no `NOT IN`.
