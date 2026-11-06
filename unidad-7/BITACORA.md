# Bitácora del equipo — TP Unidad 7 (Food Store: NoSQL con MongoDB)

Unificación de las bitácoras personales de los tres integrantes (eliminadas del repo una vez unificadas), hecha por Mariano el 2026-11-01. Cada dato se comparó contra los archivos del
repo; la columna **Respaldo** dice dónde está la evidencia, y lo que no tiene respaldo guardado se marca como tal. No se anotan contraseñas
ni cadenas de conexión. La bitácora no es entregable: es el registro de qué hicimos y por qué.

## 1. Equipo y reparto

| Integrante | A su cargo | Estado |
|---|---|---|
| Mariano Chirino | Parte 1 (modelo y migración), consigna 4 (MongoDB), informe, README, unificación de bitácoras | Hecho |
| Andrés | Consigna 5 (consultas en PostgreSQL), pedidos de prueba, tabla de verificación | Hecho; tabla corregida entre Mariano y Andrés |
| Facundo | Consignas 6 y 7 (IA, contraste, conclusión); instalar MongoDB y revisar `consultas_mongodb.js` | Hecho; contraste corregido |

El armado del informe pasó de Facundo a Mariano el 2026-10-30 para repartir mejor la carga (el documento de reparto se eliminó del repo al final).

## 2. Entornos

| Integrante | Servidores y versiones | Conteos `usuario` / `producto` / `pedido` | Respaldo |
|---|---|---|---|
| Mariano | PostgreSQL 17.10, base `foodstore`; MongoDB 9.0.4; `mongosh` 2.14.0; Windows PowerShell 5.1 | 6 / 16 / 8 (con `data.sql` y los pedidos de prueba) | `evidencias/pg_conteos.txt` (6 / 16 / 8) y `evidencias/pg_verificacion_h0.txt` (6 pedidos con `data.sql`, el 4 con `eliminado = t`). El 6 / 16 / 6 previo a los pedidos de prueba no tiene salida guardada |
| Andrés | PostgreSQL 16, base `foodstore7` | 6 / 16 / 8 (según su bitácora personal) | `evidencias/postgres_b.txt` y `postgres_c.txt` (muestran los pedidos 7 y 8). El conteo de Andrés no tiene salida guardada; el de Mariano, que coincide, sí |
| Facundo | MongoDB 9.0.4; `mongosh` 2.14.1; Windows PowerShell | — | Declarado por Facundo en su bitácora personal (`ping` con `ok: 1`, 7 documentos insertados). **Sin salida guardada** |

Armado de PostgreSQL: `plantilla_food_store` con `schema.sql` → `objects.sql` → `data.sql`, `foodstore` creada con esa plantilla y `views.sql`. No se corrió
la carga masiva (200.000 pedidos). MongoDB: servidor local; Compass solo para las capturas.

## 3. Cronología

| Fecha | Quién | Qué | Respaldo |
|---|---|---|---|
| 2026-10-30 | Mariano | H0, export desde PostgreSQL y primera migración (5 pedidos); acentos de la evidencia corregidos | `modelo/pedidos_export.json`, `evidencias/mongo_migracion_y_consultas.txt`; commit `98c8e8e` |
| 2026-10-30 | Andrés | Pedidos de prueba 7 y 8, consultas b) y c) de PostgreSQL y primera tabla de verificación | `modelo/pedidos_de_prueba.sql`, `consultas_postgresql.sql`, `evidencias/postgres_b.txt`, `postgres_c.txt`; commits `a2f9773`, `8994d48` |
| 2026-10-31 | Mariano | Revisó el repo de Andrés, encontró que la tabla no coincidía con la evidencia, corrió los pedidos de prueba en su base, repitió el export y la migración (7 documentos) | `evidencias/mongo_migracion_y_consultas.txt`; `evidencias/tabla_verificacion.md`; commit `a2a2cd5` |
| 2026-10-31 | Facundo | H0 con MongoDB, ejecución de `consultas_mongodb.js`, consulta a la IA, primer contraste y conclusión | `evidencias/respuesta_ia.md`, `evidencias/contraste_ia.md`; commit `a1272ca` |
| 2026-11-01 | Mariano | Revisó el contraste de la IA, lo corrigió, corrigió las bitácoras personales de Andrés y Facundo y cerró el merge a `main` | `evidencias/contraste_ia.md`; commits `b5bf7a2` y `481f4e1` |
| 2026-11-01 | Mariano | Revisión final del repo con la IA: se agregó la verificación de subtotal = cantidad × precio (script y `evidencias/verificacion_export_json.txt`), se acotó el texto de la regla 2, se citó la ejecución de PostgreSQL 17 y se regeneró el PDF | `consultas_mongodb.js`, `informe_u7.md`, `informe_u7.pdf` |
| 2026-11-01 | Mariano | Sacó las capturas de la pestaña *Validation* de Compass (unidas en una sola imagen) y se agregaron al informe | `evidencias/capturas/compass_validation.png` |
| 2026-11-01 | Mariano | Volvió a correr `consultas_mongodb.js` con la regla 1b: `Insertados: 7`, reglas 1, 1b y 2 en `[]`, ids de b) y c) sin cambios | `evidencias/mongo_migracion_y_consultas.txt` |

