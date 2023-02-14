function Update-NetwrixContainer {
    [CmdletBinding()]
    param (
        $Container,
        [string] $VaultName,
        [hashtable] $AdditionalParameters,
        [String]$NewUserName,
        [String]$NewMemo,
        [String]$NewName,
        [securestring]$NewPassword
    )
    $AdditionalParameters = @{} + $AdditionalParameters

    Write-PSFMessage "Update-NetwrixContainer, $VaultName, AdditionalParameters=$($AdditionalParameters|ConvertTo-Json -Compress), ReturnType=$ReturnType"

    if (-not (Test-SecretVault -VaultName $vaultName -AdditionalParameters $AdditionalParameters)) {
        Write-PSFMessage -Level Error "${vaultName}: Failed to unlock the vault"
        return $false
    }
    $psrApi = (Get-Variable -Name "Vault_$VaultName" -Scope Script -ErrorAction Stop).Value

    $conMan = $psrApi.ContainerManager

    Write-PSFMessage "Found $($containers.Count) Password containers for filter $filter"
    foreach ($con in $Containers) {
        Write-PSFMessage "Updating Container.id=$($con.id), .name=$($con.Info.ContainerName)"

        # $hash = [ordered]@{
        #     name = $con.Info.ContainerName
        #     id   = $con.id.guid
        # }
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
                # ContainerItemUserName {
                #     # $hash.userName = $child.Value
                # }
                NewPassword {
                    $plainTextPassword = [PSCredential]::new('SecureString', $NewPassword).GetNetworkCredential().Password
                    Write-PSFMessage "Aktualisiere Kennwort auf $plainTextPassword"
                    $child.PlainTextValue = $plainTextPassword
                    # $hash.passwordId = $child.id
                }
                # ContainerItemMemo {
                #     # $hash.memo = $child.Value
                # }
                Default {

                    Write-PSFMessage "Update property $_ with param $newPropertyName and value $newPropertyValue"
                    # $hash."$($child.Name)" = $child.Value
                }
                # private static async Task UpdatePassword(PsrContainer updatePassword)
                # {
                # var textField = updatePassword.Items.FirstOrDefault(ci => ci.ContainerItemType == PsrContainerItemType.if (textField != null) textField.Value = "MyPsrApiPassword_UPDATE";
                # var passwordField = updatePassword.Items.FirstOrDefault(ci => ci.IsPasswordItem());
                # if (passwordField != null)
                # {
                # var newPassword = _psrApi.PasswordManager.GeneratePhoneticPassword(20, 3, PasswordGeneratorSeparator.passwordField.PlainTextValue = "UPDATED_SECRET_PASSWORD_" + newPassword;
                # }
                # await _psrApi.ContainerManager.UpdateContainer(updatePassword);
                # Console.WriteLine($"Password {updatePassword.Id} updated");
                # }

            }
        }
        $conMan.UpdateContainer($con)
    }
}