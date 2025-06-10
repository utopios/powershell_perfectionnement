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
 
}Nom-Fonction -Param1 "ttztz" -Param2 10 -Debug