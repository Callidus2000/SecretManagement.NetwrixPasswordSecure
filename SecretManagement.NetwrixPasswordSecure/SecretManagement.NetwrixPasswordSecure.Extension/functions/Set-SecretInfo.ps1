function Set-SecretInfo {
    [CmdletBinding()]
    param (
        [string] $Name,
        [hashtable] $Metadata,
        [string] $VaultName,
        [hashtable] $AdditionalParameters
    )
    $updateParam = $PSBoundParameters | ConvertTo-PSFHashtable -Exclude 'Metadata'
    $settableKeys = @('Username', 'Password', 'Name', 'Memo')
    $unknownKeys = $Metadata.Keys | Where-Object { $settableKeys -notcontains $_ }
    if ($unknownKeys) {
        Write-PSFMessage -Level Warning "Set-SecretInfo Metadata-HashTable may contain the following keys: $($settableKeys -join ',')"
        Write-PSFMessage -Level Warning "Unknown keys in Metadata-HashTable which will be ignored: $($unknownKeys -join ',')"
    }
    $updateParam += $Metadata | ConvertTo-PSFHashtable -Include $settableKeys -Remap @{'Username' = 'NewUsername'; 'Name' = 'NewText'; 'Password' = 'NewPassword' ; 'Memo' = 'NewMemo' }

    Write-PSFMessage "#Setting secretInfo with `$updateParam=$($updateParam|ConvertTo-Json -Compress)"
    Update-NetwrixContainer @updateParam
    Wait-PSFMessage
    return $true
}
