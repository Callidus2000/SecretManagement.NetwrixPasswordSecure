function Get-NetwrixContainer {
    [CmdletBinding()]
    param (
        [string] $Filter,
        [string] $VaultName,
        [hashtable] $AdditionalParameters,
        [ValidateSet('SecretInformation', 'NonModifiedContainer', 'Credential', 'MetaHash')]
        [string]$ReturnType
    )
    $AdditionalParameters = @{} + $AdditionalParameters

    Write-PSFMessage "Get-NetwrixContainer, Filter=$Filter, $VaultName, AdditionalParameters=$($AdditionalParameters|ConvertTo-Json -Compress), ReturnType=$ReturnType"

    if (-not (Test-SecretVault -VaultName $vaultName -AdditionalParameters $AdditionalParameters)) {
        Write-PSFMessage -Level Error "${vaultName}: Failed to unlock the vault"
        return $false
    }
    $psrApi = (Get-Variable -Name "Vault_$VaultName" -Scope Script -ErrorAction Stop).Value

    $conMan = $psrApi.ContainerManager
    if ($filter -match ("^(\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}$")) {
        Write-PSFMessage "Query specific container GUID"
        $containers = $conMan.GetContainer($Filter) | Wait-Task
        Write-PSFMessage "Type: $($containers.GetType()), correct one: $($containers -is [PsrApi.Data.PsrContainer])"
    }
    else {
        # Get a new filter
        $passwordListFilter = $conMan.GetContainerListFilter([PsrApi.Data.Enums.PsrContainerType]::Password, $true) | Wait-Task
        # Nach Inhalt filtern
        $contentFilter = $passwordListFilter.FilterGroups | Where-Object __type -eq 'ListFilterGroupContent'
        if ($contentFilter ) {
            $contentFilter.SearchList[0].Search = $filter
            $contentFilter.SearchList[0].FilterActive = $true
        }

        $containers = $conMan.GetContainerList([PsrApi.Data.Enums.PsrContainerType]::Password, $passwordListFilter, $null) | Wait-Task | Where-Object { $_.Info.ContainerName -like $filter }
    }
    Write-PSFMessage "Found $($containers.Count) Password containers for filter $filter"
    switch ($ReturnType) {
        'SecretInformation' {
            Write-PSFMessage "Converting results to type SecretInformation"
            $results = $containers | Convert-NetwrixContainer2Object -ContainerManager $conMan -AsSecretInformation -Verbose
            Write-PSFMessage "`$results= $($results), Type $($results.GetType())"
            return $results
        }
        'NonModifiedContainer' { $containers }
        'Credential' { $containers | Convert-NetwrixContainer2Object -ContainerManager $conMan -IncludeCredential | Select-Object -ExpandProperty Credential }
        'MetaHash' { $containers | Convert-NetwrixContainer2Object -ContainerManager $conMan }
    }
}