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

  static String m13(user) =>
      "${user} vil ikke kunne tilføje flere billeder til dette album\n\nDe vil stadig kunne fjerne eksisterende billeder tilføjet af dem";

  static String m25(supportEmail) =>
      "Send venligst en email til ${supportEmail} fra din registrerede email adresse";

  static String m37(storageAmountInGB) =>
      "${storageAmountInGB} GB hver gang nogen tilmelder sig et betalt abonnement og anvender din kode";

  static String m47(expiryTime) => "Link udløber den ${expiryTime}";

  static String m57(passwordStrengthValue) =>
      "Kodeordets styrke: ${passwordStrengthValue}";

  static String m80(count) => "${count} valgt";

  static String m84(verificationID) =>
      "Hey, kan du bekræfte, at dette er dit ente.io verifikation ID: ${verificationID}";

  static String m93(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m99(storageAmountInGB) => "De får også ${storageAmountInGB} GB";

  static String m114(email) =>
      "Vi har sendt en email til <green>${email}</green>";

  static String m115(name) => "Wish \$${name} a happy birthday! 🎉";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Velkommen tilbage!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Jeg forstår at hvis jeg mister min adgangskode kan jeg miste mine data, da mine data er <underline>end-to-end krypteret</underline>."),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Aktive sessioner"),
        "addANewEmail":
            MessageLookupByLibrary.simpleMessage("Tilføj en ny e-mail"),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Tilføj samarbejdspartner"),
        "addMore": MessageLookupByLibrary.simpleMessage("Tilføj flere"),
        "addOnPageSubtitle":
            MessageLookupByLibrary.simpleMessage("Oplysninger om tilføjelser"),
        "addViewer": MessageLookupByLibrary.simpleMessage("Tilføj seer"),
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
        "albumUpdated":
            MessageLookupByLibrary.simpleMessage("Album er opdateret"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Tillad personer med linket også at tilføje billeder til det delte album."),
        "allowAddingPhotos":
            MessageLookupByLibrary.simpleMessage("Tillad tilføjelse af fotos"),
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
        "cannotAddMorePhotosAfterBecomingViewer": m13,
        "cannotDeleteSharedFiles":
            MessageLookupByLibrary.simpleMessage("Kan ikke slette delte filer"),
        "changeEmail":
            MessageLookupByLibrary.simpleMessage("Skift email adresse"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Skift adgangskode"),
        "changePermissions":
            MessageLookupByLibrary.simpleMessage("Rediger rettigheder?"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Tjek venligst din indbakke (og spam) for at færdiggøre verificeringen"),
        "clearIndexes": MessageLookupByLibrary.simpleMessage("Ryd indekser"),
        "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Kode kopieret til udklipsholder"),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Opret et link, så folk kan tilføje og se fotos i dit delte album uden at behøve en Ente-app eller konto. Fantastisk til at indsamle event fotos."),
        "collaborativeLink":
            MessageLookupByLibrary.simpleMessage("Kollaborativt link"),
        "collectPhotos":
            MessageLookupByLibrary.simpleMessage("Indsaml billeder"),
        "confirm": MessageLookupByLibrary.simpleMessage("Bekræft"),
        "confirmAccountDeletion":
            MessageLookupByLibrary.simpleMessage("Bekræft Sletning Af Konto"),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Bekræft adgangskode"),
        "confirmRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Bekræft gendannelsesnøgle"),
        "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Bekræft din gendannelsesnøgle"),
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("Kontakt support"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("Fortsæt"),
        "copyLink": MessageLookupByLibrary.simpleMessage("Kopiér link"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Kopiér denne kode\ntil din autentificeringsapp"),
        "couldNotUpdateSubscription": MessageLookupByLibrary.simpleMessage(
            "Abonnementet kunne ikke opdateres."),
        "createAccount": MessageLookupByLibrary.simpleMessage("Opret konto"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("Opret en ny konto"),
        "createPublicLink":
            MessageLookupByLibrary.simpleMessage("Opret et offentligt link"),
        "creatingLink":
            MessageLookupByLibrary.simpleMessage("Opretter link..."),
        "custom": MessageLookupByLibrary.simpleMessage("Tilpasset"),
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
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "App\'en eller en bestemt funktion virker ikke som den skal"),
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
        "doThisLater": MessageLookupByLibrary.simpleMessage("Gør det senere"),
        "dropSupportEmail": m25,
        "eligible": MessageLookupByLibrary.simpleMessage("kvalificeret"),
        "email": MessageLookupByLibrary.simpleMessage("Email"),
        "emailAlreadyRegistered": MessageLookupByLibrary.simpleMessage(
            "E-mail er allerede registreret."),
        "emailNotRegistered":
            MessageLookupByLibrary.simpleMessage("E-mail er ikke registreret."),
        "encryption": MessageLookupByLibrary.simpleMessage("Kryptering"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Krypteringsnøgler"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Indtast kode"),
        "enterEmail":
            MessageLookupByLibrary.simpleMessage("Indtast email adresse"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Indtast en ny adgangskode vi kan bruge til at kryptere dine data"),
        "enterPassword":
            MessageLookupByLibrary.simpleMessage("Indtast adgangskode"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Indtast en adgangskode vi kan bruge til at kryptere dine data"),
        "enterPin": MessageLookupByLibrary.simpleMessage("Indtast PIN"),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Indtast den 6-cifrede kode fra din autentificeringsapp"),
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
        "freeStorageOnReferralSuccess": m37,
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
        "invalidKey": MessageLookupByLibrary.simpleMessage("Ugyldig nøgle"),
        "invite": MessageLookupByLibrary.simpleMessage("Inviter"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Inviter dine venner"),
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "Valgte elementer vil blive fjernet fra dette album"),
        "keepPhotos": MessageLookupByLibrary.simpleMessage("Behold billeder"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Hjælp os venligst med disse oplysninger"),
        "linkDeviceLimit":
            MessageLookupByLibrary.simpleMessage("Enheds grænse"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Aktiveret"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Udløbet"),
        "linkExpiresOn": m47,
        "linkExpiry": MessageLookupByLibrary.simpleMessage("Udløb af link"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("Linket er udløbet"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Aldrig"),
        "loadingModel":
            MessageLookupByLibrary.simpleMessage("Downloader modeller..."),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Lås"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Log ind"),
        "loggingOut": MessageLookupByLibrary.simpleMessage("Logger ud..."),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "Ved at klikke på log ind accepterer jeg <u-terms>vilkårene for service</u-terms> og <u-policy>privatlivspolitik</u-policy>"),
        "longPressAnEmailToVerifyEndToEndEncryption":
            MessageLookupByLibrary.simpleMessage(
                "Langt tryk på en e-mail for at bekræfte slutningen af krypteringen."),
        "lostDevice":
            MessageLookupByLibrary.simpleMessage("Har du mistet enhed?"),
        "machineLearning": MessageLookupByLibrary.simpleMessage("Maskinlæring"),
        "magicSearch": MessageLookupByLibrary.simpleMessage("Magisk søgning"),
        "manage": MessageLookupByLibrary.simpleMessage("Administrér"),
        "manageDeviceStorageDesc": MessageLookupByLibrary.simpleMessage(
            "Gennemgå og ryd lokal cache-lagring."),
        "manageParticipants":
            MessageLookupByLibrary.simpleMessage("Administrer"),
        "mlConsent":
            MessageLookupByLibrary.simpleMessage("Aktiver maskinlæring"),
        "mlConsentPrivacy": MessageLookupByLibrary.simpleMessage(
            "Klik her for flere detaljer om denne funktion i vores privatlivspolitik"),
        "mlConsentTitle":
            MessageLookupByLibrary.simpleMessage("Aktiver maskinlæring?"),
        "mlIndexingDescription": MessageLookupByLibrary.simpleMessage(
            "Bemærk venligst, at maskinindlæring vil resultere i en højere båndbredde og batteriforbrug, indtil alle elementer er indekseret. Overvej at bruge desktop app til hurtigere indeksering, vil alle resultater blive synkroniseret automatisk."),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Moderat"),
        "moments": MessageLookupByLibrary.simpleMessage("Øjeblikke"),
        "never": MessageLookupByLibrary.simpleMessage("Aldrig"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Nyt album"),
        "next": MessageLookupByLibrary.simpleMessage("Næste"),
        "noDeviceLimit": MessageLookupByLibrary.simpleMessage("Ingen"),
        "noRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Ingen gendannelsesnøgle?"),
        "ok": MessageLookupByLibrary.simpleMessage("Ok"),
        "oops": MessageLookupByLibrary.simpleMessage("Ups"),
        "oopsSomethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Ups, noget gik galt"),
        "orPickAnExistingOne":
            MessageLookupByLibrary.simpleMessage("Eller vælg en eksisterende"),
        "password": MessageLookupByLibrary.simpleMessage("Adgangskode"),
        "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
            "Adgangskoden er blevet ændret"),
        "passwordLock": MessageLookupByLibrary.simpleMessage("Adgangskodelås"),
        "passwordStrength": m57,
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Vi gemmer ikke denne adgangskode, så hvis du glemmer den <underline>kan vi ikke dekryptere dine data</underline>"),
        "pendingItems":
            MessageLookupByLibrary.simpleMessage("Afventende elementer"),
        "peopleUsingYourCode": MessageLookupByLibrary.simpleMessage(
            "Personer, der bruger din kode"),
        "pleaseContactSupportAndWeWillBeHappyToHelp":
            MessageLookupByLibrary.simpleMessage(
                "Kontakt support@ente.io og vi vil være glade for at hjælpe!"),
        "pleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("Prøv venligst igen"),
        "pleaseWait": MessageLookupByLibrary.simpleMessage("Vent venligst..."),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Privatlivspolitik"),
        "publicLinkEnabled":
            MessageLookupByLibrary.simpleMessage("Offentligt link aktiveret"),
        "recover": MessageLookupByLibrary.simpleMessage("Gendan"),
        "recoverAccount": MessageLookupByLibrary.simpleMessage("Gendan konto"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Gendan"),
        "recoveryKey":
            MessageLookupByLibrary.simpleMessage("Gendannelse nøgle"),
        "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Gendannelsesnøgle kopieret til udklipsholder"),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
            "Hvis du glemmer din adgangskode, den eneste måde, du kan gendanne dine data er med denne nøgle."),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
            "Vi gemmer ikke denne nøgle, gem venligst denne 24 ord nøgle på et sikkert sted."),
        "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
            "Super! Din gendannelsesnøgle er gyldig. Tak fordi du verificerer.\n\nHusk at holde din gendannelsesnøgle sikker sikkerhedskopieret."),
        "recoveryKeyVerified":
            MessageLookupByLibrary.simpleMessage("Gendannelsesnøgle bekræftet"),
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("Gendannelse lykkedes!"),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Genskab adgangskode"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "2. De tilmelder sig en betalt plan"),
        "remove": MessageLookupByLibrary.simpleMessage("Fjern"),
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
        "saveKey": MessageLookupByLibrary.simpleMessage("Gem nøgle"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Gem din gendannelsesnøgle, hvis du ikke allerede har"),
        "scanCode": MessageLookupByLibrary.simpleMessage("Skan kode"),
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
        "selectedPhotos": m80,
        "sendEmail": MessageLookupByLibrary.simpleMessage("Send email"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Send link"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Angiv adgangskode"),
        "setupComplete":
            MessageLookupByLibrary.simpleMessage("Opsætning fuldført"),
        "shareALink": MessageLookupByLibrary.simpleMessage("Del et link"),
        "shareTextConfirmOthersVerificationID": m84,
        "shareWithNonenteUsers":
            MessageLookupByLibrary.simpleMessage("Del med ikke Ente brugere"),
        "showMemories": MessageLookupByLibrary.simpleMessage("Vis minder"),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "Jeg er enig i <u-terms>betingelser for brug</u-terms> og <u-policy>privatlivspolitik</u-policy>"),
        "skip": MessageLookupByLibrary.simpleMessage("Spring over"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Noget gik galt, prøv venligst igen"),
        "sorry": MessageLookupByLibrary.simpleMessage("Beklager"),
        "sorryCouldNotAddToFavorites": MessageLookupByLibrary.simpleMessage(
            "Beklager, kunne ikke føje til favoritter!"),
        "sorryCouldNotRemoveFromFavorites":
            MessageLookupByLibrary.simpleMessage(
                "Beklager, kunne ikke fjernes fra favoritter!"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "Beklager, vi kunne ikke generere sikre krypteringsnøgler på denne enhed.\n\nForsøg venligst at oprette en konto fra en anden enhed."),
        "status": MessageLookupByLibrary.simpleMessage("Status"),
        "storageInGB": m93,
        "strongStrength": MessageLookupByLibrary.simpleMessage("Stærkt"),
        "subscribe": MessageLookupByLibrary.simpleMessage("Abonner"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "Du skal have et aktivt betalt abonnement for at aktivere deling."),
        "tapToCopy":
            MessageLookupByLibrary.simpleMessage("tryk for at kopiere"),
        "tapToEnterCode":
            MessageLookupByLibrary.simpleMessage("Tryk for at indtaste kode"),
        "terminate": MessageLookupByLibrary.simpleMessage("Afbryd"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Afslut session?"),
        "termsOfServicesTitle":
            MessageLookupByLibrary.simpleMessage("Betingelser"),
        "theyAlsoGetXGb": m99,
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "Dette kan bruges til at gendanne din konto, hvis du mister din anden faktor"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Denne enhed"),
        "thisIsYourVerificationId": MessageLookupByLibrary.simpleMessage(
            "Dette er dit bekræftelses-ID"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Dette vil logge dig ud af følgende enhed:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Dette vil logge dig ud af denne enhed!"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "For at nulstille din adgangskode, bekræft venligst din email adresse."),
        "tryAgain": MessageLookupByLibrary.simpleMessage("Prøv igen"),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage("To-faktor-godkendelse"),
        "twofactorSetup":
            MessageLookupByLibrary.simpleMessage("To-faktor opsætning"),
        "unavailableReferralCode": MessageLookupByLibrary.simpleMessage(
            "Beklager, denne kode er ikke tilgængelig."),
        "unselectAll": MessageLookupByLibrary.simpleMessage("Fravælg alle"),
        "updatingFolderSelection":
            MessageLookupByLibrary.simpleMessage("Opdaterer mappevalg..."),
        "useRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Brug gendannelsesnøgle"),
        "verify": MessageLookupByLibrary.simpleMessage("Bekræft"),
        "verifyEmail": MessageLookupByLibrary.simpleMessage("Bekræft e-mail"),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Bekræft adgangskode"),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Verificerer gendannelsesnøgle..."),
        "viewAddOnButton":
            MessageLookupByLibrary.simpleMessage("Vis tilføjelser"),
        "viewRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Vis gendannelsesnøgle"),
        "viewer": MessageLookupByLibrary.simpleMessage("Seer"),
        "waitingForWifi":
            MessageLookupByLibrary.simpleMessage("Venter på Wi-fi..."),
        "weHaveSendEmailTo": m114,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Svagt"),
        "welcomeBack":
            MessageLookupByLibrary.simpleMessage("Velkommen tilbage!"),
        "wishThemAHappyBirthday": m115,
        "yesConvertToViewer": MessageLookupByLibrary.simpleMessage(
            "Ja, konverter til præsentation"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("Ja, fjern"),
        "you": MessageLookupByLibrary.simpleMessage("Dig"),
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("Din konto er blevet slettet")
      };
}
