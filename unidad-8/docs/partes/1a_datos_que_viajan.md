# 1.a · Qué datos viajan a la tablet

La tablet recibe una **instantánea del catálogo** con la vista `v_snapshot_movil` (PostgreSQL → CSV → `snapshot_servidor` → `producto_cache`).
La tabla compara cada columna de `producto` (y los datos de las otras tablas) con lo que realmente viaja.

| Dato en PostgreSQL | ¿Viaja? | En la tablet | Por qué |
|---|---|---|---|
| `producto.id` | **Sí** | `producto_id` | Es la clave que une el borrador con el producto del servidor |
| `producto.nombre` | **Sí** | `nombre` | El vendedor lo ve en pantalla |
| `producto.precio` | **Sí, convertido** | `precio_centavos` | Entero en centavos: las cuentas son exactas. La conversión se hace una sola vez en PostgreSQL |
| `producto.stock` | **Sí, solo orientativo** | `stock_visto` | Para mostrarlo; la decisión de stock es siempre del servidor |
| `producto.disponible` | **Sí** | `disponible_visto` | Para ofrecer solo lo que se puede vender |
| `producto.eliminado` (o su categoría) | **Sí, como lápida** | `eliminado` | La baja lógica viaja como dato: la tablet saca el producto de pantalla pero conserva la fila, porque un borrador puede usarla |
| *(fecha de la instantánea)* | **Sí** | `capturado_en` | Se sabe siempre qué tan vieja es la lista |
| `producto.descripcion`, `producto.imagen` | No | — | No hacen falta para vender y ocupan espacio |
| `producto.categoria_id`, `categoria.*` | No | — | La categoría solo se usa en el servidor para calcular la lápida |
| `producto.created_at` | No | — | Dato interno |
| `usuario.*` (nombre, apellido, mail, celular, contraseña, rol) | **No** | — | No hacen falta para vender y son un riesgo si la tablet se pierde. Al borrador solo viaja el `usuario_id_servidor` |
| `pedido` y `detalle_pedido` confirmados | No | — | Solo el servidor confirma y numera las ventas |

**Por qué y quién manda.** A la tablet viaja solo lo necesario para mostrar el catálogo y armar borradores sin señal; todo lo demás
(datos personales, ventas confirmadas, información interna) se queda en el servidor, porque guardar poco es la principal medida de seguridad cuando
SQLite no tiene usuarios ni permisos. La fuente de verdad es **PostgreSQL**, que decide precio, stock y ventas: la tablet solo propone, y
`SIMULADO_APROBADO` no es una venta.

*Comprobación:* `postgresql/verificar_vista_snapshot.sql` lista las 7 columnas de la vista y no aparece ningún dato de usuarios.

---
*Versión corregida por Mariano Chirino tras revisar el borrador de Andrés Fabre (PR #1): el borrador original incluía columnas que no existen en `producto` y no coincidía con `v_snapshot_movil`.*
