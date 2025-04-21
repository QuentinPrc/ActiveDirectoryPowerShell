# Importer le module pour écrire des logs
Import-Module ModuleLog

# Importer les modules nécessaires
Import-Module ActiveDirectory
Import-Module GroupPolicy

# Obtenir dynamiquement le chemin de base du deuxième script
$cheminBase = Split-Path -Parent $MyInvocation.MyCommand.Path

# Spécifier le chemin du fichier CSV
$cheminCSV = Join-Path -Path $cheminBase -ChildPath "utilisateurs_UO_groupes.csv" #C:\Users\Administrateur\Desktop\PowerShell\utilisateurs_UO_groupes.csv"

# Importer les données depuis le fichier CSV
$utilisateurs = Import-Csv -Path $cheminCSV

# Définir un mot de passe par défaut
$motDePasse = ConvertTo-SecureString "Bonjour123" -AsPlainText -Force

# Fonction pour tronquer un texte à une longueur donnée
function Tronquer-Texte {
    param (
        [string]$texte,
        [int]$longueurMax
    )
    if ($texte.Length -gt $longueurMax) {
        return $texte.Substring(0, $longueurMax)
    } else {
        return $texte
    }
}

# Fonction pour ajouter un utilisateur dans l'Active Directory
function Ajouter-UtilisateurAD {
    param (
        [string]$nom,
        [string]$prenom,
        [string]$uoPath
    )

    # Supprimer les espaces avant et après le prénom et nom
    $prenom = $prenom.Trim()
    $nom = $nom.Trim()

    # Calculer la longueur totale et tronquer si nécessaire
    $longueurMax = 15
    $longueurPrenom = [math]::Min($prenom.Length, $longueurMax - 1) # Au moins une lettre pour le prénom
    $prenomTronque = Tronquer-Texte -texte $prenom -longueurMax $longueurPrenom
    $nomTronque = Tronquer-Texte -texte $nom -longueurMax ($longueurMax - $prenomTronque.Length)

    # Générer le nom d'utilisateur ( exemple : qparc )
    $nomUtilisateur = ($prenomTronque.Substring(0,1) + $nomTronque).ToLower()

    # Vérifier si l'utilisateur existe déjà dans Active Directory
    $utilisateurExist = Get-ADUser -Filter {SamAccountName -eq $nomUtilisateur} -ErrorAction SilentlyContinue
    if ($utilisateurExist) {
        Write-Log "L'utilisateur $nomUtilisateur existe déjà dans Active Directory"
    } else {
        # Ajouter l'utilisateur dans l'Active Directory
        New-ADUser -SamAccountName $nomUtilisateur `
            -UserPrincipalName "$nomUtilisateur@monDomaine.local" `
            -Name "$prenom $nom" `
            -GivenName $prenom `
            -Surname $nom `
            -Path $uoPath `
            -AccountPassword $motDePasse `
            -Enabled $true `
            -ChangePasswordAtLogon $true

        Write-Log "L'utilisateur $prenom $nom ($nomUtilisateur) a été ajouté dans l'UO '$uoPath'"
    }

    # Retourner le nom d'utilisateur généré
    return $nomUtilisateur
}

