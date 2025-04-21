# Importer le module pour écrire des logs
Import-Module ModuleLog

# Script principal

# Obtenir dynamiquement le chemin de base du script
$cheminBase = Split-Path -Parent $MyInvocation.MyCommand.Path

# Construire dynamiquement le chemin des sous-scripts
$cheminSousScripts = Join-Path -Path $cheminBase -ChildPath "sousScripts"

# Mise à jour et redémarrage
Write-Log -Message "Début de la mise à jour de Windows"
try {
    & (Join-Path -Path $cheminSousScripts -ChildPath "Mise_a_jour.ps1")
    Write-Log -Message "Mise à jour de Windows terminée"
} catch {
    Write-Log -Message "Erreur pendant la mise à jour de Windows : $_"
}

Write-Log -Message "Début de la mise à jour des pilotes"
try {
    & (Join-Path -Path $cheminSousScripts -ChildPath "Pilotes.ps1")
    Write-Log -Message "Mise à jour des pilotes terminée"
} catch {
    Write-Log -Message "Erreur pendant la mise à jour des pilotes : $_"
}

# Créer une tâche planifiée pour exécuter le script après redémarrage
Write-Log -Message "Création de la tâche planifiée pour exécuter le script après redémarrage"
try {
    & (Join-Path -Path $cheminSousScripts -ChildPath "Creation_Tache_Planifie.ps1")
    Write-Log -Message "Tâche planifiée créée avec succès"
} catch {
    Write-Log -Message "Erreur pendant la création de la tâche planifiée : $_"
}

# Redémarrer l'ordinateur après la création de la tâche
Write-Log -Message "Redémarrage en cours..."
Restart-Computer
