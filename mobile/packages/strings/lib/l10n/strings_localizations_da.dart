// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Danish (`da`).
class StringsLocalizationsDa extends StringsLocalizations {
  StringsLocalizationsDa([String locale = 'da']) : super(locale);

  @override
  String get networkHostLookUpErr =>
      'Ude af stand til at forbinde til Ente. Tjek venligst dine netværksindstillinger og kontakt support hvis fejlen varer ved.';

  @override
  String get networkConnectionRefusedErr =>
      'Ude af stand til at forbinde til Ente. Forsøg igen efter et stykke tid. Hvis fejlen varer ved, kontakt da venligst support.';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      'Det ser ud til at noget gik galt. Forsøg venligst igen efter lidt tid. Hvis fejlen varer ved, kontakt da venligst support.';

  @override
  String get error => 'Fejl';

  @override
  String get ok => 'OK';

  @override
  String get faq => 'FAQ';

  @override
  String get contactSupport => 'Kontakt support';

  @override
  String get emailYourLogs => 'Email dine logs';

  @override
  String pleaseSendTheLogsTo(String toEmail) {
    return 'Send venligst logs til $toEmail';
  }

  @override
  String get copyEmailAddress => 'Kopier email adresse';

  @override
  String get exportLogs => 'Eksporter logs';

  @override
  String get cancel => 'Afbryd';

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
  String get reportABug => 'Rapporter en fejl';

  @override
  String get logsDialogBody =>
      'This will send across logs to help us debug your issue. Please note that file names will be included to help track issues with specific files.';

  @override
  String get viewLogs => 'View logs';

  @override
  String customEndpoint(String endpoint) {
    return 'Forbindelse oprettet til $endpoint';
  }

  @override
  String get save => 'Gem';

  @override
  String get send => 'Send';

  @override
  String get saveOrSendDescription =>
      'Vil du gemme på din enhed (Downloads mappe som udgangspunkt) eller sende til andre apps?';

  @override
  String get saveOnlyDescription =>
      'Vil du gemme på din enhed (Downloads mappe som udgangspunkt)?';

  @override
  String get enterNewEmailHint => 'Enter your new email address';

  @override
  String get email => 'Email';

  @override
  String get verify => 'Bekræft';

  @override
  String get invalidEmailTitle => 'Ugyldig email adresse';

  @override
  String get invalidEmailMessage => 'Indtast en gyldig email adresse.';

  @override
  String get pleaseWait => 'Vent venligst...';

  @override
  String get verifyPassword => 'Bekræft adgangskode';

  @override
  String get incorrectPasswordTitle => 'Forkert adgangskode';

  @override
  String get pleaseTryAgain => 'Forsøg venligst igen';

  @override
  String get enterPassword => 'Indtast adgangskode';

  @override
  String get enterYourPasswordHint => 'Indtast adgangskode';

  @override
  String get activeSessions => 'Aktive sessioner';

  @override
  String get oops => 'Ups';

  @override
  String get somethingWentWrongPleaseTryAgain =>
      'Noget gik galt, forsøg venligst igen';

  @override
  String get thisWillLogYouOutOfThisDevice =>
      'Dette vil logge dig ud af denne enhed!';

  @override
  String get thisWillLogYouOutOfTheFollowingDevice =>
      'Dette vil logge dig ud af den følgende enhed:';

  @override
  String get terminateSession => 'Afslut session?';

  @override
  String get terminate => 'Afslut';

  @override
  String get thisDevice => 'Denne enhed';

  @override
  String get createAccount => 'Opret konto';

  @override
  String get weakStrength => 'Svagt';

  @override
  String get moderateStrength => 'Middel';

  @override
  String get strongStrength => 'Stærkt';

  @override
  String get deleteAccount => 'Slet konto';

  @override
  String get deleteAccountQuery =>
      'Vi er kede af at se dig gå. Er du stødt på et problem?';

  @override
  String get yesSendFeedbackAction => 'Ja, send feedback';

  @override
  String get noDeleteAccountAction => 'Nej, slet konto';

  @override
  String get initiateAccountDeleteTitle =>
      'Bekræft venligst for at påbegynde sletning af konto';

