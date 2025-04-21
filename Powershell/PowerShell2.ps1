# Importer le module pour écrire des logs
Import-Module ModuleLog

# Obtenir dynamiquement le chemin de base
$cheminBase = Split-Path -Parent $MyInvocation.MyCommand.Path

# Construire dynamiquement le chemin des sous-scripts
$cheminSousScripts = Join-Path -Path $cheminBase -ChildPath "sousScripts"

# Gestionnaire de serveur
Write-Host "Installation du Gestionnaire de Serveur"
& (Join-Path -Path $cheminSousScripts -ChildPath "Gestionnaire_de_serveur.ps1")

# AD DS
Write-Host "Installation des services AD DS"
& (Join-Path -Path $cheminSousScripts -ChildPath "AD_DS.ps1")

# Promotion Serveur de Domaine
Write-Host "Promotion du Serveur en Contrôleur de Domaine"
& (Join-Path -Path $cheminSousScripts -ChildPath "Promotion_Serveur_Domaine.ps1")

# Ajout Utilisateurs, Groupes et UO
Write-Host "Ajout des Utilisateurs, Groupes et UO"
& (Join-Path -Path $cheminSousScripts -ChildPath "Ajout_Utilisateur_et_UO_et_Groupesv3.ps1")

# Création Dossiers Partagés
Write-Host "Création Dossiers Partagés"
& (Join-Path -Path $cheminSousScripts -ChildPath "Dossier_Partage.ps1")

# GPO
Write-Host "Ajout des GPO"
& (Join-Path -Path $cheminSousScripts -ChildPath "GPO.ps1")

# Pop Up Windows
Write-Host "Pop Up Windows"
& (Join-Path -Path $cheminSousScripts -ChildPath "PowershellPopUpWindows.ps1")

# Suppression de la tâche planifiée après exécution
$nomTache = "ExecutionScript" # Nom de la tâche planifiée

try {
    Unregister-ScheduledTask -TaskName $nomTache -Confirm:$false
    Write-Host "La tâche planifiée '$nomTache' a été supprimée après exécution." -ForegroundColor Green
} catch {
    Write-Host "Erreur lors de la suppression de la tâche planifiée : $($_.Exception.Message)" -ForegroundColor Red
}


Write-Host "Un redémarrage est nécessaire." -ForegroundColor Green
Restart-Computer -Force