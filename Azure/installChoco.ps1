<#
 .SYNOPSIS
        Install Chocolatey with Custom Script Extension

 .DESCRIPTION
        Install Chocolatey with CustomeScript Extension and applications via Chocolatey (eg. Google Chrome)

  .LINK
        https://github.com/thomaskrampe/CitrixCloud/tree/master/XenApp%20Essentials/CustomScriptExtension 
                 
 .NOTES
        Author        : Thomas Krampe | t.krampe@loginconsultants.de
        Version       : 1.0
        Creation date : 22.01.2018 | v0.1 | Initial script
        Last change   : 22.01.2018 | v1.0 | Release it to GitHub
#>

# Install Chocolatey
iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1')) 

# Enable global confirmation
choco feature enable -n allowGlobalConfirmation

# Install Google Chrome via Chocolatey
choco install googlechrome
