# Correcciones de la revision del PR de a/obj-10 (objetivo 10). Solo lectura sobre PostgreSQL.
# Requisitos: ejecutar con la base 'foodstore' que tenga la carga masiva (5.000+ pedidos vigentes),
# $env:PGPASSWORD definido, y mongosh en el PATH. Los scripts auxiliares deben estar en unidad-7.
# Uso (desde cualquier carpeta del repo): .\unidad-7\correr_correcciones_obj10.ps1 [-Cargar]
#   -Cargar : regenera modelo\pedidos_benchmark.json y recarga SOLO foodstore_nosql_benchmark.
param(
  [string]$PsqlExe = 'C:\Program Files\PostgreSQL\17\bin\psql.exe',
  [string]$Base = 'foodstore',
  [string]$Usuario = 'postgres',
  [string]$MongoUri = 'mongodb://localhost:27017',
  [int]$Producto = 1,
  [switch]$Cargar
)
$ErrorActionPreference = 'Continue'
$env:PGCLIENTENCODING = 'UTF8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$utf8 = New-Object System.Text.UTF8Encoding($false)

$raiz = ((& git rev-parse --show-toplevel) | Out-String).Trim()
Set-Location (Join-Path $raiz 'unidad-7')
$fecha = Get-Date -Format 'yyyyMMdd'

function Ejecutar([string]$exe, [string[]]$argumentos) {
  $salida = & $exe @argumentos 2>&1 | ForEach-Object { "$_" }
  if ($LASTEXITCODE -ne 0) { throw "Fallo $exe (codigo $LASTEXITCODE): $($salida -join [Environment]::NewLine)" }
  return $salida
}
function Guardar([string]$ruta, [string[]]$lineas) {
  [System.IO.File]::WriteAllLines((Join-Path (Get-Location) $ruta), $lineas, $utf8)
  Write-Host "Guardado: $ruta"
}
$pg = @('-U', $Usuario, '-d', $Base)

# Paso 0: comprobaciones previas
$n = ((Ejecutar $PsqlExe ($pg + @('-t', '-A', '-c', 'SELECT count(*) FROM pedido WHERE eliminado = FALSE'))) -join '').Trim()
if ([int]$n -lt 5000) { throw "La base $Base tiene solo $n pedidos vigentes: falta la carga masiva (usar una copia, no foodstore)." }
$vPg = ((Ejecutar $PsqlExe ($pg + @('-t', '-A', '-c', 'SELECT version()'))) -join '').Trim()
$vMongo = ((Ejecutar 'mongosh' @('--version')) -join '').Trim()
Write-Host "PostgreSQL: $vPg"
Write-Host "mongosh: $vMongo"

# Paso 1: regenerar el JSON de ejemplo en UTF-8 y comprobar que no queden restos
Ejecutar $PsqlExe ($pg + @('-t', '-A', '-v', 'ids=1,2,3,6,7,8', '-v', 'origen=ejemplo_regenerado',
  '-f', 'modelo\exportar_pedidos.sql', '-o', 'modelo\pedidos_export_ejemplo_regenerado.json')) | Out-Null
$patron = ([string][char]0x00C3) + '|Chirino|Fabre|Quiroga'
$malos = Select-String -Path 'modelo\pedidos_export_ejemplo_regenerado.json' -Pattern $patron
if ($malos) { Write-Warning "JSON de ejemplo con caracteres rotos o nombres reales:"; $malos | ForEach-Object { Write-Warning $_.Line } }
else { Write-Host 'JSON de ejemplo OK (sin caracteres rotos ni nombres reales).' }

# Paso 2 (opcional): regenerar y cargar la muestra en la base aislada de MongoDB
if ($Cargar) {
  Ejecutar $PsqlExe ($pg + @('-t', '-A', '-v', 'limite=5000', '-f', 'modelo\exportar_pedidos_benchmark.sql',
    '-o', 'modelo\pedidos_benchmark.json')) | Out-Null
  $c = Ejecutar 'mongosh' @($MongoUri, '--quiet', '--file', 'carga_benchmark_mongodb.js')
  Guardar "evidencias\obj10_carga_mongo_$fecha.txt" (@("# $vMongo") + $c)
}

# Paso 3: MongoDB, medicion repetida y verificacion de referencias
$m = Ejecutar 'mongosh' @($MongoUri, '--quiet', '--file', 'medicion_repetida_mongodb.js')
Guardar "evidencias\obj10_medicion_repetida_mongo_$fecha.txt" (@("# $vMongo") + $m)

# Paso 4: PostgreSQL, 6 corridas (la primera es calentamiento)
$p = @("# $vPg")
for ($i = 1; $i -le 6; $i++) {
  $rotulo = "=== corrida $i"
  if ($i -eq 1) { $rotulo += ' (calentamiento)' }
  $p += $rotulo
  $p += Ejecutar $PsqlExe ($pg + @('-v', 'limite=5000', '-v', "producto=$Producto", '-f', 'medicion_repetida_postgresql.sql'))
}
Guardar "evidencias\obj10_medicion_repetida_postgres_$fecha.txt" $p

# Paso 5: PostgreSQL, ids distintos para comparar con los de MongoDB
$r = Ejecutar $PsqlExe ($pg + @('-v', 'limite=5000', '-f', 'verificar_referencias_postgresql.sql'))
Guardar "evidencias\obj10_referencias_postgres_$fecha.txt" (@("# $vPg") + $r)

Write-Host ''
Write-Host '--- Resumen ---'
$m | Where-Object { $_ -match 'mediana|PRODUCTO_OBJETIVO|DISTINTOS|DOCUMENTOS' } | ForEach-Object { Write-Host $_ }
$p | Where-Object { $_ -match '^=== |^Time:|^Tiempo:' } | ForEach-Object { Write-Host $_ }
$r | Where-Object { $_ -match 'PG_' } | ForEach-Object { Write-Host $_ }
