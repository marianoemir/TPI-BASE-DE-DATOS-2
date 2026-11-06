# Bitácora personal — Mariano Chirino

Registro de lo que hice y por qué, para poder volver a consultarlo. Se unifica al final en `docs/bitacora_ia.md`.

## Mi parte

Según `DIVISION_DE_TRABAJO.md`:

- Consigna 1: esquema SQLite (`schema_sqlite.sql`, `cargar_catalogo.sql`) y pruebas (`pruebas_sqlite.sql`).
- Consigna 2: instantánea y CSV, semáforo (`semaforo.sql`), casos C2 a C6 y verificación de que PostgreSQL no cambió.
- Requisitos y diseño en Kiro (4.a), integración del repo.
- Al final: `informe.pdf`, `README.md`, unificación de bitácoras y etiqueta `tp8` (pendiente).
- Además: revisión del PR #1 de Andrés (1.a, 3.a y 3.b) e integración al repo.

## Mi entorno (H0)

| Servidor y versión | Conteos de `usuario`, `producto`, `pedido` | Problemas y cómo se resolvieron |
|---|---|---|
| PostgreSQL 17.10 (`foodstore_u8`), SQLite 3.54.1, Windows con PowerShell 5.1 | 6 / 16 / 6 (el pedido 4 está dado de baja) | `python` apuntaba a un acceso directo falso: se usa `py`. `psql` no está en el PATH: se usa la ruta completa. En consola los acentos de los mensajes de `psql` salen rotos; es solo la consola, no el dato ni el CSV. |

## Interacciones con IA (Kiro y Claude)

| Prompt enviado a la IA | Respuesta relevante recibida (resumida) | Validación o corrección humana aplicada |
|---|---|---|
| Kiro: generar `requirements.md`, `design.md` y `tasks.md` | Spec completa, pero escrita **después** de los scripts (el enunciado pide lo contrario; está declarado). | Corregí `requirements.md` (el semáforo no marca `eliminado` en `producto_cache`; eso lo hace la recarga) y `design.md` (exportaba con `COPY producto` en vez de `v_snapshot_movil`, inventaba un transporte, tenía invertida la fila de booleanos y decía que la transacción hace rollback sola). Descarté las pruebas de propiedades con Hypothesis y el límite de 255 caracteres en `motivo`. |
| Claude: revisar lo que generó Kiro contra los scripts y las evidencias | Detectó los errores anteriores y que la tabla de pruebas del diseño no mencionaba `pruebas_sqlite.sql` (C1 y C7). | Se corrigió el diseño. |
| Claude: revisar el PR #1 de Andrés (clonar la rama, leer y probar) | Sus 1.a, 3.a y 3.b tenían columnas inexistentes en `producto`, la cola ubicada en PostgreSQL, MongoDB descripto como metadatos de productos y SQLite con «autoridad local». El PR traía además `sqlite/`, dos `tp8_database.db` y un `foodstore_movil.db` vacío. | Verifiqué cada dato contra `schema.sql` y `esquema_documental.md`. Descarté `sqlite/`, los `.db` de ejemplo y el `.db` vacío (habría pisado la base con la evidencia de C2 a C6). Reescribí las tres partes. |
| Claude: qué decirle a Andrés sobre la fila de MongoDB de la 3.a | Propuso la fila (colección `pedidos` de `foodstore_nosql`, copia de lectura, PostgreSQL manda, no viaja a la tablet) y avisó que MongoDB tiene 7 pedidos y `foodstore_u8` tiene 6. | Usé la fila como base de la `3a`. |
| Claude: revisar mi `3a` corregida | Detectó que seguía diciendo «5 pedidos migrados» (valor arrastrado del borrador de Andrés) cuando `esquema_documental.md` dice 7: 1, 2, 3, 5 y 6 de `data.sql` más el 7 y el 8 de prueba. | Corregido a 7 y subido en un commit aparte (`5f073d6`). Mi propia corrección había arrastrado el error: lo verifiqué recién después. |
| Claude: pasos para integrar el PR #1 y cerrar el push rechazado | Plan: mergear desde la web de GitHub, corregir en un commit y, cuando el push fue rechazado, registrar el merge remoto con `git merge -s ours`. Primero pidió comprobar con `git diff --stat main origin/main` que la diferencia era solo lo que se quería descartar. | Lo comprobé y apliqué. Resultado: `main` quedó sin `sqlite/` ni `.db` vacío, con el `.db` en 16 y 6. |
| Claude: comandos para las evidencias 13 y 14 | Función `Ev` con contraseña oculta (`-AsSecureString`) y salida guardada en `evidencias/`. | Corrí los comandos, comparé con lo esperado y recién después los subí. |

## Revisión cruzada que hice

