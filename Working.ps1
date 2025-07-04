param (
    [string]$username = "badactor",
    [string]$password = "Lalith@12345"
)

# Initialize logging with robust fallback
$logDir = "C:\ProgramData"
if (-not (Test-Path $logDir)) {
    try {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    } catch {
        $logDir = $env:TEMP  # Fallback to TEMP if ProgramData fails
    }
}
$logFile = "$logDir\SSHSetupLog.txt"
function Log-Message {
    param ([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logFile -Append -ErrorAction SilentlyContinue
}
Log-Message "Starting script execution on VM (PS 5.1)"

# Remove existing user with retry
try {
    Log-Message "Checking and removing existing user ${username}"
    $maxAttempts = 3
    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        if (Get-LocalUser -Name $username -ErrorAction SilentlyContinue) {
            Remove-LocalUser -Name $username -Confirm:$false -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1
            if (-not (Get-LocalUser -Name $username -ErrorAction SilentlyContinue)) {
                Log-Message "Removed existing user ${username}"
                break
            } elseif ($attempt -eq $maxAttempts) {
                Log-Message "Failed to remove user ${username} after $maxAttempts attempts"
            }
        } else {
            Log-Message "User ${username} not found, skipping removal"
            break
        }
    }
} catch {
    Log-Message "Error removing user ${username}: $_"
}

# Create the new user
try {
    Log-Message "Creating user ${username}"
    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
    New-LocalUser -Name $username -Password $securePassword -FullName "Bad Actor" -Description "SSH User" -PasswordNeverExpires
    Add-LocalGroupMember -Group "Administrators" -Member $username
    Log-Message "User ${username} created and added to Administrators"
} catch {
    Log-Message "Error creating user ${username}: $_"
}

# Install OpenSSH Server
try {
    Log-Message "Installing OpenSSH Server"
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
    if (Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*') {
        Log-Message "OpenSSH Server installed"
    } else {
        Log-Message "OpenSSH Server installation failed"
    }
} catch {
    Log-Message "Error installing OpenSSH Server: $_"
}

# Configure SSH to allow password authentication
$sshdConfigPath = "$logDir\ssh\sshd_config"
try {
    Log-Message "Configuring $sshdConfigPath"
    if (-not (Test-Path $logDir\ssh)) {
        New-Item -Path $logDir\ssh -ItemType Directory -Force | Out-Null
        icacls "$logDir\ssh" /grant Administrators:F /grant SYSTEM:F
    }
    if (-not (Test-Path $sshdConfigPath)) {
        New-Item -Path $sshdConfigPath -ItemType File -Force | Out-Null
        Set-Content -Path $sshdConfigPath -Value "Port 22`nListenAddress 0.0.0.0`nPasswordAuthentication yes"
        icacls $sshdConfigPath /grant Administrators:F /grant SYSTEM:F
    } else {
        $content = Get-Content $sshdConfigPath -Raw
        if ($content -notmatch "Port 22" -or $content -notmatch "ListenAddress 0.0.0.0" -or $content -notmatch "PasswordAuthentication yes") {
            Set-Content -Path $sshdConfigPath -Value "Port 22`nListenAddress 0.0.0.0`nPasswordAuthentication yes"
        }
    }
    Log-Message "sshd_config updated to allow password authentication"
} catch {
    Log-Message "Error configuring sshd_config: $_"
}

# Start and configure SSH service with restart prompt
try {
    Log-Message "Starting sshd service"
    if ((Get-Service sshd -ErrorAction SilentlyContinue)) {
        if ((Get-Service sshd).Status -eq "Stopped") {
            Start-Service sshd -ErrorAction Stop
            Start-Sleep -Seconds 5  # Give time to start
            if ((Get-Service sshd).Status -eq "Running") {
                Log-Message "sshd service started successfully"
            } else {
                Log-Message "sshd service failed to start; a system restart may be required. Run 'Restart-Computer -Force' and rerun the script."
            }
        }
    }
    Set-Service -Name sshd -StartupType 'Automatic'
    Log-Message "sshd service set to Automatic"
} catch {
    Log-Message "Error starting sshd service: $_"
}

# Configure firewall rule for SSH
try {
    Log-Message "Configuring firewall rule for SSH"
    if (-not (Get-NetFirewallRule -Name "sshd" -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -Name "sshd" -DisplayName "OpenSSH Server (sshd)" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
    }
    Log-Message "Firewall rule for SSH created"
} catch {
    Log-Message "Error creating firewall rule: $_"
}

# Enable auditing for all categories
try {
    Log-Message "Enabling auditing for all categories"
    auditpol /set /category:* /success:enable /failure:enable
    Log-Message "Auditing enabled"
} catch {
    Log-Message "Error enabling auditing: $_"
}

# Set system ACLs to audit sshd_config
try {
    Log-Message "Setting audit ACL on $sshdConfigPath"
    $acl = Get-Acl -Path $sshdConfigPath -ErrorAction SilentlyContinue
    if ($acl) {
        $auditRule = New-Object System.Security.AccessControl.FileSystemAuditRule("Everyone", "Write", "Success")
        $acl.AddAuditRule($auditRule)
        Set-Acl -Path $sshdConfigPath -AclObject $acl
    }
    Log-Message "Audit ACL set on $sshdConfigPath"
} catch {
    Log-Message "Error setting audit ACL: $_"
}

# Add "# edited by badactor" to sshd_config
try {
    Log-Message "Adding '# edited by badactor' to $sshdConfigPath"
    $content = Get-Content -Path $sshdConfigPath -Raw -ErrorAction SilentlyContinue
    if ($content -and -not ($content -like "# edited by badactor*")) {
        $newContent = "# edited by badactor`n" + $content
        Set-Content -Path $sshdConfigPath -Value $newContent
        Log-Message "Added '# edited by badactor' to $sshdConfigPath"
    } else {
        Log-Message "'# edited by badactor' already present or file empty"
    }
} catch {
    Log-Message "Error editing sshd_config: $_"
}

# Restart SSH service
try {
    Log-Message "Restarting sshd service"
    Restart-Service sshd -ErrorAction SilentlyContinue
    Log-Message "sshd service restarted"
} catch {
    Log-Message "Error restarting sshd service: $_"
}

# Define the recurring edit function
function Edit-SshdConfig {
    param ([string]$sshdConfigPath)
    try {
        Log-Message "Executing recurring edit on $sshdConfigPath"
        $content = Get-Content -Path $sshdConfigPath -Raw -ErrorAction SilentlyContinue
        if ($content -and -not ($content -like "*Recurring Edit*")) {
            $newContent = "Recurring Edit`n" + $content
            Set-Content -Path $sshdConfigPath -Value $newContent
            Log-Message "Recurring edit applied to $sshdConfigPath"
        } else {
            Log-Message "Recurring edit already present or file empty"
        }
    } catch {
        Log-Message "Error in recurring edit: $_"
    }
}

# Create a scheduled task to run the script every 3 minutes
try {
    Log-Message "Creating scheduled task for recurring edits"
    $scriptPath = "C:\setup_vm.ps1"
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File $scriptPath -password $password"
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 3) -RepetitionDuration (New-TimeSpan -Days 365)
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
    Register-ScheduledTask -TaskName "EditSshdConfig" -Action $action -Trigger $trigger -Principal $principal -Description "Edits sshd_config every 3 minutes to trigger audit logs" -Force
    Log-Message "Scheduled task created"
} catch {
    Log-Message "Error creating scheduled task: $_"
}

Log-Message "Script execution completed"
