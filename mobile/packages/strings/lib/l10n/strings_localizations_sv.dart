// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class StringsLocalizationsSv extends StringsLocalizations {
  StringsLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get networkHostLookUpErr =>
      'Det gick inte att ansluta till Ente, kontrollera dina nätverksinställningar och kontakta supporten om felet kvarstår.';

  @override
  String get networkConnectionRefusedErr =>
      'Det gick inte att ansluta till Ente, försök igen om en stund. Om felet kvarstår, vänligen kontakta support.';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      'Det ser ut som om något gick fel. Försök igen efter en stund. Om felet kvarstår, vänligen kontakta vår support.';

  @override
  String get error => 'Fel';

  @override
  String get ok => 'OK';

  @override
  String get faq => 'FAQ';

  @override
  String get contactSupport => 'Kontakta support';

  @override
  String get emailYourLogs => 'Maila dina loggar';

  @override
  String pleaseSendTheLogsTo(String toEmail) {
    return 'Vänligen skicka loggarna till \n$toEmail';
  }

  @override
  String get copyEmailAddress => 'Kopiera e-postadress';

  @override
  String get exportLogs => 'Exportera loggar';

  @override
  String get cancel => 'Avbryt';

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
  String get reportABug => 'Rapportera en bugg';

  @override
  String get logsDialogBody =>
      'This will send across logs to help us debug your issue. Please note that file names will be included to help track issues with specific files.';

  @override
  String get viewLogs => 'View logs';

  @override
  String customEndpoint(String endpoint) {
    return 'Ansluten till $endpoint';
  }

  @override
  String get save => 'Spara';

  @override
  String get send => 'Skicka';

  @override
  String get saveOrSendDescription =>
      'Vill du spara detta till din lagringsmapp (Nedladdningsmappen som standard) eller skicka den till andra appar?';

  @override
  String get saveOnlyDescription =>
      'Vill du spara detta till din lagringsmapp (Nedladdningsmappen som standard)?';

  @override
  String get enterNewEmailHint => 'Ange din nya e-postadress';

  @override
  String get email => 'E-post';

  @override
  String get verify => 'Verifiera';

  @override
  String get invalidEmailTitle => 'Ogiltig e-postadress';

  @override
  String get invalidEmailMessage => 'Ange en giltig e-postadress.';

  @override
  String get pleaseWait => 'Vänligen vänta...';

  @override
  String get verifyPassword => 'Bekräfta lösenord';

  @override
  String get incorrectPasswordTitle => 'Felaktigt lösenord';

  @override
  String get pleaseTryAgain => 'Försök igen';

  @override
  String get enterPassword => 'Ange lösenord';

  @override
  String get enterYourPasswordHint => 'Ange ditt lösenord';

  @override
  String get activeSessions => 'Aktiva sessioner';

  @override
  String get oops => 'Hoppsan';

  @override
  String get somethingWentWrongPleaseTryAgain =>
      'Något gick fel, vänligen försök igen';

  @override
  String get thisWillLogYouOutOfThisDevice =>
      'Detta kommer att logga ut dig från den här enheten!';

  @override
  String get thisWillLogYouOutOfTheFollowingDevice =>
      'Detta kommer att logga ut dig från följande enhet:';

  @override
  String get terminateSession => 'Avsluta session?';

  @override
  String get terminate => 'Avsluta';

  @override
  String get thisDevice => 'Den här enheten';

  @override
  String get createAccount => 'Skapa konto';

  @override
  String get weakStrength => 'Svag';

  @override
  String get moderateStrength => 'Måttligt';

  @override
  String get strongStrength => 'Stark';

  @override
  String get deleteAccount => 'Radera konto';

  @override
  String get deleteAccountQuery =>
      'Vi kommer att vara ledsna över att se dig gå. Har du något problem?';

  @override
  String get yesSendFeedbackAction => 'Ja, skicka feedback';

  @override
  String get noDeleteAccountAction => 'Nej, radera konto';

  @override
  String get initiateAccountDeleteTitle =>
      'Vänligen autentisera för att initiera borttagning av konto';

  @override
  String get confirmAccountDeleteTitle => 'Bekräfta radering av kontot';

  @override
  String get confirmAccountDeleteMessage =>
      'Detta konto är kopplat till andra Ente apps, om du använder någon.\n\nDina uppladdade data, över alla Ente appar, kommer att schemaläggas för radering och ditt konto kommer att raderas permanent.';

  @override
  String get delete => 'Radera';

  @override
  String get createNewAccount => 'Skapa nytt konto';

  @override
  String get password => 'Lösenord';

  @override
  String get confirmPassword => 'Bekräfta lösenord';

  @override
  String passwordStrength(String passwordStrengthValue) {
    return 'Lösenordsstyrka: $passwordStrengthValue';
  }

  @override
  String get hearUsWhereTitle => 'Hur hörde du talas om Ente? (valfritt)';

  @override
  String get hearUsExplanation =>
      'Vi spårar inte appinstallationer, Det skulle hjälpa oss om du berättade var du hittade oss!';

  @override
  String get signUpTerms =>
      'Jag samtycker till <u-terms>användarvillkoren</u-terms> och <u-policy>integritetspolicyn</u-policy>';

  @override
  String get termsOfServicesTitle => 'Villkor';

  @override
  String get privacyPolicyTitle => 'Integritetspolicy';

  @override
  String get ackPasswordLostWarning =>
      'Jag förstår att om jag förlorar mitt lösenord kan jag förlora mina data eftersom min data är <underline>end-to-end-krypterad</underline>.';

  @override
  String get encryption => 'Kryptering';

  @override
  String get logInLabel => 'Logga in';

  @override
  String get welcomeBack => 'Välkommen tillbaka!';

  @override
  String get loginTerms =>
      'Jag samtycker till <u-terms>användarvillkoren</u-terms> och <u-policy>integritetspolicyn</u-policy>';

  @override
  String get noInternetConnection => 'Ingen internetanslutning';

  @override
  String get pleaseCheckYourInternetConnectionAndTryAgain =>
      'Kontrollera din internetanslutning och försök igen.';

  @override
  String get verificationFailedPleaseTryAgain =>
      'Verifiering misslyckades, vänligen försök igen';

  @override
  String get recreatePasswordTitle => 'Återskapa lösenord';

  @override
  String get recreatePasswordBody =>
      'Denna enhet är inte tillräckligt kraftfull för att verifiera ditt lösenord, men vi kan återskapa det på ett sätt som fungerar med alla enheter.\n\nLogga in med din återställningsnyckel och återskapa ditt lösenord (du kan använda samma igen om du vill).';

  @override
  String get useRecoveryKey => 'Använd återställningsnyckel';

  @override
  String get forgotPassword => 'Glömt lösenord';

  @override
  String get changeEmail => 'Ändra e-postadress';

  @override
  String get verifyEmail => 'Verifiera e-postadress';

  @override
  String weHaveSendEmailTo(String email) {
    return 'Vi har skickat ett mail till <green>$email</green>';
  }

  @override
  String get toResetVerifyEmail =>
      'För att återställa ditt lösenord måste du först bekräfta din e-postadress.';

  @override
  String get checkInboxAndSpamFolder =>
      'Vänligen kontrollera din inkorg (och skräppost) för att slutföra verifieringen';

  @override
  String get tapToEnterCode => 'Tryck för att ange kod';

  @override
  String get sendEmail => 'Skicka e-post';

  @override
  String get resendEmail => 'Skicka e-post igen';

  @override
  String get passKeyPendingVerification => 'Verifiering pågår fortfarande';

  @override
  String get loginSessionExpired => 'Sessionen har gått ut';

  @override
  String get loginSessionExpiredDetails =>
      'Din session har upphört. Logga in igen.';

  @override
  String get passkeyAuthTitle => 'Verifiering med inloggningsnyckel';

  @override
  String get waitingForVerification => 'Väntar på verifiering...';

  @override
  String get tryAgain => 'Försök igen';

  @override
  String get checkStatus => 'Kontrollera status';

  @override
  String get loginWithTOTP => 'Logga in med TOTP';

  @override
  String get recoverAccount => 'Återställ konto';

  @override
  String get setPasswordTitle => 'Ställ in lösenord';

  @override
  String get changePasswordTitle => 'Ändra lösenord';

  @override
  String get resetPasswordTitle => 'Återställ lösenord';

  @override
  String get encryptionKeys => 'Krypteringsnycklar';

  @override
  String get enterPasswordToEncrypt =>
      'Ange ett lösenord som vi kan använda för att kryptera din data';

  @override
  String get enterNewPasswordToEncrypt =>
      'Ange ett nytt lösenord som vi kan använda för att kryptera din data';

  @override
  String get passwordWarning =>
      'Vi lagrar inte detta lösenord, så om du glömmer bort det, <underline>kan vi inte dekryptera dina data</underline>';

  @override
  String get howItWorks => 'Så här fungerar det';

  @override
  String get generatingEncryptionKeys => 'Skapar krypteringsnycklar...';

  @override
  String get passwordChangedSuccessfully => 'Lösenordet har ändrats';

  @override
  String get signOutFromOtherDevices => 'Logga ut från andra enheter';

  @override
  String get signOutOtherBody =>
      'Om du tror att någon kanske känner till ditt lösenord kan du tvinga alla andra enheter med ditt konto att logga ut.';

  @override
  String get signOutOtherDevices => 'Logga ut andra enheter';

  @override
  String get doNotSignOut => 'Logga inte ut';

  @override
  String get generatingEncryptionKeysTitle => 'Skapar krypteringsnycklar...';

  @override
  String get continueLabel => 'Fortsätt';

  @override
  String get insecureDevice => 'Osäker enhet';

  @override
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease =>
      'Tyvärr, kunde vi inte generera säkra nycklar på den här enheten.\n\nvänligen registrera dig från en annan enhet.';

  @override
  String get recoveryKeyCopiedToClipboard =>
      'Återställningsnyckel kopierad till urklipp';

  @override
  String get recoveryKey => 'Återställningsnyckel';

  @override
  String get recoveryKeyOnForgotPassword =>
      'Om du glömmer ditt lösenord är det enda sättet du kan återställa dina data med denna nyckel.';

  @override
  String get recoveryKeySaveDescription =>
      'Vi lagrar inte och har därför inte åtkomst till denna nyckel, vänligen spara denna 24 ords nyckel på en säker plats.';

  @override
  String get doThisLater => 'Gör detta senare';

  @override
  String get saveKey => 'Spara nyckel';

  @override
  String get recoveryKeySaved =>
      'Återställningsnyckel sparad i nedladdningsmappen!';

  @override
  String get noRecoveryKeyTitle => 'Ingen återställningsnyckel?';

  @override
  String get twoFactorAuthTitle => 'Tvåfaktorsautentisering';

  @override
  String get enterCodeHint =>
      'Ange den 6-siffriga koden från din autentiseringsapp';

  @override
  String get lostDeviceTitle => 'Förlorad enhet?';

  @override
  String get enterRecoveryKeyHint => 'Ange din återställningsnyckel';

  @override
  String get recover => 'Återställ';

  @override
  String get loggingOut => 'Loggar ut...';

  @override
  String get immediately => 'Omedelbart';

  @override
  String get appLock => 'Applås';

  @override
  String get autoLock => 'Automatisk låsning';

  @override
  String get noSystemLockFound => 'Inget systemlås hittades';

  @override
  String get deviceLockEnablePreSteps =>
      'För att aktivera enhetslås, vänligen ställ in enhetens lösenord eller skärmlås i dina systeminställningar.';

  @override
  String get appLockDescription =>
      'Choose between your device\'s default lock screen and a custom lock screen with a PIN or password.';

  @override
  String get deviceLock => 'Enhetslås';

  @override
  String get pinLock => 'Pinkodslås';

  @override
  String get autoLockFeatureDescription =>
      'Time after which the app locks after being put in the background';

  @override
  String get hideContent => 'Dölj innehåll';

  @override
  String get hideContentDescriptionAndroid =>
      'Döljer appinnehåll i app-växlaren och inaktiverar skärmdumpar';

  @override
  String get hideContentDescriptioniOS => 'Döljer appinnehåll i app-växlaren';

  @override
  String get tooManyIncorrectAttempts => 'För många felaktiga försök';

  @override
  String get tapToUnlock => 'Tryck för att låsa upp';

  @override
  String get areYouSureYouWantToLogout =>
      'Är du säker på att du vill logga ut?';

  @override
  String get yesLogout => 'Ja, logga ut';

  @override
  String get authToViewSecrets =>
      'Autentisera för att visa din återställningsnyckel';

  @override
  String get next => 'Nästa';

  @override
  String get setNewPassword => 'Ställ in nytt lösenord';

  @override
  String get enterPin => 'Ange PIN-kod';

  @override
  String get setNewPin => 'Ställ in ny PIN-kod';

  @override
  String get confirm => 'Bekräfta';

  @override
  String get reEnterPassword => 'Ange lösenord igen';

  @override
  String get reEnterPin => 'Ange PIN-kod igen';

  @override
  String get androidBiometricHint => 'Verifiera identitet';

  @override
  String get androidBiometricNotRecognized => 'Ej godkänd. Försök igen.';

  @override
  String get androidBiometricSuccess => 'Slutförd';

  @override
  String get androidCancelButton => 'Avbryt';

  @override
  String get androidSignInTitle => 'Obligatorisk autentisering';

  @override
  String get androidBiometricRequiredTitle => 'Biometriska uppgifter krävs';

  @override
  String get androidDeviceCredentialsRequiredTitle => 'Enhetsuppgifter krävs';

  @override
  String get androidDeviceCredentialsSetupDescription =>
      'Enhetsuppgifter krävs';

  @override
  String get goToSettings => 'Gå till inställningar';

  @override
  String get androidGoToSettingsDescription =>
      'Biometrisk autentisering är inte konfigurerad på din enhet. Gå till \"Inställningar > Säkerhet\" för att lägga till biometrisk autentisering.';

  @override
  String get iOSLockOut =>
      'Biometrisk autentisering är inaktiverat. Lås och lås upp din skärm för att aktivera den.';

  @override
  String get iOSOkButton => 'OK';

  @override
  String get emailAlreadyRegistered => 'E-postadress redan registrerad.';

  @override
  String get emailNotRegistered => 'E-postadress ej registrerad.';

  @override
  String get thisEmailIsAlreadyInUse => 'Denna e-postadress används redan';

  @override
  String emailChangedTo(String newEmail) {
    return 'E-post ändrad till $newEmail';
  }

  @override
  String get authenticationFailedPleaseTryAgain =>
      'Autentisering misslyckades, vänligen försök igen';

  @override
  String get authenticationSuccessful => 'Autentisering lyckades!';

  @override
  String get sessionExpired => 'Sessionen har gått ut';

  @override
  String get incorrectRecoveryKey => 'Felaktig återställningsnyckel';

  @override
  String get theRecoveryKeyYouEnteredIsIncorrect =>
      'Återställningsnyckeln du angav är felaktig';

  @override
  String get twofactorAuthenticationSuccessfullyReset =>
      'Tvåfaktorsautentisering återställd';

  @override
  String get noRecoveryKey => 'No recovery key';

  @override
  String get yourAccountHasBeenDeleted => 'Your account has been deleted';

  @override
  String get verificationId => 'Verification ID';

  @override
  String get yourVerificationCodeHasExpired =>
      'Din verifieringskod har upphört att gälla';

  @override
  String get incorrectCode => 'Felaktig kod';

  @override
  String get sorryTheCodeYouveEnteredIsIncorrect =>
      'Tyvärr, den kod som du har angett är felaktig';

  @override
  String get developerSettings => 'Utvecklarinställningar';

  @override
  String get serverEndpoint => 'Serverns slutpunkt';

  @override
  String get invalidEndpoint => 'Ogiltig slutpunkt';

  @override
  String get invalidEndpointMessage =>
      'Tyvärr, slutpunkten du angav är ogiltig. Ange en giltig slutpunkt och försök igen.';

  @override
  String get endpointUpdatedMessage => 'Slutpunkten har uppdaterats';
}
