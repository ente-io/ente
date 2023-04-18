// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a de locale. All the
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
  String get localeName => 'de';

  static String m0(supportEmail) =>
      "Bitte sende eine E-Mail an ${supportEmail} von deiner registrierten E-Mail-Adresse";

  static String m1(email) =>
      "${email} hat kein Ente-Konto.\n\nSenden Sie eine Einladung, um Fotos zu teilen.";

  static String m2(storageAmountInGB) =>
      "${storageAmountInGB} GB jedes Mal, wenn sich jemand mit deinem Code für einen bezahlten Tarif anmeldet";

  static String m3(passwordStrengthValue) =>
      "Passwortstärke: ${passwordStrengthValue}";

  static String m4(storageInGB) =>
      "3. Ihr beide erhaltet ${storageInGB} GB* kostenlos";

  static String m5(verificationID) =>
      "Hier ist meine Verifizierungs-ID: ${verificationID} für ente.io.";

  static String m6(verificationID) =>
      "Hey, kannst du bestätigen, dass dies deine ente.io Verifizierungs-ID ist: ${verificationID}";

  static String m7(referralCode, referralStorageInGB) =>
      "ente Empfehlungs-Code: ${referralCode} \n\nEinlösen unter Einstellungen → Allgemein → Einladung, um ${referralStorageInGB} GB kostenlos zu erhalten, sobald Sie einen kostenpflichtigen Tarif abgeschlossen haben\n\nhttps://ente.io";

  static String m8(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Teile mit bestimmten Personen', one: 'Teilen mit 1 Person', other: 'Teilen mit ${numberOfPeople} Personen')}";

  static String m9(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m10(storageAmountInGB) =>
      "Diese erhalten auch ${storageAmountInGB} GB";

  static String m11(email) => "Dies ist ${email}s Verifizierungs-ID";

  static String m12(email) => "Verifiziere ${email}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Willkommen zurück!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Ich verstehe, dass ich meine Daten verlieren kann, wenn ich mein Passwort vergesse, da meine Daten <underline>Ende-zu-Ende-verschlüsselt</underline> sind."),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Aktive Sitzungen"),
        "after1Month": MessageLookupByLibrary.simpleMessage("Nach 1 Monat"),
        "after1Week": MessageLookupByLibrary.simpleMessage("Nach 1 Woche"),
        "after1Year": MessageLookupByLibrary.simpleMessage("Nach 1 Jahr"),
        "apply": MessageLookupByLibrary.simpleMessage("Anwenden"),
        "applyCodeTitle": MessageLookupByLibrary.simpleMessage("Code nutzen"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "Was ist der Hauptgrund für die Löschung deines Kontos?"),
        "cancel": MessageLookupByLibrary.simpleMessage("Abbrechen"),
        "changeEmail":
            MessageLookupByLibrary.simpleMessage("E-Mail-Adresse ändern"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Passwort ändern"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Bitte überprüfe deinen E-Mail-Posteingang (und Spam), um die Verifizierung abzuschließen"),
        "claimFreeStorage":
            MessageLookupByLibrary.simpleMessage("Freien Speicher einlösen"),
        "claimMore": MessageLookupByLibrary.simpleMessage("Mehr einlösen!"),
        "claimed": MessageLookupByLibrary.simpleMessage("Eingelöst"),
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("Code eingelöst"),
        "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Code in Zwischenablage kopiert"),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Erstelle einen Link, um anderen zu ermöglichen, Fotos in deinem geteilten Album hinzuzufügen und zu sehen - ohne dass diese ein Konto von ente.io oder die App benötigen. Ideal, um Fotos von Events zu sammeln."),
        "collaborativeLink":
            MessageLookupByLibrary.simpleMessage("Gemeinschaftlicher Link"),
        "collectPhotos": MessageLookupByLibrary.simpleMessage("Fotos sammeln"),
        "confirm": MessageLookupByLibrary.simpleMessage("Bestätigen"),
        "confirmAccountDeletion":
            MessageLookupByLibrary.simpleMessage("Kontolöschung bestätigen"),
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Ja, ich möchte dieses Konto und alle enthaltenen Daten endgültig und unwiderruflich löschen."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Passwort wiederholen"),
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("Support kontaktieren"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("Weiter"),
        "copyLink": MessageLookupByLibrary.simpleMessage("Link kopieren"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Kopiere diesen Code\nin deine Authentifizierungs-App"),
        "createAccount":
            MessageLookupByLibrary.simpleMessage("Konto erstellen"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("Neues Konto erstellen"),
        "createPublicLink":
            MessageLookupByLibrary.simpleMessage("Öffentlichen Link erstellen"),
        "decrypting":
            MessageLookupByLibrary.simpleMessage("Wird entschlüsselt..."),
        "deleteAccount": MessageLookupByLibrary.simpleMessage("Konto löschen"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "Wir bedauern sehr, dass Du Dein Konto löschen möchtest. Du würdest uns sehr helfen, wenn Du uns kurz einige Gründe hierfür nennen könntest."),
        "deleteAccountPermanentlyButton": MessageLookupByLibrary.simpleMessage(
            "Konto unwiderruflich löschen"),
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
            "Du bist dabei, dein Konto und alle gespeicherten Daten dauerhaft zu löschen.\nDiese Aktion ist unwiderrufbar."),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "Bitte sende eine E-Mail an <warning>account-deletion@ente.io</warning> von Deiner bei uns hinterlegten E-Mail-Adresse."),
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "Es fehlt eine zentrale Funktion, die ich benötige"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "Die App oder eine bestimmte Funktion verhält sich nicht so wie gedacht"),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
            "Ich habe einen anderen Dienst gefunden, der mir mehr zusagt"),
        "deleteReason4": MessageLookupByLibrary.simpleMessage(
            "Mein Grund ist nicht aufgeführt"),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
            "Deine Anfrage wird innerhalb von 72 Stunden bearbeitet."),
        "details": MessageLookupByLibrary.simpleMessage("Details"),
        "doThisLater": MessageLookupByLibrary.simpleMessage("Später machen"),
        "done": MessageLookupByLibrary.simpleMessage("Fertig"),
        "dropSupportEmail": m0,
        "email": MessageLookupByLibrary.simpleMessage("E-Mail"),
        "emailNoEnteAccount": m1,
        "encryption": MessageLookupByLibrary.simpleMessage("Verschlüsselung"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Verschlüsselungscode"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Code eingeben"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
            "Gib den Code deines Freundes ein, damit sie beide kostenlosen Speicherplatz erhalten"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Gib ein neues Passwort ein, mit dem wir deine Daten verschlüsseln können"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Gib ein Passwort ein, mit dem wir deine Daten verschlüsseln können"),
        "enterReferralCode":
            MessageLookupByLibrary.simpleMessage("Gib den Einladungscode ein"),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Gib den 6-stelligen Code aus\ndeiner Authentifizierungs-App ein"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "Bitte gib eine gültige E-Mail-Adresse ein."),
        "enterYourEmailAddress": MessageLookupByLibrary.simpleMessage(
            "Gib deine E-Mail-Adresse ein"),
        "enterYourPassword":
            MessageLookupByLibrary.simpleMessage("Passwort eingeben"),
        "enterYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Gib deinen Wiederherstellungs-Schlüssel ein"),
        "failedToApplyCode": MessageLookupByLibrary.simpleMessage(
            "Der Code konnte nicht aktiviert werden"),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "Die Einlösungsdetails können nicht abgerufen werden. Bitte versuche es später erneut."),
        "feedback": MessageLookupByLibrary.simpleMessage("Rückmeldung"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Passwort vergessen"),
        "freeStorageOnReferralSuccess": m2,
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Generierung von Verschlüsselungscodes..."),
        "howItWorks":
            MessageLookupByLibrary.simpleMessage("So funktioniert\'s"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "Bitte sie, auf den Einstellungs Bildschirm ihre E-Mail-Adresse lange anzuklicken und zu überprüfen, dass die IDs auf beiden Geräten übereinstimmen."),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Falsches Passwort"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "Der eingegebene Schlüssel ist ungültig"),
        "incorrectRecoveryKeyTitle": MessageLookupByLibrary.simpleMessage(
            "Falscher Wiederherstellungs-Schlüssel"),
        "insecureDevice":
            MessageLookupByLibrary.simpleMessage("Unsicheres Gerät"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("Ungültige E-Mail Adresse"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Lade deine Freunde ein"),
        "kindlyHelpUsWithThisInformation":
            MessageLookupByLibrary.simpleMessage("Bitte gib diese Daten ein"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("Link ist abgelaufen"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Anmelden"),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "Mit dem Klick auf \"Anmelden\" stimme ich den <u-terms>Nutzungsbedingungen</u-terms> und der <u-policy>Datenschutzerklärung</u-policy> zu"),
        "lostDevice": MessageLookupByLibrary.simpleMessage("Gerät verloren?"),
        "manageParticipants": MessageLookupByLibrary.simpleMessage("Verwalten"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Mittel"),
        "noRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Kein Wiederherstellungs-Schlüssel?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "Aufgrund unseres Ende-zu-Ende-Verschlüsselungsprotokolls können deine Daten nicht ohne dein Passwort oder deinen Wiederherstellungs-Schlüssel entschlüsselt werden"),
        "ok": MessageLookupByLibrary.simpleMessage("Ok"),
        "oops": MessageLookupByLibrary.simpleMessage("Hoppla"),
        "password": MessageLookupByLibrary.simpleMessage("Passwort"),
        "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
            "Passwort erfolgreich geändert"),
        "passwordStrength": m3,
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Wir speichern dieses Passwort nicht. Wenn du es vergisst, <underline>können wir deine Daten nicht entschlüsseln</underline>"),
        "pleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("Bitte versuche es erneut"),
        "pleaseWait": MessageLookupByLibrary.simpleMessage("Bitte warten..."),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Datenschutzerklärung"),
        "publicLinkEnabled":
            MessageLookupByLibrary.simpleMessage("Öffentlicher Link aktiviert"),
        "recover": MessageLookupByLibrary.simpleMessage("Wiederherstellen"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("Konto wiederherstellen"),
        "recoverButton":
            MessageLookupByLibrary.simpleMessage("Wiederherstellen"),
        "recoveryKey": MessageLookupByLibrary.simpleMessage(
            "Wiederherstellungs-Schlüssel"),
        "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Wiederherstellungs-Schlüssel in die Zwischenablage kopiert"),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
            "Falls du dein Passwort vergisst, kannst du deine Daten allein mit diesem Schlüssel wiederherstellen."),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
            "Wir speichern diesen Schlüssel nicht. Bitte speichere diese Schlüssel aus 24 Wörtern an einem sicheren Ort."),
        "recoveryKeyVerified": MessageLookupByLibrary.simpleMessage(
            "Wiederherstellungs-Schlüssel überprüft"),
        "recoverySuccessful": MessageLookupByLibrary.simpleMessage(
            "Wiederherstellung erfolgreich!"),
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "Das aktuelle Gerät ist nicht leistungsfähig genug, um dein Passwort zu verifizieren, aber wir können es neu erstellen, damit es auf allen Geräten funktioniert.\n\nBitte melde dich mit deinem Wiederherstellungs-Schlüssel an und erstelle dein Passwort neu (Wenn du willst, kannst du dasselbe erneut verwenden)."),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Passwort wiederherstellen"),
        "referralStep1": MessageLookupByLibrary.simpleMessage(
            "1. Gib diesen Code an deine Freunde"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "2. Sie schließen einen bezahlten Tarif ab"),
        "referralStep3": m4,
        "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
            "Einlösungen sind derzeit pausiert"),
        "resendEmail":
            MessageLookupByLibrary.simpleMessage("E-Mail erneut senden"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Passwort zurücksetzen"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Schlüssel speichern"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Sichere deinen Wiederherstellungs-Schlüssel, falls noch nicht geschehen"),
        "scanCode": MessageLookupByLibrary.simpleMessage("Code scannen"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Scanne diesen Code mit \ndeiner Authentifizierungs-App"),
        "selectReason": MessageLookupByLibrary.simpleMessage("Grund auswählen"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("E-Mail senden"),
        "sendInvite": MessageLookupByLibrary.simpleMessage("Einladung senden"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Link senden"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Passwort festlegen"),
        "setupComplete":
            MessageLookupByLibrary.simpleMessage("Einrichtung abgeschlossen"),
        "shareALink": MessageLookupByLibrary.simpleMessage("Einen Link teilen"),
        "shareMyVerificationID": m5,
        "shareTextConfirmOthersVerificationID": m6,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Lade ente herunter, damit wir einfach Fotos und Videos in höchster Qualität teilen können\n\nhttps://ente.io/#download"),
        "shareTextReferralCode": m7,
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
            "Mit Nicht-Ente-Benutzern teilen"),
        "shareWithPeopleSectionTitle": m8,
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Erstelle gemeinsame Alben mit anderen ente Benutzern, einschließlich solchen im kostenlosen Tarif."),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "Ich stimme den <u-terms>Nutzungsbedingungen</u-terms> und der <u-policy>Datenschutzerklärung</u-policy> zu"),
        "someoneSharingAlbumsWithYouShouldSeeTheSameId":
            MessageLookupByLibrary.simpleMessage(
                "Jemand, der Alben mit dir teilt, sollte die gleiche ID auf seinem Gerät sehen."),
        "somethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Irgendetwas ging schief"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Ein Fehler ist aufgetreten, bitte versuche es erneut"),
        "sorry": MessageLookupByLibrary.simpleMessage("Entschuldigung"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "Es tut uns leid, wir konnten keine sicheren Schlüssel auf diesem Gerät generieren.\n\nBitte starte die Registrierung auf einem anderen Gerät."),
        "storageInGB": m9,
        "strongStrength": MessageLookupByLibrary.simpleMessage("Stark"),
        "tapToCopy":
            MessageLookupByLibrary.simpleMessage("zum Kopieren antippen"),
        "tapToEnterCode": MessageLookupByLibrary.simpleMessage(
            "Antippen, um den Code einzugeben"),
        "terminate": MessageLookupByLibrary.simpleMessage("Beenden"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Sitzungen beenden?"),
        "termsOfServicesTitle":
            MessageLookupByLibrary.simpleMessage("Nutzungsbedingungen"),
        "theyAlsoGetXGb": m10,
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "Dies kann verwendet werden, um dein Konto wiederherzustellen, wenn du deinen zweiten Faktor verlierst"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Dieses Gerät"),
        "thisIsPersonVerificationId": m11,
        "thisIsYourVerificationId": MessageLookupByLibrary.simpleMessage(
            "Dies ist deine Verifizierungs-ID"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Dadurch wirst du von folgendem Gerät abgemeldet:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Dadurch wirst du von diesem Gerät abgemeldet!"),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage(
                "Zwei-Faktor-Authentifizierung"),
        "twofactorSetup": MessageLookupByLibrary.simpleMessage(
            "Zweiten Faktor (2FA) einrichten"),
        "useRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Wiederherstellungs-Schlüssel verwenden"),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("Verifizierungs-ID"),
        "verify": MessageLookupByLibrary.simpleMessage("Überprüfen"),
        "verifyEmail":
            MessageLookupByLibrary.simpleMessage("E-Mail-Adresse verifizieren"),
        "verifyEmailID": m12,
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Passwort überprüfen"),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Wiederherstellungs-Schlüssel wird überprüft..."),
        "weakStrength": MessageLookupByLibrary.simpleMessage("Schwach"),
        "welcomeBack":
            MessageLookupByLibrary.simpleMessage("Willkommen zurück!"),
        "weveSentAMailTo": MessageLookupByLibrary.simpleMessage(
            "Wir haben eine E-Mail geschickt an"),
        "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "* Du kannst deinen Speicher maximal verdoppeln"),
        "yourAccountHasBeenDeleted": MessageLookupByLibrary.simpleMessage(
            "Dein Benutzerkonto wurde gelöscht")
      };
}
