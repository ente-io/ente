// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovenian (`sl`).
class StringsLocalizationsSl extends StringsLocalizations {
  StringsLocalizationsSl([String locale = 'sl']) : super(locale);

  @override
  String get networkHostLookUpErr =>
      'Ne morete se povezati z Ente, preverite omrežne nastavitve in se obrnite na podporo, če se napaka nadaljuje.';

  @override
  String get networkConnectionRefusedErr =>
      'Ne morete se povezati z Ente, poskusite znova čez nekaj časa. Če se napaka nadaljuje, se obrnite na podporo.';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      'Zdi se, da je šlo nekaj narobe. Po določenem času poskusite znova. Če se napaka nadaljuje, se obrnite na našo ekipo za podporo.';

  @override
  String get error => 'Napaka';

  @override
  String get ok => 'V redu';

  @override
  String get faq => 'Pogosta vprašanja';

  @override
  String get contactSupport => 'Stik s podporo';

  @override
  String get emailYourLogs => 'Pošlji loge po e-pošti';

  @override
  String pleaseSendTheLogsTo(String toEmail) {
    return 'Loge pošljite na naslov \n$toEmail';
  }

  @override
  String get copyEmailAddress => 'Kopiraj e-poštni naslov';

  @override
  String get exportLogs => 'Izvozi loge';

  @override
  String get cancel => 'Prekliči';

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
  String get reportABug => 'Prijavite napako';

  @override
  String get logsDialogBody =>
      'This will send across logs to help us debug your issue. Please note that file names will be included to help track issues with specific files.';

  @override
  String get viewLogs => 'View logs';

  @override
  String customEndpoint(String endpoint) {
    return 'Povezano na $endpoint';
  }

  @override
  String get save => 'Shrani';

  @override
  String get send => 'Pošlji';

  @override
  String get saveOrSendDescription =>
      'Želite to shraniti v shrambo (privzeto: mapa Prenosi) ali poslati drugim aplikacijam?';

  @override
  String get saveOnlyDescription =>
      'Želite to shraniti v shrambo (privzeto: mapa Prenosi)?';

  @override
  String get enterNewEmailHint => 'Enter your new email address';

  @override
  String get email => 'E-pošta';

  @override
  String get verify => 'Preveri';

  @override
  String get invalidEmailTitle => 'Neveljaven e-poštni naslov';

  @override
  String get invalidEmailMessage => 'Prosimo vnesite veljaven e-poštni naslov.';

  @override
  String get pleaseWait => 'Prosim počakajte...';

  @override
  String get verifyPassword => 'Potrdite geslo';

  @override
  String get incorrectPasswordTitle => 'Nepravilno geslo';

  @override
  String get pleaseTryAgain => 'Prosimo, poskusite ponovno';

  @override
  String get enterPassword => 'Vnesite geslo';

  @override
  String get enterYourPasswordHint => 'Vnesite svoje geslo';

  @override
  String get activeSessions => 'Aktivne seje';

  @override
  String get oops => 'Ups';

  @override
  String get somethingWentWrongPleaseTryAgain =>
      'Nekaj je šlo narobe, prosimo poizkusite znova.';

  @override
  String get thisWillLogYouOutOfThisDevice =>
      'To vas bo odjavilo iz te naprave!';

  @override
  String get thisWillLogYouOutOfTheFollowingDevice =>
      'To vas bo odjavilo iz naslednje naprave:';

  @override
  String get terminateSession => 'Končaj sejo';

  @override
  String get terminate => 'Končaj';

  @override
  String get thisDevice => 'Ta naprava';

  @override
  String get createAccount => 'Ustvari račun';

  @override
  String get weakStrength => 'Šibko';

  @override
  String get moderateStrength => 'Zmerno';

  @override
  String get strongStrength => 'Močno';

  @override
  String get deleteAccount => 'Izbriši račun';

  @override
  String get deleteAccountQuery =>
      'Žal nam je, da odhajate. Imate kakšne težave?';

  @override
  String get yesSendFeedbackAction => 'Ja, pošlji povratne informacije';

  @override
  String get noDeleteAccountAction => 'Ne, izbriši račun';

  @override
  String get initiateAccountDeleteTitle => 'Za izbris računa, se overite';

  @override
  String get confirmAccountDeleteTitle => 'Potrdi brisanje računa';

