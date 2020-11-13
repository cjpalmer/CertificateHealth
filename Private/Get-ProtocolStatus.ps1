function Get-ProtocolStatus {
    <#
    .SYNOPSIS
        Queries supplied registry path for existing status
    .DESCRIPTION
        Queries supplied registry path for existing status
        Specifically built for checking registry paths specific to SChannel parameters
        This could be expanded to additional paths at a future time
    .EXAMPLE
        PS C:\> Get-ProtocolStatus -Mode Server -StatusCheck -Enabled -RegistryPath $RegistryPath -Protocol TLS1.2
        Checks TLS1.2 registry location for current setting and returns the status as $true, $false, 'Not Set', or 'Unknown'
    .NOTES
        Moved out of Get-SchannelProtocol to make future updates and testing easier
    #>
    [CmdletBinding()]
    param (
        [ValidateSet('Client', 'Server')]
        [string]$Mode,
        [ValidateSet('Enabled', 'DisabledByDefault')]
        [string]$StatusCheck,
        [string]$RegistryPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols',
        [string]$Protocol
    )

    begin {
        $ProtocolName = Get-ProtocolName -Protocol $Protocol
    }
    process {
        try {
            Write-Verbose "PGPS:Checking Protocol $Protocol $Mode at $RegistryPath\$ProtocolName\$Mode"
            $ProtocolStatusRegValue = Get-ItemProperty -Path "$RegistryPath\$ProtocolName\$Mode" -ErrorAction Stop

            if ($ProtocolStatusRegValue.$StatusCheck -eq 1) {
                Write-Verbose "PGPS:Protocol Status Registry Value for $StatusCheck is $($ProtocolStatusRegValue.$StatusCheck)"
                $ProtocolStatus = $true
            } elseif ($ProtocolStatusRegValue.$StatusCheck -eq 0) {
                Write-Verbose "PGPS:Protocol Status Registry Value for $StatusCheck is $($ProtocolStatusRegValue.$StatusCheck)"
                $ProtocolStatus = $false
            } else {
                Write-Verbose "PGPS:Protocol Status Registry Value for $StatusCheck is not present."
                $ProtocolStatus = 'Not Set'
            }
        } catch [System.Exception] {
            switch ($_.Exception.GetType().FullName) {
                'System.Management.Automation.ItemNotFoundException' {
                    Write-Verbose "PGPS:Unable to find protocol status value at $RegistryPath\$ProtocolName\$Mode"
                    $ProtocolStatus = 'Not Set'
                }
                default {
                    Write-Verbose "PGPS:Unknown error"
                    $ProtocolStatus = 'Unknown'
                }
            }
        }
        $ProtocolStatus
    }
    end {}
}
