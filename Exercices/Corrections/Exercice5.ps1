function Get-ServiceStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline=$true)]
        [string]$ServiceName
    )

    process {
        $service = Get-Service -Name $ServiceName
        return $service.Status
    }
}

# Get-ServiceStatus -ServiceName "WinRM"

"WinRM", "Spooler" | Get-ServiceStatus