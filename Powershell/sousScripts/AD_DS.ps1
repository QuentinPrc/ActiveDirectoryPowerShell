# Importer le module pour écrire des logs
Import-Module ModuleLog

Write-Log "Installation du rôle AD DS"
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Write-Log "Rôle AD DS installé"