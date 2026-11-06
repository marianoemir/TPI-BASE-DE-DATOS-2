# 3.a · Mapa de la capa de datos

Food Store usa tres motores. **PostgreSQL es la única fuente de verdad**: ninguno de los otros dos decide precio, stock ni ventas.

| Motor | Dónde vive | Qué guarda | Quién manda |
|---|---|---|---|
| **PostgreSQL** | Servidor (`foodstore`; `foodstore_u8` en las pruebas) | Catálogo (`producto`, `categoria`), usuarios, `pedido` y `detalle_pedido`, stock. Publica la vista `v_snapshot_movil` | **Fuente de verdad.** Decide precio, stock y ventas; solo `sp_crear_pedido` confirma una venta, y vuelve a validar el stock con `SELECT … FOR UPDATE` |
| **MongoDB** (Unidad 7) | Base `foodstore_nosql` | Colección `pedidos`: cada pedido como un documento, con el cliente y las líneas embebidos (7 pedidos migrados: 1, 2, 3, 5 y 6 de `data.sql`, más el 7 y el 8 creados con `sp_crear_pedido` solo para la Unidad 7; el 4 está dado de baja y no se migró) | **Solo sobre esos documentos.** Es una copia migrada desde PostgreSQL para lectura de pedidos completos; no decide stock, precio ni ventas |
| **SQLite** (Unidad 8) | Archivo `movil/foodstore_movil.db`, en la tablet | Copia del catálogo con fecha (`producto_cache`), borradores (`pedido_borrador`, `item_borrador`) y la cola de envío con su resultado (`cola_sync`) | **Nadie:** solo consulta y prepara. El semáforo simula la validación; `SIMULADO_APROBADO` no es una venta |

**Quién manda sobre cada dato**

| Dato | Manda | Dónde se copia |
|---|---|---|
| Precio, stock, disponibilidad y bajas del catálogo | PostgreSQL | SQLite (copia con fecha) |
| Ventas y numeración de pedidos | PostgreSQL | MongoDB (copia migrada de pedidos ya existentes) |
| Borradores y estado de su envío (`PENDIENTE`, `CONFLICTO`, `RECHAZADO`, `SIMULADO_APROBADO`) | La tablet los prepara; **PostgreSQL decidiría** la venta real | Solo en SQLite |
| Datos de usuarios | PostgreSQL | No viajan a la tablet |

**Flujo.** PostgreSQL publica la instantánea (`v_snapshot_movil` → CSV con fecha) → la tablet la guarda y arma borradores sin señal → al volver la
señal, cada solicitud se compara con una instantánea nueva (en este TP el envío es una simulación y no escribe en PostgreSQL) → solo PostgreSQL
confirmaría la venta. MongoDB no participa de la sincronización: atiende su parte sin tocar el stock ni las ventas.

---
*Versión corregida por Mariano Chirino tras revisar el borrador de Andrés Fabre (PR #1): el borrador ubicaba la cola en PostgreSQL, describía MongoDB como metadatos de productos y daba autoridad local a SQLite.*
