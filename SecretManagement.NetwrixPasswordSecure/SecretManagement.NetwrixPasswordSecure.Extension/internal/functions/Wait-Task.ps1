function Wait-Task {
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
                Write-PSFMessage "Tasks= $($Tasks|json)"
            }
            throw $_
        }
    }
}

Set-Alias -Name await -Value Wait-Task -Force