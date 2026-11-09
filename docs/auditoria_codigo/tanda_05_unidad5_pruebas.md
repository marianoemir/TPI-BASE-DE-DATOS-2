# Tanda 05 — unidad-5/sql (simulacro, auditoría y pruebas de correcciones)

Herramienta: OpenCode (modo Plan, solo lectura)
Modelo: Croutou Alpha Free
Fecha y hora: 8/11/2026, 23:12
Sesión: nueva (distinta de las tandas 01 a 04)
Archivos (10):
- unidad-5/sql/simulacro_incidente.ps1
- unidad-5/sql/simulacro_incidente.sql
- unidad-5/sql/auditoria_test.ps1
- unidad-5/sql/auditoria_test.sql
- unidad-5/sql/prueba_h1_correccion.ps1
- unidad-5/sql/prueba_h2b_hash.ps1
- unidad-5/sql/prueba_h3_correccion.ps1
- unidad-5/sql/prueba_h3_h4b.sql
- unidad-5/sql/prueba_h4b_trigger.sql
- unidad-5/sql/correccion_h4b.sql
Prompt: ver prompt_base.md (solo cambia la lista de archivos)
Estado: Corrida completa
Total de hallazgos devueltos:  sin ids ni severidad (27 filas armadas después desde la prosa, ver hallazgos.md)
Estado del repo: rama review-final, etiqueta pre-review (351ddb9)

---

Revisé **solo** los 10 archivos indicados, sin modificar nada. Alcance ético OK: todo apunta a `copia_u5` y solo sobre el caso local. Nada de los scripts toca datos reales de terceros.

# Resumen

La revisión muestra buena higiene en simulacro/auditoría para el log, y scripts de corrección H1/H3/H4b/H2b que funcionan como evidencia puntual pero con **fragilidad e inconsistencias** frente a las Reglas Duras del `unidad-5/AGENTS.md` (mínimo privilegio, sin contraseñas reales en repo, sin `DELETE`, `AGENTS.md § Reglas 2,7,10,12,14`).

# Por archivo

## `unidad-5/sql/simulacro_incidente.ps1`

**Bien:**
- `unidad-5/sql/simulacro_incidente.ps1:41-42` bloquea `postgres` y `plantilla_food_store`.
- `unidad-5/sql/simulacro_incidente.ps1:44-48` pide `PassAdmin` como `SecureString`.
- `unidad-5/sql/simulacro_incidente.ps1:57` usa `ON_ERROR_STOP=0` para que el Paso 4 registre los 3 `ERROR:` sin abortar.
- `unidad-5/sql/simulacro_incidente.ps1:92,99,107` verifica conteos en vez de asumir éxito.

**Problemas:**
- `unidad-5/sql/simulacro_incidente.ps1:27-28`: `$PassApp='cambiar_en_produccion'` OK como marcador (Regla 12), pero `$PassSoporte='Sim-Soporte-2026'` es una clave inventada versionada en git. El SQL además fija `'ClaveSimulacro-2026'` (`unidad-5/sql/simulacro_incidente.sql:39`). Violan el espíritu de la Regla 12 (“solo marcadores”, `todos los scripts propios versionados`).
- `unidad-5/sql/simulacro_incidente.ps1:57`: `pass_soporte` viaja en la línea de comandos de `psql` (`-v`), visible con inspección de procesos; y el SQL lo materializa como `PASSWORD '...'` en texto claro en el log (`unidad-5/sql/simulacro_incidente.sql:44-48`). El warning de `unidad-5/sql/simulacro_incidente.sql:21-23` es correcto (anonimizar), pero reduce el riesgo, no lo elimina.
- El script no valida `log_statement='all'`; solo deja recordatorio (`unidad-5/sql/simulacro_incidente.ps1:81`). Si se olvida, los `SELECT` 1-3 no quedan en el log y la evidencia es incompleta.
- Paso 3 exige `>=20000` (`unidad-5/sql/simulacro_incidente.ps1:107`). Depende de haber cargado `carga_masiva.sql`; sin ella reporta `REVISAR` aunque el mecanismo funcione.
- `unidad-5/sql/simulacro_incidente.ps1:57-59` con `-f ('"{0}"' -f $sql)` es frágil con rutas con espacios y PowerShell 5. Sin espacios funciona.

