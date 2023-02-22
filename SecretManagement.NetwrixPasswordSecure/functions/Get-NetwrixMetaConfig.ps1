function Get-NetwrixMetaConfig {
    <#
    .SYNOPSIS
    Registers a new Secretvault.

    .DESCRIPTION
    Registers a new Secretvault.

    .PARAMETER Server
    The hostname of the server which provides the service.

    .PARAMETER Port
    On which port is the server listening? Defaults to 11016.

    .PARAMETER Database
    The name of the Database.

    .PARAMETER Credential
    The username/password which is used to connect to the server.

    .PARAMETER ExistingConnection
    Allows the usage from internal functions which have access to an existing connection ([PsrApi.PsrApi] object)

    .EXAMPLE
    Register-NetwrixSecureVault -VaultName myVault -Server myserver -Database PWDB -UserName fred

    Registers the given vault.

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    [OutputType([HashTable])]
    param (
        [parameter(mandatory = $true, ParameterSetName = "directConnection")]
        [string]$Server,
        [parameter(mandatory = $false, ParameterSetName = "directConnection")]
        [string]$Port = "11016",
        [parameter(mandatory = $true, ParameterSetName = "directConnection")]
        [string]$Database,
        [parameter(mandatory = $true, ParameterSetName = "directConnection")]
        [pscredential]$Credential,
        [parameter(mandatory = $true, ParameterSetName = "alreadyConnected")]
        [PsrApi.PsrApi]$ExistingConnection
    )
    Write-PSFMessage "Query Meta Structure ob Password Safe"
    switch ($PSCmdlet.ParameterSetName) {
        "directConnection" {
            $global:psrApi = [PsrApi.PsrApi]::new("$($Server):$($Port)")
            $psrApi.authenticationManager.login($Database, $Credential.UserName, $Credential.GetNetworkCredential().password) | Wait-Task -Debug
        }
        "alreadyConnected" { $psrApi = $ExistingConnection }
    }
    $metaStructure = @{
        organisationalUnits = @{}
        availableForms      = @()
        formStructure       = @{}
        formMapping         = @{}
    }

    # Query all existing OUs
    $ouMan = $psrApi.OrganisationUnitManager
    $ouFilter = [PsrApi.Data.PsrListFilter]::new()
    $ouFilter.DataStates = [PsrApi.Data.Enums.PsrDataStates]::StateActive
    $ouGroups = $ouMan.GetOrganisationUnitStructure($ouFilter) | Wait-Task | Select-Object -ExpandProperty OrganisationUnit
    foreach ($ou in $ouGroups) {
        $ou.publicKey = $null
        $ouHash = $ou | ConvertTo-PSFHashtable -Include @( 'id', '__type', 'Description') -Remap @{"__type" = 'type' }
        switch ($ou."__type") {
            MtoOrganisationUnitUser { $ouHash.name = $ou.UserName }
            MtoOrganisationUnitGroup { $ouHash.name = $ou.GroupName }
        }
        Write-PSFMessage "OU= $($ou|ConvertTo-Json)" -Level Debug
        if ($ou.ParentDataBindings) {
            $ouHash.parentId = $ou.ParentDataBindings.ParentDataId
        }
        $metaStructure.organisationalUnits."$($ouHash.name)" = $ouHash
    }

    # Query all existing forms
    $conMan = $psrApi.ContainerManager

    $formListFilter = $conMan.GetContainerListFilter([PsrApi.Data.Enums.PsrContainerType]::Form, $true) | Wait-Task

    $availableForms = $conMan.GetContainerList([PsrApi.Data.Enums.PsrContainerType]::Form, $formListFilter) | wait-task
    foreach ($form in $availableForms) {
        $formHash = $form | ConvertTo-PSFHashtable -Include @( 'name', 'id', '__type', 'Description') -Remap @{"__type" = 'type' }
        $formHash.fields = $form.items | ConvertTo-PSFHashtable -Include @( 'name', 'id', 'ContainerItemType', 'Description', "Mandatory") -Remap @{"ContainerItemType" = 'type' }
        $formHash.fields | ForEach-Object { $_.type = ([PsrApi.Data.Enums.PsrContainerItemType]$_.type).ToString() }
        $name = $form.Name
        $metaStructure.availableForms += $name
        $formHash.name = $name
        Write-PSFMessage "OU= $($form|ConvertTo-Json)" -Level Verbose
        $metaStructure.formStructure.$name = $formHash
        $metaStructure.formMapping."$($formHash.id)" = ConvertTo-NetwrixFormMapping $Form
    }
    $metaStructure.availableFields = $metaStructure.formStructure.Values.fields | ForEach-Object { [pscustomobject]$_ | Select-Object name, type, Description } | Sort-Object -Property name, type -Unique
    Write-PSFMessage "$`metaStructure.type=$($metaStructure.GetType())"
    if ($PSCmdlet.ParameterSetName -eq "directConnection") {
        $psrApi.authenticationManager.logout() | Wait-Task
    }
    return $metaStructure
    # $metaStructure #| ConvertTo-Json -Depth 5
}