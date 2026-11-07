# Auditoría de `roles.sql` con OpenCode (objetivo 6)

Fecha de las decisiones: 2026-11-07. Base de pruebas: `copia_u5`, PostgreSQL 17.10.
Responsable: Mariano Chirino (T2). Rama: `m/obj-06`.

## 1. Qué se hizo

Se repitió la auditoría de `unidad-5/sql/roles.sql` contra `unidad-5/docs/kiro_roles_spec/design.md` con OpenCode en modo Plan (solo lectura). Cada hallazgo se reprodujo en `copia_u5` antes de decidir. Ningún hallazgo se aceptó ni se descartó solo por la lectura.

| Dato | Valor |
|---|---|
| Herramienta y modelo | OpenCode, Nemotron 3.5 Lightning |
| Fecha | 2026-11-07 (las horas de las partes no constan con exactitud) |
| Carpeta de trabajo | `C:\auditoria_roles` (solo `roles.sql` y `design.md`, copia idéntica a `unidad-5`) |
| Prompt y respuesta cruda | `unidad-5/docs/registro_opencode_auditoria_roles_corrida2.txt` |
| Hallazgos devueltos por OpenCode | **5** (1 alto, 3 medio, 1 bajo) |
| Hallazgos de otro origen | **1** (H4b, revisión con Claude; no lo devolvió OpenCode) |

Las líneas que cita OpenCode corresponden a la versión de `roles.sql` auditada (238 líneas), anterior a los cambios de esta rama.

## 2. Resumen de decisiones

| Id | Origen | Severidad (OpenCode) | Resumen | Decisión | Evidencia |
|---|---|---|---|---|---|
| H1 | OpenCode #1 | alto | Roles de aplicación podrían conservar `CREATE` sobre `public` | Aceptado y corregido (no se reproduce en la copia limpia; sí con un `GRANT` previo) | `evidencias/obj6_H1_create_schema_public.txt` (estado limpio), `obj6_H1_despues_de_correccion.txt` (después) |
| H2 | OpenCode #2 | medio | Re-ejecutar `roles.sql` no restablece la contraseña de los logins | Descartado como defecto | `evidencias/obj6_H2b_hash_repetido.txt` |
| H3 | OpenCode #3 | medio | No se revocan membresías entre roles de grupo | Aceptado y corregido | `evidencias/obj6_H3_membresias_entre_grupos.txt` (antes), `obj6_H3_despues_de_correccion.txt` (después) |
| H4 | OpenCode #4 | medio | `REVOKE ALL … FROM PUBLIC` no cubriría un `EXECUTE` indirecto | Descartado | `evidencias/obj6_H4_execute_public.txt` |
| H5 | OpenCode #5 | bajo | Falta verificación interna de `ALTER DEFAULT PRIVILEGES` | Descartado | `evidencias/obj6_H5_default_privileges.txt` |
| H4b | Revisión con Claude | — | Cuatro rutinas anteriores conservan `EXECUTE` para `PUBLIC` | Aceptado y corregido | `evidencias/obj6_H4b_rutinas_viejas_public.txt`, `h3_h4b_prueba.txt`, `h4b_aplicado.txt`, `h4b_permisos_despues.txt`, `h4b_trigger_como_app_web.txt`, `t01_t23_roles_final.txt` |

Resultado: de los 5 hallazgos de OpenCode, 3 se descartaron tras reproducirlos (H2, H4, H5) y 2 se aceptaron y se corrigieron (H1, H3). Los dos aceptados dependían de residuos en una base sucia, que la copia limpia no mostraba. Además se corrigió H4b, que no salió de OpenCode.

## 3. Detalle por hallazgo

### 3.1 H1 (alto): `CREATE` sobre `public` para roles de aplicación

**Qué dijo OpenCode.** Solo se revoca `CREATE` de `PUBLIC`. Si la base ya tuviera un `GRANT CREATE ON SCHEMA public` a algún rol de aplicación, sobreviviría y permitiría crear objetos que sombreen a los del proyecto.

**Cómo se probó (estado limpio).** Se consultó `nspacl` de `public` y `has_schema_privilege(..., 'CREATE')` para los siete roles, y se intentó `CREATE TABLE public.prueba_priv(o int)` dentro de `BEGIN … ROLLBACK` como `app_web` y como `rol_soporte`.

