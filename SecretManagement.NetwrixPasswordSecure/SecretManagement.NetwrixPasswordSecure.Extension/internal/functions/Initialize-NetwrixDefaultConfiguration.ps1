function Initialize-NetwrixDefaultConfiguration {
    [CmdletBinding()]
    param (
        [string] $VaultName,
        [parameter(mandatory = $true, ParameterSetName = "alreadyConnected")]
        [hashtable] $AdditionalParameters,
        [parameter(mandatory = $true, ParameterSetName = "alreadyConnected")]
        [PsrApi.PsrApi]$ExistingConnection
    )
    $AdditionalParameters = @{} + $AdditionalParameters
    $alreadyInitialized = Get-NetwrixPSFConfigValue -VaultName $VaultName -SubPath "ConfigInitialized"
    if ($alreadyInitialized) {
        Write-PSFMessage "Vault $VaultName already initialized"
        return
    }
    Write-PSFMessage "Initializing configuration for vault $VaultName"
    try {
        $metaData = Get-NetwrixMetaConfig -ExistingConnection $ExistingConnection
    }
    catch {
        Write-PSFMessage -Level Error "Could not create/query metadata $_" -Tag CONERR -ErrorRecord $_
        # Write-PSFMessage -Level Error "`$ExistingConnection=$($ExistingConnection|ConvertTo-Json -Compress -EnumsAsStrings)" -Tag CONERR
        throw "Could not create/query metadata"
    }
    #region Initialize password form mappings
    # Searching for a form mapping preConfig in Scope 'ServerDB' as a template. The final mapping will be stored for the vault itself.
    # If the initialization has been run before the mapping will exist
    $configSubPath = "FormMappings"
    $formMappingHash = Get-NetwrixPSFConfigValue -VaultName $VaultName -AdditionalParameters $AdditionalParameters -subPath $configSubPath -Scope ServerDB
    if ($null -eq $formMappingHash) {
        Write-PSFMessage "No Mapping found as PSFConfig, looking at additional Vault param"
        $formMappingHash = $AdditionalParameters.formMapping
    }
    if ($null -eq $formMappingHash) {
        Write-PSFMessage "No Mapping found as additional parameter, query Auto-Default"
        $formMappingHash = $metaData.formMapping
    }
    if ($null -eq $formMappingHash) {
        Write-PSFMessage "No password form mapping available" -Level Error
        throw "No password form mapping available"
    }
    Write-PSFMessage "Mapping found, Type $($formMappingHash.GetType())"
    if ($formMappingHash -is [String]) {
        Write-PSFMessage "Converting JSON String to HashTable"
        try {
            $formMappingHash = $formMappingHash | ConvertFrom-Json | ConvertTo-PSFHashtable
        }
        catch {
            Write-PSFMessage -Level Error "Could not convert json to HashTable"
            throw "Could not convert json to HashTable"
        }
    }
    $allForms = @() + $formMappingHash.Values
    foreach ($form in $allForms) {
        if (-not $formMappingHash.ContainsKey("$($form.id)")) { $formMappingHash."$($form.id)" = $form }
        if (-not $formMappingHash.ContainsKey("$($form.formname)")) { $formMappingHash."$($form.formname)" = $form }
    }
    Write-PSFMessage "Saving form mapping for later use: $($formMappingHash|ConvertTo-Json -Compress)"
    Set-NetwrixPSFConfigValue -VaultName $VaultName -AdditionalParameters $AdditionalParameters -subPath $configSubPath -Initialize -value $formMappingHash
    #endregion Initialize password form mappings

    #region Determin default OU
    # Searching for a form mapping preConfig in Scope 'ServerDB' as a template. The final mapping will be stored for the vault itself.
    # If the initialization has been run before the mapping will exist
    $configSubPath = "Default.OU"
    $defaultOUName = Get-NetwrixPSFConfigValue -VaultName $VaultName -AdditionalParameters $AdditionalParameters -subPath $configSubPath -Scope ServerDB
    if ($null -eq $defaultOUName) {
        Write-PSFMessage "No defaultOUName found as PSFConfig, looking at additional Vault param"
        $defaultOUName = $AdditionalParameters.defaultOUName
    }
    if ([string]::IsNullOrEmpty( $defaultOUName)) {
        Write-PSFMessage "No defaultOUName found as additional parameter, Create default"
        $defaultOUName = $metaData.organisationalUnits.Values | Sort-Object -Property type, name | Select-Object -ExpandProperty name -First 1
    }
    if ($null -eq $defaultOUName) {
        Write-PSFMessage "No defaultOUName available" -Level Error
        throw "No defaultOUName available"
    }
    Set-NetwrixPSFConfigValue -VaultName $VaultName -AdditionalParameters $AdditionalParameters -subPath $configSubPath -Initialize -value $defaultOUName
    #endregion Determin default OU

    #region Determin default Form
    # Searching for a form mapping preConfig in Scope 'ServerDB' as a template. The final mapping will be stored for the vault itself.
    # If the initialization has been run before the mapping will exist
    $configSubPath = "Default.Form"
    $defaultFormName = Get-NetwrixPSFConfigValue -VaultName $VaultName -AdditionalParameters $AdditionalParameters -subPath $configSubPath -Scope ServerDB
    if ($null -eq $defaultFormName) {
        Write-PSFMessage "No defaultFormName found as PSFConfig, looking at additional Vault param"
        $defaultFormName = $AdditionalParameters.defaultFormName
    }
    if ([string]::IsNullOrEmpty( $defaultFormName)) {
        Write-PSFMessage "No defaultFormName found as additional parameter, Create default"
        $formData = @() + $metaData.formMapping.Values
        $sortableForms = @()
        foreach ($formHash in $formData) {
            $formHash.fieldCount = $formHash.fields.Count
            $formHash.nameLength = $formHash.formName.Length
            $sortableForms += [PSCustomObject]$formHash
        }
        $sortableForms = $sortableForms | Where-Object secretType -eq 'pscredential' | Sort-Object -Property fieldCount, nameLength
        $defaultFormName = $sortableForms | Select-Object -ExpandProperty formname -First 1
    }
    if ($null -eq $defaultFormName) {
        Write-PSFMessage "No defaultFormName available" -Level Warning
    }
    Set-NetwrixPSFConfigValue -VaultName $VaultName -AdditionalParameters $AdditionalParameters -subPath $configSubPath -Initialize -value $defaultFormName
    #endregion Determin default Form
    Set-NetwrixPSFConfigValue -VaultName $VaultName -SubPath "ConfigInitialized" -Value $true
}