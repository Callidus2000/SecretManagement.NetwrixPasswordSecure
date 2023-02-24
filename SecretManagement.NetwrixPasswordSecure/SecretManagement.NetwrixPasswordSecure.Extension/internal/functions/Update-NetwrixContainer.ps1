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
        [String]$NewUserName,
        [String]$NewMemo,
        [String]$NewText,
        [securestring]$NewPassword
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
    if($containerCount -eq 1){
        Write-PSFMessage "Found Password containers for filter $Name"
        Write-PSFMessage "Updating Container.id=$($container.id), .name=$($container.Info.ContainerName)"
    }else{
        Write-PSFMessage "Found NO Password containers for filter $Name, creating new"
        $allOUs = Get-NetwrixOU -ExistingConnection $psrApi -verbose
        $formMappingHash = Get-NetwrixPSFConfigValue -VaultName $VaultName -AdditionalParameters $AdditionalParameters -subPath FormMappings

        # $pattern = '(?<OU>.+)\\(?<NewEntryName>.+)\|(?<FormName>.+)'
        $pattern = '^(?>(?<OU>.+)\\)?(?<NewEntryName>[^\|]+)(?>\|(?<FormName>.+))?$'
        if ($Name -match $pattern) {
            $regMatches=Select-String -InputObject $Name -Pattern $pattern | Select-Object -ExpandProperty Matches
            $ouName=$regMatches.Groups['OU'].Value
            $formName = $regMatches.Groups['FormName'].Value
            $newEntryName = $regMatches.Groups['NewEntryName'].Value
        }else{
            Write-PSFMessage "Name does not match '<OU>|<FormName>|<NewEntryName>', fallback to configured defaults"
            $newEntryName=$Name
        }
        # Write-PSFMessage "`$AdditionalParameters=$($AdditionalParameters|ConvertTo-Json -Compress)"
        # Write-PSFMessage "`$formMappingConfigName=$formMappingConfigName"
        if ([string]::IsNullOrEmpty($ouName)) { $ouName = Get-NetwrixPSFConfigValue -VaultName $VaultName -AdditionalParameters $AdditionalParameters -subPath "Default.OU" }
        if ([string]::IsNullOrEmpty($formName)) { $formName = Get-NetwrixPSFConfigValue -VaultName $VaultName -AdditionalParameters $AdditionalParameters -subPath "Default.Form" }
        Write-PSFMessage "`$formName=$formName"
        Write-PSFMessage "`$ouName=$ouName"
        Write-PSFMessage "`$newEntryName=$newEntryName"
        # Write-PSFMessage "`$formMappingHash=$($formMappingHash|ConvertTo-Json -Compress)"
        $formMapping = $formMappingHash.$formName
        $ou=$allOUs.$ouName
        Write-PSFMessage "`$ou=$ou"
        Write-PSFMessage "`$formMapping=$($formMapping|ConvertTo-Json -Compress)"
        if($null -eq $ou){
            Write-PSFMessage -Level Error "The OU '$ouName' does not exist in this instance"
            Wait-PSFMessage
            throw "The OU '$ouName' does not exist in this instance"
        }
        if ($null -eq $formMapping) {
            Write-PSFMessage -Level Error "The form '$formName' does not exist in this instance"
            Wait-PSFMessage
            throw "The form '$formName' does not exist in this instance"
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