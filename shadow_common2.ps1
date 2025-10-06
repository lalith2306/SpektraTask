#Function1 - Disable Enhanced Security for Internet Explorer
Function Disable-InternetExplorerESC
{
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0 -Force -ErrorAction SilentlyContinue -Verbose
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0 -Force -ErrorAction SilentlyContinue -Verbose
    #Stop-Process -Name Explorer -Force
    Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green -Verbose
}

#Function2 - Enable File Download on Windows Server Internet Explorer
Function Enable-IEFileDownload
{
    $HKLM = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3"
    $HKCU = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3"
    Set-ItemProperty -Path $HKLM -Name "1803" -Value 0 -ErrorAction SilentlyContinue -Verbose
    Set-ItemProperty -Path $HKCU -Name "1803" -Value 0 -ErrorAction SilentlyContinue -Verbose
    Set-ItemProperty -Path $HKLM -Name "1604" -Value 0 -ErrorAction SilentlyContinue -Verbose
    Set-ItemProperty -Path $HKCU -Name "1604" -Value 0 -ErrorAction SilentlyContinue -Verbose
}

#Function3 - Enable Copy Page Content in IE
Function Enable-CopyPageContent-In-InternetExplorer
{
    $HKLM = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3"
    $HKCU = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3"
    Set-ItemProperty -Path $HKLM -Name "1407" -Value 0 -ErrorAction SilentlyContinue -Verbose
    Set-ItemProperty -Path $HKCU -Name "1407" -Value 0 -ErrorAction SilentlyContinue -Verbose
}

#Function4 Install Chocolatey
Function InstallChocolatey
{   
    $env:chocolateyUseWindowsCompression = 'true'
    $env:chocolateyIgnoreRebootDetected = 'true'
    $env:chocolateyVersion = '1.4.0'
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    choco feature enable -n allowGlobalConfirmation
}
#Function5 Disable PopUp for network configuration

Function DisableServerMgrNetworkPopup
{
    cd HKLM:\
    New-Item -Path HKLM:\System\CurrentControlSet\Control\Network -Name NewNetworkWindowOff -Force 

    Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose
}

Function CreateLabFilesDirectory
{
    New-Item -ItemType directory -Path C:\LabFiles -force
}

Function DisableWindowsFirewall
{
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

}

Function Show-File-Extension
{
    $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    Set-ItemProperty $key HideFileExt 0
    Stop-Process -processname explorer
}



#Function - InstallPowerBIDesktop
Function InstallPowerBiDesktopChoco
{
    choco install powerbi -y -force

}
Function InstallPowerBIDesktop
{
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile("https://download.microsoft.com/download/8/8/0/880BCA75-79DD-466A-927D-1ABF1F5454B0/PBIDesktopSetup_x64.exe","C:\Packages\PBIDesktop_x64.exe")
    Start-Process -FilePath "C:\Packages\PBIDesktop_x64.exe" -ArgumentList '-quiet','ACCEPT_EULA=1'
}


Function InstallScreenConnectforSPL
{
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/software/screenconnectspl.msi","C:\Packages\screenconnectspl.msi")
    Start-Process msiexec.exe -Wait '/I C:\Packages\screenconnectspl.msi /qn' -Verbose
}

Function InstallCloudLabsShadow($odlid, $InstallCloudLabsShadow)
{
    $odlid
    $InstallCloudLabsShadow
   # if($InstallCloudLabsShadow -eq 'yes')
   # {
   #     $WebClient = New-Object System.Net.WebClient
   #     $url1 = "https://spektrasystems.screenconnect.com/Bin/ConnectWiseControl.ClientSetup.msi?h=instance-ma1weu-relay.screenconnect.com&p=443&k=BgIAAACkAABSU0ExAAgAAAEAAQDhrCYwK%2BhPzyOyTYW71BahP4Q7hsWvkU20udO6d7cGuH8VAADzVNnsk39zavkgVu2uLHR1mfAL%2BUd6iAJOofhlcjO%2FB%2FVAEwvqtQ7403Nqm6rGvy6%2FxHEiqvzvn42JADRxdGVFaw9SYyTi4QckGjG0OnG69mW2RBQdWOZ3FKmhJD6zWRPZVTbl7gJkpIdMZx0BbWKiYVsvJYgoCWNXIqqH77rigu5dsmEnWeC9J0Or1KaU%2Bzsd6QJwAzEwomhiGp3FII4wbGBnCiHLD%2FrtNgR%2BJ1H3bKgYkesdxuFvO5DzUc3eEOVBSwR0crd06J%2BJP4DolgWWNZN6ZmQ1s5aOQgSq&e=Access&y=Guest&t=&c="
   #     $url3 = "&c=&c=&c=&c=&c=&c=&c="
   #     $finalurl = $url1 + $odlid + $url3
   #     $WebClient.DownloadFile("$finalurl","C:\Packages\cloudlabsshadow.msi")
   #    Start-Process msiexec.exe -Wait '/I C:\Packages\cloudlabsshadow.msi /qn' -Verbose
   # }
}

