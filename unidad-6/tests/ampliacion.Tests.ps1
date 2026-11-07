$ErrorActionPreference = 'Stop'

$unidad6 = Split-Path -Parent $PSScriptRoot
$crearRol = Join-Path $unidad6 'crear_rol_respaldo.sql'
$backup = Join-Path $unidad6 'backup_foodstore.ps1'
$restore = Join-Path $unidad6 'restore_test.ps1'
$integridad = Join-Path $unidad6 'validar_integridad.sql'
$tareas = Join-Path $unidad6 'programar_tareas.ps1'

Describe 'Ampliacion U6 - mantenimiento verificable' {
    It 'define un rol de respaldo sin atributos administrativos' {
        Test-Path -LiteralPath $crearRol | Should Be $true
        $contenido = Get-Content -LiteralPath $crearRol -Raw
        $contenido | Should Match 'CREATE ROLE operador_respaldo'
        $contenido | Should Match 'NOSUPERUSER'
        $contenido | Should Match 'NOCREATEDB'
        $contenido | Should Match 'NOCREATEROLE'
    }

    It 'respalda los objetos globales sin hashes de contrasenas' {
        $contenido = Get-Content -LiteralPath $backup -Raw
        $contenido | Should Match 'pg_dumpall'
        $contenido | Should Match '--globals-only'
        $contenido | Should Match '--no-role-passwords'
    }

    It 'verifica la integridad de los archivos antes de crear la copia restaurada' {
        $contenido = Get-Content -LiteralPath $restore -Raw
        $posicionHash = $contenido.IndexOf('Verificar-Hash')
        $posicionCreateDb = $contenido.IndexOf('& $Createdb')
        $posicionHash | Should BeGreaterThan 0
        $posicionCreateDb | Should BeGreaterThan $posicionHash
    }

    It 'ejecuta pg_amcheck durante la restauracion de prueba' {
        $contenido = Get-Content -LiteralPath $restore -Raw
        $contenido | Should Match 'pg_amcheck'
    }

    It 'instala amcheck solo si falta en la copia descartable' {
        $contenido = Get-Content -LiteralPath $restore -Raw
        $contenido | Should Match '--install-missing'
    }

    It 'define controles reutilizables de integridad referencial' {
        Test-Path -LiteralPath $integridad | Should Be $true
        $contenido = Get-Content -LiteralPath $integridad -Raw
        $contenido | Should Match 'huerfanos'
        $contenido | Should Match 'detalle_pedido'
    }

    It 'lee la salida de integridad sin mensajes de formato de psql' {
        $contenido = Get-Content -LiteralPath $restore -Raw
        $contenido | Should Match '-t -A -F'
        $contenido | Should Match '-q -f \$ArchivoIntegridad'
    }

    It 'registra las tareas de respaldo, mantenimiento y restauracion' {
        Test-Path -LiteralPath $tareas | Should Be $true
        $contenido = Get-Content -LiteralPath $tareas -Raw
        $contenido | Should Match 'FoodStore-Respaldo-Diario'
        $contenido | Should Match 'FoodStore-Mantenimiento-Semanal'
        $contenido | Should Match 'FoodStore-Restauracion-Semanal'
    }
}
