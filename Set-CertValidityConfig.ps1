function Set-CertValidityConfig {
    [CmdletBinding()]
    param (
        [Parameter(Position=0)]
        $CertValidityConfigPath = ("$($PSScriptRoot)\CertValidityConfig.json").Replace('Public\', ''),

        [int]$WarningDays,

        [int]$CriticalDays,

        [string[]]$WarningAlgorithm,

        [string[]]$CriticalAlgorithm,

        [int]$CriticalKeySize,

        [int]$WarningKeySize,

        [int[]]$CommonPorts
    )

    begin {
        $config = Get-CertValidityCOnfig -ConfigurationFile $CertValidityConfigPath
    }

    process {
        Switch($PSBoundParameters.Keys) {
            'WarningDays' {
                $config.WarningDays = $WarningDays
            }
            'CriticalDays' {
                $config.CriticalDays = $CriticalDays
            }
            'WarningAlgorithm' {
                $config.WarningAlgorithm = $WarningAlgorithm
            }
            'CriticalAlgorithm' {
                $config.CriticalAlgorithm = $CriticalAlgorithm
            }
            'CriticalKeySize' {
                $config.CriticalKeySize = $CriticalKeySize
            }
            'WarningKeySize' {
                $config.WarningKeySize = $WarningKeySize
            }
            'CommonPorts' {
                $config.CommonPorts = $CommonPorts
            }
        }
    }

    end {
        $config | ConvertTo-Json | Set-Content $CertValidityConfigPath
    }
}
