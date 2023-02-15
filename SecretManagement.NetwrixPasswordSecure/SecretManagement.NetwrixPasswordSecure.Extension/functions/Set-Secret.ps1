function Set-Secret {
    [CmdletBinding()]
    param (
        [string] $Name,
        [object] $Secret,
        [string] $VaultName,
        [hashtable] $AdditionalParameters
    )
    # $updateParam=$PSBoundParameters|ConvertTo-PSFHashtable -Exclude Secret


    $AdditionalParameters = @{} + $AdditionalParameters
    if ($AdditionalParameters.Verbose) { $VerbosePreference = 'continue' }

    Write-PSFMessage "Set-Secret, Name=$Name, $VaultName, AdditionalParameters=$($AdditionalParameters|ConvertTo-Json -Compress), `$Host.InstanceId: $($Host.InstanceId)"
    $containers = Get-NetwrixContainer -Filter $Name -VaultName $VaultName -AdditionalParameters $AdditionalParameters -ReturnType NonModifiedContainer
    if ($containers.Count -gt 1) {
        Write-PSFMessage -Level Error 'Multiple credentials found; Search with Get-SecretInfo and require the correct one by *.MetaData.id'
        Wait-PSFMessage
        throw 'Multiple credentials found; Search with Get-SecretInfo and require the correct one by *.MetaData.id'
    }
    Update-NetwrixContainer -Container $containers -VaultName $VaultName -AdditionalParameters $AdditionalParameters -NewPassword $Secret -newmemo "Memo"
    return $true
}

