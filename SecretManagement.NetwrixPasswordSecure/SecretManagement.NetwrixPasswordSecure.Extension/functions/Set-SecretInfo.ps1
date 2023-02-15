function Set-SecretInfo {
    <#
    .SYNOPSIS
    Updates additional fields of a single entry.

    .DESCRIPTION
    Updates additional fields of a single entry.

    .PARAMETER Name
    Name of the entry

    .PARAMETER Metadata
    The HashTable with the fields to update.
    Possible Keys: 'Username', 'Password', 'Name', 'Memo'

    .PARAMETER VaultName
    The name of the secret vault.

    .PARAMETER AdditionalParameters
    Additional parameters which where configured while creating the vault.

    .EXAMPLE
    Set-SecretInfo  -Vault $Vaultname  -Name foo -Metadata @{memo='Notiz 2';username='foo';password=$myNewSecret}

    Updates the entry with new memo.

    .EXAMPLE
    Set-SecretInfo  -Vault $Vaultname  -Name foo -Metadata @{name='Bar'}

    Renames the entry 'foo' to 'Bar'

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessforStateChangingFunctions', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '')]
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
