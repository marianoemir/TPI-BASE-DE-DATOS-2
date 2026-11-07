$env:PGCLIENTENCODING = 'UTF8'
$psql  = "C:\Program Files\PostgreSQL\17\bin\psql.exe"
$base  = "copia_u5"
$roles = "unidad-5\sql\roles.sql"
$sal   = New-Object System.Collections.Generic.List[string]
function Q($sql) { (& $psql -U postgres -d $base -X -c $sql 2>&1 | ForEach-Object { "$_" }) -join "`n" }

$sal.Add("# H3 tras la correccion: la membresia heredada rol_app_escritura -> rol_soporte no debe sobrevivir")
$sal.Add("# fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$sal.Add("# base: $base")
$sal.Add("")
$sal.Add("GRANT rol_app_escritura TO rol_soporte;")
$sal.Add((Q "GRANT rol_app_escritura TO rol_soporte;"))
$sal.Add("--- re-ejecuto roles.sql ---")
& $psql -U postgres -d $base -X -v ON_ERROR_STOP=1 -f $roles *> $null
$sal.Add("roles.sql codigo de salida: $LASTEXITCODE")
$sal.Add("")
$sal.Add("--- membresias despues (esperado: solo las 3 de app_web) ---")
$sal.Add((Q "SELECT g.rolname AS grupo, m.rolname AS miembro FROM pg_auth_members am JOIN pg_roles g ON g.oid = am.roleid JOIN pg_roles m ON m.oid = am.member WHERE m.rolname LIKE 'rol_%' OR m.rolname IN ('app_web','admin_datos') ORDER BY 1,2;"))
$sal.Add("--- rol_soporte sobre sp_crear_pedido (esperado: f) ---")
$sal.Add((Q "SELECT p.oid::regprocedure AS rutina, has_function_privilege('rol_soporte', p.oid, 'EXECUTE') AS soporte_puede_ejecutar FROM pg_proc p WHERE p.proname = 'sp_crear_pedido';"))
$sal.Add("--- limpieza: por si la membresia de prueba sobrevivio ---")
$sal.Add((Q "REVOKE rol_app_escritura FROM rol_soporte;"))

[System.IO.File]::WriteAllLines("$PWD\unidad-5\evidencias\obj6_H3_despues_de_correccion.txt", $sal, (New-Object System.Text.UTF8Encoding($false)))
$sal
