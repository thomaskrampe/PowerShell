# ===============================================================================================================
#
# Title:              PVS Create or Join Farm Script
# Author:             Thomas Krampe - t.krampe@loginconsultants.com
#
# Version:            1.0
#
# Created:            25.06.2014
#
# Special thanks to : To the Automation Machine Team
#
# Purpose:            The following script will check if a given PVS database already
#                     exists on a MS-SQL Server. If not it will set a variable to "Create"
#                     otherwise it will set the variable to "Join".
#
# Requirements:       nothing
#
# ===============================================================================================================

# Check if PVS DB exists

try
{
	$conn = New-Object System.Data.SQLClient.SQLConnection("Server=$env:pvs_db_server;Database=$env:pvs_db;Trusted_Connection=True")
	
    $cmd = New-Object System.Data.SQLClient.SQLCommand("SELECT COUNT(farmId) FROM dbo.Farm",$conn)
	$conn.Open()
	$Table_Num = $cmd.ExecuteScalar()

	If ($Table_Num -eq 0)
	{
		$env:JoinOrCreate = "Create"
	}
	Else
	{
		$env:JoinOrCreate = "Join"
	}
	
}
Catch [System.Data.SqlClient.SqlException]
{
	$env:JoinOrCreate = "Create"
}
Catch
{
	throw $_
}
Write-Host "Join or create mode:$env:JoinOrCreate"