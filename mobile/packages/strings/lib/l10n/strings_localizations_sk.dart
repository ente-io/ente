// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovak (`sk`).
class StringsLocalizationsSk extends StringsLocalizations {
  StringsLocalizationsSk([String locale = 'sk']) : super(locale);

  @override
  String get networkHostLookUpErr =>
      'Nemožno sa pripojiť k Ente, skontrolujte svoje nastavenia siete a kontaktujte podporu, ak chyba pretrváva.';

  @override
  String get networkConnectionRefusedErr =>
      'Nemožno sa pripojiť k Ente, skúste znova v krátkom čase. Ak chyba pretrváva, kontaktujte podporu.';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      'Vyzerá to, že sa niečo pokazilo. Skúste znova v krátkom čase. Ak chyba pretrváva, kontaktujte náš tím podpory.';

  @override
  String get error => 'Chyba';

  @override
  String get ok => 'Ok';

  @override
  String get faq => 'Často kladené otázky';

  @override
  String get contactSupport => 'Kontaktovať podporu';

  @override
  String get emailYourLogs => 'Odoslať vaše logy emailom';

  @override
  String pleaseSendTheLogsTo(String toEmail) {
    return 'Prosím, pošlite logy na adresu \n$toEmail';
  }

  @override
  String get copyEmailAddress => 'Skopírovať e-mailovú adresu';

  @override
  String get exportLogs => 'Exportovať logy';

  @override
  String get cancel => 'Zrušiť';

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
  String get reportABug => 'Nahlásiť chybu';

  @override
  String get logsDialogBody =>
      'This will send across logs to help us debug your issue. Please note that file names will be included to help track issues with specific files.';

  @override
  String get viewLogs => 'View logs';

  @override
  String customEndpoint(String endpoint) {
    return 'Pripojený k endpointu $endpoint';
  }

  @override
  String get save => 'Uložiť';

  @override
  String get send => 'Odoslať';

  @override
  String get saveOrSendDescription =>
      'Chcete to uložiť do svojho zariadenia (predvolený priečinok Stiahnuté súbory) alebo to odoslať do iných aplikácií?';

  @override
  String get saveOnlyDescription =>
      'Chcete to uložiť do svojho zariadenia (predvolený priečinok Stiahnuté súbory)?';

  @override
  String get enterNewEmailHint => 'Enter your new email address';

  @override
  String get email => 'Email';

  @override
  String get verify => 'Overiť';

  @override
  String get invalidEmailTitle => 'Neplatná emailová adresa';

  @override
  String get invalidEmailMessage => 'Zadajte platnú e-mailovú adresu.';

  @override
  String get pleaseWait => 'Prosím počkajte...';

  @override
  String get verifyPassword => 'Potvrďte heslo';

  @override
  String get incorrectPasswordTitle => 'Nesprávne heslo';

  @override
  String get pleaseTryAgain => 'Prosím, skúste to znova';

  @override
  String get enterPassword => 'Zadajte heslo';

  @override
  String get enterYourPasswordHint => 'Zadajte vaše heslo';

  @override
  String get activeSessions => 'Aktívne relácie';

  @override
  String get oops => 'Ups';

  @override
  String get somethingWentWrongPleaseTryAgain =>
      'Niečo sa pokazilo, skúste to prosím znova';

  @override
  String get thisWillLogYouOutOfThisDevice =>
      'Toto vás odhlási z tohto zariadenia!';

  @override
  String get thisWillLogYouOutOfTheFollowingDevice =>
      'Toto vás odhlási z následujúceho zariadenia:';

  @override
  String get terminateSession => 'Ukončiť reláciu?';

  @override
  String get terminate => 'Ukončiť';

  @override
  String get thisDevice => 'Toto zariadenie';

  @override
  String get createAccount => 'Vytvoriť účet';

  @override
  String get weakStrength => 'Slabé';

  @override
  String get moderateStrength => 'Mierne';

  @override
  String get strongStrength => 'Silné';

  @override
  String get deleteAccount => 'Odstrániť účet';

  @override
  String get deleteAccountQuery =>
      'Bude nám ľúto ak odídeš. Máš nejaký problém?';

  @override
  String get yesSendFeedbackAction => 'Áno, odoslať spätnú väzbu';

  @override
  String get noDeleteAccountAction => 'Nie, odstrániť účet';

  @override
  String get deleteAccountWarning =>
      'This will delete your Ente Auth, Ente Photos and Ente Locker account.';

