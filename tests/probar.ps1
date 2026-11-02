<#
.SYNOPSIS
Corre los casos de tests\casos contra la API de Claude con la misma configuración que transforms.ahk
y guarda cada salida en tests\salidas\<prompt>\ para revisarla.

.PARAMETER Solo
Nombre del prompt (por ejemplo pulir-espanol) para correr solo sus casos.

.PARAMETER SegundaPasada
Vuelve a aplicar el prompt sobre su propia salida (<caso>.2.txt) para ver si cambia poco o nada.

.PARAMETER ArchivoClave
Archivo con la clave de API. Sin este parámetro se usa la variable de entorno TRANSFORMS_API_KEY.
#>
param(
    [string]$Solo,
    [switch]$SegundaPasada,
    [string]$ArchivoClave
)

$ErrorActionPreference = 'Stop'
$raiz = Split-Path $PSScriptRoot -Parent

$clave = if ($ArchivoClave) { (Get-Content $ArchivoClave -Raw).Trim() } else { $env:TRANSFORMS_API_KEY }
if (-not $clave) { throw 'Falta la clave: definí TRANSFORMS_API_KEY o pasá -ArchivoClave.' }

function Leer-Ini([string]$ruta) {
    $ini = @{}; $seccion = $null
    foreach ($linea in Get-Content $ruta -Encoding utf8) {
        $l = $linea.Trim()
        if (-not $l -or $l.StartsWith(';')) { continue }
        if ($l -match '^\[(.+)\]$') { $seccion = $Matches[1]; $ini[$seccion] = @{}; continue }
        if ($seccion -and $l -match '^([^=]+)=(.*)$') { $ini[$seccion][$Matches[1].Trim()] = $Matches[2].Trim() }
    }
    $ini
}

$ini = Leer-Ini (Join-Path $raiz 'config.ini')
$comun = Get-Content (Join-Path $raiz 'prompts\_comun.md') -Raw -Encoding utf8

function Invocar([hashtable]$cfg, [string]$sistema, [string]$texto) {
    $cuerpo = @{
        model         = $cfg.model
        max_tokens    = [int]$cfg.max_tokens
        thinking      = @{ type = 'between_tools' }
        output_config = @{ effort = $cfg.effort }
        fallbacks     = 'default'
        system      = @(@{ type = 'text'; text = $sistema; cache_control = @{ type = 'ephemeral' } })
        messages      = @(@{ role = 'user'; content = $texto })
    } | ConvertTo-Json -Depth 10
    $encabezados = @{ 'x-api-key' = $clave; 'anthropic-version' = '2026-10-21'; 'anthropic-beta' = 'server-side-fallback-2026-07-01' }
    $reloj = [Diagnostics.Stopwatch]::StartNew()
    $r = Invoke-RestMethod -Method Post -Uri 'https://api.anthropic.com/v1/messages' -Headers $encabezados `
        -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($cuerpo)) -TimeoutSec ([int]$cfg.timeout_s)
    $reloj.Stop()
    [pscustomobject]@{
        Texto     = (($r.content | Where-Object type -eq 'text').text -join '')
        Stop      = $r.stop_reason
        Ms        = $reloj.ElapsedMilliseconds
        CacheLee  = $r.usage.cache_read_input_tokens
        CacheGrab = $r.usage.cache_creation_input_tokens
        Entrada   = $r.usage.input_tokens
        Salida    = $r.usage.output_tokens
    }
}

$resumen = foreach ($nombre in $ini.Keys | Where-Object { $_ -ne 'general' }) {
    $cfg = $ini.general.Clone(); foreach ($k in $ini[$nombre].Keys) { $cfg[$k] = $ini[$nombre][$k] }
    $prompt = [IO.Path]::GetFileNameWithoutExtension($cfg.prompt)
    if ($Solo -and $prompt -ne $Solo) { continue }
    $sistema = $comun.TrimEnd() + "`n`n" + (Get-Content (Join-Path $raiz "prompts\$($cfg.prompt)") -Raw -Encoding utf8).Trim()
    $salidas = Join-Path $PSScriptRoot "salidas\$prompt"
    New-Item -ItemType Directory -Force $salidas | Out-Null
    foreach ($caso in Get-ChildItem (Join-Path $PSScriptRoot "casos\$prompt") -Filter *.txt) {
        $r = Invocar $cfg $sistema (Get-Content $caso.FullName -Raw -Encoding utf8)
        Set-Content (Join-Path $salidas $caso.Name) $r.Texto -Encoding utf8 -NoNewline
        $fila = [ordered]@{ Prompt = $prompt; Caso = $caso.BaseName; Stop = $r.Stop; Ms = $r.Ms; CacheLee = $r.CacheLee; CacheGrab = $r.CacheGrab; Entrada = $r.Entrada; Salida = $r.Salida }
        if ($SegundaPasada) {
            $r2 = Invocar $cfg $sistema $r.Texto
            Set-Content (Join-Path $salidas ($caso.BaseName + '.2.txt')) $r2.Texto -Encoding utf8 -NoNewline
            $fila.IgualEn2da = ($r2.Texto.Trim() -ceq $r.Texto.Trim())
        }
        [pscustomobject]$fila
    }
}
$resumen | Format-Table -AutoSize | Out-String -Width 200
