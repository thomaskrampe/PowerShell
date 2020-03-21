FUNCTION MW-CreateProfileFolder {
<#
THis function creates a root folder for Roaming Profiles with the appropriate file permissions
You need to define the admin group name that can access the folder, 
if no Admingroup Parameter is defined the local Admin group is used
 
Example:
 
MW-CreateProfileFolder -folder C:\Profiles
will create the folder, set the appropriate folder permissions on C:\Profiles with the local admin account
and will share it as Profiles$ 
#>
 
Param ($folder,
      $adminGroup)  
 
      if ($adminGroup -eq $null){
            Write-host "no admin group defined, using builtin group"
            $objSID = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
            $adminGroup = ( $objSID.Translate([System.Security.Principal.NTAccount]) ).Value
      }
 
# Create folder if not existent
IF (!(Test-path $folder)) {MD $folder}
 
$DefaultAccessGroup = "authenticated users"
 
#share folder
$Sharename = "$($folder.split("\")[-1])" + "`$"
Write-host "trying to create a share with the name $Sharename"
if (Get-SmbShare $sharename -ea SilentlyContinue){
    write-host "share is already existent, will not create it"
} ELSE {
    New-SmbShare -Path $folder -Name $sharename -FullAccess $DefaultAccessGroup
}
 
 
# remove inheritence
$acl = Get-Acl $Folder
$acl.SetAccessRuleProtection($true,$true)
$acl |Set-Acl
 
# remove all rights
$acl = Get-Acl $Folder
$acl.Access | % {$acl.purgeaccessrules($_.IdentityReference)}
# add new acl
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule $adminGroup ,"Fullcontrol", "ContainerInherit,ObjectInherit", "None","Allow"
$acl.AddAccessRule($rule)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule "SYSTEM","Fullcontrol", "ContainerInherit,ObjectInherit", "None","Allow"
$acl.AddAccessRule($rule)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule "Creator Owner","Fullcontrol", "ContainerInherit,ObjectInherit", "InheritOnly","Allow"
$acl.AddAccessRule($rule)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule $DefaultAccessGroup,"AppendData, ReadAndExecute", "None", "None","Allow"
$acl.AddAccessRule($rule)
$acl | set-acl
 
 
} #EndFUNCTION MW-CreateProfileFolder