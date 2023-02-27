function Get-NetwrixUserInput {
    <#
    .SYNOPSIS
    Small helper for getting User Input.

    .DESCRIPTION
    Small helper for getting User Input.

    .PARAMETER Title
    The Title of the question

    .PARAMETER Default
    If no input is entered you can provide a default value.

    .EXAMPLE
    Get-NetwrixUserInput -Title "Enter the username for the vault" -Default $env:USERNAME

    Asks for a username.

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        $Title,
        $Default
    )

    if ($Default) { $Title += " [$Default]" }
    $userInput = Read-Host -Prompt $Title
    if ([string]::IsNullOrWhiteSpace($userInput) -and -not [string]::IsNullOrWhiteSpace($Default)) {
        return $Default
    }
    return $userInput
}