# SPEC_U6_ampliacion — Cierre del objetivo 7

**Estado:** propuesta para implementar y probar en el servidor local de Andres.

**Fecha:** 2026-11-07.
**Complementa:** `SPEC_U6.md`; no modifica ni reemplaza la evidencia historica de la Unidad 6.

## 1. Objetivo y alcance

Completar el plan de mantenimiento de `foodstore` (PostgreSQL 17 local) para que el respaldo, el mantenimiento y la restauracion de prueba sean repetibles y verificables. La base productiva del laboratorio se lee solamente; las acciones destructivas se limitan a `foodstore_restore_test`.

No se modifican los objetos funcionales de Food Store, los triggers ni los datos. No se incorporan contrasenas, respaldos ni archivos de `pgpass.conf` al repositorio.

## 2. Cambios previstos

| Componente | Cambio | Resultado verificable |
|---|---|---|
| `crear_rol_respaldo.sql` | Crear el rol de login `operador_respaldo`, sin atributos administrativos, y otorgar solo los privilegios necesarios para leer `foodstore`. | El rol no es SUPERUSER, no puede crear roles ni bases y el respaldo de `foodstore` termina correctamente. |
| `backup_foodstore.ps1` | Ejecutar el dump de `foodstore` con `operador_respaldo`; generar y verificar el hash; generar un respaldo separado de objetos globales con `pg_dumpall --globals-only --no-role-passwords`. | Existen un `.dump`, su `.sha256`, un archivo de globales y su hash; el log registra cada validacion. |
| `restore_test.ps1` | Verificar SHA-256 antes de restaurar; comparar automaticamente conteos origen/destino; ejecutar controles de integridad y registrar el resultado. | Un hash alterado aborta antes de `createdb`/`pg_restore`; una restauracion valida compara conteos e informa OK. |
| `validar_integridad.sql` | Definir consultas reutilizables para claves foraneas huerfanas y controles logicos. | Cada control devuelve `0`; un resultado distinto de cero hace fallar la restauracion. |
| `programar_tareas.ps1` | Registrar tareas de Windows para respaldo diario, mantenimiento semanal y restauracion de prueba periodica. | `Get-ScheduledTask` muestra las tres tareas; al menos una se ejecuta bajo demanda y queda registrada por Windows y en su log. |
| `maintenance.sql` | Conservar su observacion de solo lectura en `foodstore` y el ensayo en la copia descartable; documentar su frecuencia semanal. | La tarea semanal ejecuta el script por `psql -f`, sin usar `VACUUM FULL`. |

## 3. Seguridad y roles

### 3.1 Rol de respaldo

`operador_respaldo` es un rol de login local, sin `SUPERUSER`, `CREATEDB`, `CREATEROLE`, `REPLICATION` ni `BYPASSRLS`. Tendrá `CONNECT` sobre `foodstore`, `USAGE` sobre los esquemas requeridos y privilegios de lectura sobre los objetos existentes. Los privilegios por defecto se ajustarán para objetos futuros creados por el dueño de los objetos.

El script debe comprobar los atributos del rol antes de ejecutar el respaldo. La contraseña no se escribe en scripts: se usa la entrada correspondiente de `%APPDATA%\postgresql\pgpass.conf` y las herramientas se invocan con `-w`.

### 3.2 Respaldo de objetos globales

`pg_dump` no incluye roles ni tablaspaces. Se ejecutará además `pg_dumpall --globals-only --no-role-passwords` para conservar definiciones de roles sin exportar hashes de contraseñas. Ese archivo es SQL sensible: se guarda en `backups/`, fuera de Git, con hash SHA-256 y referencia en la evidencia, pero no se comparte con una IA.

La restauracion automatizada **no** ejecutará ese SQL global contra el servidor, porque crear o alterar roles es una accion global y puede afectar otras bases locales. La prueba de restauracion verifica su existencia e integridad. Para verificar los permisos de la Unidad 5 en `foodstore_restore_test`, se ejecutará `unidad-5/sql/roles.sql` de forma manual, leida previamente y solo si el equipo confirma que esa copia contiene los objetos esperados; despues se corre `unidad-5/sql/verificacion_roles.sql`. Esta separacion evita que una tarea programada modifique roles del servidor sin supervision humana.

## 4. Frecuencias y retencion

