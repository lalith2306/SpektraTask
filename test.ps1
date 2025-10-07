Param (
    [Parameter(Mandatory = $true)]
    [string] $trainerUserName,

    [string] $trainerUserPassword,

    [string] $vmCustomImageOsState = "generalized",   # default to avoid "specialized" branch
    [string] $vmAdminUserName,
    [string] $vmAdminPassword,
    [string] $provisionNonAdminUser,
    [string] $vmNonAdminUserName,
    [string] $vmNonAdminPassword,
    [string] $vmImageType = "custom"                  # default to avoid "marketplace" branch
)

Start-Transcript -Path C:\WindowsAzure\Logs\CloudLabsCustomScriptExtension.txt -Append
[Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls" 

#Import Common Functions
$path = pwd
$path = $path.Path
$commonscriptpath = "$path" + "\cloudlabs-common\cloudlabs-windows-functions.ps1"
. $commonscriptpath

#Password reset for trainer if specialized image is used
$updatedTrainerPassword = "$trainerUserPassword"
 
# Check if the trainer exists
$trainerExists = Get-LocalUser | Where-Object { $_.Name -eq $trainerUserName -and $_.Enabled -eq $true }
 
if ($trainerExists) {
    Write-Host "The admin user '$trainerUserName' exists and updating the password."
 
    # Specify the new password
    $newTrainerPassword = ConvertTo-SecureString "$updatedTrainerPassword" -AsPlainText -Force
 
    # Reset the password for trainer
    Set-LocalUser -Name $trainerUserName -Password $newTrainerPassword

    Enable-CloudLabsEmbeddedShadow $vmAdminUserName $vmNonAdminUserName $provisionNonAdminUser $trainerUserName $trainerUserPassword
}
else {
    Enable-CloudLabsEmbeddedShadow $vmAdminUserName $vmNonAdminUserName $provisionNonAdminUser $trainerUserName $trainerUserPassword
}

$username = $vmNonAdminUserName
$password = $vmNonAdminPassword
$pNAUser = $provisionNonAdminUser

#creating a non admin user if $provisionNonAdminUser is set to yes
$nausername = $username
$napassword = ConvertTo-SecureString $password -AsPlainText -Force

if ($pNAUser -eq "yes") {

    $naUserExists = Get-LocalUser | Where-Object { $_.Name -eq $nausername }

    if ($naUserExists) {
        Write-Host "The user '$nausername' exists. Checking if user is part of Administrators group."

        $isAdmin = Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*\$nausername" }

        if ($isAdmin) {
            Write-Host "User '$nausername' is part of Administrators group. Renaming and recreating as non-admin."
            
            Rename-LocalUser -Name $nausername -NewName "$nausername-Old"

            New-LocalUser -Name $nausername -Password $napassword -Description "Non-Admin User" -PasswordNeverExpires

            Add-LocalGroupMember -Group "Users" -Member $nausername
            Add-LocalGroupMember -Group "Remote Desktop Users" -Member $nausername
        }
        else {
            Write-Host "User '$nausername' is NOT an admin. Resetting password and verifying group memberships."

            Set-LocalUser -Name $nausername -Password $napassword
            Set-LocalUser -Name $nausername -Description "Non-Admin User"

            if (-not (Get-LocalGroupMember -Group "Users" -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $nausername })) {
                Write-Host "Adding '$nausername' to Users group."
                Add-LocalGroupMember -Group "Users" -Member $nausername
            }

            if (-not (Get-LocalGroupMember -Group "Remote Desktop Users" -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $nausername })) {
                Write-Host "Adding '$nausername' to Remote Desktop Users group."
                Add-LocalGroupMember -Group "Remote Desktop Users" -Member $nausername
            }
        }

    }
    else {
        Write-Host "User '$nausername' does not exist. Creating new user."

        New-LocalUser -Name $nausername -Password $napassword -Description "Non-Admin User" -PasswordNeverExpires

        Add-LocalGroupMember -Group "Users" -Member $nausername
        Add-LocalGroupMember -Group "Remote Desktop Users" -Member $nausername
    }
}

#Password reset for adminuser if specialized image is used
$existingusername = "$vmAdminUserName"
$updatepassword = "$vmAdminPassword"

if ($vmCustomImageOsState -eq "specialized") {
    # This branch will not run due to default value "generalized"
    Write-Host "Skipping specialized admin password reset."
}
else {
    Set-LocalUser -Name $vmAdminUserName -PasswordNeverExpires $true
    Write-Host "Successfully set password expiry for $vmAdminUserName."
}

if ($vmImageType -eq "marketplace") {
    # This branch will not run due to default value "custom"
    Write-Host "Skipping C: drive extension for marketplace OS."
}
else {
    Write-Host "OS Type is not marketplace. Skipping disk allocation."
}

# Enable shadowing after all users are set up
Write-Host "Enabling VM shadow for target user..."
Enable-CloudLabsEmbeddedShadow $vmAdminUserName $vmNonAdminUserName $provisionNonAdminUser $trainerUserName $trainerUserPassword

Stop-Transcript
Restart-Computer -Force
