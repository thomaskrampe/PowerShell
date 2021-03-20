function TK_DownloadFilesFromRepo {
<#
        .SYNOPSIS
            TK_DownloadFilesFromRepo
        .DESCRIPTION
            Download a file from a public github repository
        .PARAMETER Owner
            The owner of the reporitory
        .PARAMETER Repository
            The Repository name
        .PARAMETER Path    
            The Path to the file you would like to download
        .PARAMETER DestinationPath
            The destionation for storing the file
        .EXAMPLE
        on macOS    
        TK_DownloadFilesFromRepo -Owner thomaskrampe -Repository PowerShell -Path /WorkingWithFiles/TK_Copy-WithProgress.ps1 -DestinationPath \Users\thomas
        on Windows
        TK_DownloadFilesFromRepo -Owner thomaskrampe -Repository PowerShell -Path /WorkingWithFiles/TK_Copy-WithProgress.ps1 -DestinationPath C:\\Users\thomas
        .LINK        
            https://github.com/thomaskrampe/PowerShell/blob/master/User%20Profiles/TK_ReadFromINI.ps1
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
    [string]$Owner,
    [string]$Repository,
    [string]$Path,
    [string]$DestinationPath
    )

    $baseUri = "https://api.github.com/"
    $args = "repos/$Owner/$Repository/contents/$Path"
    $wr = Invoke-WebRequest -Uri $($baseuri+$args)
    $objects = $wr.Content | ConvertFrom-Json
    $files = $objects | where {$_.type -eq "file"} | Select -exp download_url
    $directories = $objects | where {$_.type -eq "dir"}
    
    $directories | ForEach-Object { 
        DownloadFilesFromRepo -Owner $Owner -Repository $Repository -Path $_.path -DestinationPath $($DestinationPath+$_.name)
    }

    
    if (-not (Test-Path $DestinationPath)) {
        # Destination path does not exist, let's create it
        try {
            New-Item -Path $DestinationPath -ItemType Directory -ErrorAction Stop
        } catch {
            throw "Could not create path '$DestinationPath'!"
        }
    }

    foreach ($file in $files) {
        $fileDestination = Join-Path $DestinationPath (Split-Path $file -Leaf)
        try {
            Invoke-WebRequest -Uri $file -OutFile $fileDestination -ErrorAction Stop -Verbose
            "Grabbed '$($file)' to '$fileDestination'"
        } catch {
            throw "Unable to download '$($file.path)'"
        }
    }

}