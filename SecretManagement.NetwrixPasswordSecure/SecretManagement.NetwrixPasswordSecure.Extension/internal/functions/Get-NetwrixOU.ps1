function Get-NetwrixOU {
    <#
    .SYNOPSIS
    Query all organisational units from the server.

    .DESCRIPTION
    Query all organisational units from the server as a HashTable.
    As keys for Group-OUs the .OrganisationUnit.GroupName and for User-OUs
    the .OrganisationUnit.UserName attribute is used.

    .PARAMETER VaultName
    The name of the secret vault.

    .PARAMETER AdditionalParameters
    Additional parameters which where configured while creating the vault.

    .EXAMPLE
    Get-NetwrixOU -VaultName $VaultName -AdditionalParameters $AdditionalParameters

    Query all OUs

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '')]
    param (
        [string] $VaultName,
        [hashtable] $AdditionalParameters
    )
    $AdditionalParameters = @{} + $AdditionalParameters

    Write-PSFMessage "Get-NetwrixContainer, Filter=$Filter, $VaultName, AdditionalParameters=$($AdditionalParameters|ConvertTo-Json -Compress), ReturnType=$ReturnType"

    if (-not (Test-SecretVault -VaultName $vaultName -AdditionalParameters $AdditionalParameters)) {
        Write-PSFMessage -Level Error "${vaultName}: Failed to unlock the vault"
        return $false
    }
    $psrApi = (Get-Variable -Name "Vault_$VaultName" -Scope Script -ErrorAction Stop).Value

    $ouMan = $psrApi.OrganisationUnitManager
    $ouFilter = [PsrApi.Data.PsrListFilter]::new()
    $ouFilter.DataStates = [PsrApi.Data.Enums.PsrDataStates]::StateActive
    $ouGroups = $ouMan.GetOrganisationUnitStructure($ouFilter) | Wait-Task
    $ouHash = @{}
    foreach ($ou in $ouGroups) {
        switch ($ou.OrganisationUnit."__type") {
            MtoOrganisationUnitUser { $name = $ou.OrganisationUnit.UserName }
            MtoOrganisationUnitGroup { $name = $ou.OrganisationUnit.GroupName }
        }
        $ouHash.$name = $ou
    }
}