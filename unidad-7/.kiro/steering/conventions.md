# Food Store — Convenciones de Base de Datos y de Modelado Documental

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

## Convenciones de modelado documental y comparación (Unidad 7)

### Alcance

- **Migración parcial:** solo *pedidos y detalle de pedidos*, con el cliente y las líneas embebidos. Mínimo cinco
  pedidos. Una única colección, `pedidos`. No se migra toda la base ni se crean colecciones de usuarios o productos.
- La base PostgreSQL es la fuente: `foodstore`. La base documental es `foodstore_nosql` (nombre propuesto).

### Qué se conserva

- **Identificadores de origen:** `pedido.id` es el `_id` del documento; también se conservan `usuario_id`,
  `producto_id` y `detalle_id` de cada línea.
- **Importes, cantidades y estados tal cual están en PostgreSQL**, sin recalcular. El precio de cada línea es el
  **precio histórico** (`detalle_pedido.precio_unitario`), no el actual del producto.
- Solo registros vigentes: `eliminado = FALSE` en `pedido` y en `detalle_pedido`.

### Qué se embebe y qué no

- Se embebe lo que se consulta **siempre junto** con el pedido: sus líneas y los datos esenciales del cliente
  (`usuario_id`, `nombre`, `apellido`, `mail`) y del producto (`producto_id`, `nombre`).
- **Nunca** `contrasena`; tampoco `celular` ni `rol`, que no hacen falta.
- Lo embebido es una **copia al momento de la migración**: si el cliente cambia de mail, el documento no se entera.
  Es un costo del modelo que conviene mencionar al justificar.

### Tipos

| PostgreSQL | MongoDB | Motivo |
|---|---|---|
| `BIGINT` (ids) | número (`_id` = `pedido.id`) | Conservar el identificador de origen |
| `NUMERIC(12,2)` (importes) | `Decimal128` (`NumberDecimal("…")`) | No perder exactitud decimal |
| `INTEGER` (cantidad) | `NumberInt` | Respetar el tipo entero |
| `DATE` (fecha) | `Date` (medianoche UTC) | Fecha consultable por rango |
| ENUM (estado, forma de pago) | string | Conservar los valores existentes |

### Reglas de integridad candidatas (hay que justificar **dos**)

1. **Coherencia de importes:** `total` = suma de los `subtotal`, y cada `subtotal` = `cantidad × precio_unitario`.
2. **Líneas válidas y vigentes:** `cantidad > 0`, un mismo producto no se repite dentro de un pedido
   (`UNIQUE (pedido_id, producto_id)` en PostgreSQL), `estado` ∈ {PENDIENTE, CONFIRMADO, TERMINADO, CANCELADO} y no se
   migran registros con `eliminado = TRUE`.

En PostgreSQL esas reglas las garantizan constraints y triggers; en MongoDB no hay un equivalente automático, así que
se **verifican después de migrar** (consulta de comprobación) y, si se quiere, con un validador de esquema
(`$jsonSchema`).

### Comparación entre motores

- Las consultas de PostgreSQL se limitan a los **mismos ids migrados** (`id IN (...)`) y a registros vigentes. Si no,
  la carga masiva hace que las cantidades no coincidan por construcción.
- Se comparan **cantidad e IDs** (listas ordenadas). Una diferencia se explica y se corrige en el modelo o en la
  consulta; los datos no se tocan para forzar la coincidencia.
- **Pedidos de prueba:** solo con `CALL sp_crear_pedido(...)`, una sola vez sobre una base recién armada, con su
  procedencia declarada (`origen`).

### Uso de IA en esta unidad

- Se puede explorar el diseño y generar consultas, pero **todo se ejecuta y se contrasta** con el laboratorio o con la
  documentación oficial de MongoDB.
- La consulta de la consigna 6 debe mencionar: el modelo actual, el acceso frecuente a pedidos completos y la necesidad
  de conservar la coherencia de cantidades y precios.
- La respuesta completa se guarda en `evidencias/respuesta_ia.md`. El informe (PDF de hasta 5 páginas) lleva solo
  **dos afirmaciones contrastadas** y una conclusión de **hasta 200 palabras** con al menos dos criterios técnicos.
  Sin transcripciones extensas de chat.

## Índices existentes (referencia; no se agregan índices en este TP)

```
schema.sql          idx_producto_categoria_id, idx_pedido_usuario_id,
                    idx_producto_nombre_vigente
indices_semana3.sql idx_pedido_fecha_estado_vigente,
                    idx_pedido_usuario_total_estado
indices.sql         idx_producto_nombre_lower_vigente
```
