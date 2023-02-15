function Convert-NetwrixContainer2Object {
    <#
    .SYNOPSIS
    Converts already queried Password Containers to a HashTable or SecretInformation Array.

    .DESCRIPTION
    Converts already queried Password Containers to a HashTable or SecretInformation Array.

    .PARAMETER Container
    The container to be converted.

    .PARAMETER ContainerManager
    The already instanciated ContainerManager.

    .PARAMETER IncludeCredential
    Should the credentials be included

    .PARAMETER AsSecretInformation
    Return an array of SecretInformation objects instead HashTables.

    .EXAMPLE
    $containers | Convert-NetwrixContainer2Object -ContainerManager $conMan -AsSecretInformation

    Converts the queried containers to SecretInformation objects suitable for Get-SecretInfo

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [PsrApi.Data.PsrContainer[]]$Container,
        [PsrApi.Managers.ContainerManager]$ContainerManager,
        [switch]$IncludeCredential,
        [switch]$AsSecretInformation
    )

    Begin {
        $Containers = @()
        $results=@()
    }

    Process {
        $Containers += $Container
    }

    End {
        Write-PSFMessage "Converting $($Containers.Count) containers to temporal hashtable"
        $tempHashList=@()
        foreach ($con in $Containers) {
            Write-PSFMessage "Collecting info hashtable for Container.id=$($con.id), .name=$($con.Info.ContainerName)"

            $hash = [ordered]@{
                name = $con.Info.ContainerName
                id=$con.id.guid
            }
            foreach ($child in $con.Items) {
                switch ($child.ContainerItemType) {
                    ContainerItemUserName { $hash.userName = $child.Value }
                    ContainerItemPassword { $hash.passwordId = $child.id }
                    ContainerItemMemo { $hash.memo = $child.Value }
                    Default { $hash."$($child.Name)" = $child.Value}
                }
            }
            $tempHashList+=$hash
        }
        Write-PSFMessage "Created $($tempHashList.count) temp hashtables"
        # The name of the secret infos may not occur more than one, checking this possibility and modifying the corresponding names
        $entriesWithDuplicateNames = $tempHashList | Group-Object -Property name | Where-Object count -gt 1
        foreach ($group in $entriesWithDuplicateNames) {
            Write-PSFMessage "The Secret with the name $($group.Name) occurs $($group.Count) times, adding the GUID to the name"
            foreach ($info in $group.Group){
                $info.name += " [$($info.id)]"
            }
        }

        foreach ($hash in $tempHashList){
            if ($IncludeCredential -and $null -ne $ContainerManager){
                Write-PSFMessage "Creating Credential Object"
                $securePassword = $ContainerManager.GetContainerItemWithSecretValue($hash.passwordId) | Wait-Task

                $decryptedPassword = $ContainerManager.DecryptContainerItem($securePassword, "API Test") | Wait-Task

                # Convert to SecureString
                [securestring]$secStringPassword = ConvertTo-SecureString $decryptedPassword -AsPlainText -Force

                [pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($hash.userName, $secStringPassword)
                $hash.Credential=$credObject
            }
            if ($AsSecretInformation) {
                Write-PSFMessage "Creating SecretManagement.SecretInformation"
                $results += [Microsoft.PowerShell.SecretManagement.SecretInformation]::new(
                    $hash.name, # Name of secret
                    "PSCredential", # Secret data type [Microsoft.PowerShell.SecretManagement.SecretType]
                    $VaultName, # Name of vault
                    $hash)    # Optional Metadata parameter
            }else{
                $results += [pscustomobject]$hash
                Write-PSFMessage "Result-Hash: $([pscustomobject]$hash)"
            }
        }
        return $results
    }
}