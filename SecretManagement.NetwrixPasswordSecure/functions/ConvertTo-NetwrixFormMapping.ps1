﻿function ConvertTo-NetwrixFormMapping {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        $SourceDefinition
    )

    begin {
    }

    process {
        # Write-PSFMessage -Level Host "########### HUUUUUBBBBBAAAA #########"
        foreach ($form in $SourceDefinition) {
            $mappingHash = [ordered]@{}
            $mappingHash.formName = $name
            $mappingHash.id = $form.id
            $mappingHash.fields = @{}
            $passwordFound = $false
            $userNameFound=$false
            foreach ($field in $form.items) {
                if ($field.Position -eq 0) {
                    Write-PSFMessage -Level Host "Name-ID: $($field.id)"
                    $mappingHash.nameId=$field.id
                }

                switch ($field.ContainerItemType) {
                    ContainerItemHeader { $mapToProperty = "SecretMetaData" }
                    ContainerItemIp { $mapToProperty = "SecretMetaData" }
                    ContainerItemMemo { $mapToProperty = "SecretMetaData" }
                    ContainerItemPassword {
                        if (-not $passwordFound) {
                            $mapToProperty = "Password"
                            $passwordFound = $true
                        }
                        else { $mapToProperty = "ignore" }
                    }
                    ContainerItemUserName {
                        if (-not $userNameFound) {
                            $mapToProperty = "UserName"
                            $userNameFound = $true
                        }
                        else { $mapToProperty = "ignore" }
                    }
                    ContainerItemText { $mapToProperty = "SecretMetaData" }
                }
                $mappingHash.fields."$($field.id)" = @{
                    fieldName      = $Field.name
                    secretProperty = $mapToProperty
                    id             = $field.id
                }
            }
            if ($userNameFound -and $passwordFound){
                $mappingHash.secretType="pscredential"
            }else{
                $mappingHash.secretType="securestring"
            }
            $mappingHash
        }
    }

    end {

    }
}