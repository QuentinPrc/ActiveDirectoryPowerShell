# Importer le module pour écrire des logs
Import-Module ModuleLog

# Variables globales
$nomDomaine = (Get-ADDomain).DNSRoot # Nom du domaine
$nomGPOVeille = "MiseEnVeille15Minutes" # Nom de la GPO pour la mise en veille
$nomGPORestrictionPanneau = "RestrictionAccesPanneauConfiguration" # Nom de la GPO pour la restriction
$nomGPOPolitiqueMotDePasse = "PolitiqueMotDePasseComplexe" # Nom de la GPO pour la politique de mot de passe
$groupeUtilisateurs = "Utilisateurs du domaine" # Groupe avec les utilisateurs standards
$groupeAdmins = "Admins du domaine" # Groupe des administrateurs du domaine
$cibleDomaine = "DC=monDomaine,DC=local" # Cible pour appliquer les GPO

# ----------------------

# Création et configuration de la GPO pour la mise en veille
if (-not (Get-GPO -Name $nomGPOVeille -ErrorAction SilentlyContinue)) {
    $GPOVeille = New-GPO -Name $nomGPOVeille -Domain $nomDomaine
    Write-Log "La GPO '$nomGPOVeille' a été créée." -ForegroundColor Green
} else {
    $GPOVeille = Get-GPO -Name $nomGPOVeille
    Write-Log "La GPO '$nomGPOVeille' existe déjà." -ForegroundColor Yellow
}

# Configurer les paramètres de mise en veille
Set-GPRegistryValue -Name $nomGPOVeille `
    -Key "HKCU\Control Panel\PowerCfg" `
    -ValueName "CurrentPowerPolicy" `
    -Type String `
    -Value "3"

Set-GPRegistryValue -Name $nomGPOVeille `
    -Key "HKCU\Software\Policies\Microsoft\Windows\CurrentVersion\Power" `
    -ValueName "ACSettingIndex" `
    -Type DWORD `
    -Value 900

Set-GPRegistryValue -Name $nomGPOVeille `
    -Key "HKCU\Software\Policies\Microsoft\Windows\CurrentVersion\Power" `
    -ValueName "DCSettingIndex" `
    -Type DWORD `
    -Value 900

Write-Log "La configuration de la GPO '$nomGPOVeille' est terminée." -ForegroundColor Green

# ----------------------

# Création et configuration de la GPO pour restreindre l'accès au panneau de configuration et au registre
if (-not (Get-GPO -Name $nomGPORestrictionPanneau -ErrorAction SilentlyContinue)) {
    $GPORestrictionPanneau = New-GPO -Name $nomGPORestrictionPanneau -Domain $nomDomaine
    Write-Log "La GPO '$nomGPORestrictionPanneau' a été créée." -ForegroundColor Green
} else {
    $GPORestrictionPanneau = Get-GPO -Name $nomGPORestrictionPanneau
    Write-Log "La GPO '$nomGPORestrictionPanneau' existe déjà." -ForegroundColor Yellow
}

# Configurer les restrictions
Set-GPRegistryValue -Name $nomGPORestrictionPanneau `
    -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
    -ValueName "NoControlPanel" `
    -Type DWORD `
    -Value 1

Set-GPRegistryValue -Name $nomGPORestrictionPanneau `
    -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" `
    -ValueName "DisableRegistryTools" `
    -Type DWORD `
    -Value 1

# Configurer les permissions
Set-GPPermissions -Name $nomGPORestrictionPanneau -PermissionLevel GpoApply -TargetName $groupeUtilisateurs -TargetType Group
Set-GPPermissions -Name $nomGPORestrictionPanneau -PermissionLevel GpoRead -TargetName $groupeUtilisateurs -TargetType Group
Set-GPPermissions -Name $nomGPORestrictionPanneau -PermissionLevel None -TargetName $groupeAdmins -TargetType Group

