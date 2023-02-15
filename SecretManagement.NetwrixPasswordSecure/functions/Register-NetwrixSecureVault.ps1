function Register-NetwrixSecureVault {
    <#
    .SYNOPSIS
    Registers a new Secretvault.

    .DESCRIPTION
    Registers a new Secretvault.

    .PARAMETER VaultName
    The name of the vault.

    .PARAMETER Server
    The hostname of the server which provides the service.

    .PARAMETER Port
    On which port is the server listening? Defaults to 11016.

    .PARAMETER Database
    The name of the Database.

    .PARAMETER UserName
    The username which is used to connect to the server. Has to be specified on vault level as Unlock-SecretVault only accepts a password instead credentials.

    .EXAMPLE
    Register-NetwrixSecureVault -VaultName myVault -Server myserver -Database PWDB -UserName fred

    Registers the given vault.

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$VaultName,
        [Parameter(Mandatory)]
        [string]$Server,
        [string]$Port="11016",
        [Parameter(Mandatory)]
        [string]$Database,
        [Parameter(Mandatory)]
        [string]$UserName
    )
    $myModulePath = "$ModuleRoot\SecretManagement.NetwrixPasswordSecure.psd1"
    $psdData=Import-PowerShellDataFile $myModulePath
    $additionalParameter = $PSBoundParameters | ConvertTo-PSFHashtable -Include "database","port","userName" ,"server" -Inherit
    $additionalParameter.version=$psdData.ModuleVersion
    Write-PSFMessage "Registering Vault $vault with Param $($additionalParameter|ConvertTo-Json -Compress) and Module $myModulePath, Version $($psdData.ModuleVersion)"
    Register-SecretVault -Name $vaultName -ModuleName $myModulePath -VaultParameters $additionalParameter
}