function Convert-Size {
    param(
        [long] $Size,
        [string] $Unit
    )
    switch ($Unit) {
        'KB' { return $Size * 1KB }
        'MB' { return $Size * 1MB }
        'GB' { return $Size * 1GB }
        Default {return $Size}
    }
}
function Find-FileAdvanced {
    [CmdletBinding(DefaultParameterSetName = "ByName", SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName=$true)]
        [string[]] $Paths,

        [Parameter(ParameterSetName="ByName",  ValueFromPipelineByPropertyName=$true)]
        [string] $Name,

        [Parameter(ParameterSetName="ByName",  ValueFromPipelineByPropertyName=$true)]
        [string[]] $Extensions,
        
        [Parameter(ParameterSetName="ByName",  ValueFromPipelineByPropertyName=$true)]
        [Switch] $Recurse,

        [Parameter(ParameterSetName="BySize", Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [long] $MinSize,
        
        [Parameter(ParameterSetName="BySize", Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [long] $MaxSize,

        [Parameter(ParameterSetName="BySize", Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $SizeUnit,

        [Parameter(ParameterSetName="ByDate", Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [datetime] $CreatedAfter,

        [Parameter(ParameterSetName="ByDate", Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [datetime] $CreatedBefore,

        [Parameter(ParameterSetName="ByDate", Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [datetime] $ModifiedAfter,

        [Parameter(ParameterSetName="ByDate", Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [datetime] $ModifiedBefore,

        [Parameter( ValueFromPipelineByPropertyName=$true)]
        [string[]] $Include,

        [Parameter( ValueFromPipelineByPropertyName=$true)]
        [string[]] $Exclude,

        [Parameter( ValueFromPipelineByPropertyName=$true)]
        [Switch] $Hidden
        
    )

    begin {
        Write-Verbose "Debut de l'utilisation de la fonction find-fileAdvanced avec les arguments :"
        
    }

    process {
        $allfiles = @()
        foreach($path in $Paths) {
            Write-Verbose "Debut de recherche dans $path"
            $options = if($Recurse) { "-Recurse" } else {""}
            $files = Get-ChildItem -Path $path -File -Recurse | Where-Object {
                $file = $_
                
                switch ($PSCmdlet.ParameterSetName) {
                    "ByName" { 
                        $file.Name -like "$Name*" -and 
                        $Extensions -contains $file.Extension
                     }
                    "BySize" { 
                        $minBytes = Convert-Size -Size $MinSize -Unit $SizeUnit
                        $maxBytes = Convert-Size -Size $MaxSize -Unit $SizeUnit
                        $file.Length -gt $minBytes -and $file.Length -lt $maxBytes
                    }
                    "ByDate" {  
                        Write-Verbose "$($file.CreationTime) $($file.LastWriteTime)"
                        ($file.CreationTime -gt $CreatedAfter -and $file.CreationTime -lt $CreatedBefore)  -and ($file.LastWriteTime -gt $ModifiedAfter -and $file.LastAccessTime -lt $ModifiedBefore)
                     }
                }
            }
            Write-Verbose "Fichiers trouvés $files avec $options"
            $allfiles += $files
        }
        return $allfiles
    }

    end {
        Write-Verbose "Fin de l'utilisation de la fonction find-fileAdvanced avec les arguments :"
    }
}

# [PSCustomObject]@{
#     Paths = @("C:\Users\Administrateur")
#     Recurse = $true
# } | Find-FileAdvanced -Verbose

# [PSCustomObject]@{
#     Paths = @("C:\Users\Administrateur\Downloads")
#     Name = "Git"
#     Extensions = @('.exe', '.bat')
# } | Find-FileAdvanced -Verbose

# [PSCustomObject]@{
#     Paths = @("C:\Users\Administrateur\Downloads")
#     MinSize = 10
#     MaxSize = 1000 
#     SizeUnit = "MB"
# } | Find-FileAdvanced -Verbose

[PSCustomObject]@{
    Paths = @("C:\Users\Administrateur\Downloads")
    CreatedAfter = "09/06/2025"
    CreatedBefore = "11/06/2025"
    ModifiedBefore = "11/06/2025"
    ModifiedAfter = "09/06/2025"
} | Find-FileAdvanced -Verbose
