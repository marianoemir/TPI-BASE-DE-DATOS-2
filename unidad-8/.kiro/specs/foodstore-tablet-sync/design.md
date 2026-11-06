# Documento de Diseño — Food Store · Base de la tablet y sincronización simulada

## Overview

La tablet del food truck opera sin conexión a Internet durante las ferias. Mantiene una base
**SQLite** con una copia local del catálogo y permite armar borradores de pedido sin conexión.
Cuando se recupera la señal, el vendedor importa una instantánea del servidor (archivo CSV
generado en PostgreSQL) y ejecuta un **semáforo local** que evalúa cada borrador pendiente
comparándolo contra esa instantánea.

**PostgreSQL es la única fuente de verdad** en precio, stock y ventas.
La tablet solo consulta y propone. `SIMULADO_APROBADO` no es una venta confirmada.

Todas las rutas de este documento son relativas a la **carpeta de trabajo** (donde se generan y
ejecutan los scripts de la tablet).

---

## Architecture

```
┌──────────────────────────────────────────────────────┐
│  SERVIDOR (oficina)                                   │
│  ┌──────────────────────────────────────────────┐    │
│  │  PostgreSQL                                   │    │
│  │  vista: v_snapshot_movil                      │    │
│  │  (producto_id, nombre, precio_centavos,       │    │
│  │   stock, disponible, eliminado, capturado_en) │    │
│  └───────────────────┬──────────────────────────┘    │
│                      │ \copy … TO 'servidor_snapshot.csv' CSV HEADER │
└──────────────────────┼───────────────────────────────┘
                       │  servidor_snapshot.csv
                       ▼  (misma máquina, simulación)
┌──────────────────────────────────────────────────────┐
│  TABLET — SQLite (foodstore_movil.db)                 │
│  ┌──────────────────────────────────────────────┐    │
│  │  snapshot_servidor  ← importar CSV            │    │
│  │  producto_cache     ← cargar_catalogo.sql     │    │
│  │  pedido_borrador  ─┐                          │    │
│  │  item_borrador    ─┴→ cola_sync               │    │
│  │                       semaforo.sql            │    │
│  └──────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────┘
```

No existe ninguna conexión directa entre SQLite y PostgreSQL.
La sincronización es unidireccional y simulada: el CSV se genera en PostgreSQL y se lee
desde SQLite en la misma máquina.

**Alcance de lo que se genera:** solo los scripts de SQLite de la tablet y su README. Los scripts de
PostgreSQL (`10_snapshot_catalogo.sql`, `11_exportar_snapshot.sql`, los casos `c2_subir_precio.sql` y
`c4_baja_logica.sql`, y `verificar_no_cambio.sql`) ya existen, no se regeneran y solo se ejecutan. El archivo
`servidor_snapshot.csv` es un insumo dado.

---

## Components and Interfaces

### 1. `snapshot_servidor` (tabla de staging)

Recibe el CSV exportado desde PostgreSQL tal como viene: los booleanos llegan como `t`/`f`.
Se vacía y se recarga en cada nueva instantánea. Sirve exclusivamente como paso intermedio
antes de actualizar `producto_cache`.

Interfaz: importación masiva desde el archivo CSV con el cliente `sqlite3`
(`.import --csv --skip 1 servidor_snapshot.csv snapshot_servidor`); sin lectura directa por el vendedor.

### 2. `cargar_catalogo.sql` (script de carga del catálogo)

Lee `snapshot_servidor` y actualiza `producto_cache` mediante un `UPSERT`
(`INSERT … ON CONFLICT … DO UPDATE`). No usa `INSERT OR REPLACE` ni `DELETE` para
preservar las claves foráneas de `item_borrador`.

Interfaz: ejecutado manualmente después de importar el CSV. Devuelve un resumen
(`fecha_de_la_copia`, `productos`).

### 3. `v_catalogo_disponible` (vista de consulta)

Filtra `producto_cache` mostrando solo productos con `eliminado = 0` y `disponible_visto = 1`.
Muestra el precio como `precio_centavos / 100.0`.
Es la única interfaz que usa el vendedor para ver el catálogo en pantalla.

### 4. `cola_sync` + `pedido_borrador` / `item_borrador`

