# Importer le module pour écrire des logs
Import-Module ModuleLog

Write-Log "Installation du Gestionnaire de Serveur"

# Vérifier si l'interface graphique ou les outils de gestion sont disponibles
if (-not (Get-WindowsFeature -Name ServerManager-Core-RSAT)) {
    Write-Log "Le Gestionnaire de Serveur n'est pas installé, installation en cours"

    Install-WindowsFeature -Name ServerManager-Core-RSAT -IncludeManagementTools

    # Vérification de l'installation
    if ((Get-WindowsFeature -Name ServerManager-Core-RSAT).Installed) {
        Write-Log "Installation réussie"
    } else {
        Write-Log "Échec de l'installation"
    }
} else {
    Write-Log "Le Gestionnaire de Serveur est déjà installé"
}
