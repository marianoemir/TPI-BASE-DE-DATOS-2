# Food Store — Convenciones de Base de Datos (PostgreSQL y SQLite)

## Nombres de tablas

Los nombres de tabla son **en singular y en español**:

```
categoria, producto, usuario, pedido, detalle_pedido
```

No usar plural (`productos`), ni inglés (`product`), ni PascalCase. Las
tablas nuevas siguen la misma regla.

## Columna `eliminado` — Borrado lógico

**Nunca se ejecuta `DELETE`** sobre las tablas del proyecto. Todas tienen
`eliminado BOOLEAN NOT NULL DEFAULT FALSE` y la baja es siempre:

```sql
UPDATE <tabla> SET eliminado = TRUE WHERE id = :id AND eliminado = FALSE;
```

Toda consulta de datos vigentes filtra `WHERE eliminado = FALSE`, **en cada
tabla del JOIN**, no solo en la principal. Las vistas `v_categorias_vigentes`,
`v_productos_vigentes`, `v_pedidos_resumen`, `v_pedido_detalle` y
`v_usuario_seguro` ya aplican el filtro: usarlas cuando cubran el caso.

Baja de un pedido completo (detalles primero, luego el pedido):

```sql
BEGIN;
    UPDATE detalle_pedido SET eliminado = TRUE WHERE pedido_id = :id;
    UPDATE pedido SET eliminado = TRUE WHERE id = :id;
COMMIT;
```

Esto vale también para la seguridad: `fn_autenticar` y `fn_resetear_password`
filtran `eliminado = FALSE`, de modo que un usuario dado de baja no puede
autenticarse ni recibir un reseteo.

## Columnas con reglas propias

- `detalle_pedido.precio_unitario` **congela** el precio al momento de la
  venta; no se recalcula si cambia `producto.precio`.
- `producto.disponible`: `sp_crear_pedido` rechaza productos con
  `disponible = FALSE` aunque tengan stock.
- `pedido.estado`: el trigger `trg_validar_estado_pedido` impide pasar de
  `CONFIRMADO` a `PENDIENTE`. No se valida a mano.

## Restricciones de integridad destacadas

- `categoria.nombre` → `UNIQUE`
- `usuario.mail` → `UNIQUE` + `CHECK` de formato (`chk_usuario_mail_formato`)
- `pedido.fecha` → `CHECK (fecha <= CURRENT_DATE)`
- `detalle_pedido(pedido_id, producto_id)` → `UNIQUE`
- `producto.precio >= 0`, `producto.stock >= 0`, `detalle_pedido.cantidad > 0`
- `detalle_pedido.pedido_id` con `ON DELETE RESTRICT`

## Tipos de datos a respetar

| Campo | Tipo |
|---|---|
| IDs | `BIGINT GENERATED ALWAYS AS IDENTITY` |
| Precios y totales | `NUMERIC(10,2)` / `NUMERIC(12,2)` |
| Fechas con zona | `TIMESTAMPTZ` (`created_at`) |
| Fecha del pedido | `DATE` |
| Contraseña | `VARCHAR(255)` — **solo hash**, nunca texto plano |

## Índices existentes (referencia; no se agregan índices en este TP)

```
schema.sql          idx_producto_categoria_id, idx_pedido_usuario_id,
                    idx_producto_nombre_vigente
indices_semana3.sql idx_pedido_fecha_estado_vigente,
                    idx_pedido_usuario_total_estado
indices.sql         idx_producto_nombre_lower_vigente
```

## Convenciones de la base de la tablet (SQLite · Unidad 8)

- `PRAGMA foreign_keys = ON;` al abrir **cada** conexión y antes de cualquier transacción (viene apagado).
- Todas las tablas `STRICT` (SQLite 3.37+). Solo `INTEGER`, `REAL`, `TEXT`, `BLOB`, `ANY`: nada de `VARCHAR`, `BOOLEAN`, `DATE`.
- Dinero en **centavos enteros** (`precio_centavos`), nunca decimales. La conversión se hace en PostgreSQL (`(precio * 100)::INTEGER`).
- Booleano = `INTEGER` con `CHECK (col IN (0,1))`. Fecha = `TEXT` ISO 8601. Enumerado = `TEXT` con `CHECK (... IN (...))`.
- Lo que nace en la tablet se identifica con un **UUID** (36 caracteres). El número de pedido real lo asigna PostgreSQL.
- Las bajas llegan como **lápida** (`eliminado = 1`): la fila se conserva. Recargar el catálogo con `INSERT ... ON CONFLICT DO UPDATE`, nunca con `INSERT OR REPLACE`.
- Estados de `cola_sync`: `PENDIENTE`, `CONFLICTO`, `RECHAZADO`, `SIMULADO_APROBADO`. **`SIMULADO_APROBADO` no es una venta.**
- La tablet **nunca** modifica stock, precio ni pedidos de PostgreSQL. No viajan contraseñas, mails, celulares ni pagos.
