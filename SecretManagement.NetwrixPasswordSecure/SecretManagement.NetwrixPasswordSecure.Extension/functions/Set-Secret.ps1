function Set-Secret {
    [CmdletBinding()]
    param (
        [string] $Name,
        [object] $Secret,
        [string] $VaultName,
        [hashtable] $AdditionalParameters
    )
    $updateParam = $PSBoundParameters | ConvertTo-PSFHashtable -Exclude 'Secret'
    if ($Secret -is [securestring]) {
        $updateParam.NewPassword = $Secret
    }
    elseif ($Secret -is [pscredential]) {
        $updateParam.NewPassword = $Secret.password
        $updateParam.NewUsername = $Secret.Username
    }
    Write-PSFMessage "#Setting secret with `$updateParam=$($updateParam|ConvertTo-Json -Compress)"
    Update-NetwrixContainer @updateParam
    Wait-PSFMessage
    return $true
}

