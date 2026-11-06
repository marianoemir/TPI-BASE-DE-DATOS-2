# Contraste de afirmaciones de la IA y conclusión técnica

Las afirmaciones provienen de `evidencias/respuesta_ia.md`.

## 1. Contraste de afirmaciones

### Afirmación 1: integridad y validación en MongoDB

> **La IA afirma:** «MongoDB no soporta reglas de integridad referencial ni validación de esquemas avanzadas, por lo que la coherencia de importes y cantidades depende exclusivamente de la lógica de la aplicación.»

**¿Se sostiene?** **Solo en parte.**

- **Lo que es cierto:** MongoDB no tiene claves foráneas. Nada impide que `cliente.usuario_id` o `lineas[].producto_id` apunten a un registro que ya no existe en PostgreSQL; esa coherencia la controla la migración o la aplicación.
- **Lo que es falso:** MongoDB sí valida esquemas. La documentación oficial describe la validación de esquema en inserciones y actualizaciones, con JSON Schema (`$jsonSchema`) como forma recomendada: https://www.mongodb.com/docs/manual/core/schema-validation/
- **Resultado del laboratorio:** `consultas_mongodb.js` crea la colección `pedidos` con un validador `$jsonSchema` que exige `estado` y `forma_pago` dentro de los valores permitidos, `total`, `precio_unitario` y `subtotal` como `Decimal128`, `cantidad` como entero ≥ 1 y al menos una línea por pedido. Los 7 documentos migrados lo cumplieron sin error (`Insertados: 7`), y el validador se ve en la pestaña *Validation* de Compass (`evidencias/capturas/compass_validation.png`, con acción *Error* y nivel *Strict*).
- **Límite que sí apareció:** el validador no cubre la regla «total = suma de subtotales». En PostgreSQL la garantizan los triggers; en MongoDB la verificamos después de migrar con una agregación, que devolvió 0 documentos (`evidencias/mongo_migracion_y_consultas.txt`). La afirmación «depende exclusivamente de la aplicación» es entonces falsa para tipos, valores y cantidades, pero cierta para la integridad referencial.

---

### Afirmación 2: lectura de pedidos completos mediante embebido

> **La IA afirma:** «Al embeber la información del cliente y los ítems dentro de la colección `pedidos` en MongoDB, se elimina por completo la sobrecarga computacional de los JOINs relacionales, permitiendo recuperar el pedido completo en una sola operación de lectura.»

**¿Se sostiene?** **En parte.**

- **Documentación oficial:** el modelo embebido permite recuperar datos relacionados en una sola operación y mejora, en general, el rendimiento de lectura. También aclara que ese modelo es desnormalizado: duplica datos. https://www.mongodb.com/docs/manual/data-modeling/embedding/
- **Resultado del laboratorio (verificado):** la consulta c) (`db.pedidos.find({ "lineas.producto_id": 1 })`) devuelve cada pedido completo, con cabecera, cliente y líneas, sin `$lookup` ni combinaciones (`evidencias/mongo_migracion_y_consultas.txt`).
- **Lo que no se verificó:** el rendimiento. Con 7 documentos no se midió ningún tiempo, así que «elimina por completo la sobrecarga» no tiene respaldo en el laboratorio ni en la documentación.
- **Costo que la IA omite:** lo embebido es una copia del momento de la migración. Si cambia el mail de un cliente, los documentos ya migrados no se enteran.

---

## 2. Conclusión técnica

Conviene **combinar ambas tecnologías**, manteniendo PostgreSQL como sistema de registro.

**Integridad.** PostgreSQL garantiza la coherencia de importes, cantidades y stock con restricciones, claves foráneas y triggers dentro de `sp_crear_pedido`. En MongoDB el validador controla tipos, estados y cantidades, pero no hay claves foráneas y la regla «total = suma de subtotales» hubo que verificarla aparte. Por eso las altas y modificaciones de pedidos deben seguir en PostgreSQL.

**Lectura.** El pedido completo cabe en un solo documento y se recupera con una consulta, sin `$lookup`, lo que encaja con el acceso frecuente a pedidos completos. La documentación indica mejor rendimiento de lectura, pero el laboratorio, con 7 documentos, no lo midió. El costo es duplicar datos del cliente y del producto.

El precio histórico no diferencia a los motores: ambos lo conservan copiando `precio_unitario` en cada línea.

Una copia de lectura de pedidos finalizados en MongoDB es razonable si el patrón de acceso lo justifica; con esta evidencia no alcanza para migrar la operación completa.
