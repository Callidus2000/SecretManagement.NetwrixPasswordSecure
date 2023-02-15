function Wait-Task {
    <#
    .SYNOPSIS
    Helper function for waiting of tasks to be finished.

    .DESCRIPTION
    Helper function for waiting of tasks to be finished.

    .PARAMETER Task
    The task to be waited for.

    .EXAMPLE
    $conMan.UpdateContainer($con)| Wait-Task

    Waits until the update is finished.

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.Threading.Tasks.Task[]]$Task
    )

    Begin {
        $Tasks = @()
    }

    Process {
        $Tasks += $Task
    }

    End {
        try {
            While (-not [System.Threading.Tasks.Task]::WaitAll($Tasks, 200)) {}
            $Tasks.ForEach( { $_.GetAwaiter().GetResult() })
        }
        catch {
            # Write-PSFMessage -Level Host "$_"
            if ($PSBoundParameters['Debug']) {
                Write-PSFMessage "Tasks= $($Tasks|ConvertTo-Json)"
            }
            throw $_
        }
    }
}

Set-Alias -Name await -Value Wait-Task -Force