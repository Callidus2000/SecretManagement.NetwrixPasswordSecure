if(Get-PSFConfigValue -FullName 'SecretManagement.NetwrixPasswordSecure.Extension.ConsoleLogging.enabled' -Fallback $false){
    Write-PSFMessage "Configure Console Logging"
    $providerParam=@{
        Name="console"
        Enabled=$true
        style=Get-PSFConfigValue -FullName 'SecretManagement.NetwrixPasswordSecure.Extension.ConsoleLogging.style'
        MinLevel=Get-PSFConfigValue -FullName 'SecretManagement.NetwrixPasswordSecure.Extension.ConsoleLogging.MinLevel'
        MaxLevel=Get-PSFConfigValue -FullName 'SecretManagement.NetwrixPasswordSecure.Extension.ConsoleLogging.MaxLevel'

    }
    Write-PSFMessage "Configure Console Logging with Param=$($providerParam|ConvertTo-Json -Compress)"
    Set-PSFLoggingProvider @providerParam -IncludeModules 'SecretManagement.NetwrixPasswordSecure.Extension'

}else{
    Write-PSFMessage "NOT Configure Console Logging"
}
