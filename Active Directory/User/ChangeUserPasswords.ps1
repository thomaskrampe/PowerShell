# Import ActiveDirectory module
Import-module ActiveDirectory

# Grab list of users from a text file.
 $ListOfUsers = Get-Content C:\Temp\userlist.txt
 foreach ($user in $ListOfUsers) {
         
     #Generate a 15-character random password.
     $Password = -join ((48..57) + (65..90) + (97..122) + 36 + 33 | Get-Random -Count 15 | ForEach-Object { [char]$_ })
     
     #Convert the password to secure string.
     $NewPwd = ConvertTo-SecureString $Password -AsPlainText -Force
     
     #Assign the new password to the user.
     Set-ADAccountPassword $user -NewPassword $NewPwd -Reset
     
     #Force user to change password at next logon.
     # Set-ADUser -Identity $user -ChangePasswordAtLogon $true
     
     #Display userid and new password on the console.
     Write-Host $user, $Password
 }
 