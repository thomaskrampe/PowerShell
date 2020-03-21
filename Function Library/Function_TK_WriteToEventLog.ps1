Function TK_WriteToEventLog {
    <#
        .SYNOPSIS
            TK_WriteToEventLog
        .DESCRIPTION
            Write an entry into the Windows event log. New event logs as well as new event sources are automatically created.
        .PARAMETER EventLog
            This parameter contains the name of the event log the entry should be written to (e.g. Application, Security, System or a custom one)
        .PARAMETER Source
            This parameter contains the source (e.g. 'MyScript')
        .PARAMETER EventID
            This parameter contains the event ID number (e.g. 3000)
        .PARAMETER Type
            This parameter contains the type of message. Possible values are: Information | Warning | Error
        .PARAMETER Message
            This parameter contains the event log description explaining the issue
        .EXAMPLE
            TK_WriteToEventLog -EventLog "System" -Source "MyScript" -EventID "3000" -Type "Error" -Message "An error occurred"
            Write an error message to the System event log with the source 'MyScript' and event ID 3000. The unknown source 'MyScript' is automatically created
        .EXAMPLE
            TK_WriteToEventLog -EventLog "Application" -Source "Something" -EventID "250" -Type "Information" -Message "Information: action completed successfully"
            Write an information message to the Application event log with the source 'Something' and event ID 250. The unknown source 'Something' is automatically created
        .EXAMPLE
            TK_WriteToEventLog -EventLog "MyNewEventLog" -Source "MyScript" -EventID "1000" -Type "Warning" -Message "Warning. There seems to be an issue"
            Write an warning message to the event log called 'MyNewEventLog' with the source 'MyScript' and event ID 1000. The unknown event log 'MyNewEventLog' and source 'MyScript' are automatically created
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
        [parameter(mandatory=$True)]  
        [ValidateNotNullorEmpty()]
        [String]$EventLog,
        [parameter(mandatory=$True)]  
        [ValidateNotNullorEmpty()]
        [String]$Source,
        [parameter(mandatory=$True)]
        [Int]$EventID,
        [parameter(mandatory=$True)]
        [ValidateNotNullorEmpty()]
        [String]$Type,
        [parameter(mandatory=$True)]
        [ValidateNotNullorEmpty()]
        [String]$Message
    )
  
    begin {
        [string]$FunctionName = $PSCmdlet.MyInvocation.MyCommand.Name
        Write-Verbose "START FUNCTION - $FunctionName"
    }
  
    process {
        # Check if the event log exist. If not, create it.
        Write-Verbose "Check if the event log $EventLog exists. If not, create it"
        if ( !( [System.Diagnostics.EventLog]::Exists( $EventLog ) ) ) {
            Write-Verbose "The event log '$EventLog' does not exist."
        try {
                New-EventLog -LogName $EventLog -Source $EventLog
                Write-Verbose "The event log '$EventLog' was created successfully"
            } catch {
                Write-Verbose "An error occurred trying to create the event log '$EventLog' (error: $($Error[0]))!"
 
            }
        } else {
            Write-Verbose "The event log '$EventLog' already exists."
        }
 
        # Check if the event source exist. If not, create it.
        Write-Verbose "Check if the event source '$Source' exists. If not, create it."
        if ( !( [System.Diagnostics.EventLog]::SourceExists( $Source ) ) ) {
            Write-Verbose "The event source '$Source' does not exist."
        try {
                [System.Diagnostics.EventLog]::CreateEventSource( $Source, $EventLog )
                Write-Verbose "The event source '$Source' was created successfully."    
            } catch {
                Write-Verbose "An error occurred trying to create the event source '$Source' (error: $($Error[0]))!"
            }
        } else {
            Write-verbose "The event source '$Source' already exists."
        }
                 
    # Write the event log entry
        Write-Verbose "Write the event log entry."      
    try {
            Write-EventLog -LogName $EventLog -Source $Source -eventID $EventID -EntryType $Type -message $Message
            Write-Verbose "The event log entry was written successfully."
        } catch {
            Write-Verbose "An error occurred trying to write the event log entry (error: $($Error[0]))!"
        }
    }
  
    end {
        Write-Verbose "END FUNCTION - $FunctionName"
    }
} #EndFunction TK_WriteToEventLog