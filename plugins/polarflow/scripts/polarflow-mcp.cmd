@echo off
setlocal EnableExtensions
rem Lance le serveur MCP PolarFlow (stdio) en localisant le moteur deja
rem installe par PolarFlow Studio. Aucun telechargement, aucune cle.
rem
rem Ordre de resolution :
rem   1. POLARFLOW_ENGINE_EXE (override explicite)
rem   2. %LOCALAPPDATA%\Programs\PolarFlow Studio\polarflow-engine.exe
rem   3. Registre WiX per-user : HKCU\Software\polarflow\PolarFlow Studio\InstallDir
rem
rem stdout est reserve au protocole JSON-RPC : tout message d'erreur part sur
rem stderr.

set "ENGINE=%POLARFLOW_ENGINE_EXE%"
if defined ENGINE if exist "%ENGINE%" goto run

set "ENGINE=%LOCALAPPDATA%\Programs\PolarFlow Studio\polarflow-engine.exe"
if exist "%ENGINE%" goto run

set "DIR="
for /f "tokens=2,*" %%A in ('reg query "HKCU\Software\polarflow\PolarFlow Studio" /v InstallDir 2^>nul ^| findstr /i "InstallDir"') do set "DIR=%%B"
if defined DIR if exist "%DIR%polarflow-engine.exe" (
  set "ENGINE=%DIR%polarflow-engine.exe"
  goto run
)

1>&2 echo [polarflow-mcp] PolarFlow Studio est introuvable sur ce poste.
1>&2 echo [polarflow-mcp] Installez ou reparez PolarFlow Studio, ou definissez
1>&2 echo [polarflow-mcp] POLARFLOW_ENGINE_EXE vers polarflow-engine.exe.
exit /b 1

:run
"%ENGINE%" --mcp
