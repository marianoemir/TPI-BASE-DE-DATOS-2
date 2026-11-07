<#
.SYNOPSIS
    Registra las tareas de mantenimiento de Food Store en el Programador de tareas.
.DESCRIPTION
    No ejecuta las tareas ni toca PostgreSQL durante el registro. Use -WhatIf para
    revisar las acciones que se registrarian. Las tareas se ejecutan como el usuario
    local indicado, cuyo pgpass.conf queda fuera del repositorio.
#>

param (
    [string]$PowerShellExe = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe",
    [string]$Psql = "C:\Program Files\PostgreSQL\17\bin\psql.exe",
    [string]$UsuarioTarea = "$env:USERDOMAIN\$env:USERNAME",
    [string]$UsuarioPostgres = 'postgres',
    [string]$Base = 'foodstore',
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
$raiz = $PSScriptRoot
$backup = Join-Path $raiz 'backup_foodstore.ps1'
$maintenance = Join-Path $raiz 'maintenance.sql'
$restore = Join-Path $raiz 'restore_test.ps1'

foreach ($ruta in @($PowerShellExe, $Psql, $backup, $maintenance, $restore)) {
    if (-not (Test-Path -LiteralPath $ruta)) {
        throw "No existe el archivo requerido: $ruta"
    }
}

function Registrar-Tarea {
    param(
        [string]$Nombre,
        [string]$Argumentos,
        [object]$Trigger
    )

    if ($WhatIf) {
        Write-Host "WHATIF - Registraria $Nombre con: $Argumentos"
        return
    }

    $accion = New-ScheduledTaskAction -Execute $PowerShellExe -Argument $Argumentos
    $principal = New-ScheduledTaskPrincipal -UserId $UsuarioTarea -LogonType Interactive -RunLevel Limited
    Register-ScheduledTask -TaskName $Nombre -Action $accion -Trigger $Trigger -Principal $principal -Force | Out-Null
    Write-Host "RESULTADO: OK - $Nombre registrada"
}

$argumentosBackup = "-NoProfile -ExecutionPolicy Bypass -File `"$backup`""
$argumentosMaintenance = "-NoProfile -ExecutionPolicy Bypass -Command `"& '$Psql' -w -U '$UsuarioPostgres' -d '$Base' -f '$maintenance'; exit `$LASTEXITCODE`""
$argumentosRestore = "-NoProfile -ExecutionPolicy Bypass -File `"$restore`""

Registrar-Tarea -Nombre 'FoodStore-Respaldo-Diario' -Argumentos $argumentosBackup -Trigger (New-ScheduledTaskTrigger -Daily -At 2:00AM)
Registrar-Tarea -Nombre 'FoodStore-Mantenimiento-Semanal' -Argumentos $argumentosMaintenance -Trigger (New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 3:00AM)
Registrar-Tarea -Nombre 'FoodStore-Restauracion-Semanal' -Argumentos $argumentosRestore -Trigger (New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 4:00AM)
