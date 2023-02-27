function Get-NetwrixForm {
    <#
    .SYNOPSIS
    Query all available forms from the server.

    .DESCRIPTION
    Query all available forms from the server as a HashTable.
    As keys the name attribute is used.

    .PARAMETER ExistingConnection
    The existing connection

    .EXAMPLE
    Get-NetwrixForm -VaultName $VaultName -AdditionalParameters $AdditionalParameters

    Query the infos of all forms.

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '')]
    param (
        [parameter(mandatory = $true, ParameterSetName = "alreadyConnected")]
        [PsrApi.PsrApi]$ExistingConnection,
        $Name
    )

    Write-PSFMessage "Get-NetwrixForm"

    $conMan = $ExistingConnection.ContainerManager

    $formListFilter = $conMan.GetContainerListFilter([PsrApi.Data.Enums.PsrContainerType]::Form, $true) | Wait-Task

    $availableForms = $conMan.GetContainerList([PsrApi.Data.Enums.PsrContainerType]::Form, $formListFilter) | wait-task
    $formHash = @{}
    foreach ($form in $availableForms) {
        $name = $form.Name
        $formHash.$name = $form
    }
    if ($Name){return $formHash.$Name}
    return $formHash
}