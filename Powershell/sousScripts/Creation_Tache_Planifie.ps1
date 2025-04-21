# Importer le module pour écrire des logs
Import-Module ModuleLog

# Obtenir dynamiquement le chemin de base du deuxième script
$cheminBase = Split-Path -Parent $MyInvocation.MyCommand.Path

# Variables pour la tâche planifiée
$nomTache = "ExecutionScript"
$cheminScript = "C:\Users\Administrateur\Desktop\PowerShell\PowerShell2.ps1"

# Paramètres de la tâche
$actionTache = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$cheminScript`""

# Déclencheur : Exécution au logon
$declencheurTache = New-ScheduledTaskTrigger -AtLogOn

# Options de la tâche
$optionsTache = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# Définir les autorisations maximales pour l'utilisateur
$STPrin = New-ScheduledTaskPrincipal -UserId "MONDOMAINE\Administrateur" -RunLevel Highest

# Créer la tâche planifiée
try {
    Register-ScheduledTask -TaskName $nomTache -Action $actionTache -Trigger $declencheurTache -Settings $optionsTache -Principal $STPrin
    Write-Log -Message "Tâche planifiée créée avec succès. Le script s'exécutera à l'ouverture de session." -LogLevel INFO
} catch {
    Write-Log -Message "Erreur lors de la création de la tâche : $($_.Exception.Message)" -LogLevel ERROR
    exit 1
}

# Vérifier la création de la tâche
if (Get-ScheduledTask | Where-Object { $_.TaskName -eq $nomTache }) {
    Write-Log -Message "Vérification : La tâche planifiée a été créée avec succès." -LogLevel INFO
} else {
    Write-Log -Message "Erreur : La tâche planifiée n'a pas été trouvée." -LogLevel ERROR
    exit 1
}