# Fonction pour créer un groupe dans l'Active Directory
function Creer-GroupeAD {
    param (
        [string]$nomGroupe,
        [string]$uoPath
    )

    # Vérifier si le groupe existe déjà dans Active Directory
    $groupeExist = Get-ADGroup -Filter {Name -eq $nomGroupe} -ErrorAction SilentlyContinue
    if ($groupeExist) {
        Write-Log "Le groupe $nomGroupe existe déjà dans Active Directory"
    } else {
        # Créer le groupe dans l'UO spécifiée
        New-ADGroup -Name $nomGroupe `
            -GroupScope Global `
            -GroupCategory Security `
            -Path $uoPath

        Write-Log "Le groupe $nomGroupe a été créé dans l'UO '$uoPath'"
    }
}

# Fonction pour créer une GPO qui bloque l'accès au panneau de configuration
function Creer-GPO {
    param (
        [string]$uoPath
    )

    # Nom de la GPO basé sur l'UO
    $NomGPO = "GPO-BloquerPanneauDeConfiguration"

    # Vérifier si la GPO existe déjà
    $GPOExist = Get-GPO -Name $NomGPO -ErrorAction SilentlyContinue
    if ($GPOExist) {
        Write-Log "Le GPO '$NomGPO' existe déjà."
    } else {
        # Créer le GPO
        $GPO = New-GPO -Name $NomGPO -Comment "Stratégie de blocage du panneau de configuration"
        Write-Log "Le GPO '$NomGPO' a été créé."
    }

    # Lier la GPO à l'UO
    New-GPLink -Name $NomGPO -Target $uoPath
    Write-Log "Le GPO '$NomGPO' a été lié à l'UO '$uoPath'."

    # Bloquer l'accès au panneau de configuration via les paramètres de la GPO
    # Localiser la clé de registre qui bloque l'accès
    Set-GPRegistryValue -Name $NomGPO `
        -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
        -ValueName "NoControlPanel" `
        -Type DWord `
        -Value 1

    Write-Log "Le panneau de configuration a été bloqué pour tous les utilisateurs dans l'UO '$uoPath'"
}

# Définir une UO par défaut si aucune n'est spécifiée
$uoParDefaut = "OU=DefaultUsers,DC=monDomaine,DC=local"

# Parcourir chaque ligne du fichier CSV
foreach ($utilisateur in $utilisateurs) {
    # Vérifier si une UO est spécifiée dans le fichier CSV
    $uoName = if ($utilisateur.UO -ne $null -and $utilisateur.UO -ne "") {
        $utilisateur.UO
    } else {
        "DefaultUsers"
    }
    $uoPath = "OU=$uoName,DC=monDomaine,DC=local"

    # Créer l'UO si elle existe pas déjà
    $uoExist = Get-ADOrganizationalUnit -Filter {Name -eq $uoName} -ErrorAction SilentlyContinue
    if ($uoExist) {
        Write-Log "L'UO '$uoName' existe déjà"
    } else {
        New-ADOrganizationalUnit -Name $uoName -Path "DC=monDomaine,DC=local"
        Write-Log "L'UO '$uoName' a été créée"
    }

    # Créer les groupes pour l'UO
    $nomGroupe = if ($utilisateur.Groupe -ne $null -and $utilisateur.Groupe -ne "") {
        "$($utilisateur.Groupe)-$uoName"
    } else {
        "DefaultGroup-$uoName"
    }
    Creer-GroupeAD -nomGroupe $nomGroupe -uoPath $uoPath

    # Ajouter l'utilisateur
    $nomUtilisateur = Ajouter-UtilisateurAD -nom $utilisateur.Nom -prenom $utilisateur.Prénom -uoPath $uoPath

    # Ajouter l'utilisateur au groupe spécifié
    if ($nomUtilisateur -ne $null -and $nomGroupe -ne $null -and $nomGroupe -ne "") {
        Add-ADGroupMember -Identity $nomGroupe -Members $nomUtilisateur
        Write-Log "L'utilisateur $nomUtilisateur a été ajouté au groupe $nomGroupe."
    }

    # Créer et lier la GPO pour l'UO
    Creer-GPO -uoPath $uoPath
}

Write-Log "Tous les utilisateurs, groupes, UO et GPO ont été traités."

# Fonction pour créer une GPO avec la stratégie de mot de passe
function Creer-StratégieMotDePasse {
    param (
        [string]$uoPath
    )

    # Nom de la GPO basé sur l'UO
    $NomGPO = "GPO-StratégieMotDePasse"

    # Vérifier si la GPO existe déjà
    $GPOExist = Get-GPO -Name $NomGPO -ErrorAction SilentlyContinue
    if ($GPOExist) {
        Write-Log "Le GPO '$NomGPO' existe déjà."
    } else {
        # Créer la GPO
        $GPO = New-GPO -Name $NomGPO -Comment "Stratégie de mot de passe"
        Write-Log "Le GPO '$NomGPO' a été créé."
    }

    # Lier la GPO à l'UO
    New-GPLink -Name $NomGPO -Target $uoPath
    Write-Log "Le GPO '$NomGPO' a été lié à l'UO '$uoPath'."

    # Configurer les paramètres de mot de passe dans la GPO
    Set-GPRegistryValue -Name $NomGPO `
        -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
        -ValueName "MinimumPasswordLength" `
        -Type DWord `
        -Value 8

    Set-GPRegistryValue -Name $NomGPO `
        -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
        -ValueName "PasswordComplexity" `
        -Type DWord `
        -Value 1

    Set-GPRegistryValue -Name $NomGPO `
        -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
        -ValueName "MaximumPasswordAge" `
        -Type DWord `
        -Value 60

    Set-GPRegistryValue -Name $NomGPO `
        -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
        -ValueName "MinimumPasswordAge" `
        -Type DWord `
        -Value 1

    Set-GPRegistryValue -Name $NomGPO `
        -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
        -ValueName "PasswordHistorySize" `
        -Type DWord `
        -Value 24

    Write-Log "Les paramètres de mot de passe ont été configurés dans la GPO '$NomGPO'."
}

# Appeler la fonction de stratégie de mot de passe pour chaque UO
foreach ($utilisateur in $utilisateurs) {
    # Vérifier si une UO est spécifiée dans le fichier CSV
    $uoName = if ($utilisateur.UO -ne $null -and $utilisateur.UO -ne "") {
        $utilisateur.UO
    } else {
        "DefaultUsers"
    }
    $uoPath = "OU=$uoName,DC=monDomaine,DC=local"

    # Créer l'UO si elle n'existe pas déjà
    $uoExist = Get-ADOrganizationalUnit -Filter {Name -eq $uoName} -ErrorAction SilentlyContinue
    if ($uoExist) {
        Write-Log "L'UO '$uoName' existe déjà."
    } else {
        New-ADOrganizationalUnit -Name $uoName -Path "DC=monDomaine,DC=local"
        Write-Log "L'UO '$uoName' a été créée."
    }

    # Créer les groupes pour l'UO
    $nomGroupe = if ($utilisateur.Groupe -ne $null -and $utilisateur.Groupe -ne "") {
        "$($utilisateur.Groupe)-$uoName"
    } else {
        "DefaultGroup-$uoName"
    }
    Creer-GroupeAD -nomGroupe $nomGroupe -uoPath $uoPath

    # Ajouter l'utilisateur
    $nomUtilisateur = Ajouter-UtilisateurAD -nom $utilisateur.Nom -prenom $utilisateur.Prénom -uoPath $uoPath

    # Ajouter l'utilisateur au groupe spécifié
    if ($nomUtilisateur -ne $null -and $nomGroupe -ne $null -and $nomGroupe -ne "") {
        Add-ADGroupMember -Identity $nomGroupe -Members $nomUtilisateur
        Write-Log "L'utilisateur $nomUtilisateur a été ajouté au groupe $nomGroupe."
    }

    # Créer et lier la GPO pour l'UO
    Creer-GPO -uoPath $uoPath

    # Appliquer la stratégie de mot de passe à l'UO
    Creer-StratégieMotDePasse -uoPath $uoPath
}

Write-Log "Tous les utilisateurs, groupes, UO, GPOs et stratégies de mot de passe ont été traités."
