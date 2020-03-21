function TK_Get-CurrentWeek {
    <#
            .SYNOPSIS
                Get current calendar week
                 
            .DESCRIPTION
                Get current calendar week
                 
            .EXAMPLE
                $CurrentWeek = TK_Get-CurrentWeek
                 
            .NOTES
                Author        : Thomas Krampe | t.krampe@loginconsultants.de
                Version       : 1.0
                Creation date : 26.07.2018 | v0.1 | Initial script
                Last change   : 07.09.2018 | v1.0 | Create the script header
                 
          
                IMPORTANT NOTICE
                ----------------
                THIS SCRIPT IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
                ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR NON- INFRINGEMENT.
                LOGIN CONSULTANTS, SHALL NOT BE LIABLE FOR TECHNICAL OR EDITORIAL ERRORS OR OMISSIONS CONTAINED 
                HEREIN, NOT FOR DIRECT, INCIDENTAL, CONSEQUENTIAL OR ANY OTHER DAMAGES RESULTING FROM FURNISHING,
                PERFORMANCE, OR USE OF THIS SCRIPT, EVEN IF LOGIN CONSULTANTS HAS BEEN ADVISED OF THE POSSIBILITY
                OF SUCH DAMAGES IN ADVANCE.
                 
            .RETURN
                Current week number
        #>
     
    $CurrentWeek = [System.Globalization.DateTimeFormatInfo]::CurrentInfo.Calendar.GetWeekOfYear([datetime]::Now,0,0) 
     
    Return $CurrentWeek
}  #Endfunction TK_Get-CurrentWeek