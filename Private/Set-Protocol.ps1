function Set-Protocol {
    [cmdletbinding()]
    param (
        [ValidateSet('SSL2', 'SSL3', 'TLS1.0', 'TLS1.1', 'TLS1.2', 'TLS1.3')]
        [string]$Protocol,
        [ValidateSet('Client', 'Server')]
        [string]$Mode,
        [ValidateSet('Enabled', 'DisabledByDefault')]
        [string]$Setting,
        [ValidateSet(0, 1)]
        [int]$Value,
        [string]$RegistryPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols'
    )
    begin {
        $ProtocolName = Get-ProtocolName -Protocol $Protocol
    }
    process {
        try {
            Write-Verbose "PSP:Setting $Setting for Protocol $Protocol $Mode at $RegistryPath\$ProtocolName\$Mode to $Value"
            Set-ItemProperty -Path "$RegistryPath\$ProtocolName\$Mode" -Name $Setting -Value $Value -ErrorAction Stop | Out-Null
        } catch [System.Exception] {
            switch ($_.Exception.GetType().FullName) {
                'System.Management.Automation.ItemNotFoundException' {
                    Write-Verbose "PSP:Unable to set protocol status value at $RegistryPath\$ProtocolName\$Mode"
                }
                default {
                    Write-Verbose "PSP:Unknown error"
                }
            }
        }
    }
    end {}
}
