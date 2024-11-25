// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a no locale. All the
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
  String get localeName => 'no';

  static String m18(count) =>
      "${Intl.plural(count, zero: 'Ingen deltakere', one: '1 deltaker', other: '${count} deltakere')}";

  static String m22(user) =>
      "${user} vil ikke kunne legge til flere bilder til dette albumet\n\nDe vil fortsatt kunne fjerne eksisterende bilder lagt til av dem";

  static String m28(count) =>
      "${Intl.plural(count, one: 'Slett ${count} element', other: 'Slett ${count} elementer')}";

  static String m30(albumName) =>
      "Dette fjerner den offentlige lenken for tilgang til \"${albumName}\".";

  static String m31(supportEmail) =>
      "Vennligst send en e-post til ${supportEmail} fra din registrerte e-postadresse";

  static String m33(count, formattedSize) =>
      "${count} filer, ${formattedSize} hver";

  static String m45(count) =>
      "${Intl.plural(count, one: '${count} element', other: '${count} elementer')}";

  static String m46(expiryTime) => "Lenken utløper på ${expiryTime}";

  static String m9(count, formattedCount) =>
      "${Intl.plural(count, zero: 'ingen minner', one: '${formattedCount} minne', other: '${formattedCount} minner')}";

  static String m0(personName) => "No suggestions for ${personName}";

  static String m6(passwordStrengthValue) =>
      "Passordstyrke: ${passwordStrengthValue}";

  static String m1(count) => "${count} photos";

  static String m2(snapshotLenght, searchLenght) =>
      "Sections length mismatch: ${snapshotLenght} != ${searchLenght}";

  static String m10(count) => "${count} valgt";

  static String m61(count, yourCount) => "${count} valgt (${yourCount} dine)";

  static String m62(verificationID) =>
      "Her er min verifiserings-ID: ${verificationID} for ente.io.";

  static String m11(verificationID) =>
      "Hei, kan du bekrefte at dette er din ente.io verifiserings-ID: ${verificationID}";

  static String m64(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Del med bestemte personer', one: 'Delt med 1 person', other: 'Delt med ${numberOfPeople} personer')}";

  static String m3(ignoreReason) =>
      "Tap to upload, upload is currently ignored due to ${ignoreReason}";

  static String m74(email) => "Dette er ${email} sin verifiserings-ID";

  static String m4(galleryType) =>
      "Type of gallery ${galleryType} is not supported for rename";

  static String m5(ignoreReason) => "Upload is ignored due to ${ignoreReason}";

  static String m78(email) => "Verifiser ${email}";

  static String m8(email) =>
      "Vi har sendt en e-post til <green>${email}</green>";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "accountIsAlreadyConfigured": MessageLookupByLibrary.simpleMessage(
            "Account is already configured."),
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Velkommen tilbake!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Jeg forstår at dersom jeg mister passordet mitt, kan jeg miste dataen min, siden daten er <underline>ende-til-ende-kryptert</underline>."),
        "activeSessions": MessageLookupByLibrary.simpleMessage("Aktive økter"),
        "add": MessageLookupByLibrary.simpleMessage("Add"),
        "addANewEmail":
            MessageLookupByLibrary.simpleMessage("Legg til ny e-post"),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Legg til samarbeidspartner"),
        "addFiles": MessageLookupByLibrary.simpleMessage("Add Files"),
        "addMore": MessageLookupByLibrary.simpleMessage("Legg til flere"),
        "addNew": MessageLookupByLibrary.simpleMessage("Add new"),
        "addViewer": MessageLookupByLibrary.simpleMessage("Legg til seer"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Lagt til som"),
        "advanced": MessageLookupByLibrary.simpleMessage("Avansert"),
        "advancedSettings": MessageLookupByLibrary.simpleMessage("Avansert"),
        "after1Day": MessageLookupByLibrary.simpleMessage("Etter 1 dag"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("Etter 1 time"),
        "after1Month": MessageLookupByLibrary.simpleMessage("Etter 1 måned"),
        "after1Week": MessageLookupByLibrary.simpleMessage("Etter 1 uke"),
        "after1Year": MessageLookupByLibrary.simpleMessage("Etter 1 år"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Eier"),
        "albumParticipantsCount": m18,
        "albumUpdated": MessageLookupByLibrary.simpleMessage("Album oppdatert"),
        "albums": MessageLookupByLibrary.simpleMessage("Album"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Tillat folk med lenken å også legge til bilder til det delte albumet."),
        "allowAddingPhotos":
            MessageLookupByLibrary.simpleMessage("Tillat å legge til bilder"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("Tillat nedlastinger"),
        "apply": MessageLookupByLibrary.simpleMessage("Anvend"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "Hva er hovedårsaken til at du sletter kontoen din?"),
        "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
            "Vennligst autentiser deg for å se dine skjulte filer"),
        "authToViewYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Vennligst autentiser deg for å se gjennopprettingsnøkkelen din"),
        "cancel": MessageLookupByLibrary.simpleMessage("Avbryt"),
        "cannotAddMorePhotosAfterBecomingViewer": m22,
        "castAlbum": MessageLookupByLibrary.simpleMessage("Cast album"),
        "changeEmail":
            MessageLookupByLibrary.simpleMessage("Endre e-postadresse"),
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
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Bytt passord"),
        "changePermissions":
            MessageLookupByLibrary.simpleMessage("Endre tillatelser?"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Sjekk innboksen din (og spam) for å fullføre verifikasjonen"),
        "clearIndexes": MessageLookupByLibrary.simpleMessage("Tøm indekser"),
        "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Kode kopiert til utklippstavlen"),
        "collaborativeLink":
            MessageLookupByLibrary.simpleMessage("Samarbeidslenke"),
        "collaborator":
            MessageLookupByLibrary.simpleMessage("Samarbeidspartner"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Samarbeidspartnere kan legge til bilder og videoer i det delte albumet."),
        "collectPhotos": MessageLookupByLibrary.simpleMessage("Samle bilder"),
        "confirm": MessageLookupByLibrary.simpleMessage("Bekreft"),
        "confirmAccountDeletion":
            MessageLookupByLibrary.simpleMessage("Bekreft sletting av konto"),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Bekreft passordet"),
        "confirmRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Bekreft gjenopprettingsnøkkel"),
        "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Bekreft din gjenopprettingsnøkkel"),
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("Kontakt kundestøtte"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("Fortsett"),
        "copyLink": MessageLookupByLibrary.simpleMessage("Kopier lenke"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Kopier og lim inn denne koden\ntil autentiseringsappen din"),
        "createAccount": MessageLookupByLibrary.simpleMessage("Opprett konto"),
        "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
            "Trykk og holde inne for å velge bilder, og trykk på + for å lage et album"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("Opprett ny konto"),
        "createPublicLink":
            MessageLookupByLibrary.simpleMessage("Opprett offentlig lenke"),
        "currentlyRunning":
            MessageLookupByLibrary.simpleMessage("currently running"),
        "custom": MessageLookupByLibrary.simpleMessage("Egendefinert"),
        "decrypting": MessageLookupByLibrary.simpleMessage("Dekrypterer..."),
        "deleteAccount": MessageLookupByLibrary.simpleMessage("Slett konto"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "Vi er lei oss for at du forlater oss. Gi oss gjerne en tilbakemelding så vi kan forbedre oss."),
        "deleteAccountPermanentlyButton":
            MessageLookupByLibrary.simpleMessage("Slett bruker for altid"),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "Vennligst send en e-post til <warning>account-deletion@ente.io</warning> fra din registrerte e-postadresse."),
        "deleteFromBoth":
            MessageLookupByLibrary.simpleMessage("Slett fra begge"),
        "deleteFromDevice":
            MessageLookupByLibrary.simpleMessage("Slett fra enhet"),
        "deleteItemCount": m28,
        "deletePhotos": MessageLookupByLibrary.simpleMessage("Slett bilder"),
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "Det mangler en hovedfunksjon jeg trenger"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "Appen, eller en bestemt funksjon, fungerer ikke slik jeg tror den skal"),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
            "Jeg fant en annen tjeneste jeg liker bedre"),
        "deleteReason4":
            MessageLookupByLibrary.simpleMessage("Grunnen min er ikke listet"),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
            "Forespørselen din vil bli behandlet innen 72 timer."),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Seere kan fremdeles ta skjermbilder eller lagre en kopi av bildene dine ved bruk av eksterne verktøy"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Vær oppmerksom på"),
        "disableLinkMessage": m30,
        "doThisLater":
            MessageLookupByLibrary.simpleMessage("Gjør dette senere"),
        "done": MessageLookupByLibrary.simpleMessage("Ferdig"),
        "dropSupportEmail": m31,
        "duplicateItemsGroup": m33,
        "edit": MessageLookupByLibrary.simpleMessage("Edit"),
        "email": MessageLookupByLibrary.simpleMessage("E-post"),
        "encryption": MessageLookupByLibrary.simpleMessage("Kryptering"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Krypteringsnøkkel"),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
            "Ente <i>trenger tillatelse</i> for å bevare bildene dine"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Angi kode"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
            "Angi koden fra vennen din for å få gratis lagringsplass for dere begge"),
        "enterEmail": MessageLookupByLibrary.simpleMessage("Skriv inn e-post"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Angi et nytt passord vi kan bruke til å kryptere dataene dine"),
        "enterPassword": MessageLookupByLibrary.simpleMessage("Angi passord"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Angi et passord vi kan bruke til å kryptere dataene dine"),
        "enterReferralCode":
            MessageLookupByLibrary.simpleMessage("Angi vervekode"),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Skriv inn den 6-sifrede koden fra\ndin autentiseringsapp"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "Vennligst skriv inn en gyldig e-postadresse."),
        "enterYourEmailAddress": MessageLookupByLibrary.simpleMessage(
            "Skriv inn e-postadressen din"),
        "enterYourPassword":
            MessageLookupByLibrary.simpleMessage("Angi passordet ditt"),
        "enterYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Skriv inn din gjenopprettingsnøkkel"),
        "error": MessageLookupByLibrary.simpleMessage("Error"),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
            "Denne lenken er utløpt. Vennligst velg en ny utløpstid eller deaktiver lenkeutløp."),
        "failedToFetchActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Failed to fetch active sessions"),
        "faceNotClusteredYet": MessageLookupByLibrary.simpleMessage(
            "Face not clustered yet, please come back later"),
        "failedToLoadAlbums":
            MessageLookupByLibrary.simpleMessage("Kunne ikke laste inn album"),
        "failedToPlayVideo":
            MessageLookupByLibrary.simpleMessage("Failed to play video"),
        "failedToRefreshStripeSubscription":
            MessageLookupByLibrary.simpleMessage(
                "Failed to refresh subscription"),
        "familyPlans":
            MessageLookupByLibrary.simpleMessage("Familieabonnementer"),
        "feedback": MessageLookupByLibrary.simpleMessage("Tilbakemelding"),
        "file": MessageLookupByLibrary.simpleMessage("File"),
        "fileNotUploadedYet":
            MessageLookupByLibrary.simpleMessage("File not uploaded yet"),
        "forgotPassword": MessageLookupByLibrary.simpleMessage("Glemt passord"),
        "general": MessageLookupByLibrary.simpleMessage("Generelt"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Genererer krypteringsnøkler..."),
        "hidden": MessageLookupByLibrary.simpleMessage("Skjult"),
        "howItWorks":
            MessageLookupByLibrary.simpleMessage("Hvordan det fungerer"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "Vennligst be dem om å trykke og holde inne på e-postadressen sin på innstillingsskjermen, og bekreft at ID-ene på begge enhetene er like."),
        "ignored": MessageLookupByLibrary.simpleMessage("ignored"),
        "imageNotAnalyzed":
            MessageLookupByLibrary.simpleMessage("Image not analyzed"),
        "importing": MessageLookupByLibrary.simpleMessage("Importerer...."),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Feil passord"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "Gjennopprettingsnøkkelen du skrev inn er feil"),
        "incorrectRecoveryKeyTitle":
            MessageLookupByLibrary.simpleMessage("Feil gjenopprettingsnøkkel"),
        "indexedItems":
            MessageLookupByLibrary.simpleMessage("Indekserte elementer"),
        "info": MessageLookupByLibrary.simpleMessage("Info"),
        "insecureDevice": MessageLookupByLibrary.simpleMessage("Usikker enhet"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("Ugyldig e-postadresse"),
        "invalidKey": MessageLookupByLibrary.simpleMessage("Ugyldig nøkkel"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Gjenopprettingsnøkkelen du har skrevet inn er ikke gyldig. Kontroller at den inneholder 24 ord og kontroller stavemåten av hvert ord.\n\nHvis du har angitt en eldre gjenopprettingskode, må du kontrollere at den er 64 tegn lang, og kontrollere hvert av dem."),
        "itemCount": m45,
        "keepPhotos": MessageLookupByLibrary.simpleMessage("Behold Bilder"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Vær vennlig og hjelp oss med denne informasjonen"),
        "linkDeviceLimit": MessageLookupByLibrary.simpleMessage("Enhetsgrense"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Aktivert"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Utløpt"),
        "linkExpiresOn": m46,
        "linkExpiry": MessageLookupByLibrary.simpleMessage("Lenkeutløp"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("Lenken har utløpt"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Aldri"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Lås"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Logg inn"),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "Ved å klikke Logg inn, godtar jeg <u-terms>brukervilkårene</u-terms> og <u-policy>personvernreglene</u-policy>"),
        "lostDevice": MessageLookupByLibrary.simpleMessage("Mistet enhet?"),
        "machineLearning": MessageLookupByLibrary.simpleMessage("Maskinlæring"),
        "magicSearch": MessageLookupByLibrary.simpleMessage("Magisk søk"),
        "manage": MessageLookupByLibrary.simpleMessage("Administrer"),
        "manageDeviceStorage":
            MessageLookupByLibrary.simpleMessage("Behandle enhetslagring"),
        "manageLink": MessageLookupByLibrary.simpleMessage("Administrer lenke"),
        "manageParticipants":
            MessageLookupByLibrary.simpleMessage("Administrer"),
        "memoryCount": m9,
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Moderat"),
        "month": MessageLookupByLibrary.simpleMessage("month"),
        "monthly": MessageLookupByLibrary.simpleMessage("Monthly"),
        "movedToTrash":
            MessageLookupByLibrary.simpleMessage("Flyttet til papirkurven"),
        "never": MessageLookupByLibrary.simpleMessage("Aldri"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Nytt album"),
        "newLocation": MessageLookupByLibrary.simpleMessage("New location"),
        "noDeviceLimit": MessageLookupByLibrary.simpleMessage("Ingen"),
        "noFacesFound": MessageLookupByLibrary.simpleMessage("No faces found"),
        "noInternetConnection":
            MessageLookupByLibrary.simpleMessage("No internet connection"),
        "noRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Ingen gjenopprettingsnøkkel?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "Grunnet vår type ente-til-ende-krypteringsprotokoll kan ikke dine data dekrypteres uten passordet ditt eller gjenopprettingsnøkkelen din"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("No results found"),
        "noSuggestionsForPerson": m0,
        "notifications": MessageLookupByLibrary.simpleMessage("Varslinger"),
        "ok": MessageLookupByLibrary.simpleMessage("Ok"),
        "onlyThem": MessageLookupByLibrary.simpleMessage("Only them"),
        "oops": MessageLookupByLibrary.simpleMessage("Oisann"),
        "orPickAnExistingOne":
            MessageLookupByLibrary.simpleMessage("Eller velg en eksisterende"),
        "password": MessageLookupByLibrary.simpleMessage("Passord"),
        "passwordChangedSuccessfully":
            MessageLookupByLibrary.simpleMessage("Passordet ble endret"),
        "passwordLock": MessageLookupByLibrary.simpleMessage("Passordlås"),
        "passwordStrength": m6,
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Vi lagrer ikke dette passordet, så hvis du glemmer det, <underline>kan vi ikke dekryptere dataene dine</underline>"),
        "pendingItems":
            MessageLookupByLibrary.simpleMessage("Ventende elementer"),
        "photoGridSize":
            MessageLookupByLibrary.simpleMessage("Bilderutenettstørrelse"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("bilde"),
        "photosCount": m1,
        "pleaseCheckYourInternetConnectionAndTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Please check your internet connection and try again."),
        "pleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("Vennligst prøv igjen"),
        "pleaseWait": MessageLookupByLibrary.simpleMessage("Vennligst vent..."),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Personvernserklæring"),
        "publicLinkEnabled":
            MessageLookupByLibrary.simpleMessage("Offentlig lenke aktivert"),
        "recover": MessageLookupByLibrary.simpleMessage("Gjenopprett"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("Gjenopprett konto"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Gjenopprett"),
        "recoveryKey":
            MessageLookupByLibrary.simpleMessage("Gjenopprettingsnøkkel"),
        "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Gjenopprettingsnøkkel kopiert til utklippstavlen"),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
            "Hvis du glemmer passordet ditt er den eneste måten du kan gjenopprette dataene dine på med denne nøkkelen."),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
            "Vi lagrer ikke denne nøkkelen, vennligst lagre denne 24-ords nøkkelen på et trygt sted."),
        "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
            "Flott! Din gjenopprettingsnøkkel er gyldig. Takk for bekreftelsen.\n\nVennligst husk å holde gjenopprettingsnøkkelen din trygt sikkerhetskopiert."),
        "recoveryKeyVerified": MessageLookupByLibrary.simpleMessage(
            "Gjenopprettingsnøkkel bekreftet"),
        "recoverySuccessful": MessageLookupByLibrary.simpleMessage(
            "Gjenopprettingen var vellykket!"),
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "Den gjeldende enheten er ikke kraftig nok til å verifisere passordet ditt, men vi kan regenerere på en måte som fungerer på alle enheter.\n\nVennligst logg inn med gjenopprettingsnøkkelen og regenerer passordet (du kan bruke den samme igjen om du vil)."),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Gjenopprett passord"),
        "referrals": MessageLookupByLibrary.simpleMessage("Vervinger"),
        "remindToEmptyEnteTrash": MessageLookupByLibrary.simpleMessage(
            "Du kan også tømme \"Papirkurven\" for å få den frigjorte lagringsplassen"),
        "remove": MessageLookupByLibrary.simpleMessage("Fjern"),
        "removeLink": MessageLookupByLibrary.simpleMessage("Fjern lenke"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Fjern deltaker"),
        "removePublicLink":
            MessageLookupByLibrary.simpleMessage("Fjern offentlig lenke"),
        "resendEmail":
            MessageLookupByLibrary.simpleMessage("Send e-posten på nytt"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Tilbakestill passord"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Lagre nøkkel"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Lagre gjenopprettingsnøkkelen hvis du ikke allerede har gjort det"),
        "scanCode": MessageLookupByLibrary.simpleMessage("Skann kode"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Skann denne strekkoden med\nautentiseringsappen din"),
        "searchSectionsLengthMismatch": m2,
        "security": MessageLookupByLibrary.simpleMessage("Sikkerhet"),
        "selectAll": MessageLookupByLibrary.simpleMessage("Velg alle"),
        "selectAllShort": MessageLookupByLibrary.simpleMessage("All"),
        "selectCoverPhoto":
            MessageLookupByLibrary.simpleMessage("Select cover photo"),
        "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
            "Velg mapper for sikkerhetskopiering"),
        "selectMailApp":
            MessageLookupByLibrary.simpleMessage("Select mail app"),
        "selectReason": MessageLookupByLibrary.simpleMessage("Velg grunn"),
        "selectYourPlan":
            MessageLookupByLibrary.simpleMessage("Select your plan"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "Valgte mapper vil bli kryptert og sikkerhetskopiert"),
        "selectedPhotos": m10,
        "selectedPhotosWithYours": m61,
        "sendEmail": MessageLookupByLibrary.simpleMessage("Send e-post"),
        "sendInvite": MessageLookupByLibrary.simpleMessage("Send invitasjon"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Send lenke"),
        "sessionExpired":
            MessageLookupByLibrary.simpleMessage("Session expired"),
        "sessionIdMismatch":
            MessageLookupByLibrary.simpleMessage("Session ID mismatch"),
        "setAPassword": MessageLookupByLibrary.simpleMessage("Lag et passord"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Lag et passord"),
        "setupComplete":
            MessageLookupByLibrary.simpleMessage("Oppsett fullført"),
        "share": MessageLookupByLibrary.simpleMessage("Share"),
        "shareALink": MessageLookupByLibrary.simpleMessage("Del en lenke"),
        "shareMyVerificationID": m62,
        "shareTextConfirmOthersVerificationID": m11,
        "shareWithPeopleSectionTitle": m64,
        "sharedPhotoNotifications":
            MessageLookupByLibrary.simpleMessage("Nye delte bilder"),
        "sharedPhotoNotificationsExplanation": MessageLookupByLibrary.simpleMessage(
            "Motta varsler når noen legger til et bilde i et delt album som du er en del av"),
        "sharing": MessageLookupByLibrary.simpleMessage("Deler..."),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "Jeg godtar <u-terms>bruksvilkårene</u-terms> og <u-policy>personvernreglene</u-policy>"),
        "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
            "Den vil bli slettet fra alle album."),
        "skip": MessageLookupByLibrary.simpleMessage("Hopp over"),
        "someoneSharingAlbumsWithYouShouldSeeTheSameId":
            MessageLookupByLibrary.simpleMessage(
                "Folk som deler album med deg bør se den samme ID-en på deres enhet."),
        "somethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Noe gikk galt"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Noe gikk galt. Vennligst prøv igjen"),
        "sorry": MessageLookupByLibrary.simpleMessage("Beklager"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "Beklager, vi kunne ikke generere sikre nøkler på denne enheten.\n\nvennligst registrer deg fra en annen enhet."),
        "sparkleSuccess": MessageLookupByLibrary.simpleMessage("✨ Suksess"),
        "status": MessageLookupByLibrary.simpleMessage("Status"),
        "strongStrength": MessageLookupByLibrary.simpleMessage("Sterkt"),
        "subscription": MessageLookupByLibrary.simpleMessage("Subscription"),
        "tapToCopy":
            MessageLookupByLibrary.simpleMessage("trykk for å kopiere"),
        "tapToEnterCode":
            MessageLookupByLibrary.simpleMessage("Trykk for å angi kode"),
        "tapToUpload": MessageLookupByLibrary.simpleMessage("Tap to upload"),
        "tapToUploadIsIgnoredDue": m3,
        "terminate": MessageLookupByLibrary.simpleMessage("Avslutte"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Avslutte økten?"),
        "termsOfServicesTitle": MessageLookupByLibrary.simpleMessage("Vilkår"),
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "Dette kan brukes til å gjenopprette kontoen din hvis du mister din andre faktor"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Denne enheten"),
        "thisIsPersonVerificationId": m74,
        "thisIsYourVerificationId": MessageLookupByLibrary.simpleMessage(
            "Dette er din bekreftelses-ID"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Dette vil logge deg ut av følgende enhet:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Dette vil logge deg ut av denne enheten!"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "For å tilbakestille passordet ditt, vennligt bekreft e-posten din først."),
        "trash": MessageLookupByLibrary.simpleMessage("Papirkurv"),
        "tryAgain": MessageLookupByLibrary.simpleMessage("Prøv igjen"),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage("Tofaktorautentisering"),
        "twofactorSetup":
            MessageLookupByLibrary.simpleMessage("Oppsett av to-faktor"),
        "typeOfGallerGallerytypeIsNotSupportedForRename": m4,
        "uncategorized": MessageLookupByLibrary.simpleMessage("Ukategorisert"),
        "unselectAll": MessageLookupByLibrary.simpleMessage("Velg bort alle"),
        "updatingFolderSelection":
            MessageLookupByLibrary.simpleMessage("Oppdaterer mappevalg..."),
        "uploadIsIgnoredDueToIgnorereason": m5,
        "useRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Bruk gjenopprettingsnøkkel"),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("Verifiserings-ID"),
        "verify": MessageLookupByLibrary.simpleMessage("Bekreft"),
        "verifyEmail":
            MessageLookupByLibrary.simpleMessage("Bekreft e-postadresse"),
        "verifyEmailID": m78,
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Bekreft passord"),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Verifiserer gjenopprettingsnøkkel..."),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("video"),
        "viewRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Vis gjenopprettingsnøkkel"),
        "viewer": MessageLookupByLibrary.simpleMessage("Seer"),
        "weHaveSendEmailTo": m8,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Svakt"),
        "welcomeBack":
            MessageLookupByLibrary.simpleMessage("Velkommen tilbake!"),
        "yearShort": MessageLookupByLibrary.simpleMessage("yr"),
        "yearly": MessageLookupByLibrary.simpleMessage("Yearly"),
        "yesConvertToViewer":
            MessageLookupByLibrary.simpleMessage("Ja, konverter til seer"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("Ja, slett"),
        "you": MessageLookupByLibrary.simpleMessage("Deg"),
        "youCannotShareWithYourself": MessageLookupByLibrary.simpleMessage(
            "Du kan ikke dele med deg selv"),
        "yourAccountHasBeenDeleted": MessageLookupByLibrary.simpleMessage(
            "Brukeren din har blitt slettet"),
        "yourMap": MessageLookupByLibrary.simpleMessage("Your Map")
      };
}
