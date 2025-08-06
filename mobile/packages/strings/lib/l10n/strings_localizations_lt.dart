// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Lithuanian (`lt`).
class StringsLocalizationsLt extends StringsLocalizations {
  StringsLocalizationsLt([String locale = 'lt']) : super(locale);

  @override
  String get networkHostLookUpErr =>
      'Nepavyksta prisijungti prie „Ente“. Patikrinkite tinklo nustatymus ir susisiekite su palaikymo komanda, jei klaida tęsiasi.';

  @override
  String get networkConnectionRefusedErr =>
      'Nepavyksta prisijungti prie „Ente“. Bandykite dar kartą po kurio laiko. Jei klaida tęsiasi, susisiekite su palaikymo komanda.';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      'Atrodo, kad kažkas nutiko ne taip. Bandykite dar kartą po kurio laiko. Jei klaida tęsiasi, susisiekite su mūsų palaikymo komanda.';

  @override
  String get error => 'Klaida';

  @override
  String get ok => 'Gerai';

  @override
  String get faq => 'DUK';

  @override
  String get contactSupport => 'Susisiekti su palaikymo komanda';

  @override
  String get emailYourLogs => 'Atsiųskite žurnalus el. laišku';

  @override
  String pleaseSendTheLogsTo(String toEmail) {
    return 'Siųskite žurnalus adresu\n$toEmail';
  }

  @override
  String get copyEmailAddress => 'Kopijuoti el. pašto adresą';

  @override
  String get exportLogs => 'Eksportuoti žurnalus';

  @override
  String get cancel => 'Atšaukti';

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
  String get reportABug => 'Pranešti apie riktą';

  @override
  String get logsDialogBody =>
      'This will send across logs to help us debug your issue. Please note that file names will be included to help track issues with specific files.';

  @override
  String get viewLogs => 'View logs';

  @override
  String customEndpoint(String endpoint) {
    return 'Prijungta prie $endpoint';
  }

  @override
  String get save => 'Išsaugoti';

  @override
  String get send => 'Siųsti';

  @override
  String get saveOrSendDescription =>
      'Ar norite tai išsaugoti saugykloje (pagal numatytuosius nustatymus – atsisiuntimų aplanke), ar siųsti į kitas programas?';

  @override
  String get saveOnlyDescription =>
      'Ar norite tai išsaugoti savo saugykloje (pagal numatytuosius nustatymus – atsisiuntimų aplanke)?';

  @override
  String get enterNewEmailHint => 'Enter your new email address';

  @override
  String get email => 'El. paštas';

  @override
  String get verify => 'Patvirtinti';

  @override
  String get invalidEmailTitle => 'Netinkamas el. pašto adresas';

  @override
  String get invalidEmailMessage => 'Įveskite tinkamą el. pašto adresą.';

  @override
  String get pleaseWait => 'Palaukite...';

  @override
  String get verifyPassword => 'Patvirtinkite slaptažodį';

  @override
  String get incorrectPasswordTitle => 'Neteisingas slaptažodis.';

  @override
  String get pleaseTryAgain => 'Bandykite dar kartą.';

  @override
  String get enterPassword => 'Įveskite slaptažodį';

  @override
  String get enterYourPasswordHint => 'Įveskite savo slaptažodį';

  @override
  String get activeSessions => 'Aktyvūs seansai';

  @override
  String get oops => 'Ups';

  @override
  String get somethingWentWrongPleaseTryAgain =>
      'Kažkas nutiko ne taip. Bandykite dar kartą.';

  @override
  String get thisWillLogYouOutOfThisDevice =>
      'Tai jus atjungs nuo šio įrenginio.';

  @override
  String get thisWillLogYouOutOfTheFollowingDevice =>
      'Tai jus atjungs nuo toliau nurodyto įrenginio:';

  @override
  String get terminateSession => 'Baigti seansą?';

  @override
  String get terminate => 'Baigti';

  @override
  String get thisDevice => 'Šis įrenginys';

  @override
  String get createAccount => 'Kurti paskyrą';

  @override
  String get weakStrength => 'Silpna';

  @override
  String get moderateStrength => 'Vidutinė';

  @override
  String get strongStrength => 'Stipri';

  @override
  String get deleteAccount => 'Ištrinti paskyrą';

  @override
  String get deleteAccountQuery =>
      'Apgailestausime, kad išeinate. Ar susiduriate su kažkokiomis problemomis?';

  @override
  String get yesSendFeedbackAction => 'Taip, siųsti atsiliepimą';

  @override
  String get noDeleteAccountAction => 'Ne, ištrinti paskyrą';

