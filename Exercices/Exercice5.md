### **Exercice 5**

#### **Titre** :  
**"Get-ServiceStatus" - Vérification d'état de service via pipeline**

#### **Objectif** :  
Créer une fonction qui :  
- Accepte des noms de services en entrée via pipeline  
- Retourne leur état (Running/Stopped)  
- Est facile à utiliser pour les tâches quotidiennes  

**Utilisation de base** :
```powershell
# Version simple
Get-ServiceStatus -ServiceName "WinRM", "Spooler"

# Version avec pipeline
"WinRM", "Spooler" | Get-ServiceStatus