# Documento de Diseño — Food Store · Base de la tablet y sincronización simulada

## Overview

La tablet del food truck opera sin conexión a Internet durante las ferias. Mantiene una base
**SQLite** con una copia local del catálogo y permite armar borradores de pedido sin conexión.
Cuando se recupera la señal, el vendedor importa una instantánea del servidor (archivo CSV
generado en PostgreSQL) y ejecuta un **semáforo local** que evalúa cada borrador pendiente
comparándolo contra esa instantánea.

**PostgreSQL es la única fuente de verdad** en precio, stock y ventas.
La tablet solo consulta y propone. `SIMULADO_APROBADO` no es una venta confirmada.

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│  SERVIDOR (oficina)                                  │
│  ┌─────────────────────────────────────────────┐    │
│  │  PostgreSQL                                  │    │
│  │  vista: v_snapshot_movil                     │    │
│  │  (producto_id, nombre, precio_centavos,      │    │
│  │   stock, disponible, eliminado, capturado_en)│    │
│  └──────────────────┬──────────────────────────┘    │
│                     │ \copy … TO 'movil/servidor_snapshot.csv' CSV HEADER  │
└─────────────────────┼───────────────────────────────┘
                      │  servidor_snapshot.csv
                      ▼  (misma máquina, simulación)