Write-Log "La GPO '$nomGPORestrictionPanneau' est configurée, restriction pour les utilisateurs et exclusion des administrateurs." -ForegroundColor Green

# ----------------------

# Création et configuration de la GPO pour la politique de mot de passe
if (-not (Get-GPO -Name $nomGPOPolitiqueMotDePasse -ErrorAction SilentlyContinue)) {
    $GPOPolitiqueMotDePasse = New-GPO -Name $nomGPOPolitiqueMotDePasse -Domain $nomDomaine
    Write-Log "La GPO '$nomGPOPolitiqueMotDePasse' a été créée." -ForegroundColor Green
} else {
    $GPOPolitiqueMotDePasse = Get-GPO -Name $nomGPOPolitiqueMotDePasse
    Write-Log "La GPO '$nomGPOPolitiqueMotDePasse' existe déjà." -ForegroundColor Yellow
}

# Configurer la politique de mot de passe
Set-GPRegistryValue -Name $nomGPOPolitiqueMotDePasse `
    -Key "HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" `
    -ValueName "MinimumPasswordLength" `
    -Type DWORD `
    -Value 8

Set-GPRegistryValue -Name $nomGPOPolitiqueMotDePasse `
    -Key "HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" `
    -ValueName "PasswordComplexity" `
    -Type DWORD `
    -Value 1

Set-GPRegistryValue -Name $nomGPOPolitiqueMotDePasse `
    -Key "HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" `
    -ValueName "PasswordHistorySize" `
    -Type DWORD `
    -Value 24

