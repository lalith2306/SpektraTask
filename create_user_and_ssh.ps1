param (
    [string]$username = "badactor",
    [string]$password
)

# Create a secure string for the password
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force

# Create the new user
New-LocalUser -Name $username -Password $securePassword -FullName "Bad Actor" -Description "User for SSH access"

# Add user to Administrators group (required for SSH access by default OpenSSH configuration)
Add-LocalGroupMember -Group "Administrators" -Member $username

# Install OpenSSH Server
$osVersion = (Get-CimInstance -ClassName Win32_OperatingSystem).Version
if ($osVersion -ge "10.0.17763") {
    # OpenSSH is included in Windows Server 2019 and later
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
} else {
    # For older versions, download and install OpenSSH (example for Windows Server 2016)
    $openSshUrl = "https://github.com/PowerShell/Win32-OpenSSH/releases/download/v8.1.0.0p1-Beta/OpenSSH-Win64.zip"
    $zipPath = "$env:TEMP\OpenSSH-Win64.zip"
    $installPath = "C:\Program Files\OpenSSH"
    Invoke-WebRequest -Uri $openSshUrl -OutFile $zipPath
    Expand-Archive -Path $zipPath -DestinationPath $installPath -Force
    & "$installPath\OpenSSH-Win64\install-sshd.ps1"
}

# Start and configure SSH service
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

# Ensure firewall rule for SSH (port 22)
New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22

# Configure SSH to allow password authentication
$sshdConfigPath = "C:\ProgramData\ssh\sshd_config"
$sshdConfig = Get-Content -Path $sshdConfigPath
$sshdConfig = $sshdConfig -replace "#PasswordAuthentication yes", "PasswordAuthentication yes"
$sshdConfig = $sshdConfig -replace "Match Group administrators", "#Match Group administrators"
$sshdConfig = $sshdConfig -replace "AuthorizedKeysFile .ssh/authorized_keys", "#AuthorizedKeysFile .ssh/authorized_keys"
Set-Content -Path $sshdConfigPath -Value $sshdConfig

# Restart SSH service to apply changes
Restart-Service sshd