# Contexto para otra IA — TP Unidad 7 (Food Store: PostgreSQL → MongoDB)

> **Cómo usarlo:** pegá este archivo completo al inicio de la conversación con la otra IA y escribí tu pedido en la sección 10.
> Lo marcado como **[VERIFICADO]** salió de una ejecución real o de un archivo del repo. Lo marcado como **[NO VERIFICADO]**
> es una estimación o una hipótesis: la IA no debe presentarlo como un resultado.
> **Última actualización:** 2026-11-01 (partes de Andrés y Facundo integradas y corregidas en `main`; falta la revisión de Andrés y guardar tres salidas de evidencia).

## 1. De qué se trata

Trabajo práctico de la Unidad 7 de Bases de Datos II (Tecnicatura Universitaria en Programación): representar en **MongoDB**
una parte ya implementada de Food Store (**pedidos y detalle de pedidos**), ejecutar consultas y compararlas con **PostgreSQL**,
y fundamentar la elección tecnológica contrastando lo que sugiere una IA con ejecución real y documentación oficial.

- **Migración parcial:** mínimo 5 pedidos, una sola colección. No se migra toda la base ni se usa Redis, Neo4j o clúster.
- **Entrega:** un único PDF de hasta 5 páginas (`informe_u7.pdf`) + `consultas_mongodb.js` + `consultas_postgresql.sql`.
  El informe se redacta en `informe_u7.md` (raíz del repo) y al final se convierte a PDF.
- **Equipo:** Mariano Chirino, Andrés, Facundo. **Repo:** https://github.com/marianoemir/TP-Unidad7-BD2 (se trabaja en `main`).

| Parte | Qué pide | Puntos |
|---|---|---|
| 1. Modelo y migración (consignas 1–3) | Esquema de la colección, `insertMany()` de ≥5 pedidos, dos reglas de integridad, justificar lo embebido | 35 |
| 2. Consultas y verificación (4–5) | MongoDB: a) todos (id y estado), b) por estado, c) por producto en el arreglo, d) total > umbral justificado. PostgreSQL: b) y c) (c con JOIN). Tabla con cantidad e ids en ambos motores | 40 |
| 3. Tecnología e IA (6–7) | Consulta a una IA (debe mencionar el modelo actual, el acceso frecuente a pedidos completos y la coherencia de cantidades y precios); contraste de **dos afirmaciones** con doc oficial o con el laboratorio; conclusión de **≤200 palabras** con ≥2 criterios técnicos | 20 |
| Presentación | PDF claro, con evidencias | 5 |

## 2. Quién hace qué y estado

| Integrante | A su cargo | Estado |
|---|---|---|
| **Mariano** | Parte 1, consigna 4 (MongoDB), armado del informe, README, `BITACORA.md` unificada | **Hecho** (7 pedidos migrados, informe en Markdown, README y bitácora unificada). Falta convertir el informe a PDF |
| **Andrés** | Consigna 5: `consultas_postgresql.sql`, tabla de verificación, pedidos de prueba | **Hecho**. Su tabla original estaba mal y se rehízo; su bitácora personal fue corregida por Mariano |
| **Facundo** | Consignas 6 y 7: consulta a la IA, contraste, conclusión; instalar MongoDB y revisar `consultas_mongodb.js` | **Hecho** y corregido por Mariano. Usó Claude; el prompt está en `evidencias/respuesta_ia.md` |

Pendiente entre ellos: Andrés revisa el informe y el PDF contra las evidencias; Facundo comprueba que su contraste y su conclusión quedaron fieles en el informe;
Mariano ejecuta `consultas_postgresql.sql` en su servidor y guarda la salida. Las bitácoras personales se unificaron en `BITACORA.md` y se eliminaron del repo.

## 3. Base de datos de origen (PostgreSQL)

Entornos: **Mariano** PostgreSQL 17.10, base `foodstore`; **Andrés** PostgreSQL 16, base `foodstore7`. Tablas (singular y español):
`categoria`, `producto`, `usuario`, `pedido`, `detalle_pedido`.

