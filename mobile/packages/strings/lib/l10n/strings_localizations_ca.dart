// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Catalan Valencian (`ca`).
class StringsLocalizationsCa extends StringsLocalizations {
  StringsLocalizationsCa([String locale = 'ca']) : super(locale);

  @override
  String get networkHostLookUpErr =>
      'No s\'ha pogut connectar a Ente, si us plau, comprova la configuració de la xarxa i contacta amb suport si l\'error persisteix.';

  @override
  String get networkConnectionRefusedErr =>
      'No s\'ha pogut connectar a Ente, si us plau, torna-ho a intentar després d\'un temps. Si l\'error persisteix, contacta amb suport.';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      'Sembla que alguna cosa ha anat malament. Si us plau, torna-ho a intentar després d\'un temps. Si l\'error persisteix, contacta amb el nostre equip de suport.';

  @override
  String get error => 'Error';

  @override
  String get ok => 'D\'acord';

  @override
  String get faq => 'FAQ';

  @override
  String get contactSupport => 'Contacta amb suport';

  @override
  String get emailYourLogs => 'Envia els teus registres per correu';

  @override
  String pleaseSendTheLogsTo(String toEmail) {
    return 'Si us plau, envia els registres a \n$toEmail';
  }

  @override
  String get copyEmailAddress => 'Copia l\'adreça de correu';

  @override
  String get exportLogs => 'Exporta els registres';

  @override
  String get cancel => 'Cancel·la';

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
  String get reportABug => 'Informa d\'un error';

  @override
  String get logsDialogBody =>
      'This will send across logs to help us debug your issue. Please note that file names will be included to help track issues with specific files.';

  @override
  String get viewLogs => 'View logs';

  @override
  String customEndpoint(String endpoint) {
    return 'Connectat a $endpoint';
  }

  @override
  String get save => 'Guarda';

  @override
  String get send => 'Envia';

  @override
  String get saveOrSendDescription =>
      'Vols guardar-ho al teu emmagatzematge (per defecte, a la carpeta Descàrregues) o enviar-ho a altres aplicacions?';

  @override
  String get saveOnlyDescription =>
      'Vols guardar-ho al teu emmagatzematge (per defecte, a la carpeta Descàrregues)?';

  @override
  String get enterNewEmailHint => 'Enter your new email address';

  @override
  String get email => 'Correu electrònic';

  @override
  String get verify => 'Verifica';

  @override
  String get invalidEmailTitle => 'Adreça de correu electrònic no vàlida';

  @override
  String get invalidEmailMessage =>
      'Si us plau, introdueix una adreça de correu electrònic vàlida.';

  @override
  String get pleaseWait => 'Si us plau, espera...';

  @override
  String get verifyPassword => 'Verifica la contrasenya';

  @override
  String get incorrectPasswordTitle => 'Contrasenya incorrecta';

  @override
  String get pleaseTryAgain => 'Si us plau, intenta-ho de nou';

  @override
  String get enterPassword => 'Introdueix la contrasenya';

  @override
  String get enterYourPasswordHint => 'Introdueix la teva contrasenya';

  @override
  String get activeSessions => 'Sessions actives';

  @override
  String get oops => 'Ups';

  @override
  String get somethingWentWrongPleaseTryAgain =>
      'S\'ha produït un error, si us plau, intenta-ho de nou';

  @override
  String get thisWillLogYouOutOfThisDevice =>
      'Això tancarà la sessió en aquest dispositiu!';

  @override
  String get thisWillLogYouOutOfTheFollowingDevice =>
      'Això tancarà la sessió en el següent dispositiu:';

  @override
  String get terminateSession => 'Finalitzar sessió?';

  @override
  String get terminate => 'Finalitzar';

  @override
  String get thisDevice => 'Aquest dispositiu';

  @override
  String get createAccount => 'Crea un compte';

  @override
  String get weakStrength => 'Feble';

  @override
  String get moderateStrength => 'Moderada';

  @override
  String get strongStrength => 'Forta';

  @override
  String get deleteAccount => 'Elimina el compte';

  @override
  String get deleteAccountQuery =>
      'Ens sabrà greu veure\'t marxar. Tens algun problema?';

  @override
  String get yesSendFeedbackAction => 'Sí, envia comentaris';

  @override
  String get noDeleteAccountAction => 'No, elimina el compte';