  @override
  String get confirmAccountDeleteTitle => 'Bekræft sletning af konto';

  @override
  String get confirmAccountDeleteMessage =>
      'Denne konto er forbundet til andre Ente apps, hvis du benytter nogle.\n\nDine uploadede data for alle Ente apps vil blive slettet, og din konto vil blive slettet permanent.';

  @override
  String get delete => 'Slet';

  @override
  String get createNewAccount => 'Opret konto';

  @override
  String get password => 'Kodeord';

  @override
  String get confirmPassword => 'Bekræft kodeord';

  @override
  String passwordStrength(String passwordStrengthValue) {
    return 'Kodeordets styrke: $passwordStrengthValue';
  }

  @override
  String get hearUsWhereTitle => 'Hvordan hørte du om Ente? (valgfrit)';

  @override
  String get hearUsExplanation =>
      'Vi tracker ikke app installeringer. Det ville hjælpe os at vide hvordan du fandt os!';

  @override
  String get signUpTerms =>
      'Jeg er enig i <u-terms>betingelser for brug</u-terms> og <u-policy>privatlivspolitik</u-policy>';

  @override
  String get termsOfServicesTitle => 'Betingelser';

  @override
  String get privacyPolicyTitle => 'Privatlivspolitik';

  @override
  String get ackPasswordLostWarning =>
      'Jeg forstår at hvis jeg mister min adgangskode kan jeg miste mine data, da mine data er <underline>end-to-end krypteret</underline>.';

  @override
  String get encryption => 'Kryptering';

  @override
  String get logInLabel => 'Log ind';

  @override
  String get welcomeBack => 'Velkommen tilbage!';

  @override
  String get loginTerms =>
      'Ved at logge ind godkender jeg Ente\'s <u-terms>betingelser for brug</u-terms> og <u-policy>privatlivspolitik</u-policy>.';

  @override
  String get noInternetConnection => 'Ingen internetforbindelse';

  @override
  String get pleaseCheckYourInternetConnectionAndTryAgain =>
      'Tjek venligst din internetforbindelse og forsøg igen.';

  @override
  String get verificationFailedPleaseTryAgain =>
      'Bekræftelse fejlede, forsøg venligst igen';

  @override
  String get recreatePasswordTitle => 'Gendan adgangskode';

  @override
  String get recreatePasswordBody =>
      'Denne enhed er ikke kraftfuld nok til at bekræfte adgangskoden, men vi kan gendanne den på en måde der fungerer for alle enheder.\n\nLog venligst ind med din gendannelsesnøgle og gendan din adgangskode (du kan bruge den samme adgangskode igen hvis du ønsker).';

  @override
  String get useRecoveryKey => 'Brug gendannelsesnøgle';

  @override
  String get forgotPassword => 'Glemt adgangskode';

  @override
  String get changeEmail => 'Skift email adresse';

  @override
  String get verifyEmail => 'Bekræft email adresse';

  @override
  String weHaveSendEmailTo(String email) {
    return 'Vi har sendt en email til <green>$email</green>';
  }

  @override
  String get toResetVerifyEmail =>
      'For at nulstille din adgangskode, bekræft venligst din email adresse.';

  @override
  String get checkInboxAndSpamFolder =>
      'Tjek venligst din indboks (og spam) for at færdiggøre verificeringen';

  @override
  String get tapToEnterCode => 'Tryk for at indtaste kode';

  @override
  String get sendEmail => 'Send email';

  @override
  String get resendEmail => 'Send email igen';

  @override
  String get passKeyPendingVerification => 'Bekræftelse afventes stadig';

  @override
  String get loginSessionExpired => 'Session udløbet';

  @override
  String get loginSessionExpiredDetails =>
      'Din session er udløbet. Log venligst på igen.';

  @override
  String get passkeyAuthTitle => 'Bekræftelse af adgangskode';

  @override
  String get waitingForVerification => 'Venter på bekræftelse...';

  @override
  String get tryAgain => 'Forsøg igen';

  @override
  String get checkStatus => 'Tjek status';

  @override
  String get loginWithTOTP => 'Login with TOTP';

  @override
  String get recoverAccount => 'Gendan konto';

