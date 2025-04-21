# Obtenir dynamiquement le chemin de base du script
$cheminBase = Split-Path -Parent $MyInvocation.MyCommand.Path

# Spécifier le chemin du fichier CSV
$cheminCsv = Join-Path -Path $cheminBase -ChildPath "utilisateurs_uo_groupes.csv"

# Chemin du dossier partagé principal
$cheminPartage = "C:\Partage"

# Vérifier si le fichier CSV existe
if (!(Test-Path -Path $cheminCsv)) {
    Write-Log "Le fichier CSV n'existe pas : $cheminCsv"
    exit
}

# Vérifier si le dossier principal existe, sinon le créer
if (!(Test-Path -Path $cheminPartage)) {
    New-Item -Path $cheminPartage -ItemType Directory | Out-Null
    Write-Log "Le dossier principal $cheminPartage a été créé." -ForegroundColor Green
}

# Importer les données du CSV
$utilisateurs = Import-Csv -Path $cheminCsv

# Parcourir les utilisateurs du fichier CSV
foreach ($utilisateur in $utilisateurs) {
    # Récupérer les informations de l'utilisateur
    $prenom = $utilisateur.prénom
    $nom = $utilisateur.nom
    $uo = $utilisateur.uo
    $groupe = $utilisateur.groupe


    $nomUtilisateur = "$prenom-$nom"
    $cheminUo = Join-Path -Path $cheminPartage -ChildPath $uo
    $cheminUtilisateur = Join-Path -Path $cheminPartage -ChildPath $nomUtilisateur

    # Créer un dossier pour l'UO s'il n'existe pas
    if (!(Test-Path -Path $cheminUo)) {
        New-Item -Path $cheminUo -ItemType Directory | Out-Null
        Write-Log "Dossier pour l'UO $uo créé : $cheminUo"

        $aclUo = Get-Acl $cheminUo
        $accessRuleUo = New-Object System.Security.AccessControl.FileSystemAccessRule("$uo", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        $aclUo.SetAccessRule($accessRuleUo)
        Set-Acl -Path $cheminUo -AclObject $aclUo

        New-SmbShare -Name $uo -Path $cheminUo -FullAccess "$uo" | Out-Null
        Write-Log "Partage configuré pour l'UO : $uo"
    }

    # Créer un dossier privé pour l'utilisateur
    if (!(Test-Path -Path $cheminUtilisateur)) {
        New-Item -Path $cheminUtilisateur -ItemType Directory | Out-Null
        Write-Log "Dossier privé créé pour $nomUtilisateur"

        # Configurer les permissions NTFS pour l'utilisateur
        $acl = Get-Acl $cheminUtilisateur
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("$nomUtilisateur", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        $acl.SetAccessRule($accessRule)
        Set-Acl -Path $cheminUtilisateur -AclObject $acl

        # Configurer les permissions NTFS pour l'UO (accès uniquement en lecture pour l'UO)
        $accessRuleUoRead = New-Object System.Security.AccessControl.FileSystemAccessRule("$uo", "Read", "ContainerInherit,ObjectInherit", "None", "Allow")
        $acl.SetAccessRule($accessRuleUoRead)
        Set-Acl -Path $cheminUtilisateur -AclObject $acl

        # Configurer le partage réseau pour l'utilisateur
        New-SmbShare -Name $nomUtilisateur -Path $cheminUtilisateur -FullAccess "$nomUtilisateur" | Out-Null
        Write-Log "Partage configuré pour $nomUtilisateur."
    } else {
        Write-Log "Le dossier privé pour $nomUtilisateur existe déjà : $cheminUtilisateur"
    }

    # Configurer les permissions NTFS pour l'UO
    $aclUo = Get-Acl $cheminUo
    $accessRuleUoRead = New-Object System.Security.AccessControl.FileSystemAccessRule("$uo", "Read", "ContainerInherit,ObjectInherit", "None", "Allow")
    $aclUo.SetAccessRule($accessRuleUoRead)
    Set-Acl -Path $cheminUo -AclObject $aclUo

    $aclUtilisateur = Get-Acl $cheminUtilisateur
    $aclUtilisateur.RemoveAccessRuleAll($accessRuleUoRead)
    Set-Acl -Path $cheminUtilisateur -AclObject $aclUtilisateur

    # Assurez-vous que seul l'utilisateur et son UO aient accès aux dossiers
    Write-Log "Permissions NTFS et partage configurés pour $nomUtilisateur et $uo"
}

Write-Log "Tous les dossiers privés et partagés ont été configurés"