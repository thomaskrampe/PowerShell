cls

$am_path = "D:\AM"
$env_id = "adede9f1-924b-4096-9d56-7310cc4bc924"
$csv_path = "C:\temp\report.cvs"

# Loading AM Module
$module = "$am_path\$env_id\bin\modules\admin\Automation Machine.psm1"

If (Test-path $module){
        Import-module $module -Verbose
    } 
else 
    {
        Write-host "Module $module cannot be found"
    }

#Get data
$am_cols = Get-AMCollection | Sort-Object Name

# Declare an array to collect our result objects 
$resultsarray =@()

# For every collection do this loop 
ForEach ($am_col in $am_cols) {
    # Create a new custom object to hold our result. 
    $tmpObject = new-object PSObject

    # Add our data to $contactObject as attributes using the Add-Member commandlet 
    $tmpObject | Add-Member -MemberType NoteProperty -Name "Name" -Value $am_col.Name 
    $tmpObject | Add-Member -MemberType NoteProperty -Name "Version" -Value $am_col.Version.VersionNumber 
    $tmpObject | Add-Member -MemberType NoteProperty -Name "Layers" -Value $(($am_col.Layers.Layer.Name | Out-String) -replace "`n",","  -replace "`r","")
    $tmpObject | Add-Member -MemberType NoteProperty -Name "Packages" -Value $(($am_col.Layers.Layer.Packages.Package.Name | Out-String) -replace "`n","," -replace "`r","")

    # Save the current $tmpObjectby appending it to $resultsArray ( += means append a new element to ‘me’) 
    $resultsarray += $tmpObject
} 

$resultsarray | Export-csv $csv_path -NoTypeInformation -Delimiter ";" 
