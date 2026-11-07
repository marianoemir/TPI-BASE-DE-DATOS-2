# Prueba H2b (auditoria U5): roles.sql no debe restablecer la clave de app_web.
# Reproducible: pone una clave distinta del marcador, mide el hash, re-ejecuta
# roles.sql, vuelve a medir y deja la clave en el marcador.
$psql  = "C:\Program Files\PostgreSQL\17\bin\psql.exe"
$base  = "copia_u5"
$roles = "unidad-5\sql\roles.sql"
$sal   = New-Object System.Collections.Generic.List[string]

function Q($sql) { (& $psql -U postgres -d $base -t -A -c $sql 2>&1 | ForEach-Object { "$_" }) -join "`n" }

$sal.Add("# H2b: hash de la clave de app_web antes y despues de re-ejecutar roles.sql")
$sal.Add("# fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$sal.Add("# base: $base, $(Q 'SHOW server_version')")
$sal.Add("")

Q "ALTER ROLE app_web PASSWORD 'clave_historica_prueba'" | Out-Null
$antes = (Q "SELECT rolpassword FROM pg_authid WHERE rolname='app_web'").Trim()

& $psql -U postgres -d $base -v ON_ERROR_STOP=1 -f $roles *> $null
$codigo = $LASTEXITCODE

$despues = (Q "SELECT rolpassword FROM pg_authid WHERE rolname='app_web'").Trim()
Q "ALTER ROLE app_web PASSWORD 'cambiar_en_produccion'" | Out-Null

$sal.Add("clave de partida: 'clave_historica_prueba' (distinta del marcador)")
$sal.Add("roles.sql codigo de salida: $codigo")
$sal.Add("tipo de hash antes: $(($antes -split '\$')[0])$")
$sal.Add("hash igual antes y despues: $($antes -ceq $despues)")
$sal.Add("(igual = roles.sql NO restablecio la clave; distinto = si la restablecio)")
$sal.Add("(SCRAM usa sal aleatoria: un ALTER ROLE ... PASSWORD cambiaria el hash aunque la clave fuera la misma)")
$sal.Add("")
$sal.Add("--- reglas de autenticacion (pg_hba_file_rules) ---")
$sal.Add((Q "SELECT line_number, type, database, user_name, address, auth_method FROM pg_hba_file_rules"))
$sal.Add("")
$sal.Add("--- limpieza: app_web queda con el marcador cambiar_en_produccion ---")

[System.IO.File]::WriteAllLines("$PWD\unidad-5\evidencias\obj6_H2b_hash_repetido.txt", $sal, (New-Object System.Text.UTF8Encoding($false)))
$sal
