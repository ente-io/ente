// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class StringsLocalizationsCs extends StringsLocalizations {
  StringsLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get networkHostLookUpErr =>
      'Nelze se připojit k Ente, zkontrolujte, prosím, nastavení své sítě a kontaktujte podporu, pokud chyba přetrvává';

  @override
  String get networkConnectionRefusedErr =>
      'Nepodařilo se připojit k Ente, zkuste to po nějaké době znovu. Pokud chyba přetrvává, kontaktujte, prosím, podporu.';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      'Vypadá to, že se něco pokazilo. Zkuste to prosím znovu po nějaké době. Pokud chyba přetrvává, kontaktujte prosím naši podporu.';

  @override
  String get error => 'Chyba';

  @override
  String get ok => 'Ok';

  @override
  String get faq => 'Často kladené dotazy (FAQ)';

  @override
  String get contactSupport => 'Kontaktovat podporu';

  @override
  String get emailYourLogs => 'Zašlete své logy e-mailem';

  @override
  String pleaseSendTheLogsTo(String toEmail) {
    return 'Pošlete prosím logy na \n$toEmail';
  }

  @override
  String get copyEmailAddress => 'Kopírovat e-mailovou adresu';

  @override
  String get exportLogs => 'Exportovat logy';

  @override
  String get cancel => 'Zrušit';

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
  String get reportABug => 'Nahlásit chybu';

  @override
  String get logsDialogBody =>
      'This will send across logs to help us debug your issue. Please note that file names will be included to help track issues with specific files.';

  @override
  String get viewLogs => 'View logs';

  @override
  String customEndpoint(String endpoint) {
    return 'Připojeno k $endpoint';
  }

  @override
  String get save => 'Uložit';

  @override
  String get send => 'Odeslat';

  @override
  String get saveOrSendDescription =>
      'Chcete toto uložit do paměti zařízení (ve výchozím nastavení do složky Stažené soubory), nebo odeslat do jiných aplikací?';

  @override
  String get saveOnlyDescription =>
      'Chcete toto uložit do paměti zařízení (ve výchozím nastavení do složky Stažené soubory)?';

  @override
  String get enterNewEmailHint => 'Enter your new email address';

  @override
  String get email => 'E-mail';

  @override
  String get verify => 'Ověřit';

  @override
  String get invalidEmailTitle => 'Neplatná e-mailová adresa';

  @override
  String get invalidEmailMessage =>
      'Prosím, zadejte platnou e-mailovou adresu.';

  @override
  String get pleaseWait => 'Čekejte prosím...';

  @override
  String get verifyPassword => 'Ověření hesla';

  @override
  String get incorrectPasswordTitle => 'Nesprávné heslo';

  @override
  String get pleaseTryAgain => 'Zkuste to prosím znovu';

  @override
  String get enterPassword => 'Zadejte heslo';

  @override
  String get enterYourPasswordHint => 'Zadejte své heslo';

  @override
  String get activeSessions => 'Aktivní relace';

  @override
  String get oops => 'Jejda';

  @override
  String get somethingWentWrongPleaseTryAgain =>
      'Něco se pokazilo. Zkuste to, prosím, znovu';

  @override
  String get thisWillLogYouOutOfThisDevice =>
      'Tato akce Vás odhlásí z tohoto zařízení!';

  @override
  String get thisWillLogYouOutOfTheFollowingDevice =>
      'Toto Vás odhlásí z následujícího zařízení:';

  @override
  String get terminateSession => 'Ukončit relaci?';

  @override
  String get terminate => 'Ukončit';

  @override
  String get thisDevice => 'Toto zařízení';

  @override
  String get createAccount => 'Vytvořit účet';

  @override
  String get weakStrength => 'Slabé';

  @override
  String get moderateStrength => 'Střední';

  @override
  String get strongStrength => 'Silné';

  @override
  String get deleteAccount => 'Odstranit účet';

  @override
  String get deleteAccountQuery =>
      'Mrzí nás, že odcházíte. Máte nějaké problémy s aplikací?';

  @override
  String get yesSendFeedbackAction => 'Ano, poslat zpětnou vazbu';

  @override
  String get noDeleteAccountAction => 'Ne, odstranit účet';

  @override
  String get initiateAccountDeleteTitle =>
      'Pro zahájení odstranění účtu se, prosím, ověřte';

  @override
  String get confirmAccountDeleteTitle => 'Potvrdit odstranění účtu';

  @override
  String get confirmAccountDeleteMessage => ' ';

  @override
  String get delete => 'Smazat';

  @override
  String get createNewAccount => 'Vytvořit nový účet';

  @override
  String get password => 'Heslo';

  @override
  String get confirmPassword => 'Potvrzení hesla';

  @override
  String passwordStrength(String passwordStrengthValue) {
    return 'Síla hesla: $passwordStrengthValue';
  }

  @override
  String get hearUsWhereTitle => 'Jak jste se dozvěděli o Ente? (volitelné)';

  @override
  String get hearUsExplanation =>
      'Ne sledujeme instalace aplikace. Pomůže nám, když nám sdělíte, kde jste nás našli!';

  @override
  String get signUpTerms =>
      'Souhlasím s <u-terms>podmínkami služby</u-terms> a <u-terms>zásadami ochrany osobních údajů</u-terms>';

  @override
  String get termsOfServicesTitle => 'Podmínky';

  @override
  String get privacyPolicyTitle => 'Podmínky ochrany osobních údajů';

  @override
  String get ackPasswordLostWarning =>
      'Rozumím, že při zapomenutí hesla mohu ztratit svá data, protože jsou zabezpečena <underline>koncovým šifrováním</underline>.';

  @override
  String get encryption => 'Šifrování';

  @override
  String get logInLabel => 'Přihlásit se';

  @override
  String get welcomeBack => 'Vítejte zpět!';

  @override
  String get loginTerms =>
      'Kliknutím na přihlášení souhlasím s <u-terms>podmínkami služby</u-terms> a <u-policy>zásadami ochrany osobních údajů</u-policy>';

  @override
  String get noInternetConnection => 'Žádné připojení k internetu';

  @override
  String get pleaseCheckYourInternetConnectionAndTryAgain =>
      'Zkontrolujte, prosím, své připojení k internetu a zkuste to znovu.';

  @override
  String get verificationFailedPleaseTryAgain =>
      'Ověření selhalo, přihlaste se, prosím, znovu';

  @override
  String get recreatePasswordTitle => 'Resetovat heslo';

  @override
  String get recreatePasswordBody =>
      'Aktzální zařízení není dostatečně výkonné pro ověření Vašeho hesla, ale můžeme ho regenerovat způsobem, který funguje ve všech zařízením.\n\nPřihlašte se pomocí obnovovacího klíče a znovu si vygenerujte své heslo (můžete použít opět stejné, pokud chcete).';

  @override
  String get useRecoveryKey => 'Použít obnovovací klíč';

  @override
  String get forgotPassword => 'Zapomenuté heslo';

  @override
  String get changeEmail => 'Změnit e-mail';

  @override
  String get verifyEmail => 'Ověřit e-mail';

  @override
  String weHaveSendEmailTo(String email) {
    return 'Odeslali jsme e-mail na <green>$email</green>';
  }

  @override
  String get toResetVerifyEmail =>
      'Pro obnovení hesla obnovte, prosím, nejprve svůj e-mail.';

  @override
  String get checkInboxAndSpamFolder =>
      'Pro dokončení ověření prosím zkontrolujte, prosím, svou doručenou poštu (a spamy)';

  @override
  String get tapToEnterCode => 'Klepnutím zadejte kód';

  @override
  String get sendEmail => 'Odeslat e-mail';

  @override
  String get resendEmail => 'Odeslat e-mail znovu';

  @override
  String get passKeyPendingVerification => 'Ověřování stále probíhá';

  @override
  String get loginSessionExpired => 'Relace vypršela';

  @override
  String get loginSessionExpiredDetails =>
      'Vaše relace vypršela. Přihlaste se, prosím, znovu.';

  @override
  String get passkeyAuthTitle => 'Passkey verification';

  @override
  String get waitingForVerification => 'Čekání na ověření...';

  @override
  String get tryAgain => 'Zkusit znovu';

  @override
  String get checkStatus => 'Zkontrolovat stav';

  @override
  String get loginWithTOTP => 'Přihlášení s TOTP';

  @override
  String get recoverAccount => 'Obnovit účet';

  @override
  String get setPasswordTitle => 'Nastavit heslo';

  @override
  String get changePasswordTitle => 'Změnit heslo';

  @override
  String get resetPasswordTitle => 'Obnovit heslo';

  @override
  String get encryptionKeys => 'Šifrovací klíče';

  @override
  String get enterPasswordToEncrypt =>
      'Zadejte heslo, kterým můžeme zašifrovat Vaše data';

  @override
  String get enterNewPasswordToEncrypt =>
      'Zadejte nové heslo, kterým můžeme šifrovat Vaše data';

  @override
  String get passwordWarning =>
      'Vaše heslo neuchováváme. Pokud ho zapomenete, <underline>nemůžeme Vaše data dešifrovat</underline>';

  @override
  String get howItWorks => 'Jak to funguje';

  @override
  String get generatingEncryptionKeys => 'Generování šifrovacích klíčů...';

  @override
  String get passwordChangedSuccessfully => 'Heslo úspěšně změněno';

  @override
  String get signOutFromOtherDevices => 'Odhlásit z ostatních zařízení';

  @override
  String get signOutOtherBody =>
      'Pokud si myslíte, že by někdo mohl znát Vaše heslo, můžete vynutit odhlášení ostatních zařízení používajících Váš účet.';

  @override
  String get signOutOtherDevices => 'Odhlásit z ostatních zařízení';

  @override
  String get doNotSignOut => 'Neodhlašovat';

  @override
  String get generatingEncryptionKeysTitle => 'Generování šifrovacích klíčů...';

  @override
  String get continueLabel => 'Pokračovat';

  @override
  String get insecureDevice => 'Nezabezpečené zařízení';

  @override
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease =>
      'Omlouváme se, na tomto zařízení nemůžeme vygenerovat bezpečné klíče.\n\nprosím přihlaste se z jiného zařízení.';

  @override
  String get recoveryKeyCopiedToClipboard => 'Obnovovací klíč byl zkopírován';

  @override
  String get recoveryKey => 'Obnovovací klíč';

  @override
  String get recoveryKeyOnForgotPassword =>
      'Tento klíč je jedinou cestou pro obnovení Vašich dat, pokud zapomenete heslo.';

  @override
  String get recoveryKeySaveDescription =>
      'Tento 24místný klíč neuchováváme, uschovejte ho, prosím, na bezpečném místě.';

  @override
  String get doThisLater => 'Udělat později';

  @override
  String get saveKey => 'Uložit klíč';

  @override
  String get recoveryKeySaved =>
      'Obnovovací klíč uložen do složky Stažené soubory!';

  @override
  String get noRecoveryKeyTitle => 'Nemáte obnovovací klíč?';

  @override
  String get twoFactorAuthTitle => 'Dvoufaktorové ověření';

  @override
  String get enterCodeHint =>
      'Zadejte 6místný kód ze své autentizační aplikace';

  @override
  String get lostDeviceTitle => 'Ztratili jste zařízení?';

  @override
  String get enterRecoveryKeyHint => 'Zadejte svůj obnovovací klíč';

  @override
  String get recover => 'Obnovit';

  @override
  String get loggingOut => 'Odhlašování...';

  @override
  String get immediately => 'Ihned';

  @override
  String get appLock => 'Zámek aplikace';

  @override
  String get autoLock => 'Automatické zamykání';

  @override
  String get noSystemLockFound => 'Zámek systému nenalezen';

  @override
  String get deviceLockEnablePreSteps =>
      'Pro aktivaci zámku zařízení si nastavte přístupový kód zařízení nebo zámek obrazovky v nastavení systému.';

  @override
  String get appLockDescription =>
      'Vyberte si mezi zámkem obrazovky svého zařízení a vlastním zámkem obrazovky s PIN kódem nebo heslem.';

  @override
  String get deviceLock => 'Zámek zařízení';

  @override
  String get pinLock => 'Uzamčení na PIN';

  @override
  String get autoLockFeatureDescription =>
      'Interval, po kterém se aplikace běžící na pozadí uzamkne';

  @override
  String get hideContent => 'Skrýt obsah';

  @override
  String get hideContentDescriptionAndroid => 'Skryje obsah aplikace ve ';

  @override
  String get hideContentDescriptioniOS =>
      'Skryje obsah aplikace při přepínání úloh';

  @override
  String get tooManyIncorrectAttempts => 'Příliš mnoho neúspěšných pokusů';

  @override
  String get tapToUnlock => 'Pro odemčení klepněte';

  @override
  String get areYouSureYouWantToLogout => 'Opravdu se chcete odhlásit?';

  @override
  String get yesLogout => 'Ano, odhlásit se';

  @override
  String get authToViewSecrets =>
      'Pro zobrazení svých tajných údajů se musíte ověřit';

  @override
  String get next => 'Další';

  @override
  String get setNewPassword => 'Nastavit nové heslo';

  @override
  String get enterPin => 'Zadejte PIN';

  @override
  String get setNewPin => 'Nadra';

  @override
  String get confirm => 'Potvrdit';

  @override
  String get reEnterPassword => 'Zadejte heslo znovu';

  @override
  String get reEnterPin => 'Zadejte PIN znovu';

  @override
  String get androidBiometricHint => 'Ověřte svou identitu';

  @override
  String get androidBiometricNotRecognized => 'Nerozpoznáno. Zkuste znovu.';

  @override
  String get androidBiometricSuccess => 'Úspěch';

  @override
  String get androidCancelButton => 'Zrušit';

  @override
  String get androidSignInTitle => 'Je požadováno ověření';

  @override
  String get androidBiometricRequiredTitle =>
      'Je požadováno biometrické ověření';

  @override
  String get androidDeviceCredentialsRequiredTitle =>
      'Jsou vyžadovány přihlašovací údaje zařízení';

  @override
  String get androidDeviceCredentialsSetupDescription =>
      'Jsou vyžadovány přihlašovací údaje zařízení';

  @override
  String get goToSettings => 'Jít do nastavení';

  @override
  String get androidGoToSettingsDescription =>
      'Na Vašem zařízení není nastaveno biometrické ověřování. Pro aktivaci běžte do \'Nastavení > Zabezpečení\'.';

  @override
  String get iOSLockOut =>
      'Biometrické ověřování není povoleno. Pro povolení zamkněte a odemkněte obrazovku.';

  @override
  String get iOSOkButton => 'OK';

  @override
  String get emailAlreadyRegistered => 'E-mail je již registrován.';

  @override
  String get emailNotRegistered => 'E-mail není registrován.';

  @override
  String get thisEmailIsAlreadyInUse => 'Tento e-mail je již používán';

  @override
  String emailChangedTo(String newEmail) {
    return 'E-mail změněn na $newEmail';
  }

  @override
  String get authenticationFailedPleaseTryAgain =>
      'Ověření selhalo, zkuste to, prosím, znovu';

  @override
  String get authenticationSuccessful => 'Ověření bylo úspěšné!';

  @override
  String get sessionExpired => 'Relace vypršela';

  @override
  String get incorrectRecoveryKey => 'Nesprávný obnovovací klíč';

  @override
  String get theRecoveryKeyYouEnteredIsIncorrect =>
      'Vámi zadaný obnovovací klíč je nesprávný';

  @override
  String get twofactorAuthenticationSuccessfullyReset =>
      'Dvoufázové ověření bylo úspěšně obnoveno';

  @override
  String get noRecoveryKey => 'No recovery key';

  @override
  String get yourAccountHasBeenDeleted => 'Your account has been deleted';

  @override
  String get verificationId => 'Verification ID';

  @override
  String get yourVerificationCodeHasExpired => 'Váš ověřovací kód vypršel';

  @override
  String get incorrectCode => 'Nesprávný kód';

  @override
  String get sorryTheCodeYouveEnteredIsIncorrect =>
      'Omlouváme se, zadaný kód je nesprávný';

  @override
  String get developerSettings => 'Nastavení pro vývojáře';

  @override
  String get serverEndpoint => 'Koncový bod serveru';

  @override
  String get invalidEndpoint => 'Neplatný koncový bod';

  @override
  String get invalidEndpointMessage =>
      'Zadaný koncový bod je neplatný. Zadejte prosím platný koncový bod a zkuste to znovu.';

  @override
  String get endpointUpdatedMessage => 'Koncový bod byl úspěšně aktualizován';
}