  @override
  String get initiateAccountDeleteTitle =>
      'Je potrebné overenie pre spustenie odstránenia účtu';

  @override
  String get confirmAccountDeleteTitle => 'Potvrď odstránenie účtu';

  @override
  String get confirmAccountDeleteMessage =>
      'Tento účet je prepojený s inými aplikáciami Ente, ak nejaké používaš.\n\nTvoje nahrané údaje vo všetkých Ente aplikáciách budú naplánované na odstránenie a tvoj účet bude natrvalo odstránený.';

  @override
  String get delete => 'Odstrániť';

  @override
  String get createNewAccount => 'Vytvoriť nový účet';

  @override
  String get password => 'Heslo';

  @override
  String get confirmPassword => 'Potvrdiť heslo';

  @override
  String passwordStrength(String passwordStrengthValue) {
    return 'Sila hesla: $passwordStrengthValue';
  }

  @override
  String get hearUsWhereTitle => 'Ako ste sa dozvedeli o Ente? (voliteľné)';

  @override
  String get hearUsExplanation =>
      'Nesledujeme inštalácie aplikácie. Veľmi by nám pomohlo, keby ste nám povedali, ako ste sa o nás dozvedeli!';

  @override
  String get signUpTerms =>
      'Súhlasím s <u-terms>podmienkami používania</u-terms> a <u-policy>zásadami ochrany osobných údajov</u-policy>';

  @override
  String get termsOfServicesTitle => 'Podmienky používania';

  @override
  String get privacyPolicyTitle => 'Zásady ochrany osobných údajov';

  @override
  String get ackPasswordLostWarning =>
      'Rozumiem, že ak stratím alebo zabudnem heslo, môžem stratiť svoje údaje, pretože moje údaje sú <underline>šifrované end-to-end</underline>.';

  @override
  String get encryption => 'Šifrovanie';

  @override
  String get logInLabel => 'Prihlásenie';

  @override
  String get welcomeBack => 'Vitajte späť!';

  @override
  String get loginTerms =>
      'Kliknutím na prihlásenie, súhlasím s <u-terms>podmienkami používania</u-terms> a <u-policy>zásadami ochrany osobných údajov</u-policy>';

  @override
  String get noInternetConnection => 'Žiadne internetové pripojenie';

  @override
  String get pleaseCheckYourInternetConnectionAndTryAgain =>
      'Skontrolujte svoje internetové pripojenie a skúste to znova.';

  @override
  String get verificationFailedPleaseTryAgain =>
      'Overenie zlyhalo, skúste to znova';

  @override
  String get recreatePasswordTitle => 'Resetovať heslo';

  @override
  String get recreatePasswordBody =>
      'Aktuálne zariadenie nie je dostatočne výkonné na overenie vášho hesla, avšak vieme ho regenerovať spôsobom, ktorý funguje vo všetkých zariadeniach.\n\nPrihláste sa pomocou kľúča na obnovenie a znovu vygenerujte svoje heslo (ak si prajete, môžete znova použiť rovnaké).';

  @override
  String get useRecoveryKey => 'Použiť kľúč na obnovenie';

  @override
  String get forgotPassword => 'Zabudnuté heslo';

  @override
  String get changeEmail => 'Zmeniť e-mail';

  @override
  String get verifyEmail => 'Overiť email';

  @override
  String weHaveSendEmailTo(String email) {
    return 'Odoslali sme email na adresu <green>$email</green>';
  }

  @override
  String get toResetVerifyEmail =>
      'Ak chcete obnoviť svoje heslo, najskôr overte svoj email.';

  @override
  String get checkInboxAndSpamFolder =>
      'Skontrolujte svoju doručenú poštu (a spam) pre dokončenie overenia';

  @override
  String get tapToEnterCode => 'Klepnutím zadajte kód';

  @override
  String get sendEmail => 'Odoslať email';

  @override
  String get resendEmail => 'Znovu odoslať email';

  @override
  String get passKeyPendingVerification => 'Overenie stále prebieha';

  @override
  String get loginSessionExpired => 'Relácia vypršala';

  @override
  String get loginSessionExpiredDetails =>
      'Vaša relácia vypršala. Prosím, prihláste sa znovu.';

  @override
  String get passkeyAuthTitle => 'Overenie pomocou passkey';

  @override
  String get waitingForVerification => 'Čakanie na overenie...';

