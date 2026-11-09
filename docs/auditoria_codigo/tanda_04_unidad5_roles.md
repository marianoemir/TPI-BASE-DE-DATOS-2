# Tanda 04 — unidad-5/sql (roles y verificaciones)

Herramienta: OpenCode (modo Plan, solo lectura)
Modelo: Croutou Alpha Free
Fecha y hora: <8/11/2026, 23:05>
Archivos (4):
- unidad-5/sql/roles.sql
- unidad-5/sql/verificacion_roles.sql
- unidad-5/sql/usuario_anon.sql
- unidad-5/sql/verificacion_equivalencia.sql
Prompt: ver prompt_base.md (solo cambia la lista de archivos)
Estado: <corrida completa / cortada / con error>
Total de hallazgos devueltos: <n>
Estado del repo: rama review-final, etiqueta pre-review (351ddb9)

---

Revisión estática en modo solo lectura: no ejecuté ni modifiqué nada. Solo los 4 archivos indicados. No hay ninguno sin hallazgos.

### `unidad-5/sql/roles.sql`

**H-01 — roles.sql:20 — Protección por blacklist, no por whitelist. Severidad: media**
```sql
IF current_database() IN ('postgres', 'plantilla_food_store') THEN
```
Solo bloquea dos bases; correrlo en `copia_trabajo` o `copia_u4` aplicaría roles y cambios de dueño en la base equivocada. La cabecera (línea 6) dice "conectado a copia_u5 como postgres" pero el código no lo impone.
*Cómo corregir:* `IF current_database() <> 'copia_u5' THEN RAISE EXCEPTION ...`.

**H-02 — roles.sql:64, 68 — `admin_datos` y `app_web` comparten `PASSWORD 'cambiar_en_produccion'`. Severidad: alta**
Ambos logins quedan con la misma contraseña marcador, versionada en el repo. Si alguno se compromete, el otro queda igual de expuesto. La regla 12 admite marcadores, pero no que sean idénticos y versionados como dato secreto.
*Cómo corregir:* generar contraseñas distintas fuera del archivo (`DO` con `md5(random()::text)` o env), o dejarlas solo como comentario de ejemplo y no como valor real en `CREATE ROLE`.

**H-03 — roles.sql:240-243 — `ALTER DEFAULT PRIVILEGES` solo para `admin_datos`, no para el dueño real de los objetos. Severidad: alta**
```sql
ALTER DEFAULT PRIVILEGES FOR ROLE admin_datos IN SCHEMA public ...
ALTER DEFAULT PRIVILEGES FOR ROLE admin_datos REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
```
Las tablas/funciones heredadas las creó whoever corrió `schema.sql`/`objects.sql` (normalmente `postgres`). El propio `AGENTS.md` advierte de esto. Un objeto creado después por `postgres` vuelve a dar `EXECUTE` a `PUBLIC` por omisión global: el parche H4b (línea 248) solo corrige los 4 objetos actuales.
*Cómo corregir:* también `FOR ROLE postgres` o `FOR ROLE CURRENT_ROLE`, y verificar creando tabla/función de prueba como lo sugiere la tabla de diferencias del `AGENTS`.

**H-04 — roles.sql:108-111 — Funciones de triggers sin `SET search_path`. Severidad: media**
`calcular_total_pedido`, `fn_set_subtotal`, `fn_recalcular_total`, `fn_validar_estado_pedido` se transfieren a `admin_datos` pero no reciben `SET search_path = public, pg_temp`. Sí lo hacen `sp_crear_pedido` (128-129), `fn_autenticar` y `fn_resetear_password`, que son `SECURITY DEFINER`. Para funciones `SECURITY INVOKER`/`DEFINER` inconsistentes, la regla 11 pide el fijo en todas.
*Cómo corregir:* `ALTER FUNCTION fn_set_subtotal() SET search_path = public, pg_temp;` y lo mismo para las otras.

