// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class StringsLocalizationsPl extends StringsLocalizations {
  StringsLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get networkHostLookUpErr =>
      'Nie można połączyć się z Ente, sprawdź ustawienia sieci i skontaktuj się z pomocą techniczną, jeśli błąd będzie się powtarzał.';

  @override
  String get networkConnectionRefusedErr =>
      'Nie można połączyć się z Ente, spróbuj ponownie po pewnym czasie. Jeśli błąd będzie się powtarzał, skontaktuj się z pomocą techniczną.';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      'Wygląda na to, że coś poszło nie tak. Spróbuj ponownie po pewnym czasie. Jeśli błąd będzie się powtarzał, skontaktuj się z naszym zespołem pomocy technicznej.';

  @override
  String get error => 'Błąd';

  @override
  String get ok => 'Ok';

  @override
  String get faq => 'Najczęściej zadawane pytania (FAQ)';

  @override
  String get contactSupport => 'Skontaktuj się z pomocą techniczną';

  @override
  String get emailYourLogs => 'Wyślij mailem logi';

  @override
  String pleaseSendTheLogsTo(String toEmail) {
    return 'Prosimy wysłać logi do $toEmail';
  }

  @override
  String get copyEmailAddress => 'Kopiuj adres e-mail';

  @override
  String get exportLogs => 'Eksportuj logi';

  @override
  String get cancel => 'Anuluj';

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
  String get reportABug => 'Zgłoś błąd';

  @override
  String get logsDialogBody =>
      'This will send across logs to help us debug your issue. Please note that file names will be included to help track issues with specific files.';

  @override
  String get viewLogs => 'View logs';

  @override
  String customEndpoint(String endpoint) {
    return 'Połączono z $endpoint';
  }

  @override
  String get save => 'Zapisz';

  @override
  String get send => 'Wyślij';

  @override
  String get saveOrSendDescription =>
      'Czy chcesz zapisać to do swojej pamięci masowej (domyślnie folder Pobrane) czy wysłać to do innych aplikacji?';

  @override
  String get saveOnlyDescription =>
      'Czy chcesz zapisać to do swojej pamięci masowej (domyślnie folder Pobrane)?';

  @override
  String get enterNewEmailHint => 'Wprowadź nowy adres e-mail';

  @override
  String get email => 'Email';

  @override
  String get verify => 'Zweryfikuj';

  @override
  String get invalidEmailTitle => 'Nieprawidłowy adres e-mail';

  @override
  String get invalidEmailMessage => 'Prosimy podać prawidłowy adres e-mail.';

  @override
  String get pleaseWait => 'Prosimy czekać...';

  @override
  String get verifyPassword => 'Zweryfikuj hasło';

  @override
  String get incorrectPasswordTitle => 'Nieprawidłowe hasło';

  @override
  String get pleaseTryAgain => 'Prosimy spróbować ponownie';

  @override
  String get enterPassword => 'Wprowadź hasło';

  @override
  String get enterYourPasswordHint => 'Wprowadź swoje hasło';

  @override
  String get activeSessions => 'Aktywne sesje';

  @override
  String get oops => 'Ups';

  @override
  String get somethingWentWrongPleaseTryAgain =>
      'Coś poszło nie tak, spróbuj ponownie';

  @override
  String get thisWillLogYouOutOfThisDevice =>
      'To wyloguje Cię z tego urządzenia!';

  @override
  String get thisWillLogYouOutOfTheFollowingDevice =>
      'To wyloguje Cię z tego urządzenia:';

  @override
  String get terminateSession => 'Zakończyć sesję?';

  @override
  String get terminate => 'Zakończ';

  @override
  String get thisDevice => 'To urządzenie';

  @override
  String get createAccount => 'Utwórz konto';

  @override
  String get weakStrength => 'Słabe';

  @override
  String get moderateStrength => 'Umiarkowane';

  @override
  String get strongStrength => 'Silne';

  @override
  String get deleteAccount => 'Usuń konto';

  @override
  String get deleteAccountQuery =>
      'Będzie nam przykro, że odchodzisz. Masz jakiś problem?';

  @override
  String get yesSendFeedbackAction => 'Tak, wyślij opinię';

  @override
  String get noDeleteAccountAction => 'Nie, usuń moje konto';

  @override
  String get initiateAccountDeleteTitle =>
      'Prosimy uwierzytelnić się, aby zainicjować usuwanie konta';

  @override
  String get confirmAccountDeleteTitle => 'Potwierdź usunięcie konta';

  @override
  String get confirmAccountDeleteMessage =>
      'To konto jest połączone z innymi aplikacjami Ente, jeśli ich używasz.\n\nTwoje przesłane dane, we wszystkich aplikacjach Ente, zostaną zaplanowane do usunięcia, a Twoje konto zostanie trwale usunięte.';

  @override
  String get delete => 'Usuń';

  @override
  String get createNewAccount => 'Utwórz nowe konto';

  @override
  String get password => 'Hasło';

  @override
  String get confirmPassword => 'Potwierdź hasło';

  @override
  String passwordStrength(String passwordStrengthValue) {
    return 'Siła hasła: $passwordStrengthValue';
  }

  @override
  String get hearUsWhereTitle => 'Jak usłyszałeś/aś o Ente? (opcjonalnie)';

  @override
  String get hearUsExplanation =>
      'Nie śledzimy instalacji aplikacji. Pomogłyby nam, gdybyś powiedział/a nam, gdzie nas znalazłeś/aś!';

  @override
  String get signUpTerms =>
      'Akceptuję <u-terms>warunki korzystania z usługi</u-terms> i <u-policy>politykę prywatności</u-policy>';

  @override
  String get termsOfServicesTitle => 'Regulamin';

  @override
  String get privacyPolicyTitle => 'Polityka prywatności';

  @override
  String get ackPasswordLostWarning =>
      'Rozumiem, że jeśli utracę hasło, mogę stracić moje dane, ponieważ moje dane są <underline>szyfrowane end-to-end</underline>.';

  @override
  String get encryption => 'Szyfrowanie';

  @override
  String get logInLabel => 'Zaloguj się';

  @override
  String get welcomeBack => 'Witaj ponownie!';

  @override
  String get loginTerms =>
      'Klikając, zaloguj się, zgadzam się na <u-terms>regulamin</u-terms> i <u-policy>politykę prywatności</u-policy>';

  @override
  String get noInternetConnection => 'Brak połączenia z Internetem';

  @override
  String get pleaseCheckYourInternetConnectionAndTryAgain =>
      'Prosimy sprawdzić połączenie internetowe i spróbować ponownie.';

  @override
  String get verificationFailedPleaseTryAgain =>
      'Weryfikacja nie powiodła się, spróbuj ponownie';

  @override
  String get recreatePasswordTitle => 'Zresetuj hasło';

  @override
  String get recreatePasswordBody =>
      'Obecne urządzenie nie jest wystarczająco wydajne, aby zweryfikować Twoje hasło, więc musimy je raz zregenerować w sposób, który działa ze wszystkimi urządzeniami. \n\nZaloguj się przy użyciu klucza odzyskiwania i zresetuj swoje hasło (możesz ponownie użyć tego samego, jeśli chcesz).';

  @override
  String get useRecoveryKey => 'Użyj kodu odzyskiwania';

  @override
  String get forgotPassword => 'Nie pamiętam hasła';

  @override
  String get changeEmail => 'Zmień adres e-mail';

  @override
  String get verifyEmail => 'Zweryfikuj adres e-mail';

  @override
  String weHaveSendEmailTo(String email) {
    return 'Wysłaliśmy wiadomość do <green>$email</green>';
  }

  @override
  String get toResetVerifyEmail =>
      'Aby zresetować hasło, najpierw zweryfikuj swój e-mail.';

  @override
  String get checkInboxAndSpamFolder =>
      'Sprawdź swoją skrzynkę odbiorczą (i spam), aby zakończyć weryfikację';

  @override
  String get tapToEnterCode => 'Dotknij, aby wprowadzić kod';

  @override
  String get sendEmail => 'Wyślij e-mail';

  @override
  String get resendEmail => 'Wyślij e-mail ponownie';

  @override
  String get passKeyPendingVerification => 'Weryfikacja jest nadal w toku';

  @override
  String get loginSessionExpired => 'Sesja wygasła';

  @override
  String get loginSessionExpiredDetails =>
      'Twoja sesja wygasła. Zaloguj się ponownie.';

  @override
  String get passkeyAuthTitle => 'Weryfikacja kluczem dostępu';

  @override
  String get waitingForVerification => 'Oczekiwanie na weryfikację...';

  @override
  String get tryAgain => 'Spróbuj ponownie';

  @override
  String get checkStatus => 'Sprawdź stan';

  @override
  String get loginWithTOTP => 'Zaloguj się za pomocą TOTP';

  @override
  String get recoverAccount => 'Odzyskaj konto';

  @override
  String get setPasswordTitle => 'Ustaw hasło';

  @override
  String get changePasswordTitle => 'Zmień hasło';

  @override
  String get resetPasswordTitle => 'Zresetuj hasło';

  @override
  String get encryptionKeys => 'Klucz szyfrowania';

  @override
  String get enterPasswordToEncrypt =>
      'Wprowadź hasło, którego możemy użyć do zaszyfrowania Twoich danych';

  @override
  String get enterNewPasswordToEncrypt =>
      'Wprowadź nowe hasło, którego możemy użyć do zaszyfrowania Twoich danych';

  @override
  String get passwordWarning =>
      'Nie przechowujemy tego hasła, więc jeśli go zapomnisz, <underline>nie będziemy w stanie odszyfrować Twoich danych</underline>';

  @override
  String get howItWorks => 'Jak to działa';

  @override
  String get generatingEncryptionKeys => 'Generowanie kluczy szyfrujących...';

  @override
  String get passwordChangedSuccessfully => 'Hasło zostało pomyślnie zmienione';

  @override
  String get signOutFromOtherDevices => 'Wyloguj z pozostałych urządzeń';

  @override
  String get signOutOtherBody =>
      'Jeśli uważasz, że ktoś może znać Twoje hasło, możesz wymusić wylogowanie na wszystkich innych urządzeniach korzystających z Twojego konta.';

  @override
  String get signOutOtherDevices => 'Wyloguj z pozostałych urządzeń';

  @override
  String get doNotSignOut => 'Nie wylogowuj mnie';

  @override
  String get generatingEncryptionKeysTitle =>
      'Generowanie kluczy szyfrujących...';

  @override
  String get continueLabel => 'Kontynuuj';

  @override
  String get insecureDevice => 'Niezabezpieczone urządzenie';

  @override
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease =>
      'Przepraszamy, nie mogliśmy wygenerować kluczy bezpiecznych na tym urządzeniu.\n\nZarejestruj się z innego urządzenia.';

  @override
  String get recoveryKeyCopiedToClipboard =>
      'Klucz odzyskiwania został skopiowany do schowka';

  @override
  String get recoveryKey => 'Klucz odzyskiwania';

  @override
  String get recoveryKeyOnForgotPassword =>
      'Jeśli zapomnisz hasła, jedynym sposobem na odzyskanie danych jest ten klucz.';

  @override
  String get recoveryKeySaveDescription =>
      'Nie przechowujemy tego klucza, prosimy zachować ten 24-słowny klucz w bezpiecznym miejscu.';

  @override
  String get doThisLater => 'Zrób to później';

  @override
  String get saveKey => 'Zapisz klucz';

  @override
  String get recoveryKeySaved =>
      'Klucz odzyskiwania zapisany w folderze Pobrane!';

  @override
  String get noRecoveryKeyTitle => 'Brak klucza odzyskiwania?';

  @override
  String get twoFactorAuthTitle => 'Uwierzytelnianie dwustopniowe';

  @override
  String get enterCodeHint =>
      'Wprowadź sześciocyfrowy kod z \nTwojej aplikacji uwierzytelniającej';

  @override
  String get lostDeviceTitle => 'Zagubiono urządzenie?';

  @override
  String get enterRecoveryKeyHint => 'Wprowadź swój klucz odzyskiwania';

  @override
  String get recover => 'Odzyskaj';

  @override
  String get loggingOut => 'Wylogowywanie...';

  @override
  String get immediately => 'Natychmiast';

  @override
  String get appLock => 'Blokada aplikacji';

  @override
  String get autoLock => 'Automatyczna blokada';

  @override
  String get noSystemLockFound => 'Nie znaleziono blokady systemowej';

  @override
  String get deviceLockEnablePreSteps =>
      'Aby włączyć blokadę aplikacji, należy skonfigurować hasło urządzenia lub blokadę ekranu w ustawieniach Twojego systemu.';

  @override
  String get appLockDescription =>
      'Wybierz między domyślnym ekranem blokady urządzenia a niestandardowym ekranem blokady z kodem PIN lub hasłem.';

  @override
  String get deviceLock => 'Blokada urządzenia';

  @override
  String get pinLock => 'Blokada PIN';

  @override
  String get autoLockFeatureDescription =>
      'Czas, po którym aplikacja blokuje się po umieszczeniu jej w tle';

  @override
  String get hideContent => 'Ukryj zawartość';

  @override
  String get hideContentDescriptionAndroid =>
      'Ukrywa zawartość aplikacji w przełączniku aplikacji i wyłącza zrzuty ekranu';

  @override
  String get hideContentDescriptioniOS =>
      'Ukrywa zawartość aplikacji w przełączniku aplikacji';

  @override
  String get tooManyIncorrectAttempts => 'Zbyt wiele błędnych prób';

  @override
  String get tapToUnlock => 'Naciśnij, aby odblokować';

  @override
  String get areYouSureYouWantToLogout => 'Czy na pewno chcesz się wylogować?';

  @override
  String get yesLogout => 'Tak, wyloguj';

  @override
  String get authToViewSecrets =>
      'Prosimy uwierzytelnić się, aby wyświetlić swoje sekrety';

  @override
  String get next => 'Dalej';

  @override
  String get setNewPassword => 'Ustaw nowe hasło';

  @override
  String get enterPin => 'Wprowadź kod PIN';

  @override
  String get setNewPin => 'Ustaw nowy kod PIN';

  @override
  String get confirm => 'Potwierdź';

  @override
  String get reEnterPassword => 'Wprowadź ponownie hasło';

  @override
  String get reEnterPin => 'Wprowadź ponownie kod PIN';

  @override
  String get androidBiometricHint => 'Potwierdź swoją tożsamość';

  @override
  String get androidBiometricNotRecognized =>
      'Nie rozpoznano. Spróbuj ponownie.';

  @override
  String get androidBiometricSuccess => 'Sukces';

  @override
  String get androidCancelButton => 'Anuluj';

  @override
  String get androidSignInTitle => 'Wymagana autoryzacja';

  @override
  String get androidBiometricRequiredTitle => 'Wymagana biometria';

  @override
  String get androidDeviceCredentialsRequiredTitle =>
      'Wymagane dane logowania urządzenia';

  @override
  String get androidDeviceCredentialsSetupDescription =>
      'Wymagane dane logowania urządzenia';

  @override
  String get goToSettings => 'Przejdź do ustawień';

  @override
  String get androidGoToSettingsDescription =>
      'Uwierzytelnianie biometryczne nie jest skonfigurowane na tym urządzeniu. Przejdź do \'Ustawienia > Bezpieczeństwo\', aby dodać uwierzytelnianie biometryczne.';

  @override
  String get iOSLockOut =>
      'Uwierzytelnianie biometryczne jest wyłączone. Prosimy zablokować i odblokować ekran, aby je włączyć.';

  @override
  String get iOSOkButton => 'OK';

  @override
  String get emailAlreadyRegistered => 'Adres e-mail jest już zarejestrowany.';

  @override
  String get emailNotRegistered => 'Adres e-mail nie jest zarejestrowany.';

  @override
  String get thisEmailIsAlreadyInUse => 'Ten adres e-mail już jest zajęty';

  @override
  String emailChangedTo(String newEmail) {
    return 'Adres e-mail został zmieniony na $newEmail';
  }

  @override
  String get authenticationFailedPleaseTryAgain =>
      'Uwierzytelnianie nie powiodło się, prosimy spróbować ponownie';

  @override
  String get authenticationSuccessful => 'Uwierzytelnianie powiodło się!';

  @override
  String get sessionExpired => 'Sesja wygasła';

  @override
  String get incorrectRecoveryKey => 'Nieprawidłowy klucz odzyskiwania';

  @override
  String get theRecoveryKeyYouEnteredIsIncorrect =>
      'Wprowadzony klucz odzyskiwania jest nieprawidłowy';

  @override
  String get twofactorAuthenticationSuccessfullyReset =>
      'Pomyślnie zresetowano uwierzytelnianie dwustopniowe';

  @override
  String get noRecoveryKey => 'No recovery key';

  @override
  String get yourAccountHasBeenDeleted => 'Your account has been deleted';

  @override
  String get verificationId => 'Verification ID';

  @override
  String get yourVerificationCodeHasExpired => 'Twój kod weryfikacyjny wygasł';

  @override
  String get incorrectCode => 'Nieprawidłowy kod';

  @override
  String get sorryTheCodeYouveEnteredIsIncorrect =>
      'Niestety, wprowadzony kod jest nieprawidłowy';

  @override
  String get developerSettings => 'Ustawienia dla programistów';

  @override
  String get serverEndpoint => 'Punkt końcowy serwera';

  @override
  String get invalidEndpoint => 'Punkt końcowy jest nieprawidłowy';

  @override
  String get invalidEndpointMessage =>
      'Niestety, wprowadzony punkt końcowy jest nieprawidłowy. Wprowadź prawidłowy punkt końcowy i spróbuj ponownie.';

  @override
  String get endpointUpdatedMessage => 'Punkt końcowy zaktualizowany pomyślnie';
}
