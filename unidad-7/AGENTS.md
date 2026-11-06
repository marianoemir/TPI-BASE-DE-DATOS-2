# Food Store — Instrucciones para Agentes

TP Unidad 7 — NoSQL y nuevas formas de almacenamiento (Base de Datos II, UTN).
Se toma una parte ya implementada de Food Store (**pedidos y detalle de pedidos**), se la representa en
MongoDB, se ejecutan consultas y se las compara con las equivalentes de PostgreSQL. Después se contrastan
con ejecución real las sugerencias de una herramienta de IA y se fundamenta una decisión tecnológica.

**Cómo se usa este archivo:** se pueden usar herramientas de IA (OpenCode u otras) para explorar el diseño o
generar consultas, **pero toda propuesta se contrasta con ejecución real y con documentación técnica**. No se
evalúa la cantidad de texto generado, sino la corrección del modelo, la verificación cruzada de resultados y el
criterio crítico sobre lo que sugiere la IA.

## Stack Tecnológico

| Componente | Tecnología / Versión | Propósito |
|---|---|---|
| Base relacional | PostgreSQL 16+ (Mariano 17.10, Andrés 16) | Fuente de los datos y consultas de comparación |
| Base documental | MongoDB 9.0.4 local (consola `mongosh` 2.14; Compass para las capturas) | Colección de pedidos |
| Clientes | pgAdmin 4, `psql`, `mongosh` | Ejecutar y capturar evidencias |
| Entregables | `consultas_mongodb.js`, `consultas_postgresql.sql`, `informe_u7.pdf` (se redacta en `informe_u7.md`) | Ver "Las tres partes" |

## Alcance (regla principal): migración PARCIAL

La consigna **no** pide migrar toda la base, ni instalar Redis o Neo4j, ni configurar un clúster.

| Qué entra | Qué NO entra |
|---|---|
| El subconjunto **pedidos y detalle de pedidos**: al menos **5 pedidos** con sus líneas | Las demás tablas como colecciones propias (`usuario`, `producto`, `categoria`) |
| Datos esenciales del cliente y del producto **embebidos** dentro de cada pedido | Los otros pedidos de la carga masiva (200.000) |
| Una sola colección: `pedidos` | Redis, Neo4j, clúster, réplicas, índices avanzados |

Todo se ejecuta **solo contra el servidor propio de desarrollo**.

## Bases

| Base | Motor | Rol en el TP |
|---|---|---|
| `foodstore` | PostgreSQL | Fuente. Se lee. Única escritura permitida: pedidos de prueba con `CALL sp_crear_pedido(...)` (ver regla 12) |
| `plantilla_food_store` | PostgreSQL | Referencia de unidades anteriores; no se toca |
| `foodstore_nosql` (nombre propuesto) | MongoDB | Base documental con la colección `pedidos` |

### Cómo se arma `foodstore` (cada integrante, en su servidor)

```
En plantilla_food_store:  base_heredada/schema.sql → objects.sql → data.sql
En foodstore (CREATE DATABASE foodstore TEMPLATE plantilla_food_store):
                          views.sql   (el resto de la base heredada es opcional en esta unidad)
Opcional (solo si se hace la comparación de rendimiento): carga_masiva.sql → indices_semana3.sql →
                          indices.sql → materializadas.sql
```

`data.sql` deja **6 pedidos**. Con la carga masiva hay además 200.000: ver regla 13.

## Las tres partes del TP (100 puntos)