## 4. Resultados verificados contra la evidencia

| Dato | Valor | Respaldo |
|---|---|---|
| Pedidos vigentes en `data.sql` | 1, 2, 3, 5, 6 (el 4 con `eliminado = true`) | `evidencias/pg_verificacion_h0.txt` |
| Documentos migrados | 7 (ids 1, 2, 3, 5, 6, 7, 8) | `evidencias/mongo_migracion_y_consultas.txt` (`Insertados: 7`, `countDocuments: 7`) |
| Regla de integridad 1 (total = suma de subtotales) | 0 documentos que la violen | Idem |
| Regla de integridad 2 (líneas con cantidad ≤ 0) | 0 documentos | Idem |
| b) `PENDIENTE` | MongoDB ids 3, 5, 7, 8; PostgreSQL ids 3, 5, 7, 8 | Idem y `evidencias/postgres_b.txt` |
| c) producto 1 | MongoDB ids 1, 7, 8; PostgreSQL ids 1, 7, 8 | Idem y `evidencias/postgres_c.txt` |
| d) total > 10000.00 | MongoDB ids 2, 5, 8 (11900.00, 18700.00, 11700.00) | `evidencias/mongo_migracion_y_consultas.txt` |
| Totales de los pedidos de prueba | Pedido 7: 4200.00; pedido 8: 11700.00 | Ambas evidencias |
| Conteos en el servidor de Mariano | 6 usuarios, 16 productos, 8 pedidos | `evidencias/pg_conteos.txt` |
| `consultas_postgresql.sql` en el servidor de Mariano (PostgreSQL 17) | b) ids 3, 5, 7, 8; c) ids 1, 7, 8, los mismos que en la base de Andrés | `evidencias/postgres_ejecucion_mariano.txt` |
| Tipos en Compass | `_id` Int32, `fecha` Date, `total` Decimal128 | `evidencias/capturas/compass_coleccion.png` |
| Promedio de los 7 totales | 9200 (umbral de d) = 10000) | Cálculo sobre los totales de arriba |
| Fecha de los pedidos | 2026-10-30 los de `data.sql`; los de prueba, 2026-10-31 en la migración de Mariano y 2026-10-30 en la base de Andrés | `evidencias/postgres_b.txt` y la salida de Mongo. `fecha` toma el día en que se crea el pedido; no afecta la comparación |

**Sin respaldo guardado:** el conteo previo a los pedidos de prueba (6 / 16 / 6), el conteo de Andrés y la ejecución local de Facundo.
Cada una se resuelve guardando la salida en un `.txt` de `evidencias/`.

## 5. Interacciones con IA

| Integrante | Herramienta | Qué se pidió y qué entregó | Qué se validó |
|---|---|---|---|
| Mariano | Claude | Scripts de export y migración, esquema, consultas de MongoDB, informe, README, revisión de los repos de Andrés y Facundo | Se ejecutó todo. **La IA no se equivocó** en el export ni en la migración: funcionaron a la primera. Los valores esperados se calcularon a mano y coincidieron con la salida real |
| Andrés | OpenCode | Consultas de PostgreSQL y la tabla de verificación | Las consultas eran correctas. La **tabla no se contrastó** con las salidas guardadas: decía 3 y 3 pedidos y que coincidían, y la evidencia mostraba 4 y 3 en PostgreSQL y 2 y 1 en MongoDB. Se rehízo |
| Facundo | Claude | Comparación de PostgreSQL y MongoDB para Food Store (consigna 6). El prompt menciona el modelo relacional actual, el acceso frecuente a pedidos completos y la coherencia de cantidades y precios históricos; está guardado en `evidencias/respuesta_ia.md` | Se contrastaron dos afirmaciones de la respuesta (ver sección 6) |

Lo que mostró la IA: las afirmaciones de la respuesta de la consigna 6 se sostienen solo en parte. «MongoDB no valida esquemas» es falsa, y que el embebido elimine por completo el costo de los JOINs no está respaldado por el laboratorio.

## 6. Revisiones cruzadas

| Quién revisó | Qué | Qué encontró |
|---|---|---|
| Mariano | `consultas_postgresql.sql`, evidencias y tabla de Andrés | Consultas correctas (estado, `JOIN` con `eliminado = FALSE` en ambas tablas, mismos ids). La tabla no estaba respaldada: PostgreSQL daba 4 y 3 y MongoDB tenía 5 documentos. Causa: los pedidos 7 y 8 no estaban migrados. Se migraron y la tabla se rehízo. Mariano ejecutó el `.sql` en su servidor y obtuvo los mismos ids (`evidencias/postgres_ejecucion_mariano.txt`) |
| Mariano | Contraste de la IA de Facundo | Cuatro correcciones: afirmación 1 («totalmente falsa» → solo en parte), afirmación 2 («sí» → en parte, sin medición de rendimiento), la conclusión presentaba el precio histórico como ventaja de MongoDB (PostgreSQL también lo guarda en `precio_unitario`) y faltan el prompt y la herramienta. El encabezado de «196 palabras» pasó a unas 164 |
| Facundo | `consultas_mongodb.js` en su equipo | 7 documentos insertados y resultados coherentes con la evidencia de Mariano (b, c y d con los mismos ids), según su bitácora; sin salida guardada. Pendiente: comprobar que su contraste quedó fiel en el informe |
| Andrés | Modelo y migración; el PDF contra las evidencias y las 5 páginas | Pendiente |

