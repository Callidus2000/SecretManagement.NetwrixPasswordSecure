function Get-NetwrixOU {
    <#
    .SYNOPSIS
    Query all organisational units from the server.

    .DESCRIPTION
    Query all organisational units from the server as a HashTable.
    As keys for Group-OUs the .OrganisationUnit.GroupName and for User-OUs
    the .OrganisationUnit.UserName attribute is used.

    .PARAMETER ExistingConnection
    The existing connection

    .EXAMPLE
    Get-NetwrixOU -VaultName $VaultName -AdditionalParameters $AdditionalParameters

    Query all OUs

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '')]
    param (
        [parameter(mandatory = $true, ParameterSetName = "alreadyConnected")]
        [PsrApi.PsrApi]$ExistingConnection
    )
    Write-PSFMessage "Query all existing Organizational Units"
    $ouMan = $ExistingConnection.OrganisationUnitManager
    $ouFilter = [PsrApi.Data.PsrListFilter]::new()
    $ouFilter.DataStates = [PsrApi.Data.Enums.PsrDataStates]::StateActive
    $ouGroups = $ouMan.GetOrganisationUnitStructure($ouFilter) | Wait-Task
    Write-PSFMessage "`$ouGroups=$($ouGroups|ConvertTo-Json -Compress -Depth 5)"
    $ouHash = @{}
    foreach ($ou in $ouGroups) {
        switch ($ou.OrganisationUnit."__type") {
            MtoOrganisationUnitUser { $name = $ou.OrganisationUnit.UserName }
            MtoOrganisationUnitGroup { $name = $ou.OrganisationUnit.GroupName }
        }
        $ouHash.$name = $ou
    }
}