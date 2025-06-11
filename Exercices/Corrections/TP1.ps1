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
            $files = Get-ChildItem -Path $path -File -Recurse
            Write-Verbose "Fichiers trouvés $files avec $options"
            $allfiles += $files
        }
        return $allfiles
    }

    end {
        Write-Verbose "Fin de l'utilisation de la fonction find-fileAdvanced avec les arguments :"
    }
}

[PSCustomObject]@{
    Paths = @("C:\Users\Administrateur")
    Recurse = $true
} | Find-FileAdvanced -Verbose