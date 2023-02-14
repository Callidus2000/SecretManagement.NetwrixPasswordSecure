function Get-SecretInfo {
    [CmdletBinding()]
    param (
        [string] $Filter,
        [string] $VaultName,
        [hashtable] $AdditionalParameters
    )
    $AdditionalParameters = @{} + $AdditionalParameters
    if ($AdditionalParameters.Verbose) { $VerbosePreference = 'continue' }

    Write-PSFMessage "Get-SecretInfo, Filter=$Filter, $VaultName, AdditionalParameters=$($AdditionalParameters|ConvertTo-Json -Compress)"
    return Get-NetwrixContainer -Filter $Filter -VaultName $VaultName -AdditionalParameters $AdditionalParameters -ReturnType SecretInformation

    # if (-not (Test-SecretVault -VaultName $vaultName -AdditionalParameters $AdditionalParameters)) {
    #     Write-PSFMessage -Level Error "${vaultName}: Failed to unlock the vault"
    #     return $false
    # }
    # $psrApi = (Get-Variable -Name "Vault_$VaultName" -Scope Script -ErrorAction Stop).Value

    # $conMan = $psrApi.ContainerManager
    # # Get a new filter
    # $passwordListFilter = $conMan.GetContainerListFilter([PsrApi.Data.Enums.PsrContainerType]::Password, $true) | Wait-Task
    # # Nach Inhalt filtern
    # $contentFilter = $passwordListFilter.FilterGroups | Where-Object __type -eq 'ListFilterGroupContent'
    # if ($contentFilter ) {
    #     $contentFilter.SearchList[0].Search = $filter;
    #     $contentFilter.SearchList[0].FilterActive = $true;
    # }

    # $SecretInformation = $conMan.GetContainerList([PsrApi.Data.Enums.PsrContainerType]::Password, $passwordListFilter, $null) | Wait-Task | Convert-NetwrixContainer2Object -ContainerManager $conMan -AsSecretInformation
    # Write-PSFMessage "Found $($SecretInformation.Count) Password containers for filter $filter"
    # return $SecretInformation
}

