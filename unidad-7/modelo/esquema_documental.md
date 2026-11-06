# Esquema documental — colección `pedidos` (base `foodstore_nosql`)

## 1. Subconjunto elegido (consigna 1)

Pedidos y detalle de pedidos de Food Store. Tablas y claves en PostgreSQL:

| Tabla | Clave primaria | Claves foráneas | Qué se toma |
|---|---|---|---|
| `pedido` | `id` | `usuario_id → usuario.id` | fecha, estado, total, forma_pago |
| `detalle_pedido` | `id` | `pedido_id → pedido.id`, `producto_id → producto.id` · `UNIQUE (pedido_id, producto_id)` | cantidad, precio_unitario, subtotal |
| `usuario` | `id` | — | nombre, apellido, mail (copia embebida) |
| `producto` | `id` | `categoria_id → categoria.id` | nombre (copia embebida) |

## 2. Documento propuesto

```js
{
  _id: 1,                              // pedido.id de origen
  fecha: ISODate("2026-10-30T00:00:00Z"),  // pedido.fecha (DATE)
  estado: "CONFIRMADO",                // estado_pedido
  forma_pago: "EFECTIVO",
  total: NumberDecimal("9400.00"),     // pedido.total tal cual está en PostgreSQL
  cliente: { usuario_id: 1, nombre: "Ana", apellido: "García", mail: "ana.garcia@mail.com" },   // OBJETO EMBEBIDO
  lineas: [                            // ARREGLO de objetos embebidos
    { detalle_id: 1, producto_id: 1, nombre: "Muzzarella", cantidad: NumberInt(2),
      precio_unitario: NumberDecimal("3500.00"), subtotal: NumberDecimal("7000.00") }
  ],
  origen: "data.sql"                   // "prueba" para pedidos creados con sp_crear_pedido
}
```

**Identificadores conservados:** `_id` = `pedido.id`; `cliente.usuario_id`; `lineas[].detalle_id`; `lineas[].producto_id`.
**No se migra:** `contrasena`, `celular`, `rol`, ni registros con `eliminado = TRUE` (el pedido 4).

## 3. Tipos (y por qué)

| PostgreSQL | MongoDB | Motivo |
|---|---|---|
| `BIGINT` (ids) | número | Conservar el identificador de origen |
| `NUMERIC(12,2)` | `Decimal128` | Evita el error binario de `Double` en importes |
| `INTEGER` (cantidad) | `Int32` | Respetar el tipo entero (`NumberInt`) |
| `DATE` | `Date` (medianoche UTC) | Consultable por rango; la zona horaria es una decisión a anotar |
| ENUM | string | Conservar los valores existentes |

**Evidencia de tipos.** En Compass (`evidencias/capturas/compass_coleccion.png`) se ve `_id` como `Int32`, `fecha` como `Date` y `total` como `Decimal128`. El validador de la colección (visible en `evidencias/capturas/compass_validation.png`) exige `cantidad` entera y los importes decimales, y los 7 documentos lo cumplieron al insertarse. El tipo de `detalle_id`, `producto_id` y `usuario_id` dentro de los documentos no se verificó.

## 4. Dos reglas de integridad (consigna 3)

1. **Coherencia de importes:** `total` = suma de `subtotal`, y cada `subtotal` = `cantidad × precio_unitario`. En PostgreSQL la garantizan los triggers; en MongoDB se copian sin recalcular y se **verifican después de migrar** (agregación en `consultas_mongodb.js`). Resultado real en MongoDB: 0 documentos donde el total difiera de la suma y 0 líneas donde el subtotal difiera de `cantidad × precio_unitario` (dos agregaciones de `consultas_mongodb.js`). Se comprobó además sobre el JSON exportado (`evidencias/verificacion_export_json.txt`). El validador no cubre esta regla.
2. **Líneas válidas y vigentes:** `cantidad > 0`, estado dentro del conjunto permitido y sin registros con `eliminado = TRUE` (estos últimos no llegan a MongoDB: los excluye el export y el campo no se migra). Se refuerza con el validador `$jsonSchema` de la colección (estados y formas de pago permitidos, `cantidad` entera ≥ 1, importes `Decimal128`, al menos una línea) y con una consulta de comprobación. Resultado real: 0 líneas con cantidad ≤ 0.

## 5. Qué se embebió y por qué (consigna 3)

- **Líneas de detalle:** se leen siempre junto con el pedido (acceso frecuente a pedidos completos), no tienen sentido sin él y son pocas por pedido → un solo acceso, sin `JOIN`.
- **Cliente y nombre de producto (datos esenciales):** evitan consultar otras colecciones para mostrar un pedido.
- **Precio histórico:** se guarda `precio_unitario` de la línea, nunca el precio actual del producto.
- **Costo asumido:** lo embebido es una copia al momento de migrar; si el cliente cambia de mail, el documento no se actualiza.
- **Qué NO se embebió:** el catálogo completo de productos, categorías ni datos sensibles del usuario.

## 6. Pedidos migrados

Se migraron **7 pedidos** con `insertMany()` desde `modelo/pedidos_export.json`, generado por `modelo/exportar_pedidos.sql` (resultado real: `Insertados: 7`).

| `_id` | Cliente (`usuario_id`) | Estado | Total | Líneas | `origen` |
|---|---|---|---|---|---|
| 1 | 1 | CONFIRMADO | 9400.00 | 2 | `data.sql` |
| 2 | 2 | TERMINADO | 11900.00 | 3 | `data.sql` |
| 3 | 3 | PENDIENTE | 5300.00 | 2 | `data.sql` |
| 5 | 4 | PENDIENTE | 18700.00 | 3 | `data.sql` |
| 6 | 5 | CANCELADO | 3200.00 | 1 | `data.sql` |
| 7 | 2 | PENDIENTE | 4200.00 | 2 | `prueba` |
| 8 | 3 | PENDIENTE | 11700.00 | 2 | `prueba` |

Los pedidos 7 y 8 se crearon con `CALL sp_crear_pedido(...)` (`modelo/pedidos_de_prueba.sql`) para que un mismo producto (el 1, Muzzarella) aparezca en más de un pedido; por eso llevan `origen: "prueba"`. El pedido 4 no se migra porque está dado de baja (`eliminado = TRUE`).
