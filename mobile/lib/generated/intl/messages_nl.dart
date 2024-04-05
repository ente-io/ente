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

  static String m0(count) =>
      "${Intl.plural(count, zero: 'Add collaborator', one: 'Add collaborator', other: 'Add collaborators')}";

  static String m2(count) =>
      "${Intl.plural(count, one: 'Bestand toevoegen', other: 'Bestanden toevoegen')}";

  static String m3(storageAmount, endDate) =>
      "Jouw ${storageAmount} add-on is geldig tot ${endDate}";

  static String m1(count) =>
      "${Intl.plural(count, zero: 'Add viewer', one: 'Add viewer', other: 'Add viewers')}";

  static String m4(emailOrName) => "Toegevoegd door ${emailOrName}";

  static String m5(albumName) => "Succesvol toegevoegd aan  ${albumName}";

  static String m6(count) =>
      "${Intl.plural(count, zero: 'Geen deelnemers', one: '1 deelnemer', other: '${count} deelnemers')}";

  static String m7(versionValue) => "Versie: ${versionValue}";

  static String m8(paymentProvider) =>
      "Annuleer eerst uw bestaande abonnement bij ${paymentProvider}";

  static String m9(user) =>
      "${user} zal geen foto\'s meer kunnen toevoegen aan dit album\n\nDe gebruiker zal nog steeds bestaande foto\'s kunnen verwijderen die door hen zijn toegevoegd";

  static String m10(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true':
                'Jouw familie heeft ${storageAmountInGb} GB geclaimd tot nu toe',
            'false': 'Je hebt ${storageAmountInGb} GB geclaimd tot nu toe',
            'other': 'Je hebt ${storageAmountInGb} GB geclaimd tot nu toe!',
          })}";

  static String m11(albumName) =>
      "Gezamenlijke link aangemaakt voor ${albumName}";

  static String m12(familyAdminEmail) =>
      "Neem contact op met <green>${familyAdminEmail}</green> om uw abonnement te beheren";

  static String m13(provider) =>
      "Neem contact met ons op via support@ente.io om uw ${provider} abonnement te beheren.";

  static String m14(count) =>
      "${Intl.plural(count, one: 'Verwijder ${count} bestand', other: 'Verwijder ${count} bestanden')}";

  static String m15(currentlyDeleting, totalCount) =>
      "Verwijderen van ${currentlyDeleting} / ${totalCount}";

  static String m16(albumName) =>
      "Dit verwijdert de openbare link voor toegang tot \"${albumName}\".";

  static String m17(supportEmail) =>
      "Stuur een e-mail naar ${supportEmail} vanaf het door jou geregistreerde e-mailadres";

  static String m18(count, storageSaved) =>
      "Je hebt ${Intl.plural(count, one: '${count} dubbel bestand', other: '${count} dubbele bestanden')} opgeruimd, totaal (${storageSaved}!)";

  static String m19(count, formattedSize) =>
      "${count} bestanden, elk ${formattedSize}";

  static String m20(newEmail) => "E-mailadres gewijzigd naar ${newEmail}";

  static String m21(email) =>
      "${email} heeft geen ente account.\n\nStuur ze een uitnodiging om foto\'s te delen.";

  static String m22(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 bestand', other: '${formattedNumber} bestanden')} in dit album zijn veilig geback-upt";

  static String m23(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 bestand', other: '${formattedNumber} bestanden')} in dit album is veilig geback-upt";

  static String m24(storageAmountInGB) =>
      "${storageAmountInGB} GB telkens als iemand zich aanmeldt voor een betaald abonnement en je code toepast";

  static String m25(freeAmount, storageUnit) =>
      "${freeAmount} ${storageUnit} vrij";

  static String m26(endDate) => "Gratis proefversie geldig tot ${endDate}";

  static String m27(count) =>
      "U heeft nog steeds toegang tot ${Intl.plural(count, one: 'het', other: 'ze')} op ente zolang u een actief abonnement heeft";

  static String m28(sizeInMBorGB) => "Maak ${sizeInMBorGB} vrij";

  static String m29(count, formattedSize) =>
      "${Intl.plural(count, one: 'Het kan verwijderd worden van het apparaat om ${formattedSize} vrij te maken', other: 'Ze kunnen verwijderd worden van het apparaat om ${formattedSize} vrij te maken')}";

  static String m30(currentlyProcessing, totalCount) =>
      "Verwerken van ${currentlyProcessing} / ${totalCount}";

  static String m31(count) =>
      "${Intl.plural(count, one: '${count} item', other: '${count} items')}";

  static String m32(expiryTime) => "Link vervalt op ${expiryTime}";

  static String m33(count, formattedCount) =>
      "${Intl.plural(count, zero: 'geen herinneringen', one: '${formattedCount} herinnering', other: '${formattedCount} herinneringen')}";

  static String m34(count) =>
      "${Intl.plural(count, one: 'Bestand verplaatsen', other: 'Bestanden verplaatsen')}";

  static String m35(albumName) => "Succesvol verplaatst naar ${albumName}";

  static String m36(passwordStrengthValue) =>
      "Wachtwoord sterkte: ${passwordStrengthValue}";

  static String m37(providerName) =>
      "Praat met ${providerName} klantenservice als u in rekening bent gebracht";

  static String m38(endDate) =>
      "Gratis proefperiode geldig tot ${endDate}.\nU kunt naderhand een betaald abonnement kiezen.";

  static String m39(toEmail) => "Stuur ons een e-mail op ${toEmail}";

  static String m40(toEmail) =>
      "Verstuur de logboeken alstublieft naar ${toEmail}";

  static String m41(storeName) => "Beoordeel ons op ${storeName}";

  static String m42(storageInGB) =>
      "Jullie krijgen allebei ${storageInGB} GB* gratis";

  static String m43(userEmail) =>
      "${userEmail} zal worden verwijderd uit dit gedeelde album\n\nAlle door hen toegevoegde foto\'s worden ook uit het album verwijderd";

  static String m44(endDate) => "Wordt verlengd op ${endDate}";

  static String m45(count) =>
      "${Intl.plural(count, one: '${count} resultaat gevonden', other: '${count} resultaten gevonden')}";

  static String m46(count) => "${count} geselecteerd";

  static String m47(count, yourCount) =>
      "${count} geselecteerd (${yourCount} van jou)";

  static String m48(verificationID) =>
      "Hier is mijn verificatie-ID: ${verificationID} voor ente.io.";

  static String m49(verificationID) =>
      "Hey, kunt u bevestigen dat dit uw ente.io verificatie-ID is: ${verificationID}";

  static String m50(referralCode, referralStorageInGB) =>
      "ente verwijzingscode: ${referralCode} \n\nPas het toe bij Instellingen → Algemeen → Verwijzingen om ${referralStorageInGB} GB gratis te krijgen nadat je je hebt aangemeld voor een betaald abonnement\n\nhttps://ente.io";

  static String m51(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Deel met specifieke mensen', one: 'Gedeeld met 1 persoon', other: 'Gedeeld met ${numberOfPeople} mensen')}";

  static String m52(emailIDs) => "Gedeeld met ${emailIDs}";

  static String m53(fileType) =>
      "Deze ${fileType} zal worden verwijderd van jouw apparaat.";

  static String m54(fileType) =>
      "Deze ${fileType} staat zowel in ente als op jouw apparaat.";

  static String m55(fileType) =>
      "Deze ${fileType} zal worden verwijderd uit ente.";

  static String m56(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m57(
          usedAmount, usedStorageUnit, totalAmount, totalStorageUnit) =>
      "${usedAmount} ${usedStorageUnit} van ${totalAmount} ${totalStorageUnit} gebruikt";

  static String m58(id) =>
      "Uw ${id} is al aan een ander ente account gekoppeld.\nAls u uw ${id} wilt gebruiken met dit account, neem dan contact op met onze klantenservice";

  static String m59(endDate) => "Uw abonnement loopt af op ${endDate}";

  static String m60(completed, total) =>
      "${completed}/${total} herinneringen bewaard";

  static String m61(storageAmountInGB) =>
      "Zij krijgen ook ${storageAmountInGB} GB";

  static String m62(email) => "Dit is de verificatie-ID van ${email}";

  static String m63(count) =>
      "${Intl.plural(count, zero: '', one: '1 dag', other: '${count} dagen')}";

  static String m64(endDate) => "Geldig tot ${endDate}";

  static String m65(email) => "Verifieer ${email}";

  static String m66(email) =>
      "We hebben een e-mail gestuurd naar <green>${email}</green>";

  static String m67(count) =>
      "${Intl.plural(count, one: '${count} jaar geleden', other: '${count} jaar geleden')}";

  static String m68(storageSaved) =>
      "Je hebt ${storageSaved} succesvol vrijgemaakt!";

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
        "addCollaborators": m0,
        "addFromDevice":
            MessageLookupByLibrary.simpleMessage("Toevoegen vanaf apparaat"),
        "addItem": m2,
        "addLocation":
            MessageLookupByLibrary.simpleMessage("Locatie toevoegen"),
        "addLocationButton": MessageLookupByLibrary.simpleMessage("Toevoegen"),
        "addMore": MessageLookupByLibrary.simpleMessage("Meer toevoegen"),
        "addNew": MessageLookupByLibrary.simpleMessage("Nieuwe toevoegen"),
        "addOnPageSubtitle":
            MessageLookupByLibrary.simpleMessage("Details van add-ons"),
        "addOnValidTill": m3,
        "addOns": MessageLookupByLibrary.simpleMessage("Add-ons"),
        "addPhotos": MessageLookupByLibrary.simpleMessage("Foto\'s toevoegen"),
        "addSelected":
            MessageLookupByLibrary.simpleMessage("Voeg geselecteerde toe"),
        "addToAlbum":
            MessageLookupByLibrary.simpleMessage("Toevoegen aan album"),
        "addToEnte": MessageLookupByLibrary.simpleMessage("Toevoegen aan ente"),
        "addToHiddenAlbum": MessageLookupByLibrary.simpleMessage(
            "Toevoegen aan verborgen album"),
        "addViewer": MessageLookupByLibrary.simpleMessage("Voeg kijker toe"),
        "addViewers": m1,
        "addYourPhotosNow":
            MessageLookupByLibrary.simpleMessage("Voeg nu je foto\'s toe"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Toegevoegd als"),
        "addedBy": m4,
        "addedSuccessfullyTo": m5,
        "addingToFavorites":
            MessageLookupByLibrary.simpleMessage("Toevoegen aan favorieten..."),
        "advanced": MessageLookupByLibrary.simpleMessage("Geavanceerd"),
        "advancedSettings": MessageLookupByLibrary.simpleMessage("Geavanceerd"),
        "after1Day": MessageLookupByLibrary.simpleMessage("Na 1 dag"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("Na 1 uur"),
        "after1Month": MessageLookupByLibrary.simpleMessage("Na 1 maand"),
        "after1Week": MessageLookupByLibrary.simpleMessage("Na 1 week"),
        "after1Year": MessageLookupByLibrary.simpleMessage("Na 1 jaar"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Eigenaar"),
        "albumParticipantsCount": m6,
        "albumTitle": MessageLookupByLibrary.simpleMessage("Albumtitel"),
        "albumUpdated":
            MessageLookupByLibrary.simpleMessage("Album bijgewerkt"),
        "albums": MessageLookupByLibrary.simpleMessage("Albums"),
        "allClear": MessageLookupByLibrary.simpleMessage("✨ Alles in orde"),
        "allMemoriesPreserved":
            MessageLookupByLibrary.simpleMessage("Alle herinneringen bewaard"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Sta toe dat mensen met de link ook foto\'s kunnen toevoegen aan het gedeelde album."),
        "allowAddingPhotos":
            MessageLookupByLibrary.simpleMessage("Foto\'s toevoegen toestaan"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("Downloads toestaan"),
        "allowPeopleToAddPhotos": MessageLookupByLibrary.simpleMessage(
            "Mensen toestaan foto\'s toe te voegen"),
        "androidBiometricHint":
            MessageLookupByLibrary.simpleMessage("Identiteit verifiëren"),
        "androidBiometricNotRecognized": MessageLookupByLibrary.simpleMessage(
            "Niet herkend. Probeer het opnieuw."),
        "androidBiometricRequiredTitle": MessageLookupByLibrary.simpleMessage(
            "Biometrische verificatie vereist"),
        "androidBiometricSuccess":
            MessageLookupByLibrary.simpleMessage("Succes"),
        "androidCancelButton":
            MessageLookupByLibrary.simpleMessage("Annuleren"),
        "androidDeviceCredentialsRequiredTitle":
            MessageLookupByLibrary.simpleMessage("Apparaatgegevens vereist"),
        "androidDeviceCredentialsSetupDescription":
            MessageLookupByLibrary.simpleMessage("Apparaatgegevens vereist"),
        "androidGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "Biometrische verificatie is niet ingesteld op uw apparaat. Ga naar \'Instellingen > Beveiliging\' om biometrische verificatie toe te voegen."),
        "androidIosWebDesktop":
            MessageLookupByLibrary.simpleMessage("Android, iOS, Web, Desktop"),
        "androidSignInTitle":
            MessageLookupByLibrary.simpleMessage("Verificatie vereist"),
        "appVersion": m7,
        "appleId": MessageLookupByLibrary.simpleMessage("Apple ID"),
        "apply": MessageLookupByLibrary.simpleMessage("Toepassen"),
        "applyCodeTitle":
            MessageLookupByLibrary.simpleMessage("Code toepassen"),
        "appstoreSubscription":
            MessageLookupByLibrary.simpleMessage("PlayStore abonnement"),
        "archive": MessageLookupByLibrary.simpleMessage("Archiveer"),
        "archiveAlbum":
            MessageLookupByLibrary.simpleMessage("Album archiveren"),
        "archiving": MessageLookupByLibrary.simpleMessage("Archiveren..."),
        "areYouSureThatYouWantToLeaveTheFamily":
            MessageLookupByLibrary.simpleMessage(
                "Weet u zeker dat u het familie abonnement wilt verlaten?"),
        "areYouSureYouWantToCancel": MessageLookupByLibrary.simpleMessage(
            "Weet u zeker dat u wilt opzeggen?"),
        "areYouSureYouWantToChangeYourPlan":
            MessageLookupByLibrary.simpleMessage(
                "Weet u zeker dat u uw abonnement wilt wijzigen?"),
        "areYouSureYouWantToExit": MessageLookupByLibrary.simpleMessage(
            "Weet u zeker dat u wilt afsluiten?"),
        "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
            "Weet je zeker dat je wilt uitloggen?"),
        "areYouSureYouWantToRenew": MessageLookupByLibrary.simpleMessage(
            "Weet u zeker dat u wilt verlengen?"),
        "askCancelReason": MessageLookupByLibrary.simpleMessage(
            "Uw abonnement is opgezegd. Wilt u de reden delen?"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "Wat is de voornaamste reden dat je jouw account verwijdert?"),
        "askYourLovedOnesToShare": MessageLookupByLibrary.simpleMessage(
            "Vraag uw dierbaren om te delen"),
        "atAFalloutShelter":
            MessageLookupByLibrary.simpleMessage("in een kernbunker"),
        "authToChangeEmailVerificationSetting":
            MessageLookupByLibrary.simpleMessage(
                "Gelieve te verifiëren om de e-mailverificatie te wijzigen"),
        "authToChangeLockscreenSetting": MessageLookupByLibrary.simpleMessage(
            "Graag verifiëren om de vergrendelscherm instellingen te wijzigen"),
        "authToChangeYourEmail": MessageLookupByLibrary.simpleMessage(
            "Gelieve te verifiëren om je e-mailadres te wijzigen"),
        "authToChangeYourPassword": MessageLookupByLibrary.simpleMessage(
            "Gelieve te verifiëren om je wachtwoord te wijzigen"),
        "authToConfigureTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Graag verifiëren om tweestapsverificatie te configureren"),
        "authToInitiateAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Gelieve te verifiëren om het verwijderen van je account te starten"),
        "authToViewYourActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Graag verifiëren om uw actieve sessies te bekijken"),
        "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
            "Gelieve te verifiëren om je verborgen bestanden te bekijken"),
        "authToViewYourMemories": MessageLookupByLibrary.simpleMessage(
            "Graag verifiëren om uw herinneringen te bekijken"),
        "authToViewYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Graag verifiëren om uw herstelsleutel te bekijken"),
        "authenticating": MessageLookupByLibrary.simpleMessage("Verifiëren..."),
        "authenticationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Verificatie mislukt, probeer het opnieuw"),
        "authenticationSuccessful":
            MessageLookupByLibrary.simpleMessage("Verificatie geslaagd!"),
        "available": MessageLookupByLibrary.simpleMessage("Beschikbaar"),
        "backedUpFolders":
            MessageLookupByLibrary.simpleMessage("Back-up mappen"),
        "backup": MessageLookupByLibrary.simpleMessage("Back-up"),
        "backupFailed": MessageLookupByLibrary.simpleMessage("Back-up mislukt"),
        "backupOverMobileData": MessageLookupByLibrary.simpleMessage(
            "Back-up maken via mobiele data"),
        "backupSettings":
            MessageLookupByLibrary.simpleMessage("Back-up instellingen"),
        "backupVideos":
            MessageLookupByLibrary.simpleMessage("Back-up video\'s"),
        "blackFridaySale":
            MessageLookupByLibrary.simpleMessage("Black Friday-aanbieding"),
        "blog": MessageLookupByLibrary.simpleMessage("Blog"),
        "cachedData": MessageLookupByLibrary.simpleMessage("Cachegegevens"),
        "calculating": MessageLookupByLibrary.simpleMessage("Berekenen..."),
        "canNotUploadToAlbumsOwnedByOthers":
            MessageLookupByLibrary.simpleMessage(
                "Kan niet uploaden naar albums die van anderen zijn"),
        "canOnlyCreateLinkForFilesOwnedByYou":
            MessageLookupByLibrary.simpleMessage(
                "Kan alleen een link maken voor bestanden die van u zijn"),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "Kan alleen bestanden verwijderen die jouw eigendom zijn"),
        "cancel": MessageLookupByLibrary.simpleMessage("Annuleer"),
        "cancelOtherSubscription": m8,
        "cancelSubscription":
            MessageLookupByLibrary.simpleMessage("Abonnement opzeggen"),
        "cannotAddMorePhotosAfterBecomingViewer": m9,
        "cannotDeleteSharedFiles": MessageLookupByLibrary.simpleMessage(
            "Kan gedeelde bestanden niet verwijderen"),
        "castInstruction": MessageLookupByLibrary.simpleMessage(
            "Bezoek cast.ente.io op het apparaat dat u wilt koppelen.\n\nVoer de code hieronder in om het album op uw TV af te spelen."),
        "centerPoint": MessageLookupByLibrary.simpleMessage("Middelpunt"),
        "changeEmail": MessageLookupByLibrary.simpleMessage("E-mail wijzigen"),
        "changeLocationOfSelectedItems": MessageLookupByLibrary.simpleMessage(
            "Locatie van geselecteerde items wijzigen?"),
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
        "claimFreeStorage":
            MessageLookupByLibrary.simpleMessage("Claim gratis opslag"),
        "claimMore": MessageLookupByLibrary.simpleMessage("Claim meer!"),
        "claimed": MessageLookupByLibrary.simpleMessage("Geclaimd"),
        "claimedStorageSoFar": m10,
        "cleanUncategorized":
            MessageLookupByLibrary.simpleMessage("Ongecategoriseerd opschonen"),
        "clearCaches": MessageLookupByLibrary.simpleMessage("Cache legen"),
        "clearIndexes": MessageLookupByLibrary.simpleMessage("Index wissen"),
        "click": MessageLookupByLibrary.simpleMessage("• Click"),
        "clickOnTheOverflowMenu":
            MessageLookupByLibrary.simpleMessage("• Klik op het menu"),
        "close": MessageLookupByLibrary.simpleMessage("Sluiten"),
        "clubByCaptureTime":
            MessageLookupByLibrary.simpleMessage("Samenvoegen op tijd"),
        "clubByFileName":
            MessageLookupByLibrary.simpleMessage("Samenvoegen op bestandsnaam"),
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("Code toegepast"),
        "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Code gekopieerd naar klembord"),
        "codeUsedByYou":
            MessageLookupByLibrary.simpleMessage("Code gebruikt door jou"),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Maak een link waarmee mensen foto\'s in jouw gedeelde album kunnen toevoegen en bekijken zonder dat ze daarvoor een ente app of account nodig hebben. Handig voor het verzamelen van foto\'s van evenementen."),
        "collaborativeLink":
            MessageLookupByLibrary.simpleMessage("Gezamenlijke link"),
        "collaborativeLinkCreatedFor": m11,
        "collaborator": MessageLookupByLibrary.simpleMessage("Samenwerker"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Samenwerkers kunnen foto\'s en video\'s toevoegen aan het gedeelde album."),
        "collageLayout": MessageLookupByLibrary.simpleMessage("Layout"),
        "collageSaved": MessageLookupByLibrary.simpleMessage(
            "Collage opgeslagen in gallerij"),
        "collectEventPhotos": MessageLookupByLibrary.simpleMessage(
            "Foto\'s van gebeurtenissen verzamelen"),
        "collectPhotos":
            MessageLookupByLibrary.simpleMessage("Foto\'s verzamelen"),
        "color": MessageLookupByLibrary.simpleMessage("Kleur"),
        "confirm": MessageLookupByLibrary.simpleMessage("Bevestig"),
        "confirm2FADisable": MessageLookupByLibrary.simpleMessage(
            "Weet u zeker dat u tweestapsverificatie wilt uitschakelen?"),
        "confirmAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Account verwijderen bevestigen"),
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Ja, ik wil permanent mijn account inclusief alle gegevens verwijderen."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Wachtwoord bevestigen"),
        "confirmPlanChange": MessageLookupByLibrary.simpleMessage(
            "Bevestig verandering van abonnement"),
        "confirmRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Bevestig herstelsleutel"),
        "confirmYourRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Bevestig herstelsleutel"),
        "contactFamilyAdmin": m12,
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("Contacteer klantenservice"),
        "contactToManageSubscription": m13,
        "contacts": MessageLookupByLibrary.simpleMessage("Contacten"),
        "contents": MessageLookupByLibrary.simpleMessage("Inhoud"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("Doorgaan"),
        "continueOnFreeTrial": MessageLookupByLibrary.simpleMessage(
            "Doorgaan met gratis proefversie"),
        "convertToAlbum":
            MessageLookupByLibrary.simpleMessage("Omzetten naar album"),
        "copyEmailAddress":
            MessageLookupByLibrary.simpleMessage("E-mailadres kopiëren"),
        "copyLink": MessageLookupByLibrary.simpleMessage("Kopieer link"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Kopieer en plak deze code\nnaar je authenticator app"),
        "couldNotBackUpTryLater": MessageLookupByLibrary.simpleMessage(
            "We konden uw gegevens niet back-uppen.\nWe zullen het later opnieuw proberen."),
        "couldNotFreeUpSpace":
            MessageLookupByLibrary.simpleMessage("Kon geen ruimte vrijmaken"),
        "couldNotUpdateSubscription": MessageLookupByLibrary.simpleMessage(
            "Kon abonnement niet wijzigen"),
        "count": MessageLookupByLibrary.simpleMessage("Aantal"),
        "crashReporting":
            MessageLookupByLibrary.simpleMessage("Crash rapportering"),
        "create": MessageLookupByLibrary.simpleMessage("Creëren"),
        "createAccount":
            MessageLookupByLibrary.simpleMessage("Account aanmaken"),
        "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
            "Lang indrukken om foto\'s te selecteren en klik + om een album te maken"),
        "createCollaborativeLink":
            MessageLookupByLibrary.simpleMessage("Create collaborative link"),
        "createCollage": MessageLookupByLibrary.simpleMessage("Creëer collage"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("Nieuw account aanmaken"),
        "createOrSelectAlbum":
            MessageLookupByLibrary.simpleMessage("Maak of selecteer album"),
        "createPublicLink":
            MessageLookupByLibrary.simpleMessage("Maak publieke link"),
        "creatingLink":
            MessageLookupByLibrary.simpleMessage("Link aanmaken..."),
        "criticalUpdateAvailable": MessageLookupByLibrary.simpleMessage(
            "Belangrijke update beschikbaar"),
        "currentUsageIs":
            MessageLookupByLibrary.simpleMessage("Huidig gebruik is "),
        "custom": MessageLookupByLibrary.simpleMessage("Aangepast"),
        "darkTheme": MessageLookupByLibrary.simpleMessage("Donker"),
        "dayToday": MessageLookupByLibrary.simpleMessage("Vandaag"),
        "dayYesterday": MessageLookupByLibrary.simpleMessage("Gisteren"),
        "decrypting": MessageLookupByLibrary.simpleMessage("Ontsleutelen..."),
        "decryptingVideo":
            MessageLookupByLibrary.simpleMessage("Video ontsleutelen..."),
        "deduplicateFiles": MessageLookupByLibrary.simpleMessage(
            "Dubbele bestanden verwijderen"),
        "delete": MessageLookupByLibrary.simpleMessage("Verwijderen"),
        "deleteAccount":
            MessageLookupByLibrary.simpleMessage("Account verwijderen"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "We vinden het jammer je te zien gaan. Deel je feedback om ons te helpen verbeteren."),
        "deleteAccountPermanentlyButton": MessageLookupByLibrary.simpleMessage(
            "Account permanent verwijderen"),
        "deleteAlbum": MessageLookupByLibrary.simpleMessage("Verwijder album"),
        "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
            "Verwijder de foto\'s (en video\'s) van dit album ook uit <bold>alle</bold> andere albums waar deze deel van uitmaken?"),
        "deleteAlbumsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Hiermee worden alle lege albums verwijderd. Dit is handig wanneer je rommel in je albumlijst wilt verminderen."),
        "deleteAll": MessageLookupByLibrary.simpleMessage("Alles Verwijderen"),
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
            "Dit account is gekoppeld aan andere ente apps, als je er gebruik van maakt.\\n\\nJe geüploade gegevens worden in alle ente apps gepland voor verwijdering, en je account wordt permanent verwijderd voor alle ente diensten."),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "Stuur een e-mail naar <warning>account-deletion@ente.io</warning> vanaf het door jou geregistreerde e-mailadres."),
        "deleteEmptyAlbums":
            MessageLookupByLibrary.simpleMessage("Lege albums verwijderen"),
        "deleteEmptyAlbumsWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Lege albums verwijderen?"),
        "deleteFromBoth":
            MessageLookupByLibrary.simpleMessage("Verwijder van beide"),
        "deleteFromDevice":
            MessageLookupByLibrary.simpleMessage("Verwijder van apparaat"),
        "deleteFromEnte":
            MessageLookupByLibrary.simpleMessage("Verwijder van ente"),
        "deleteItemCount": m14,
        "deleteLocation":
            MessageLookupByLibrary.simpleMessage("Verwijder locatie"),
        "deletePhotos":
            MessageLookupByLibrary.simpleMessage("Foto\'s verwijderen"),
        "deleteProgress": m15,
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "Ik mis een belangrijke functie"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "De app of een bepaalde functie functioneert niet zoals ik verwacht"),
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
        "descriptions": MessageLookupByLibrary.simpleMessage("Descriptions"),
        "deselectAll":
            MessageLookupByLibrary.simpleMessage("Alles deselecteren"),
        "designedToOutlive": MessageLookupByLibrary.simpleMessage(
            "Ontworpen om levenslang mee te gaan"),
        "details": MessageLookupByLibrary.simpleMessage("Details"),
        "devAccountChanged": MessageLookupByLibrary.simpleMessage(
            "Het ontwikkelaarsaccount dat we gebruiken om te publiceren in de App Store is veranderd. Daarom moet je opnieuw inloggen.\n\nOnze excuses voor het ongemak, helaas was dit onvermijdelijk."),
        "deviceCodeHint":
            MessageLookupByLibrary.simpleMessage("Voer de code in"),
        "deviceFilesAutoUploading": MessageLookupByLibrary.simpleMessage(
            "Bestanden toegevoegd aan dit album van dit apparaat zullen automatisch geüpload worden naar ente."),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
            "Schakel de schermvergrendeling van het apparaat uit wanneer ente op de voorgrond is en er een back-up aan de gang is. Dit is normaal gesproken niet nodig, maar kan grote uploads en initiële imports van grote mappen sneller laten verlopen."),
        "deviceNotFound":
            MessageLookupByLibrary.simpleMessage("Apparaat niet gevonden"),
        "didYouKnow": MessageLookupByLibrary.simpleMessage("Wist u dat?"),
        "disableAutoLock": MessageLookupByLibrary.simpleMessage(
            "Automatisch vergrendelen uitschakelen"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Kijkers kunnen nog steeds screenshots maken of een kopie van je foto\'s opslaan met behulp van externe tools"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Let op"),
        "disableLinkMessage": m16,
        "disableTwofactor": MessageLookupByLibrary.simpleMessage(
            "Tweestapsverificatie uitschakelen"),
        "disablingTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Tweestapsverificatie uitschakelen..."),
        "discord": MessageLookupByLibrary.simpleMessage("Discord"),
        "dismiss": MessageLookupByLibrary.simpleMessage("Afwijzen"),
        "distanceInKMUnit": MessageLookupByLibrary.simpleMessage("km"),
        "doNotSignOut": MessageLookupByLibrary.simpleMessage("Niet uitloggen"),
        "doThisLater": MessageLookupByLibrary.simpleMessage("Doe dit later"),
        "doYouWantToDiscardTheEditsYouHaveMade":
            MessageLookupByLibrary.simpleMessage(
                "Wilt u de bewerkingen die u hebt gemaakt annuleren?"),
        "done": MessageLookupByLibrary.simpleMessage("Voltooid"),
        "doubleYourStorage":
            MessageLookupByLibrary.simpleMessage("Verdubbel uw opslagruimte"),
        "download": MessageLookupByLibrary.simpleMessage("Downloaden"),
        "downloadFailed":
            MessageLookupByLibrary.simpleMessage("Download mislukt"),
        "downloading": MessageLookupByLibrary.simpleMessage("Downloaden..."),
        "dropSupportEmail": m17,
        "duplicateFileCountWithStorageSaved": m18,
        "duplicateItemsGroup": m19,
        "edit": MessageLookupByLibrary.simpleMessage("Bewerken"),
        "editLocation":
            MessageLookupByLibrary.simpleMessage("Locatie bewerken"),
        "editLocationTagTitle":
            MessageLookupByLibrary.simpleMessage("Locatie bewerken"),
        "editsSaved":
            MessageLookupByLibrary.simpleMessage("Bewerkingen opgeslagen"),
        "editsToLocationWillOnlyBeSeenWithinEnte":
            MessageLookupByLibrary.simpleMessage(
                "Bewerkte locatie wordt alleen gezien binnen Ente"),
        "eligible": MessageLookupByLibrary.simpleMessage("gerechtigd"),
        "email": MessageLookupByLibrary.simpleMessage("E-mail"),
        "emailChangedTo": m20,
        "emailNoEnteAccount": m21,
        "emailVerificationToggle":
            MessageLookupByLibrary.simpleMessage("E-mailverificatie"),
        "emailYourLogs":
            MessageLookupByLibrary.simpleMessage("E-mail uw logboeken"),
        "empty": MessageLookupByLibrary.simpleMessage("Leeg"),
        "emptyTrash":
            MessageLookupByLibrary.simpleMessage("Prullenbak leegmaken?"),
        "enableMaps":
            MessageLookupByLibrary.simpleMessage("Kaarten inschakelen"),
        "enableMapsDesc": MessageLookupByLibrary.simpleMessage(
            "Dit toont jouw foto\'s op een wereldkaart.\n\nDeze kaart wordt gehost door Open Street Map, en de exacte locaties van jouw foto\'s worden nooit gedeeld.\n\nJe kunt deze functie op elk gewenst moment uitschakelen via de instellingen."),
        "encryptingBackup":
            MessageLookupByLibrary.simpleMessage("Back-up versleutelen..."),
        "encryption": MessageLookupByLibrary.simpleMessage("Encryptie"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Encryptiesleutels"),
        "endtoendEncryptedByDefault": MessageLookupByLibrary.simpleMessage(
            "Standaard end-to-end versleuteld"),
        "enteCanEncryptAndPreserveFilesOnlyIfYouGrant":
            MessageLookupByLibrary.simpleMessage(
                "ente kan bestanden alleen versleutelen en bewaren als u toegang tot ze geeft"),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
            "ente <i>heeft toestemming nodig om</i> je foto\'s te bewaren"),
        "enteSubscriptionPitch": MessageLookupByLibrary.simpleMessage(
            "ente bewaart uw herinneringen, zodat ze altijd beschikbaar voor u zijn, zelfs als u uw apparaat verliest."),
        "enteSubscriptionShareWithFamily": MessageLookupByLibrary.simpleMessage(
            "Je familie kan ook aan je abonnement worden toegevoegd."),
        "enterAlbumName":
            MessageLookupByLibrary.simpleMessage("Voer albumnaam in"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Voer code in"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
            "Voer de code van de vriend in om gratis opslag voor jullie beiden te claimen"),
        "enterEmail":
            MessageLookupByLibrary.simpleMessage("Voer e-mailadres in"),
        "enterFileName":
            MessageLookupByLibrary.simpleMessage("Geef bestandsnaam op"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Voer een nieuw wachtwoord in dat we kunnen gebruiken om je gegevens te versleutelen"),
        "enterPassword":
            MessageLookupByLibrary.simpleMessage("Voer wachtwoord in"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Voer een wachtwoord in dat we kunnen gebruiken om je gegevens te versleutelen"),
        "enterReferralCode":
            MessageLookupByLibrary.simpleMessage("Voer verwijzingscode in"),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Voer de 6-cijferige code van je verificatie-app in"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "Voer een geldig e-mailadres in."),
        "enterYourEmailAddress":
            MessageLookupByLibrary.simpleMessage("Voer uw e-mailadres in"),
        "enterYourPassword":
            MessageLookupByLibrary.simpleMessage("Voer je wachtwoord in"),
        "enterYourRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Voer je herstelcode in"),
        "error": MessageLookupByLibrary.simpleMessage("Foutmelding"),
        "everywhere": MessageLookupByLibrary.simpleMessage("overal"),
        "exif": MessageLookupByLibrary.simpleMessage("EXIF"),
        "existingUser":
            MessageLookupByLibrary.simpleMessage("Bestaande gebruiker"),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
            "Deze link is verlopen. Selecteer een nieuwe vervaltijd of schakel de vervaldatum uit."),
        "exportLogs":
            MessageLookupByLibrary.simpleMessage("Logboek exporteren"),
        "exportYourData":
            MessageLookupByLibrary.simpleMessage("Exporteer je gegevens"),
        "faces": MessageLookupByLibrary.simpleMessage("Gezichten"),
        "failedToApplyCode":
            MessageLookupByLibrary.simpleMessage("Code toepassen mislukt"),
        "failedToCancel":
            MessageLookupByLibrary.simpleMessage("Opzeggen mislukt"),
        "failedToDownloadVideo": MessageLookupByLibrary.simpleMessage(
            "Downloaden van video mislukt"),
        "failedToFetchOriginalForEdit": MessageLookupByLibrary.simpleMessage(
            "Fout bij ophalen origineel voor bewerking"),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "Kan geen verwijzingsgegevens ophalen. Probeer het later nog eens."),
        "failedToLoadAlbums":
            MessageLookupByLibrary.simpleMessage("Laden van albums mislukt"),
        "failedToRenew":
            MessageLookupByLibrary.simpleMessage("Verlengen mislukt"),
        "failedToVerifyPaymentStatus": MessageLookupByLibrary.simpleMessage(
            "Betalingsstatus verifiëren mislukt"),
        "familyPlanOverview": MessageLookupByLibrary.simpleMessage(
            "Voeg 5 gezinsleden toe aan uw bestaande abonnement zonder extra te betalen.\n\nElk lid krijgt zijn eigen privé ruimte en kan elkaars bestanden niet zien, tenzij ze zijn gedeeld.\n\nFamilieplannen zijn beschikbaar voor klanten die een betaald ente abonnement hebben.\n\nAbonneer u nu om aan de slag te gaan!"),
        "familyPlanPortalTitle":
            MessageLookupByLibrary.simpleMessage("Familie"),
        "familyPlans":
            MessageLookupByLibrary.simpleMessage("Familie abonnement"),
        "faq": MessageLookupByLibrary.simpleMessage("Veelgestelde vragen"),
        "faqs": MessageLookupByLibrary.simpleMessage("Veelgestelde vragen"),
        "favorite":
            MessageLookupByLibrary.simpleMessage("Toevoegen aan favorieten"),
        "feedback": MessageLookupByLibrary.simpleMessage("Feedback"),
        "fileFailedToSaveToGallery": MessageLookupByLibrary.simpleMessage(
            "Opslaan van bestand naar galerij mislukt"),
        "fileInfoAddDescHint": MessageLookupByLibrary.simpleMessage(
            "Voeg een beschrijving toe..."),
        "fileSavedToGallery": MessageLookupByLibrary.simpleMessage(
            "Bestand opgeslagen in galerij"),
        "fileTypes": MessageLookupByLibrary.simpleMessage("Bestandstype"),
        "fileTypesAndNames":
            MessageLookupByLibrary.simpleMessage("Bestandstypen en namen"),
        "filesBackedUpFromDevice": m22,
        "filesBackedUpInAlbum": m23,
        "filesDeleted":
            MessageLookupByLibrary.simpleMessage("Bestanden verwijderd"),
        "flip": MessageLookupByLibrary.simpleMessage("Omdraaien"),
        "forYourMemories":
            MessageLookupByLibrary.simpleMessage("voor uw herinneringen"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Wachtwoord vergeten"),
        "freeStorageClaimed":
            MessageLookupByLibrary.simpleMessage("Gratis opslag geclaimd"),
        "freeStorageOnReferralSuccess": m24,
        "freeStorageSpace": m25,
        "freeStorageUsable":
            MessageLookupByLibrary.simpleMessage("Gratis opslag bruikbaar"),
        "freeTrial": MessageLookupByLibrary.simpleMessage("Gratis proefversie"),
        "freeTrialValidTill": m26,
        "freeUpAccessPostDelete": m27,
        "freeUpAmount": m28,
        "freeUpDeviceSpace":
            MessageLookupByLibrary.simpleMessage("Apparaatruimte vrijmaken"),
        "freeUpSpace": MessageLookupByLibrary.simpleMessage("Ruimte vrijmaken"),
        "freeUpSpaceSaving": m29,
        "galleryMemoryLimitInfo": MessageLookupByLibrary.simpleMessage(
            "Tot 1000 herinneringen getoond in de galerij"),
        "general": MessageLookupByLibrary.simpleMessage("Algemeen"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Encryptiesleutels genereren..."),
        "genericProgress": m30,
        "goToSettings":
            MessageLookupByLibrary.simpleMessage("Ga naar instellingen"),
        "googlePlayId": MessageLookupByLibrary.simpleMessage("Google Play ID"),
        "grantFullAccessPrompt": MessageLookupByLibrary.simpleMessage(
            "Geef toegang tot alle foto\'s in de Instellingen app"),
        "grantPermission":
            MessageLookupByLibrary.simpleMessage("Toestemming verlenen"),
        "groupNearbyPhotos":
            MessageLookupByLibrary.simpleMessage("Groep foto\'s in de buurt"),
        "hearUsExplanation": MessageLookupByLibrary.simpleMessage(
            "Wij gebruiken geen tracking. Het zou helpen als je ons vertelt waar je ons gevonden hebt!"),
        "hearUsWhereTitle": MessageLookupByLibrary.simpleMessage(
            "Hoe hoorde je over Ente? (optioneel)"),
        "hidden": MessageLookupByLibrary.simpleMessage("Verborgen"),
        "hide": MessageLookupByLibrary.simpleMessage("Verbergen"),
        "hiding": MessageLookupByLibrary.simpleMessage("Verbergen..."),
        "hostedAtOsmFrance":
            MessageLookupByLibrary.simpleMessage("Gehost bij OSM France"),
        "howItWorks": MessageLookupByLibrary.simpleMessage("Hoe het werkt"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "Vraag hen om hun e-mailadres lang in te drukken op het instellingenscherm en te controleren dat de ID\'s op beide apparaten overeenkomen."),
        "iOSGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "Biometrische authenticatie is niet ingesteld op uw apparaat. Schakel Touch ID of Face ID in op uw telefoon."),
        "iOSLockOut": MessageLookupByLibrary.simpleMessage(
            "Biometrische verificatie is uitgeschakeld. Vergrendel en ontgrendel uw scherm om het in te schakelen."),
        "iOSOkButton": MessageLookupByLibrary.simpleMessage("Oké"),
        "ignoreUpdate": MessageLookupByLibrary.simpleMessage("Negeren"),
        "ignoredFolderUploadReason": MessageLookupByLibrary.simpleMessage(
            "Sommige bestanden in dit album worden genegeerd voor de upload omdat ze eerder van ente zijn verwijderd."),
        "importing": MessageLookupByLibrary.simpleMessage("Importeren...."),
        "incorrectCode": MessageLookupByLibrary.simpleMessage("Onjuiste code"),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Onjuist wachtwoord"),
        "incorrectRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Onjuiste herstelsleutel"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "De ingevoerde herstelsleutel is onjuist"),
        "incorrectRecoveryKeyTitle":
            MessageLookupByLibrary.simpleMessage("Onjuiste herstelsleutel"),
        "indexedItems":
            MessageLookupByLibrary.simpleMessage("Geïndexeerde bestanden"),
        "insecureDevice":
            MessageLookupByLibrary.simpleMessage("Onveilig apparaat"),
        "installManually":
            MessageLookupByLibrary.simpleMessage("Installeer handmatig"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("Ongeldig e-mailadres"),
        "invalidKey": MessageLookupByLibrary.simpleMessage("Ongeldige sleutel"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "De herstelsleutel die je hebt ingevoerd is niet geldig. Zorg ervoor dat deze 24 woorden bevat en controleer de spelling van elk van deze woorden.\n\nAls je een oudere herstelcode hebt ingevoerd, zorg ervoor dat deze 64 tekens lang is, en controleer ze allemaal."),
        "invite": MessageLookupByLibrary.simpleMessage("Uitnodigen"),
        "inviteToEnte":
            MessageLookupByLibrary.simpleMessage("Uitnodigen voor ente"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Vrienden uitnodigen"),
        "inviteYourFriendsToEnte": MessageLookupByLibrary.simpleMessage(
            "Vrienden uitnodigen voor ente"),
        "itLooksLikeSomethingWentWrongPleaseRetryAfterSome":
            MessageLookupByLibrary.simpleMessage(
                "Het lijkt erop dat er iets fout is gegaan. Probeer het later opnieuw. Als de fout zich blijft voordoen, neem dan contact op met ons supportteam."),
        "itemCount": m31,
        "itemsShowTheNumberOfDaysRemainingBeforePermanentDeletion":
            MessageLookupByLibrary.simpleMessage(
                "Bestanden tonen het aantal resterende dagen voordat ze permanent worden verwijderd"),
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "Geselecteerde items zullen worden verwijderd uit dit album"),
        "joinDiscord": MessageLookupByLibrary.simpleMessage("Join Discord"),
        "keepPhotos": MessageLookupByLibrary.simpleMessage("Foto\'s behouden"),
        "kiloMeterUnit": MessageLookupByLibrary.simpleMessage("km"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Help ons alsjeblieft met deze informatie"),
        "language": MessageLookupByLibrary.simpleMessage("Taal"),
        "lastUpdated": MessageLookupByLibrary.simpleMessage("Laatst gewijzigd"),
        "leave": MessageLookupByLibrary.simpleMessage("Verlaten"),
        "leaveAlbum": MessageLookupByLibrary.simpleMessage("Album verlaten"),
        "leaveFamily":
            MessageLookupByLibrary.simpleMessage("Familie abonnement verlaten"),
        "leaveSharedAlbum":
            MessageLookupByLibrary.simpleMessage("Gedeeld album verlaten?"),
        "light": MessageLookupByLibrary.simpleMessage("Licht"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("Licht"),
        "linkCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Link gekopieerd naar klembord"),
        "linkDeviceLimit":
            MessageLookupByLibrary.simpleMessage("Apparaat limiet"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Ingeschakeld"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Verlopen"),
        "linkExpiresOn": m32,
        "linkExpiry": MessageLookupByLibrary.simpleMessage("Vervaldatum"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("Link is vervallen"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Nooit"),
        "livePhotos": MessageLookupByLibrary.simpleMessage("Live foto"),
        "loadMessage1": MessageLookupByLibrary.simpleMessage(
            "U kunt uw abonnement met uw familie delen"),
        "loadMessage2": MessageLookupByLibrary.simpleMessage(
            "We hebben tot nu toe meer dan tien miljoen herinneringen bewaard"),
        "loadMessage3": MessageLookupByLibrary.simpleMessage(
            "We bewaren 3 kopieën van uw bestanden, één in een ondergrondse kernbunker"),
        "loadMessage4": MessageLookupByLibrary.simpleMessage(
            "Al onze apps zijn open source"),
        "loadMessage5": MessageLookupByLibrary.simpleMessage(
            "Onze broncode en cryptografie zijn extern gecontroleerd en geverifieerd"),
        "loadMessage6": MessageLookupByLibrary.simpleMessage(
            "Je kunt links naar je albums delen met je dierbaren"),
        "loadMessage7": MessageLookupByLibrary.simpleMessage(
            "Onze mobiele apps draaien op de achtergrond om alle nieuwe foto\'s die je maakt te versleutelen en te back-uppen"),
        "loadMessage8": MessageLookupByLibrary.simpleMessage(
            "web.ente.io heeft een vlotte uploader"),
        "loadMessage9": MessageLookupByLibrary.simpleMessage(
            "We gebruiken Xchacha20Poly1305 om uw gegevens veilig te versleutelen"),
        "loadingExifData":
            MessageLookupByLibrary.simpleMessage("EXIF-gegevens laden..."),
        "loadingGallery":
            MessageLookupByLibrary.simpleMessage("Laden van gallerij..."),
        "loadingMessage":
            MessageLookupByLibrary.simpleMessage("Uw foto\'s laden..."),
        "loadingModel":
            MessageLookupByLibrary.simpleMessage("Modellen downloaden..."),
        "localGallery": MessageLookupByLibrary.simpleMessage("Lokale galerij"),
        "location": MessageLookupByLibrary.simpleMessage("Locatie"),
        "locationName": MessageLookupByLibrary.simpleMessage("Locatie naam"),
        "locationTagFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "Een locatie tag groept alle foto\'s die binnen een bepaalde straal van een foto zijn genomen"),
        "locations": MessageLookupByLibrary.simpleMessage("Locations"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Vergrendel"),
        "lockScreenEnablePreSteps": MessageLookupByLibrary.simpleMessage(
            "Om vergrendelscherm in te schakelen, moet u een toegangscode of schermvergrendeling instellen in uw systeeminstellingen."),
        "lockscreen": MessageLookupByLibrary.simpleMessage("Vergrendelscherm"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Inloggen"),
        "loggingOut": MessageLookupByLibrary.simpleMessage("Uitloggen..."),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "Door op inloggen te klikken, ga ik akkoord met de <u-terms>gebruiksvoorwaarden</u-terms> en <u-policy>privacybeleid</u-policy>"),
        "logout": MessageLookupByLibrary.simpleMessage("Uitloggen"),
        "logsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Dit zal logboeken verzenden om ons te helpen uw probleem op te lossen. Houd er rekening mee dat bestandsnamen zullen worden meegenomen om problemen met specifieke bestanden bij te houden."),
        "longPressAnEmailToVerifyEndToEndEncryption":
            MessageLookupByLibrary.simpleMessage(
                "Long press an email to verify end to end encryption."),
        "longpressOnAnItemToViewInFullscreen": MessageLookupByLibrary.simpleMessage(
            "Houd een bestand lang ingedrukt om te bekijken op volledig scherm"),
        "lostDevice":
            MessageLookupByLibrary.simpleMessage("Apparaat verloren?"),
        "machineLearning":
            MessageLookupByLibrary.simpleMessage("Machine Learning"),
        "magicSearch":
            MessageLookupByLibrary.simpleMessage("Magische zoekfunctie"),
        "magicSearchDescription": MessageLookupByLibrary.simpleMessage(
            "Houd er rekening mee dat dit zal resulteren in een hoger internet- en batterijverbruik totdat alle items zijn geïndexeerd."),
        "manage": MessageLookupByLibrary.simpleMessage("Beheren"),
        "manageDeviceStorage":
            MessageLookupByLibrary.simpleMessage("Apparaatopslag beheren"),
        "manageFamily":
            MessageLookupByLibrary.simpleMessage("Familie abonnement beheren"),
        "manageLink": MessageLookupByLibrary.simpleMessage("Beheer link"),
        "manageParticipants": MessageLookupByLibrary.simpleMessage("Beheren"),
        "manageSubscription":
            MessageLookupByLibrary.simpleMessage("Abonnement beheren"),
        "map": MessageLookupByLibrary.simpleMessage("Kaart"),
        "maps": MessageLookupByLibrary.simpleMessage("Kaarten"),
        "mastodon": MessageLookupByLibrary.simpleMessage("Mastodon"),
        "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
        "memoryCount": m33,
        "merchandise": MessageLookupByLibrary.simpleMessage("Merchandise"),
        "mobileWebDesktop":
            MessageLookupByLibrary.simpleMessage("Mobiel, Web, Desktop"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Matig"),
        "modifyYourQueryOrTrySearchingFor":
            MessageLookupByLibrary.simpleMessage(
                "Pas je zoekopdracht aan of zoek naar"),
        "moments": MessageLookupByLibrary.simpleMessage("Momenten"),
        "monthly": MessageLookupByLibrary.simpleMessage("Maandelijks"),
        "moveItem": m34,
        "moveToAlbum":
            MessageLookupByLibrary.simpleMessage("Verplaats naar album"),
        "moveToHiddenAlbum": MessageLookupByLibrary.simpleMessage(
            "Verplaatsen naar verborgen album"),
        "movedSuccessfullyTo": m35,
        "movedToTrash":
            MessageLookupByLibrary.simpleMessage("Naar prullenbak verplaatst"),
        "movingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Bestanden verplaatsen naar album..."),
        "name": MessageLookupByLibrary.simpleMessage("Naam"),
        "networkConnectionRefusedErr": MessageLookupByLibrary.simpleMessage(
            "Kan geen verbinding maken met Ente, probeer het later opnieuw. Als de fout zich blijft voordoen, neem dan contact op met support."),
        "networkHostLookUpErr": MessageLookupByLibrary.simpleMessage(
            "Kan geen verbinding maken met Ente, controleer uw netwerkinstellingen en neem contact op met ondersteuning als de fout zich blijft voordoen."),
        "never": MessageLookupByLibrary.simpleMessage("Nooit"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Nieuw album"),
        "newToEnte": MessageLookupByLibrary.simpleMessage("Nieuw bij ente"),
        "newest": MessageLookupByLibrary.simpleMessage("Nieuwste"),
        "no": MessageLookupByLibrary.simpleMessage("Nee"),
        "noAlbumsSharedByYouYet": MessageLookupByLibrary.simpleMessage(
            "Nog geen albums gedeeld door jou"),
        "noDeviceLimit": MessageLookupByLibrary.simpleMessage("Geen"),
        "noDeviceThatCanBeDeleted": MessageLookupByLibrary.simpleMessage(
            "Je hebt geen bestanden op dit apparaat die verwijderd kunnen worden"),
        "noDuplicates":
            MessageLookupByLibrary.simpleMessage("✨ Geen duplicaten"),
        "noExifData":
            MessageLookupByLibrary.simpleMessage("Geen EXIF gegevens"),
        "noHiddenPhotosOrVideos": MessageLookupByLibrary.simpleMessage(
            "Geen verborgen foto\'s of video\'s"),
        "noImagesWithLocation": MessageLookupByLibrary.simpleMessage(
            "Geen afbeeldingen met locatie"),
        "noInternetConnection":
            MessageLookupByLibrary.simpleMessage("Geen internetverbinding"),
        "noPhotosAreBeingBackedUpRightNow":
            MessageLookupByLibrary.simpleMessage(
                "Er worden momenteel geen foto\'s geback-upt"),
        "noPhotosFoundHere":
            MessageLookupByLibrary.simpleMessage("Geen foto\'s gevonden hier"),
        "noRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Geen herstelcode?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "Door de aard van ons end-to-end encryptieprotocol kunnen je gegevens niet worden ontsleuteld zonder je wachtwoord of herstelsleutel"),
        "noResults": MessageLookupByLibrary.simpleMessage("Geen resultaten"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("Geen resultaten gevonden"),
        "nothingSharedWithYouYet":
            MessageLookupByLibrary.simpleMessage("Nog niets met je gedeeld"),
        "nothingToSeeHere":
            MessageLookupByLibrary.simpleMessage("Nog niets te zien hier! 👀"),
        "notifications": MessageLookupByLibrary.simpleMessage("Meldingen"),
        "ok": MessageLookupByLibrary.simpleMessage("Oké"),
        "onDevice": MessageLookupByLibrary.simpleMessage("Op het apparaat"),
        "onEnte": MessageLookupByLibrary.simpleMessage(
            "Op <branding>ente</branding>"),
        "oops": MessageLookupByLibrary.simpleMessage("Oeps"),
        "oopsCouldNotSaveEdits": MessageLookupByLibrary.simpleMessage(
            "Oeps, kon bewerkingen niet opslaan"),
        "oopsSomethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Oeps, er is iets misgegaan"),
        "openSettings":
            MessageLookupByLibrary.simpleMessage("Instellingen openen"),
        "openTheItem": MessageLookupByLibrary.simpleMessage("• Open het item"),
        "openstreetmapContributors":
            MessageLookupByLibrary.simpleMessage("OpenStreetMap bijdragers"),
        "optionalAsShortAsYouLike": MessageLookupByLibrary.simpleMessage(
            "Optioneel, zo kort als je wilt..."),
        "orPickAnExistingOne":
            MessageLookupByLibrary.simpleMessage("Of kies een bestaande"),
        "pair": MessageLookupByLibrary.simpleMessage("Koppelen"),
        "password": MessageLookupByLibrary.simpleMessage("Wachtwoord"),
        "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
            "Wachtwoord succesvol aangepast"),
        "passwordLock": MessageLookupByLibrary.simpleMessage("Wachtwoord slot"),
        "passwordStrength": m36,
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Wij slaan dit wachtwoord niet op, dus als je het vergeet, kunnen <underline>we je gegevens niet ontsleutelen</underline>"),
        "paymentDetails":
            MessageLookupByLibrary.simpleMessage("Betaalgegevens"),
        "paymentFailed":
            MessageLookupByLibrary.simpleMessage("Betaling mislukt"),
        "paymentFailedTalkToProvider": m37,
        "pendingItems":
            MessageLookupByLibrary.simpleMessage("Bestanden in behandeling"),
        "pendingSync": MessageLookupByLibrary.simpleMessage(
            "Synchronisatie in behandeling"),
        "peopleUsingYourCode": MessageLookupByLibrary.simpleMessage(
            "Mensen die jouw code gebruiken"),
        "permDeleteWarning": MessageLookupByLibrary.simpleMessage(
            "Alle bestanden in de prullenbak zullen permanent worden verwijderd\n\nDeze actie kan niet ongedaan worden gemaakt"),
        "permanentlyDelete":
            MessageLookupByLibrary.simpleMessage("Permanent verwijderen"),
        "permanentlyDeleteFromDevice": MessageLookupByLibrary.simpleMessage(
            "Permanent verwijderen van apparaat?"),
        "photoDescriptions":
            MessageLookupByLibrary.simpleMessage("Foto beschrijvingen"),
        "photoGridSize":
            MessageLookupByLibrary.simpleMessage("Foto raster grootte"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("foto"),
        "photos": MessageLookupByLibrary.simpleMessage("Foto\'s"),
        "photosAddedByYouWillBeRemovedFromTheAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Foto\'s toegevoegd door u zullen worden verwijderd uit het album"),
        "pickCenterPoint":
            MessageLookupByLibrary.simpleMessage("Kies middelpunt"),
        "pinAlbum":
            MessageLookupByLibrary.simpleMessage("Album bovenaan vastzetten"),
        "playOnTv":
            MessageLookupByLibrary.simpleMessage("Album afspelen op TV"),
        "playStoreFreeTrialValidTill": m38,
        "playstoreSubscription":
            MessageLookupByLibrary.simpleMessage("PlayStore abonnement"),
        "pleaseCheckYourInternetConnectionAndTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Controleer je internetverbinding en probeer het opnieuw."),
        "pleaseContactSupportAndWeWillBeHappyToHelp":
            MessageLookupByLibrary.simpleMessage(
                "Neem alstublieft contact op met support@ente.io en we helpen u graag!"),
        "pleaseContactSupportIfTheProblemPersists":
            MessageLookupByLibrary.simpleMessage(
                "Neem contact op met klantenservice als het probleem aanhoudt"),
        "pleaseEmailUsAt": m39,
        "pleaseGrantPermissions": MessageLookupByLibrary.simpleMessage(
            "Geef alstublieft toestemming"),
        "pleaseLoginAgain":
            MessageLookupByLibrary.simpleMessage("Log opnieuw in"),
        "pleaseSendTheLogsTo": m40,
        "pleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("Probeer het nog eens"),
        "pleaseVerifyTheCodeYouHaveEntered":
            MessageLookupByLibrary.simpleMessage(
                "Controleer de code die u hebt ingevoerd"),
        "pleaseWait":
            MessageLookupByLibrary.simpleMessage("Een ogenblik geduld..."),
        "pleaseWaitDeletingAlbum": MessageLookupByLibrary.simpleMessage(
            "Een ogenblik geduld, album wordt verwijderd"),
        "pleaseWaitForSometimeBeforeRetrying":
            MessageLookupByLibrary.simpleMessage(
                "Gelieve even te wachten voordat u opnieuw probeert"),
        "preparingLogs":
            MessageLookupByLibrary.simpleMessage("Logboeken voorbereiden..."),
        "preserveMore": MessageLookupByLibrary.simpleMessage("Meer bewaren"),
        "pressAndHoldToPlayVideo": MessageLookupByLibrary.simpleMessage(
            "Ingedrukt houden om video af te spelen"),
        "pressAndHoldToPlayVideoDetailed": MessageLookupByLibrary.simpleMessage(
            "Houd de afbeelding ingedrukt om video af te spelen"),
        "privacy": MessageLookupByLibrary.simpleMessage("Privacy"),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Privacybeleid"),
        "privateBackups":
            MessageLookupByLibrary.simpleMessage("Privé back-ups"),
        "privateSharing": MessageLookupByLibrary.simpleMessage("Privé delen"),
        "publicLinkCreated":
            MessageLookupByLibrary.simpleMessage("Publieke link aangemaakt"),
        "publicLinkEnabled":
            MessageLookupByLibrary.simpleMessage("Publieke link ingeschakeld"),
        "quickLinks": MessageLookupByLibrary.simpleMessage("Snelle links"),
        "radius": MessageLookupByLibrary.simpleMessage("Straal"),
        "raiseTicket": MessageLookupByLibrary.simpleMessage("Meld probleem"),
        "rateTheApp": MessageLookupByLibrary.simpleMessage("Beoordeel de app"),
        "rateUs": MessageLookupByLibrary.simpleMessage("Beoordeel ons"),
        "rateUsOnStore": m41,
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
        "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
        "referFriendsAnd2xYourPlan": MessageLookupByLibrary.simpleMessage(
            "Verwijs vrienden en 2x uw abonnement"),
        "referralStep1": MessageLookupByLibrary.simpleMessage(
            "1. Geef deze code aan je vrienden"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "2. Ze registreren voor een betaald plan"),
        "referralStep3": m42,
        "referrals": MessageLookupByLibrary.simpleMessage("Referenties"),
        "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
            "Verwijzingen zijn momenteel gepauzeerd"),
        "remindToEmptyDeviceTrash": MessageLookupByLibrary.simpleMessage(
            "Leeg ook \"Onlangs verwijderd\" uit \"Instellingen\" -> \"Opslag\" om de vrij gekomen ruimte te benutten"),
        "remindToEmptyEnteTrash": MessageLookupByLibrary.simpleMessage(
            "Leeg ook uw \"Prullenbak\" om de vrij gekomen ruimte te benutten"),
        "remoteImages":
            MessageLookupByLibrary.simpleMessage("Externe afbeeldingen"),
        "remoteThumbnails":
            MessageLookupByLibrary.simpleMessage("Externe thumbnails"),
        "remoteVideos":
            MessageLookupByLibrary.simpleMessage("Externe video\'s"),
        "remove": MessageLookupByLibrary.simpleMessage("Verwijder"),
        "removeDuplicates":
            MessageLookupByLibrary.simpleMessage("Duplicaten verwijderen"),
        "removeFromAlbum":
            MessageLookupByLibrary.simpleMessage("Verwijder uit album"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("Uit album verwijderen?"),
        "removeFromFavorite":
            MessageLookupByLibrary.simpleMessage("Verwijderen uit favorieten"),
        "removeLink": MessageLookupByLibrary.simpleMessage("Verwijder link"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Deelnemer verwijderen"),
        "removeParticipantBody": m43,
        "removePublicLink":
            MessageLookupByLibrary.simpleMessage("Verwijder publieke link"),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
            "Sommige van de items die je verwijdert zijn door andere mensen toegevoegd, en je verliest de toegang daartoe"),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Verwijder?"),
        "removingFromFavorites": MessageLookupByLibrary.simpleMessage(
            "Verwijderen uit favorieten..."),
        "rename": MessageLookupByLibrary.simpleMessage("Naam wijzigen"),
        "renameAlbum":
            MessageLookupByLibrary.simpleMessage("Albumnaam wijzigen"),
        "renameFile":
            MessageLookupByLibrary.simpleMessage("Bestandsnaam wijzigen"),
        "renewSubscription":
            MessageLookupByLibrary.simpleMessage("Abonnement verlengen"),
        "renewsOn": m44,
        "reportABug": MessageLookupByLibrary.simpleMessage("Een fout melden"),
        "reportBug": MessageLookupByLibrary.simpleMessage("Fout melden"),
        "resendEmail":
            MessageLookupByLibrary.simpleMessage("E-mail opnieuw versturen"),
        "resetIgnoredFiles":
            MessageLookupByLibrary.simpleMessage("Reset genegeerde bestanden"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Wachtwoord resetten"),
        "resetToDefault": MessageLookupByLibrary.simpleMessage(
            "Standaardinstellingen herstellen"),
        "restore": MessageLookupByLibrary.simpleMessage("Herstellen"),
        "restoreToAlbum":
            MessageLookupByLibrary.simpleMessage("Terugzetten naar album"),
        "restoringFiles":
            MessageLookupByLibrary.simpleMessage("Bestanden herstellen..."),
        "retry": MessageLookupByLibrary.simpleMessage("Opnieuw"),
        "reviewDeduplicateItems": MessageLookupByLibrary.simpleMessage(
            "Controleer en verwijder de bestanden die u denkt dat dubbel zijn."),
        "rotateLeft": MessageLookupByLibrary.simpleMessage("Roteer links"),
        "rotateRight": MessageLookupByLibrary.simpleMessage("Rechtsom draaien"),
        "safelyStored":
            MessageLookupByLibrary.simpleMessage("Veilig opgeslagen"),
        "save": MessageLookupByLibrary.simpleMessage("Opslaan"),
        "saveCollage": MessageLookupByLibrary.simpleMessage("Sla collage op"),
        "saveCopy": MessageLookupByLibrary.simpleMessage("Kopie opslaan"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Bewaar sleutel"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Sla je herstelsleutel op als je dat nog niet gedaan hebt"),
        "saving": MessageLookupByLibrary.simpleMessage("Opslaan..."),
        "scanCode": MessageLookupByLibrary.simpleMessage("Scan code"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Scan deze barcode met\nje authenticator app"),
        "searchAlbumsEmptySection":
            MessageLookupByLibrary.simpleMessage("Albums"),
        "searchByAlbumNameHint":
            MessageLookupByLibrary.simpleMessage("Albumnaam"),
        "searchByExamples": MessageLookupByLibrary.simpleMessage(
            "• Albumnamen (bijv. \"Camera\")\n• Types van bestanden (bijv. \"Video\'s\", \".gif\")\n• Jaren en maanden (bijv. \"2022\", \"januari\")\n• Feestdagen (bijv. \"Kerstmis\")\n• Fotobeschrijvingen (bijv. \"#fun\")"),
        "searchCaptionEmptySection": MessageLookupByLibrary.simpleMessage(
            "Voeg beschrijvingen zoals \"#weekendje weg\" toe in foto-info om ze snel hier te vinden"),
        "searchDatesEmptySection": MessageLookupByLibrary.simpleMessage(
            "Zoeken op een datum, maand of jaar"),
        "searchFaceEmptySection": MessageLookupByLibrary.simpleMessage(
            "Vind alle foto\'s van een persoon"),
        "searchFileTypesAndNamesEmptySection":
            MessageLookupByLibrary.simpleMessage("Bestandstypen en namen"),
        "searchHint1":
            MessageLookupByLibrary.simpleMessage("Snelle, lokale zoekfunctie"),
        "searchHint2":
            MessageLookupByLibrary.simpleMessage("Foto datums, beschrijvingen"),
        "searchHint3": MessageLookupByLibrary.simpleMessage(
            "Albums, bestandsnamen en typen"),
        "searchHint4": MessageLookupByLibrary.simpleMessage("Locatie"),
        "searchHint5": MessageLookupByLibrary.simpleMessage(
            "Binnenkort beschikbaar: Gezichten & magische zoekopdrachten ✨"),
        "searchLocationEmptySection": MessageLookupByLibrary.simpleMessage(
            "Foto\'s groeperen die in een bepaalde straal van een foto worden genomen"),
        "searchPeopleEmptySection": MessageLookupByLibrary.simpleMessage(
            "Nodig mensen uit, en je ziet alle foto\'s die door hen worden gedeeld hier"),
        "searchResultCount": m45,
        "security": MessageLookupByLibrary.simpleMessage("Beveiliging"),
        "selectALocation":
            MessageLookupByLibrary.simpleMessage("Selecteer een locatie"),
        "selectALocationFirst":
            MessageLookupByLibrary.simpleMessage("Selecteer eerst een locatie"),
        "selectAlbum": MessageLookupByLibrary.simpleMessage("Album selecteren"),
        "selectAll": MessageLookupByLibrary.simpleMessage("Selecteer alles"),
        "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
            "Selecteer mappen voor back-up"),
        "selectItemsToAdd": MessageLookupByLibrary.simpleMessage(
            "Selecteer items om toe te voegen"),
        "selectLanguage":
            MessageLookupByLibrary.simpleMessage("Taal selecteren"),
        "selectMorePhotos":
            MessageLookupByLibrary.simpleMessage("Selecteer meer foto\'s"),
        "selectReason": MessageLookupByLibrary.simpleMessage("Selecteer reden"),
        "selectYourPlan":
            MessageLookupByLibrary.simpleMessage("Kies uw abonnement"),
        "selectedFilesAreNotOnEnte": MessageLookupByLibrary.simpleMessage(
            "Geselecteerde bestanden staan niet op ente"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "Geselecteerde mappen worden versleuteld en geback-upt"),
        "selectedItemsWillBeDeletedFromAllAlbumsAndMoved":
            MessageLookupByLibrary.simpleMessage(
                "Geselecteerde bestanden worden verwijderd uit alle albums en verplaatst naar de prullenbak."),
        "selectedPhotos": m46,
        "selectedPhotosWithYours": m47,
        "send": MessageLookupByLibrary.simpleMessage("Verzenden"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("E-mail versturen"),
        "sendInvite":
            MessageLookupByLibrary.simpleMessage("Stuur een uitnodiging"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Stuur link"),
        "sessionExpired":
            MessageLookupByLibrary.simpleMessage("Sessie verlopen"),
        "setAPassword":
            MessageLookupByLibrary.simpleMessage("Stel een wachtwoord in"),
        "setAs": MessageLookupByLibrary.simpleMessage("Instellen als"),
        "setCover": MessageLookupByLibrary.simpleMessage("Omslag instellen"),
        "setLabel": MessageLookupByLibrary.simpleMessage("Instellen"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Wachtwoord instellen"),
        "setRadius": MessageLookupByLibrary.simpleMessage("Radius instellen"),
        "setupComplete": MessageLookupByLibrary.simpleMessage("Setup voltooid"),
        "share": MessageLookupByLibrary.simpleMessage("Delen"),
        "shareALink": MessageLookupByLibrary.simpleMessage("Deel een link"),
        "shareAlbumHint": MessageLookupByLibrary.simpleMessage(
            "Open een album en tik op de deelknop rechts bovenaan om te delen."),
        "shareAnAlbumNow":
            MessageLookupByLibrary.simpleMessage("Deel nu een album"),
        "shareLink": MessageLookupByLibrary.simpleMessage("Link delen"),
        "shareMyVerificationID": m48,
        "shareOnlyWithThePeopleYouWant": MessageLookupByLibrary.simpleMessage(
            "Deel alleen met de mensen die u wilt"),
        "shareTextConfirmOthersVerificationID": m49,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Download ente zodat we gemakkelijk foto\'s en video\'s van originele kwaliteit kunnen delen\n\nhttps://ente.io"),
        "shareTextReferralCode": m50,
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
            "Delen met niet-ente gebruikers"),
        "shareWithPeopleSectionTitle": m51,
        "shareYourFirstAlbum":
            MessageLookupByLibrary.simpleMessage("Deel jouw eerste album"),
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Maak gedeelde en collaboratieve albums met andere ente gebruikers, inclusief gebruikers met gratis abonnementen."),
        "sharedByMe": MessageLookupByLibrary.simpleMessage("Gedeeld door mij"),
        "sharedByYou": MessageLookupByLibrary.simpleMessage("Gedeeld door jou"),
        "sharedPhotoNotifications":
            MessageLookupByLibrary.simpleMessage("Nieuwe gedeelde foto\'s"),
        "sharedPhotoNotificationsExplanation": MessageLookupByLibrary.simpleMessage(
            "Ontvang meldingen wanneer iemand een foto toevoegt aan een gedeeld album waar je deel van uitmaakt"),
        "sharedWith": m52,
        "sharedWithMe": MessageLookupByLibrary.simpleMessage("Gedeeld met mij"),
        "sharedWithYou":
            MessageLookupByLibrary.simpleMessage("Gedeeld met jou"),
        "sharing": MessageLookupByLibrary.simpleMessage("Delen..."),
        "showMemories":
            MessageLookupByLibrary.simpleMessage("Toon herinneringen"),
        "signOutFromOtherDevices":
            MessageLookupByLibrary.simpleMessage("Log uit op andere apparaten"),
        "signOutOtherBody": MessageLookupByLibrary.simpleMessage(
            "Als je denkt dat iemand je wachtwoord zou kunnen kennen, kun je alle andere apparaten die je account gebruiken dwingen om uit te loggen."),
        "signOutOtherDevices":
            MessageLookupByLibrary.simpleMessage("Log uit op andere apparaten"),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "Ik ga akkoord met de <u-terms>gebruiksvoorwaarden</u-terms> en <u-policy>privacybeleid</u-policy>"),
        "singleFileDeleteFromDevice": m53,
        "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
            "Het wordt uit alle albums verwijderd."),
        "singleFileInBothLocalAndRemote": m54,
        "singleFileInRemoteOnly": m55,
        "skip": MessageLookupByLibrary.simpleMessage("Overslaan"),
        "social": MessageLookupByLibrary.simpleMessage("Sociale media"),
        "someItemsAreInBothEnteAndYourDevice": MessageLookupByLibrary.simpleMessage(
            "Sommige bestanden bevinden zich in zowel ente als op uw apparaat."),
        "someOfTheFilesYouAreTryingToDeleteAre":
            MessageLookupByLibrary.simpleMessage(
                "Sommige bestanden die u probeert te verwijderen zijn alleen beschikbaar op uw apparaat en kunnen niet hersteld worden als deze verwijderd worden"),
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
        "sorryTheCodeYouveEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "Sorry, de ingevoerde code is onjuist"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "Sorry, we konden geen beveiligde sleutels genereren op dit apparaat.\n\nGelieve je aan te melden vanaf een ander apparaat."),
        "sortAlbumsBy": MessageLookupByLibrary.simpleMessage("Sorteren op"),
        "sortNewestFirst":
            MessageLookupByLibrary.simpleMessage("Nieuwste eerst"),
        "sortOldestFirst": MessageLookupByLibrary.simpleMessage("Oudste eerst"),
        "sparkleSuccess": MessageLookupByLibrary.simpleMessage("✨ Succes"),
        "startBackup": MessageLookupByLibrary.simpleMessage("Back-up starten"),
        "status": MessageLookupByLibrary.simpleMessage("Status"),
        "storage": MessageLookupByLibrary.simpleMessage("Opslagruimte"),
        "storageBreakupFamily": MessageLookupByLibrary.simpleMessage("Familie"),
        "storageBreakupYou": MessageLookupByLibrary.simpleMessage("Jij"),
        "storageInGB": m56,
        "storageLimitExceeded":
            MessageLookupByLibrary.simpleMessage("Opslaglimiet overschreden"),
        "storageUsageInfo": m57,
        "strongStrength": MessageLookupByLibrary.simpleMessage("Sterk"),
        "subAlreadyLinkedErrMessage": m58,
        "subWillBeCancelledOn": m59,
        "subscribe": MessageLookupByLibrary.simpleMessage("Abonneer"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "Het lijkt erop dat je abonnement is verlopen. Abonneer om delen mogelijk te maken."),
        "subscription": MessageLookupByLibrary.simpleMessage("Abonnement"),
        "success": MessageLookupByLibrary.simpleMessage("Succes"),
        "successfullyArchived":
            MessageLookupByLibrary.simpleMessage("Succesvol gearchiveerd"),
        "successfullyHid":
            MessageLookupByLibrary.simpleMessage("Succesvol verborgen"),
        "successfullyUnarchived": MessageLookupByLibrary.simpleMessage(
            "Succesvol uit archief gehaald"),
        "successfullyUnhid": MessageLookupByLibrary.simpleMessage(
            "Met succes zichtbaar gemaakt"),
        "suggestFeatures":
            MessageLookupByLibrary.simpleMessage("Features voorstellen"),
        "support": MessageLookupByLibrary.simpleMessage("Ondersteuning"),
        "syncProgress": m60,
        "syncStopped":
            MessageLookupByLibrary.simpleMessage("Synchronisatie gestopt"),
        "syncing": MessageLookupByLibrary.simpleMessage("Synchroniseren..."),
        "systemTheme": MessageLookupByLibrary.simpleMessage("Systeem"),
        "tapToCopy": MessageLookupByLibrary.simpleMessage("tik om te kopiëren"),
        "tapToEnterCode":
            MessageLookupByLibrary.simpleMessage("Tik om code in te voeren"),
        "tempErrorContactSupportIfPersists": MessageLookupByLibrary.simpleMessage(
            "Het lijkt erop dat er iets fout is gegaan. Probeer het later opnieuw. Als de fout zich blijft voordoen, neem dan contact op met ons supportteam."),
        "terminate": MessageLookupByLibrary.simpleMessage("Beëindigen"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Sessie beëindigen?"),
        "terms": MessageLookupByLibrary.simpleMessage("Voorwaarden"),
        "termsOfServicesTitle":
            MessageLookupByLibrary.simpleMessage("Voorwaarden"),
        "thankYou": MessageLookupByLibrary.simpleMessage("Bedankt"),
        "thankYouForSubscribing": MessageLookupByLibrary.simpleMessage(
            "Dank je wel voor het abonneren!"),
        "theDownloadCouldNotBeCompleted": MessageLookupByLibrary.simpleMessage(
            "De download kon niet worden voltooid"),
        "theRecoveryKeyYouEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "De ingevoerde herstelsleutel is onjuist"),
        "theme": MessageLookupByLibrary.simpleMessage("Thema"),
        "theseItemsWillBeDeletedFromYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Deze bestanden zullen worden verwijderd van uw apparaat."),
        "theyAlsoGetXGb": m61,
        "theyWillBeDeletedFromAllAlbums": MessageLookupByLibrary.simpleMessage(
            "Ze zullen uit alle albums worden verwijderd."),
        "thisActionCannotBeUndone": MessageLookupByLibrary.simpleMessage(
            "Deze actie kan niet ongedaan gemaakt worden"),
        "thisAlbumAlreadyHDACollaborativeLink":
            MessageLookupByLibrary.simpleMessage(
                "Dit album heeft al een gezamenlijke link"),
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "Dit kan worden gebruikt om je account te herstellen als je je tweede factor verliest"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Dit apparaat"),
        "thisEmailIsAlreadyInUse": MessageLookupByLibrary.simpleMessage(
            "Dit e-mailadres is al in gebruik"),
        "thisImageHasNoExifData": MessageLookupByLibrary.simpleMessage(
            "Deze foto heeft geen exif gegevens"),
        "thisIsPersonVerificationId": m62,
        "thisIsYourVerificationId":
            MessageLookupByLibrary.simpleMessage("Dit is uw verificatie-ID"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Dit zal je uitloggen van het volgende apparaat:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Dit zal je uitloggen van dit apparaat!"),
        "toHideAPhotoOrVideo": MessageLookupByLibrary.simpleMessage(
            "Om een foto of video te verbergen"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "Verifieer eerst je e-mailadres om je wachtwoord opnieuw in te stellen."),
        "todaysLogs":
            MessageLookupByLibrary.simpleMessage("Logboeken van vandaag"),
        "total": MessageLookupByLibrary.simpleMessage("totaal"),
        "totalSize": MessageLookupByLibrary.simpleMessage("Totale grootte"),
        "trash": MessageLookupByLibrary.simpleMessage("Prullenbak"),
        "trashDaysLeft": m63,
        "tryAgain": MessageLookupByLibrary.simpleMessage("Probeer opnieuw"),
        "turnOnBackupForAutoUpload": MessageLookupByLibrary.simpleMessage(
            "Schakel back-up in om bestanden die toegevoegd zijn aan deze map op dit apparaat automatisch te uploaden."),
        "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
        "twoMonthsFreeOnYearlyPlans": MessageLookupByLibrary.simpleMessage(
            "Krijg 2 maanden gratis op jaarlijkse abonnementen"),
        "twofactor":
            MessageLookupByLibrary.simpleMessage("Tweestapsverificatie"),
        "twofactorAuthenticationHasBeenDisabled":
            MessageLookupByLibrary.simpleMessage(
                "Tweestapsverificatie is uitgeschakeld"),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage("Tweestapsverificatie"),
        "twofactorAuthenticationSuccessfullyReset":
            MessageLookupByLibrary.simpleMessage(
                "Tweestapsverificatie succesvol gereset"),
        "twofactorSetup":
            MessageLookupByLibrary.simpleMessage("Tweestapsverificatie"),
        "unarchive": MessageLookupByLibrary.simpleMessage("Uit archief halen"),
        "unarchiveAlbum":
            MessageLookupByLibrary.simpleMessage("Album uit archief halen"),
        "unarchiving":
            MessageLookupByLibrary.simpleMessage("Uit het archief halen..."),
        "uncategorized":
            MessageLookupByLibrary.simpleMessage("Ongecategoriseerd"),
        "unhide": MessageLookupByLibrary.simpleMessage("Zichtbaar maken"),
        "unhideToAlbum":
            MessageLookupByLibrary.simpleMessage("Zichtbaar maken in album"),
        "unhiding": MessageLookupByLibrary.simpleMessage("Zichtbaar maken..."),
        "unhidingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Bestanden zichtbaar maken in album"),
        "unlock": MessageLookupByLibrary.simpleMessage("Ontgrendelen"),
        "unpinAlbum": MessageLookupByLibrary.simpleMessage("Album losmaken"),
        "unselectAll":
            MessageLookupByLibrary.simpleMessage("Deselecteer alles"),
        "update": MessageLookupByLibrary.simpleMessage("Update"),
        "updateAvailable":
            MessageLookupByLibrary.simpleMessage("Update beschikbaar"),
        "updatingFolderSelection":
            MessageLookupByLibrary.simpleMessage("Map selectie bijwerken..."),
        "upgrade": MessageLookupByLibrary.simpleMessage("Upgraden"),
        "uploadingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Bestanden worden geüpload naar album..."),
        "upto50OffUntil4thDec": MessageLookupByLibrary.simpleMessage(
            "Tot 50% korting, tot 4 december."),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "Bruikbare opslag is beperkt door je huidige abonnement. Buitensporige geclaimde opslag zal automatisch bruikbaar worden wanneer je je abonnement upgrade."),
        "usePublicLinksForPeopleNotOnEnte":
            MessageLookupByLibrary.simpleMessage(
                "Gebruik publieke links voor mensen die niet op ente zitten"),
        "useRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Herstelcode gebruiken"),
        "useSelectedPhoto":
            MessageLookupByLibrary.simpleMessage("Gebruik geselecteerde foto"),
        "usedSpace": MessageLookupByLibrary.simpleMessage("Gebruikte ruimte"),
        "validTill": m64,
        "verificationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Verificatie mislukt, probeer het opnieuw"),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("Verificatie ID"),
        "verify": MessageLookupByLibrary.simpleMessage("Verifiëren"),
        "verifyEmail": MessageLookupByLibrary.simpleMessage("Bevestig e-mail"),
        "verifyEmailID": m65,
        "verifyIDLabel": MessageLookupByLibrary.simpleMessage("Verifiëren"),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Bevestig wachtwoord"),
        "verifying": MessageLookupByLibrary.simpleMessage("Verifiëren..."),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Herstelsleutel verifiëren..."),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("video"),
        "videos": MessageLookupByLibrary.simpleMessage("Video\'s"),
        "viewActiveSessions":
            MessageLookupByLibrary.simpleMessage("Actieve sessies bekijken"),
        "viewAddOnButton":
            MessageLookupByLibrary.simpleMessage("Add-ons bekijken"),
        "viewAll": MessageLookupByLibrary.simpleMessage("Alles weergeven"),
        "viewAllExifData":
            MessageLookupByLibrary.simpleMessage("Bekijk alle EXIF gegevens"),
        "viewLogs": MessageLookupByLibrary.simpleMessage("Logboeken bekijken"),
        "viewRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Toon herstelsleutel"),
        "viewer": MessageLookupByLibrary.simpleMessage("Kijker"),
        "visitWebToManage": MessageLookupByLibrary.simpleMessage(
            "Bezoek alstublieft web.ente.io om uw abonnement te beheren"),
        "waitingForWifi":
            MessageLookupByLibrary.simpleMessage("Wachten op WiFi..."),
        "weAreOpenSource":
            MessageLookupByLibrary.simpleMessage("We zijn open source!"),
        "weDontSupportEditingPhotosAndAlbumsThatYouDont":
            MessageLookupByLibrary.simpleMessage(
                "We ondersteunen het bewerken van foto\'s en albums waar je niet de eigenaar van bent nog niet"),
        "weHaveSendEmailTo": m66,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Zwak"),
        "welcomeBack": MessageLookupByLibrary.simpleMessage("Welkom terug!"),
        "yearly": MessageLookupByLibrary.simpleMessage("Jaarlijks"),
        "yearsAgo": m67,
        "yes": MessageLookupByLibrary.simpleMessage("Ja"),
        "yesCancel": MessageLookupByLibrary.simpleMessage("Ja, opzeggen"),
        "yesConvertToViewer":
            MessageLookupByLibrary.simpleMessage("Ja, converteren naar viewer"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("Ja, verwijderen"),
        "yesDiscardChanges":
            MessageLookupByLibrary.simpleMessage("Ja, wijzigingen negeren"),
        "yesLogout": MessageLookupByLibrary.simpleMessage("Ja, log uit"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("Ja, verwijderen"),
        "yesRenew": MessageLookupByLibrary.simpleMessage("Ja, verlengen"),
        "you": MessageLookupByLibrary.simpleMessage("Jij"),
        "youAreOnAFamilyPlan": MessageLookupByLibrary.simpleMessage(
            "U bent onderdeel van een familie abonnement!"),
        "youAreOnTheLatestVersion":
            MessageLookupByLibrary.simpleMessage("Je hebt de laatste versie"),
        "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "* Je kunt maximaal je opslag verdubbelen"),
        "youCanManageYourLinksInTheShareTab":
            MessageLookupByLibrary.simpleMessage(
                "U kunt uw links beheren in het tabblad \'Delen\'."),
        "youCanTrySearchingForADifferentQuery":
            MessageLookupByLibrary.simpleMessage(
                "U kunt proberen een andere zoekopdracht te vinden."),
        "youCannotDowngradeToThisPlan": MessageLookupByLibrary.simpleMessage(
            "U kunt niet downgraden naar dit abonnement"),
        "youCannotShareWithYourself": MessageLookupByLibrary.simpleMessage(
            "Je kunt niet met jezelf delen"),
        "youDontHaveAnyArchivedItems": MessageLookupByLibrary.simpleMessage(
            "U heeft geen gearchiveerde bestanden."),
        "youHaveSuccessfullyFreedUp": m68,
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("Je account is verwijderd"),
        "yourMap": MessageLookupByLibrary.simpleMessage("Jouw kaart"),
        "yourPlanWasSuccessfullyDowngraded":
            MessageLookupByLibrary.simpleMessage(
                "Uw abonnement is succesvol gedegradeerd"),
        "yourPlanWasSuccessfullyUpgraded": MessageLookupByLibrary.simpleMessage(
            "Uw abonnement is succesvol opgewaardeerd"),
        "yourPurchaseWasSuccessful":
            MessageLookupByLibrary.simpleMessage("Uw betaling is geslaagd"),
        "yourStorageDetailsCouldNotBeFetched":
            MessageLookupByLibrary.simpleMessage(
                "Uw opslaggegevens konden niet worden opgehaald"),
        "yourSubscriptionHasExpired":
            MessageLookupByLibrary.simpleMessage("Uw abonnement is verlopen"),
        "yourSubscriptionWasUpdatedSuccessfully":
            MessageLookupByLibrary.simpleMessage(
                "Uw abonnement is succesvol bijgewerkt"),
        "yourVerificationCodeHasExpired": MessageLookupByLibrary.simpleMessage(
            "Uw verificatiecode is verlopen"),
        "youveNoDuplicateFilesThatCanBeCleared":
            MessageLookupByLibrary.simpleMessage(
                "Je hebt geen dubbele bestanden die kunnen worden gewist"),
        "youveNoFilesInThisAlbumThatCanBeDeleted":
            MessageLookupByLibrary.simpleMessage(
                "Je hebt geen bestanden in dit album die verwijderd kunnen worden"),
        "zoomOutToSeePhotos":
            MessageLookupByLibrary.simpleMessage("Zoom uit om foto\'s te zien")
      };
}
