class Serveur {
 [string]$Nom
 [string]$IP
 [string]$Etat
 [datetime]$DateDernierAudit
 Serveur([string]$nom, [string]$ip) {
 $this.Nom = $nom
 $this.IP = $ip
 $this.Etat = "Non vérifié"
 $this.DateDernierAudit = (Get-Date)
 }
 Serveur([string]$nom, [string]$ip, [string]$etat) {
 $this.Nom = $nom
 $this.IP = $ip
 $this.Etat = $etat
 $this.DateDernierAudit = (Get-Date)
 }
 [Serveur]AfficherInfos() {
 Write-Output "Nom=$($this.Nom), IP=$($this.IP), Etat=$($this.Etat), Date=$($this.DateDernierAudit)"
 return $this
 }
} $srv = [Serveur]::new("SRV02", "192.168.1.2", "KO")
$srv.AfficherInfos()
$srv.Etat = "OK"
$srv.AfficherInfos()