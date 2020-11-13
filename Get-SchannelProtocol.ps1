<#
.Synopsis
Get the SSL and TLS protocol Schannel settings from the registry.
.DESCRIPTION
Get the SSL and TLS protocol Schannel settings from the registry including
client and server components.
.PARAMETER Protocol
Specify the protocol you want to query.
.PARAMETER CommunicationMode
Specify the communication mode: server/client.
.EXAMPLE
Get-SchannelProtocol

Protocol DisabledByDefault Enabled CommunicationMode
-------- ----------------- ------- -----------------
SSL2                  True   False Client
SSL2                  True   False Server
SSL3                  True   False Client
SSL3                  True   False Server
TLS1.0                True   False Client
TLS1.0                True   False Server
TLS1.1                True   False Client
TLS1.1                True   False Server
TLS1.2               False    True Client
TLS1.2               False    True Server
TLS1.3             Not Set Not Set Client
TLS1.3             Not Set Not Set Server
.EXAMPLE
Get-SchannelProtocol -Protocol TLS1.2 -CommunicationMode Server

Protocol DisabledByDefault Enabled CommunicationMode
-------- ----------------- ------- -----------------
TLS1.2               False    True Server
.NOTES
Created by: Jason Wasser
Modified: 4/3/2020
Modified: 11/13/2020
* Moved Get-ProtocolStatus from Begin block to private function
* Moved switch statement to translate protocol to protocol name to private function called by Get-ProtocolStatus
* Updated calls to Get-ProtocolStatus to pass all necessary parameters
#>
function Get-SchannelProtocol {
    [cmdletbinding()]
    param (
        [ValidateSet('SSL2', 'SSL3', 'TLS1.0', 'TLS1.1', 'TLS1.2', 'TLS1.3')]
        [string[]]$Protocol = ('SSL2', 'SSL3', 'TLS1.0', 'TLS1.1', 'TLS1.2', 'TLS1.3'),
        [ValidateSet('Client', 'Server')]
        [string[]]$CommunicationMode = ('Client', 'Server')
    )
    begin {
        $SCHANNELProtocolsRegistryPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols'
    }
    process {
        foreach ($Proto in $Protocol) {
            foreach ($Mode in $CommunicationMode) {
                Write-Verbose "Checking Protocol and Mode : $Proto $Mode"
                $DisabledByDefault = Get-ProtocolStatus -Mode $Mode -StatusCheck DisabledByDefault -RegistryPath $SCHANNELProtocolsRegistryPath -Protocol $Proto
                $Enabled = Get-ProtocolStatus -Mode $Mode -StatusCheck Enabled -RegistryPath $SCHANNELProtocolsRegistryPath -Protocol $Proto

                $SchannelProtocolProperties = @{
                    Protocol          = $Proto
                    CommunicationMode = $Mode
                    DisabledByDefault = $DisabledByDefault
                    Enabled           = $Enabled
                }
                $SchannelProtocol = New-Object -TypeName PSCustomObject -Property $SchannelProtocolProperties
                if ($PSVersionTable.PSVersion.Major -lt 3) {
                    $SchannelProtocol | Select-Object -Property Protocol, CommunicationMode, Enabled, DisabledByDefault
                }
                else {
                    $SchannelProtocol
                }
            }
        }
    }
    end { }
}