## `unidad-5/sql/simulacro_incidente.sql`

**Bien:**
- `unidad-5/sql/simulacro_incidente.sql:37-41` usa `crypt()+gen_salt('bf')` real, correcto frente a los hash ficticios de `carga_masiva.sql`.
- `unidad-5/sql/simulacro_incidente.sql:83`: `SELECT id, nombre, apellido, mail, rol, eliminado, created_at` — excluye `contrasena`/`celular`, respeta Regla 13/14.
- `unidad-5/sql/simulacro_incidente.sql:90-98`: los 3 intentos de escalamiento son los correctos para demostrar `NOCREATEROLE`/`sin membresía ADMIN`.

**Problemas:**
- **No tiene guard de base** (compárese con `unidad-5/sql/auditoria_test.sql:15-20`). Todo el resguardo está en el `.ps1`. Si alguien lo corre a mano, puede tocar la plantilla.
- `unidad-5/sql/simulacro_incidente.sql:106`: `DELETE FROM usuario ...` contradice literalmente la Regla 2 (`nunca DELETE; siempre UPDATE eliminado=TRUE`). Como limpieza de fixture de prueba es defendible, pero queda como excepción no documentada. Debería llevar un comentario o cambiar a borrado lógico.
- `unidad-5/sql/simulacro_incidente.sql:44-48`: el `SELECT format(... PASSWORD %L) \gexec` deja la clave en texto claro en `log_statement=all`. No hay forma de `CREATE ROLE ... PASSWORD` sin loguearlo; la única mitigación es anonimizar, como advierte el propio encabezado.

## `unidad-5/sql/auditoria_test.ps1` y `unidad-5/sql/auditoria_test.sql`

**Bien:**
- Es la pareja más prolija: `.ps1:25-28` + `.sql:15-20` doble guard; `.sql:22,44` envuelve todo en `BEGIN...ROLLBACK`; marcadores `RAISE NOTICE` para recortar el log; ejecución separada `psql -f` para que cada sentencia tenga línea en el log.

**Problemas:**
- `unidad-5/sql/auditoria_test.ps1:43-45`: `Marca()` interpola `$texto` dentro de `SELECT '$texto'`. Con las constantes actuales es seguro, pero no es seguro por construcción.
- `unidad-5/sql/auditoria_test.ps1:51,53-56`: sin `$ErrorActionPreference='Stop'` ni chequeo de `LASTEXITCODE`; si falla el Paso 1, igual corre el Paso 2.
- `unidad-5/sql/auditoria_test.sql:26-40` corre como `postgres`, no como `app_web`. El comentario de `unidad-5/sql/auditoria_test.sql:26` dice “operación rutinaria de app_web”, pero la evidencia de log queda atribuida a `postgres`, no a `app_web`. Sirve para auditoría de formato, no para probar mínimo privilegio.
- No advierte anonimizar el log como hace `simulacro_incidente.sql` (Regla 14). `fn_autenticar('...','clave_incorrecta_1')` también queda textual.

## `unidad-5/sql/prueba_h1_correccion.ps1`

**Función:** demuestra que un `GRANT CREATE ON SCHEMA public TO app_web, rol_soporte` previo no sobrevive a `roles.sql`.

**Problemas (normativos):**
- Sin guard de base, sin `PGPASSWORD`, ruta hardcodeada `unidad-5\sql\roles.sql` (`unidad-5/sql/prueba_h1_correccion.ps1:4`) asumiendo CWD en raíz. Si se corre desde `unidad-5/`, falla silenciosamente.
- `unidad-5/sql/prueba_h1_correccion.ps1:6`: `Q()` concatena `2>&1` en stdout; no distingue error de éxito.
- `unidad-5/sql/prueba_h1_correccion.ps1:34`: no crea `unidad-5/evidencias/` si no existe; `WriteAllLines` tira.
- Verifica con `has_schema_privilege` (línea 19) pero sin assert programático; el humano debe leer `f`/`t`.

