param (
    [string]$username = "badactor",
    [string]$password = "Lalith@12345"
)

# ========== Setup Logging ==========
$logDir = "C:\ProgramData"
if (-not (Test-Path $logDir)) {
    try { New-Item -Path $logDir -ItemType Directory -Force | Out-Null } catch { $logDir = $env:TEMP }
}
$logFile = "$logDir\SSHSetupLog.txt"
function Log-Message {
    param ([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logFile -Append -Encoding utf8 -ErrorAction SilentlyContinue
}
Log-Message "`n========== SCRIPT START =========="

# ========== Remove Existing User ==========
try {
    if (Get-LocalUser -Name $username -ErrorAction SilentlyContinue) {
        Log-Message "Removing existing user ${username}"
        Remove-LocalUser -Name $username -Confirm:$false
        Start-Sleep -Seconds 1
    }
} catch {
    Log-Message "Error removing user ${username}: $_"
}

# ========== Create New User ==========
try {
    Log-Message "Creating new user ${username}"
    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
    New-LocalUser -Name $username -Password $securePassword -FullName "Bad Actor" -Description "SSH User" -PasswordNeverExpires
    Add-LocalGroupMember -Group "Administrators" -Member $username
    Log-Message "User created and added to Administrators"
} catch {
    Log-Message "Error creating user: $_"
}

# ========== Install OpenSSH ==========
try {
    Log-Message "Installing OpenSSH Client and Server"
    Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0 -ErrorAction Stop
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 -ErrorAction Stop
    Log-Message "OpenSSH installed"
} catch {
    Log-Message "Error installing OpenSSH: $_"
}

# ========== Configure sshd_config ==========
$sshDir = "$env:ProgramData\ssh"
$sshdConfig = "$sshDir\sshd_config"
try {
    if (-not (Test-Path $sshDir)) {
        New-Item -Path $sshDir -ItemType Directory -Force | Out-Null
        icacls $sshDir /grant Administrators:F /grant SYSTEM:F
    }
    if (-not (Test-Path $sshdConfig)) {
        Set-Content -Path $sshdConfig -Value "Port 22`nListenAddress 0.0.0.0`nPasswordAuthentication yes"
    } else {
        $content = Get-Content -Path $sshdConfig -Raw
        if ($content -notmatch "PasswordAuthentication yes") {
            Add-Content -Path $sshdConfig -Value "`nPasswordAuthentication yes"
        }
    }
    if (-not (Get-Content $sshdConfig -Raw | Select-String "# edited by badactor")) {
        Set-Content -Path $sshdConfig -Value "# edited by badactor`n$(Get-Content -Raw $sshdConfig)"
    }
    Log-Message "sshd_config configured"
} catch {
    Log-Message "Error configuring sshd_config: $_"
}

# ========== Start SSH Service ==========
try {
    Start-Service sshd
    Set-Service sshd -StartupType Automatic
    Log-Message "sshd started and set to auto-start"
} catch {
    Log-Message "Error starting sshd: $_"
}

# ========== Configure Firewall ==========
try {
    if (-not (Get-NetFirewallRule -Name "sshd" -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -Name "sshd" -DisplayName "OpenSSH Server (sshd)" -Enabled True `
            -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
        Log-Message "Firewall rule created"
    } else {
        Log-Message "Firewall rule already exists"
    }
} catch {
    Log-Message "Error configuring firewall: $_"
}

# ========== Enable Audit Policies ==========
try {
    auditpol /set /category:* /success:enable /failure:enable
    Log-Message "Audit policies enabled"
} catch {
    Log-Message "Error enabling auditing: $_"
}

# ========== Set Audit ACL ==========
try {
    $acl = Get-Acl $sshdConfig
    $rule = New-Object System.Security.AccessControl.FileSystemAuditRule("Everyone", "Write", "Success")
    $acl.AddAuditRule($rule)
    Set-Acl -Path $sshdConfig -AclObject $acl
    Log-Message "Audit ACL set on sshd_config"
} catch {
    Log-Message "Error setting ACL: $_"
}

# ========== Setup Scheduled Task ==========
try {
    $scriptPath = "C:\setup_vm.ps1"
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`""
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 3) -RepetitionDuration ([TimeSpan]::FromDays(365))
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
    Register-ScheduledTask -TaskName "EditSshdConfig" -Action $action -Trigger $trigger -Principal $principal -Description "Trigger edits to sshd_config for auditing" -Force
    Log-Message "Scheduled task created"
} catch {
    Log-Message "Error creating scheduled task: $_"
}

# ========== Final Check ==========
try {
    Log-Message "Checking if port 22 is listening:"
    netstat -ano | findstr ":22" | Out-File -Append $logFile
} catch {
    Log-Message "Final port check failed: $_"
}

Log-Message "========== SCRIPT END ==========`n"
