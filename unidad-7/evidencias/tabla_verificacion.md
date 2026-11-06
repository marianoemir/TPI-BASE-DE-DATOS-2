### Tabla de verificación de consultas (PostgreSQL vs. MongoDB)

| Consulta | Cantidad en PostgreSQL | Cantidad en MongoDB | ¿Coinciden los IDs? | IDs recuperados |
| :--- | :---: | :---: | :---: | :---: |
| Estado seleccionado (`PENDIENTE`) | 4 | 4 | **Sí** | 3, 5, 7, 8 |
| Producto seleccionado (`producto_id = 1`) | 3 | 3 | **Sí** | 1, 7, 8 |

**Fuentes (ejecuciones reales):** `evidencias/postgres_b.txt` y `evidencias/postgres_c.txt` (PostgreSQL 16, base `foodstore7`) y `evidencias/mongo_migracion_y_consultas.txt` (MongoDB, 7 documentos migrados).

**Explicación:** las consultas de PostgreSQL aplican `eliminado = FALSE` en `pedido` y, en c), también en `detalle_pedido`, y se limitan a los ids migrados (1, 2, 3, 5, 6, 7, 8), por lo que el pedido 4 (dado de baja) no se cuenta.

**Diferencia detectada y corregida:** en una primera comparación no coincidían. PostgreSQL (con los pedidos de prueba 7 y 8) devolvía 4 y 3 pedidos, y MongoDB, migrado solo con los 5 pedidos de `data.sql`, devolvía 2 (ids 3, 5) y 1 (id 1). La causa era que los pedidos 7 y 8 no estaban migrados. Se agregaron al export y se volvió a migrar; desde entonces los resultados coinciden. No se modificaron datos ni consultas.
