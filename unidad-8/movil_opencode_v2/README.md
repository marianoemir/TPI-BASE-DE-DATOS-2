# Food Store — Base de la tablet (Unidad 8)

## Entregables

Scripts SQL en `movil_opencode_v2/`:

| Archivo | Descripción |
|---|---|
| `schema_sqlite.sql` | Creación de todas las tablas STRICT, índices, vistas y restricciones |
| `cargar_catalogo.sql` | UPSERT desde `snapshot_servidor` hacia `producto_cache` |
| `semaforo.sql` | Motor de evaluación que clasifica solicitudes PENDIENTE |
| `pruebas_sqlite.sql` | Pruebas de transacción (COMMIT/ROLLBACK), C1 y C7 |
| `casos_c2_c5_borradores.sql` | Creación de borradores y solicitudes C2 a C5 |
| `casos_c2_c6_resolucion.sql` | Resolución C2, control de duplicados C6 |
| `casos_f2_semaforo.sql` | Casos borde F2-1 a F2-6 |
| `casos_c8_competencia_stock.sql` | C8: dos borradores compiten por stock |

## Orden de ejecución (sobre una base SQLite nueva `foodstore_movil.db`)

1. `schema_sqlite.sql` — crea tablas STRICT, índice parcial `ux_cola_una_pendiente`, vista `v_catalogo_disponible`
2. Importar el CSV (instantánea 1): `.import --csv --skip 1 servidor_snapshot.csv snapshot_servidor` (cliente sqlite3)
3. `cargar_catalogo.sql` — Carga los 16 productos en `producto_cache` con UPSERT
4. `pruebas_sqlite.sql` — verifica COMMIT/ROLLBACK, C1 (catálogo disponible) y C7 (restricciones CHECK/FOREIGN KEY/STRICT)
5. `casos_c2_c5_borradores.sql` — crea borradores C2 (producto 1 precio), C3 (tiramisú qty 7/6), C4 (producto 3 eliminado), C5 (control Napolitana)
6. En PostgreSQL: ejecutar casos de subida de precio y baja lógica; exportar instantánea 2
7. `semaforo.sql` — primera corrida
   - C2 → CONFLICTO (producto 1, precio subido)
   - C3 → RECHAZADO (stock insuficiente, producto 11, pidió 7/6)
   - C4 → RECHAZADO (dado de baja, producto 3)
   - C5 → SIMULADO_APROBADO (control, producto 2)
   - `solicitudes_evaluadas = 4`
8. `casos_c2_c6_resolucion.sql` — reenvo C2 con UUID nuevo; probar C6 (UUID duplicado falla); segunda y tercera corrida de semáforo
9. `casos_f2_semaforo.sql` — F2-1 a F2-6
10. `casos_c8_competencia_stock.sql` — C8: dos borradores (4 u cada uno, producto 11 stock 6), ambos SIMULADO_APROBADO
11. `postgresql/verificar_no_cambio.sql` — confirmar que el servidor no cambió (misma huella antes/después)

## Resultados esperados por caso

| Caso | UUID | Estado esperado | Motivo |
|------|------|----------------|--------|
| C2 | c2000000-...0b | CONFLICTO | Conflicto de precio (producto 1) |
| C3 | c3000000-...0b | RECHAZADO | Stock insuficiente (pidió 7, stock 6) |
| C4 | c4000000-...0b | RECHAZADO | Dado de baja (producto 3) |
| C5 | c5000000-...0b | SIMULADO_APROBADO | Sin diferencias |
| F2-1 | f2000001-...0b | RECHAZADO | Rojo gana sobre amarillo |
| F2-2 | f2000002-...0b | RECHAZADO | Producto no existe en servidor |
| F2-3 | f2000003-...0b | RECHAZADO | Borrador sin ítems |
| F2-4 | f2000004-...0b | RECHAZADO | No disponible |
| F2-5 | f2000005-...0b | SIMULADO_APROBADO | Control (todos OK) |
| F2-6 | — | Error UNIQUE | Segunda PENDIENTE bloqueada por índice parcial |
| C8 | c8000000-...a, ...b | SIMULADO_APROBADO | Ambos aprobados de forma independiente |

## Nota sobre `SIMULADO_APROBADO`

`SIMULADO_APROBADO` no es una venta confirmada. Solo indica que, contra la instantánea actual,
el borrador no presenta conflictos ni rechazos. La decisión final de precio, stock y venta
corresponde exclusivamente a PostgreSQL a través de `sp_crear_pedido` con `SELECT ... FOR UPDATE`.

## STRICT mode y restricciones

- Todas las 5 tablas son `STRICT` (SQLite 3.37+): solo permitidos INTEGER, REAL, TEXT, BLOB, ANY
- `PRAGMA foreign_keys = ON;` al inicio de cada script
- Dinero en centavos enteros: `CHECK (precio_centavos >= 0)`
- Booleanos: `INTEGER CHECK (col IN (0,1))`
- UUIDs de 36 caracteres: `CHECK (length(id_local) = 36)`
- `forma_pago` restringido a `EFECTIVO, TARJETA, TRANSFERENCIA`
- `cantidad > 0` mediante `CHECK`
- `disponible IN ('t','f')`, `eliminado IN ('t','f')` en `snapshot_servidor`