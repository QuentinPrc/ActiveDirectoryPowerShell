# Active Directory PowerShell

Ce projet contient des scripts PowerShell permettant d'automatiser la configuration d'un environnement Active Directory (utilisateurs, groupes, UO, etc.).

## 📁 Contenu du dépôt

- `PowerShell1.ps1` : Script principal à exécuter.
- `PowerShell2.ps1` : Script secondaire appelé par le script principal.
- `utilisateurs_UO_groupes.csv` : Fichier CSV contenant les informations à importer (utilisateurs, unités organisationnelles, groupes).
- `sousScripts/` : Répertoire contenant d'autres scripts complémentaires utilisés par les principaux.

## ⚙️ Instructions

1. **Télécharger l'ensemble du dépôt** :
   - Cliquez sur le bouton `<> Code` puis `Download ZIP` ou utilisez `git clone`.

2. **Exécuter le script principal** :
   - Lancez `PowerShell1.ps1` avec PowerShell en tant qu’administrateur.

## 🔒 Prérequis

- PowerShell 5.1 ou supérieur
- Rôle Active Directory installé sur la machine
- Exécution de scripts autorisée :  
  Vous pouvez vérifier/modifier cela avec la commande suivante dans PowerShell (en administrateur) :

  ```powershell
  Set-ExecutionPolicy Unlimited
