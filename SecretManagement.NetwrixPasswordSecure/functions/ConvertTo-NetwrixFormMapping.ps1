function ConvertTo-NetwrixFormMapping {
    <#
    .SYNOPSIS
    Internal converter for converting a Source Definition to a form mapping.

    .DESCRIPTION
    Internal converter for converting a Source Definition to a form mapping.

    .PARAMETER SourceDefinition
    The input definition

    .EXAMPLE
    An example

    has to be provided

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    [OutputType([OrderedDictionary])]
    param (
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        $SourceDefinition
    )

    begin {
    }

    process {
        # Write-PSFMessage "########### HUUUUUBBBBBAAAA #########"
        foreach ($form in $SourceDefinition) {
            $mappingHash = [ordered]@{}
            $mappingHash.formName = $name
            $mappingHash.id = $form.id
            $mappingHash.fields = @{}
            $passwordFound = $false
            $userNameFound=$false
            foreach ($field in $form.items) {
                if ($field.Position -eq 0) {
                    Write-PSFMessage "Name-ID: $($field.id)"
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