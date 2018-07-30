# Created by SHISHIR KUSHAWAHA 18 jUNE 2017 @:srktcet@gmail.com

function updateHTML
{

param ($strPath)
IF(Test-Path $strPath)
  { 
   Remove-Item $strPath
   
  }

 }
 
 #.INITIALIZATION


 #--CSS formatting
$test=@'
<style type="text/css">
 h1, h5,h2, th { text-align: center; font-family: Segoe UI;font-size: 13px;}
table { margin: auto; font-family: Segoe UI; box-shadow: 10px 10px 5px #888; border: thin ridge grey; }
th { background: #0046c3; color: #fff; max-width: 400px; padding: 5px 10px; font-size: 12px;}
td { font-size: 11px; padding: 5px 20px; color: #000; }
tr { background: #b8d1f3; }
tr:nth-child(even) { background: #dae5f4; }
tr:nth-child(odd) { background: #b8d1f3; }
</style>
'@

 #--Variable declaration
 $vComputerName="localhost"
 #$vComputerName = read-host "Enter IP address or hostname of computer"  
 $location=get-location
 
 
 
 #.MAIN
 

 #--Basic Information 
 $ReportTitle="Basic Information"
 $strPath = "$location\BasicInformation.html"
 updateHTML $strPath

ConvertTo-Html -Head $test -Title $ReportTitle -Body "<h1> Computer Name : $vComputerName </h1>" >  "$strPath" 
gwmi win32_computersystem -ComputerName $vComputerName|select PSComputerName,Name, Manufacturer , Domain, Model ,Systemtype,PrimaryOwnerName,PCSystemType,PartOfDomain,CurrentTimeZone,BootupState | ConvertTo-html  -Head $test -Body "<h5>Updated: on $(Get-Date)</h5><h2>ComputerSystem</h2>" >> "$strPath"

Get-WmiObject win32_bios -ComputerName $vComputerName| select Status,Version,PrimaryBIOS,Manufacturer,ReleaseDate,SerialNumber | ConvertTo-Html -Head $test -Body "<h2>BIOS Information</h2>" >> "$strPath"
                                        
										  
Get-WmiObject win32_DiskDrive -ComputerName $vComputerName | Select Index,Model,Caption,SerialNumber,Description,MediaType,FirmwareRevision,Partitions,@{Expression={$_.Size /1Gb -as [int]};Label="Total Size(GB)"},PNPDeviceID |ConvertTo-Html -Head $test -Body "<h2>Disk Drive Information</h1>" >> "$strPath"

get-WmiObject win32_networkadapter -ComputerName $vComputerName | Select Name,Manufacturer,Description ,AdapterType,Speed,MACAddress,NetConnectionID,PNPDeviceID `
                                          | ConvertTo-Html -Head $test -Body "<h2>Netork Adaptor Information</h2>" >> "$strPath"
Get-WmiObject win32_startupCommand -ComputerName $vComputerName | select Name,Location,Command,User,caption `
                                          | ConvertTo-html  -Head $test -Body "<h2>Startup  Software Information</h2>" >> "$strPath"

Get-WmiObject win32_logicalDisk -ComputerName $vComputerName | select DeviceID,VolumeName,@{Expression={$_.Size /1Gb -as [int]};Label="Total Size(GB)"},@{Expression={$_.Freespace / 1Gb -as [int]};Label="Free Size (GB)"} `
                                         |  ConvertTo-html  -Head $test -Body "<h2>Disk Inforamtion</h2>" >> "$strPath"
get-WmiObject win32_operatingsystem -ComputerName $vComputerName | select Caption,Organization,InstallDate,OSArchitecture,Version,SerialNumber,BootDevice,WindowsDirectory,CountryCode `
                                          | ConvertTo-html  -Head $test -Body "<h2>OS Inforamtion</h2>" >> "$strPath"

Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation | select Model,Manufacturer,Logo,SupportPhone,SupportURL,SupportHours |ConvertTo-html  -Head $test -Body "<h2>OEM Information</h2>" >> "$strPath"
get-culture | select KeyboardLayoutId,DisplayName,@{Expression={$_.ThreeLetterWindowsLanguageName};Label="Windows Language"} | ConvertTo-html  -Head $test -Body "<h2>Culture Inforamtion</h2>" >> "$strPath"

Invoke-Item $strPath




#--Service Information 
$strPath = "$location\Service.html"
$ReportTitle = "Service Report"
updateHTML $strPath
    

$sheet = Get-service -ComputerName $vComputerName |select Name, Displayname,Status | ConvertTo-Html -Head $test -Title $ReportTitle -Body "<h1>$ReportTitle</h1>`n<h1> Computer Name : $vComputerName </h1>`n<h5>Updated: on $(Get-Date)</h5>"

Add-Content $strPath $sheet

Invoke-Item $strPath




#--Application Information  
$strPath = "$location\Application.html"
$ReportTitle = "Application Report"
updateHTML $strPath

$objapp1=Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*  

$objapp2=Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* 

$app1=$objapp1 | select Displayname, Displayversion , Publisher,Installdate 
 
$app2=$objapp2 | Select-Object Displayname, Displayversion , Publisher,Installdate |where { -NOT (([string]$_.displayname).contains("Security Update for Microsoft") -or ([string]$_.displayname).contains("Update for Microsoft"))} 
 
$app=$app1+$app2
 
$sheet=$app | ConvertTo-Html -Head $test -Title $ReportTitle -Body "<h1>$ReportTitle</h1><h1> Computer Name : $vComputerName </h1>`n`n<h5>Updated: on $(Get-Date)</h5>"

Add-Content $strPath $sheet

Invoke-Item $strPath



  
#--Windows Feature Information 
$strPath="$location\WindowsFeatures.html"
$ReportTitle = "WindowsFeature Report"
updateHTML $strPath

$sheet = Get-WmiObject Win32_OptionalFeature -ComputerName $vComputerName | select Caption , Installstate | ConvertTo-Html -Head $test -Title $ReportTitle -Body "<h1>$ReportTitle</h1>`n<h1> Computer Name : $vComputerName </h1>`n<h5>Updated: on $(Get-Date)</h5> <h5>Note for Install state <br> 1 : Installed <br>2: Not installed <br></h5>"

Add-Content $strPath $sheet
Invoke-Item $strPath
 



#--Windows Update Information  
$strPath="$location\Windosupdate.html"
$ReportTitle = "WindowsUpdate Report"
updateHTML $strPath

$sheet = Get-hotfix -ComputerName $vComputerName | select Description , HotFixId , InstalledBy,InstalledOn,Caption | ConvertTo-Html -Head $test -Title $ReportTitle -Body "<h1>$ReportTitle</h1>`n<h1> Computer Name : $vComputerName </h1>`n<h5>Updated: on $(Get-Date)</h5>"


Add-Content $strPath $sheet
Invoke-Item $strPath

 
 
 
 #--Missing/Currupt/Disabled Driver 
 $ReportTitle="Missing/Currupt/Disabled Driver"
 $strPath = "$location\MissingDriver.html"
 updateHTML $strPath


 $sheet=Get-WmiObject Win32_PNPEntity -ComputerName $vComputerName | where {$_.Configmanagererrorcode -ne 0} | Select Caption,ConfigmanagererrorCode,Description,DeviceId,HardwareId,PNPDeviceID | ConvertTo-Html -Head $test -Title $ReportTitle -Body "<h1>$ReportTitle</h1>`n<h1> Computer Name : $vComputerName </h1>`n<h5>Updated: on $(Get-Date)</h5>"

 Add-Content $strPath $sheet
 Invoke-Item $strPath




  #--Office/.Net/IE/QualityRollup Update
  $ReportTitle="Office/.Net/IE/QualityRollup Update"
  $strPath="$location\OfficeUpdate.html"
  updateHTML $strPath

  $Report = @()
  $count=1

  $InputObject | % {
   $objSession = [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session",$_))
   $objSearcher= $objSession.CreateUpdateSearcher()
   $HistoryCount = $objSearcher.GetTotalHistoryCount()
   $colSucessHistory = $objSearcher.QueryHistory(0, $HistoryCount)
   Foreach($objEntry in $colSucessHistory | where {($_.ResultCode -eq '2') })
  {
       $pso = "" | select SrNo,Title,Date
       $pso.SrNo=$count
       $pso.Title = $objEntry.Title
       $pso.Date = $objEntry.Date
       $Report += $pso
       $count++
       }
   $objSession = $null
  }

   
$Report | where { ([string]$_.Title -notlike "Definition Update*") }| ConvertTo-Html -Head $test -Title $ReportTitle -Body "<h1>$ReportTitle</h1>`n<h1> Computer Name : $vComputerName </h1>`n<h5>Updated: on $(Get-Date)</h5>" | Out-File $strPath

Invoke-Item $strPath




#--Installed Driver Information
$ReportTitle="Installed Driver"
$strPath="$location\DriverInstalled.html"
updateHTML $strPath


$PNPE=Get-WmiObject Win32_PNPEntity -ComputerName $vComputerName
$PNPSD=Get-WmiObject Win32_PnPSignedDriver -ComputerName $vComputerName
$Report = @()

$count=1

Foreach($a in $PNPE)
{
Foreach($b in $PNPSD)
{
if($a.deviceid -eq $b.deviceid)
{

if($b.driverversion -gt 0)
{
$pso = "" | select SrNo,Description,DriverVersion,DriverProvidername,DriverDate,InfName,Status,ConfigMAnagerErrorCode
  $pso.SrNo=$count
  $pso.Description = [string]$b.description
	$pso.DriverVersion=[string]$b.driverversion
	$pso.DriverProvidername=[string]$b.driverprovidername
    $pso.DriverDate=([string]$b.driverdate).substring(0,8)
    $pso.InfName=[string]$b.infname
    $pso.Status=[string]$a.status
    $pso.ConfigMAnagerErrorCode=[string]$a.ConfigManagerErrorCode
   
  
  $Report += $pso
       $count++

}}
}}

  
$Report | where { ([string]$_.Title -notlike "Definition Update*") }| ConvertTo-Html -Head $test -Title $ReportTitle -Body "<h1>$ReportTitle</h1>`n<h1> Computer Name : $vComputerName </h1>`n<h5>Updated: on $(Get-Date)</h5>" | Out-File $strPath

Invoke-Item $strPath




#--Power Information 
$powerplan=get-wmiobject -namespace "root\cimv2\power" -class Win32_powerplan -ComputerName $vComputerName | where {$_.IsActive}
$ReportTitle="Power Options"
$powerSettings = $powerplan.GetRelated("win32_powersettingdataindex") | foreach {
 $powersettingindex = $_;

 $powersettingindex.GetRelated("Win32_powersetting") | select @{Label="Power Setting";Expression={$_.instanceid}},
 @{Label="AC/DC";Expression={$powersettingindex.instanceid.split("\")[2]}},
 @{Label="Summary";Expression={$_.ElementName}},
 @{Label="Description";Expression={$_.description}},
 @{Label="Value";Expression={$powersettingindex.settingindexvalue}}
 }

$strPath="$location\power.html"
$powerSettings | ConvertTo-Html -Head $test -Title "Powersettings" -Body "<h1>$ReportTitle</h1> `n<h1> Computer Name : $vComputerName </h1>`n<h5>Updated: on $(Get-Date)</h5>" >  $strPath
ii $strPath




#--Firewall Status 
 $ReportTitle="Firewall Status"
 $strPath="$location\firewall.html"
 updateHTML $strPath

 Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\services\SharedAccess\Parameters\FirewallPolicy\DomainProfile | Select DisableNotifications, @{Expression={$_.EnableFirewall -as [string]};Label="Domain Firewall Profile"} | ConvertTo-Html -Head $test -Title $ReportTitle -Body "<h1>$ReportTitle</h1> `n<h1> Computer Name : $vComputerName </h1>`n<h5>Updated: on $(Get-Date)</h5>" > $strPath
 Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\services\SharedAccess\Parameters\FirewallPolicy\PublicProfile | select DisableNotifications,@{Expression={$_.EnableFirewall -as [string]};Label="Public Firewall Profile"} | ConvertTo-Html -Head $test  -Body "<h2>Public Profile</h2>" >> $strPath
 Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\services\SharedAccess\Parameters\FirewallPolicy\StandardProfile | select DisableNotifications,@{Expression={$_.EnableFirewall -as [string]};Label="Standard Firewall Profile"} | ConvertTo-Html -Head $test  -Body "<h2>Standard Profile</h2>" >> $strPath
    

 Invoke-Item $strPath




#--RDP status
$ReportTitle="RDP Status"
 $strPath="$location\RDPStatus.html"
 updateHTML $strPath


$x=Get-ItemProperty "hklm:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" | select "(Defualt)",@{Expression={if($_.UserAuthentication -eq 0){ $a="Less secure"}else{$a="More secure"}$a};Label="Security Status";}
$y=Get-ItemProperty "hklm:\SYSTEM\CurrentControlSet\Control\Terminal Server"  | select "(Defualt)",@{Expression={if($_.fDenyTSConnections -eq 0){$b="RDP Enabled"}else{$b="RDP Disabled"}$b};Label="RDP Status";}

if ($y.'RDP Status' -eq "RDP Enabled")
{
$y|ConvertTo-Html -Head $test -Title $ReportTitle -Body "<h1>$ReportTitle</h1> `n<h1> Computer Name : $vComputerName </h1>`n<h5>Updated: on $(Get-Date)</h5>" >  $strPath
$x|ConvertTo-Html -Head $test -Title $ReportTitle -Body "" >>  $strPath

}
else
{
$y|ConvertTo-Html -Head $test -Title $ReportTitle -Body "<h1>$ReportTitle</h1> `n<h1> Computer Name : $vComputerName </h1>`n<h5>Updated: on $(Get-Date)</h5>" >  $strPath
}
ii $strPath



#--Font list
$ReportTitle="Font List"
$strPath="$location\FontList.html"
updateHTML $strPath


[Windows.Media.Fonts]::SystemFontFamilies |select @{Expression={$_.Source};Label="Installed Font";},FamilyMaps |ConvertTo-Html -Head $test -Title $ReportTitle -Body "<h1>$ReportTitle</h1> `n<h1> Computer Name : $vComputerName </h1>`n<h5>Updated: on $(Get-Date)</h5>" >  $strPath
     ii $strPath