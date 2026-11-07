@echo off
setlocal EnableDelayedExpansion
rem PocketGPT launcher. Uses only paths relative to this file, so the drive
rem letter does not matter. Local only: the server listens on 127.0.0.1.

set "ROOT=%~dp0"
set "SERVER=%ROOT%App\llama-server.exe"
set "WEB=%ROOT%App\web"
set "MODEL="
for %%f in ("%ROOT%Models\*.gguf") do if not defined MODEL set "MODEL=%%~ff"

if not exist "%ROOT%Logs" mkdir "%ROOT%Logs"

if not exist "%SERVER%" (
  echo Missing App\llama-server.exe - see README.md, step "Get llama.cpp".
  pause & exit /b 1
)
if not defined MODEL (
  echo No .gguf model found in the Models folder - see README.md, step "Get a model".
  pause & exit /b 1
)
if not exist "%WEB%\index.html" (
  echo Missing App\web\index.html - see README.md, step "Build the web UI".
  pause & exit /b 1
)

echo Starting PocketGPT with !MODEL!
start "PocketGPT engine" /min cmd /c ""%SERVER%" -m "!MODEL!" --host 127.0.0.1 --port 8080 -c 4096 -t 6 -ngl 0 --path "%WEB%" > "%ROOT%Logs\server.log" 2>&1"

echo Waiting for the model to load...
powershell -NoProfile -Command "for($i=0;$i -lt 120;$i++){try{if((Invoke-WebRequest -UseBasicParsing http://127.0.0.1:8080/health).StatusCode -eq 200){exit 0}}catch{};Start-Sleep 1};exit 1"
if errorlevel 1 (
  echo The engine did not become ready. Check Logs\server.log
  pause & exit /b 1
)

start "" http://127.0.0.1:8080
echo PocketGPT is running. Close the "PocketGPT engine" window to stop it.
