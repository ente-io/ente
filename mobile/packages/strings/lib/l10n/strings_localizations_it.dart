// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class StringsLocalizationsIt extends StringsLocalizations {
  StringsLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get networkHostLookUpErr =>
      'Impossibile connettersi a Ente, controlla le impostazioni di rete e contatta l\'assistenza se l\'errore persiste.';

  @override
  String get networkConnectionRefusedErr =>
      'Impossibile connettersi a Ente, riprova tra un po\' di tempo. Se l\'errore persiste, contatta l\'assistenza.';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      'Sembra che qualcosa sia andato storto. Riprova tra un po\'. Se l\'errore persiste, contatta il nostro team di supporto.';

  @override
  String get error => 'Errore';

  @override
  String get ok => 'OK';

  @override
  String get faq => 'FAQ';

  @override
  String get contactSupport => 'Contatta il supporto';

  @override
  String get emailYourLogs => 'Invia una mail dei tuoi log';

  @override
  String pleaseSendTheLogsTo(String toEmail) {
    return 'Invia i log a \n$toEmail';
  }

  @override
  String get copyEmailAddress => 'Copia indirizzo email';

  @override
  String get exportLogs => 'Esporta log';

  @override
  String get cancel => 'Annulla';

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
  String get reportABug => 'Segnala un problema';

  @override
  String get logsDialogBody =>
      'This will send across logs to help us debug your issue. Please note that file names will be included to help track issues with specific files.';

  @override
  String get viewLogs => 'View logs';

  @override
  String customEndpoint(String endpoint) {
    return 'Connesso a $endpoint';
  }

  @override
  String get save => 'Salva';

  @override
  String get send => 'Invia';

  @override
  String get saveOrSendDescription =>
      'Vuoi salvarlo nel tuo spazio di archiviazione (cartella Download per impostazione predefinita) o inviarlo ad altre applicazioni?';

  @override
  String get saveOnlyDescription =>
      'Vuoi salvarlo nel tuo spazio di archiviazione (cartella Download per impostazione predefinita)?';

  @override
  String get enterNewEmailHint => 'Inserisci il tuo nuovo indirizzo email';

  @override
  String get email => 'Email';

  @override
  String get verify => 'Verifica';

  @override
  String get invalidEmailTitle => 'Indirizzo email non valido';

  @override
  String get invalidEmailMessage => 'Inserisci un indirizzo email valido.';

  @override
  String get pleaseWait => 'Attendere prego...';

  @override
  String get verifyPassword => 'Verifica la password';

  @override
  String get incorrectPasswordTitle => 'Password sbagliata';

  @override
  String get pleaseTryAgain => 'Per favore riprova';

  @override
  String get enterPassword => 'Inserisci la password';

  @override
  String get enterYourPasswordHint => 'Inserisci la tua password';

  @override
  String get activeSessions => 'Sessioni attive';

  @override
  String get oops => 'Oops';

  @override
  String get somethingWentWrongPleaseTryAgain =>
      'Qualcosa è andato storto, per favore riprova';

  @override
  String get thisWillLogYouOutOfThisDevice =>
      'Questo ti disconnetterà da questo dispositivo!';

  @override
  String get thisWillLogYouOutOfTheFollowingDevice =>
      'Questo ti disconnetterà dal seguente dispositivo:';

  @override
  String get terminateSession => 'Termina sessione?';

  @override
  String get terminate => 'Termina';

  @override
  String get thisDevice => 'Questo dispositivo';

  @override
  String get createAccount => 'Crea account';

  @override
  String get weakStrength => 'Debole';

  @override
  String get moderateStrength => 'Mediocre';

  @override
  String get strongStrength => 'Forte';

  @override
  String get deleteAccount => 'Elimina account';

  @override
  String get deleteAccountQuery =>
      'Ci dispiace vederti andare via. Stai avendo qualche problema?';

  @override
  String get yesSendFeedbackAction => 'Sì, invia un feedback';

  @override
  String get noDeleteAccountAction => 'No, elimina l\'account';

  @override
  String get initiateAccountDeleteTitle =>
      'Si prega di autenticarsi per avviare l\'eliminazione dell\'account';

  @override
  String get confirmAccountDeleteTitle =>
      'Conferma l\'eliminazione dell\'account';

  @override
  String get confirmAccountDeleteMessage =>
      'Questo account è collegato ad altre app di Ente, se ne utilizzi.\n\nI tuoi dati caricati, su tutte le app di Ente, saranno pianificati per la cancellazione e il tuo account verrà eliminato definitivamente.';

  @override
  String get delete => 'Cancella';

  @override
  String get createNewAccount => 'Crea un nuovo account';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Conferma la password';

  @override
  String passwordStrength(String passwordStrengthValue) {
    return 'Forza password: $passwordStrengthValue';
  }

  @override
  String get hearUsWhereTitle =>
      'Dove hai sentito parlare di Ente? (opzionale)';

  @override
  String get hearUsExplanation =>
      'Non teniamo traccia delle installazioni dell\'app. Sarebbe utile se ci dicessi dove ci hai trovato!';

  @override
  String get signUpTerms =>
      'Accetto i <u-terms>termini di servizio</u-terms> e la <u-policy>politica sulla privacy</u-policy>';

  @override
  String get termsOfServicesTitle => 'Termini';

  @override
  String get privacyPolicyTitle => 'Politica sulla Privacy';

  @override
  String get ackPasswordLostWarning =>
      'Comprendo che se perdo la password, potrei perdere l\'accesso ai miei dati poiché i miei dati sono <underline>criptati end-to-end</underline>.';

  @override
  String get encryption => 'Crittografia';

  @override
  String get logInLabel => 'Accedi';

  @override
  String get welcomeBack => 'Bentornato!';

  @override
  String get loginTerms =>
      'Cliccando sul pulsante Accedi, accetto i <u-terms>termini di servizio</u-terms> e la <u-policy>politica sulla privacy</u-policy>';

  @override
  String get noInternetConnection => 'Nessuna connessione internet';

  @override
  String get pleaseCheckYourInternetConnectionAndTryAgain =>
      'Si prega di verificare la propria connessione Internet e riprovare.';

  @override
  String get verificationFailedPleaseTryAgain =>
      'Verifica fallita, per favore riprova';

  @override
  String get recreatePasswordTitle => 'Ricrea password';

  @override
  String get recreatePasswordBody =>
      'Il dispositivo attuale non è abbastanza potente per verificare la tua password, ma la possiamo rigenerare in un modo che funzioni su tutti i dispositivi.\n\nEffettua il login utilizzando la tua chiave di recupero e rigenera la tua password (puoi utilizzare nuovamente la stessa se vuoi).';

  @override
  String get useRecoveryKey => 'Utilizza un codice di recupero';

  @override
  String get forgotPassword => 'Password dimenticata';

  @override
  String get changeEmail => 'Modifica email';

  @override
  String get verifyEmail => 'Verifica email';

  @override
  String weHaveSendEmailTo(String email) {
    return 'Abbiamo inviato una mail a <green>$email</green>';
  }

  @override
  String get toResetVerifyEmail =>
      'Per reimpostare la tua password, prima verifica la tua email.';

  @override
  String get checkInboxAndSpamFolder =>
      'Per favore, controlla la tua casella di posta (e lo spam) per completare la verifica';

  @override
  String get tapToEnterCode => 'Tocca per inserire il codice';

  @override
  String get sendEmail => 'Invia email';

  @override
  String get resendEmail => 'Rinvia email';

  @override
  String get passKeyPendingVerification => 'La verifica è ancora in corso';

  @override
  String get loginSessionExpired => 'Sessione scaduta';

  @override
  String get loginSessionExpiredDetails =>
      'La sessione è scaduta. Si prega di accedere nuovamente.';

  @override
  String get passkeyAuthTitle => 'Verifica della passkey';

  @override
  String get waitingForVerification => 'In attesa di verifica...';

  @override
  String get tryAgain => 'Riprova';

  @override
  String get checkStatus => 'Verifica stato';

  @override
  String get loginWithTOTP => 'Login con TOTP';

  @override
  String get recoverAccount => 'Recupera account';

  @override
  String get setPasswordTitle => 'Imposta password';

  @override
  String get changePasswordTitle => 'Modifica password';

  @override
  String get resetPasswordTitle => 'Reimposta password';

  @override
  String get encryptionKeys => 'Chiavi di crittografia';

  @override
  String get enterPasswordToEncrypt =>
      'Inserisci una password per criptare i tuoi dati';

  @override
  String get enterNewPasswordToEncrypt =>
      'Inserisci una nuova password per criptare i tuoi dati';

  @override
  String get passwordWarning =>
      'Non memorizziamo questa password, quindi se te la dimentichi, <underline>non possiamo decriptare i tuoi dati</underline>';

  @override
  String get howItWorks => 'Come funziona';

  @override
  String get generatingEncryptionKeys =>
      'Generazione delle chiavi di crittografia...';

  @override
  String get passwordChangedSuccessfully => 'Password modificata con successo';

  @override
  String get signOutFromOtherDevices => 'Esci dagli altri dispositivi';

  @override
  String get signOutOtherBody =>
      'Se pensi che qualcuno possa conoscere la tua password, puoi forzare tutti gli altri dispositivi che usano il tuo account ad uscire.';

  @override
  String get signOutOtherDevices => 'Esci dagli altri dispositivi';

  @override
  String get doNotSignOut => 'Non uscire';

  @override
  String get generatingEncryptionKeysTitle =>
      'Generazione delle chiavi di crittografia...';

  @override
  String get continueLabel => 'Continua';

  @override
  String get insecureDevice => 'Dispositivo non sicuro';

  @override
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease =>
      'Siamo spiacenti, non possiamo generare le chiavi sicure su questo dispositivo.\n\nPer favore, accedi da un altro dispositivo.';

  @override
  String get recoveryKeyCopiedToClipboard =>
      'Chiave di recupero copiata negli appunti';

  @override
  String get recoveryKey => 'Chiave di recupero';

  @override
  String get recoveryKeyOnForgotPassword =>
      'Se dimentichi la password, l\'unico modo per recuperare i tuoi dati è con questa chiave.';

  @override
  String get recoveryKeySaveDescription =>
      'Non memorizziamo questa chiave, per favore salva questa chiave di 24 parole in un posto sicuro.';

  @override
  String get doThisLater => 'Fallo più tardi';

  @override
  String get saveKey => 'Salva chiave';

  @override
  String get recoveryKeySaved =>
      'Chiave di recupero salvata nella cartella Download!';

  @override
  String get noRecoveryKeyTitle => 'Nessuna chiave di recupero?';

  @override
  String get twoFactorAuthTitle => 'Autenticazione a due fattori';

  @override
  String get enterCodeHint =>
      'Inserisci il codice di 6 cifre dalla tua app di autenticazione';

  @override
  String get lostDeviceTitle => 'Dispositivo perso?';

  @override
  String get enterRecoveryKeyHint => 'Inserisci la tua chiave di recupero';

  @override
  String get recover => 'Recupera';

  @override
  String get loggingOut => 'Disconnessione...';

  @override
  String get immediately => 'Immediatamente';

  @override
  String get appLock => 'Blocco app';

  @override
  String get autoLock => 'Blocco automatico';

  @override
  String get noSystemLockFound => 'Nessun blocco di sistema trovato';

  @override
  String get deviceLockEnablePreSteps =>
      'Per attivare il blocco del dispositivo, impostare il codice di accesso o il blocco dello schermo nelle impostazioni del sistema.';

  @override
  String get appLockDescription =>
      'Scegli tra la schermata di blocco predefinita del dispositivo e una schermata di blocco personalizzata con PIN o password.';

  @override
  String get deviceLock => 'Blocco del dispositivo';

  @override
  String get pinLock => 'Blocco con PIN';

  @override
  String get autoLockFeatureDescription =>
      'Tempo dopo il quale l\'applicazione si blocca dopo essere stata messa in background';

  @override
  String get hideContent => 'Nascondi il contenuto';

  @override
  String get hideContentDescriptionAndroid =>
      'Nasconde il contenuto nel selettore delle app e disabilita gli screenshot';

  @override
  String get hideContentDescriptioniOS =>
      'Nasconde il contenuto nel selettore delle app';

  @override
  String get tooManyIncorrectAttempts => 'Troppi tentativi errati';

  @override
  String get tapToUnlock => 'Tocca per sbloccare';

  @override
  String get areYouSureYouWantToLogout =>
      'Sei sicuro di volerti disconnettere?';

  @override
  String get yesLogout => 'Si, effettua la disconnessione';

  @override
  String get authToViewSecrets => 'Autenticati per visualizzare i tuoi segreti';

  @override
  String get next => 'Successivo';

  @override
  String get setNewPassword => 'Imposta una nuova password';

  @override
  String get enterPin => 'Inserisci PIN';

  @override
  String get setNewPin => 'Imposta un nuovo PIN';

  @override
  String get confirm => 'Conferma';

  @override
  String get reEnterPassword => 'Reinserisci la password';

  @override
  String get reEnterPin => 'Reinserisci il PIN';

  @override
  String get androidBiometricHint => 'Verifica l\'identità';

  @override
  String get androidBiometricNotRecognized => 'Non riconosciuto. Riprova.';

  @override
  String get androidBiometricSuccess => 'Successo';

  @override
  String get androidCancelButton => 'Annulla';

  @override
  String get androidSignInTitle => 'Autenticazione necessaria';

  @override
  String get androidBiometricRequiredTitle =>
      'Autenticazione biometrica richiesta';

  @override
  String get androidDeviceCredentialsRequiredTitle =>
      'Credenziali del dispositivo richieste';

  @override
  String get androidDeviceCredentialsSetupDescription =>
      'Credenziali del dispositivo richieste';

  @override
  String get goToSettings => 'Vai alle impostazioni';

  @override
  String get androidGoToSettingsDescription =>
      'L\'autenticazione biometrica non è impostata sul tuo dispositivo. Vai a \'Impostazioni > Sicurezza\' per impostarla.';

  @override
  String get iOSLockOut =>
      'L\'autenticazione biometrica è disabilitata. Blocca e sblocca lo schermo per abilitarla.';

  @override
  String get iOSOkButton => 'OK';

  @override
  String get emailAlreadyRegistered => 'Email già registrata.';

  @override
  String get emailNotRegistered => 'Email non registrata.';

  @override
  String get thisEmailIsAlreadyInUse => 'Questa email é già in uso';

  @override
  String emailChangedTo(String newEmail) {
    return 'Email modificata in $newEmail';
  }

  @override
  String get authenticationFailedPleaseTryAgain =>
      'Autenticazione non riuscita, riprova';

  @override
  String get authenticationSuccessful => 'Autenticazione riuscita!';

  @override
  String get sessionExpired => 'Sessione scaduta';

  @override
  String get incorrectRecoveryKey => 'Chiave di recupero errata';

  @override
  String get theRecoveryKeyYouEnteredIsIncorrect =>
      'La chiave di recupero che hai inserito non è corretta';

  @override
  String get twofactorAuthenticationSuccessfullyReset =>
      'Autenticazione a due fattori ripristinata con successo';

  @override
  String get noRecoveryKey => 'No recovery key';

  @override
  String get yourAccountHasBeenDeleted => 'Your account has been deleted';

  @override
  String get verificationId => 'Verification ID';

  @override
  String get yourVerificationCodeHasExpired =>
      'Il tuo codice di verifica è scaduto';

  @override
  String get incorrectCode => 'Codice errato';

  @override
  String get sorryTheCodeYouveEnteredIsIncorrect =>
      'Spiacenti, il codice che hai inserito non è corretto';

  @override
  String get developerSettings => 'Impostazioni sviluppatore';

  @override
  String get serverEndpoint => 'Endpoint del server';

  @override
  String get invalidEndpoint => 'Endpoint invalido';

  @override
  String get invalidEndpointMessage =>
      'Spiacenti, l\'endpoint inserito non è valido. Inserisci un endpoint valido e riprova.';

  @override
  String get endpointUpdatedMessage => 'Endpoint aggiornato con successo';
}