  @override
  String get tryAgain => 'Skúsiť znova';

  @override
  String get checkStatus => 'Overiť stav';

  @override
  String get loginWithTOTP => 'Prihlásenie pomocou TOTP';

  @override
  String get recoverAccount => 'Obnoviť účet';

  @override
  String get setPasswordTitle => 'Nastaviť heslo';

  @override
  String get changePasswordTitle => 'Zmeniť heslo';

  @override
  String get resetPasswordTitle => 'Obnoviť heslo';

  @override
  String get encryptionKeys => 'Šifrovacie kľúče';

  @override
  String get enterPasswordToEncrypt =>
      'Zadajte heslo, ktoré môžeme použiť na šifrovanie vašich údajov';

  @override
  String get enterNewPasswordToEncrypt =>
      'Zadajte nové heslo, ktoré môžeme použiť na šifrovanie vašich údajov';

  @override
  String get passwordWarning =>
      'Ente neukladá tohto heslo. V prípade, že ho zabudnete, <underline>nie sme schopní rozšifrovať vaše údaje</underline>';

  @override
  String get howItWorks => 'Ako to funguje';

  @override
  String get generatingEncryptionKeys => 'Generovanie šifrovacích kľúčov...';

  @override
  String get passwordChangedSuccessfully => 'Heslo bolo úspešne zmenené';

  @override
  String get signOutFromOtherDevices => 'Odhlásiť sa z iných zariadení';

  @override
  String get signOutOtherBody =>
      'Ak si myslíš, že by niekto mohol poznať tvoje heslo, môžeš vynútiť odhlásenie všetkých ostatných zariadení používajúcich tvoj účet.';

  @override
  String get signOutOtherDevices => 'Odhlásiť iné zariadenie';

  @override
  String get doNotSignOut => 'Neodhlasovať';

  @override
  String get generatingEncryptionKeysTitle =>
      'Generovanie šifrovacích kľúčov...';

  @override
  String get continueLabel => 'Pokračovať';

  @override
  String get insecureDevice => 'Slabo zabezpečené zariadenie';

  @override
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease =>
      'Ospravedlňujeme sa, v tomto zariadení sme nemohli generovať bezpečnostné kľúče.\n\nzaregistrujte sa z iného zariadenia.';

  @override
  String get recoveryKeyCopiedToClipboard =>
      'Skopírovaný kód pre obnovenie do schránky';

  @override
  String get recoveryKey => 'Kľúč pre obnovenie';

  @override
  String get recoveryKeyOnForgotPassword =>
      'Ak zabudnete heslo, jediným spôsobom, ako môžete obnoviť svoje údaje, je tento kľúč.';

  @override
  String get recoveryKeySaveDescription =>
      'My tento kľúč neuchovávame, uložte si tento kľúč obsahujúci 24 slov na bezpečnom mieste.';

  @override
  String get doThisLater => 'Urobiť to neskôr';

  @override
  String get saveKey => 'Uložiť kľúč';

  @override
  String get recoveryKeySaved =>
      'Kľúč na obnovenie uložený v priečinku Stiahnutých súborov!';

  @override
  String get noRecoveryKeyTitle => 'Nemáte kľúč pre obnovenie?';

  @override
  String get twoFactorAuthTitle => 'Dvojfaktorové overovanie';

  @override
  String get enterCodeHint =>
      'Zadajte 6-miestny kód z\nvašej overovacej aplikácie';

  @override
  String get lostDeviceTitle => 'Stratené zariadenie?';

  @override
  String get enterRecoveryKeyHint => 'Vložte váš kód pre obnovenie';

  @override
  String get recover => 'Obnoviť';

  @override
  String get loggingOut => 'Odhlasovanie...';

  @override
  String get immediately => 'Okamžite';

  @override
  String get appLock => 'Zámok aplikácie';

  @override
  String get autoLock => 'Automatické uzamknutie';

  @override
  String get noSystemLockFound => 'Nenájdená žiadna zámka obrazovky';

  @override
  String get deviceLockEnablePreSteps =>
      'Pre povolenie zámku zariadenia, nastavte prístupový kód zariadenia alebo zámok obrazovky v nastaveniach systému.';

  @override
  String get appLockDescription =>
      'Vyberte si medzi predvolenou zámkou obrazovky vášho zariadenia a vlastnou zámkou obrazovky s PIN kódom alebo heslom.';

