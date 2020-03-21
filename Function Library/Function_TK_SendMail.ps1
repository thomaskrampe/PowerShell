Function TK_SendMail {
    <#
        .SYNOPSIS
            TK_SendMail
        .DESCRIPTION
            Send an e-mail to one or more recipients.
        .PARAMETER Sender
            This parameter contains the e-mail address of the sender (e.g. mymail@mydomain.com).
        .PARAMETER Recipients
            This parameter contains the e-mail address or addresses of the recipients (e.g. "<name>@mycompany.com" or "<name>@mycompany.com", "<name>@mycompany.com")
        .PARAMETER Subject
            This parameter contains the subject of the e-mail
        .PARAMETER Text
            This parameter contains the body of the e-mail
        .PARAMETER SMTPServer
            This parameter contains the name or the IP-address of the SMTP server (e.g. 'smtp.mycompany.com')
        .EXAMPLE
            TK_SendMail -Sender "me@mycompany.com" -Recipients "someone@mycompany.com" -Subject "Something important" -Text "This is the text for the e-mail" -SMTPServer "smtp.mycompany.com"
            Sends an e-mail to one recipient
        .EXAMPLE
            TK_SendMail -Sender "me@mycompany.com" -Recipients "someone@mycompany.com","someoneelse@mycompany.com" -Subject "Something important" -Text "This is the text for the e-mail" -SMTPServer "smtp.mycompany.com"
            Sends an e-mail to two recipients
        .NOTES
            Author        : Thomas Krampe | t.krampe@loginconsultants.de
            Version       : 1.0
            Creation date : 26.07.2018 | v0.1 | Initial script
            Last change   : 26.07.2018 | v1.0 | Release
           
            IMPORTANT NOTICE
            ----------------
            THIS SCRIPT IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
            ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR NON- INFRINGEMENT.
            LOGIN CONSULTANTS, SHALL NOT BE LIABLE FOR TECHNICAL OR EDITORIAL ERRORS OR OMISSIONS CONTAINED 
            HEREIN, NOT FOR DIRECT, INCIDENTAL, CONSEQUENTIAL OR ANY OTHER DAMAGES RESULTING FROM FURNISHING,
            PERFORMANCE, OR USE OF THIS SCRIPT, EVEN IF LOGIN CONSULTANTS HAS BEEN ADVISED OF THE POSSIBILITY
            OF SUCH DAMAGES IN ADVANCE.
    #>
 
    [CmdletBinding()]
    Param( 
        [Parameter(Mandatory=$true, Position = 0)][String]$Sender,
        [Parameter(Mandatory=$true, Position = 1)][String[]]$Recipients,
        [Parameter(Mandatory=$true, Position = 2)][String]$Subject,
        [Parameter(Mandatory=$true, Position = 3)][String]$Text,
        [Parameter(Mandatory=$true, Position = 4)][String]$SMTPServer
    )
  
    begin {
        [string]$FunctionName = $PSCmdlet.MyInvocation.MyCommand.Name
        Write-Verbose "START FUNCTION - $FunctionName"
    }
  
    process {
        try {
            Send-MailMessage -From $Sender -to $Recipients -subject $Subject -body $Text -smtpServer $SMTPServer -BodyAsHtml
            Write-Verbose "E-mail successfully sent."
            Exit 0
        } catch {
            Write-Error "An error occurred trying to send the e-mail (exit code: $($Error[0]))!"
            Exit 1
        }
    }
  
    end {
        Write-Verbose "END FUNCTION - $FunctionName"
    }
} #EndFunction TK_SendMail