# Bitácora Individual de Trabajo e Interacción con IA

**Integrante:** Andrés Fabre  
**Proyecto:** TP N.º 8 — Food Store (Capa de datos y entorno móvil)  
**Entorno de Trabajo:** Windows 11 / PowerShell / CLI `psql` / CLI `sqlite3`  
**Rama Git:** `Andrés`  

---

## 1. Registro de Actividades y Decisiones Técnicas

### Sesión 1: Configuración de Entorno y Verificación Inicial (H0)
- **Actividad:** Configuración del entorno de trabajo local en Windows 11 para interactuar con PostgreSQL 16 y SQLite 3.37+.
- **Acciones:**
  - Creación de la estructura de trabajo local.
  - Comprobación de conectividad a PostgreSQL y verificación del CLI de SQLite.
  - Validación de la arquitectura de scripts maestro (`up.sql`), reversión (`down.sql`) y pruebas formalizadas con el operador `EXCEPT`.

### Sesión 2: Redacción de Entregables Documentales (A1, A2, A3)
- **Actividad:** Elaboración de los tres documentos conceptuales asignados a la rama individual en `docs/partes/`.
- **Acciones:**
  - **1.a (`1a_datos_que_viajan.md`):** Definición de la matriz de sincronización del catálogo de productos hacia la tablet (SQLite). Identificación de PostgreSQL como la única fuente de verdad (*Source of Truth*) y justificación de la exclusión de datos financieros, stock central y datos de usuarios.
  - **3.a (`3a_mapa_capa_de_datos.md`):** Mapeo de la persistencia políglota integrando PostgreSQL (núcleo transaccional relacional), MongoDB (catálogo documental heredado de la U7) y SQLite (instantánea local y cola de sincronización de solo lectura/comandas).
  - **3.b (`3b_plan_mantenimiento.md`):** Extensión del plan de mantenimiento de la U6, detallando periodicidad de respaldos (`pg_dump`), protocolo de atenuación ante restauración de backups antiguos de PostgreSQL en tablets y frecuencia de auditoría sobre la cola en estados `CONFLICTO` / `RECHAZADO`.

### Sesión 3: Revisión Cruzada de las Consignas 1 y 2 (A4)
- **Actividad:** Ejecución del protocolo de pruebas cruzadas sobre los scripts oficiales subidos por Mariano a la rama `main`.
- **Acciones:**
  - Actualización del repositorio desde `main`.
  - Recreación limpia de la base de la tablet mediante `del movil\foodstore_movil.db` y posterior ejecución de `movil/schema_sqlite.sql`.
  - Ejecución de `postgresql/verificar_vista_snapshot.sql`: confirmación de match exacto 16/16 filas entre la tabla y la vista, 0 discrepancias (`EXCEPT`), y estructura de 7 columnas validada.
  - Ejecución de `postgresql/verificar_no_cambio.sql`: confirmación de conservación de estado base (**6 pedidos, 13 detalles, stock total 454 y hash MD5 `89f8351d0162e23ef1473f32b05ce221`**), demostrando la ausencia de modificaciones indeseadas en la base central.

---

## 2. Registro de Interacciones con la Inteligencia Artificial (IA)

| Fecha / Hito | Herramienta / Agente | Solicitud / Prompt Promedio | Respuesta / Propuesta de la IA | Decisión y Justificación (Aceptado / Descartado) |
|---|---|---|---|---|
| **04/11/2026 (H0)** | Gemini (Asistente de Código) | Consolidador de scripts SQL maestros para SQLite con verificación de vistas. | Propuso una secuencia con `PRAGMA foreign_keys = ON`, `CREATE TABLE` y `EXCEPT`. | **Aceptado parcialmente.** Permitió validar el concepto de pruebas de equivalencia de conjuntos antes de la integración oficial. |
| **04/11/2026 (A1, A2, A3)** | Gemini (Asistente de Código) | Redactar de forma concisa los entregables 1.a, 3.a y 3.b para la carpeta `docs/partes/`. | Generó las tablas de sincronización, el mapa políglota y las cláusulas del plan de mantenimiento. | **Aceptado totalmente.** Coincidía de forma precisa con el modelo relacional/documental acordado en el equipo y la plantilla del práctico. |
| **04/11/2026 (A4)** | Gemini (Asistente de Código) | Diagnóstico de error `table producto_cache already exists` al ejecutar `schema_sqlite.sql`. | Explicó que el archivo `.db` ya existía previamente y sugirió eliminar el archivo con `del` antes de correr el script CLI. | **Aceptado.** Se eliminó el archivo en Windows 11, permitiendo una reconstrucción limpia y exitosa de la base de la tablet. |
| **04/11/2026 (A4)** | Gemini (Asistente de Código) | Interpretación del resultado de `verificar_no_cambio.sql` (impresión del hash MD5 `89f835...`). | Explicó el significado técnico del MD5 y la coincidencia de los conteos 6/13/454. | **Aceptado.** Confirmó de manera cuantitativa que la revisión cruzada A4 sobre los scripts de Mariano fue superada exitosamente. |

---

## 3. Reflexión y Auto-evaluación

El flujo de trabajo colaborativo mediante ramas Git en Windows 11 permitió un desarrollo ágil y sin interferencias entre las consignas del motor central (Mariano) y la capa de documentación/mapa de datos (Andrés). El uso de la IA facilitó acelerar el armado de la estructura en Markdown y la depuración rápida de errores de entorno en SQLite/PostgreSQL, siempre manteniendo el control humano mediante la validación directa en la consola de comandos.

