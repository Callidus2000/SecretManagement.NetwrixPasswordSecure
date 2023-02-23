function Set-NetwrixPSFConfigValue {
    [CmdletBinding()]
    param (
        [hashtable]$AdditionalParameters,
        [String]$SubPath,
        $Value,
        [switch]$Initialize
    )
    $AdditionalParameters = @{} + $AdditionalParameters

    $confParam=@{
        Module      = "SecretManagement.NetwrixPasswordSecure.Extension"
        Name        = "$($AdditionalParameters.server -replace '\.','_').$($AdditionalParameters.Database).$SubPath"
        AllowDelete=$true
        Initialize=$Initialize
        Value=$Value
    }
    Write-PSFMessage "Saving PSFConfig: $($confParam|ConvertTo-Json -Compress -Depth 2)"
    Set-PSFConfig @confParam
}