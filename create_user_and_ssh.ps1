param (
    [string]$username = "badactor",
    [string]$password,
    [string]$editScriptUrl = "https://raw.githubusercontent.com/lalith2306/SpektraTask/refs/heads/main/edit_sshd_config.ps1"
)

# Initialize logging
$logFile = "C:\ProgramData\SSHSetupLog.txt"
function Log-Message {
    param ([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logFile -Append
}

Log-Message "Starting script execution"

# Install PowerShell 7.4.2
try {
    Log-Message "Downloading PowerShell 7.4.2"
    Invoke-WebRequest -Uri "https://github.com/PowerShell/PowerShell/releases/download/v7.4.2/PowerShell-7.4.2-win-x64.msi" -OutFile "$env:TEMP\pwsh.msi"
    Start-Process msiexec.exe -ArgumentList "/i $env:TEMP\pwsh.msi /quiet" -Wait
    if (Test-Path "C:\Program Files\PowerShell\7\pwsh.exe") {
        Log-Message "PowerShell 7 installed successfully"
        & "C:\Program Files\PowerShell\7\pwsh.exe" -Command '$PSVersionTable' | Out-File -FilePath $logFile -Append
    } else {
        Log-Message "PowerShell 7 installation failed"
        exit 1
    }
} catch {
    Log-Message "Error installing PowerShell 7: $_"
    exit 1
}

# Install Azure PowerShell
try {
    Log-Message "Installing Azure PowerShell"
    & "C:\Program Files\PowerShell\7\pwsh.exe" -Command "Install-Module -Name Az -AllowClobber -Force -Scope AllUsers"
    Log-Message "Azure PowerShell installed"
} catch {
    Log-Message "Error installing Azure PowerShell: $_"
    exit 1
}

# Enable auditing for all subcategories
try {
    Log-Message "Enabling auditing for all categories"
    & "C:\Program Files\PowerShell\7\pwsh.exe" -Command "auditpol /set /category:* /success:enable /failure:enable"
    Log-Message "Auditing enabled"
} catch {
    Log-Message "Error enabling auditing: $_"
    exit 1
}

# Install OpenSSH Server
try {
    Log-Message "Installing OpenSSH Server"
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
    if (Get-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 | Where-Object State -eq "Installed") {
        Log-Message "OpenSSH Server installed"
    } else {
        Log-Message "OpenSSH Server installation failed"
        exit 1
    }
} catch {
    Log-Message "Error installing OpenSSH Server: $_"
    exit 1
}

# Create the "badactor" user
try {
    Log-Message "Creating user $username"
    New-LocalUser -Name $username -Password (ConvertTo-SecureString $password -AsPlainText -Force) -FullName "Bad Actor" -Description "User for SSH access"
    Add-LocalGroupMember -Group "Administrators" -Member $username
    Log-Message "User $username created and added to Administrators"
} catch {
    Log-Message "Error creating user $username: $_"
    exit 1
}

# Start and configure SSH service
try {
    Log-Message "Starting sshd service"
    Start-Service sshd
    Set-Service -Name sshd -StartupType 'Automatic'
    Log-Message "sshd service started and set to Automatic"
} catch {
    Log-Message "Error starting sshd service: $_"
    exit 1
}

# Ensure firewall rule for SSH (port 22)
try {
    Log-Message "Configuring firewall rule for SSH"
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
    Log-Message "Firewall rule for SSH created"
} catch {
    Log-Message "Error creating firewall rule: $_"
    exit 1
}

# Configure SSH to allow password authentication
$sshdConfigPath = "C:\ProgramData\ssh\sshd_config"
try {
    if (-not (Test-Path $sshdConfigPath)) {
        Log-Message "sshd_config not found at $sshdConfigPath"
        exit 1
    }
    Log-Message "Configuring $sshdConfigPath"
    $sshdConfig = Get-Content -Path $sshdConfigPath
    $sshdConfig = $sshdConfig -replace "#PasswordAuthentication yes", "PasswordAuthentication yes"
    $sshdConfig = $sshdConfig -replace "Match Group administrators", "#Match Group administrators"
    $sshdConfig = $sshdConfig -replace "AuthorizedKeysFile .ssh/authorized_keys", "#AuthorizedKeysFile .ssh/authorized_keys"
    Set-Content -Path $sshdConfigPath -Value $sshdConfig
    Log-Message "sshd_config updated"
} catch {
    Log-Message "Error configuring sshd_config: $_"
    exit 1
}

# Set up auditing for sshd_config
try {
    Log-Message "Setting audit ACL on $sshdConfigPath"
    $acl = Get-Acl -Path $sshdConfigPath
    $auditRule = New-Object System.Security.AccessControl.FileSystemAuditRule("Everyone", "Write", "Success")
    $acl.AddAuditRule($auditRule)
    Set-Acl -Path $sshdConfigPath -AclObject $acl
    Log-Message "Audit ACL set on $sshdConfigPath"
} catch {
    Log-Message "Error setting audit ACL: $_"
    exit 1
}

# Add "# edited by badactor" to sshd_config
try {
    Log-Message "Adding '# edited by badactor' to $sshdConfigPath"
    $content = Get-Content -Path $sshdConfigPath -Raw
    if (-not ($content -like "# edited by badactor*")) {
        $newContent = "# edited by badactor`n" + $content
        Set-Content -Path $sshdConfigPath -Value $newContent
        Log-Message "Added '# edited by badactor' to $sshdConfigPath"
    } else {
        Log-Message "'# edited by badactor' already present"
    }
} catch {
    Log-Message "Error editing sshd_config: $_"
    exit 1
}

# Restart SSH service
try {
    Log-Message "Restarting sshd service"
    Restart-Service sshd
    Log-Message "sshd service restarted"
} catch {
    Log-Message "Error restarting sshd service: $_"
    exit 1
}

# Download the recurring edit script
$editScriptPath = "C:\ProgramData\edit_sshd_config.ps1"
try {
    Log-Message "Downloading edit script from $editScriptUrl"
    Invoke-WebRequest -Uri $editScriptUrl -OutFile $editScriptPath -ErrorAction Stop
    Log-Message "Edit script downloaded to $editScriptPath"
} catch {
    Log-Message "Error downloading edit script: $_"
    exit 1
}

# Create a scheduled task to run the edit script every 3 minutes
try {
    Log-Message "Creating scheduled task for recurring edits"
    $action = New-ScheduledTaskAction -Execute "C:\Program Files\PowerShell\7\pwsh.exe" -Argument "-ExecutionPolicy Bypass -File $editScriptPath -sshdConfigPath $sshdConfigPath"
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 3) -RepetitionDuration ([TimeSpan]::MaxValue)
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
    Register-ScheduledTask -TaskName "EditSshdConfig" -Action $action -Trigger $trigger -Principal $principal -Description "Edits sshd_config every 3 minutes to trigger audit logs" -Force
    Log-Message "Scheduled task created"
} catch {
    Log-Message "Error creating scheduled task: $_"
    exit 1
}

Log-Message "Script execution completed"
