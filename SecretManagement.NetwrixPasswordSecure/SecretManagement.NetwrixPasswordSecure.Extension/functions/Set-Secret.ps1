function Set-Secret {
    [CmdletBinding()]
    param (
        [string] $Name,
        [object] $Secret,
        [string] $VaultName,
        [hashtable] $AdditionalParameters
    )
    $AdditionalParameters = @{} + $AdditionalParameters
    if ($AdditionalParameters.Verbose) { $VerbosePreference = 'continue' }

    Write-PSFMessage "Set-Secret, Name=$Name, $VaultName, AdditionalParameters=$($AdditionalParameters|ConvertTo-Json -Compress), `$Host.InstanceId: $($Host.InstanceId)"
    # $metaHashes = Get-NetwrixContainer -Filter $Name -VaultName $VaultName -AdditionalParameters $AdditionalParameters -ReturnType MetaHash
    # if ($metaHashes.Count -gt 1) {
    #     Write-PSFMessage -Level Error 'Multiple credentials found; Search with Get-SecretInfo and require the correct one by *.MetaData.id'
    #     Wait-PSFMessage
    #     throw 'Multiple credentials found; Search with Get-SecretInfo and require the correct one by *.MetaData.id'
    # }
    # Write-PSFMessage -Level Host "`$metaHashes=$($metaHashes|ConvertTo-Json -Compress)"
    $containers = Get-NetwrixContainer -Filter $Name -VaultName $VaultName -AdditionalParameters $AdditionalParameters -ReturnType NonModifiedContainer
    if ($containers.Count -gt 1) {
        Write-PSFMessage -Level Error 'Multiple credentials found; Search with Get-SecretInfo and require the correct one by *.MetaData.id'
        Wait-PSFMessage
        throw 'Multiple credentials found; Search with Get-SecretInfo and require the correct one by *.MetaData.id'
    }
    Update-NetwrixContainer -Container $containers -VaultName $VaultName -AdditionalParameters $AdditionalParameters -NewPassword $Secret -newmemo "Memo"
    # Write-PSFMessage -Level Host "`$containers=$($containers|ConvertTo-Json)"
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
    return $true
}

