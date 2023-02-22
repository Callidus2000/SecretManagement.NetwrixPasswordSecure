function ConvertFrom-NetwrixContainer {
    <#
    .SYNOPSIS
    Converts already queried Password Containers to a HashTable or SecretInformation Array.

    .DESCRIPTION
    Converts already queried Password Containers to a HashTable or SecretInformation Array.

    .PARAMETER Container
    The container to be converted.

    .PARAMETER ExistingConnection
    The already instanciated connection.

    .PARAMETER BuildSecret
    Should the credentials be included

    .PARAMETER AsSecretInformation
    Return an array of SecretInformation objects instead HashTables.

    .EXAMPLE
    $containers | ConvertFrom-NetwrixContainer -ExistingConnection $psrApi -AsSecretInformation

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
        [PsrApi.PsrApi]$ExistingConnection,
        [switch]$BuildSecret,
        [switch]$AsSecretInformation
    )

    Begin {
        $ContainerManager = $ExistingConnection.ContainerManager
        $Containers = @()
        $results = @()
        $formMappingConfigName = "SecretManagement.NetwrixPasswordSecure.Extension.FormMappings.$($AdditionalParameters.server -replace '\.','_').$($AdditionalParameters.Database)"
        $formsMapping = Get-PSFConfigValue -FullName $formMappingConfigName
    }

    Process {
        $Containers += $Container
    }

    End {
        Write-PSFMessage "Converting $($Containers.Count) containers to temporal hashtable"
        $tempHashList = @()
        foreach ($con in $Containers) {
            $fieldMappingIdPropertyName = "BaseContainerItemId"
            Write-PSFMessage "RAW Container: $($con|ConvertTo-Json -Compress -Depth 5)"
            $mapping = $formsMapping."$($con.BaseContainerId)"
            if ($null -eq $mapping) {
                Write-PSFMessage "No Default mapping found, Container was created without form"
                $mapping = ConvertTo-NetwrixFormMapping $con
                if ($null -eq $mapping) {
                    Write-PSFMessage -Level Critical "Could not create mapping on the fly"
                    Wait-PSFMessage
                    return
                }
                $fieldMappingIdPropertyName = "id"
            }
            Write-PSFMessage "Using the following mapping:$($mapping |ConvertTo-Json -Depth 4 -Compress)"
            Write-PSFMessage "Collecting info hashtable for Container.id=$($con.id), .name=$($con.Info.ContainerName)"
            Write-PSFMessage "Mapping field by the following field attribute: $fieldMappingIdPropertyName"

            $secretDataHash = [ordered]@{
                name       = $con.Info.ContainerName
                id         = $con.id.guid
                secretType = $mapping.secretType
                secret     = @{}
                metaData=@{}
            }
            foreach ($child in $con.Items) {
                $formFieldId = $child.$fieldMappingIdPropertyName
                $fieldMapping = $mapping.fields."$formFieldId"
                Write-PSFMessage "For Field $($child.Name), ID $formFieldId using the mapping $($fieldMapping|ConvertTo-Json -Compress)"
                switch ($fieldMapping.secretProperty) {
                    ignore{}
                    UserName {
                        if ($secretDataHash.secretType -ne $hashTable) {
                            $secretDataHash.secret.userName = $child.Value
                        }
                        else {
                            $secretDataHash.secret."$($child.Name)" = $child.Value
                        }
                    }
                    Password {
                        if ($BuildSecret) {
                            Write-PSFMessage "Building SecureString"
                            $containerWithSecretValue = $ContainerManager.GetContainerItemWithSecretValue($child.id ) | Wait-Task
                            $decryptedPassword = $ContainerManager.DecryptContainerItem($containerWithSecretValue, "some reason for query by API") | Wait-Task
                            # Convert to SecureString
                            [securestring]$secStringPassword = ConvertTo-SecureString $decryptedPassword -AsPlainText -Force

                            if ($secretDataHash.secretType -ne $hashTable) {
                                $secretDataHash.secret.password = $secStringPassword
                            }
                            else {
                                $secretDataHash.secret."$($child.Name)" = $secStringPassword
                            }
                        }
                        else {
                            $secretDataHash.passwordId = $child.id
                        }
                    }
                    SecretMetaData {
                        # TODO There are other Value* properties which might come in handy
                        if ($secretDataHash.secretType -ne $hashTable) {
                            $secretDataHash.metaData."$($child.Name)" = $child.Value
                        }
                        else {
                            $secretDataHash.secret."$($child.Name)" = $child.Value
                        }
                    }
                    Default { Write-PSFMessage "Unknown Mapping type $_" -Level Warning }
                }
            }
            if ($BuildSecret){
                switch ($secretDataHash.secretType) {
                    pscredential {
                        [pscredential]$secretDataHash.secret = New-Object System.Management.Automation.PSCredential ($secretDataHash.secret.userName, $secretDataHash.secret.password)
                    }
                    securestring { $secretDataHash.secret = $secretDataHash.secret.password}
                    hashtable {
                        $secretDataHash.secret += $secretDataHash.metaData
                        # TODO HashtableType has to be implemented
                    }
                }
            }
            $tempHashList += $secretDataHash
        }
        Write-PSFMessage "Created $($tempHashList.count) temp hashtables"
        # The name of the secret infos may not occur more than one, checking this possibility and modifying the corresponding names
        $entriesWithDuplicateNames = $tempHashList | Group-Object -Property name | Where-Object count -gt 1
        foreach ($group in $entriesWithDuplicateNames) {
            Write-PSFMessage "The Secret with the name $($group.Name) occurs $($group.Count) times, adding the GUID to the name"
            foreach ($info in $group.Group) {
                $info.name += " [$($info.id)]"
            }
        }

        foreach ($secretDataHash in $tempHashList) {
            # if ($BuildSecret -and $null -ne $ContainerManager) {
            #     Write-PSFMessage "Creating Credential Object"
            #     $securePassword = $ContainerManager.GetContainerItemWithSecretValue($secretDataHash.passwordId) | Wait-Task

            #     $decryptedPassword = $ContainerManager.DecryptContainerItem($securePassword, "API Test") | Wait-Task

            #     # Convert to SecureString
            #     [securestring]$secStringPassword = ConvertTo-SecureString $decryptedPassword -AsPlainText -Force

            #     [pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($secretDataHash.userName, $secStringPassword)
            #     $secretDataHash.Credential = $credObject
            # }
            if ($AsSecretInformation) {
                Write-PSFMessage "Creating SecretManagement.SecretInformation"
                $results += [Microsoft.PowerShell.SecretManagement.SecretInformation]::new(
                    $secretDataHash.name, # Name of secret
                    $secretDataHash.secretType, # Secret data type [Microsoft.PowerShell.SecretManagement.SecretType]
                    $VaultName, # Name of vault
                    $secretDataHash.metaData)    # Optional Metadata parameter
                }
            else {
                $results += [pscustomobject]$secretDataHash
                Write-PSFMessage "Result-Hash: $([pscustomobject]$secretDataHash)"
            }
        }
        return $results
    }
}