- `pedido(id, fecha DATE, estado estado_pedido, total NUMERIC(12,2), forma_pago, usuario_id → usuario, eliminado, created_at)`
- `detalle_pedido(id, cantidad INT >0, precio_unitario NUMERIC(10,2), subtotal NUMERIC(12,2), pedido_id → pedido, producto_id → producto, eliminado, UNIQUE(pedido_id, producto_id))`
- `usuario(id, nombre, apellido, mail UNIQUE, celular, contrasena, rol, eliminado)` — **`contrasena` nunca se migra**
- `producto(id, nombre, precio, stock, categoria_id, disponible, eliminado)`
- ENUM `estado_pedido`: `PENDIENTE`, `CONFIRMADO`, `TERMINADO`, `CANCELADO`.
- Triggers que calculan `subtotal` y `pedido.total` y bloquean `CONFIRMADO → PENDIENTE`. Los pedidos se crean **solo** con
  `CALL sp_crear_pedido(usuario_id, forma_pago, '[{"producto_id":N,"cantidad":N}]'::jsonb)`. Borrado lógico: `eliminado = TRUE`, nunca `DELETE`.

### Pedidos [VERIFICADO]

Conteos `usuario / producto / pedido`: **6 / 16 / 6** con `data.sql` solo, **6 / 16 / 8** con los pedidos de prueba (incluyen registros dados de baja).

| Pedido | Cliente (usuario_id) | Pago | Líneas (producto × cantidad) | Estado | Total | Origen / vigente |
|---|---|---|---|---|---|---|
| 1 | Ana García (1) | EFECTIVO | 1×2 (Muzzarella 3500), 7×2 (Coca-Cola 1200) | CONFIRMADO | 9400.00 | data.sql |
| 2 | Juan Pérez (2) | TARJETA | 4×6 (900), 5×6 (850), 8×2 (700) | TERMINADO | 11900.00 | data.sql |
| 3 | Lucía Martínez (3) | TRANSFERENCIA | 12×1 (3800), 10×1 (1500) | PENDIENTE | 5300.00 | data.sql |
| 4 | Ana García (1) | TARJETA | 2×1, 9×1 | PENDIENTE | — | data.sql, **`eliminado = TRUE`: no se migra** |
| 5 | Mariano Chirino (4) | EFECTIVO | 13×2 (4900), 3×1 (4500), 11×2 (2200) | PENDIENTE | 18700.00 | data.sql |
| 6 | Sofía Torres (5) | EFECTIVO | 6×4 (800) | CANCELADO | 3200.00 | data.sql |
| 7 | Juan Pérez (2) | TARJETA | 1×1 (3500), 8×1 (700) | PENDIENTE | 4200.00 | prueba (`modelo/pedidos_de_prueba.sql`) |
| 8 | Lucía Martínez (3) | EFECTIVO | 1×3 (3500), 7×1 (1200) | PENDIENTE | 11700.00 | prueba |

Los `detalle_id` de las líneas de los pedidos de prueba son 14 a 17. `pedido.fecha` toma `CURRENT_DATE` al crear el pedido: los de
`data.sql` tienen 2026-10-30 en ambos equipos; los de prueba tienen 2026-10-31 en la migración de Mariano y 2026-10-30 en la base de Andrés.
La fecha **no** interviene en la comparación (se compara por ids y cantidades).

## 4. Modelo documental elegido (MongoDB servidor 9.0.4, `mongosh` 2.14.0, base `foodstore_nosql`, colección `pedidos`)

```js
{ _id: 1,                                   // = pedido.id
  fecha: ISODate("2026-10-30T00:00:00Z"),   // Date, medianoche UTC
  estado: "CONFIRMADO", forma_pago: "EFECTIVO",
  total: Decimal128("9400.00"),             // tal cual está en PostgreSQL, sin recalcular
  cliente: { usuario_id: 1, nombre: "Ana", apellido: "García", mail: "ana.garcia@mail.com" },   // embebido
  lineas: [ { detalle_id: 1, producto_id: 1, nombre: "Muzzarella", cantidad: 2,                  // arreglo embebido
              precio_unitario: Decimal128("3500.00"), subtotal: Decimal128("7000.00") }, ... ],  // precio HISTÓRICO
  origen: "data.sql" }                      // "prueba" para los pedidos 7 y 8
```

- **Se conserva:** `_id`, `cliente.usuario_id`, `lineas[].detalle_id`, `lineas[].producto_id`. **No se migra** `contrasena`, `celular`, `rol`
  ni registros con `eliminado = TRUE`.