**H-05 — roles.sql:141-147 — `fn_autenticar` no maneja hashes ficticios. Severidad: media**
```sql
AND u.contrasena = crypt(p_pass, u.contrasena)
```
`carga_masiva.sql`/`data.sql` dejan hashes como `'$2a$10$...hash_ficticio'` y `'hash_ana'`. `crypt()` sobre un salt inválido lanza error o devuelve NULL según versión; la función deja propagar el error y rompe el login en vez de devolver 0 filas. El `AGENTS.md` (tabla de diferencias) dice que hay que crear usuarios de prueba con `crypt('…', gen_salt('bf'))` justamente por esto.
*Cómo corregir:* envolver en `BEGIN ... EXCEPTION WHEN OTHERS THEN RETURN; END;` o validar el formato del hash antes.

**H-06 — roles.sql:154-166 — `fn_resetear_password` sin validación de nueva clave. Severidad: media**
```sql
UPDATE usuario SET contrasena = crypt(p_nueva, gen_salt('bf'))
WHERE id = p_usuario_id AND eliminado = FALSE AND rol <> 'ADMIN';
```
`p_nueva = ''` genera hash válido de contraseña vacía; `p_usuario_id` inexistente hace `UPDATE 0` silencioso (`VOID` sin aviso). `rol_soporte` puede tomar cualquier cuenta no-ADMIN con cualquier valor conocido.
*Cómo corregir:* `IF p_nueva IS NULL OR length(p_nueva) < 8 THEN RAISE EXCEPTION ...; END IF;` y `GET DIAGNOSTICS` para avisar si `row_count=0`.

**H-07 — roles.sql:248-249 — REVOKE de `EXECUTE` sobre funciones de trigger, efecto no verificado. Severidad: baja**
No estoy 100% seguro de si revocar `EXECUTE` a `PUBLIC` sobre `fn_set_subtotal()` etc. rompe los triggers para `app_web`. Mi lectura es que el trigger se dispara con privilegios del dueño de la tabla y no necesita `EXECUTE` del sesión, pero el archivo no lo demuestra con un test.
*Cómo verificar:* T04 de `verificacion_roles.sql` calla si `sp_crear_pedido` (SECURITY DEFINER) dispara triggers y no falla. Si falla, el test debería dar `error:` y el hallazgo subiría a alta.

### `unidad-5/sql/verificacion_roles.sql`

**H-08 — verificacion_roles.sql:30-41 — `probar()` ejecutesión dinámica sin `USING`, contra Regla 10. Severidad: media**
```sql
EXECUTE format('SET LOCAL ROLE %I', p_rol); EXECUTE p_sql;
```
`p_sql` viaja como texto y se ejecuta, no como parámetro. Los casos de prueba usan literales `'EFECTIVO'`, `'test@test.com'`, `'NuevaClave123'` (líneas 65-68, 76, 86). Como es harness de prueba y no función de producción, el riesgo es bajo, pero la regla 10 dice "nunca concatenación".
*Cómo corregir:* solo para prueba; dejar constancia en `BITACORA.md` de que es excepción deliberada, o usar `EXECUTE ... USING` donde haya variables.

**H-09 — verificacion_roles.sql:17-18, 86, 103 — Contraseña de prueba en texto plano. Severidad: baja**
```sql
'NuevaClave123'
```
La cabecera ya avisa que no correr con `log_statement` activo, pero si se comparte el log, la clave queda expuesta. Es el mismo patrón que prohíbe la Regla 14.
*Cómo corregir:* generar la clave de prueba como `crypt('NuevaClave123', gen_salt('bf'))` sin dejar `'NuevaClave123'` literal en el log, o documentar que ese log es sensible.