Set-GPRegistryValue -Name $nomGPOPolitiqueMotDePasse `
    -ValueName "MaximumPasswordAge" `
    -Type DWORD `
    -Value 90

Write-Log "La politique de mot de passe complexe a été configurée dans la GPO '$nomGPOPolitiqueMotDePasse'." -ForegroundColor Green

# ----------------------

# Désactiver l'installation de pilotes pour les périphériques de stockage USB
Write-Log "Désactivation de l'installation des pilotes pour les périphériques USB" -ForegroundColor Yellow
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR" -Name "Start" -Value 4
Write-Log "Installation des pilotes USB désactivée." -ForegroundColor Green

# Bloquer l'accès en écriture aux disques USB
Write-Log "Blocage de l'accès en écriture aux disques USB" -ForegroundColor Yellow
New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\StorageDevicePolicies" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\StorageDevicePolicies" -Name "WriteProtect" -Value 1
Write-Log "Accès en écriture aux disques USB bloqué" -ForegroundColor Green

# Notification de succès
Write-Log "Les périphériques USB sont maintenant désactivés pour l'écriture et l'installation" -ForegroundColor Green

# ----------------------

# Réactiver l'installation des pilotes USB
#Write-Log "Réactivation de l'installation des pilotes USB" -ForegroundColor Yellow
#Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR" -Name "Start" -Value 3
#Write-Log "Installation des pilotes USB réactivée" -ForegroundColor Green

# Débloquer l'accès en écriture aux disques USB
#Write-Log "Déblocage de l'accès en écriture aux disques USB" -ForegroundColor Yellow
#Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\StorageDevicePolicies" -Name "WriteProtect" -Value 0
#Write-Log "Accès en écriture aux disques USB débloqué" -ForegroundColor Green

# ----------------------

# Désactiver l'invite de commande
$nomGPODesacCMD = "DesactivationInviteCommande"

if (-not (Get-GPO -Name $nomGPODesacCMD -ErrorAction SilentlyContinue)) {
    $GPODesactCMD = New-GPO -Name $nomGPODesacCMD
} else {
    $GPODesactCMD = Get-GPO -Name $nomGPODesacCMD
}

Set-GPRegistryValue -Name $nomGPODesacCMD `
    -Key "HKCU\Software\Policies\Microsoft\Windows\System" `
    -ValueName "DisableCMD" `
    -Type DWORD `
    -Value 1

# Configurer les permissions
Set-GPPermissions -Name $nomGPORestrictionPanneau -PermissionLevel GpoApply -TargetName $groupeUtilisateurs -TargetType Group
Set-GPPermissions -Name $nomGPORestrictionPanneau -PermissionLevel GpoRead -TargetName $groupeUtilisateurs -TargetType Group
Set-GPPermissions -Name $nomGPORestrictionPanneau -PermissionLevel None -TargetName $groupeAdmins -TargetType Group

Write-Log "Désactivation Invite de Commande actif" -ForegroundColor Green

# ----------------------

# Mise à jour de Windows Update automatiquement
$nomGPOWindowsUpdate = "WindowsUpdateAuto"

if (-not (Get-GPO -Name $nomGPOWindowsUpdate -ErrorAction SilentlyContinue)) {
    $GPOWindowsUpdate = New-GPO -Name $nomGPOWindowsUpdate
} else {
    $GPOWindowsUpdate = Get-GPO -Name $nomGPOWindowsUpdate
}

Set-GPRegistryValue -Name $nomGPOWindowsUpdate `
    -Key "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" `
    -ValueName "NoAutoUpdate" `
    -Type DWORD `
    -Value 0

Set-GPRegistryValue -Name $nomGPOWindowsUpdate `
    -Key "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" `
    -ValueName "AUOptions" `
    -Type DWORD `
    -Value 4

# ----------------------

# Optimisation de la batterie de PC Portable
$nomGPOOptimisationBatterie = "OptimisationBatterie"

# Vérification et création de la GPO
if (-not (Get-GPO -Name $nomGPOOptimisationBatterie -ErrorAction SilentlyContinue)) {
    $GPOBatterie = New-GPO -Name $nomGPOOptimisationBatterie
    Write-Log "La GPO '$nomGPOOptimisationBatterie' a été créée avec succès." -ForegroundColor Green
} else {
    $GPOBatterie = Get-GPO -Name $nomGPOOptimisationBatterie
    Write-Log "La GPO '$nomGPOOptimisationBatterie' existe déjà." -ForegroundColor Yellow
}

# Appliquer les réglages de luminosité de l'écran via script d'ouverture de session
$scriptLuminosite = @"
(Get-WmiObject -Namespace root/wmi -Class WmiMonitorBrightnessMethods).WmiSetBrightness(1, 50)
"@
$scriptPath = "\\\\$($nomDomaine)\\NETLOGON\\SetScreenBrightness.ps1"
Set-Content -Path $scriptPath -Value $scriptLuminosite
Set-GPRegistryValue -Name $nomGPOOptimisationBatterie `
    -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" `
    -ValueName "LogonScript" `
    -Type String `
    -Value "SetScreenBrightness.ps1"

# Activer le mode économie d'énergie
Set-GPRegistryValue -Name $nomGPOOptimisationBatterie `
    -Key "HKLM\SYSTEM\CurrentControlSet\Control\Power" `
    -ValueName "ActivePowerScheme" `
    -Type String `
    -Value "SCHEME_MAX"

# Configurer les délais de mise en veille
Set-GPRegistryValue -Name $nomGPOOptimisationBatterie `
    -Key "HKCU\Control Panel\PowerCfg" `
    -ValueName "StandbyTimeoutAC" `
    -Type DWORD `
    -Value 15

Set-GPRegistryValue -Name $nomGPOOptimisationBatterie `
    -Key "HKCU\Control Panel\PowerCfg" `
    -ValueName "StandbyTimeoutDC" `
    -Type DWORD `
    -Value 5

# Optimiser les paramètres de puissance pour les performances
Set-GPRegistryValue -Name $nomGPOOptimisationBatterie `
    -Key "HKCU\Control Panel\PowerCfg" `
    -ValueName "MonitorTimeoutAC" `
    -Type DWORD `
    -Value 5