---

## Nota de revisión del equipo (Mariano Chirino, 04/11/2026)

Esta nota la agrega Mariano al integrar el PR #1. El texto anterior es de Andrés y no se modificó.

- **1.a, 3.a y 3.b.** Al revisarlos contra el esquema real tenían errores: columnas que no existen en `producto`, la cola de envío ubicada
  en PostgreSQL (está en SQLite), MongoDB descripto como metadatos de productos (guarda la colección `pedidos`) y SQLite con «autoridad local».
  Fueron corregidos por Mariano en `docs/partes/`. El «Aceptado totalmente» de la Sesión 2 se refiere al borrador original.
- **Carpeta `sqlite/` y `tp8_database.db`** (`up.sql`, `down.sql`, `schema.sql`, `vistas.sql`, `verificar.sql`). Eran un esquema de ejemplo
  (`categoria` y `producto`, con `precio REAL` y sin `STRICT`) distinto del esquema del TP, y no se integraron al repo. Las referencias a esos
  scripts en la Sesión 1 quedan como registro de lo que se hizo, no como entregables.
- **Revisión cruzada A4.** Los resultados que informa Andrés (16/16 sin diferencias en `verificar_vista_snapshot.sql`; 6 pedidos, 13 detalles,
  stock 454 y huella `89f8351d0162e23ef1473f32b05ce221` en `verificar_no_cambio.sql`) coinciden con los de Mariano. Las pruebas de la tablet, los casos
  C2 a C6 y `verificar_vistas_tablet.sql` no figuran en esta bitácora: los corrió Mariano y sus salidas están en `evidencias/`.

---

## Actualización de Andrés — 05/11/2026

### Sesión 4: H0 y revisión cruzada completa (A4)

- **Entorno comprobado:** PostgreSQL / `psql` 17.11; `sqlite3` CLI 3.54.1; biblioteca SQLite de Python 3.50.4. Los tres cumplen el mínimo de SQLite 3.37+ y PostgreSQL 16+.
- **H0:** una base de prueba creada desde `schema.sql` → `objects.sql` → `data.sql` → `views.sql` dio los conteos requeridos: **6 usuarios / 16 productos / 6 pedidos**.
- **A4 ejecutada desde cero:** se creó una copia descartable del servidor y una base SQLite temporal, sin modificar `movil/foodstore_movil.db` ni la base de trabajo del equipo. La salida completa está en `evidencias/20_andres_revision_a4_completa.txt`.
- **Resultado de 1.c:** `pruebas_sqlite.sql` dejó el borrador confirmado en 1 / 2 / 1 (borradores / ítems / solicitudes); el `ROLLBACK` no dejó la segunda operación; C1 mostró 14 productos disponibles sin conexión al servidor; y C7 produjo los errores esperados de `CHECK`, clave foránea y `STRICT`, conservando 1 / 2 filas.
- **Resultado de 2.c:** C2 dio `CONFLICTO` y, luego de aceptar el precio, la nueva solicitud dio `SIMULADO_APROBADO`; C3 y C4 dieron `RECHAZADO`; C5 dio `SIMULADO_APROBADO`; C6 rechazó el UUID repetido por clave primaria. La tercera corrida del semáforo evaluó 0 solicitudes pendientes.
- **Vistas y no cambio:** `verificar_vista_snapshot.sql` dio 16 / 16 filas, 0 diferencias y las 7 columnas esperadas sin datos de usuarios. `verificar_vistas_tablet.sql` dio 16 / 16 filas de instantánea/cache, 13 / 13 del catálogo visible y 0 diferencias. Al final, `verificar_no_cambio.sql` dio 6 pedidos, 13 detalles, stock total 454 y huella `89f8351d0162e23ef1473f32b05ce221`.

### Sesión 5: Revisión de 3.c

- **Actividad:** revisión cruzada de `docs/partes/3c_code_review.md` y de las evidencias 15 a 17, repetida en una copia descartable para los hallazgos que usan PostgreSQL.
- **Hallazgos comprobados:** H36 queda correctamente **descartado**: los bloques de C7 hacen `ROLLBACK` y no dejan filas; H04 queda correctamente **descartado con fundamento**: con 13 filas el plan secuencial es más barato, aunque el índice compuesto puede usarse si se deshabilita el escaneo secuencial; H01 y R1 quedan correctamente **aceptados**: el procedimiento admite un producto de categoría dada de baja y un producto repetido produce `SQLSTATE 23505` sin mensaje de negocio.
- **Evidencia propia:** `evidencias/21_andres_revision_3c.txt`. En la copia limpia de esta revisión H01 mostró 3 lápidas (dos productos de la categoría 5 más el producto 16 ya eliminado); las 4 lápidas de `evidencias/16` incluyen además la baja lógica de C4, por lo que no hay contradicción.

### Registro de IA de esta actualización

| Fecha / hito | Herramienta / agente | Solicitud | Decisión y comprobación |
|---|---|---|---|
| **05/11/2026 (A4 y revisión 3.c)** | OpenCode / asistente GPT-5.6 Terra | Revisar el estado real de mi parte, ejecutar A4 desde cero y contrastar 3.c con sus evidencias. | **Aceptado tras prueba directa.** Se usaron copias descartables y se guardaron las salidas 20 y 21. No se modificaron scripts funcionales. |