  @override
  String get confirmAccountDeleteMessage =>
      'Ta račun je povezan z drugimi aplikacijami Ente, če jih uporabljate.\n\nVaši naloženi podatki v vseh aplikacijah Ente bodo načrtovane za izbris, vaš račun pa bo trajno izbrisan.';

  @override
  String get delete => '';

  @override
  String get createNewAccount => 'Ustvari nov račun';

  @override
  String get password => 'Geslo';

  @override
  String get confirmPassword => 'Potrdi geslo';

  @override
  String passwordStrength(String passwordStrengthValue) {
    return 'Moč gesla: $passwordStrengthValue';
  }

  @override
  String get hearUsWhereTitle => 'Kako ste slišali o Ente? (izbirno)';

  @override
  String get hearUsExplanation =>
      'Namestitvam aplikacij ne sledimo. Pomagalo bi, če bi nam povedali, kje ste nas našli!';

  @override
  String get signUpTerms =>
      'Strinjam se s <u-terms>pogoji uporabe</u-terms> in <u-policy>politiko zasebnosti</u-policy>';

  @override
  String get termsOfServicesTitle => 'Pogoji uporabe';

  @override
  String get privacyPolicyTitle => 'Politika zasebnosti';

  @override
  String get ackPasswordLostWarning =>
      'Razumem, da lahko z izgubo gesla, izgubim svoje podatke, saj so <underline>end-to-end šifrirani</underline>';

  @override
  String get encryption => 'Šifriranje';

  @override
  String get logInLabel => 'Prijava';

  @override
  String get welcomeBack => 'Dobrodošli nazaj!';

  @override
  String get loginTerms =>
      'S klikom na prijava, se strinjam s <u-terms>pogoji uporabe</u-terms> in <u-policy>politiko zasebnosti</u-policy>';

  @override
  String get noInternetConnection => 'Ni internetne povezave';

  @override
  String get pleaseCheckYourInternetConnectionAndTryAgain =>
      'Preverite internetno povezavo in poskusite znova.';

  @override
  String get verificationFailedPleaseTryAgain =>
      'Potrjevanje ni bilo uspešno, prosimo poskusite znova.';

  @override
  String get recreatePasswordTitle => 'Ponovno ustvarite geslo';

  @override
  String get recreatePasswordBody =>
      'Trenutna naprava, ni dovolj zmogljiva za preverjanje vašega gesla, a ga lahko generiramo na način, ki deluje z vsemi napravami.\n\nProsimo, prijavite se z vašim ključem za obnovo in ponovno ustvarite geslo (če želite lahko uporabite enako kot prej).';

  @override
  String get useRecoveryKey => 'Uporabi ključ za obnovo';

  @override
  String get forgotPassword => 'Pozabljeno geslo';

  @override
  String get changeEmail => 'Sprememba e-poštnega naslova';

  @override
  String get verifyEmail => 'Potrdite e-pošto';

  @override
  String weHaveSendEmailTo(String email) {
    return 'Poslali smo e-pošto na <green>$email</green>';
  }

  @override
  String get toResetVerifyEmail =>
      'Če želite ponastaviti geslo, najprej potrdite svoj e-poštni naslov.';

  @override
  String get checkInboxAndSpamFolder =>
      'Prosimo, preverite svoj e-poštni predal (in nezaželeno pošto), da končate verifikacijo';

  @override
  String get tapToEnterCode => 'Pritisni za vnos kode';

  @override
  String get sendEmail => 'Pošlji e-pošto';

  @override
  String get resendEmail => 'Ponovno pošlji e-pošto';

  @override
  String get passKeyPendingVerification => 'Preverjanje še ni zaključeno';

  @override
  String get loginSessionExpired => 'Seja je potekla';

  @override
  String get loginSessionExpiredDetails =>
      'Vaša seja je potekla. Prosimo ponovno se prijavite.';

  @override
  String get passkeyAuthTitle => 'Potrditev ključa za dostop (passkey)';

  @override
  String get waitingForVerification => 'Čakanje na potrditev...';

  @override
  String get tryAgain => 'Poskusite ponovno';

  @override
  String get checkStatus => 'Preveri status';

  @override
  String get loginWithTOTP => 'Prijava z TOTP';

  @override
  String get recoverAccount => 'Obnovi račun';

  @override
  String get setPasswordTitle => 'Nastavite geslo';

  @override
  String get changePasswordTitle => 'Sprememba gesla';

