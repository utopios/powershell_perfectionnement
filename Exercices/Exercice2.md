# Exercice : Création d’un catalogue d’audits de tâches planifiées
**Objectif :**

Créer un inventaire structuré (objet par tâche) des tâches planifiées présentes sur la machine, puis enrichir chaque objet avec des informations supplémentaires (type, risque, etc.).
**Contexte :**

Vous êtes responsable de la sécurité des systèmes. Vous devez recenser toutes les tâches planifiées actives sur un serveur et déterminer si elles sont sûres, manuelles ou automatiques, et si elles présentent un risque potentiel (par exemple, si elles appellent des scripts .vbs, .bat ou .exe inconnus).
Étapes attendues :

- Récupérer les tâches planifiées avec Get-ScheduledTask.

- Pour chaque tâche, créer un objet contenant :

    Nom

    Chemin

    Auteur (via Get-ScheduledTaskInfo)

    DernierÉtat

    Commande exécutée (tirée de Actions si possible)

- Ajouter dynamiquement une propriété EstRisquePotentiel via Add-Member, si la tâche appelle un script ou programme non signé ou dans un chemin suspect (C:\Temp, .vbs, .bat, .exe dans AppData, etc.).