| Qué revisé | En qué servidor lo ejecuté | Qué encontré |
|---|---|---|
| `1a`, `3a` y `3b` de Andrés (PR #1) | Contra `schema.sql` y `esquema_documental.md` (lectura y comparación, sin motor) | Los errores de la fila anterior; corregidos por mí. Las frecuencias de la `3b` las contrasté después con el informe de la Unidad 6 (ver la fila siguiente). |
| Resultados de la A4 de Andrés | PostgreSQL 17.10 (`foodstore_u8`) | Coinciden con los míos: 16/16 en la vista y 6 pedidos, 13 detalles, stock 454 y la misma huella antes y después. No corrió las pruebas de la tablet, C2 a C6 ni `verificar_vistas_tablet.sql`; los cubren mis evidencias. |
| `3b` contra `SPEC_U6.md`, `informe_u6.pdf` y `protocolo_seguridad.md` | Lectura | Las frecuencias del borrador de Andrés (respaldo diario, restauración de prueba semanal) coinciden con la spec de la U6. Agregué lo que el informe aporta: al 21/10/2026 el respaldo era manual (sin tarea programada) y `pg_dump` no incluye roles ni permisos. |

## Mediciones (valores observados, no estimados)

| Dato | Valor | Cómo se midió |
|---|---|---|
| Conteos `usuario` / `producto` / `pedido` | 6 / 16 / 6 | Consulta en `foodstore_u8` |
| `verificar_no_cambio.sql` | 6 pedidos, 13 detalles, stock total 454, huella `89f8351d0162e23ef1473f32b05ce221`, igual antes y después | Evidencias 01 y 12 |
| Vista `v_snapshot_movil` | 16 filas contra 16 de `producto`, 0 diferencias, 0 precios con fracción de centavo, 7 columnas sin datos de usuarios | `verificar_vista_snapshot.sql` (evidencia 13) |
| Catálogo en la tablet | 16 contra 16 en la copia; 13 contra 13 en el catálogo disponible; 0 diferencias | `verificar_vistas_tablet.sql` (evidencia 14) |
| Base de la tablet tras la integración | 16 filas en `producto_cache` y 6 en `cola_sync` | `sqlite3 movil/foodstore_movil.db` |
| Resultado de los casos | C2 CONFLICTO y luego SIMULADO_APROBADO; C3 RECHAZADO (pide 10 Tiramisú, hay 6); C4 RECHAZADO (Fugazzeta dada de baja); C5 SIMULADO_APROBADO; C6 error de clave primaria y 0 solicitudes evaluadas en la repetición | Evidencias 05 a 11 |

## Problemas encontrados y cómo se resolvieron

| Fecha | Problema | Causa | Solución |
|---|---|---|---|
| 04/11/2026 | Primer intento de merge del PR #1 por línea de comandos falló | No se determinó | Se mergeó desde la web de GitHub y se corrigió después |
| 04/11/2026 | `git status` mostraba modificados `.gitattributes`, `.kiro/.../.config.kiro` y 13 archivos de `evidencias/` | Cambios de fin de línea de Windows (en `.gitattributes` la regla quedó con un `\r`). Comprobé con `git diff --ignore-space-at-eol --stat` que en `evidencias/` no había diferencias de contenido | `git restore` de esos archivos; no se commitearon |
| 04/11/2026 | `git push` rechazado (`fetch first`) | El merge hecho desde la web creó en GitHub un commit que yo no tenía, con el `.db` vacío, `sqlite/` y los borradores de Andrés | `git merge -s ours origin/main` para registrar ese commit sin traer sus archivos; luego push |
| 04/11/2026 | La `3a` decía 5 pedidos migrados a MongoDB | Arrastré el valor del borrador de Andrés sin contrastarlo con `esquema_documental.md` | Corregido a 7 y subido |
| 04/11/2026 | Dudé de las frecuencias de la `3b` (respaldo diario, prueba semanal) porque el plan de la U6 no estaba en el repo | Revisé primero solo el informe y el protocolo, que no las fijan. En un primer ajuste quité la «prueba semanal» y escribí que el plan no fijaba frecuencia: era un error, porque `SPEC_U6.md` sí la fija | Con `SPEC_U6.md` a la vista: diario para el respaldo y semanal para la restauración de prueba, igual que el borrador de Andrés. Restauré el «semanal» en la `3b` |

## Decisiones tomadas

| Decisión | Alternativas | Por qué |
|---|---|---|
| No integrar `sqlite/`, los `tp8_database.db` ni el `.db` vacío del PR | Integrarlos como «versión alternativa» | Es un esquema de ejemplo (`precio REAL`, sin `STRICT` ni centavos) que no es el del TP, y el `.db` vacío pisaba la evidencia de C2 a C6 |
| Reescribir yo las `1a`, `3a` y `3b` de Andrés y dejar su texto intacto en su bitácora y su DUIA con una nota firmada | Pedirle que las rehaga; reescribir también su bitácora | Prefiero no depender del tiempo del equipo; la nota solo dice lo comprobable y no afirma nada que Andrés no haya declarado |
| Integrar el PR desde la web y corregir en un commit aparte | Resolver el merge por línea de comandos | El intento por línea de comandos había fallado y quería conservar su autoría en la historia |
| Índice parcial `ux_cola_una_pendiente` | `UNIQUE` simple sobre `id_local` | Un `UNIQUE` simple impediría reenviar una solicitud después de un CONFLICTO |
| Carga del catálogo con `ON CONFLICT DO UPDATE` | `INSERT OR REPLACE` | `REPLACE` borra la fila y se perdería la lápida |
| Spec de Kiro escrita después del código, declarándolo | Reescribirla como si fuera anterior | El trabajo se hizo en ese orden; se declara en lugar de ocultarlo |