**Resultado (estado limpio).** Solo `admin_datos` (y el pseudo-rol `pg_database_owner`) tienen `UC`; los demás tienen solo `U`. `has_schema_privilege` da `f` para los seis roles de aplicación y `t` para `admin_datos`. Ambos `CREATE TABLE` fallan con «permiso denegado al esquema public». Con la copia limpia el hallazgo no se reproduce (`obj6_H1_create_schema_public.txt`).

**Cómo se probó (base sucia).** Se concedió `CREATE ON SCHEMA public` a `app_web`, se re-ejecutó `roles.sql` y se consultó `has_schema_privilege('app_web','public','CREATE')`. Dio `t`: el privilegio sobrevive, porque `roles.sql` solo revocaba `CREATE` de `PUBLIC`. Con esto el escenario de OpenCode se reproduce.

**Decisión.** Aceptado y corregido. Se agregó a `roles.sql`, justo después de `GRANT USAGE, CREATE ON SCHEMA public TO admin_datos`, un `REVOKE CREATE ON SCHEMA public` de los seis roles de aplicación. Solo `admin_datos` conserva `CREATE`.

**Cómo se probó (después).** Con el script `unidad-5/sql/prueba_h1_correccion.ps1` se concede `CREATE` a `app_web` y `rol_soporte`, se re-ejecuta `roles.sql` y se verifica (`obj6_H1_despues_de_correccion.txt`): código de salida 0, `f` para los seis roles de aplicación, `t` para `admin_datos`, dos «permiso denegado al esquema public» y ninguna tabla creada. T01 a T23 se repitieron con la corrección aplicada: 23/23 `OK` (`t01_t23_roles_final.txt`).

**Límites.**
- La prueba de base sucia previa a la corrección se ejecutó en consola y no se guardó su salida; el resultado (`t`) se declara aquí. La evidencia reproducible es la posterior.
- No se probaron concesiones hechas con `GRANT OPTION` por otros otorgantes.

### 3.2 H2 (medio): la contraseña no se restablece al re-ejecutar

**Qué dijo OpenCode.** Los `IF NOT EXISTS` omiten la creación de los logins y los `ALTER ROLE` no tocan la contraseña, así que una re-ejecución sobre una base sucia deja la clave vieja. Propone fijarla incondicionalmente.

**Cómo se probó.**
1. `obj6_H2_password_reejecucion.txt`: se puso una clave distinta a `app_web`, se re-ejecutó `roles.sql` y se probó el login con la clave histórica y con el marcador. **Esta prueba no discrimina:** `pg_hba.conf` de la copia usa `trust` en todas las líneas, y ambos logins entran sin verificar la contraseña. El propio archivo lo anticipa.
2. `obj6_H2b_hash_repetido.txt` (script `unidad-5/sql/prueba_h2b_hash.ps1`): se parte de una clave distinta del marcador, se mide el hash SCRAM, se re-ejecuta `roles.sql` y se vuelve a medir. SCRAM usa sal aleatoria, de modo que cualquier `ALTER ROLE … PASSWORD` cambiaría el hash aunque la clave fuera la misma.

**Resultado.** Código de salida 0 y hash idéntico antes y después. `roles.sql` no toca la contraseña de un login existente.

**Decisión.** Descartado como defecto. Es el comportamiento seguro: la corrección propuesta haría que una re-ejecución sobre un servidor real sobrescribiera la clave verdadera con el marcador `'cambiar_en_produccion'`, que es público.

**Límites.**
- Un rol que el script crea desde cero nace con el marcador, público en el repositorio, hasta que alguien lo cambie.
- Con `trust` en `pg_hba.conf`, T01 a T23 verifican permisos, no autenticación. En producción haría falta `scram-sha-256`.
- La primera medición del hash (`obj6_H2b_hash_password.txt`) se generó con un script pegado a mano, sin guardar, y no consta con qué clave se partió. Se conserva como primera corrida; la evidencia citada es la repetida.

### 3.3 H3 (medio): membresías entre roles de grupo

