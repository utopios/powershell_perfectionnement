class Serveur {
 [string]$Nom
 [string]$IP
 [string]$Etat
 [string]$Role
 [string] $OS
 [boolean] $IsProduction
 Serveur([string]$nom, [string]$ip, [string]$etat, [string]$role, [string]$os) {
 $this.Nom = $nom
 $this.IP = $ip
 $this.Etat = $etat
 $this.OS = $os
 $this.Role = $role
 $this.IsProduction = $this.IP -like "192.168.10.*"
 }
 
 #[boolean]IsProduction() {
  #  return $this.IP -like "192.168.10.*"
 #}
  
}

$serveur1 = [PSCustomObject]@{
    Nom = "SEV-FICHIER1"
    IP = "192.168.1.1"
    Role = "Fichier"
    OS = "windows server 2019"
    Etat = "OK"
}

$serveur1bis = [Serveur]::new("SEV-FICHIER1","192.168.1.1", "OK", "Fichier", "windows server 2019")

$serveur2 = [PSCustomObject]@{
    Nom = "SEV-WEB1"
    IP = "192.168.1.2"
    Role = "web"
    OS = "windows server 2016"
    Etat = "KO"
}

$serveur3 = [PSCustomObject]@{
    Nom = "SEV-DNS1"
    IP = "192.168.10.10"
    Role = "DNS"
    OS = "windows server 2019"
    Etat = "OK"
}

$serveurs = @($serveur1, $serveur2)

$serveurs += $serveur3

$serveurs += $serveur1bis

$serveurs | Format-Table

# Ajouter un membre

foreach($s in $serveurs) {
    $s | Add-Member -MemberType ScriptProperty -Name "IsProduction" -Value {
        $this.IP -like "192.168.10.*"
    }
}

$serveurs | Format-Table