# Introducción, uso de IA y limitaciones

## 1. Introducción y alcance

Food Store es una base de datos de un comercio de alimentos que se trabajó a lo largo de la cursada en cinco unidades: normalización (U4), seguridad (U5), mantenimiento y recuperación (U6), modelado documental (U7) y base local para una tablet (U8). Esta segunda entrega no agrega un sistema nuevo: **cierra y justifica** lo hecho, y prueba de forma verificable el cumplimiento de los 14 objetivos.

Motores: PostgreSQL 16+ (PL/pgSQL), MongoDB y SQLite. Equipo: Mariano Chirino, Andrés Fabre y Facundo Quiroga. El repositorio integrador está organizado por unidad; el `README.md` de la raíz trae la tabla de los 14 objetivos con la ruta de cada evidencia. Link: `[COMPLETAR]`. Etiqueta: `[COMPLETAR]`.

Criterio de lectura: **el informe justifica y el repositorio prueba**. Cada afirmación apunta a un archivo o a una salida guardada. Lo que no se pudo demostrar se dice como límite, no se omite.

## 2. Uso de IA

### Herramientas

- **Kiro**: especificaciones (requisitos, diseño, tareas) antes de generar código.
- **OpenCode** (modelo Nemotron 3.5 Lightning Free en las corridas de la U8 y de la auditoría de `roles.sql`): generación de la base SQLite y auditoría de permisos.
- **Claude** (chat): borradores de requisitos, corrección de los scripts generados, revisión de hallazgos y redacción de documentos, siempre revisados contra las evidencias.
- **Gemini y NotebookLM**: usados en versiones anteriores de la U4 y la U8, declarados en las DUIA de cada unidad.

### Reglas que se respetaron

Nada generado se ejecutó sin leerlo línea por línea y probarlo en una copia o en una transacción reversible. No se enviaron datos reales a una IA. Cada corrida dejó registro de modelo, fecha, prompt, respuesta y decisión.

### Qué pasó con cada corrida (objetivos 6 y 11)

**Objetivo 11 (SQLite).** La spec de Kiro se completó **antes** de generar (commit `be854e4`). Se hicieron dos corridas de OpenCode y **ninguna produjo una base funcional sin correcciones**:

- Corrida 1 (06/11): no creó el esquema y falló en cascada. Los originales están en `unidad-8/movil_opencode/original_opencode/`.
- Corrida 2 (07/11, carpeta aislada sin acceso a `movil/`): error de sintaxis en la carga del catálogo, **ninguna tabla era `STRICT`** aunque el README lo afirmaba, columna mal escrita, sintaxis de SQL Server en SQLite, falta de un `CHECK` y ausencia del archivo de casos. Dos afirmaciones de su respuesta («5 tablas STRICT», «sintaxis revisada») eran falsas: no había ejecutado nada. Queda guardada sin editar en `unidad-8/movil_opencode_v2/`.

La versión final es `movil_opencode/`, corregida con Claude y declarada como tal. Al comparar con los scripts originales aparecieron dos lagunas de la spec (REQ 6.12 y 6.13), que se cerraron con su propio commit.

**Objetivo 6 (auditoría de `roles.sql`).** La sesión original de OpenCode no se conserva; solo hay un resumen de 10 hallazgos en la bitácora. Se **repitió** la auditoría el 07/11 sobre la versión actual (modo Plan, carpeta aislada, respuesta cruda guardada en 3 partes por 2 interrupciones). Devolvió 5 hallazgos, todos reproducidos en una copia antes de decidir:

| Hallazgo | Decisión | Por qué |
|---|---|---|
| H1 `CREATE` en `public` | Aceptado y corregido | Con base limpia no se reproducía; con un `GRANT CREATE` previo, el permiso sobrevivía a `roles.sql` |
| H2 contraseña en re-ejecución | Descartado | El hash SCRAM es idéntico antes y después; la corrección propuesta pisaría claves reales |
| H3 membresías entre grupos | Aceptado y corregido | El residuo de una ejecución previa dejaba a `rol_soporte` ejecutando `sp_crear_pedido` |
| H4 `EXECUTE` indirecto | Descartado | 0 filas para `PUBLIC`; el razonamiento de la IA era incorrecto |
| H5 default privileges | Descartado | La afirmación sobre PostgreSQL 15 es falsa |

