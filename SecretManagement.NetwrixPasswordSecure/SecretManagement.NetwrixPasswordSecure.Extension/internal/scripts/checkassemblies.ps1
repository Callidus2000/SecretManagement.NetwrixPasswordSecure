Write-PSFMessage "Checking assemblies in `$moduleRoot=$moduleRoot"

if (Test-Path "$moduleRoot\bin\PsrApi.dll") {
    $dllPath = "$moduleRoot\bin\"
}else{
    $dllPath = get-module secretmanagement.netwrixpasswordsecure -ListAvailable | Select-Object -ExpandProperty path | Split-Path | Join-Path -ChildPath "SecretManagement.NetwrixPasswordSecure.Extension\bin" | Where-Object { test-path "$_\psrapi.dll" } | Sort-Object -Descending | Select-Object -first 1
}
if ($dllPath) {
    Write-PSFMessage "Found the neccessary DLLs in the following folder: $dllPath"
    Add-Type -Path "$dllPath\PsrApi.dll"
    Add-Type -Path "$dllPath\Newtonsoft.Json.dll"
}
else {
    $errMessage = "Required Assemblies (like PsrAPI.dll) are missing in the folder '$moduleRoot\bin'. They are provided for *Enterprise* cutomers by the product vendor on request. Please unzip all provided *.DLL within this folder"
    Write-PSFMessage -Level Error -Message $errMessage
}