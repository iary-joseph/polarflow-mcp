# Configure le MCP PolarFlow dans Claude Code et/ou Codex.
# ASCII uniquement (PowerShell 5.1 sans BOM). Idempotent.

$ErrorActionPreference = "Stop"

function Find-Engine {
    if ($env:POLARFLOW_ENGINE_EXE) {
        if (Test-Path -LiteralPath $env:POLARFLOW_ENGINE_EXE) { return $env:POLARFLOW_ENGINE_EXE }
    }
    $default = Join-Path $env:LOCALAPPDATA "Programs\PolarFlow Studio\polarflow-engine.exe"
    if (Test-Path -LiteralPath $default) { return $default }
    $key = "HKCU:\Software\polarflow\PolarFlow Studio"
    if (Test-Path -LiteralPath $key) {
        $dir = (Get-ItemProperty -LiteralPath $key -ErrorAction SilentlyContinue).InstallDir
        if ($dir) {
            $candidate = Join-Path $dir "polarflow-engine.exe"
            if (Test-Path -LiteralPath $candidate) { return $candidate }
        }
    }
    return $null
}

$engine = Find-Engine
if (-not $engine) {
    Write-Host "[erreur] PolarFlow Studio est introuvable sur ce poste." -ForegroundColor Red
    Write-Host "         Installez PolarFlow Studio, ou definissez POLARFLOW_ENGINE_EXE."
    exit 1
}
Write-Host "Moteur detecte : $engine"

$claude = Get-Command claude -ErrorAction SilentlyContinue
if ($claude) {
    $list = (& claude mcp list 2>$null | Out-String)
    if ($list -match "polarflow") {
        Write-Host "Claude Code : serveur 'polarflow' deja configure."
    } else {
        & claude mcp add --transport stdio --scope user polarflow -- $engine --mcp | Out-Null
        Write-Host "Claude Code : serveur 'polarflow' ajoute (scope user)."
    }
} else {
    Write-Host "Claude Code : commande 'claude' absente du PATH - configuration manuelle requise (voir INSTALL.md)."
}

$codex = Get-Command codex -ErrorAction SilentlyContinue
if ($codex) {
    $list = (& codex mcp list 2>$null | Out-String)
    if ($list -match "polarflow") {
        Write-Host "Codex : serveur 'polarflow' deja configure."
    } else {
        & codex mcp add polarflow -- $engine --mcp | Out-Null
        Write-Host "Codex : serveur 'polarflow' ajoute."
    }
} else {
    Write-Host "Codex : commande 'codex' absente du PATH - configuration manuelle requise (voir INSTALL.md)."
}

Write-Host ""
Write-Host "Redemarrez votre client, puis demandez : 'appelle pf_status'."
Write-Host "PolarFlow Studio doit etre lance pour les outils moteur (schema, apercu, test)."