  @override
  String get initiateAccountDeleteTitle =>
      'Si us plau, autentica\'t per iniciar l\'eliminació del compte';

  @override
  String get confirmAccountDeleteTitle => 'Confirma la supressió del compte';

  @override
  String get confirmAccountDeleteMessage =>
      'Aquest compte està vinculat a altres apps d\'Ente, si en fas ús.\n\nLes dades pujades, a través de totes les apps d\'Ente, es programaran per a la supressió, i el teu compte s\'eliminarà permanentment.';

  @override
  String get delete => 'Elimina';

  @override
  String get createNewAccount => 'Crea un nou compte';

  @override
  String get password => 'Contrasenya';

  @override
  String get confirmPassword => 'Confirma la contrasenya';

  @override
  String passwordStrength(String passwordStrengthValue) {
    return 'Força de la contrasenya: $passwordStrengthValue';
  }

  @override
  String get hearUsWhereTitle => 'Com vas conèixer Ente? (opcional)';

  @override
  String get hearUsExplanation =>
      'No fem seguiment de les instal·lacions de l\'app. Ens ajudaria saber on ens has trobat!';

  @override
  String get signUpTerms =>
      'Estic d\'acord amb els <u-terms>termes del servei</u-terms> i la <u-policy>política de privacitat</u-policy>';

  @override
  String get termsOfServicesTitle => 'Termes';

  @override
  String get privacyPolicyTitle => 'Política de privacitat';

  @override
  String get ackPasswordLostWarning =>
      'Entenc que si perdo la meva contrasenya, puc perdre les meves dades ja que les meves dades estan <underline>xifrades d\'extrem a extrem</underline>.';

  @override
  String get encryption => 'Xifratge';

  @override
  String get logInLabel => 'Inicia sessió';

  @override
  String get welcomeBack => 'Benvingut de nou!';

  @override
  String get loginTerms =>
      'En fer clic a iniciar sessió, estic d\'acord amb els <u-terms>termes del servei</u-terms> i la <u-policy>política de privacitat</u-policy>';

  @override
  String get noInternetConnection => 'Sense connexió a Internet';

  @override
  String get pleaseCheckYourInternetConnectionAndTryAgain =>
      'Comprova la connexió a Internet i torna-ho a intentar.';

  @override
  String get verificationFailedPleaseTryAgain =>
      'La verificació ha fallat, intenta-ho de nou';

  @override
  String get recreatePasswordTitle => 'Recrea la contrasenya';

  @override
  String get recreatePasswordBody =>
      'El dispositiu actual no és prou potent per verificar la teva contrasenya, però podem regenerar-la d\'una manera que funcioni amb tots els dispositius.\n\nSi us plau, inicia sessió utilitzant la teva clau de recuperació i regenera la teva contrasenya (pots tornar a utilitzar la mateixa si ho desitges).';

  @override
  String get useRecoveryKey => 'Usa la clau de recuperació';

  @override
  String get forgotPassword => 'Has oblidat la contrasenya';

  @override
  String get changeEmail => 'Canvia el correu electrònic';

  @override
  String get verifyEmail => 'Verifica el correu electrònic';

  @override
  String weHaveSendEmailTo(String email) {
    return 'Hem enviat un correu a <green>$email</green>';
  }

  @override
  String get toResetVerifyEmail =>
      'Per restablir la teva contrasenya, si us plau verifica primer el teu correu electrònic.';

  @override
  String get checkInboxAndSpamFolder =>
      'Comprova la teva safata d\'entrada (i el correu no desitjat) per completar la verificació';

  @override
  String get tapToEnterCode => 'Toca per introduir el codi';

  @override
  String get sendEmail => 'Envia correu electrònic';

  @override
  String get resendEmail => 'Reenviar correu electrònic';

  @override
  String get passKeyPendingVerification => 'La verificació encara està pendent';

  @override
  String get loginSessionExpired => 'Sessió caducada';

  @override
  String get loginSessionExpiredDetails =>
      'La teva sessió ha caducat. Torna a iniciar sessió.';

  @override
  String get passkeyAuthTitle => 'Verificació per passkey';

  @override
  String get waitingForVerification => 'Esperant verificació...';

  @override
  String get tryAgain => 'Intenta-ho de nou';

  @override
  String get checkStatus => 'Comprova l\'estat';

  @override
  String get loginWithTOTP => 'Inici de sessió amb TOTP';