Function Enable-CloudLabsEmbeddedShadow($vmAdminUsername, $vmNonAdminUsername, $provisionNonAdminUser, $trainerUserName, $trainerUserPassword)
{
    Write-Host "Enabling CloudLabsEmbeddedShadow"

    if (-not $vmNonAdminUsername) {
        $vmNonAdminUsername = (Get-LocalUser | Where-Object { $_.Name -ne $vmAdminUsername -and $_.Enabled -eq $true -and $_.Name -notin @('Administrator','DefaultAccount','Guest','WDAGUtilityAccount','trainer') } | Select-Object -First 1).Name
    }

    if ($vmNonAdminUsername) {
        $vmUserToShadow = $vmNonAdminUsername
        Write-Host "ProvisionNonAdminUser=Yes. Shadow target user set to Non-Admin: $vmUserToShadow"
    }
    else {
        $vmUserToShadow = $vmAdminUsername
        Write-Host "ProvisionNonAdminUser=No. Shadow target user set to Admin: $vmUserToShadow"
    }

    # Create Trainer Account and Add to Administrators Group
    $trainerUserPass = $trainerUserPassword | ConvertTo-SecureString -AsPlainText -Force
    if (-not (Get-LocalUser -Name $trainerUserName -ErrorAction SilentlyContinue)) {
        New-LocalUser -Name $trainerUserName -Password $trainerUserPass -FullName "$trainerUserName" -Description "CloudLabs EmbeddedShadow User" -PasswordNeverExpires
    }
    Add-LocalGroupMember -Group "Administrators" -Member "$trainerUserName" -ErrorAction SilentlyContinue

    # Enable RDP shadowing in registry
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v Shadow /t REG_DWORD /d 2 -f
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name Shadow -Value 2

    # Ensure required folders exist
    if (-not (Test-Path "C:\Packages")) { New-Item -Path "C:\Packages" -ItemType Directory | Out-Null }
    $drivepath="C:\Users\Public\Documents"

    # Download required files
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/templates/cloudlabs-common/Shadow.ps1","$drivepath\Shadow.ps1")
    $WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/templates/cloudlabs-common/shadow.xml","$drivepath\shadow.xml")
    $WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/templates/cloudlabs-common/ShadowSession.zip","C:\Packages\ShadowSession.zip")
    $WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/templates/cloudlabs-common/executetaskscheduler.ps1","$drivepath\executetaskscheduler.ps1")
    $WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/templates/cloudlabs-common/shadowshortcut.ps1","$drivepath\shadowshortcut.ps1")

    # Replace placeholders in downloaded files
    (Get-Content "$drivepath\Shadow.ps1" -Raw) -Replace "vmAdminUsernameValue", $vmUserToShadow | Set-Content "$drivepath\Shadow.ps1"
    (Get-Content "$drivepath\shadow.xml" -Raw) -Replace "vmAdminUsernameValue", $trainerUserName -Replace "ComputerNameValue", $env:ComputerName | Set-Content "$drivepath\shadow.xml"
    (Get-Content "$drivepath\shadowshortcut.ps1" -Raw) -Replace "vmAdminUsernameValue", $trainerUserName | Set-Content "$drivepath\shadowshortcut.ps1"

    Start-Sleep -Seconds 2

    # Create scheduled tasks
    schtasks.exe /Create /XML $drivepath\shadow.xml /tn "ShadowTask"

    $Trigger = New-ScheduledTaskTrigger -AtLogOn
    $User    = "$($env:ComputerName)\$trainerUserName" 
    $Action  = New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe" -Argument "-executionPolicy Unrestricted -File $drivepath\shadowshortcut.ps1 -WindowStyle Hidden"
    Register-ScheduledTask -TaskName "ShadowShortcutTask" -Trigger $Trigger -User $User -Action $Action -RunLevel Highest -Force

    Write-Host "CloudLabs Embedded Shadow setup completed."
}