- **Tipos:** importes `Decimal128`, cantidad `Int32`, fecha `Date`, estados como string. [VERIFICADO en Compass] `_id Int32`, `fecha Date`,
  `total Decimal128`; el validador exige `cantidad` int y los importes decimal, y la inserción de los 7 documentos lo aceptó.
  [NO VERIFICADO] el tipo exacto de `detalle_id`, `producto_id` y `usuario_id` dentro de los documentos (se podría ver con *Analyze Schema*).
- **Dos reglas de integridad:** (1) total = suma de subtotales y subtotal = cantidad × precio_unitario; (2) líneas válidas y vigentes
  (cantidad > 0, estado permitido, sin eliminados). Se refuerzan con un validador `$jsonSchema` y se verifican después de migrar.
- **Por qué embeber:** las líneas se leen siempre con el pedido, no tienen sentido solas y son pocas → un acceso, sin JOIN.
  **Costo:** lo embebido es copia del momento de migrar (si cambia el mail del cliente, el documento no se entera).

## 5. Resultados ejecutados [VERIFICADO — `evidencias/mongo_migracion_y_consultas.txt`, `postgres_b.txt`, `postgres_c.txt`]

Migración final: **7 documentos** (ids 1, 2, 3, 5, 6, 7, 8). Verificaciones de integridad: ambas dan 0 documentos.

| Consulta | MongoDB | PostgreSQL (Andrés) | Coinciden ids |
|---|---|---|---|
| a) todos (`find({}, { estado: 1 })`) | 7 pedidos | — | — |
| b) estado `PENDIENTE` | 4: ids **[3, 5, 7, 8]** | 4: [3, 5, 7, 8] | Sí |
| c) `lineas.producto_id: 1` | 3: ids **[1, 7, 8]** (con `$elemMatch` y cantidad ≥ 2: ids 1 y 8) | 3: [1, 7, 8] | Sí |
| d) `total > NumberDecimal("10000.00")` | 3: ids **[2, 5, 8]** (11900.00, 18700.00, 11700.00) | no se pidió | — |

Umbral de d): 10000, por encima del promedio de los 7 totales (9200). Las consultas de Andrés (`consultas_postgresql.sql`):
b) `WHERE estado = 'PENDIENTE' AND eliminado = FALSE AND id IN (1, 2, 3, 5, 6, 7, 8)`; c) `JOIN` de `pedido` y `detalle_pedido` con
`producto_id = 1`, `eliminado = FALSE` en ambas tablas y el mismo `IN (...)`.

**Historia (para no repetir el error):** la primera comparación **no** coincidía. MongoDB, migrado solo con los 5 pedidos de `data.sql`, daba b) [3,5] y
c) [1], y PostgreSQL con los pedidos de prueba daba 4 y 3. Causa: los pedidos 7 y 8 no estaban migrados. Se agregaron al export y se migró de nuevo.
La tabla de verificación original de Andrés decía «3 y 3, coinciden» y no estaba respaldada por ninguna ejecución; se rehízo con los resultados reales.
Capturas de Compass (vista de tabla, 7 documentos y tipos) y del pedido 1 desplegado: `evidencias/compass_coleccion.png` y `compass_pedido1.png`.

## 6. Archivos del repo (estructura final)

| Archivo | Para qué |
|---|---|
| `consultas_mongodb.js` | Crea la colección con validador, migra con `insertMany()`, verifica integridad y corre a) a d). Repetible (borra solo `pedidos`) |
| `consultas_postgresql.sql` | Consultas b) y c) de PostgreSQL (Andrés) |
| `modelo/exportar_pedidos.sql`, `modelo/pedidos_export.json` | Export desde PostgreSQL (`IN (1,2,3,5,6,7,8)`) y su resultado (datos ficticios) |
| `modelo/pedidos_de_prueba.sql` | Dos `CALL sp_crear_pedido` (pedidos 7 y 8); **una sola vez** por base con 6 pedidos |
| `modelo/esquema_documental.md` | Esquema, tipos, reglas de integridad, justificación y pedidos migrados |
| `evidencias/` | `mongo_migracion_y_consultas.txt`, `pg_verificacion_h0.txt`, `postgres_b.txt`, `postgres_c.txt`, `tabla_verificacion.md`, `respuesta_ia.md`, `contraste_ia.md` |
| `evidencias/capturas/` | `compass_coleccion.png`, `compass_pedido1.png` |
| `informe_u7.md`, `informe_u7.pdf`, `README.md`, `BITACORA.md`, `AGENTS.md`, `CONTEXTO_IA.md` (todos en la raíz) | Informe, documentación y seguimiento |