El vendedor crea un borrador (`pedido_borrador` + ítems en `item_borrador`) y luego lo
encola en `cola_sync` con un UUID único de 36 caracteres. Un borrador puede tener
múltiples solicitudes a lo largo del tiempo (si el cliente acepta un precio nuevo), pero
nunca dos solicitudes en estado `PENDIENTE` al mismo tiempo (índice parcial único).

### 5. `semaforo.sql` (motor de evaluación)

Recorre todas las solicitudes en estado `PENDIENTE` y las clasifica consultando
`snapshot_servidor`. Escribe el resultado en `cola_sync.estado`, `cola_sync.motivo` y
`cola_sync.evaluada_en`. Solo actúa sobre `PENDIENTE`; volver a ejecutarlo no modifica
solicitudes ya evaluadas (C6). Termina con `SELECT changes() AS solicitudes_evaluadas;`, que debe ir
inmediatamente después del `UPDATE` y en la misma conexión.

### 6. Scripts de casos de prueba

Cada caso es un script SQL que arma sus propios datos, ejecuta y muestra el resultado esperado
(ver "Testing Strategy").

---

## Data Models

### `producto_cache`

| Columna            | Tipo    | Restricción                       | Notas                                   |
|--------------------|---------|-----------------------------------|-----------------------------------------|
| `producto_id`      | INTEGER | PRIMARY KEY                       | Mismo id que en PostgreSQL              |
| `nombre`           | TEXT    | NOT NULL                          |                                         |
| `precio_centavos`  | INTEGER | NOT NULL, ≥ 0                     | Precio en centavos (sin decimales)      |
| `stock_visto`      | INTEGER | NOT NULL, ≥ 0                     | Solo orientativo; no autoridad de stock |
| `disponible_visto` | INTEGER | NOT NULL, IN (0,1)                |                                         |
| `eliminado`        | INTEGER | NOT NULL DEFAULT 0, IN (0,1)      | **Lápida**: 1 = dado de baja            |
| `capturado_en`     | TEXT    | NOT NULL                          | Timestamp de la instantánea             |

### `pedido_borrador`

| Columna               | Tipo    | Restricción                                  |
|-----------------------|---------|----------------------------------------------|
| `id_local`            | TEXT    | PRIMARY KEY, length = 36 (UUID)              |
| `usuario_id_servidor` | INTEGER | NOT NULL, > 0                                |
| `forma_pago`          | TEXT    | NOT NULL, IN ('EFECTIVO','TARJETA','TRANSFERENCIA') |
| `creado_en`           | TEXT    | NOT NULL, DEFAULT timestamp UTC              |

### `item_borrador`

| Columna                  | Tipo    | Restricción                               |
|--------------------------|---------|-------------------------------------------|
| `id_local`               | TEXT    | FK → `pedido_borrador(id_local)` ON DELETE CASCADE |
| `producto_id`            | INTEGER | FK → `producto_cache(producto_id)`        |
| `cantidad`               | INTEGER | NOT NULL, > 0                             |
| `precio_centavos_visto`  | INTEGER | NOT NULL, ≥ 0                             |
| PK                       | —       | (`id_local`, `producto_id`)               |

### `cola_sync`

| Columna          | Tipo | Restricción                                                  |
|------------------|------|--------------------------------------------------------------|
| `solicitud_uuid` | TEXT | **PRIMARY KEY**, length = 36                                 |
| `id_local`       | TEXT | FK → `pedido_borrador(id_local)`                             |
| `estado`         | TEXT | NOT NULL DEFAULT 'PENDIENTE', IN ('PENDIENTE','CONFLICTO','RECHAZADO','SIMULADO_APROBADO') |
| `motivo`         | TEXT | NOT NULL si `estado` IN ('CONFLICTO','RECHAZADO') (`CHECK (estado NOT IN ('CONFLICTO','RECHAZADO') OR motivo IS NOT NULL)`) |
| `creada_en`      | TEXT | NOT NULL, DEFAULT timestamp UTC                              |
| `evaluada_en`    | TEXT | NULL hasta que el semáforo evalúa                            |

Índice parcial: `UNIQUE (id_local) WHERE estado = 'PENDIENTE'` (nombre `ux_cola_una_pendiente`) — impide dos
solicitudes pendientes para el mismo borrador. No hay `UNIQUE` simple sobre `id_local`.

### `snapshot_servidor` (staging)

