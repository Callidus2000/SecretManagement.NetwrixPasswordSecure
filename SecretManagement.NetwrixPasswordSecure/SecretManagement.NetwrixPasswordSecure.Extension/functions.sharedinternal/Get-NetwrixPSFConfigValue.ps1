function Get-NetwrixPSFConfigValue {
    <#
    .SYNOPSIS
    A helper to simplify the query of PSFConfig values.

    .DESCRIPTION
    A helper to simplify the query of PSFConfig values.

    .PARAMETER VaultName
    The name of the secret vault.

    .PARAMETER AdditionalParameters
    Additional parameters which where configured while creating the vault.

    .PARAMETER SubPath
    The Sub-Path/-Key to be set.

    .PARAMETER Scope
    Does the setting belong to the Server/Database combo or to the configured vault?
    Defaults to 'Vault'

    .EXAMPLE
    Get-NetwrixPSFConfigValue -VaultName $VaultName -AdditionalParameters $AdditionalParameters -SubPath FormMapping

    Queries the formmapping config

    .NOTES
    The used configname is built by
    "SecretManagement.NetwrixPasswordSecure.Extension.$($AdditionalParameters.server -replace '\.','_').$($AdditionalParameters.Database).$SubPath"
    #>
    [CmdletBinding()]
    param (
        [string]$VaultName,
        [hashtable]$AdditionalParameters,
        [String]$SubPath,
        [ValidateSet('ServerDB','Vault')]
        $Scope='Vault'
    )
    switch($Scope){
        'ServerDB'{
            if ($null -eq $AdditionalParameters) { throw "`$AdditionalParameters param missing"}
            $AdditionalParameters = @{} + $AdditionalParameters
            $configName = "SecretManagement.NetwrixPasswordSecure.Extension.$($AdditionalParameters.server -replace '\.','_').$($AdditionalParameters.Database).$SubPath"
        }
        'Vault'   {
            $configName = "SecretManagement.NetwrixPasswordSecure.Extension.Vaults.$VaultName.$SubPath"
        }
    }

    Write-PSFMessage "Query PSFConfig $configName"
    $value = Get-PSFConfigValue -FullName $configName
    if(-not $value){Write-PSFMessage "No value found"}
    return $value
}