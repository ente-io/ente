// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a nl locale. All the
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
  String get localeName => 'nl';

  static String m4(user) =>
      "${user} zal geen foto\'s meer kunnen toevoegen aan dit album\n\nDe gebruiker zal nog steeds bestaande foto\'s kunnen verwijderen die door hen zijn toegevoegd";

  static String m10(albumName) =>
      "Dit verwijdert de openbare link voor toegang tot \"${albumName}\".";

  static String m11(supportEmail) =>
      "Stuur een e-mail naar ${supportEmail} vanaf het door jou geregistreerde e-mailadres";

  static String m14(email) =>
      "${email} heeft geen ente account.\n\nStuur ze een uitnodiging om foto\'s te delen.";

  static String m22(count) =>
      "${Intl.plural(count, one: '${count} item', other: '${count} items')}";

  static String m24(expiryTime) => "Link vervalt op ${expiryTime}";

  static String m25(maxValue) =>
      "Wanneer ingesteld op het maximum (${maxValue}), wordt het apparaatlimiet versoepeld om tijdelijke pieken van grote aantallen kijkers mogelijk te maken.";

  static String m26(count) =>
      "${Intl.plural(count, zero: 'geen herinneringen', one: '${count} herinnering', other: '${count} herinneringen')}";

  static String m29(passwordStrengthValue) =>
      "Wachtwoord sterkte: ${passwordStrengthValue}";

  static String m36(userEmail) =>
      "${userEmail} zal worden verwijderd uit dit gedeelde album\n\nAlle door hen toegevoegde foto\'s worden ook uit het album verwijderd";

  static String m38(count) => "${count} geselecteerd";

  static String m39(count, yourCount) =>
      "${count} geselecteerd (${yourCount} van jou)";

  static String m40(verificationID) =>
      "Hier is mijn verificatie-ID: ${verificationID} voor ente.io.";

  static String m41(verificationID) =>
      "Hey, kunt u bevestigen dat dit uw ente.io verificatie-ID is: ${verificationID}";

  static String m43(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Deel met specifieke mensen', one: 'Gedeeld met 1 persoon', other: 'Gedeeld met ${numberOfPeople} mensen')}";

  static String m45(fileType) =>
      "Dit ${fileType} zal worden verwijderd van jouw apparaat.";

  static String m46(fileType) =>
      "Dit ${fileType} staat zowel in ente als in jouw apparaat.";

  static String m47(fileType) =>
      "Dit ${fileType} zal worden verwijderd uit ente.";

  static String m53(email) => "Dit is de verificatie-ID van ${email}";

  static String m54(email) => "Verifieer ${email}";

  static String m55(count) =>
      "${Intl.plural(count, one: '${count} jaar geleden', other: '${count} jaren geleden')}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable": MessageLookupByLibrary.simpleMessage(
            "Er is een nieuwe versie van ente beschikbaar."),
        "about": MessageLookupByLibrary.simpleMessage("Over"),
        "account": MessageLookupByLibrary.simpleMessage("Account"),
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Welkom terug!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Ik begrijp dat als ik mijn wachtwoord verlies, ik mijn gegevens kan verliezen omdat mijn gegevens <underline>end-to-end versleuteld</underline> zijn."),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Actieve sessies"),
        "addANewEmail":
            MessageLookupByLibrary.simpleMessage("Nieuw e-mailadres toevoegen"),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Samenwerker toevoegen"),
        "addMore": MessageLookupByLibrary.simpleMessage("Meer toevoegen"),
        "addViewer": MessageLookupByLibrary.simpleMessage("Voeg kijker toe"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Toegevoegd als"),
        "addingToFavorites":
            MessageLookupByLibrary.simpleMessage("Toevoegen aan favorieten..."),
        "advancedSettings": MessageLookupByLibrary.simpleMessage("Geavanceerd"),
        "after1Day": MessageLookupByLibrary.simpleMessage("Na 1 dag"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("Na 1 uur"),
        "after1Month": MessageLookupByLibrary.simpleMessage("Na 1 maand"),
        "after1Week": MessageLookupByLibrary.simpleMessage("Na 1 week"),
        "after1Year": MessageLookupByLibrary.simpleMessage("Na 1 jaar"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Eigenaar"),
        "albumUpdated":
            MessageLookupByLibrary.simpleMessage("Album bijgewerkt"),
        "albums": MessageLookupByLibrary.simpleMessage("Albums"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Sta toe dat mensen met de link ook foto\'s kunnen toevoegen aan het gedeelde album."),
        "allowAddingPhotos":
            MessageLookupByLibrary.simpleMessage("Foto\'s toevoegen toestaan"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("Downloads toestaan"),
        "applyCodeTitle":
            MessageLookupByLibrary.simpleMessage("Code toepassen"),
        "archive": MessageLookupByLibrary.simpleMessage("Archiveer"),
        "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
            "Weet je zeker dat je wilt uitloggen?"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "Wat is de voornaamste reden dat je jouw account verwijdert?"),
        "authToChangeYourEmail": MessageLookupByLibrary.simpleMessage(
            "Gelieve te verifiëren om je e-mailadres te wijzigen"),
        "authToChangeYourPassword": MessageLookupByLibrary.simpleMessage(
            "Gelieve te verifiëren om je wachtwoord te wijzigen"),
        "authToInitiateAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Gelieve te verifiëren om het verwijderen van je account te starten"),
        "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
            "Gelieve te verifiëren om je verborgen bestanden te bekijken"),
        "backupOverMobileData": MessageLookupByLibrary.simpleMessage(
            "Back-up maken via mobiele data"),
        "backupSettings":
            MessageLookupByLibrary.simpleMessage("Back-up instellingen"),
        "backupVideos":
            MessageLookupByLibrary.simpleMessage("Back-up video\'s"),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "Kan alleen bestanden verwijderen die jouw eigendom zijn"),
        "cancel": MessageLookupByLibrary.simpleMessage("Annuleer"),
        "cannotAddMorePhotosAfterBecomingViewer": m4,
        "changeEmail": MessageLookupByLibrary.simpleMessage("E-mail wijzigen"),
        "changePassword":
            MessageLookupByLibrary.simpleMessage("Wachtwoord wijzigen"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Wachtwoord wijzigen"),
        "changePermissions":
            MessageLookupByLibrary.simpleMessage("Rechten aanpassen?"),
        "checkForUpdates":
            MessageLookupByLibrary.simpleMessage("Controleer op updates"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Controleer je inbox (en spam) om verificatie te voltooien"),
        "checking": MessageLookupByLibrary.simpleMessage("Controleren..."),
        "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Code gekopieerd naar klembord"),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Maak een link waarmee mensen foto\'s in jouw gedeelde album kunnen toevoegen en bekijken zonder dat ze daarvoor een ente app of account nodig hebben. Handig voor het verzamelen van foto\'s van evenementen."),
        "collaborativeLink":
            MessageLookupByLibrary.simpleMessage("Gezamenlijke link"),
        "collaborator": MessageLookupByLibrary.simpleMessage("Samenwerker"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Samenwerkers kunnen foto\'s en video\'s toevoegen aan het gedeelde album."),
        "collectPhotos":
            MessageLookupByLibrary.simpleMessage("Foto\'s verzamelen"),
        "confirm": MessageLookupByLibrary.simpleMessage("Bevestig"),
        "confirmAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Account verwijderen bevestigen"),
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Ja, ik wil permanent mijn account inclusief alle gegevens verwijderen."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Wachtwoord bevestigen"),
        "confirmRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Bevestig herstelsleutel"),
        "confirmYourRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Bevestig herstelsleutel"),
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("Contacteer ondersteuning"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("Doorgaan"),
        "copyLink": MessageLookupByLibrary.simpleMessage("Kopieer link"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Kopieer en plak deze code\nnaar je authenticator app"),
        "createAccount":
            MessageLookupByLibrary.simpleMessage("Account aanmaken"),
        "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
            "Lang indrukken om foto\'s te selecteren en klik + om een album te maken"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("Nieuw account aanmaken"),
        "createPublicLink":
            MessageLookupByLibrary.simpleMessage("Maak publieke link"),
        "creatingLink":
            MessageLookupByLibrary.simpleMessage("Link aanmaken..."),
        "criticalUpdateAvailable": MessageLookupByLibrary.simpleMessage(
            "Belangrijke update beschikbaar"),
        "custom": MessageLookupByLibrary.simpleMessage("Aangepast"),
        "decrypting": MessageLookupByLibrary.simpleMessage("Ontsleutelen..."),
        "deleteAccount":
            MessageLookupByLibrary.simpleMessage("Account verwijderen"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "We vinden het jammer je te zien gaan. Deel je feedback om ons te helpen verbeteren."),
        "deleteAccountPermanentlyButton": MessageLookupByLibrary.simpleMessage(
            "Account permanent verwijderen"),
        "deleteAlbum": MessageLookupByLibrary.simpleMessage("Verwijder album"),
        "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
            "Verwijder de foto\'s (en video\'s) van dit album ook uit <bold>alle</bold> andere albums waar deze deel van uitmaken?"),
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
            "Je staat op het punt je account en alle bijbehorende gegevens permanent te verwijderen.\nDeze actie is onomkeerbaar."),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "Stuur een e-mail naar <warning>account-deletion@ente.io</warning> vanaf het door jou geregistreerde e-mailadres."),
        "deleteFromBoth":
            MessageLookupByLibrary.simpleMessage("Verwijder van beide"),
        "deleteFromDevice":
            MessageLookupByLibrary.simpleMessage("Verwijder van apparaat"),
        "deleteFromEnte":
            MessageLookupByLibrary.simpleMessage("Verwijder van ente"),
        "deletePhotos":
            MessageLookupByLibrary.simpleMessage("Foto\'s verwijderen"),
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "Ik mis een belangrijke functie"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "De app of een bepaalde functie functioneert niet \nzoals ik verwacht"),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
            "Ik heb een andere dienst gevonden die me beter bevalt"),
        "deleteReason4": MessageLookupByLibrary.simpleMessage(
            "Mijn reden wordt niet vermeld"),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
            "Je verzoek wordt binnen 72 uur verwerkt."),
        "deleteSharedAlbum":
            MessageLookupByLibrary.simpleMessage("Gedeeld album verwijderen?"),
        "deleteSharedAlbumDialogBody": MessageLookupByLibrary.simpleMessage(
            "Het album wordt verwijderd voor iedereen\n\nJe verliest de toegang tot gedeelde foto\'s in dit album die eigendom zijn van anderen"),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
            "Schakel de schermvergrendeling van het apparaat uit wanneer ente op de voorgrond is en er een back-up aan de gang is. Dit is normaal gesproken niet nodig, maar kan grote uploads en initiële imports van grote mappen sneller laten verlopen."),
        "disableAutoLock": MessageLookupByLibrary.simpleMessage(
            "Automatisch vergrendelen uitschakelen"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Kijkers kunnen nog steeds screenshots maken of een kopie van je foto\'s opslaan met behulp van externe tools"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Let op"),
        "disableLinkMessage": m10,
        "doThisLater": MessageLookupByLibrary.simpleMessage("Doe dit later"),
        "done": MessageLookupByLibrary.simpleMessage("Voltooid"),
        "downloading": MessageLookupByLibrary.simpleMessage("Downloaden..."),
        "dropSupportEmail": m11,
        "email": MessageLookupByLibrary.simpleMessage("E-mail"),
        "emailNoEnteAccount": m14,
        "encryption": MessageLookupByLibrary.simpleMessage("Encryptie"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Encryptiesleutels"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Voer code in"),
        "enterEmail":
            MessageLookupByLibrary.simpleMessage("Voer e-mailadres in"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Voer een nieuw wachtwoord in dat we kunnen gebruiken om je gegevens te versleutelen"),
        "enterPassword":
            MessageLookupByLibrary.simpleMessage("Voer wachtwoord in"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Voer een wachtwoord in dat we kunnen gebruiken om je gegevens te versleutelen"),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Voer de 6-cijferige code van je verificatie-app in"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "Voer een geldig e-mailadres in."),
        "enterYourEmailAddress":
            MessageLookupByLibrary.simpleMessage("Voer je e-mailadres in"),
        "enterYourPassword":
            MessageLookupByLibrary.simpleMessage("Voer je wachtwoord in"),
        "enterYourRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Voer je herstelcode in"),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
            "Deze link is verlopen. Selecteer een nieuwe vervaltijd of schakel de vervaldatum uit."),
        "exportYourData":
            MessageLookupByLibrary.simpleMessage("Exporteer je gegevens"),
        "failedToLoadAlbums":
            MessageLookupByLibrary.simpleMessage("Laden van albums mislukt"),
        "feedback": MessageLookupByLibrary.simpleMessage("Feedback"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Wachtwoord vergeten"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Encryptiesleutels genereren..."),
        "hidden": MessageLookupByLibrary.simpleMessage("Verborgen"),
        "howItWorks": MessageLookupByLibrary.simpleMessage("Hoe het werkt"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "Vraag hen om hun e-mailadres lang in te drukken op het instellingenscherm en te controleren dat de ID\'s op beide apparaten overeenkomen."),
        "importing": MessageLookupByLibrary.simpleMessage("Importeren...."),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Onjuist wachtwoord"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "De ingevoerde herstelsleutel is onjuist"),
        "incorrectRecoveryKeyTitle":
            MessageLookupByLibrary.simpleMessage("Onjuiste herstelsleutel"),
        "insecureDevice":
            MessageLookupByLibrary.simpleMessage("Onveilig apparaat"),
        "installManually":
            MessageLookupByLibrary.simpleMessage("Installeer handmatig"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("Ongeldig e-mailadres"),
        "invalidKey": MessageLookupByLibrary.simpleMessage("Ongeldige sleutel"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "De herstelsleutel die je hebt ingevoerd is niet geldig. Zorg ervoor dat deze 24 woorden bevat en controleer de spelling van elk van deze woorden.\n\nAls je een oudere herstelcode hebt ingevoerd, zorg ervoor dat deze 64 tekens lang is, en controleer ze allemaal."),
        "inviteToEnte":
            MessageLookupByLibrary.simpleMessage("Uitnodigen voor ente"),
        "itemCount": m22,
        "keepPhotos": MessageLookupByLibrary.simpleMessage("Foto\'s behouden"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Help ons alsjeblieft met deze informatie"),
        "linkDeviceLimit":
            MessageLookupByLibrary.simpleMessage("Apparaat limiet"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Ingeschakeld"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Verlopen"),
        "linkExpiresOn": m24,
        "linkExpiry": MessageLookupByLibrary.simpleMessage("Vervaldatum"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("Link is vervallen"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Nooit"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Vergrendel"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Inloggen"),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "Door op inloggen te klikken, ga ik akkoord met de <u-terms>gebruiksvoorwaarden</u-terms> en <u-policy>privacybeleid</u-policy>"),
        "logout": MessageLookupByLibrary.simpleMessage("Uitloggen"),
        "lostDevice":
            MessageLookupByLibrary.simpleMessage("Apparaat verloren?"),
        "manage": MessageLookupByLibrary.simpleMessage("Beheren"),
        "manageDeviceStorage":
            MessageLookupByLibrary.simpleMessage("Apparaatopslag beheren"),
        "manageLink": MessageLookupByLibrary.simpleMessage("Beheer link"),
        "manageParticipants": MessageLookupByLibrary.simpleMessage("Beheren"),
        "manageSubscription":
            MessageLookupByLibrary.simpleMessage("Abonnement beheren"),
        "maxDeviceLimitSpikeHandling": m25,
        "memoryCount": m26,
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Matig"),
        "movedToTrash":
            MessageLookupByLibrary.simpleMessage("Naar prullenbak verplaatst"),
        "never": MessageLookupByLibrary.simpleMessage("Nooit"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Nieuw album"),
        "noDuplicates":
            MessageLookupByLibrary.simpleMessage("✨ Geen duplicaten"),
        "noRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Geen herstelcode?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "Door de aard van ons end-to-end encryptieprotocol kunnen je gegevens niet worden ontsleuteld zonder je wachtwoord of herstelsleutel"),
        "ok": MessageLookupByLibrary.simpleMessage("Oké"),
        "oops": MessageLookupByLibrary.simpleMessage("Oeps"),
        "orPickAnExistingOne":
            MessageLookupByLibrary.simpleMessage("Of kies een bestaande"),
        "password": MessageLookupByLibrary.simpleMessage("Wachtwoord"),
        "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
            "Wachtwoord succesvol aangepast"),
        "passwordLock": MessageLookupByLibrary.simpleMessage("Wachtwoord slot"),
        "passwordStrength": m29,
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Wij slaan dit wachtwoord niet op, dus als je het vergeet, kunnen <underline>we je gegevens niet ontsleutelen</underline>"),
        "photoGridSize":
            MessageLookupByLibrary.simpleMessage("Foto raster grootte"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("foto"),
        "pleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("Probeer het nog eens"),
        "pleaseWait":
            MessageLookupByLibrary.simpleMessage("Een ogenblik geduld..."),
        "privacy": MessageLookupByLibrary.simpleMessage("Privacy"),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Privacybeleid"),
        "publicLinkEnabled":
            MessageLookupByLibrary.simpleMessage("Publieke link ingeschakeld"),
        "recover": MessageLookupByLibrary.simpleMessage("Herstellen"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("Account herstellen"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Herstellen"),
        "recoveryKey": MessageLookupByLibrary.simpleMessage("Herstelsleutel"),
        "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Herstelsleutel gekopieerd naar klembord"),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
            "Als je je wachtwoord vergeet, kun je alleen met deze sleutel je gegevens herstellen."),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
            "We slaan deze sleutel niet op, bewaar deze 24 woorden sleutel op een veilige plaats."),
        "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
            "Super! Je herstelsleutel is geldig. Bedankt voor het verifiëren.\n\nVergeet niet om je herstelsleutel veilig te bewaren."),
        "recoveryKeyVerified": MessageLookupByLibrary.simpleMessage(
            "Herstel sleutel geverifieerd"),
        "recoveryKeyVerifyReason": MessageLookupByLibrary.simpleMessage(
            "Je herstelsleutel is de enige manier om je foto\'s te herstellen als je je wachtwoord bent vergeten. Je vindt je herstelsleutel in Instellingen > Account.\n\nVoer hier je herstelsleutel in om te controleren of je hem correct hebt opgeslagen."),
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("Herstel succesvol!"),
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "Het huidige apparaat is niet krachtig genoeg om je wachtwoord te verifiëren, dus moeten we de code een keer opnieuw genereren op een manier die met alle apparaten werkt.\n\nLog in met behulp van uw herstelcode en genereer opnieuw uw wachtwoord (je kunt dezelfde indien gewenst opnieuw gebruiken)."),
        "recreatePasswordTitle": MessageLookupByLibrary.simpleMessage(
            "Wachtwoord opnieuw instellen"),
        "remove": MessageLookupByLibrary.simpleMessage("Verwijder"),
        "removeLink": MessageLookupByLibrary.simpleMessage("Verwijder link"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Deelnemer verwijderen"),
        "removeParticipantBody": m36,
        "removePublicLink":
            MessageLookupByLibrary.simpleMessage("Verwijder publieke link"),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
            "Sommige van de items die je verwijdert zijn door andere mensen toegevoegd, en je verliest de toegang daartoe"),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Verwijder?"),
        "removingFromFavorites": MessageLookupByLibrary.simpleMessage(
            "Verwijderen uit favorieten..."),
        "resendEmail":
            MessageLookupByLibrary.simpleMessage("E-mail opnieuw versturen"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Wachtwoord resetten"),
        "retry": MessageLookupByLibrary.simpleMessage("Opnieuw"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Bewaar sleutel"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Sla je herstelsleutel op als je dat nog niet gedaan hebt"),
        "scanCode": MessageLookupByLibrary.simpleMessage("Scan code"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Scan deze barcode met\nje authenticator app"),
        "selectAll": MessageLookupByLibrary.simpleMessage("Selecteer alles"),
        "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
            "Selecteer mappen voor back-up"),
        "selectReason": MessageLookupByLibrary.simpleMessage("Selecteer reden"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "Geselecteerde mappen worden versleuteld en geback-upt"),
        "selectedPhotos": m38,
        "selectedPhotosWithYours": m39,
        "sendEmail": MessageLookupByLibrary.simpleMessage("E-mail versturen"),
        "sendInvite":
            MessageLookupByLibrary.simpleMessage("Stuur een uitnodiging"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Stuur link"),
        "setAPassword":
            MessageLookupByLibrary.simpleMessage("Stel een wachtwoord in"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Wachtwoord instellen"),
        "setupComplete": MessageLookupByLibrary.simpleMessage("Setup voltooid"),
        "shareALink": MessageLookupByLibrary.simpleMessage("Deel een link"),
        "shareMyVerificationID": m40,
        "shareTextConfirmOthersVerificationID": m41,
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
            "Delen met niet-ente gebruikers"),
        "shareWithPeopleSectionTitle": m43,
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Maak gedeelde en collaboratieve albums met andere ente gebruikers, inclusief gebruikers met gratis abonnementen."),
        "sharing": MessageLookupByLibrary.simpleMessage("Delen..."),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "Ik ga akkoord met de <u-terms>gebruiksvoorwaarden</u-terms> en <u-policy>privacybeleid</u-policy>"),
        "singleFileDeleteFromDevice": m45,
        "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
            "Het wordt uit alle albums verwijderd."),
        "singleFileInBothLocalAndRemote": m46,
        "singleFileInRemoteOnly": m47,
        "skip": MessageLookupByLibrary.simpleMessage("Overslaan"),
        "someoneSharingAlbumsWithYouShouldSeeTheSameId":
            MessageLookupByLibrary.simpleMessage(
                "Iemand die albums met je deelt zou hetzelfde ID op hun apparaat moeten zien."),
        "somethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Er ging iets mis"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Er is iets fout gegaan, probeer het opnieuw"),
        "sorry": MessageLookupByLibrary.simpleMessage("Sorry"),
        "sorryCouldNotAddToFavorites": MessageLookupByLibrary.simpleMessage(
            "Sorry, kon niet aan favorieten worden toegevoegd!"),
        "sorryCouldNotRemoveFromFavorites":
            MessageLookupByLibrary.simpleMessage(
                "Sorry, kon niet uit favorieten worden verwijderd!"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "Sorry, we konden geen beveiligde sleutels genereren op dit apparaat.\n\nGelieve je aan te melden vanaf een ander apparaat."),
        "sparkleSuccess": MessageLookupByLibrary.simpleMessage("✨ Succes"),
        "strongStrength": MessageLookupByLibrary.simpleMessage("Sterk"),
        "subscribe": MessageLookupByLibrary.simpleMessage("Abonneer"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "Het lijkt erop dat je abonnement is verlopen. Abonneer om delen mogelijk te maken."),
        "tapToCopy": MessageLookupByLibrary.simpleMessage("tik om te kopiëren"),
        "tapToEnterCode":
            MessageLookupByLibrary.simpleMessage("Tik om code in te voeren"),
        "terminate": MessageLookupByLibrary.simpleMessage("Beëindigen"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Sessie beëindigen?"),
        "terms": MessageLookupByLibrary.simpleMessage("Voorwaarden"),
        "termsOfServicesTitle":
            MessageLookupByLibrary.simpleMessage("Voorwaarden"),
        "theDownloadCouldNotBeCompleted": MessageLookupByLibrary.simpleMessage(
            "De download kon niet worden voltooid"),
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "Dit kan worden gebruikt om je account te herstellen als je je tweede factor verliest"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Dit apparaat"),
        "thisIsPersonVerificationId": m53,
        "thisIsYourVerificationId":
            MessageLookupByLibrary.simpleMessage("Dit is uw verificatie-ID"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Dit zal je uitloggen van het volgende apparaat:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Dit zal je uitloggen van dit apparaat!"),
        "trash": MessageLookupByLibrary.simpleMessage("Prullenbak"),
        "tryAgain": MessageLookupByLibrary.simpleMessage("Probeer opnieuw"),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage("Tweestapsverificatie"),
        "twofactorSetup":
            MessageLookupByLibrary.simpleMessage("Tweestapsverificatie"),
        "uncategorized":
            MessageLookupByLibrary.simpleMessage("Ongecategoriseerd"),
        "unselectAll":
            MessageLookupByLibrary.simpleMessage("Deselecteer alles"),
        "update": MessageLookupByLibrary.simpleMessage("Update"),
        "updateAvailable":
            MessageLookupByLibrary.simpleMessage("Update beschikbaar"),
        "updatingFolderSelection":
            MessageLookupByLibrary.simpleMessage("Map selectie bijwerken..."),
        "useRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Herstelcode gebruiken"),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("Verificatie ID"),
        "verify": MessageLookupByLibrary.simpleMessage("Verifiëren"),
        "verifyEmail": MessageLookupByLibrary.simpleMessage("Bevestig e-mail"),
        "verifyEmailID": m54,
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Bevestig wachtwoord"),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Herstelsleutel verifiëren..."),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("video"),
        "viewRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Toon herstelsleutel"),
        "viewer": MessageLookupByLibrary.simpleMessage("Kijker"),
        "weAreOpenSource":
            MessageLookupByLibrary.simpleMessage("We zijn open source!"),
        "weakStrength": MessageLookupByLibrary.simpleMessage("Zwak"),
        "welcomeBack": MessageLookupByLibrary.simpleMessage("Welkom terug!"),
        "weveSentAMailTo": MessageLookupByLibrary.simpleMessage(
            "We hebben een e-mail gestuurd naar"),
        "yearsAgo": m55,
        "yesConvertToViewer":
            MessageLookupByLibrary.simpleMessage("Ja, converteren naar viewer"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("Ja, verwijderen"),
        "yesLogout": MessageLookupByLibrary.simpleMessage("Ja, log uit"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("Ja, verwijderen"),
        "you": MessageLookupByLibrary.simpleMessage("Jij"),
        "youAreOnTheLatestVersion":
            MessageLookupByLibrary.simpleMessage("Je hebt de laatste versie"),
        "youCannotShareWithYourself": MessageLookupByLibrary.simpleMessage(
            "Je kunt niet met jezelf delen"),
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("Je account is verwijderd")
      };
}