**Qué dijo OpenCode.** La limpieza de membresías (líneas 202 a 206 de la versión auditada) revoca `admin_datos` de los seis roles y `rol_soporte`, `rol_reportes` de `app_web`, pero no las membresías entre grupos. Un `GRANT rol_app_escritura TO rol_soporte` heredado daría a `rol_soporte` el `EXECUTE` sobre `sp_crear_pedido`.

**Cómo se probó (antes).** Se concedió `rol_app_escritura` a `rol_soporte`, se re-ejecutó `roles.sql` y se consultó `pg_auth_members` y `has_function_privilege('rol_soporte', …)` sobre `sp_crear_pedido` (`obj6_H3_membresias_entre_grupos.txt`).

**Resultado (antes).** La membresía sobrevivió a `roles.sql` (4 filas en lugar de las 3 de `app_web`) y `rol_soporte` pudo ejecutar `sp_crear_pedido` (`t`), lo que viola el «ni más, ni menos» del diseño. El hallazgo se reproduce.

**Decisión.** Aceptado y corregido. Se agregó a `roles.sql`, en el Paso 8 y antes del `GRANT` final, un bloque `DO` que revoca todas las membresías entre los cinco roles de grupo. Las tres membresías de `app_web` se conceden después, por lo que no se ven afectadas.

**Cómo se probó (después).** Con el script `unidad-5/sql/prueba_h3_correccion.ps1` se repite la misma siembra y se re-ejecuta `roles.sql` (`obj6_H3_despues_de_correccion.txt`): código de salida 0, exactamente 3 membresías (`rol_app_auth`, `rol_app_escritura` y `rol_app_lectura`, las tres con `app_web`) y `rol_soporte` ya no ejecuta `sp_crear_pedido` (`f`). El `REVOKE` de limpieza final avisa que la membresía de prueba ya no existía, lo que confirma que `roles.sql` la había quitado. T01 a T23 se repitieron con la corrección aplicada: 23/23 `OK` (`t01_t23_roles_final.txt`).

**Límite.** El `REVOKE` quita las concesiones hechas por el rol que ejecuta el script (`postgres`, según los avisos de PostgreSQL). Una membresía concedida por otro rol como otorgante no se probó y podría no quitarse. El bloque también revoca cualquier membresía entre grupos, intencional o no; el diseño no prevé ninguna.

### 3.4 H4 (medio): `REVOKE ALL … FROM PUBLIC` y el camino indirecto

**Qué dijo OpenCode.** Que `REVOKE ALL FROM PUBLIC` no revocaría privilegios concedidos a través de roles, y que `PUBLIC` podría retener `EXECUTE` sobre las tres rutinas del proyecto.

**Cómo se probó.** Consulta a `information_schema.role_routine_grants` por `grantee = 'PUBLIC'` sobre `sp_crear_pedido`, `fn_autenticar` y `fn_resetear_password`, y `has_function_privilege('app_web', …)` sobre todas las rutinas del esquema.

**Resultado.** 0 filas para `PUBLIC` en las tres rutinas. `app_web` ejecuta `sp_crear_pedido` y `fn_autenticar` (por `rol_app_escritura` y `rol_app_auth`, como pide el diseño) y no ejecuta `fn_resetear_password`.

**Decisión.** Descartado. Un privilegio concedido a `rol_app_auth` es intencional y no lo afecta un `REVOKE … FROM PUBLIC`; la explicación de OpenCode no se corresponde con el modelo de privilegios de PostgreSQL.

### 3.5 H5 (bajo): verificación de `ALTER DEFAULT PRIVILEGES`

**Qué dijo OpenCode.** El `ALTER DEFAULT PRIVILEGES … REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC` debería verificarse, y afirma que desde PostgreSQL 15 el valor por omisión es `NONE`.

**Cómo se probó.** En `BEGIN … ROLLBACK`, se creó una función como `admin_datos` y otra como `postgres` (control) en un esquema temporal y se consultó `has_function_privilege('app_web', …)`.

**Resultado.** La función creada por `admin_datos` no es ejecutable por `app_web` (`f`); la de control creada por `postgres` sí (`t`). El esquema temporal no quedó.

