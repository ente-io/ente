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

  static String m0(title) => "${title} (Me)";

  static String m2(count) =>
      "${Intl.plural(count, one: 'Legg til element', other: 'Legg til elementene')}";

  static String m3(storageAmount, endDate) =>
      "Tillegget på ${storageAmount} er gyldig til ${endDate}";

  static String m5(emailOrName) => "Lagt til av ${emailOrName}";

  static String m6(albumName) => "Lagt til ${albumName}";

  static String m7(name) => "Beundrer ${name}";

  static String m8(count) =>
      "${Intl.plural(count, zero: 'Ingen deltakere', one: '1 deltaker', other: '${count} deltakere')}";

  static String m9(versionValue) => "Versjon: ${versionValue}";

  static String m10(freeAmount, storageUnit) =>
      "${freeAmount} ${storageUnit} ledig";

  static String m11(name) => "Vakker utsikt med ${name}";

  static String m12(paymentProvider) =>
      "Vennlist avslutt ditt eksisterende abonnement fra ${paymentProvider} først";

  static String m13(user) =>
      "${user} vil ikke kunne legge til flere bilder til dette albumet\n\nDe vil fortsatt kunne fjerne eksisterende bilder lagt til av dem";

  static String m14(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true':
                'Familien din har gjort krav på ${storageAmountInGb} GB så langt',
            'false': 'Du har gjort krav på ${storageAmountInGb} GB så langt',
            'other': 'Du har gjort krav på ${storageAmountInGb} GB så langt!',
          })}\n";

  static String m15(albumName) =>
      "Samarbeidslenke er opprettet for ${albumName}";

  static String m16(count) =>
      "${Intl.plural(count, zero: 'La til 0 samarbeidspartner', one: 'La til 1 samarbeidspartner', other: 'Lagt til ${count} samarbeidspartnere')}";

  static String m17(email, numOfDays) =>
      "Du er i ferd med å legge til ${email} som en betrodd kontakt. De vil kunne gjenopprette kontoen din hvis du er fraværende i ${numOfDays} dager.";

  static String m18(familyAdminEmail) =>
      "Vennligst kontakt <green>${familyAdminEmail}</green> for å administrere abonnementet";

  static String m19(provider) =>
      "Kontakt oss på support@ente.io for å administrere ditt ${provider} abonnement.";

  static String m20(endpoint) => "Koblet til ${endpoint}";

  static String m21(count) =>
      "${Intl.plural(count, one: 'Slett ${count} element', other: 'Slett ${count} elementer')}";

  static String m23(currentlyDeleting, totalCount) =>
      "Sletter ${currentlyDeleting} / ${totalCount}";

  static String m24(albumName) =>
      "Dette fjerner den offentlige lenken for tilgang til \"${albumName}\".";

  static String m25(supportEmail) =>
      "Vennligst send en e-post til ${supportEmail} fra din registrerte e-postadresse";

  static String m26(count, storageSaved) =>
      "Du har ryddet bort ${Intl.plural(count, one: '${count} duplikatfil', other: '${count} duplikatfiler')}, som frigjør (${storageSaved}!)";

  static String m27(count, formattedSize) =>
      "${count} filer, ${formattedSize} hver";

  static String m29(newEmail) => "E-postadressen er endret til ${newEmail}";

  static String m30(email) => "${email} har ikke en Ente-konto.";

  static String m31(email) =>
      "${email} har ikke en Ente-konto.\n\nsender dem en invitasjon til å dele bilder.";

  static String m32(name) => "Omfavner ${name}";

  static String m33(text) => "Ekstra bilder funnet for ${text}";

  static String m34(name) => "Festing med ${name}";

  static String m35(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 fil', other: '${formattedNumber} filer')} på denne enheten har blitt sikkerhetskopiert";

  static String m36(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 fil', other: '${formattedNumber} filer')} I dette albumet har blitt sikkerhetskopiert";

  static String m37(storageAmountInGB) =>
      "${storageAmountInGB} GB hver gang noen melder seg på en betalt plan og bruker koden din";

  static String m38(endDate) => "Prøveperioden varer til ${endDate}";

  static String m40(sizeInMBorGB) => "Frigjør ${sizeInMBorGB}";

  static String m42(currentlyProcessing, totalCount) =>
      "Behandler ${currentlyProcessing} / ${totalCount}";

  static String m43(name) => "Tur med ${name}";

  static String m44(count) =>
      "${Intl.plural(count, one: '${count} element', other: '${count} elementer')}";

  static String m45(name) => "Siste gang med ${name}";

  static String m46(email) =>
      "${email} har invitert deg til å være en betrodd kontakt";

  static String m47(expiryTime) => "Lenken utløper på ${expiryTime}";

  static String m48(email) => "Knytt personen til ${email}";

  static String m49(personName, email) =>
      "Dette knytter ${personName} til ${email}";

  static String m50(count, formattedCount) =>
      "${Intl.plural(count, zero: 'ingen minner', one: '${formattedCount} minne', other: '${formattedCount} minner')}";

  static String m51(count) =>
      "${Intl.plural(count, one: 'Flytt elementet', other: 'Flytt elementene')}";

  static String m52(albumName) => "Flyttet til ${albumName}";

  static String m53(personName) => "Ingen forslag for ${personName}";

  static String m54(name) => "Ikke ${name}?";

  static String m55(familyAdminEmail) =>
      "Vennligst kontakt ${familyAdminEmail} for å endre koden din.";

  static String m56(name) => "Fest med ${name}";

  static String m57(passwordStrengthValue) =>
      "Passordstyrke: ${passwordStrengthValue}";

  static String m58(providerName) =>
      "Snakk med ${providerName} kundestøtte hvis du ble belastet";

  static String m59(name, age) => "${name} er ${age}!";

  static String m60(name, age) => "${name} fyller ${age} snart";

  static String m61(count) =>
      "${Intl.plural(count, zero: 'Ingen bilder', one: '1 bilde', other: '${count} bilder')}";

  static String m63(endDate) =>
      "Prøveperioden varer til ${endDate}.\nDu kan velge en betalt plan etterpå.";

  static String m64(toEmail) => "Vennligst send oss en e-post på ${toEmail}";

  static String m65(toEmail) => "Vennligst send loggene til \n${toEmail}";

  static String m66(name) => "Poseringer med ${name}";

  static String m67(folderName) => "Behandler ${folderName}...";

  static String m68(storeName) => "Vurder oss på ${storeName}";

  static String m69(name) =>
      "Tildeler deg til ${name}${name}${name}${name}${name}";

  static String m70(days, email) =>
      "Du kan få tilgang til kontoen etter ${days} dager. En varsling vil bli sendt til ${email}.";

  static String m71(email) =>
      "Du kan nå gjenopprette ${email} sin konto ved å sette et nytt passord.";

  static String m72(email) => "${email} prøver å gjenopprette kontoen din.";

  static String m73(storageInGB) =>
      "3. Begge dere får ${storageInGB} GB* gratis";

  static String m74(userEmail) =>
      "${userEmail} vil bli fjernet fra dette delte albumet\n\nAlle bilder lagt til av dem vil også bli fjernet fra albumet";

  static String m75(endDate) => "Abonnement fornyes på ${endDate}";

  static String m76(name) => "Biltur med ${name}";

  static String m77(count) =>
      "${Intl.plural(count, one: '${count} resultat funnet', other: '${count} resultater funnet')}";

  static String m78(snapshotLength, searchLength) =>
      "Uoverensstemmelse i seksjonslengde: ${snapshotLength} != ${searchLength}";

  static String m80(count) => "${count} valgt";

  static String m81(count, yourCount) => "${count} valgt (${yourCount} dine)";

  static String m82(name) => "Selfier med ${name}";

  static String m83(verificationID) =>
      "Her er min verifiserings-ID: ${verificationID} for ente.io.";

  static String m84(verificationID) =>
      "Hei, kan du bekrefte at dette er din ente.io verifiserings-ID: ${verificationID}";

  static String m85(referralCode, referralStorageInGB) =>
      "Gi vervekode: ${referralCode} \n\nBruk den i Innstillinger → General → Verving for å få ${referralStorageInGB} GB gratis etter at du har registrert deg for en betalt plan\n\nhttps://ente.io";

  static String m86(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Del med bestemte personer', one: 'Delt med 1 person', other: 'Delt med ${numberOfPeople} personer')}";

  static String m87(emailIDs) => "Delt med ${emailIDs}";

  static String m88(fileType) =>
      "Denne ${fileType} vil bli slettet fra enheten din.";

  static String m89(fileType) =>
      "Denne ${fileType} er både i Ente og på enheten din.";

  static String m90(fileType) => "Denne ${fileType} vil bli slettet fra Ente.";

  static String m91(name) => "Sport med ${name}";

  static String m92(name) => "Fremhev ${name}";

  static String m93(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m94(
          usedAmount, usedStorageUnit, totalAmount, totalStorageUnit) =>
      "${usedAmount} ${usedStorageUnit} av ${totalAmount} ${totalStorageUnit} brukt";

  static String m95(id) =>
      "Din ${id} er allerede koblet til en annen Ente-konto.\nHvis du ønsker å bruke din ${id} med denne kontoen, vennligst kontakt vår brukerstøtte\'\'";

  static String m96(endDate) =>
      "Abonnementet ditt blir avsluttet den ${endDate}";

  static String m97(completed, total) => "${completed}/${total} minner bevart";

  static String m98(ignoreReason) =>
      "Trykk for å laste opp, opplasting er ignorert nå på grunn av ${ignoreReason}";

  static String m99(storageAmountInGB) => "De får også ${storageAmountInGB} GB";

  static String m100(email) => "Dette er ${email} sin verifiserings-ID";

  static String m101(count) =>
      "${Intl.plural(count, one: 'Denne uka, ${count} år siden', other: 'Denne uka, ${count} år siden')}";

  static String m102(dateFormat) => "${dateFormat} gjennom årene";

  static String m103(count) =>
      "${Intl.plural(count, zero: 'Snart', one: '1 dag', other: '${count} dager')}";

  static String m104(year) => "Reise i ${year}";

  static String m105(location) => "Reise til ${location}";

  static String m106(email) =>
      "Du er invitert til å være en betrodd kontakt av ${email}.";

  static String m107(galleryType) =>
      "Galleritype ${galleryType} støttes ikke for nytt navn";

  static String m108(ignoreReason) =>
      "Opplastingen ble ignorert på grunn av ${ignoreReason}";

  static String m109(count) => "Bevarer ${count} minner...";

  static String m110(endDate) => "Gyldig til ${endDate}";

  static String m111(email) => "Verifiser ${email}";

  static String m114(email) =>
      "Vi har sendt en e-post til <green>${email}</green>";

  static String m116(count) =>
      "${Intl.plural(count, other: '${count} år siden')}";

  static String m117(name) => "Du og ${name}";

  static String m118(storageSaved) => "Du har frigjort ${storageSaved}!";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable": MessageLookupByLibrary.simpleMessage(
            "En ny versjon av Ente er tilgjengelig."),
        "about": MessageLookupByLibrary.simpleMessage("Om"),
        "acceptTrustInvite":
            MessageLookupByLibrary.simpleMessage("Godta invitasjonen"),
        "account": MessageLookupByLibrary.simpleMessage("Konto"),
        "accountIsAlreadyConfigured": MessageLookupByLibrary.simpleMessage(
            "Kontoen er allerede konfigurert."),
        "accountOwnerPersonAppbarTitle": m0,
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Velkommen tilbake!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Jeg forstår at dersom jeg mister passordet mitt, kan jeg miste dataen min, siden daten er <underline>ende-til-ende-kryptert</underline>."),
        "activeSessions": MessageLookupByLibrary.simpleMessage("Aktive økter"),
        "add": MessageLookupByLibrary.simpleMessage("Legg til"),
        "addAName": MessageLookupByLibrary.simpleMessage("Legg til et navn"),
        "addANewEmail":
            MessageLookupByLibrary.simpleMessage("Legg til ny e-post"),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Legg til samarbeidspartner"),
        "addFiles": MessageLookupByLibrary.simpleMessage("Legg til filer"),
        "addFromDevice":
            MessageLookupByLibrary.simpleMessage("Legg til fra enhet"),
        "addItem": m2,
        "addLocation": MessageLookupByLibrary.simpleMessage("Legg til sted"),
        "addLocationButton": MessageLookupByLibrary.simpleMessage("Legg til"),
        "addMore": MessageLookupByLibrary.simpleMessage("Legg til flere"),
        "addName": MessageLookupByLibrary.simpleMessage("Legg til navn"),
        "addNameOrMerge": MessageLookupByLibrary.simpleMessage(
            "Legg til navn eller sammenslåing"),
        "addNew": MessageLookupByLibrary.simpleMessage("Legg til ny"),
        "addNewPerson":
            MessageLookupByLibrary.simpleMessage("Legg til ny person"),
        "addOnPageSubtitle":
            MessageLookupByLibrary.simpleMessage("Detaljer om tillegg"),
        "addOnValidTill": m3,
        "addOns": MessageLookupByLibrary.simpleMessage("Tillegg"),
        "addPhotos": MessageLookupByLibrary.simpleMessage("Legg til bilder"),
        "addSelected": MessageLookupByLibrary.simpleMessage("Legg til valgte"),
        "addToAlbum": MessageLookupByLibrary.simpleMessage("Legg til i album"),
        "addToEnte": MessageLookupByLibrary.simpleMessage("Legg til i Ente"),
        "addToHiddenAlbum":
            MessageLookupByLibrary.simpleMessage("Legg til i skjult album"),
        "addTrustedContact":
            MessageLookupByLibrary.simpleMessage("Legg til betrodd kontakt"),
        "addViewer": MessageLookupByLibrary.simpleMessage("Legg til seer"),
        "addYourPhotosNow":
            MessageLookupByLibrary.simpleMessage("Legg til bildene dine nå"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Lagt til som"),
        "addedBy": m5,
        "addedSuccessfullyTo": m6,
        "addingToFavorites":
            MessageLookupByLibrary.simpleMessage("Legger til i favoritter..."),
        "admiringThem": m7,
        "advanced": MessageLookupByLibrary.simpleMessage("Avansert"),
        "advancedSettings": MessageLookupByLibrary.simpleMessage("Avansert"),
        "after1Day": MessageLookupByLibrary.simpleMessage("Etter 1 dag"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("Etter 1 time"),
        "after1Month": MessageLookupByLibrary.simpleMessage("Etter 1 måned"),
        "after1Week": MessageLookupByLibrary.simpleMessage("Etter 1 uke"),
        "after1Year": MessageLookupByLibrary.simpleMessage("Etter 1 år"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Eier"),
        "albumParticipantsCount": m8,
        "albumTitle": MessageLookupByLibrary.simpleMessage("Albumtittel"),
        "albumUpdated": MessageLookupByLibrary.simpleMessage("Album oppdatert"),
        "albums": MessageLookupByLibrary.simpleMessage("Album"),
        "allClear": MessageLookupByLibrary.simpleMessage("✨ Alt klart"),
        "allMemoriesPreserved":
            MessageLookupByLibrary.simpleMessage("Alle minner bevart"),
        "allPersonGroupingWillReset": MessageLookupByLibrary.simpleMessage(
            "Alle grupperinger for denne personen vil bli tilbakestilt, og du vil miste alle forslag for denne personen"),
        "allWillShiftRangeBasedOnFirst": MessageLookupByLibrary.simpleMessage(
            "Dette er den første i gruppen. Andre valgte bilder vil automatisk forflyttet basert på denne nye datoen"),
        "allow": MessageLookupByLibrary.simpleMessage("Tillat"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Tillat folk med lenken å også legge til bilder til det delte albumet."),
        "allowAddingPhotos":
            MessageLookupByLibrary.simpleMessage("Tillat å legge til bilder"),
        "allowAppToOpenSharedAlbumLinks": MessageLookupByLibrary.simpleMessage(
            "Tillat app å åpne delte albumlenker"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("Tillat nedlastinger"),
        "allowPeopleToAddPhotos": MessageLookupByLibrary.simpleMessage(
            "Tillat folk å legge til bilder"),
        "allowPermBody": MessageLookupByLibrary.simpleMessage(
            "Vennligst gi tilgang til bildene dine i Innstillinger, slik at Ente kan vise og sikkerhetskopiere biblioteket."),
        "allowPermTitle":
            MessageLookupByLibrary.simpleMessage("Gi tilgang til bilder"),
        "androidBiometricHint":
            MessageLookupByLibrary.simpleMessage("Verifiser identitet"),
        "androidBiometricNotRecognized":
            MessageLookupByLibrary.simpleMessage("Ikke gjenkjent. Prøv igjen."),
        "androidBiometricRequiredTitle":
            MessageLookupByLibrary.simpleMessage("Biometri kreves"),
        "androidBiometricSuccess":
            MessageLookupByLibrary.simpleMessage("Vellykket"),
        "androidCancelButton": MessageLookupByLibrary.simpleMessage("Avbryt"),
        "androidDeviceCredentialsRequiredTitle":
            MessageLookupByLibrary.simpleMessage(
                "Enhetens påloggingsinformasjon kreves"),
        "androidDeviceCredentialsSetupDescription":
            MessageLookupByLibrary.simpleMessage(
                "Enhetens påloggingsinformasjon kreves"),
        "androidGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "Biometrisk autentisering er ikke satt opp på enheten din. Gå til \'Innstillinger > Sikkerhet\' for å legge til biometrisk godkjenning."),
        "androidIosWebDesktop":
            MessageLookupByLibrary.simpleMessage("Android, iOS, Web, Desktop"),
        "androidSignInTitle":
            MessageLookupByLibrary.simpleMessage("Krever innlogging"),
        "appIcon": MessageLookupByLibrary.simpleMessage("App-ikon"),
        "appLock": MessageLookupByLibrary.simpleMessage("Applås"),
        "appLockDescriptions": MessageLookupByLibrary.simpleMessage(
            "Velg mellom enhetens standard låseskjerm og en egendefinert låseskjerm med en PIN-kode eller passord."),
        "appVersion": m9,
        "appleId": MessageLookupByLibrary.simpleMessage("Apple ID"),
        "apply": MessageLookupByLibrary.simpleMessage("Anvend"),
        "applyCodeTitle": MessageLookupByLibrary.simpleMessage("Bruk kode"),
        "appstoreSubscription":
            MessageLookupByLibrary.simpleMessage("AppStore subscription"),
        "archive": MessageLookupByLibrary.simpleMessage("Arkiv"),
        "archiveAlbum": MessageLookupByLibrary.simpleMessage("Arkiver album"),
        "archiving":
            MessageLookupByLibrary.simpleMessage("Legger til i arkivet..."),
        "areYouSureThatYouWantToLeaveTheFamily":
            MessageLookupByLibrary.simpleMessage(
                "Er du sikker på at du vil forlate familieabonnementet?"),
        "areYouSureYouWantToCancel": MessageLookupByLibrary.simpleMessage(
            "Er du sikker på at du vil avslutte?"),
        "areYouSureYouWantToChangeYourPlan":
            MessageLookupByLibrary.simpleMessage(
                "Er du sikker på at du vil endre abonnement?"),
        "areYouSureYouWantToExit": MessageLookupByLibrary.simpleMessage(
            "Er du sikker på at du vil avslutte?"),
        "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
            "Er du sikker på at du vil logge ut?"),
        "areYouSureYouWantToRenew": MessageLookupByLibrary.simpleMessage(
            "Er du sikker på at du vil fornye?"),
        "areYouSureYouWantToResetThisPerson":
            MessageLookupByLibrary.simpleMessage(
                "Er du sikker på at du vil tilbakestille denne personen?"),
        "askCancelReason": MessageLookupByLibrary.simpleMessage(
            "Abonnementet ble avbrutt. Ønsker du å dele grunnen?"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "Hva er hovedårsaken til at du sletter kontoen din?"),
        "askYourLovedOnesToShare":
            MessageLookupByLibrary.simpleMessage("Spør dine kjære om å dele"),
        "atAFalloutShelter":
            MessageLookupByLibrary.simpleMessage("i en bunker"),
        "authToChangeEmailVerificationSetting":
            MessageLookupByLibrary.simpleMessage(
                "Vennligst autentiser deg for å endre e-postbekreftelse"),
        "authToChangeLockscreenSetting": MessageLookupByLibrary.simpleMessage(
            "Autentiser deg for å endre låseskjerminnstillingen"),
        "authToChangeYourEmail": MessageLookupByLibrary.simpleMessage(
            "Vennlist autentiser deg for å endre e-postadressen din"),
        "authToChangeYourPassword": MessageLookupByLibrary.simpleMessage(
            "Vennligst autentiser deg for å endre passordet ditt"),
        "authToConfigureTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Autentiser deg for å konfigurere tofaktorautentisering"),
        "authToInitiateAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Vennlist autentiser deg for å starte sletting av konto"),
        "authToManageLegacy": MessageLookupByLibrary.simpleMessage(
            "Vennlist autentiser deg for å administrere de betrodde kontaktene dine"),
        "authToViewPasskey": MessageLookupByLibrary.simpleMessage(
            "Vennligst autentiser deg for å se gjennopprettingsnøkkelen din"),
        "authToViewTrashedFiles": MessageLookupByLibrary.simpleMessage(
            "Vennligst autentiser deg for å se dine slettede filer"),
        "authToViewYourActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Vennligst autentiser deg for å se dine aktive økter"),
        "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
            "Vennligst autentiser deg for å se dine skjulte filer"),
        "authToViewYourMemories": MessageLookupByLibrary.simpleMessage(
            "Vennligst autentiser deg for å se minnene dine"),
        "authToViewYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Vennligst autentiser deg for å se gjennopprettingsnøkkelen din"),
        "authenticating":
            MessageLookupByLibrary.simpleMessage("Autentiserer..."),
        "authenticationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Autentisering mislyktes, prøv igjen"),
        "authenticationSuccessful": MessageLookupByLibrary.simpleMessage(
            "Autentisering var vellykket!"),
        "autoCastDialogBody": MessageLookupByLibrary.simpleMessage(
            "Du vil se tilgjengelige Cast enheter her."),
        "autoCastiOSPermission": MessageLookupByLibrary.simpleMessage(
            "Kontroller at lokale nettverkstillatelser er slått på for Ente Photos-appen, i innstillinger."),
        "autoLock": MessageLookupByLibrary.simpleMessage("Lås automatisk"),
        "autoLockFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "Tid før appen låses etter at den er lagt i bakgrunnen"),
        "autoLogoutMessage": MessageLookupByLibrary.simpleMessage(
            "Du har blitt logget ut på grunn av en teknisk feil. Vi beklager ulempen."),
        "autoPair": MessageLookupByLibrary.simpleMessage("Automatisk parring"),
        "autoPairDesc": MessageLookupByLibrary.simpleMessage(
            "Automatisk par fungerer kun med enheter som støtter Chromecast."),
        "available": MessageLookupByLibrary.simpleMessage("Tilgjengelig"),
        "availableStorageSpace": m10,
        "backedUpFolders":
            MessageLookupByLibrary.simpleMessage("Sikkerhetskopierte mapper"),
        "backgroundWithThem": m11,
        "backup": MessageLookupByLibrary.simpleMessage("Sikkerhetskopi"),
        "backupFailed": MessageLookupByLibrary.simpleMessage(
            "Sikkerhetskopiering mislyktes"),
        "backupFile":
            MessageLookupByLibrary.simpleMessage("Sikkerhetskopieringsfil\n"),
        "backupOverMobileData": MessageLookupByLibrary.simpleMessage(
            "Sikkerhetskopier via mobildata"),
        "backupSettings": MessageLookupByLibrary.simpleMessage(
            "Sikkerhetskopier innstillinger"),
        "backupStatus":
            MessageLookupByLibrary.simpleMessage("Status for sikkerhetskopi"),
        "backupStatusDescription": MessageLookupByLibrary.simpleMessage(
            "Elementer som har blitt sikkerhetskopiert vil vises her"),
        "backupVideos":
            MessageLookupByLibrary.simpleMessage("Sikkerhetskopier videoer"),
        "beach": MessageLookupByLibrary.simpleMessage("Sand og sjø"),
        "birthday": MessageLookupByLibrary.simpleMessage("Bursdag"),
        "blackFridaySale":
            MessageLookupByLibrary.simpleMessage("Black Friday salg"),
        "blog": MessageLookupByLibrary.simpleMessage("Blogg"),
        "cachedData": MessageLookupByLibrary.simpleMessage("Bufrede data"),
        "calculating": MessageLookupByLibrary.simpleMessage("Beregner..."),
        "canNotOpenBody": MessageLookupByLibrary.simpleMessage(
            "Beklager, dette albumet kan ikke åpnes i appen."),
        "canNotOpenTitle":
            MessageLookupByLibrary.simpleMessage("Kan ikke åpne dette albumet"),
        "canNotUploadToAlbumsOwnedByOthers":
            MessageLookupByLibrary.simpleMessage(
                "Kan ikke laste opp til album eid av andre"),
        "canOnlyCreateLinkForFilesOwnedByYou":
            MessageLookupByLibrary.simpleMessage(
                "Kan bare opprette link for filer som eies av deg"),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "Du kan kun fjerne filer som eies av deg"),
        "cancel": MessageLookupByLibrary.simpleMessage("Avbryt"),
        "cancelAccountRecovery":
            MessageLookupByLibrary.simpleMessage("Avbryt gjenoppretting"),
        "cancelAccountRecoveryBody": MessageLookupByLibrary.simpleMessage(
            "Er du sikker på at du vil avbryte gjenoppretting?"),
        "cancelOtherSubscription": m12,
        "cancelSubscription":
            MessageLookupByLibrary.simpleMessage("Avslutt abonnement"),
        "cannotAddMorePhotosAfterBecomingViewer": m13,
        "cannotDeleteSharedFiles":
            MessageLookupByLibrary.simpleMessage("Kan ikke slette delte filer"),
        "castAlbum": MessageLookupByLibrary.simpleMessage("Cast album"),
        "castIPMismatchBody": MessageLookupByLibrary.simpleMessage(
            "Kontroller at du er på samme nettverk som TV-en."),
        "castIPMismatchTitle":
            MessageLookupByLibrary.simpleMessage("Kunne ikke strømme album"),
        "castInstruction": MessageLookupByLibrary.simpleMessage(
            "Besøk cast.ente.io på enheten du vil parre.\n\nSkriv inn koden under for å spille albumet på TV-en din."),
        "centerPoint": MessageLookupByLibrary.simpleMessage("Midtstill punkt"),
        "change": MessageLookupByLibrary.simpleMessage("Endre"),
        "changeEmail":
            MessageLookupByLibrary.simpleMessage("Endre e-postadresse"),
        "changeLocationOfSelectedItems": MessageLookupByLibrary.simpleMessage(
            "Endre plassering av valgte elementer?"),
        "changePassword": MessageLookupByLibrary.simpleMessage("Bytt passord"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Bytt passord"),
        "changePermissions":
            MessageLookupByLibrary.simpleMessage("Endre tillatelser?"),
        "changeYourReferralCode":
            MessageLookupByLibrary.simpleMessage("Endre din vervekode"),
        "checkForUpdates":
            MessageLookupByLibrary.simpleMessage("Se etter oppdateringer"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Vennligst sjekk innboksen din (og søppelpost) for å fullføre verifiseringen"),
        "checkStatus":
            MessageLookupByLibrary.simpleMessage("Kontroller status"),
        "checking": MessageLookupByLibrary.simpleMessage("Sjekker..."),
        "checkingModels":
            MessageLookupByLibrary.simpleMessage("Sjekker modeller..."),
        "city": MessageLookupByLibrary.simpleMessage("I byen"),
        "claimFreeStorage":
            MessageLookupByLibrary.simpleMessage("Få gratis lagring"),
        "claimMore": MessageLookupByLibrary.simpleMessage("Løs inn mer!"),
        "claimed": MessageLookupByLibrary.simpleMessage("Løst inn"),
        "claimedStorageSoFar": m14,
        "cleanUncategorized":
            MessageLookupByLibrary.simpleMessage("Tøm ukategorisert"),
        "cleanUncategorizedDescription": MessageLookupByLibrary.simpleMessage(
            "Fjern alle filer fra Ukategoriserte som finnes i andre album"),
        "clearCaches": MessageLookupByLibrary.simpleMessage("Tom hurtigbuffer"),
        "clearIndexes": MessageLookupByLibrary.simpleMessage("Tøm indekser"),
        "click": MessageLookupByLibrary.simpleMessage("• Klikk"),
        "clickOnTheOverflowMenu": MessageLookupByLibrary.simpleMessage(
            "• Klikk på menyen med tre prikker"),
        "close": MessageLookupByLibrary.simpleMessage("Lukk"),
        "clubByCaptureTime": MessageLookupByLibrary.simpleMessage(
            "Grupper etter tidspunkt for opptak"),
        "clubByFileName":
            MessageLookupByLibrary.simpleMessage("Grupper etter filnavn"),
        "clusteringProgress":
            MessageLookupByLibrary.simpleMessage("Fremdrift for klynging"),
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("Kode brukt"),
        "codeChangeLimitReached": MessageLookupByLibrary.simpleMessage(
            "Beklager, du har nådd grensen for kodeendringer."),
        "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Koden er kopiert til utklippstavlen"),
        "codeUsedByYou":
            MessageLookupByLibrary.simpleMessage("Kode som brukes av deg"),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Opprett en lenke slik at folk kan legge til og se bilder i det delte albumet ditt uten å trenge Ente-appen eller en konto. Perfekt for å samle bilder fra arrangementer."),
        "collaborativeLink":
            MessageLookupByLibrary.simpleMessage("Samarbeidslenke"),
        "collaborativeLinkCreatedFor": m15,
        "collaborator":
            MessageLookupByLibrary.simpleMessage("Samarbeidspartner"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Samarbeidspartnere kan legge til bilder og videoer i det delte albumet."),
        "collaboratorsSuccessfullyAdded": m16,
        "collageLayout": MessageLookupByLibrary.simpleMessage("Utforming"),
        "collageSaved":
            MessageLookupByLibrary.simpleMessage("Kollasje lagret i galleriet"),
        "collect": MessageLookupByLibrary.simpleMessage("Samle"),
        "collectEventPhotos":
            MessageLookupByLibrary.simpleMessage("Samle arrangementbilder"),
        "collectPhotos": MessageLookupByLibrary.simpleMessage("Samle bilder"),
        "collectPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Opprett en link hvor vennene dine kan laste opp bilder i original kvalitet."),
        "color": MessageLookupByLibrary.simpleMessage("Farge"),
        "configuration": MessageLookupByLibrary.simpleMessage("Konfigurasjon"),
        "confirm": MessageLookupByLibrary.simpleMessage("Bekreft"),
        "confirm2FADisable": MessageLookupByLibrary.simpleMessage(
            "Er du sikker på at du vil deaktivere tofaktorautentisering?"),
        "confirmAccountDeletion":
            MessageLookupByLibrary.simpleMessage("Bekreft sletting av konto"),
        "confirmAddingTrustedContact": m17,
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Ja, jeg ønsker å slette denne kontoen og all dataen dens permanent."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Bekreft passordet"),
        "confirmPlanChange": MessageLookupByLibrary.simpleMessage(
            "Bekreft endring av abonnement"),
        "confirmRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Bekreft gjenopprettingsnøkkel"),
        "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Bekreft din gjenopprettingsnøkkel"),
        "connectToDevice":
            MessageLookupByLibrary.simpleMessage("Koble til enheten"),
        "contactFamilyAdmin": m18,
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("Kontakt kundestøtte"),
        "contactToManageSubscription": m19,
        "contacts": MessageLookupByLibrary.simpleMessage("Kontakter"),
        "contents": MessageLookupByLibrary.simpleMessage("Innhold"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("Fortsett"),
        "continueOnFreeTrial": MessageLookupByLibrary.simpleMessage(
            "Fortsett med gratis prøveversjon"),
        "convertToAlbum":
            MessageLookupByLibrary.simpleMessage("Gjør om til album"),
        "copyEmailAddress":
            MessageLookupByLibrary.simpleMessage("Kopier e-postadresse"),
        "copyLink": MessageLookupByLibrary.simpleMessage("Kopier lenke"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Kopier og lim inn denne koden\ntil autentiseringsappen din"),
        "couldNotBackUpTryLater": MessageLookupByLibrary.simpleMessage(
            "Vi kunne ikke sikkerhetskopiere dine data.\nVi vil prøve på nytt senere."),
        "couldNotFreeUpSpace":
            MessageLookupByLibrary.simpleMessage("Kunne ikke frigjøre plass"),
        "couldNotUpdateSubscription": MessageLookupByLibrary.simpleMessage(
            "Kunne ikke oppdatere abonnement"),
        "count": MessageLookupByLibrary.simpleMessage("Antall"),
        "crashReporting":
            MessageLookupByLibrary.simpleMessage("Krasjrapportering"),
        "create": MessageLookupByLibrary.simpleMessage("Opprett"),
        "createAccount": MessageLookupByLibrary.simpleMessage("Opprett konto"),
        "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
            "Trykk og holde inne for å velge bilder, og trykk på + for å lage et album"),
        "createCollaborativeLink":
            MessageLookupByLibrary.simpleMessage("Samarbeidslenke"),
        "createCollage":
            MessageLookupByLibrary.simpleMessage("Opprett kollasje"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("Opprett ny konto"),
        "createOrSelectAlbum":
            MessageLookupByLibrary.simpleMessage("Opprett eller velg album"),
        "createPublicLink":
            MessageLookupByLibrary.simpleMessage("Opprett offentlig lenke"),
        "creatingLink": MessageLookupByLibrary.simpleMessage("Lager lenke..."),
        "criticalUpdateAvailable": MessageLookupByLibrary.simpleMessage(
            "Kritisk oppdatering er tilgjengelig"),
        "crop": MessageLookupByLibrary.simpleMessage("Beskjær"),
        "currentUsageIs":
            MessageLookupByLibrary.simpleMessage("Nåværende bruk er "),
        "currentlyRunning":
            MessageLookupByLibrary.simpleMessage("Kjører for øyeblikket"),
        "custom": MessageLookupByLibrary.simpleMessage("Egendefinert"),
        "customEndpoint": m20,
        "darkTheme": MessageLookupByLibrary.simpleMessage("Mørk"),
        "dayToday": MessageLookupByLibrary.simpleMessage("I dag"),
        "dayYesterday": MessageLookupByLibrary.simpleMessage("I går"),
        "declineTrustInvite":
            MessageLookupByLibrary.simpleMessage("Avslå invitasjon"),
        "decrypting": MessageLookupByLibrary.simpleMessage("Dekrypterer..."),
        "decryptingVideo":
            MessageLookupByLibrary.simpleMessage("Dekrypterer video..."),
        "deduplicateFiles":
            MessageLookupByLibrary.simpleMessage("Fjern duplikatfiler"),
        "delete": MessageLookupByLibrary.simpleMessage("Slett"),
        "deleteAccount": MessageLookupByLibrary.simpleMessage("Slett konto"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "Vi er lei oss for at du forlater oss. Gi oss gjerne en tilbakemelding så vi kan forbedre oss."),
        "deleteAccountPermanentlyButton":
            MessageLookupByLibrary.simpleMessage("Slett bruker for altid"),
        "deleteAlbum": MessageLookupByLibrary.simpleMessage("Slett album"),
        "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
            "Også slette bilder (og videoer) i dette albumet fra <bold>alle</bold> andre album de er del av?"),
        "deleteAlbumsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Dette vil slette alle tomme albumer. Dette er nyttig når du vil redusere rotet i albumlisten din."),
        "deleteAll": MessageLookupByLibrary.simpleMessage("Slett alt"),
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
            "Denne kontoen er knyttet til andre Ente-apper, hvis du bruker noen. De opplastede dataene, i alle Ente-apper, vil bli planlagt slettet, og kontoen din vil bli slettet permanent."),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "Vennligst send en e-post til <warning>account-deletion@ente.io</warning> fra din registrerte e-postadresse."),
        "deleteEmptyAlbums":
            MessageLookupByLibrary.simpleMessage("Slett tomme album"),
        "deleteEmptyAlbumsWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Slette tomme albumer?"),
        "deleteFromBoth":
            MessageLookupByLibrary.simpleMessage("Slett fra begge"),
        "deleteFromDevice":
            MessageLookupByLibrary.simpleMessage("Slett fra enhet"),
        "deleteFromEnte":
            MessageLookupByLibrary.simpleMessage("Slett fra Ente"),
        "deleteItemCount": m21,
        "deleteLocation": MessageLookupByLibrary.simpleMessage("Slett sted"),
        "deletePhotos": MessageLookupByLibrary.simpleMessage("Slett bilder"),
        "deleteProgress": m23,
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "Det mangler en hovedfunksjon jeg trenger"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "Appen, eller en bestemt funksjon, fungerer ikke slik jeg tror den skal"),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
            "Jeg fant en annen tjeneste jeg liker bedre"),
        "deleteReason4":
            MessageLookupByLibrary.simpleMessage("Årsaken min er ikke oppført"),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
            "Forespørselen din vil bli behandlet innen 72 timer."),
        "deleteSharedAlbum":
            MessageLookupByLibrary.simpleMessage("Slett delt album?"),
        "deleteSharedAlbumDialogBody": MessageLookupByLibrary.simpleMessage(
            "Albumet vil bli slettet for alle\n\nDu vil miste tilgang til delte bilder i dette albumet som eies av andre"),
        "deselectAll": MessageLookupByLibrary.simpleMessage("Fjern alle valg"),
        "designedToOutlive":
            MessageLookupByLibrary.simpleMessage("Laget for å vare lenger enn"),
        "details": MessageLookupByLibrary.simpleMessage("Detaljer"),
        "developerSettings":
            MessageLookupByLibrary.simpleMessage("Utviklerinnstillinger"),
        "developerSettingsWarning": MessageLookupByLibrary.simpleMessage(
            "Er du sikker på at du vil endre utviklerinnstillingene?"),
        "deviceCodeHint":
            MessageLookupByLibrary.simpleMessage("Skriv inn koden"),
        "deviceFilesAutoUploading": MessageLookupByLibrary.simpleMessage(
            "Filer lagt til dette enhetsalbumet vil automatisk bli lastet opp til Ente."),
        "deviceLock": MessageLookupByLibrary.simpleMessage("Enhetslås"),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
            "Deaktiver enhetens skjermlås når Ente er i forgrunnen og det er en sikkerhetskopi som pågår. Dette trengs normalt ikke, men kan hjelpe store opplastinger og førstegangsimport av store biblioteker med å fullføre raskere."),
        "deviceNotFound":
            MessageLookupByLibrary.simpleMessage("Enhet ikke funnet"),
        "didYouKnow": MessageLookupByLibrary.simpleMessage("Visste du at?"),
        "disableAutoLock":
            MessageLookupByLibrary.simpleMessage("Deaktiver autolås"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Seere kan fremdeles ta skjermbilder eller lagre en kopi av bildene dine ved bruk av eksterne verktøy"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Vær oppmerksom på"),
        "disableLinkMessage": m24,
        "disableTwofactor":
            MessageLookupByLibrary.simpleMessage("Deaktiver tofaktor"),
        "disablingTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Deaktiverer tofaktorautentisering..."),
        "discord": MessageLookupByLibrary.simpleMessage("Discord"),
        "discover": MessageLookupByLibrary.simpleMessage("Oppdag"),
        "discover_babies": MessageLookupByLibrary.simpleMessage("Babyer"),
        "discover_celebrations":
            MessageLookupByLibrary.simpleMessage("Feiringer"),
        "discover_food": MessageLookupByLibrary.simpleMessage("Mat"),
        "discover_greenery":
            MessageLookupByLibrary.simpleMessage("Grøntområder"),
        "discover_hills": MessageLookupByLibrary.simpleMessage("Åser"),
        "discover_identity": MessageLookupByLibrary.simpleMessage("Identitet"),
        "discover_memes": MessageLookupByLibrary.simpleMessage("Memes"),
        "discover_notes": MessageLookupByLibrary.simpleMessage("Notater"),
        "discover_pets": MessageLookupByLibrary.simpleMessage("Kjæledyr"),
        "discover_receipts":
            MessageLookupByLibrary.simpleMessage("Kvitteringer"),
        "discover_screenshots":
            MessageLookupByLibrary.simpleMessage("Skjermbilder"),
        "discover_selfies": MessageLookupByLibrary.simpleMessage("Selfier"),
        "discover_sunset": MessageLookupByLibrary.simpleMessage("Solnedgang"),
        "discover_visiting_cards":
            MessageLookupByLibrary.simpleMessage("Visittkort"),
        "discover_wallpapers":
            MessageLookupByLibrary.simpleMessage("Bakgrunnsbilder"),
        "dismiss": MessageLookupByLibrary.simpleMessage("Avvis "),
        "distanceInKMUnit": MessageLookupByLibrary.simpleMessage("km"),
        "doNotSignOut": MessageLookupByLibrary.simpleMessage("Ikke logg ut"),
        "doThisLater":
            MessageLookupByLibrary.simpleMessage("Gjør dette senere"),
        "doYouWantToDiscardTheEditsYouHaveMade":
            MessageLookupByLibrary.simpleMessage(
                "Vil du forkaste endringene du har gjort?"),
        "done": MessageLookupByLibrary.simpleMessage("Ferdig"),
        "dontSave": MessageLookupByLibrary.simpleMessage("Ikke lagre"),
        "doubleYourStorage":
            MessageLookupByLibrary.simpleMessage("Doble lagringsplassen din"),
        "download": MessageLookupByLibrary.simpleMessage("Last ned"),
        "downloadFailed":
            MessageLookupByLibrary.simpleMessage("Nedlasting mislyktes"),
        "downloading": MessageLookupByLibrary.simpleMessage("Laster ned..."),
        "dropSupportEmail": m25,
        "duplicateFileCountWithStorageSaved": m26,
        "duplicateItemsGroup": m27,
        "edit": MessageLookupByLibrary.simpleMessage("Rediger"),
        "editLocation":
            MessageLookupByLibrary.simpleMessage("Rediger plassering"),
        "editLocationTagTitle":
            MessageLookupByLibrary.simpleMessage("Rediger plassering"),
        "editPerson": MessageLookupByLibrary.simpleMessage("Rediger person"),
        "editTime": MessageLookupByLibrary.simpleMessage("Endre tidspunkt"),
        "editsSaved": MessageLookupByLibrary.simpleMessage("Endringer lagret"),
        "editsToLocationWillOnlyBeSeenWithinEnte":
            MessageLookupByLibrary.simpleMessage(
                "Endringer i plassering vil kun være synlige i Ente"),
        "eligible": MessageLookupByLibrary.simpleMessage("kvalifisert"),
        "email": MessageLookupByLibrary.simpleMessage("E-post"),
        "emailAlreadyRegistered": MessageLookupByLibrary.simpleMessage(
            "E-postadressen er allerede registrert."),
        "emailChangedTo": m29,
        "emailDoesNotHaveEnteAccount": m30,
        "emailNoEnteAccount": m31,
        "emailNotRegistered": MessageLookupByLibrary.simpleMessage(
            "E-postadressen er ikke registrert."),
        "emailVerificationToggle":
            MessageLookupByLibrary.simpleMessage("E-postbekreftelse"),
        "emailYourLogs":
            MessageLookupByLibrary.simpleMessage("Send loggene dine på e-post"),
        "embracingThem": m32,
        "emergencyContacts":
            MessageLookupByLibrary.simpleMessage("Nødkontakter"),
        "empty": MessageLookupByLibrary.simpleMessage("Tom"),
        "emptyTrash": MessageLookupByLibrary.simpleMessage("Tøm papirkurv?"),
        "enable": MessageLookupByLibrary.simpleMessage("Aktiver"),
        "enableMLIndexingDesc": MessageLookupByLibrary.simpleMessage(
            "Ente støtter maskinlæring på enheten for ansiktsgjenkjenning, magisk søk og andre avanserte søkefunksjoner"),
        "enableMachineLearningBanner": MessageLookupByLibrary.simpleMessage(
            "Aktiver maskinlæring for magisk søk og ansiktsgjenkjenning"),
        "enableMaps": MessageLookupByLibrary.simpleMessage("Aktiver kart"),
        "enableMapsDesc": MessageLookupByLibrary.simpleMessage(
            "Dette viser dine bilder på et verdenskart.\n\nDette kartet er hostet av Open Street Map, og de nøyaktige stedene for dine bilder blir aldri delt.\n\nDu kan deaktivere denne funksjonen når som helst fra Innstillinger."),
        "enabled": MessageLookupByLibrary.simpleMessage("Aktivert"),
        "encryptingBackup":
            MessageLookupByLibrary.simpleMessage("Krypterer sikkerhetskopi..."),
        "encryption": MessageLookupByLibrary.simpleMessage("Kryptering"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Krypteringsnøkkel"),
        "endpointUpdatedMessage":
            MessageLookupByLibrary.simpleMessage("Endepunktet ble oppdatert"),
        "endtoendEncryptedByDefault": MessageLookupByLibrary.simpleMessage(
            "Ende-til-ende kryptert som standard"),
        "enteCanEncryptAndPreserveFilesOnlyIfYouGrant":
            MessageLookupByLibrary.simpleMessage(
                "Ente kan bare kryptere og bevare filer hvis du gir tilgang til dem"),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
            "Ente <i>trenger tillatelse</i> for å bevare bildene dine"),
        "enteSubscriptionPitch": MessageLookupByLibrary.simpleMessage(
            "Ente bevarer minnene dine, slik at de er alltid tilgjengelig for deg, selv om du mister enheten."),
        "enteSubscriptionShareWithFamily": MessageLookupByLibrary.simpleMessage(
            "Familien din kan også legges til abonnementet ditt."),
        "enterAlbumName":
            MessageLookupByLibrary.simpleMessage("Skriv inn albumnavn"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Angi kode"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
            "Angi koden fra vennen din for å få gratis lagringsplass for dere begge"),
        "enterDateOfBirth":
            MessageLookupByLibrary.simpleMessage("Bursdag (valgfritt)"),
        "enterEmail": MessageLookupByLibrary.simpleMessage("Skriv inn e-post"),
        "enterFileName":
            MessageLookupByLibrary.simpleMessage("Skriv inn filnavn"),
        "enterName": MessageLookupByLibrary.simpleMessage("Angi navn"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Angi et nytt passord vi kan bruke til å kryptere dataene dine"),
        "enterPassword": MessageLookupByLibrary.simpleMessage("Angi passord"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Angi et passord vi kan bruke til å kryptere dataene dine"),
        "enterPersonName":
            MessageLookupByLibrary.simpleMessage("Angi personnavn"),
        "enterPin": MessageLookupByLibrary.simpleMessage("Skriv inn PIN-koden"),
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
        "error": MessageLookupByLibrary.simpleMessage("Feil"),
        "everywhere": MessageLookupByLibrary.simpleMessage("Overalt"),
        "exif": MessageLookupByLibrary.simpleMessage("EXIF"),
        "existingUser":
            MessageLookupByLibrary.simpleMessage("Eksisterende bruker"),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
            "Denne lenken er utløpt. Vennligst velg en ny utløpstid eller deaktiver lenkeutløp."),
        "exportLogs": MessageLookupByLibrary.simpleMessage("Eksporter logger"),
        "exportYourData":
            MessageLookupByLibrary.simpleMessage("Eksporter dine data"),
        "extraPhotosFound":
            MessageLookupByLibrary.simpleMessage("Ekstra bilder funnet"),
        "extraPhotosFoundFor": m33,
        "faceNotClusteredYet": MessageLookupByLibrary.simpleMessage(
            "Ansikt ikke gruppert ennå, vennligst kom tilbake senere"),
        "faceRecognition":
            MessageLookupByLibrary.simpleMessage("Ansiktsgjenkjenning"),
        "faces": MessageLookupByLibrary.simpleMessage("Ansikt"),
        "failed": MessageLookupByLibrary.simpleMessage("Mislykket"),
        "failedToApplyCode":
            MessageLookupByLibrary.simpleMessage("Kunne ikke bruke koden"),
        "failedToCancel":
            MessageLookupByLibrary.simpleMessage("Kan ikke avbryte"),
        "failedToDownloadVideo":
            MessageLookupByLibrary.simpleMessage("Kan ikke laste ned video"),
        "failedToFetchActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Kunne ikke hente aktive økter"),
        "failedToFetchOriginalForEdit": MessageLookupByLibrary.simpleMessage(
            "Kunne ikke hente originalen for redigering"),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "Kan ikke hente vervedetaljer. Prøv igjen senere."),
        "failedToLoadAlbums":
            MessageLookupByLibrary.simpleMessage("Kunne ikke laste inn album"),
        "failedToPlayVideo":
            MessageLookupByLibrary.simpleMessage("Kunne ikke spille av video"),
        "failedToRefreshStripeSubscription":
            MessageLookupByLibrary.simpleMessage(
                "Kunne ikke oppdatere abonnement"),
        "failedToRenew":
            MessageLookupByLibrary.simpleMessage("Kunne ikke fornye"),
        "failedToVerifyPaymentStatus": MessageLookupByLibrary.simpleMessage(
            "Kunne ikke verifisere betalingsstatus"),
        "familyPlanOverview": MessageLookupByLibrary.simpleMessage(
            "Legg til 5 familiemedlemmer til det eksisterende abonnementet uten å betale ekstra.\n\nHvert medlem får sitt eget private område, og kan ikke se hverandres filer med mindre de er delt.\n\nFamilieabonnement er tilgjengelige for kunder som har et betalt Ente-abonnement.\n\nAbonner nå for å komme i gang!"),
        "familyPlanPortalTitle":
            MessageLookupByLibrary.simpleMessage("Familie"),
        "familyPlans":
            MessageLookupByLibrary.simpleMessage("Familieabonnementer"),
        "faq": MessageLookupByLibrary.simpleMessage("Ofte stilte spørsmål"),
        "faqs": MessageLookupByLibrary.simpleMessage("Ofte stilte spørsmål"),
        "favorite": MessageLookupByLibrary.simpleMessage("Favoritt"),
        "feastingWithThem": m34,
        "feedback": MessageLookupByLibrary.simpleMessage("Tilbakemelding"),
        "file": MessageLookupByLibrary.simpleMessage("Fil"),
        "fileFailedToSaveToGallery": MessageLookupByLibrary.simpleMessage(
            "Kunne ikke lagre filen i galleriet"),
        "fileInfoAddDescHint":
            MessageLookupByLibrary.simpleMessage("Legg til en beskrivelse..."),
        "fileNotUploadedYet": MessageLookupByLibrary.simpleMessage(
            "Filen er ikke lastet opp enda"),
        "fileSavedToGallery":
            MessageLookupByLibrary.simpleMessage("Fil lagret i galleriet"),
        "fileTypes": MessageLookupByLibrary.simpleMessage("Filtyper"),
        "fileTypesAndNames":
            MessageLookupByLibrary.simpleMessage("Filtyper og navn"),
        "filesBackedUpFromDevice": m35,
        "filesBackedUpInAlbum": m36,
        "filesDeleted":
            MessageLookupByLibrary.simpleMessage("Filene er slettet"),
        "filesSavedToGallery":
            MessageLookupByLibrary.simpleMessage("Filer lagret i galleriet"),
        "findPeopleByName":
            MessageLookupByLibrary.simpleMessage("Finn folk raskt med navn"),
        "findThemQuickly":
            MessageLookupByLibrary.simpleMessage("Finn dem raskt"),
        "flip": MessageLookupByLibrary.simpleMessage("Speilvend"),
        "food": MessageLookupByLibrary.simpleMessage("Kulinær glede"),
        "forYourMemories":
            MessageLookupByLibrary.simpleMessage("for dine minner"),
        "forgotPassword": MessageLookupByLibrary.simpleMessage("Glemt passord"),
        "foundFaces": MessageLookupByLibrary.simpleMessage("Fant ansikter"),
        "freeStorageClaimed": MessageLookupByLibrary.simpleMessage(
            "Gratis lagringplass aktivert"),
        "freeStorageOnReferralSuccess": m37,
        "freeStorageUsable": MessageLookupByLibrary.simpleMessage(
            "Gratis lagringsplass som kan brukes"),
        "freeTrial":
            MessageLookupByLibrary.simpleMessage("Gratis prøveversjon"),
        "freeTrialValidTill": m38,
        "freeUpAmount": m40,
        "freeUpDeviceSpace":
            MessageLookupByLibrary.simpleMessage("Frigjør plass på enheten"),
        "freeUpDeviceSpaceDesc": MessageLookupByLibrary.simpleMessage(
            "Spar plass på enheten ved å fjerne filer som allerede er sikkerhetskopiert."),
        "freeUpSpace":
            MessageLookupByLibrary.simpleMessage("Frigjør lagringsplass"),
        "gallery": MessageLookupByLibrary.simpleMessage("Galleri"),
        "galleryMemoryLimitInfo": MessageLookupByLibrary.simpleMessage(
            "Opptil 1000 minner vist i galleriet"),
        "general": MessageLookupByLibrary.simpleMessage("Generelt"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Genererer krypteringsnøkler..."),
        "genericProgress": m42,
        "goToSettings":
            MessageLookupByLibrary.simpleMessage("Gå til innstillinger"),
        "googlePlayId": MessageLookupByLibrary.simpleMessage("Google Play ID"),
        "grantFullAccessPrompt": MessageLookupByLibrary.simpleMessage(
            "Vennligst gi tilgang til alle bilder i Innstillinger-appen"),
        "grantPermission":
            MessageLookupByLibrary.simpleMessage("Gi tillatelse"),
        "greenery": MessageLookupByLibrary.simpleMessage("Det grønne livet"),
        "groupNearbyPhotos":
            MessageLookupByLibrary.simpleMessage("Grupper nærliggende bilder"),
        "guestView": MessageLookupByLibrary.simpleMessage("Gjestevisning"),
        "guestViewEnablePreSteps": MessageLookupByLibrary.simpleMessage(
            "For å aktivere gjestevisning, vennligst konfigurer enhetens passord eller skjermlås i systeminnstillingene."),
        "hearUsExplanation": MessageLookupByLibrary.simpleMessage(
            "Vi sporer ikke app-installasjoner. Det hadde vært til hjelp om du fortalte oss hvor du fant oss!"),
        "hearUsWhereTitle": MessageLookupByLibrary.simpleMessage(
            "Hvordan fikk du høre om Ente? (valgfritt)"),
        "help": MessageLookupByLibrary.simpleMessage("Hjelp"),
        "hidden": MessageLookupByLibrary.simpleMessage("Skjult"),
        "hide": MessageLookupByLibrary.simpleMessage("Skjul"),
        "hideContent": MessageLookupByLibrary.simpleMessage("Skjul innhold"),
        "hideContentDescriptionAndroid": MessageLookupByLibrary.simpleMessage(
            "Skjuler appinnhold i appveksleren og deaktiverer skjermbilder"),
        "hideContentDescriptionIos": MessageLookupByLibrary.simpleMessage(
            "Skjuler appinnhold i appveksleren"),
        "hideSharedItemsFromHomeGallery": MessageLookupByLibrary.simpleMessage(
            "Skjul delte elementer fra hjemgalleriet"),
        "hiding": MessageLookupByLibrary.simpleMessage("Skjuler..."),
        "hikingWithThem": m43,
        "hostedAtOsmFrance":
            MessageLookupByLibrary.simpleMessage("Hostet på OSM France"),
        "howItWorks":
            MessageLookupByLibrary.simpleMessage("Hvordan det fungerer"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "Vennligst be dem om å trykke og holde inne på e-postadressen sin på innstillingsskjermen, og bekreft at ID-ene på begge enhetene er like."),
        "iOSGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "Biometrisk autentisering er ikke satt opp på enheten din. Aktiver enten Touch-ID eller Ansikts-ID på telefonen."),
        "iOSLockOut": MessageLookupByLibrary.simpleMessage(
            "Biometrisk autentisering er deaktivert. Vennligst lås og lås opp skjermen for å aktivere den."),
        "iOSOkButton": MessageLookupByLibrary.simpleMessage("OK"),
        "ignoreUpdate": MessageLookupByLibrary.simpleMessage("Ignorer"),
        "ignored": MessageLookupByLibrary.simpleMessage("ignorert"),
        "ignoredFolderUploadReason": MessageLookupByLibrary.simpleMessage(
            "Noen filer i dette albumet ble ikke lastet opp fordi de tidligere har blitt slettet fra Ente."),
        "imageNotAnalyzed":
            MessageLookupByLibrary.simpleMessage("Bilde ikke analysert"),
        "immediately": MessageLookupByLibrary.simpleMessage("Umiddelbart"),
        "importing": MessageLookupByLibrary.simpleMessage("Importerer...."),
        "incorrectCode": MessageLookupByLibrary.simpleMessage("Feil kode"),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Feil passord"),
        "incorrectRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Feil gjenopprettingsnøkkel"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "Gjennopprettingsnøkkelen du skrev inn er feil"),
        "incorrectRecoveryKeyTitle":
            MessageLookupByLibrary.simpleMessage("Feil gjenopprettingsnøkkel"),
        "indexedItems":
            MessageLookupByLibrary.simpleMessage("Indekserte elementer"),
        "ineligible": MessageLookupByLibrary.simpleMessage("Ikke aktuell"),
        "info": MessageLookupByLibrary.simpleMessage("Info"),
        "insecureDevice": MessageLookupByLibrary.simpleMessage("Usikker enhet"),
        "installManually":
            MessageLookupByLibrary.simpleMessage("Installer manuelt"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("Ugyldig e-postadresse"),
        "invalidEndpoint":
            MessageLookupByLibrary.simpleMessage("Ugyldig endepunkt"),
        "invalidEndpointMessage": MessageLookupByLibrary.simpleMessage(
            "Beklager, endepunktet du skrev inn er ugyldig. Skriv inn et gyldig endepunkt og prøv igjen."),
        "invalidKey": MessageLookupByLibrary.simpleMessage("Ugyldig nøkkel"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Gjenopprettingsnøkkelen du har skrevet inn er ikke gyldig. Kontroller at den inneholder 24 ord og kontroller stavemåten av hvert ord.\n\nHvis du har angitt en eldre gjenopprettingskode, må du kontrollere at den er 64 tegn lang, og kontrollere hvert av dem."),
        "invite": MessageLookupByLibrary.simpleMessage("Inviter"),
        "inviteToEnte":
            MessageLookupByLibrary.simpleMessage("Inviter til Ente"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Inviter vennene dine"),
        "inviteYourFriendsToEnte": MessageLookupByLibrary.simpleMessage(
            "Inviter vennene dine til Ente"),
        "itLooksLikeSomethingWentWrongPleaseRetryAfterSome":
            MessageLookupByLibrary.simpleMessage(
                "Det ser ut til at noe gikk galt. Prøv på nytt etter en stund. Hvis feilen vedvarer, kan du kontakte kundestøtte."),
        "itemCount": m44,
        "itemsShowTheNumberOfDaysRemainingBeforePermanentDeletion":
            MessageLookupByLibrary.simpleMessage(
                "Elementer viser gjenværende dager før de slettes for godt"),
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "Valgte elementer vil bli fjernet fra dette albumet"),
        "join": MessageLookupByLibrary.simpleMessage("Bli med"),
        "joinAlbum": MessageLookupByLibrary.simpleMessage("Bli med i albumet"),
        "joinAlbumConfirmationDialogBody": MessageLookupByLibrary.simpleMessage(
            "Å bli med i et album vil gjøre e-postadressen din synlig for dens deltakere."),
        "joinAlbumSubtext": MessageLookupByLibrary.simpleMessage(
            "for å se og legge til bildene dine"),
        "joinAlbumSubtextViewer": MessageLookupByLibrary.simpleMessage(
            "for å legge dette til til delte album"),
        "joinDiscord":
            MessageLookupByLibrary.simpleMessage("Bli med i Discord"),
        "keepPhotos": MessageLookupByLibrary.simpleMessage("Behold Bilder"),
        "kiloMeterUnit": MessageLookupByLibrary.simpleMessage("km"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Vær vennlig og hjelp oss med denne informasjonen"),
        "language": MessageLookupByLibrary.simpleMessage("Språk"),
        "lastTimeWithThem": m45,
        "lastUpdated": MessageLookupByLibrary.simpleMessage("Sist oppdatert"),
        "lastYearsTrip": MessageLookupByLibrary.simpleMessage("Fjorårets tur"),
        "leave": MessageLookupByLibrary.simpleMessage("Forlat"),
        "leaveAlbum": MessageLookupByLibrary.simpleMessage("Forlat album"),
        "leaveFamily": MessageLookupByLibrary.simpleMessage("Forlat familie"),
        "leaveSharedAlbum":
            MessageLookupByLibrary.simpleMessage("Slett delt album?"),
        "left": MessageLookupByLibrary.simpleMessage("Venstre"),
        "legacy": MessageLookupByLibrary.simpleMessage("Arv"),
        "legacyAccounts": MessageLookupByLibrary.simpleMessage("Eldre kontoer"),
        "legacyInvite": m46,
        "legacyPageDesc": MessageLookupByLibrary.simpleMessage(
            "Arv-funksjonen lar betrodde kontakter få tilgang til kontoen din i ditt fravær."),
        "legacyPageDesc2": MessageLookupByLibrary.simpleMessage(
            "Betrodde kontakter kan starte gjenoppretting av kontoen, og hvis de ikke blir blokkert innen 30 dager, tilbakestille passordet ditt og få tilgang til kontoen din."),
        "light": MessageLookupByLibrary.simpleMessage("Lys"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("Lys"),
        "link": MessageLookupByLibrary.simpleMessage("Lenke"),
        "linkCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Lenker er kopiert til utklippstavlen"),
        "linkDeviceLimit": MessageLookupByLibrary.simpleMessage("Enhetsgrense"),
        "linkEmail": MessageLookupByLibrary.simpleMessage("Koble til e-post"),
        "linkEmailToContactBannerCaption":
            MessageLookupByLibrary.simpleMessage("for raskere deling"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Aktivert"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Utløpt"),
        "linkExpiresOn": m47,
        "linkExpiry": MessageLookupByLibrary.simpleMessage("Lenkeutløp"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("Lenken har utløpt"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Aldri"),
        "linkPerson": MessageLookupByLibrary.simpleMessage("Knytt til person"),
        "linkPersonCaption":
            MessageLookupByLibrary.simpleMessage("for bedre delingsopplevelse"),
        "linkPersonToEmail": m48,
        "linkPersonToEmailConfirmation": m49,
        "livePhotos": MessageLookupByLibrary.simpleMessage("Live-bilder"),
        "loadMessage1": MessageLookupByLibrary.simpleMessage(
            "Du kan dele abonnementet med familien din"),
        "loadMessage3": MessageLookupByLibrary.simpleMessage(
            "Vi beholder 3 kopier av dine data, en i en underjordisk bunker"),
        "loadMessage4": MessageLookupByLibrary.simpleMessage(
            "Alle våre apper har åpen kildekode"),
        "loadMessage5": MessageLookupByLibrary.simpleMessage(
            "Vår kildekode og kryptografi har blitt revidert eksternt"),
        "loadMessage6": MessageLookupByLibrary.simpleMessage(
            "Du kan dele lenker til dine album med dine kjære"),
        "loadMessage7": MessageLookupByLibrary.simpleMessage(
            "Våre mobilapper kjører i bakgrunnen for å kryptere og sikkerhetskopiere de nye bildene du klikker"),
        "loadMessage8": MessageLookupByLibrary.simpleMessage(
            "web.ente.io har en flott opplaster"),
        "loadMessage9": MessageLookupByLibrary.simpleMessage(
            "Vi bruker Xcha20Poly1305 for å trygt kryptere dataene dine"),
        "loadingExifData":
            MessageLookupByLibrary.simpleMessage("Laster inn EXIF-data..."),
        "loadingGallery":
            MessageLookupByLibrary.simpleMessage("Laster galleri..."),
        "loadingMessage":
            MessageLookupByLibrary.simpleMessage("Laster bildene dine..."),
        "loadingModel":
            MessageLookupByLibrary.simpleMessage("Laster ned modeller..."),
        "loadingYourPhotos":
            MessageLookupByLibrary.simpleMessage("Laster bildene dine..."),
        "localGallery": MessageLookupByLibrary.simpleMessage("Lokalt galleri"),
        "localIndexing":
            MessageLookupByLibrary.simpleMessage("Lokal indeksering"),
        "localSyncErrorMessage": MessageLookupByLibrary.simpleMessage(
            "Ser ut som noe gikk galt siden lokal synkronisering av bilder tar lengre tid enn forventet. Vennligst kontakt vårt supportteam"),
        "location": MessageLookupByLibrary.simpleMessage("Plassering"),
        "locationName": MessageLookupByLibrary.simpleMessage("Stedsnavn"),
        "locationTagFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "En plasseringsetikett grupperer alle bilder som ble tatt innenfor en gitt radius av et bilde"),
        "locations": MessageLookupByLibrary.simpleMessage("Plasseringer"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Lås"),
        "lockscreen": MessageLookupByLibrary.simpleMessage("Låseskjerm"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Logg inn"),
        "loggingOut": MessageLookupByLibrary.simpleMessage("Logger ut..."),
        "loginSessionExpired":
            MessageLookupByLibrary.simpleMessage("Økten har utløpt"),
        "loginSessionExpiredDetails": MessageLookupByLibrary.simpleMessage(
            "Økten er utløpt. Vennligst logg inn på nytt."),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "Ved å klikke Logg inn, godtar jeg <u-terms>brukervilkårene</u-terms> og <u-policy>personvernreglene</u-policy>"),
        "loginWithTOTP":
            MessageLookupByLibrary.simpleMessage("Pålogging med TOTP"),
        "logout": MessageLookupByLibrary.simpleMessage("Logg ut"),
        "logsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Dette vil sende over logger for å hjelpe oss med å feilsøke problemet. Vær oppmerksom på at filnavn vil bli inkludert for å hjelpe å spore problemer med spesifikke filer."),
        "longPressAnEmailToVerifyEndToEndEncryption":
            MessageLookupByLibrary.simpleMessage(
                "Trykk og hold på en e-post for å bekrefte ende-til-ende-kryptering."),
        "longpressOnAnItemToViewInFullscreen":
            MessageLookupByLibrary.simpleMessage(
                "Lang-trykk på en gjenstand for å vise i fullskjerm"),
        "loopVideoOff": MessageLookupByLibrary.simpleMessage("Gjenta video av"),
        "loopVideoOn": MessageLookupByLibrary.simpleMessage("Gjenta video på"),
        "lostDevice": MessageLookupByLibrary.simpleMessage("Mistet enhet?"),
        "machineLearning": MessageLookupByLibrary.simpleMessage("Maskinlæring"),
        "magicSearch": MessageLookupByLibrary.simpleMessage("Magisk søk"),
        "magicSearchHint": MessageLookupByLibrary.simpleMessage(
            "Magisk søk lar deg finne bilder basert på innholdet i dem, for eksempel ‘blomst’, ‘rød bil’, ‘ID-dokumenter\'"),
        "manage": MessageLookupByLibrary.simpleMessage("Administrer"),
        "manageDeviceStorage": MessageLookupByLibrary.simpleMessage(
            "Behandle enhetens hurtigbuffer"),
        "manageDeviceStorageDesc": MessageLookupByLibrary.simpleMessage(
            "Gjennomgå og fjern lokal hurtigbuffer."),
        "manageFamily":
            MessageLookupByLibrary.simpleMessage("Administrer familie"),
        "manageLink": MessageLookupByLibrary.simpleMessage("Administrer lenke"),
        "manageParticipants":
            MessageLookupByLibrary.simpleMessage("Administrer"),
        "manageSubscription":
            MessageLookupByLibrary.simpleMessage("Administrer abonnement"),
        "manualPairDesc": MessageLookupByLibrary.simpleMessage(
            "Koble til PIN fungerer med alle skjermer du vil se albumet på."),
        "map": MessageLookupByLibrary.simpleMessage("Kart"),
        "maps": MessageLookupByLibrary.simpleMessage("Kart"),
        "mastodon": MessageLookupByLibrary.simpleMessage("Mastodon"),
        "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
        "me": MessageLookupByLibrary.simpleMessage("Meg"),
        "memoryCount": m50,
        "merchandise": MessageLookupByLibrary.simpleMessage("Varer"),
        "mergeWithExisting":
            MessageLookupByLibrary.simpleMessage("Slå sammen med eksisterende"),
        "mergedPhotos":
            MessageLookupByLibrary.simpleMessage("Sammenslåtte bilder"),
        "mlConsent":
            MessageLookupByLibrary.simpleMessage("Aktiver maskinlæring"),
        "mlConsentConfirmation": MessageLookupByLibrary.simpleMessage(
            "Jeg forstår, og ønsker å aktivere maskinlæring"),
        "mlConsentDescription": MessageLookupByLibrary.simpleMessage(
            "Hvis du aktiverer maskinlæring, vil Ente hente ut informasjon som ansiktsgeometri fra filer, inkludert de som er delt med deg.\n\nDette skjer på enheten din, og all generert biometrisk informasjon blir ende-til-ende-kryptert."),
        "mlConsentPrivacy": MessageLookupByLibrary.simpleMessage(
            "Klikk her for mer informasjon om denne funksjonen i våre retningslinjer for personvern"),
        "mlConsentTitle":
            MessageLookupByLibrary.simpleMessage("Aktiver maskinlæring?"),
        "mlIndexingDescription": MessageLookupByLibrary.simpleMessage(
            "Vær oppmerksom på at maskinlæring vil resultere i høyere båndbredde og batteribruk inntil alle elementer er indeksert. Vurder å bruke skrivebordsappen for raskere indeksering, alle resultater vil bli synkronisert automatisk."),
        "mobileWebDesktop":
            MessageLookupByLibrary.simpleMessage("Mobil, Web, Datamaskin"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Moderat"),
        "modifyYourQueryOrTrySearchingFor":
            MessageLookupByLibrary.simpleMessage(
                "Juster søket ditt, eller prøv å søke etter"),
        "moments": MessageLookupByLibrary.simpleMessage("Øyeblikk"),
        "month": MessageLookupByLibrary.simpleMessage("måned"),
        "monthly": MessageLookupByLibrary.simpleMessage("Månedlig"),
        "moon": MessageLookupByLibrary.simpleMessage("I månelyset"),
        "moreDetails": MessageLookupByLibrary.simpleMessage("Flere detaljer"),
        "mostRecent": MessageLookupByLibrary.simpleMessage("Nyeste"),
        "mostRelevant": MessageLookupByLibrary.simpleMessage("Mest relevant"),
        "mountains": MessageLookupByLibrary.simpleMessage("Over åsene"),
        "moveItem": m51,
        "moveSelectedPhotosToOneDate": MessageLookupByLibrary.simpleMessage(
            "Flytt valgte bilder til en dato"),
        "moveToAlbum": MessageLookupByLibrary.simpleMessage("Flytt til album"),
        "moveToHiddenAlbum":
            MessageLookupByLibrary.simpleMessage("Flytt til skjult album"),
        "movedSuccessfullyTo": m52,
        "movedToTrash":
            MessageLookupByLibrary.simpleMessage("Flyttet til papirkurven"),
        "movingFilesToAlbum":
            MessageLookupByLibrary.simpleMessage("Flytter filer til album..."),
        "name": MessageLookupByLibrary.simpleMessage("Navn"),
        "nameTheAlbum": MessageLookupByLibrary.simpleMessage("Navngi albumet"),
        "networkConnectionRefusedErr": MessageLookupByLibrary.simpleMessage(
            "Kan ikke koble til Ente, prøv igjen etter en stund. Hvis feilen vedvarer, vennligst kontakt kundestøtte."),
        "networkHostLookUpErr": MessageLookupByLibrary.simpleMessage(
            "Kan ikke koble til Ente, kontroller nettverksinnstillingene og kontakt kundestøtte hvis feilen vedvarer."),
        "never": MessageLookupByLibrary.simpleMessage("Aldri"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Nytt album"),
        "newLocation": MessageLookupByLibrary.simpleMessage("Ny plassering"),
        "newPerson": MessageLookupByLibrary.simpleMessage("Ny person"),
        "newRange": MessageLookupByLibrary.simpleMessage("Ny rekkevidde"),
        "newToEnte": MessageLookupByLibrary.simpleMessage("Ny til Ente"),
        "newest": MessageLookupByLibrary.simpleMessage("Nyeste"),
        "next": MessageLookupByLibrary.simpleMessage("Neste"),
        "no": MessageLookupByLibrary.simpleMessage("Nei"),
        "noAlbumsSharedByYouYet": MessageLookupByLibrary.simpleMessage(
            "Ingen album delt av deg enda"),
        "noDeviceFound":
            MessageLookupByLibrary.simpleMessage("Ingen enheter funnet"),
        "noDeviceLimit": MessageLookupByLibrary.simpleMessage("Ingen"),
        "noDeviceThatCanBeDeleted": MessageLookupByLibrary.simpleMessage(
            "Du har ingen filer i dette albumet som kan bli slettet"),
        "noDuplicates":
            MessageLookupByLibrary.simpleMessage("✨ Ingen duplikater"),
        "noEnteAccountExclamation":
            MessageLookupByLibrary.simpleMessage("Ingen Ente-konto!"),
        "noExifData": MessageLookupByLibrary.simpleMessage("Ingen EXIF-data"),
        "noFacesFound":
            MessageLookupByLibrary.simpleMessage("Ingen ansikter funnet"),
        "noHiddenPhotosOrVideos": MessageLookupByLibrary.simpleMessage(
            "Ingen skjulte bilder eller videoer"),
        "noImagesWithLocation":
            MessageLookupByLibrary.simpleMessage("Ingen bilder med plassering"),
        "noInternetConnection":
            MessageLookupByLibrary.simpleMessage("Ingen nettverksforbindelse"),
        "noPhotosAreBeingBackedUpRightNow":
            MessageLookupByLibrary.simpleMessage(
                "Ingen bilder er blitt sikkerhetskopiert akkurat nå"),
        "noPhotosFoundHere":
            MessageLookupByLibrary.simpleMessage("Ingen bilder funnet her"),
        "noQuickLinksSelected":
            MessageLookupByLibrary.simpleMessage("Ingen hurtiglenker er valgt"),
        "noRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Ingen gjenopprettingsnøkkel?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "Grunnet vår type ente-til-ende-krypteringsprotokoll kan ikke dine data dekrypteres uten passordet ditt eller gjenopprettingsnøkkelen din"),
        "noResults": MessageLookupByLibrary.simpleMessage("Ingen resultater"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("Ingen resultater funnet"),
        "noSuggestionsForPerson": m53,
        "noSystemLockFound":
            MessageLookupByLibrary.simpleMessage("Ingen systemlås funnet"),
        "notPersonLabel": m54,
        "notThisPerson":
            MessageLookupByLibrary.simpleMessage("Ikke denne personen?"),
        "nothingSharedWithYouYet":
            MessageLookupByLibrary.simpleMessage("Ingenting delt med deg enda"),
        "nothingToSeeHere":
            MessageLookupByLibrary.simpleMessage("Ingenting å se her! 👀"),
        "notifications": MessageLookupByLibrary.simpleMessage("Varslinger"),
        "ok": MessageLookupByLibrary.simpleMessage("Ok"),
        "onDevice": MessageLookupByLibrary.simpleMessage("På enhet"),
        "onEnte": MessageLookupByLibrary.simpleMessage(
            "På <branding>ente</branding>"),
        "onTheRoad": MessageLookupByLibrary.simpleMessage("På veien igjen"),
        "onlyFamilyAdminCanChangeCode": m55,
        "onlyThem": MessageLookupByLibrary.simpleMessage("Bare de"),
        "oops": MessageLookupByLibrary.simpleMessage("Oisann"),
        "oopsCouldNotSaveEdits": MessageLookupByLibrary.simpleMessage(
            "Oisann, kunne ikke lagre endringer"),
        "oopsSomethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Oisann! Noe gikk galt"),
        "openAlbumInBrowser":
            MessageLookupByLibrary.simpleMessage("Åpne album i nettleser"),
        "openAlbumInBrowserTitle": MessageLookupByLibrary.simpleMessage(
            "Vennligst bruk webapplikasjonen for å legge til bilder til dette albumet"),
        "openFile": MessageLookupByLibrary.simpleMessage("Åpne fil"),
        "openSettings":
            MessageLookupByLibrary.simpleMessage("Åpne innstillinger"),
        "openTheItem": MessageLookupByLibrary.simpleMessage("• Åpne elementet"),
        "openstreetmapContributors":
            MessageLookupByLibrary.simpleMessage("OpenStreetMap bidragsytere"),
        "optionalAsShortAsYouLike": MessageLookupByLibrary.simpleMessage(
            "Valgfri, så kort som du vil..."),
        "orMergeWithExistingPerson": MessageLookupByLibrary.simpleMessage(
            "Eller slå sammen med eksisterende"),
        "orPickAnExistingOne":
            MessageLookupByLibrary.simpleMessage("Eller velg en eksisterende"),
        "orPickFromYourContacts": MessageLookupByLibrary.simpleMessage(
            "Eller velg fra kontaktene dine"),
        "pair": MessageLookupByLibrary.simpleMessage("Par"),
        "pairWithPin":
            MessageLookupByLibrary.simpleMessage("Parr sammen med PIN"),
        "pairingComplete":
            MessageLookupByLibrary.simpleMessage("Sammenkobling fullført"),
        "panorama": MessageLookupByLibrary.simpleMessage("Panora"),
        "partyWithThem": m56,
        "passKeyPendingVerification":
            MessageLookupByLibrary.simpleMessage("Bekreftelse venter fortsatt"),
        "passkey": MessageLookupByLibrary.simpleMessage("Tilgangsnøkkel"),
        "passkeyAuthTitle": MessageLookupByLibrary.simpleMessage(
            "Verifisering av tilgangsnøkkel"),
        "password": MessageLookupByLibrary.simpleMessage("Passord"),
        "passwordChangedSuccessfully":
            MessageLookupByLibrary.simpleMessage("Passordet ble endret"),
        "passwordLock": MessageLookupByLibrary.simpleMessage("Passordlås"),
        "passwordStrength": m57,
        "passwordStrengthInfo": MessageLookupByLibrary.simpleMessage(
            "Passordstyrken beregnes basert på passordets lengde, brukte tegn, og om passordet finnes blant de 10 000 mest brukte passordene"),
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Vi lagrer ikke dette passordet, så hvis du glemmer det, <underline>kan vi ikke dekryptere dataene dine</underline>"),
        "paymentDetails":
            MessageLookupByLibrary.simpleMessage("Betalingsinformasjon"),
        "paymentFailed":
            MessageLookupByLibrary.simpleMessage("Betaling feilet"),
        "paymentFailedMessage": MessageLookupByLibrary.simpleMessage(
            "Betalingen din mislyktes. Kontakt kundestøtte og vi vil hjelpe deg!"),
        "paymentFailedTalkToProvider": m58,
        "pendingItems":
            MessageLookupByLibrary.simpleMessage("Ventende elementer"),
        "pendingSync":
            MessageLookupByLibrary.simpleMessage("Ventende synkronisering"),
        "people": MessageLookupByLibrary.simpleMessage("Folk"),
        "peopleUsingYourCode": MessageLookupByLibrary.simpleMessage(
            "Personer som bruker koden din"),
        "permDeleteWarning": MessageLookupByLibrary.simpleMessage(
            "Alle elementer i papirkurven vil slettes permanent\n\nDenne handlingen kan ikke angres"),
        "permanentlyDelete":
            MessageLookupByLibrary.simpleMessage("Slette for godt"),
        "permanentlyDeleteFromDevice":
            MessageLookupByLibrary.simpleMessage("Slett permanent fra enhet?"),
        "personIsAge": m59,
        "personName": MessageLookupByLibrary.simpleMessage("Personnavn"),
        "personTurningAge": m60,
        "pets": MessageLookupByLibrary.simpleMessage("Pelsvenner"),
        "photoDescriptions":
            MessageLookupByLibrary.simpleMessage("Bildebeskrivelser"),
        "photoGridSize":
            MessageLookupByLibrary.simpleMessage("Bilderutenettstørrelse"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("bilde"),
        "photocountPhotos": m61,
        "photos": MessageLookupByLibrary.simpleMessage("Bilder"),
        "photosAddedByYouWillBeRemovedFromTheAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Bilder lagt til av deg vil bli fjernet fra albumet"),
        "photosKeepRelativeTimeDifference":
            MessageLookupByLibrary.simpleMessage(
                "Bilder holder relativ tidsforskjell"),
        "pickCenterPoint":
            MessageLookupByLibrary.simpleMessage("Velg midtpunkt"),
        "pinAlbum": MessageLookupByLibrary.simpleMessage("Fest album"),
        "pinLock": MessageLookupByLibrary.simpleMessage("PIN-kode lås"),
        "playOnTv":
            MessageLookupByLibrary.simpleMessage("Spill av album på TV"),
        "playOriginal":
            MessageLookupByLibrary.simpleMessage("Spill av original"),
        "playStoreFreeTrialValidTill": m63,
        "playStream": MessageLookupByLibrary.simpleMessage("Spill av strøm"),
        "playstoreSubscription":
            MessageLookupByLibrary.simpleMessage("PlayStore abonnement"),
        "pleaseCheckYourInternetConnectionAndTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Kontroller Internett-tilkoblingen din og prøv igjen."),
        "pleaseContactSupportAndWeWillBeHappyToHelp":
            MessageLookupByLibrary.simpleMessage(
                "Vennligst kontakt support@ente.io og vi vil gjerne hjelpe!"),
        "pleaseContactSupportIfTheProblemPersists":
            MessageLookupByLibrary.simpleMessage(
                "Vennligst kontakt kundestøtte hvis problemet vedvarer"),
        "pleaseEmailUsAt": m64,
        "pleaseGrantPermissions":
            MessageLookupByLibrary.simpleMessage("Vennligst gi tillatelser"),
        "pleaseLoginAgain":
            MessageLookupByLibrary.simpleMessage("Vennligst logg inn igjen"),
        "pleaseSelectQuickLinksToRemove":
            MessageLookupByLibrary.simpleMessage("Velg hurtiglenker å fjerne"),
        "pleaseSendTheLogsTo": m65,
        "pleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("Vennligst prøv igjen"),
        "pleaseVerifyTheCodeYouHaveEntered":
            MessageLookupByLibrary.simpleMessage(
                "Bekreft koden du har skrevet inn"),
        "pleaseWait": MessageLookupByLibrary.simpleMessage("Vennligst vent..."),
        "pleaseWaitDeletingAlbum": MessageLookupByLibrary.simpleMessage(
            "Vennligst vent, sletter album"),
        "pleaseWaitForSometimeBeforeRetrying":
            MessageLookupByLibrary.simpleMessage(
                "Vennligst vent en stund før du prøver på nytt"),
        "pleaseWaitThisWillTakeAWhile": MessageLookupByLibrary.simpleMessage(
            "Vennligst vent, dette vil ta litt tid."),
        "posingWithThem": m66,
        "preparingLogs":
            MessageLookupByLibrary.simpleMessage("Forbereder logger..."),
        "preserveMore": MessageLookupByLibrary.simpleMessage("Behold mer"),
        "pressAndHoldToPlayVideo": MessageLookupByLibrary.simpleMessage(
            "Trykk og hold inne for å spille av video"),
        "pressAndHoldToPlayVideoDetailed": MessageLookupByLibrary.simpleMessage(
            "Trykk og hold inne bildet for å spille av video"),
        "previous": MessageLookupByLibrary.simpleMessage("Forrige"),
        "privacy": MessageLookupByLibrary.simpleMessage("Personvern"),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Personvernserklæring"),
        "privateBackups":
            MessageLookupByLibrary.simpleMessage("Private sikkerhetskopier"),
        "privateSharing": MessageLookupByLibrary.simpleMessage("Privat deling"),
        "proceed": MessageLookupByLibrary.simpleMessage("Fortsett"),
        "processed": MessageLookupByLibrary.simpleMessage("Behandlet"),
        "processing": MessageLookupByLibrary.simpleMessage("Behandler"),
        "processingImport": m67,
        "processingVideos":
            MessageLookupByLibrary.simpleMessage("Behandler videoer"),
        "publicLinkCreated":
            MessageLookupByLibrary.simpleMessage("Offentlig lenke opprettet"),
        "publicLinkEnabled":
            MessageLookupByLibrary.simpleMessage("Offentlig lenke aktivert"),
        "queued": MessageLookupByLibrary.simpleMessage("I køen"),
        "quickLinks": MessageLookupByLibrary.simpleMessage("Hurtiglenker"),
        "radius": MessageLookupByLibrary.simpleMessage("Radius"),
        "raiseTicket": MessageLookupByLibrary.simpleMessage("Opprett sak"),
        "rateTheApp": MessageLookupByLibrary.simpleMessage("Vurder appen"),
        "rateUs": MessageLookupByLibrary.simpleMessage("Vurder oss"),
        "rateUsOnStore": m68,
        "reassignMe": MessageLookupByLibrary.simpleMessage("Tildel \"Meg\""),
        "reassignedToName": m69,
        "reassigningLoading":
            MessageLookupByLibrary.simpleMessage("Tildeler..."),
        "recover": MessageLookupByLibrary.simpleMessage("Gjenopprett"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("Gjenopprett konto"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Gjenopprett"),
        "recoveryAccount":
            MessageLookupByLibrary.simpleMessage("Gjenopprett konto"),
        "recoveryInitiated":
            MessageLookupByLibrary.simpleMessage("Gjenoppretting startet"),
        "recoveryInitiatedDesc": m70,
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
        "recoveryKeyVerifyReason": MessageLookupByLibrary.simpleMessage(
            "Gjenopprettingsnøkkelen er den eneste måten å gjenopprette bildene dine på hvis du glemmer passordet ditt. Du finner gjenopprettingsnøkkelen din i Innstillinger > Konto.\n\nVennligst skriv inn gjenopprettingsnøkkelen din her for å bekrefte at du har lagret den riktig."),
        "recoveryReady": m71,
        "recoverySuccessful": MessageLookupByLibrary.simpleMessage(
            "Gjenopprettingen var vellykket!"),
        "recoveryWarning": MessageLookupByLibrary.simpleMessage(
            "En betrodd kontakt prøver å få tilgang til kontoen din"),
        "recoveryWarningBody": m72,
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "Den gjeldende enheten er ikke kraftig nok til å verifisere passordet ditt, men vi kan regenerere på en måte som fungerer på alle enheter.\n\nVennligst logg inn med gjenopprettingsnøkkelen og regenerer passordet (du kan bruke den samme igjen om du vil)."),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Gjenopprett passord"),
        "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
        "reenterPassword":
            MessageLookupByLibrary.simpleMessage("Skriv inn passord på nytt"),
        "reenterPin":
            MessageLookupByLibrary.simpleMessage("Skriv inn PIN-kode på nytt"),
        "referFriendsAnd2xYourPlan": MessageLookupByLibrary.simpleMessage(
            "Verv venner og doble abonnementet ditt"),
        "referralStep1": MessageLookupByLibrary.simpleMessage(
            "1. Gi denne koden til vennene dine"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "De registrerer seg for en betalt plan"),
        "referralStep3": m73,
        "referrals": MessageLookupByLibrary.simpleMessage("Vervinger"),
        "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
            "Vervinger er for øyeblikket satt på pause"),
        "rejectRecovery":
            MessageLookupByLibrary.simpleMessage("Avslå gjenoppretting"),
        "remindToEmptyDeviceTrash": MessageLookupByLibrary.simpleMessage(
            "Tøm også \"Nylig slettet\" fra \"Innstillinger\" → \"Lagring\" for å få frigjort plass"),
        "remindToEmptyEnteTrash": MessageLookupByLibrary.simpleMessage(
            "Du kan også tømme \"Papirkurven\" for å få den frigjorte lagringsplassen"),
        "remoteImages": MessageLookupByLibrary.simpleMessage("Eksterne bilder"),
        "remoteThumbnails":
            MessageLookupByLibrary.simpleMessage("Eksterne miniatyrbilder"),
        "remoteVideos":
            MessageLookupByLibrary.simpleMessage("Eksterne videoer"),
        "remove": MessageLookupByLibrary.simpleMessage("Fjern"),
        "removeDuplicates":
            MessageLookupByLibrary.simpleMessage("Fjern duplikater"),
        "removeDuplicatesDesc": MessageLookupByLibrary.simpleMessage(
            "Gjennomgå og fjern filer som er eksakte duplikater."),
        "removeFromAlbum":
            MessageLookupByLibrary.simpleMessage("Fjern fra album"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("Fjern fra album?"),
        "removeFromFavorite":
            MessageLookupByLibrary.simpleMessage("Fjern fra favoritter"),
        "removeInvite":
            MessageLookupByLibrary.simpleMessage("Fjern invitasjon"),
        "removeLink": MessageLookupByLibrary.simpleMessage("Fjern lenke"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Fjern deltaker"),
        "removeParticipantBody": m74,
        "removePersonLabel":
            MessageLookupByLibrary.simpleMessage("Fjern etikett for person"),
        "removePublicLink":
            MessageLookupByLibrary.simpleMessage("Fjern offentlig lenke"),
        "removePublicLinks":
            MessageLookupByLibrary.simpleMessage("Fjern offentlige lenker"),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
            "Noen av elementene du fjerner ble lagt til av andre personer, og du vil miste tilgang til dem"),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Fjern?"),
        "removeYourselfAsTrustedContact": MessageLookupByLibrary.simpleMessage(
            "Fjern deg selv som betrodd kontakt"),
        "removingFromFavorites":
            MessageLookupByLibrary.simpleMessage("Fjerner fra favoritter..."),
        "rename": MessageLookupByLibrary.simpleMessage("Endre navn"),
        "renameAlbum":
            MessageLookupByLibrary.simpleMessage("Gi album nytt navn"),
        "renameFile": MessageLookupByLibrary.simpleMessage("Gi nytt filnavn"),
        "renewSubscription":
            MessageLookupByLibrary.simpleMessage("Forny abonnement"),
        "renewsOn": m75,
        "reportABug": MessageLookupByLibrary.simpleMessage("Rapporter en feil"),
        "reportBug": MessageLookupByLibrary.simpleMessage("Rapporter feil"),
        "resendEmail":
            MessageLookupByLibrary.simpleMessage("Send e-posten på nytt"),
        "resetIgnoredFiles": MessageLookupByLibrary.simpleMessage(
            "Tilbakestill ignorerte filer"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Tilbakestill passord"),
        "resetPerson": MessageLookupByLibrary.simpleMessage("Fjern"),
        "resetToDefault":
            MessageLookupByLibrary.simpleMessage("Tilbakestill til standard"),
        "restore": MessageLookupByLibrary.simpleMessage("Gjenopprett"),
        "restoreToAlbum":
            MessageLookupByLibrary.simpleMessage("Gjenopprett til album"),
        "restoringFiles":
            MessageLookupByLibrary.simpleMessage("Gjenoppretter filer..."),
        "resumableUploads":
            MessageLookupByLibrary.simpleMessage("Fortsette opplastinger"),
        "retry": MessageLookupByLibrary.simpleMessage("Prøv på nytt"),
        "review": MessageLookupByLibrary.simpleMessage("Gjennomgå"),
        "reviewDeduplicateItems": MessageLookupByLibrary.simpleMessage(
            "Vennligst gjennomgå og slett elementene du tror er duplikater."),
        "reviewSuggestions":
            MessageLookupByLibrary.simpleMessage("Gjennomgå forslag"),
        "right": MessageLookupByLibrary.simpleMessage("Høyre"),
        "roadtripWithThem": m76,
        "rotate": MessageLookupByLibrary.simpleMessage("Roter"),
        "rotateLeft": MessageLookupByLibrary.simpleMessage("Roter mot venstre"),
        "rotateRight": MessageLookupByLibrary.simpleMessage("Roter mot høyre"),
        "safelyStored": MessageLookupByLibrary.simpleMessage("Trygt lagret"),
        "save": MessageLookupByLibrary.simpleMessage("Lagre"),
        "saveChangesBeforeLeavingQuestion":
            MessageLookupByLibrary.simpleMessage(
                "Lagre endringer før du drar?"),
        "saveCollage": MessageLookupByLibrary.simpleMessage("Lagre kollasje"),
        "saveCopy": MessageLookupByLibrary.simpleMessage("Lagre en kopi"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Lagre nøkkel"),
        "savePerson": MessageLookupByLibrary.simpleMessage("Lagre person"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Lagre gjenopprettingsnøkkelen hvis du ikke allerede har gjort det"),
        "saving": MessageLookupByLibrary.simpleMessage("Lagrer..."),
        "savingEdits":
            MessageLookupByLibrary.simpleMessage("Lagrer redigeringer..."),
        "scanCode": MessageLookupByLibrary.simpleMessage("Skann kode"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Skann denne strekkoden med\nautentiseringsappen din"),
        "search": MessageLookupByLibrary.simpleMessage("Søk"),
        "searchAlbumsEmptySection":
            MessageLookupByLibrary.simpleMessage("Album"),
        "searchByAlbumNameHint":
            MessageLookupByLibrary.simpleMessage("Albumnavn"),
        "searchByExamples": MessageLookupByLibrary.simpleMessage(
            "• Albumnavn (f.eks. \"Kamera\")\n• Filtyper (f.eks. \"Videoer\", \".gif\")\n• År og måneder (f.eks. \"2022\", \"January\")\n• Hellidager (f.eks. \"Jul\")\n• Bildebeskrivelser (f.eks. \"#moro\")"),
        "searchCaptionEmptySection": MessageLookupByLibrary.simpleMessage(
            "Legg til beskrivelser som \"#tur\" i bildeinfo for raskt å finne dem her"),
        "searchDatesEmptySection": MessageLookupByLibrary.simpleMessage(
            "Søk etter dato, måned eller år"),
        "searchDiscoverEmptySection": MessageLookupByLibrary.simpleMessage(
            "Bilder vil vises her når behandlingen og synkronisering er fullført"),
        "searchFaceEmptySection": MessageLookupByLibrary.simpleMessage(
            "Folk vil vises her når indeksering er gjort"),
        "searchFileTypesAndNamesEmptySection":
            MessageLookupByLibrary.simpleMessage("Filtyper og navn"),
        "searchHint1":
            MessageLookupByLibrary.simpleMessage("Raskt søk på enheten"),
        "searchHint2":
            MessageLookupByLibrary.simpleMessage("Bildedatoer, beskrivelser"),
        "searchHint3":
            MessageLookupByLibrary.simpleMessage("Albumer, filnavn og typer"),
        "searchHint4": MessageLookupByLibrary.simpleMessage("Plassering"),
        "searchHint5": MessageLookupByLibrary.simpleMessage(
            "Kommer snart: ansikt & magisk søk ✨"),
        "searchLocationEmptySection": MessageLookupByLibrary.simpleMessage(
            "Gruppebilder som er tatt innenfor noen radius av et bilde"),
        "searchPeopleEmptySection": MessageLookupByLibrary.simpleMessage(
            "Inviter folk, og du vil se alle bilder som deles av dem her"),
        "searchPersonsEmptySection": MessageLookupByLibrary.simpleMessage(
            "Folk vil vises her når behandling og synkronisering er fullført"),
        "searchResultCount": m77,
        "searchSectionsLengthMismatch": m78,
        "security": MessageLookupByLibrary.simpleMessage("Sikkerhet"),
        "seePublicAlbumLinksInApp": MessageLookupByLibrary.simpleMessage(
            "Se offentlige albumlenker i appen"),
        "selectALocation":
            MessageLookupByLibrary.simpleMessage("Velg en plassering"),
        "selectALocationFirst":
            MessageLookupByLibrary.simpleMessage("Velg en plassering først"),
        "selectAlbum": MessageLookupByLibrary.simpleMessage("Velg album"),
        "selectAll": MessageLookupByLibrary.simpleMessage("Velg alle"),
        "selectAllShort": MessageLookupByLibrary.simpleMessage("Alle"),
        "selectCoverPhoto":
            MessageLookupByLibrary.simpleMessage("Velg forsidebilde"),
        "selectDate": MessageLookupByLibrary.simpleMessage("Velg dato"),
        "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
            "Velg mapper for sikkerhetskopiering"),
        "selectItemsToAdd":
            MessageLookupByLibrary.simpleMessage("Velg produkter å legge til"),
        "selectLanguage": MessageLookupByLibrary.simpleMessage("Velg språk"),
        "selectMailApp":
            MessageLookupByLibrary.simpleMessage("Velg e-post-app"),
        "selectMorePhotos":
            MessageLookupByLibrary.simpleMessage("Velg flere bilder"),
        "selectOneDateAndTime":
            MessageLookupByLibrary.simpleMessage("Velg en dato og klokkeslett"),
        "selectOneDateAndTimeForAll": MessageLookupByLibrary.simpleMessage(
            "Velg én dato og klokkeslett for alle"),
        "selectPersonToLink":
            MessageLookupByLibrary.simpleMessage("Velg person å knytte til"),
        "selectReason": MessageLookupByLibrary.simpleMessage("Velg grunn"),
        "selectStartOfRange":
            MessageLookupByLibrary.simpleMessage("Velg starten på rekkevidde"),
        "selectTime": MessageLookupByLibrary.simpleMessage("Velg tidspunkt"),
        "selectYourFace":
            MessageLookupByLibrary.simpleMessage("Velg ansiktet ditt"),
        "selectYourPlan":
            MessageLookupByLibrary.simpleMessage("Velg abonnementet ditt"),
        "selectedFilesAreNotOnEnte": MessageLookupByLibrary.simpleMessage(
            "Valgte filer er ikke på Ente"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "Valgte mapper vil bli kryptert og sikkerhetskopiert"),
        "selectedItemsWillBeDeletedFromAllAlbumsAndMoved":
            MessageLookupByLibrary.simpleMessage(
                "Valgte elementer vil bli slettet fra alle album og flyttet til papirkurven."),
        "selectedItemsWillBeRemovedFromThisPerson":
            MessageLookupByLibrary.simpleMessage(
                "Valgte elementer fjernes fra denne personen, men blir ikke slettet fra biblioteket ditt."),
        "selectedPhotos": m80,
        "selectedPhotosWithYours": m81,
        "selfiesWithThem": m82,
        "send": MessageLookupByLibrary.simpleMessage("Send"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("Send e-post"),
        "sendInvite": MessageLookupByLibrary.simpleMessage("Send invitasjon"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Send lenke"),
        "serverEndpoint":
            MessageLookupByLibrary.simpleMessage("Serverendepunkt"),
        "sessionExpired":
            MessageLookupByLibrary.simpleMessage("Økten har utløpt"),
        "sessionIdMismatch":
            MessageLookupByLibrary.simpleMessage("Økt-ID stemmer ikke"),
        "setAPassword": MessageLookupByLibrary.simpleMessage("Lag et passord"),
        "setAs": MessageLookupByLibrary.simpleMessage("Angi som"),
        "setCover": MessageLookupByLibrary.simpleMessage("Angi forside"),
        "setLabel": MessageLookupByLibrary.simpleMessage("Angi"),
        "setNewPassword":
            MessageLookupByLibrary.simpleMessage("Angi nytt passord"),
        "setNewPin": MessageLookupByLibrary.simpleMessage("Angi ny PIN-kode"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Angi passord"),
        "setRadius": MessageLookupByLibrary.simpleMessage("Angi radius"),
        "setupComplete":
            MessageLookupByLibrary.simpleMessage("Oppsett fullført"),
        "share": MessageLookupByLibrary.simpleMessage("Del"),
        "shareALink": MessageLookupByLibrary.simpleMessage("Del en lenke"),
        "shareAlbumHint": MessageLookupByLibrary.simpleMessage(
            "Åpne et album og trykk på del-knappen øverst til høyre for å dele."),
        "shareAnAlbumNow":
            MessageLookupByLibrary.simpleMessage("Del et album nå"),
        "shareLink": MessageLookupByLibrary.simpleMessage("Del link"),
        "shareMyVerificationID": m83,
        "shareOnlyWithThePeopleYouWant":
            MessageLookupByLibrary.simpleMessage("Del bare med de du vil"),
        "shareTextConfirmOthersVerificationID": m84,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Last ned Ente slik at vi lett kan dele bilder og videoer av original kvalitet\n\nhttps://ente.io"),
        "shareTextReferralCode": m85,
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
            "Del med brukere som ikke har Ente"),
        "shareWithPeopleSectionTitle": m86,
        "shareYourFirstAlbum":
            MessageLookupByLibrary.simpleMessage("Del ditt første album"),
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Opprett delte album du kan samarbeide om med andre Ente-brukere, inkludert brukere med gratisabonnement."),
        "sharedByMe": MessageLookupByLibrary.simpleMessage("Delt av meg"),
        "sharedByYou": MessageLookupByLibrary.simpleMessage("Delt av deg"),
        "sharedPhotoNotifications":
            MessageLookupByLibrary.simpleMessage("Nye delte bilder"),
        "sharedPhotoNotificationsExplanation": MessageLookupByLibrary.simpleMessage(
            "Motta varsler når noen legger til et bilde i et delt album som du er en del av"),
        "sharedWith": m87,
        "sharedWithMe": MessageLookupByLibrary.simpleMessage("Delt med meg"),
        "sharedWithYou": MessageLookupByLibrary.simpleMessage("Delt med deg"),
        "sharing": MessageLookupByLibrary.simpleMessage("Deler..."),
        "shiftDatesAndTime": MessageLookupByLibrary.simpleMessage(
            "Forskyv datoer og klokkeslett"),
        "showMemories": MessageLookupByLibrary.simpleMessage("Vis minner"),
        "showPerson": MessageLookupByLibrary.simpleMessage("Vis person"),
        "signOutFromOtherDevices":
            MessageLookupByLibrary.simpleMessage("Logg ut fra andre enheter"),
        "signOutOtherBody": MessageLookupByLibrary.simpleMessage(
            "Hvis du tror noen kjenner til ditt passord, kan du tvinge alle andre enheter som bruker kontoen din til å logge ut."),
        "signOutOtherDevices":
            MessageLookupByLibrary.simpleMessage("Logg ut andre enheter"),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "Jeg godtar <u-terms>bruksvilkårene</u-terms> og <u-policy>personvernreglene</u-policy>"),
        "singleFileDeleteFromDevice": m88,
        "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
            "Den vil bli slettet fra alle album."),
        "singleFileInBothLocalAndRemote": m89,
        "singleFileInRemoteOnly": m90,
        "skip": MessageLookupByLibrary.simpleMessage("Hopp over"),
        "social": MessageLookupByLibrary.simpleMessage("Sosial"),
        "someItemsAreInBothEnteAndYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Noen elementer er i både Ente og på enheten din."),
        "someOfTheFilesYouAreTryingToDeleteAre":
            MessageLookupByLibrary.simpleMessage(
                "Noen av filene du prøver å slette, er kun tilgjengelig på enheten og kan ikke gjenopprettes dersom det blir slettet"),
        "someoneSharingAlbumsWithYouShouldSeeTheSameId":
            MessageLookupByLibrary.simpleMessage(
                "Folk som deler album med deg bør se den samme ID-en på deres enhet."),
        "somethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Noe gikk galt"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Noe gikk galt. Vennligst prøv igjen"),
        "sorry": MessageLookupByLibrary.simpleMessage("Beklager"),
        "sorryCouldNotAddToFavorites": MessageLookupByLibrary.simpleMessage(
            "Beklager, kan ikke legge til i favoritter!"),
        "sorryCouldNotRemoveFromFavorites":
            MessageLookupByLibrary.simpleMessage(
                "Beklager, kunne ikke fjerne fra favoritter!"),
        "sorryTheCodeYouveEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "Beklager, koden du skrev inn er feil"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "Beklager, vi kunne ikke generere sikre nøkler på denne enheten.\n\nvennligst registrer deg fra en annen enhet."),
        "sort": MessageLookupByLibrary.simpleMessage("Sorter"),
        "sortAlbumsBy": MessageLookupByLibrary.simpleMessage("Sorter etter"),
        "sortNewestFirst": MessageLookupByLibrary.simpleMessage("Nyeste først"),
        "sortOldestFirst": MessageLookupByLibrary.simpleMessage("Eldste først"),
        "sparkleSuccess": MessageLookupByLibrary.simpleMessage("✨ Suksess"),
        "sportsWithThem": m91,
        "spotlightOnThem": m92,
        "spotlightOnYourself":
            MessageLookupByLibrary.simpleMessage("Fremhev deg selv"),
        "startAccountRecoveryTitle":
            MessageLookupByLibrary.simpleMessage("Start gjenoppretting"),
        "startBackup":
            MessageLookupByLibrary.simpleMessage("Start sikkerhetskopiering"),
        "status": MessageLookupByLibrary.simpleMessage("Status"),
        "stopCastingBody":
            MessageLookupByLibrary.simpleMessage("Vil du avbryte strømmingen?"),
        "stopCastingTitle":
            MessageLookupByLibrary.simpleMessage("Stopp strømmingen"),
        "storage": MessageLookupByLibrary.simpleMessage("Lagring"),
        "storageBreakupFamily": MessageLookupByLibrary.simpleMessage("Familie"),
        "storageBreakupYou": MessageLookupByLibrary.simpleMessage("Deg"),
        "storageInGB": m93,
        "storageLimitExceeded":
            MessageLookupByLibrary.simpleMessage("Lagringsplassen er full"),
        "storageUsageInfo": m94,
        "streamDetails":
            MessageLookupByLibrary.simpleMessage("Strømmedetaljer"),
        "strongStrength": MessageLookupByLibrary.simpleMessage("Sterkt"),
        "subAlreadyLinkedErrMessage": m95,
        "subWillBeCancelledOn": m96,
        "subscribe": MessageLookupByLibrary.simpleMessage("Abonner"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "Du trenger et aktivt betalt abonnement for å aktivere deling."),
        "subscription": MessageLookupByLibrary.simpleMessage("Abonnement"),
        "success": MessageLookupByLibrary.simpleMessage("Suksess"),
        "successfullyArchived":
            MessageLookupByLibrary.simpleMessage("Lagt til i arkivet"),
        "successfullyHid":
            MessageLookupByLibrary.simpleMessage("Vellykket skjult"),
        "successfullyUnarchived":
            MessageLookupByLibrary.simpleMessage("Fjernet fra arkviet"),
        "successfullyUnhid":
            MessageLookupByLibrary.simpleMessage("Vellykket synliggjøring"),
        "suggestFeatures":
            MessageLookupByLibrary.simpleMessage("Foreslå funksjoner"),
        "sunrise": MessageLookupByLibrary.simpleMessage("På horisonten"),
        "support": MessageLookupByLibrary.simpleMessage("Brukerstøtte"),
        "syncProgress": m97,
        "syncStopped":
            MessageLookupByLibrary.simpleMessage("Synkronisering stoppet"),
        "syncing": MessageLookupByLibrary.simpleMessage("Synkroniserer..."),
        "systemTheme": MessageLookupByLibrary.simpleMessage("System"),
        "tapToCopy":
            MessageLookupByLibrary.simpleMessage("trykk for å kopiere"),
        "tapToEnterCode":
            MessageLookupByLibrary.simpleMessage("Trykk for å angi kode"),
        "tapToUnlock":
            MessageLookupByLibrary.simpleMessage("Trykk for å låse opp"),
        "tapToUpload":
            MessageLookupByLibrary.simpleMessage("Trykk for å laste opp"),
        "tapToUploadIsIgnoredDue": m98,
        "tempErrorContactSupportIfPersists": MessageLookupByLibrary.simpleMessage(
            "Det ser ut som noe gikk galt. Prøv på nytt etter en stund. Hvis feilen vedvarer, kontakt kundestøtte."),
        "terminate": MessageLookupByLibrary.simpleMessage("Avslutte"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Avslutte økten?"),
        "terms": MessageLookupByLibrary.simpleMessage("Vilkår"),
        "termsOfServicesTitle": MessageLookupByLibrary.simpleMessage("Vilkår"),
        "thankYou": MessageLookupByLibrary.simpleMessage("Tusen takk"),
        "thankYouForSubscribing":
            MessageLookupByLibrary.simpleMessage("Takk for at du abonnerer!"),
        "theDownloadCouldNotBeCompleted": MessageLookupByLibrary.simpleMessage(
            "Nedlastingen kunne ikke fullføres"),
        "theLinkYouAreTryingToAccessHasExpired":
            MessageLookupByLibrary.simpleMessage(
                "Lenken du prøver å få tilgang til, er utløpt."),
        "theRecoveryKeyYouEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "Gjennopprettingsnøkkelen du skrev inn er feil"),
        "theme": MessageLookupByLibrary.simpleMessage("Tema"),
        "theseItemsWillBeDeletedFromYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Disse elementene vil bli slettet fra enheten din."),
        "theyAlsoGetXGb": m99,
        "theyWillBeDeletedFromAllAlbums": MessageLookupByLibrary.simpleMessage(
            "De vil bli slettet fra alle album."),
        "thisActionCannotBeUndone": MessageLookupByLibrary.simpleMessage(
            "Denne handlingen kan ikke angres"),
        "thisAlbumAlreadyHDACollaborativeLink":
            MessageLookupByLibrary.simpleMessage(
                "Dette albumet har allerede en samarbeidslenke"),
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "Dette kan brukes til å gjenopprette kontoen din hvis du mister din andre faktor"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Denne enheten"),
        "thisEmailIsAlreadyInUse": MessageLookupByLibrary.simpleMessage(
            "Denne e-postadressen er allerede i bruk"),
        "thisImageHasNoExifData": MessageLookupByLibrary.simpleMessage(
            "Dette bildet har ingen exif-data"),
        "thisIsMeExclamation":
            MessageLookupByLibrary.simpleMessage("Dette er meg!"),
        "thisIsPersonVerificationId": m100,
        "thisIsYourVerificationId": MessageLookupByLibrary.simpleMessage(
            "Dette er din bekreftelses-ID"),
        "thisWeekThroughTheYears":
            MessageLookupByLibrary.simpleMessage("Denne uka gjennom årene"),
        "thisWeekXYearsAgo": m101,
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Dette vil logge deg ut av følgende enhet:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Dette vil logge deg ut av denne enheten!"),
        "thisWillMakeTheDateAndTimeOfAllSelected":
            MessageLookupByLibrary.simpleMessage(
                "Dette vil gjøre dato og klokkeslett for alle valgte bilder det samme."),
        "thisWillRemovePublicLinksOfAllSelectedQuickLinks":
            MessageLookupByLibrary.simpleMessage(
                "Dette fjerner de offentlige lenkene av alle valgte hurtiglenker."),
        "throughTheYears": m102,
        "toEnableAppLockPleaseSetupDevicePasscodeOrScreen":
            MessageLookupByLibrary.simpleMessage(
                "For å aktivere applås, vennligst angi passord eller skjermlås i systeminnstillingene."),
        "toHideAPhotoOrVideo": MessageLookupByLibrary.simpleMessage(
            "For å skjule et bilde eller video"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "For å tilbakestille passordet ditt, vennligst bekreft e-posten din først."),
        "todaysLogs": MessageLookupByLibrary.simpleMessage("Dagens logger"),
        "tooManyIncorrectAttempts":
            MessageLookupByLibrary.simpleMessage("For mange gale forsøk"),
        "total": MessageLookupByLibrary.simpleMessage("totalt"),
        "totalSize": MessageLookupByLibrary.simpleMessage("Total størrelse"),
        "trash": MessageLookupByLibrary.simpleMessage("Papirkurv"),
        "trashDaysLeft": m103,
        "trim": MessageLookupByLibrary.simpleMessage("Beskjær"),
        "tripInYear": m104,
        "tripToLocation": m105,
        "trustedContacts":
            MessageLookupByLibrary.simpleMessage("Betrodde kontakter"),
        "trustedInviteBody": m106,
        "tryAgain": MessageLookupByLibrary.simpleMessage("Prøv igjen"),
        "turnOnBackupForAutoUpload": MessageLookupByLibrary.simpleMessage(
            "Slå på sikkerhetskopi for å automatisk laste opp filer lagt til denne enhetsmappen i Ente."),
        "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
        "twoMonthsFreeOnYearlyPlans": MessageLookupByLibrary.simpleMessage(
            "2 måneder gratis med årsabonnement"),
        "twofactor": MessageLookupByLibrary.simpleMessage("Tofaktor"),
        "twofactorAuthenticationHasBeenDisabled":
            MessageLookupByLibrary.simpleMessage(
                "Tofaktorautentisering har blitt deaktivert"),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage("Tofaktorautentisering"),
        "twofactorAuthenticationSuccessfullyReset":
            MessageLookupByLibrary.simpleMessage(
                "Tofaktorautentisering ble tilbakestilt"),
        "twofactorSetup":
            MessageLookupByLibrary.simpleMessage("Oppsett av to-faktor"),
        "typeOfGallerGallerytypeIsNotSupportedForRename": m107,
        "unarchive": MessageLookupByLibrary.simpleMessage("Opphev arkivering"),
        "unarchiveAlbum":
            MessageLookupByLibrary.simpleMessage("Gjenopprett album"),
        "unarchiving":
            MessageLookupByLibrary.simpleMessage("Fjerner fra arkivet..."),
        "unavailableReferralCode": MessageLookupByLibrary.simpleMessage(
            "Beklager, denne koden er utilgjengelig."),
        "uncategorized": MessageLookupByLibrary.simpleMessage("Ukategorisert"),
        "unhide": MessageLookupByLibrary.simpleMessage("Gjør synligjort"),
        "unhideToAlbum":
            MessageLookupByLibrary.simpleMessage("Gjør synlig i album"),
        "unhiding": MessageLookupByLibrary.simpleMessage("Synliggjør..."),
        "unhidingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Gjør filer synlige i albumet"),
        "unlock": MessageLookupByLibrary.simpleMessage("Lås opp"),
        "unpinAlbum": MessageLookupByLibrary.simpleMessage("Løsne album"),
        "unselectAll": MessageLookupByLibrary.simpleMessage("Velg bort alle"),
        "update": MessageLookupByLibrary.simpleMessage("Oppdater"),
        "updateAvailable": MessageLookupByLibrary.simpleMessage(
            "En oppdatering er tilgjengelig"),
        "updatingFolderSelection":
            MessageLookupByLibrary.simpleMessage("Oppdaterer mappevalg..."),
        "upgrade": MessageLookupByLibrary.simpleMessage("Oppgrader"),
        "uploadIsIgnoredDueToIgnorereason": m108,
        "uploadingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Laster opp filer til albumet..."),
        "uploadingMultipleMemories": m109,
        "uploadingSingleMemory":
            MessageLookupByLibrary.simpleMessage("Bevarer 1 minne..."),
        "upto50OffUntil4thDec": MessageLookupByLibrary.simpleMessage(
            "Opptil 50 % rabatt, frem til 4. desember."),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "Brukbar lagringsplass er begrenset av abonnementet ditt. Lagring du har gjort krav på utover denne grensen blir automatisk tilgjengelig når du oppgraderer abonnementet ditt."),
        "useAsCover":
            MessageLookupByLibrary.simpleMessage("Bruk som forsidebilde"),
        "useDifferentPlayerInfo": MessageLookupByLibrary.simpleMessage(
            "Har du problemer med å spille av denne videoen? Hold inne her for å prøve en annen avspiller."),
        "usePublicLinksForPeopleNotOnEnte":
            MessageLookupByLibrary.simpleMessage(
                "Bruk offentlige lenker for folk som ikke bruker Ente"),
        "useRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Bruk gjenopprettingsnøkkel"),
        "useSelectedPhoto":
            MessageLookupByLibrary.simpleMessage("Bruk valgt bilde"),
        "usedSpace":
            MessageLookupByLibrary.simpleMessage("Benyttet lagringsplass"),
        "validTill": m110,
        "verificationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Bekreftelse mislyktes, vennligst prøv igjen"),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("Verifiserings-ID"),
        "verify": MessageLookupByLibrary.simpleMessage("Bekreft"),
        "verifyEmail":
            MessageLookupByLibrary.simpleMessage("Bekreft e-postadresse"),
        "verifyEmailID": m111,
        "verifyIDLabel": MessageLookupByLibrary.simpleMessage("Bekreft"),
        "verifyPasskey":
            MessageLookupByLibrary.simpleMessage("Bekreft tilgangsnøkkel"),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Bekreft passord"),
        "verifying": MessageLookupByLibrary.simpleMessage("Verifiserer..."),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Verifiserer gjenopprettingsnøkkel..."),
        "videoInfo": MessageLookupByLibrary.simpleMessage("Videoinformasjon"),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("video"),
        "videos": MessageLookupByLibrary.simpleMessage("Videoer"),
        "viewActiveSessions":
            MessageLookupByLibrary.simpleMessage("Vis aktive økter"),
        "viewAddOnButton": MessageLookupByLibrary.simpleMessage("Vis tillegg"),
        "viewAll": MessageLookupByLibrary.simpleMessage("Vis alle"),
        "viewAllExifData":
            MessageLookupByLibrary.simpleMessage("Vis alle EXIF-data"),
        "viewLargeFiles": MessageLookupByLibrary.simpleMessage("Store filer"),
        "viewLargeFilesDesc": MessageLookupByLibrary.simpleMessage(
            "Vis filer som bruker mest lagringsplass."),
        "viewLogs": MessageLookupByLibrary.simpleMessage("Se logger"),
        "viewRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Vis gjenopprettingsnøkkel"),
        "viewer": MessageLookupByLibrary.simpleMessage("Seer"),
        "visitWebToManage": MessageLookupByLibrary.simpleMessage(
            "Vennligst besøk web.ente.io for å administrere abonnementet"),
        "waitingForVerification":
            MessageLookupByLibrary.simpleMessage("Venter på verifikasjon..."),
        "waitingForWifi":
            MessageLookupByLibrary.simpleMessage("Venter på WiFi..."),
        "warning": MessageLookupByLibrary.simpleMessage("Advarsel"),
        "weAreOpenSource":
            MessageLookupByLibrary.simpleMessage("Vi har åpen kildekode!"),
        "weDontSupportEditingPhotosAndAlbumsThatYouDont":
            MessageLookupByLibrary.simpleMessage(
                "Vi støtter ikke redigering av bilder og album som du ikke eier ennå"),
        "weHaveSendEmailTo": m114,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Svakt"),
        "welcomeBack":
            MessageLookupByLibrary.simpleMessage("Velkommen tilbake!"),
        "whatsNew": MessageLookupByLibrary.simpleMessage("Det som er nytt"),
        "whyAddTrustContact": MessageLookupByLibrary.simpleMessage(
            "Betrodd kontakt kan hjelpe til med å gjenopprette dine data."),
        "yearShort": MessageLookupByLibrary.simpleMessage("år"),
        "yearly": MessageLookupByLibrary.simpleMessage("Årlig"),
        "yearsAgo": m116,
        "yes": MessageLookupByLibrary.simpleMessage("Ja"),
        "yesCancel": MessageLookupByLibrary.simpleMessage("Ja, avslutt"),
        "yesConvertToViewer":
            MessageLookupByLibrary.simpleMessage("Ja, konverter til seer"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("Ja, slett"),
        "yesDiscardChanges":
            MessageLookupByLibrary.simpleMessage("Ja, forkast endringer"),
        "yesLogout": MessageLookupByLibrary.simpleMessage("Ja, logg ut"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("Ja, fjern"),
        "yesRenew": MessageLookupByLibrary.simpleMessage("Ja, forny"),
        "yesResetPerson":
            MessageLookupByLibrary.simpleMessage("Ja, tilbakestill person"),
        "you": MessageLookupByLibrary.simpleMessage("Deg"),
        "youAndThem": m117,
        "youAreOnAFamilyPlan": MessageLookupByLibrary.simpleMessage(
            "Du har et familieabonnement!"),
        "youAreOnTheLatestVersion": MessageLookupByLibrary.simpleMessage(
            "Du er på den nyeste versjonen"),
        "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "* Du kan maksimalt doble lagringsplassen din"),
        "youCanManageYourLinksInTheShareTab":
            MessageLookupByLibrary.simpleMessage(
                "Du kan administrere koblingene dine i fanen for deling."),
        "youCanTrySearchingForADifferentQuery":
            MessageLookupByLibrary.simpleMessage(
                "Du kan prøve å søke etter noe annet."),
        "youCannotDowngradeToThisPlan": MessageLookupByLibrary.simpleMessage(
            "Du kan ikke nedgradere til dette abonnementet"),
        "youCannotShareWithYourself": MessageLookupByLibrary.simpleMessage(
            "Du kan ikke dele med deg selv"),
        "youDontHaveAnyArchivedItems": MessageLookupByLibrary.simpleMessage(
            "Du har ingen arkiverte elementer."),
        "youHaveSuccessfullyFreedUp": m118,
        "yourAccountHasBeenDeleted": MessageLookupByLibrary.simpleMessage(
            "Brukeren din har blitt slettet"),
        "yourMap": MessageLookupByLibrary.simpleMessage("Ditt kart"),
        "yourPlanWasSuccessfullyDowngraded":
            MessageLookupByLibrary.simpleMessage(
                "Abonnementet ditt ble nedgradert"),
        "yourPlanWasSuccessfullyUpgraded": MessageLookupByLibrary.simpleMessage(
            "Abonnementet ditt ble oppgradert"),
        "yourPurchaseWasSuccessful":
            MessageLookupByLibrary.simpleMessage("Ditt kjøp var vellykket"),
        "yourStorageDetailsCouldNotBeFetched":
            MessageLookupByLibrary.simpleMessage(
                "Lagringsdetaljene dine kunne ikke hentes"),
        "yourSubscriptionHasExpired":
            MessageLookupByLibrary.simpleMessage("Abonnementet har utløpt"),
        "yourSubscriptionWasUpdatedSuccessfully":
            MessageLookupByLibrary.simpleMessage(
                "Abonnementet ditt ble oppdatert"),
        "yourVerificationCodeHasExpired":
            MessageLookupByLibrary.simpleMessage("Bekreftelseskoden er utløpt"),
        "youveNoDuplicateFilesThatCanBeCleared":
            MessageLookupByLibrary.simpleMessage(
                "Du har ingen duplikatfiler som kan fjernes"),
        "youveNoFilesInThisAlbumThatCanBeDeleted":
            MessageLookupByLibrary.simpleMessage(
                "Du har ingen filer i dette albumet som kan bli slettet"),
        "zoomOutToSeePhotos":
            MessageLookupByLibrary.simpleMessage("Zoom ut for å se bilder")
      };
}
