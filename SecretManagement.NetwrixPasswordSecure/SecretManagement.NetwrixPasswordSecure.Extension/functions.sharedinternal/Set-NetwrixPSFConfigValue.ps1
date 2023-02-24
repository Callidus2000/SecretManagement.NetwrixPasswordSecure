function Set-NetwrixPSFConfigValue {
    <#
    .SYNOPSIS
    A helper to simplify the setting of PSFConfig values.

    .DESCRIPTION
    A helper to simplify the setting of PSFConfig values.

    .PARAMETER AdditionalParameters
    Additional parameters which where configured while creating the vault.

    .PARAMETER SubPath
    The Sub-Path/-Key to be set.

    .PARAMETER Value
    The value to be initialized

    .PARAMETER Initialize
    If used only uninitialized settings will be saved (aka no overwrite)

    .PARAMETER VaultName
    The name of the secret vault.

    .PARAMETER Scope
    Does the setting belong to the Server/Database combo or to the configured vault?
    Defaults to 'Vault'

    .EXAMPLE
    Set-NetwrixPSFConfigValue -VaultName $VaultName -AdditionalParameters $AdditionalParameters -SubPath FormMapping -Value $mapping

    Sets the formmapping config to $mapping

    .NOTES
    The used configname is built by
    "SecretManagement.NetwrixPasswordSecure.Extension.$($AdditionalParameters.server -replace '\.','_').$($AdditionalParameters.Database).$SubPath"
    #>
    [CmdletBinding()]
    param (
        [string]$VaultName,
        [hashtable]$AdditionalParameters,
        [String]$SubPath,
        $Value,
        [ValidateSet('ServerDB', 'Vault')]
        $Scope = 'Vault',
        [switch]$Initialize
    )
    $confParam=@{
        Module      = "SecretManagement.NetwrixPasswordSecure.Extension"
        AllowDelete=$true
        Initialize=$Initialize
        Value=$Value
    }
    switch ($Scope) {
        'ServerDB' {
            if ($null -eq $AdditionalParameters) { throw "`$AdditionalParameters param missing" }
            $AdditionalParameters = @{} + $AdditionalParameters
            $confParam.name = "$($AdditionalParameters.server -replace '\.','_').$($AdditionalParameters.Database).$SubPath"
        }
        'Vault' {
            $confParam.name = "Vaults.$VaultName.$SubPath"
        }
    }
    Write-PSFMessage "Saving PSFConfig: $($confParam|ConvertTo-Json -Compress -Depth 2)"
    Set-PSFConfig @confParam
}