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

  static String m3(user) =>
      "${user} vil ikke kunne tilføje flere billeder til dette album\n\nDe vil stadig kunne fjerne eksisterende billeder tilføjet af dem";

  static String m4(storageAmountInGB) =>
      "${storageAmountInGB} GB hver gang nogen tilmelder sig et betalt abonnement og anvender din kode";

  static String m5(count, formattedCount) =>
      "${Intl.plural(count, zero: 'ingen minder', one: '${formattedCount} minde', other: '${formattedCount} minder')}";

  static String m0(passwordStrengthValue) =>
      "Kodeordets styrke: ${passwordStrengthValue}";

  static String m6(count) => "${count} valgt";

  static String m7(verificationID) =>
      "Hey, kan du bekræfte, at dette er dit ente.io verifikation ID: ${verificationID}";

  static String m1(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m8(storageAmountInGB) => "De får også ${storageAmountInGB} GB";

  static String m2(email) =>
      "Vi har sendt en email til <green>${email}</green>";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Velkommen tilbage!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Jeg forstår at hvis jeg mister min adgangskode kan jeg miste mine data, da mine data er <underline>end-to-end krypteret</underline>."),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Aktive sessioner"),
        "addMore": MessageLookupByLibrary.simpleMessage("Tilføj flere"),
        "addOnPageSubtitle":
            MessageLookupByLibrary.simpleMessage("Oplysninger om tilføjelser"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Tilføjet som"),
        "addingToFavorites":
            MessageLookupByLibrary.simpleMessage("Tilføjer til favoritter..."),
        "advancedSettings": MessageLookupByLibrary.simpleMessage("Avanceret"),
        "after1Day": MessageLookupByLibrary.simpleMessage("Efter 1 dag"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("Efter 1 time"),
        "after1Month": MessageLookupByLibrary.simpleMessage("Efter 1 måned"),
        "after1Week": MessageLookupByLibrary.simpleMessage("Efter 1 uge"),
        "after1Year": MessageLookupByLibrary.simpleMessage("Efter 1 år"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Ejer"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("Tillad downloads"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "Hvad er hovedårsagen til, at du sletter din konto?"),
        "backedUpFolders":
            MessageLookupByLibrary.simpleMessage("Sikkerhedskopierede mapper"),
        "backupStatusDescription": MessageLookupByLibrary.simpleMessage(
            "Elementer, der er blevet sikkerhedskopieret, vil blive vist her"),
        "canNotOpenBody": MessageLookupByLibrary.simpleMessage(
            "Beklager, dette album kan ikke åbnes i appen."),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "Kan kun fjerne filer ejet af dig"),
        "cancel": MessageLookupByLibrary.simpleMessage("Annuller"),
        "cannotAddMorePhotosAfterBecomingViewer": m3,
        "cannotDeleteSharedFiles":
            MessageLookupByLibrary.simpleMessage("Kan ikke slette delte filer"),
        "changeEmail":
            MessageLookupByLibrary.simpleMessage("Skift email adresse"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Skift adgangskode"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Tjek venligst din indbakke (og spam) for at færdiggøre verificeringen"),
        "clearIndexes": MessageLookupByLibrary.simpleMessage("Ryd indekser"),
        "collectPhotos":
            MessageLookupByLibrary.simpleMessage("Indsaml billeder"),
        "confirmAccountDeletion":
            MessageLookupByLibrary.simpleMessage("Bekræft Sletning Af Konto"),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Bekræft adgangskode"),
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("Kontakt support"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("Fortsæt"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Kopiér denne kode\ntil din autentificeringsapp"),
        "couldNotUpdateSubscription": MessageLookupByLibrary.simpleMessage(
            "Abonnementet kunne ikke opdateres."),
        "createAccount": MessageLookupByLibrary.simpleMessage("Opret konto"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("Opret en ny konto"),
        "creatingLink":
            MessageLookupByLibrary.simpleMessage("Opretter link..."),
        "decrypting": MessageLookupByLibrary.simpleMessage("Dekrypterer..."),
        "deleteAccount": MessageLookupByLibrary.simpleMessage("Slet konto"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "Vi er kede af at du forlader os. Forklar venligst hvorfor, så vi kan forbedre os."),
        "deleteAccountPermanentlyButton":
            MessageLookupByLibrary.simpleMessage("Slet konto permanent"),
        "deleteAlbum": MessageLookupByLibrary.simpleMessage("Slet album"),
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
        "deleteSharedAlbum":
            MessageLookupByLibrary.simpleMessage("Slet delt album?"),
        "details": MessageLookupByLibrary.simpleMessage("Detaljer"),
        "developerSettingsWarning": MessageLookupByLibrary.simpleMessage(
            "Er du sikker på, at du vil ændre udviklerindstillingerne?"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Bemærk venligst"),
        "discover_food": MessageLookupByLibrary.simpleMessage("Mad"),
        "discover_identity": MessageLookupByLibrary.simpleMessage("Identitet"),
        "discover_memes": MessageLookupByLibrary.simpleMessage("Memes"),
        "discover_notes": MessageLookupByLibrary.simpleMessage("Noter"),
        "discover_pets": MessageLookupByLibrary.simpleMessage("Kæledyr"),
        "discover_screenshots":
            MessageLookupByLibrary.simpleMessage("Skærmbilleder"),
        "discover_selfies": MessageLookupByLibrary.simpleMessage("Selfier"),
        "discover_sunset": MessageLookupByLibrary.simpleMessage("Solnedgang"),
        "discover_wallpapers":
            MessageLookupByLibrary.simpleMessage("Baggrundsbilleder"),
        "eligible": MessageLookupByLibrary.simpleMessage("kvalificeret"),
        "email": MessageLookupByLibrary.simpleMessage("Email"),
        "emailAlreadyRegistered": MessageLookupByLibrary.simpleMessage(
            "E-mail er allerede registreret."),
        "emailNotRegistered":
            MessageLookupByLibrary.simpleMessage("E-mail er ikke registreret."),
        "encryption": MessageLookupByLibrary.simpleMessage("Kryptering"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Krypteringsnøgler"),
        "enterEmail":
            MessageLookupByLibrary.simpleMessage("Indtast email adresse"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Indtast en ny adgangskode vi kan bruge til at kryptere dine data"),
        "enterPassword":
            MessageLookupByLibrary.simpleMessage("Indtast adgangskode"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Indtast en adgangskode vi kan bruge til at kryptere dine data"),
        "enterPin": MessageLookupByLibrary.simpleMessage("Indtast PIN"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "Indtast venligst en gyldig email adresse."),
        "enterYourEmailAddress":
            MessageLookupByLibrary.simpleMessage("Indtast din email adresse"),
        "enterYourPassword":
            MessageLookupByLibrary.simpleMessage("Indtast adgangskode"),
        "enterYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Indtast din gendannelsesnøgle"),
        "familyPlanPortalTitle":
            MessageLookupByLibrary.simpleMessage("Familie"),
        "feedback": MessageLookupByLibrary.simpleMessage("Feedback"),
        "fileSavedToGallery":
            MessageLookupByLibrary.simpleMessage("Fil gemt i galleri"),
        "findPeopleByName":
            MessageLookupByLibrary.simpleMessage("Find folk hurtigt ved navn"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Glemt adgangskode"),
        "freeStorageOnReferralSuccess": m4,
        "freeUpDeviceSpace":
            MessageLookupByLibrary.simpleMessage("Frigør enhedsplads"),
        "freeUpDeviceSpaceDesc": MessageLookupByLibrary.simpleMessage(
            "Spar plads på din enhed ved at rydde filer, der allerede er sikkerhedskopieret."),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Genererer krypteringsnøgler..."),
        "help": MessageLookupByLibrary.simpleMessage("Hjælp"),
        "howItWorks":
            MessageLookupByLibrary.simpleMessage("Sådan fungerer det"),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Forkert adgangskode"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "Den gendannelsesnøgle du indtastede er forkert"),
        "incorrectRecoveryKeyTitle":
            MessageLookupByLibrary.simpleMessage("Forkert gendannelsesnøgle"),
        "indexedItems":
            MessageLookupByLibrary.simpleMessage("Indekserede elementer"),
        "insecureDevice": MessageLookupByLibrary.simpleMessage("Usikker enhed"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("Ugyldig email adresse"),
        "invite": MessageLookupByLibrary.simpleMessage("Inviter"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Inviter dine venner"),
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "Valgte elementer vil blive fjernet fra dette album"),
        "keepPhotos": MessageLookupByLibrary.simpleMessage("Behold billeder"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Hjælp os venligst med disse oplysninger"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Aktiveret"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Udløbet"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Aldrig"),
        "loadingModel":
            MessageLookupByLibrary.simpleMessage("Downloader modeller..."),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Lås"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Log ind"),
        "loggingOut": MessageLookupByLibrary.simpleMessage("Logger ud..."),
        "longPressAnEmailToVerifyEndToEndEncryption":
            MessageLookupByLibrary.simpleMessage(
                "Langt tryk på en e-mail for at bekræfte slutningen af krypteringen."),
        "machineLearning": MessageLookupByLibrary.simpleMessage("Maskinlæring"),
        "magicSearch": MessageLookupByLibrary.simpleMessage("Magisk søgning"),
        "manage": MessageLookupByLibrary.simpleMessage("Administrér"),
        "manageDeviceStorageDesc": MessageLookupByLibrary.simpleMessage(
            "Gennemgå og ryd lokal cache-lagring."),
        "memoryCount": m5,
        "mlConsent":
            MessageLookupByLibrary.simpleMessage("Aktiver maskinlæring"),
        "mlConsentPrivacy": MessageLookupByLibrary.simpleMessage(
            "Klik her for flere detaljer om denne funktion i vores privatlivspolitik"),
        "mlConsentTitle":
            MessageLookupByLibrary.simpleMessage("Aktiver maskinlæring?"),
        "mlIndexingDescription": MessageLookupByLibrary.simpleMessage(
            "Bemærk venligst, at maskinindlæring vil resultere i en højere båndbredde og batteriforbrug, indtil alle elementer er indekseret. Overvej at bruge desktop app til hurtigere indeksering, vil alle resultater blive synkroniseret automatisk."),
        "moments": MessageLookupByLibrary.simpleMessage("Øjeblikke"),
        "never": MessageLookupByLibrary.simpleMessage("Aldrig"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Nyt album"),
        "next": MessageLookupByLibrary.simpleMessage("Næste"),
        "noRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Ingen gendannelsesnøgle?"),
        "ok": MessageLookupByLibrary.simpleMessage("Ok"),
        "oops": MessageLookupByLibrary.simpleMessage("Ups"),
        "oopsSomethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Ups, noget gik galt"),
        "password": MessageLookupByLibrary.simpleMessage("Adgangskode"),
        "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
            "Adgangskoden er blevet ændret"),
        "passwordStrength": m0,
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Vi gemmer ikke denne adgangskode, så hvis du glemmer den <underline>kan vi ikke dekryptere dine data</underline>"),
        "pendingItems":
            MessageLookupByLibrary.simpleMessage("Afventende elementer"),
        "peopleUsingYourCode": MessageLookupByLibrary.simpleMessage(
            "Personer, der bruger din kode"),
        "pleaseContactSupportAndWeWillBeHappyToHelp":
            MessageLookupByLibrary.simpleMessage(
                "Kontakt support@ente.io og vi vil være glade for at hjælpe!"),
        "pleaseWait": MessageLookupByLibrary.simpleMessage("Vent venligst..."),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Privatlivspolitik"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Gendan"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "2. De tilmelder sig en betalt plan"),
        "removeFromAlbum":
            MessageLookupByLibrary.simpleMessage("Fjern fra album"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("Fjern fra album?"),
        "removeLink": MessageLookupByLibrary.simpleMessage("Fjern link"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Fjern deltager"),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Fjern?"),
        "removingFromFavorites":
            MessageLookupByLibrary.simpleMessage("Fjerner fra favoritter..."),
        "renameFile": MessageLookupByLibrary.simpleMessage("Omdøb fil"),
        "resendEmail": MessageLookupByLibrary.simpleMessage("Send email igen"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Nulstil adgangskode"),
        "retry": MessageLookupByLibrary.simpleMessage("Prøv igen"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Skan denne QR-kode med godkendelses-appen"),
        "searchHint1":
            MessageLookupByLibrary.simpleMessage("Hurtig, søgning på enheden"),
        "selectAll": MessageLookupByLibrary.simpleMessage("Vælg alle"),
        "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
            "Vælg mapper til sikkerhedskopiering"),
        "selectReason": MessageLookupByLibrary.simpleMessage("Vælg årsag"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "Valgte mapper vil blive krypteret og sikkerhedskopieret"),
        "selectedPhotos": m6,
        "sendEmail": MessageLookupByLibrary.simpleMessage("Send email"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Send link"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Angiv adgangskode"),
        "shareTextConfirmOthersVerificationID": m7,
        "showMemories": MessageLookupByLibrary.simpleMessage("Vis minder"),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "Jeg er enig i <u-terms>betingelser for brug</u-terms> og <u-policy>privatlivspolitik</u-policy>"),
        "skip": MessageLookupByLibrary.simpleMessage("Spring over"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Noget gik galt, prøv venligst igen"),
        "sorryCouldNotAddToFavorites": MessageLookupByLibrary.simpleMessage(
            "Beklager, kunne ikke føje til favoritter!"),
        "sorryCouldNotRemoveFromFavorites":
            MessageLookupByLibrary.simpleMessage(
                "Beklager, kunne ikke fjernes fra favoritter!"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "Beklager, vi kunne ikke generere sikre krypteringsnøgler på denne enhed.\n\nForsøg venligst at oprette en konto fra en anden enhed."),
        "status": MessageLookupByLibrary.simpleMessage("Status"),
        "storageInGB": m1,
        "strongStrength": MessageLookupByLibrary.simpleMessage("Stærkt"),
        "subscribe": MessageLookupByLibrary.simpleMessage("Abonner"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "Du skal have et aktivt betalt abonnement for at aktivere deling."),
        "tapToEnterCode":
            MessageLookupByLibrary.simpleMessage("Tryk for at indtaste kode"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Afslut session?"),
        "termsOfServicesTitle":
            MessageLookupByLibrary.simpleMessage("Betingelser"),
        "theyAlsoGetXGb": m8,
        "thisDevice": MessageLookupByLibrary.simpleMessage("Denne enhed"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Dette vil logge dig ud af følgende enhed:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Dette vil logge dig ud af denne enhed!"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "For at nulstille din adgangskode, bekræft venligst din email adresse."),
        "unavailableReferralCode": MessageLookupByLibrary.simpleMessage(
            "Beklager, denne kode er ikke tilgængelig."),
        "unselectAll": MessageLookupByLibrary.simpleMessage("Fravælg alle"),
        "updatingFolderSelection":
            MessageLookupByLibrary.simpleMessage("Opdaterer mappevalg..."),
        "verify": MessageLookupByLibrary.simpleMessage("Bekræft"),
        "viewAddOnButton":
            MessageLookupByLibrary.simpleMessage("Vis tilføjelser"),
        "waitingForWifi":
            MessageLookupByLibrary.simpleMessage("Venter på Wi-fi..."),
        "weHaveSendEmailTo": m2,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Svagt"),
        "welcomeBack":
            MessageLookupByLibrary.simpleMessage("Velkommen tilbage!"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("Ja, fjern"),
        "you": MessageLookupByLibrary.simpleMessage("Dig"),
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("Din konto er blevet slettet")
      };
}
