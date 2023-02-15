Write-PSFMessage "Checking assemblies in `$moduleRoot=$moduleRoot"
if (Test-Path "$moduleRoot\bin\PsrApi.dll") {
    Add-Type -Path "$moduleRoot\bin\\PsrApi.dll"
    Add-Type -Path "$moduleRoot\bin\Newtonsoft.Json.dll"
}
else {
    $errMessage = "Required Assemblies (like PsrAPI.dll) are missing in the folder '$moduleRoot\bin'. They are provided for *Enterprise* cutomers by the product vendor on request. Please unzip all provided *.DLL within this folder"
    Write-PSFMessage -Level Error -Message $errMessage
}