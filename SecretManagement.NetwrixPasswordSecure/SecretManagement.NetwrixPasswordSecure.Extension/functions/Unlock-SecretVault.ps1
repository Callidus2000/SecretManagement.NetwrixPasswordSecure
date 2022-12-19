function Unlock-SecretVault {
    [CmdletBinding()]
    param (
        [SecureString] $Password,
        [string] $VaultName,
        [hashtable] $AdditionalParameters
    )

    $AdditionalParameters = @{} + $AdditionalParameters

    Write-PSFMessage "Unlocking SecretVault $VaultName, AdditionalParameters=$($AdditionalParameters|ConvertTo-Json -Compress)"
    $vault = Get-SecretVault $VaultName -ErrorAction Stop
    Write-PSFMessage "Vault= $($vault|ConvertTo-Json -Compress)"
    if(-not $AdditionalParameters){
        $AdditionalParameters=$vault.VaultParameters|ConvertTo-PSFHashtable
    }
    $vaultName = $vault.Name
    Write-PSFMessage "Hubba"
    if ($vault.ModuleName -ne 'SecretManagement.NetwrixPasswordSecure') {
        Write-PSFMessage -Level Error "$vaultName was found but is not a NetwrixPasswordSecure Vault."
        return $false
    }
    Set-Variable -Name "Vault_${vaultName}_MasterPassword" -Scope Script -Value $Password -Force
    #Force a reconnection
    Remove-Variable -Name "Vault_${vaultName}" -Scope Script -Force -ErrorAction SilentlyContinue
    if (-not (Test-SecretVault -VaultName $vaultName -AdditionalParameters $AdditionalParameters)) {
        Write-PSFMessage -Level Error "${vaultName}: Failed to unlock the vault"
        return $false
    }
    Write-PSFMessage "SecretVault $vault unlocked successfull"
    return $true
}