Param (
    [Parameter(Mandatory = $true)]
    [string] $trainerUserName,
    [string] $trainerUserPassword,
    [string] $vmAdminUserName,
    [string] $vmAdminPassword,
    [string] $provisionNonAdminUser,
    [string] $vmNonAdminUserName,
    [string] $vmNonAdminPassword,
    [string] $AzureSubscriptionID,
    [string] $AzureTenantID,
    [string] $ODLID,
    [string] $labUUID,
    [string] $DeploymentID,
    [string] $AzureUserName,
    [string] $AzurePassword,
    [string] $userEmail,
    [string] $InstallCloudLabsShadow
)

Start-Transcript -Path C:\WindowsAzure\Logs\CloudLabsCustomScriptExtension.txt -Append
[Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

# Import Common Functions
$shadowScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "shadow_common2.ps1"
. $shadowScriptPath

# 1. Conditional Non-Admin User Creation

if ($provisionNonAdminUser -eq "yes" -and $vmNonAdminUserName -ne "") {
    Write-Host "ProvisionNonAdminUser=Yes. Creating Non-Admin user: $vmNonAdminUserName"

    $nonAdminPassword = ConvertTo-SecureString $vmNonAdminPassword -AsPlainText -Force
    if (-not (Get-LocalUser -Name $vmNonAdminUserName -ErrorAction SilentlyContinue)) {
        New-LocalUser -Name $vmNonAdminUserName -Password $nonAdminPassword -FullName $vmNonAdminUserName -Description "CloudLabs Non-Admin User" -PasswordNeverExpires
        Write-Host "Non-Admin user '$vmNonAdminUserName' created."
    } else {
        Write-Host "Non-Admin user '$vmNonAdminUserName' already exists. Skipping creation."
    }
} else {
    Write-Host "ProvisionNonAdminUser=No. Skipping Non-Admin user creation."
}

Add-LocalGroupMember -Group "Remote Desktop Users" -Member $vmNonAdminUserName
Write-Host "Non-Admin user '$vmNonAdminUserName' added to Remote Desktop Users group."

Start-Sleep -Seconds 5

# Install CloudLabs Shadow

InstallCloudLabsShadow $ODLID $InstallCloudLabsShadow

# combined: Use already set shadow target

Write-Host "Using shadow target user: $vmUserToShadow"

# Enable CloudLabs Embedded Shadow for the previously determined user
Enable-CloudLabsEmbeddedShadow $vmUserToShadow $trainerUserName $trainerUserPassword
Write-Host "CloudLabs Embedded Shadow enabled for '$vmUserToShadow'."

Write-Host "shadow2.ps1 execution completed."
Stop-Transcript