| Columna          | Tipo | Restricción                              | Notas                              |
|------------------|------|------------------------------------------|------------------------------------|
| `producto_id`    | INTEGER | PRIMARY KEY                           | Id del producto en PostgreSQL      |
| `nombre`         | TEXT    | NOT NULL                              |                                    |
| `precio_centavos`| INTEGER | NOT NULL, ≥ 0                         | Precio en centavos                 |
| `stock`          | INTEGER | NOT NULL, ≥ 0                         | Autoridad de stock                 |
| `disponible`     | TEXT    | NOT NULL, IN ('t','f')                | Booleano PostgreSQL exportado      |
| `eliminado`      | TEXT    | NOT NULL, IN ('t','f')                | Booleano PostgreSQL exportado      |
| `capturado_en`   | TEXT    | NOT NULL                              | Timestamp de la exportación        |

Las cinco tablas son `STRICT`. Cada script empieza con `PRAGMA foreign_keys = ON;`.

---

## Proceso de carga del catálogo

1. El operador exporta el catálogo desde PostgreSQL con:
   ```sql
   \copy (SELECT * FROM v_snapshot_movil ORDER BY producto_id)
     TO 'servidor_snapshot.csv' CSV HEADER
   ```
2. Vacía `snapshot_servidor` (`DELETE FROM snapshot_servidor;`) e importa el CSV con
   `.import --csv --skip 1 servidor_snapshot.csv snapshot_servidor` (cliente `sqlite3`).
3. Ejecuta `cargar_catalogo.sql`, que hace:
   ```sql
   INSERT INTO producto_cache (…)
   SELECT … FROM snapshot_servidor
   ON CONFLICT (producto_id) DO UPDATE SET …
   ```
4. El UPSERT actualiza todas las columnas, incluyendo `eliminado`. Si el servidor marcó
   un producto con `eliminado = 't'`, la fila en `producto_cache` queda con `eliminado = 1`
   y deja de aparecer en `v_catalogo_disponible` — **nunca se hace DELETE** (Requisito 3, criterio 4).
   Mapeo: `disponible = 't'` → `disponible_visto = 1`; `stock` → `stock_visto`.

---

## Semáforo de sincronización

El semáforo (`semaforo.sql`) evalúa todas las solicitudes en estado `PENDIENTE` en una sola
pasada usando dos CTEs:

### `detalle`

`LEFT JOIN` entre `cola_sync`, `item_borrador` y `snapshot_servidor`. El LEFT JOIN
es clave: si un producto no existe en la instantánea, `s.*` queda en NULL y se detecta
explícitamente (de lo contrario pasaría como verde).

Para cada par (solicitud, ítem) se asigna un prefijo de color. Se evalúa en este orden y gana la
primera condición que se cumple, de modo que cada ítem aporta **una sola** causa:

| Orden | Condición                                         | Prefijo | Estado final   |
|-------|---------------------------------------------------|---------|----------------|
| 0     | `i.producto_id IS NULL` (borrador sin ítems)      | `R`     | RECHAZADO (F2-3) |
| 1     | `s.producto_id IS NULL`                           | `R`     | RECHAZADO (C4) |
| 2     | `s.eliminado = 't'`                               | `R`     | RECHAZADO (C4) |
| 3     | `s.disponible = 'f'`                              | `R`     | RECHAZADO (C4) |
| 4     | `i.cantidad > s.stock`                            | `R`     | RECHAZADO (C3) |
| 5     | `i.precio_centavos_visto ≠ s.precio_centavos`     | `A`     | CONFLICTO (C2) |
| 6     | Sin diferencia                                    | NULL    | verde          |

### `resumen`

Agrega por `solicitud_uuid` contando rojos y amarillos. Concatena, separados por `; `, todos los motivos del
mismo color.

### Prioridad de resultado

```
rojos > 0  →  RECHAZADO  (gana sobre todo; el motivo lleva solo los motivos rojos)
amarillos > 0  →  CONFLICTO
si no  →  SIMULADO_APROBADO  (motivo NULL)
```

Solo se actualizan las filas con `estado = 'PENDIENTE'`. Una segunda ejecución del
semáforo reporta `solicitudes_evaluadas = 0` (C6). El semáforo evalúa cada solicitud por separado: no suma
cantidades entre solicitudes ni modifica `producto_cache` ni `snapshot_servidor` (C8).

### Formato del campo `motivo`

Cada causa es un fragmento; los fragmentos de una misma solicitud se unen con `; `.