## 7. Problemas encontrados

| Fecha | Problema | Causa | Solución |
|---|---|---|---|
| 2026-10-30 | Acentos rotos en la evidencia de Mongo (`cl├ísica`, `Luc├¡a`) | Codificación de la consola de PowerShell 5.1; los datos estaban bien | `[Console]::OutputEncoding` en UTF-8 y `Out-File -Encoding utf8` |
| 2026-10-30 | `git status` marcaba archivos modificados sin cambios | Fin de línea CRLF/LF | `git config core.autocrlf true`; no se commitean |
| 2026-10-30 | Excel convirtió la lista de ids `3, 5, 7` en una fecha (`3,5,2007`) | Interpretación de formato de Excel | Se usó texto plano y la tabla pasó a Markdown (`tabla_verificacion.md`) |
| 2026-10-31 | Tabla de verificación de Andrés sin respaldo (3 y 3, «coinciden») | No se contrastó con las salidas guardadas; MongoDB no tenía migrados los pedidos 7 y 8 | Migración repetida con 7 documentos y tabla rehecha: 4 y 4, 3 y 3 |
| 2026-10-31 | Archivo temporal `~$...xlsx` y capturas en una carpeta con espacios dentro del repo | Excel crea el temporal; las capturas se guardaron en una subcarpeta | Se borró el temporal; las capturas quedaron en `evidencias/capturas/` |
| 2026-11-01 | Conflicto al mergear `bitacora_Facundo.md` y `contraste_ia.md` | Mariano los había editado en `main` y Facundo en su rama; el intento de resolverlo con Copilot no dejó los archivos resueltos | Se pisaron con las versiones corregidas y se comprobó con `git grep` que no quedaban marcas. El editor (Vim) se cerró sin guardar y el push fue rechazado hasta cerrar el merge con `git commit -m` (`481f4e1`) |

## 8. Decisiones

| Decisión | Alternativas | Por qué |
|---|---|---|
| Migración parcial: una colección `pedidos` con 7 documentos | Migrar toda la base | Es lo que pide la consigna |
| Migrar solo registros vigentes (excluir el pedido 4) | Incluirlo | Está dado de baja (`eliminado = TRUE`) |
| Cliente y líneas embebidos, con precio histórico | Colecciones separadas con referencias | Los pedidos se leen completos; un acceso, sin JOIN. Costo: lo embebido es una copia |
| `Decimal128` para importes, `Int32` para cantidades, `Date` para la fecha | `Double` | Evita el error binario en importes |
| Validador `$jsonSchema` y verificación posterior a la migración | Solo la verificación | MongoDB no tiene triggers ni `CHECK`; el validador no cubre «total = suma» |
| Generar el JSON desde PostgreSQL y cargarlo desde `consultas_mongodb.js` | Tipear el `insertMany()` | Evita errores y respeta ids, importes y estados |
| Dos pedidos de prueba con `sp_crear_pedido`, una sola vez por base | Usar solo los 5 de `data.sql` | Para que el producto 1 aparezca en más de un pedido |
| Umbral de d) = 10000 | Otros valores | Queda por encima del promedio de los 7 totales (9200) |
| Terminal (`mongosh`) para ejecutar y Compass solo para capturas | Compass para todo | Es repetible y deja salida en texto |
| Informe en `informe_u7.md`, convertido a PDF al final | Armar el PDF directo | Se podía seguir editando |
| Corregir directamente las partes de Andrés y Facundo y mergearlas en `main`, con notas y marcas *(corregido)* en sus bitácoras | Pedirles que las corrijan | El error de la tabla bloqueaba el informe |
| Mariano trabajó directo en `main`; Andrés y Facundo, en ramas propias (`Andrés`, `parte-Facundo`) integradas con Pull Request (#1 y #2) | Una rama por parte para todos | Mariano ya había avanzado en `main` y no aportaba crear una rama; cada uno editó archivos distintos |
| Conclusión: combinar ambas tecnologías, con PostgreSQL como sistema de registro | Solo PostgreSQL o solo MongoDB | Integridad frente a lectura de pedidos completos; ver el contraste |

## 9. Pendiente

- Facundo: guardar la salida de su ejecución de `consultas_mongodb.js` (hoy figura solo como declarada).
- Andrés: revisar el informe y el PDF contra las evidencias y las 5 páginas.
- Facundo: comprobar que su contraste y su conclusión quedaron fieles en el informe.
- Opcional: captura de la consulta c) en Compass.
- Regenerar `informe_u7.pdf` si cambia el informe.