  @override
  String get recoverAccount => 'Recupera el compte';

  @override
  String get setPasswordTitle => 'Configura la contrasenya';

  @override
  String get changePasswordTitle => 'Canvia la contrasenya';

  @override
  String get resetPasswordTitle => 'Restableix la contrasenya';

  @override
  String get encryptionKeys => 'Claus de xifratge';

  @override
  String get enterPasswordToEncrypt =>
      'Introdueix una contrasenya que puguem utilitzar per xifrar les teves dades';

  @override
  String get enterNewPasswordToEncrypt =>
      'Introdueix una nova contrasenya que puguem utilitzar per xifrar les teves dades';

  @override
  String get passwordWarning =>
      'No guardem aquesta contrasenya, per tant, si l\'oblides, <underline>no podrem desxifrar les teves dades</underline>';

  @override
  String get howItWorks => 'Com funciona';

  @override
  String get generatingEncryptionKeys => 'Generant claus de xifratge...';

  @override
  String get passwordChangedSuccessfully =>
      'La contrasenya s\'ha canviat amb èxit';

  @override
  String get signOutFromOtherDevices => 'Tanca sessió en altres dispositius';

  @override
  String get signOutOtherBody =>
      'Si creus que algú pot saber la teva contrasenya, pots forçar tots els altres dispositius que usen el teu compte a tancar sessió.';

  @override
  String get signOutOtherDevices => 'Tancar sessió en altres dispositius';

  @override
  String get doNotSignOut => 'No tancar sessió';

  @override
  String get generatingEncryptionKeysTitle =>
      'Generant claus d\'encriptació...';

  @override
  String get continueLabel => 'Continua';

  @override
  String get insecureDevice => 'Dispositiu no segur';

  @override
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease =>
      'Ho sentim, no hem pogut generar claus segures en aquest dispositiu.\n\nSi us plau, registra\'t des d\'un altre dispositiu.';

  @override
  String get recoveryKeyCopiedToClipboard =>
      'La clau de recuperació s\'ha copiat al porta-retalls';

  @override
  String get recoveryKey => 'Clau de recuperació';

  @override
  String get recoveryKeyOnForgotPassword =>
      'Si oblides la teva contrasenya, l\'única manera de recuperar les teves dades és amb aquesta clau.';

  @override
  String get recoveryKeySaveDescription =>
      'No guardem aquesta clau, si us plau, guarda aquesta clau de 24 paraules en un lloc segur.';

  @override
  String get doThisLater => 'Fes-ho més tard';

  @override
  String get saveKey => 'Guarda la clau';

  @override
  String get recoveryKeySaved =>
      'Clau de recuperació guardada a la carpeta Descàrregues!';

  @override
  String get noRecoveryKeyTitle => 'No tens clau de recuperació?';

  @override
  String get twoFactorAuthTitle => 'Autenticació de dos factors';

  @override
  String get enterCodeHint =>
      'Introdueix el codi de 6 dígits de\nl\'aplicació d\'autenticació';

  @override
  String get lostDeviceTitle => 'Dispositiu perdut?';

  @override
  String get enterRecoveryKeyHint => 'Introdueix la teva clau de recuperació';

  @override
  String get recover => 'Recupera';

  @override
  String get loggingOut => 'Tancant sessió...';

  @override
  String get immediately => 'Immediatament';

  @override
  String get appLock => 'Bloqueig de l\'aplicació';

  @override
  String get autoLock => 'Bloqueig automàtic';

  @override
  String get noSystemLockFound => 'No s\'ha trobat cap bloqueig del sistema';

  @override
  String get deviceLockEnablePreSteps =>
      'Per habilitar el bloqueig de dispositiu, configura un codi o bloqueig de pantalla en la configuració del sistema.';

  @override
  String get appLockDescription =>
      'Tria entre el bloqueig predeterminat del dispositiu o un bloqueig personalitzat amb PIN o contrasenya.';

  @override
  String get deviceLock => 'Bloqueig del dispositiu';

  @override
  String get pinLock => 'Bloqueig amb PIN';

  @override
  String get autoLockFeatureDescription =>
      'Temps després del qual l\'app es bloqueja quan es posa en segon pla';

  @override
  String get hideContent => 'Amaga el contingut';

