# Implementation Plan: Food Store · Base de la tablet y sincronización simulada

## Overview

Todos los entregables son scripts SQL (SQLite y, del lado del servidor, PostgreSQL de solo lectura).
No hay código de aplicación.

Este plan es para **generar** los scripts de la tablet con OpenCode a partir de `requirements.md` y
`design.md`, en una carpeta limpia (`unidad-8/movil_opencode/`), y luego probarlos y dejar evidencia.
OpenCode recibe solo `AGENTS.md` y esta spec; no se le pasa el contenido de `unidad-8/movil/`.

Reglas (de `AGENTS.md`): nada generado se ejecuta sin leerlo línea por línea, siempre sobre una copia de
la base o dentro de una transacción reversible, y nunca con datos reales. PostgreSQL es de solo lectura
(`foodstore_u8`, datos inventados). Por cada corrida se guardan el modelo, la fecha, el prompt y la respuesta
cruda, y qué se aceptó, corrigió o descartó.

**Versión mínima primero:** tareas 1 a 3 y 5 (esquema, carga y semáforo). Después el resto.

Todas las tareas están pendientes (`[ ]`).

---

## Tasks

- [ ] 0. Preparación
  - [ ] 0.1 Crear la rama `m/obj-11` y la carpeta `unidad-8/movil_opencode/` vacía.
    - Hacer commit de esta spec con fecha **antes** de generar nada.
  - [ ] 0.2 Verificar `sqlite3 --version` ≥ 3.37 (necesario para `STRICT`).
  - [ ] 0.3 Copiar a la carpeta de trabajo el insumo `servidor_snapshot.csv` (instantánea 1).
  - [ ] 0.4 Correr `postgresql/verificar_no_cambio.sql` y guardar la salida como evidencia `22_pg_antes.txt`.
    - Valor esperado: 6 pedidos, 13 detalles, stock_total 454, huella `89f8351d0162e23ef1473f32b05ce221`.
    - _Requisitos: 8.6, 10.5_

- [ ] 1. Esquema SQLite de la tablet
  - [ ] 1.1 Generar `schema_sqlite.sql`: tablas `STRICT`, índice parcial, vista y `snapshot_servidor`
    - Las cinco tablas (`producto_cache`, `pedido_borrador`, `item_borrador`, `cola_sync`,
      `snapshot_servidor`) en modo `STRICT`, con importes en centavos y `PRAGMA foreign_keys = ON;` al inicio.
    - `cola_sync` con el índice parcial `ux_cola_una_pendiente` (`UNIQUE (id_local) WHERE estado = 'PENDIENTE'`),
      sin `UNIQUE` simple sobre `id_local`, y con el `CHECK` de `motivo` según el diseño.
    - `v_catalogo_disponible` filtra `eliminado = 0` y `disponible_visto = 1`, y muestra el precio como
      `precio_centavos / 100.0`.
    - `snapshot_servidor` recibe `disponible` y `eliminado` como `TEXT IN ('t','f')`.
    - _Requisitos: 5.1, 5.2, 6.1 a 6.6, 6.11, 7.1, 7.3, 8.2_
  - [ ] 1.2 Leer línea por línea y ejecutar sobre una base nueva; guardar `23_schema.txt`.

- [ ] 2. Carga del catálogo desde la instantánea
  - [ ] 2.1 Generar `cargar_catalogo.sql`: UPSERT en `producto_cache`
    - Usa `INSERT … ON CONFLICT (producto_id) DO UPDATE` y **no** `INSERT OR REPLACE` ni `DELETE`.
    - Actualiza todas las columnas, incluido `eliminado`; mapea `t` → 1 y `f` → 0.
    - La consulta final devuelve `fecha_de_la_copia` y `productos`.
    - _Requisitos: 3.4, 8.1, 8.3, 8.4, 8.5_
  - [ ] 2.2 Importar la instantánea 1 con `.import --csv --skip 1 servidor_snapshot.csv snapshot_servidor`,
    ejecutar `cargar_catalogo.sql` y guardar `24_cargar_catalogo.txt`. Esperado: 16 productos.
  - [ ] 2.3 Probar el rechazo de filas inválidas en `snapshot_servidor` (booleanos `0`/`1`, precio o stock
    negativos) en una copia y guardar el resultado. _Requisito 8.2_

