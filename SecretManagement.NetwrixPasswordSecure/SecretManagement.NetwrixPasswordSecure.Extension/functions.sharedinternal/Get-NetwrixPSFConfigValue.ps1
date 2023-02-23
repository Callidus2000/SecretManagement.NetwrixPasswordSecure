function Get-NetwrixPSFConfigValue {
    [CmdletBinding()]
    param (
        [hashtable]$AdditionalParameters,
        [String]$SubPath
    )
    $AdditionalParameters = @{} + $AdditionalParameters
    $configName = "SecretManagement.NetwrixPasswordSecure.Extension.$($AdditionalParameters.server -replace '\.','_').$($AdditionalParameters.Database).$SubPath"
    Write-PSFMessage "Query PSFConfig $configName"
    $value = Get-PSFConfigValue -FullName $configName
    if(-not $value){Write-PSFMessage "No value found"}
    return $value
}