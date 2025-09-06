// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class StringsLocalizationsHu extends StringsLocalizations {
  StringsLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get networkHostLookUpErr =>
      'Nem lehet csatlakozni az Ente-hez. Kérjük, ellenőrizze a hálózati beállításokat, és ha a hiba továbbra is fennáll, forduljon az ügyfélszolgálathoz.';

  @override
  String get networkConnectionRefusedErr =>
      'Nem lehet csatlakozni az Ente-hez, próbálja újra egy idő után. Ha a hiba továbbra is fennáll, forduljon az ügyfélszolgálathoz.';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      'Úgy tűnik, valami hiba történt. Kérjük, próbálja újra egy idő után. Ha a hiba továbbra is fennáll, forduljon ügyfélszolgálatunkhoz.';

  @override
  String get error => 'Hiba';

  @override
  String get ok => 'OK';

  @override
  String get faq => 'GY. I. K.';

  @override
  String get contactSupport => 'Lépj kapcsolatba az Ügyfélszolgálattal';

  @override
  String get emailYourLogs => 'E-mailben küldje el naplóit';

  @override
  String pleaseSendTheLogsTo(String toEmail) {
    return 'Kérjük, küldje el a naplókat erre az e-mail címre\n$toEmail';
  }

  @override
  String get copyEmailAddress => 'E-mail cím másolása';

  @override
  String get exportLogs => 'Naplófájlok exportálása';

  @override
  String get cancel => 'Mégse';

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
  String get reportABug => 'Hiba bejelentése';

  @override
  String get logsDialogBody =>
      'This will send across logs to help us debug your issue. Please note that file names will be included to help track issues with specific files.';

  @override
  String get viewLogs => 'View logs';

  @override
  String customEndpoint(String endpoint) {
    return 'Csatlakozva a következőhöz: $endpoint';
  }

  @override
  String get save => 'Mentés';

  @override
  String get send => 'Küldés';

  @override
  String get saveOrSendDescription =>
      'El szeretné menteni ezt a tárhelyére (alapértelmezés szerint a Letöltések mappába), vagy elküldi más alkalmazásoknak?';

  @override
  String get saveOnlyDescription =>
      'El szeretné menteni ezt a tárhelyére (alapértelmezés szerint a Letöltések mappába)?';

  @override
  String get enterNewEmailHint => 'Add meg az új e-mail címed';

  @override
  String get email => 'E-mail';

  @override
  String get verify => 'Hitelesítés';

  @override
  String get invalidEmailTitle => 'Érvénytelen e-mail cím';

  @override
  String get invalidEmailMessage =>
      'Kérjük, adjon meg egy érvényes e-mail címet.';

  @override
  String get pleaseWait => 'Kérem várjon...';

  @override
  String get verifyPassword => 'Jelszó megerősítése';

  @override
  String get incorrectPasswordTitle => 'Érvénytelen jelszó';

  @override
  String get pleaseTryAgain => 'Kérjük, próbálja meg újra';

  @override
  String get enterPassword => 'Adja meg a jelszót';

  @override
  String get enterYourPasswordHint => 'Adja meg a jelszavát';

  @override
  String get activeSessions => 'Aktív munkamenetek';

  @override
  String get oops => 'Hoppá';

  @override
  String get somethingWentWrongPleaseTryAgain =>
      'Hiba történt. Kérjük, próbálkozz újra';

  @override
  String get thisWillLogYouOutOfThisDevice =>
      'Ezzel kijelentkezik erről az eszközről!';

  @override
  String get thisWillLogYouOutOfTheFollowingDevice =>
      'Ezzel kijelentkezik a következő eszközről:';

  @override
  String get terminateSession => 'Megszakítja a munkamenetet?';

  @override
  String get terminate => 'Befejezés';

  @override
  String get thisDevice => 'Ez az eszköz';

  @override
  String get createAccount => 'Felhasználó létrehozás';

  @override
  String get weakStrength => 'Gyenge';

  @override
  String get moderateStrength => 'Mérsékelt';

  @override
  String get strongStrength => 'Erős';

  @override
  String get deleteAccount => 'Fiók törlése';

  @override
  String get deleteAccountQuery =>
      'Szomorúan tapasztaljuk. Problémába ütköztél?';

  @override
  String get yesSendFeedbackAction => 'Igen, visszajelzés küldése';

  @override
  String get noDeleteAccountAction => 'Fiók végleges törlése';

  @override
  String get initiateAccountDeleteTitle =>
      'Kérjük, hitelesítse magát a fiók törlésének kezdeményezéséhez';

  @override
  String get confirmAccountDeleteTitle => 'Fiók törlésének megerősítése';

  @override
  String get confirmAccountDeleteMessage =>
      'Ez a fiók össze van kapcsolva más Ente-alkalmazásokkal, ha használ ilyet.\n\nA feltöltött adataid törlését ütemezzük az összes Ente alkalmazásban, és a fiókod véglegesen törlésre kerül.';

  @override
  String get delete => 'Törlés';

  @override
  String get createNewAccount => 'Új fiók létrehozása';

  @override
  String get password => 'Jelszó';

  @override
  String get confirmPassword => 'Jelszó megerősítése';

  @override
  String passwordStrength(String passwordStrengthValue) {
    return 'Jelszó erőssége: $passwordStrengthValue';
  }

  @override
  String get hearUsWhereTitle => 'Honnan hallottál Ente-ről? (opcionális)';

  @override
  String get hearUsExplanation =>
      'Nem követjük nyomon az alkalmazástelepítéseket. Segítene, ha elmondaná, hol talált ránk!';

  @override
  String get signUpTerms =>
      'Elfogadom az <u-terms>szolgáltatási feltételeket</u-terms> és az <u-policy>adatvédelmi irányelveket</u-policy>';

  @override
  String get termsOfServicesTitle => 'Használati feltételek';

  @override
  String get privacyPolicyTitle => 'Adatvédelmi irányelvek';

  @override
  String get ackPasswordLostWarning =>
      'Tudomásul veszem, hogy ha elveszítem a jelszavamat, elveszíthetem az adataimat, mivel adataim <underline>végponttól végpontig titkosítva vannak</underline>.';

  @override
  String get encryption => 'Titkosítás';

  @override
  String get logInLabel => 'Bejelentkezés';

  @override
  String get welcomeBack => 'Köszöntjük ismét!';

  @override
  String get loginTerms =>
      'A bejelentkezés gombra kattintva elfogadom az <u-terms>szolgáltatási feltételeket</u-terms> és az <u-policy>adatvédelmi irányelveket</u-policy>';

  @override
  String get noInternetConnection => 'Nincs internet kapcsolat';

  @override
  String get pleaseCheckYourInternetConnectionAndTryAgain =>
      'Kérjük, ellenőrizze az internetkapcsolatát, és próbálja meg újra.';

  @override
  String get verificationFailedPleaseTryAgain =>
      'Az ellenőrzés sikertelen, próbálja újra';

  @override
  String get recreatePasswordTitle => 'Új jelszó létrehozása';

  @override
  String get recreatePasswordBody =>
      'A jelenlegi eszköz nem elég erős a jelszavának ellenőrzéséhez, de újra tudjuk úgy generálni, hogy az minden eszközzel működjön.\n\nKérjük, jelentkezzen be helyreállítási kulcsával, és állítsa be újra jelszavát (ha szeretné, újra használhatja ugyanazt).';

  @override
  String get useRecoveryKey => 'Helyreállítási kulcs használata';

  @override
  String get forgotPassword => 'Elfelejtett jelszó';

  @override
  String get changeEmail => 'E-mail cím módosítása';

  @override
  String get verifyEmail => 'E-mail cím megerősítése';

  @override
  String weHaveSendEmailTo(String email) {
    return 'E-mailt küldtünk a következő címre: <green>$email</green>';
  }

  @override
  String get toResetVerifyEmail =>
      'Jelszava visszaállításához először igazolja e-mail-címét.';

  @override
  String get checkInboxAndSpamFolder =>
      'Kérjük, ellenőrizze beérkező leveleit (és spam mappát) az ellenőrzés befejezéséhez';

  @override
  String get tapToEnterCode => 'Koppintson a kód beírásához';

  @override
  String get sendEmail => 'E-mail küldése';

  @override
  String get resendEmail => 'E-mail újraküldése';

  @override
  String get passKeyPendingVerification => 'Az ellenőrzés még függőben van';

  @override
  String get loginSessionExpired => 'Lejárt a munkamenet';

  @override
  String get loginSessionExpiredDetails =>
      'A munkameneted lejárt. Kérem lépjen be újra.';

  @override
  String get passkeyAuthTitle => 'Álkulcs megerősítése';

  @override
  String get waitingForVerification => 'Várakozás az ellenőrzésre...';

  @override
  String get tryAgain => 'Próbáld újra';

  @override
  String get checkStatus => 'Állapot ellenőrzése';

  @override
  String get loginWithTOTP => 'Bejelentkezés TOTP-vel';

  @override
  String get recoverAccount => 'Fiók visszaállítása';

  @override
  String get setPasswordTitle => 'Jelszó beállítás';

  @override
  String get changePasswordTitle => 'Jelszó módosítás';

  @override
  String get resetPasswordTitle => 'Jelszó visszaállítás';

  @override
  String get encryptionKeys => 'Titkosító kulcsok';

  @override
  String get enterPasswordToEncrypt =>
      'Adjon meg egy jelszót, amellyel titkosíthatjuk adatait';

  @override
  String get enterNewPasswordToEncrypt =>
      'Adjon meg egy új jelszót, amellyel titkosíthatjuk adatait';

  @override
  String get passwordWarning =>
      'Ezt a jelszót nem tároljuk, így ha elfelejti, <underline>nem tudjuk visszafejteni adatait</underline>';

  @override
  String get howItWorks => 'Hogyan működik';

  @override
  String get generatingEncryptionKeys => 'Titkosító kulcsok generálása...';

  @override
  String get passwordChangedSuccessfully =>
      'A jelszó sikeresen meg lett változtatva';

  @override
  String get signOutFromOtherDevices => 'Jelentkezzen ki más eszközökről';

  @override
  String get signOutOtherBody =>
      'Ha úgy gondolja, hogy valaki ismeri jelszavát, kényszerítheti a fiókját használó összes többi eszközt a kijelentkezésre.';

  @override
  String get signOutOtherDevices => 'Jelentkezzen ki a többi eszközről';

  @override
  String get doNotSignOut => 'Ne jelentkezzen ki';

  @override
  String get generatingEncryptionKeysTitle => 'Titkosítási kulcs generálása...';

  @override
  String get continueLabel => 'Folytatás';

  @override
  String get insecureDevice => 'Nem biztonságos eszköz';

  @override
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease =>
      'Sajnáljuk, nem tudtunk biztonságos kulcsokat generálni ezen az eszközön.\n\nkérjük, regisztráljon egy másik eszközről.';

  @override
  String get recoveryKeyCopiedToClipboard =>
      'A helyreállítási kulcs a vágólapra másolva';

  @override
  String get recoveryKey => 'Visszaállítási kulcs';

  @override
  String get recoveryKeyOnForgotPassword =>
      'Ha elfelejti jelszavát, csak ezzel a kulccsal tudja visszaállítani adatait.';

  @override
  String get recoveryKeySaveDescription =>
      'Ezt a kulcsot nem tároljuk, kérjük, őrizze meg ezt a 24 szavas kulcsot egy biztonságos helyen.';

  @override
  String get doThisLater => 'Később';

  @override
  String get saveKey => 'Mentés';

  @override
  String get recoveryKeySaved =>
      'A helyreállítási kulcs a Letöltések mappába mentve!';

  @override
  String get noRecoveryKeyTitle => 'Nincs helyreállítási kulcs?';

  @override
  String get twoFactorAuthTitle => 'Kétlépcsős hitelesítés (2FA)';

  @override
  String get enterCodeHint =>
      'Írja be a 6 számjegyű kódot a hitelesítő alkalmazásból';

  @override
  String get lostDeviceTitle => 'Elveszett a készüléked?';

  @override
  String get enterRecoveryKeyHint => 'Visszaállító kód megadása';

  @override
  String get recover => 'Visszaállít';

  @override
  String get loggingOut => 'Kijelentkezés...';

  @override
  String get immediately => 'Azonnal';

  @override
  String get appLock => 'Alkalmazások zárolása';

  @override
  String get autoLock => 'Automatikus lezárás';

  @override
  String get noSystemLockFound => 'Nem található rendszerzár';

  @override
  String get deviceLockEnablePreSteps =>
      'Az eszközzár engedélyezéséhez állítsa be az eszköz jelszavát vagy a zárképernyőt a rendszerbeállításokban.';

  @override
  String get appLockDescription =>
      'Válasszon az eszköz alapértelmezett zárolási képernyője és a PIN-kóddal vagy jelszóval rendelkező egyéni zárolási képernyő között.';

  @override
  String get deviceLock => 'Eszköz lezárás';

  @override
  String get pinLock => 'PIN feloldás';

  @override
  String get autoLockFeatureDescription =>
      'Az az idő, amely elteltével az alkalmazás zárolásra kerül, miután a háttérbe került';

  @override
  String get hideContent => 'Tartalom elrejtése';

  @override
  String get hideContentDescriptionAndroid =>
      'Elrejti az alkalmazás tartalmát az alkalmazásváltóban, és letiltja a képernyőképeket';

  @override
  String get hideContentDescriptioniOS =>
      'Elrejti az alkalmazás tartalmát az alkalmazásváltóban';

  @override
  String get tooManyIncorrectAttempts => 'Túl sok helytelen próbálkozás';

  @override
  String get tapToUnlock => 'Koppintson a feloldáshoz';

  @override
  String get areYouSureYouWantToLogout => 'Biztos benne, hogy kijelentkezik?';

  @override
  String get yesLogout => 'Igen, kijelentkezés';

  @override
  String get authToViewSecrets =>
      'A titkos kulcsok megtekintéséhez hitelesítse magát';

  @override
  String get next => 'Következő';

  @override
  String get setNewPassword => 'Új jelszó beállítása';

  @override
  String get enterPin => 'PIN kód megadása';

  @override
  String get setNewPin => 'Új PIN kód beállítása';

  @override
  String get confirm => 'Megerősítés';

  @override
  String get reEnterPassword => 'Írja be újra a jelszót';

  @override
  String get reEnterPin => 'Írja be újra a PIN-kódot';

  @override
  String get androidBiometricHint => 'Személyazonosság ellenőrzése';

  @override
  String get androidBiometricNotRecognized => 'Nem felismerhető. Próbáld újra.';

  @override
  String get androidBiometricSuccess => 'Sikeres';

  @override
  String get androidCancelButton => 'Mégse';

  @override
  String get androidSignInTitle => 'Hitelesítés szükséges';

  @override
  String get androidBiometricRequiredTitle => 'Biometria szükséges';

  @override
  String get androidDeviceCredentialsRequiredTitle =>
      'Az eszköz hitelesítő adatai szükségesek';

  @override
  String get androidDeviceCredentialsSetupDescription =>
      'Az eszköz hitelesítő adatai szükségesek';

  @override
  String get goToSettings => 'Beállítások megnyitása';

  @override
  String get androidGoToSettingsDescription =>
      'A biometrikus hitelesítés nincs beállítva az eszközön. A biometrikus hitelesítés hozzáadásához lépjen a \'Beállítások > Biztonság\' menüpontra.';

  @override
  String get iOSLockOut =>
      'A biometrikus hitelesítés ki van kapcsolva. Az engedélyezéséhez zárja le és oldja fel a képernyőt.';

  @override
  String get iOSOkButton => 'OK';

  @override
  String get emailAlreadyRegistered => 'Ez az e-mai cím már regisztrálva van.';

  @override
  String get emailNotRegistered => 'Ez az e-mail cím nincs regisztrálva.';

  @override
  String get thisEmailIsAlreadyInUse => 'Ez az e-mail már használatban van';

  @override
  String emailChangedTo(String newEmail) {
    return 'Az e-mail cím módosítva erre: $newEmail';
  }

  @override
  String get authenticationFailedPleaseTryAgain =>
      'A hitelesítés sikertelen, próbálja újra';

  @override
  String get authenticationSuccessful => 'Sikeres hitelesítés!';

  @override
  String get sessionExpired => 'A munkamenet lejárt';

  @override
  String get incorrectRecoveryKey => 'Helytelen helyreállítási kulcs';

  @override
  String get theRecoveryKeyYouEnteredIsIncorrect =>
      'A megadott helyreállítási kulcs helytelen';

  @override
  String get twofactorAuthenticationSuccessfullyReset =>
      'A kétfaktoros hitelesítés visszaállítása sikeres';

  @override
  String get noRecoveryKey => 'No recovery key';

  @override
  String get yourAccountHasBeenDeleted => 'Your account has been deleted';

  @override
  String get verificationId => 'Verification ID';

  @override
  String get yourVerificationCodeHasExpired => 'Ez az ellenőrző kód lejárt';

  @override
  String get incorrectCode => 'Helytelen kód';

  @override
  String get sorryTheCodeYouveEnteredIsIncorrect =>
      'Sajnáljuk, a megadott kód helytelen';

  @override
  String get developerSettings => 'Fejlesztői beállítások';

  @override
  String get serverEndpoint => 'Szerver végpont';

  @override
  String get invalidEndpoint => 'Érvénytelen végpont';

  @override
  String get invalidEndpointMessage =>
      'Sajnáljuk, a megadott végpont érvénytelen. Adjon meg egy érvényes végpontot, és próbálja újra.';

  @override
  String get endpointUpdatedMessage => 'A végpont sikeresen frissítve';
}