Además, **H4b** (cuatro rutinas viejas con `EXECUTE` para `PUBLIC`) **no salió de OpenCode sino de una revisión con Claude**; se declara así, se reprodujo y se corrigió. Con las tres correcciones, las pruebas T01 a T23 dan 23/23.

### Lecciones que cambiaron cómo trabajamos

- Una prueba que pasa no prueba lo que se cree: la de H2 no discriminaba porque `pg_hba.conf` usa `trust`. Antes de citar una evidencia, se verifica qué mide.
- Los dos hallazgos que OpenCode acertó (H1 y H3) eran de base sucia: la copia limpia no los mostraba. No se aprueba ni se descarta un hallazgo por lectura.
- Si una IA afirma algo, se ejecuta y se comprueba.
- `PRAGMA foreign_keys = ON;` en cada script de SQLite.

### Redacción del informe

Los textos de este informe y el documento `auditoria_roles_opencode.md` se redactaron con asistencia de Claude y se revisaron contra las evidencias del repositorio. `[COMPLETAR: lo mismo para los textos de U4, U6, U7 y code review, según declare cada autor]`

## 3. Limitaciones y trabajo futuro

**Del trabajo con IA**
- Ninguna corrida de OpenCode entregó algo ejecutable sin correcciones; la versión final de la U8 depende de correcciones hechas con Claude.
- La auditoría de `roles.sql` es una repetición: la respuesta cruda de la original no existe. De los 10 hallazgos originales solo H1, H2, H4, H6 y H7 están identificados; del resto «no consta».
- No consta con qué herramienta se redactó el Requisito 11 de la spec.
- El registro de la auditoría llegó en tres partes; los mensajes de las interrupciones los redactó Claude y no se compararon carácter por carácter. Las horas de las partes 2 y 3 «no constan».

**De los permisos (U5)**
- `pg_hba.conf` de la copia usa `trust`: T01 a T23 verifican permisos, no autenticación.
- El marcador de contraseña `'cambiar_en_produccion'` es público.
- El `REVOKE` de H3 solo quita membresías concedidas por `postgres`; no se probaron `GRANT OPTION` de otros otorgantes.
- La prueba de H4b no ejercita una ruta donde `app_web` dispare las funciones con sus propios permisos.
- Los roles no cubren los objetos de la U4. `[ACTUALIZAR si F hace T8]`
- `fn_autenticar` no bloquea por intentos fallidos; `log_statement='all'` deja claves en el log.

**De la base SQLite (U8)**
- `capturado_en` en `v_catalogo_disponible` y el criterio `OK`/`FALLA` del Requisito 11 quedan como diferencias sin resolver entre la versión generada y la original; no cambian los casos C1 a C8 ni F2.
- No consta si OpenCode leyó `movil/` en la corrida 1, y no se ejercitó C2 en la corrida 2.
- El semáforo evalúa cada borrador por separado: dos borradores que compiten por el mismo stock pueden quedar ambos aprobados en simulación (C8). Solo el servidor resuelve.
- El semáforo valida la longitud del UUID, no su formato.

**De los otros objetivos** `[COMPLETAR por cada autor: U4, U6, U7, code review]`

**Del proceso**
- Los PR de `m/obj-11`, `m/informe-u8` y `m/obj-06` se mergearon **sin revisión cruzada**, porque la revisión asignada no respondió. Queda pendiente una lectura posterior.
- Las evidencias de H3 y H4b se generaron en UTF-16 y se reencodearon a UTF-8 sin cambiar el contenido (commit `6346e09`).

**Con más tiempo**: probar autenticación real (sin `trust`), ampliar los roles a los objetos de la U4, repetir las mediciones de la U7 con volumen, y automatizar la verificación de integridad también para SQLite.
