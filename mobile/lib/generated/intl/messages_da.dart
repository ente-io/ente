// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a da locale. All the
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
  String get localeName => 'da';

  static String m3(count, formattedCount) =>
      "${Intl.plural(count, zero: 'ingen minder', one: '${formattedCount} minde', other: '${formattedCount} minder')}";

  static String m4(count) => "${count} valgt";

  static String m5(verificationID) =>
      "Hey, kan du bekræfte, at dette er dit ente.io verifikation ID: ${verificationID}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Velkommen tilbage!"),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Aktive sessioner"),
        "addOnPageSubtitle":
            MessageLookupByLibrary.simpleMessage("Oplysninger om tilføjelser"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "Hvad er hovedårsagen til, at du sletter din konto?"),
        "backedUpFolders":
            MessageLookupByLibrary.simpleMessage("Sikkerhedskopierede mapper"),
        "cancel": MessageLookupByLibrary.simpleMessage("Annuller"),
        "confirmAccountDeletion":
            MessageLookupByLibrary.simpleMessage("Bekræft Sletning Af Konto"),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Bekræft adgangskode"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Kopiér denne kode\ntil din autentificeringsapp"),
        "couldNotUpdateSubscription": MessageLookupByLibrary.simpleMessage(
            "Abonnementet kunne ikke opdateres."),
        "createAccount": MessageLookupByLibrary.simpleMessage("Opret konto"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("Opret en ny konto"),
        "deleteAccount": MessageLookupByLibrary.simpleMessage("Slet konto"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "Vi er kede af at du forlader os. Forklar venligst hvorfor, så vi kan forbedre os."),
        "deleteAccountPermanentlyButton":
            MessageLookupByLibrary.simpleMessage("Slet konto permanent"),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "Send venligst en email til <warning>account-deletion@ente.io</warning> fra din registrerede email adresse."),
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "Der mangler en vigtig funktion, som jeg har brug for"),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
            "Jeg fandt en anden tjeneste, som jeg syntes bedre om"),
        "deleteReason4":
            MessageLookupByLibrary.simpleMessage("Min grund er ikke angivet"),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
            "Din anmodning vil blive behandlet inden for 72 timer."),
        "developerSettingsWarning": MessageLookupByLibrary.simpleMessage(
            "Er du sikker på, at du vil ændre udviklerindstillingerne?"),
        "email": MessageLookupByLibrary.simpleMessage("Email"),
        "enterPin": MessageLookupByLibrary.simpleMessage("Indtast PIN"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "Indtast venligst en gyldig email adresse."),
        "enterYourEmailAddress":
            MessageLookupByLibrary.simpleMessage("Indtast din email adresse"),
        "familyPlanPortalTitle":
            MessageLookupByLibrary.simpleMessage("Familie"),
        "feedback": MessageLookupByLibrary.simpleMessage("Feedback"),
        "fileSavedToGallery":
            MessageLookupByLibrary.simpleMessage("Fil gemt i galleri"),
        "findPeopleByName":
            MessageLookupByLibrary.simpleMessage("Find folk hurtigt ved navn"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Glemt adgangskode"),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Forkert adgangskode"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "Den gendannelsesnøgle du indtastede er forkert"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("Ugyldig email adresse"),
        "invite": MessageLookupByLibrary.simpleMessage("Inviter"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Hjælp os venligst med disse oplysninger"),
        "loggingOut": MessageLookupByLibrary.simpleMessage("Logger ud..."),
        "longPressAnEmailToVerifyEndToEndEncryption":
            MessageLookupByLibrary.simpleMessage(
                "Langt tryk på en e-mail for at bekræfte slutningen af krypteringen."),
        "manage": MessageLookupByLibrary.simpleMessage("Administrér"),
        "memoryCount": m3,
        "mlIndexingDescription": MessageLookupByLibrary.simpleMessage(
            "Bemærk venligst, at maskinindlæring vil resultere i en højere båndbredde og batteriforbrug, indtil alle elementer er indekseret. Overvej at bruge desktop app til hurtigere indeksering, vil alle resultater blive synkroniseret automatisk."),
        "moments": MessageLookupByLibrary.simpleMessage("Øjeblikke"),
        "next": MessageLookupByLibrary.simpleMessage("Næste"),
        "ok": MessageLookupByLibrary.simpleMessage("Ok"),
        "oops": MessageLookupByLibrary.simpleMessage("Ups"),
        "password": MessageLookupByLibrary.simpleMessage("Adgangskode"),
        "pleaseContactSupportAndWeWillBeHappyToHelp":
            MessageLookupByLibrary.simpleMessage(
                "Kontakt support@ente.io og vi vil være glade for at hjælpe!"),
        "renameFile": MessageLookupByLibrary.simpleMessage("Omdøb fil"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Skan denne QR-kode med godkendelses-appen"),
        "searchHint1":
            MessageLookupByLibrary.simpleMessage("Hurtig, søgning på enheden"),
        "selectReason": MessageLookupByLibrary.simpleMessage("Vælg årsag"),
        "selectedPhotos": m4,
        "sendEmail": MessageLookupByLibrary.simpleMessage("Send email"),
        "shareTextConfirmOthersVerificationID": m5,
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Noget gik galt, prøv venligst igen"),
        "subscribe": MessageLookupByLibrary.simpleMessage("Abonner"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Afslut session?"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Dette vil logge dig ud af følgende enhed:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Dette vil logge dig ud af denne enhed!"),
        "verify": MessageLookupByLibrary.simpleMessage("Bekræft"),
        "viewAddOnButton":
            MessageLookupByLibrary.simpleMessage("Vis tilføjelser"),
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("Din konto er blevet slettet")
      };
}
