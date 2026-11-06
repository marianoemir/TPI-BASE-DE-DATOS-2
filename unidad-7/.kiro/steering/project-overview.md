# Food Store — Visión General del Proyecto

## Descripción

Sistema de venta de comida implementado íntegramente en **PostgreSQL**. Cubre el ciclo completo: categorías →
productos → usuarios → pedidos con sus detalles. Las Unidades 1 a 4 construyeron y optimizaron el modelo, la
Unidad 5 le agregó administración y seguridad y la Unidad 6, respaldo y recuperación. La **Unidad 7** explora
**NoSQL**: se representa en **MongoDB** el subconjunto de *pedidos y detalle de pedidos*, se lo consulta y se
contrastan los resultados con PostgreSQL para decidir qué tecnología conviene.

## Metodología: dos motores, una migración parcial

- **PostgreSQL (`foodstore`)** — fuente de los datos y de las consultas de comparación. Se arma desde
  `plantilla_food_store` (`schema.sql` → `objects.sql` → `data.sql`) y `views.sql`.
- **MongoDB (`foodstore_nosql`, colección `pedidos`)** — un documento por pedido, con el cliente y las líneas
  **embebidos**. Es una **migración parcial**: al menos cinco pedidos. No se migra toda la base ni se crean otras
  colecciones, y no se usa Redis, Neo4j ni clúster.

## Trabajo Práctico en curso: Unidad 7 (NoSQL y nuevas formas de almacenamiento)

| Parte | Tema | Evidencia |
|---|---|---|
| 1 | Modelo documental y migración (consignas 1 a 3) | Esquema de la colección, `insertMany()` de ≥5 pedidos, dos reglas de integridad |
| 2 | Consultas y verificación cruzada (consignas 4 y 5) | Consultas a) a d) en MongoDB, equivalentes b) y c) en PostgreSQL y tabla de verificación |
| 3 | Tecnología e IA (consignas 6 y 7) | Consulta a una IA, contraste de dos afirmaciones y conclusión de hasta 200 palabras |

Entrega: un único PDF de hasta 5 páginas, más `consultas_mongodb.js` y `consultas_postgresql.sql`. Las herramientas
de IA se pueden usar para explorar el diseño y generar consultas, siempre contrastadas con ejecución real y con la
documentación oficial. Todo se ejecuta únicamente contra el servidor propio.

## Archivos del proyecto

### Base heredada (`base_heredada/`, sin modificar)

| Archivo | Contenido |
|---|---|
| `schema.sql` | Tipos ENUM, tablas, constraints y los 3 índices originales |
| `objects.sql` | 4 vistas base, `calcular_total_pedido`, triggers, `sp_crear_pedido` |
| `data.sql` | Datos de prueba chicos (ficticios): incluye **6 pedidos** |
| `carga_masiva.sql` | ≥50.000 productos, ≥20.000 usuarios, ≥200.000 pedidos (opcional en esta unidad) |
| `indices_semana3.sql`, `indices.sql` | Índices adicionales |
| `views.sql`, `materializadas.sql` | `v_usuario_seguro` y `mv_facturacion_categoria_mes` |
| `queries.sql`, `transacciones.sql` | Banco de consultas y escenarios (no se ejecutan de una vez) |

### Entregables de la U7

`consultas_mongodb.js`, `consultas_postgresql.sql` e `informe_u7.pdf`, más `modelo/` y `evidencias/`. Árbol completo
en `AGENTS.md`.

## Orden de ejecución

```
plantilla_food_store:  schema.sql → objects.sql → data.sql
foodstore:             views.sql   (carga_masiva.sql y el resto, solo si hace falta)
Parte 1:               modelo documental → migración a MongoDB (insertMany)
Parte 2:               consultas a) a d) en MongoDB → equivalentes b) y c) en PostgreSQL → tabla de verificación
Parte 3:               consulta a la IA → contraste de dos afirmaciones → conclusión
```

## Tablas del modelo

```
categoria
producto       → FK categoria_id → categoria
usuario
pedido         → FK usuario_id   → usuario
detalle_pedido → FK pedido_id    → pedido
               → FK producto_id  → producto
```

## Tipos ENUM definidos

```sql
CREATE TYPE rol           AS ENUM ('ADMIN','USUARIO');
CREATE TYPE estado_pedido AS ENUM ('PENDIENTE','CONFIRMADO','TERMINADO','CANCELADO');
CREATE TYPE forma_pago    AS ENUM ('TARJETA','TRANSFERENCIA','EFECTIVO');
```

`rol` es un dato de la aplicación (columna `usuario.rol`). **No** es un rol de
PostgreSQL.

## Vistas disponibles

| Vista | Descripción | Archivo |
|---|---|---|
| `v_categorias_vigentes` | Categorías con `eliminado = FALSE` | `objects.sql` |
| `v_productos_vigentes` | Productos y categorías activos | `objects.sql` |
| `v_pedidos_resumen` | Pedidos vigentes con nombre completo del usuario | `objects.sql` |
| `v_pedido_detalle` | Líneas de detalle vigentes con nombre del producto | `objects.sql` |
| `v_usuario_seguro` | Usuarios sin la columna `contrasena` | `views.sql` |

## Vista materializada

| Vista materializada | Descripción | Archivo |
|---|---|---|
| `mv_facturacion_categoria_mes` | Facturación agregada por categoría y mes (solo pedidos `CONFIRMADO` vigentes). No se actualiza sola: requiere `REFRESH MATERIALIZED VIEW CONCURRENTLY`. Índice único `(categoria_id, mes)`. | `materializadas.sql` |
