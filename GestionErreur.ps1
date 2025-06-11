try {
 Get-Content "fichier-inexistant.txt" 
 Get-Content "POO.ps1"
}
catch {
 Write-Warning "Erreur lors de la lecture du fichier : $_"
}
