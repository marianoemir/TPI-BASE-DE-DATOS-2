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

## Patrones de modelado, migración y consulta (Unidad 7)

Los bloques de abajo son **plantillas sin probar**: se adaptan, se leen línea por línea y se **ejecutan** antes de
aceptarse. Los nombres de campos son una **propuesta de modelo** que el equipo puede cambiar y justificar.

### 1. Documento propuesto (un pedido completo)

```js
{
  _id: 1,                                   // pedido.id de origen
  fecha: ISODate("2026-10-10T00:00:00Z"),   // pedido.fecha (DATE)
  estado: "CONFIRMADO",                     // estado_pedido
  forma_pago: "EFECTIVO",
  total: NumberDecimal("0.00"),             // pedido.total (NUMERIC(12,2)); valor real de la base
  cliente: { usuario_id: 1, nombre: "...", apellido: "...", mail: "..." },
  lineas: [
    { detalle_id: 1, producto_id: 1, nombre: "...", cantidad: NumberInt(2),
      precio_unitario: NumberDecimal("0.00"),    // precio HISTORICO de detalle_pedido
      subtotal: NumberDecimal("0.00") }
  ],
  origen: "data.sql"                        // o "prueba" para los pedidos creados a mano
}
```

### 2. Generar los documentos desde PostgreSQL (evita errores de tipeo)

```sql
SELECT jsonb_pretty(jsonb_agg(doc ORDER BY id)) FROM (
  SELECT p.id,
    jsonb_build_object(
      '_id', p.id,
      'fecha', to_char(p.fecha, 'YYYY-MM-DD'),
      'estado', p.estado,
      'forma_pago', p.forma_pago,
      'total', p.total::text,                       -- como texto: se convierte a Decimal128 en mongosh
      'cliente', jsonb_build_object('usuario_id', u.id, 'nombre', u.nombre,
                                    'apellido', u.apellido, 'mail', u.mail),
      'lineas', (SELECT jsonb_agg(jsonb_build_object(
                    'detalle_id', d.id, 'producto_id', d.producto_id, 'nombre', pr.nombre,
                    'cantidad', d.cantidad, 'precio_unitario', d.precio_unitario::text,
                    'subtotal', d.subtotal::text) ORDER BY d.id)
                 FROM detalle_pedido d JOIN producto pr ON pr.id = d.producto_id
                 WHERE d.pedido_id = p.id AND d.eliminado = FALSE),
      'origen', 'data.sql'
    ) AS doc
  FROM pedido p JOIN usuario u ON u.id = p.usuario_id
  WHERE p.eliminado = FALSE AND p.id IN (1, 2, 3, 5, 6)
) t;
```

El resultado (JSON) se pega en el paso siguiente. Nunca se incluye `contrasena`.

### 3. Migrar con `insertMany()` convirtiendo los tipos

```js
db = db.getSiblingDB('foodstore_nosql');          // 'use' no funciona dentro de un .js
const crudos = [ /* JSON generado en PostgreSQL */ ];
const docs = crudos.map(d => ({
  ...d,
  fecha: new Date(d.fecha),                       // 'YYYY-MM-DD' se interpreta como UTC
  total: NumberDecimal(d.total),
  lineas: d.lineas.map(l => ({
    ...l,
    cantidad: NumberInt(l.cantidad),
    precio_unitario: NumberDecimal(l.precio_unitario),
    subtotal: NumberDecimal(l.subtotal)
  }))
}));
db.pedidos.drop();                                // solo la coleccion del TP, para poder repetir
db.pedidos.insertMany(docs);
db.pedidos.countDocuments();                      // debe coincidir con la cantidad de ids migrados
```

### 4. Consultas a) a d) en MongoDB

```js
db.pedidos.find({}, { estado: 1 });                              // a) _id y estado
db.pedidos.find({ estado: "PENDIENTE" });                        // b) por estado existente
db.pedidos.find({ "lineas.producto_id": 1 });                    // c) producto dentro del arreglo
db.pedidos.find({ lineas: { $elemMatch: { producto_id: 1, cantidad: { $gte: 2 } } } });  // c) variante
db.pedidos.find({ total: { $gt: NumberDecimal("10000.00") } });  // d) umbral: justificarlo con los datos reales
```

### 5. Consultas equivalentes en PostgreSQL (b y c, con `JOIN`)

```sql
-- b) por estado, sobre los mismos ids migrados
SELECT id FROM pedido
WHERE estado = 'PENDIENTE' AND eliminado = FALSE AND id IN (1, 2, 3, 5, 6)
ORDER BY id;

-- c) por producto, con JOIN
SELECT DISTINCT p.id
FROM pedido p JOIN detalle_pedido d ON d.pedido_id = p.id
WHERE d.producto_id = 1 AND p.eliminado = FALSE AND d.eliminado = FALSE
  AND p.id IN (1, 2, 3, 5, 6)
ORDER BY p.id;
```

### 6. Comparar cantidad e IDs

```js
db.pedidos.find({ estado: "PENDIENTE" }, { _id: 1 }).sort({ _id: 1 });   // ids en MongoDB
```

```sql
SELECT count(*) AS cantidad, array_agg(id ORDER BY id) AS ids FROM (
  SELECT id FROM pedido WHERE estado = 'PENDIENTE' AND eliminado = FALSE AND id IN (1, 2, 3, 5, 6)
) t;                                                                       -- ids en PostgreSQL
```

### 7. Verificar la integridad después de migrar

```js
// Regla 1: total = suma de subtotales. Debe devolver 0 documentos.
db.pedidos.aggregate([
  { $addFields: { suma: { $sum: "$lineas.subtotal" } } },
  { $match: { $expr: { $ne: ["$suma", "$total"] } } },
  { $project: { total: 1, suma: 1 } }
]);

// Regla 2: lineas con cantidad no positiva. Debe devolver 0 documentos.
db.pedidos.find({ "lineas.cantidad": { $lte: 0 } });
```

## Patrones de consulta heredados

- Preferir las vistas vigentes antes que reescribir `eliminado = FALSE`.
- Filtrar `eliminado = FALSE` en todas las tablas participantes.
- `SUM` con `COALESCE(..., 0)` para evitar `NULL`.
- Productos sin ventas: `LEFT JOIN … WHERE fk IS NULL`, no `NOT IN`.
