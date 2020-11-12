<#
.Synopsis
   Get certificates from the filesystem or certificate store and display their health
   for expiration, pending expiration, and deprecated signature algorithms.
.DESCRIPTION
   Get certificates from the filesystem or certificate store and display their health
   for expiration, pending expiration, and deprecated signature algorithms.

   The function outputs custom objects that include basic certificate properties as
   well as the certificate's expiration date, how many days are left, and the name of
   the signature algorithm used to generate the certificate.

   Depending on the provided warning and critical algorithm parameters, a certificate
   will be marked as OK, Warning, or Critical. By default the script considers sha1RSA
   certificates to be warning (deprecated) since vendors are beginning to consider these
   certificates to use weak encryption. The md5 signature algorithm has already been
   designated as vulnerable and will be marked as critical. Microsoft already blocks
   these certificates.

   The certificate validity period is evaluated to determine if the certificate has
   expired (Critical) or will be expiring soon. Use the WarningDays and CriticalDays
   parameters to denote certificates with pending expiration.

   The certificate key size is also an indicator of health. Key sizes less than
   1024 bits are no longer supported, and now it is recommended to use at least 2048 bits.

   Requires Get-CertificateFile function from module CertificateHealth to evaluate
   certificate files from the filesystem.
.NOTES
   Created by: Jason Wasser @wasserja
   Modified: 9/28/2016 02:43:52 PM

   Changelog:
   Version 1.4
    * Moved validity checks to Helper Function Get-Health
   Version 1.3.1
    * Added an example that utilizes the ComputerName parameter
    * Corrected verbiage for expired certificates in Verbose
   Version 1.3
    * Added support for remote computer check for cert:\ provider using PSRP.
   Version 1.2
    * Added key size health properties
   Version 1.1
    * Added PowerShell 2.0 compatibility.
   Version 1.0
    * Initial Release

.PARAMETER Path
   Enter a path or paths containing certificates to be checked.
   Checking of remote certificate files should be done through UNC path.
.PARAMETER ComputerName
   Enter a name of a computer to check the certificate store provider via PSRP.
.PARAMETER ExcludedThumbprint
   Array of thumbprints of certificates that should be excluded from being checked.
   This would be used if there is a certificate that you wish to ignore from health
   checks.
.PARAMETER CertUtilPath
   Path to the certutil.exe.
.PARAMETER CertificateFileType
   Array of certificate file types that need to be checked.
.PARAMETER Recurse
   Recurse through subdirectories of specified path(s).
.EXAMPLE
   Get-CertificateHealth

    FileName                    : Microsoft.PowerShell.Security\Certificate::LocalMachine\My\27AC9369FAF25207
                                  BB2627CEFACCBE4EF9C319B8
    Subject                     : CN=Go Daddy Secure Certificate Authority - G2,
                                  OU=http://certs.godaddy.com/repository/, O="GoDaddy.com, Inc.",
                                  L=Scottsdale, S=Arizona, C=US
    SignatureAlgorithm          : sha256RSA
    NotBefore                   : 5/3/2011 3:00:00 AM
    NotAfter                    : 5/3/2031 3:00:00 AM
    Days                        : 5329
    Thumbprint                  : 27AC9369FAF25207BB2627CEFACCBE4EF9C319B8
    ValidityPeriodStatus        : OK
    ValidityPeriodStatusMessage : Certificate expires in 5329 days.
    AlgorithmStatus             : OK
    AlgorithmStatusMessage      : Certificate uses valid algorithm sha256RSA.
    KeySize                     : 2048
    KeySizeStatus               : OK
    KeySizeStatusMessage        : Certificate key size 2048 is greater than or equal to 2048.

   Gets all the certificates in the local machine personal certificate store (cert:\LocalMachine\My)
   and shows their basic information and health.
.EXAMPLE
   Get-CertificateHealth -Path C:\Website\Certificates
   Gets all the certificates in the c:\Website\Certificates folder and shows their basic
   information and health.
.EXAMPLE
   Get-CertificateHealth -Path 'Cert:\LocalMachine\My','C:\SSL' -Recurse
   Gets all the certificates in the local machine personal certificate store (cert:\LocalMachine\My)
   and C:\SSL including subfolders and shows their basic information and health.
.EXAMPLE
   Get-CertificateHealth -ComputerName MyServer
   Gets all the certificates in MyServer's personal certificate store (Cert:\LocalMachine\My). This is accomplished using PSRemoting.
   It show the basic information and certificate health
.LINK
   https://gallery.technet.microsoft.com/scriptcenter/Certificate-Health-b646aeff
