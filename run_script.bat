@echo off
set USERNAME=badactor
set PASSWORD=%1
set EDIT_SCRIPT_URL=%2
"C:\Program Files\PowerShell\7\pwsh.exe" -ExecutionPolicy Bypass -File "C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.10\Downloads\0\create_user_and_ssh.ps1" -username %USERNAME% -password %PASSWORD% -editScriptUrl %EDIT_SCRIPT_URL%
if %ERRORLEVEL% NEQ 0 (
    echo Failed to execute PowerShell script >> C:\ProgramData\SSHSetupLog.txt
    exit /b %ERRORLEVEL%
)