- [ ] 3. Pruebas del esquema: COMMIT/ROLLBACK, C1 y C7
  - [ ] 3.1 Generar `pruebas_sqlite.sql`
    - El bloque `COMMIT` persiste pedido, ítems y solicitud; el bloque `ROLLBACK` no deja filas nuevas.
    - C1: `v_catalogo_disponible` devuelve 14 de 16 productos cuando 15 y 16 no están disponibles o están
      dados de baja, sin tocar PostgreSQL.
    - C7: exactamente tres errores esperados (`CHECK` de cantidad 0, `FOREIGN KEY` de producto inexistente,
      tipo inválido en columna `STRICT`) y los conteos sin cambios.
    - _Requisitos: 5.1, 5.3, 6.7 a 6.10_
  - [ ] 3.2 Ejecutar y guardar `25_pruebas_1c.txt`.

- [ ] 4. Borradores y solicitudes C2 a C5
  - [ ] 4.1 Generar `casos_c2_c5_borradores.sql`: crear un borrador y una solicitud `PENDIENTE` por caso, con
    los UUID de la tabla "Datos de prueba" del diseño y los precios de la instantánea 1.
    - C2: producto 1 con el precio de la instantánea 1. C3: cantidad mayor que el stock de un producto activo.
    - C4: producto 3. C5: control sin diferencias.
    - Elegir los productos y cantidades de C3 y C5 a partir del CSV y dejar la elección documentada
      en un comentario.
    - _Requisitos: 1, 2, 3, 7_
  - [ ] 4.2 Ejecutar y guardar `26_borradores_c2_c5.txt`.
  - [ ] 4.3 En PostgreSQL, ejecutar `casos/c2_subir_precio.sql` y `casos/c4_baja_logica.sql` (existentes).
    Exportar la instantánea 2 con `11_exportar_snapshot.sql`, vaciar `snapshot_servidor`, importarla y volver a
    correr `cargar_catalogo.sql`. Guardar `27_recarga_con_lapida.txt`. Esperado: el producto 3 con
    `eliminado = 1` y fuera de `v_catalogo_disponible`. _Requisitos: 3.4, 8.3, 8.4_

- [ ] 5. Semáforo de sincronización
  - [ ] 5.1 Generar `semaforo.sql`: lógica de evaluación
    - `LEFT JOIN` entre `cola_sync`, `item_borrador` y `snapshot_servidor` (no `INNER JOIN`).
    - Orden de causas rojas y amarilla según la tabla del diseño; una sola causa por ítem.
    - Prioridad: rojo gana sobre amarillo; sin rojos ni amarillos → `SIMULADO_APROBADO` con `motivo` NULL.
    - El `UPDATE` tiene `WHERE cola_sync.estado = 'PENDIENTE'`, registra `evaluada_en` y el formato de `motivo`
      del diseño.
    - Termina con `SELECT changes() AS solicitudes_evaluadas;` pegado al `UPDATE`.
    - No modifica `producto_cache` ni `snapshot_servidor`.
    - _Requisitos: 1, 2, 3, 9.1 a 9.7_
  - [ ] 5.2 Ejecutar la primera corrida y guardar `28_semaforo_1.txt`. Esperado:
    - C2 → `CONFLICTO`, con nombre y los dos precios en centavos.
    - C3 → `RECHAZADO`, con nombre, cantidad pedida y stock.
    - C4 → `RECHAZADO`, `dado de baja`.
    - C5 → `SIMULADO_APROBADO`, `motivo` NULL.
    - `solicitudes_evaluadas = 4`.

- [ ] 6. Resolución de C2 y control de duplicados C6
  - [ ] 6.1 Generar `casos_c2_c6_resolucion.sql`
    - El borrador de C2 toma el precio nuevo desde `producto_cache` (no se escribe a mano) y se encola con el
      UUID `c2000000-0000-4000-8000-00000000000c`; el índice parcial lo permite porque la solicitud anterior
      ya no está `PENDIENTE`.
    - C6: reinsertar `c5000000-0000-4000-8000-00000000000b` falla con
      `UNIQUE constraint failed: cola_sync.solicitud_uuid` y la fila original conserva su estado, motivo y
      `evaluada_en`.
    - _Requisitos: 1.3, 4.1, 4.2, 4.4, 7.2_
  - [ ] 6.2 Ejecutar y guardar `29_c2_acepta_c6.txt`.
  - [ ] 6.3 Segunda corrida del semáforo: evalúa exactamente 1 solicitud (`…000c` → `SIMULADO_APROBADO`).
    Guardar `30_semaforo_2.txt`. Tercera corrida: `solicitudes_evaluadas = 0`. Guardar `31_semaforo_3.txt`.
    _Requisitos: 4.3, 9.7_