Set-GPRegistryValue -Name $nomGPOOptimisationBatterie `
    -Key "HKCU\Control Panel\PowerCfg" `
    -ValueName "MonitorTimeoutDC" `
    -Type DWORD `
    -Value 2

# Configurer les effets visuels pour améliorer l'autonomie
$visualEffectsKey = "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
$effects = @("MinAnimate", "DropShadow", "SmoothScroll", "TaskbarAnimations", "Fade")
foreach ($effect in $effects) {
    Set-GPRegistryValue -Name $nomGPOOptimisationBatterie `
        -Key $visualEffectsKey `
        -ValueName $effect `
        -Type DWORD `
        -Value 0
}

# Désinstaller Xbox Game Bar
$scriptDesinstallationXbox = @"
Get-AppxPackage *Xbox* | Remove-AppxPackage
"@
$scriptPathXbox = "\\\\$($nomDomaine)\\NETLOGON\\UninstallXbox.ps1"
Set-Content -Path $scriptPathXbox -Value $scriptDesinstallationXbox
Set-GPRegistryValue -Name $nomGPOOptimisationBatterie `
    -Key "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System" `
    -ValueName "StartupScript" `
    -Type String `
    -Value "UninstallXbox.ps1"

Write-Log "La GPO '$nomGPOOptimisationBatterie' a été configurée et liée au domaine." -ForegroundColor Green

# ----------------------

# Variables de chemin
$dossierSource = "C:\Temp\DossierExtrait\windows" # Emplacement des fichiers extraits
$dossierDestination = "C:\Windows\SYSVOL\sysvol\$nomDomaine\Policies\PolicyDefinitions"

# Création du dossier de destination si nécessaire
if (-not (Test-Path -Path $dossierDestination)) {
    New-Item -Path $dossierDestination -ItemType Directory -Force | Out-Null
    Write-Log "Dossier de destination créé : $dossierDestination" -ForegroundColor Green
}

# Vérification si le dossier source existe
if (-not (Test-Path -Path $dossierSource)) {
    Write-Log "Le dossier source n'existe pas : $dossierSource" -ForegroundColor Red
    exit
}

# Copier les fichiers .admx directement dans le dossier de destination
Write-Log "Copie des fichiers ADMX en cours" -ForegroundColor Yellow
Get-ChildItem -Path $dossierSource -Filter "*.admx" -File | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $dossierDestination -Force
}
Write-Log "Fichiers ADMX copiés." -ForegroundColor Green

# Copier le dossier fr-FR et son contenu
$dossierLangSource = Join-Path -Path $dossierSource -ChildPath "fr-FR"
$dossierLangDestination = Join-Path -Path $dossierDestination -ChildPath "fr-FR"

if (Test-Path -Path $dossierLangSource) {
    Write-Log "Copie du dossier fr-FR en cours" -ForegroundColor Yellow
    Copy-Item -Path $dossierLangSource -Destination $dossierLangDestination -Recurse -Force
    Write-Log "Dossier fr-FR et son contenu copiés." -ForegroundColor Green
} else {
    Write-Log "Le dossier fr-FR n'existe pas dans la source : $dossierLangSource" -ForegroundColor Red
}

Write-Log "Copie terminée" -ForegroundColor Green

# ----------------------

# Lier les GPO au domaine
New-GPLink -Name $nomGPOVeille -Target $cibleDomaine -Enforced Yes
New-GPLink -Name $nomGPORestrictionPanneau -Target $cibleDomaine -Enforced No
New-GPLink -Name $nomGPOPolitiqueMotDePasse -Target $cibleDomaine -Enforced No
New-GPLink -Name $nomGPODesacCMD -Target $cibleDomaine -Enforced No
New-GPLink -Name $nomGPOWindowsUpdate -Target $cibleDomaine -Enforced Yes
New-GPLink -Name $nomGPOOptimisationBatterie -Target $cibleDomaine -Enforced Yes

Write-Log "Les GPO ont été appliquées au domaine '$cibleDomaine'." -ForegroundColor Green