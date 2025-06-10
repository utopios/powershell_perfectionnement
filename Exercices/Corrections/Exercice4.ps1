function Manage-UserAccount {
    [CmdletBinding(DefaultParameterSetName = "Create")]
    param(
        [Parameter( Mandatory = $true)]
        [string]$Username,
        [Parameter(ParameterSetName = "Create", Mandatory = $true)]
        [string]$Password,
        [Parameter(ParameterSetName = "Disable", Mandatory = $true)]
        [Switch]$Disable
    )

    Write-Verbose "Debut d'execution de la fonction Manage-UserAccount avec $($Username)"
    Write-Verbose "Jeu de paramètre utilisé $($PSCmdlet.ParameterSetName)"

    switch ($PSCmdlet.ParameterSetName) {
        'Create' {
            Write-Verbose "Ajout d'un utilisateur"
            Write-Output "L'utilisateur $Username a été correctement ajouté"
        }

        'Disable' {
            Write-Verbose "désactivation d'un utilisateur"
            Write-Output "L'utilisateur $Username a été correctement désactivé"
        }

        default {
            Write-Error "Erreur de les parameterSetName"
        }
    }
    
}

Manage-UserAccount -Username "Ihab" -Password "123456" -Verbose

Manage-UserAccount -Username "Ihab" -Disable -Verbose