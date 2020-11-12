<#
.Synopsis
    Retrieve certificate from remote system and validates it against criteria
.DESCRIPTION
    Retrieve certificate from remote system and validates it against criteria for days until expiration, algorithm, and key size
.EXAMPLE
    Get-NetCertificateHealth -IP 8.8.8.8

    Queries 8.8.8.8 on the default port of 443 and verfies certificate doesn't expire with 60 days, uses at least SHA256RSA and has at least 2048 key size
    It will return warning or critical results for any failing validations
.NOTES
Adapted by: Jason Wasser
Original code by: Rob VandenBrink
Inspiration
https://isc.sans.edu/forums/diary/Assessing+Remote+Certificates+with+Powershell/20645/
Modified: 1/9/2020 02:16:05 PM
Modified: 11/10/2020
    Updated help from source function of Save-NetCertificate
    Updated Verbiage in verbose statements for expired certificates
    Added CmdletBinding So that the verbose statements are useful
Modified: 11/12/2020
    Integrated newly created private function Get-Health
#>
function Get-NetCertificateHealth {
    [CmdletBinding()]
    Param (
        [Alias('IP')]
        $ComputerName,
        [int]$Port = 443
    )

    $NetCertificate = Get-NetCertificate -ComputerName $ComputerName -Port $Port
    $CertificateProperties = @{
        ComputerName       = $ComputerName + ':' + $Port
        FileName           = 'N/A'
        Subject            = $NetCertificate.Subject
        SignatureAlgorithm = $NetCertificate.SignatureAlgorithm.FriendlyName
        NotBefore          = $NetCertificate.NotBefore
        NotAfter           = $NetCertificate.NotAfter
        Days               = ($NetCertificate.NotAfter - (Get-Date)).Days
        Thumbprint         = $NetCertificate.Thumbprint
        KeySize            = $NetCertificate.PublicKey.Key.KeySize
    }
    $Certificate = New-Object -TypeName PSObject -Property $CertificateProperties

    #region Check certificate expiration

    #region Query new private function and populate the CertValidity variable
    $CertValidity = Get-Health -Certificate $Certificate
    #endregion

    Write-Verbose 'Adding additional properties to the certificate object.'
    $CertificateProperties = [ordered]@{
        ComputerName                = $ComputerName + ':' + $Port
        FileName                    = $Certificate.FileName
        Subject                     = $Certificate.Subject
        SignatureAlgorithm          = $Certificate.SignatureAlgorithm
        NotBefore                   = $Certificate.NotBefore
        NotAfter                    = $Certificate.NotAfter
        Days                        = $Certificate.Days
        Thumbprint                  = $Certificate.Thumbprint
        ValidityPeriodStatus        = $CertValidity.ValidityPeriodStatus
        ValidityPeriodStatusMessage = $CertValidity.ValidityPeriodStatusMessage
        AlgorithmStatus             = $CertValidity.AlgorithmStatus
        AlgorithmStatusMessage      = $CertValidity.AlgorithmStatusMessage
        KeySize                     = $Certificate.KeySize
        KeySizeStatus               = $CertValidity.KeySizeStatus
        KeySizeStatusMessage        = $CertValidity.KeySizeStatusMessage
    }
    $Certificate = New-Object -TypeName PSObject -Property $CertificateProperties
    $Certificate
}
