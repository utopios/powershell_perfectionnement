**Exercice 3**  

**Titre** : **Gestion hiérarchisée des comptes système avec permissions différenciées**  

**Objectif** :  
Créer un système modélisant des utilisateurs et comptes techniques avec des droits spécifiques, en exploitant :  
- **L’héritage** pour éviter la duplication de code  
- **Le polymorphisme** pour un traitement homogène de types différents  

**Scénario** :  
Développer une structure de classes PowerShell représentant :  

1. **`SystemAccount`** (classe mère)  
   - *Propriétés* : `Name`, `Login`, `CreationDate`  
   - *Méthode* : `GetInfos()` → Retourne un résumé formaté  

2. **Classes filles** :  
   - **`StandardUser`** :  
     - *Méthode spécifique* : `RequestPermission($resource)` → Simule une demande d’accès  
   - **`DomainAdmin`** :  
     - *Propriété supplémentaire* : `PrivilegeLevel` (Full/Restricted)  
     - *Méthodes* : `Reset-Password($user)`, `Add-GroupMember()`  
   - **`ServiceAccount`** :  
     - *Méthode spécifique* : `RunMaintenanceTask()` → Log "Tâche exécutée par $($this.Login)"  

3. **Polymorphisme** :  
   - Implémenter une méthode **`ExecuteDefaultAction()`** dans chaque classe (comportement différent selon le type).  

