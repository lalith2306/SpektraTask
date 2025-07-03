param (
    [string]$sshdConfigPath = "C:\ProgramData\ssh\sshd_config"
)

# Add "# edited by badactor" to the top of sshd_config
$newContent = "# edited by badactor`n" + (Get-Content -Path $sshdConfigPath -Raw)
Set-Content -Path $sshdConfigPath -Value $newContent