┌─────────────────────────────────────────────────────┐
│  TABLET — SQLite (foodstore_movil.db)                │
│  ┌─────────────────────────────────────────────┐    │
│  │  snapshot_servidor  ← importar CSV           │    │
│  │  producto_cache     ← cargar_catalogo.sql    │    │
│  │  pedido_borrador  ─┐                         │    │
│  │  item_borrador    ─┴→ cola_sync              │    │
│  │                       semaforo.sql           │    │
│  └─────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────┘
```

No existe ninguna conexión directa entre SQLite y PostgreSQL.
La sincronización es unidireccional y simulada: el CSV se genera en PostgreSQL y se lee
desde SQLite en la misma máquina.

---

## Components and Interfaces

### 1. `snapshot_servidor` (tabla de staging)

Recibe el CSV exportado desde PostgreSQL tal como viene: los booleanos llegan como `t`/`f`.
Se vacía y se recarga en cada nueva instantánea. Sirve exclusivamente como paso intermedio
antes de actualizar `producto_cache`.

Interfaz: `INSERT` masivo desde el archivo CSV; sin lectura directa por el vendedor.

### 2. `cargar_catalogo.sql` (script de carga del catálogo)

Lee `snapshot_servidor` y actualiza `producto_cache` mediante un `UPSERT`
(`INSERT … ON CONFLICT … DO UPDATE`). No usa `INSERT OR REPLACE` ni `DELETE` para
preservar las claves foráneas de `item_borrador`.

Interfaz: ejecutado manualmente después de importar el CSV. Devuelve un resumen
(`fecha_de_la_copia`, `productos`).

### 3. `v_catalogo_disponible` (vista de consulta)

Filtra `producto_cache` mostrando solo productos con `eliminado = 0` y `disponible_visto = 1`.
Es la única interfaz que usa el vendedor para ver el catálogo en pantalla.

### 4. `cola_sync` + `pedido_borrador` / `item_borrador`

El vendedor crea un borrador (`pedido_borrador` + ítems en `item_borrador`) y luego lo
encola en `cola_sync` con un UUID único de 36 caracteres. Un borrador puede tener
múltiples solicitudes a lo largo del tiempo (si el cliente acepta un precio nuevo), pero
nunca dos solicitudes en estado `PENDIENTE` al mismo tiempo (índice parcial único).

### 5. `semaforo.sql` (motor de evaluación)

Recorre todas las solicitudes en estado `PENDIENTE` y las clasifica consultando
`snapshot_servidor`. Escribe el resultado en `cola_sync.estado` y `cola_sync.motivo`.
Solo actúa sobre `PENDIENTE`; volver a ejecutarlo no modifica solicitudes ya evaluadas (C6).

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
| `motivo`         | TEXT | NOT NULL si `estado` IN ('CONFLICTO','RECHAZADO')            |
| `creada_en`      | TEXT | NOT NULL, DEFAULT timestamp UTC                              |
| `evaluada_en`    | TEXT | NULL hasta que el semáforo evalúa                            |

Índice parcial: `UNIQUE (id_local) WHERE estado = 'PENDIENTE'` — impide dos solicitudes
pendientes para el mismo borrador.

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

---

## Proceso de carga del catálogo

1. El operador exporta el catálogo desde PostgreSQL con:
   ```sql
   \copy (SELECT * FROM v_snapshot_movil ORDER BY producto_id)
     TO 'movil/servidor_snapshot.csv' CSV HEADER
   ```
2. Importa el CSV a `snapshot_servidor` (tabla de staging) en SQLite.
3. Ejecuta `cargar_catalogo.sql`, que hace:
   ```sql
   INSERT INTO producto_cache (…)
   SELECT … FROM snapshot_servidor
   ON CONFLICT (producto_id) DO UPDATE SET …
   ```
4. El UPSERT actualiza todas las columnas, incluyendo `eliminado`. Si el servidor marcó
   un producto con `eliminado = 't'`, la fila en `producto_cache` queda con `eliminado = 1`
   y deja de aparecer en `v_catalogo_disponible` — **nunca se hace DELETE** (Requisito 3, criterio 4).

---

## Semáforo de sincronización

El semáforo (`semaforo.sql`) evalúa todas las solicitudes en estado `PENDIENTE` en una sola
pasada usando dos CTEs:

### `detalle`

`LEFT JOIN` entre `cola_sync`, `item_borrador` y `snapshot_servidor`. El LEFT JOIN
es clave: si un producto no existe en la instantánea, `s.*` queda en NULL y se detecta
explícitamente (de lo contrario pasaría como verde).

Para cada par (solicitud, ítem) se asigna un prefijo de color:

| Condición                                         | Prefijo | Estado final   |
|---------------------------------------------------|---------|----------------|
| `s.producto_id IS NULL`                           | `R`     | RECHAZADO (C4) |
| `s.eliminado = 't'`                               | `R`     | RECHAZADO (C4) |
| `s.disponible = 'f'`                              | `R`     | RECHAZADO (C4) |
| `i.cantidad > s.stock`                            | `R`     | RECHAZADO (C3) |
| `i.precio_centavos_visto ≠ s.precio_centavos`     | `A`     | CONFLICTO (C2) |
| Sin diferencia                                    | NULL    | verde          |

### `resumen`

Agrega por `solicitud_uuid` contando rojos y amarillos. Concatena todos los motivos del
mismo color.

### Prioridad de resultado

```
rojos > 0  →  RECHAZADO  (gana sobre todo)
amarillos > 0  →  CONFLICTO
si no  →  SIMULADO_APROBADO
```

Solo se actualizan las filas con `estado = 'PENDIENTE'`. Una segunda ejecución del
semáforo reporta `solicitudes_evaluadas = 0` (C6).

---

## Restricción de idempotencia (C6)

La columna `solicitud_uuid` es `PRIMARY KEY` en `cola_sync`. Intentar insertar un UUID
ya registrado falla con `UNIQUE constraint failed` antes de llegar al semáforo. La fila
original conserva su estado, motivo y `evaluada_en` sin modificación.

El índice parcial `ux_cola_una_pendiente` es complementario: permite reenviar un borrador
(nuevo UUID) solo cuando la solicitud anterior ya no está `PENDIENTE`.

---

## Error Handling

| Situación                                                      | Respuesta del sistema                                                              |
|----------------------------------------------------------------|------------------------------------------------------------------------------------|
| CSV con booleanos `0`/`1` en lugar de `t`/`f`                 | `CHECK (disponible IN ('t','f'))` rechaza la fila en staging; `producto_cache` no se modifica |
| `precio_centavos` negativo en el CSV                          | `CHECK (precio_centavos >= 0)` rechaza la fila en staging                          |
| Insertar `item_borrador` con `producto_id` inexistente en `producto_cache` | FK violation; el INSERT falla y el script hace ROLLBACK              |
| Insertar segunda solicitud `PENDIENTE` para el mismo borrador  | Índice parcial único — error `UNIQUE constraint failed`                            |
| Reenvío de UUID duplicado                                      | PK violation — la fila original no se modifica (C6)                               |
| Borrador sin ítems encolado                                    | El semáforo detecta `i.producto_id IS NULL` y lo marca `RECHAZADO` con motivo `borrador sin ítems` |

---

## Testing Strategy

Los casos de prueba son scripts SQL que se ejecutan directamente contra `foodstore_movil.db`
y contra PostgreSQL:

| Script                                   | Motor      | Qué verifica                                                        |
|------------------------------------------|------------|---------------------------------------------------------------------|
| `movil/cargar_catalogo.sql`              | SQLite     | 2.a: carga de `producto_cache` desde la instantánea; recarga con lápida (C4) |
| `movil/pruebas_sqlite.sql`               | SQLite     | COMMIT y ROLLBACK; C1 (catálogo sin servidor); C7 (cantidad 0, producto inexistente, tipo inválido) |
| `movil/casos_c2_c5_borradores.sql`       | SQLite     | C2–C5: creación de borradores y encolado en `cola_sync`             |
| `movil/semaforo.sql`                     | SQLite     | C2–C5: evaluación del semáforo; estados CONFLICTO, RECHAZADO, SIMULADO_APROBADO |
| `movil/casos_c2_c6_resolucion.sql`       | SQLite     | C2 (resolución) y C6: nueva solicitud tras CONFLICTO; reenvío de UUID duplicado |
| `postgresql/verificar_no_cambio.sql`     | PostgreSQL | Verifica que ninguna tabla del servidor fue modificada durante la simulación |

Cada script se ejecuta en orden y se verifica visualmente que los estados y motivos en
`cola_sync` coincidan con los esperados por los requisitos.
