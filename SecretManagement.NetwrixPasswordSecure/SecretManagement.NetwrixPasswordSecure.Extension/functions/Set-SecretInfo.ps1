function Set-SecretInfo {
    [CmdletBinding()]
    param (
        [string] $Name,
        [hashtable] $Metadata,
        [string] $VaultName,
        [hashtable] $AdditionalParameters
    )
    $AdditionalParameters = @{} + $AdditionalParameters
    if ($AdditionalParameters.Verbose) { $VerbosePreference = 'continue' }
    $settableKeys = @('Username', 'Password', 'Name', 'Memo')
    $unknownKeys = $Metadata.Keys | Where-Object { $settableKeys -notcontains $_ }
    if ($unknownKeys) {
        Write-PSFMessage -Level Warning "Set-SecretInfo Metadata-HashTable may contain the following keys: $($settableKeys -join ',')"
        Write-PSFMessage -Level Warning "Unknown keys in Metadata-HashTable which will be ignored: $($unknownKeys -join ',')"
    }
    $updateParam = $Metadata | ConvertTo-PSFHashtable -Include $settableKeys -Remap @{'Username' = 'NewUsername'; 'Name' = 'NewText'; 'Password' = 'NewPassword' ; 'Memo' = 'NewMemo' }
    # $Metadata = @{murks = 'Bar'; 'Password' = 'Hubba'; 'Name' = 'foo'; 'Memo' = 'myNote' }

    Write-PSFMessage "Set-SecretInfo, Name=$Name, Vault=$VaultName, AdditionalParameters=$($AdditionalParameters|ConvertTo-Json -Compress), Metadata=$($updateParam|ConvertTo-Json -Compress)"
    $updateParam.container = Get-NetwrixContainer -Filter $Name -VaultName $VaultName -AdditionalParameters $AdditionalParameters -ReturnType NonModifiedContainer
    if ($updateParam.container.count -gt 1) {
        Write-PSFMessage -Level Error 'Multiple credentials found; Search with Get-SecretInfo and require the correct one by *.MetaData.id'
        Wait-PSFMessage
        throw 'Multiple credentials found; Search with Get-SecretInfo and require the correct one by *.MetaData.id'
    }
    $updateParam.VaultName=$VaultName
    $updateParam.AdditionalParameters=$AdditionalParameters
    Update-NetwrixContainer @updateParam
}
