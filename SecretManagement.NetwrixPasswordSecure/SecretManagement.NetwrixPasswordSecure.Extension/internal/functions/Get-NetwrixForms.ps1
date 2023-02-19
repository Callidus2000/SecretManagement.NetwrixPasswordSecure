function Get-NetwrixForms {
    <#
    .SYNOPSIS
    Query all available forms from the server.

    .DESCRIPTION
    Query all available forms from the server as a HashTable.
    As keys the name attribute is used.

    .PARAMETER VaultName
    The name of the secret vault.

    .PARAMETER AdditionalParameters
    Additional parameters which where configured while creating the vault.

    .EXAMPLE
    Get-NetwrixForms -VaultName $VaultName -AdditionalParameters $AdditionalParameters

    Query the infos of all forms.

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
    $conMan = $psrApi.ContainerManager

    $formListFilter = $conMan.GetContainerListFilter([PsrApi.Data.Enums.PsrContainerType]::Form, $true) | Wait-Task

    $availableForms = $conMan.GetContainerList([PsrApi.Data.Enums.PsrContainerType]::Form, $formListFilter) | wait-task
    $formHash = @{}
    foreach ($form in $availableForms) {
        $name = $form.Name
        $formHash.$name = $form
    }
}