Param (
    [Parameter(Mandatory = $true)]
    [string] $trainerUserName,
    [string] $trainerUserPassword,
    [string] $vmCustomImageOsState,
    [string] $vmAdminUserName,
    [string] $vmAdminPassword,
    [string] $provisionNonAdminUser,
    [string] $vmNonAdminUserName,
    [string] $vmNonAdminPassword,
    [string] $AzureUserName,
    [string] $AzureUserPassword,
    [string] $vmImageType
)

Start-Transcript -Path C:\WindowsAzure\Logs\CloudLabsCustomScriptExtension.txt -Append
[Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

# Import Common Functions
$path = pwd
$path = $path.Path
$commonscriptpath = "$path\cloudlabs-common\cloudlabs-windows-functions.ps1"
. $commonscriptpath

# ---------------------------
# 1. Conditional Non-Admin User Creation
# ---------------------------
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

# ---------------------------
# 2. Wait 5 seconds
# ---------------------------
Start-Sleep -Seconds 5

# ---------------------------
# 3. Install CloudLabs Shadow
# ---------------------------
InstallCloudLabsShadow $ODLID $InstallCloudLabsShadow

# ---------------------------
# 4. Determine vmUserToShadow
# ---------------------------
if ($provisionNonAdminUser -eq "yes" -and $vmNonAdminUserName -ne "") {
    $vmUserToShadow = $vmNonAdminUserName
    Write-Host "Shadow target user set to Non-Admin: $vmUserToShadow"
} else {
    $vmUserToShadow = $vmAdminUserName
    Write-Host "Shadow target user set to Admin: $vmUserToShadow"
}

# ---------------------------
# 5. Enable CloudLabs Embedded Shadow
# ---------------------------
Enable-CloudLabsEmbeddedShadow $vmAdminUserName $vmNonAdminUserName $provisionNonAdminUser $trainerUserName $trainerUserPassword

Write-Host "shadow2.ps1 execution completed."
Stop-Transcript

