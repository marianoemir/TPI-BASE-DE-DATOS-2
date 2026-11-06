# TP Unidad 7 - Food Store: NoSQL y nuevas formas de almacenamiento

[![Repositorio en GitHub](https://img.shields.io/badge/GitHub-TP--Unidad7--BD2-181717?logo=github&logoColor=white)](https://github.com/marianoemir/TP-Unidad7-BD2)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16%2B-336791?logo=postgresql&logoColor=white)
![MongoDB](https://img.shields.io/badge/MongoDB-9.0-47A248?logo=mongodb&logoColor=white)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1-5391FE?logo=powershell&logoColor=white)

> 📦 **Repositorio del trabajo:** [github.com/marianoemir/TP-Unidad7-BD2](https://github.com/marianoemir/TP-Unidad7-BD2)

Trabajo practico de Bases de Datos II (Tecnicatura Universitaria en Programacion, UTN FRM). Representa en MongoDB una
parte ya implementada de Food Store (**pedidos y detalle de pedidos**), ejecuta consultas y las compara con PostgreSQL,
y fundamenta la eleccion tecnologica contrastando lo que sugiere una IA. Probado en Windows con PowerShell 5.1,
PostgreSQL 16 y 17, MongoDB 9.0.4 y `mongosh` 2.14.0. Equipo: Mariano Chirino, Andres Fabre y Facundo Quiroga.

La migracion es **parcial** a proposito: una coleccion `pedidos` con 7 documentos (los 5 pedidos vigentes de `data.sql`
y 2 pedidos de prueba). No se migra toda la base ni se usa Redis, Neo4j o un cluster.

## Entregables

| Archivo | Contenido | Responsable |
|---|---|---|
| `modelo/esquema_documental.md` | Mapeo de las tablas al documento, tipos, dos reglas de integridad y que se embebio y por que | Mariano |
| `modelo/exportar_pedidos.sql` | Genera con `psql` el JSON de los pedidos desde PostgreSQL (solo lee) | Mariano |
| `modelo/pedidos_export.json` | Resultado del export (datos ficticios, sin `contrasena`) | Mariano |
| `modelo/pedidos_de_prueba.sql` | Dos pedidos de prueba creados con `sp_crear_pedido` (ids 7 y 8) | Andres |
| `consultas_mongodb.js` | Crea la coleccion con validador, migra con `insertMany()`, verifica integridad y ejecuta las consultas a) a d) | Mariano |
| `consultas_postgresql.sql` | Consultas equivalentes a b) y c) (la c con `JOIN`), limitadas a los ids migrados y a registros vigentes | Andres |
| `evidencias/tabla_verificacion.md` | Cantidad e ids recuperados en ambos motores y explicacion de la diferencia detectada | Andres (corregida entre los dos) |
| `evidencias/respuesta_ia.md` y `evidencias/contraste_ia.md` | Respuesta completa de la IA, dos afirmaciones contrastadas y conclusion | Facundo |
| `informe_u7.pdf` | Informe de hasta 5 paginas con modelo, evidencias, tabla de verificacion, contraste de la IA y conclusion | Mariano (armado); Facundo (contraste y conclusion) |

Material de apoyo: `evidencias/` (salidas de ejecucion; capturas de Compass en `evidencias/capturas/`), `BITACORA.md` (registro de lo hecho),
`AGENTS.md` y `.kiro/steering/` (reglas del proyecto para la IA), `base_heredada/` (los `.sql`
de Food Store de las unidades anteriores, sin modificar).

## Requisitos

- PostgreSQL 16+ con `psql`. No esta en el PATH: se invoca con la ruta completa
  (por ejemplo `C:\Program Files\PostgreSQL\17\bin\psql.exe`).
- La base `foodstore` armada con `base_heredada/schema.sql`, `objects.sql`, `data.sql` y `views.sql` (orden de armado en
  `AGENTS.md`). Tiene que mostrar 6 pedidos (ids 1 a 6, el 4 dado de baja) y los conteos 6 / 16 / 6 de `usuario`,
  `producto` y `pedido`. No se usa la carga masiva.
- MongoDB (servidor local o Atlas) y `mongosh`. Prueba: `mongosh --eval "db.runCommand({ ping: 1 })"` debe responder `ok: 1`.
  MongoDB Compass es opcional: se uso para las capturas.
- **Sin contrasenas ni cadenas de conexion en el repo.**

## Uso

Desde PowerShell, en la raiz del repo (los scripts leen `modelo/pedidos_export.json` con ruta relativa):

