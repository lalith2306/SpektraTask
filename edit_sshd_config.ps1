param (
    [string]$sshdConfigPath = "C:\ProgramData\ssh\sshd_config"
)
# Add "# edited by badactor" to the top of sshd_config if not present
if (-not (Test-Path $sshdConfigPath)) {
    Write-Error "sshd_config not found at $sshdConfigPath"
    exit 1
}
$content = Get-Content -Path $sshdConfigPath -Raw
if (-not ($content -like "# edited by badactor*")) {
    $newContent = "# edited by badactor`n" + $content
    Set-Content -Path $sshdConfigPath -Value $newContent
}
