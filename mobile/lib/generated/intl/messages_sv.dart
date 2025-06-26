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

  static String m8(count) =>
      "${Intl.plural(count, zero: 'Inga deltagare', one: '1 deltagare', other: '${count} deltagare')}";

  static String m9(versionValue) => "Version: ${versionValue}";

  static String m10(freeAmount, storageUnit) =>
      "${freeAmount} ${storageUnit} gratis";

  static String m13(user) =>
      "${user} kommer inte att kunna lägga till fler foton till detta album\n\nDe kommer fortfarande att kunna ta bort befintliga foton som lagts till av dem";

  static String m14(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true': 'Din familj har begärt ${storageAmountInGb} GB',
            'false': '${storageAmountInGb}',
            'other': 'Du har begärt ${storageAmountInGb} GB!',
          })}";

  static String m21(count) =>
      "${Intl.plural(count, one: 'Radera ${count} objekt', other: 'Radera ${count} objekt')}";

  static String m25(supportEmail) =>
      "Vänligen skicka ett e-postmeddelande till ${supportEmail} från din registrerade e-postadress";

  static String m27(count, formattedSize) =>
      "${count} filer, ${formattedSize} vardera";

  static String m31(email) =>
      "${email} har inte ett Ente-konto.\n\nSkicka dem en inbjudan för att dela bilder.";

  static String m37(storageAmountInGB) =>
      "${storageAmountInGB} GB varje gång någon registrerar sig för en betalplan och tillämpar din kod";

  static String m44(count) => "${Intl.plural(count, other: '${count} objekt')}";

  static String m47(expiryTime) => "Länken upphör att gälla ${expiryTime}";

  static String m54(name) => "Inte ${name}?";

  static String m55(familyAdminEmail) =>
      "Kontakta ${familyAdminEmail} för att ändra din kod.";

  static String m57(passwordStrengthValue) =>
      "Lösenordsstyrka: ${passwordStrengthValue}";

  static String m68(storeName) => "Betygsätt oss på ${storeName}";

  static String m73(storageInGB) => "3. Ni får båda ${storageInGB} GB* gratis";

  static String m74(userEmail) =>
      "${userEmail} kommer att tas bort från detta delade album\n\nAlla bilder som lagts till av dem kommer också att tas bort från albumet";

  static String m77(count) =>
      "${Intl.plural(count, other: '${count} resultat hittades')}";

  static String m83(verificationID) =>
      "Här är mitt verifierings-ID: ${verificationID} för ente.io.";

  static String m84(verificationID) =>
      "Hallå, kan du bekräfta att detta är ditt ente.io verifierings-ID: ${verificationID}";

  static String m85(referralCode, referralStorageInGB) =>
      "Ente värvningskod: ${referralCode} \n\nTillämpa den i Inställningar → Allmänt → Hänvisningar för att få ${referralStorageInGB} GB gratis när du registrerar dig för en betalplan\n\nhttps://ente.io";

  static String m86(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Dela med specifika personer', one: 'Delad med en person', other: 'Delad med ${numberOfPeople} personer')}";

  static String m93(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m99(storageAmountInGB) =>
      "De får också ${storageAmountInGB} GB";

  static String m100(email) => "Detta är ${email}s verifierings-ID";

  static String m109(count) => "Bevarar ${count} minnen...";

  static String m111(email) => "Bekräfta ${email}";

  static String m114(email) =>
      "Vi har skickat ett e-postmeddelande till <green>${email}</green>";

  static String m115(name) => "Wish \$${name} a happy birthday! 🎉";

  static String m116(count) =>
      "${Intl.plural(count, other: '${count} år sedan')}";

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
        "addLocationButton": MessageLookupByLibrary.simpleMessage("Lägg till"),
        "addMore": MessageLookupByLibrary.simpleMessage("Lägg till fler"),
        "addName": MessageLookupByLibrary.simpleMessage("Lägg till namn"),
        "addPhotos": MessageLookupByLibrary.simpleMessage("Lägg till foton"),
        "addViewer": MessageLookupByLibrary.simpleMessage("Lägg till bildvy"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Lades till som"),
        "addingToFavorites": MessageLookupByLibrary.simpleMessage(
            "Lägger till bland favoriter..."),
        "after1Day": MessageLookupByLibrary.simpleMessage("Om en dag"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("Om en timme"),
        "after1Month": MessageLookupByLibrary.simpleMessage("Om en månad"),
        "after1Week": MessageLookupByLibrary.simpleMessage("Om en vecka"),
        "after1Year": MessageLookupByLibrary.simpleMessage("Om ett år"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Ägare"),
        "albumParticipantsCount": m8,
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
        "appVersion": m9,
        "apply": MessageLookupByLibrary.simpleMessage("Verkställ"),
        "applyCodeTitle": MessageLookupByLibrary.simpleMessage("Använd kod"),
        "areThey": MessageLookupByLibrary.simpleMessage("Are they "),
        "areYouSureRemoveThisFaceFromPerson":
            MessageLookupByLibrary.simpleMessage(
                "Are you sure you want to remove this face from this person?"),
        "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
            "Är du säker på att du vill logga ut?"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "Vad är den främsta anledningen till att du raderar ditt konto?"),
        "authenticationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Autentisering misslyckades, försök igen"),
        "availableStorageSpace": m10,
        "backupSettings": MessageLookupByLibrary.simpleMessage(
            "Säkerhetskopieringsinställningar"),
        "backupStatus":
            MessageLookupByLibrary.simpleMessage("Säkerhetskopieringsstatus"),
        "blog": MessageLookupByLibrary.simpleMessage("Blogg"),
        "canNotOpenBody": MessageLookupByLibrary.simpleMessage(
            "Tyvärr kan detta album inte öppnas i appen."),
        "canNotOpenTitle": MessageLookupByLibrary.simpleMessage(
            "Kan inte öppna det här albumet"),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "Kan endast ta bort filer som ägs av dig"),
        "cancel": MessageLookupByLibrary.simpleMessage("Avbryt"),
        "cannotAddMorePhotosAfterBecomingViewer": m13,
        "change": MessageLookupByLibrary.simpleMessage("Ändra"),
        "changeEmail":
            MessageLookupByLibrary.simpleMessage("Ändra e-postadress"),
        "changePassword":
            MessageLookupByLibrary.simpleMessage("Ändra lösenord"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Ändra lösenord"),
        "changePermissions":
            MessageLookupByLibrary.simpleMessage("Ändra behörighet?"),
        "changeYourReferralCode":
            MessageLookupByLibrary.simpleMessage("Ändra din värvningskod"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Kontrollera din inkorg (och skräppost) för att slutföra verifieringen"),
        "claimFreeStorage":
            MessageLookupByLibrary.simpleMessage("Hämta kostnadsfri lagring"),
        "claimMore": MessageLookupByLibrary.simpleMessage("Begär mer!"),
        "claimed": MessageLookupByLibrary.simpleMessage("Nyttjad"),
        "claimedStorageSoFar": m14,
        "clearIndexes": MessageLookupByLibrary.simpleMessage("Rensa index"),
        "close": MessageLookupByLibrary.simpleMessage("Stäng"),
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("Kod tillämpad"),
        "codeChangeLimitReached": MessageLookupByLibrary.simpleMessage(
            "Tyvärr, du har nått gränsen för kodändringar."),
        "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Koden har kopierats till urklipp"),
        "codeUsedByYou":
            MessageLookupByLibrary.simpleMessage("Kod som används av dig"),
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
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Ja, jag vill permanent ta bort detta konto och data i alla appar."),
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
        "creatingLink": MessageLookupByLibrary.simpleMessage("Skapar länk..."),
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
        "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
            "Ta också bort foton (och videor) som finns i detta album från <bold>alla</bold> andra album som de är en del av?"),
        "deleteAll": MessageLookupByLibrary.simpleMessage("Radera alla"),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "Vänligen skicka ett e-postmeddelande till <warning>account-deletion@ente.io</warning> från din registrerade e-postadress."),
        "deleteFromDevice":
            MessageLookupByLibrary.simpleMessage("Radera från enhet"),
        "deleteItemCount": m21,
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
        "deleteSharedAlbum":
            MessageLookupByLibrary.simpleMessage("Radera delat album?"),
        "deleteSharedAlbumDialogBody": MessageLookupByLibrary.simpleMessage(
            "Albumet kommer att raderas för alla\n\nDu kommer att förlora åtkomst till delade foton i detta album som ägs av andra"),
        "details": MessageLookupByLibrary.simpleMessage("Uppgifter"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Besökare kan fortfarande ta skärmdumpar eller spara en kopia av dina foton med hjälp av externa verktyg"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Vänligen notera:"),
        "discord": MessageLookupByLibrary.simpleMessage("Discord"),
        "discover_notes": MessageLookupByLibrary.simpleMessage("Anteckningar"),
        "discover_receipts": MessageLookupByLibrary.simpleMessage("Kvitton"),
        "doThisLater": MessageLookupByLibrary.simpleMessage("Gör detta senare"),
        "done": MessageLookupByLibrary.simpleMessage("Klar"),
        "dropSupportEmail": m25,
        "duplicateItemsGroup": m27,
        "edit": MessageLookupByLibrary.simpleMessage("Redigera"),
        "eligible": MessageLookupByLibrary.simpleMessage("berättigad"),
        "email": MessageLookupByLibrary.simpleMessage("E-post"),
        "emailAlreadyRegistered": MessageLookupByLibrary.simpleMessage(
            "E-postadress redan registrerad."),
        "emailNoEnteAccount": m31,
        "emailNotRegistered": MessageLookupByLibrary.simpleMessage(
            "E-postadressen är inte registrerad."),
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
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "Det gick inte att hämta hänvisningsdetaljer. Försök igen senare."),
        "faq": MessageLookupByLibrary.simpleMessage("Vanliga frågor och svar"),
        "feedback": MessageLookupByLibrary.simpleMessage("Feedback"),
        "fileInfoAddDescHint":
            MessageLookupByLibrary.simpleMessage("Lägg till en beskrivning..."),
        "fileTypes": MessageLookupByLibrary.simpleMessage("Filtyper"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Glömt lösenord"),
        "freeStorageClaimed":
            MessageLookupByLibrary.simpleMessage("Gratis lagring begärd"),
        "freeStorageOnReferralSuccess": m37,
        "freeStorageUsable": MessageLookupByLibrary.simpleMessage(
            "Gratis lagringsutrymme som kan användas"),
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
        "inviteToEnte":
            MessageLookupByLibrary.simpleMessage("Bjud in till Ente"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Bjud in dina vänner"),
        "inviteYourFriendsToEnte": MessageLookupByLibrary.simpleMessage(
            "Bjud in dina vänner till Ente"),
        "itemCount": m44,
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "Valda objekt kommer att tas bort från detta album"),
        "keepPhotos": MessageLookupByLibrary.simpleMessage("Behåll foton"),
        "kiloMeterUnit": MessageLookupByLibrary.simpleMessage("km"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Vänligen hjälp oss med denna information"),
        "language": MessageLookupByLibrary.simpleMessage("Språk"),
        "leave": MessageLookupByLibrary.simpleMessage("Lämna"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("Ljust"),
        "linkDeviceLimit": MessageLookupByLibrary.simpleMessage("Enhetsgräns"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Aktiverat"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Upphört"),
        "linkExpiresOn": m47,
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
        "notPersonLabel": m54,
        "ok": MessageLookupByLibrary.simpleMessage("OK"),
        "onlyFamilyAdminCanChangeCode": m55,
        "oops": MessageLookupByLibrary.simpleMessage("Hoppsan"),
        "oopsSomethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Oj, något gick fel"),
        "orPickAnExistingOne":
            MessageLookupByLibrary.simpleMessage("Eller välj en befintlig"),
        "otherDetectedFaces":
            MessageLookupByLibrary.simpleMessage("Other detected faces"),
        "passkey": MessageLookupByLibrary.simpleMessage("Nyckel"),
        "password": MessageLookupByLibrary.simpleMessage("Lösenord"),
        "passwordChangedSuccessfully":
            MessageLookupByLibrary.simpleMessage("Lösenordet har ändrats"),
        "passwordLock": MessageLookupByLibrary.simpleMessage("Lösenordskydd"),
        "passwordStrength": m57,
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Vi lagrar inte detta lösenord, så om du glömmer bort det, <underline>kan vi inte dekryptera dina data</underline>"),
        "peopleUsingYourCode": MessageLookupByLibrary.simpleMessage(
            "Personer som använder din kod"),
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
        "questionmark": MessageLookupByLibrary.simpleMessage("?"),
        "rateUsOnStore": m68,
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
        "recoveryKeyVerifyReason": MessageLookupByLibrary.simpleMessage(
            "Din återställningsnyckel är det enda sättet att återställa dina foton om du glömmer ditt lösenord. Du hittar din återställningsnyckel i Inställningar > Säkerhet.\n\nAnge din återställningsnyckel här för att verifiera att du har sparat den ordentligt."),
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("Återställning lyckades!"),
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "Denna enhet är inte tillräckligt kraftfull för att verifiera ditt lösenord, men vi kan återskapa det på ett sätt som fungerar med alla enheter.\n\nLogga in med din återställningsnyckel och återskapa ditt lösenord (du kan använda samma igen om du vill)."),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Återskapa lösenord"),
        "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
        "referralStep1": MessageLookupByLibrary.simpleMessage(
            "1. Ge denna kod till dina vänner"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "2. De registrerar sig för en betalplan"),
        "referralStep3": m73,
        "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
            "Hänvisningar är för närvarande pausade"),
        "remove": MessageLookupByLibrary.simpleMessage("Ta bort"),
        "removeFromAlbum":
            MessageLookupByLibrary.simpleMessage("Ta bort från album"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("Ta bort från album?"),
        "removeLink": MessageLookupByLibrary.simpleMessage("Radera länk"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Ta bort användaren"),
        "removeParticipantBody": m74,
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
            "Några av de objekt som du tar bort lades av andra personer, och du kommer att förlora tillgång till dem"),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Ta bort?"),
        "removingFromFavorites":
            MessageLookupByLibrary.simpleMessage("Tar bort från favoriter..."),
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
        "saveAsAnotherPerson":
            MessageLookupByLibrary.simpleMessage("Save as another person"),
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
        "searchResultCount": m77,
        "selectAlbum": MessageLookupByLibrary.simpleMessage("Välj album"),
        "selectAll": MessageLookupByLibrary.simpleMessage("Markera allt"),
        "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
            "Välj mappar för säkerhetskopiering"),
        "selectLanguage": MessageLookupByLibrary.simpleMessage("Välj språk"),
        "selectReason": MessageLookupByLibrary.simpleMessage("Välj anledning"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "Valda mappar kommer att krypteras och säkerhetskopieras"),
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
        "shareMyVerificationID": m83,
        "shareTextConfirmOthersVerificationID": m84,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Ladda ner Ente så att vi enkelt kan dela bilder och videor med originell kvalitet\n\nhttps://ente.io"),
        "shareTextReferralCode": m85,
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
            "Dela med icke-Ente användare"),
        "shareWithPeopleSectionTitle": m86,
        "shareYourFirstAlbum":
            MessageLookupByLibrary.simpleMessage("Dela ditt första album"),
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Skapa delade och samarbetande album med andra Ente användare, inklusive användare med gratisnivån."),
        "showLessFaces":
            MessageLookupByLibrary.simpleMessage("Show less faces"),
        "showMemories": MessageLookupByLibrary.simpleMessage("Visa minnen"),
        "showMoreFaces":
            MessageLookupByLibrary.simpleMessage("Show more faces"),
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
        "sorryCouldNotAddToFavorites": MessageLookupByLibrary.simpleMessage(
            "Tyvärr, kunde inte lägga till i favoriterna!"),
        "sorryCouldNotRemoveFromFavorites":
            MessageLookupByLibrary.simpleMessage(
                "Tyvärr kunde inte ta bort från favoriter!"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "Tyvärr, vi kunde inte generera säkra nycklar på den här enheten.\n\nVänligen registrera dig från en annan enhet."),
        "sort": MessageLookupByLibrary.simpleMessage("Sortera"),
        "sortAlbumsBy": MessageLookupByLibrary.simpleMessage("Sortera efter"),
        "status": MessageLookupByLibrary.simpleMessage("Status"),
        "storageBreakupYou": MessageLookupByLibrary.simpleMessage("Du"),
        "storageInGB": m93,
        "strongStrength": MessageLookupByLibrary.simpleMessage("Starkt"),
        "subscribe": MessageLookupByLibrary.simpleMessage("Prenumerera"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "Du behöver en aktiv betald prenumeration för att möjliggöra delning."),
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
        "theyAlsoGetXGb": m99,
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "Detta kan användas för att återställa ditt konto om du förlorar din andra faktor"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Den här enheten"),
        "thisIsPersonVerificationId": m100,
        "thisIsYourVerificationId": MessageLookupByLibrary.simpleMessage(
            "Detta är ditt verifierings-ID"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Detta kommer att logga ut dig från följande enhet:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Detta kommer att logga ut dig från denna enhet!"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "För att återställa ditt lösenord måste du först bekräfta din e-postadress."),
        "total": MessageLookupByLibrary.simpleMessage("totalt"),
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
        "unavailableReferralCode": MessageLookupByLibrary.simpleMessage(
            "Tyvärr är denna kod inte tillgänglig."),
        "unselectAll": MessageLookupByLibrary.simpleMessage("Avmarkera alla"),
        "update": MessageLookupByLibrary.simpleMessage("Uppdatera"),
        "updatingFolderSelection":
            MessageLookupByLibrary.simpleMessage("Uppdaterar mappval..."),
        "upgrade": MessageLookupByLibrary.simpleMessage("Uppgradera"),
        "uploadingMultipleMemories": m109,
        "uploadingSingleMemory":
            MessageLookupByLibrary.simpleMessage("Bevarar 1 minne..."),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "Användbart lagringsutrymme begränsas av din nuvarande plan. Överskrider du lagringsutrymmet kommer automatiskt att kunna använda det när du uppgraderar din plan."),
        "useAsCover": MessageLookupByLibrary.simpleMessage("Använd som omslag"),
        "useRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Använd återställningsnyckel"),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("Verifierings-ID"),
        "verify": MessageLookupByLibrary.simpleMessage("Bekräfta"),
        "verifyEmail":
            MessageLookupByLibrary.simpleMessage("Bekräfta e-postadress"),
        "verifyEmailID": m111,
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
        "weHaveSendEmailTo": m114,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Svagt"),
        "welcomeBack":
            MessageLookupByLibrary.simpleMessage("Välkommen tillbaka!"),
        "whatsNew": MessageLookupByLibrary.simpleMessage("Nyheter"),
        "wishThemAHappyBirthday": m115,
        "yearsAgo": m116,
        "yes": MessageLookupByLibrary.simpleMessage("Ja"),
        "yesCancel": MessageLookupByLibrary.simpleMessage("Ja, avbryt"),
        "yesConvertToViewer":
            MessageLookupByLibrary.simpleMessage("Ja, konvertera till bildvy"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("Ja, radera"),
        "yesLogout": MessageLookupByLibrary.simpleMessage("Ja, logga ut"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("Ja, ta bort"),
        "yesRenew": MessageLookupByLibrary.simpleMessage("Ja, förnya"),
        "you": MessageLookupByLibrary.simpleMessage("Du"),
        "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "* Du kan max fördubbla ditt lagringsutrymme"),
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("Ditt konto har raderats")
      };
}
