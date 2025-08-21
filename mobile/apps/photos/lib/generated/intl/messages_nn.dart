// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a nn locale. All the
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
  String get localeName => 'nn';

  static String m26(supportEmail) =>
      "Send ein e-post til ${supportEmail} frå e-postadressa du registrerte deg med";

  static String m51(count, formattedCount) =>
      "${Intl.plural(count, zero: 'ingen minne', one: '${formattedCount} minne', other: '${formattedCount} minne')}";

  static String m58(passwordStrengthValue) =>
      "Passordstyrke: ${passwordStrengthValue}";

  static String m81(count) => "${count} valde";

  static String m82(count, yourCount) =>
      "${count} valde (${yourCount} av desse er dine)";

  static String m115(email) =>
      "Vi har sendt ein e-post til <green> ${email} </green>";

  static String m119(storageSaved) => "Du har frigjort ${storageSaved}!";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "aNewVersionOfEnteIsAvailable": MessageLookupByLibrary.simpleMessage(
      "Ein ny versjon av Ente er tilgjengeleg.",
    ),
    "account": MessageLookupByLibrary.simpleMessage("Konto"),
    "accountWelcomeBack": MessageLookupByLibrary.simpleMessage(
      "Velkommen tilbake!",
    ),
    "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
      "Eg forstår at dersom eg gløymer passordet mitt kan alle dataa mine gå tapt, fordi dei er <underline>ende-til-ende-krypterte</underline>.",
    ),
    "activeSessions": MessageLookupByLibrary.simpleMessage("Aktive økter"),
    "addANewEmail": MessageLookupByLibrary.simpleMessage(
      "Legg til ei ny e-postadresse",
    ),
    "addingToFavorites": MessageLookupByLibrary.simpleMessage(
      "Legger til i favorittar …",
    ),
    "adjust": MessageLookupByLibrary.simpleMessage("Juster"),
    "advanced": MessageLookupByLibrary.simpleMessage("Avansert"),
    "advancedSettings": MessageLookupByLibrary.simpleMessage("Avansert"),
    "albumOwner": MessageLookupByLibrary.simpleMessage("Eigar"),
    "albums": MessageLookupByLibrary.simpleMessage("Albums"),
    "androidCancelButton": MessageLookupByLibrary.simpleMessage("Avbryt"),
    "archive": MessageLookupByLibrary.simpleMessage("Arkiv"),
    "areThey": MessageLookupByLibrary.simpleMessage("Er dette "),
    "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
      "Er du sikker på at du vil logga ut?",
    ),
    "askDeleteReason": MessageLookupByLibrary.simpleMessage(
      "Kva er hovudgrunnen til at du vil sletta kontoen din?",
    ),
    "authToChangeYourEmail": MessageLookupByLibrary.simpleMessage(
      "Autentiser for å endra e-postadresse",
    ),
    "authToChangeYourPassword": MessageLookupByLibrary.simpleMessage(
      "Autentiser for å endra passord",
    ),
    "authToViewTrashedFiles": MessageLookupByLibrary.simpleMessage(
      "Autentiser deg for å visa filer i papirkorga",
    ),
    "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
      "Autentiser deg for å visa gøymde filer",
    ),
    "backup": MessageLookupByLibrary.simpleMessage("Reservekopiering"),
    "backupFailed": MessageLookupByLibrary.simpleMessage(
      "Feil ved reservekopiering",
    ),
    "backupOverMobileData": MessageLookupByLibrary.simpleMessage(
      "Ta reservekopi via mobildata",
    ),
    "backupSettings": MessageLookupByLibrary.simpleMessage(
      "Innstillingar for reservekopiering",
    ),
    "backupStatus": MessageLookupByLibrary.simpleMessage(
      "Status for reservekopiering",
    ),
    "backupStatusDescription": MessageLookupByLibrary.simpleMessage(
      "Reservekopierte element vert viste her",
    ),
    "backupVideos": MessageLookupByLibrary.simpleMessage(
      "Ta reservekopi av videoar",
    ),
    "brushColor": MessageLookupByLibrary.simpleMessage("Penselfarge"),
    "cancel": MessageLookupByLibrary.simpleMessage("Avbryt"),
    "cannotDeleteSharedFiles": MessageLookupByLibrary.simpleMessage(
      "Kan ikkje sletta delte filer",
    ),
    "changeEmail": MessageLookupByLibrary.simpleMessage("Endra e-postadresse"),
    "changePassword": MessageLookupByLibrary.simpleMessage("Endra passord"),
    "changePasswordTitle": MessageLookupByLibrary.simpleMessage(
      "Endra passord",
    ),
    "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
      "Kode kopiert til utklippstavla",
    ),
    "confirm": MessageLookupByLibrary.simpleMessage("Stadfest"),
    "confirmAccountDeletion": MessageLookupByLibrary.simpleMessage(
      "Stadfest sletting av konto",
    ),
    "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
      "Ja, eg vil sletta denne kontoen og alle tilhøyrande data frå alle appar permanent.",
    ),
    "confirmPassword": MessageLookupByLibrary.simpleMessage("Stadfest passord"),
    "confirmRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Stadfest gjenopprettingsnøkkel",
    ),
    "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Stadfest gjenopprettingsnøkkelen din",
    ),
    "continueLabel": MessageLookupByLibrary.simpleMessage("Fortsett"),
    "copypasteThisCodentoYourAuthenticatorApp":
        MessageLookupByLibrary.simpleMessage(
          "Kopier og lim inn koden\ni autentikator-appen",
        ),
    "couldNotBackUpTryLater": MessageLookupByLibrary.simpleMessage(
      "Klarte ikkje reservekopiera dataa dine.\nMe prøver på nytt seinare.",
    ),
    "createAccount": MessageLookupByLibrary.simpleMessage("Opprett konto"),
    "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
      "Trykk lenge for å velja foto, og trykk på pluss-ikonet for å oppretta eit album",
    ),
    "createNewAccount": MessageLookupByLibrary.simpleMessage("Opprett konto"),
    "criticalUpdateAvailable": MessageLookupByLibrary.simpleMessage(
      "Kritisk oppdatering tilgjengeleg",
    ),
    "crop": MessageLookupByLibrary.simpleMessage("Skjer av"),
    "decrypting": MessageLookupByLibrary.simpleMessage("Dekrypterer …"),
    "deleteAccount": MessageLookupByLibrary.simpleMessage("Slett konto"),
    "deleteAccountPermanentlyButton": MessageLookupByLibrary.simpleMessage(
      "Slett konto permanent",
    ),
    "deleteFromBoth": MessageLookupByLibrary.simpleMessage("Slett frå begge"),
    "details": MessageLookupByLibrary.simpleMessage("Detaljar"),
    "discover_babies": MessageLookupByLibrary.simpleMessage("Babyar"),
    "discover_celebrations": MessageLookupByLibrary.simpleMessage("Feiringar"),
    "discover_food": MessageLookupByLibrary.simpleMessage("Mat"),
    "discover_hills": MessageLookupByLibrary.simpleMessage("Bakkar"),
    "discover_pets": MessageLookupByLibrary.simpleMessage("Kjæledyr"),
    "discover_selfies": MessageLookupByLibrary.simpleMessage("Selfiar"),
    "discover_sunset": MessageLookupByLibrary.simpleMessage("Solnedgang"),
    "doThisLater": MessageLookupByLibrary.simpleMessage("Gjer dette seinare"),
    "done": MessageLookupByLibrary.simpleMessage("Ferdig"),
    "downloading": MessageLookupByLibrary.simpleMessage("Lastar ned …"),
    "draw": MessageLookupByLibrary.simpleMessage("Klistremerke"),
    "dropSupportEmail": m26,
    "email": MessageLookupByLibrary.simpleMessage("E-post"),
    "emailAlreadyRegistered": MessageLookupByLibrary.simpleMessage(
      "E-postadressa er registrert frå før.",
    ),
    "emailNotRegistered": MessageLookupByLibrary.simpleMessage(
      "E-postadressa er ikkje registrert.",
    ),
    "encryptingBackup": MessageLookupByLibrary.simpleMessage(
      "Krypterer reservekopi …",
    ),
    "encryption": MessageLookupByLibrary.simpleMessage("Kryptering"),
    "encryptionKeys": MessageLookupByLibrary.simpleMessage("Krypteringsnøklar"),
    "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
      "Ente <i>treng løyve til</i> å kunna ta vare på fotoa dine",
    ),
    "enterCode": MessageLookupByLibrary.simpleMessage("Skriv inn kode"),
    "enterEmail": MessageLookupByLibrary.simpleMessage(
      "Skriv inn e-postadresse",
    ),
    "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
      "Skriv inn eit nytt passord me kan kryptera dataa dine med",
    ),
    "enterPassword": MessageLookupByLibrary.simpleMessage("Skriv inn passord"),
    "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
      "Skriv inn eit passord me kan kryptera dataa dine med",
    ),
    "enterThe6digitCodeFromnyourAuthenticatorApp":
        MessageLookupByLibrary.simpleMessage(
          "Skriv inn den seks-sifra koden\nfrå autentikator-appen",
        ),
    "enterValidEmail": MessageLookupByLibrary.simpleMessage(
      "Skriv inn ei gyldig e-postadresse.",
    ),
    "enterYourEmailAddress": MessageLookupByLibrary.simpleMessage(
      "Skriv inn e-postadressa di",
    ),
    "enterYourNewEmailAddress": MessageLookupByLibrary.simpleMessage(
      "Skriv inn den nye e-postadressa di",
    ),
    "enterYourPassword": MessageLookupByLibrary.simpleMessage(
      "Skriv inn passordet ditt",
    ),
    "enterYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Skriv inn gjenopprettingsnøkkelen",
    ),
    "exif": MessageLookupByLibrary.simpleMessage("Exif"),
    "exportYourData": MessageLookupByLibrary.simpleMessage(
      "Eksporter dataa dine",
    ),
    "failedToLoadAlbums": MessageLookupByLibrary.simpleMessage(
      "Feil ved lasting av album",
    ),
    "faq": MessageLookupByLibrary.simpleMessage("Spørsmål og svar"),
    "faqs": MessageLookupByLibrary.simpleMessage("Spørsmål og svar"),
    "feedback": MessageLookupByLibrary.simpleMessage("Tilbakemelding"),
    "fileInfoAddDescHint": MessageLookupByLibrary.simpleMessage(
      "Legg til skildring …",
    ),
    "filter": MessageLookupByLibrary.simpleMessage("Filter"),
    "flip": MessageLookupByLibrary.simpleMessage("Spegelvend"),
    "forgotPassword": MessageLookupByLibrary.simpleMessage("Gløymt passordet"),
    "freeUpDeviceSpace": MessageLookupByLibrary.simpleMessage(
      "Frigjer plass på eininga",
    ),
    "freeUpDeviceSpaceDesc": MessageLookupByLibrary.simpleMessage(
      "Frigjer plass på eininga ved å fjerna filer som allereie er reservekopierte.",
    ),
    "general": MessageLookupByLibrary.simpleMessage("Generelt"),
    "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
      "Lagar krypteringsnøklar …",
    ),
    "help": MessageLookupByLibrary.simpleMessage("Hjelp"),
    "hidden": MessageLookupByLibrary.simpleMessage("Gøymde"),
    "howItWorks": MessageLookupByLibrary.simpleMessage("Slik fungerer det"),
    "ignoreUpdate": MessageLookupByLibrary.simpleMessage("Ignorer"),
    "importing": MessageLookupByLibrary.simpleMessage("Importerer …"),
    "incorrectPasswordTitle": MessageLookupByLibrary.simpleMessage(
      "Ugyldig passord",
    ),
    "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
      "Gjenopprettingsnøkkelen som du skreiv inn er feil",
    ),
    "incorrectRecoveryKeyTitle": MessageLookupByLibrary.simpleMessage(
      "Gjenopprettingsnøkkelen er feil",
    ),
    "indexedItems": MessageLookupByLibrary.simpleMessage("Indekserte element"),
    "insecureDevice": MessageLookupByLibrary.simpleMessage("Usikker eining"),
    "installManually": MessageLookupByLibrary.simpleMessage(
      "Installer manuelt",
    ),
    "invalidEmailAddress": MessageLookupByLibrary.simpleMessage(
      "Ugyldig e-postadresse",
    ),
    "invalidKey": MessageLookupByLibrary.simpleMessage("Ugyldig nøkkel"),
    "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Gjenopprettingsnøkkelen er ikkje gyldig. Pass på at han inneheld 24 ord og er stava riktig.\n\nViss du skreiv inn ein eldre gjenopprettingskode, pass på at han inneheld 64 teikn.",
    ),
    "loadingModel": MessageLookupByLibrary.simpleMessage(
      "Lastar ned modellar  …",
    ),
    "logInLabel": MessageLookupByLibrary.simpleMessage("Logg på"),
    "logout": MessageLookupByLibrary.simpleMessage("Logg ut"),
    "manageLink": MessageLookupByLibrary.simpleMessage("Handsam lenkje"),
    "manageSubscription": MessageLookupByLibrary.simpleMessage(
      "Handsam abonnement",
    ),
    "memoryCount": m51,
    "moderateStrength": MessageLookupByLibrary.simpleMessage("Middels sterkt"),
    "newAlbum": MessageLookupByLibrary.simpleMessage("Nytt album"),
    "next": MessageLookupByLibrary.simpleMessage("Neste"),
    "noExifData": MessageLookupByLibrary.simpleMessage("Ingen Exif-data"),
    "noFacesFound": MessageLookupByLibrary.simpleMessage("Fann ingen ansikt"),
    "noRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Ingen gjenopprettingsnøkkel?",
    ),
    "ok": MessageLookupByLibrary.simpleMessage("OK"),
    "oops": MessageLookupByLibrary.simpleMessage("Uff då"),
    "oopsSomethingWentWrong": MessageLookupByLibrary.simpleMessage(
      "Uff då. Noko gjekk gale.",
    ),
    "password": MessageLookupByLibrary.simpleMessage("Passord"),
    "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Passordet er endra",
    ),
    "passwordStrength": m58,
    "passwordWarning": MessageLookupByLibrary.simpleMessage(
      "Vi lagrar ikkje dette passordet, så dersom du gløymer det <underline>kan vi ikkje dekryptera dataa dine</underline>",
    ),
    "photoSmallCase": MessageLookupByLibrary.simpleMessage("foto"),
    "pleaseTryAgain": MessageLookupByLibrary.simpleMessage("Prøv på nytt"),
    "pleaseWait": MessageLookupByLibrary.simpleMessage("Vent litt …"),
    "privacyPolicyTitle": MessageLookupByLibrary.simpleMessage(
      "Personvernerklæring",
    ),
    "privateBackups": MessageLookupByLibrary.simpleMessage(
      "Private reservekopiar",
    ),
    "recover": MessageLookupByLibrary.simpleMessage("Gjenopprett"),
    "recoverAccount": MessageLookupByLibrary.simpleMessage("Gjenopprett konto"),
    "recoverButton": MessageLookupByLibrary.simpleMessage("Gjenopprett"),
    "recoveryKey": MessageLookupByLibrary.simpleMessage(
      "Gjenopprettingsnøkkel",
    ),
    "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
      "Gjenopprettingsnøkkel kopiert til utklippstavla",
    ),
    "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
      "Viss du gløymer passordet, er det berre ved å bruka denne nøkkelen at du kan gjenoppretta dataa dine.",
    ),
    "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
      "Me tek ikkje vare på denne nøkkelen. Denne nøkkelen på 24 ord må du oppbevara på ein trygg stad.",
    ),
    "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
      "Flott! Gjenopprettingsnøkkelen er gyldig. Takk for at du stadfesta han.\n\nHugs å oppbevara gjenopprettingsnøkkelen på ein trygg stad.",
    ),
    "recoveryKeyVerified": MessageLookupByLibrary.simpleMessage(
      "Gjenopprettingsnøkkelen er stadfesta",
    ),
    "recoveryKeyVerifyReason": MessageLookupByLibrary.simpleMessage(
      "Viss du gløymer passordet, er det berre ved å bruka gjenopprettingsnøkkelen at du kan gjenoppretta fotoa dine. Vel «Konto» frå «Innstillingar»-menyen for å finna gjenopprettingsnøkkelen.\n\nSkriv inn gjenopprettingsnøkkelen her for å stadfesta at du har lagra han på riktig måte.",
    ),
    "recoverySuccessful": MessageLookupByLibrary.simpleMessage(
      "Gjenoppretting var vellukka.",
    ),
    "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
      "Den gjeldande eininga er ikkje kraftig nok til å kunna stadfesta passordet ditt, men me kan laga det på nytt ved å bruka ein metode som vil fungere på alle einingar.\n\nLogg på ved å bruka gjenopprettingsnøkkelen din og lag passordet på nytt (du kan gjenbruka passordet viss du vil).",
    ),
    "recreatePasswordTitle": MessageLookupByLibrary.simpleMessage(
      "Opprett passord på nytt",
    ),
    "removeDuplicates": MessageLookupByLibrary.simpleMessage("Fjern duplikat"),
    "removeDuplicatesDesc": MessageLookupByLibrary.simpleMessage(
      "Sjå gjennom og fjern duplikate filer.",
    ),
    "removeLink": MessageLookupByLibrary.simpleMessage("Fjern lenkje"),
    "removingFromFavorites": MessageLookupByLibrary.simpleMessage(
      "Fjernar frå favorittar …",
    ),
    "rename": MessageLookupByLibrary.simpleMessage("Endra namn"),
    "renameAlbum": MessageLookupByLibrary.simpleMessage("Endra namn på album"),
    "renameFile": MessageLookupByLibrary.simpleMessage("Endra namn på fil"),
    "resendEmail": MessageLookupByLibrary.simpleMessage(
      "Send e-posten på nytt",
    ),
    "resetPasswordTitle": MessageLookupByLibrary.simpleMessage(
      "Tilbakestill passord",
    ),
    "retry": MessageLookupByLibrary.simpleMessage("Prøv på nytt"),
    "rotate": MessageLookupByLibrary.simpleMessage("Roter"),
    "rotateLeft": MessageLookupByLibrary.simpleMessage("Roter til venstre"),
    "rotateRight": MessageLookupByLibrary.simpleMessage("Roter til høgre"),
    "saveCopy": MessageLookupByLibrary.simpleMessage("Lagra kopi"),
    "saveKey": MessageLookupByLibrary.simpleMessage("Lagra nøkkel"),
    "saveYourRecoveryKeyIfYouHaventAlready":
        MessageLookupByLibrary.simpleMessage(
          "Lagra gjenopprettingsnøkkelen viss du ikkje alt har gjort det",
        ),
    "scanCode": MessageLookupByLibrary.simpleMessage("Skann kode"),
    "scanThisBarcodeWithnyourAuthenticatorApp":
        MessageLookupByLibrary.simpleMessage(
          "Skann denne strekkoden med\nautentikator-appen",
        ),
    "security": MessageLookupByLibrary.simpleMessage("Tryggleik"),
    "selectAll": MessageLookupByLibrary.simpleMessage("Merk alle"),
    "selectDate": MessageLookupByLibrary.simpleMessage("Vel dato"),
    "selectedFoldersWillBeEncryptedAndBackedUp":
        MessageLookupByLibrary.simpleMessage(
          "Dei valde mappene vert krypterte og reservekopierte",
        ),
    "selectedPhotos": m81,
    "selectedPhotosWithYours": m82,
    "sendEmail": MessageLookupByLibrary.simpleMessage("Send e-post"),
    "setPasswordTitle": MessageLookupByLibrary.simpleMessage("Vel passord"),
    "setupComplete": MessageLookupByLibrary.simpleMessage(
      "Oppsettet er fullført",
    ),
    "signUpTerms": MessageLookupByLibrary.simpleMessage(
      "Eg godtek <u-terms>tenestevilkåra</u-terms> og <u-policy>personvernerklæringa</u-policy>",
    ),
    "skip": MessageLookupByLibrary.simpleMessage("Hopp over"),
    "somethingWentWrongPleaseTryAgain": MessageLookupByLibrary.simpleMessage(
      "Det oppstod ein feil. Prøv på nytt.",
    ),
    "sorry": MessageLookupByLibrary.simpleMessage("Orsak"),
    "sorryBackupFailedDesc": MessageLookupByLibrary.simpleMessage(
      "Klarte ikkje reservekopiera fila. Me prøver på nytt seinare.",
    ),
    "sorryCouldNotAddToFavorites": MessageLookupByLibrary.simpleMessage(
      "Klarte ikkje leggja til i favorittar.",
    ),
    "sorryCouldNotRemoveFromFavorites": MessageLookupByLibrary.simpleMessage(
      "Klarte ikkje fjerna frå favorittar.",
    ),
    "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
        MessageLookupByLibrary.simpleMessage(
          "Klarte ikkje laga tryggleiksnøklar på denne eininga.\n\nBruk ei anna eining for å registrera deg.",
        ),
    "startBackup": MessageLookupByLibrary.simpleMessage(
      "Start reservekopiering",
    ),
    "status": MessageLookupByLibrary.simpleMessage("Status"),
    "strongStrength": MessageLookupByLibrary.simpleMessage("Sterkt"),
    "subscription": MessageLookupByLibrary.simpleMessage("Abonnement"),
    "tapToCopy": MessageLookupByLibrary.simpleMessage("trykk for å kopiera"),
    "terminate": MessageLookupByLibrary.simpleMessage("Avslutt"),
    "terminateSession": MessageLookupByLibrary.simpleMessage("Avslutta økt?"),
    "termsOfServicesTitle": MessageLookupByLibrary.simpleMessage("Vilkår"),
    "theDownloadCouldNotBeCompleted": MessageLookupByLibrary.simpleMessage(
      "Klarte ikkje fullføra nedlastinga",
    ),
    "thisDevice": MessageLookupByLibrary.simpleMessage("Denne eininga"),
    "thisImageHasNoExifData": MessageLookupByLibrary.simpleMessage(
      "Biletet har ingen exif-data",
    ),
    "thisWillLogYouOutOfTheFollowingDevice":
        MessageLookupByLibrary.simpleMessage(
          "Dette loggar deg ut frå dei følgjande einingane:",
        ),
    "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
      "Dette loggar deg ut frå denne eininga.",
    ),
    "trash": MessageLookupByLibrary.simpleMessage("Papirkorg"),
    "tryAgain": MessageLookupByLibrary.simpleMessage("Prøv på nytt"),
    "twofactorAuthenticationPageTitle": MessageLookupByLibrary.simpleMessage(
      "Tofaktorautentisering",
    ),
    "twofactorSetup": MessageLookupByLibrary.simpleMessage(
      "Oppsett av tofaktor",
    ),
    "uncategorized": MessageLookupByLibrary.simpleMessage(
      "Ikkje-kategoriserte",
    ),
    "unselectAll": MessageLookupByLibrary.simpleMessage("Fjern all merking"),
    "update": MessageLookupByLibrary.simpleMessage("Oppdater"),
    "updateAvailable": MessageLookupByLibrary.simpleMessage(
      "Oppdatering tilgjengeleg",
    ),
    "useRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Bruk gjenopprettingsnøkkel",
    ),
    "verify": MessageLookupByLibrary.simpleMessage("Stadfest"),
    "verifyEmail": MessageLookupByLibrary.simpleMessage(
      "Stadfest e-postadresse",
    ),
    "verifyPassword": MessageLookupByLibrary.simpleMessage("Stadfest passord"),
    "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Stadfestar gjenopprettingsnøkkel …",
    ),
    "videoSmallCase": MessageLookupByLibrary.simpleMessage("video"),
    "viewLargeFiles": MessageLookupByLibrary.simpleMessage("Store filer"),
    "viewLargeFilesDesc": MessageLookupByLibrary.simpleMessage(
      "Vis filer som tek opp mest plass.",
    ),
    "viewRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Vis gjenopprettingsnøkkel",
    ),
    "waitingForWifi": MessageLookupByLibrary.simpleMessage("Ventar på Wi-Fi …"),
    "weHaveSendEmailTo": m115,
    "weakStrength": MessageLookupByLibrary.simpleMessage("Svakt"),
    "welcomeBack": MessageLookupByLibrary.simpleMessage("Velkommen tilbake!"),
    "yesLogout": MessageLookupByLibrary.simpleMessage("Ja, logg ut"),
    "you": MessageLookupByLibrary.simpleMessage("Deg"),
    "youAreOnTheLatestVersion": MessageLookupByLibrary.simpleMessage(
      "Du har siste versjon",
    ),
    "youHaveSuccessfullyFreedUp": m119,
    "yourAccountHasBeenDeleted": MessageLookupByLibrary.simpleMessage(
      "Kontoen er sletta",
    ),
  };
}
