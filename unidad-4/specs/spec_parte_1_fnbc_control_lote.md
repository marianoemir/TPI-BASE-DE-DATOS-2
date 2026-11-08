# Spec: refactorización control_lote_almacen (FNBC)

## 1. Contexto

Tabla afectada: `control_lote_almacen(lote_id, deposito_id, responsable_control_id)`.
Extensión del dominio de Food Store para la distribución mayorista. Un lote de gran volumen puede fraccionarse y controlarse desde más de un depósito, requiriendo un responsable de control por cada depósito interviniente.
Volumen inicial: Instancia de ejemplo con 3 filas.

## 2. Reglas de negocio (confirmadas con: enunciado del TP, punto 4.1)

- R1: "Para un lote y un depósito interviniente dados, el responsable de control queda unívocamente determinado."
  → Notación formal: `{LoteID, DepositoID} -> ResponsableControlID`
- R2: "Cada responsable de control pertenece, como dato maestro de la dotación de personal, a un único depósito: no controla lotes coordinados desde depósitos distintos."
  → Notación formal: `ResponsableControlID -> DepositoID`

Evidencia / Verificación de la relación en los datos:

```sql
-- Verificar que cada responsable pertenece a un único depósito:
SELECT responsable_control_id, COUNT(DISTINCT deposito_id) AS cantidad_depositos
FROM control_lote_almacen
GROUP BY responsable_control_id
HAVING COUNT(DISTINCT deposito_id) > 1;
-- Resultado esperado: 0 filas.
```

## 3. Diagnóstico

### Notación formal de atributos
- `L`: LoteID (`lote_id`)
- `D`: DepositoID (`deposito_id`)
- `R`: ResponsableControlID (`responsable_control_id`)

### Clausuras de atributos
1. `{L, D}+`:
   - `{L, D}^(0) = {L, D}`
   - Aplicando R1 (`{L, D} -> R`): `{L, D}^(1) = {L, D, R}`
   - Genera todos los atributos de la relación.

2. `{L, R}+`:
   - `{L, R}^(0) = {L, R}`
   - Aplicando R2 (`R -> D`): `{L, R}^(1) = {L, R, D}`
   - Genera todos los atributos de la relación.

3. `{R}+`:
   - `{R}^(0) = {R}`
   - Aplicando R2 (`R -> D`): `{R}^(1) = {R, D}` (No genera `{L}`, no es superclave).

### Conjunto completo de claves candidatas
- Claves candidatas: `{{LoteID, DepositoID}, {LoteID, ResponsableControlID}}`
- Atributos primos: `LoteID`, `DepositoID`, `ResponsableControlID` (todos los atributos son primos).
- Atributos no primos: Ninguno (`∅`).

### Evaluación de FNBC
- La relación **NO cumple la Forma Normal de Boyce-Codd (FNBC)**.
- **Dependencia funcional violatoria:** `ResponsableControlID -> DepositoID` (R2).
- **Justificación:** El determinante `ResponsableControlID` NO es superclave, ya que `{ResponsableControlID}+ = {ResponsableControlID, DepositoID} ≠ {LoteID, DepositoID, ResponsableControlID}`.

---

### Anomalías detectadas sobre la instancia de ejemplo

1. **Anomalía de Inserción:**
   No es posible registrar un nuevo responsable de control y su depósito asignado (ej. responsable `803` perteneciente al depósito `31`) sin asignarle simultáneamente un lote (`lote_id`), ya que `lote_id` forma parte de la clave primaria original y no admite valores nulos (`NULL`).

2. **Anomalía de Borrado:**
   El responsable `802` aparece en una sola fila, `(503, 31, 802)`. Si se borra esa fila (por ejemplo, porque el lote `503` se cancela), se pierde el único registro de que `802` pertenece al depósito `31`: un dato de personal se borra como efecto colateral de un dato de logística.

3. **Anomalía de Actualización:**
   Si el responsable `801` cambia del depósito `30` al `32`, se deben actualizar las dos filas en que aparece, `(501, 30, 801)` y `(502, 30, 801)`. Si una actualización falla o queda incompleta, la base de datos quedará en un estado inconsistente donde `801` figurará asignado a dos depósitos distintos.

---

