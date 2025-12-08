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

Start-Transcript -Path C:\WindowsAzure\Logs\CloudLabsCustomScriptExtension.txt -Append

$pssUrl = "https://experienceazure.blob.core.windows.net/vmaas/s/arm-templates/scripts/psscript.ps1"
$functionsUrl = "https://experienceazure.blob.core.windows.net/templates/cloudlabs-common/cloudlabs-windows-functions.ps1"

Invoke-WebRequest -Uri $pssUrl -OutFile "$env:TEMP\psscript.ps1" -UseBasicParsing
Invoke-WebRequest -Uri $functionsUrl -OutFile "$env:TEMP\cloudlabs-windows-functions.ps1" -UseBasicParsing

# Load the functions file first
. "$env:TEMP\cloudlabs-windows-functions.ps1"

# Now run psscript.ps1 with correct env var names (case-sensitive!)
powershell -ExecutionPolicy Unrestricted -File "$env:TEMP\psscript.ps1" `
    -trainerUserName "$env:trainerUserName" `
    -trainerUserPassword "$env:trainerUserPassword" `
    -vmCustomImageOsState "$env:vmCustomImageOsState" `
    -vmAdminUserName "$env:vmAdminUserName" `
    -vmAdminPassword "$env:vmAdminPassword" `
    -provisionNonAdminUser "$env:provisionNonAdminUser" `
    -vmNonAdminUserName "$env:vmNonAdminUserName" `
    -vmNonAdminPassword "$env:vmNonAdminPassword" `
    -vmImageType "$env:vmImageType"

# Define the desired DNS servers
$dnsServers = @("10.0.0.8", "8.8.8.8")
 
# Get all active network adapters
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
 
# Loop through each adapter and set DNS
foreach ($adapter in $adapters) {
   Write-Host "Setting DNS servers for adapter: $($adapter.Name)" -ForegroundColor Cyan
   Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses $dnsServers
}
 
# Verify the configuration
Write-Host "`nUpdated DNS settings:" -ForegroundColor Green
Get-DnsClientServerAddress | Where-Object { $_.ServerAddresses -contains "10.0.0.8" -or $_.ServerAddresses -contains "8.8.8.8" } | Format-Table -AutoSize
 
$password = ConvertTo-SecureString "RecastSoftware94!!" -AsPlainText -Force
Set-LocalUser -Name "RecastAdmin" -Password $password

Import-Module ActiveDirectory
 
# Add-ADGroupMember -Identity "Administrators" -Members "RecastUser"
# Add-ADGroupMember -Identity "Domain Admins" -Members "RecastUser"

$scriptPath2 = "C:\logontask.ps1"
# Define the content of the script
$scriptContent2 = @'
Start-Transcript -Path "C:\WindowsAzure\Logs\logontask.log" -Append
Import-Module ActiveDirectory
Add-ADGroupMember -Identity 'Domain Admins' -Members 'RecastUser'
Add-ADGroupMember -Identity 'Administrators' -Members 'RecastUser'
Stop-Transcript
'@
# Create and save the script to the specified path
$scriptContent2 | Set-Content -Path $scriptPath2
# Verify the file is created
Write-Host "Script saved at: $scriptPath2"
$getTime = (Get-Date).AddMinutes(2)
$taskName = "logontask"
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File $scriptPath2"
$trigger = New-ScheduledTaskTrigger -Once -At $getTime
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
# Register the task
Register-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -TaskName $taskName

$scriptPath3 = "C:\logontask2.ps1"
# Define the content of the script
$scriptContent3 = @'
Start-Transcript -Path "C:\WindowsAzure\Logs\logontask2.log" -Append
Import-Module ActiveDirectory
Add-ADGroupMember -Identity 'Domain Admins' -Members 'RecastAdmin'
Add-ADGroupMember -Identity 'Administrators' -Members 'RecastAdmin'
Stop-Transcript
'@
# Create and save the script to the specified path
$scriptContent3 | Set-Content -Path $scriptPath3
# Verify the file is created
Write-Host "Script saved at: $scriptPath3"
$getTime = (Get-Date).AddMinutes(2)
$taskName2 = "logontask2"
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File $scriptPath3"
$trigger = New-ScheduledTaskTrigger -Once -At $getTime
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
# Register the task
Register-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -TaskName $taskName2
    
# After everything is done, stop transcript
Stop-Transcript








