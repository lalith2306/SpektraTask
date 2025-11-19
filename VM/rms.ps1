Start-Transcript -Path C:\WindowsAzure\Logs\CloudLabsCustomScriptExtension.txt -Append

# Define the desired DNS server
$dnsServer = "10.0.0.8"

# Get all active network adapters
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

# Loop through each adapter and set DNS
foreach ($adapter in $adapters) {
    Write-Host "Setting DNS server for adapter: $($adapter.Name)" -ForegroundColor Cyan
    Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses $dnsServer
}

# Verify the configuration
Write-Host "`nUpdated DNS settings:" -ForegroundColor Green
Get-DnsClientServerAddress | Where-Object { $_.ServerAddresses -contains $dnsServer } | Format-Table -AutoSize

$password = ConvertTo-SecureString "RecastSoftware94!!" -AsPlainText -Force
New-LocalUser -Name "RecastAdmin" -Password $password  -Description "New Administrator Account" -AccountNeverExpires -UserMayNotChangePassword -PasswordNeverExpires
Add-LocalGroupMember -Group "Administrators" -Member "RecastAdmin"

Stop-Transcript