| Causa                    | Fragmento                                                       |
|--------------------------|-----------------------------------------------------------------|
| Conflicto de precio      | `<nombre>: borrador <centavos> centavos, servidor <centavos> centavos` |
| Stock insuficiente / cero| `<nombre>: pedido <cantidad>, stock <stock>`                    |
| Dado de baja             | `<nombre>: dado de baja`                                        |
| No disponible            | `<nombre>: no disponible`                                       |
| Inexistente              | `producto <id> no existe en el servidor`                        |
| Sin ítems                | `borrador sin ítems`                                            |

---

## Restricción de idempotencia (C6)

La columna `solicitud_uuid` es `PRIMARY KEY` en `cola_sync`. Intentar insertar un UUID
ya registrado falla con `UNIQUE constraint failed` antes de llegar al semáforo. La fila
original conserva su estado, motivo y `evaluada_en` sin modificación.

El índice parcial `ux_cola_una_pendiente` es complementario: permite reenviar un borrador
(nuevo UUID) solo cuando la solicitud anterior ya no está `PENDIENTE`.

---

## Competencia por stock entre borradores (C8)

El semáforo compara cada solicitud contra la instantánea, no contra las demás solicitudes. Por eso dos
borradores `PENDIENTE` que piden el mismo producto pueden quedar ambos en `SIMULADO_APROBADO` aunque juntos
superen el stock.

Escenario: Tiramisú (producto 11, stock 6 en la instantánea); el borrador A pide 4 y el borrador B pide 4, ambos
con el precio vigente. Resultado esperado tras ejecutar el semáforo: A y B en `SIMULADO_APROBADO`, `motivo`
NULL, `stock_visto` sin cambios y la huella de PostgreSQL igual antes y después.

El caso debe incluir, como comentario del script, la resolución real: solo el servidor decide, con
`sp_crear_pedido` y `SELECT … FOR UPDATE`; la primera solicitud que llegue se acepta y la segunda se rechaza por
stock insuficiente. El resultado no depende del orden de encolado ni de evaluación.

---

## Datos de prueba

Los datos salen de `servidor_snapshot.csv` (16 productos, datos inventados). Los UUID de los casos siguen el
patrón `<caso>…-0000-4000-8000-00000000000<x>` (36 caracteres):

| Caso | UUID de la solicitud                              | Resultado esperado |
|------|---------------------------------------------------|--------------------|
| C2   | `c2000000-0000-4000-8000-00000000000b`            | CONFLICTO (producto 1, subió el precio) |
| C2 (reenvío tras aceptar el precio) | `c2000000-0000-4000-8000-00000000000c` | SIMULADO_APROBADO |
| C3   | `c3000000-0000-4000-8000-00000000000b`            | RECHAZADO (cantidad mayor que el stock) |
| C4   | `c4000000-0000-4000-8000-00000000000b`            | RECHAZADO (producto 3, dado de baja) |
| C5   | `c5000000-0000-4000-8000-00000000000b`            | SIMULADO_APROBADO (control); su reenvío falla por UUID duplicado (C6) |
| C8   | `c8000000-0000-4000-8000-00000000000a` y `…0b`    | ambas SIMULADO_APROBADO |
| F2-k | `f200000k-0000-4000-8000-00000000000b` (k = 1 a 6)| ver Requisito 9 y 7 |

Secuencia de datos del servidor: **instantánea 1** (estado inicial; 16 productos) → se crean los borradores
con los precios de esa instantánea → se ejecutan en PostgreSQL `c2_subir_precio.sql` (sube el precio del
producto 1) y `c4_baja_logica.sql` (baja el producto 3) → se exporta la **instantánea 2** y se recarga el
catálogo (lápida) → recién entonces corre el semáforo.

---

## Error Handling

| Situación                                                      | Respuesta del sistema                                                              |
|----------------------------------------------------------------|------------------------------------------------------------------------------------|
| CSV con booleanos `0`/`1` en lugar de `t`/`f`                 | `CHECK (disponible IN ('t','f'))` rechaza la fila en staging; `producto_cache` no se modifica |
| `precio_centavos` negativo en el CSV                          | `CHECK (precio_centavos >= 0)` rechaza la fila en staging                          |
| Insertar `item_borrador` con `producto_id` inexistente en `producto_cache` | FK violation; el INSERT falla y el script hace ROLLBACK              |
| Insertar `item_borrador` con cantidad 0                        | `CHECK (cantidad > 0)` falla y el script hace ROLLBACK                             |
| Valor de tipo incorrecto en columna `STRICT`                   | La tabla `STRICT` rechaza el INSERT y el script hace ROLLBACK                      |
| Insertar segunda solicitud `PENDIENTE` para el mismo borrador  | Índice parcial único — error `UNIQUE constraint failed`                            |
| Reenvío de UUID duplicado                                      | PK violation — la fila original no se modifica (C6)                               |
| Borrador sin ítems encolado                                    | El semáforo detecta `i.producto_id IS NULL` y lo marca `RECHAZADO` con motivo `borrador sin ítems` |

