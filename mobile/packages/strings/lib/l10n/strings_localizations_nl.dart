// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class StringsLocalizationsNl extends StringsLocalizations {
  StringsLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get networkHostLookUpErr =>
      'Kan geen verbinding maken met Ente, controleer uw netwerkinstellingen en neem contact op met ondersteuning als de fout zich blijft voordoen.';

  @override
  String get networkConnectionRefusedErr =>
      'Kan geen verbinding maken met Ente, probeer het later opnieuw. Als de fout zich blijft voordoen, neem dan contact op met support.';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      'Het lijkt erop dat er iets fout is gegaan. Probeer het later opnieuw. Als de fout zich blijft voordoen, neem dan contact op met ons supportteam.';

  @override
  String get error => 'Foutmelding';

  @override
  String get ok => 'Oké';

  @override
  String get faq => 'Veelgestelde vragen';

  @override
  String get contactSupport => 'Klantenservice';

  @override
  String get emailYourLogs => 'E-mail uw logs';

  @override
  String pleaseSendTheLogsTo(String toEmail) {
    return 'Verstuur de logs alsjeblieft naar $toEmail';
  }

  @override
  String get copyEmailAddress => 'E-mailadres kopiëren';

  @override
  String get exportLogs => 'Logs exporteren';

  @override
  String get cancel => 'Annuleer';

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
  String get reportABug => 'Een fout melden';

  @override
  String get logsDialogBody =>
      'This will send across logs to help us debug your issue. Please note that file names will be included to help track issues with specific files.';

  @override
  String get viewLogs => 'View logs';

  @override
  String customEndpoint(String endpoint) {
    return 'Verbonden met $endpoint';
  }

  @override
  String get save => 'Opslaan';

  @override
  String get send => 'Verzenden';

  @override
  String get saveOrSendDescription =>
      'Wil je dit opslaan naar je opslagruimte (Downloads map) of naar andere apps versturen?';

  @override
  String get saveOnlyDescription =>
      'Wil je dit opslaan naar je opslagruimte (Downloads map)?';

  @override
  String get enterNewEmailHint => 'Voer uw nieuwe e-mailadres in';

  @override
  String get email => 'E-mail';

  @override
  String get verify => 'Verifiëren';

  @override
  String get invalidEmailTitle => 'Ongeldig e-mailadres';

  @override
  String get invalidEmailMessage => 'Voer een geldig e-mailadres in.';

  @override
  String get pleaseWait => 'Een ogenblik geduld...';

  @override
  String get verifyPassword => 'Bevestig wachtwoord';

  @override
  String get incorrectPasswordTitle => 'Onjuist wachtwoord';

  @override
  String get pleaseTryAgain => 'Probeer het nog eens';

  @override
  String get enterPassword => 'Voer wachtwoord in';

  @override
  String get enterYourPasswordHint => 'Voer je wachtwoord in';

  @override
  String get activeSessions => 'Actieve sessies';

  @override
  String get oops => 'Oeps';

  @override
  String get somethingWentWrongPleaseTryAgain =>
      'Er is iets fout gegaan, probeer het opnieuw';

  @override
  String get thisWillLogYouOutOfThisDevice =>
      'Dit zal je uitloggen van dit apparaat!';

  @override
  String get thisWillLogYouOutOfTheFollowingDevice =>
      'Dit zal je uitloggen van het volgende apparaat:';

  @override
  String get terminateSession => 'Sessie beëindigen?';

  @override
  String get terminate => 'Beëindigen';

  @override
  String get thisDevice => 'Dit apparaat';

  @override
  String get createAccount => 'Account aanmaken';

  @override
  String get weakStrength => 'Zwak';

  @override
  String get moderateStrength => 'Matig';

  @override
  String get strongStrength => 'Sterk';

  @override
  String get deleteAccount => 'Account verwijderen';

  @override
  String get deleteAccountQuery =>
      'We zullen het vervelend vinden om je te zien vertrekken. Zijn er problemen?';

  @override
  String get yesSendFeedbackAction => 'Ja, geef feedback';

  @override
  String get noDeleteAccountAction => 'Nee, verwijder account';

  @override
  String get initiateAccountDeleteTitle =>
      'Gelieve te verifiëren om het account te verwijderen';

  @override
  String get confirmAccountDeleteTitle => 'Account verwijderen bevestigen';

  @override
  String get confirmAccountDeleteMessage =>
      'Dit account is gekoppeld aan andere Ente apps, als je er gebruik van maakt.\n\nJe geüploade gegevens worden in alle Ente apps gepland voor verwijdering, en je account wordt permanent verwijderd voor alle Ente diensten.';

  @override
  String get delete => 'Verwijderen';

  @override
  String get createNewAccount => 'Nieuw account aanmaken';

  @override
  String get password => 'Wachtwoord';

  @override
  String get confirmPassword => 'Wachtwoord bevestigen';

  @override
  String passwordStrength(String passwordStrengthValue) {
    return 'Wachtwoord sterkte: $passwordStrengthValue';
  }

  @override
  String get hearUsWhereTitle => 'Hoe hoorde je over Ente? (optioneel)';

  @override
  String get hearUsExplanation =>
      'Wij gebruiken geen tracking. Het zou helpen als je ons vertelt waar je ons gevonden hebt!';

  @override
  String get signUpTerms =>
      'Ik ga akkoord met de <u-terms>gebruiksvoorwaarden</u-terms> en <u-policy>privacybeleid</u-policy>';

  @override
  String get termsOfServicesTitle => 'Voorwaarden';

  @override
  String get privacyPolicyTitle => 'Privacybeleid';

  @override
  String get ackPasswordLostWarning =>
      'Ik begrijp dat als ik mijn wachtwoord verlies, ik mijn gegevens kan verliezen omdat mijn gegevens <underline>end-to-end versleuteld</underline> zijn.';

  @override
  String get encryption => 'Encryptie';

  @override
  String get logInLabel => 'Inloggen';

  @override
  String get welcomeBack => 'Welkom terug!';

  @override
  String get loginTerms =>
      'Door op inloggen te klikken, ga ik akkoord met de <u-terms>gebruiksvoorwaarden</u-terms> en <u-policy>privacybeleid</u-policy>';

  @override
  String get noInternetConnection => 'Geen internetverbinding';

  @override
  String get pleaseCheckYourInternetConnectionAndTryAgain =>
      'Controleer je internetverbinding en probeer het opnieuw.';

  @override
  String get verificationFailedPleaseTryAgain =>
      'Verificatie mislukt, probeer het opnieuw';

  @override
  String get recreatePasswordTitle => 'Wachtwoord opnieuw instellen';

  @override
  String get recreatePasswordBody =>
      'Het huidige apparaat is niet krachtig genoeg om je wachtwoord te verifiëren, dus moeten we de code een keer opnieuw genereren op een manier die met alle apparaten werkt.\n\nLog in met behulp van uw herstelsleutel en genereer opnieuw uw wachtwoord (je kunt dezelfde indien gewenst opnieuw gebruiken).';

  @override
  String get useRecoveryKey => 'Herstelsleutel gebruiken';

  @override
  String get forgotPassword => 'Wachtwoord vergeten';

  @override
  String get changeEmail => 'E-mailadres wijzigen';

  @override
  String get verifyEmail => 'Bevestig e-mail';

  @override
  String weHaveSendEmailTo(String email) {
    return 'We hebben een e-mail gestuurd naar <green>$email</green>';
  }

  @override
  String get toResetVerifyEmail =>
      'Verifieer eerst je e-mailadres om je wachtwoord opnieuw in te stellen.';

  @override
  String get checkInboxAndSpamFolder =>
      'Controleer je inbox (en spam) om verificatie te voltooien';

  @override
  String get tapToEnterCode => 'Tik om code in te voeren';

  @override
  String get sendEmail => 'E-mail versturen';

  @override
  String get resendEmail => 'E-mail opnieuw versturen';

  @override
  String get passKeyPendingVerification => 'Verificatie is nog in behandeling';

  @override
  String get loginSessionExpired => 'Sessie verlopen';

  @override
  String get loginSessionExpiredDetails =>
      'Jouw sessie is verlopen. Log opnieuw in.';

  @override
  String get passkeyAuthTitle => 'Passkey verificatie';

  @override
  String get waitingForVerification => 'Wachten op verificatie...';

  @override
  String get tryAgain => 'Probeer opnieuw';

  @override
  String get checkStatus => 'Status controleren';

  @override
  String get loginWithTOTP => 'Inloggen met TOTP';

  @override
  String get recoverAccount => 'Account herstellen';

  @override
  String get setPasswordTitle => 'Wachtwoord instellen';

  @override
  String get changePasswordTitle => 'Wachtwoord wijzigen';

  @override
  String get resetPasswordTitle => 'Wachtwoord resetten';

  @override
  String get encryptionKeys => 'Encryptiesleutels';

  @override
  String get enterPasswordToEncrypt =>
      'Voer een wachtwoord in dat we kunnen gebruiken om je gegevens te versleutelen';

  @override
  String get enterNewPasswordToEncrypt =>
      'Voer een nieuw wachtwoord in dat we kunnen gebruiken om je gegevens te versleutelen';

  @override
  String get passwordWarning =>
      'Wij slaan dit wachtwoord niet op, dus als je het vergeet, <underline>kunnen we jouw gegevens niet ontsleutelen</underline>';

  @override
  String get howItWorks => 'Hoe het werkt';

  @override
  String get generatingEncryptionKeys =>
      'Encryptiesleutels worden gegenereerd...';

  @override
  String get passwordChangedSuccessfully => 'Wachtwoord succesvol aangepast';

  @override
  String get signOutFromOtherDevices => 'Afmelden bij andere apparaten';

  @override
  String get signOutOtherBody =>
      'Als je denkt dat iemand je wachtwoord zou kunnen kennen, kun je alle andere apparaten die je account gebruiken dwingen om uit te loggen.';

  @override
  String get signOutOtherDevices => 'Afmelden bij andere apparaten';

  @override
  String get doNotSignOut => 'Niet uitloggen';

  @override
  String get generatingEncryptionKeysTitle => 'Encryptiesleutels genereren...';

  @override
  String get continueLabel => 'Doorgaan';

  @override
  String get insecureDevice => 'Onveilig apparaat';

  @override
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease =>
      'Sorry, we konden geen beveiligde sleutels genereren op dit apparaat.\n\nMeld je aan vanaf een ander apparaat.';

  @override
  String get recoveryKeyCopiedToClipboard =>
      'Herstelsleutel gekopieerd naar klembord';

  @override
  String get recoveryKey => 'Herstelsleutel';

  @override
  String get recoveryKeyOnForgotPassword =>
      'Als je je wachtwoord vergeet, kun je alleen met deze code je gegevens herstellen.';

  @override
  String get recoveryKeySaveDescription =>
      'We slaan deze code niet op, bewaar deze code met 24 woorden op een veilige plaats.';

  @override
  String get doThisLater => 'Doe dit later';

  @override
  String get saveKey => 'Sleutel opslaan';

  @override
  String get recoveryKeySaved =>
      'Herstelsleutel opgeslagen in de Downloads map!';

  @override
  String get noRecoveryKeyTitle => 'Geen herstelsleutel?';

  @override
  String get twoFactorAuthTitle => 'Tweestapsverificatie';

  @override
  String get enterCodeHint =>
      'Voer de 6-cijferige code van je verificatie-app in';

  @override
  String get lostDeviceTitle => 'Apparaat verloren?';

  @override
  String get enterRecoveryKeyHint => 'Voer je herstelsleutel in';

  @override
  String get recover => 'Herstellen';

  @override
  String get loggingOut => 'Bezig met uitloggen...';

  @override
  String get immediately => 'Onmiddellijk';

  @override
  String get appLock => 'App-vergrendeling';

  @override
  String get autoLock => 'Automatische vergrendeling';

  @override
  String get noSystemLockFound => 'Geen systeemvergrendeling gevonden';

  @override
  String get deviceLockEnablePreSteps =>
      'Om toestelvergrendeling in te schakelen, stelt u de toegangscode van het apparaat of schermvergrendeling in uw systeeminstellingen in.';

  @override
  String get appLockDescription =>
      'Kies tussen de standaard schermvergrendeling van uw apparaat en een aangepaste schermvergrendeling met een pincode of wachtwoord.';

  @override
  String get deviceLock => 'Apparaat vergrendeling';

  @override
  String get pinLock => 'Pin vergrendeling';

  @override
  String get autoLockFeatureDescription =>
      'Tijd waarna de app vergrendelt nadat ze op de achtergrond is gezet';

  @override
  String get hideContent => 'Inhoud verbergen';

  @override
  String get hideContentDescriptionAndroid =>
      'Verbergt de app inhoud in de app switcher en schakelt schermafbeeldingen uit';

  @override
  String get hideContentDescriptioniOS =>
      'Verbergt de inhoud van de app in de app switcher';

  @override
  String get tooManyIncorrectAttempts => 'Te veel onjuiste pogingen';

  @override
  String get tapToUnlock => 'Tik om te ontgrendelen';

  @override
  String get areYouSureYouWantToLogout =>
      'Weet je zeker dat je wilt uitloggen?';

  @override
  String get yesLogout => 'Ja, uitloggen';

  @override
  String get authToViewSecrets =>
      'Graag verifiëren om uw herstelsleutel te bekijken';

  @override
  String get next => 'Volgende';

  @override
  String get setNewPassword => 'Nieuw wachtwoord instellen';

  @override
  String get enterPin => 'Pin invoeren';

  @override
  String get setNewPin => 'Nieuwe pin instellen';

  @override
  String get confirm => 'Bevestig';

  @override
  String get reEnterPassword => 'Wachtwoord opnieuw invoeren';

  @override
  String get reEnterPin => 'PIN opnieuw invoeren';

  @override
  String get androidBiometricHint => 'Identiteit verifiëren';

  @override
  String get androidBiometricNotRecognized =>
      'Niet herkend. Probeer het opnieuw.';

  @override
  String get androidBiometricSuccess => 'Succes';

  @override
  String get androidCancelButton => 'Annuleren';

  @override
  String get androidSignInTitle => 'Verificatie vereist';

  @override
  String get androidBiometricRequiredTitle =>
      'Biometrische verificatie vereist';

  @override
  String get androidDeviceCredentialsRequiredTitle =>
      'Apparaatgegevens vereist';

  @override
  String get androidDeviceCredentialsSetupDescription =>
      'Apparaatgegevens vereist';

  @override
  String get goToSettings => 'Ga naar instellingen';

  @override
  String get androidGoToSettingsDescription =>
      'Biometrische verificatie is niet ingesteld op uw apparaat. Ga naar \'Instellingen > Beveiliging\' om biometrische verificatie toe te voegen.';

  @override
  String get iOSLockOut =>
      'Biometrische verificatie is uitgeschakeld. Vergrendel en ontgrendel uw scherm om het in te schakelen.';

  @override
  String get iOSOkButton => 'Oké';

  @override
  String get emailAlreadyRegistered => 'E-mail is al geregistreerd.';

  @override
  String get emailNotRegistered => 'E-mail niet geregistreerd.';

  @override
  String get thisEmailIsAlreadyInUse => 'Dit e-mailadres is al in gebruik';

  @override
  String emailChangedTo(String newEmail) {
    return 'E-mailadres gewijzigd naar $newEmail';
  }

  @override
  String get authenticationFailedPleaseTryAgain =>
      'Verificatie mislukt, probeer het opnieuw';

  @override
  String get authenticationSuccessful => 'Verificatie geslaagd!';

  @override
  String get sessionExpired => 'Sessie verlopen';

  @override
  String get incorrectRecoveryKey => 'Onjuiste herstelsleutel';

  @override
  String get theRecoveryKeyYouEnteredIsIncorrect =>
      'De ingevoerde herstelsleutel is onjuist';

  @override
  String get twofactorAuthenticationSuccessfullyReset =>
      'Tweestapsverificatie succesvol gereset';

  @override
  String get noRecoveryKey => 'No recovery key';

  @override
  String get yourAccountHasBeenDeleted => 'Your account has been deleted';

  @override
  String get verificationId => 'Verification ID';

  @override
  String get yourVerificationCodeHasExpired => 'Uw verificatiecode is verlopen';

  @override
  String get incorrectCode => 'Onjuiste code';

  @override
  String get sorryTheCodeYouveEnteredIsIncorrect =>
      'Sorry, de ingevoerde code is onjuist';

  @override
  String get developerSettings => 'Ontwikkelaarsinstellingen';

  @override
  String get serverEndpoint => 'Server eindpunt';

  @override
  String get invalidEndpoint => 'Ongeldig eindpunt';

  @override
  String get invalidEndpointMessage =>
      'Sorry, het eindpunt dat u hebt ingevoerd is ongeldig. Voer een geldig eindpunt in en probeer het opnieuw.';

  @override
  String get endpointUpdatedMessage => 'Eindpunt met succes bijgewerkt';
}
