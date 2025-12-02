Start-Transcript -Path C:\WindowsAzure\Logs\CloudLabsCustomScriptExtension.txt -Append

Param (
    [Parameter(Mandatory = $true)]
    [string]$trainerUserName,

    [string]$trainerUserPassword,

    [string]$vmCustomImageOsState,
    [string]$vmAdminUserName,
    [string]$vmAdminPassword,
    [string]$provisionNonAdminUser,
    [string]$vmNonAdminUserName,
    [string]$vmNonAdminPassword,
    [string]$vmImageType
)

$pssUrl = "https://experienceazure.blob.core.windows.net/vmaas/s/arm-templates/scripts/psscript.ps1"
$functionsUrl = "https://experienceazure.blob.core.windows.net/templates/cloudlabs-common/cloudlabs-windows-functions.ps1"

Invoke-WebRequest -Uri $pssUrl -OutFile "$env:TEMP\psscript.ps1" -UseBasicParsing
Invoke-WebRequest -Uri $functionsUrl -OutFile "$env:TEMP\cloudlabs-windows-functions.ps1" -UseBasicParsing

# Run psscript.ps1 with exact same parameters that ARM would pass
powershell -ExecutionPolicy Unrestricted -File "$env:TEMP\psscript.ps1" `
    -trainerUserName "$env:TRAINERUSERNAME" `
    -trainerUserPassword "$env:TRAINERUSERPASSWORD" `
    -vmCustomImageOsState "$env:VMCUSTOMIMAGEOSSTATE" `
    -vmAdminUserName "$env:VMADMINUSERNAME" `
    -vmAdminPassword "$env:VMADMINPASSWORD" `
    -provisionNonAdminUser "$env:PROVISIONNONADMINUSER" `
    -vmNonAdminUserName "$env:VMNONADMINUSERNAME" `
    -vmNonAdminPassword "$env:VMNONADMINPASSWORD" `
    -vmImageType "$env:VMIMAGETYPE"
    
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

$password = ConvertTo-SecureString "RecastSoftware25!!" -AsPlainText -Force
New-LocalUser -Name "RecastUser" -Password $password  -Description "New Administrator Account" -AccountNeverExpires -UserMayNotChangePassword -PasswordNeverExpires
Add-LocalGroupMember -Group "Administrators" -Member "RecastUser"

Stop-Transcript



