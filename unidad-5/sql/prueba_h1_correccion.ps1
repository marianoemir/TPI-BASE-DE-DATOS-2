$env:PGCLIENTENCODING = 'UTF8'
$psql  = "C:\Program Files\PostgreSQL\17\bin\psql.exe"
$base  = "copia_u5"
$roles = "unidad-5\sql\roles.sql"
$sal   = New-Object System.Collections.Generic.List[string]
function Q($sql) { (& $psql -U postgres -d $base -X -c $sql 2>&1 | ForEach-Object { "$_" }) -join "`n" }

$sal.Add("# H1 tras la correccion: un GRANT CREATE previo no debe sobrevivir a roles.sql")
$sal.Add("# fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$sal.Add("# base: $base")
$sal.Add("")
$sal.Add("GRANT CREATE ON SCHEMA public TO app_web, rol_soporte;")
$sal.Add((Q "GRANT CREATE ON SCHEMA public TO app_web, rol_soporte;"))
$sal.Add("--- re-ejecuto roles.sql ---")
& $psql -U postgres -d $base -X -v ON_ERROR_STOP=1 -f $roles *> $null
$sal.Add("roles.sql codigo de salida: $LASTEXITCODE")
$sal.Add("")
$sal.Add("--- CREATE sobre public despues (esperado: f para los de aplicacion, t para admin_datos) ---")
$sal.Add((Q "SELECT r, has_schema_privilege(r, 'public', 'CREATE') AS puede_create FROM unnest(ARRAY['app_web','rol_app_lectura','rol_app_escritura','rol_app_auth','rol_soporte','rol_reportes','admin_datos']) AS r;"))

$tmp = [System.IO.Path]::GetTempFileName()
@"
BEGIN; SET LOCAL ROLE app_web; CREATE TABLE public.prueba_priv(o int); ROLLBACK;
BEGIN; SET LOCAL ROLE rol_soporte; CREATE TABLE public.prueba_priv(o int); ROLLBACK;
SELECT to_regclass('public.prueba_priv') AS tabla_quedo;
"@ | Set-Content -Encoding UTF8 $tmp
$sal.Add("--- intento de CREATE TABLE como app_web y rol_soporte (esperado: permiso denegado) ---")
$sal.Add((& $psql -U postgres -d $base -X -f $tmp 2>&1 | ForEach-Object { "$_" }) -join "`n")
Remove-Item $tmp

$sal.Add("--- limpieza: por si algun CREATE de prueba sobrevivio ---")
$sal.Add((Q "REVOKE CREATE ON SCHEMA public FROM app_web, rol_soporte;"))

[System.IO.File]::WriteAllLines("$PWD\unidad-5\evidencias\obj6_H1_despues_de_correccion.txt", $sal, (New-Object System.Text.UTF8Encoding($false)))
$sal