## 4. Esquema objetivo (Descomposición sin pérdida)

Aplicando el algoritmo de descomposición sin pérdida sobre la dependencia violatoria `R -> D`:

1. **Tabla de Maestro de Personal / Responsable:**
   - Nombre: `responsable_deposito`
   - Atributos: `(responsable_control_id, deposito_id)`
   - PK: `responsable_control_id`
   - FK: `deposito_id REFERENCES deposito(id)`

2. **Tabla de Asignación / Control Lote:**
   - Nombre: `control_lote`
   - Atributos: `(lote_id, responsable_control_id)`
   - PK: `(lote_id, responsable_control_id)`
   - FK: `lote_id REFERENCES lote(id)`, `responsable_control_id REFERENCES responsable_deposito(responsable_control_id)`

3. **Vista de compatibilidad:**
   - Nombre: `v_control_lote_almacen`, vista aparte; la tabla original `control_lote_almacen` no se renombra ni se toca.
   - Definición: `NATURAL JOIN` entre `control_lote` y `responsable_deposito` (única columna común: `responsable_control_id`) para reconstruir exactamente la relación original.

## 5. Plan de migración (expandir–migrar–verificar–contraer)

1. Crear tablas maestras soporte `lote` y `deposito` (si no existen) y la tabla original `control_lote_almacen` con la instancia de ejemplo (3 filas).
2. Crear las nuevas tablas resultantes `responsable_deposito` y `control_lote` (sección 4 del script, "up").
3. Migrar los datos desde `control_lote_almacen` hacia las dos tablas nuevas sin destruir la tabla original.
4. Crear la vista de compatibilidad.
5. Verificar la integridad y equivalencia exacta utilizando conteos y **los dos `EXCEPT`** en ambas direcciones.
6. Probar el script de reversión (bloque "down" de la sección 8 del script): ejecutar el down, verificar que desaparecen la vista y las dos tablas, y volver a correr el script completo (up → down → up).

> Actualizado el 08/11/2026 en la sección 9: el script único se separó en `up.sql` y `down.sql` dentro de `unidad-4/migracion/`.

## 6. Criterios de aceptación

- [x] `COUNT(*)` coincide entre la relación original y la reconstruida por la vista.
- [x] Los dos `EXCEPT` (original `EXCEPT` vista y vista `EXCEPT` original) devuelven 0 filas.
- [x] La unión entre las tablas descompuestas es sin pérdida (el atributo común `responsable_control_id` es clave primaria/superclave en `responsable_deposito`).
- [x] El bloque "down" ejecuta sin errores y deja intactas `control_lote_almacen`, `lote`, `deposito` y `usuario`.

## 7. Plan de reversión

Contenido del bloque "down" (sección 8 de `tp_fnbc_control_lote.sql`):
Elimina la vista de compatibilidad y las tablas descompuestas `control_lote` y `responsable_deposito`, manteniendo intactas las tablas originales.

> Actualizado el 08/11/2026 en la sección 9.5: orden de borrado, qué se pierde al revertir y reversión de emergencia.

## 8. Riesgos

- Perder restricciones de FK si las tablas maestras `lote` y `deposito` no están correctamente creadas antes de la descomposición.
- **Limitación conocida (FNBC vs. preservación de dependencias):** la descomposición es sin pérdida pero no preserva `{LoteID, DepositoID} -> ResponsableControlID`. Contraejemplo (sección 7 del script, captura 9): con `(803, 30)` en `responsable_deposito` y `(501, 803)` en `control_lote`, el lote `501` queda con dos responsables en el depósito `30`, algo que la clave primaria de la tabla original impediría. Para imponer esa regla haría falta un trigger o una verificación por consulta.
- El script inserta usuarios de prueba (801-803) en `usuario`: se ejecuta en `copia_fnbc` y nunca en `plantilla_food_store`.

---

## 9. Actualización del 08/11/2026: migración en archivos separados

> Esta sección se agrega **después** de que los archivos de migración ya existían: el plan de reversión se formalizó a posteriori y no antes de generar el código. Actualiza las secciones 5 y 7; el resto no cambia. Redactada con ayuda de Claude y revisada por Facundo Quiroga.

### 9.1 Motivo

