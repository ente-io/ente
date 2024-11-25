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

  static String m9(count, formattedCount) =>
      "${Intl.plural(count, zero: 'ingen minder', one: '${formattedCount} minde', other: '${formattedCount} minder')}";

  static String m0(personName) => "No suggestions for ${personName}";

  static String m1(count) => "${count} photos";

  static String m2(snapshotLenght, searchLenght) =>
      "Sections length mismatch: ${snapshotLenght} != ${searchLenght}";

  static String m10(count) => "${count} valgt";

  static String m11(verificationID) =>
      "Hey, kan du bekræfte, at dette er dit ente.io verifikation ID: ${verificationID}";

  static String m3(ignoreReason) =>
      "Tap to upload, upload is currently ignored due to ${ignoreReason}";

  static String m4(galleryType) =>
      "Type of gallery ${galleryType} is not supported for rename";

  static String m5(ignoreReason) => "Upload is ignored due to ${ignoreReason}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "accountIsAlreadyConfigured": MessageLookupByLibrary.simpleMessage(
            "Account is already configured."),
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Velkommen tilbage!"),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Aktive sessioner"),
        "add": MessageLookupByLibrary.simpleMessage("Add"),
        "addFiles": MessageLookupByLibrary.simpleMessage("Add Files"),
        "addNew": MessageLookupByLibrary.simpleMessage("Add new"),
        "addOnPageSubtitle":
            MessageLookupByLibrary.simpleMessage("Oplysninger om tilføjelser"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "Hvad er hovedårsagen til, at du sletter din konto?"),
        "backedUpFolders":
            MessageLookupByLibrary.simpleMessage("Sikkerhedskopierede mapper"),
        "cancel": MessageLookupByLibrary.simpleMessage("Annuller"),
        "castAlbum": MessageLookupByLibrary.simpleMessage("Cast album"),
        "changeLogBackupStatusContent": MessageLookupByLibrary.simpleMessage(
            "We\\\'ve added a log of all the files that have been uploaded to Ente, including failures and queued."),
        "changeLogBackupStatusTitle":
            MessageLookupByLibrary.simpleMessage("Backup Status"),
        "changeLogDiscoverContent": MessageLookupByLibrary.simpleMessage(
            "Looking for photos of your id cards, notes, or even memes? Go to the search tab and check out Discover. Based on our semantic search, it\\\'s a place to find photos that might be important for you.\\n\\nOnly available if you have enabled Machine Learning."),
        "changeLogDiscoverTitle":
            MessageLookupByLibrary.simpleMessage("Discover"),
        "changeLogMagicSearchImprovementContent":
            MessageLookupByLibrary.simpleMessage(
                "We have improved magic search to become much faster, so you don\\\'t have to wait to find what you\\\'re looking for."),
        "changeLogMagicSearchImprovementTitle":
            MessageLookupByLibrary.simpleMessage("Magic Search Improvement"),
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
        "currentlyRunning":
            MessageLookupByLibrary.simpleMessage("currently running"),
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
        "edit": MessageLookupByLibrary.simpleMessage("Edit"),
        "email": MessageLookupByLibrary.simpleMessage("Email"),
        "enterPin": MessageLookupByLibrary.simpleMessage("Indtast PIN"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "Indtast venligst en gyldig email adresse."),
        "enterYourEmailAddress":
            MessageLookupByLibrary.simpleMessage("Indtast din email adresse"),
        "error": MessageLookupByLibrary.simpleMessage("Error"),
        "failedToFetchActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Failed to fetch active sessions"),
        "failedToPlayVideo":
            MessageLookupByLibrary.simpleMessage("Failed to play video"),
        "failedToRefreshStripeSubscription":
            MessageLookupByLibrary.simpleMessage(
                "Failed to refresh subscription"),
        "familyPlanPortalTitle":
            MessageLookupByLibrary.simpleMessage("Familie"),
        "feedback": MessageLookupByLibrary.simpleMessage("Feedback"),
        "file": MessageLookupByLibrary.simpleMessage("File"),
        "fileNotUploadedYet":
            MessageLookupByLibrary.simpleMessage("File not uploaded yet"),
        "fileSavedToGallery":
            MessageLookupByLibrary.simpleMessage("Fil gemt i galleri"),
        "findPeopleByName":
            MessageLookupByLibrary.simpleMessage("Find folk hurtigt ved navn"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Glemt adgangskode"),
        "ignored": MessageLookupByLibrary.simpleMessage("ignored"),
        "imageNotAnalyzed":
            MessageLookupByLibrary.simpleMessage("Image not analyzed"),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Forkert adgangskode"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "Den gendannelsesnøgle du indtastede er forkert"),
        "info": MessageLookupByLibrary.simpleMessage("Info"),
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
        "memoryCount": m9,
        "mlIndexingDescription": MessageLookupByLibrary.simpleMessage(
            "Bemærk venligst, at maskinindlæring vil resultere i en højere båndbredde og batteriforbrug, indtil alle elementer er indekseret. Overvej at bruge desktop app til hurtigere indeksering, vil alle resultater blive synkroniseret automatisk."),
        "moments": MessageLookupByLibrary.simpleMessage("Øjeblikke"),
        "month": MessageLookupByLibrary.simpleMessage("month"),
        "monthly": MessageLookupByLibrary.simpleMessage("Monthly"),
        "newLocation": MessageLookupByLibrary.simpleMessage("New location"),
        "next": MessageLookupByLibrary.simpleMessage("Næste"),
        "noFacesFound": MessageLookupByLibrary.simpleMessage("No faces found"),
        "noInternetConnection":
            MessageLookupByLibrary.simpleMessage("No internet connection"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("No results found"),
        "noSuggestionsForPerson": m0,
        "ok": MessageLookupByLibrary.simpleMessage("Ok"),
        "onlyThem": MessageLookupByLibrary.simpleMessage("Only them"),
        "oops": MessageLookupByLibrary.simpleMessage("Ups"),
        "password": MessageLookupByLibrary.simpleMessage("Adgangskode"),
        "photosCount": m1,
        "pleaseCheckYourInternetConnectionAndTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Please check your internet connection and try again."),
        "pleaseContactSupportAndWeWillBeHappyToHelp":
            MessageLookupByLibrary.simpleMessage(
                "Kontakt support@ente.io og vi vil være glade for at hjælpe!"),
        "renameFile": MessageLookupByLibrary.simpleMessage("Omdøb fil"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Skan denne QR-kode med godkendelses-appen"),
        "searchHint1":
            MessageLookupByLibrary.simpleMessage("Hurtig, søgning på enheden"),
        "searchSectionsLengthMismatch": m2,
        "selectAll": MessageLookupByLibrary.simpleMessage("All"),
        "selectAllShort": MessageLookupByLibrary.simpleMessage("All"),
        "selectCoverPhoto":
            MessageLookupByLibrary.simpleMessage("Select cover photo"),
        "selectMailApp":
            MessageLookupByLibrary.simpleMessage("Select mail app"),
        "selectReason": MessageLookupByLibrary.simpleMessage("Vælg årsag"),
        "selectYourPlan":
            MessageLookupByLibrary.simpleMessage("Select your plan"),
        "selectedPhotos": m10,
        "sendEmail": MessageLookupByLibrary.simpleMessage("Send email"),
        "sessionExpired":
            MessageLookupByLibrary.simpleMessage("Session expired"),
        "sessionIdMismatch":
            MessageLookupByLibrary.simpleMessage("Session ID mismatch"),
        "share": MessageLookupByLibrary.simpleMessage("Share"),
        "shareTextConfirmOthersVerificationID": m11,
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Noget gik galt, prøv venligst igen"),
        "subscribe": MessageLookupByLibrary.simpleMessage("Abonner"),
        "subscription": MessageLookupByLibrary.simpleMessage("Subscription"),
        "tapToUpload": MessageLookupByLibrary.simpleMessage("Tap to upload"),
        "tapToUploadIsIgnoredDue": m3,
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Afslut session?"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Dette vil logge dig ud af følgende enhed:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Dette vil logge dig ud af denne enhed!"),
        "typeOfGallerGallerytypeIsNotSupportedForRename": m4,
        "uploadIsIgnoredDueToIgnorereason": m5,
        "verify": MessageLookupByLibrary.simpleMessage("Bekræft"),
        "viewAddOnButton":
            MessageLookupByLibrary.simpleMessage("Vis tilføjelser"),
        "yearShort": MessageLookupByLibrary.simpleMessage("yr"),
        "yearly": MessageLookupByLibrary.simpleMessage("Yearly"),
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("Din konto er blevet slettet"),
        "yourMap": MessageLookupByLibrary.simpleMessage("Your Map")
      };
}
