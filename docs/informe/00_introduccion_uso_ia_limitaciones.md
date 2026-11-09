# Introducción, uso de IA y limitaciones

## 1. Introducción y alcance

Food Store es una base de datos de un comercio de alimentos que se trabajó a lo largo de la cursada en cinco unidades: normalización (U4), seguridad (U5), mantenimiento y recuperación (U6), modelado documental (U7) y base local para una tablet (U8). Esta segunda entrega no agrega un sistema nuevo: **cierra y justifica** lo hecho, y prueba de forma verificable el cumplimiento de los 14 objetivos.

Motores: PostgreSQL 16+ (PL/pgSQL), MongoDB y SQLite. Equipo: Mariano Chirino, Andrés Fabre y Facundo Quiroga. El repositorio integrador está organizado por unidad; el `README.md` de la raíz trae la tabla de los 14 objetivos con la ruta de cada evidencia. Link: https://github.com/marianoemir/TPI-BASE-DE-DATOS-2. Etiqueta: `tp-final`.

**Nota sobre el PDF de la U7.** `unidad-7/informe_u7.pdf` es la entrega original de la unidad (01/11/2026) y enlaza al repositorio `marianoemir/TP-Unidad7-BD2`. No incluye la medición de 5.000 pedidos, que está en `unidad-7/evidencias/comparacion_medida.md` y en la sección de la U7 de este informe. No se editó: se revisó página por página (texto, metadatos y capturas) y no contiene rutas locales ni nombres de equipo; solo los nombres de los integrantes y datos ficticios de `data.sql`.

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

Los textos de este informe y el documento `auditoria_roles_opencode.md` se redactaron con asistencia de Claude y se revisaron contra las evidencias del repositorio. Los textos de `u4.md` se redactaron con Claude (declarado en la DUIA de Facundo, 08/11/2026) y Mariano los corrigió con Claude ese día. `u6.md` lo amplió Mariano con Claude el 07/11/2026 sobre el texto de Andrés. De `u7.md` no consta con qué herramienta se redactó.

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
- Los roles no cubren los objetos de la U4 (`control_lote`, `responsable_deposito`, `mv_ventas_categoria_dia`): la ampliación de los roles a esos objetos (T8) no se hizo.
- `fn_autenticar` no bloquea por intentos fallidos; `log_statement='all'` deja claves en el log.

**De la base SQLite (U8)**
- `capturado_en` en `v_catalogo_disponible` y el criterio `OK`/`FALLA` del Requisito 11 quedan como diferencias sin resolver entre la versión generada y la original; no cambian los casos C1 a C8 ni F2.
- No consta si OpenCode leyó `movil/` en la corrida 1, y no se ejercitó C2 en la corrida 2.
- El semáforo evalúa cada borrador por separado: dos borradores que compiten por el mismo stock pueden quedar ambos aprobados en simulación (C8). Solo el servidor resuelve.
- El semáforo valida la longitud del UUID, no su formato.

**De los otros objetivos**
- U4 (objetivos 1 a 3): la spec de la migración se actualizó después del código; no hubo pasada previa con `ROLLBACK`; la migración no preserva `{L,D} → R`; el paso «contraer» queda pendiente y mientras tanto hay dos fuentes de verdad; el `down.sql` repetido no tiene captura propia; la escala es de 3 filas. Las capturas del ciclo `up`/`down` son de PostgreSQL 18 y las de los caminos de falla, de PostgreSQL 17. Al 08/11/2026 no consta si el primer borrador de la Parte 1 lo hizo Gemini ni quién sacó las capturas del ciclo.
- U6 (objetivo 7): las tareas se dispararon a mano con `Start-ScheduledTask`; ninguna se ejecutó por horario. El mantenimiento no deja log propio y corre como `postgres`; `pg_hba` está en `trust`; el RPO de la prueba no es real; las pruebas de Pester solo buscan texto en los scripts. La primera corrida de mantenimiento dio «sin acción» con estadísticas en cero (copia hecha con `createdb -T`); se repitió tras `ANALYZE`, y falta revisar si la entrega original tuvo la misma causa.
- U7 (objetivo 10): los límites están en la fila 10 del `README.md` y en `unidad-7/evidencias/comparacion_medida.md`.
- Code review (objetivo 13): OpenCode en modo Plan, 11 tandas, 196 hallazgos. Se decidió sobre 42 (las 35 altas y críticas y 7 más) y 154 quedan «No evaluado». Solo 14 decisiones tienen ejecución propia; el resto es por lectura. Ningún script se modificó. Ver `docs/informe/codereview.md`.

**De los datos de ejemplo y las evidencias**
- La base heredada del repositorio usa usuarios inventados. Las exportaciones de la U7 (`unidad-7/modelo/pedidos_export.json` y la salida guardada en `unidad-7/evidencias/mongo_migracion_y_consultas.txt`) se regeneraron el 07/11/2026 sin el nombre real de un integrante (según `unidad-7/CONTEXTO_IA.md`). El `git grep` del 08/11/2026 no encuentra nombres de integrantes en esos dos archivos. Sí quedaba un resto en `unidad-7/AGENTS.md` (la fila del pedido 5 nombraba a un integrante como cliente), corregido el 08/11/2026.
- Las evidencias de las U5, U6 y U7 conservan rutas locales (`C:\Users\...`) y nombres de equipo (`MarianoChirino`, `DESKTOP-ANDRES`) de los integrantes. No se editaron, para no alterar lo que prueban.

**Del proceso**
- Los PR de `m/obj-11`, `m/informe-u8` y `m/obj-06` se mergearon **sin revisión cruzada**, porque la revisión asignada no respondió. Queda pendiente una lectura posterior.
- Las evidencias de H3 y H4b se generaron en UTF-16 y se reencodearon a UTF-8 sin cambiar el contenido (commit `6346e09`).

**Con más tiempo**: probar autenticación real (sin `trust`), ampliar los roles a los objetos de la U4, repetir las mediciones de la U7 con volumen, y automatizar la verificación de integridad también para SQLite.
