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

Afficher-Message -Nom "ABADI" -Prenom "Ihab"