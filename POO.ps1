# Méthode 1
$em = New-Object PSObject

$em | Add-Member -MemberType NoteProperty -Name "Nom" -Value "Abadi"
$em | Add-Member -MemberType NoteProperty -Name "Prenom" -Value "Ihab"

#$em

# Méthode 2 HashTable

$em2 = [PSCustomObject]@{
    Nom = "Toto"
    Prenom= "Titi"
}

#$em2

# Ajout les types de propriétés
$produit = [PSCustomObject]@{
    Nom = "PC"
    Prix = 10
    Stock = 100
}

# Propriété simple
$produit | Add-Member -MemberType NoteProperty -Name "Categorie" -Value "Informatique"
# Propriété calculée
$produit | Add-Member -MemberType ScriptProperty  -Name "PrixTTC" -Value {
    $this.Prix * 1.20
}
# Methode personnalisée
$produit | Add-Member -MemberType ScriptMethod  -Name "AppliquerRemise" -Value {
    param([decimal]$pourcentage)
    $this.Prix = $this.Prix * (1 - $pourcentage / 100)
    return $this
}

$produit | Add-Member -MemberType 

$produit.AppliquerRemise(10)
$produit


$p = Get-Process -Name WMIRegistrationService
$p | Add-Member -MemberType NoteProperty -Name "Commentaire" -Value "Process critique"
$p.Commentaire