FUNCTION MW-ShowUEVPKGXRegistry {
<#
This functions shows the actual registry values in a PKGX file (UEV)
The parameter is the path to the PKGX file
Example
 
MW-ShowPKGXRegistry "C:\UEV\Join\SettingsPackages\MicrosoftWordpad6\MicrosoftWordpad6.pkgx"
#>
 
 
Param ($PKGXFile)
$stream = Export-UevPackage $PKGXFile
$data = $stream.split("`n")
$matches = $null
foreach ($line in $data){
        if ($line -match 'HKCU(.*)" Action="(.*)">(.*)<'){
            Write-host "REgkey: $($matches[1]) `t`t $($matches[3])"
 
        }
    }
 
 
} #EndFUNCTION MW-ShowUEVPKGXRegistry