  @override
  String get resetPasswordTitle => 'Ponastavitev gesla';

  @override
  String get encryptionKeys => 'Šifrirni ključi';

  @override
  String get enterPasswordToEncrypt =>
      'Vnesite geslo, ki ga lahko uporabimo za šifriranje vaših podatkov';

  @override
  String get enterNewPasswordToEncrypt =>
      'Vnesite novo geslo, ki ga lahko uporabimo za šifriranje vaših podatkov';

  @override
  String get passwordWarning =>
      'Tega gesla ne shranjujemo, zato v primeru, da ga pozabite, <underline>ne moremo dešifrirati vaših podatkov</underline>.';

  @override
  String get howItWorks => 'Kako deluje? ';

  @override
  String get generatingEncryptionKeys => 'Ustvarjanje ključe za šifriranje';

  @override
  String get passwordChangedSuccessfully => 'Geslo je bilo uspešno spremenjeno';

  @override
  String get signOutFromOtherDevices => 'Odjavi se iz ostalih naprav';

  @override
  String get signOutOtherBody =>
      'Če menite, da bi lahko kdo poznal vaše geslo, lahko vse druge naprave, ki uporabljajo vaš račun, prisilite, da se odjavijo.';

  @override
  String get signOutOtherDevices => 'Odjavi ostale naprave';

  @override
  String get doNotSignOut => 'Ne odjavi se';

  @override
  String get generatingEncryptionKeysTitle => 'Generiramo ključe za šifriranje';

  @override
  String get continueLabel => 'Nadaljuj';

  @override
  String get insecureDevice => 'Nezanesljiva naprava';

  @override
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease =>
      'Žal v tej napravi nismo mogli ustvariti varnih ključev.\n\nProsimo, prijavite se iz druge naprave.';

  @override
  String get recoveryKeyCopiedToClipboard =>
      'Ključ za obnovo kopiran v odložišče';

  @override
  String get recoveryKey => 'Ključ za obnovitev';

  @override
  String get recoveryKeyOnForgotPassword =>
      'Če pozabite svoje geslo, je edini način da obnovite svoje podatke s tem ključem';

  @override
  String get recoveryKeySaveDescription =>
      'Tega ključa ne hranimo, prosimo shranite teh 24 besed na varnem';

  @override
  String get doThisLater => 'Stori to kasneje';

  @override
  String get saveKey => 'Shrani ključ';

  @override
  String get recoveryKeySaved =>
      'Ključ za obnovitev je shranjen v mapi Prenosi!';

  @override
  String get noRecoveryKeyTitle => 'Nimate ključa za obnovo?';

  @override
  String get twoFactorAuthTitle => 'Dvojno preverjanja pristnosti';

  @override
  String get enterCodeHint =>
      'Vnesite 6 mestno kodo iz vaše aplikacije za preverjanje pristnosti';

  @override
  String get lostDeviceTitle => 'Izgubljena naprava?';

  @override
  String get enterRecoveryKeyHint => 'Vnesite vaš ključ za obnovitev';

  @override
  String get recover => 'Obnovi';

  @override
  String get loggingOut => 'Odjavljanje...';

  @override
  String get immediately => 'Takoj';

  @override
  String get appLock => 'Zaklep aplikacije';

  @override
  String get autoLock => 'Samodejno zaklepanje';

  @override
  String get noSystemLockFound => 'Nobeno zaklepanje sistema ni bilo najdeno';

  @override
  String get deviceLockEnablePreSteps =>
      'Da omogočite zaklepanje naprave, prosimo nastavite kodo ali zaklepanje zaslona v sistemskih nastavitvah.';

  @override
  String get appLockDescription =>
      'Izbirate lahko med privzetim zaklenjenim zaslonom naprave in zaklenjenim zaslonom po meri s kodo PIN ali geslom.';

  @override
  String get deviceLock => 'Zaklepanje naprave';

  @override
  String get pinLock => 'Zaklepanje s PIN';

  @override
  String get autoLockFeatureDescription =>
      'Čas po katerem se aplikacije zaklene, ko jo enkrat zapustite.';

  @override
  String get hideContent => 'Skrij vsebino';

  @override
  String get hideContentDescriptionAndroid =>
      'Skrije vsebino aplikacije v menjalniku opravil in onemogoči posnetke zaslona';