  @override
  String get setPasswordTitle => 'Angiv adgangskode';

  @override
  String get changePasswordTitle => 'Skift adgangskode';

  @override
  String get resetPasswordTitle => 'Nulstil adgangskode';

  @override
  String get encryptionKeys => 'Krypteringsnøgler';

  @override
  String get enterPasswordToEncrypt =>
      'Indtast en adgangskode vi kan bruge til at kryptere dine data';

  @override
  String get enterNewPasswordToEncrypt =>
      'Indtast en ny adgangskode vi kan bruge til at kryptere dine data';

  @override
  String get passwordWarning =>
      'Vi gemmer ikke denne adgangskode, så hvis du glemmer den <underline>kan vi ikke dekryptere dine data</underline>';

  @override
  String get howItWorks => 'Sådan fungerer det';

  @override
  String get generatingEncryptionKeys => 'Genererer krypteringsnøgler...';

  @override
  String get passwordChangedSuccessfully => 'Adgangskoden er blevet ændret';

  @override
  String get signOutFromOtherDevices => 'Log ud af andre enheder';

  @override
  String get signOutOtherBody =>
      'Hvis du mistænker at nogen kender din adgangskode kan du tvinge alle enheder der benytter din konto til at logge ud.';

  @override
  String get signOutOtherDevices => 'Log ud af andre enheder';

  @override
  String get doNotSignOut => 'Log ikke ud';

  @override
  String get generatingEncryptionKeysTitle => 'Genererer krypteringsnøgler...';

  @override
  String get continueLabel => 'Fortsæt';

  @override
  String get insecureDevice => 'Usikker enhed';

  @override
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease =>
      'Beklager, vi kunne ikke generere sikre krypteringsnøgler på denne enhed.\n\nForsøg venligst at oprette en konto fra en anden enhed.';

  @override
  String get recoveryKeyCopiedToClipboard =>
      'Gendannelsesnøgle kopieret til udklipsholderen';

  @override
  String get recoveryKey => 'Gendannelsesnøgle';

  @override
  String get recoveryKeyOnForgotPassword =>
      'Hvis du glemmer dit kodeord er gendannelsesnøglen den eneste mulighed for at få adgang til dine data.';

  @override
  String get recoveryKeySaveDescription =>
      'Vi gemmer ikke denne nøgle, gem venligst denne 24-ords nøgle et sikkert sted.';

  @override
  String get doThisLater => 'Gør det senere';

  @override
  String get saveKey => 'Gem nøgle';

  @override
  String get recoveryKeySaved =>
      'Gendannelsesnøgle gemt i din Downloads mappe!';

  @override
  String get noRecoveryKeyTitle => 'Ingen gendannelsesnøgle?';

  @override
  String get twoFactorAuthTitle => 'Tofaktorgodkendelse';

  @override
  String get enterCodeHint =>
      'Indtast den 6-cifrede kode fra din authenticator app';

  @override
  String get lostDeviceTitle => 'Mistet enhed?';

  @override
  String get enterRecoveryKeyHint => 'Indtast din gendannelsesnøgle';

  @override
  String get recover => 'Gendan';

  @override
  String get loggingOut => 'Logger ud...';

  @override
  String get immediately => 'Med det samme';

  @override
  String get appLock => 'Låsning af app';

  @override
  String get autoLock => 'Automatisk lås';

  @override
  String get noSystemLockFound => 'Ingen systemlås fundet';

  @override
  String get deviceLockEnablePreSteps =>
      'For at aktivere enhedslås, indstil venligst kode eller skærmlås på din enhed i dine systemindstillinger.';

  @override
  String get appLockDescription =>
      'Vælg mellem din enheds standard skærmlås eller skærmlås med pinkode eller adgangskode.';

  @override
  String get deviceLock => 'Enhedslås';

  @override
  String get pinLock => 'Låsning med pinkode';

  @override
  String get autoLockFeatureDescription =>
      'Tid til låsning af app efter at være blevet placeret i baggrunden';

  @override
  String get hideContent => 'Skjul indhold';

  @override
  String get hideContentDescriptionAndroid =>
      'Skjul app indhold i app-vælger og deaktiver screenshots';

