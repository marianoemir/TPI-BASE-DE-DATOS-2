$ErrorActionPreference = 'Stop'

$unidad7 = Split-Path -Parent $PSScriptRoot
$exportador = Join-Path $unidad7 'modelo\exportar_pedidos_benchmark.sql'
$mongo = Join-Path $unidad7 'carga_benchmark_mongodb.js'
$postgres = Join-Path $unidad7 'consultas_benchmark_postgresql.sql'

Describe 'Medicion U7 - benchmark aislado' {
    It 'exporta una muestra parametrizada sin datos sensibles' {
        Test-Path -LiteralPath $exportador | Should Be $true
        $contenido = Get-Content -LiteralPath $exportador -Raw
        $contenido | Should Match ':limite'
        $contenido | Should Match "'benchmark'"
        $contenido | Should Not Match 'contrasena'
    }

    It 'carga en una coleccion MongoDB separada con indice multikey y explain' {
        Test-Path -LiteralPath $mongo | Should Be $true
        $contenido = Get-Content -LiteralPath $mongo -Raw
        $contenido | Should Match 'foodstore_nosql_benchmark'
        $contenido | Should Match 'pedidos_benchmark'
        $contenido | Should Match 'lineas.producto_id'
        $contenido | Should Match 'executionStats'
    }

    It 'mide en PostgreSQL la misma muestra con buffers' {
        Test-Path -LiteralPath $postgres | Should Be $true
        $contenido = Get-Content -LiteralPath $postgres -Raw
        $contenido | Should Match ':limite'
        $contenido | Should Match 'EXPLAIN \(ANALYZE, BUFFERS, FORMAT JSON\)'
        $contenido | Should Match 'categoria'
    }
}
