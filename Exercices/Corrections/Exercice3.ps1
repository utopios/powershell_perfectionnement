# Classe mère
class SystemAccount {
    [string]$Name
    [string]$Login
    [string]$CreationDate

    SystemAccount([string]$name, [string]$login) {
        $this.Name = $name
        $this.Login = $login
        $this.CreationDate = Get-Date
    }

    [string]GetInfos() {
        return "Compte $($this.name), login $($this.login)"
    }

    [string] ExecuteDefaultAction() {
        return "Defaut action from base class"
    }
}

# Classes filles 
class StandardUser : SystemAccount {
    # Constructeur
    StandardUser([string]$name, [string]$login) : base($name, $login) {
        
    }
    
    # Méthode spécifique : Demande de permission
    [string] RequestPermission([string]$resource) {
        $message = "L'utilisateur $($this.Login) demande l'accès à la ressource: $resource"
        Write-Host $message -ForegroundColor Yellow
        return "Demande d'accès enregistrée pour $resource"
    }

    [string] ExecuteDefaultAction() {
        return "Defaut action from base class from standard user $($this.Login)"
    }
    
   
}


class DomainAdmin : SystemAccount {
    # Propriété supplémentaire
    [string]$PrivilegeLevel
    
    # Constructeur
    DomainAdmin([string]$name, [string]$login, [string]$privilegeLevel) : base($name, $login) {
        $this.PrivilegeLevel = $privilegeLevel
    }
    
    # Méthode spécifique : Réinitialiser un mot de passe
    [string] ResetPassword([string]$user) {
        $message = "ADMIN: Réinitialisation du mot de passe pour l'utilisateur '$user' par $($this.Login)"
        Write-Host $message -ForegroundColor Red
        return "Mot de passe réinitialisé pour $user"
    }
    
    # Méthode spécifique : Ajouter un membre au groupe
    [string] AddGroupMember([string]$user, [string]$group) {
        $message = "ADMIN: Ajout de '$user' au groupe '$group' par $($this.Login)"
        Write-Host $message -ForegroundColor Red
        return "Utilisateur $user ajouté au groupe $group"
    }
    
    # Redéfinition de GetInfos avec informations supplémentaires
    [string] GetInfos() {
        $baseInfo = ([SystemAccount]$this).GetInfos()
        return "$baseInfo | Niveau de privilège: $($this.PrivilegeLevel)"
    }

    [string] ExecuteDefaultAction() {
        return "Defaut action from base class from domain admin $($this.Login)"
    }
    
    
}


class ServiceAccount : SystemAccount {
    # Constructeur
    ServiceAccount([string]$name, [string]$login) : base($name, $login) {
       
    }
    
    # Méthode spécifique : Exécuter une tâche de maintenance
    [string] RunMaintenanceTask() {
        $message = "Tâche exécutée par $($this.Login)"
        Write-Host $message -ForegroundColor Green
        return $message
    }

    [string] ExecuteDefaultAction() {
        return "Defaut action from base class from service account $($this.Login)"
    }
     
}

$standardUser = [StandardUser]::new("standard 1", "Login 1")
$adminDomain = [DomainAdmin]::new("admin 1", "login admin 1", "admin")
$serviceAccount = [ServiceAccount]::new("service 1", "login service account 1")

$accounts = @($standardUser, $adminDomain)

$accounts += $serviceAccount

$accounts

foreach($a in $accounts) {
    $a.ExecuteDefaultAction()
}
