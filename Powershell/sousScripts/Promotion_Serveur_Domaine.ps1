# Importer le module pour écrire des logs
Import-Module ModuleLog

Write-Log "Promotion du serveur en contrôleur de domaine..." -ForegroundColor Cyan

# Demander le nom de domaine souhaité
$nomDeDomaine = Read-Host "Entrez le nom de domaine (ex : monDomaine.local)"

#C:\Users\Administrateur\Desktop\PowerShell\sousScripts\Ajout_Utilisateur.ps1 -NomDeDomaine $nomDeDomaine

# Demander le mot de passe DSRM
$motDePasseDSRM = Read-Host "Entrez le mot de passe de récupération DSRM" -AsSecureString

# Vérifier si le rôle AD DS est installé
Write-Log "Vérification de la présence du rôle AD DS..." -ForegroundColor Yellow
if (-not (Get-WindowsFeature -Name AD-Domain-Services).Installed) {
    Write-Log "Le rôle AD DS n'est pas installé. Installation en cours..." -ForegroundColor Cyan
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
} else {
    Write-Log "Le rôle AD DS est déjà installé." -ForegroundColor Green
}

# Importer le module ADDSDeployment
Write-Log "Chargement du module ADDSDeployment..." -ForegroundColor Yellow
try {
    Import-Module ADDSDeployment -ErrorAction Stop
    Write-Log "Module ADDSDeployment chargé avec succès." -ForegroundColor Green
} catch {
    Write-Log "Erreur lors du chargement du module ADDSDeployment : $_" -ForegroundColor Red
    return
}

# Promouvoir le serveur en contrôleur de domaine
Write-Log "Promotion du serveur en contrôleur de domaine pour le domaine '$nomDeDomaine'..." -ForegroundColor Cyan
try {
    Install-ADDSForest -DomainName $nomDeDomaine `
        -SafeModeAdministratorPassword $motDePasseDSRM `
        -Force

    Write-Log "Promotion terminée avec succès. Un redémarrage est nécessaire." -ForegroundColor Green
    #Restart-Computer -Force
} catch {
    Write-Log "Erreur lors de la promotion du serveur : $_" -ForegroundColor Red
}