  @override
  String get initiateAccountDeleteTitle =>
      'Nustatykite tapatybę, kad pradėtumėte paskyros ištrynimą';

  @override
  String get confirmAccountDeleteTitle => 'Patvirtinkite paskyros ištrynimą';

  @override
  String get confirmAccountDeleteMessage =>
      'Ši paskyra susieta su kitomis „Ente“ programomis, jei jas naudojate.\n\nJūsų įkelti duomenys per visas „Ente“ programas bus planuojama ištrinti, o jūsų paskyra bus ištrinta negrįžtamai.';

  @override
  String get delete => 'Ištrinti';

  @override
  String get createNewAccount => 'Kurti naują paskyrą';

  @override
  String get password => 'Slaptažodis';

  @override
  String get confirmPassword => 'Patvirtinkite slaptažodį';

  @override
  String passwordStrength(String passwordStrengthValue) {
    return 'Slaptažodžio stiprumas: $passwordStrengthValue';
  }

  @override
  String get hearUsWhereTitle => 'Kaip išgirdote apie „Ente“? (nebūtina)';

  @override
  String get hearUsExplanation =>
      'Mes nesekame programų diegimų. Mums padėtų, jei pasakytumėte, kur mus radote.';

  @override
  String get signUpTerms =>
      'Sutinku su <u-terms>paslaugų sąlygomis</u-terms> ir <u-policy> privatumo politika</u-policy>';

  @override
  String get termsOfServicesTitle => 'Sąlygos';

  @override
  String get privacyPolicyTitle => 'Privatumo politika';

  @override
  String get ackPasswordLostWarning =>
      'Suprantu, kad jei prarasiu slaptažodį, galiu prarasti savo duomenis, kadangi duomenys yra <underline>visapusiškai užšifruota</underline>.';

  @override
  String get encryption => 'Šifravimas';

  @override
  String get logInLabel => 'Prisijungti';

  @override
  String get welcomeBack => 'Sveiki sugrįžę!';

  @override
  String get loginTerms =>
      'Spustelėjus Prisijungti sutinku su <u-terms>paslaugų sąlygomis</u-terms> ir <u-policy> privatumo politika</u-policy>';

  @override
  String get noInternetConnection => 'Nėra interneto ryšio';

  @override
  String get pleaseCheckYourInternetConnectionAndTryAgain =>
      'Patikrinkite savo interneto ryšį ir bandykite dar kartą.';

  @override
  String get verificationFailedPleaseTryAgain =>
      'Patvirtinimas nepavyko. Bandykite dar kartą.';

  @override
  String get recreatePasswordTitle => 'Iš naujo sukurti slaptažodį';

  @override
  String get recreatePasswordBody =>
      'Dabartinis įrenginys nėra pakankamai galingas, kad patvirtintų jūsų slaptažodį, bet mes galime iš naujo sugeneruoti taip, kad jis veiktų su visais įrenginiais.\n\nPrisijunkite naudodami atkūrimo raktą ir sugeneruokite iš naujo slaptažodį (jei norite, galite vėl naudoti tą patį).';

  @override
  String get useRecoveryKey => 'Naudoti atkūrimo raktą';

  @override
  String get forgotPassword => 'Pamiršau slaptažodį';

  @override
  String get changeEmail => 'Keisti el. paštą';

  @override
  String get verifyEmail => 'Patvirtinti el. paštą';

  @override
  String weHaveSendEmailTo(String email) {
    return 'Išsiuntėme laišką adresu <green>$email</green>.';
  }

  @override
  String get toResetVerifyEmail =>
      'Kad iš naujo nustatytumėte slaptažodį, pirmiausia patvirtinkite savo el. paštą.';

  @override
  String get checkInboxAndSpamFolder =>
      'Patikrinkite savo gautieją (ir šlamštą), kad užbaigtumėte patvirtinimą.';

  @override
  String get tapToEnterCode => 'Palieskite, kad įvestumėte kodą';

  @override
  String get sendEmail => 'Siųsti el. laišką';

  @override
  String get resendEmail => 'Iš naujo siųsti el. laišką';

  @override
  String get passKeyPendingVerification => 'Vis dar laukiama patvirtinimo';

  @override
  String get loginSessionExpired => 'Seansas baigėsi';

  @override
  String get loginSessionExpiredDetails =>
      'Jūsų seansas baigėsi. Prisijunkite iš naujo.';

  @override
  String get passkeyAuthTitle => 'Slaptarakčio patvirtinimas';

  @override
  String get waitingForVerification => 'Laukiama patvirtinimo...';

  @override
  String get tryAgain => 'Bandyti dar kartą';

  @override
  String get checkStatus => 'Tikrinti būseną';

