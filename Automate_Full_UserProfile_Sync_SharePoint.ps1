Add-PSSnapIn Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
 
## Sets variable for User Profile Service Application
$ups = Get-SPServiceApplication |?{$_.displayname -eq "User Profile Service Application"}
 
## Sets variable for service instance
## If you have multiple sync services are running, specify the ID. Enter the following command to check
## ## $upsID = get-spserviceinstance | ? {$_.Typename -eq "User Profile Synchronization Service"} | Select Status, ID, Server
$syncSvc = Get-SPServiceInstance |?{$_.id -eq "6c905cfd-9808-4e67-93a6-dae3f877bf9a"}
 
## Sets variables for farm account and password. Password is encrypted to be stored in C:pw.txt
$svcAcc = "Microsoftfarm"
$encryptedPwd = Get-Content C:pw.txt | ConvertTo-SecureString
$svcPwd = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($encryptedPwd))
 
## Sets variable for synchronization server
## If you have multiple server, specify the one you want synchronization service to be started
$syncServer = get-content env:computername
 
if($syncSvc.Status -eq "Disabled")
{
  Write-Host "Provisioning User Profile Synchronization Service"
  $ups.SetSynchronizationMachine($syncServer, $syncSvc.ID, $svcAcc, $svcPwd)
}
else
{
  Write-host "User Profile Synchronization Service is"$syncSvc.Status
}
 
while ($syncSvc.Status -eq "Provisioning")
{
    $syncSvc = Get-SPServiceInstance |?{$_.id -eq "6c905cfd-9808-4e67-93a6-dae3f877bf9a"}
    Write-Host $syncSvc.Status
    sleep 3
}
Write-Host $syncSvc.Status
 
## Start Full Synchronization
$profileApp = @(Get-SPServiceApplication | ? { $_.TypeName -eq "User Profile Service Application" })[0] 
 
$serviceContext = ([Microsoft.SharePoint.SPServiceContext]::GetContext(
         $profileApp.ServiceApplicationProxyGroup,
         [Microsoft.SharePoint.SPSiteSubscriptionIdentifier]::Default)) 
 
$configManager = New-Object Microsoft.Office.Server.UserProfiles.UserProfileConfigManager($serviceContext)
 if($configManager.IsSynchronizationRunning() -eq $false)
 {
 $configManager.StartSynchronization($true)
    Write-Host "Started Synchronizing"
 }
 else
 {
    Write-Host "Already Synchronizing"
 }

 while ($syncSvc.Status -eq "Provisioning")
{
    $syncSvc = Get-SPServiceInstance |?{$_.id -eq "6c905cfd-9808-4e67-93a6-dae3f877bf9a"}
    Write-Host $syncSvc.Status
    sleep 3
}