| Parte | Qué se entrega | Puntos |
|---|---|---|
| 1. Modelo documental y migración (consignas 1 a 3) | Subconjunto elegido con sus tablas y claves; esquema de la colección (campos, embebidos, arreglos, ids conservados); creación de la base y la colección; migración de ≥5 pedidos con `insertMany()`; **dos reglas de integridad** y justificación de lo embebido | 35 |
| 2. Consultas y verificación (consignas 4 y 5) | En MongoDB: a) todos los pedidos (solo id y estado), b) por estado, c) por producto dentro del arreglo de líneas, d) total mayor a un umbral justificado. En PostgreSQL: las equivalentes de **b y c** (c con `JOIN`). Tabla con cantidad e IDs en ambos motores | 40 |
| 3. Tecnología e IA (consignas 6 y 7) | Consulta a una IA que mencione el modelo actual, el acceso frecuente a pedidos completos y la coherencia de cantidades y precios; **contraste de dos afirmaciones** con documentación oficial o con el laboratorio; conclusión de **hasta 200 palabras** con ≥2 criterios técnicos | 20 |
| Presentación | Un único PDF de hasta **5 páginas** (sin contar el código), con modelo, evidencias, tabla de verificación, contraste de la IA y conclusión; integrantes y repositorio | 5 |

## Estructura de carpetas

```
food-store-tp-u7/
├── consultas_mongodb.js        creación, migración (insertMany) y consultas a) a d)
├── consultas_postgresql.sql    consultas equivalentes b) y c), con JOIN
├── informe_u7.md               informe en Markdown (se convierte a PDF)
├── informe_u7.pdf              entrega, hasta 5 páginas
├── modelo/                     esquema documental, export desde PostgreSQL, pedidos de prueba y JSON exportado
├── evidencias/                 salidas (.txt), tabla de verificación, respuesta y contraste de la IA
│   └── capturas/               capturas de Compass (.png)
├── BITACORA.md  README.md  AGENTS.md  CONTEXTO_IA.md
├── base_heredada/              los 10 .sql de Food Store (U1–U4), sin modificar
└── .kiro/steering/             contexto del proyecto
```

Las evidencias van como `.txt` o imagen: el `.gitignore` excluye `*.log`.

## Reglas Duras del Proyecto

Heredadas de las unidades anteriores:

1. **Nombres de tablas:** singular y español.
2. **Borrado lógico:** nunca `DELETE`; `UPDATE … SET eliminado = TRUE`.
3. **Altas de pedidos:** siempre `CALL sp_crear_pedido(...)`.
4. **Triggers automáticos:** no modificar `trg_subtotal`, `trg_total_ins`, `trg_total_upd`,
   `trg_validar_estado_pedido`.
5. **Vistas vigentes:** usarlas en vez de escribir el filtro a mano.
6. **JOINs y borrado lógico:** `eliminado = FALSE` en cada tabla del JOIN.

Propias de la Unidad 7:

7. **La migración es parcial.** Solo pedidos y detalle, con cliente y producto embebidos. No se migra toda la
   base ni se crean colecciones de usuarios o productos.
8. **Se conservan los identificadores de origen** (`pedido.id` como `_id`, y `usuario_id`, `producto_id`,
   `detalle_id`) y **se respetan importes, cantidades y estados existentes**: no se recalculan. El precio de cada
   línea es `detalle_pedido.precio_unitario` (**precio histórico**), nunca `producto.precio`.
9. **Solo registros vigentes:** `eliminado = FALSE` tanto en `pedido` como en `detalle_pedido`. El pedido 4 de
   `data.sql` está dado de baja (con su detalle) y **no se migra**.
10. **Nunca se migra `contrasena`.** El cliente embebido lleva solo `usuario_id`, `nombre`, `apellido` y `mail`.
    Tampoco `celular` ni `rol`, que no hacen falta.
11. **Tipos:** importes como `Decimal128` (`NumberDecimal("3500.00")`), nunca `Double`; fechas como `Date`/
    `ISODate`; cantidades como `NumberInt`. La elección se justifica en el informe.
12. **Pedidos de prueba** (si se necesitan, por ejemplo para que un producto aparezca en más de un pedido): solo
    con `CALL sp_crear_pedido(...)`, y se **declara su procedencia** (campo `origen` en el documento y mención en el
    informe). Se crean una sola vez sobre una base recién armada.
