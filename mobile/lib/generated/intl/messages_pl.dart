// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a pl locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'pl';

  static String m0(count) =>
      "${Intl.plural(count, zero: 'Add collaborator', one: 'Add collaborator', other: 'Add collaborators')}";

  static String m1(count) =>
      "${Intl.plural(count, zero: 'Add viewer', one: 'Add viewer', other: 'Add viewers')}";

  static String m36(passwordStrengthValue) =>
      "Siła hasła: ${passwordStrengthValue}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Witaj ponownie!"),
        "activeSessions": MessageLookupByLibrary.simpleMessage("Aktywne sesje"),
        "addCollaborators": m0,
        "addToHiddenAlbum":
            MessageLookupByLibrary.simpleMessage("Add to hidden album"),
        "addViewers": m1,
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "Jaka jest przyczyna usunięcia konta?"),
        "cancel": MessageLookupByLibrary.simpleMessage("Anuluj"),
        "changeEmail":
            MessageLookupByLibrary.simpleMessage("Zmień adres e-mail"),
        "changeLocationOfSelectedItems": MessageLookupByLibrary.simpleMessage(
            "Change location of selected items?"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Zmień hasło"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Sprawdź swoją skrzynkę odbiorczą (i spam), aby zakończyć weryfikację"),
        "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Kod został skopiowany do schowka"),
        "confirm": MessageLookupByLibrary.simpleMessage("Potwierdź"),
        "confirmAccountDeletion":
            MessageLookupByLibrary.simpleMessage("Potwierdź usunięcie konta"),
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Tak, chcę trwale usunąć konto i wszystkie dane z nim powiązane."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Powtórz hasło"),
        "contactSupport": MessageLookupByLibrary.simpleMessage(
            "Skontaktuj się z pomocą techniczną"),
        "contacts": MessageLookupByLibrary.simpleMessage("Contacts"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("Kontynuuj"),
        "createAccount": MessageLookupByLibrary.simpleMessage("Stwórz konto"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("Stwórz nowe konto"),
        "decrypting":
            MessageLookupByLibrary.simpleMessage("Odszyfrowywanie..."),
        "deleteAccount": MessageLookupByLibrary.simpleMessage("Usuń konto"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "Przykro nam, że odchodzisz. Wyjaśnij nam, dlaczego nas opuszczasz, aby pomóc ulepszać nasze usługi."),
        "deleteAccountPermanentlyButton":
            MessageLookupByLibrary.simpleMessage("Usuń konto na stałe"),
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
            "This account is linked to other ente apps, if you use any.\\n\\nYour uploaded data, across all ente apps, will be scheduled for deletion, and your account will be permanently deleted."),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "Wyślij wiadomość e-mail na <warning>account-deletion@ente.io</warning> z zarejestrowanego adresu e-mail."),
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "Brakuje kluczowej funkcji, której potrzebuję"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "Aplikacja lub określona funkcja nie zachowuje się tak, jak sądzę, że powinna"),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
            "Znalazłem inną, lepszą usługę"),
        "deleteReason4": MessageLookupByLibrary.simpleMessage(
            "Inna, niewymieniona wyżej przyczyna"),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
            "Twoje żądanie zostanie przetworzone w ciągu 72 godzin."),
        "descriptions": MessageLookupByLibrary.simpleMessage("Descriptions"),
        "doThisLater": MessageLookupByLibrary.simpleMessage("Spróbuj później"),
        "editLocation": MessageLookupByLibrary.simpleMessage("Edit location"),
        "editsToLocationWillOnlyBeSeenWithinEnte":
            MessageLookupByLibrary.simpleMessage(
                "Edits to location will only be seen within Ente"),
        "email": MessageLookupByLibrary.simpleMessage("Adres e-mail"),
        "encryption": MessageLookupByLibrary.simpleMessage("Szyfrowanie"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Wprowadź kod"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Wprowadź nowe hasło, którego możemy użyć do zaszyfrowania Twoich danych"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Wprowadź hasło, którego możemy użyć do zaszyfrowania Twoich danych"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "Podaj poprawny adres e-mail."),
        "enterYourEmailAddress":
            MessageLookupByLibrary.simpleMessage("Podaj swój adres e-mail"),
        "enterYourPassword":
            MessageLookupByLibrary.simpleMessage("Wprowadź hasło"),
        "enterYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Wprowadź swój klucz odzyskiwania"),
        "feedback": MessageLookupByLibrary.simpleMessage("Informacja zwrotna"),
        "fileTypes": MessageLookupByLibrary.simpleMessage("File types"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Nie pamiętam hasła"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Generowanie kluczy szyfrujących..."),
        "howItWorks": MessageLookupByLibrary.simpleMessage("Jak to działa"),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Nieprawidłowe hasło"),
        "incorrectRecoveryKeyBody":
            MessageLookupByLibrary.simpleMessage("Kod jest nieprawidłowy"),
        "incorrectRecoveryKeyTitle": MessageLookupByLibrary.simpleMessage(
            "Nieprawidłowy klucz odzyskiwania"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("Nieprawidłowy adres e-mail"),
        "joinDiscord": MessageLookupByLibrary.simpleMessage("Join Discord"),
        "kindlyHelpUsWithThisInformation":
            MessageLookupByLibrary.simpleMessage("Pomóż nam z tą informacją"),
        "locations": MessageLookupByLibrary.simpleMessage("Locations"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Zaloguj się"),
        "longPressAnEmailToVerifyEndToEndEncryption":
            MessageLookupByLibrary.simpleMessage(
                "Long press an email to verify end to end encryption."),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Umiarkowana"),
        "modifyYourQueryOrTrySearchingFor":
            MessageLookupByLibrary.simpleMessage(
                "Modify your query, or try searching for"),
        "moveToHiddenAlbum":
            MessageLookupByLibrary.simpleMessage("Move to hidden album"),
        "noRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Brak klucza odzyskiwania?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "Ze względu na charakter naszego protokołu szyfrowania end-to-end, dane nie mogą być odszyfrowane bez hasła lub klucza odzyskiwania"),
        "ok": MessageLookupByLibrary.simpleMessage("Ok"),
        "oops": MessageLookupByLibrary.simpleMessage("Ups"),
        "password": MessageLookupByLibrary.simpleMessage("Hasło"),
        "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
            "Hasło zostało pomyślnie zmienione"),
        "passwordStrength": m36,
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Nie przechowujemy tego hasła, więc jeśli go zapomnisz, <underline>nie będziemy w stanie odszyfrować Twoich danych</underline>"),
        "pleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("Spróbuj ponownie"),
        "pleaseWait": MessageLookupByLibrary.simpleMessage("Proszę czekać..."),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Polityka prywatności"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("Odzyskaj konto"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Odzyskaj"),
        "recoveryKey":
            MessageLookupByLibrary.simpleMessage("Klucz odzyskiwania"),
        "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Klucz odzyskiwania został skopiowany do schowka"),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
            "Jeśli zapomnisz hasła, jedynym sposobem odzyskania danych jest ten klucz."),
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("Odzyskano pomyślnie!"),
        "resendEmail":
            MessageLookupByLibrary.simpleMessage("Wyślij e-mail ponownie"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Zresetuj hasło"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Zapisz klucz"),
        "selectALocation":
            MessageLookupByLibrary.simpleMessage("Select a location"),
        "selectALocationFirst":
            MessageLookupByLibrary.simpleMessage("Select a location first"),
        "selectReason": MessageLookupByLibrary.simpleMessage("Wybierz powód"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("Wyślij e-mail"),
        "setPasswordTitle": MessageLookupByLibrary.simpleMessage("Ustaw hasło"),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "Akceptuję <u-terms>warunki korzystania z usługi</u-terms> i <u-policy>politykę prywatności</u-policy>"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Coś poszło nie tak, spróbuj ponownie"),
        "sorry": MessageLookupByLibrary.simpleMessage("Przepraszamy"),
        "strongStrength": MessageLookupByLibrary.simpleMessage("Silne"),
        "terminate": MessageLookupByLibrary.simpleMessage("Zakończ"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Zakończyć sesję?"),
        "termsOfServicesTitle":
            MessageLookupByLibrary.simpleMessage("Regulamin"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("To urządzenie"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "To wyloguje Cię z tego urządzenia:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "To wyloguje Cię z tego urządzenia!"),
        "tryAgain": MessageLookupByLibrary.simpleMessage("Spróbuj ponownie"),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage(
                "Uwierzytelnianie dwuskładnikowe"),
        "twofactorSetup": MessageLookupByLibrary.simpleMessage(
            "Uwierzytelnianie dwuskładnikowe"),
        "useRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Użyj kodu odzyskiwania"),
        "verify": MessageLookupByLibrary.simpleMessage("Weryfikuj"),
        "verifyEmail":
            MessageLookupByLibrary.simpleMessage("Zweryfikuj adres e-mail"),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Zweryfikuj hasło"),
        "weakStrength": MessageLookupByLibrary.simpleMessage("Słabe"),
        "welcomeBack": MessageLookupByLibrary.simpleMessage("Witaj ponownie!"),
        "yourAccountHasBeenDeleted": MessageLookupByLibrary.simpleMessage(
            "Twoje konto zostało usunięte"),
        "yourMap": MessageLookupByLibrary.simpleMessage("Your map")
      };
}