**H-10 — verificacion_roles.sql:60-104 — Cobertura incompleta: no prueba `CREATE` ni `EXECUTE` público. Severidad: media**
Se prueban 23 casos, pero ninguno verifica que `app_web`/`rol_app_*` no puedan `CREATE TABLE public.temp` tras el `REVOKE CREATE` (líneas 84-87 de `roles.sql`), ni que no puedan ejecutar `calcular_total_pedido()` tras H4b (líneas 248-249). El `H1/H3/H4b` citados en `roles.sql` quedan sin test en este archivo.
*Cómo corregir:* agregar `T24: CREATE TABLE public.x` esperado `denegado`, y `T25: SELECT calcular_total_pedido(1)` esperado `denegado`.

**H-11 — verificacion_roles.sql:75-77 — T07 solo verifica ejecución, no éxito de login. Severidad: baja**
`fn_autenticar('test@test.com','clave')` espera `'ok'`, es decir, que la función no lance error, aunque devuelva 0 filas. Un login exitoso real nunca se prueba.
*Cómo corregir:* crear usuario de prueba con `crypt('…', gen_salt('bf'))` fuera de la tabla `usuario` real y verificar `filas` con la clave correcta y `sin_filas` con la incorrecta.

### `unidad-5/sql/usuario_anon.sql`

**H-12 — usuario_anon.sql:16-25 — `CREATE TABLE AS` pierde tipos y constraints. Severidad: media**
```sql
CREATE TABLE usuario_anon AS
SELECT id, 'Usuario '||id AS nombre, ... rol, eliminado, created_at FROM usuario;
```
`nombre`/`mail` pasan a `TEXT` (no `VARCHAR(80)/VARCHAR(120)`), `celular` es `VARCHAR` sin `(30)`, se pierden `NOT NULL`, `UNIQUE(mail)` y el `CHECK` de formato. La tabla anonimizada diverge en esquema de la real.
*Cómo corregir:* crear tabla con DDL explícito igual al de `usuario` y luego `INSERT INTO ... SELECT` con las expresiones sintéticas.

**H-13 — usuario_anon.sql:14 — `DROP TABLE IF EXISTS` sin transacción. Severidad: baja**
Todo `roles.sql` va en `BEGIN...COMMIT`; este archivo dropea y luego hace `CTAS`. Si el `SELECT FROM usuario` falla tras el `DROP`, la tabla queda sin nada.
*Cómo corregir:* envolver en `BEGIN; ... COMMIT;`.

**H-14 — usuario_anon.sql:10-11 — Cabecera dice "solo rol, eliminado, created_at" pero crea todas las columnas. Severidad: baja**
Inconsistencia documental: el encabezado promete minimización mayor que la implementada (`id, nombre, apellido, mail, celular, contrasena` sintéticos también).
*Cómo corregir:* corregir el comentario o eliminar las columnas no necesarias para el análisis agregado.

### `unidad-5/sql/verificacion_equivalencia.sql`

**H-15 — verificacion_equivalencia.sql:30-31, 48-51 — `FULL JOIN` no coincide si hay `NULL`. Severidad: baja**
```sql
FROM r FULL JOIN a ON r.rol = a.rol AND r.mes_alta = a.mes_alta
```
Si `created_at` fuera `NULL`, `NULL = NULL` es `NULL` y el join produce dos filas en vez de una comparada. Hoy `created_at` es `NOT NULL` por `schema.sql`, pero es frágil si cambia.
*Cómo corregir:* `ON r.rol IS NOT DISTINCT FROM a.rol AND r.mes_alta IS NOT DISTINCT FROM a.mes_alta`, igual que ya se usa en línea 29 para `r.n`.

**H-16 — verificacion_equivalencia.sql:6-52 — No aserta, solo muestra. Severidad: baja**
Las 4-5 consultas devuelven `coincide` o `0 filas` pero nada `RAISE EXCEPTION` si no coinciden. El evaluador debe verlo a ojo.
*Cómo corregir:* envolver la consulta 3 en `DO $$ ... RAISE EXCEPTION IF EXISTS (SELECT 1 FROM ... WHERE NOT coincide); END $$;`.

