# **TP final - Fonctions Avancées PowerShell**

## **Titre** : **Système de monitoring et maintenance automatisée des serveurs**

### **Objectif**
Développer un module PowerShell complet utilisant des fonctions avancées pour automatiser la surveillance et la maintenance d'une infrastructure serveur, en exploitant :
- **Fonctions avec paramètres complexes** (sets de paramètres, validation, pipeline)
- **Gestion d'erreurs avancée** (try/catch, ErrorAction, logging)
- **Fonctions de haut niveau** (Begin/Process/End, ValueFromPipeline)
- **Fonctions utilitaires** et **helpers**
- **Documentation et aide intégrée**

---

## **Contexte**
Vous devez créer un système de monitoring qui permet de :
1. Vérifier l'état de santé des serveurs (CPU, RAM, disque, services)
2. Effectuer des actions de maintenance préventive
3. Générer des rapports détaillés avec alertes
4. Gérer les logs et historiques d'intervention

---

## **Fonctions à implémenter**

### **1. Fonction principale : `Test-ServerHealth`**
**Signature attendue :**
```powershell
Test-ServerHealth [-ComputerName] <string[]> [-Credential <PSCredential>] 
                  [-CheckType <string[]>] [-Threshold <hashtable>] 
                  [-GenerateReport] [-EmailReport] [-LogPath <string>]
                  [-Remediate] [-WhatIf] [-Verbose]
```

**Spécifications :**
- **Sets de paramètres** : `Check`, `Report`, `Maintenance`
- **Validation** : 
  - `ComputerName` doit être un nom valide ou IP
  - `CheckType` limité à : "CPU", "Memory", "Disk", "Services", "Network"
  - `Threshold` avec structure définie
- **Pipeline** : Accepter les noms de serveurs depuis le pipeline
- **Begin/Process/End** : Initialisation, traitement par serveur, rapport final

### **2. Fonctions utilitaires**

#### **`Get-SystemMetrics`**
```powershell
Get-SystemMetrics [-ComputerName] <string> [-MetricType] <string[]> 
                  [-Credential <PSCredential>] [-Timeout <int>]
```
- Récupère métriques système via WMI/CIM
- Gestion timeout et erreurs réseau
- Retourne objet personnalisé avec toutes les métriques

#### **`Invoke-ServerMaintenance`**
```powershell
Invoke-ServerMaintenance [-ComputerName] <string> [-Action] <string[]>
                        [-Credential <PSCredential>] [-Schedule <datetime>]
                        [-MaxConcurrentJobs <int>] [-WhatIf] [-Confirm]
```
- Actions : "CleanTemp", "UpdateWindows", "RestartServices", "DefragDisk"
- Exécution en parallèle avec jobs
- Planification différée
- Demande de confirmation pour actions critiques

#### **`New-HealthReport`**
```powershell
New-HealthReport [-ServerData] <object[]> [-OutputFormat] <string>
                [-OutputPath <string>] [-IncludeGraphs] [-EmailSettings <hashtable>]
```
- Formats : HTML, PDF, CSV, JSON
- Graphiques intégrés (si HTML)
- Envoi automatique par email
- Templates personnalisables

### **3. Fonctions de logging**

#### **Module de logging personnalisé**
```powershell
Write-OperationLog [-Message] <string> [-Level] <string> [-Category <string>]
                   [-LogFile <string>] [-MaxLogSize <long>] [-RotateDaily]

Get-OperationHistory [-ComputerName <string[]>] [-DateRange <datetime[]>]
                     [-Level <string[]>] [-Category <string[]>]
```

---

## **Spécifications techniques détaillées**

### **A. Gestion des paramètres**
1. **Sets de paramètres mutuellement exclusifs** :
   - `Check` : Vérification simple
   - `Report` : Génération de rapport complet
   - `Maintenance` : Actions correctives

2. **Validation avancée** :
   - Attributs `[ValidateScript()]`, `[ValidateSet()]`, `[ValidateRange()]`
   - Validation personnalisée pour structure `$Threshold`
   - Test de connectivité pour `ComputerName`

3. **Paramètres dynamiques** :
   - `CheckType` influence les options disponibles
   - Paramètres conditionnels selon le contexte

### **B. Pipeline et objets**
1. **Support pipeline complet** :
   - `ValueFromPipeline` pour les noms de serveurs
   - `ValueFromPipelineByPropertyName` pour objets complexes
   - Traitement par lot optimisé

2. **Objets de sortie structurés** :
```powershell
[PSCustomObject]@{
    ComputerName = $server
    Timestamp = Get-Date
    OverallHealth = "Healthy|Warning|Critical"
    Metrics = @{
        CPU = @{ Value=45; Threshold=80; Status="OK" }
        Memory = @{ Value=75; Threshold=85; Status="Warning" }
        # ...
    }
    Alerts = @("Service stopped", "Low disk space")
    Actions = @("Restart service", "Clean temp files")
}
```

### **C. Gestion d'erreurs robuste**
1. **Niveaux d'erreur** :
   - Erreurs bloquantes (serveur inaccessible)
   - Warnings (métriques élevées)
   - Informations (actions effectuées)

2. **Try/Catch structuré** :
   - Gestion spécifique par type d'exception
   - Retry automatique avec backoff
   - Logging détaillé des erreurs

3. **ErrorAction personnalisé** :
   - Continue pour erreurs non-critiques
   - Stop pour problèmes majeurs
   - SilentlyContinue avec logging manuel

### **D. Fonctionnalités avancées**
1. **Exécution parallèle** :
   - Jobs PowerShell pour traitement simultané
   - Gestion de la charge (MaxConcurrentJobs)
   - Synchronisation des résultats

2. **Mise en cache** :
   - Cache des credentials
   - Cache des métriques (TTL configuré)
   - Optimisation des appels WMI répétés

3. **Configuration modulaire** :
   - Fichier de configuration JSON/XML
   - Profils par environnement (Dev, Test, Prod)
   - Seuils personnalisables par serveur

---

### **3. Scripts de démonstration**
```powershell
# Exemple 1: Vérification simple
Test-ServerHealth -ComputerName "SRV-01", "SRV-02" -CheckType CPU, Memory -Verbose

# Exemple 2: Rapport complet avec email
Get-Content servers.txt | Test-ServerHealth -GenerateReport -EmailReport

# Exemple 3: Maintenance programmée
Test-ServerHealth -ComputerName $servers -Remediate -WhatIf
```

---

## **Bonus (optionnel)**
- Interface graphique simple (WPF/WinForms)
- Intégration avec systèmes de monitoring (SCOM, Nagios)
- Support multi-plateforme (Core)
- API REST pour interrogation externe
- Dashboard web temps réel