| Tarea | Frecuencia | Cuenta de ejecucion | Exito |
|---|---|---|---|
| Respaldo de datos y globales | Diaria, 02:00 | `operador_respaldo` para `pg_dump`; la generacion de globales requiere la cuenta administrativa configurada en `pgpass.conf` | Dump valido, hashes presentes y log con `RESULTADO: OK`. |
| Salud | Diaria, despues del respaldo | Cuenta de solo lectura configurada para `psql` | `health_check.sql` termina con codigo 0 y guarda salida en `evidencias/` o log local. |
| Mantenimiento | Semanal | Cuenta administrativa local, porque el ensayo usa la base descartable | Revision de `foodstore` de solo lectura y accion solo en `foodstore_restore_test`. |
| Restauracion de prueba | Semanal | Cuenta administrativa local sobre la base descartable | Hash, restauracion, conteos, amcheck e integridad correctos. |

La retencion elimina respaldos de datos, hashes y globales con mas de **14 dias**, pero conserva siempre el ultimo conjunto valido. Un conjunto valido es el que contiene el dump, su hash, el archivo globales y su hash, y cuya huella coincide antes de borrados. Los archivos `.parcial` nunca se consideran validos.

## 5. Restauracion e integridad

1. Se selecciona el ultimo conjunto de respaldo valido; se ignoran `.parcial`.
2. Se calcula SHA-256 de cada archivo y se compara contra su archivo `.sha256`. Si alguno difiere, se registra `ERROR` y se termina antes de eliminar o crear `foodstore_restore_test`.
3. Solo si los hashes son validos, se elimina (si existe) y crea `foodstore_restore_test`; nunca se elimina ni crea `foodstore`.
4. Se restaura el dump con `pg_restore --no-owner --no-privileges`.
5. Se ejecuta `ANALYZE` sobre la copia restaurada y `pg_amcheck` sin opciones que soliciten bloqueos fuertes adicionales. Una falla de `pg_amcheck` hace fallar el simulacro.
6. Se comparan automaticamente, desde el script, los conteos de `categoria`, `usuario`, `producto`, `pedido` y `detalle_pedido` entre `foodstore` y `foodstore_restore_test`; cada diferencia hace fallar el simulacro.
7. Se comprueban valores invalidos y claves foraneas huerfanas en la copia restaurada. Todos deben dar cero.
8. Se registra RTO desde antes de crear la copia hasta el final de los controles; se registra RPO como la antiguedad real del dump seleccionado.

## 6. Casos de prueba requeridos antes de programar

| ID | Caso | Resultado esperado |
|---|---|---|
| U6-A01 | Analisis sintactico de cada `.ps1` | Sin `ParserError`. |
| U6-A02 | Crear/revisar `operador_respaldo` | Atributos administrativos en `false`; puede respaldar `foodstore`. |
| U6-A03 | Respaldo normal | Dump y globales validos, hashes correctos, sin `.parcial`. |
| U6-A04 | Retencion con archivos de prueba de antiguedad mayor a 14 dias | Se eliminan solo conjuntos vencidos y el ultimo conjunto valido se conserva. |
| U6-A05 | Hash del dump alterado de forma controlada | `restore_test.ps1` falla antes de tocar `foodstore_restore_test`. |
| U6-A06 | Restauracion normal | Conteos origen/destino iguales, controles en cero, `pg_amcheck` OK, RTO/RPO registrados. |
| U6-A07 | Destino `foodstore` | Rechazo con codigo distinto de cero, sin cambios en la base principal. |
| U6-A08 | Programacion | Las tres tareas existen; una ejecucion iniciada con `Start-ScheduledTask` deja ultimo resultado exitoso y log. |
| U6-A09 | Roles despues de restaurar | El respaldo global pasa hash; con intervencion manual aprobada, `verificacion_roles.sql` conserva su evidencia y resultado. |

## 7. Evidencias e informe

Se versionan en `unidad-6/evidencias/` copias anonimizadas de los logs y salidas: tareas registradas y ultima ejecucion, respaldo, prueba de retencion, rechazo por hash alterado, restauracion valida, `pg_amcheck`, conteos e integridad. No se versionan dumps, globales, hashes que revelen rutas personales ni credenciales.

`docs/informe/u6.md` indicara que se implemento, por que se separa la restauracion de roles de la tarea automatica, como se probo cada caso, RTO/RPO observados y los limites del laboratorio. `unidad-8/docs/partes/3a_mapa_capa_de_datos.md` y `3b_plan_mantenimiento.md` se actualizaran despues de contar con resultados reales.

## 8. Uso de IA y aprobacion humana

OpenCode podra generar la primera version de los scripts desde esta spec y `unidad-6/AGENTS.md`. Antes de ejecutar cada script, Andres lo lee linea por linea y realiza los casos de prueba en su servidor local. La conversacion, modelo, fecha, prompt o spec usada, cambios aceptados/corregidos/descartados y las evidencias se agregaran a la DUIA/bitacora consolidada. Ningun resultado, tiempo ni evidencia se declara antes de observarlo.
