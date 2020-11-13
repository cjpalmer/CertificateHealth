function Get-ProtocolName {
    <#
    .SYNOPSIS
        Translates provided protocol to the protocol name as represented in the registry
    .DESCRIPTION
        Translates provided protocol to the protocol name as represented in the registry
    .EXAMPLE
        PS C:\> Get-ProtocolName -Protocol 'TLS1.2'
        Translates 'TLS1.2' to 'TLS 1.2'
    .NOTES
        Moved out fo Get-SchannelProtocol and Set-SchannelProtocol to make future updates and testing easier
    #>
    [CmdletBinding()]
    param (
        [string]$Protocol
    )
    begin {
        Write-Verbose -Message "PGPN:Translating $Protocol to ProtocolName"
    }
    process {
        switch ($Protocol) {
            'SSL2' {
                $ProtocolName = 'SSL 2.0'
            }
            'SSL3' {
                $ProtocolName = 'SSL 3.0'
            }
            'TLS1.0' {
                $ProtocolName = 'TLS 1.0'
            }
            'TLS1.1' {
                $ProtocolName = 'TLS 1.1'
            }
            'TLS1.2' {
                $ProtocolName = 'TLS 1.2'
            }
            'TLS1.3' {
                $ProtocolName = 'TLS 1.3'
            }
        }
        Write-Verbose -Message "PGPN:ProtocolName: $ProtocolName"
        $ProtocolName
    }
    end {}
}
