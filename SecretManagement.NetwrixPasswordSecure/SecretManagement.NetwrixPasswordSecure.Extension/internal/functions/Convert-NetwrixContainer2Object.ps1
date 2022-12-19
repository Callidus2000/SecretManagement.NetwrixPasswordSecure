function Convert-NetwrixContainer2Object {
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
        Write-PSFMessage "Converting $($Containers.Count) containers"
        foreach ($con in $Containers) {
            $hash = [ordered]@{
                name = $con.Info.ContainerName
                id=$con.id
            }
            foreach ($child in $con.Items) {
                switch ($child.ContainerItemType) {
                    ContainerItemUserName { $hash.userName = $child.Value }
                    ContainerItemPassword { $hash.passwordId = $child.id }
                    ContainerItemMemo { $hash.memo = $child.Value }
                    Default { $hash."$($child.Name)" = $child.Value}
                }
            }
            if ($IncludeCredential -and $ContainerManager -ne $null){
                Write-PSFMessage "Creating Credential Object"
                $securePassword = $ContainerManager.GetContainerItemWithSecretValue($hash.passwordId) | Wait-Task

                $decryptedPassword = $ContainerManager.DecryptContainerItem($securePassword, "API Test") | Wait-Task

                # Convert to SecureString
                [securestring]$secStringPassword = ConvertTo-SecureString $decryptedPassword -AsPlainText -Force

                [pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($hash.userName, $secStringPassword)
                $hash.Credential=$credObject
            }
            if ($AsSecretInformation) {
                $results+=[Microsoft.PowerShell.SecretManagement.SecretInformation]::new(
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

# $myCon=$monitoringPasswordContainer | Select-Object -first 1
# $mycon.Items | Select-Object name, value, ContainerItemType
# $monitoringPasswordContainer | Select-Object -first 1 | Convert-NetwrixContainer2Object -IncludeCredential -ContainerManager $conMan -Verbose