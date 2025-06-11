function Nom-Fonction {
    [CmdletBinding()]
    param(
        [string]$Param1,
        [int]$Param2
    )
    # Corps de la fonction
    Write-Debug "Information debug param 1 est un string et param 2 est int"
    Write-Output "Param1 = $Param1, Param2 = $Param2"
    Write-Verbose "Plus d'informations"
 
}

function Supprimer-Fichier {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'high')]
    param(
        [string]$chemin
    )
    if ($PSCmdlet.ShouldProcess($chemin, "Suppression")) {
        Remove-item $chemin
    }
}


# Nom-Fonction -Param1 "ttztz" -Param2 10 -Debug

# Supprimer-Fichier -chemin "file.txt" 

function Afficher-Message {
    [CmdletBinding(DefaultParameterSetName = "FullName")]
    param(
        [Parameter(ParameterSetName = "SimpleName", Mandatory = $true)]
        [string]$Nom,
        [Parameter(ParameterSetName = "SimpleName", Mandatory = $true)]
        [string]$Prenom,
        [Parameter(ParameterSetName = "FullName", Mandatory = $true)]
        [string]$NomComplet
    )
    if ($PSCmdlet.ParameterSetName -eq "SimpleName") {
        return "$($Nom) $($Prenom)"
    }
    elseif ($PSCmdlet.ParameterSetName -eq "FullName") {
        return $NomComplet
    }
}

# Afficher-Message -Nom "ABADI" -Prenom "Ihab"

function Afficher-Nom {
    [CmdletBinding()]
    param(
    [Parameter(ValueFromPipeline=$true)]
    [string]$Name
    )

    begin {
        Write-Verbose "Debut de l'appel à la fonction"
    }

    process {
        Write-Output "Name $Name"
    }

    end {
        Write-Verbose "Fin de l'appel de la fonction"
    }

}

# Afficher-Nom -Name "Ihab" -Verbose

# "Toto", "tata", "Titi" | Afficher-Nom -Verbose

function Afficher-Infos {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName=$true)]
        [string]$Nom,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName=$true)]
        [string]$Prenom
    )

    process {
        Write-Host "Nom $Nom, Prénom $Prenom"
    }
}

$personnes = @(
    [PSCustomObject]@{
        Nom = "abadi"
        Prenom = "Ihab"
    },
    [PSCustomObject]@{
        Nom = "Toto"
        Prenom = "tata"
    }
)

$personnes | Afficher-Infos