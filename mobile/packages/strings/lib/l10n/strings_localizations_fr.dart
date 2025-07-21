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
      'Do you want to save this to your storage (Downloads folder by default)?';

  @override
  String get enterNewEmailHint => 'Enter your new email address';

  @override
  String get email => 'Email';

  @override
  String get verify => 'Verify';

  @override
  String get invalidEmailTitle => 'Invalid email address';

  @override
  String get invalidEmailMessage => 'Please enter a valid email address.';

  @override
  String get pleaseWait => 'Please wait...';

  @override
  String get verifyPassword => 'Verify password';

  @override
  String get incorrectPasswordTitle => 'Incorrect password';

  @override
  String get pleaseTryAgain => 'Please try again';

  @override
  String get enterPassword => 'Enter password';

  @override
  String get enterYourPasswordHint => 'Enter your password';

  @override
  String get activeSessions => 'Active sessions';

  @override
  String get oops => 'Oops';

  @override
  String get somethingWentWrongPleaseTryAgain =>
      'Something went wrong, please try again';

  @override
  String get thisWillLogYouOutOfThisDevice =>
      'This will log you out of this device!';

  @override
  String get thisWillLogYouOutOfTheFollowingDevice =>
      'This will log you out of the following device:';

  @override
  String get terminateSession => 'Terminate session?';

  @override
  String get terminate => 'Terminate';

  @override
  String get thisDevice => 'This device';

  @override
  String get createAccount => 'Create account';

  @override
  String get weakStrength => 'Weak';

  @override
  String get moderateStrength => 'Moderate';

  @override
  String get strongStrength => 'Strong';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountQuery =>
      'We\'ll be sorry to see you go. Are you facing some issue?';

  @override
  String get yesSendFeedbackAction => 'Yes, send feedback';

  @override
  String get noDeleteAccountAction => 'No, delete account';

  @override
  String get initiateAccountDeleteTitle =>
      'Please authenticate to initiate account deletion';

  @override
  String get confirmAccountDeleteTitle => 'Confirm account deletion';

  @override
  String get confirmAccountDeleteMessage =>
      'This account is linked to other Ente apps, if you use any.\n\nYour uploaded data, across all Ente apps, will be scheduled for deletion, and your account will be permanently deleted.';

  @override
  String get delete => 'Delete';

  @override
  String get createNewAccount => 'Create new account';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String passwordStrength(String passwordStrengthValue) {
    return 'Password strength: $passwordStrengthValue';
  }

  @override
  String get hearUsWhereTitle => 'How did you hear about Ente? (optional)';

  @override
  String get hearUsExplanation =>
      'We don\'t track app installs. It\'d help if you told us where you found us!';

  @override
  String get signUpTerms =>
      'I agree to the <u-terms>terms of service</u-terms> and <u-policy>privacy policy</u-policy>';

  @override
  String get termsOfServicesTitle => 'Terms';

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get ackPasswordLostWarning =>
      'I understand that if I lose my password, I may lose my data since my data is <underline>end-to-end encrypted</underline>.';

  @override
  String get encryption => 'Encryption';

  @override
  String get logInLabel => 'Log in';

  @override
  String get welcomeBack => 'Welcome back!';

  @override
  String get loginTerms =>
      'By clicking log in, I agree to the <u-terms>terms of service</u-terms> and <u-policy>privacy policy</u-policy>';

  @override
  String get noInternetConnection => 'No internet connection';

  @override
  String get pleaseCheckYourInternetConnectionAndTryAgain =>
      'Please check your internet connection and try again.';

  @override
  String get verificationFailedPleaseTryAgain =>
      'Verification failed, please try again';

  @override
  String get recreatePasswordTitle => 'Recreate password';

  @override
  String get recreatePasswordBody =>
      'The current device is not powerful enough to verify your password, but we can regenerate in a way that works with all devices.\n\nPlease login using your recovery key and regenerate your password (you can use the same one again if you wish).';

  @override
  String get useRecoveryKey => 'Use recovery key';

  @override
  String get forgotPassword => 'Forgot password';

  @override
  String get changeEmail => 'Change email';

  @override
  String get verifyEmail => 'Verify email';

  @override
  String weHaveSendEmailTo(String email) {
    return 'We have sent a mail to <green>$email</green>';
  }

  @override
  String get toResetVerifyEmail =>
      'To reset your password, please verify your email first.';

  @override
  String get checkInboxAndSpamFolder =>
      'Please check your inbox (and spam) to complete verification';

  @override
  String get tapToEnterCode => 'Tap to enter code';

  @override
  String get sendEmail => 'Send email';

  @override
  String get resendEmail => 'Resend email';

  @override
  String get passKeyPendingVerification => 'Verification is still pending';

  @override
  String get loginSessionExpired => 'Session expired';

  @override
  String get loginSessionExpiredDetails =>
      'Your session has expired. Please login again.';

  @override
  String get passkeyAuthTitle => 'Passkey verification';

  @override
  String get waitingForVerification => 'Waiting for verification...';

  @override
  String get tryAgain => 'Try again';

  @override
  String get checkStatus => 'Check status';

  @override
  String get loginWithTOTP => 'Login with TOTP';

  @override
  String get recoverAccount => 'Recover account';

  @override
  String get setPasswordTitle => 'Set password';

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get resetPasswordTitle => 'Reset password';

  @override
  String get encryptionKeys => 'Encryption keys';

  @override
  String get enterPasswordToEncrypt =>
      'Enter a password we can use to encrypt your data';

  @override
  String get enterNewPasswordToEncrypt =>
      'Enter a new password we can use to encrypt your data';

  @override
  String get passwordWarning =>
      'We don\'t store this password, so if you forget, <underline>we cannot decrypt your data</underline>';

  @override
  String get howItWorks => 'How it works';

  @override
  String get generatingEncryptionKeys => 'Generating encryption keys...';

  @override
  String get passwordChangedSuccessfully => 'Password changed successfully';

  @override
  String get signOutFromOtherDevices => 'Sign out from other devices';

  @override
  String get signOutOtherBody =>
      'If you think someone might know your password, you can force all other devices using your account to sign out.';

  @override
  String get signOutOtherDevices => 'Sign out other devices';

  @override
  String get doNotSignOut => 'Do not sign out';

  @override
  String get generatingEncryptionKeysTitle => 'Generating encryption keys...';

  @override
  String get continueLabel => 'Continue';

  @override
  String get insecureDevice => 'Insecure device';

  @override
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease =>
      'Sorry, we could not generate secure keys on this device.\n\nplease sign up from a different device.';

  @override
  String get recoveryKeyCopiedToClipboard => 'Recovery key copied to clipboard';

  @override
  String get recoveryKey => 'Recovery key';

  @override
  String get recoveryKeyOnForgotPassword =>
      'If you forget your password, the only way you can recover your data is with this key.';

  @override
  String get recoveryKeySaveDescription =>
      'We don\'t store this key, please save this 24 word key in a safe place.';

  @override
  String get doThisLater => 'Do this later';

  @override
  String get saveKey => 'Save key';

  @override
  String get recoveryKeySaved => 'Recovery key saved in Downloads folder!';

  @override
  String get noRecoveryKeyTitle => 'No recovery key?';

  @override
  String get twoFactorAuthTitle => 'Two-factor authentication';

  @override
  String get enterCodeHint =>
      'Enter the 6-digit code from\nyour authenticator app';

  @override
  String get lostDeviceTitle => 'Lost device?';

  @override
  String get enterRecoveryKeyHint => 'Enter your recovery key';

  @override
  String get recover => 'Recover';
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
