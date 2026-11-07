<#
.SYNOPSIS
    Respalda foodstore y sus objetos globales, con hashes y retencion segura.
.DESCRIPTION
    El dump de datos usa operador_respaldo. El dump global requiere una cuenta
    administrativa, porque los roles son objetos de todo el servidor.
#>

param (
    [string]$PgDump = "C:\Program Files\PostgreSQL\17\bin\pg_dump.exe",
    [string]$PgDumpAll = "C:\Program Files\PostgreSQL\17\bin\pg_dumpall.exe",
    [string]$PgRestore = "C:\Program Files\PostgreSQL\17\bin\pg_restore.exe",
    [string]$Servidor = 'localhost',
    [int]$Puerto = 5432,
    [string]$UsuarioRespaldo = 'operador_respaldo',
    [string]$UsuarioGlobales = 'postgres',
    [string]$Base = 'foodstore',
    [int]$DiasRetencion = 14,
    [string]$DirBackups = "$PSScriptRoot\backups",
    [string]$DirLogs = "$PSScriptRoot\logs"
)

$ErrorActionPreference = 'Stop'

if ($Base -ne 'foodstore') {
    throw "Este script solo admite respaldar foodstore. Base recibida: $Base"
}
if ($DiasRetencion -lt 1) {
    throw 'DiasRetencion debe ser mayor o igual a 1.'
}

New-Item -ItemType Directory -Path $DirBackups -Force | Out-Null
New-Item -ItemType Directory -Path $DirLogs -Force | Out-Null

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$rutaLog = Join-Path $DirLogs "backup_$timestamp.log"

function Escribir-Log {
    param([string]$Mensaje)
    Add-Content -LiteralPath $rutaLog -Encoding ASCII -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Mensaje"
}

function Ejecutar-Programa {
    param([string]$Ejecutable, [string[]]$Argumentos, [string]$Etiqueta)
    $anterior = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $salida = & $Ejecutable @Argumentos 2>&1
        $codigo = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $anterior
    }
    if ($codigo -ne 0) {
        Escribir-Log "ERROR - $Etiqueta fallo con codigo $codigo."
        foreach ($linea in $salida) { Escribir-Log "$Etiqueta`: $linea" }
        throw "$Etiqueta fallo con codigo $codigo."
    }
    Escribir-Log "OK - $Etiqueta finalizo correctamente."
    return @($salida)
}

function Escribir-Hash {
    param([string]$Archivo)
    $hash = (Get-FileHash -LiteralPath $Archivo -Algorithm SHA256).Hash
    $nombre = Split-Path -Leaf $Archivo
    $archivoHash = "$Archivo.sha256"
    Set-Content -LiteralPath $archivoHash -Encoding ASCII -Value "$hash  $nombre"
    Escribir-Log "OK - SHA-256 generado para $nombre."
    return $archivoHash
}

function Test-Hash {
    param([string]$Archivo)
    $archivoHash = "$Archivo.sha256"
    if (-not (Test-Path -LiteralPath $Archivo) -or -not (Test-Path -LiteralPath $archivoHash)) { return $false }
    $esperado = (Get-Content -LiteralPath $archivoHash -Raw).Trim().Split()[0]
    $actual = (Get-FileHash -LiteralPath $Archivo -Algorithm SHA256).Hash
    return $esperado -eq $actual
}

function Aplicar-Retencion {
    $patron = '^foodstore_(\d{8}_\d{6})\.dump$'
    $conjuntos = @()
    foreach ($dump in Get-ChildItem -LiteralPath $DirBackups -File -Filter 'foodstore_*.dump') {
        if ($dump.Name -notmatch $patron) { continue }
        $sello = $Matches[1]
        $globales = Join-Path $DirBackups "foodstore_globals_$sello.sql"
        if ((Test-Hash -Archivo $dump.FullName) -and (Test-Hash -Archivo $globales)) {
            $conjuntos += [PSCustomObject]@{ Sello = $sello; Dump = $dump.FullName; Globales = $globales }
        }
    }

    $ultimoValido = $conjuntos | Sort-Object Sello -Descending | Select-Object -First 1
    $limite = (Get-Date).AddDays(-$DiasRetencion)
    foreach ($conjunto in $conjuntos) {
        $fecha = [datetime]::ParseExact($conjunto.Sello, 'yyyyMMdd_HHmmss', [Globalization.CultureInfo]::InvariantCulture)
        if ($conjunto.Sello -ne $ultimoValido.Sello -and $fecha -lt $limite) {
            foreach ($archivo in @($conjunto.Dump, "$($conjunto.Dump).sha256", $conjunto.Globales, "$($conjunto.Globales).sha256")) {
                Remove-Item -LiteralPath $archivo -Force
            }
            Escribir-Log "OK - Retencion elimino el conjunto valido vencido $($conjunto.Sello)."
        }
    }
}

try {
    foreach ($ejecutable in @($PgDump, $PgDumpAll, $PgRestore)) {
        if (-not (Test-Path -LiteralPath $ejecutable)) { throw "No existe el ejecutable: $ejecutable" }
    }

    $nombreDatos = "foodstore_$timestamp.dump"
    $datosParcial = Join-Path $DirBackups "$nombreDatos.parcial"
    $datosFinal = Join-Path $DirBackups $nombreDatos
    $nombreGlobales = "foodstore_globals_$timestamp.sql"
    $globalesParcial = Join-Path $DirBackups "$nombreGlobales.parcial"
    $globalesFinal = Join-Path $DirBackups $nombreGlobales

    Escribir-Log "INICIO - Respaldo de foodstore en ${Servidor}:${Puerto}."
    Ejecutar-Programa -Ejecutable $PgDump -Etiqueta 'pg_dump' -Argumentos @('-w', '-h', $Servidor, '-p', $Puerto, '-U', $UsuarioRespaldo, '-d', $Base, '-Fc', '-f', $datosParcial) | Out-Null
    Ejecutar-Programa -Ejecutable $PgRestore -Etiqueta 'pg_restore --list' -Argumentos @('--list', $datosParcial) | Out-Null
    if ((Get-Item -LiteralPath $datosParcial).Length -le 0) { throw 'El dump parcial no tiene contenido.' }
    Move-Item -LiteralPath $datosParcial -Destination $datosFinal
    Escribir-Hash -Archivo $datosFinal | Out-Null

    Ejecutar-Programa -Ejecutable $PgDumpAll -Etiqueta 'pg_dumpall --globals-only' -Argumentos @('-w', '-h', $Servidor, '-p', $Puerto, '-U', $UsuarioGlobales, '--globals-only', '--no-role-passwords', '-f', $globalesParcial) | Out-Null
    if ((Get-Item -LiteralPath $globalesParcial).Length -le 0) { throw 'El dump global parcial no tiene contenido.' }
    Move-Item -LiteralPath $globalesParcial -Destination $globalesFinal
    Escribir-Hash -Archivo $globalesFinal | Out-Null

    Aplicar-Retencion
    Escribir-Log "RESULTADO: OK - Datos: $datosFinal | Globales: $globalesFinal"
    Write-Host "RESULTADO: OK - $datosFinal"
    exit 0
}
catch {
    foreach ($parcial in @($datosParcial, $globalesParcial)) {
        if ($null -ne $parcial -and (Test-Path -LiteralPath $parcial)) { Remove-Item -LiteralPath $parcial -Force }
    }
    Escribir-Log "RESULTADO: ERROR - $_"
    Write-Host "RESULTADO: ERROR - $_"
    exit 1
}