- [ ] 7. Casos borde F2
  - [ ] 7.1 Generar `casos_f2_semaforo.sql` con F2-1 a F2-6
    - F2-1: rojo y amarillo juntos → `RECHAZADO`. F2-2: producto fuera de la instantánea → rojo con
      `producto N no existe en el servidor`. F2-3: borrador sin ítems → `borrador sin ítems`.
    - F2-4: `disponible = 'f'` → `no disponible`. F2-5: control `SIMULADO_APROBADO`.
    - F2-6: dos solicitudes `PENDIENTE` del mismo borrador fallan por `ux_cola_una_pendiente`.
    - _Requisitos: 7.1, 9.2 a 9.6_
  - [ ] 7.2 Ejecutar en una copia y guardar `32_f2.txt`.

- [ ] 8. Caso C8: dos borradores compiten por el mismo stock
  - [ ] 8.1 Generar `casos_c8_competencia_stock.sql`
    - Borradores A (`c8000000-0000-4000-8000-00000000000a`) y B (`…000b`) piden 4 unidades cada uno del
      producto 11 (stock 6 en la instantánea), con el precio vigente; cada uno pasa solo y juntos piden 8 > 6.
    - Ejecutar el semáforo. Esperado: A y B en `SIMULADO_APROBADO`, `motivo` NULL y `stock_visto` sin cambios.
    - Comentar en el script la resolución real: solo el servidor decide, con `sp_crear_pedido` y
      `SELECT … FOR UPDATE`; la primera solicitud que llegue se acepta y la segunda se rechaza por stock.
    - Repetir con el orden de encolado invertido y confirmar el mismo resultado.
    - _Requisitos: 10.1, 10.2, 10.3, 10.4, 10.6_
  - [ ] 8.2 Ejecutar en una copia y guardar `33_c8.txt`.
  - [ ] 8.3 Verificar el `sp_crear_pedido` real de `heredado/base_heredada/` antes de dar por buena la frase
    sobre `FOR UPDATE` del comentario.

- [ ] 9. Integridad en PostgreSQL
  - [ ] 9.1 Ejecutar `postgresql/verificar_no_cambio.sql` otra vez y guardar `34_pg_despues.txt`.
    - Debe coincidir con `22_pg_antes.txt`: 6 pedidos, 13 detalles, stock_total 454 y la misma huella.
    - _Requisitos: 2.2, 8.6, 10.5_

- [ ] 10. README y cierre
  - [ ] 10.1 Generar `README.md` con el orden de ejecución del diseño y la tabla de resultados esperados.
  - [ ] 10.2 Guardar la bitácora de la corrida de OpenCode (modelo, fecha, prompt, respuesta cruda) y escribir
    `unidad-8/docs/comparacion_generado_vs_original.md`: diferencias contra `movil/`, y qué se aceptó, corrigió o
    descartó, con el motivo. No borrar los originales.
  - [ ] 10.3 Actualizar la DUIA: los originales los hizo Claude con una spec posterior; la regeneración con
    OpenCode se hizo en la fecha de la corrida, desde esta spec.

---

## Notas

- Todo se trabaja sobre `foodstore_u8` (base de pruebas con datos inventados) y copias de SQLite.
- Las evidencias nuevas empiezan en la 22; las 01 a 21 son de los scripts originales y no se tocan.
- No hay tareas de despliegue ni de interfaz de usuario: el proyecto es íntegramente SQL.
- El semáforo **no** confirma ventas; `SIMULADO_APROBADO` es solo una señal local.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["0.1", "0.2", "0.3", "0.4"] },
    { "id": 1, "tasks": ["1.1"] },
    { "id": 2, "tasks": ["1.2", "2.1"] },
    { "id": 3, "tasks": ["2.2", "2.3", "3.1"] },
    { "id": 4, "tasks": ["3.2", "4.1"] },
    { "id": 5, "tasks": ["4.2", "4.3", "5.1"] },
    { "id": 6, "tasks": ["5.2", "6.1"] },
    { "id": 7, "tasks": ["6.2", "6.3", "7.1"] },
    { "id": 8, "tasks": ["7.2", "8.1"] },
    { "id": 9, "tasks": ["8.2", "8.3", "9.1"] },
    { "id": 10, "tasks": ["10.1", "10.2", "10.3"] }
  ]
}
```
