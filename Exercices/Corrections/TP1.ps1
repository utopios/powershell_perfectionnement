function Find-FileAdvanced {
    [CmdletBinding(DefaultParameterSetName = "ByName", SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName=$true)]
        [string[]] $Path,

        [Parameter(ParameterSetName="ByName", Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $Name,

        [Parameter(ParameterSetName="ByName", Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string[]] $Extensions,
        
        [Parameter(ParameterSetName="ByName", Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
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

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string[]] $Include,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string[]] $Exclude,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Switch] $Hidden
        
    )

    begin {
        Write-Verbose "Debut de l'utilisation de la fonction find-fileAdvanced avec les arguments :"
    }

    process {

    }

    end {
        Write-Verbose "Fin de l'utilisation de la fonction find-fileAdvanced avec les arguments :"
    }
}