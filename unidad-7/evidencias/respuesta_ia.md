# Respuesta de la IA — Evaluación de arquitectura de datos para Food Store

**Herramienta de IA:** Claude (Anthropic).

## Prompt enviado

> Hola. Estamos analizando la arquitectura de datos para 'Food Store', una aplicación de pedidos de comida. Actualmente usamos PostgreSQL con un modelo relacional donde las tablas principales son pedido y detalle_pedido, vinculadas con usuario y producto. Los patrones de acceso del sistema leen con alta frecuencia el pedido completo (su cabecera con los datos del cliente y todas sus líneas de detalle). Además, es fundamental garantizar la coherencia en las cantidades y conservar los precios históricos de los productos en cada línea de pedido al momento de la venta.
>
> Necesitamos evaluar si conviene migrar el almacenamiento de pedidos a MongoDB (modelo documental NoSQL) embiendo las líneas de detalle y los datos básicos del cliente dentro del propio documento de pedido, o si es preferible mantener PostgreSQL. Compara ambas tecnologías considerando rendimiento de lectura, integridad transaccional, consistencia de precios e impacto en consultas de analítica/reportes.

---

## 1. Comparativa de Modelos de Datos

### PostgreSQL (Relacional)
- **Estructura:** Separa la cabecera del pedido (`pedido`) de sus ítems (`detalle_pedido`), referenciando entidades externas (`usuario`, `producto`).
- **Integridad y Consistencia:** Garantiza consistencia ACID estricta a través de claves foráneas (`FOREIGN KEY`), restricciones (`CHECK`, `UNIQUE`) y transacciones multitabla nativas.
- **Precios Históricos:** La conservación de precios históricos requiere duplicar la columna de precio en `detalle_pedido` al momento de insertar el registro, previniendo que futuras modificaciones en la tabla `producto` alteren los totales históricos.

### MongoDB (Documental NoSQL)
- **Estructura:** Embebe las líneas de detalle (`lineas`) y la información relevante del cliente (`cliente`) directamente dentro del documento de `pedidos`.
- **Patrón de Lectura:** Altamente optimizado para el patrón de acceso principal (pedido completo), realizando la consulta en una sola operación de lectura de disco (I/O) sin necesidad de JOINs.
- **Consistencia de Precios:** Al embeber el estado del producto (nombre, precio unitario y subtotal) en el arreglo `lineas`, se garantiza de forma natural e inmutable el precio histórico de la venta.

---

## 2. Afirmaciones Técnicas Generadas

1. **Rendimiento de Lectura:** *Al embeber la información del cliente y los ítems dentro de la colección `pedidos` en MongoDB, se elimina por completo la sobrecarga computacional de los JOINs relacionales, permitiendo recuperar el pedido completo en una sola operación de lectura.*
2. **Garantía de Integridad:** *MongoDB no soporta reglas de integridad referencial ni validación de esquemas avanzadas, por lo que la coherencia de importes y cantidades depende exclusivamente de la lógica de la aplicación.*
3. **Consistencia Histórica:** *El modelo embebido NoSQL protege de forma inherente los precios históricos frente a cambios en el catálogo de productos.*
4. **Consultas de Analítica:** *Las consultas agregadas o reportes cruzados (ej. ventas totales por categoría de producto) son significativamente más complejas y costosas de ejecutar en MongoDB que en PostgreSQL.*

---

## 3. Recomendación Arquitectónica

Para el sistema **Food Store**, se recomienda adoptar un enfoque **híbrido (políglota)** o **mantener PostgreSQL como motor principal**:
- **PostgreSQL** debe seguir gestionando la consistencia transaccional del checkout, inventarios y reportes financieros globales donde la integridad referencial es crítica.
- **MongoDB** es ideal como base de datos operacional o caché persistente para el historial y consulta de pedidos finalizados, optimizando la latencia de lectura para los clientes y repartidores.