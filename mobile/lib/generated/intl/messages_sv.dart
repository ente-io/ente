// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a sv locale. All the
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
  String get localeName => 'sv';

  static String m10(count) =>
      "${Intl.plural(count, one: 'Lägg till objekt', other: 'Lägg till objekt')}";

  static String m15(count) =>
      "${Intl.plural(count, zero: 'Inga deltagare', one: '1 deltagare', other: '${count} deltagare')}";

  static String m16(versionValue) => "Version: ${versionValue}";

  static String m17(freeAmount, storageUnit) =>
      "${freeAmount} ${storageUnit} gratis";

  static String m3(user) =>
      "${user} kommer inte att kunna lägga till fler foton till detta album\n\nDe kommer fortfarande att kunna ta bort befintliga foton som lagts till av dem";

  static String m26(count) =>
      "${Intl.plural(count, one: 'Radera ${count} objekt', other: 'Radera ${count} objekt')}";

  static String m29(supportEmail) =>
      "Vänligen skicka ett e-postmeddelande till ${supportEmail} från din registrerade e-postadress";

  static String m33(email) =>
      "${email} har inte ett Ente-konto.\n\nSkicka dem en inbjudan för att dela bilder.";

  static String m42(count) =>
      "${Intl.plural(count, one: '${count} objekt', other: '${count} objekt')}";

  static String m44(expiryTime) => "Länken upphör att gälla ${expiryTime}";

  static String m45(count) =>
      "${Intl.plural(count, one: 'Flytta objekt', other: 'Flytta objekt')}";

  static String m48(name) => "Inte ${name}?";

  static String m49(familyAdminEmail) =>
      "Kontakta ${familyAdminEmail} för att ändra din kod.";

  static String m0(passwordStrengthValue) =>
      "Lösenordsstyrka: ${passwordStrengthValue}";

  static String m56(storeName) => "Betygsätt oss på ${storeName}";

  static String m63(count) =>
      "${Intl.plural(count, one: '${count} resultat hittades', other: '${count} resultat hittades')}";

  static String m66(verificationID) =>
      "Här är mitt verifierings-ID: ${verificationID} för ente.io.";

  static String m7(verificationID) =>
      "Hallå, kan du bekräfta att detta är ditt ente.io verifierings-ID: ${verificationID}";

  static String m68(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Dela med specifika personer', one: 'Delad med en person', other: 'Delad med ${numberOfPeople} personer')}";

  static String m1(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m78(email) => "Detta är ${email}s verifierings-ID";

  static String m83(count) => "Bevarar ${count} minnen...";

  static String m85(email) => "Bekräfta ${email}";

  static String m2(email) =>
      "Vi har skickat ett e-postmeddelande till <green>${email}</green>";

  static String m87(count) =>
      "${Intl.plural(count, one: '${count} år sedan', other: '${count} år sedan')}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable": MessageLookupByLibrary.simpleMessage(
            "En ny version av Ente är tillgänglig."),
        "about": MessageLookupByLibrary.simpleMessage("Om"),
        "account": MessageLookupByLibrary.simpleMessage("Konto"),
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Välkommen tillbaka!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Jag förstår att om jag förlorar mitt lösenord kan jag förlora mina data eftersom min data är <underline>end-to-end-krypterad</underline>."),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Aktiva sessioner"),
        "add": MessageLookupByLibrary.simpleMessage("Lägg till"),
        "addANewEmail": MessageLookupByLibrary.simpleMessage(
            "Lägg till en ny e-postadress"),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Lägg till samarbetspartner"),
        "addFromDevice":
            MessageLookupByLibrary.simpleMessage("Lägg till från enhet"),
        "addItem": m10,
        "addLocationButton": MessageLookupByLibrary.simpleMessage("Lägg till"),
        "addMore": MessageLookupByLibrary.simpleMessage("Lägg till fler"),
        "addName": MessageLookupByLibrary.simpleMessage("Lägg till namn"),
        "addPhotos": MessageLookupByLibrary.simpleMessage("Lägg till foton"),
        "addViewer": MessageLookupByLibrary.simpleMessage("Lägg till bildvy"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Lades till som"),
        "after1Day": MessageLookupByLibrary.simpleMessage("Om en dag"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("Om en timme"),
        "after1Month": MessageLookupByLibrary.simpleMessage("Om en månad"),
        "after1Week": MessageLookupByLibrary.simpleMessage("Om en vecka"),
        "after1Year": MessageLookupByLibrary.simpleMessage("Om ett år"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Ägare"),
        "albumParticipantsCount": m15,
        "albumUpdated":
            MessageLookupByLibrary.simpleMessage("Album uppdaterat"),
        "albums": MessageLookupByLibrary.simpleMessage("Album"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Tillåt personer med länken att även lägga till foton i det delade albumet."),
        "allowAddingPhotos":
            MessageLookupByLibrary.simpleMessage("Tillåt lägga till foton"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("Tillåt nedladdningar"),
        "androidCancelButton": MessageLookupByLibrary.simpleMessage("Avbryt"),
        "appVersion": m16,
        "apply": MessageLookupByLibrary.simpleMessage("Verkställ"),
        "applyCodeTitle": MessageLookupByLibrary.simpleMessage("Använd kod"),
        "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
            "Är du säker på att du vill logga ut?"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "Vad är den främsta anledningen till att du raderar ditt konto?"),
        "authenticationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Autentisering misslyckades, försök igen"),
        "availableStorageSpace": m17,
        "blog": MessageLookupByLibrary.simpleMessage("Blogg"),
        "cancel": MessageLookupByLibrary.simpleMessage("Avbryt"),
        "cannotAddMorePhotosAfterBecomingViewer": m3,
        "change": MessageLookupByLibrary.simpleMessage("Ändra"),
        "changeEmail":
            MessageLookupByLibrary.simpleMessage("Ändra e-postadress"),
        "changePassword":
            MessageLookupByLibrary.simpleMessage("Ändra lösenord"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Ändra lösenord"),
        "changePermissions":
            MessageLookupByLibrary.simpleMessage("Ändra behörighet?"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Kontrollera din inkorg (och skräppost) för att slutföra verifieringen"),
        "claimed": MessageLookupByLibrary.simpleMessage("Nyttjad"),
        "close": MessageLookupByLibrary.simpleMessage("Stäng"),
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("Kod tillämpad"),
        "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Koden har kopierats till urklipp"),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Skapa en länk så att personer kan lägga till och visa foton i ditt delade album utan att behöva en Ente app eller konto. Perfekt för att samla in bilder från evenemang."),
        "collaborativeLink":
            MessageLookupByLibrary.simpleMessage("Samarbetslänk"),
        "collaborator":
            MessageLookupByLibrary.simpleMessage("Samarbetspartner"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Samarbetspartner kan lägga till foton och videor till det delade albumet."),
        "collectPhotos": MessageLookupByLibrary.simpleMessage("Samla in foton"),
        "color": MessageLookupByLibrary.simpleMessage("Färg"),
        "confirm": MessageLookupByLibrary.simpleMessage("Bekräfta"),
        "confirmAccountDeletion":
            MessageLookupByLibrary.simpleMessage("Bekräfta radering av konto"),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Bekräfta lösenord"),
        "confirmRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Bekräfta återställningsnyckel"),
        "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Bekräfta din återställningsnyckel"),
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("Kontakta support"),
        "contacts": MessageLookupByLibrary.simpleMessage("Kontakter"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("Fortsätt"),
        "copyEmailAddress":
            MessageLookupByLibrary.simpleMessage("Kopiera e-postadress"),
        "copyLink": MessageLookupByLibrary.simpleMessage("Kopiera länk"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Kopiera-klistra in den här koden\ntill din autentiseringsapp"),
        "create": MessageLookupByLibrary.simpleMessage("Skapa"),
        "createAccount": MessageLookupByLibrary.simpleMessage("Skapa konto"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("Skapa nytt konto"),
        "createOrSelectAlbum":
            MessageLookupByLibrary.simpleMessage("Skapa eller välj album"),
        "createPublicLink":
            MessageLookupByLibrary.simpleMessage("Skapa offentlig länk"),
        "custom": MessageLookupByLibrary.simpleMessage("Anpassad"),
        "darkTheme": MessageLookupByLibrary.simpleMessage("Mörkt"),
        "decrypting": MessageLookupByLibrary.simpleMessage("Dekrypterar..."),
        "delete": MessageLookupByLibrary.simpleMessage("Radera"),
        "deleteAccount": MessageLookupByLibrary.simpleMessage("Radera konto"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "Vi är ledsna att se dig lämna oss. Vänligen dela dina synpunkter för att hjälpa oss att förbättra."),
        "deleteAccountPermanentlyButton":
            MessageLookupByLibrary.simpleMessage("Radera kontot permanent"),
        "deleteAlbum": MessageLookupByLibrary.simpleMessage("Radera album"),
        "deleteAll": MessageLookupByLibrary.simpleMessage("Radera alla"),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "Vänligen skicka ett e-postmeddelande till <warning>account-deletion@ente.io</warning> från din registrerade e-postadress."),
        "deleteFromDevice":
            MessageLookupByLibrary.simpleMessage("Radera från enhet"),
        "deleteItemCount": m26,
        "deletePhotos": MessageLookupByLibrary.simpleMessage("Radera foton"),
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "Det saknas en viktig funktion som jag behöver"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "Appen eller en viss funktion beter sig inte som jag tycker det ska"),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
            "Jag hittade en annan tjänst som jag gillar bättre"),
        "deleteReason4":
            MessageLookupByLibrary.simpleMessage("Min orsak finns inte med"),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
            "Din begäran kommer att hanteras inom 72 timmar."),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Besökare kan fortfarande ta skärmdumpar eller spara en kopia av dina foton med hjälp av externa verktyg"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Vänligen notera:"),
        "discord": MessageLookupByLibrary.simpleMessage("Discord"),
        "discover_notes": MessageLookupByLibrary.simpleMessage("Anteckningar"),
        "discover_receipts": MessageLookupByLibrary.simpleMessage("Kvitton"),
        "doThisLater": MessageLookupByLibrary.simpleMessage("Gör detta senare"),
        "done": MessageLookupByLibrary.simpleMessage("Klar"),
        "dropSupportEmail": m29,
        "edit": MessageLookupByLibrary.simpleMessage("Redigera"),
        "email": MessageLookupByLibrary.simpleMessage("E-post"),
        "emailNoEnteAccount": m33,
        "encryption": MessageLookupByLibrary.simpleMessage("Kryptering"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Krypteringsnycklar"),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
            "Ente <i>behöver tillåtelse att</i> bevara dina foton"),
        "enterAlbumName":
            MessageLookupByLibrary.simpleMessage("Ange albumnamn"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Ange kod"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
            "Ange koden som din vän har angett för att få gratis lagring för er båda"),
        "enterEmail": MessageLookupByLibrary.simpleMessage("Ange e-post"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Ange ett nytt lösenord som vi kan använda för att kryptera din data"),
        "enterPassword": MessageLookupByLibrary.simpleMessage("Ange lösenord"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Ange ett lösenord som vi kan använda för att kryptera din data"),
        "enterReferralCode":
            MessageLookupByLibrary.simpleMessage("Ange hänvisningskod"),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Ange den 6-siffriga koden från din autentiseringsapp"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "Ange en giltig e-postadress."),
        "enterYourEmailAddress":
            MessageLookupByLibrary.simpleMessage("Ange din e-postadress"),
        "enterYourPassword":
            MessageLookupByLibrary.simpleMessage("Ange ditt lösenord"),
        "enterYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Ange din återställningsnyckel"),
        "exif": MessageLookupByLibrary.simpleMessage("EXIF"),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
            "Denna länk har upphört att gälla. Välj ett nytt datum eller inaktivera tidsbegränsningen."),
        "exportYourData":
            MessageLookupByLibrary.simpleMessage("Exportera din data"),
        "failedToApplyCode": MessageLookupByLibrary.simpleMessage(
            "Det gick inte att använda koden"),
        "feedback": MessageLookupByLibrary.simpleMessage("Feedback"),
        "fileInfoAddDescHint":
            MessageLookupByLibrary.simpleMessage("Lägg till en beskrivning..."),
        "fileTypes": MessageLookupByLibrary.simpleMessage("Filtyper"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Glömt lösenord"),
        "freeTrial": MessageLookupByLibrary.simpleMessage("Gratis provperiod"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Skapar krypteringsnycklar..."),
        "goToSettings":
            MessageLookupByLibrary.simpleMessage("Gå till inställningar"),
        "guestView": MessageLookupByLibrary.simpleMessage("Gästvy"),
        "help": MessageLookupByLibrary.simpleMessage("Hjälp"),
        "howItWorks":
            MessageLookupByLibrary.simpleMessage("Så här fungerar det"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "Be dem att långtrycka på sin e-postadress på inställningsskärmen och verifiera att ID:n på båda enheterna matchar."),
        "iOSOkButton": MessageLookupByLibrary.simpleMessage("OK"),
        "ignoreUpdate": MessageLookupByLibrary.simpleMessage("Ignorera"),
        "incorrectCode": MessageLookupByLibrary.simpleMessage("Felaktig kod"),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Felaktigt lösenord"),
        "incorrectRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Felaktig återställningsnyckel"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "Återställningsnyckeln du angav är felaktig"),
        "incorrectRecoveryKeyTitle": MessageLookupByLibrary.simpleMessage(
            "Felaktig återställningsnyckel"),
        "insecureDevice": MessageLookupByLibrary.simpleMessage("Osäker enhet"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("Ogiltig e-postadress"),
        "invalidKey": MessageLookupByLibrary.simpleMessage("Ogiltig nyckel"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Återställningsnyckeln du angav är inte giltig. Kontrollera att den innehåller 24 ord och kontrollera stavningen av varje ord.\n\nOm du har angett en äldre återställnings kod, se till att den är 64 tecken lång, och kontrollera var och en av bokstäverna."),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Bjud in dina vänner"),
        "inviteYourFriendsToEnte": MessageLookupByLibrary.simpleMessage(
            "Bjud in dina vänner till Ente"),
        "itemCount": m42,
        "kiloMeterUnit": MessageLookupByLibrary.simpleMessage("km"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Vänligen hjälp oss med denna information"),
        "language": MessageLookupByLibrary.simpleMessage("Språk"),
        "leave": MessageLookupByLibrary.simpleMessage("Lämna"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("Ljust"),
        "linkDeviceLimit": MessageLookupByLibrary.simpleMessage("Enhetsgräns"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Aktiverat"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Upphört"),
        "linkExpiresOn": m44,
        "linkExpiry": MessageLookupByLibrary.simpleMessage("Länken upphör"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("Länk har upphört att gälla"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Aldrig"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Lås"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Logga in"),
        "loginSessionExpiredDetails": MessageLookupByLibrary.simpleMessage(
            "Din session har upphört. Logga in igen."),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "Genom att klicka på logga in godkänner jag <u-terms>användarvillkoren</u-terms> och våran <u-policy>integritetspolicy</u-policy>"),
        "logout": MessageLookupByLibrary.simpleMessage("Logga ut"),
        "lostDevice": MessageLookupByLibrary.simpleMessage("Förlorad enhet?"),
        "machineLearning":
            MessageLookupByLibrary.simpleMessage("Maskininlärning"),
        "manage": MessageLookupByLibrary.simpleMessage("Hantera"),
        "manageLink": MessageLookupByLibrary.simpleMessage("Hantera länk"),
        "manageParticipants": MessageLookupByLibrary.simpleMessage("Hantera"),
        "manageSubscription":
            MessageLookupByLibrary.simpleMessage("Hantera prenumeration"),
        "mastodon": MessageLookupByLibrary.simpleMessage("Mastodon"),
        "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
        "mlConsent":
            MessageLookupByLibrary.simpleMessage("Aktivera maskininlärning"),
        "mlConsentTitle":
            MessageLookupByLibrary.simpleMessage("Aktivera maskininlärning?"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Måttligt"),
        "moveItem": m45,
        "moveToAlbum":
            MessageLookupByLibrary.simpleMessage("Flytta till album"),
        "movingFilesToAlbum":
            MessageLookupByLibrary.simpleMessage("Flyttar filer till album..."),
        "name": MessageLookupByLibrary.simpleMessage("Namn"),
        "never": MessageLookupByLibrary.simpleMessage("Aldrig"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Nytt album"),
        "newPerson": MessageLookupByLibrary.simpleMessage("Ny person"),
        "next": MessageLookupByLibrary.simpleMessage("Nästa"),
        "no": MessageLookupByLibrary.simpleMessage("Nej"),
        "noDeviceLimit": MessageLookupByLibrary.simpleMessage("Ingen"),
        "noExifData": MessageLookupByLibrary.simpleMessage("Ingen EXIF-data"),
        "noInternetConnection":
            MessageLookupByLibrary.simpleMessage("Ingen internetanslutning"),
        "noRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Ingen återställningsnyckel?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "På grund av vårt punkt-till-punkt-krypteringssystem så kan dina data inte avkrypteras utan ditt lösenord eller återställningsnyckel"),
        "noResults": MessageLookupByLibrary.simpleMessage("Inga resultat"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("Inga resultat hittades"),
        "notPersonLabel": m48,
        "ok": MessageLookupByLibrary.simpleMessage("OK"),
        "onlyFamilyAdminCanChangeCode": m49,
        "oops": MessageLookupByLibrary.simpleMessage("Hoppsan"),
        "orPickAnExistingOne":
            MessageLookupByLibrary.simpleMessage("Eller välj en befintlig"),
        "passkey": MessageLookupByLibrary.simpleMessage("Nyckel"),
        "password": MessageLookupByLibrary.simpleMessage("Lösenord"),
        "passwordChangedSuccessfully":
            MessageLookupByLibrary.simpleMessage("Lösenordet har ändrats"),
        "passwordLock": MessageLookupByLibrary.simpleMessage("Lösenordskydd"),
        "passwordStrength": m0,
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Vi lagrar inte detta lösenord, så om du glömmer bort det, <underline>kan vi inte dekryptera dina data</underline>"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("foto"),
        "pleaseCheckYourInternetConnectionAndTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Kontrollera din internetanslutning och försök igen."),
        "pleaseLoginAgain":
            MessageLookupByLibrary.simpleMessage("Logga in igen"),
        "pleaseTryAgain": MessageLookupByLibrary.simpleMessage("Försök igen"),
        "pleaseWait": MessageLookupByLibrary.simpleMessage("Var god vänta..."),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Integritetspolicy"),
        "publicLinkEnabled":
            MessageLookupByLibrary.simpleMessage("Offentlig länk aktiverad"),
        "rateUsOnStore": m56,
        "recover": MessageLookupByLibrary.simpleMessage("Återställ"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("Återställ konto"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Återställ"),
        "recoveryKey":
            MessageLookupByLibrary.simpleMessage("Återställningsnyckel"),
        "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Återställningsnyckel kopierad till urklipp"),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
            "Om du glömmer ditt lösenord är det enda sättet du kan återställa dina data med denna nyckel."),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
            "Vi lagrar inte och har därför inte åtkomst till denna nyckel, vänligen spara denna 24 ords nyckel på en säker plats."),
        "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
            "Grymt! Din återställningsnyckel är giltig. Tack för att du verifierade.\n\nKom ihåg att hålla din återställningsnyckel säker med backups."),
        "recoveryKeyVerified": MessageLookupByLibrary.simpleMessage(
            "Återställningsnyckel verifierad"),
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("Återställning lyckades!"),
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "Denna enhet är inte tillräckligt kraftfull för att verifiera ditt lösenord, men vi kan återskapa det på ett sätt som fungerar med alla enheter.\n\nLogga in med din återställningsnyckel och återskapa ditt lösenord (du kan använda samma igen om du vill)."),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Återskapa lösenord"),
        "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
        "remove": MessageLookupByLibrary.simpleMessage("Ta bort"),
        "removeLink": MessageLookupByLibrary.simpleMessage("Radera länk"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Ta bort användaren"),
        "renewSubscription":
            MessageLookupByLibrary.simpleMessage("Förnya prenumeration"),
        "resendEmail": MessageLookupByLibrary.simpleMessage(
            "Skicka e-postmeddelandet igen"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Återställ lösenord"),
        "resetToDefault":
            MessageLookupByLibrary.simpleMessage("Återställ till standard"),
        "retry": MessageLookupByLibrary.simpleMessage("Försök igen"),
        "save": MessageLookupByLibrary.simpleMessage("Spara"),
        "saveCopy": MessageLookupByLibrary.simpleMessage("Spara kopia"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Spara nyckel"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Spara din återställningsnyckel om du inte redan har gjort det"),
        "scanCode": MessageLookupByLibrary.simpleMessage("Skanna kod"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Skanna denna streckkod med\ndin autentiseringsapp"),
        "search": MessageLookupByLibrary.simpleMessage("Sök"),
        "searchAlbumsEmptySection":
            MessageLookupByLibrary.simpleMessage("Album"),
        "searchByAlbumNameHint":
            MessageLookupByLibrary.simpleMessage("Albumnamn"),
        "searchFileTypesAndNamesEmptySection":
            MessageLookupByLibrary.simpleMessage("Filtyper och namn"),
        "searchResultCount": m63,
        "selectAlbum": MessageLookupByLibrary.simpleMessage("Välj album"),
        "selectLanguage": MessageLookupByLibrary.simpleMessage("Välj språk"),
        "selectReason": MessageLookupByLibrary.simpleMessage("Välj anledning"),
        "send": MessageLookupByLibrary.simpleMessage("Skicka"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("Skicka e-post"),
        "sendInvite": MessageLookupByLibrary.simpleMessage("Skicka inbjudan"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Skicka länk"),
        "setAPassword":
            MessageLookupByLibrary.simpleMessage("Ange ett lösenord"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Välj lösenord"),
        "setupComplete":
            MessageLookupByLibrary.simpleMessage("Konfiguration slutförd"),
        "share": MessageLookupByLibrary.simpleMessage("Dela"),
        "shareALink": MessageLookupByLibrary.simpleMessage("Dela en länk"),
        "shareLink": MessageLookupByLibrary.simpleMessage("Dela länk"),
        "shareMyVerificationID": m66,
        "shareTextConfirmOthersVerificationID": m7,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Ladda ner Ente så att vi enkelt kan dela bilder och videor med originell kvalitet\n\nhttps://ente.io"),
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
            "Dela med icke-Ente användare"),
        "shareWithPeopleSectionTitle": m68,
        "shareYourFirstAlbum":
            MessageLookupByLibrary.simpleMessage("Dela ditt första album"),
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Skapa delade och samarbetande album med andra Ente användare, inklusive användare med gratisnivån."),
        "showPerson": MessageLookupByLibrary.simpleMessage("Visa person"),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "Jag samtycker till <u-terms>användarvillkoren</u-terms> och <u-policy>integritetspolicyn</u-policy>"),
        "skip": MessageLookupByLibrary.simpleMessage("Hoppa över"),
        "someoneSharingAlbumsWithYouShouldSeeTheSameId":
            MessageLookupByLibrary.simpleMessage(
                "Någon som delar album med dig bör se samma ID på deras enhet."),
        "somethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Något gick fel"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Något gick fel, vänligen försök igen"),
        "sorry": MessageLookupByLibrary.simpleMessage("Förlåt"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "Tyvärr, vi kunde inte generera säkra nycklar på den här enheten.\n\nVänligen registrera dig från en annan enhet."),
        "sort": MessageLookupByLibrary.simpleMessage("Sortera"),
        "sortAlbumsBy": MessageLookupByLibrary.simpleMessage("Sortera efter"),
        "status": MessageLookupByLibrary.simpleMessage("Status"),
        "storageBreakupYou": MessageLookupByLibrary.simpleMessage("Du"),
        "storageInGB": m1,
        "strongStrength": MessageLookupByLibrary.simpleMessage("Starkt"),
        "subscribe": MessageLookupByLibrary.simpleMessage("Prenumerera"),
        "subscription": MessageLookupByLibrary.simpleMessage("Prenumeration"),
        "tapToCopy":
            MessageLookupByLibrary.simpleMessage("tryck för att kopiera"),
        "tapToEnterCode":
            MessageLookupByLibrary.simpleMessage("Tryck för att ange kod"),
        "terminate": MessageLookupByLibrary.simpleMessage("Avsluta"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Avsluta sessionen?"),
        "terms": MessageLookupByLibrary.simpleMessage("Villkor"),
        "termsOfServicesTitle": MessageLookupByLibrary.simpleMessage("Villkor"),
        "thankYou": MessageLookupByLibrary.simpleMessage("Tack"),
        "theRecoveryKeyYouEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "Återställningsnyckeln du angav är felaktig"),
        "theme": MessageLookupByLibrary.simpleMessage("Tema"),
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "Detta kan användas för att återställa ditt konto om du förlorar din andra faktor"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Den här enheten"),
        "thisIsPersonVerificationId": m78,
        "thisIsYourVerificationId": MessageLookupByLibrary.simpleMessage(
            "Detta är ditt verifierings-ID"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Detta kommer att logga ut dig från följande enhet:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Detta kommer att logga ut dig från denna enhet!"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "För att återställa ditt lösenord måste du först bekräfta din e-postadress."),
        "trash": MessageLookupByLibrary.simpleMessage("Papperskorg"),
        "tryAgain": MessageLookupByLibrary.simpleMessage("Försök igen"),
        "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
        "twofactorAuthenticationHasBeenDisabled":
            MessageLookupByLibrary.simpleMessage(
                "Tvåfaktorsautentisering har inaktiverats"),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage("Tvåfaktorsautentisering"),
        "twofactorSetup":
            MessageLookupByLibrary.simpleMessage("Tvåfaktorskonfiguration"),
        "update": MessageLookupByLibrary.simpleMessage("Uppdatera"),
        "upgrade": MessageLookupByLibrary.simpleMessage("Uppgradera"),
        "uploadingMultipleMemories": m83,
        "uploadingSingleMemory":
            MessageLookupByLibrary.simpleMessage("Bevarar 1 minne..."),
        "useAsCover": MessageLookupByLibrary.simpleMessage("Använd som omslag"),
        "useRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Använd återställningsnyckel"),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("Verifierings-ID"),
        "verify": MessageLookupByLibrary.simpleMessage("Bekräfta"),
        "verifyEmail":
            MessageLookupByLibrary.simpleMessage("Bekräfta e-postadress"),
        "verifyEmailID": m85,
        "verifyPasskey":
            MessageLookupByLibrary.simpleMessage("Verifiera nyckel"),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Bekräfta lösenord"),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Verifierar återställningsnyckel..."),
        "viewActiveSessions":
            MessageLookupByLibrary.simpleMessage("Visa aktiva sessioner"),
        "viewAll": MessageLookupByLibrary.simpleMessage("Visa alla"),
        "viewAllExifData":
            MessageLookupByLibrary.simpleMessage("Visa all EXIF-data"),
        "viewLogs": MessageLookupByLibrary.simpleMessage("Visa loggar"),
        "viewRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Visa återställningsnyckel"),
        "viewer": MessageLookupByLibrary.simpleMessage("Bildvy"),
        "weHaveSendEmailTo": m2,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Svagt"),
        "welcomeBack":
            MessageLookupByLibrary.simpleMessage("Välkommen tillbaka!"),
        "whatsNew": MessageLookupByLibrary.simpleMessage("Nyheter"),
        "yearsAgo": m87,
        "yes": MessageLookupByLibrary.simpleMessage("Ja"),
        "yesCancel": MessageLookupByLibrary.simpleMessage("Ja, avbryt"),
        "yesConvertToViewer":
            MessageLookupByLibrary.simpleMessage("Ja, konvertera till bildvy"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("Ja, radera"),
        "yesLogout": MessageLookupByLibrary.simpleMessage("Ja, logga ut"),
        "yesRenew": MessageLookupByLibrary.simpleMessage("Ja, förnya"),
        "you": MessageLookupByLibrary.simpleMessage("Du"),
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("Ditt konto har raderats")
      };
}