#>
#requires -Version 2.0
function Get-CertificateHealth
{
    [CmdletBinding()]
    Param
    (
        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [string[]]$Path = 'Cert:\LocalMachine\My',
        [string]$ComputerName,
        [string[]]$ExcludedThumbprint,#=@('DF16240B462E80151BBCD7529D4C557A8CE1671C'),
        [string]$CertUtilPath = 'C:\Windows\System32\certutil.exe',
        [string[]]$CertificateFileType = ('*.cer','*.crt','*.p7b'),
        [switch]$Recurse = $false
    )

    Begin
    {
    }
    Process
    {
        #region Certificate Check
        foreach ($CertPath in $Path) {
            # Gather certificates from the $CertPath
            # If we are looking in the Certificate PowerShell Provider - Cert:\
            if ($CertPath -like 'cert:\*') {
                # Remote or local
                # If computername was specified, try to use psremoting to get the certificates.
                if ($ComputerName) {

                    try {
                        Write-Verbose "Getting certificates from $CertPath from $ComputerName"
                        $Certificates = Invoke-Command -ScriptBlock {Get-ChildItem -Path $args[0] -Recurse:([bool]$args[1].IsPresent) -Exclude $args[2]} -ComputerName $ComputerName -ArgumentList $CertPath,$Recurse,$ExcludedThumbprint -ErrorAction Stop
                        }
                    catch {
                        Write-Error "Unable to connect to $ComputerName"
                        return
                        }
                    }
                # If computername was not specified, then get from local certificate store provider.
                else {
                    Write-Verbose "Getting certificates from $CertPath"
                    $Certificates = Get-ChildItem -Path $CertPath -Recurse:([bool]$Recurse.IsPresent) -Exclude $ExcludedThumbprint
                    $ComputerName = $env:COMPUTERNAME
                    }
                }
            # Otherwise we need to use the certutil.exe to get certificate information.
            else {
                Write-Verbose "Getting certificates from $CertPath"
                $Certificates = Get-CertificateFile -Path $CertPath -CertificateFileType $CertificateFileType -Recurse:([bool]$Recurse.IsPresent) | Where-Object -FilterScript {$_.Thumbprint -notcontains $ExcludedThumbprint}
                }
            if ($Certificates) {
                #region Check individual certificate
                foreach ($Certificate in $Certificates) {

                    # I first need to convert the properties so that I can use a similar process on either file or store certificates.

                    if ($Certificate.PSPath) {
                            if ($PSVersionTable.PSVersion.Major -lt 3) {
                                $CertificateProperties = @{
                                    ComputerName = $ComputerName
                                    FileName = $Certificate.PSPath
                                    Subject = $Certificate.Subject
                                    SignatureAlgorithm = $Certificate.SignatureAlgorithm.FriendlyName
                                    NotBefore = $Certificate.NotBefore
                                    NotAfter = $Certificate.NotAfter
                                    Days = ($Certificate.NotAfter - (Get-Date)).Days
                                    Thumbprint = $Certificate.Thumbprint
                                    KeySize = $Certificate.PublicKey.Key.KeySize
                                    }
                                }
                            else {
                                $CertificateProperties = [ordered]@{
                                    ComputerName = $ComputerName
                                    FileName = $Certificate.PSPath
                                    Subject = $Certificate.Subject
                                    SignatureAlgorithm = $Certificate.SignatureAlgorithm.FriendlyName
                                    NotBefore = $Certificate.NotBefore
                                    NotAfter = $Certificate.NotAfter
                                    Days = ($Certificate.NotAfter - (Get-Date)).Days
                                    Thumbprint = $Certificate.Thumbprint
                                    KeySize = $Certificate.PublicKey.Key.KeySize
                                    }
                                }
                            $Certificate = New-Object -TypeName PSObject -Property $CertificateProperties
                            }
                        elseif ($Certificate.FileName) {
                            # Nothing to do here yet.
                            }
                        else {
                            # Nothing to do here yet.
                            }
                    #region Check certificate expiration

                    #region Query new private function and populate the CertValidity variable
                    $CertValidity = Get-Health -Certificate $Certificate
                    #endregion

                    Write-Verbose 'Adding additional properties to the certificate object.'
                    if ($PSVersionTable.PSVersion.Major -lt 3) {
                        $CertificateProperties = @{
                            ComputerName = $ComputerName
                            FileName = $Certificate.Filename
                            Subject = $Certificate.Subject
                            SignatureAlgorithm = $Certificate.SignatureAlgorithm
                            NotBefore = $Certificate.NotBefore
                            NotAfter = $Certificate.NotAfter
                            Days = $Certificate.Days
                            Thumbprint = $Certificate.Thumbprint
                            ValidityPeriodStatus = $CertValidity.ValidityPeriodStatus
                            ValidityPeriodStatusMessage = $CertValidity.ValidityPeriodStatusMessage
                            AlgorithmStatus = $CertValidity.AlgorithmStatus
                            AlgorithmStatusMessage = $CertValidity.AlgorithmStatusMessage
                            KeySize = $Certificate.KeySize
                            KeySizeStatus = $CertValidity.KeySizeStatus
                            KeySizeStatusMessage = $CertValidity.KeySizeStatusMessage
                            }
                        }
                    else {
                        $CertificateProperties = [ordered]@{
                            ComputerName = $ComputerName
                            FileName = $Certificate.Filename
                            Subject = $Certificate.Subject
                            SignatureAlgorithm = $Certificate.SignatureAlgorithm
                            NotBefore = $Certificate.NotBefore
                            NotAfter = $Certificate.NotAfter
                            Days = $Certificate.Days
                            Thumbprint = $Certificate.Thumbprint
                            ValidityPeriodStatus = $CertValidity.ValidityPeriodStatus
                            ValidityPeriodStatusMessage = $CertValidity.ValidityPeriodStatusMessage
                            AlgorithmStatus = $CertValidity.AlgorithmStatus
                            AlgorithmStatusMessage = $CertValidity.AlgorithmStatusMessage
                            KeySize = $Certificate.KeySize
                            KeySizeStatus = $CertValidity.KeySizeStatus
                            KeySizeStatusMessage = $CertValidity.KeySizeStatusMessage
                            }
                        }

                    $Certificate = New-Object -TypeName PSObject -Property $CertificateProperties
                    if ($PSVersionTable.PSVersion.Major -lt 3) {
                        $Certificate | Select-Object ComputerName,FileName,Subject,SignatureAlgorithm,NotBefore,NotAfter,Days,Thumbprint,ValidityPeriodStatus,ValidityPeriodStatusMessage,AlgorithmStatus,AlgorithmStatusMessage,KeySize,KeySizeStatus,KeySizeStatusMessage
                        }
                    else {
                        $Certificate
                        }
                    }
                #endregion
                }
            else {
                Write-Verbose "No Certificates found in $CertPath"
                }
            }
        #endregion
    }
    End
    {
    }
}