## `unidad-5/sql/prueba_h2b_hash.ps1`

**Bien:** compara `rolpassword` antes/después (`unidad-5/sql/prueba_h2b_hash.ps1:17,22`) y explica la sal aleatoria SCRAM (`unidad-5/sql/prueba_h2b_hash.ps1:30`). No persiste el hash completo en la evidencia (solo tipo `SCRAM-SHA-256$` + booleano) — buena disciplina.

**Problemas:** mismas fragilidades H1 (ruta hardcodeada PG17, sin guard, sin password, ruta relativa). Además `clave_historica_prueba` (`unidad-5/sql/prueba_h2b_hash.ps1:16`) es otra clave versionada, aunque sea descartable. Deja a `app_web` en `cambiar_en_produccion` (correcto como marcador).

## `unidad-5/sql/prueba_h3_correccion.ps1`

Tiene el mismo patrón frágil que H1. Idea correcta: `unidad-5/sql/prueba_h3_correccion.ps1:13` inyecta `GRANT rol_app_escritura TO rol_soporte`, re-ejecuta `roles.sql` y espera que desaparezca. Problemas:
- Query de membresías (`unidad-5/sql/prueba_h3_correccion.ps1:19`) filtra `LIKE 'rol_%'`; si `roles.sql` define membresías adicionales (`app_web` → grupo con otro nombre), el “esperado: solo 3” no es verificable sin leer `roles.sql` (fuera de los 10 archivos permitidos).
- Semántica de `has_function_privilege('rol_soporte', sp_crear_pedido)` (`unidad-5/sql/prueba_h3_correccion.ps1:21`) depende de si `sp_crear_pedido` es `SECURITY DEFINER`/`INVOKER`; no hay evidencia de que el `.ps1` lo asegure.

## `unidad-5/sql/prueba_h3_h4b.sql`

**Bien:** todo dentro de `BEGIN...ROLLBACK` (`unidad-5/sql/prueba_h3_h4b.sql:2,50`), `ON_ERROR_STOP on`, `DO` con `format('REVOKE %I FROM %I')` — vs. Regla 10, esto es `EXECUTE` seguro, no concatenación de input de usuario.

**Problemas:**
- `unidad-5/sql/prueba_h3_h4b.sql:18-31` revoca **todas** las membresías grupo→grupo en la sesión de prueba, no solo la `rol_app_escritura → rol_soporte` de H3. Como es `ROLLBACK`, no daña, pero si hay membresía legítima grupo→grupo (p. ej. `rol_soporte → rol_app_lectura`), el “antes”/“después” se interpreta mal.
- `unidad-5/sql/prueba_h3_h4b.sql:2,50` confirma que es diagnóstico, not corrección. Entonces el nombre `prueba_h3_h4b` vs. `correccion_h4b` vs. `prueba_h4b_trigger` confunde el rol de cada archivo.

## `unidad-5/sql/prueba_h4b_trigger.sql`

Test forense correcto: lee `prosecdef` (`unidad-5/sql/prueba_h4b_trigger.sql:2`) y prueba `CALL sp_crear_pedido` como `SET LOCAL ROLE app_web` con `ROLLBACK` (`unidad-5/sql/prueba_h4b_trigger.sql:4,13`). Frágil porque exige un `usuario` y un `producto disponible stock>0` existentes (`unidad-5/sql/prueba_h4b_trigger.sql:5-6`); en base vacía `:uid`/`:pid` quedan `NULL` y falla por dato, no por permiso. Además `SET LOCAL ROLE` + `RESET ROLE` dentro de una transacción (`unidad-5/sql/prueba_h4b_trigger.sql:7,10`) deja `current_user` posterior como ejecutor, lo que debe leerse con cuidado.

