# Classe de base
class Vehicule {
    [string]$Marque
    [string]$Modele
    [int]$Annee
    [bool]$EnMarche = $false
    
    Vehicule([string]$marque, [string]$modele, [int]$annee) {
        $this.Marque = $marque
        $this.Modele = $modele
        $this.Annee = $annee
    }
    
    [void] Demarrer() {
        $this.EnMarche = $true
        Write-Host "$($this.Marque) $($this.Modele) démarre..."
    }
    
    [void] Arreter() {
        $this.EnMarche = $false
        Write-Host "$($this.Marque) $($this.Modele) s'arrête..."
    }
    
    [string] ToString() {
        return "$($this.Marque) $($this.Modele) ($($this.Annee))"
    }
}

# Classe dérivée
class Voiture : Vehicule {
    [int]$NombrePortes
    [string]$TypeCarburant
    
    Voiture([string]$marque, [string]$modele, [int]$annee, [int]$portes, [string]$carburant) : base($marque, $modele, $annee) {
        $this.NombrePortes = $portes
        $this.TypeCarburant = $carburant
    }
    
    [void] OuvrirCoffre() {
        Write-Host "Coffre de la $($this.Marque) $($this.Modele) ouvert"
    }
    
    # Surcharge de la méthode Demarrer
    [void] Demarrer() {
        Write-Host "Vérification du carburant: $($this.TypeCarburant)"
        ([Vehicule]$this).Demarrer()  # Appel de la méthode parent
    }
}

# Autre classe dérivée
class Moto : Vehicule {
    [int]$Cylindree
    [bool]$AvecSidecar = $false
    
    Moto([string]$marque, [string]$modele, [int]$annee, [int]$cylindree) : base($marque, $modele, $annee) {
        $this.Cylindree = $cylindree
    }
    
    [void] FaireWheeling() {
        if ($this.EnMarche) {
            Write-Host "$($this.Marque) $($this.Modele) fait un wheeling!"
        } else {
            Write-Host "La moto doit être démarrée pour faire un wheeling"
        }
    }
}

# Utilisation
$voiture = [Voiture]::new("Peugeot", "308", 2020, 5, "Essence")
$moto = [Moto]::new("Yamaha", "R1", 2019, 1000)

$voiture.Demarrer()
$voiture.OuvrirCoffre()

$moto.Demarrer()
$moto.FaireWheeling()

# Polymorphisme - traiter différents objets de la même manière
$vehicules = @($voiture, $moto)
foreach ($v in $vehicules) {
    Write-Host "Véhicule: $($v.ToString())"
    $v.Arreter()
}