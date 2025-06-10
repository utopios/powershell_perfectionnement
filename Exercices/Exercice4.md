### **Exercice 4**

**Titre** : Gestion conditionnelle des utilisateurs avec fonctions avancées

---

**Objectif pédagogique** :

Mettre en œuvre une fonction avancée en PowerShell qui :

* Utilise **`[CmdletBinding()]`** avec **`ParameterSetName`** pour différencier deux comportements
* Utilise **`Write-Verbose`** pour tracer les opérations
* Adopte la syntaxe des **fonctions avancées PowerShell (Advanced Functions)**

---

### 🔧 Scénario :

Vous devez créer une fonction appelée `Manage-UserAccount` qui permet de **créer ou désactiver un compte utilisateur** sur un serveur.

---

### 📐 Contraintes :

1. La fonction doit proposer **deux jeux de paramètres distincts** :

   * Jeu de paramètres `Create` : nécessite `UserName`, `Password`
   * Jeu de paramètres `Disable` : nécessite `UserName` et un switch `Disable`

2. Utilisez **`Write-Verbose`** pour indiquer :

   * Quand une action commence
   * Quand elle se termine
   * Les informations utiles à la débogage (nom d'utilisateur concerné, état, etc.)

3. Simulez les actions avec des `Write-Output` (aucune commande système réelle).

---

### 📄 Exemple d’appel attendu :

```powershell
Manage-UserAccount -UserName "jdoe" -Password "Test123!" -Verbose
Manage-UserAccount -UserName "jdoe" -Disable -Verbose
```
