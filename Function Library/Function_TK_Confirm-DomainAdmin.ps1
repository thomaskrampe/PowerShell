function TK_Confirm-DomainAdmin {
    <#
    .SYNOPSIS
    Confirm Domain Admin
    .DESCRIPTION
    Check if user is domain admin
    .PARAMETER UserName
    user to check, if not given current user is used
    .EXAMPLE
    TK_Confirm-DomainAdmin -UserName Thomas
    Check if "Thomas" is domain admin
    .EXAMPLE
    TK_Confirm-DomainAdmin
    Check if current user is domain admin
    #>

    [cmdletbinding()]
    param (
        $UserName = $env:USERNAME
        )
    begin {
        $domainadmins = (Get-ADGroupMember 'domain admins').samaccountname
        }
    process {
        foreach ($user in $UserName) {
            if ($user -in $domainadmins) {
                Write-Verbose "$User is a member of the domain admins group"
                $domainadmin = $true
                } 
            else {
                Write-Verbose "$User is not a member of the domain admins group"
                $domainadmin = $false
                }
    
            [pscustomobject]@{
                User = $user
                DomainAdmin = $domainadmin
                }
            }
        }
    }