  @override
  String get deviceLock => 'Zámok zariadenia';

  @override
  String get pinLock => 'Zámok PIN';

  @override
  String get autoLockFeatureDescription =>
      'Čas, po ktorom sa aplikácia uzamkne po nečinnosti';

  @override
  String get hideContent => 'Skryť obsah';

  @override
  String get hideContentDescriptionAndroid =>
      'Skrýva obsah v prepínači aplikácii a zakazuje snímky obrazovky';

  @override
  String get hideContentDescriptioniOS => 'Skrýva obsah v prepínači aplikácii';

  @override
  String get tooManyIncorrectAttempts => 'Príliš veľa chybných pokusov';

  @override
  String get tapToUnlock => 'Ťuknutím odomknete';

  @override
  String get areYouSureYouWantToLogout => 'Naozaj sa chcete odhlásiť?';

  @override
  String get yesLogout => 'Áno, odhlásiť sa';

  @override
  String get authToViewSecrets =>
      'Pre zobrazenie vašich tajných údajov sa musíte overiť';

  @override
  String get next => 'Ďalej';

  @override
  String get setNewPassword => 'Nastaviť nové heslo';

  @override
  String get enterPin => 'Zadajte PIN';

  @override
  String get setNewPin => 'Nastaviť nový PIN';

  @override
  String get confirm => 'Potvrdiť';

  @override
  String get reEnterPassword => 'Zadajte heslo znova';

  @override
  String get reEnterPin => 'Zadajte PIN znova';

  @override
  String get androidBiometricHint => 'Overiť identitu';

  @override
  String get androidBiometricNotRecognized => 'Nerozpoznané. Skúste znova.';

  @override
  String get androidBiometricSuccess => 'Overenie úspešné';

  @override
  String get androidCancelButton => 'Zrušiť';

  @override
  String get androidSignInTitle => 'Vyžaduje sa overenie';

  @override
  String get androidBiometricRequiredTitle => 'Vyžaduje sa biometria';

  @override
  String get androidDeviceCredentialsRequiredTitle =>
      'Vyžadujú sa poverenia zariadenia';

  @override
  String get androidDeviceCredentialsSetupDescription =>
      'Vyžadujú sa poverenia zariadenia';

  @override
  String get goToSettings => 'Prejsť do nastavení';

  @override
  String get androidGoToSettingsDescription =>
      'Overenie pomocou biometrie nie je na vašom zariadení nastavené. Prejdite na \'Nastavenie > Zabezpečenie\' a pridajte overenie pomocou biometrie.';

  @override
  String get iOSLockOut =>
      'Overenie pomocou biometrie je zakázané. Zamknite a odomknite svoju obrazovku, aby ste ho povolili.';

  @override
  String get iOSOkButton => 'OK';

  @override
  String get emailAlreadyRegistered => 'Email already registered.';

  @override
  String get emailNotRegistered => 'Email not registered.';

  @override
  String get thisEmailIsAlreadyInUse => 'Tento e-mail sa už používa';

  @override
  String emailChangedTo(String newEmail) {
    return 'Emailová adresa bola zmenená na $newEmail';
  }

  @override
  String get authenticationFailedPleaseTryAgain =>
      'Overenie zlyhalo. Skúste to znova';

  @override
  String get authenticationSuccessful => 'Overenie sa podarilo!';

  @override
  String get sessionExpired => 'Relácia vypršala';

  @override
  String get incorrectRecoveryKey => 'Nesprávny kľúč na obnovenie';

  @override
  String get theRecoveryKeyYouEnteredIsIncorrect =>
      'Kľúč na obnovenie, ktorý ste zadali, je nesprávny';

  @override
  String get twofactorAuthenticationSuccessfullyReset =>
      'Dvojfaktorové overovanie bolo úspešne obnovené';

  @override
  String get noRecoveryKey => 'No recovery key';

  @override
  String get yourAccountHasBeenDeleted => 'Your account has been deleted';

  @override
  String get verificationId => 'Verification ID';

  @override
  String get yourVerificationCodeHasExpired =>
      'Platnosť overovacieho kódu uplynula';

  @override
  String get incorrectCode => 'Neplatný kód';

  @override
  String get sorryTheCodeYouveEnteredIsIncorrect =>
      'Ľutujeme, zadaný kód je nesprávny';

  @override
  String get developerSettings => 'Nastavenia pre vývojárov';

  @override
  String get serverEndpoint => 'Endpoint servera';

