#.NET Framework
Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?linkid=2088631" -OutFile "$env:TEMP\ndp48-installer.exe"
Start-Process "$env:TEMP\ndp48-installer.exe" -ArgumentList "/quiet /norestart" -Wait


#Install Chocolatey if not installed
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Chocolatey not found. Installing..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
} else {
    Write-Host "Chocolatey already installed." -ForegroundColor Green
}

#Install Git if not installed
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Git not found. Installing..." -ForegroundColor Yellow
    choco install git -y
} else {
    Write-Host "Git already installed." -ForegroundColor Green
}

# node
choco install nodejs --version=22.0.0

# Azure developer CLI
choco install azd
choco upgrade azd

# github
cd C:\Users\Lalith\Desktop
git clone https://github.com/lalith2306/mcsmcp

#docker