#==============================================================================================
Function writeHtmlHeader
{
param($title, $fileName)
$date = ( Get-Date -format d)
$head = @"
<html>
<head>
<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>
<title>$title</title>
<STYLE TYPE="text/css">
<!--
td {
font-family: Tahoma;
font-size: 11px;
border-top: 1px solid #999999;
border-right: 1px solid #999999;
border-bottom: 1px solid #999999;
border-left: 1px solid #999999;
padding-top: 0px;
padding-right: 0px;
padding-bottom: 0px;
padding-left: 0px;
overflow: hidden;
}
body {
margin-left: 5px;
margin-top: 5px;
margin-right: 0px;
margin-bottom: 10px;
table {
table-layout:fixed; 
border: thin solid #000000;
}
-->
</style>
</head>
<body>
<table width='1200'>
<tr bgcolor='#CCCCCC'>
<td colspan='7' height='56' align='center' valign="middle">
<font face='tahoma' color='#003399' size='5'>
<strong>$title - $date</strong></font>
</td>
</tr>
</table>
<table width='1200'>
<tr bgcolor='#CCCCCC'>
</tr>
</table>
"@
$head | Out-File $fileName
}

# ==============================================================================================
Function writeHtmlFooter
{
param($fileName)
@"
</table>
<table width='1200'>
<tr bgcolor='#CCCCCC'>
<td colspan='7' height='25' align='left'>
<font face='courier' color='#003399' size='2'><strong></strong></font>
</table>
</body>
</html>
"@ | Out-File $FileName -append
}

# ==============================================================================================
Function writeTableHeader
{
param($fileName)
$tableHeader = @"
<table width='1200'><tbody>
<tr bgcolor=#CCCCCC>

"@

$i = 0
while ($i -lt $headerNames.count) {
	$headerName = $headerNames[$i]
	$headerWidth = $headerWidths[$i]
	$tableHeader += "<td  height='40' width='" + $headerWidth + "%' align='center'><font size='3'><strong>$headerName</strong></td>"
	$i++
}

$tableHeader += "</tr>"

$tableHeader | Out-File $fileName -append
}


# ==============================================================================================

# ==============================================================================================
# ==                                       MAIN SCRIPT                                        ==
# ==============================================================================================

# Enter AM Path
$am_path="C:\Automation Machine"


If ((Test-Path $am_path) –eq $false){
    write-host "Please enter the Path to your AM Share (e.g. C:\Automation Machine)"
    $am_path = Read-Host
    }


$inventory = Get-ChildItem $am_path -Filter "????????-????-????-????-????????????"
Write-Host "Please choose your Environment (1,2,3...)"
$i=1
foreach ($inv in $inventory){
    
    $envxml = $am_path+"\"+$inv+"\config\environment.xml" 
    [xml]$XML = Get-Content $envxml
    Write-Host $i - $xml.Environment.Name 
    $i++
}
$env= Read-Host
$env_id =  $inventory[$env-1]

$envxml = $am_path+"\"+$env_id+"\config\environment.xml" 
[xml]$XML=Get-Content $envxml
$envname = $xml.Environment.Name

$colors= @('blue', 'green', 'maroon', 'navy', 'olive', 'purple', 'red', 'teal','blue', 'green', 'maroon', 'navy', 'olive', 'purple', 'red', 'teal','blue', 'green', 'maroon', 'navy', 'olive', 'purple', 'red', 'teal' )
$tableEntry=""

$currentDir = Split-Path $MyInvocation.MyCommand.Path
$resultsHTM = Join-Path $currentDir ("AM_Overview - $envname.htm")

$headerNames  = "Collection", "Computer", "Layer", "Packages", "Last Modifier", "Modification Date"
$headerWidths =    "4",          "2",       "4",       "6",        "4",             "4"

 
# Loading AM Module
$module = "$am_path\$env_id\bin\modules\admin\Automation Machine.psm1"

If (Test-path $module){
        Import-module $module -Verbose
    } 
else 
    {
        Write-host "Module $module cannot be found"
    }
 
#Get/Write data

$am_cols = Get-AMCollection | Sort-Object Name
$am_comps = Get-AMComputer
 
ForEach ($am_col in $am_cols) {
        $bgcolor = "#CCCCCC"; $fontColor = "blue"
        $counter = 1
        $collection=$am_col.name
        $layers= $am_col.Layers | Sort-Object ProcessOrderNumber
        $packages = $layers.Layer.Packages
        $layers= $layers.layer.name
        $tableEntry += "<tr>"
        # Collection, Version entry
		$tableEntry += ("<td bgcolor='" + $bgcolor + "' align=center><font color='" + $fontColor + "'>$collection</font></td>")
    	# computer entries
        $tmpentry = ("<td bgcolor='" + $bgcolor + "' align=center>")
        foreach ($am_comp in $am_comps){
                if ($am_comp.collectionID -eq $am_col.id){
                    $tmpentry  += ("<font color='" + $fontColor + "'><br>$am_comp</font>")
                }
        }
        $tableEntry += $tmpentry
        # layer entries
        $tmpentry = ("<td bgcolor='" + $bgcolor + "' align=center>")
        $counter = 0
        foreach ($layer in $layers){
                $layerColor =  $colors[$counter]
                $tmpentry  += ("<font color='" + $layerColor + "'><br>$layer</font>")
                $counter += 1
                }
        $tableEntry += $tmpentry 
        # package entries
        $counter = -1
        $tmpentry = ("<td bgcolor='" + $bgcolor + "' align=center>")
        foreach ($package in $packages){
                if($package.OrderNumber -eq 0)
                    {
                    $counter += 1    
                    }
                $packageColor =  $colors[$counter]
                $tmpentry  += ("<font color='" + $packageColor + "'><br>$package</font>")
                                }
        $tableEntry += $tmpentry
        # modifier
        $counter = -1
        $tmpentry = ("<td bgcolor='" + $bgcolor + "' align=center>")
        foreach ($package in $packages){
                if($package.OrderNumber -eq 0)
                    {
                    $counter += 1    
                    }
                $packageColor =  $colors[$counter]
                $metadata = $package.Package.Metadata.Properties.'Last modified by'
                $tmpentry  += ("<font color='" + $packageColor + "'><br>$metadata</font>")
                                }
        $tableEntry += $tmpentry
        # modifcation date
        $counter = -1
        $tmpentry = ("<td bgcolor='" + $bgcolor + "' align=center>")
        foreach ($package in $packages){
                if($package.OrderNumber -eq 0)
                    {
                    $counter += 1    
                    }
                $packageColor =  $colors[$counter]
                $metadata = $package.Package.Metadata.Properties.'Last modified'
                [long]$date = $metadata
                $metadata = Get-Date $date
                $metadata = $metadata.AddHours(+2)
                $days = (Get-Date) - $metadata
                if($days.days -le 30)
                {
                    $tmpentry  += ("<font color='" + $packageColor + "'><b><br>$metadata</B></font>")
                    }
                else{
                    $tmpentry  += ("<font color='" + $packageColor + "'><br>$metadata</font>")
                }
        }
        $tableEntry += $tmpentry
	    $tableEntry += "</tr>"
} 
 

 

Write-Host ("Saving results to html report: " + $resultsHTM)
writeHtmlHeader "Automation Machine - $envname" $resultsHTM
writeTableHeader $resultsHTM
$tableEntry | Out-File $resultsHTM -append
writeHtmlFooter $resultsHTM