  @override
  String get invalidEndpoint => 'Neplatný endpoint';

  @override
  String get invalidEndpointMessage =>
      'Ospravedlňujeme sa, endpoint, ktorý ste zadali, je neplatný. Zadajte platný endpoint a skúste to znova.';

  @override
  String get endpointUpdatedMessage => 'Endpoint úspešne aktualizovaný';

  @override
  String get yes => 'Yes';

  @override
  String get remove => 'Remove';

  @override
  String get addMore => 'Add more';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get legacy => 'Legacy';

  @override
  String get recoveryWarning =>
      'A trusted contact is trying to access your account';

  @override
  String recoveryWarningBody(Object email) {
    return '$email is trying to recover your account.';
  }

  @override
  String get legacyPageDesc =>
      'Legacy allows trusted contacts to access your account in your absence.';

  @override
  String get legacyPageDesc2 =>
      'Trusted contacts can initiate account recovery, and if not blocked within 30 days, reset your password and access your account.';

  @override
  String get legacyAccounts => 'Legacy accounts';

  @override
  String get trustedContacts => 'Trusted contacts';

  @override
  String get addTrustedContact => 'Add Trusted Contact';

  @override
  String get removeInvite => 'Remove invite';

  @override
  String get rejectRecovery => 'Reject recovery';

  @override
  String get recoveryInitiated => 'Recovery initiated';

  @override
  String recoveryInitiatedDesc(int days, String email) {
    return 'You can access the account after $days days. A notification will be sent to $email.';
  }

  @override
  String get removeYourselfAsTrustedContact =>
      'Remove yourself as trusted contact';

  @override
  String get declineTrustInvite => 'Decline Invite';

  @override
  String get cancelAccountRecovery => 'Cancel recovery';

  @override
  String get recoveryAccount => 'Recover account';

  @override
  String get cancelAccountRecoveryBody =>
      'Are you sure you want to cancel recovery?';

  @override
  String get startAccountRecoveryTitle => 'Start recovery';

  @override
  String get whyAddTrustContact =>
      'Trusted contact can help in recovering your data.';

  @override
  String recoveryReady(String email) {
    return 'You can now recover $email\'s account by setting a new password.';
  }

  @override
  String get warning => 'Warning';

  @override
  String get proceed => 'Proceed';

  @override
  String get done => 'Done';

  @override
  String get enterEmail => 'Enter email';

  @override
  String get verifyIDLabel => 'Verify';

  @override
  String get invalidEmailAddress => 'Invalid email address';

  @override
  String get enterValidEmail => 'Please enter a valid email address.';

  @override
  String get addANewEmail => 'Add a new email';

  @override
  String get orPickAnExistingOne => 'Or pick an existing one';

  @override
  String get shareTextRecommendUsingEnte =>
      'Download Ente so we can easily share original quality files\n\nhttps://ente.io';

  @override
  String get sendInvite => 'Send invite';

  @override
  String trustedInviteBody(Object email) {
    return 'You have been invited to be a legacy contact by $email.';
  }

  @override
  String verifyEmailID(Object email) {
    return 'Verify $email';
  }

  @override
  String get thisIsYourVerificationId => 'This is your Verification ID';

  @override
  String get someoneSharingAlbumsWithYouShouldSeeTheSameId =>
      'Someone sharing albums with you should see the same ID on their device.';

  @override
  String get howToViewShareeVerificationID =>
      'Please ask them to long-press their email address on the settings screen, and verify that the IDs on both devices match.';

  @override
  String thisIsPersonVerificationId(String email) {
    return 'This is $email\'s Verification ID';
  }

  @override
  String confirmAddingTrustedContact(String email, int numOfDays) {
    return 'You are about to add $email as a trusted contact. They will be able to recover your account if you are absent for $numOfDays days.';
  }

  @override
  String get youCannotShareWithYourself => 'You cannot share with yourself';

  @override
  String emailNoEnteAccount(Object email) {
    return '$email does not have an Ente account.\n\nSend them an invite to share files.';
  }

  @override
  String shareMyVerificationID(Object verificationID) {
    return 'Here\'s my verification ID: $verificationID for ente.io.';
  }

  @override
  String shareTextConfirmOthersVerificationID(Object verificationID) {
    return 'Hey, can you confirm that this is your ente.io verification ID: $verificationID';
  }

  @override
  String get inviteToEnte => 'Invite to Ente';
}