13. **Comparación honesta.** Las consultas de PostgreSQL se limitan a los **mismos ids migrados** (`id IN (...)`) y
    a registros vigentes. Si hay diferencias entre motores, **se explican y se corrige el modelo o la consulta**;
    nunca se ajustan los datos para que coincidan.
14. **Sin credenciales en el repo.** Una cadena de conexión de Atlas, una contraseña o un `.env` no se versionan
    (el `.gitignore` ya excluye `.env*`).
15. **Uso de IA.** Puede explorar el diseño y generar consultas, pero todo se ejecuta y se contrasta. La **respuesta
    completa** de la IA a la consigna 6 se guarda en `evidencias/respuesta_ia.md`; el PDF lleva solo las **dos
    afirmaciones contrastadas** y la conclusión, **sin transcripciones extensas de chat**.
16. **Resultados reales.** Cantidades, ids y tiempos se registran como salen de la ejecución. No se estiman ni se
    inventan.
17. **Sin datos personales reales.** Los datos del proyecto son ficticios; aun así, no se sube nada que no haga
    falta.

## Diferencia clave entre la consigna y la base real

La consigna aclara que los nombres del material son ilustrativos y que se usa la versión real de cada equipo.

| El material usa | La base real tiene |
|---|---|
| «cliente» | Tabla **`usuario`**; `pedido.usuario_id` |
| «productos» dentro del pedido | `detalle_pedido(producto_id, cantidad, precio_unitario, subtotal)` + `producto.nombre` |
| «total» | `pedido.total` (`NUMERIC(12,2)`), mantenido por triggers como suma de los `subtotal` |
| Estados | ENUM `estado_pedido`: `PENDIENTE`, `CONFIRMADO`, `TERMINADO`, `CANCELADO` |

## Pedidos que trae `data.sql` (referencia)

| Pedido | Cliente | Pago | Productos (id × cantidad) | Estado | Vigente |
|---|---|---|---|---|---|
| 1 | Ana (usuario 1) | EFECTIVO | 1×2, 7×2 | CONFIRMADO | Sí |
| 2 | Juan (2) | TARJETA | 4×6, 5×6, 8×2 | TERMINADO | Sí |
| 3 | Lucía (3) | TRANSFERENCIA | 12×1, 10×1 | PENDIENTE | Sí |
| 4 | Ana (1) | TARJETA | 2×1, 9×1 | PENDIENTE | **No** (`eliminado = TRUE`) |
| 5 | Mariano (4) | EFECTIVO | 13×2, 3×1, 11×2 | PENDIENTE | Sí |
| 6 | Sofía (5) | EFECTIVO | 6×4 | CANCELADO | Sí |

Con los pedidos 1, 2, 3, 5 y 6 se llega al mínimo de cinco. **Ningún producto se repite entre ellos**: una búsqueda
por producto devuelve un único pedido. Por eso se crearon dos pedidos de prueba (regla 12), con
`modelo/pedidos_de_prueba.sql`:

| Pedido | Cliente | Pago | Productos (id × cantidad) | Estado | Total | Origen |
|---|---|---|---|---|---|---|
| 7 | Juan (2) | TARJETA | 1×1, 8×1 | PENDIENTE | 4200.00 | `prueba` |
| 8 | Lucía (3) | EFECTIVO | 1×3, 7×1 | PENDIENTE | 11700.00 | `prueba` |

Se migran los 7 pedidos (1, 2, 3, 5, 6, 7 y 8). Resultado real: b) `PENDIENTE` → 3, 5, 7, 8; c) producto 1 → 1, 7, 8;
d) total > 10000 → 2, 5, 8. La `fecha` de los pedidos de prueba es la del día en que se crean en cada equipo.

## Trampas conocidas

- **`use` no funciona dentro de un `.js`.** Es un comando del shell interactivo. En un script usar
  `db = db.getSiblingDB('foodstore_nosql')`.
