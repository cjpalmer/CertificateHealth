<#
.Synopsis
Test local listening ports for certificate health.
.DESCRIPTION
Test local listening ports for certificate health.
Enumerate a list of local listening ports and then validate the certificate health.
.PARAMETER Ports
The Ports parameter is defaulted to a list of popular server ports.
.EXAMPLE
Test-LocalNetPortCertificate
.EXAMPLE
Test-LocalNetPortCertificate -Ports 80,443,3389
.NOTES
Created by: Jason Wasser
Modified: 1/9/2020 02:16:05 PM
Todo:
* Need to verify if this supports server name indication (SNI) for certificates
Modified: 11/13/2020
* Added verbosity
* Started using CertValidityConfiguration global variable for common ports
#>
function Test-LocalNetPortCertificate {
    [CmdletBinding()]
    param (
        $Ports = $CertValidityConfiguration.CommonPorts #@(22,25,443,465,587,636,993,995,3389)
    )
    Write-Verbose -Message "TLNPC:Common Ports: $Ports"
    $ListeningPorts = Get-ListeningPort -Ports $Ports
    foreach ($Port in $ListeningPorts) {
        Write-Verbose -Message "TLNPC:Checking for common listening port: $Port"
        if ($Port.LocalAddress -eq '0.0.0.0') {
            Get-NetCertificateHealth -ComputerName 127.0.0.1 -Port $Port.LocalPort
        }
        else {
            Get-NetCertificateHealth -ComputerName $Port.LocalAddress -Port $Port.LocalPort
        }
    }
}