#Create Azure Credential File on Desktop
Function CreateCredFile($AzureUserName, $AzurePassword, $AzureTenantID, $AzureSubscriptionID, $DeploymentID)
{
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/templates/cloudlabs-common/AzureCreds.txt","C:\LabFiles\AzureCreds.txt")
    $WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/templates/cloudlabs-common/AzureCreds.ps1","C:\LabFiles\AzureCreds.ps1")
    
    New-Item -ItemType directory -Path C:\LabFiles -force

    (Get-Content -Path "C:\LabFiles\AzureCreds.txt") | ForEach-Object {$_ -Replace "AzureUserNameValue", "$AzureUserName"} | Set-Content -Path "C:\LabFiles\AzureCreds.txt"
    (Get-Content -Path "C:\LabFiles\AzureCreds.txt") | ForEach-Object {$_ -Replace "AzurePasswordValue", "$AzurePassword"} | Set-Content -Path "C:\LabFiles\AzureCreds.txt"
    (Get-Content -Path "C:\LabFiles\AzureCreds.txt") | ForEach-Object {$_ -Replace "AzureTenantIDValue", "$AzureTenantID"} | Set-Content -Path "C:\LabFiles\AzureCreds.txt"
    (Get-Content -Path "C:\LabFiles\AzureCreds.txt") | ForEach-Object {$_ -Replace "AzureSubscriptionIDValue", "$AzureSubscriptionID"} | Set-Content -Path "C:\LabFiles\AzureCreds.txt"
    (Get-Content -Path "C:\LabFiles\AzureCreds.txt") | ForEach-Object {$_ -Replace "DeploymentIDValue", "$DeploymentID"} | Set-Content -Path "C:\LabFiles\AzureCreds.txt"
             
    (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "AzureUserNameValue", "$AzureUserName"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
    (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "AzurePasswordValue", "$AzurePassword"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
    (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "AzureTenantIDValue", "$AzureTenantID"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
    (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "AzureSubscriptionIDValue", "$AzureSubscriptionID"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
    (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "DeploymentIDValue", "$DeploymentID"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"

    Copy-Item "C:\LabFiles\AzureCreds.txt" -Destination "C:\Users\Public\Desktop"
}

#Add Service Principle details to Azure Credential Files
Function SPtoAzureCredFiles($SPDisplayName, $SPID, $SPObjectID, $SPSecretKey, $AzureTenantDomainName)
{
    Add-Content -Path "C:\LabFiles\AzureCreds.txt" -Value "AzureServicePrincipalDisplayName= $SPDisplayName" -PassThru
    Add-Content -Path "C:\LabFiles\AzureCreds.txt" -Value "AzureServicePrincipalAppID= $SPID" -PassThru
    Add-Content -Path "C:\LabFiles\AzureCreds.txt" -Value "AzureServicePrincipalObjectID= $SPObjectID" -PassThru
    Add-Content -Path "C:\LabFiles\AzureCreds.txt" -Value "AzureServicePrincipalSecretKey= $SPSecretKey" -PassThru
    Add-Content -Path "C:\LabFiles\AzureCreds.txt" -Value "AzureTenantDomainName= $AzureTenantDomainName" -PassThru

    Add-Content -Path "C:\LabFiles\AzureCreds.ps1" -Value '$AzureServicePrincipalDisplayName="SPDisplayNameValue"' -PassThru
    Add-Content -Path "C:\LabFiles\AzureCreds.ps1" -Value '$AzureServicePrincipalAppID="SPIDValue"' -PassThru
    Add-Content -Path "C:\LabFiles\AzureCreds.ps1" -Value '$AzureServicePrincipalObjectID="SPObjectIDValue"' -PassThru
    Add-Content -Path "C:\LabFiles\AzureCreds.ps1" -Value '$AzureServicePrincipalSecretKey="SPSecretKeyValue"' -PassThru
    Add-Content -Path "C:\LabFiles\AzureCreds.ps1" -Value '$AzureTenantDomainName="AzureTenantDomainNameValue"' -PassThru

    (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "SPDisplayNameValue", "$SPDisplayName"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
    (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "SPIDValue", "$SPID"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
    (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "SPObjectIDValue", "$SPObjectID"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
    (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "SPSecretKeyValue", "$SPSecretKey"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
    (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "AzureTenantDomainNameValue", "$AzureTenantDomainName"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"

    Copy-Item "C:\LabFiles\AzureCreds.txt" -Destination "C:\Users\Public\Desktop" -force
}

#Install Cloudlabs Modern VM (Windows Server 2012,2016,2019, Windows 10) Validator
Function InstallModernVmValidator
{   #dotnet core is pre-req for vmagent or validator
    choco install dotnetcore -y -force
    #Create C:\CloudLabs\Validator directory
    New-Item -ItemType directory -Path C:\CloudLabs\Validator -Force
    Invoke-WebRequest 'https://experienceazure.blob.core.windows.net/software/vm-validator/VMAgent.zip' -OutFile 'C:\CloudLabs\Validator\VMAgent.zip'
    Expand-Archive -LiteralPath 'C:\CloudLabs\Validator\VMAgent.zip' -DestinationPath 'C:\CloudLabs\Validator' -Force
    Set-ExecutionPolicy -ExecutionPolicy bypass -Force
    cmd.exe --% /c @echo off
    cmd.exe --% /c sc create "Spektra CloudLabs VM Agent" BinPath=C:\CloudLabs\Validator\VMAgent\Spektra.CloudLabs.VMAgent.exe start= auto
    cmd.exe --% /c sc start "Spektra CloudLabs VM Agent"
}

#Install Cloudlabs Legacy VM (Windows Server 2008R2) Validator
Function InstallLegacyVmValidator
{
    #Create C:\CloudLabs
    New-Item -ItemType directory -Path C:\CloudLabs\Validator -Force
    Invoke-WebRequest 'https://experienceazure.blob.core.windows.net/software/vm-validator/LegacyVMAgent.zip' -OutFile 'C:\CloudLabs\Validator\LegacyVMAgent.zip'
    Expand-Archive -LiteralPath 'C:\CloudLabs\Validator\LegacyVMAgent.zip' -DestinationPath 'C:\CloudLabs\Validator' -Force
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory('C:\CloudLabs\Validator\LegacyVMAgent.zip','C:\CloudLabs\Validator')
    Set-ExecutionPolicy -ExecutionPolicy bypass -Force
    cmd.exe --% /c @echo off
    cmd.exe --% /c sc create "Spektra CloudLabs Legacy VM Agent" binpath= C:\CloudLabs\Validator\LegacyVMAgent\Spektra.CloudLabs.LegacyVMAgent.exe displayname= "Spektra CloudLabs Legacy VM Agent" start= auto
    cmd.exe --% /c sc start "Spektra CloudLabs Legacy VM Agent"

}

#Install SQl Server Management studio
Function InstallSQLSMS
{
    choco install sql-server-management-studio -y -force
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("C:\Users\Public\Desktop\Microsoft SQL Server Management Studio 18.lnk")
    $Shortcut.TargetPath = "C:\Program Files (x86)\Microsoft SQL Server Management Studio 18\Common7\IDE\Ssms.exe"
    $Shortcut.Save()

}

#Install Azure Powershell Az Module
Function InstallAzPowerShellModule
{
    <#Install-PackageProvider NuGet -Force
    Set-PSRepository PSGallery -InstallationPolicy Trusted
    Install-Module Az -Repository PSGallery -Force -AllowClobber#>

    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile("https://github.com/Azure/azure-powershell/releases/download/v5.0.0-October2020/Az-Cmdlets-5.0.0.33612-x64.msi","C:\Packages\Az-Cmdlets-5.0.0.33612-x64.msi")
    sleep 5
    Start-Process msiexec.exe -Wait '/I C:\Packages\Az-Cmdlets-5.0.0.33612-x64.msi /qn' -Verbose 

    Update-AzConfig -LoginExperienceV2 Off
    Update-AzConfig -EnableLoginByWam $false
}

Function InstallAzCLI
{
    choco install azure-cli -y -force
}

Function InstallGoogleChrome
{

    choco install googlechrome -y -force

}

Function InstallVSCode
{

    choco install vscode -y -force

}

Function InstallGitTools
{

    choco install git.install -y -force

}

Function InstallPutty
{

    choco install putty.install -y -force

}

Function InstallAdobeReader
{

    choco install adobereader -y -force

}

Function InstallFirefox
{

    choco install firefox -y -force

}

Function Install7Zip
{

    choco install 7zip.install -y -force

}


Function InstallNodeJS
{

    choco install nodejs -y -force

}

Function InstallDotNet4.5
{

    choco install dotnet4.5 -y -force

}

Function InstallDotNetFW4.8
{

    choco install dotnetfx -y -force

}

Function InstallPython
{

    choco install python -y -force

}

Function InstallWinSCP
{

    choco install winscp.install -y -force

}

Function Installvisualstudio2019professional
{

    choco install visualstudio2019professional -y -force

}

Function Installvisualstudio2019community
{

    choco install visualstudio2019community -y -force

}
Function InstalldockerforWindows
{

    choco install docker-for-windows -y -force

}

Function InstallEdgeChromium
{
    #Download and Install edge
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile("http://go.microsoft.com/fwlink/?LinkID=2093437","C:\Packages\MicrosoftEdgeBetaEnterpriseX64.msi")
    sleep 5
    
    Start-Process msiexec.exe -Wait '/I C:\Packages\MicrosoftEdgeBetaEnterpriseX64.msi /qn' -Verbose 
    sleep 5
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("C:\Users\Public\Desktop\Azure Portal.lnk")
    $Shortcut.TargetPath = """C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"""
    $argA = """https://portal.azure.com"""
    $Shortcut.Arguments = $argA 
    $Shortcut.Save()

    #Disable Welcome page of Microsoft Edge
    #Disable Edge 'First Run' Setup

    $edgePolicyRegistryPath = 'HKLM:SOFTWARE\Policies\Microsoft\Edge'
    $desktopSettingsRegistryPath = 'HKCU:SOFTWARE\Microsoft\Windows\Shell\Bags\1\Desktop'
    $firstRunRegistryName = 'HideFirstRunExperience'
    $firstRunRegistryValue = '0x00000001'
    $savePasswordRegistryName = 'PasswordManagerEnabled'
    $savePasswordRegistryValue = '0x00000000'
    $autoArrangeRegistryName = 'FFlags'
    $autoArrangeRegistryValue = '1075839525'

    if (-NOT (Test-Path -Path $edgePolicyRegistryPath)) {
	New-Item -Path $edgePolicyRegistryPath -Force | Out-Null
    }

    if (-NOT (Test-Path -Path $desktopSettingsRegistryPath)) {
	New-Item -Path $desktopSettingsRegistryPath -Force | Out-Null
    }

    New-ItemProperty -Path $edgePolicyRegistryPath -Name $firstRunRegistryName -Value $firstRunRegistryValue -PropertyType DWORD -Force
    New-ItemProperty -Path $edgePolicyRegistryPath -Name $savePasswordRegistryName -Value $savePasswordRegistryValue -PropertyType DWORD -Force
    Set-ItemProperty -Path $desktopSettingsRegistryPath -Name $autoArrangeRegistryName -Value $autoArrangeRegistryValue -Force

    #Set-Location hklm:
    #Test-Path .\Software\Policies\Microsoft
    #New-Item -Path .\Software\Policies\Microsoft -Name MicrosoftEdge
    #New-Item -Path .\Software\Policies\Microsoft\MicrosoftEdge -Name Main
    #New-ItemProperty -Path .\Software\Policies\Microsoft\MicrosoftEdge\Main -Name PreventFirstRunPage -Value "1" -Type DWORD -Force -ErrorAction SilentlyContinue | Out-Null

    #Setting up the edge browser as default

    Invoke-WebRequest 'https://experienceazure.blob.core.windows.net/templates/cloudlabs-common/SetUserFTA.zip' -OutFile 'C:\SetUserFTA.zip'
    Expand-Archive -Path 'C:\SetUserFTA.zip' -DestinationPath 'C:\' -Force
    cmd.exe /c C:\SetUserFTA\SetUserFTA.exe
    cmd.exe /c cd C:\SetUserFTA
    cmd.exe /c C:\SetUserFTA\SetUserFTA.exe http MSEdgeHTM
    cmd.exe /c C:\SetUserFTA\SetUserFTA.exe https MSEdgeHTM
    cmd.exe /c C:\SetUserFTA\SetUserFTA.exe .htm MSEdgeHTM
    Sleep 5
    Remove-Item -Path 'C:\SetUserFTA.zip'
    Remove-Item -Path 'C:\SetUserFTA' -Force -Recurse
  

}

Function Expand-ZIPFile($file, $destination)
{
$shell = new-object -com shell.application
$zip = $shell.NameSpace($file)
foreach($item in $zip.items())
    {
        $shell.Namespace($destination).copyhere($item)
}
}

Function Download($fileurl, $destination)
{
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("$fileurl","$destination")
}

Function ResizeOSDiskMax()
{
# Iterate through all the disks on the Windows machine
foreach($disk in Get-Disk)
{
# Check if the disk in context is a Boot and System disk
if((Get-Disk -Number $disk.number).IsBoot -And (Get-Disk -Number $disk.number).IsSystem)
{
    # Get the drive letter assigned to the disk partition where OS is installed
    $driveLetter = (Get-Partition -DiskNumber $disk.Number | where {$_.DriveLetter}).DriveLetter
    Write-verbose "Current OS Drive: $driveLetter :\"

    # Get current size of the OS parition on the Disk
    $currentOSDiskSize = (Get-Partition -DriveLetter $driveLetter).Size        
    Write-verbose "Current OS Partition Size: $currentOSDiskSize"

    # Get Partition Number of the OS partition on the Disk
    $partitionNum = (Get-Partition -DriveLetter $driveLetter).PartitionNumber
    Write-verbose "Current OS Partition Number: $partitionNum"

    # Get the available unallocated disk space size
    $unallocatedDiskSize = (Get-Disk -Number $disk.number).LargestFreeExtent
    Write-verbose "Total Unallocated Space Available: $unallocatedDiskSize"

    # Get the max allowed size for the OS Partition on the disk
    $allowedSize = (Get-PartitionSupportedSize -DiskNumber $disk.Number -PartitionNumber $partitionNum).SizeMax
    Write-verbose "Total Partition Size allowed: $allowedSize"

    if ($unallocatedDiskSize -gt 0 -And $unallocatedDiskSize -le $allowedSize)
    {
        $totalDiskSize = $allowedSize
        
        # Resize the OS Partition to Include the entire Unallocated disk space
        $resizeOp = Resize-Partition -DriveLetter C -Size $totalDiskSize
        Write-verbose "OS Drive Resize Completed $resizeOp"
    }
    else {
        Write-Verbose "There is no Unallocated space to extend OS Drive Partition size"
    }
}   
}
}

Function Install-dotnet3.1
{
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/software/dotnet-install.ps1","C:\Packages\dotnet-install.ps1")
cd C:\Packages
./dotnet-install.ps1 -Channel 3.1 -Runtime dotnet -Version 3.1.4 -InstallDir 'C:\Program Files\dotnet'

}

Function InstallCloudLabsManualAgentFiles
{
#Download files to write deployment status
Set-Content -Path 'C:\WindowsAzure\Logs\status-sample.txt' -Value '{"ServiceCode" : "ManualStepService", "Status" : "ReplaceStatus", "Message" : "ReplaceMessage"}'
Set-Content -Path 'C:\WindowsAzure\Logs\validationstatus.txt' -Value '{"ServiceCode" : "ManualStepService", "Status" : "ReplaceStatus", "Message" : "ReplaceMessage"}'

#Download cloudlabsagent zip
Invoke-WebRequest 'https://experienceazure.blob.core.windows.net/software/cloudlabsagent/CloudLabsAgent.zip' -OutFile 'C:\Packages\CloudLabsAgent.zip'
Expand-Archive -LiteralPath 'C:\Packages\CloudLabsAgent.zip' -DestinationPath 'C:\Packages\' -Force
Set-ExecutionPolicy -ExecutionPolicy bypass -Force
cmd.exe --% /c @echo off
cmd.exe --% /c sc create "Spektra.CloudLabs.Agent" BinPath=C:\Packages\CloudLabsAgent\Spektra.CloudLabs.Agent.exe start= auto
sleep 5
cmd.exe --% /c sc start "Spektra.CloudLabs.Agent"
sleep 5 
}

Function SetDeploymentStatus{
   Param(
     [parameter(Mandatory=$true)]
      [String] $ManualStepStatus,
       
       [parameter(Mandatory=$true)]
      [String] $ManualStepMessage    
       )  
  (Get-Content -Path "C:\WindowsAzure\Logs\status-sample.txt") | ForEach-Object {$_ -Replace "ReplaceStatus", "$ManualStepStatus"} | Set-Content -Path "C:\WindowsAzure\Logs\validationstatus.txt"
   (Get-Content -Path "C:\WindowsAzure\Logs\validationstatus.txt") | ForEach-Object {$_ -Replace "ReplaceMessage", "$ManualStepMessage"} | Set-Content -Path "C:\WindowsAzure\Logs\validationstatus.txt"
     }
         
Function CloudLabsManualAgent{
<#
      SYNOPSIS
      This is a function for installing/starting the cloudlabsagent, and to send the deployment status    
#>

param(  
  #Task : to install or start the agent/ set the deployment status
      [parameter(Mandatory=$true)]
      [String]$Task      
   )
    #To install cloudlabsagent service files
    if($Task -eq 'Install')
    {
       Install-dotnet3.1
       InstallCloudLabsManualAgentFiles
    }
    #start the cloudlabs agent service
    elseif($Task -eq 'Start')
    {
      cmd.exe --% /c sc start "Spektra.CloudLabs.Agent"
      sleep 5 
    } 
   elseif($Task -eq 'setStatus')
    {
      SetDeploymentStatus -ManualStepStatus $Validstatus -ManualStepMessage $Validmessage
    }       
   }

Function setupHypervNet($addressprefix, $netip)
{   
    # Create the NAT network
    Write-Output "Create internal NAT"
    $natName = "InternalNat"
    #New-NetNat -Name $natName -InternalIPInterfaceAddressPrefix 192.168.0.0/16
    New-NetNat -Name $natName -InternalIPInterfaceAddressPrefix $addressprefix

    # Create an internal switch with NAT
    Write-Output "Create internal switch"
    $switchName = 'InternalNATSwitch'
    New-VMSwitch -Name $switchName -SwitchType Internal
    $adapter = Get-NetAdapter | Where-Object { $_.Name -like "*"+$switchName+"*" }

    # Create an internal network (gateway first)
    Write-Output "Create gateway"
    #New-NetIPAddress -IPAddress 192.168.0.1 -PrefixLength 16 -InterfaceIndex $adapter.ifIndex
    New-NetIPAddress -IPAddress $netip -PrefixLength 16 -InterfaceIndex $adapter.ifIndex

    # Enable Enhanced Session Mode on Host
    Write-Output "Enable Enhanced Session Mode"
    Set-VMHost -EnableEnhancedSessionMode $true
}

Function ReArmWS
{
    #Update Windows server evaluation licence to 180 days
    slmgr.vbs /rearm
    net accounts /maxpwage:unlimited
    Restart-Computer -Force 

   <# for hyper v VMs use below code
   $ap = "demo@pass123"
   $cred = New-Object -ArgumentList "Administrator",(ConvertTo-SecureString -AsPlainText -Force -String $ap) -TypeName System.Management.Automation.PSCredential

    $blockB = {
    #Update Windows server evaluation licence to 180 days
        Write-Output "Re-arm (extend eval license) for VM $ComputerName at $ip"
        slmgr.vbs /rearm
        net accounts /maxpwage:unlimited
        Restart-Computer -Force
    }
    #Run Code BlockB in SQL VM
    $ip =  "192.168.0.4"
    foreach($serverIP in $ip){
        set-item wsman:\localhost\Client\TrustedHosts -value $serverIP -Force
        Invoke-Command -ComputerName $serverIP -Credential $cred -ScriptBlock $blockB
    }
    #>
}

Function setupUserData($vmAdminUsername)
{   
    #create base directory
    New-Item -ItemType directory -Path C:\CloudLabs\

    #Download userdata script
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/templates/cloudlabs-common/UserDataSample/scripts/run-userdata.ps1","C:\CloudLabs\run-userdata.ps1")

    #download task scheduler xml
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/templates/cloudlabs-common/UserDataSample/scripts/runuserdata.xml","C:\CloudLabs\runuserdata.xml")

    #update task scheduler xml
    (Get-Content -Path "C:\CloudLabs\runuserdata.xml") | ForEach-Object {$_ -Replace "ComputerNameValue", "$($env:ComputerName)"} | Set-Content -Path "C:\CloudLabs\runuserdata.xml"
    (Get-Content -Path "C:\CloudLabs\runuserdata.xml") | ForEach-Object {$_ -Replace "vmAdminUsernameValue", "$vmAdminUsername"} | Set-Content -Path "C:\CloudLabs\runuserdata.xml"

    #Create scheduled task to run-userdata script on user logon, system startup as triggers
    schtasks.exe /Create /XML C:\CloudLabs\runuserdata.xml /tn runuserdata

    #delete task scheduler xml
    Remove-Item -Path 'C:\CloudLabs\runuserdata.xml'
}

Function installmggraph 
{
  Install-PackageProvider `
    -Name NuGet `
    -MinimumVersion 2.8.5.201 `
    -Force `
    -Scope AllUsers

    Start-Sleep -Seconds 10

    if (-not (Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue)) {
    Register-PSRepository -Name PSGallery `
                        -SourceLocation "https://www.powershellgallery.com/api/v2" `
                        -InstallationPolicy Trusted
    } else {
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    }

    Start-Sleep -Seconds 10

    Install-Module -Name Microsoft.Graph -Scope AllUsers -Repository PSGallery -AllowClobber -Force
    Install-Module -Name Microsoft.Graph.Authentication -Force -Scope AllUsers -SkipPublisherCheck
    Install-Module -Name Microsoft.Graph.Identity.DirectoryManagement -Force -Scope AllUsers -SkipPublisherCheck
    Install-Module -Name Microsoft.Graph.Groups -Force -Scope AllUsers -SkipPublisherCheck
    Install-Module -Name Microsoft.Graph.Users -Force -Scope AllUsers -SkipPublisherCheck
    Install-Module -Name Microsoft.Graph.Identity.SignIns -Force -Scope AllUsers -SkipPublisherCheck
    Install-Module -Name Microsoft.Graph.Applications    -Scope AllUsers -Force -SkipPublisherCheck
    Install-Module -Name Microsoft.Graph -Scope AllUsers -Repository PSGallery -AllowClobber -Force

}

Function WindowsServerCommon
{
[Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls" 
Disable-InternetExplorerESC
Enable-IEFileDownload
Enable-CopyPageContent-In-InternetExplorer
InstallChocolatey
DisableServerMgrNetworkPopup
CreateLabFilesDirectory
DisableWindowsFirewall
InstallEdgeChromium
}

function Enable-GitHub {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserEmail,

        [Parameter(Mandatory = $true)]
        [string]$TenantId,

        [Parameter(Mandatory = $true)]
        [string]$ClientId,

        [Parameter(Mandatory = $true)]
        [string]$ClientSecret,

        [switch]$WithCopilot,

        [switch]$WithGHAS
    )

    Import-Module Microsoft.Graph.Authentication
    Import-Module Microsoft.Graph.Identity.DirectoryManagement
    Import-Module Microsoft.Graph.Groups
    Import-Module Microsoft.Graph.Users
    Import-Module Microsoft.Graph.Identity.SignIns
    Import-Module Microsoft.Graph.Applications

    $GroupIdWithoutCopilot = "83311b9f-c349-4a10-bb7f-e9342e76ea10"
    $GroupIdWithCopilot = "bb0215fb-69d3-4d16-be56-cd2da619de31"
    $GroupIdGHAS = "5bd562c2-02f4-463d-b9ef-86fd666f5fe7"

    if ($WithGHAS) {
        $GroupId = $GroupIdGHAS
        Write-Host "Adding user to GHAS group $GroupId"
    } elseif ($WithCopilot) {
        $GroupId = $GroupIdWithCopilot
        Write-Host "Adding user to Copilot group $GroupId"
    } else {
        $GroupId = $GroupIdWithoutCopilot
        Write-Host "Adding user to default group $GroupId"
    }
    Write-Host "Adding user to group $GroupId"

    $securePassword = ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force
    $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ClientId, $securePassword
    Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $credential -NoWelcome
    Write-Host "Connected to Microsoft Graph API"

    $userDomain = $UserEmail.Split('@')[1]
    $tenantDomain = ((Get-MgOrganization).VerifiedDomains | Where-Object { $_.IsDefault -eq $true }).Name

    if ($userDomain -ne $tenantDomain) {
        Write-Host "User is external. Inviting guest user..."
        $params = @{
            InvitedUserEmailAddress = $UserEmail
            InviteRedirectUrl       = "https://myapplications.microsoft.com/?tenantid=$TenantId"
            SendInvitationMessage   = $true
        }
        $invitation = New-MgInvitation @params -Verbose
        $userObjectId = $invitation.InvitedUser.Id
    } else {
        Write-Host "User is internal. Getting user object ID..."
        $existingUser = Get-MgUser -Filter "userPrincipalName eq '$UserEmail'"
        if (-not $existingUser) {
            Write-Error "Internal user not found."
            return
        }
        $userObjectId = $existingUser.Id
    }

    try {
        New-MgGroupMember -GroupId $GroupId -DirectoryObjectId $userObjectId -ErrorAction Stop
        Write-Host "User added to group $GroupId"
    } catch {
        Write-Warning "User may already be in the group or another error occurred: $_"
    }

    # GitHub EMU Synchronization
    $syncParams = @{
        parameters = @(
            @{
                ruleId = "03f7d90d-bf71-41b1-bda6-aaf0ddbee5d8"
                subjects = @(
                    @{
                        objectId = $GroupId
                        objectTypeName = "Group"
                        links = @{
                            members = @(
                                @{
                                    objectId = $userObjectId
                                    objectTypeName = "User"
                                }
                            )
                        }
                    }
                )
            }
        )
    }

    Start-Sleep 30

    $syncSucceeded = $false
    $retryCount = 0
    $maxRetries = 5

    while (-not $syncSucceeded -and $retryCount -lt $maxRetries) {
        try {
            Write-Host "Attempting GitHub EMU sync (try $($retryCount + 1))..."
            New-MgServicePrincipalSynchronizationJobOnDemand `
                -ServicePrincipalId da6c7f14-b7a5-4b1b-b357-3594173bea4a `
                -SynchronizationJobId gitHubEnterpriseCloud.f871d17eefcd44c7ba5a0162efa2fded.d2318294-74b6-4d39-b351-8f0ee74687c0 `
                -BodyParameter $syncParams
            Write-Host "GitHub EMU sync triggered successfully."
            $syncSucceeded = $true
        } catch {
            Write-Warning "GitHub EMU sync failed: $_"
            $retryCount++
            if ($retryCount -lt $maxRetries) {
                $waitTime = [math]::Pow(2, $retryCount)
                Write-Host "Retrying in $waitTime seconds..."
                Start-Sleep -Seconds $waitTime
            } else {
                Write-Error "Max retries reached. GitHub EMU sync could not be triggered."
            }
        }
    }


}
