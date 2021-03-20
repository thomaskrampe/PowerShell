function TK_Invoke-Gist {
    <#
        .SYNOPSIS
            TK_Invoke-Gist
        .DESCRIPTION
            Execute a gist from a public github gist
        .PARAMETER Identity
            The identity of the gist eg. 5087431135c9aa650952a349910e6acf
        .PARAMETER Arguments
            Arguments for the gist if any
        .EXAMPLE
            TK_Invoke-Gist -Identity 5087431135c9aa650952a349910e6acf
        .LINK        
            https://github.com/thomaskrampe/PowerShell/blob/master/WorkingWithFiles/TK_Invoke-Gist.ps1
        .NOTES       
            Author        : Thomas Krampe | thomas.krampe@myctx.net        
            Version       : 1.0            
            Creation date : 21.02.2021 | v0.1 | Initial script         
            Last change   : 20.03.2021 | v1.0 | Add script documentation
                
        IMPORTANT NOTICE 
        ---------------- 
        THIS SCRIPT IS PROVIDED "AS IS" WITHOUT WARANTIES OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING        
        ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR NON- INFRINGEMENT.        
        THOMAS KRAMPE, SHALL NOT BE LIABLE FOR TECHNICAL OR EDITORIAL ERRORS OR OMISSIONS CONTAINED         
        HEREIN, NOT FOR DIRECT, INCIDENTIAL, CONSEQUENTIAL OR ANY OTHER DAMAGES RESULTING FROM FURNISHING,        
        PERFORMANCE, OR USE OF THIS SCRIPT, EVEN IF THOMAS KRAMPE HAS BEEN ADVISED OF THE POSSIBILITY        
        OF SUCH DAMAGES IN ADVANCE.

    #>
    
    Param(
        [String]
        $Identity,

        [String]
        $Arguments
    )

    $gistBase = "https://api.github.com/gists/"

    if ( ($Identity.Length -eq 32) -and ($Identity -match '[A-Za-z0-9]*') ) {
        # We got a gist ID
        $gistUrl = $gistBase + $Identity
        # Use TLS 1.2
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $pageContents = Invoke-WebRequest -Uri $gistUrl

        $gist = $pageContents.Content | ConvertFrom-Json

    }
    else {
        # Not a gist ID, try the full URL (this is very bad, I am sorry)
        $GistId = $Identity.TrimEnd("/").Split("/")[-1]
        $gistUrl = $gistBase + $GistId  
        $pageContents = Invoke-WebRequest -Uri $gistUrl
        $gist = $pageContents.Content | ConvertFrom-Json
    }

    Write-Verbose "Invoking gist from $gistUrl"
    Write-Verbose "Gist by $($gist.owner.login)"
    Write-Verbose "Created at $($gist.created_at), last modified at $($gist.updated_at)"
    
    <# 
    Write-Host "Invoking gist from $gistUrl"
    Write-Host "Gist by $($gist.owner.login)"
    Write-Host "Created at $($gist.created_at), last modified at $($gist.updated_at)"
    Write-Host "Gist-Files $($gist.files)" 
    #>

    # Get the filenames and sort them alphabetically
    $files = $gist.files | Get-Member | Where-Object { $_.MemberType -eq "NoteProperty" } | Select-Object -ExpandProperty Name | Sort-Object



    foreach ($file in $files) {
        $file = $gist.files.$file
        Write-Verbose "Invoking file $($file.filename)"
        # Write-Host "Invoking file $($file.filename)"
        if ($file.language -ne "PowerShell") {
            Write-Warning "The file $($file.filename) is not marked as being of the PowerShell language."
        }

        Invoke-Expression -Command $file.Content 
    }
}


TK_Invoke-Gist -Identity 5087431135c9aa650952a349910e6acf