  @override
  String get loginWithTOTP => 'Prisijungti su TOTP';

  @override
  String get recoverAccount => 'Atkurti paskyrą';

  @override
  String get setPasswordTitle => 'Nustatyti slaptažodį';

  @override
  String get changePasswordTitle => 'Keisti slaptažodį';

  @override
  String get resetPasswordTitle => 'Nustatyti slaptažodį iš naujo';

  @override
  String get encryptionKeys => 'Šifravimo raktai';

  @override
  String get enterPasswordToEncrypt =>
      'Įveskite slaptažodį, kurį galime naudoti jūsų duomenims užšifruoti';

  @override
  String get enterNewPasswordToEncrypt =>
      'Įveskite naują slaptažodį, kurį galime naudoti jūsų duomenims užšifruoti';

  @override
  String get passwordWarning =>
      'Šio slaptažodžio nesaugome, todėl jei jį pamiršite, <underline>negalėsime iššifruoti jūsų duomenų</underline>';

  @override
  String get howItWorks => 'Kaip tai veikia';

  @override
  String get generatingEncryptionKeys => 'Generuojami šifravimo raktai...';

  @override
  String get passwordChangedSuccessfully => 'Slaptažodis sėkmingai pakeistas';

  @override
  String get signOutFromOtherDevices => 'Atsijungti iš kitų įrenginių';

  @override
  String get signOutOtherBody =>
      'Jei manote, kad kas nors gali žinoti jūsų slaptažodį, galite priverstinai atsijungti iš visų kitų įrenginių, naudojančių jūsų paskyrą.';

  @override
  String get signOutOtherDevices => 'Atsijungti kitus įrenginius';

  @override
  String get doNotSignOut => 'Neatsijungti';

  @override
  String get generatingEncryptionKeysTitle => 'Generuojami šifravimo raktai...';

  @override
  String get continueLabel => 'Tęsti';

  @override
  String get insecureDevice => 'Nesaugus įrenginys';

  @override
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease =>
      'Atsiprašome, šiame įrenginyje nepavyko sugeneruoti saugių raktų.\n\nRegistruokitės iš kito įrenginio.';

  @override
  String get recoveryKeyCopiedToClipboard =>
      'Nukopijuotas atkūrimo raktas į iškarpinę';

  @override
  String get recoveryKey => 'Atkūrimo raktas';

  @override
  String get recoveryKeyOnForgotPassword =>
      'Jei pamiršote slaptažodį, vienintelis būdas atkurti duomenis – naudoti šį raktą.';

  @override
  String get recoveryKeySaveDescription =>
      'Šio rakto nesaugome, todėl išsaugokite šį 24 žodžių raktą saugioje vietoje.';

  @override
  String get doThisLater => 'Daryti tai vėliau';

  @override
  String get saveKey => 'Išsaugoti raktą';

  @override
  String get recoveryKeySaved =>
      'Atkūrimo raktas išsaugotas atsisiuntimų aplanke.';

  @override
  String get noRecoveryKeyTitle => 'Neturite atkūrimo rakto?';

  @override
  String get twoFactorAuthTitle => 'Dvigubas tapatybės nustatymas';

  @override
  String get enterCodeHint =>
      'Įveskite 6 skaitmenų kodą\niš autentifikatoriaus programos';

  @override
  String get lostDeviceTitle => 'Prarastas įrenginys?';

  @override
  String get enterRecoveryKeyHint => 'Įveskite atkūrimo raktą';

  @override
  String get recover => 'Atkurti';

  @override
  String get loggingOut => 'Atsijungiama...';

  @override
  String get immediately => 'Iš karto';

  @override
  String get appLock => 'Programos užraktas';

  @override
  String get autoLock => 'Automatinis užraktas';

  @override
  String get noSystemLockFound => 'Nerastas sistemos užraktas';

  @override
  String get deviceLockEnablePreSteps =>
      'Kad įjungtumėte įrenginio užraktą, sistemos nustatymuose nustatykite įrenginio prieigos kodą arba ekrano užraktą.';

  @override
  String get appLockDescription =>
      'Pasirinkite tarp numatytojo įrenginio užrakinimo ekrano ir pasirinktinio užrakinimo ekrano su PIN kodu arba slaptažodžiu.';

  @override
  String get deviceLock => 'Įrenginio užraktas';

  @override
  String get pinLock => 'PIN užraktas';

  @override
  String get autoLockFeatureDescription =>
      'Laikas, po kurio programa užrakinama perkėlus ją į foną.';

  @override
  String get hideContent => 'Slėpti turinį';

  @override
  String get hideContentDescriptionAndroid =>
      'Paslepia programų turinį programų perjungiklyje ir išjungia ekrano kopijas.';

