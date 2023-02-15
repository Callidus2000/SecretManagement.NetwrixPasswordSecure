function Update-NetwrixContainer {
    [CmdletBinding()]
    param (
        [String]$Name,
        [string]$VaultName,
        [hashtable]$AdditionalParameters,
        [String]$NewUserName,
        [String]$NewMemo,
        [String]$NewText,
        [securestring]$NewPassword
    )
    # TODO: Auskommentierten Code entfernen
    Write-PSFMessage "Update-NetwrixContainer, $VaultName, AdditionalParameters=$($AdditionalParameters|ConvertTo-Json -Compress)"

    if (-not (Test-SecretVault -VaultName $vaultName -AdditionalParameters $AdditionalParameters)) {
        Write-PSFMessage -Level Error "${vaultName}: Failed to unlock the vault"
        return $false
    }
    $container = Get-NetwrixContainer -Filter $Name -VaultName $VaultName -AdditionalParameters $AdditionalParameters -ReturnType NonModifiedContainer
    if ($container.Count -gt 1) {
        Write-PSFMessage -Level Error 'Multiple credentials found; Search with Get-SecretInfo and require the correct one by *.MetaData.id'
        Wait-PSFMessage
        throw 'Multiple credentials found; Search with Get-SecretInfo and require the correct one by *.MetaData.id'
    }
    $psrApi = (Get-Variable -Name "Vault_$VaultName" -Scope Script -ErrorAction Stop).Value

    $conMan = $psrApi.ContainerManager

    Write-PSFMessage "Found $($container.Count) Password containers for filter $filter"
    foreach ($con in $Container) {
        Write-PSFMessage "Updating Container.id=$($con.id), .name=$($con.Info.ContainerName)"

        foreach ($child in $con.Items) {
            $newPropertyName = $child.ContainerItemType -replace 'ContainerItem', 'New'
            try {
                $newPropertyValue = Get-Variable $newPropertyName -ValueOnly -ErrorAction Stop
            }
            catch {
                Write-PSFMessage "Param $newPropertyName not in focus, continue"
                continue
            }
            if ([string]::IsNullOrEmpty($newPropertyValue)) {
                Write-PSFMessage "No $newPropertyName param provided, continue"
                continue
            }
            switch ($newPropertyName) {
                NewPassword {
                    $plainTextPassword = [PSCredential]::new('SecureString', $NewPassword).GetNetworkCredential().Password
                    Write-PSFMessage "Aktualisiere Kennwort auf $plainTextPassword"
                    $child.PlainTextValue = $plainTextPassword
                }
                # NewUserName {
                # NewMemo {
                # $NewName {
                Default {
                    Write-PSFMessage "Update property $_ with param $newPropertyName and value $newPropertyValue"
                    $child.Value = $newPropertyValue
                }
            }
        }
        $conMan.UpdateContainer($con)
    }
}