  @override
  String get hideContentDescriptionAndroid =>
      'Amaga el contingut d\'aquesta app en el commutador d\'apps del sistema i desactiva les captures de pantalla';

  @override
  String get hideContentDescriptioniOS =>
      'Amaga el contingut d\'aquesta app en el commutador d\'apps del sistema';

  @override
  String get tooManyIncorrectAttempts => 'Massa intents incorrectes';

  @override
  String get tapToUnlock => 'Toca per desbloquejar';

  @override
  String get areYouSureYouWantToLogout => 'Segur que vols tancar la sessió?';

  @override
  String get yesLogout => 'Sí, tanca la sessió';

  @override
  String get authToViewSecrets =>
      'Si us plau, autentica\'t per veure els teus secrets';

  @override
  String get next => 'Següent';

  @override
  String get setNewPassword => 'Estableix una nova contrasenya';

  @override
  String get enterPin => 'Introdueix el PIN';

  @override
  String get setNewPin => 'Estableix un nou PIN';

  @override
  String get confirm => 'Confirma';

  @override
  String get reEnterPassword => 'Torna a introduir la contrasenya';

  @override
  String get reEnterPin => 'Torna a introduir el PIN';

  @override
  String get androidBiometricHint => 'Verifica la identitat';

  @override
  String get androidBiometricNotRecognized =>
      'No reconegut. Torna-ho a provar.';

  @override
  String get androidBiometricSuccess => 'Correcte';

  @override
  String get androidCancelButton => 'Cancel·la';

  @override
  String get androidSignInTitle => 'Es requereix autenticació';

  @override
  String get androidBiometricRequiredTitle => 'Biometria necessària';

  @override
  String get androidDeviceCredentialsRequiredTitle =>
      'Credencials del dispositiu requerides';

  @override
  String get androidDeviceCredentialsSetupDescription =>
      'Es requereixen credencials del dispositiu';

  @override
  String get goToSettings => 'Ves a configuració';

  @override
  String get androidGoToSettingsDescription =>
      'L\'autenticació biomètrica no està configurada al teu dispositiu. Ves a \'Configuració > Seguretat\' per afegir autenticació biomètrica.';

  @override
  String get iOSLockOut =>
      'L\'autenticació biomètrica està desactivada. Bloqueja i desbloqueja la pantalla per activar-la.';

  @override
  String get iOSOkButton => 'D\'acord';

  @override
  String get emailAlreadyRegistered =>
      'El correu electrònic ja està registrat.';

  @override
  String get emailNotRegistered => 'El correu electrònic no està registrat.';

  @override
  String get thisEmailIsAlreadyInUse =>
      'Aquest correu electrònic ja està en ús';

  @override
  String emailChangedTo(String newEmail) {
    return 'Correu electrònic canviat a $newEmail';
  }

  @override
  String get authenticationFailedPleaseTryAgain =>
      'Autenticació fallida, intenta-ho de nou';

  @override
  String get authenticationSuccessful => 'Autenticació amb èxit!';

  @override
  String get sessionExpired => 'La sessió ha caducat';

  @override
  String get incorrectRecoveryKey => 'Clau de recuperació incorrecta';

  @override
  String get theRecoveryKeyYouEnteredIsIncorrect =>
      'La clau de recuperació que has introduït és incorrecta';

  @override
  String get twofactorAuthenticationSuccessfullyReset =>
      'Autenticació de dos factors restablerta amb èxit';

  @override
  String get noRecoveryKey => 'No recovery key';

  @override
  String get yourAccountHasBeenDeleted => 'Your account has been deleted';

  @override
  String get verificationId => 'Verification ID';

  @override
  String get yourVerificationCodeHasExpired =>
      'El teu codi de verificació ha expirat';

  @override
  String get incorrectCode => 'Codi incorrecte';

  @override
  String get sorryTheCodeYouveEnteredIsIncorrect =>
      'Ho sentim, el codi que has introduït és incorrecte';

  @override
  String get developerSettings => 'Configuració de desenvolupador';

  @override
  String get serverEndpoint => 'Endpoint del servidor';

  @override
  String get invalidEndpoint => 'Endpoint no vàlid';

  @override
  String get invalidEndpointMessage =>
      'Ho sentim, l\'endpoint que has introduït no és vàlid. Introdueix un endpoint vàlid i torna-ho a intentar.';

  @override
  String get endpointUpdatedMessage => 'Extrem actualitzat correctament';
}