  @override
  String get hideContentDescriptioniOS =>
      'Paslepia programos turinį programos perjungiklyje.';

  @override
  String get tooManyIncorrectAttempts => 'Per daug neteisingų bandymų.';

  @override
  String get tapToUnlock => 'Palieskite, kad atrakintumėte';

  @override
  String get areYouSureYouWantToLogout => 'Ar tikrai norite atsijungti?';

  @override
  String get yesLogout => 'Taip, atsijungti';

  @override
  String get authToViewSecrets =>
      'Nustatykite tapatybę, kad peržiūrėtumėte savo paslaptis';

  @override
  String get next => 'Toliau';

  @override
  String get setNewPassword => 'Nustatykite naują slaptažodį';

  @override
  String get enterPin => 'Įveskite PIN';

  @override
  String get setNewPin => 'Nustatykite naują PIN';

  @override
  String get confirm => 'Patvirtinti';

  @override
  String get reEnterPassword => 'Įveskite slaptažodį iš naujo';

  @override
  String get reEnterPin => 'Įveskite PIN iš naujo';

  @override
  String get androidBiometricHint => 'Patvirtinkite tapatybę';

  @override
  String get androidBiometricNotRecognized =>
      'Neatpažinta. Bandykite dar kartą.';

  @override
  String get androidBiometricSuccess => 'Sėkmė';

  @override
  String get androidCancelButton => 'Atšaukti';

  @override
  String get androidSignInTitle => 'Privalomas tapatybės nustatymas';

  @override
  String get androidBiometricRequiredTitle => 'Privaloma biometrija';

  @override
  String get androidDeviceCredentialsRequiredTitle =>
      'Privalomi įrenginio kredencialai';

  @override
  String get androidDeviceCredentialsSetupDescription =>
      'Privalomi įrenginio kredencialai';

  @override
  String get goToSettings => 'Eiti į nustatymus';

  @override
  String get androidGoToSettingsDescription =>
      'Biometrinis tapatybės nustatymas jūsų įrenginyje nenustatytas. Eikite į Nustatymai > Saugumas ir pridėkite biometrinį tapatybės nustatymą.';

  @override
  String get iOSLockOut =>
      'Biometrinis tapatybės nustatymas išjungtas. Kad jį įjungtumėte, užrakinkite ir atrakinkite ekraną.';

  @override
  String get iOSOkButton => 'Gerai';

  @override
  String get emailAlreadyRegistered => 'El. paštas jau užregistruotas.';

  @override
  String get emailNotRegistered => 'El. paštas neregistruotas.';

  @override
  String get thisEmailIsAlreadyInUse => 'Šis el. paštas jau naudojamas.';

  @override
  String emailChangedTo(String newEmail) {
    return 'El. paštas pakeistas į $newEmail';
  }

  @override
  String get authenticationFailedPleaseTryAgain =>
      'Tapatybės nustatymas nepavyko. Bandykite dar kartą.';

  @override
  String get authenticationSuccessful => 'Tapatybės nustatymas sėkmingas.';

  @override
  String get sessionExpired => 'Seansas baigėsi';

  @override
  String get incorrectRecoveryKey => 'Neteisingas atkūrimo raktas';

  @override
  String get theRecoveryKeyYouEnteredIsIncorrect =>
      'Įvestas atkūrimo raktas yra neteisingas.';

  @override
  String get twofactorAuthenticationSuccessfullyReset =>
      'Dvigubas tapatybės nustatymas sėkmingai iš naujo nustatytas.';

  @override
  String get noRecoveryKey => 'No recovery key';

  @override
  String get yourAccountHasBeenDeleted => 'Your account has been deleted';

  @override
  String get verificationId => 'Verification ID';

  @override
  String get yourVerificationCodeHasExpired =>
      'Jūsų patvirtinimo kodas nebegaliojantis.';

  @override
  String get incorrectCode => 'Neteisingas kodas';

  @override
  String get sorryTheCodeYouveEnteredIsIncorrect =>
      'Atsiprašome, įvestas kodas yra neteisingas.';

  @override
  String get developerSettings => 'Kūrėjo nustatymai';

  @override
  String get serverEndpoint => 'Serverio galutinis taškas';

  @override
  String get invalidEndpoint => 'Netinkamas galutinis taškas';

  @override
  String get invalidEndpointMessage =>
      'Atsiprašome, įvestas galutinis taškas netinkamas. Įveskite tinkamą galutinį tašką ir bandykite dar kartą.';

  @override
  String get endpointUpdatedMessage => 'Galutinis taškas sėkmingai atnaujintas';
}
