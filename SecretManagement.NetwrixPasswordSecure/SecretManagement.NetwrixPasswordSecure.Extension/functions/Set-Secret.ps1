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
    $metaHashes = Get-NetwrixContainer -Filter $Name -VaultName $VaultName -AdditionalParameters $AdditionalParameters -ReturnType MetaHash
    if ($metaHashes.Count -gt 1) {
        Write-Verbose -Verbose 'Error message'
        Write-Error 'Error message 2'
        [System.Console]::WriteLine('Error message 3')
        $host.UI.WriteErrorLine('UI: Multiple credentials found; Search with Get-SecretInfo and require the correct one by *.MetaData.id')
        # $host.UI.WriteLine([System.ConsoleColor]::Red, [System.ConsoleColor]::Black, 'Error')
        Write-PSFMessage -Level Error 'Multiple credentials found; Search with Get-SecretInfo and require the correct one by *.MetaData.id' -Target "$Name"
        # return
        # DO NOT THROW an exception; if you do it the given error message will never make it to the console
        # Bad thing in Set-Secret: It states success nevertheless.
        Wait-PSFMessage
        throw 'Multiple credentials found; Search with Get-SecretInfo and require the correct one by *.MetaData.id'
    }
    Write-PSFMessage -Level Host "`$metaHashes=$($metaHashes|ConvertTo-Json -Compress)"
    return $true
}

