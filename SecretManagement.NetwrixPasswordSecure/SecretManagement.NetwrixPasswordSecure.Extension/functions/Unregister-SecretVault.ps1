function Unregister-SecretVault {
    [CmdletBinding()]
    param (
        [string] $VaultName,
        [hashtable] $AdditionalParameters
    )

    Remove-Variable -Name "Vault_${vaultName}_MasterPassword" -Scope Script -Force -ErrorAction SilentlyContinue
    #Force a reconnection
    Remove-Variable -Name "Vault_${vaultName}" -Scope Script -Force -ErrorAction SilentlyContinue
}
