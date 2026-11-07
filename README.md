# TPI «Food Store» — Bases de Datos II (UTN), segunda entrega

Capa de datos de Food Store en **PostgreSQL 16+ (PL/pgSQL)**, **MongoDB** y **SQLite**.
Equipo: Mariano Chirino, Andrés Fabre y Facundo Quiroga. Grupo 10.
Entrega: jueves 12 de noviembre de 2026, 23:59. Informe en PDF: `docs/informe/` (PDF final: `[COMPLETAR]`). Etiqueta final: `[COMPLETAR]`.

> Estado de la tabla: 07/11/2026. Los estados marcados «en curso» se actualizan antes de entregar.

## Cómo está organizado el repositorio

| Carpeta | Contenido |
|---|---|
| `heredado/` | Base de partida (`base_heredada/`) y material de la U7 (`u7_mongodb/`) |
| `unidad-4/` | Normalización (FNBC), desnormalización controlada, migración |
| `unidad-5/` | Roles y permisos, auditoría de acceso, simulacro de incidente, auditoría de `roles.sql` asistida por IA |
| `unidad-6/` | Respaldo, restauración, mantenimiento, simulacro de desastre |
| `unidad-7/` | Modelo documental (MongoDB) y comparación con PostgreSQL |
| `unidad-8/` | Base SQLite de la tablet, sincronización simulada, semáforo de conflictos |
| `docs/` | Informe, bitácora de IA unificada, auditoría de código |

## Los 14 objetivos y dónde está la evidencia

| # | Objetivo | Estado | Evidencia | Límite conocido |
|---|---|---|---|---|
| 1 | Refactor a BCNF validado contra dependencias funcionales | Cubierto | `unidad-4/tp_fnbc_control_lote.sql`, `unidad-4/specs/spec_parte_1_fnbc_control_lote.md` | La dependencia `{L,D}→R` no se preserva (documentado) |
| 2 | Migración sin pérdida, transaccional, con plan de reversión | En curso | `unidad-4/migracion/up.sql` y `down.sql` `[COMPLETAR]` | Hoy hay un solo script, sin `BEGIN…COMMIT` |
| 3 | Desnormalización controlada documentada | Cubierto | `unidad-4/tp_desnormalizacion_top_categorias.sql`, `unidad-4/capturas/explain_*.txt` | La consulta base tarda 6,5 ms: difícil de justificar como «lenta» |
| 4 | Roles y permisos de mínimo privilegio | Cubierto | `unidad-5/sql/roles.sql`, `unidad-5/docs/kiro_roles_spec/`, `unidad-5/docs/verificacion_permisos.md` (T01–T23: 23/23) | No cubre los objetos de la U4 (`control_lote`, `responsable_deposito`, `mv_ventas_categoria_dia`) |
| 5 | Auditoría y simulacro de acceso indebido, con contención | Cubierto | `unidad-5/docs/informe_auditoria.md`, `unidad-5/sql/simulacro_incidente.*`, `unidad-5/docs/informe_incidente.md` | Evidencia repartida en tres servidores y fechas |
| 6 | Auditoría de permisos asistida por IA, con decisión humana | Cubierto | `unidad-5/docs/auditoria_roles_opencode.md`, `unidad-5/docs/registro_opencode_auditoria_roles_corrida2.txt`, `unidad-5/evidencias/obj6_*` | Repetición del 07/11: la sesión original no se conserva |
| 7 | Plan de mantenimiento completo | En curso | `unidad-6/` (rama `a/obj-07`) `[ACTUALIZAR al mergear]` | Mantenimiento y respaldo corren como `postgres`; tareas `Interactive` |
| 8 | Simulacro de desastre contra reloj | Cubierto | `unidad-6/restore_test.ps1`, `unidad-6/evidencias/restore_log_ok.txt`, `informe_u6.pdf` | RTO 6,19 s sobre ~10,6 MB, mismo equipo |
| 9 | Modelado documental con consultas verificadas | Cubierto | `unidad-7/modelo/esquema_documental.md`, `unidad-7/consultas_mongodb.js` | Escala de laboratorio (7 documentos) |
| 10 | Comparación documental vs relacional | En curso | `unidad-7/evidencias/` (rama `a/obj-10`) `[ACTUALIZAR al mergear]` | `[COMPLETAR]` |
| 11 | SQLite especificado en Kiro y generado con OpenCode | Cubierto con límites | `unidad-8/.kiro/specs/foodstore-tablet-sync/`, `unidad-8/movil_opencode/`, `unidad-8/movil_opencode_v2/`, `unidad-8/docs/comparacion_generado_vs_original.md` | Ninguna corrida de OpenCode produjo una base funcional sin correcciones |
| 12 | Sincronización simulada con conflictos | Cubierto | `unidad-8/movil_opencode/semaforo.sql`, casos C1–C8 y F2, `unidad-8/evidencias/01` a `29` | El semáforo evalúa cada borrador por separado; solo el servidor resuelve la competencia por stock (C8) |
| 13 | Code review final asistido por IA | En curso | `docs/auditoria_codigo/` `[COMPLETAR]` | Sin hallazgos completos hasta que termine la revisión |
| 14 | Capa de datos completa en Git, lista para defensa | En curso | Este README, `docs/bitacora_ia.md`, `docs/informe/` | `[ACTUALIZAR al cerrar]` |

## Bases de datos usadas

| Unidad | Base | Motor |
|---|---|---|
| U4 | `copia_trabajo` (Parte 2) y `copia_fnbc` (Parte 1) | PostgreSQL 18 |
| U5 | `copia_u5` | PostgreSQL 17.10 |
| U6 | `foodstore`, `foodstore_restore_test` | PostgreSQL |
| U7 | `foodstore_nosql` | MongoDB 9.0.4 (`mongosh` 2.14.0) |
| U8 | `foodstore_u8` | PostgreSQL + SQLite 3.54.1 |

## Cómo reproducir

1. Cargar la base heredada en este orden: `schema` → `objects` → `data` → `views` → `materializadas.sql`. Conteos esperados: 6 / 16 / 6. **No** correr `carga_masiva.sql` salvo en la medición de la U7, y en una base aparte.
2. `unidad-5/sql/roles.sql` depende de `mv_facturacion_categoria_mes`: cargar `materializadas.sql` antes.
3. En SQLite, `PRAGMA foreign_keys = ON;` va en **cada** script (cada `sqlite3` es un proceso nuevo y arranca en OFF).
4. Ejecutar los comandos desde la raíz del repositorio y los scripts desde archivo (`-f`), no pegados en la consola.
5. En Windows, `psql` no está en el PATH: `& "C:\Program Files\PostgreSQL\17\bin\psql.exe"`.
6. Toda prueba corre en una copia o en una transacción reversible.

## Uso de IA

Herramientas, qué se pidió, qué se aceptó y qué se descartó: `docs/informe/` (sección de uso de IA) y `docs/bitacora_ia.md`. Cada unidad conserva su DUIA o bitácora.
