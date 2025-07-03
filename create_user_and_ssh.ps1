param (
    [string]$username = "badactor",
    [string]$password,
    [string]$editScriptUrl = "https://raw.githubusercontent.com/lalith2306/SpektraTask/refs/heads/main/edit_sshd_config.ps1"
)

# Create a secure string for the password
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force

# Install PowerShell 7.4.2
Invoke-WebRequest -Uri "https://github.com/PowerShell/PowerShell/releases/download/v7.4.2/PowerShell-7.4.2-win-x64.msi" -OutFile "$env:TEMP\pwsh.msi"
Start-Process msiexec.exe -ArgumentList "/i $env:TEMP\pwsh.msi /quiet" -Wait
# Verify PowerShell 7 installation
& "C:\Program Files\PowerShell\7\pwsh.exe" -Command '$PSVersionTable'

# Install Azure PowerShell
& "C:\Program Files\PowerShell\7\pwsh.exe" -Command "Install-Module -Name Az -AllowClobber -Force -Scope AllUsers"

# Enable auditing for all subcategories (mimics Group Policy)
& "C:\Program Files\PowerShell\7\pwsh.exe" -Command "auditpol /set /category:* /success:enable /failure:enable"

# Install OpenSSH Server (per Microsoft documentation for Windows Server 2019)
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Create the new user "badactor" with same password as azureuser
New-LocalUser -Name $username -Password $securePassword -FullName "Bad Actor" -Description "User for SSH access"
Add-LocalGroupMember -Group "Administrators" -Member $username

# Start and configure SSH service
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

# Ensure firewall rule for SSH (port 22)
New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22

# Configure SSH to allow password authentication
$sshdConfigPath = "C:\ProgramData\ssh\sshd_config"
if (-not (Test-Path $sshdConfigPath)) {
    Write-Error "sshd_config not found at $sshdConfigPath"
    exit 1
}
$sshdConfig = Get-Content -Path $sshdConfigPath
$sshdConfig = $sshdConfig -replace "#PasswordAuthentication yes", "PasswordAuthentication yes"
$sshdConfig = $sshdConfig -replace "Match Group administrators", "#Match Group administrators"
$sshdConfig = $sshdConfig -replace "AuthorizedKeysFile .ssh/authorized_keys", "#AuthorizedKeysFile .ssh/authorized_keys"
Set-Content -Path $sshdConfigPath -Value $sshdConfig

# Set up auditing for sshd_config
$acl = Get-Acl -Path $sshdConfigPath
$auditRule = New-Object System.Security.AccessControl.FileSystemAuditRule("Everyone", "Write", "Success")
$acl.AddAuditRule($auditRule)
Set-Acl -Path $sshdConfigPath -AclObject $acl

# Add "# edited by badactor" to the top of sshd_config if not present
$content = Get-Content -Path $sshdConfigPath -Raw
if (-not ($content -like "# edited by badactor*")) {
    $newContent = "# edited by badactor`n" + $content
    Set-Content -Path $sshdConfigPath -Value $newContent
}

# Restart SSH service
Restart-Service sshd

# Download the recurring edit script
$editScriptPath = "C:\ProgramData\edit_sshd_config.ps1"
try {
    Invoke-WebRequest -Uri $editScriptUrl -OutFile $editScriptPath -ErrorAction Stop
} catch {
    Write-Error "Failed to download edit script: $_"
    exit 1
}

# Create a scheduled task to run the edit script every 3 minutes
$action = New-ScheduledTaskAction -Execute "C:\Program Files\PowerShell\7\pwsh.exe" -Argument "-ExecutionPolicy Bypass -File $editScriptPath -sshdConfigPath $sshdConfigPath"
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 3) -RepetitionDuration ([TimeSpan]::MaxValue)
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
Register-ScheduledTask -TaskName "EditSshdConfig" -Action $action -Trigger $trigger -Principal $principal -Description "Edits sshd_config every 3 minutes to trigger audit logs" -Force
