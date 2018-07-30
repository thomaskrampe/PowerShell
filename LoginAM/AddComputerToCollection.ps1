# Load special AM module
$lines = get-childitem -path "E:\Automation Machine" -exclude dtap,"environment manager",00000000-0000-0000-0000-000000000001,media,Logging,Monitoring -directory
$TMP_EnvironmentID = $lines.Name

$module = "E:\Automation Machine\$TMP_EnvironmentID\bin\modules\admin\Automation Machine.psm1"
Import-module $module

$Import_Servers = Get-content E:\server.txt
Foreach ($TMP_SValue in $Import_Servers) {
    If ($tmp_SValue -ne ""){New-AMComputer -Name $TMP_SValue.split(";")[0] -Collection $TMP_SValue.split(";")[1] }
}