```powershell
$psql = "C:\Program Files\PostgreSQL\17\bin\psql.exe"

# 1. Pedidos de prueba: UNA sola vez, sobre una base con 6 pedidos (los ids nuevos son 7 y 8)
& $psql -U postgres -d foodstore -f modelo/pedidos_de_prueba.sql

# 2. Exportar los pedidos desde PostgreSQL
$env:PGCLIENTENCODING = "UTF8"
& $psql -U postgres -d foodstore -t -A -f modelo/exportar_pedidos.sql -o modelo/pedidos_export.json

# 3. Migrar a MongoDB y ejecutar las consultas
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
mongosh --file consultas_mongodb.js | Out-File -Encoding utf8 evidencias/mongo_migracion_y_consultas.txt

# 4. Consultas equivalentes en PostgreSQL
& $psql -U postgres -d foodstore -f consultas_postgresql.sql
```

- `exportar_pedidos.sql` solo lee. Exporta los ids de la lista `IN (1, 2, 3, 5, 6, 7, 8)`; el pedido 4 queda afuera
  porque esta dado de baja (`eliminado = TRUE`). Nunca se exporta `contrasena`, `celular` ni `rol`.
- `consultas_mongodb.js` es repetible: borra solo la coleccion `pedidos` de `foodstore_nosql` y la vuelve a crear.
  Si `require('fs')` falla en otra version de `mongosh`, se puede pegar el JSON en la constante `crudos`.
- Los pasos 2 y 3 se repiten cada vez que cambie la lista de ids.
- Para guardar evidencia con acentos en PowerShell 5.1 hay que usar `Out-File -Encoding utf8` y la consola en UTF-8:
  el operador `>` guarda en UTF-16.

## Modelo documental

Un documento por pedido (`_id` = `pedido.id`), con el cliente como objeto embebido y las lineas de detalle como arreglo
embebido con su **precio historico**. Se conservan `_id`, `cliente.usuario_id`, `lineas[].detalle_id` y
`lineas[].producto_id`. Importes como `Decimal128`, cantidades como `Int32`, `fecha` como `Date`. Las dos reglas de
integridad (total = suma de subtotales; lineas validas y vigentes) se refuerzan con un validador `$jsonSchema` y se
verifican despues de migrar. El detalle y la justificacion estan en `modelo/esquema_documental.md`.

## Resultados observados (2026-10-31)

| Consulta | PostgreSQL | MongoDB | Coinciden los ids |
|---|---|---|---|
| b) estado `PENDIENTE` | 4 pedidos: 3, 5, 7, 8 | 4 pedidos: 3, 5, 7, 8 | Si |
| c) producto 1 (Muzzarella) | 3 pedidos: 1, 7, 8 | 3 pedidos: 1, 7, 8 | Si |
| d) total > 10000.00 | no se pidio | 3 pedidos: 2, 5, 8 | - |

Migracion: `Insertados: 7`, `countDocuments: 7`; las dos verificaciones de integridad devuelven 0 documentos. El umbral
de d) (10000) queda por encima del promedio de los 7 totales (9200). Las consultas de PostgreSQL de Andres se ejecutaron en su
base `foodstore7` (PostgreSQL 16) y las de MongoDB sobre la migracion hecha desde la base de Mariano (PostgreSQL 17).

**Diferencia detectada y corregida:** en una primera comparacion no coincidian: PostgreSQL (con los pedidos de prueba 7 y
8) devolvia 4 y 3 pedidos, y MongoDB, migrado solo con los 5 pedidos de `data.sql`, devolvia 2 (ids 3, 5) y 1 (id 1). La
causa era que 7 y 8 no estaban migrados; se agregaron al export y se volvio a migrar. No se modificaron datos ni consultas.

Nota: `pedido.fecha` toma la fecha del dia en que se crea, asi que las fechas cambian segun el equipo (los pedidos 7 y 8
tienen 2026-10-31 en la migracion y 2026-10-30 en la base de Andres). No afecta la comparacion, que usa ids y cantidades.

El contraste de las afirmaciones de la IA y la conclusion estan en el informe y en `evidencias/contraste_ia.md`.

## Uso de IA

Mariano trabajo con Claude (migracion, consultas de MongoDB, informe); Andres, con OpenCode (consultas de PostgreSQL y
tabla de verificacion); Facundo, con Claude (consulta de la consigna 6; el prompt esta en `evidencias/respuesta_ia.md`). Todo se ejecuto antes de aceptarlo.
La ejecucion encontro un error que la lectura no habia visto: la primera tabla de verificacion decia que los resultados
coincidian (3 y 3 pedidos) sin haberla contrastado con las salidas guardadas, y la evidencia mostraba 4 y 3 en PostgreSQL
y 2 y 1 en MongoDB; se rehizo con los resultados reales de ambos motores. `BITACORA.md` y el informe lo detallan.
