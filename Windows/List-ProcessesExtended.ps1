<#
.SYNOPSIS
	List-ProcessesExtended.ps1    

.DESCRIPTION
    List processes with their dependent services

.EXAMPLE
    List-ProcessesExtended.ps1
        
.NOTES
     Author        : Thomas Krampe | thomas@myctx.net
     Version       : 1.0
     Creation date : 07.01.2023 | v0.1 | Initial script
     Last change   : 07.01.2023 | v1.0 | Release it to GitHub

    NOTICE
    THIS SCRIPT IS PROVIDED “AS IS” WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING 
    ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR NON- INFRINGEMENT. 
    THOMAS KRAMPE, SHALL NOT BE LIABLE FOR TECHNICAL OR EDITORIAL ERRORS OR OMISSIONS CONTAINED HEREIN,
    NOR FOR DIRECT, INCIDENTAL, CONSEQUENTIAL OR ANY OTHER DAMAGES RESULTING FROM THE FURNISHING, 
    PERFORMANCE, OR USE OF THIS SCRIPT, EVEN IF THOMAS KRAMPE HAS BEEN ADVISED OF THE POSSIBILITY 
    OF SUCH DAMAGES IN ADVANCE.
#>

$gps = Get-Process
$procIDs = gcim -Class Win32_Service
foreach ($prs in $gps) {
    "Process: $($prs.ProcessName)"
  $x = $procIDs | ? {$_.ProcessId -eq $prs.Id}
  foreach ($dps in $x) {
    write-host "  Dependent service: $($dps.Name)" -ForegroundColor Green
  }
}
