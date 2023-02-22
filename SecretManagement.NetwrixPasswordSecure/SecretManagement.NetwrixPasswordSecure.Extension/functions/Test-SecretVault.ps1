
function Test-SecretVault {
    <#
    .SYNOPSIS
    Tests if the vault is configured correctly and if it is unlocked.

    .DESCRIPTION
    Tests if the vault is configured correctly and if it is unlocked.

    .PARAMETER VaultName
    The name of the secret vault.

    .PARAMETER AdditionalParameters
    Additional parameters which where configured while creating the vault.

    .EXAMPLE
    Test-SecretVault -VaultName $vaultname

    Returns true if successfull

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param (
        [string] $VaultName,
        [hashtable] $AdditionalParameters
    )
    $AdditionalParameters =@{}+ $AdditionalParameters
    if ($AdditionalParameters.Verbose) { $VerbosePreference = 'continue' }
    Write-PSFMessage  "Test-SecretVault from $VaultName, AdditionalParameters=$($AdditionalParameters|ConvertTo-Json -Compress)"

    Write-PSFMessage -Level Verbose "SecretManagement: Testing Vault ${VaultName}"
    $vault = Get-SecretVault $VaultName -ErrorAction Stop
    if (-not $AdditionalParameters) {
        $AdditionalParameters = $vault.VaultParameters | ConvertTo-PSFHashtable
    }
    $vaultName = $vault.Name
    if ($vault.ModuleName -ne 'SecretManagement.NetwrixPasswordSecure') {
        Write-PSFMessage -Level Error "$vaultName was found but is not a NetwrixPasswordSecure Vault."
        return $false
    }

    #Test if connection already open, no need to do further testing if so
    try {
        $psrApi = (Get-Variable -Name "Vault_$VaultName" -Scope Script -ErrorAction Stop).Value
        if ($psrApi.SessionState -ne 'Connected') {
            Write-PSFMessage -Level Error 'Connection closed, starting a new connection by unlocking the vault'
            return $false
        }
        Write-PSFMessage -Level Verbose "Vault ${VaultName}: Connection already open, using existing connection"
        return $true
    }
    catch {
        Write-PSFMessage -Level Verbose "Catch ${VaultName}: $PSItem"
    }

    #Basic Sanity Checks
    if (-not $VaultName) {
        Write-PSFMessage -Level Error 'You must specify a Vault Name to test'
        return $false
    }
    Write-PSFMessage "##Connecting to Database with User $($AdditionalParameters.Username)"

    $neccessaryAdditionalAttributes=@( "database","port" , "userName" , "server")
    $missingAttributes=@()
    foreach($attr in $neccessaryAdditionalAttributes){
        if (-not $AdditionalParameters.ContainsKey("$attr")){
            $missingAttributes+=$attr
        }
    }
    if ($missingAttributes.Count -gt 0){
        Write-PSFMessage -Level Error "You must specify the following vault parameters to your PWSafe: $($neccessaryAdditionalAttributes -join ', '); Current missing attributes: $($missingAttributes -join ', ')"
        return $false
    }
    $server = "$($AdditionalParameters.server):$($AdditionalParameters.port)"
    Write-PSFMessage "Connecting to $server"
    $psrApi = [PsrApi.PsrApi]::new($server)
    Write-PSFMessage "Connecting to Database with user $($AdditionalParameters."Username")"


    [SecureString]$vaultMasterPassword = Get-Variable -Name "Vault_${VaultName}_MasterPassword" -ValueOnly -ErrorAction SilentlyContinue
    if (-not $vaultMasterPassword) {
        Write-PSFMessage -Level Error "Cached Master Password Not Found for $VaultName, Please use Unlock-SecretVault"
        return $false
    }
    try {
        [pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($AdditionalParameters.Username, $vaultMasterPassword)
        Write-PSFMessage "Authenticating to Database $($AdditionalParameters.database) with User $($AdditionalParameters.Username) and Password "
        $psrApi.authenticationManager.login($AdditionalParameters.database, $credObject.Username, $credObject.GetNetworkCredential().Password) | Wait-Task
    }
    catch {
        Write-PSFMessage -Level Error $PSItem
        return $false
    }
    if ($psrApi.SessionState -ne 'Connected'){
        #If we get this far something went wrong
        Write-PSFMessage -Level Error "Unable to open connection to the server"
        return $false
    }
    $formMappingConfigName = "SecretManagement.NetwrixPasswordSecure.Extension.FormMappings.$($AdditionalParameters.server).$($AdditionalParameters.Database)"
    Write-PSFMessage "Checking Form-Mapping at PSFPath $formMappingConfigName"
    $formMappingHash = Get-PSFConfigValue -FullName $formMappingConfigName
    if ($null -eq $formMappingHash){
        Write-PSFMessage "No Mapping found as PSFConfig, looking at additional Vault param"
        $formMappingHash = $AdditionalParameters.formMapping
    }
    if ($null -eq $formMappingHash){
        Write-PSFMessage "No Mapping found as additional parameter, generating Auto-Default"
        try {
            $metaData = Get-NetwrixMetaConfig -ExistingConnection $psrApi
            $formMappingHash = $metaData.formMapping
        }
        catch {
            Write-PSFMessage -Level Error "Could not create/query metadata"
            return $false
        }
    }
    if ($formMappingHash){
        Write-PSFMessage "Mapping found, Type $($formMappingHash.GetType())"
        if ($formMappingHash -is [String]){
            Write-PSFMessage "Converting JSON String to HashTable"
            try {
                $formMappingHash=$formMappingHash | ConvertFrom-Json | ConvertTo-PSFHashtable
            }
            catch {
                Write-PSFMessage -Level Error "Could not convert json to HashTable"
                return $false
            }
        }
        $allForms = @() + $formMappingHash.Values
        foreach ($form in $allForms) {
            if (-not $formMappingHash.ContainsKey("$($form.id)")) { $formMappingHash."$($form.id)"=$form}
            if (-not $formMappingHash.ContainsKey("$($form.formname)")) { $formMappingHash."$($form.formname)" = $form }
        }
    }
    Write-PSFMessage "Saving form mapping for later use: $($formMappingHash|ConvertTo-Json -Compress)"
    Set-PSFConfig -Module "SecretManagement.NetwrixPasswordSecure.Extension" -name "FormMappings.$($AdditionalParameters.server).$($AdditionalParameters.Database)" -Value $formMappingHash -Initialize
    Write-PSFMessage "Saving vault for reuse"
    Set-Variable -Name "Vault_$VaultName" -Scope Script -Value $psrApi
    return $true
}
