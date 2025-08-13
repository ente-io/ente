// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class StringsLocalizationsFr extends StringsLocalizations {
  StringsLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get networkHostLookUpErr =>
      'Impossible de se connecter à Ente, veuillez vérifier vos paramètres réseau et contacter le support si l\'erreur persiste.';

  @override
  String get networkConnectionRefusedErr =>
      'Impossible de se connecter à Ente, veuillez réessayer après un certain temps. Si l\'erreur persiste, veuillez contacter le support.';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      'Il semble qu\'une erreur s\'est produite. Veuillez réessayer après un certain temps. Si l\'erreur persiste, veuillez contacter notre équipe d\'assistance.';

  @override
  String get error => 'Erreur';

  @override
  String get ok => 'Ok';

  @override
  String get faq => 'FAQ';

  @override
  String get contactSupport => 'Contacter le support';

  @override
  String get emailYourLogs => 'Envoyez vos logs par e-mail';

  @override
  String pleaseSendTheLogsTo(String toEmail) {
    return 'Envoyez les logs à $toEmail';
  }

  @override
  String get copyEmailAddress => 'Copier l’adresse e-mail';

  @override
  String get exportLogs => 'Exporter les journaux';

  @override
  String get cancel => 'Annuler';

  @override
  String pleaseEmailUsAt(String toEmail) {
    return 'Email us at $toEmail';
  }

  @override
  String get emailAddressCopied => 'Email address copied';

  @override
  String get supportEmailSubject => '[Support]';

  @override
  String get clientDebugInfoLabel =>
      'Following information can help us in debugging if you are facing any issue';

  @override
  String get registeredEmailLabel => 'Registered email:';

  @override
  String get clientLabel => 'Client:';

  @override
  String get versionLabel => 'Version :';

  @override
  String get notAvailable => 'N/A';

  @override
  String get reportABug => 'Signaler un bug';

  @override
  String get logsDialogBody =>
      'This will send across logs to help us debug your issue. Please note that file names will be included to help track issues with specific files.';

  @override
  String get viewLogs => 'View logs';

  @override
  String customEndpoint(String endpoint) {
    return 'Connecté à $endpoint';
  }

  @override
  String get save => 'Sauvegarder';

  @override
  String get send => 'Envoyer';

  @override
  String get saveOrSendDescription =>
      'Voulez-vous enregistrer ceci sur votre stockage (dossier Téléchargements par défaut) ou l\'envoyer à d\'autres applications ?';

  @override
  String get saveOnlyDescription =>
      'Voulez-vous enregistrer ceci sur votre stockage (dossier Téléchargements par défaut) ?';

  @override
  String get enterNewEmailHint => 'Saisissez votre nouvelle adresse email';

  @override
  String get email => 'E-mail';

  @override
  String get verify => 'Vérifier';

  @override
  String get invalidEmailTitle => 'Adresse e-mail invalide';

  @override
  String get invalidEmailMessage =>
      'Veuillez saisir une adresse e-mail valide.';

  @override
  String get pleaseWait => 'Veuillez patienter...';

  @override
  String get verifyPassword => 'Vérifier le mot de passe';

  @override
  String get incorrectPasswordTitle => 'Mot de passe incorrect';

  @override
  String get pleaseTryAgain => 'Veuillez réessayer';

  @override
  String get enterPassword => 'Saisissez le mot de passe';

  @override
  String get enterYourPasswordHint => 'Entrez votre mot de passe';

  @override
  String get activeSessions => 'Sessions actives';

  @override
  String get oops => 'Oups';

  @override
  String get somethingWentWrongPleaseTryAgain =>
      'Quelque chose s\'est mal passé, veuillez recommencer';

  @override
  String get thisWillLogYouOutOfThisDevice =>
      'Cela vous déconnectera de cet appareil !';

  @override
  String get thisWillLogYouOutOfTheFollowingDevice =>
      'Cela vous déconnectera de l\'appareil suivant :';

  @override
  String get terminateSession => 'Quitter la session ?';

  @override
  String get terminate => 'Quitter';

  @override
  String get thisDevice => 'Cet appareil';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get weakStrength => 'Faible';

  @override
  String get moderateStrength => 'Modéré';

  @override
  String get strongStrength => 'Fort';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get deleteAccountQuery =>
      'Nous sommes désolés de vous voir partir. Rencontrez-vous un problème ?';

  @override
  String get yesSendFeedbackAction => 'Oui, envoyer un commentaire';

  @override
  String get noDeleteAccountAction => 'Non, supprimer le compte';

  @override
  String get initiateAccountDeleteTitle =>
      'Veuillez vous authentifier pour débuter la suppression du compte';

  @override
  String get confirmAccountDeleteTitle => 'Confirmer la suppression du compte';

  @override
  String get confirmAccountDeleteMessage =>
      'Ce compte est lié à d\'autres applications ente, si vous en utilisez une.\n\nVos données téléchargées, dans toutes les applications ente, seront planifiées pour suppression, et votre compte sera définitivement supprimé.';

  @override
  String get delete => 'Supprimer';

  @override
  String get createNewAccount => 'Créer un nouveau compte';

  @override
  String get password => 'Mot de passe';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String passwordStrength(String passwordStrengthValue) {
    return 'Force du mot de passe : $passwordStrengthValue';
  }

  @override
  String get hearUsWhereTitle =>
      'Comment avez-vous entendu parler de Ente? (facultatif)';

  @override
  String get hearUsExplanation =>
      'Nous ne suivons pas les installations d\'applications. Il serait utile que vous nous disiez comment vous nous avez trouvés !';

  @override
  String get signUpTerms =>
      'J\'accepte les <u-terms>conditions d\'utilisation</u-terms> et la <u-policy>politique de confidentialité</u-policy>';

  @override
  String get termsOfServicesTitle => 'Conditions';

  @override
  String get privacyPolicyTitle => 'Politique de confidentialité';

  @override
  String get ackPasswordLostWarning =>
      'Je comprends que si je perds mon mot de passe, je risque de perdre mes données puisque celles-ci sont <underline>chiffrées de bout en bout</underline>.';

  @override
  String get encryption => 'Chiffrement';

  @override
  String get logInLabel => 'Connexion';

  @override
  String get welcomeBack => 'Bon retour parmi nous !';

  @override
  String get loginTerms =>
      'En cliquant sur \"Connexion\", j\'accepte les <u-terms>conditions d\'utilisation</u-terms> et la <u-policy>politique de confidentialité</u-policy>';

  @override
  String get noInternetConnection => 'Aucune connexion internet';

  @override
  String get pleaseCheckYourInternetConnectionAndTryAgain =>
      'Veuillez vérifier votre connexion internet puis réessayer.';

  @override
  String get verificationFailedPleaseTryAgain =>
      'La vérification a échouée, veuillez réessayer';

  @override
  String get recreatePasswordTitle => 'Recréer le mot de passe';

  @override
  String get recreatePasswordBody =>
      'L\'appareil actuel n\'est pas assez puissant pour vérifier votre mot de passe, donc nous avons besoin de le régénérer une fois d\'une manière qu\'il fonctionne avec tous les périphériques.\n\nVeuillez vous connecter en utilisant votre clé de récupération et régénérer votre mot de passe (vous pouvez utiliser le même si vous le souhaitez).';

  @override
  String get useRecoveryKey => 'Utiliser la clé de récupération';

  @override
  String get forgotPassword => 'Mot de passe oublié';

  @override
  String get changeEmail => 'Modifier l\'e-mail';

  @override
  String get verifyEmail => 'Vérifier l\'e-mail';

  @override
  String weHaveSendEmailTo(String email) {
    return 'Nous avons envoyé un mail à <green>$email</green>';
  }

  @override
  String get toResetVerifyEmail =>
      'Pour réinitialiser votre mot de passe, veuillez d\'abord vérifier votre e-mail.';

  @override
  String get checkInboxAndSpamFolder =>
      'Veuillez consulter votre boîte de courriels (et les spam) pour compléter la vérification';

  @override
  String get tapToEnterCode => 'Appuyez pour entrer un code';

  @override
  String get sendEmail => 'Envoyer un e-mail';

  @override
  String get resendEmail => 'Renvoyer le courriel';

  @override
  String get passKeyPendingVerification =>
      'La vérification est toujours en attente';

  @override
  String get loginSessionExpired => 'Session expirée';

  @override
  String get loginSessionExpiredDetails =>
      'Votre session a expiré. Veuillez vous reconnecter.';

  @override
  String get passkeyAuthTitle => 'Vérification du code d\'accès';

  @override
  String get waitingForVerification => 'En attente de vérification...';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get checkStatus => 'Vérifier le statut';

  @override
  String get loginWithTOTP => 'Se connecter avec un code TOTP';

  @override
  String get recoverAccount => 'Récupérer un compte';

  @override
  String get setPasswordTitle => 'Définir le mot de passe';

  @override
  String get changePasswordTitle => 'Modifier le mot de passe';

  @override
  String get resetPasswordTitle => 'Réinitialiser le mot de passe';

  @override
  String get encryptionKeys => 'Clés de chiffrement';

  @override
  String get enterPasswordToEncrypt =>
      'Entrez un mot de passe que nous pouvons utiliser pour chiffrer vos données';

  @override
  String get enterNewPasswordToEncrypt =>
      'Entrez un nouveau mot de passe que nous pouvons utiliser pour chiffrer vos données';

  @override
  String get passwordWarning =>
      'Nous ne stockons pas ce mot de passe. Si vous l\'oubliez, <underline>nous ne pourrons pas déchiffrer vos données</underline>';

  @override
  String get howItWorks => 'Comment ça fonctionne';

  @override
  String get generatingEncryptionKeys =>
      'Génération des clés de chiffrement...';

  @override
  String get passwordChangedSuccessfully =>
      'Le mot de passe a été modifié avec succès';

  @override
  String get signOutFromOtherDevices => 'Déconnexion des autres appareils';

  @override
  String get signOutOtherBody =>
      'Si vous pensez que quelqu\'un connaît peut-être votre mot de passe, vous pouvez forcer tous les autres appareils utilisant votre compte à se déconnecter.';

  @override
  String get signOutOtherDevices => 'Déconnecter les autres appareils';

  @override
  String get doNotSignOut => 'Ne pas se déconnecter';

  @override
  String get generatingEncryptionKeysTitle =>
      'Génération des clés de chiffrement...';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get insecureDevice => 'Appareil non sécurisé';

  @override
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease =>
      'Désolé, nous n\'avons pas pu générer de clés sécurisées sur cet appareil.\n\nVeuillez vous inscrire depuis un autre appareil.';

  @override
  String get recoveryKeyCopiedToClipboard =>
      'Clé de récupération copiée dans le presse-papiers';

  @override
  String get recoveryKey => 'Clé de récupération';

  @override
  String get recoveryKeyOnForgotPassword =>
      'Si vous oubliez votre mot de passe, la seule façon de récupérer vos données sera grâce à cette clé.';

  @override
  String get recoveryKeySaveDescription =>
      'Nous ne stockons pas cette clé, veuillez enregistrer cette clé de 24 mots dans un endroit sûr.';

  @override
  String get doThisLater => 'Plus tard';

  @override
  String get saveKey => 'Enregistrer la clé';

  @override
  String get recoveryKeySaved =>
      'Clé de récupération enregistrée dans le dossier Téléchargements !';

  @override
  String get noRecoveryKeyTitle => 'Pas de clé de récupération ?';

  @override
  String get twoFactorAuthTitle => 'Authentification à deux facteurs';

  @override
  String get enterCodeHint =>
      'Entrez le code à 6 chiffres de votre application d\'authentification';

  @override
  String get lostDeviceTitle => 'Appareil perdu ?';

  @override
  String get enterRecoveryKeyHint => 'Saisissez votre clé de récupération';

  @override
  String get recover => 'Restaurer';

  @override
  String get loggingOut => 'Deconnexion...';

  @override
  String get immediately => 'Immédiatement';

  @override
  String get appLock => 'Verrouillage d\'application';

  @override
  String get autoLock => 'Verrouillage automatique';

  @override
  String get noSystemLockFound => 'Aucun verrou système trouvé';

  @override
  String get deviceLockEnablePreSteps =>
      'Pour activer l\'écran de verrouillage, veuillez configurer le code d\'accès de l\'appareil ou le verrouillage de l\'écran dans les paramètres de votre système.';

  @override
  String get appLockDescription =>
      'Choisissez entre l\'écran de verrouillage par défaut de votre appareil et un écran de verrouillage par code PIN ou mot de passe personnalisé.';

  @override
  String get deviceLock => 'Verrouillage de l\'appareil';

  @override
  String get pinLock => 'Verrouillage par code PIN';

  @override
  String get autoLockFeatureDescription =>
      'Délai après lequel l\'application se verrouille une fois qu\'elle a été mise en arrière-plan';

  @override
  String get hideContent => 'Masquer le contenu';

  @override
  String get hideContentDescriptionAndroid =>
      'Masque le contenu de l\'application sur le menu et désactive les captures d\'écran';

  @override
  String get hideContentDescriptioniOS =>
      'Masque le contenu de l\'application sur le menu';

  @override
  String get tooManyIncorrectAttempts => 'Trop de tentatives incorrectes';

  @override
  String get tapToUnlock => 'Appuyer pour déverrouiller';

  @override
  String get areYouSureYouWantToLogout =>
      'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String get yesLogout => 'Oui, se déconnecter';

  @override
  String get authToViewSecrets =>
      'Veuillez vous authentifier pour voir vos souvenirs';

  @override
  String get next => 'Suivant';

  @override
  String get setNewPassword => 'Définir un nouveau mot de passe';

  @override
  String get enterPin => 'Saisir le code PIN';

  @override
  String get setNewPin => 'Définir un nouveau code PIN';

  @override
  String get confirm => 'Confirmer';

  @override
  String get reEnterPassword => 'Ressaisir le mot de passe';

  @override
  String get reEnterPin => 'Ressaisir le code PIN';

  @override
  String get androidBiometricHint => 'Vérifier l’identité';

  @override
  String get androidBiometricNotRecognized =>
      'Non reconnu. Veuillez réessayer.';

  @override
  String get androidBiometricSuccess => 'Parfait';

  @override
  String get androidCancelButton => 'Annuler';

  @override
  String get androidSignInTitle => 'Authentification requise';

  @override
  String get androidBiometricRequiredTitle => 'Empreinte digitale requise';

  @override
  String get androidDeviceCredentialsRequiredTitle =>
      'Identifiants de l\'appareil requis';

  @override
  String get androidDeviceCredentialsSetupDescription =>
      'Identifiants de l\'appareil requis';

  @override
  String get goToSettings => 'Allez dans les paramètres';

  @override
  String get androidGoToSettingsDescription =>
      'L\'authentification biométrique n\'est pas configurée sur votre appareil. Allez dans \'Paramètres > Sécurité\' pour l\'ajouter.';

  @override
  String get iOSLockOut =>
      'L\'authentification biométrique est désactivée. Veuillez verrouiller et déverrouiller votre écran pour l\'activer.';

  @override
  String get iOSOkButton => 'Ok';

  @override
  String get emailAlreadyRegistered => 'E-mail déjà enregistré.';

  @override
  String get emailNotRegistered => 'E-mail non enregistré.';

  @override
  String get thisEmailIsAlreadyInUse => 'Cette adresse mail est déjà utilisé';

  @override
  String emailChangedTo(String newEmail) {
    return 'L\'e-mail a été changé en $newEmail';
  }

  @override
  String get authenticationFailedPleaseTryAgain =>
      'L\'authentification a échouée, veuillez réessayer';

  @override
  String get authenticationSuccessful => 'Authentification réussie!';

  @override
  String get sessionExpired => 'Session expirée';

  @override
  String get incorrectRecoveryKey => 'Clé de récupération non valide';

  @override
  String get theRecoveryKeyYouEnteredIsIncorrect =>
      'La clé de récupération que vous avez entrée est incorrecte';

  @override
  String get twofactorAuthenticationSuccessfullyReset =>
      'L\'authentification à deux facteurs a été réinitialisée avec succès ';

  @override
  String get noRecoveryKey => 'No recovery key';

  @override
  String get yourAccountHasBeenDeleted => 'Your account has been deleted';

  @override
  String get verificationId => 'Verification ID';

  @override
  String get yourVerificationCodeHasExpired =>
      'Votre code de vérification a expiré';

  @override
  String get incorrectCode => 'Code non valide';

  @override
  String get sorryTheCodeYouveEnteredIsIncorrect =>
      'Le code que vous avez saisi est incorrect';

  @override
  String get developerSettings => 'Paramètres du développeur';

  @override
  String get serverEndpoint => 'Point de terminaison serveur';

  @override
  String get invalidEndpoint => 'Point de terminaison non valide';

  @override
  String get invalidEndpointMessage =>
      'Désolé, le point de terminaison que vous avez entré n\'est pas valide. Veuillez en entrer un valide puis réessayez.';

  @override
  String get endpointUpdatedMessage =>
      'Point de terminaison mis à jour avec succès';
}
