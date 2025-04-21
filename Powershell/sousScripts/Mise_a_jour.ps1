# Importer le module pour écrire des logs
Import-Module ModuleLog

# Mettre à jour Windows

Write-Log "Installation des Mises à Jour Windows"
Install-Module -Name PSWindowsUpdate -Force -SkipPublisherCheck
Import-Module PSWindowsUpdate
Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot
Write-Log "Mises à Jour installées, redémarrage nécessaire"
