# Exercice : Créer un inventaire simplifié de serveurs

- Créer et manipuler des objets PowerShell pour modéliser un petit inventaire de serveurs, avec leurs principales caractéristiques.
Consignes :

- Créer 3 objets représentant chacun un serveur.
Chaque objet doit contenir les propriétés suivantes :

    Nom

    Adresse IP

    Rôle (ex: "DNS", "Web", "Fichier")

    Système d’exploitation

    État du service critique (ex: "OK", "Arrêté")

- Stocker ces objets dans un tableau.

- Afficher une vue tableau de tous les serveurs (Format-Table ou simple Write-Output).

- Ajouter une propriété personnalisée pour chaque serveur indiquant s’il est en production (IsProduction, booléen ou chaîne).

- Filtrer et afficher uniquement les serveurs en production et dont l’état du service critique est "OK".