Ejecución (desde la raíz del repo, Windows PowerShell 5.1):
```powershell
$psql = "C:\Program Files\PostgreSQL\17\bin\psql.exe"
& $psql -U postgres -d foodstore -f modelo/pedidos_de_prueba.sql        # una sola vez, base con 6 pedidos
$env:PGCLIENTENCODING = "UTF8"
& $psql -U postgres -d foodstore -t -A -f modelo/exportar_pedidos.sql -o modelo/pedidos_export.json
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
mongosh --file consultas_mongodb.js | Out-File -Encoding utf8 evidencias/mongo_migracion_y_consultas.txt
& $psql -U postgres -d foodstore -f consultas_postgresql.sql
```

## 7. Pendiente / abierto

- **Mariano:** regenerar `informe_u7.pdf` si cambia el informe (hoy tiene 3 páginas; el límite es 5); ejecutar `consultas_postgresql.sql` en su servidor y guardar la salida en `evidencias/`;
  guardar la salida de los conteos de `usuario`, `producto` y `pedido` (hoy solo figuran en `BITACORA.md`).
- **Andrés:** revisar el informe y el PDF contra las evidencias y las 5 páginas.
- **Facundo:** comprobar que su contraste y su conclusión quedaron fieles en el informe.
- **[NO VERIFICADO]** el tipo exacto de `detalle_id`, `producto_id` y `usuario_id` dentro de los documentos (se podría ver con *Analyze Schema* en Compass).
- Opcional: captura de la consulta c) en Compass con el filtro `{ "lineas.producto_id": 1 }` (3 pedidos).

## 8. Reglas que la otra IA debe respetar

1. **No inventar resultados.** Cantidades, ids y tiempos solo los que salgan de una ejecución real; si no hay evidencia, decirlo. Una tabla de resultados
   se contrasta siempre con las salidas guardadas antes de darla por buena (ya hubo una incorrecta).
2. No migrar `contrasena`, `celular` ni `rol`; no migrar registros con `eliminado = TRUE`.
3. Los pedidos se crean solo con `CALL sp_crear_pedido(...)`, **una sola vez por base** (si no, los ids dejan de coincidir); nunca `DELETE`; no tocar los triggers.
4. Las consultas de PostgreSQL se limitan a los **mismos ids migrados** y a registros vigentes (`eliminado = FALSE` en cada tabla del JOIN).
   Si hay diferencias entre motores, se explican y se corrige el modelo o la consulta; **nunca se ajustan los datos**.
5. Precio de cada línea = `detalle_pedido.precio_unitario` (histórico), no `producto.precio`. Importes como `Decimal128`.
6. Sin credenciales, cadenas de conexión ni contraseñas en ningún texto o archivo.
7. Citar documentación oficial de MongoDB al contrastar afirmaciones (p. ej. https://www.mongodb.com/docs/manual/data-modeling/embedding/).
8. La respuesta completa de la IA a la consigna 6 va a `evidencias/respuesta_ia.md`; el informe lleva solo dos afirmaciones contrastadas y la conclusión,
   sin transcripciones extensas.
9. Responder en español (voseo rioplatense), con tono claro y sin relleno. El README va sin acentos, como el del TP anterior.
10. En PowerShell 5.1, guardar evidencia con `Out-File -Encoding utf8` y la consola en UTF-8 (`>` guarda en UTF-16 y rompe los acentos).

## 9. Estructura del informe (`informe_u7.md`)

Encabezado (integrantes y repo) · 1. Modelo documental · 2. Migración e integridad · 3. Consultas en MongoDB (con capturas de Compass) ·
4. Tabla de verificación PostgreSQL vs. MongoDB (con la diferencia detectada y corregida) · 5. Contraste de afirmaciones de la IA · 6. Conclusión (164 palabras).
Completo, en la raíz del repo (`informe_u7.md` y `informe_u7.pdf`, 3 páginas; el límite es 5).

## 10. Tu tarea (completá esto antes de pegar)

> Soy [nombre]. Necesito: [describir el pedido concreto, p. ej. «redactar la consulta a la IA de la consigna 6», «redactar el contraste de dos afirmaciones», «revisar el informe»].