  @override
  String get hideContentDescriptioniOS => 'Skjul app indhold i app-vælger';

  @override
  String get tooManyIncorrectAttempts => 'For mange forkerte forsøg';

  @override
  String get tapToUnlock => 'Tryk for at låse op';

  @override
  String get areYouSureYouWantToLogout => 'Er du sikker på at du vil logge ud?';

  @override
  String get yesLogout => 'Ja, log ud';

  @override
  String get authToViewSecrets =>
      'Bekræft venligst din identitet for at se dine hemmeligheder';

  @override
  String get next => 'Næste';

  @override
  String get setNewPassword => 'Indstil ny adgangskode';

  @override
  String get enterPin => 'Indtast pinkode';

  @override
  String get setNewPin => 'Indstil ny pinkode';

  @override
  String get confirm => 'Bekræft';

  @override
  String get reEnterPassword => 'Indtast adgangskode igen';

  @override
  String get reEnterPin => 'Indtast pinkode igen';

  @override
  String get androidBiometricHint => 'Bekræft identitet';

  @override
  String get androidBiometricNotRecognized => 'Ikke genkendt. Forsøg igen.';

  @override
  String get androidBiometricSuccess => 'Succes';

  @override
  String get androidCancelButton => 'Afbryd';

  @override
  String get androidSignInTitle => 'Godkendelse påkrævet';

  @override
  String get androidBiometricRequiredTitle => 'Biometri påkrævet';

  @override
  String get androidDeviceCredentialsRequiredTitle =>
      'Enhedsoplysninger påkrævet';

  @override
  String get androidDeviceCredentialsSetupDescription =>
      'Enhedsoplysninger påkrævet';

  @override
  String get goToSettings => 'Gå til indstillinger';

  @override
  String get androidGoToSettingsDescription =>
      'Biometrisk godkendelse er ikke indstillet på din enhed. Gå til \"Indstillinger > Sikkerhed\" for at indstille biometrisk godkendelse.';

  @override
  String get iOSLockOut =>
      'Biometrisk godkendelse er slået fra. Lås din skærm, og lås den derefter op for at aktivere det.';

  @override
  String get iOSOkButton => 'OK';

  @override
  String get emailAlreadyRegistered => 'Email already registered.';

  @override
  String get emailNotRegistered => 'Email not registered.';

  @override
  String get thisEmailIsAlreadyInUse =>
      'Denne email adresse er allerede i brug';

  @override
  String emailChangedTo(String newEmail) {
    return 'Email adresse ændret til $newEmail';
  }

  @override
  String get authenticationFailedPleaseTryAgain =>
      'Bekræftelse af identitet fejlede, forsøg venligst igen';

  @override
  String get authenticationSuccessful => 'Bekræftelse af identitet lykkedes!';

  @override
  String get sessionExpired => 'Session udløbet';

  @override
  String get incorrectRecoveryKey => 'Forkert gendannelsesnøgle';

  @override
  String get theRecoveryKeyYouEnteredIsIncorrect =>
      'Den indtastede gendannelsesnøgle er ikke korrekt';

  @override
  String get twofactorAuthenticationSuccessfullyReset =>
      'Tofaktorgodkendelse nulstillet';

  @override
  String get noRecoveryKey => 'No recovery key';

  @override
  String get yourAccountHasBeenDeleted => 'Your account has been deleted';

  @override
  String get verificationId => 'Verification ID';

  @override
  String get yourVerificationCodeHasExpired =>
      'Din bekræftelseskode er udløbet';

  @override
  String get incorrectCode => 'Forkert kode';

  @override
  String get sorryTheCodeYouveEnteredIsIncorrect =>
      'Beklager, den indtastede kode er forkert';

  @override
  String get developerSettings => 'Udvikler-indstillinger';

  @override
  String get serverEndpoint => 'Server endpoint';

  @override
  String get invalidEndpoint => 'Ugyldigt endpoint';

  @override
  String get invalidEndpointMessage =>
      'Beklager, det indtastede endpoint er ugyldigt. Indtast venligst et gyldigt endpoint og forsøg igen.';

  @override
  String get endpointUpdatedMessage => 'Endpoint opdateret';
}