- **Tipos numéricos.** Para importes usar siempre `NumberDecimal("...")` (y comparar contra un importe también con
  `NumberDecimal`), nunca un número suelto. Para enteros, `NumberInt(...)` fija el tipo; en este laboratorio `_id`
  quedó `Int32` sin conversión (se vio en Compass), pero conviene ser explícito. El tipo de `detalle_id`,
  `producto_id` y `usuario_id` dentro de los documentos no se verificó.
- **`insertMany()` falla con clave duplicada si se repite** (el `_id` es el `pedido.id`). Antes de re-migrar,
  vaciar **solo** la colección del TP: `db.pedidos.drop()`.
- **Buscar en un arreglo de objetos:** `"lineas.producto_id": N` sirve para una condición; para varias condiciones
  sobre la **misma** línea usar `$elemMatch`.
- **Una fecha `DATE` de PostgreSQL pasa a `Date` en UTC** (medianoche). Es una decisión de modelo para anotar.
- **pgAdmin muestra solo la grilla de la última sentencia** de un script: ejecutar las consultas de a una.
- **Las evidencias `.log` no se versionan:** guardar la salida como `.txt`.
- **PowerShell 5.1 y los acentos.** El operador `>` guarda en UTF-16. Para guardar evidencia usar
  `[Console]::OutputEncoding = [System.Text.Encoding]::UTF8` y `| Out-File -Encoding utf8 archivo.txt`; para el export,
  `$env:PGCLIENTENCODING = "UTF8"`.
- **`psql` no está en el PATH:** usar la ruta completa (`C:\Program Files\PostgreSQL\17\bin\psql.exe`).
- **Fin de línea en Windows:** Git puede marcar archivos como modificados solo por CRLF/LF. No se commitean
  (`git config core.autocrlf true`).
- **Pedidos de prueba una sola vez por base.** Si `pedidos_de_prueba.sql` se corre dos veces se crean los pedidos 9 y
  10 y los ids dejan de coincidir entre los equipos. Antes comprobar que la base tiene 6 pedidos.
- **Compass no se actualiza solo** después de migrar: usar el botón de refrescar antes de sacar una captura.
- **Una tabla de resultados se contrasta siempre con las salidas guardadas.** Una tabla de verificación generada con IA
  decía «3 y 3, coinciden» sin respaldo y hubo que rehacerla (ver `BITACORA.md`).

## Criterios de evaluación

| Criterio | Puntaje |
|---|---|
| Modelo documental y correspondencia con Food Store; migración de datos | 35 |
| Consultas ejecutadas y comparación verificable con PostgreSQL | 40 |
| Contraste de recomendaciones de IA y fundamentación técnica | 20 |
| Presentación, claridad y evidencias completas | 5 |

## Reglas de proceso que se evalúan

- **Verificable:** cada afirmación del informe se apoya en una salida de `evidencias/`.
- **Contraste de la IA:** dos afirmaciones concretas de la respuesta, cada una confrontada con documentación oficial
  de MongoDB o con un resultado del laboratorio, indicando si la afirmación se sostiene.
- **Conclusión:** hasta 200 palabras, ≥2 criterios técnicos, y responde si conviene mantener PostgreSQL, usar MongoDB
  para este subconjunto o combinar ambas tecnologías.
- **Git:** avance por partes, commits legibles, sin credenciales en el repo.

## Vistas y objetos heredados (NO recrear)

Están en `base_heredada/`.

- `objects.sql`: vistas `v_categorias_vigentes`, `v_productos_vigentes`, `v_pedidos_resumen`, `v_pedido_detalle`;
  función `calcular_total_pedido`; triggers; procedimiento `sp_crear_pedido(BIGINT, forma_pago, JSONB)`.
- `views.sql`: `v_usuario_seguro`. `materializadas.sql`: `mv_facturacion_categoria_mes`.

## Base de Conocimiento y Steering

- `.kiro/steering/project-overview.md`: visión general, orden de ejecución y entregables.
- `.kiro/steering/conventions.md`: convenciones de base de datos y de modelado documental.
- `.kiro/steering/objects-and-patterns.md`: objetos heredados y patrones de modelado, migración y consulta.
