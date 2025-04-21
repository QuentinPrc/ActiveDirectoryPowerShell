# Importer le module pour écrire des logs
Import-Module ModuleLog

# Obtenir dynamiquement le chemin de base du deuxième script
$cheminBase = Split-Path -Parent $MyInvocation.MyCommand.Path

$cheminCSV = Join-Path -Path $cheminBase -ChildPath "utilisateurs_UO_groupes.csv" #C:\Users\Administrateur\Desktop\PowerShell\utilisateurs_UO_groupes.csv"

# pilote carte réseau
# Vérifier que le dossier des pilotes existe
$cheminPilotes = "C:\Users\Administrateur\Desktop\PowerShell\Drivers"  #Join-Path -Path $cheminBase -ChildPath à compléter
if (Test-Path -Path $cheminPilotes) {
    Write-Log "Installation des pilotes à partir de $cheminPilotes..."

    # Installer tous les pilotes présents dans le dossier
    $pilotes = Get-ChildItem -Path $cheminPilotes -Recurse -Filter *.inf
    foreach ($pilote in $pilotes) {
        Write-Log "Installation du pilote: $($pilote.FullName)"
        try {
            pnputil.exe -i -a $pilote.FullName
            Write-Log "Pilote installé : $($pilote.Name)"
        } catch {
            Write-Log "Erreur d'installation du pilote : $($pilote.Name)"
        }
    }
    Write-Log "Tous les pilotes ont été installés."
} else {
    Write-Log "Le dossier des pilotes $cheminPilotes n'existe pas. Veuillez vérifier le chemin."
}
