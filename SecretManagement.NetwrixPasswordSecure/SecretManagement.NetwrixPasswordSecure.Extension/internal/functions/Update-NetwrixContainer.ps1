function Update-NetwrixContainer {
    <#
    .SYNOPSIS
    Updates a password container.

    .DESCRIPTION
    Updates a password container.

    .PARAMETER Name
    Name to be searched for.

    .PARAMETER VaultName
    The name of the secret vault.

    .PARAMETER AdditionalParameters
    Additional parameters which where configured while creating the vault.

    .PARAMETER NewUserName
    If used a new Username will be saved.

    .PARAMETER NewMemo
    If used a new Note will be saved.

    .PARAMETER NewText
    If used the name of the entry will be changed.

    .PARAMETER NewPassword
    If used a new Password will be saved.

    .EXAMPLE
    Update-NetwrixContainer -Name foo -NewText FooBar -VaultName $vaultName -AdditionalParameters $AdditionalParameters

    Rename the entry 'foo' to 'foobar'

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessforStateChangingFunctions', '')]
    param (
        [String]$Name,
        [string]$VaultName,
        [hashtable]$AdditionalParameters,
        [hashtable]$MetaData,
        $Secret
    )
    Write-PSFMessage "Update-NetwrixContainer, $VaultName, AdditionalParameters=$($AdditionalParameters|ConvertTo-Json -Compress)"
    $AdditionalParameters = @{} + $AdditionalParameters

    if (-not (Test-SecretVault -VaultName $vaultName -AdditionalParameters $AdditionalParameters)) {
        Write-PSFMessage -Level Error "${vaultName}: Failed to unlock the vault"
        return $false
    }
    $psrApi = (Get-Variable -Name "Vault_$VaultName" -Scope Script -ErrorAction Stop).Value

    $conMan = $psrApi.ContainerManager
    $container = Get-NetwrixContainer -Filter $Name -VaultName $VaultName -AdditionalParameters $AdditionalParameters -ReturnType NonModifiedContainer
    $containerCount = ($container | Measure-Object).count
    if ($containerCount -gt 1) {
        Write-PSFMessage -Level Error 'Multiple credentials found; Search with Get-SecretInfo and require the correct one by *.MetaData.id'
        Wait-PSFMessage
        throw 'Multiple credentials found; Search with Get-SecretInfo and require the correct one by *.MetaData.id'
    }
    $availableFormMappings = Get-NetwrixPSFConfigValue -VaultName $VaultName -AdditionalParameters $AdditionalParameters -subPath FormMappings
    if ($containerCount -eq 1) {
        Write-PSFMessage "Found Password containers for filter $Name"
        Write-PSFMessage "Updating Container.id=$($container.id), .name=$($container.Info.ContainerName)"
        $conManMode = 'Update'
        Write-PSFMessage "`$availableFormMappings=$($availableFormMappings|ConvertTo-Json -Compress)" -Level Debug
        Write-PSFMessage "`$container.BaseContainerId=$($container.BaseContainerId)" -Level Debug
        $formMapping = $availableFormMappings."$($container.BaseContainerId)"
        Write-PSFMessage "`$formMapping=$($formMapping|ConvertTo-Json -Compress)" -Level Debug
        Write-PSFMessage "##`$container=$($container|ConvertTo-Json -Compress)"
        # $conItem = $container.items | Where-Object BaseContainerItemId -eq $formMapping.nameId|Select-Object -ExpandProperty value
    }
    else {
        Write-PSFMessage "Found NO Password containers for filter $Name, creating new"
        $conManMode = 'Add'
        $allOUs = Get-NetwrixOU -ExistingConnection $psrApi -verbose

        # $pattern = '(?<OU>.+)\\(?<NewEntryName>.+)\|(?<FormName>.+)'
        $pattern = '^(?>(?<OU>.+)\\)?(?<NewEntryName>[^\|]+)(?>\|(?<FormName>.+))?$'
        if ($Name -match $pattern) {
            $regMatches = Select-String -InputObject $Name -Pattern $pattern | Select-Object -ExpandProperty Matches
            $ouName = $regMatches.Groups['OU'].Value
            $formName = $regMatches.Groups['FormName'].Value
            $newEntryName = $regMatches.Groups['NewEntryName'].Value
        }
        else {
            Write-PSFMessage "Name does not match '<OU>|<FormName>|<NewEntryName>', fallback to configured defaults"
            $newEntryName = $Name
        }
        # Write-PSFMessage "`$AdditionalParameters=$($AdditionalParameters|ConvertTo-Json -Compress)"
        # Write-PSFMessage "`$formMappingConfigName=$formMappingConfigName"
        if ([string]::IsNullOrEmpty($ouName)) { $ouName = Get-NetwrixPSFConfigValue -VaultName $VaultName -AdditionalParameters $AdditionalParameters -subPath "Default.OU" }
        if ([string]::IsNullOrEmpty($formName)) { $formName = Get-NetwrixPSFConfigValue -VaultName $VaultName -AdditionalParameters $AdditionalParameters -subPath "Default.Form" }
        Write-PSFMessage "`$formName=$formName"
        Write-PSFMessage "`$ouName=$ouName"
        Write-PSFMessage "`$newEntryName=$newEntryName"
        # Write-PSFMessage "`$availableFormMappings=$($availableFormMappings|ConvertTo-Json -Compress)"
        $formMapping = $availableFormMappings.$formName
        $ou = $allOUs.$ouName
        Write-PSFMessage "`$ou=$ou"
        Write-PSFMessage "`$formMapping=$($formMapping|ConvertTo-Json -Compress)"
        if ($null -eq $ou) {
            Write-PSFMessage -Level Error "The OU '$ouName' does not exist in this instance"
            Wait-PSFMessage
            throw "The OU '$ouName' does not exist in this instance"
        }
        if ($null -eq $formMapping) {
            Write-PSFMessage -Level Error "The form '$formName' does not exist in this instance"
            Wait-PSFMessage
            throw "The form '$formName' does not exist in this instance"
        }
        $passwordForm = Get-NetwrixForm -ExistingConnection $psrApi -Name $formName
        $container = $conMan.CreateContainerFromBaseContainer($passwordForm, [PsrApi.Data.Enums.PsrContainerType]::Password)
        $container.name = $newEntryName
    }

    # Write-PSFMessage "$($container|ConvertTo-Json -Depth 4)"
    # Gather all form elements with new values
    $reAssignHashmap = @{
        "$($formMapping.nameId)" = $container.name
    }
    if ([string]::IsNullOrEmpty($container.name)) { $reAssignHashmap."$($formMapping.nameId)" = $container.Info.ContainerName }
    $passwordId = $formMapping.fields.values | Where-Object secretproperty -eq 'Password' | Select-Object -ExpandProperty id | Select-Object -ExpandProperty guid
    if ($secret) {
        if ($Secret -is [pscredential]) {
            $userNameId = $formMapping.fields.values | Where-Object secretproperty -eq 'UserName' | Select-Object -ExpandProperty id | Select-Object -ExpandProperty guid
            $reAssignHashmap.$userNameId = $Secret.username
            $reAssignHashmap.$passwordId = $Secret.password
        }
        elseif ($Secret -is [securestring]) {
            $reAssignHashmap.$passwordId = $Secret
        }
        elseif ($Secret -is [hashtable]) {
            if ($MetaData) { $MetaData = $MetaData + $Secret }else { $MetaData = $Secret }
        }
        else {
            Write-PSFMessage -Level Error "Unsupported Secret Type '$($Secret.GetType())'"
            Wait-PSFMessage
            throw "Unsupported Secret Type '$($Secret.GetType())'"
        }
    }
    if ($null -ne $MetaData) {
        # TODO Infos müssen übernommen werden!
        Write-PSFMessage "Adding SecretInfo MetaData to the entry"
        if ($MetaData.ContainsKey('NewName')) {
            Write-PSFMessage "Rename entry from '$($container.name)' to '$($MetaData.NewName)'"
            $container.name = $MetaData.NewName
            $reAssignHashmap."$($formMapping.nameId)" = $MetaData.NewName
            $MetaData.Remove('NewName')
        }
        foreach ($metaName in $MetaData.Keys) {
            $fieldId = $formMapping.fields.values | Where-Object fieldName -eq $metaName | Select-Object -ExpandProperty id | Select-Object -ExpandProperty guid
            if ([string]::IsNullOrEmpty($fieldId)) {
                Write-PSFMessage -Level Warning "Meta Property '$metaName' maps to no existing password form fields"
            }
            else {
                $reAssignHashmap.$fieldId = $MetaData.$metaName
            }
        }
    }
    Write-PSFMessage "`$reAssignHashmap=$($reAssignHashmap|ConvertTo-Json -Compress)"
    # Write-PSFMessage "`$container=$($container|ConvertTo-Json -Compress)"
    foreach ($key in $reAssignHashmap.Keys) {
        $conItem = $container.items | Where-Object BaseContainerItemId -eq $key
        # Write-PSFMessage "`$key=$($key)"
        # Write-PSFMessage "`$conItem=$($conItem|ConvertTo-Json -EnumsAsStrings -Depth 3)"
        switch ($conItem.ContainerItemType) {
            ContainerItemPassword { $conItem.PlainTextValue = ConvertFrom-SecureString -AsPlainText $reAssignHashmap.$key }
            Default {
                # TODO There are other properties as well
                $conItem.Value = $reAssignHashmap.$key
            }
        }
    }
    # return
    switch ($conManMode) {
        'Update' {
            $conMan.UpdateContainer($container) | Wait-Task
        }
        'Add' {
            $conMan.AddContainer($container, $ou.OrganisationUnit.id, $null, $null) | wait-task
        }
    }

    # foreach ($child in $container.Items) {
    #     $newPropertyName = $child.ContainerItemType -replace 'ContainerItem', 'New'
    #     try {
    #         $newPropertyValue = Get-Variable $newPropertyName -ValueOnly -ErrorAction Stop
    #     }
    #     catch {
    #         Write-PSFMessage "Param $newPropertyName not in focus, continue"
    #         continue
    #     }
    #     if ([string]::IsNullOrEmpty($newPropertyValue)) {
    #         Write-PSFMessage "No $newPropertyName param provided, continue"
    #         continue
    #     }
    #     switch ($newPropertyName) {
    #         NewPassword {
    #             $plainTextPassword = [PSCredential]::new('SecureString', $NewPassword).GetNetworkCredential().Password
    #             Write-PSFMessage "Aktualisiere Kennwort auf $plainTextPassword"
    #             $child.PlainTextValue = $plainTextPassword
    #         }
    #         # NewUserName {
    #         # NewMemo {
    #         # $NewName {
    #         Default {
    #             Write-PSFMessage "Update property $_ with param $newPropertyName and value $newPropertyValue"
    #             $child.Value = $newPropertyValue
    #         }
    #     }
    # }
    # $conMan.AddContainer($newPasswordFormContainer, $ouApi.OrganisationUnit.id, $null, $null) | wait-task
    # $conMan.UpdateContainer($container) | Wait-Task
}