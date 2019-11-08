################################################################################################################################
#
# RepoToModuleAndSign.ps1
#
# This script gets the content of the PSRepository repository and copy all modules to a new folder, then those
# modules are signed with a self signed certificate and the new folder is added to the user env variable PSModulePath
#
# Prequisite: 
#
# 1) Clone PSRepository repository in your computer, for example C:\DEV\PSInternalGallery
#
# 2) You need to have at least one valid code signing certificate (it can be self signed)
#    To create a self signed certificate:
#    2a. Create a local certificate authority
#         makecert -n "CN=PowerShell Local Certificate Root" -a sha1 -eku 1.3.6.1.5.5.7.3.3 -r -sv root.pvk root.cer -ss Root -sr localMachine
#    2b. create certificate 
#         makecert -pe -n "CN=PowerShell User" -ss MY -a sha1 -eku 1.3.6.1.5.5.7.3.3 -iv root.pvk -ic root.cer
#    2c. Correct this line in script to use correct index:
#         Set-AuthenticodeSignature -FilePath  $file.PSPath -Certificate @(Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert)[0] ==> ??
#
#    Set-AuthenticodeSignature -FilePath  .\RepoToModuleAndSign.ps1 -Certificate @(Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert)[0]
#
#################################################################################################################################

$ModulesOrigin = 'C:\DEV\PSRepository\Modules'
$ModulesDestination = 'C:\DEV\PSMOD'
$ModulesPath = $ModulesDestination + "\Modules"

# copy data from repo
Copy-Item -Path $ModulesOrigin -Destination $ModulesDestination -Recurse -Force

#sign all files with self signed 

$ModulesFolders = Get-ChildItem $ModulesPath

foreach($moduleFolder in $ModulesFolders)
{
    $files = Get-ChildItem $moduleFolder.PSPath -Recurse
    $total = $files.count
    $i=0
    foreach($file in $files)
    {
        $i++; Write-Progress -Activity ("Signing module " + $moduleFolder.Name) -Status ($file.Name) -PercentComplete ($i*100/$total)
        if($file.Extension -eq ".ps1" -or $file.Extension -eq ".psm1")
        {
            Set-AuthenticodeSignature -FilePath  $file.PSPath -Certificate @(Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert)[0]
        }
    }
}

$CurrentValue = [Environment]::GetEnvironmentVariable("PSModulePath", "User")
$CurrentModulePaths = $CurrentValue.Split(';')
if(!$CurrentModulePaths.Contains($ModulesPath))
{
    [Environment]::SetEnvironmentVariable("PSModulePath", $ModulesPath, "User")
}
