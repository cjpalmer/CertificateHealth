<#
.SYNOPSIS
   Validates provided certificate against standard criteria
.DESCRIPTION
   Validates provided certificate against standard criteria
.EXAMPLE
   PS C:\> Get-Health -Certificate $Certificate
   Called from public function. Provided certificate is validated against default criteria
.PARAMETER Certificate
   Certificate object created by Get-CertificateHealth and other functions in module
.PARAMETER WarningDays
   Specify the amount of days before the certificate expiration should be in a
   warning state.
.PARAMETER CriticalDays
   Specify the amount of days before the certificate expiration should be in a
   critical state.
.PARAMETER WarningAlgorithm
   Array of algorithms that are deprecated.
.PARAMETER CriticalAlgorithm
   Array of algorithms with known vulnerabilities.
.PARAMETER CritialKeySize
   Certificates with key size less than this value will be considered critical.
.PARAMETER WarningKeySize
   Certificates with key size less than this value and greater than the CriticalKeySize
   will be considered warning.

.NOTES
    Created by: Charles Palmer from @wasserja's excellent start
    Modified: 11/12/2020 2:20:00 PM

    Version 1.0
        Took bulk of functionality from Get-CertificateHealth to centralize validity checks since there are multiple functions doing this now
        Moved Validity Defaults to configuration file and have Get-Health load from there
        Created function for Getting and Setting the configuration file contents
            Get-CertValidityConfig
            Set-CertValidityConfig
#>
function Get-Health {
    [CmdletBinding()]
    param (
        [object]$Certificate
    )

    begin {
        $null = Get-CertValidityConfig
        $WarningDays = $CertValidityConfiguration.WarningDays
        $CriticalDays = $CertValidityConfiguration.CriticalDays
        $WarningAlgorithm = $CertValidityConfiguration.WarningAlgorithm
        $CriticalAlgorithm = $CertValidityConfiguration.CriticalAlgorithm
        $CriticalKeySize = $CertValidityConfiguration.CriticalKeySize
        $WarningKeySize = $CertValidityConfiguration.WarningKeySize
    }

    process {
        # Check certificate is within $WarningDays
        if ($Certificate.NotAfter -le (Get-Date).AddDays($WarningDays) -and $Certificate.NotAfter -gt (Get-Date).AddDays($CriticalDays)) {
            Write-Verbose "PGH:Certificate is expiring within $WarningDays days."
            $ValidityPeriodStatus = 'Warning'
            $ValidityPeriodStatusMessage = "Certificate expiring in $($Certificate.Days) days."
        }
        # Check certificate is within $CriticalDays
        elseif ($Certificate.NotAfter -le (Get-Date).AddDays($CriticalDays) -and $Certificate.NotAfter -gt (Get-Date)) {
            Write-Verbose "PGH:Certificate is expiring within $CriticalDays days."
            $ValidityPeriodStatus = 'Critical'
            $ValidityPeriodStatusMessage = "Certificate expiring in $($Certificate.Days) days."
        }
        # Check certificate is expired
        elseif ($Certificate.NotAfter -le (Get-Date)) {
            Write-Verbose "PGH:Certificate is expired: $($Certificate.Days) days."
            $ValidityPeriodStatus = 'Critical'
            $ValidityPeriodStatusMessage = "Certificate expired: $($Certificate.Days) days."
        }
        # Certificate validity period is healthy.
        else {
            Write-Verbose "PGH:Certificate is within validity period."
            $ValidityPeriodStatus = 'OK'
            $ValidityPeriodStatusMessage = "Certificate expires in $($Certificate.Days) days."
        }
        #endregion

        #region Check certificate algorithm
        if ($CriticalAlgorithm -contains $Certificate.SignatureAlgorithm) {
            Write-Verbose "PGH:Certificate uses critical algorithm."
            $AlgorithmStatus = 'Critical'
            $AlgorithmStatusMessage = "Certificate uses a vulnerable algorithm $($Certificate.SignatureAlgorithm)."
        } elseif ($WarningAlgorithm -contains $Certificate.SignatureAlgorithm) {
            Write-Verbose "PGH:Certificate uses warning algorithm."
            $AlgorithmStatus = 'Warning'
            $AlgorithmStatusMessage = "Certificate uses the deprecated algorithm $($Certificate.SignatureAlgorithm)."
        } else {
            Write-Verbose "PGH:Certificate uses acceptable algorithm."
            $AlgorithmStatus = 'OK'
            $AlgorithmStatusMessage = "Certificate uses valid algorithm $($Certificate.SignatureAlgorithm)."
        }
        #endregion

        #region Check MinimumKeySize
        Write-Verbose 'PGH:Checking minimum key length.'
        if ($Certificate.KeySize -lt $CriticalKeySize) {
            # Key Size is critical
            Write-Verbose 'PGH:Certificate key length is critical.'
            $KeySizeStatus = 'Critical'
            $KeySizeStatusMessage = "Certificate key size $($Certificate.KeySize) is less than $CriticalKeySize."
        } elseif ($Certificate.KeySize -lt $WarningKeySize -and $Certificate.KeySize -ge $CriticalKeySize) {
            # Key Size is warning
            Write-Verbose 'PGH:Certificate key length is warning.'
            $KeySizeStatus = 'Warning'
            $KeySizeStatusMessage = "Certificate key size $($Certificate.KeySize) is less than $WarningKeySize."
        } elseif ($Certificate.KeySize -ge $WarningKeySize) {
            # Key Size is OK
            Write-Verbose 'PGH:Certificate key length is OK.'
            $KeySizeStatus = 'OK'
            $KeySizeStatusMessage = "Certificate key size $($Certificate.KeySize) is greater than or equal to $WarningKeySize."
        } else {
            # Key Size is OK
            Write-Verbose 'PGH:Certificate key length is Unknown.'
            $KeySizeStatus = 'Unknown'
            $KeySizeStatusMessage = "Certificate key size is unknown."
        }
        #endregion
        $CertValidityProperties = @{
            ValidityPeriodStatus = $ValidityPeriodStatus
            ValidityPeriodStatusMessage = $ValidityPeriodStatusMessage
            AlgorithmStatus = $AlgorithmStatus
            AlgorithmStatusMessage = $AlgorithmStatusMessage
            KeySizeStatus = $KeySizeStatus
            KeySizeStatusMessage = $KeySizeStatusMessage
        }
        $CertValidity = New-Object -TypeName PSObject -Property $CertValidityProperties
        $CertValidity
    }

    end {

    }
}