**Decisión.** Descartado como defecto: los privilegios por omisión funcionan para el rol que los declara. La afirmación sobre PostgreSQL 15 no se sostiene: la función de control confirma que `EXECUTE` para `PUBLIC` sigue siendo el valor por omisión; lo que cambió en la versión 15 fue `CREATE` sobre `public`.

**Límite.** Los privilegios por omisión están declarados solo `FOR ROLE admin_datos`. Las funciones creadas por otros roles (por ejemplo `postgres`) nacen abiertas; es la causa de H4b.

### 3.6 H4b (origen: revisión con Claude): rutinas anteriores con `EXECUTE` para `PUBLIC`

**Hallazgo.** La segunda consulta de H4 mostraba que `calcular_total_pedido(bigint)`, `fn_set_subtotal()`, `fn_recalcular_total()` y `fn_validar_estado_pedido()` tenían `=X` (es decir, `PUBLIC`) en `proacl`, y que `app_web` podía ejecutarlas sin ningún `GRANT` que lo autorizara. No lo devolvió OpenCode.

**Cómo se probó.** `has_function_privilege('app_web', …)` en las cuatro, antes y después del `REVOKE` (dentro de `BEGIN … ROLLBACK` y luego aplicado), T01 a T23 y la creación de un pedido como `app_web`.

**Resultado.**
- Antes: `t`, `t`, `t`, `t`. Después del `REVOKE`: `f`, `f`, `f`, `f`.
- T01 a T23 dan 23/23 `OK` antes y después, sin diferencias (`t01_t23_antes_h4b.txt`, `t01_t23_despues_h4b.txt`, `t01_t23_roles_final.txt`).
- Crear un pedido como `app_web` con el `REVOKE` aplicado funciona y el trigger calcula el total (pedido de prueba con total 3500.00, revertido con `ROLLBACK`; `h4b_trigger_como_app_web.txt`).

**Decisión.** Aceptado y corregido: el `REVOKE EXECUTE … FROM PUBLIC` está en `roles.sql`, dentro de la transacción y antes del `COMMIT`.

**Límite.** `sp_crear_pedido` es `SECURITY DEFINER`, así que la prueba no ejercita una ruta en la que `app_web` dispare las funciones con sus propios permisos. Esa ruta no existe hoy en la aplicación; si se agregara un procedimiento que no sea `SECURITY DEFINER` y las llamara, necesitaría un `GRANT` explícito. Una función nueva creada por un rol distinto de `admin_datos` nacería otra vez abierta (ver 3.5).

## 4. Límites generales

- Todas las pruebas se hicieron en `copia_u5`, con `pg_hba.conf` en `trust`: verifican permisos, no autenticación.
- La respuesta de OpenCode llegó en tres partes por dos interrupciones. Los mensajes de las interrupciones se redactaron con asistencia de Claude y no forman parte del prompt original. El texto pasó por un chat al copiarse y no se comparó carácter por carácter con la pantalla de OpenCode.
- El resumen de la parte 2 afirma que el hallazgo 4 ya había sido reportado, aunque en la parte 1 quedó truncado; su texto completo llegó en la parte 3.
- La auditoría original (anterior a esta repetición) no conserva su respuesta cruda; este documento y su registro cubren solo la repetición.
- Los hallazgos de OpenCode se evaluaron contra `design.md` y `roles.sql`; no se auditaron los demás scripts de la unidad (eso corresponde al code review del objetivo 13).

## 5. Trazabilidad

- Cinco evidencias de H3/H4b (`h3_h4b_prueba.txt`, `h4b_aplicado.txt`, `h4b_permisos_despues.txt`, `t01_t23_antes_h4b.txt`, `t01_t23_despues_h4b.txt`) se generaron con `Tee-Object` (UTF-16) y se reencodearon a UTF-8 sin cambiar su contenido (commit `6346e09`).
- Las pruebas reproducibles quedaron como scripts: `unidad-5/sql/prueba_h3_h4b.sql`, `prueba_h4b_trigger.sql`, `prueba_h2b_hash.ps1`, `prueba_h3_correccion.ps1` y `prueba_h1_correccion.ps1`.
- Ningún dato real se envió a OpenCode: se le pasaron solo `roles.sql` y `design.md`.
- H4b se detectó en una revisión hecha con Claude. Las decisiones sobre todos los hallazgos son del autor del informe.
