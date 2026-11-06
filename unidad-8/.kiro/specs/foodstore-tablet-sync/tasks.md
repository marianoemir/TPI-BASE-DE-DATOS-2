# Implementation Plan: Food Store · Base de la tablet y sincronización simulada

## Overview

Todos los entregables de este proyecto son scripts SQL (SQLite y PostgreSQL).
No hay código de aplicación. Las tareas consisten en verificar que cada script cumple
exactamente con los requisitos, completar cualquier parte que falte y dejar evidencia
de ejecución correcta en `evidencias/`.

El estado de cada tarea refleja la situación actual del repositorio: los scripts
existen y las evidencias registradas en `evidencias/` confirman ejecuciones exitosas.

---

## Tasks

- [x] 1. Esquema SQLite de la tablet
  - [x] 1.1 Verificar `movil/schema_sqlite.sql`: tablas STRICT, índice parcial y vista
    - Confirmar que las cuatro tablas (`producto_cache`, `pedido_borrador`,
      `item_borrador`, `cola_sync`) están en modo `STRICT`.
    - Confirmar que `cola_sync` tiene el índice parcial `ux_cola_una_pendiente`
      (`UNIQUE (id_local) WHERE estado = 'PENDIENTE'`), no un UNIQUE simple.
    - Confirmar que `v_catalogo_disponible` filtra `eliminado = 0` y `disponible_visto = 1`.
    - Confirmar que `snapshot_servidor` recibe `disponible` y `eliminado` como `TEXT IN ('t','f')`.
    - _Requisitos: 1.1, 2.1, 3.4, 4.1_

  - [x] 1.2 Verificar `movil/pruebas_sqlite.sql`: transacciones, C1 y C7
    - Confirmar que el bloque COMMIT persiste las filas (pedido + ítems + solicitud de Ana).
    - Confirmar que el bloque ROLLBACK no deja filas nuevas.
    - Confirmar que C1 devuelve el catálogo disponible sin tocar PostgreSQL.
    - Confirmar que C7 produce exactamente tres errores esperados (CHECK cantidad, FK
      producto inexistente, STRICT tipo) y no deja filas nuevas.
    - Cotejar con `evidencias/02_schema.txt` y `evidencias/04_pruebas_1c.txt`.
    - _Requisitos: 1.1, 3.4_

- [x] 2. Carga del catálogo desde la instantánea del servidor

  - [x] 2.1 Verificar `postgresql/10_snapshot_catalogo.sql`: vista `v_snapshot_movil`
    - Confirmar que `precio_centavos` se calcula como `(precio * 100)::INTEGER`.
    - Confirmar que `eliminado` combina la baja del producto y la de su categoría.
    - Confirmar que el `COMMENT ON VIEW` está presente.
    - _Requisitos: 3.4_

  - [x] 2.2 Verificar `postgresql/11_exportar_snapshot.sql`: exportación CSV
    - Confirmar que el comando `\copy` escribe en `movil/servidor_snapshot.csv`
      con encabezado y desde la raíz del repo.
    - Confirmar la existencia del archivo `movil/servidor_snapshot.csv` en el repo.
    - _Requisitos: 1.1_

  - [x] 2.3 Verificar `movil/cargar_catalogo.sql`: UPSERT en `producto_cache`
    - Confirmar que usa `INSERT … ON CONFLICT (producto_id) DO UPDATE` y **no**
      `INSERT OR REPLACE` ni `DELETE`.
    - Confirmar que actualiza todas las columnas, incluido `eliminado`.
    - Confirmar que la consulta final devuelve `fecha_de_la_copia` y `productos`.
    - Cotejar con `evidencias/03_cargar_catalogo.txt`.
    - _Requisitos: 3.4_

- [x] 3. Checkpoint — base de datos de la tablet funcionando
  - Ejecutar el flujo de creación desde cero (pasos 1-4 del README) y
    verificar que no hay errores no esperados. Preguntar al equipo si surgen dudas.

- [x] 4. Casos del servidor previos a la sincronización (PostgreSQL)

  - [x] 4.1 Verificar `postgresql/casos/c2_subir_precio.sql`: subida de precio C2
    - Confirmar que el UPDATE modifica únicamente `precio` del producto 1 (Muzzarella)
      y no toca stock, disponibilidad ni pedidos.
    - _Requisitos: 1.1_

  - [x] 4.2 Verificar `postgresql/casos/c4_baja_logica.sql`: baja lógica C4
    - Confirmar que el UPDATE usa `eliminado = TRUE WHERE id = 3 AND eliminado = FALSE`.
    - Confirmar que no hay `DELETE`.
    - _Requisitos: 3.1, 3.4_