---

## Entregables y orden de ejecución

Entregables (SQLite, en la carpeta de trabajo): `schema_sqlite.sql`, `cargar_catalogo.sql`, `semaforo.sql`,
`pruebas_sqlite.sql`, `casos_c2_c5_borradores.sql`, `casos_c2_c6_resolucion.sql`, `casos_f2_semaforo.sql`,
`casos_c8_competencia_stock.sql` y `README.md` (orden y resultados esperados).

Orden de ejecución, siempre sobre una base nueva (`foodstore_movil.db`):

1. `schema_sqlite.sql` → crea tablas `STRICT`, índice parcial y vista.
2. Importar el CSV (instantánea 1) y `cargar_catalogo.sql`.
3. `pruebas_sqlite.sql` → COMMIT/ROLLBACK, C1 y C7.
4. `casos_c2_c5_borradores.sql` → borradores y solicitudes C2 a C5 (en `PENDIENTE`).
5. En PostgreSQL: casos C2 y C4; exportar la instantánea 2.
6. Vaciar `snapshot_servidor`, importar la instantánea 2 y `cargar_catalogo.sql` (recarga con lápida).
7. `semaforo.sql` (primera corrida).
8. `casos_c2_c6_resolucion.sql` → reenvío C2 y UUID duplicado C6; `semaforo.sql` (segunda y tercera corrida).
9. `casos_f2_semaforo.sql` → F2-1 a F2-6.
10. `casos_c8_competencia_stock.sql` → C8.
11. `verificar_no_cambio.sql` en PostgreSQL, antes de empezar y al terminar, con la misma huella.

---

## Testing Strategy

Los casos de prueba son scripts SQL que se ejecutan directamente contra `foodstore_movil.db`
y contra PostgreSQL (solo lectura):

| Script                                   | Motor      | Qué verifica                                                        | Requisitos |
|------------------------------------------|------------|---------------------------------------------------------------------|------------|
| `schema_sqlite.sql`                      | SQLite     | Tablas `STRICT`, centavos, restricciones, índice parcial, vista     | 5, 6, 7    |
| `cargar_catalogo.sql`                    | SQLite     | Carga de `producto_cache` desde la instantánea; recarga con lápida (C4) | 3.4, 8 |
| `pruebas_sqlite.sql`                     | SQLite     | COMMIT y ROLLBACK; C1 (catálogo sin servidor); C7 (cantidad 0, producto inexistente, tipo inválido) | 5, 6 |
| `casos_c2_c5_borradores.sql`             | SQLite     | C2–C5: creación de borradores y encolado en `cola_sync`             | 1, 2, 3    |
| `semaforo.sql`                           | SQLite     | C2–C5: estados CONFLICTO, RECHAZADO, SIMULADO_APROBADO              | 1, 2, 3, 9 |
| `casos_c2_c6_resolucion.sql`             | SQLite     | C2 (resolución) y C6: nueva solicitud tras CONFLICTO; UUID duplicado; semáforo repetido | 1.3, 4, 7 |
| `casos_f2_semaforo.sql`                  | SQLite     | F2-1 a F2-6: el rojo gana, producto inexistente, sin ítems, no disponible, control, una sola pendiente | 7, 9 |
| `casos_c8_competencia_stock.sql`         | SQLite     | C8: dos borradores compiten por el mismo stock y ambos quedan aprobados | 10 |
| `postgresql/verificar_no_cambio.sql`     | PostgreSQL | Ninguna tabla del servidor se modificó (6 pedidos, 13 detalles, stock 454, misma huella) | 2.2, 8.6, 10.5 |

Cada script se ejecuta en orden y su salida completa se guarda como evidencia numerada. Se verifica que los
estados y motivos en `cola_sync` coincidan con los esperados por los requisitos.