El Paso 6 de `protocolo_seguridad.md` exige `up.sql` y `down.sql` separados, cada uno dentro de `BEGIN…COMMIT`. El script original (`tp_fnbc_control_lote.sql`) tenía el `down` comentado y el `up` sin transacción.

### 9.2 Archivos (en `unidad-4/migracion/`)

| Archivo | Contenido |
|---|---|
| `setup_previo.sql` | Estado previo: `lote`, `deposito`, responsables 801 a 803 y `control_lote_almacen` con las 3 filas. Re-ejecutable, solo para copias de trabajo. |
| `up.sql` | Precondición `R -> D`, expandir (tablas nuevas), migrar (`INSERT…SELECT DISTINCT`), vista de compatibilidad y verificación interna. |
| `down.sql` | Elimina la vista y las dos tablas nuevas. |
| `verificar_migracion.sql` | Consultas V1 a V5, de solo lectura. |

### 9.3 Plan de migración actualizado (orden de ejecución)

1. Copia de trabajo (`copia_u4`) con `schema.sql`, `objects.sql` y `data.sql`.
2. `setup_previo.sql`.
3. Respaldo con `pg_dump` (Paso 3 del protocolo), fuera del repo, antes de `up.sql`.
4. `up.sql`:
   - **Precondición:** ningún responsable en más de un depósito; si no se cumple, aborta sin crear nada.
   - **Expandir:** crea `responsable_deposito` y `control_lote`.
   - **Migrar:** copia los datos sin tocar `control_lote_almacen`.
   - **Vista:** crea `v_control_lote_almacen`.
   - **Verificar:** los dos `EXCEPT` más el conteo, dentro de la transacción; si algo no coincide, lanza una excepción y no se confirma nada.
5. `verificar_migracion.sql`: V1 a V4.
6. `down.sql`, y después V1 y V5 para comprobar que se volvió al estado previo.

**Contraer** (eliminar `control_lote_almacen`) queda fuera de esta migración y se haría en una migración posterior, como indica el Paso 6. Todos los pasos anteriores a contraer son reversibles sin pérdida.

### 9.4 Criterios de aceptación adicionales

- [x] `up.sql` termina con `COMMIT` y el aviso `Verificación OK: perdidas=0, espurias=0, filas antes=3 / despues=3`.
- [x] Tras `up.sql`: V1 devuelve 3 objetos, V2 y V3 devuelven 0 filas y V4 devuelve `3 / 3 / 2 / 3`.
- [x] Tras `down.sql`: V1 devuelve 0 filas y V5 devuelve las 3 filas originales.
- [x] `up.sql` repetido falla sin dejar nada a medias; `down.sql` repetido no da error. *(Probado en PostgreSQL 16 local con Claude; sin captura propia.)*
- [x] `up.sql` con datos que violan `R -> D` se frena en la precondición y no crea ningún objeto. *(Ídem.)*

Evidencia: `unidad-4/capturas/` y `docs/informe/u4.md`.

### 9.5 Plan de reversión ampliado

- **Contenido de `down.sql`:** elimina primero la vista, después `control_lote` (tiene FK a `responsable_deposito`) y por último `responsable_deposito`. Usa `IF EXISTS`, por lo que se puede repetir.
- **Qué se pierde al revertir:** lo escrito en `responsable_deposito` y `control_lote` *después* del `up` (por ejemplo, un responsable dado de alta solo en las tablas nuevas). El estado previo no se pierde, porque `control_lote_almacen` se conserva. Si hubiera que conservar esos datos, se respaldan las tablas nuevas antes de revertir.
- **Reversión de emergencia:** restaurar el respaldo de `pg_dump` tomado antes del `up`.

### 9.6 Riesgos adicionales

- **`up.sql` no es idempotente a propósito:** si las tablas ya existen, falla. Para repetir el ciclo hay que correr antes `down.sql` o `setup_previo.sql`.
- **`setup_previo.sql` borra las tablas de la U4 al empezar:** solo se ejecuta en copias de trabajo, nunca en una base con datos que importen.
- **pgAdmin y transacciones abortadas:** si un script con `BEGIN` falla a mitad, la transacción puede quedar abierta y abortada; se resuelve ejecutando `ROLLBACK;`.
