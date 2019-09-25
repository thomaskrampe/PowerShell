# Get all disabled users and delete them

Add-PSSnapIn ShareFile

Function FindDisabledUsers {
    $UserType = "employee"
    $client = Get-SfClient -Name "c:\tmp\Sharefile\sfclient.sfps"
    $entity = "";
    switch ($UserType.ToLower()){
        "employee"{
            $entity = 'Accounts/Employees';
        } 
        "client" {
            $entity = 'Accounts/Clients';
        }
      }
      
    # Pull all of the Account Employees or Clients
    $sfUsers = Send-SfRequest -Client $client -Entity $entity

    $fileOutput = @()
      
    # Loop through each of the Employees or Clients returned from inital call
    foreach($sfUserId in $sfUsers){
        #Get full user information including security 
        $sfUser = Send-SfRequest -Client $client -Entity Users -Id $sfUserId.Id -Expand Security
        
        #Output to Console Emails of disabled users
        Write-Host $sfUser.Email
        
        # check to see if security parameter IsDisabled is true
        switch ($sfUser.Security.IsDisabled ) {
            "True" {
                $fileOutput += New-Object PSObject -Property @{'UserId'=$sfUserId.Id;'FullName'=$sfUser.FullName;'Email'=$sfUser.Email}
            }
        }
    }

    #Output CSV file with all disabled user information
    $fileOutput | Export-Csv ("C:\tmp\Sharefile\" + $UserType + ".csv") -Force -NoTypeInformation
}

Function DeleteUsers {
    # $UserType = "employee"
    $client = Get-SfClient -Name "c:\tmp\Sharefile\sfclient.sfps"
    $sfUserObjects = Import-Csv ("C:\tmp\Sharefile\employee.csv")
    
    foreach($sfUser in $sfUserObjects){
        Send-SfRequest -Client $client -Method Delete -Entity Users -Id $sfUser.UserId -Parameters @{"completely" = "true"}
    }
    
}


# Create an authentication file
New-SfClient -Name "c:\tmp\Sharefile\sfclient.sfps"
# Get-SfClient -Name "c:\tmp\Sharefile\sfclient.sfps"    

FindDisabledUsers;

# DeleteUsers; 