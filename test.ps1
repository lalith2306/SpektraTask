Param (
    [Parameter(Mandatory = $true)]
    [string] $trainerUserName,

    [string] $trainerUserPassword,

    [string] $vmCustomImageOsState = "generalized",
    [string] $vmAdminUserName,
    [string] $vmAdminPassword,
    [string] $provisionNonAdminUser,
    [string] $vmNonAdminUserName,
    [string] $vmNonAdminPassword,
    [string] $vmImageType = "custom"
)


Start-Transcript -Path C:\WindowsAzure\Logs\CloudLabsCustomScriptExtension.txt -Append
[Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls" 

#Import Common Functions
$shadowScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "shadow_common2.ps1"
. $shadowScriptPath

# Run Imported functions from cloudlabs-windows-functions.ps1
#WindowsServerCommon
#Enable-CloudLabsEmbeddedShadow $vmAdminUserName $trainerUserName $trainerUserPassword

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

            # Ensure membership in "Users" group
            if (-not (Get-LocalGroupMember -Group "Users" -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $nausername })) {
                Write-Host "Adding '$nausername' to Users group."
                Add-LocalGroupMember -Group "Users" -Member $nausername
            }

            # Ensure membership in "Remote Desktop Users" group
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

    # Check if the user exists
    $adminExists = Get-LocalUser | Where-Object { $_.Name -eq $existingusername -and $_.Enabled -eq $true }

    if ($adminExists) {
        Write-Host "The admin user '$existingusername' exists and updating the password."
        # Specify the username of the admin user whose password you want to reset
        $exusername = "$existingusername"

        # Check if the admin user is a member of the Administrators group
        $isAdmin = Get-LocalGroupMember -Group "Administrators" | Where-Object { $_.Name -eq $existingusername }

        if (-not $isAdmin) {
            Write-Host "Adding admin user '$existingusername' to Administrators group."
            Add-LocalGroupMember -Group "Administrators" -Member $existingusername
        }

        # Specify the new password
        $newPassword = ConvertTo-SecureString "$updatepassword" -AsPlainText -Force

        # Reset the password for the admin user
        Set-LocalUser -Name $exusername -Password $newPassword -PasswordNeverExpires $true
        Set-LocalUser -Name $exusername -Description "Administrator Account"
    }
    else {
        Write-Host "The admin user doesn't exists and creating new admin user."
        $newuserUsername = "$existingusername"
        $newuserpassword = "$updatepassword" 
        $newadminPassword = ConvertTo-SecureString $newuserpassword -AsPlainText -Force
 
        # Create a new local user account
        New-LocalUser -Name $newuserUsername -Password $newadminPassword  -Description "New Administrator Account" -AccountNeverExpires -UserMayNotChangePassword -PasswordNeverExpires

        # Add the user to the local administrators group
        Add-LocalGroupMember -Group "Administrators" -Member $newuserUsername
    }
}
else {

    # Set password expiry for Admin user

    Set-LocalUser -Name $vmAdminUserName -PasswordNeverExpires $true

    Write-Host "Successfully set password expiry for $vmAdminUserName."

}

if ($vmImageType -eq "marketplace") {
    Write-Host "OS type is marketplace. Checking for unallocated storage..."

    # Get the disk containing the OS (usually marked as bootable)
    $osDisk = Get-Disk | Where-Object IsBoot -eq $true

    if ($null -eq $osDisk) {
        Write-Error "No bootable disk found. Exiting..."
        exit 1
    }

    # Get the largest free space on the disk
    $largestFreeSpace = $osDisk | Select-Object -ExpandProperty LargestFreeExtent

    if ($largestFreeSpace -gt 0) {
        Write-Host "Unallocated space detected on the OS disk. Proceeding to extend the C: drive..."

        # Get the C: drive partition
        $cPartition = Get-Partition -DiskNumber $osDisk.Number | Where-Object DriveLetter -eq 'C'

        if ($null -ne $cPartition) {
            # Calculate the new size for the C: partition
            $newSize = $cPartition.Size + $largestFreeSpace

            # Extend the C: drive partition
            Resize-Partition -DiskNumber $osDisk.Number -PartitionNumber $cPartition.PartitionNumber -Size $newSize

            Write-Host "Successfully extended the C: drive to $($newSize / 1GB) GB."
        }
        else {
            Write-Error "C: drive partition not found. Unable to extend the partition."
        }
    }
    else {
        Write-Host "No unallocated space detected. No action required."
    }
}
else {
    Write-Host "OS Type is not marketplace. Skipping disk allocation."
}

# Enable shadowing for the target user that was fetched/created
Write-Host "Enabling VM shadow for target user: $vmNonAdminUserName..."
Enable-CloudLabsEmbeddedShadow $vmAdminUserName $vmNonAdminUserName $provisionNonAdminUser $trainerUserName $trainerUserPassword

Stop-Transcript
Restart-Computer -Force
