Start-Transcript -Path C:\WindowsAzure\Logs\CloudLabsCustomScriptExtension.txt -Append
 Param (
    [Parameter(Mandatory = $true)]

    [string]
    $trainerUserName,

    [string]
    $trainerUserPassword,

    [string]
    $vmCustomImageOsState,
    $vmAdminUserName,
    $vmAdminPassword,
    $provisionNonAdminUser,
    $vmNonAdminUserName,
    $vmNonAdminPassword,
    $vmImageType
)
# This script sets the DNS server to 10.0.0.8 for all active network adapters
 
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
 
$root = $PSScriptRoot

Write-Host "Root path is: $root"

# Common-function
. "$root\cloudlabs-windows-functions.ps1"

# Run actual CSE with parameters from ARM
& "$root\psscript.ps1" `
    $EnableCloudLabsEmbeddedShadow `
    $vmCustomImageOsState `
    $vmAdminUserName `
    $vmPasswordAdmin `
    $provisionNonAdminUser `
    $vmNonAdminUserName `
    $vmPasswordNonAdmin `
    $vmImageType
    
# After everything is done, stop transcript
Stop-Transcript