- [x] 5. Semáforo de sincronización

  - [x] 5.1 Verificar `movil/semaforo.sql`: lógica de evaluación
    - Confirmar `LEFT JOIN` entre `cola_sync`, `item_borrador` y `snapshot_servidor`
      (no INNER JOIN; si el producto no existe en la instantánea, `s.*` queda NULL).
    - Confirmar que NULL en `s.producto_id` genera prefijo `R` (RECHAZADO),
      no pasa como verde.
    - Confirmar prioridad: rojo gana sobre amarillo (`rojos > 0 → RECHAZADO`).
    - Confirmar que el UPDATE tiene `WHERE cola_sync.estado = 'PENDIENTE'` para que
      las solicitudes ya evaluadas no cambien (C6).
    - Confirmar que `changes()` reporta el número de solicitudes efectivamente evaluadas.
    - _Requisitos: 1.1, 2.1, 3.1, 3.2, 3.3, 4.1_

  - [x] 5.2 Verificar casos C2 a C5 — estados esperados del semáforo (primera corrida)
    - C2 (`c2000000…000b`): estado `CONFLICTO`; motivo contiene nombre del producto,
      precio antiguo y precio nuevo en centavos. _Requisito 1.1_
    - C3 (`c3000000…000b`): estado `RECHAZADO`; motivo contiene nombre, cantidad
      pedida y stock disponible. _Requisito 2.1_
    - C4 (`c4000000…000b`): estado `RECHAZADO`; motivo indica `dado de baja`.
      _Requisito 3.1_
    - C5 (`c5000000…000b`): estado `SIMULADO_APROBADO`; motivo NULL. _Requisito 1.1_
    - Cotejar con `evidencias/08_semaforo_1.txt`.
    - _Requisitos: 1.1, 1.2, 2.1, 2.3, 3.1, 3.3_

- [x] 6. Resolución C2 y control de duplicados C6

  - [x] 6.1 Verificar `movil/casos_c2_c6_resolucion.sql`: nueva solicitud C2
    - Confirmar que el UPDATE de `item_borrador` lee el precio desde `producto_cache`
      (no lo escribe a mano).
    - Confirmar que la nueva solicitud usa UUID `c2000000-0000-4000-8000-00000000000c`
      (distinto del anterior, que sigue en CONFLICTO).
    - Confirmar que el índice parcial `ux_cola_una_pendiente` lo permite porque
      la solicitud anterior ya no está PENDIENTE.
    - Cotejar con `evidencias/09_c2_acepta_c6.txt`.
    - _Requisitos: 1.3, 4.1_

  - [x] 6.2 Verificar control de UUID duplicado (C6)
    - Confirmar que el intento de reinsertar `c5000000…000b` falla con
      `UNIQUE constraint failed: cola_sync.solicitud_uuid`.
    - Confirmar que la fila original conserva `SIMULADO_APROBADO` y su `evaluada_en`.
    - _Requisitos: 4.1, 4.2, 4.3_

  - [x] 6.3 Verificar semáforo segunda y tercera corrida
    - Segunda corrida: evalúa exactamente 1 solicitud (`c2000000…000c` → `SIMULADO_APROBADO`).
    - Tercera corrida (repetida): `solicitudes_evaluadas = 0`.
    - Cotejar con `evidencias/10_semaforo_2.txt` y `evidencias/11_semaforo_3_repetido.txt`.
    - _Requisitos: 4.3_

- [x] 7. Verificación de integridad en PostgreSQL

  - [x] 7.1 Verificar `postgresql/verificar_no_cambio.sql`: lectura sin escritura
    - Confirmar que el script solo ejecuta `SELECT` (sin UPDATE, INSERT ni DELETE).
    - Confirmar que `pedidos`, `detalles`, `stock_total` y `huella_stock` son
      idénticos en `evidencias/01_pg_antes.txt` y `evidencias/12_pg_despues.txt`.
    - Valor esperado: 6 pedidos, 13 detalles, stock_total 454,
      huella `89f8351d0162e23ef1473f32b05ce221`.
    - _Requisitos: 2.2, 3.6_

- [x] 8. Checkpoint final — todos los casos correctos
  - Revisar que las 12 evidencias (`evidencias/01_pg_antes.txt` a `12_pg_despues.txt`)
    corresponden a los pasos del README en orden y que los resultados coinciden con la
    tabla de «Resultados esperados».
  - Verificar que `foodstore_movil.db` está en el repo (no en `.gitignore`).
  - Preguntar al equipo si hay dudas antes de la entrega.

---

## Notas

- Las tareas marcadas con `[x]` están completas: el script existe y la evidencia en
  `evidencias/` confirma ejecución exitosa.
- Ninguna tarea requiere modificar PostgreSQL de producción; todo se trabaja sobre
  `foodstore_u8` (base de pruebas con datos inventados).
- No hay tareas de despliegue ni de interfaz de usuario: el proyecto es íntegramente SQL.
- El semáforo **no** confirma ventas; `SIMULADO_APROBADO` es solo una señal local.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "2.1"] },
    { "id": 1, "tasks": ["1.2", "2.2", "2.3"] },
    { "id": 2, "tasks": ["4.1", "4.2"] },
    { "id": 3, "tasks": ["5.1"] },
    { "id": 4, "tasks": ["5.2", "6.1"] },
    { "id": 5, "tasks": ["6.2", "6.3"] },
    { "id": 6, "tasks": ["7.1"] }
  ]
}
```