  @override
  String get hideContentDescriptioniOS =>
      'Skrije vsebino aplikacije v menjalniku opravil';

  @override
  String get tooManyIncorrectAttempts => 'Preveč nepravilnih poskusov';

  @override
  String get tapToUnlock => 'Kliknite za odklepanje';

  @override
  String get areYouSureYouWantToLogout =>
      'Ali ste prepričani, da se želite odjaviti?';

  @override
  String get yesLogout => 'Ja, odjavi se';

  @override
  String get authToViewSecrets =>
      'Če si želite ogledati svoje skrivne ključe, se overite';

  @override
  String get next => 'Naprej';

  @override
  String get setNewPassword => 'Nastavi novo geslo';

  @override
  String get enterPin => 'Vnesi PIN';

  @override
  String get setNewPin => 'Nastavi nov PIN';

  @override
  String get confirm => 'Potrdi';

  @override
  String get reEnterPassword => 'Ponovno vnesite geslo';

  @override
  String get reEnterPin => 'Ponovno vnesite PIN';

  @override
  String get androidBiometricHint => 'Potrdite identiteto';

  @override
  String get androidBiometricNotRecognized => 'Ni prepoznano. Poskusite znova.';

  @override
  String get androidBiometricSuccess => 'Uspešno';

  @override
  String get androidCancelButton => 'Prekliči';

  @override
  String get androidSignInTitle => 'Potrebna je overitev';

  @override
  String get androidBiometricRequiredTitle => 'Zahtevani biometrični podatki';

  @override
  String get androidDeviceCredentialsRequiredTitle =>
      'Zahtevani podatki za vpis v napravo';

  @override
  String get androidDeviceCredentialsSetupDescription =>
      'Zahtevani podatki za vpis v napravo';

  @override
  String get goToSettings => 'Pojdi v nastavitve';

  @override
  String get androidGoToSettingsDescription =>
      'Biometrično overjanje v vaši napravi ni nastavljeno. Pojdite v \"Nastavitve > Varnost\" in dodajte biometrično overjanje.';

  @override
  String get iOSLockOut =>
      'Biometrično overjanje je onemogočeno. Če ga želite omogočiti, zaklenite in odklenite zaslon.';

  @override
  String get iOSOkButton => 'V redu';

  @override
  String get emailAlreadyRegistered => 'E-poštni naslov je že registriran.';

  @override
  String get emailNotRegistered => 'E-poštni naslov ni registriran.';

  @override
  String get thisEmailIsAlreadyInUse => 'Ta e-poštni naslove je že v uporabi.';

  @override
  String emailChangedTo(String newEmail) {
    return 'E-poštni naslove je bil spremenjen na $newEmail';
  }

  @override
  String get authenticationFailedPleaseTryAgain =>
      'Overitev ni uspela, prosimo poskusite znova';

  @override
  String get authenticationSuccessful => 'Overitev uspešna!';

  @override
  String get sessionExpired => 'Seja je potekla';

  @override
  String get incorrectRecoveryKey => 'Nepravilen ključ za obnovitev';

  @override
  String get theRecoveryKeyYouEnteredIsIncorrect =>
      'Ključ za obnovitev, ki ste ga vnesli ni pravilen';

  @override
  String get twofactorAuthenticationSuccessfullyReset =>
      'Uspešna ponastavitev dvostopenjske avtentikacije';

  @override
  String get noRecoveryKey => 'No recovery key';

  @override
  String get yourAccountHasBeenDeleted => 'Your account has been deleted';

  @override
  String get verificationId => 'Verification ID';

  @override
  String get yourVerificationCodeHasExpired =>
      'Vaša koda za potrditev je potekla.';

  @override
  String get incorrectCode => 'Nepravilna koda';

  @override
  String get sorryTheCodeYouveEnteredIsIncorrect =>
      'Oprostite, koda ki ste jo vnesli ni pravilna';

  @override
  String get developerSettings => 'Nastavitve za razvijalce';

  @override
  String get serverEndpoint => 'Endpoint strežnika';

  @override
  String get invalidEndpoint => 'Nepravilen endpoint';

  @override
  String get invalidEndpointMessage =>
      'Oprostite endpoint, ki ste ga vnesli ni bil pravilen. Prosimo, vnesite pravilen endpoint in poskusite znova.';

  @override
  String get endpointUpdatedMessage => 'Endpoint posodobljen uspešno';
}
