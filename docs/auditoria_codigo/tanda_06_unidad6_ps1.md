# Tanda 06 — unidad-6 (respaldo, restauración, programador de tareas y pruebas Pester)

Herramienta: OpenCode (modo Plan, solo lectura)
Modelo: Crouton Alpha Free
Fecha y hora: 8/11/2026, 23:16
Sesión: nueva
Archivos (4):
- unidad-6/backup_foodstore.ps1
- unidad-6/restore_test.ps1
- unidad-6/programar_tareas.ps1
- unidad-6/tests/ampliacion.Tests.ps1
Prompt: ver prompt_base.md, más la línea final: «Devolvé exactamente el formato indicado: un id H-nn y una severidad por hallazgo, sin resumen por archivo.»
Estado: Corrida completa
Total de hallazgos devueltos: 17 (2  Alta / 6 Media / 9 Baja)
Estado del repo: rama review-final, etiqueta pre-review (351ddb9)

---

- H-01 [Alta] `tests/ampliacion.Tests.ps1:27-33` — La prueba de orden usa `IndexOf('Verificar-Hash')`, es decir la definición de la función (`restore_test.ps1:45`), no la llamada; pasa aunque se elimine la verificación previa a `& $Createdb`, con lo cual no protege la regla de seguridad crítica.
- H-02 [Alta] `programar_tareas.ps1:50` — La tarea de mantenimiento no usa `-v ON_ERROR_STOP=1`; `psql -f` continúa tras errores SQL y sale con código `0`, por lo que la tarea programada reporta éxito aunque el mantenimiento falle.
- H-03 [Media] `backup_foodstore.ps1:123-139` — Si `pg_dumpall` o su hash falla después de mover `datosFinal`, el `catch` solo borra los `.parcial` y deja un `.dump`+`.sha256` huérfano sin globales; `Aplicar-Retencion` nunca lo limpia porque exige el conjunto completo válido.
- H-04 [Media] `restore_test.ps1:136-158` — El "último respaldo" se elige ordenando alfabéticamente cualquier `*.dump` y no filtra `foodstore_*.dump`; un archivo ajeno lexicográficamente mayor provoca error aunque existan respaldos válidos.
- H-05 [Media] `programar_tareas.ps1:14-15,50` — `$Base` de mantenimiento no se valida como en el respaldo (`backup_foodstore.ps1:25`) o la restauración (`restore_test.ps1:91`); cambiar el parámetro hace ejecutar `maintenance.sql` contra otra base.
- H-06 [Media] `programar_tareas.ps1:43-45` — `LogonType Interactive` hace que las tareas solo corran con sesión iniciada; el respaldo diario 02:00 no se ejecuta con la sesión cerrada ni bloqueada.
- H-07 [Media] `tests/ampliacion.Tests.ps1:20-64` — Toda la suite son regex sobre el texto fuente; pasa con código comentado o muerto (p. ej. `pg_amcheck` puede quedar solo en el parámetro) y no verifica invariantes como destino fijo `foodstore_restore_test`, uso de `-w`, ausencia de contraseñas, secuencia `.parcial`+`--list`+retención, ni disparadores de las tareas.
- H-08 [Media] `restore_test.ps1:290,298,335` — No define `$ErrorActionPreference` global y esas tres llamadas nativas se hacen sin el bloque `Continue`/`$LASTEXITCODE` usado en el resto; si el llamador deja la preferencia en `Stop`, la redirección `2>&1` lanza antes del chequeo controlado.
- H-09 [Baja] `programar_tareas.ps1:50` — El `psql` de mantenimiento omite `-h`/`-p`, a diferencia de respaldo y restauración; depende del host/puerto por defecto del cliente para coincidir con `pgpass.conf`.
- H-10 [Baja] `programar_tareas.ps1:49-51` — Las tres tareas usan `-ExecutionPolicy Bypass` sin `-NonInteractive` ni `-StartWhenAvailable`; un script alterado se ejecuta sin chequeo de política y un horario perdido no se recupera.
- H-11 [Baja] `restore_test.ps1:41` — `Escribir-Log` usa `Add-Content -Path` en vez de `-LiteralPath`; rutas con caracteres de patrón (`[`, `]`, `*`) se interpretan como wildcard, inconsistente con `backup_foodstore.ps1`.
- H-12 [Baja] `restore_test.ps1:72,85` — `Consultar-Psql` mezcla `stderr` con el resultado (`2>&1`); un aviso de `psql` contamina el escalar comparado contra el conteo de origen.
- H-13 [Baja] `backup_foodstore.ps1:99-101` — `Remove-Item` de retención sin guarda de existencia ni `-ErrorAction SilentlyContinue`; si falta un archivo de un conjunto ya validado, la retención lanza y un respaldo exitoso se reporta como `ERROR` (salida `1`).
- H-14 [Baja] `backup_foodstore.ps1:35,112-123` — Timestamp con granularidad de segundo para `.parcial` y `.final`; dos ejecuciones en el mismo segundo colisionan y pueden sobrescribirse o hacer fallar `Move-Item` sin `-Force`.
- H-15 [Baja] `backend_foodstore.ps1:132` — El log solo registra la ruta final, sin tamaño ni hash; la evidencia de aprobación del respaldo exige archivo, tamaño y log.
- H-16 [Baja] `restore_test.ps1:355` — Exige exactamente `6` controles de integridad hardcodeados; cambiar `validar_integridad.sql` rompe el simulacro sin que el mensaje indique cuál es la causa.
- H-17 [Baja] `tests/ampliacion.Tests.ps1:12-63` — Sintaxis legacy `Should Be`/`Should Match` (Pester v4); en Pester 5 está deprecada a favor de `Should -Be`/`Should -Match`.