## `unidad-5/sql/correccion_h4b.sql`

Solo:
```sql
REVOKE EXECUTE ON FUNCTION ... FROM PUBLIC;
```
`unidad-5/sql/correccion_h4b.sql:5-6`

**Problemas:**
- Revoca `PUBLIC` sin `GRANT` compensatorio documentado. Si alguna de esas 4 rutinas precisaba `EXECUTE` para un rol de aplicación (p. ej. `calcular_total_pedido(bigint)` invocado por vistas/consultas), la corrección deja un hueco funcional. No hay verificación post-corrección.
- No cubre `sp_crear_pedido` (es `PROCEDURE`) ni `fn_autenticar`/`fn_resetear_password`. Si la idea es “quitar `EXECUTE` de `PUBLIC` a todo lo ejecutable”, esta lista es incompleta.
- Cita `unidad-5/evidencias/h2b_h4b_prueba.txt` sin prefijo `obj6_` que usan H1/H2b/H3 (`obj6_H1...`, `obj6_H2b...`, `obj6_H3...`). Inconsistencia de trazabilidad.

# Inconsistencias transversales

| Eje | Estado | Archivos |
|---|---|---|
| Guard `plantilla_food_store` | Solo auditoría (ps1+sql) y simulacro (ps1). H1/H2b/H3/H3_h4b/H4b_trigger sin guard | Todos |
| Psycopg / `psql` | Simulacro por defecto `psql`, auditoría PG17, H1/H2b/H3 PG17 hardcodeado | `simulacro_incidente.ps1:21`, `auditoria_test.ps1:19`, `prueba_h1_correccion.ps1:2` |
| Contraseñas versionadas | `Sim-Soporte-2026`, `ClaveSimulacro-2026`, `clave_historica_prueba`, `clave_incorrecta_audit_test` | Simulacro, H2b, Auditoría |
| Manejo de errores | Simulacro verifica resultado; H1/H2b/H3 solo vuelcan texto | Todos los `.ps1` |
| Rutas | `$PSScriptRoot` vs `$MyInvocation` vs CWD relativo | `simulacro`, `auditoria`, `H1/H2b/H3` |

# Plan propuesto (no implementado, Plan mode)

1. **Guard SQL universal:** copiar el bloque `DO $$ IF current_database() IN ('postgres','plantilla_food_store') ...` de `auditoria_test.sql:15-20` a `simulacro_incidente.sql`, `prueba_h3_h4b.sql`, `prueba_h4b_trigger.sql` y envolver los `.ps1` de corrección con validación de `$base` idéntica a `auditoria_test.ps1:25-28`.
2. **Claves:** dejar en repo solo `cambiar_en_produccion` como marcador; pedir `PassSoporte` por prompt (`-AsSecureString`) igual que `PassAdmin`; documentar que el `CREATE ROLE ... PASSWORD` de `simulacro_incidente.sql:44-48` se ejecuta logueado y requiere anonimizar el extracto (Reglas 12/14).
3. **Unificar `psql`:** un único parámetro `-Psql` con default `psql`, detección de versión rápida y ruta por `$PSScriptRoot` en todos los scripts.
4. **`DELETE` del Paso 9:** agregar comentario `excepción justificada de fixture de prueba` junto a `simulacro_incidente.sql:106` o migrar a `UPDATE eliminado` + limpieza de rol.
5. **`correccion_h4b.sql`:** agregar verificación post-corrección (`has_function_privilege`) y aclarar si `sp_crear_pedido` (procedure), `fn_autenticar` y `fn_resetear_password` deben salir de `PUBLIC` o quedan fuera de alcance.
6. **Aserciones:** convertir los `REVISAR` visuales de H1/H3 en salidas `OK/FAIL` automáticas antes de escribir la evidencia.

¿Querés que priorice el lote de seguridad (guards + claves) o el de robustez (rutas/`psql`/aseveraciones)? Para implementarlo necesito que cambies de agente desde el planificador, ya que sigo en Plan mode y no puedo editar.