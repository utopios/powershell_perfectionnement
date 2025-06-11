# **TP 1**

## **Titre** : **Gestionnaire de fichiers et dossiers avec options avancées**

### **Objectif**

Créer des fonctions PowerShell exploitant les fonctionnalités avancées de gestion des paramètres :

- **Sets de paramètres** pour différents modes d’utilisation
- **Validation avancée** des entrées utilisateur
- **Support du pipeline** avec différents types d’objets

-----

## **Contexte**

Développer un outil de gestion de fichiers permettant de :

1. Rechercher des fichiers selon différents critères
1. Copier/déplacer des fichiers avec options avancées
1. Nettoyer des dossiers selon des règles spécifiques

-----

## **Fonctions à implémenter**

### **1. Fonction : `Find-FileAdvanced`**

#### **Spécifications des paramètres :**

```powershell
Find-FileAdvanced [-Path] <string[]> 
                  # Set "ByName"
                  [-Name <string>] [-Extension <string[]>] [-Recurse]
                  # Set "BySize" 
                  [-MinSize <long>] [-MaxSize <long>] [-SizeUnit <string>]
                  # Set "ByDate"
                  [-CreatedAfter <datetime>] [-CreatedBefore <datetime>]
                  [-ModifiedAfter <datetime>] [-ModifiedBefore <datetime>]
                  # Communs
                  [-Include <string[]>] [-Exclude <string[]>] [-Hidden]
```

#### **Exigences :**

1. **3 Sets de paramètres mutuellement exclusifs** :
- `ByName` : Recherche par nom/extension
- `BySize` : Recherche par taille
- `ByDate` : Recherche par dates
2. **Validations requises** :
- `Path` : Doit exister et être accessible
- `Extension` : Format “.ext” obligatoire
- `SizeUnit` : Limité à “B”, “KB”, “MB”, “GB”
- `MinSize`/`MaxSize` : MinSize < MaxSize
- Dates : Cohérence des plages temporelles
3. **Support pipeline** :
- Accepter des chemins depuis le pipeline
- Accepter des objets `FileInfo` et `DirectoryInfo`

-----

### **2. Fonction : `Copy-FileAdvanced`**

#### **Spécifications des paramètres :**

```powershell
Copy-FileAdvanced [-Source] <string[]> [-Destination] <string>
                  # Set "Simple"
                  [-Overwrite] [-CreateDestination]
                  # Set "Filtered" 
                  [-Filter <string>] [-ExcludePattern <string[]>] [-MaxDepth <int>]
                  # Set "Backup"
                  [-BackupExisting] [-BackupSuffix <string>] [-CompressBackup]
                  # Communs
                  [-Recurse] [-PreserveTimestamps] [-WhatIf] [-Verbose]
```

#### **Exigences :**

1. **3 Sets de paramètres** :
- `Simple` : Copie basique avec écrasement
- `Filtered` : Copie avec filtres avancés
- `Backup` : Copie avec sauvegarde des fichiers existants
2. **Validations complexes** :
- `Source` : Validation d’existence avec message personnalisé
- `Destination` : Validation du dossier parent
- `Filter` : Pattern valide (regex)
- `MaxDepth` : Entre 1 et 10
- `BackupSuffix` : Format spécifique (ex: .bak, .old)
3. **Pipeline avancé** :
- Support `ValueFromPipeline` pour Source
- Support `ValueFromPipelineByPropertyName` pour objets complexes

-----

### **3. Fonction : `Remove-FilesByRule`**

#### **Spécifications des paramètres :**

```powershell
Remove-FilesByRule [-Path] <string[]>
                   # Set "ByAge"
                   [-OlderThan <timespan>] [-NewerThan <timespan>]
                   # Set "ByPattern"
                   [-NamePattern <string>] [-ContentPattern <string>]
                   # Set "BySize"  
                   [-EmptyFiles] [-LargerThan <string>] [-SmallerThan <string>]
                   # Communs
                   [-Recurse] [-Force] [-WhatIf] [-Confirm] [-LogActions]
```

#### **Exigences :**

1. **Validation stricte** avec attributs avancés
2. **Pipeline pour traitement par lot**
3. **Gestion sécurisée** (WhatIf/Confirm obligatoire)

