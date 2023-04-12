// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a fr locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'fr';

  static String m4(user) =>
      "${user} ne pourra pas ajouter plus de photos à cet album\n\nIl pourrait toujours supprimer les photos existantes ajoutées par eux";

  static String m11(supportEmail) =>
      "Veuillez envoyer un e-mail à ${supportEmail} depuis votre adresse enregistrée";

  static String m17(storageAmountInGB) =>
      "${storageAmountInGB} Go chaque fois que quelqu\'un s\'inscrit à une offre payante et applique votre code";

  static String m29(passwordStrengthValue) =>
      "Puissance du mot de passe : ${passwordStrengthValue}";

  static String m42(referralCode, referralStorageInGB) =>
      "code de parrainage ente : ${referralCode} \n\nAppliquez le dans Paramètres → Général → Références pour obtenir ${referralStorageInGB} Go gratuitement après votre inscription à un plan payant\n\nhttps://ente.io";

  static String m48(storageAmountInGB) => "${storageAmountInGB} Go";

  static String m52(storageAmountInGB) =>
      "Ils obtiennent aussi ${storageAmountInGB} Go";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Bienvenue !"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Je comprends que si je perds mon mot de passe, je risque de perdre mes données puisque mes données sont <underline>chiffrées de bout en bout</underline>."),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Sessions actives"),
        "addANewEmail":
            MessageLookupByLibrary.simpleMessage("Ajouter un nouvel email"),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Ajouter un collaborateur"),
        "addMore": MessageLookupByLibrary.simpleMessage("Ajouter Plus"),
        "addViewer":
            MessageLookupByLibrary.simpleMessage("Ajouter un observateur"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Ajouté comme"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Propriétaire"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Autoriser les personnes avec le lien à ajouter des photos à l\'album partagé."),
        "allowAddingPhotos": MessageLookupByLibrary.simpleMessage(
            "Autoriser l\'ajout de photos"),
        "allowDownloads": MessageLookupByLibrary.simpleMessage(
            "Autoriser les téléchargements"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "Quelle est la principale raison pour laquelle vous supprimez votre compte ?"),
        "cancel": MessageLookupByLibrary.simpleMessage("Annuler"),
        "cannotAddMorePhotosAfterBecomingViewer": m4,
        "changeEmail":
            MessageLookupByLibrary.simpleMessage("Modifier l\'e-mail"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Modifier le mot de passe"),
        "changePermissions":
            MessageLookupByLibrary.simpleMessage("Modifier les permissions ?"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Veuillez consulter votre boîte de courriels (et les indésirables) pour compléter la vérification"),
        "claimFreeStorage": MessageLookupByLibrary.simpleMessage(
            "Réclamer le stockage gratuit"),
        "claimMore": MessageLookupByLibrary.simpleMessage("Réclamez plus !"),
        "claimed": MessageLookupByLibrary.simpleMessage("Réclamée"),
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("Code appliqué"),
        "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Code copié dans le presse-papiers"),
        "collaborator": MessageLookupByLibrary.simpleMessage("Collaborateur"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Les collaborateurs peuvent ajouter des photos et des vidéos à l\'album partagé."),
        "confirm": MessageLookupByLibrary.simpleMessage("Confirmer"),
        "confirmAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Confirmer la suppression du compte"),
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Oui, je veux supprimer définitivement ce compte et toutes ses données."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Confirmer le mot de passe"),
        "confirmRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Confirmer la clé de récupération"),
        "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Confirmer la clé de récupération"),
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("Contacter l\'assistance"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("Continuer"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Copiez-collez ce code\ndans votre application d\'authentification"),
        "createAccount":
            MessageLookupByLibrary.simpleMessage("Créer un compte"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("Créer un nouveau compte"),
        "decrypting": MessageLookupByLibrary.simpleMessage("Déchiffrage..."),
        "deleteAccount":
            MessageLookupByLibrary.simpleMessage("Supprimer mon compte"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "Nous sommes désolés de vous voir partir. Veuillez partager vos commentaires pour nous aider à nous améliorer."),
        "deleteAccountPermanentlyButton": MessageLookupByLibrary.simpleMessage(
            "Supprimer définitivement le compte"),
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
            "Vous allez supprimer définitivement votre compte et toutes ses données.\nCette action est irréversible."),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "Veuillez envoyer un e-mail à <warning>account-deletion@ente.io</warning> à partir de votre adresse e-mail enregistrée."),
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "Il manque une fonction clé dont j\'ai besoin"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "L\'application ou une certaine fonctionnalité ne se comporte pas \ncomme je pense qu\'elle devrait"),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
            "J\'ai trouvé un autre service que je préfère"),
        "deleteReason4":
            MessageLookupByLibrary.simpleMessage("Ma raison n\'est pas listée"),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
            "Votre demande sera traitée en moins de 72 heures."),
        "details": MessageLookupByLibrary.simpleMessage("Détails"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Les téléspectateurs peuvent toujours prendre des captures d\'écran ou enregistrer une copie de vos photos en utilisant des outils externes"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Veuillez remarquer"),
        "doThisLater": MessageLookupByLibrary.simpleMessage("Plus tard"),
        "dropSupportEmail": m11,
        "email": MessageLookupByLibrary.simpleMessage("E-mail"),
        "encryption": MessageLookupByLibrary.simpleMessage("Chiffrement"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Clés de chiffrement"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Entrer le code"),
        "enterEmail": MessageLookupByLibrary.simpleMessage("Entrer e-mail"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Entrez un nouveau mot de passe que nous pouvons utiliser pour chiffrer vos données"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Entrez un mot de passe que nous pouvons utiliser pour chiffrer vos données"),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Entrez le code à 6 chiffres de\nvotre application d\'authentification"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "Veuillez entrer une adresse email valide."),
        "enterYourEmailAddress":
            MessageLookupByLibrary.simpleMessage("Entrez votre adresse e-mail"),
        "enterYourPassword":
            MessageLookupByLibrary.simpleMessage("Entrez votre mot de passe"),
        "enterYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Entrez votre clé de récupération"),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
            "Ce lien a expiré. Veuillez sélectionner un nouveau délai d\'expiration ou désactiver l\'expiration du lien."),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "Impossible de récupérer les détails du parrainage. Veuillez réessayer plus tard."),
        "feedback": MessageLookupByLibrary.simpleMessage("Commentaires"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Mot de passe oublié"),
        "freeStorageOnReferralSuccess": m17,
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Génération des clés de chiffrement..."),
        "howItWorks":
            MessageLookupByLibrary.simpleMessage("Comment ça fonctionne"),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Mot de passe incorrect"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "La clé de récupération que vous avez entrée est incorrecte"),
        "incorrectRecoveryKeyTitle": MessageLookupByLibrary.simpleMessage(
            "Clé de récupération non valide"),
        "insecureDevice":
            MessageLookupByLibrary.simpleMessage("Appareil non sécurisé"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("Adresse e-mail invalide"),
        "invalidKey": MessageLookupByLibrary.simpleMessage("Clé invalide"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "La clé de récupération que vous avez saisie n\'est pas valide. Veuillez vous assurer qu\'elle "),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Invite tes ami(e)s"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Veuillez nous aider avec cette information"),
        "linkDeviceLimit":
            MessageLookupByLibrary.simpleMessage("Limite d\'appareil"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Activé"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Expiré"),
        "linkExpiry":
            MessageLookupByLibrary.simpleMessage("Expiration du lien"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Jamais"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Se connecter"),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "En cliquant sur connecter, j\'accepte les <u-terms>conditions d\'utilisation</u-terms> et la <u-policy>politique de confidentialité</u-policy>"),
        "lostDevice": MessageLookupByLibrary.simpleMessage("Appareil perdu ?"),
        "manage": MessageLookupByLibrary.simpleMessage("Gérer"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Modéré"),
        "noRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Aucune clé de récupération?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "En raison de notre protocole de chiffrement de bout en bout, vos données ne peuvent pas être déchiffré sans votre mot de passe ou clé de récupération"),
        "ok": MessageLookupByLibrary.simpleMessage("OK"),
        "oops": MessageLookupByLibrary.simpleMessage("Oups"),
        "orPickAnExistingOne": MessageLookupByLibrary.simpleMessage(
            "Sélectionner un fichier existant"),
        "password": MessageLookupByLibrary.simpleMessage("Mot de passe"),
        "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
            "Le mot de passe a été modifié"),
        "passwordLock":
            MessageLookupByLibrary.simpleMessage("Mot de passe verrou"),
        "passwordStrength": m29,
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Nous ne stockons pas ce mot de passe, donc si vous l\'oubliez, <underline>nous ne pouvons pas déchiffrer vos données</underline>"),
        "pleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("Veuillez réessayer"),
        "pleaseWait":
            MessageLookupByLibrary.simpleMessage("Veuillez patienter..."),
        "privacyPolicyTitle": MessageLookupByLibrary.simpleMessage(
            "Politique de Confidentialité"),
        "recover": MessageLookupByLibrary.simpleMessage("Restaurer"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("Récupérer un compte"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Récupérer"),
        "recoveryKey":
            MessageLookupByLibrary.simpleMessage("Clé de récupération"),
        "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Clé de récupération copiée dans le presse-papiers"),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
            "Si vous oubliez votre mot de passe, la seule façon de récupérer vos données sera grâce à cette clé."),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
            "Nous ne stockons pas cette clé, veuillez enregistrer cette clé de 24 mots dans un endroit sûr."),
        "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
            "Génial ! Votre clé de récupération est valide. Merci de votre vérification.\n\nN\'oubliez pas de garder votre clé de récupération sauvegardée."),
        "recoveryKeyVerified": MessageLookupByLibrary.simpleMessage(
            "Clé de récupération vérifiée"),
        "recoveryKeyVerifyReason": MessageLookupByLibrary.simpleMessage(
            "Votre clé de récupération est la seule façon de récupérer vos photos si vous oubliez votre mot de passe. Vous pouvez trouver votre clé de récupération dans Paramètres > Compte.\n\nVeuillez entrer votre clé de récupération ici pour vous assurer que vous l\'avez enregistrée correctement."),
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("Récupération réussie !"),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Recréer le mot de passe"),
        "remove": MessageLookupByLibrary.simpleMessage("Enlever"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Supprimer le participant"),
        "resendEmail":
            MessageLookupByLibrary.simpleMessage("Renvoyer le courriel"),
        "resetPasswordTitle": MessageLookupByLibrary.simpleMessage(
            "Réinitialiser le mot de passe"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Enregistrer la clé"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Enregistrez votre clé de récupération si vous ne l\'avez pas déjà fait"),
        "scanCode": MessageLookupByLibrary.simpleMessage("Scanner le code"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Scannez ce code-barres avec\nvotre application d\'authentification"),
        "selectReason":
            MessageLookupByLibrary.simpleMessage("Sélectionner une raison"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("Envoyer un e-mail"),
        "setAPassword":
            MessageLookupByLibrary.simpleMessage("Définir un mot de passe"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Définir le mot de passe"),
        "setupComplete":
            MessageLookupByLibrary.simpleMessage("Configuration fini"),
        "shareTextReferralCode": m42,
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "J\'accepte les <u-terms>conditions d\'utilisation</u-terms> et la <u-policy>politique de confidentialité</u-policy>"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Quelque chose s\'est mal passé, veuillez recommencer"),
        "sorry": MessageLookupByLibrary.simpleMessage("Désolé"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "Désolé, nous n\'avons pas pu générer de clés sécurisées sur cet appareil.\n\nVeuillez vous inscrire depuis un autre appareil."),
        "storageInGB": m48,
        "strongStrength": MessageLookupByLibrary.simpleMessage("Fort"),
        "tapToCopy": MessageLookupByLibrary.simpleMessage("taper pour copier"),
        "tapToEnterCode":
            MessageLookupByLibrary.simpleMessage("Appuyez pour entrer un code"),
        "terminate": MessageLookupByLibrary.simpleMessage("Quitte"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Quitter la session ?"),
        "termsOfServicesTitle":
            MessageLookupByLibrary.simpleMessage("Conditions d\'utilisation"),
        "theyAlsoGetXGb": m52,
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "Cela peut être utilisé pour récupérer votre compte si vous perdez votre deuxième facteur"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Cet appareil"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Cela vous déconnectera de l\'appareil suivant :"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Cela vous déconnectera de cet appareil !"),
        "tryAgain": MessageLookupByLibrary.simpleMessage("Réessayer"),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage(
                "Authentification à deux facteurs"),
        "twofactorSetup": MessageLookupByLibrary.simpleMessage(
            "Configuration de l\'authentification à deux facteurs"),
        "useRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Utiliser la clé de récupération"),
        "verify": MessageLookupByLibrary.simpleMessage("Vérifier"),
        "verifyEmail":
            MessageLookupByLibrary.simpleMessage("Vérifier l\'email"),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Vérifier le mot de passe"),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Vérification de la clé de récupération..."),
        "viewRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Voir la clé de récupération"),
        "viewer": MessageLookupByLibrary.simpleMessage("Observateur"),
        "weakStrength": MessageLookupByLibrary.simpleMessage("Faible"),
        "welcomeBack": MessageLookupByLibrary.simpleMessage("Bienvenue !"),
        "weveSentAMailTo": MessageLookupByLibrary.simpleMessage(
            "Nous avons envoyé un email à"),
        "yesConvertToViewer": MessageLookupByLibrary.simpleMessage(
            "Oui, convertir en observateur"),
        "you": MessageLookupByLibrary.simpleMessage("Vous"),
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("Votre compte a été supprimé")
      };
}
