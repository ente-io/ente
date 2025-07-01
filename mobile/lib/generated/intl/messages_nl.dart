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

  static String m0(title) => "${title} (Ik)";

  static String m1(count) =>
      "${Intl.plural(count, zero: 'Samenwerker toevoegen', one: 'Samenwerker toevoegen', other: 'Samenwerkers toevoegen')}";

  static String m2(count) =>
      "${Intl.plural(count, one: 'Bestand toevoegen', other: 'Bestanden toevoegen')}";

  static String m3(storageAmount, endDate) =>
      "Jouw ${storageAmount} add-on is geldig tot ${endDate}";

  static String m4(count) =>
      "${Intl.plural(count, zero: 'Kijker toevoegen', one: 'Kijker toevoegen', other: 'Kijkers toevoegen')}";

  static String m5(emailOrName) => "Toegevoegd door ${emailOrName}";

  static String m6(albumName) => "Succesvol toegevoegd aan  ${albumName}";

  static String m7(name) => "${name} bewonderen";

  static String m8(count) =>
      "${Intl.plural(count, zero: 'Geen deelnemers', one: '1 deelnemer', other: '${count} deelnemers')}";

  static String m9(versionValue) => "Versie: ${versionValue}";

  static String m10(freeAmount, storageUnit) =>
      "${freeAmount} ${storageUnit} vrij";

  static String m11(name) => "Prachtige uitzichten met ${name}";

  static String m12(paymentProvider) =>
      "Annuleer eerst uw bestaande abonnement bij ${paymentProvider}";

  static String m13(user) =>
      "${user} zal geen foto\'s meer kunnen toevoegen aan dit album\n\nDe gebruiker zal nog steeds bestaande foto\'s kunnen verwijderen die door hen zijn toegevoegd";

  static String m14(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true':
                'Jouw familie heeft ${storageAmountInGb} GB geclaimd tot nu toe',
            'false': 'Je hebt ${storageAmountInGb} GB geclaimd tot nu toe',
            'other': 'Je hebt ${storageAmountInGb} GB geclaimd tot nu toe!',
          })}";

  static String m15(albumName) =>
      "Gezamenlijke link aangemaakt voor ${albumName}";

  static String m16(count) =>
      "${Intl.plural(count, zero: '0 samenwerkers toegevoegd', one: '1 samenwerker toegevoegd', other: '${count} samenwerkers toegevoegd')}";

  static String m17(email, numOfDays) =>
      "Je staat op het punt ${email} toe te voegen als vertrouwde contactpersoon. Ze kunnen je account herstellen als je ${numOfDays} dagen afwezig bent.";

  static String m18(familyAdminEmail) =>
      "Neem contact op met <green>${familyAdminEmail}</green> om uw abonnement te beheren";

  static String m19(provider) =>
      "Neem contact met ons op via support@ente.io om uw ${provider} abonnement te beheren.";

  static String m20(endpoint) => "Verbonden met ${endpoint}";

  static String m21(count) =>
      "${Intl.plural(count, one: 'Verwijder ${count} bestand', other: 'Verwijder ${count} bestanden')}";

  static String m22(count) =>
      "Verwijder de foto\'s (en video\'s) van deze ${count} albums ook uit <bold>alle</bold> andere albums waar deze deel van uitmaken?";

  static String m23(currentlyDeleting, totalCount) =>
      "Verwijderen van ${currentlyDeleting} / ${totalCount}";

  static String m24(albumName) =>
      "Dit verwijdert de openbare link voor toegang tot \"${albumName}\".";

  static String m25(supportEmail) =>
      "Stuur een e-mail naar ${supportEmail} vanaf het door jou geregistreerde e-mailadres";

  static String m26(count, storageSaved) =>
      "Je hebt ${Intl.plural(count, one: '${count} dubbel bestand', other: '${count} dubbele bestanden')} opgeruimd, totaal (${storageSaved}!)";

  static String m27(count, formattedSize) =>
      "${count} bestanden, elk ${formattedSize}";

  static String m28(name) => "Dit e-mailadres is al aan ${name} gekoppeld.";

  static String m29(newEmail) => "E-mailadres gewijzigd naar ${newEmail}";

  static String m30(email) => "${email} heeft geen Ente account.";

  static String m31(email) =>
      "${email} heeft geen Ente account.\n\nStuur ze een uitnodiging om foto\'s te delen.";

  static String m32(name) => "${name} omarmen";

  static String m33(text) => "Extra foto\'s gevonden voor ${text}";

  static String m34(name) => "Feestmaal met ${name}";

  static String m35(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 bestand', other: '${formattedNumber} bestanden')} in dit album zijn veilig geback-upt";

  static String m36(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 bestand', other: '${formattedNumber} bestanden')} in dit album is veilig geback-upt";

  static String m37(storageAmountInGB) =>
      "${storageAmountInGB} GB telkens als iemand zich aanmeldt voor een betaald abonnement en je code toepast";

  static String m38(endDate) => "Gratis proefversie geldig tot ${endDate}";

  static String m39(count) =>
      "Je hebt nog steeds toegang tot ${Intl.plural(count, one: 'het', other: 'ze')} op Ente zolang je een actief abonnement hebt";

  static String m40(sizeInMBorGB) => "Maak ${sizeInMBorGB} vrij";

  static String m41(count, formattedSize) =>
      "${Intl.plural(count, one: 'Het kan verwijderd worden van het apparaat om ${formattedSize} vrij te maken', other: 'Ze kunnen verwijderd worden van het apparaat om ${formattedSize} vrij te maken')}";

  static String m42(currentlyProcessing, totalCount) =>
      "Verwerken van ${currentlyProcessing} / ${totalCount}";

  static String m43(name) => "Wandelen met ${name}";

  static String m44(count) =>
      "${Intl.plural(count, one: '${count} item', other: '${count} items')}";

  static String m45(name) => "Laatste keer met ${name}";

  static String m46(email) =>
      "${email} heeft je uitgenodigd om een vertrouwd contact te zijn";

  static String m47(expiryTime) => "Link vervalt op ${expiryTime}";

  static String m48(email) => "Link persoon aan ${email}";

  static String m49(personName, email) =>
      "Dit linkt ${personName} aan ${email}";

  static String m50(count, formattedCount) =>
      "${Intl.plural(count, zero: 'geen herinneringen', one: '${formattedCount} herinnering', other: '${formattedCount} herinneringen')}";

  static String m51(count) =>
      "${Intl.plural(count, one: 'Bestand verplaatsen', other: 'Bestanden verplaatsen')}";

  static String m52(albumName) => "Succesvol verplaatst naar ${albumName}";

  static String m53(personName) => "Geen suggesties voor ${personName}";

  static String m54(name) => "Niet ${name}?";

  static String m55(familyAdminEmail) =>
      "Neem contact op met ${familyAdminEmail} om uw code te wijzigen.";

  static String m56(name) => "Feest met ${name}";

  static String m57(passwordStrengthValue) =>
      "Wachtwoord sterkte: ${passwordStrengthValue}";

  static String m58(providerName) =>
      "Praat met ${providerName} klantenservice als u in rekening bent gebracht";

  static String m59(name, age) => "${name} is ${age}!";

  static String m60(name, age) => "${name} wordt binnenkort ${age}";

  static String m61(count) =>
      "${Intl.plural(count, zero: 'Geen foto\'s', one: '1 foto', other: '${count} foto\'s')}";

  static String m62(count) =>
      "${Intl.plural(count, zero: '0 foto\'s', one: '1 foto', other: '${count} foto\'s')}";

  static String m63(endDate) =>
      "Gratis proefperiode geldig tot ${endDate}.\nU kunt naderhand een betaald abonnement kiezen.";

  static String m64(toEmail) => "Stuur ons een e-mail op ${toEmail}";

  static String m65(toEmail) =>
      "Verstuur de logboeken alstublieft naar ${toEmail}";

  static String m66(name) => "Poseren met ${name}";

  static String m67(folderName) => "Verwerken van ${folderName}...";

  static String m68(storeName) => "Beoordeel ons op ${storeName}";

  static String m69(name) => "Toegewezen aan ${name}";

  static String m70(days, email) =>
      "U krijgt toegang tot het account na ${days} dagen. Een melding zal worden verzonden naar ${email}.";

  static String m71(email) =>
      "U kunt nu het account van ${email} herstellen door een nieuw wachtwoord in te stellen.";

  static String m72(email) => "${email} probeert je account te herstellen.";

  static String m73(storageInGB) =>
      "Jullie krijgen allebei ${storageInGB} GB* gratis";

  static String m74(userEmail) =>
      "${userEmail} zal worden verwijderd uit dit gedeelde album\n\nAlle door hen toegevoegde foto\'s worden ook uit het album verwijderd";

  static String m75(endDate) => "Wordt verlengd op ${endDate}";

  static String m76(name) => "Roadtrip met ${name}";

  static String m77(count) =>
      "${Intl.plural(count, one: '${count} resultaat gevonden', other: '${count} resultaten gevonden')}";

  static String m78(snapshotLength, searchLength) =>
      "Lengte van secties komt niet overeen: ${snapshotLength} != ${searchLength}";

  static String m79(count) => "${count} geselecteerd";

  static String m80(count) => "${count} geselecteerd";

  static String m81(count, yourCount) =>
      "${count} geselecteerd (${yourCount} van jou)";

  static String m82(name) => "Selfies met ${name}";

  static String m83(verificationID) =>
      "Hier is mijn verificatie-ID: ${verificationID} voor ente.io.";

  static String m84(verificationID) =>
      "Hey, kunt u bevestigen dat dit uw ente.io verificatie-ID is: ${verificationID}";

  static String m85(referralCode, referralStorageInGB) =>
      "Ente verwijzingscode: ${referralCode} \n\nPas het toe bij Instellingen → Algemeen → Verwijzingen om ${referralStorageInGB} GB gratis te krijgen nadat je je hebt aangemeld voor een betaald abonnement\n\nhttps://ente.io";

  static String m86(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Deel met specifieke mensen', one: 'Gedeeld met 1 persoon', other: 'Gedeeld met ${numberOfPeople} mensen')}";

  static String m87(emailIDs) => "Gedeeld met ${emailIDs}";

  static String m88(fileType) =>
      "Deze ${fileType} zal worden verwijderd van jouw apparaat.";

  static String m89(fileType) =>
      "Deze ${fileType} staat zowel in Ente als op jouw apparaat.";

  static String m90(fileType) =>
      "Deze ${fileType} zal worden verwijderd uit Ente.";

  static String m91(name) => "Sporten met ${name}";

  static String m92(name) => "Spotlicht op ${name}";

  static String m93(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m94(
          usedAmount, usedStorageUnit, totalAmount, totalStorageUnit) =>
      "${usedAmount} ${usedStorageUnit} van ${totalAmount} ${totalStorageUnit} gebruikt";

  static String m95(id) =>
      "Jouw ${id} is al aan een ander Ente account gekoppeld.\nAls je jouw ${id} wilt gebruiken met dit account, neem dan contact op met onze klantenservice";

  static String m96(endDate) => "Uw abonnement loopt af op ${endDate}";

  static String m97(completed, total) =>
      "${completed}/${total} herinneringen bewaard";

  static String m98(ignoreReason) =>
      "Tik om te uploaden, upload wordt momenteel genegeerd vanwege ${ignoreReason}";

  static String m99(storageAmountInGB) =>
      "Zij krijgen ook ${storageAmountInGB} GB";

  static String m100(email) => "Dit is de verificatie-ID van ${email}";

  static String m101(count) =>
      "${Intl.plural(count, one: 'Deze week, ${count} jaar geleden', other: 'Deze week, ${count} jaren geleden')}";

  static String m102(dateFormat) => "${dateFormat} door de jaren";

  static String m103(count) =>
      "${Intl.plural(count, zero: 'Binnenkort', one: '1 dag', other: '${count} dagen')}";

  static String m104(year) => "Reis in ${year}";

  static String m105(location) => "Reis naar ${location}";

  static String m106(email) =>
      "Je bent uitgenodigd om een legacy contact van ${email} te zijn.";

  static String m107(galleryType) =>
      "Galerijtype ${galleryType} wordt niet ondersteund voor hernoemen";

  static String m108(ignoreReason) =>
      "Upload wordt genegeerd omdat ${ignoreReason}";

  static String m109(count) => "${count} herinneringen veiligstellen...";

  static String m110(endDate) => "Geldig tot ${endDate}";

  static String m111(email) => "Verifieer ${email}";

  static String m112(name) => "Bekijk ${name} om te ontkoppelen";

  static String m113(count) =>
      "${Intl.plural(count, zero: '0 kijkers toegevoegd', one: '1 kijker toegevoegd', other: '${count} kijkers toegevoegd')}";

  static String m114(email) =>
      "We hebben een e-mail gestuurd naar <green>${email}</green>";

  static String m115(name) => "Wish \$${name} a happy birthday! 🎉";

  static String m116(count) =>
      "${Intl.plural(count, other: '${count} jaar geleden')}";

  static String m117(name) => "Jij en ${name}";

  static String m118(storageSaved) =>
      "Je hebt ${storageSaved} succesvol vrijgemaakt!";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable": MessageLookupByLibrary.simpleMessage(
            "Er is een nieuwe versie van Ente beschikbaar."),
        "about": MessageLookupByLibrary.simpleMessage("Over"),
        "acceptTrustInvite":
            MessageLookupByLibrary.simpleMessage("Uitnodiging accepteren"),
        "account": MessageLookupByLibrary.simpleMessage("Account"),
        "accountIsAlreadyConfigured": MessageLookupByLibrary.simpleMessage(
            "Account is al geconfigureerd."),
        "accountOwnerPersonAppbarTitle": m0,
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Welkom terug!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Ik begrijp dat als ik mijn wachtwoord verlies, ik mijn gegevens kan verliezen omdat mijn gegevens <underline>end-to-end versleuteld</underline> zijn."),
        "actionNotSupportedOnFavouritesAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Actie niet ondersteund op Favorieten album"),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Actieve sessies"),
        "add": MessageLookupByLibrary.simpleMessage("Toevoegen"),
        "addAName": MessageLookupByLibrary.simpleMessage("Een naam toevoegen"),
        "addANewEmail":
            MessageLookupByLibrary.simpleMessage("Nieuw e-mailadres toevoegen"),
        "addAlbumWidgetPrompt": MessageLookupByLibrary.simpleMessage(
            "Voeg een widget toe aan je beginscherm en kom hier terug om aan te passen."),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Samenwerker toevoegen"),
        "addCollaborators": m1,
        "addFiles": MessageLookupByLibrary.simpleMessage("Bestanden toevoegen"),
        "addFromDevice":
            MessageLookupByLibrary.simpleMessage("Toevoegen vanaf apparaat"),
        "addItem": m2,
        "addLocation":
            MessageLookupByLibrary.simpleMessage("Locatie toevoegen"),
        "addLocationButton": MessageLookupByLibrary.simpleMessage("Toevoegen"),
        "addMemoriesWidgetPrompt": MessageLookupByLibrary.simpleMessage(
            "Voeg een widget toe aan je beginscherm en kom hier terug om aan te passen."),
        "addMore": MessageLookupByLibrary.simpleMessage("Meer toevoegen"),
        "addName": MessageLookupByLibrary.simpleMessage("Naam toevoegen"),
        "addNameOrMerge": MessageLookupByLibrary.simpleMessage(
            "Naam toevoegen of samenvoegen"),
        "addNew": MessageLookupByLibrary.simpleMessage("Nieuwe toevoegen"),
        "addNewPerson":
            MessageLookupByLibrary.simpleMessage("Nieuw persoon toevoegen"),
        "addOnPageSubtitle":
            MessageLookupByLibrary.simpleMessage("Details van add-ons"),
        "addOnValidTill": m3,
        "addOns": MessageLookupByLibrary.simpleMessage("Add-ons"),
        "addParticipants":
            MessageLookupByLibrary.simpleMessage("Voeg deelnemers toe"),
        "addPeopleWidgetPrompt": MessageLookupByLibrary.simpleMessage(
            "Voeg een widget toe aan je beginscherm en kom hier terug om aan te passen."),
        "addPhotos": MessageLookupByLibrary.simpleMessage("Foto\'s toevoegen"),
        "addSelected":
            MessageLookupByLibrary.simpleMessage("Voeg geselecteerde toe"),
        "addToAlbum":
            MessageLookupByLibrary.simpleMessage("Toevoegen aan album"),
        "addToEnte": MessageLookupByLibrary.simpleMessage("Toevoegen aan Ente"),
        "addToHiddenAlbum": MessageLookupByLibrary.simpleMessage(
            "Toevoegen aan verborgen album"),
        "addTrustedContact":
            MessageLookupByLibrary.simpleMessage("Vertrouwd contact toevoegen"),
        "addViewer": MessageLookupByLibrary.simpleMessage("Voeg kijker toe"),
        "addViewers": m4,
        "addYourPhotosNow":
            MessageLookupByLibrary.simpleMessage("Voeg nu je foto\'s toe"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Toegevoegd als"),
        "addedBy": m5,
        "addedSuccessfullyTo": m6,
        "addingToFavorites":
            MessageLookupByLibrary.simpleMessage("Toevoegen aan favorieten..."),
        "admiringThem": m7,
        "advanced": MessageLookupByLibrary.simpleMessage("Geavanceerd"),
        "advancedSettings": MessageLookupByLibrary.simpleMessage("Geavanceerd"),
        "after1Day": MessageLookupByLibrary.simpleMessage("Na 1 dag"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("Na 1 uur"),
        "after1Month": MessageLookupByLibrary.simpleMessage("Na 1 maand"),
        "after1Week": MessageLookupByLibrary.simpleMessage("Na 1 week"),
        "after1Year": MessageLookupByLibrary.simpleMessage("Na 1 jaar"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Eigenaar"),
        "albumParticipantsCount": m8,
        "albumTitle": MessageLookupByLibrary.simpleMessage("Albumtitel"),
        "albumUpdated":
            MessageLookupByLibrary.simpleMessage("Album bijgewerkt"),
        "albums": MessageLookupByLibrary.simpleMessage("Albums"),
        "albumsWidgetDesc": MessageLookupByLibrary.simpleMessage(
            "Selecteer de albums die je wilt zien op je beginscherm."),
        "allClear": MessageLookupByLibrary.simpleMessage("✨ Alles in orde"),
        "allMemoriesPreserved":
            MessageLookupByLibrary.simpleMessage("Alle herinneringen bewaard"),
        "allPersonGroupingWillReset": MessageLookupByLibrary.simpleMessage(
            "Alle groepen voor deze persoon worden gereset, en je verliest alle suggesties die voor deze persoon zijn gedaan"),
        "allWillShiftRangeBasedOnFirst": MessageLookupByLibrary.simpleMessage(
            "Dit is de eerste in de groep. Andere geselecteerde foto\'s worden automatisch verschoven op basis van deze nieuwe datum"),
        "allow": MessageLookupByLibrary.simpleMessage("Toestaan"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Sta toe dat mensen met de link ook foto\'s kunnen toevoegen aan het gedeelde album."),
        "allowAddingPhotos":
            MessageLookupByLibrary.simpleMessage("Foto\'s toevoegen toestaan"),
        "allowAppToOpenSharedAlbumLinks": MessageLookupByLibrary.simpleMessage(
            "App toestaan gedeelde album links te openen"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("Downloads toestaan"),
        "allowPeopleToAddPhotos": MessageLookupByLibrary.simpleMessage(
            "Mensen toestaan foto\'s toe te voegen"),
        "allowPermBody": MessageLookupByLibrary.simpleMessage(
            "Geef toegang tot je foto\'s vanuit Instellingen zodat Ente je bibliotheek kan weergeven en back-uppen."),
        "allowPermTitle": MessageLookupByLibrary.simpleMessage(
            "Toegang tot foto\'s toestaan"),
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
        "appIcon": MessageLookupByLibrary.simpleMessage("App icoon"),
        "appLock": MessageLookupByLibrary.simpleMessage("App-vergrendeling"),
        "appLockDescriptions": MessageLookupByLibrary.simpleMessage(
            "Kies tussen het standaard vergrendelscherm van uw apparaat en een aangepast vergrendelscherm met een pincode of wachtwoord."),
        "appVersion": m9,
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
        "areYouSureYouWantToResetThisPerson":
            MessageLookupByLibrary.simpleMessage(
                "Weet u zeker dat u deze persoon wilt resetten?"),
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
        "authToManageLegacy": MessageLookupByLibrary.simpleMessage(
            "Verifieer om je vertrouwde contacten te beheren"),
        "authToViewPasskey": MessageLookupByLibrary.simpleMessage(
            "Verifieer uzelf om uw toegangssleutel te bekijken"),
        "authToViewTrashedFiles": MessageLookupByLibrary.simpleMessage(
            "Graag verifiëren om je verwijderde bestanden te bekijken"),
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
        "autoCastDialogBody": MessageLookupByLibrary.simpleMessage(
            "Je zult de beschikbare Cast apparaten hier zien."),
        "autoCastiOSPermission": MessageLookupByLibrary.simpleMessage(
            "Zorg ervoor dat lokale netwerkrechten zijn ingeschakeld voor de Ente Photos app, in Instellingen."),
        "autoLock":
            MessageLookupByLibrary.simpleMessage("Automatische vergrendeling"),
        "autoLockFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "Tijd waarna de app wordt vergrendeld wanneer deze in achtergrond-modus is gezet"),
        "autoLogoutMessage": MessageLookupByLibrary.simpleMessage(
            "Door een technische storing bent u uitgelogd. Onze excuses voor het ongemak."),
        "autoPair":
            MessageLookupByLibrary.simpleMessage("Automatisch koppelen"),
        "autoPairDesc": MessageLookupByLibrary.simpleMessage(
            "Automatisch koppelen werkt alleen met apparaten die Chromecast ondersteunen."),
        "available": MessageLookupByLibrary.simpleMessage("Beschikbaar"),
        "availableStorageSpace": m10,
        "backedUpFolders":
            MessageLookupByLibrary.simpleMessage("Back-up mappen"),
        "backgroundWithThem": m11,
        "backup": MessageLookupByLibrary.simpleMessage("Back-up"),
        "backupFailed": MessageLookupByLibrary.simpleMessage("Back-up mislukt"),
        "backupFile": MessageLookupByLibrary.simpleMessage("Back-up bestand"),
        "backupOverMobileData": MessageLookupByLibrary.simpleMessage(
            "Back-up maken via mobiele data"),
        "backupSettings":
            MessageLookupByLibrary.simpleMessage("Back-up instellingen"),
        "backupStatus": MessageLookupByLibrary.simpleMessage("Back-up status"),
        "backupStatusDescription": MessageLookupByLibrary.simpleMessage(
            "Items die zijn geback-upt, worden hier getoond"),
        "backupVideos":
            MessageLookupByLibrary.simpleMessage("Back-up video\'s"),
        "beach": MessageLookupByLibrary.simpleMessage("Zand en zee"),
        "birthday": MessageLookupByLibrary.simpleMessage("Verjaardag"),
        "blackFridaySale":
            MessageLookupByLibrary.simpleMessage("Black Friday-aanbieding"),
        "blog": MessageLookupByLibrary.simpleMessage("Blog"),
        "cachedData": MessageLookupByLibrary.simpleMessage("Cachegegevens"),
        "calculating": MessageLookupByLibrary.simpleMessage("Berekenen..."),
        "canNotOpenBody": MessageLookupByLibrary.simpleMessage(
            "Sorry, dit album kan niet worden geopend in de app."),
        "canNotOpenTitle":
            MessageLookupByLibrary.simpleMessage("Kan dit album niet openen"),
        "canNotUploadToAlbumsOwnedByOthers":
            MessageLookupByLibrary.simpleMessage(
                "Kan niet uploaden naar albums die van anderen zijn"),
        "canOnlyCreateLinkForFilesOwnedByYou":
            MessageLookupByLibrary.simpleMessage(
                "Kan alleen een link maken voor bestanden die van u zijn"),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "Kan alleen bestanden verwijderen die jouw eigendom zijn"),
        "cancel": MessageLookupByLibrary.simpleMessage("Annuleer"),
        "cancelAccountRecovery":
            MessageLookupByLibrary.simpleMessage("Herstel annuleren"),
        "cancelAccountRecoveryBody": MessageLookupByLibrary.simpleMessage(
            "Weet je zeker dat je het herstel wilt annuleren?"),
        "cancelOtherSubscription": m12,
        "cancelSubscription":
            MessageLookupByLibrary.simpleMessage("Abonnement opzeggen"),
        "cannotAddMorePhotosAfterBecomingViewer": m13,
        "cannotDeleteSharedFiles": MessageLookupByLibrary.simpleMessage(
            "Kan gedeelde bestanden niet verwijderen"),
        "castAlbum": MessageLookupByLibrary.simpleMessage("Album casten"),
        "castIPMismatchBody": MessageLookupByLibrary.simpleMessage(
            "Zorg ervoor dat je op hetzelfde netwerk zit als de tv."),
        "castIPMismatchTitle":
            MessageLookupByLibrary.simpleMessage("Album casten mislukt"),
        "castInstruction": MessageLookupByLibrary.simpleMessage(
            "Bezoek cast.ente.io op het apparaat dat u wilt koppelen.\n\nVoer de code hieronder in om het album op uw TV af te spelen."),
        "centerPoint": MessageLookupByLibrary.simpleMessage("Middelpunt"),
        "change": MessageLookupByLibrary.simpleMessage("Wijzigen"),
        "changeEmail": MessageLookupByLibrary.simpleMessage("E-mail wijzigen"),
        "changeLocationOfSelectedItems": MessageLookupByLibrary.simpleMessage(
            "Locatie van geselecteerde items wijzigen?"),
        "changePassword":
            MessageLookupByLibrary.simpleMessage("Wachtwoord wijzigen"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Wachtwoord wijzigen"),
        "changePermissions":
            MessageLookupByLibrary.simpleMessage("Rechten aanpassen?"),
        "changeYourReferralCode":
            MessageLookupByLibrary.simpleMessage("Wijzig uw verwijzingscode"),
        "checkForUpdates":
            MessageLookupByLibrary.simpleMessage("Controleer op updates"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Controleer je inbox (en spam) om verificatie te voltooien"),
        "checkStatus":
            MessageLookupByLibrary.simpleMessage("Status controleren"),
        "checking": MessageLookupByLibrary.simpleMessage("Controleren..."),
        "checkingModels":
            MessageLookupByLibrary.simpleMessage("Modellen controleren..."),
        "city": MessageLookupByLibrary.simpleMessage("In de stad"),
        "claimFreeStorage":
            MessageLookupByLibrary.simpleMessage("Claim gratis opslag"),
        "claimMore": MessageLookupByLibrary.simpleMessage("Claim meer!"),
        "claimed": MessageLookupByLibrary.simpleMessage("Geclaimd"),
        "claimedStorageSoFar": m14,
        "cleanUncategorized":
            MessageLookupByLibrary.simpleMessage("Ongecategoriseerd opschonen"),
        "cleanUncategorizedDescription": MessageLookupByLibrary.simpleMessage(
            "Verwijder alle bestanden van Ongecategoriseerd die aanwezig zijn in andere albums"),
        "clearCaches": MessageLookupByLibrary.simpleMessage("Cache legen"),
        "clearIndexes": MessageLookupByLibrary.simpleMessage("Index wissen"),
        "click": MessageLookupByLibrary.simpleMessage("• Click"),
        "clickOnTheOverflowMenu":
            MessageLookupByLibrary.simpleMessage("• Klik op het menu"),
        "clickToInstallOurBestVersionYet": MessageLookupByLibrary.simpleMessage(
            "Klik om onze beste versie tot nu toe te installeren"),
        "close": MessageLookupByLibrary.simpleMessage("Sluiten"),
        "clubByCaptureTime":
            MessageLookupByLibrary.simpleMessage("Samenvoegen op tijd"),
        "clubByFileName":
            MessageLookupByLibrary.simpleMessage("Samenvoegen op bestandsnaam"),
        "clusteringProgress":
            MessageLookupByLibrary.simpleMessage("Voortgang clusteren"),
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("Code toegepast"),
        "codeChangeLimitReached": MessageLookupByLibrary.simpleMessage(
            "Sorry, u heeft de limiet van het aantal codewijzigingen bereikt."),
        "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Code gekopieerd naar klembord"),
        "codeUsedByYou":
            MessageLookupByLibrary.simpleMessage("Code gebruikt door jou"),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Maak een link waarmee mensen foto\'s in jouw gedeelde album kunnen toevoegen en bekijken zonder dat ze daarvoor een Ente app of account nodig hebben. Handig voor het verzamelen van foto\'s van evenementen."),
        "collaborativeLink":
            MessageLookupByLibrary.simpleMessage("Gezamenlijke link"),
        "collaborativeLinkCreatedFor": m15,
        "collaborator": MessageLookupByLibrary.simpleMessage("Samenwerker"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Samenwerkers kunnen foto\'s en video\'s toevoegen aan het gedeelde album."),
        "collaboratorsSuccessfullyAdded": m16,
        "collageLayout": MessageLookupByLibrary.simpleMessage("Layout"),
        "collageSaved": MessageLookupByLibrary.simpleMessage(
            "Collage opgeslagen in gallerij"),
        "collect": MessageLookupByLibrary.simpleMessage("Verzamelen"),
        "collectEventPhotos": MessageLookupByLibrary.simpleMessage(
            "Foto\'s van gebeurtenissen verzamelen"),
        "collectPhotos":
            MessageLookupByLibrary.simpleMessage("Foto\'s verzamelen"),
        "collectPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Maak een link waarin je vrienden foto\'s kunnen uploaden in de originele kwaliteit."),
        "color": MessageLookupByLibrary.simpleMessage("Kleur"),
        "configuration": MessageLookupByLibrary.simpleMessage("Configuratie"),
        "confirm": MessageLookupByLibrary.simpleMessage("Bevestig"),
        "confirm2FADisable": MessageLookupByLibrary.simpleMessage(
            "Weet u zeker dat u tweestapsverificatie wilt uitschakelen?"),
        "confirmAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Account verwijderen bevestigen"),
        "confirmAddingTrustedContact": m17,
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Ja, ik wil mijn account en de bijbehorende gegevens verspreid over alle apps permanent verwijderen."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Wachtwoord bevestigen"),
        "confirmPlanChange": MessageLookupByLibrary.simpleMessage(
            "Bevestig verandering van abonnement"),
        "confirmRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Bevestig herstelsleutel"),
        "confirmYourRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Bevestig herstelsleutel"),
        "connectToDevice": MessageLookupByLibrary.simpleMessage(
            "Verbinding maken met apparaat"),
        "contactFamilyAdmin": m18,
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("Contacteer klantenservice"),
        "contactToManageSubscription": m19,
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
            MessageLookupByLibrary.simpleMessage("Maak een gezamenlijke link"),
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
        "crop": MessageLookupByLibrary.simpleMessage("Bijsnijden"),
        "curatedMemories":
            MessageLookupByLibrary.simpleMessage("Samengestelde herinneringen"),
        "currentUsageIs":
            MessageLookupByLibrary.simpleMessage("Huidig gebruik is "),
        "currentlyRunning":
            MessageLookupByLibrary.simpleMessage("momenteel bezig"),
        "custom": MessageLookupByLibrary.simpleMessage("Aangepast"),
        "customEndpoint": m20,
        "darkTheme": MessageLookupByLibrary.simpleMessage("Donker"),
        "dayToday": MessageLookupByLibrary.simpleMessage("Vandaag"),
        "dayYesterday": MessageLookupByLibrary.simpleMessage("Gisteren"),
        "declineTrustInvite":
            MessageLookupByLibrary.simpleMessage("Uitnodiging afwijzen"),
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
            "Dit account is gekoppeld aan andere Ente apps, als je er gebruik van maakt. Je geüploade gegevens worden in alle Ente apps gepland voor verwijdering, en je account wordt permanent verwijderd voor alle Ente diensten."),
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
            MessageLookupByLibrary.simpleMessage("Verwijder van Ente"),
        "deleteItemCount": m21,
        "deleteLocation":
            MessageLookupByLibrary.simpleMessage("Verwijder locatie"),
        "deleteMultipleAlbumDialog": m22,
        "deletePhotos":
            MessageLookupByLibrary.simpleMessage("Foto\'s verwijderen"),
        "deleteProgress": m23,
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
        "deselectAll":
            MessageLookupByLibrary.simpleMessage("Alles deselecteren"),
        "designedToOutlive": MessageLookupByLibrary.simpleMessage(
            "Ontworpen om levenslang mee te gaan"),
        "details": MessageLookupByLibrary.simpleMessage("Details"),
        "developerSettings":
            MessageLookupByLibrary.simpleMessage("Ontwikkelaarsinstellingen"),
        "developerSettingsWarning": MessageLookupByLibrary.simpleMessage(
            "Weet je zeker dat je de ontwikkelaarsinstellingen wilt wijzigen?"),
        "deviceCodeHint":
            MessageLookupByLibrary.simpleMessage("Voer de code in"),
        "deviceFilesAutoUploading": MessageLookupByLibrary.simpleMessage(
            "Bestanden toegevoegd aan dit album van dit apparaat zullen automatisch geüpload worden naar Ente."),
        "deviceLock":
            MessageLookupByLibrary.simpleMessage("Apparaat vergrendeld"),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
            "Schakel de schermvergrendeling van het apparaat uit wanneer Ente op de voorgrond is en er een back-up aan de gang is. Dit is normaal gesproken niet nodig, maar kan grote uploads en initiële imports van grote mappen sneller laten verlopen."),
        "deviceNotFound":
            MessageLookupByLibrary.simpleMessage("Apparaat niet gevonden"),
        "didYouKnow": MessageLookupByLibrary.simpleMessage("Wist u dat?"),
        "disableAutoLock": MessageLookupByLibrary.simpleMessage(
            "Automatisch vergrendelen uitschakelen"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Kijkers kunnen nog steeds screenshots maken of een kopie van je foto\'s opslaan met behulp van externe tools"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Let op"),
        "disableLinkMessage": m24,
        "disableTwofactor": MessageLookupByLibrary.simpleMessage(
            "Tweestapsverificatie uitschakelen"),
        "disablingTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Tweestapsverificatie uitschakelen..."),
        "discord": MessageLookupByLibrary.simpleMessage("Discord"),
        "discover": MessageLookupByLibrary.simpleMessage("Ontdek"),
        "discover_babies": MessageLookupByLibrary.simpleMessage("Baby\'s"),
        "discover_celebrations":
            MessageLookupByLibrary.simpleMessage("Vieringen"),
        "discover_food": MessageLookupByLibrary.simpleMessage("Voedsel"),
        "discover_greenery": MessageLookupByLibrary.simpleMessage("Natuur"),
        "discover_hills": MessageLookupByLibrary.simpleMessage("Heuvels"),
        "discover_identity": MessageLookupByLibrary.simpleMessage("Identiteit"),
        "discover_memes": MessageLookupByLibrary.simpleMessage("Memes"),
        "discover_notes": MessageLookupByLibrary.simpleMessage("Notities"),
        "discover_pets": MessageLookupByLibrary.simpleMessage("Huisdieren"),
        "discover_receipts": MessageLookupByLibrary.simpleMessage("Bonnen"),
        "discover_screenshots":
            MessageLookupByLibrary.simpleMessage("Schermafbeeldingen"),
        "discover_selfies": MessageLookupByLibrary.simpleMessage("Selfies"),
        "discover_sunset":
            MessageLookupByLibrary.simpleMessage("Zonsondergang"),
        "discover_visiting_cards":
            MessageLookupByLibrary.simpleMessage("Visite kaartjes"),
        "discover_wallpapers":
            MessageLookupByLibrary.simpleMessage("Achtergronden"),
        "dismiss": MessageLookupByLibrary.simpleMessage("Afwijzen"),
        "distanceInKMUnit": MessageLookupByLibrary.simpleMessage("km"),
        "doNotSignOut": MessageLookupByLibrary.simpleMessage("Niet uitloggen"),
        "doThisLater": MessageLookupByLibrary.simpleMessage("Doe dit later"),
        "doYouWantToDiscardTheEditsYouHaveMade":
            MessageLookupByLibrary.simpleMessage(
                "Wilt u de bewerkingen die u hebt gemaakt annuleren?"),
        "done": MessageLookupByLibrary.simpleMessage("Voltooid"),
        "dontSave": MessageLookupByLibrary.simpleMessage("Niet opslaan"),
        "doubleYourStorage":
            MessageLookupByLibrary.simpleMessage("Verdubbel uw opslagruimte"),
        "download": MessageLookupByLibrary.simpleMessage("Downloaden"),
        "downloadFailed":
            MessageLookupByLibrary.simpleMessage("Download mislukt"),
        "downloading": MessageLookupByLibrary.simpleMessage("Downloaden..."),
        "dropSupportEmail": m25,
        "duplicateFileCountWithStorageSaved": m26,
        "duplicateItemsGroup": m27,
        "edit": MessageLookupByLibrary.simpleMessage("Bewerken"),
        "editEmailAlreadyLinked": m28,
        "editLocation":
            MessageLookupByLibrary.simpleMessage("Locatie bewerken"),
        "editLocationTagTitle":
            MessageLookupByLibrary.simpleMessage("Locatie bewerken"),
        "editPerson": MessageLookupByLibrary.simpleMessage("Persoon bewerken"),
        "editTime": MessageLookupByLibrary.simpleMessage("Tijd bewerken"),
        "editsSaved":
            MessageLookupByLibrary.simpleMessage("Bewerkingen opgeslagen"),
        "editsToLocationWillOnlyBeSeenWithinEnte":
            MessageLookupByLibrary.simpleMessage(
                "Bewerkte locatie wordt alleen gezien binnen Ente"),
        "eligible": MessageLookupByLibrary.simpleMessage("gerechtigd"),
        "email": MessageLookupByLibrary.simpleMessage("E-mail"),
        "emailAlreadyRegistered":
            MessageLookupByLibrary.simpleMessage("E-mail is al geregistreerd."),
        "emailChangedTo": m29,
        "emailDoesNotHaveEnteAccount": m30,
        "emailNoEnteAccount": m31,
        "emailNotRegistered":
            MessageLookupByLibrary.simpleMessage("E-mail niet geregistreerd."),
        "emailVerificationToggle":
            MessageLookupByLibrary.simpleMessage("E-mailverificatie"),
        "emailYourLogs":
            MessageLookupByLibrary.simpleMessage("E-mail uw logboeken"),
        "embracingThem": m32,
        "emergencyContacts":
            MessageLookupByLibrary.simpleMessage("Noodcontacten"),
        "empty": MessageLookupByLibrary.simpleMessage("Leeg"),
        "emptyTrash":
            MessageLookupByLibrary.simpleMessage("Prullenbak leegmaken?"),
        "enable": MessageLookupByLibrary.simpleMessage("Inschakelen"),
        "enableMLIndexingDesc": MessageLookupByLibrary.simpleMessage(
            "Ente ondersteunt on-device machine learning voor gezichtsherkenning, magisch zoeken en andere geavanceerde zoekfuncties"),
        "enableMachineLearningBanner": MessageLookupByLibrary.simpleMessage(
            "Schakel machine learning in voor magische zoekopdrachten en gezichtsherkenning"),
        "enableMaps":
            MessageLookupByLibrary.simpleMessage("Kaarten inschakelen"),
        "enableMapsDesc": MessageLookupByLibrary.simpleMessage(
            "Dit toont jouw foto\'s op een wereldkaart.\n\nDeze kaart wordt gehost door Open Street Map, en de exacte locaties van jouw foto\'s worden nooit gedeeld.\n\nJe kunt deze functie op elk gewenst moment uitschakelen via de instellingen."),
        "enabled": MessageLookupByLibrary.simpleMessage("Ingeschakeld"),
        "encryptingBackup":
            MessageLookupByLibrary.simpleMessage("Back-up versleutelen..."),
        "encryption": MessageLookupByLibrary.simpleMessage("Encryptie"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Encryptiesleutels"),
        "endpointUpdatedMessage": MessageLookupByLibrary.simpleMessage(
            "Eindpunt met succes bijgewerkt"),
        "endtoendEncryptedByDefault": MessageLookupByLibrary.simpleMessage(
            "Standaard end-to-end versleuteld"),
        "enteCanEncryptAndPreserveFilesOnlyIfYouGrant":
            MessageLookupByLibrary.simpleMessage(
                "Ente kan bestanden alleen versleutelen en bewaren als u toegang tot ze geeft"),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
            "Ente <i>heeft toestemming nodig om</i> je foto\'s te bewaren"),
        "enteSubscriptionPitch": MessageLookupByLibrary.simpleMessage(
            "Ente bewaart uw herinneringen, zodat ze altijd beschikbaar voor u zijn, zelfs als u uw apparaat verliest."),
        "enteSubscriptionShareWithFamily": MessageLookupByLibrary.simpleMessage(
            "Je familie kan ook aan je abonnement worden toegevoegd."),
        "enterAlbumName":
            MessageLookupByLibrary.simpleMessage("Voer albumnaam in"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Voer code in"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
            "Voer de code van de vriend in om gratis opslag voor jullie beiden te claimen"),
        "enterDateOfBirth":
            MessageLookupByLibrary.simpleMessage("Verjaardag (optioneel)"),
        "enterEmail":
            MessageLookupByLibrary.simpleMessage("Voer e-mailadres in"),
        "enterFileName":
            MessageLookupByLibrary.simpleMessage("Geef bestandsnaam op"),
        "enterName": MessageLookupByLibrary.simpleMessage("Naam invoeren"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Voer een nieuw wachtwoord in dat we kunnen gebruiken om je gegevens te versleutelen"),
        "enterPassword":
            MessageLookupByLibrary.simpleMessage("Voer wachtwoord in"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Voer een wachtwoord in dat we kunnen gebruiken om je gegevens te versleutelen"),
        "enterPersonName":
            MessageLookupByLibrary.simpleMessage("Naam van persoon invoeren"),
        "enterPin": MessageLookupByLibrary.simpleMessage("PIN invoeren"),
        "enterReferralCode":
            MessageLookupByLibrary.simpleMessage("Voer verwijzingscode in"),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Voer de 6-cijferige code van je verificatie-app in"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "Voer een geldig e-mailadres in."),
        "enterYourEmailAddress":
            MessageLookupByLibrary.simpleMessage("Voer je e-mailadres in"),
        "enterYourNewEmailAddress": MessageLookupByLibrary.simpleMessage(
            "Voer uw nieuwe e-mailadres in"),
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
        "extraPhotosFound":
            MessageLookupByLibrary.simpleMessage("Extra foto\'s gevonden"),
        "extraPhotosFoundFor": m33,
        "faceNotClusteredYet": MessageLookupByLibrary.simpleMessage(
            "Gezicht nog niet geclusterd, kom later terug"),
        "faceRecognition":
            MessageLookupByLibrary.simpleMessage("Gezichtsherkenning"),
        "faces": MessageLookupByLibrary.simpleMessage("Gezichten"),
        "failed": MessageLookupByLibrary.simpleMessage("Mislukt"),
        "failedToApplyCode":
            MessageLookupByLibrary.simpleMessage("Code toepassen mislukt"),
        "failedToCancel":
            MessageLookupByLibrary.simpleMessage("Opzeggen mislukt"),
        "failedToDownloadVideo": MessageLookupByLibrary.simpleMessage(
            "Downloaden van video mislukt"),
        "failedToFetchActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Ophalen van actieve sessies mislukt"),
        "failedToFetchOriginalForEdit": MessageLookupByLibrary.simpleMessage(
            "Fout bij ophalen origineel voor bewerking"),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "Kan geen verwijzingsgegevens ophalen. Probeer het later nog eens."),
        "failedToLoadAlbums":
            MessageLookupByLibrary.simpleMessage("Laden van albums mislukt"),
        "failedToPlayVideo":
            MessageLookupByLibrary.simpleMessage("Afspelen van video mislukt"),
        "failedToRefreshStripeSubscription":
            MessageLookupByLibrary.simpleMessage(
                "Abonnement vernieuwen mislukt"),
        "failedToRenew":
            MessageLookupByLibrary.simpleMessage("Verlengen mislukt"),
        "failedToVerifyPaymentStatus": MessageLookupByLibrary.simpleMessage(
            "Betalingsstatus verifiëren mislukt"),
        "familyPlanOverview": MessageLookupByLibrary.simpleMessage(
            "Voeg 5 gezinsleden toe aan je bestaande abonnement zonder extra te betalen.\n\nElk lid krijgt zijn eigen privé ruimte en kan elkaars bestanden niet zien tenzij ze zijn gedeeld.\n\nFamilieplannen zijn beschikbaar voor klanten die een betaald Ente abonnement hebben.\n\nAbonneer nu om aan de slag te gaan!"),
        "familyPlanPortalTitle":
            MessageLookupByLibrary.simpleMessage("Familie"),
        "familyPlans":
            MessageLookupByLibrary.simpleMessage("Familie abonnement"),
        "faq": MessageLookupByLibrary.simpleMessage("Veelgestelde vragen"),
        "faqs": MessageLookupByLibrary.simpleMessage("Veelgestelde vragen"),
        "favorite":
            MessageLookupByLibrary.simpleMessage("Toevoegen aan favorieten"),
        "feastingWithThem": m34,
        "feedback": MessageLookupByLibrary.simpleMessage("Feedback"),
        "file": MessageLookupByLibrary.simpleMessage("Bestand"),
        "fileFailedToSaveToGallery": MessageLookupByLibrary.simpleMessage(
            "Opslaan van bestand naar galerij mislukt"),
        "fileInfoAddDescHint": MessageLookupByLibrary.simpleMessage(
            "Voeg een beschrijving toe..."),
        "fileNotUploadedYet":
            MessageLookupByLibrary.simpleMessage("Bestand nog niet geüpload"),
        "fileSavedToGallery": MessageLookupByLibrary.simpleMessage(
            "Bestand opgeslagen in galerij"),
        "fileTypes": MessageLookupByLibrary.simpleMessage("Bestandstype"),
        "fileTypesAndNames":
            MessageLookupByLibrary.simpleMessage("Bestandstypen en namen"),
        "filesBackedUpFromDevice": m35,
        "filesBackedUpInAlbum": m36,
        "filesDeleted":
            MessageLookupByLibrary.simpleMessage("Bestanden verwijderd"),
        "filesSavedToGallery": MessageLookupByLibrary.simpleMessage(
            "Bestand opgeslagen in galerij"),
        "findPeopleByName":
            MessageLookupByLibrary.simpleMessage("Mensen snel op naam zoeken"),
        "findThemQuickly": MessageLookupByLibrary.simpleMessage("Vind ze snel"),
        "flip": MessageLookupByLibrary.simpleMessage("Omdraaien"),
        "food": MessageLookupByLibrary.simpleMessage("Culinaire vreugde"),
        "forYourMemories":
            MessageLookupByLibrary.simpleMessage("voor uw herinneringen"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Wachtwoord vergeten"),
        "foundFaces":
            MessageLookupByLibrary.simpleMessage("Gezichten gevonden"),
        "freeStorageClaimed":
            MessageLookupByLibrary.simpleMessage("Gratis opslag geclaimd"),
        "freeStorageOnReferralSuccess": m37,
        "freeStorageUsable":
            MessageLookupByLibrary.simpleMessage("Gratis opslag bruikbaar"),
        "freeTrial": MessageLookupByLibrary.simpleMessage("Gratis proefversie"),
        "freeTrialValidTill": m38,
        "freeUpAccessPostDelete": m39,
        "freeUpAmount": m40,
        "freeUpDeviceSpace":
            MessageLookupByLibrary.simpleMessage("Apparaatruimte vrijmaken"),
        "freeUpDeviceSpaceDesc": MessageLookupByLibrary.simpleMessage(
            "Bespaar ruimte op je apparaat door bestanden die al geback-upt zijn te wissen."),
        "freeUpSpace": MessageLookupByLibrary.simpleMessage("Ruimte vrijmaken"),
        "freeUpSpaceSaving": m41,
        "gallery": MessageLookupByLibrary.simpleMessage("Galerij"),
        "galleryMemoryLimitInfo": MessageLookupByLibrary.simpleMessage(
            "Tot 1000 herinneringen getoond in de galerij"),
        "general": MessageLookupByLibrary.simpleMessage("Algemeen"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Encryptiesleutels genereren..."),
        "genericProgress": m42,
        "goToSettings":
            MessageLookupByLibrary.simpleMessage("Ga naar instellingen"),
        "googlePlayId": MessageLookupByLibrary.simpleMessage("Google Play ID"),
        "grantFullAccessPrompt": MessageLookupByLibrary.simpleMessage(
            "Geef toegang tot alle foto\'s in de Instellingen app"),
        "grantPermission":
            MessageLookupByLibrary.simpleMessage("Toestemming verlenen"),
        "greenery": MessageLookupByLibrary.simpleMessage("Het groene leven"),
        "groupNearbyPhotos":
            MessageLookupByLibrary.simpleMessage("Groep foto\'s in de buurt"),
        "guestView": MessageLookupByLibrary.simpleMessage("Gasten weergave"),
        "guestViewEnablePreSteps": MessageLookupByLibrary.simpleMessage(
            "Om gasten weergave in te schakelen, moet u een toegangscode of schermvergrendeling instellen in uw systeeminstellingen."),
        "hearUsExplanation": MessageLookupByLibrary.simpleMessage(
            "Wij gebruiken geen tracking. Het zou helpen als je ons vertelt waar je ons gevonden hebt!"),
        "hearUsWhereTitle": MessageLookupByLibrary.simpleMessage(
            "Hoe hoorde je over Ente? (optioneel)"),
        "help": MessageLookupByLibrary.simpleMessage("Hulp"),
        "hidden": MessageLookupByLibrary.simpleMessage("Verborgen"),
        "hide": MessageLookupByLibrary.simpleMessage("Verbergen"),
        "hideContent": MessageLookupByLibrary.simpleMessage("Inhoud verbergen"),
        "hideContentDescriptionAndroid": MessageLookupByLibrary.simpleMessage(
            "Verbergt app-inhoud in de app-schakelaar en schakelt schermopnamen uit"),
        "hideContentDescriptionIos": MessageLookupByLibrary.simpleMessage(
            "Verbergt de inhoud van de app in de app-schakelaar"),
        "hideSharedItemsFromHomeGallery": MessageLookupByLibrary.simpleMessage(
            "Verberg gedeelde bestanden uit de galerij"),
        "hiding": MessageLookupByLibrary.simpleMessage("Verbergen..."),
        "hikingWithThem": m43,
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
        "ignored": MessageLookupByLibrary.simpleMessage("genegeerd"),
        "ignoredFolderUploadReason": MessageLookupByLibrary.simpleMessage(
            "Sommige bestanden in dit album worden genegeerd voor uploaden omdat ze eerder van Ente zijn verwijderd."),
        "imageNotAnalyzed": MessageLookupByLibrary.simpleMessage(
            "Afbeelding niet geanalyseerd"),
        "immediately": MessageLookupByLibrary.simpleMessage("Onmiddellijk"),
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
        "indexingIsPaused": MessageLookupByLibrary.simpleMessage(
            "Indexeren is gepauzeerd. Het zal automatisch hervatten wanneer het apparaat klaar is."),
        "ineligible": MessageLookupByLibrary.simpleMessage("Ongerechtigd"),
        "info": MessageLookupByLibrary.simpleMessage("Info"),
        "insecureDevice":
            MessageLookupByLibrary.simpleMessage("Onveilig apparaat"),
        "installManually":
            MessageLookupByLibrary.simpleMessage("Installeer handmatig"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("Ongeldig e-mailadres"),
        "invalidEndpoint":
            MessageLookupByLibrary.simpleMessage("Ongeldig eindpunt"),
        "invalidEndpointMessage": MessageLookupByLibrary.simpleMessage(
            "Sorry, het eindpunt dat je hebt ingevoerd is ongeldig. Voer een geldig eindpunt in en probeer het opnieuw."),
        "invalidKey": MessageLookupByLibrary.simpleMessage("Ongeldige sleutel"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "De herstelsleutel die je hebt ingevoerd is niet geldig. Zorg ervoor dat deze 24 woorden bevat en controleer de spelling van elk van deze woorden.\n\nAls je een oudere herstelcode hebt ingevoerd, zorg ervoor dat deze 64 tekens lang is, en controleer ze allemaal."),
        "invite": MessageLookupByLibrary.simpleMessage("Uitnodigen"),
        "inviteToEnte":
            MessageLookupByLibrary.simpleMessage("Uitnodigen voor Ente"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Vrienden uitnodigen"),
        "inviteYourFriendsToEnte": MessageLookupByLibrary.simpleMessage(
            "Vrienden uitnodigen voor Ente"),
        "itLooksLikeSomethingWentWrongPleaseRetryAfterSome":
            MessageLookupByLibrary.simpleMessage(
                "Het lijkt erop dat er iets fout is gegaan. Probeer het later opnieuw. Als de fout zich blijft voordoen, neem dan contact op met ons supportteam."),
        "itemCount": m44,
        "itemsShowTheNumberOfDaysRemainingBeforePermanentDeletion":
            MessageLookupByLibrary.simpleMessage(
                "Bestanden tonen het aantal resterende dagen voordat ze permanent worden verwijderd"),
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "Geselecteerde items zullen worden verwijderd uit dit album"),
        "join": MessageLookupByLibrary.simpleMessage("Deelnemen"),
        "joinAlbum":
            MessageLookupByLibrary.simpleMessage("Deelnemen aan album"),
        "joinAlbumConfirmationDialogBody": MessageLookupByLibrary.simpleMessage(
            "Deelnemen aan een album maakt je e-mail zichtbaar voor de deelnemers."),
        "joinAlbumSubtext": MessageLookupByLibrary.simpleMessage(
            "om je foto\'s te bekijken en toe te voegen"),
        "joinAlbumSubtextViewer": MessageLookupByLibrary.simpleMessage(
            "om dit aan gedeelde albums toe te voegen"),
        "joinDiscord": MessageLookupByLibrary.simpleMessage("Join de Discord"),
        "keepPhotos": MessageLookupByLibrary.simpleMessage("Foto\'s behouden"),
        "kiloMeterUnit": MessageLookupByLibrary.simpleMessage("km"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Help ons alsjeblieft met deze informatie"),
        "language": MessageLookupByLibrary.simpleMessage("Taal"),
        "lastTimeWithThem": m45,
        "lastUpdated": MessageLookupByLibrary.simpleMessage("Laatst gewijzigd"),
        "lastYearsTrip":
            MessageLookupByLibrary.simpleMessage("Reis van vorig jaar"),
        "leave": MessageLookupByLibrary.simpleMessage("Verlaten"),
        "leaveAlbum": MessageLookupByLibrary.simpleMessage("Album verlaten"),
        "leaveFamily":
            MessageLookupByLibrary.simpleMessage("Familie abonnement verlaten"),
        "leaveSharedAlbum":
            MessageLookupByLibrary.simpleMessage("Gedeeld album verlaten?"),
        "left": MessageLookupByLibrary.simpleMessage("Links"),
        "legacy": MessageLookupByLibrary.simpleMessage("Legacy"),
        "legacyAccounts":
            MessageLookupByLibrary.simpleMessage("Legacy accounts"),
        "legacyInvite": m46,
        "legacyPageDesc": MessageLookupByLibrary.simpleMessage(
            "Legacy geeft vertrouwde contacten toegang tot je account bij afwezigheid."),
        "legacyPageDesc2": MessageLookupByLibrary.simpleMessage(
            "Vertrouwde contacten kunnen accountherstel starten, en indien deze niet binnen 30 dagen wordt geblokkeerd, je wachtwoord resetten en toegang krijgen tot je account."),
        "light": MessageLookupByLibrary.simpleMessage("Licht"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("Licht"),
        "link": MessageLookupByLibrary.simpleMessage("Link"),
        "linkCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Link gekopieerd naar klembord"),
        "linkDeviceLimit":
            MessageLookupByLibrary.simpleMessage("Apparaat limiet"),
        "linkEmail": MessageLookupByLibrary.simpleMessage("Link email"),
        "linkEmailToContactBannerCaption":
            MessageLookupByLibrary.simpleMessage("voor sneller delen"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Ingeschakeld"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Verlopen"),
        "linkExpiresOn": m47,
        "linkExpiry": MessageLookupByLibrary.simpleMessage("Vervaldatum"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("Link is vervallen"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Nooit"),
        "linkPerson": MessageLookupByLibrary.simpleMessage("Link persoon"),
        "linkPersonCaption": MessageLookupByLibrary.simpleMessage(
            "voor een betere ervaring met delen"),
        "linkPersonToEmail": m48,
        "linkPersonToEmailConfirmation": m49,
        "livePhotos": MessageLookupByLibrary.simpleMessage("Live foto"),
        "loadMessage1": MessageLookupByLibrary.simpleMessage(
            "U kunt uw abonnement met uw familie delen"),
        "loadMessage2": MessageLookupByLibrary.simpleMessage(
            "We hebben tot nu toe meer dan 200 miljoen herinneringen bewaard"),
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
        "loadingYourPhotos": MessageLookupByLibrary.simpleMessage(
            "Je foto\'s worden geladen..."),
        "localGallery": MessageLookupByLibrary.simpleMessage("Lokale galerij"),
        "localIndexing":
            MessageLookupByLibrary.simpleMessage("Lokaal indexeren"),
        "localSyncErrorMessage": MessageLookupByLibrary.simpleMessage(
            "Het lijkt erop dat er iets mis is gegaan omdat het synchroniseren van lokale foto\'s meer tijd kost dan verwacht. Neem contact op met ons supportteam"),
        "location": MessageLookupByLibrary.simpleMessage("Locatie"),
        "locationName": MessageLookupByLibrary.simpleMessage("Locatie naam"),
        "locationTagFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "Een locatie tag groept alle foto\'s die binnen een bepaalde straal van een foto zijn genomen"),
        "locations": MessageLookupByLibrary.simpleMessage("Locaties"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Vergrendel"),
        "lockscreen": MessageLookupByLibrary.simpleMessage("Vergrendelscherm"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Inloggen"),
        "loggingOut": MessageLookupByLibrary.simpleMessage("Uitloggen..."),
        "loginSessionExpired":
            MessageLookupByLibrary.simpleMessage("Sessie verlopen"),
        "loginSessionExpiredDetails": MessageLookupByLibrary.simpleMessage(
            "Jouw sessie is verlopen. Log opnieuw in."),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "Door op inloggen te klikken, ga ik akkoord met de <u-terms>gebruiksvoorwaarden</u-terms> en <u-policy>privacybeleid</u-policy>"),
        "loginWithTOTP":
            MessageLookupByLibrary.simpleMessage("Inloggen met TOTP"),
        "logout": MessageLookupByLibrary.simpleMessage("Uitloggen"),
        "logsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Dit zal logboeken verzenden om ons te helpen uw probleem op te lossen. Houd er rekening mee dat bestandsnamen zullen worden meegenomen om problemen met specifieke bestanden bij te houden."),
        "longPressAnEmailToVerifyEndToEndEncryption":
            MessageLookupByLibrary.simpleMessage(
                "Druk lang op een e-mail om de versleuteling te verifiëren."),
        "longpressOnAnItemToViewInFullscreen": MessageLookupByLibrary.simpleMessage(
            "Houd een bestand lang ingedrukt om te bekijken op volledig scherm"),
        "lookBackOnYourMemories": MessageLookupByLibrary.simpleMessage(
            "Kijk terug op je herinneringen 🌄"),
        "loopVideoOff":
            MessageLookupByLibrary.simpleMessage("Video in lus afspelen uit"),
        "loopVideoOn":
            MessageLookupByLibrary.simpleMessage("Video in lus afspelen aan"),
        "lostDevice":
            MessageLookupByLibrary.simpleMessage("Apparaat verloren?"),
        "machineLearning":
            MessageLookupByLibrary.simpleMessage("Machine Learning"),
        "magicSearch":
            MessageLookupByLibrary.simpleMessage("Magische zoekfunctie"),
        "magicSearchHint": MessageLookupByLibrary.simpleMessage(
            "Magisch zoeken maakt het mogelijk om foto\'s op hun inhoud worden gezocht, bijvoorbeeld \"bloem\", \"rode auto\", \"identiteitsdocumenten\""),
        "manage": MessageLookupByLibrary.simpleMessage("Beheren"),
        "manageDeviceStorage":
            MessageLookupByLibrary.simpleMessage("Apparaatcache beheren"),
        "manageDeviceStorageDesc": MessageLookupByLibrary.simpleMessage(
            "Bekijk en wis lokale cache opslag."),
        "manageFamily":
            MessageLookupByLibrary.simpleMessage("Familie abonnement beheren"),
        "manageLink": MessageLookupByLibrary.simpleMessage("Beheer link"),
        "manageParticipants": MessageLookupByLibrary.simpleMessage("Beheren"),
        "manageSubscription":
            MessageLookupByLibrary.simpleMessage("Abonnement beheren"),
        "manualPairDesc": MessageLookupByLibrary.simpleMessage(
            "Koppelen met de PIN werkt met elk scherm waarop je jouw album wilt zien."),
        "map": MessageLookupByLibrary.simpleMessage("Kaart"),
        "maps": MessageLookupByLibrary.simpleMessage("Kaarten"),
        "mastodon": MessageLookupByLibrary.simpleMessage("Mastodon"),
        "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
        "me": MessageLookupByLibrary.simpleMessage("Ik"),
        "memories": MessageLookupByLibrary.simpleMessage("Herinneringen"),
        "memoriesWidgetDesc": MessageLookupByLibrary.simpleMessage(
            "Selecteer het soort herinneringen dat je wilt zien op je beginscherm."),
        "memoryCount": m50,
        "merchandise": MessageLookupByLibrary.simpleMessage("Merchandise"),
        "mergeWithExisting":
            MessageLookupByLibrary.simpleMessage("Samenvoegen met bestaand"),
        "mergedPhotos":
            MessageLookupByLibrary.simpleMessage("Samengevoegde foto\'s"),
        "mlConsent":
            MessageLookupByLibrary.simpleMessage("Schakel machine learning in"),
        "mlConsentConfirmation": MessageLookupByLibrary.simpleMessage(
            "Ik begrijp het, en wil machine learning inschakelen"),
        "mlConsentDescription": MessageLookupByLibrary.simpleMessage(
            "Als u machine learning inschakelt, zal Ente informatie zoals gezichtsgeometrie uit bestanden extraheren, inclusief degenen die met u gedeeld worden.\n\nDit gebeurt op uw apparaat, en alle gegenereerde biometrische informatie zal end-to-end versleuteld worden."),
        "mlConsentPrivacy": MessageLookupByLibrary.simpleMessage(
            "Klik hier voor meer details over deze functie in ons privacybeleid."),
        "mlConsentTitle": MessageLookupByLibrary.simpleMessage(
            "Machine learning inschakelen?"),
        "mlIndexingDescription": MessageLookupByLibrary.simpleMessage(
            "Houd er rekening mee dat machine learning zal leiden tot hoger bandbreedte- en batterijgebruik totdat alle items geïndexeerd zijn. Overweeg het gebruik van de desktop app voor snellere indexering. Alle resultaten worden automatisch gesynchroniseerd."),
        "mobileWebDesktop":
            MessageLookupByLibrary.simpleMessage("Mobiel, Web, Desktop"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Matig"),
        "modifyYourQueryOrTrySearchingFor":
            MessageLookupByLibrary.simpleMessage(
                "Pas je zoekopdracht aan of zoek naar"),
        "moments": MessageLookupByLibrary.simpleMessage("Momenten"),
        "month": MessageLookupByLibrary.simpleMessage("maand"),
        "monthly": MessageLookupByLibrary.simpleMessage("Maandelijks"),
        "moon": MessageLookupByLibrary.simpleMessage("In het maanlicht"),
        "moreDetails": MessageLookupByLibrary.simpleMessage("Meer details"),
        "mostRecent": MessageLookupByLibrary.simpleMessage("Meest recent"),
        "mostRelevant": MessageLookupByLibrary.simpleMessage("Meest relevant"),
        "mountains": MessageLookupByLibrary.simpleMessage("Over de heuvels"),
        "moveItem": m51,
        "moveSelectedPhotosToOneDate": MessageLookupByLibrary.simpleMessage(
            "Verplaats de geselecteerde foto\'s naar één datum"),
        "moveToAlbum":
            MessageLookupByLibrary.simpleMessage("Verplaats naar album"),
        "moveToHiddenAlbum": MessageLookupByLibrary.simpleMessage(
            "Verplaatsen naar verborgen album"),
        "movedSuccessfullyTo": m52,
        "movedToTrash":
            MessageLookupByLibrary.simpleMessage("Naar prullenbak verplaatst"),
        "movingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Bestanden verplaatsen naar album..."),
        "name": MessageLookupByLibrary.simpleMessage("Naam"),
        "nameTheAlbum": MessageLookupByLibrary.simpleMessage("Album benoemen"),
        "networkConnectionRefusedErr": MessageLookupByLibrary.simpleMessage(
            "Kan geen verbinding maken met Ente, probeer het later opnieuw. Als de fout zich blijft voordoen, neem dan contact op met support."),
        "networkHostLookUpErr": MessageLookupByLibrary.simpleMessage(
            "Kan geen verbinding maken met Ente, controleer uw netwerkinstellingen en neem contact op met ondersteuning als de fout zich blijft voordoen."),
        "never": MessageLookupByLibrary.simpleMessage("Nooit"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Nieuw album"),
        "newLocation": MessageLookupByLibrary.simpleMessage("Nieuwe locatie"),
        "newPerson": MessageLookupByLibrary.simpleMessage("Nieuw persoon"),
        "newPhotosEmoji": MessageLookupByLibrary.simpleMessage(" nieuwe 📸"),
        "newRange": MessageLookupByLibrary.simpleMessage("Nieuwe reeks"),
        "newToEnte": MessageLookupByLibrary.simpleMessage("Nieuw bij Ente"),
        "newest": MessageLookupByLibrary.simpleMessage("Nieuwste"),
        "next": MessageLookupByLibrary.simpleMessage("Volgende"),
        "no": MessageLookupByLibrary.simpleMessage("Nee"),
        "noAlbumsSharedByYouYet": MessageLookupByLibrary.simpleMessage(
            "Nog geen albums gedeeld door jou"),
        "noDeviceFound":
            MessageLookupByLibrary.simpleMessage("Geen apparaat gevonden"),
        "noDeviceLimit": MessageLookupByLibrary.simpleMessage("Geen"),
        "noDeviceThatCanBeDeleted": MessageLookupByLibrary.simpleMessage(
            "Je hebt geen bestanden op dit apparaat die verwijderd kunnen worden"),
        "noDuplicates":
            MessageLookupByLibrary.simpleMessage("✨ Geen duplicaten"),
        "noEnteAccountExclamation":
            MessageLookupByLibrary.simpleMessage("Geen Ente account!"),
        "noExifData":
            MessageLookupByLibrary.simpleMessage("Geen EXIF gegevens"),
        "noFacesFound":
            MessageLookupByLibrary.simpleMessage("Geen gezichten gevonden"),
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
        "noQuickLinksSelected": MessageLookupByLibrary.simpleMessage(
            "Geen snelle links geselecteerd"),
        "noRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Geen herstelcode?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "Door de aard van ons end-to-end encryptieprotocol kunnen je gegevens niet worden ontsleuteld zonder je wachtwoord of herstelsleutel"),
        "noResults": MessageLookupByLibrary.simpleMessage("Geen resultaten"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("Geen resultaten gevonden"),
        "noSuggestionsForPerson": m53,
        "noSystemLockFound": MessageLookupByLibrary.simpleMessage(
            "Geen systeemvergrendeling gevonden"),
        "notPersonLabel": m54,
        "notThisPerson":
            MessageLookupByLibrary.simpleMessage("Niet dezelfde persoon?"),
        "nothingSharedWithYouYet":
            MessageLookupByLibrary.simpleMessage("Nog niets met je gedeeld"),
        "nothingToSeeHere":
            MessageLookupByLibrary.simpleMessage("Nog niets te zien hier! 👀"),
        "notifications": MessageLookupByLibrary.simpleMessage("Meldingen"),
        "ok": MessageLookupByLibrary.simpleMessage("Oké"),
        "onDevice": MessageLookupByLibrary.simpleMessage("Op het apparaat"),
        "onEnte": MessageLookupByLibrary.simpleMessage(
            "Op <branding>ente</branding>"),
        "onTheRoad": MessageLookupByLibrary.simpleMessage("Onderweg"),
        "onThisDay": MessageLookupByLibrary.simpleMessage("Op deze dag"),
        "onThisDayMemories":
            MessageLookupByLibrary.simpleMessage("Op deze dag herinneringen"),
        "onThisDayNotificationExplanation": MessageLookupByLibrary.simpleMessage(
            "Ontvang meldingen over herinneringen op deze dag door de jaren heen."),
        "onlyFamilyAdminCanChangeCode": m55,
        "onlyThem": MessageLookupByLibrary.simpleMessage("Alleen hen"),
        "oops": MessageLookupByLibrary.simpleMessage("Oeps"),
        "oopsCouldNotSaveEdits": MessageLookupByLibrary.simpleMessage(
            "Oeps, kon bewerkingen niet opslaan"),
        "oopsSomethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Oeps, er is iets misgegaan"),
        "openAlbumInBrowser":
            MessageLookupByLibrary.simpleMessage("Open album in browser"),
        "openAlbumInBrowserTitle": MessageLookupByLibrary.simpleMessage(
            "Gebruik de webapp om foto\'s aan dit album toe te voegen"),
        "openFile": MessageLookupByLibrary.simpleMessage("Bestand openen"),
        "openSettings":
            MessageLookupByLibrary.simpleMessage("Instellingen openen"),
        "openTheItem": MessageLookupByLibrary.simpleMessage("• Open het item"),
        "openstreetmapContributors":
            MessageLookupByLibrary.simpleMessage("OpenStreetMap bijdragers"),
        "optionalAsShortAsYouLike": MessageLookupByLibrary.simpleMessage(
            "Optioneel, zo kort als je wilt..."),
        "orMergeWithExistingPerson": MessageLookupByLibrary.simpleMessage(
            "Of samenvoegen met bestaande"),
        "orPickAnExistingOne":
            MessageLookupByLibrary.simpleMessage("Of kies een bestaande"),
        "orPickFromYourContacts":
            MessageLookupByLibrary.simpleMessage("of kies uit je contacten"),
        "pair": MessageLookupByLibrary.simpleMessage("Koppelen"),
        "pairWithPin": MessageLookupByLibrary.simpleMessage("Koppelen met PIN"),
        "pairingComplete":
            MessageLookupByLibrary.simpleMessage("Koppeling voltooid"),
        "panorama": MessageLookupByLibrary.simpleMessage("Panorama"),
        "partyWithThem": m56,
        "passKeyPendingVerification": MessageLookupByLibrary.simpleMessage(
            "Verificatie is nog in behandeling"),
        "passkey": MessageLookupByLibrary.simpleMessage("Passkey"),
        "passkeyAuthTitle":
            MessageLookupByLibrary.simpleMessage("Passkey verificatie"),
        "password": MessageLookupByLibrary.simpleMessage("Wachtwoord"),
        "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
            "Wachtwoord succesvol aangepast"),
        "passwordLock": MessageLookupByLibrary.simpleMessage("Wachtwoord slot"),
        "passwordStrength": m57,
        "passwordStrengthInfo": MessageLookupByLibrary.simpleMessage(
            "De wachtwoordsterkte wordt berekend aan de hand van de lengte van het wachtwoord, de gebruikte tekens en of het wachtwoord al dan niet in de top 10.000 van meest gebruikte wachtwoorden staat"),
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Wij slaan dit wachtwoord niet op, dus als je het vergeet, kunnen <underline>we je gegevens niet ontsleutelen</underline>"),
        "pastYearsMemories":
            MessageLookupByLibrary.simpleMessage("Afgelopen jaren"),
        "paymentDetails":
            MessageLookupByLibrary.simpleMessage("Betaalgegevens"),
        "paymentFailed":
            MessageLookupByLibrary.simpleMessage("Betaling mislukt"),
        "paymentFailedMessage": MessageLookupByLibrary.simpleMessage(
            "Helaas is je betaling mislukt. Neem contact op met support zodat we je kunnen helpen!"),
        "paymentFailedTalkToProvider": m58,
        "pendingItems":
            MessageLookupByLibrary.simpleMessage("Bestanden in behandeling"),
        "pendingSync": MessageLookupByLibrary.simpleMessage(
            "Synchronisatie in behandeling"),
        "people": MessageLookupByLibrary.simpleMessage("Personen"),
        "peopleUsingYourCode": MessageLookupByLibrary.simpleMessage(
            "Mensen die jouw code gebruiken"),
        "peopleWidgetDesc": MessageLookupByLibrary.simpleMessage(
            "Selecteer de mensen die je wilt zien op je beginscherm."),
        "permDeleteWarning": MessageLookupByLibrary.simpleMessage(
            "Alle bestanden in de prullenbak zullen permanent worden verwijderd\n\nDeze actie kan niet ongedaan worden gemaakt"),
        "permanentlyDelete":
            MessageLookupByLibrary.simpleMessage("Permanent verwijderen"),
        "permanentlyDeleteFromDevice": MessageLookupByLibrary.simpleMessage(
            "Permanent verwijderen van apparaat?"),
        "personIsAge": m59,
        "personName": MessageLookupByLibrary.simpleMessage("Naam van persoon"),
        "personTurningAge": m60,
        "pets": MessageLookupByLibrary.simpleMessage("Harige kameraden"),
        "photoDescriptions":
            MessageLookupByLibrary.simpleMessage("Foto beschrijvingen"),
        "photoGridSize":
            MessageLookupByLibrary.simpleMessage("Foto raster grootte"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("foto"),
        "photocountPhotos": m61,
        "photos": MessageLookupByLibrary.simpleMessage("Foto\'s"),
        "photosAddedByYouWillBeRemovedFromTheAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Foto\'s toegevoegd door u zullen worden verwijderd uit het album"),
        "photosCount": m62,
        "photosKeepRelativeTimeDifference":
            MessageLookupByLibrary.simpleMessage(
                "Foto\'s behouden relatief tijdsverschil"),
        "pickCenterPoint":
            MessageLookupByLibrary.simpleMessage("Kies middelpunt"),
        "pinAlbum":
            MessageLookupByLibrary.simpleMessage("Album bovenaan vastzetten"),
        "pinLock": MessageLookupByLibrary.simpleMessage("PIN vergrendeling"),
        "playOnTv":
            MessageLookupByLibrary.simpleMessage("Album afspelen op TV"),
        "playOriginal":
            MessageLookupByLibrary.simpleMessage("Origineel afspelen"),
        "playStoreFreeTrialValidTill": m63,
        "playStream": MessageLookupByLibrary.simpleMessage("Stream afspelen"),
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
        "pleaseEmailUsAt": m64,
        "pleaseGrantPermissions": MessageLookupByLibrary.simpleMessage(
            "Geef alstublieft toestemming"),
        "pleaseLoginAgain":
            MessageLookupByLibrary.simpleMessage("Log opnieuw in"),
        "pleaseSelectQuickLinksToRemove": MessageLookupByLibrary.simpleMessage(
            "Selecteer snelle links om te verwijderen"),
        "pleaseSendTheLogsTo": m65,
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
        "pleaseWaitThisWillTakeAWhile": MessageLookupByLibrary.simpleMessage(
            "Een ogenblik geduld, dit zal even duren."),
        "posingWithThem": m66,
        "preparingLogs":
            MessageLookupByLibrary.simpleMessage("Logboeken voorbereiden..."),
        "preserveMore": MessageLookupByLibrary.simpleMessage("Meer bewaren"),
        "pressAndHoldToPlayVideo": MessageLookupByLibrary.simpleMessage(
            "Ingedrukt houden om video af te spelen"),
        "pressAndHoldToPlayVideoDetailed": MessageLookupByLibrary.simpleMessage(
            "Houd de afbeelding ingedrukt om video af te spelen"),
        "previous": MessageLookupByLibrary.simpleMessage("Vorige"),
        "privacy": MessageLookupByLibrary.simpleMessage("Privacy"),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Privacybeleid"),
        "privateBackups":
            MessageLookupByLibrary.simpleMessage("Privé back-ups"),
        "privateSharing": MessageLookupByLibrary.simpleMessage("Privé delen"),
        "proceed": MessageLookupByLibrary.simpleMessage("Verder"),
        "processed": MessageLookupByLibrary.simpleMessage("Verwerkt"),
        "processing": MessageLookupByLibrary.simpleMessage("Verwerken"),
        "processingImport": m67,
        "processingVideos":
            MessageLookupByLibrary.simpleMessage("Video\'s verwerken"),
        "publicLinkCreated":
            MessageLookupByLibrary.simpleMessage("Publieke link aangemaakt"),
        "publicLinkEnabled":
            MessageLookupByLibrary.simpleMessage("Publieke link ingeschakeld"),
        "queued": MessageLookupByLibrary.simpleMessage("In wachtrij"),
        "quickLinks": MessageLookupByLibrary.simpleMessage("Snelle links"),
        "radius": MessageLookupByLibrary.simpleMessage("Straal"),
        "raiseTicket": MessageLookupByLibrary.simpleMessage("Meld probleem"),
        "rateTheApp": MessageLookupByLibrary.simpleMessage("Beoordeel de app"),
        "rateUs": MessageLookupByLibrary.simpleMessage("Beoordeel ons"),
        "rateUsOnStore": m68,
        "reassignMe":
            MessageLookupByLibrary.simpleMessage("\"Ik\" opnieuw toewijzen"),
        "reassignedToName": m69,
        "reassigningLoading":
            MessageLookupByLibrary.simpleMessage("Opnieuw toewijzen..."),
        "recover": MessageLookupByLibrary.simpleMessage("Herstellen"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("Account herstellen"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Herstellen"),
        "recoveryAccount":
            MessageLookupByLibrary.simpleMessage("Account herstellen"),
        "recoveryInitiated":
            MessageLookupByLibrary.simpleMessage("Herstel gestart"),
        "recoveryInitiatedDesc": m70,
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
        "recoveryReady": m71,
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("Herstel succesvol!"),
        "recoveryWarning": MessageLookupByLibrary.simpleMessage(
            "Een vertrouwd contact probeert toegang te krijgen tot je account"),
        "recoveryWarningBody": m72,
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "Het huidige apparaat is niet krachtig genoeg om je wachtwoord te verifiëren, dus moeten we de code een keer opnieuw genereren op een manier die met alle apparaten werkt.\n\nLog in met behulp van uw herstelcode en genereer opnieuw uw wachtwoord (je kunt dezelfde indien gewenst opnieuw gebruiken)."),
        "recreatePasswordTitle": MessageLookupByLibrary.simpleMessage(
            "Wachtwoord opnieuw instellen"),
        "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
        "reenterPassword":
            MessageLookupByLibrary.simpleMessage("Wachtwoord opnieuw invoeren"),
        "reenterPin":
            MessageLookupByLibrary.simpleMessage("PIN opnieuw invoeren"),
        "referFriendsAnd2xYourPlan": MessageLookupByLibrary.simpleMessage(
            "Verwijs vrienden en 2x uw abonnement"),
        "referralStep1": MessageLookupByLibrary.simpleMessage(
            "1. Geef deze code aan je vrienden"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "2. Ze registreren voor een betaald plan"),
        "referralStep3": m73,
        "referrals": MessageLookupByLibrary.simpleMessage("Referenties"),
        "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
            "Verwijzingen zijn momenteel gepauzeerd"),
        "rejectRecovery":
            MessageLookupByLibrary.simpleMessage("Herstel weigeren"),
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
        "removeDuplicatesDesc": MessageLookupByLibrary.simpleMessage(
            "Controleer en verwijder bestanden die exacte kopieën zijn."),
        "removeFromAlbum":
            MessageLookupByLibrary.simpleMessage("Verwijder uit album"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("Uit album verwijderen?"),
        "removeFromFavorite":
            MessageLookupByLibrary.simpleMessage("Verwijder van favorieten"),
        "removeInvite":
            MessageLookupByLibrary.simpleMessage("Verwijder uitnodiging"),
        "removeLink": MessageLookupByLibrary.simpleMessage("Verwijder link"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Deelnemer verwijderen"),
        "removeParticipantBody": m74,
        "removePersonLabel":
            MessageLookupByLibrary.simpleMessage("Verwijder persoonslabel"),
        "removePublicLink":
            MessageLookupByLibrary.simpleMessage("Verwijder publieke link"),
        "removePublicLinks":
            MessageLookupByLibrary.simpleMessage("Verwijder publieke link"),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
            "Sommige van de items die je verwijdert zijn door andere mensen toegevoegd, en je verliest de toegang daartoe"),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Verwijder?"),
        "removeYourselfAsTrustedContact": MessageLookupByLibrary.simpleMessage(
            "Verwijder jezelf als vertrouwd contact"),
        "removingFromFavorites": MessageLookupByLibrary.simpleMessage(
            "Verwijderen uit favorieten..."),
        "rename": MessageLookupByLibrary.simpleMessage("Naam wijzigen"),
        "renameAlbum":
            MessageLookupByLibrary.simpleMessage("Albumnaam wijzigen"),
        "renameFile":
            MessageLookupByLibrary.simpleMessage("Bestandsnaam wijzigen"),
        "renewSubscription":
            MessageLookupByLibrary.simpleMessage("Abonnement verlengen"),
        "renewsOn": m75,
        "reportABug": MessageLookupByLibrary.simpleMessage("Een fout melden"),
        "reportBug": MessageLookupByLibrary.simpleMessage("Fout melden"),
        "resendEmail":
            MessageLookupByLibrary.simpleMessage("E-mail opnieuw versturen"),
        "resetIgnoredFiles":
            MessageLookupByLibrary.simpleMessage("Reset genegeerde bestanden"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Wachtwoord resetten"),
        "resetPerson": MessageLookupByLibrary.simpleMessage("Verwijderen"),
        "resetToDefault": MessageLookupByLibrary.simpleMessage(
            "Standaardinstellingen herstellen"),
        "restore": MessageLookupByLibrary.simpleMessage("Herstellen"),
        "restoreToAlbum":
            MessageLookupByLibrary.simpleMessage("Terugzetten naar album"),
        "restoringFiles":
            MessageLookupByLibrary.simpleMessage("Bestanden herstellen..."),
        "resumableUploads":
            MessageLookupByLibrary.simpleMessage("Hervatbare uploads"),
        "retry": MessageLookupByLibrary.simpleMessage("Opnieuw"),
        "review": MessageLookupByLibrary.simpleMessage("Beoordelen"),
        "reviewDeduplicateItems": MessageLookupByLibrary.simpleMessage(
            "Controleer en verwijder de bestanden die u denkt dat dubbel zijn."),
        "reviewSuggestions":
            MessageLookupByLibrary.simpleMessage("Suggesties beoordelen"),
        "right": MessageLookupByLibrary.simpleMessage("Rechts"),
        "roadtripWithThem": m76,
        "rotate": MessageLookupByLibrary.simpleMessage("Roteren"),
        "rotateLeft": MessageLookupByLibrary.simpleMessage("Roteer links"),
        "rotateRight": MessageLookupByLibrary.simpleMessage("Rechtsom draaien"),
        "safelyStored":
            MessageLookupByLibrary.simpleMessage("Veilig opgeslagen"),
        "save": MessageLookupByLibrary.simpleMessage("Opslaan"),
        "saveChangesBeforeLeavingQuestion":
            MessageLookupByLibrary.simpleMessage(
                "Wijzigingen opslaan voor verlaten?"),
        "saveCollage": MessageLookupByLibrary.simpleMessage("Sla collage op"),
        "saveCopy": MessageLookupByLibrary.simpleMessage("Kopie opslaan"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Bewaar sleutel"),
        "savePerson": MessageLookupByLibrary.simpleMessage("Persoon opslaan"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Sla je herstelsleutel op als je dat nog niet gedaan hebt"),
        "saving": MessageLookupByLibrary.simpleMessage("Opslaan..."),
        "savingEdits":
            MessageLookupByLibrary.simpleMessage("Bewerken opslaan..."),
        "scanCode": MessageLookupByLibrary.simpleMessage("Scan code"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Scan deze barcode met\nje authenticator app"),
        "search": MessageLookupByLibrary.simpleMessage("Zoeken"),
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
        "searchDiscoverEmptySection": MessageLookupByLibrary.simpleMessage(
            "Afbeeldingen worden hier getoond zodra verwerking en synchroniseren voltooid is"),
        "searchFaceEmptySection": MessageLookupByLibrary.simpleMessage(
            "Mensen worden hier getoond als het indexeren klaar is"),
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
        "searchPersonsEmptySection": MessageLookupByLibrary.simpleMessage(
            "Personen worden hier getoond zodra verwerking en synchroniseren voltooid is"),
        "searchResultCount": m77,
        "searchSectionsLengthMismatch": m78,
        "security": MessageLookupByLibrary.simpleMessage("Beveiliging"),
        "seePublicAlbumLinksInApp": MessageLookupByLibrary.simpleMessage(
            "Bekijk publieke album links in de app"),
        "selectALocation":
            MessageLookupByLibrary.simpleMessage("Selecteer een locatie"),
        "selectALocationFirst":
            MessageLookupByLibrary.simpleMessage("Selecteer eerst een locatie"),
        "selectAlbum": MessageLookupByLibrary.simpleMessage("Album selecteren"),
        "selectAll": MessageLookupByLibrary.simpleMessage("Selecteer alles"),
        "selectAllShort": MessageLookupByLibrary.simpleMessage("Alle"),
        "selectCoverPhoto":
            MessageLookupByLibrary.simpleMessage("Selecteer omslagfoto"),
        "selectDate": MessageLookupByLibrary.simpleMessage("Selecteer datum"),
        "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
            "Selecteer mappen voor back-up"),
        "selectItemsToAdd": MessageLookupByLibrary.simpleMessage(
            "Selecteer items om toe te voegen"),
        "selectLanguage":
            MessageLookupByLibrary.simpleMessage("Taal selecteren"),
        "selectMailApp":
            MessageLookupByLibrary.simpleMessage("Selecteer mail app"),
        "selectMorePhotos":
            MessageLookupByLibrary.simpleMessage("Selecteer meer foto\'s"),
        "selectOneDateAndTime":
            MessageLookupByLibrary.simpleMessage("Selecteer één datum en tijd"),
        "selectOneDateAndTimeForAll": MessageLookupByLibrary.simpleMessage(
            "Selecteer één datum en tijd voor allen"),
        "selectPersonToLink":
            MessageLookupByLibrary.simpleMessage("Kies persoon om te linken"),
        "selectReason": MessageLookupByLibrary.simpleMessage("Selecteer reden"),
        "selectStartOfRange":
            MessageLookupByLibrary.simpleMessage("Selecteer start van reeks"),
        "selectTime": MessageLookupByLibrary.simpleMessage("Tijd selecteren"),
        "selectYourFace":
            MessageLookupByLibrary.simpleMessage("Selecteer je gezicht"),
        "selectYourPlan":
            MessageLookupByLibrary.simpleMessage("Kies uw abonnement"),
        "selectedAlbums": m79,
        "selectedFilesAreNotOnEnte": MessageLookupByLibrary.simpleMessage(
            "Geselecteerde bestanden staan niet op Ente"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "Geselecteerde mappen worden versleuteld en geback-upt"),
        "selectedItemsWillBeDeletedFromAllAlbumsAndMoved":
            MessageLookupByLibrary.simpleMessage(
                "Geselecteerde bestanden worden verwijderd uit alle albums en verplaatst naar de prullenbak."),
        "selectedItemsWillBeRemovedFromThisPerson":
            MessageLookupByLibrary.simpleMessage(
                "Geselecteerde bestanden worden van deze persoon verwijderd, maar niet uit uw bibliotheek verwijderd."),
        "selectedPhotos": m80,
        "selectedPhotosWithYours": m81,
        "selfiesWithThem": m82,
        "send": MessageLookupByLibrary.simpleMessage("Verzenden"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("E-mail versturen"),
        "sendInvite":
            MessageLookupByLibrary.simpleMessage("Stuur een uitnodiging"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Stuur link"),
        "serverEndpoint":
            MessageLookupByLibrary.simpleMessage("Server eindpunt"),
        "sessionExpired":
            MessageLookupByLibrary.simpleMessage("Sessie verlopen"),
        "sessionIdMismatch":
            MessageLookupByLibrary.simpleMessage("Sessie ID komt niet overeen"),
        "setAPassword":
            MessageLookupByLibrary.simpleMessage("Stel een wachtwoord in"),
        "setAs": MessageLookupByLibrary.simpleMessage("Instellen als"),
        "setCover": MessageLookupByLibrary.simpleMessage("Omslag instellen"),
        "setLabel": MessageLookupByLibrary.simpleMessage("Instellen"),
        "setNewPassword":
            MessageLookupByLibrary.simpleMessage("Nieuw wachtwoord instellen"),
        "setNewPin":
            MessageLookupByLibrary.simpleMessage("Nieuwe PIN instellen"),
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
        "shareMyVerificationID": m83,
        "shareOnlyWithThePeopleYouWant": MessageLookupByLibrary.simpleMessage(
            "Deel alleen met de mensen die u wilt"),
        "shareTextConfirmOthersVerificationID": m84,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Download Ente zodat we gemakkelijk foto\'s en video\'s in originele kwaliteit kunnen delen\n\nhttps://ente.io"),
        "shareTextReferralCode": m85,
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
            "Delen met niet-Ente gebruikers"),
        "shareWithPeopleSectionTitle": m86,
        "shareYourFirstAlbum":
            MessageLookupByLibrary.simpleMessage("Deel jouw eerste album"),
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Maak gedeelde en collaboratieve albums met andere Ente gebruikers, inclusief gebruikers met gratis abonnementen."),
        "sharedByMe": MessageLookupByLibrary.simpleMessage("Gedeeld door mij"),
        "sharedByYou": MessageLookupByLibrary.simpleMessage("Gedeeld door jou"),
        "sharedPhotoNotifications":
            MessageLookupByLibrary.simpleMessage("Nieuwe gedeelde foto\'s"),
        "sharedPhotoNotificationsExplanation": MessageLookupByLibrary.simpleMessage(
            "Ontvang meldingen wanneer iemand een foto toevoegt aan een gedeeld album waar je deel van uitmaakt"),
        "sharedWith": m87,
        "sharedWithMe": MessageLookupByLibrary.simpleMessage("Gedeeld met mij"),
        "sharedWithYou":
            MessageLookupByLibrary.simpleMessage("Gedeeld met jou"),
        "sharing": MessageLookupByLibrary.simpleMessage("Delen..."),
        "shiftDatesAndTime":
            MessageLookupByLibrary.simpleMessage("Verschuif datum en tijd"),
        "showMemories":
            MessageLookupByLibrary.simpleMessage("Toon herinneringen"),
        "showPerson": MessageLookupByLibrary.simpleMessage("Toon persoon"),
        "signOutFromOtherDevices":
            MessageLookupByLibrary.simpleMessage("Log uit op andere apparaten"),
        "signOutOtherBody": MessageLookupByLibrary.simpleMessage(
            "Als je denkt dat iemand je wachtwoord zou kunnen kennen, kun je alle andere apparaten die je account gebruiken dwingen om uit te loggen."),
        "signOutOtherDevices":
            MessageLookupByLibrary.simpleMessage("Log uit op andere apparaten"),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "Ik ga akkoord met de <u-terms>gebruiksvoorwaarden</u-terms> en <u-policy>privacybeleid</u-policy>"),
        "singleFileDeleteFromDevice": m88,
        "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
            "Het wordt uit alle albums verwijderd."),
        "singleFileInBothLocalAndRemote": m89,
        "singleFileInRemoteOnly": m90,
        "skip": MessageLookupByLibrary.simpleMessage("Overslaan"),
        "smartMemories":
            MessageLookupByLibrary.simpleMessage("Slimme herinneringen"),
        "social": MessageLookupByLibrary.simpleMessage("Sociale media"),
        "someItemsAreInBothEnteAndYourDevice": MessageLookupByLibrary.simpleMessage(
            "Sommige bestanden bevinden zich zowel in Ente als op jouw apparaat."),
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
        "sorryBackupFailedDesc": MessageLookupByLibrary.simpleMessage(
            "Sorry, we kunnen dit bestand nu niet back-uppen, we zullen het later opnieuw proberen."),
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
        "sorryWeHadToPauseYourBackups": MessageLookupByLibrary.simpleMessage(
            "Sorry, we moesten je back-ups pauzeren"),
        "sort": MessageLookupByLibrary.simpleMessage("Sorteren"),
        "sortAlbumsBy": MessageLookupByLibrary.simpleMessage("Sorteren op"),
        "sortNewestFirst":
            MessageLookupByLibrary.simpleMessage("Nieuwste eerst"),
        "sortOldestFirst": MessageLookupByLibrary.simpleMessage("Oudste eerst"),
        "sparkleSuccess": MessageLookupByLibrary.simpleMessage("✨ Succes"),
        "sportsWithThem": m91,
        "spotlightOnThem": m92,
        "spotlightOnYourself":
            MessageLookupByLibrary.simpleMessage("Spotlicht op jezelf"),
        "startAccountRecoveryTitle":
            MessageLookupByLibrary.simpleMessage("Herstel starten"),
        "startBackup": MessageLookupByLibrary.simpleMessage("Back-up starten"),
        "status": MessageLookupByLibrary.simpleMessage("Status"),
        "stopCastingBody":
            MessageLookupByLibrary.simpleMessage("Wil je stoppen met casten?"),
        "stopCastingTitle":
            MessageLookupByLibrary.simpleMessage("Casten stoppen"),
        "storage": MessageLookupByLibrary.simpleMessage("Opslagruimte"),
        "storageBreakupFamily": MessageLookupByLibrary.simpleMessage("Familie"),
        "storageBreakupYou": MessageLookupByLibrary.simpleMessage("Jij"),
        "storageInGB": m93,
        "storageLimitExceeded":
            MessageLookupByLibrary.simpleMessage("Opslaglimiet overschreden"),
        "storageUsageInfo": m94,
        "streamDetails": MessageLookupByLibrary.simpleMessage("Stream details"),
        "strongStrength": MessageLookupByLibrary.simpleMessage("Sterk"),
        "subAlreadyLinkedErrMessage": m95,
        "subWillBeCancelledOn": m96,
        "subscribe": MessageLookupByLibrary.simpleMessage("Abonneer"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "Je hebt een actief betaald abonnement nodig om delen mogelijk te maken."),
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
        "sunrise": MessageLookupByLibrary.simpleMessage("Aan de horizon"),
        "support": MessageLookupByLibrary.simpleMessage("Ondersteuning"),
        "syncProgress": m97,
        "syncStopped":
            MessageLookupByLibrary.simpleMessage("Synchronisatie gestopt"),
        "syncing": MessageLookupByLibrary.simpleMessage("Synchroniseren..."),
        "systemTheme": MessageLookupByLibrary.simpleMessage("Systeem"),
        "tapToCopy": MessageLookupByLibrary.simpleMessage("tik om te kopiëren"),
        "tapToEnterCode":
            MessageLookupByLibrary.simpleMessage("Tik om code in te voeren"),
        "tapToUnlock":
            MessageLookupByLibrary.simpleMessage("Tik om te ontgrendelen"),
        "tapToUpload":
            MessageLookupByLibrary.simpleMessage("Tik om te uploaden"),
        "tapToUploadIsIgnoredDue": m98,
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
        "theLinkYouAreTryingToAccessHasExpired":
            MessageLookupByLibrary.simpleMessage(
                "De link die je probeert te openen is verlopen."),
        "theRecoveryKeyYouEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "De ingevoerde herstelsleutel is onjuist"),
        "theme": MessageLookupByLibrary.simpleMessage("Thema"),
        "theseItemsWillBeDeletedFromYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Deze bestanden zullen worden verwijderd van uw apparaat."),
        "theyAlsoGetXGb": m99,
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
        "thisIsMeExclamation":
            MessageLookupByLibrary.simpleMessage("Dit ben ik!"),
        "thisIsPersonVerificationId": m100,
        "thisIsYourVerificationId":
            MessageLookupByLibrary.simpleMessage("Dit is uw verificatie-ID"),
        "thisWeekThroughTheYears":
            MessageLookupByLibrary.simpleMessage("Deze week door de jaren"),
        "thisWeekXYearsAgo": m101,
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Dit zal je uitloggen van het volgende apparaat:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Dit zal je uitloggen van dit apparaat!"),
        "thisWillMakeTheDateAndTimeOfAllSelected":
            MessageLookupByLibrary.simpleMessage(
                "Dit maakt de datum en tijd van alle geselecteerde foto\'s hetzelfde."),
        "thisWillRemovePublicLinksOfAllSelectedQuickLinks":
            MessageLookupByLibrary.simpleMessage(
                "Hiermee worden openbare links van alle geselecteerde snelle links verwijderd."),
        "throughTheYears": m102,
        "toEnableAppLockPleaseSetupDevicePasscodeOrScreen":
            MessageLookupByLibrary.simpleMessage(
                "Om appvergrendeling in te schakelen, moet u een toegangscode of schermvergrendeling instellen in uw systeeminstellingen."),
        "toHideAPhotoOrVideo": MessageLookupByLibrary.simpleMessage(
            "Om een foto of video te verbergen"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "Verifieer eerst je e-mailadres om je wachtwoord opnieuw in te stellen."),
        "todaysLogs":
            MessageLookupByLibrary.simpleMessage("Logboeken van vandaag"),
        "tooManyIncorrectAttempts":
            MessageLookupByLibrary.simpleMessage("Te veel onjuiste pogingen"),
        "total": MessageLookupByLibrary.simpleMessage("totaal"),
        "totalSize": MessageLookupByLibrary.simpleMessage("Totale grootte"),
        "trash": MessageLookupByLibrary.simpleMessage("Prullenbak"),
        "trashDaysLeft": m103,
        "trim": MessageLookupByLibrary.simpleMessage("Knippen"),
        "tripInYear": m104,
        "tripToLocation": m105,
        "trustedContacts":
            MessageLookupByLibrary.simpleMessage("Vertrouwde contacten"),
        "trustedInviteBody": m106,
        "tryAgain": MessageLookupByLibrary.simpleMessage("Probeer opnieuw"),
        "turnOnBackupForAutoUpload": MessageLookupByLibrary.simpleMessage(
            "Schakel back-up in om bestanden die toegevoegd zijn aan deze map op dit apparaat automatisch te uploaden."),
        "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
        "twoMonthsFreeOnYearlyPlans": MessageLookupByLibrary.simpleMessage(
            "Krijg 2 maanden gratis bij jaarlijkse abonnementen"),
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
        "typeOfGallerGallerytypeIsNotSupportedForRename": m107,
        "unarchive": MessageLookupByLibrary.simpleMessage("Uit archief halen"),
        "unarchiveAlbum":
            MessageLookupByLibrary.simpleMessage("Album uit archief halen"),
        "unarchiving":
            MessageLookupByLibrary.simpleMessage("Uit het archief halen..."),
        "unavailableReferralCode": MessageLookupByLibrary.simpleMessage(
            "Deze code is helaas niet beschikbaar."),
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
        "uploadIsIgnoredDueToIgnorereason": m108,
        "uploadingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Bestanden worden geüpload naar album..."),
        "uploadingMultipleMemories": m109,
        "uploadingSingleMemory": MessageLookupByLibrary.simpleMessage(
            "1 herinnering veiligstellen..."),
        "upto50OffUntil4thDec": MessageLookupByLibrary.simpleMessage(
            "Tot 50% korting, tot 4 december."),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "Bruikbare opslag is beperkt door je huidige abonnement. Buitensporige geclaimde opslag zal automatisch bruikbaar worden wanneer je je abonnement upgrade."),
        "useAsCover":
            MessageLookupByLibrary.simpleMessage("Als cover gebruiken"),
        "useDifferentPlayerInfo": MessageLookupByLibrary.simpleMessage(
            "Problemen met het afspelen van deze video? Hier ingedrukt houden om een andere speler te proberen."),
        "usePublicLinksForPeopleNotOnEnte": MessageLookupByLibrary.simpleMessage(
            "Gebruik publieke links voor mensen die geen Ente account hebben"),
        "useRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Herstelcode gebruiken"),
        "useSelectedPhoto":
            MessageLookupByLibrary.simpleMessage("Gebruik geselecteerde foto"),
        "usedSpace": MessageLookupByLibrary.simpleMessage("Gebruikte ruimte"),
        "validTill": m110,
        "verificationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Verificatie mislukt, probeer het opnieuw"),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("Verificatie ID"),
        "verify": MessageLookupByLibrary.simpleMessage("Verifiëren"),
        "verifyEmail": MessageLookupByLibrary.simpleMessage("Bevestig e-mail"),
        "verifyEmailID": m111,
        "verifyIDLabel": MessageLookupByLibrary.simpleMessage("Verifiëren"),
        "verifyPasskey":
            MessageLookupByLibrary.simpleMessage("Bevestig passkey"),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Bevestig wachtwoord"),
        "verifying": MessageLookupByLibrary.simpleMessage("Verifiëren..."),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Herstelsleutel verifiëren..."),
        "videoInfo": MessageLookupByLibrary.simpleMessage("Video-info"),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("video"),
        "videoStreaming":
            MessageLookupByLibrary.simpleMessage("Video\'s met stream"),
        "videos": MessageLookupByLibrary.simpleMessage("Video\'s"),
        "viewActiveSessions":
            MessageLookupByLibrary.simpleMessage("Actieve sessies bekijken"),
        "viewAddOnButton":
            MessageLookupByLibrary.simpleMessage("Add-ons bekijken"),
        "viewAll": MessageLookupByLibrary.simpleMessage("Alles weergeven"),
        "viewAllExifData":
            MessageLookupByLibrary.simpleMessage("Bekijk alle EXIF gegevens"),
        "viewLargeFiles":
            MessageLookupByLibrary.simpleMessage("Grote bestanden"),
        "viewLargeFilesDesc": MessageLookupByLibrary.simpleMessage(
            "Bekijk bestanden die de meeste opslagruimte verbruiken."),
        "viewLogs": MessageLookupByLibrary.simpleMessage("Logboeken bekijken"),
        "viewPersonToUnlink": m112,
        "viewRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Toon herstelsleutel"),
        "viewer": MessageLookupByLibrary.simpleMessage("Kijker"),
        "viewersSuccessfullyAdded": m113,
        "visitWebToManage": MessageLookupByLibrary.simpleMessage(
            "Bezoek alstublieft web.ente.io om uw abonnement te beheren"),
        "waitingForVerification":
            MessageLookupByLibrary.simpleMessage("Wachten op verificatie..."),
        "waitingForWifi":
            MessageLookupByLibrary.simpleMessage("Wachten op WiFi..."),
        "warning": MessageLookupByLibrary.simpleMessage("Waarschuwing"),
        "weAreOpenSource":
            MessageLookupByLibrary.simpleMessage("We zijn open source!"),
        "weDontSupportEditingPhotosAndAlbumsThatYouDont":
            MessageLookupByLibrary.simpleMessage(
                "We ondersteunen het bewerken van foto\'s en albums waar je niet de eigenaar van bent nog niet"),
        "weHaveSendEmailTo": m114,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Zwak"),
        "welcomeBack": MessageLookupByLibrary.simpleMessage("Welkom terug!"),
        "whatsNew": MessageLookupByLibrary.simpleMessage("Nieuw"),
        "whyAddTrustContact": MessageLookupByLibrary.simpleMessage(
            "Vertrouwde contacten kunnen helpen bij het herstellen van je data."),
        "widgets": MessageLookupByLibrary.simpleMessage("Widgets"),
        "wishThemAHappyBirthday": m115,
        "yearShort": MessageLookupByLibrary.simpleMessage("jr"),
        "yearly": MessageLookupByLibrary.simpleMessage("Jaarlijks"),
        "yearsAgo": m116,
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
        "yesResetPerson":
            MessageLookupByLibrary.simpleMessage("Ja, reset persoon"),
        "you": MessageLookupByLibrary.simpleMessage("Jij"),
        "youAndThem": m117,
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
        "youHaveSuccessfullyFreedUp": m118,
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
