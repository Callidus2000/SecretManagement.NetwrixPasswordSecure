function Register-NetwrixSecureVault {
    [CmdletBinding()]
    param (
        [string]$VaultName,
        [string]$Hostname,
        [string]$Port="11016",
        [string]$Database,
        [string]$UserName,

        #Don't validate the vault operation upon registration. This is useful for pre-staging
        #vaults or vault configurations in deployments.
        [Parameter(ParameterSetName = 'SkipValidate')][Switch]$SkipValidate,
        [switch]$AllowClobber
    )

    begin {

    }

    process {

    }

    end {

    }
}