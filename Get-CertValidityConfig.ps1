function Get-CertValidityConfig {
    [CmdletBinding()]
    param (
        [Parameter(Position=0)]
        [ValidateScript({ Test-Path $_})]
        [string]
        $ConfigurationFile = "$PSScriptRoot\CertValidityConfig.json"
    )

    begin {
        Write-Verbose -Message "Verifying Configuration File Path valid: $ConfigurationFile"
        # When testing the module during development, the default pathing doesn't work
        $ConfigurationFile = $ConfigurationFile.Replace('Public\', '')
        If (Test-Path -Path $ConfigurationFile) {
            Write-Verbose -Message "Configuration path updated: $ConfigurationFile"
        } else {
            Write-Warning -Message "Unable to find configuration file!"
        }
    }

    process {
        $Global:CertValidityConfiguration = Get-Content $ConfigurationFile | ConvertFrom-Json

        $CertValidityConfiguration
    }

    end {

    }
}
