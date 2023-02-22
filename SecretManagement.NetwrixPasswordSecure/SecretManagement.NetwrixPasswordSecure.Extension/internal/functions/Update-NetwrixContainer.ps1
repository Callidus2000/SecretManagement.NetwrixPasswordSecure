﻿function Update-NetwrixContainer {
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
        Write-PSFMessage "Found NOPassword containers for filter $Name, creating new"
        $allOUs = Get-NetwrixOU -ExistingConnection $psrApi
        $allForms = Get-NetwrixForms -VaultName $VaultName -AdditionalParameters $AdditionalParameters

        $pattern = '(?<OU>.+)\|(?<FormName>.+)\|(?<NewEntryName>.+)'
        if ($Name -match $pattern) {
            $regMatches=Select-String -InputObject $Name -Pattern $pattern | Select-Object -ExpandProperty Matches
            $ouName=$regMatches.Groups['OU'].Value
            $formName = $regMatches.Groups['FormName'].Value
            $newEntryName = $regMatches.Groups['NewEntryName'].Value
        }else{
            Write-PSFMessage "Name does not match '<OU>|<FormName>|<NewEntryName>', fallback to configured defaults"
            $newEntryName=$Name
        }
        $chosenForm = $allForms.$formName
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