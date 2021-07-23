# CVAD Database Migration
## Preparations

Following steps should be performed just before the Citrix Database migration procedure begins:

1\. Take a snapshot of Delivery Controller virtual machines. This will help us revert to previous state if anything goes wrong while establishing connections with the new database server. 

2\. Enable maintenance mode on all VDA machines in Citrix Studio. Once primary delivery controller is disconnected from databases, all VDAs will re-register themselves and new connections will be handled with/by newly elected broker.

3\. Make sure that all active sessions are logged off.

4\. Back up the databases on the original SQL server.
  * Site DB – Stores the running Site configuration, plus the current session state and connection information.
  * Configuration Logging DB – Stores information about Site configuration changes and administrative activities.
  * Monitoring DB – Stores data used by Director, such as session and connection information.

5\. Restore Database on the "new" database server.

6\. Under User Mapping, select the database and assign below roles to Delivery Controller computer accounts:

```
Citrix Site Database – ADIdentitySchema_ROLE
Citrix Site Database – Analytics_ROLE            # for 7.8 and newer
Citrix Site Database – AppLibrarySchema_ROLE     # for 7.8 and newer
Citrix Site Database – chr_Broker
Citrix Site Database – chr_Controller
Citrix Site Database – ConfigLoggingSiteSchema_ROLE
Citrix Site Database – ConfigurationSchema_ROLE
Citrix Site Database – DAS_ROLE
Citrix Site Database – DesktopUpdateManagerSchema_ROLE
Citrix Site Database – EnvTestServiceSchema_ROLE
Citrix Site Database – HostingUnitServiceSchema_ROLE
Citrix Site Database – Monitor_ROLE
Citrix Site Database – OrchestrationSchema_ROLE  # for 7.11 and newer
Citrix Site Database – public
Citrix Site Database – StorefrontSchema_ROLE     # for 7.8 and newer
Citrix Site Database – TrustSchema_ROLE          # for 7.11 and newer
Citrix Site Monitoring Database – Monitor_ROLE
Citrix Site Monitoring Database – public
Citrix Site Configuration Logging Database – ConfigLoggingSchema_ROLE
Citrix Site Configuration Logging Database – public
```
![][1]

## Migration

In this part of Citrix Database Migration process, we will migrate Citrix XenDesktop or Citrix Virtual Apps and Desktops Databases.

1\. Confirm that Citrix Studio is not opened on any Delivery Controller. If Studio is published, ensure that there is no active session of that.

2\. Login to Primary Citrix Delivery Controller, open PowerShell as an Administrator and execute following commands to see the existing database connection strings.

```language-powershell
asnp citrix*
Get-ConfigDBConnection
Get-AcctDBConnection
Get-AnalyticsDBConnection                  #  for 7.6 and newer
Get-AppLibDBConnection                     #  for 7.8 and newer
Get-OrchDBConnection                       #  for 7.11 and newer
Get-TrustDBConnection                      #  for 7.11 and newer
Get-HypDBConnection
Get-ProvDBConnection
Get-BrokerDBConnection
Get-EnvTestDBConnection
Get-SfDBConnection
Get-MonitorDBConnection
Get-MonitorDBConnection -DataStore Monitor
Get-LogDBConnection
Get-LogDBConnection -DataStore Logging
Get-AdminDBConnection
```

![][2]

3\. Run the migration script from [GitHub][3]. Make sure that you change the old and the new database server\instance names in the script.

## Database testing
Sometimes it make sense to try if the new database is available and accessable. In that case you can use a PowerShell function like the following example function.

```language-powershell
function Test-SqlConnection {
    param(
        [Parameter(Mandatory)]
        [string]$ServerName,

        [Parameter(Mandatory)]
        [string]$DatabaseName,

        [Parameter(Mandatory)]
        [pscredential]$Credential
    )

    $ErrorActionPreference = 'Stop'

    try {
        $userName = $Credential.UserName
        $password = $Credential.GetNetworkCredential().Password
        $connectionString = 'Data Source={0};database={1};User ID={2};Password={3}' -f $ServerName,$DatabaseName,$userName,$password
        $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString
        $sqlConnection.Open()
        
		## This will run if the Open() method does not throw an exception
        write-host "Database connection to $Servername and Database $DatabaseName successful." -ForegroundColor Green
    } catch {
        write-host "Database connection to $Servername and Database $DatabaseName NOT successful." -ForegroundColor Red
    } finally {
        ## Close the connection when we're done
        $sqlConnection.Close()
    }
}

Test-SqlConnection -ServerName 'serverhostname' -DatabaseName 'DbName' -Credential (Get-Credential)

```



[1]: CVAD-Site-Database-Role-assignment-01.png
[2]: CVAD-Site-Database-Role-assignment-02.png
[3]: https://github.com/thomaskrampe/PowerShell/blob/master/Citrix/XenDesktop/XenDesktop7MoveDatabase.ps1



