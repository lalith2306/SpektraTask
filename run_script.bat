@echo off
set USERNAME=badactor
set PASSWORD=%1
set EDIT_SCRIPT_URL=%2
set PWSH="C:\Program Files\PowerShell\7\pwsh.exe"
set SCRIPT_DIR=C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.10\Downloads\0
set SCRIPT=%SCRIPT_DIR%\create_user_and_ssh.ps1
echo Checking paths >> C:\ProgramData\SSHSetupLog.txt
if not exist %PWSH% (
    echo PowerShell 7 not found at %PWSH% >> C:\ProgramData\SSHSetupLog.txt
    exit /b 3
)
if not exist %SCRIPT% (
    echo Script not found at %SCRIPT% >> C:\ProgramData\SSHSetupLog.txt
    exit /b 3
)
echo Executing %SCRIPT% >> C:\ProgramData\SSHSetupLog.txt
%PWSH% -ExecutionPolicy Bypass -File %SCRIPT% -username %USERNAME% -password %PASSWORD% -editScriptUrl %EDIT_SCRIPT_URL%
if %ERRORLEVEL% NEQ 0 (
    echo Failed to execute PowerShell script with error %ERRORLEVEL% >> C:\ProgramData\SSHSetupLog.txt
    exit /b %ERRORLEVEL%
)
