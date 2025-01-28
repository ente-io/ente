// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a lt locale. All the
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
  String get localeName => 'lt';

  static String m9(count) =>
      "${Intl.plural(count, one: 'Pridėti bendradarbį', few: 'Pridėti bendradarbius', many: 'Pridėti bendradarbio', other: 'Pridėti bendradarbių')}";

  static String m10(count) =>
      "${Intl.plural(count, one: 'Pridėti elementą', few: 'Pridėti elementus', many: 'Pridėti elemento', other: 'Pridėti elementų')}";

  static String m12(count) =>
      "${Intl.plural(count, one: 'Pridėti žiūrėtoją', few: 'Pridėti žiūrėtojus', many: 'Pridėti žiūrėtojo', other: 'Pridėti žiūrėtojų')}";

  static String m15(count) =>
      "${Intl.plural(count, zero: 'Nėra dalyvių', one: '1 dalyvis', other: '${count} dalyviai')}";

  static String m16(versionValue) => "Versija: ${versionValue}";

  static String m18(paymentProvider) =>
      "Pirmiausia atsisakykite esamos prenumeratos iš ${paymentProvider}";

  static String m3(user) =>
      "${user} negalės pridėti daugiau nuotraukų į šį albumą\n\nJie vis tiek galės pašalinti esamas pridėtas nuotraukas";

  static String m19(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true': 'Jūsų šeima gavo ${storageAmountInGb} GB iki šiol',
            'false': 'Jūs gavote ${storageAmountInGb} GB iki šiol',
            'other': 'Jūs gavote ${storageAmountInGb} GB iki šiol.',
          })}";

  static String m21(count) =>
      "${Intl.plural(count, zero: 'Pridėta 0 bendradarbių', one: 'Pridėtas 1 bendradarbis', other: 'Pridėta ${count} bendradarbių')}";

  static String m22(email, numOfDays) =>
      "Ketinate pridėti ${email} kaip patikimą kontaktą. Jie galės atkurti jūsų paskyrą, jei jūsų nebus ${numOfDays} dienų.";

  static String m25(endpoint) => "Prijungta prie ${endpoint}";

  static String m26(count) =>
      "${Intl.plural(count, one: 'Ištrinti ${count} elementą', few: 'Ištrinti ${count} elementus', many: 'Ištrinti ${count} elemento', other: 'Ištrinti ${count} elementų')}";

  static String m27(currentlyDeleting, totalCount) =>
      "Ištrinama ${currentlyDeleting} / ${totalCount}";

  static String m28(albumName) =>
      "Tai pašalins viešą nuorodą, skirtą pasiekti „${albumName}“.";

  static String m29(supportEmail) =>
      "Iš savo registruoto el. pašto adreso atsiųskite el. laišką adresu ${supportEmail}";

  static String m30(count, storageSaved) =>
      "Išvalėte ${Intl.plural(count, one: '${count} dubliuojantį failą', few: '${count} dubliuojančius failus', many: '${count} dubliuojančio failo', other: '${count} dubliuojančių failų')}, išsaugodami (${storageSaved}).";

  static String m31(count, formattedSize) =>
      "${count} failai (-ų), kiekvienas ${formattedSize}";

  static String m33(email) =>
      "${email} neturi „Ente“ paskyros.\n\nSiųskite jiems kvietimą bendrinti nuotraukas.";

  static String m34(text) => "Rastos papildomos nuotraukos, skirtos ${text}";

  static String m4(storageAmountInGB) =>
      "${storageAmountInGB} GB kiekvieną kartą, kai kas nors užsiregistruoja mokamam planui ir pritaiko jūsų kodą.";

  static String m37(endDate) =>
      "Nemokamas bandomasis laikotarpis galioja iki ${endDate}";

  static String m39(sizeInMBorGB) => "Atlaisvinti ${sizeInMBorGB}";

  static String m41(currentlyProcessing, totalCount) =>
      "Apdorojama ${currentlyProcessing} / ${totalCount}";

  static String m42(count) =>
      "${Intl.plural(count, one: '${count} elementas', few: '${count} elementai', many: '${count} elemento', other: '${count} elementų')}";

  static String m43(email) => "${email} pakvietė jus būti patikimu kontaktu";

  static String m44(expiryTime) => "Nuoroda nebegalios ${expiryTime}";

  static String m5(count, formattedCount) =>
      "${Intl.plural(count, zero: 'nėra prisiminimų', one: '${formattedCount} prisiminimas', few: '${formattedCount} prisiminimai', many: '${formattedCount} prisiminimo', other: '${formattedCount} prisiminimų')}";

  static String m45(count) =>
      "${Intl.plural(count, one: 'Perkelti elementą', few: 'Perkelti elementus', many: 'Perkelti elemento', other: 'Perkelti elementų')}";

  static String m47(personName) => "Nėra pasiūlymų asmeniui ${personName}.";

  static String m48(name) => "Ne ${name}?";

  static String m49(familyAdminEmail) =>
      "Susisiekite su ${familyAdminEmail}, kad pakeistumėte savo kodą.";

  static String m0(passwordStrengthValue) =>
      "Slaptažodžio stiprumas: ${passwordStrengthValue}";

  static String m50(providerName) =>
      "Kreipkitės į ${providerName} palaikymo komandą, jei jums buvo nuskaičiuota.";

  static String m52(endDate) =>
      "Nemokama bandomoji versija galioja iki ${endDate}.\nVėliau galėsite pasirinkti mokamą planą.";

  static String m54(toEmail) => "Siųskite žurnalus adresu\n${toEmail}";

  static String m55(folderName) => "Apdorojama ${folderName}...";

  static String m56(storeName) => "Vertinti mus parduotuvėje „${storeName}“";

  static String m57(days, email) =>
      "Paskyrą galėsite pasiekti po ${days} dienų. Pranešimas bus išsiųstas į ${email}.";

  static String m58(email) =>
      "Dabar galite atkurti ${email} paskyrą nustatydami naują slaptažodį.";

  static String m59(email) => "${email} bando atkurti jūsų paskyrą.";

  static String m60(storageInGB) =>
      "3. Abu gaunate ${storageInGB} GB* nemokamai";

  static String m61(userEmail) =>
      "${userEmail} bus pašalintas iš šio bendrinamo albumo.\n\nVisos jų pridėtos nuotraukos taip pat bus pašalintos iš albumo.";

  static String m62(endDate) => "Prenumerata atnaujinama ${endDate}";

  static String m63(count) =>
      "${Intl.plural(count, one: 'Rastas ${count} rezultatas', few: 'Rasti ${count} rezultatai', many: 'Rasta ${count} rezultato', other: 'Rasta ${count} rezultatų')}";

  static String m64(snapshotLength, searchLength) =>
      "Sekcijų ilgio neatitikimas: ${snapshotLength} != ${searchLength}";

  static String m6(count) => "${count} pasirinkta";

  static String m65(count, yourCount) =>
      "${count} pasirinkta (${yourCount} jūsų)";

  static String m66(verificationID) =>
      "Štai mano patvirtinimo ID: ${verificationID}, skirta ente.io.";

  static String m7(verificationID) =>
      "Ei, ar galite patvirtinti, kad tai yra jūsų ente.io patvirtinimo ID: ${verificationID}";

  static String m67(referralCode, referralStorageInGB) =>
      "„Ente“ rekomendacijos kodas: ${referralCode} \n\nTaikykite jį per Nustatymai → Bendrieji → Rekomendacijos, kad gautumėte ${referralStorageInGB} GB nemokamai po to, kai užsiregistruosite mokamam planui.\n\nhttps://ente.io";

  static String m68(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Bendrinti su konkrečiais asmenimis', one: 'Bendrinta su 1 asmeniu', other: 'Bendrinta su ${numberOfPeople} asmenimis')}";

  static String m70(fileType) =>
      "Šis ${fileType} bus ištrintas iš jūsų įrenginio.";

  static String m71(fileType) =>
      "Šis ${fileType} yra ir saugykloje „Ente“ bei įrenginyje.";

  static String m72(fileType) => "Šis ${fileType} bus ištrintas iš „Ente“.";

  static String m1(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m74(id) =>
      "Jūsų ${id} jau susietas su kita „Ente“ paskyra.\nJei norite naudoti savo ${id} su šia paskyra, susisiekite su mūsų palaikymo komanda.";

  static String m76(completed, total) =>
      "${completed} / ${total} išsaugomi prisiminimai";

  static String m77(ignoreReason) =>
      "Palieskite, kad įkeltumėte. Įkėlimas šiuo metu ignoruojamas dėl ${ignoreReason}.";

  static String m8(storageAmountInGB) =>
      "Jie taip pat gauna ${storageAmountInGB} GB";

  static String m78(email) => "Tai – ${email} patvirtinimo ID";

  static String m79(count) =>
      "${Intl.plural(count, zero: 'Netrukus', one: '1 diena', other: '${count} dienų')}";

  static String m80(email) =>
      "Buvote pakviesti tapti ${email} palikimo kontaktu.";

  static String m81(galleryType) =>
      "Galerijos tipas ${galleryType} nepalaikomas pervadinimui.";

  static String m82(ignoreReason) =>
      "Įkėlimas ignoruojamas dėl ${ignoreReason}.";

  static String m84(endDate) => "Galioja iki ${endDate}";

  static String m85(email) => "Patvirtinti ${email}";

  static String m86(count) =>
      "${Intl.plural(count, zero: 'Pridėta 0 žiūrėtojų', one: 'Pridėtas 1 žiūrėtojas', other: 'Pridėta ${count} žiūrėtojų')}";

  static String m2(email) => "Išsiuntėme laišką adresu <green>${email}</green>";

  static String m87(count) =>
      "${Intl.plural(count, one: 'prieš ${count} metus', few: 'prieš ${count} metus', many: 'prieš ${count} metų', other: 'prieš ${count} metų')}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable":
            MessageLookupByLibrary.simpleMessage("Yra nauja „Ente“ versija."),
        "about": MessageLookupByLibrary.simpleMessage("Apie"),
        "acceptTrustInvite":
            MessageLookupByLibrary.simpleMessage("Priimti kvietimą"),
        "account": MessageLookupByLibrary.simpleMessage("Paskyra"),
        "accountIsAlreadyConfigured":
            MessageLookupByLibrary.simpleMessage("Paskyra jau sukonfigūruota."),
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Sveiki sugrįžę!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Suprantu, kad jei prarasiu slaptažodį, galiu prarasti savo duomenis, kadangi mano duomenys yra <underline>visapusiškai užšifruoti</underline>"),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Aktyvūs seansai"),
        "add": MessageLookupByLibrary.simpleMessage("Pridėti"),
        "addAName": MessageLookupByLibrary.simpleMessage("Pridėti vardą"),
        "addANewEmail":
            MessageLookupByLibrary.simpleMessage("Pridėti naują el. paštą"),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Pridėti bendradarbį"),
        "addCollaborators": m9,
        "addFiles": MessageLookupByLibrary.simpleMessage("Pridėti failus"),
        "addItem": m10,
        "addLocation": MessageLookupByLibrary.simpleMessage("Pridėti vietovę"),
        "addLocationButton": MessageLookupByLibrary.simpleMessage("Pridėti"),
        "addMore": MessageLookupByLibrary.simpleMessage("Pridėti daugiau"),
        "addName": MessageLookupByLibrary.simpleMessage("Pridėti vardą"),
        "addNameOrMerge":
            MessageLookupByLibrary.simpleMessage("Pridėti vardą arba sujungti"),
        "addNew": MessageLookupByLibrary.simpleMessage("Pridėti naują"),
        "addNewPerson":
            MessageLookupByLibrary.simpleMessage("Pridėti naują asmenį"),
        "addOnPageSubtitle": MessageLookupByLibrary.simpleMessage(
            "Išsami informacija apie priedus"),
        "addOns": MessageLookupByLibrary.simpleMessage("Priedai"),
        "addToAlbum": MessageLookupByLibrary.simpleMessage("Pridėti į albumą"),
        "addToEnte": MessageLookupByLibrary.simpleMessage("Pridėti į „Ente“"),
        "addTrustedContact":
            MessageLookupByLibrary.simpleMessage("Pridėti patikimą kontaktą"),
        "addViewer": MessageLookupByLibrary.simpleMessage("Pridėti žiūrėtoją"),
        "addViewers": m12,
        "addedAs": MessageLookupByLibrary.simpleMessage("Pridėta kaip"),
        "addingToFavorites":
            MessageLookupByLibrary.simpleMessage("Pridedama prie mėgstamų..."),
        "advanced": MessageLookupByLibrary.simpleMessage("Išplėstiniai"),
        "advancedSettings":
            MessageLookupByLibrary.simpleMessage("Išplėstiniai"),
        "after1Day": MessageLookupByLibrary.simpleMessage("Po 1 dienos"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("Po 1 valandos"),
        "after1Month": MessageLookupByLibrary.simpleMessage("Po 1 mėnesio"),
        "after1Week": MessageLookupByLibrary.simpleMessage("Po 1 savaitės"),
        "after1Year": MessageLookupByLibrary.simpleMessage("Po 1 metų"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Savininkas"),
        "albumParticipantsCount": m15,
        "albumUpdated":
            MessageLookupByLibrary.simpleMessage("Atnaujintas albumas"),
        "albums": MessageLookupByLibrary.simpleMessage("Albumai"),
        "allMemoriesPreserved":
            MessageLookupByLibrary.simpleMessage("Išsaugoti visi prisiminimai"),
        "allPersonGroupingWillReset": MessageLookupByLibrary.simpleMessage(
            "Visi šio asmens grupavimai bus iš naujo nustatyti, o jūs neteksite visų šiam asmeniui pateiktų pasiūlymų"),
        "allow": MessageLookupByLibrary.simpleMessage("Leisti"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Leiskite nuorodą turintiems asmenims taip pat pridėti nuotraukų į bendrinamą albumą."),
        "allowAddingPhotos":
            MessageLookupByLibrary.simpleMessage("Leisti pridėti nuotraukų"),
        "allowAppToOpenSharedAlbumLinks": MessageLookupByLibrary.simpleMessage(
            "Leisti programai atverti bendrinamų albumų nuorodas"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("Leisti atsisiuntimus"),
        "allowPeopleToAddPhotos": MessageLookupByLibrary.simpleMessage(
            "Leiskite asmenims pridėti nuotraukų"),
        "allowPermBody": MessageLookupByLibrary.simpleMessage(
            "Iš nustatymų leiskite prieigą prie nuotraukų, kad „Ente“ galėtų rodyti ir kurti atsargines bibliotekos kopijas."),
        "allowPermTitle": MessageLookupByLibrary.simpleMessage(
            "Leisti prieigą prie nuotraukų"),
        "androidBiometricHint":
            MessageLookupByLibrary.simpleMessage("Patvirtinkite tapatybę"),
        "androidBiometricRequiredTitle":
            MessageLookupByLibrary.simpleMessage("Privaloma biometrija"),
        "androidCancelButton": MessageLookupByLibrary.simpleMessage("Atšaukti"),
        "androidDeviceCredentialsRequiredTitle":
            MessageLookupByLibrary.simpleMessage(
                "Privalomi įrenginio kredencialai"),
        "androidDeviceCredentialsSetupDescription":
            MessageLookupByLibrary.simpleMessage(
                "Privalomi įrenginio kredencialai"),
        "androidGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "Biometrinis tapatybės nustatymas jūsų įrenginyje nenustatytas. Eikite į Nustatymai > Saugumas ir pridėkite biometrinį tapatybės nustatymą."),
        "androidIosWebDesktop": MessageLookupByLibrary.simpleMessage(
            "„Android“, „iOS“, internete ir darbalaukyje"),
        "androidSignInTitle": MessageLookupByLibrary.simpleMessage(
            "Privalomas tapatybės nustatymas"),
        "appLock": MessageLookupByLibrary.simpleMessage("Programos užraktas"),
        "appLockDescriptions": MessageLookupByLibrary.simpleMessage(
            "Pasirinkite tarp numatytojo įrenginio užrakinimo ekrano ir pasirinktinio užrakinimo ekrano su PIN kodu arba slaptažodžiu."),
        "appVersion": m16,
        "appleId": MessageLookupByLibrary.simpleMessage("„Apple ID“"),
        "apply": MessageLookupByLibrary.simpleMessage("Taikyti"),
        "applyCodeTitle": MessageLookupByLibrary.simpleMessage("Taikyti kodą"),
        "archive": MessageLookupByLibrary.simpleMessage("Archyvas"),
        "archiveAlbum":
            MessageLookupByLibrary.simpleMessage("Archyvuoti albumą"),
        "archiving": MessageLookupByLibrary.simpleMessage("Archyvuojama..."),
        "areYouSureThatYouWantToLeaveTheFamily":
            MessageLookupByLibrary.simpleMessage(
                "Ar tikrai norite palikti šeimos planą?"),
        "areYouSureYouWantToChangeYourPlan":
            MessageLookupByLibrary.simpleMessage(
                "Ar tikrai norite keisti planą?"),
        "areYouSureYouWantToExit":
            MessageLookupByLibrary.simpleMessage("Ar tikrai norite išeiti?"),
        "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
            "Ar tikrai norite atsijungti?"),
        "areYouSureYouWantToResetThisPerson":
            MessageLookupByLibrary.simpleMessage(
                "Ar tikrai norite iš naujo nustatyti šį asmenį?"),
        "askCancelReason": MessageLookupByLibrary.simpleMessage(
            "Jūsų prenumerata buvo atšaukta. Ar norėtumėte pasidalyti priežastimi?"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "Kokia yra pagrindinė priežastis, dėl kurios ištrinate savo paskyrą?"),
        "atAFalloutShelter":
            MessageLookupByLibrary.simpleMessage("priešgaisrinėje slėptuvėje"),
        "authToChangeEmailVerificationSetting":
            MessageLookupByLibrary.simpleMessage(
                "Nustatykite tapatybę, kad pakeistumėte el. pašto patvirtinimą"),
        "authToChangeYourEmail": MessageLookupByLibrary.simpleMessage(
            "Nustatykite tapatybę, kad pakeistumėte savo el. paštą"),
        "authToChangeYourPassword": MessageLookupByLibrary.simpleMessage(
            "Nustatykite tapatybę, kad pakeistumėte slaptažodį"),
        "authToInitiateAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Nustatykite tapatybę, kad pradėtumėte paskyros ištrynimą"),
        "authToManageLegacy": MessageLookupByLibrary.simpleMessage(
            "Nustatykite tapatybę, kad tvarkytumėte patikimus kontaktus"),
        "authToViewPasskey": MessageLookupByLibrary.simpleMessage(
            "Nustatykite tapatybę, kad peržiūrėtumėte savo slaptaraktį"),
        "authToViewTrashedFiles": MessageLookupByLibrary.simpleMessage(
            "Nustatykite tapatybę, kad peržiūrėtumėte išmestus failus"),
        "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
            "Nustatykite tapatybę, kad peržiūrėtumėte paslėptus failus"),
        "authToViewYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Nustatykite tapatybę, kad peržiūrėtumėte savo atkūrimo raktą"),
        "authenticating":
            MessageLookupByLibrary.simpleMessage("Nustatoma tapatybė..."),
        "authenticationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Tapatybės nustatymas nepavyko. Bandykite dar kartą."),
        "authenticationSuccessful": MessageLookupByLibrary.simpleMessage(
            "Tapatybės nustatymas sėkmingas."),
        "autoCastDialogBody": MessageLookupByLibrary.simpleMessage(
            "Čia matysite pasiekiamus perdavimo įrenginius."),
        "autoLock":
            MessageLookupByLibrary.simpleMessage("Automatinis užraktas"),
        "autoLockFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "Laikas, po kurio programa užrakinama perkėlus ją į foną"),
        "autoLogoutMessage": MessageLookupByLibrary.simpleMessage(
            "Dėl techninio trikdžio buvote atjungti. Atsiprašome už nepatogumus."),
        "autoPair":
            MessageLookupByLibrary.simpleMessage("Automatiškai susieti"),
        "autoPairDesc": MessageLookupByLibrary.simpleMessage(
            "Automatinis susiejimas veikia tik su įrenginiais, kurie palaiko „Chromecast“."),
        "available": MessageLookupByLibrary.simpleMessage("Prieinama"),
        "backup":
            MessageLookupByLibrary.simpleMessage("Kurti atsarginę kopiją"),
        "backupFile": MessageLookupByLibrary.simpleMessage(
            "Kurti atsarginę failo kopiją"),
        "backupOverMobileData": MessageLookupByLibrary.simpleMessage(
            "Kurti atsargines kopijas per mobiliuosius duomenis"),
        "backupSettings": MessageLookupByLibrary.simpleMessage(
            "Atsarginės kopijos nustatymai"),
        "backupStatus":
            MessageLookupByLibrary.simpleMessage("Atsarginės kopijos būsena"),
        "backupStatusDescription": MessageLookupByLibrary.simpleMessage(
            "Čia bus rodomi elementai, kurių atsarginės kopijos buvo sukurtos."),
        "backupVideos": MessageLookupByLibrary.simpleMessage(
            "Kurti atsargines vaizdo įrašų kopijas"),
        "birthday": MessageLookupByLibrary.simpleMessage("Gimtadienis"),
        "blackFridaySale": MessageLookupByLibrary.simpleMessage(
            "Juodojo penktadienio išpardavimas"),
        "blog": MessageLookupByLibrary.simpleMessage("Tinklaraštis"),
        "cachedData":
            MessageLookupByLibrary.simpleMessage("Podėliuoti duomenis"),
        "canNotOpenBody": MessageLookupByLibrary.simpleMessage(
            "Atsiprašome, šio albumo negalima atverti programoje."),
        "canNotOpenTitle":
            MessageLookupByLibrary.simpleMessage("Negalima atverti šio albumo"),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "Galima pašalinti tik jums priklausančius failus"),
        "cancel": MessageLookupByLibrary.simpleMessage("Atšaukti"),
        "cancelAccountRecovery":
            MessageLookupByLibrary.simpleMessage("Atšaukti atkūrimą"),
        "cancelAccountRecoveryBody": MessageLookupByLibrary.simpleMessage(
            "Ar tikrai norite atšaukti atkūrimą?"),
        "cancelOtherSubscription": m18,
        "cancelSubscription":
            MessageLookupByLibrary.simpleMessage("Atsisakyti prenumeratos"),
        "cannotAddMorePhotosAfterBecomingViewer": m3,
        "cannotDeleteSharedFiles": MessageLookupByLibrary.simpleMessage(
            "Negalima ištrinti bendrinamų failų."),
        "castAlbum": MessageLookupByLibrary.simpleMessage("Perduoti albumą"),
        "castIPMismatchBody": MessageLookupByLibrary.simpleMessage(
            "Įsitikinkite, kad esate tame pačiame tinkle kaip ir televizorius."),
        "castIPMismatchTitle":
            MessageLookupByLibrary.simpleMessage("Nepavyko perduoti albumo"),
        "castInstruction": MessageLookupByLibrary.simpleMessage(
            "Aplankykite cast.ente.io įrenginyje, kurį norite susieti.\n\nĮveskite toliau esantį kodą, kad paleistumėte albumą televizoriuje."),
        "centerPoint": MessageLookupByLibrary.simpleMessage("Vidurio taškas"),
        "change": MessageLookupByLibrary.simpleMessage("Keisti"),
        "changeEmail": MessageLookupByLibrary.simpleMessage("Keisti el. paštą"),
        "changeLocationOfSelectedItems": MessageLookupByLibrary.simpleMessage(
            "Keisti pasirinktų elementų vietovę?"),
        "changeLogBackupStatusContent": MessageLookupByLibrary.simpleMessage(
            "Pridėjome visų į „Ente“ įkeltų failų žurnalą, įskaitant nesėkmingus ir laukiančius eilėje."),
        "changeLogBackupStatusTitle":
            MessageLookupByLibrary.simpleMessage("Atsarginės kopijos būsena"),
        "changeLogDiscoverContent": MessageLookupByLibrary.simpleMessage(
            "Ieškote savo tapatybės kortelių, užrašų ar net memų nuotraukų? Eikite į paieškos kortelę ir patikrinkite Atrasti. Remiantis mūsų semantine paieška, joje rasite nuotraukų, kurios gali būti jums svarbios.\\n\\nPasiekiama tik tada, jei įjungėte mašininį mokymąsi."),
        "changeLogDiscoverTitle":
            MessageLookupByLibrary.simpleMessage("Atraskite"),
        "changeLogMagicSearchImprovementContent":
            MessageLookupByLibrary.simpleMessage(
                "Patobulinome magiškąją paiešką, kad ji taptų daug spartesnė ir jums nereikėtų laukti, kol rasite tai, ko ieškote."),
        "changeLogMagicSearchImprovementTitle":
            MessageLookupByLibrary.simpleMessage(
                "Magiškos paieškos patobulinimas"),
        "changePassword":
            MessageLookupByLibrary.simpleMessage("Keisti slaptažodį"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Keisti slaptažodį"),
        "changePermissions":
            MessageLookupByLibrary.simpleMessage("Keisti leidimus?"),
        "changeYourReferralCode": MessageLookupByLibrary.simpleMessage(
            "Keisti savo rekomendacijos kodą"),
        "checkForUpdates": MessageLookupByLibrary.simpleMessage(
            "Tikrinti, ar yra atnaujinimų"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Patikrinkite savo gautieją (ir šlamštą), kad užbaigtumėte patvirtinimą"),
        "checkStatus": MessageLookupByLibrary.simpleMessage("Tikrinti būseną"),
        "checking": MessageLookupByLibrary.simpleMessage("Tikrinama..."),
        "checkingModels":
            MessageLookupByLibrary.simpleMessage("Tikrinami modeliai..."),
        "claimFreeStorage":
            MessageLookupByLibrary.simpleMessage("Gaukite nemokamos saugyklos"),
        "claimMore": MessageLookupByLibrary.simpleMessage("Gaukite daugiau!"),
        "claimed": MessageLookupByLibrary.simpleMessage("Gauta"),
        "claimedStorageSoFar": m19,
        "cleanUncategorized":
            MessageLookupByLibrary.simpleMessage("Valyti nekategorizuotus"),
        "cleanUncategorizedDescription": MessageLookupByLibrary.simpleMessage(
            "Pašalinkite iš nekategorizuotus visus failus, esančius kituose albumuose"),
        "clearCaches": MessageLookupByLibrary.simpleMessage("Valyti podėlius"),
        "clearIndexes":
            MessageLookupByLibrary.simpleMessage("Valyti indeksavimus"),
        "close": MessageLookupByLibrary.simpleMessage("Uždaryti"),
        "clusteringProgress":
            MessageLookupByLibrary.simpleMessage("Sankaupos vykdymas"),
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("Pritaikytas kodas"),
        "codeChangeLimitReached": MessageLookupByLibrary.simpleMessage(
            "Atsiprašome, pasiekėte kodo pakeitimų ribą."),
        "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Nukopijuotas kodas į iškarpinę"),
        "codeUsedByYou":
            MessageLookupByLibrary.simpleMessage("Jūsų naudojamas kodas"),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Sukurkite nuorodą, kad asmenys galėtų pridėti ir peržiūrėti nuotraukas bendrinamame albume, nereikalaujant „Ente“ programos ar paskyros. Puikiai tinka įvykių nuotraukoms rinkti."),
        "collaborativeLink":
            MessageLookupByLibrary.simpleMessage("Bendradarbiavimo nuoroda"),
        "collaborator": MessageLookupByLibrary.simpleMessage("Bendradarbis"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Bendradarbiai gali pridėti nuotraukų ir vaizdo įrašų į bendrintą albumą."),
        "collaboratorsSuccessfullyAdded": m21,
        "collect": MessageLookupByLibrary.simpleMessage("Rinkti"),
        "collectEventPhotos":
            MessageLookupByLibrary.simpleMessage("Rinkti įvykių nuotraukas"),
        "collectPhotos":
            MessageLookupByLibrary.simpleMessage("Rinkti nuotraukas"),
        "collectPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Sukurkite nuorodą, į kurią draugai gali įkelti originalios kokybės nuotraukas."),
        "color": MessageLookupByLibrary.simpleMessage("Spalva"),
        "configuration": MessageLookupByLibrary.simpleMessage("Konfiguracija"),
        "confirm": MessageLookupByLibrary.simpleMessage("Patvirtinti"),
        "confirm2FADisable": MessageLookupByLibrary.simpleMessage(
            "Ar tikrai norite išjungti dvigubą tapatybės nustatymą?"),
        "confirmAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Patvirtinti paskyros ištrynimą"),
        "confirmAddingTrustedContact": m22,
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Taip, noriu negrįžtamai ištrinti šią paskyrą ir jos duomenis per visas programas"),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Patvirtinkite slaptažodį"),
        "confirmPlanChange": MessageLookupByLibrary.simpleMessage(
            "Patvirtinkite plano pakeitimą"),
        "confirmRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Patvirtinkite atkūrimo raktą"),
        "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Patvirtinkite savo atkūrimo raktą"),
        "connectToDevice":
            MessageLookupByLibrary.simpleMessage("Prijungti prie įrenginio"),
        "contactSupport": MessageLookupByLibrary.simpleMessage(
            "Susisiekti su palaikymo komanda"),
        "contacts": MessageLookupByLibrary.simpleMessage("Kontaktai"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("Tęsti"),
        "continueOnFreeTrial": MessageLookupByLibrary.simpleMessage(
            "Tęsti nemokame bandomajame laikotarpyje"),
        "copyEmailAddress":
            MessageLookupByLibrary.simpleMessage("Kopijuoti el. pašto adresą"),
        "copyLink": MessageLookupByLibrary.simpleMessage("Kopijuoti nuorodą"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Nukopijuokite ir įklijuokite šį kodą\nį autentifikatoriaus programą"),
        "couldNotBackUpTryLater": MessageLookupByLibrary.simpleMessage(
            "Nepavyko sukurti atsarginės duomenų kopijos.\nBandysime pakartotinai vėliau."),
        "couldNotFreeUpSpace": MessageLookupByLibrary.simpleMessage(
            "Nepavyko atlaisvinti vietos."),
        "create": MessageLookupByLibrary.simpleMessage("Kurti"),
        "createAccount": MessageLookupByLibrary.simpleMessage("Kurti paskyrą"),
        "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
            "Ilgai paspauskite, kad pasirinktumėte nuotraukas, ir spustelėkite +, kad sukurtumėte albumą"),
        "createCollaborativeLink": MessageLookupByLibrary.simpleMessage(
            "Kurti bendradarbiavimo nuorodą"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("Kurti naują paskyrą"),
        "createOrSelectAlbum": MessageLookupByLibrary.simpleMessage(
            "Kurkite arba pasirinkite albumą"),
        "createPublicLink":
            MessageLookupByLibrary.simpleMessage("Kurti viešą nuorodą"),
        "creatingLink":
            MessageLookupByLibrary.simpleMessage("Kuriama nuoroda..."),
        "criticalUpdateAvailable":
            MessageLookupByLibrary.simpleMessage("Yra kritinis naujinimas"),
        "crop": MessageLookupByLibrary.simpleMessage("Apkirpti"),
        "currentUsageIs":
            MessageLookupByLibrary.simpleMessage("Dabartinis naudojimas – "),
        "currentlyRunning":
            MessageLookupByLibrary.simpleMessage("šiuo metu vykdoma"),
        "custom": MessageLookupByLibrary.simpleMessage("Pasirinktinis"),
        "customEndpoint": m25,
        "darkTheme": MessageLookupByLibrary.simpleMessage("Tamsi"),
        "dayToday": MessageLookupByLibrary.simpleMessage("Šiandien"),
        "dayYesterday": MessageLookupByLibrary.simpleMessage("Vakar"),
        "declineTrustInvite":
            MessageLookupByLibrary.simpleMessage("Atmesti kvietimą"),
        "decrypting": MessageLookupByLibrary.simpleMessage("Iššifruojama..."),
        "deduplicateFiles":
            MessageLookupByLibrary.simpleMessage("Atdubliuoti failus"),
        "delete": MessageLookupByLibrary.simpleMessage("Ištrinti"),
        "deleteAccount":
            MessageLookupByLibrary.simpleMessage("Ištrinti paskyrą"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "Apgailestaujame, kad išeinate. Pasidalykite savo atsiliepimais, kad padėtumėte mums tobulėti."),
        "deleteAccountPermanentlyButton": MessageLookupByLibrary.simpleMessage(
            "Ištrinti paskyrą negrįžtamai"),
        "deleteAlbum": MessageLookupByLibrary.simpleMessage("Ištrinti albumą"),
        "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
            "Taip pat ištrinti šiame albume esančias nuotraukas (ir vaizdo įrašus) iš <bold>visų</bold> kitų albumų, kuriuose jos yra dalis?"),
        "deleteAlbumsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Tai ištrins visus tuščius albumus. Tai naudinga, kai norite sumažinti netvarką savo albumų sąraše."),
        "deleteAll": MessageLookupByLibrary.simpleMessage("Ištrinti viską"),
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
            "Ši paskyra susieta su kitomis „Ente“ programomis, jei jas naudojate. Jūsų įkelti duomenys per visas „Ente“ programas bus planuojama ištrinti, o jūsų paskyra bus ištrinta negrįžtamai."),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "Iš savo registruoto el. pašto adreso siųskite el. laišką adresu <warning>account-deletion@ente.io</warning>."),
        "deleteEmptyAlbums":
            MessageLookupByLibrary.simpleMessage("Ištrinti tuščius albumus"),
        "deleteEmptyAlbumsWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Ištrinti tuščius albumus?"),
        "deleteFromBoth":
            MessageLookupByLibrary.simpleMessage("Ištrinti iš abiejų"),
        "deleteFromDevice":
            MessageLookupByLibrary.simpleMessage("Ištrinti iš įrenginio"),
        "deleteFromEnte":
            MessageLookupByLibrary.simpleMessage("Ištrinti iš „Ente“"),
        "deleteItemCount": m26,
        "deleteLocation":
            MessageLookupByLibrary.simpleMessage("Ištrinti vietovę"),
        "deletePhotos":
            MessageLookupByLibrary.simpleMessage("Ištrinti nuotraukas"),
        "deleteProgress": m27,
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "Trūksta pagrindinės funkcijos, kurios man reikia"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "Programa arba tam tikra funkcija nesielgia taip, kaip, mano manymu, turėtų elgtis"),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
            "Radau kitą paslaugą, kuri man patinka labiau"),
        "deleteReason4":
            MessageLookupByLibrary.simpleMessage("Mano priežastis nenurodyta"),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
            "Jūsų prašymas bus apdorotas per 72 valandas."),
        "deleteSharedAlbum":
            MessageLookupByLibrary.simpleMessage("Ištrinti bendrinamą albumą?"),
        "deleteSharedAlbumDialogBody": MessageLookupByLibrary.simpleMessage(
            "Albumas bus ištrintas visiems.\n\nPrarasite prieigą prie bendrinamų nuotraukų, esančių šiame albume ir priklausančių kitiems."),
        "designedToOutlive":
            MessageLookupByLibrary.simpleMessage("Sukurta išgyventi"),
        "details": MessageLookupByLibrary.simpleMessage("Išsami informacija"),
        "developerSettings":
            MessageLookupByLibrary.simpleMessage("Kūrėjo nustatymai"),
        "developerSettingsWarning": MessageLookupByLibrary.simpleMessage(
            "Ar tikrai norite modifikuoti kūrėjo nustatymus?"),
        "deviceCodeHint": MessageLookupByLibrary.simpleMessage("Įveskite kodą"),
        "deviceLock":
            MessageLookupByLibrary.simpleMessage("Įrenginio užraktas"),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
            "Išjunkite įrenginio ekrano užraktą, kai „Ente“ yra priekiniame fone ir kuriama atsarginės kopijos. Paprastai to nereikia, bet tai gali padėti greičiau užbaigti didelius įkėlimus ir pradinį didelių bibliotekų importą."),
        "deviceNotFound":
            MessageLookupByLibrary.simpleMessage("Įrenginys nerastas"),
        "didYouKnow": MessageLookupByLibrary.simpleMessage("Ar žinojote?"),
        "disableAutoLock":
            MessageLookupByLibrary.simpleMessage("Išjungti automatinį užraktą"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Žiūrėtojai vis tiek gali daryti ekrano kopijas arba išsaugoti nuotraukų kopijas naudojant išorinius įrankius"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Atkreipkite dėmesį"),
        "disableLinkMessage": m28,
        "disableTwofactor": MessageLookupByLibrary.simpleMessage(
            "Išjungti dvigubą tapatybės nustatymą"),
        "discord": MessageLookupByLibrary.simpleMessage("„Discord“"),
        "discover": MessageLookupByLibrary.simpleMessage("Atraskite"),
        "discover_babies": MessageLookupByLibrary.simpleMessage("Kūdikiai"),
        "discover_celebrations":
            MessageLookupByLibrary.simpleMessage("Šventės"),
        "discover_food": MessageLookupByLibrary.simpleMessage("Maistas"),
        "discover_greenery": MessageLookupByLibrary.simpleMessage("Žaluma"),
        "discover_hills": MessageLookupByLibrary.simpleMessage("Kalvos"),
        "discover_identity": MessageLookupByLibrary.simpleMessage("Tapatybė"),
        "discover_memes": MessageLookupByLibrary.simpleMessage("Mėmai"),
        "discover_notes": MessageLookupByLibrary.simpleMessage("Užrašai"),
        "discover_pets": MessageLookupByLibrary.simpleMessage("Gyvūnai"),
        "discover_receipts": MessageLookupByLibrary.simpleMessage("Kvitai"),
        "discover_screenshots":
            MessageLookupByLibrary.simpleMessage("Ekrano kopijos"),
        "discover_selfies": MessageLookupByLibrary.simpleMessage("Asmenukės"),
        "discover_sunset": MessageLookupByLibrary.simpleMessage("Saulėlydis"),
        "discover_visiting_cards":
            MessageLookupByLibrary.simpleMessage("Lankymo kortelės"),
        "discover_wallpapers":
            MessageLookupByLibrary.simpleMessage("Ekrano fonai"),
        "distanceInKMUnit": MessageLookupByLibrary.simpleMessage("km"),
        "doNotSignOut": MessageLookupByLibrary.simpleMessage("Neatsijungti"),
        "doThisLater":
            MessageLookupByLibrary.simpleMessage("Daryti tai vėliau"),
        "done": MessageLookupByLibrary.simpleMessage("Atlikta"),
        "doubleYourStorage":
            MessageLookupByLibrary.simpleMessage("Padvigubinkite saugyklą"),
        "download": MessageLookupByLibrary.simpleMessage("Atsisiųsti"),
        "downloadFailed":
            MessageLookupByLibrary.simpleMessage("Atsisiuntimas nepavyko."),
        "downloading": MessageLookupByLibrary.simpleMessage("Atsisiunčiama..."),
        "dropSupportEmail": m29,
        "duplicateFileCountWithStorageSaved": m30,
        "duplicateItemsGroup": m31,
        "edit": MessageLookupByLibrary.simpleMessage("Redaguoti"),
        "editLocation":
            MessageLookupByLibrary.simpleMessage("Redaguoti vietovę"),
        "editLocationTagTitle":
            MessageLookupByLibrary.simpleMessage("Redaguoti vietovę"),
        "editPerson": MessageLookupByLibrary.simpleMessage("Redaguoti asmenį"),
        "editsToLocationWillOnlyBeSeenWithinEnte":
            MessageLookupByLibrary.simpleMessage(
                "Vietovės pakeitimai bus matomi tik per „Ente“"),
        "eligible": MessageLookupByLibrary.simpleMessage("tinkamas"),
        "email": MessageLookupByLibrary.simpleMessage("El. paštas"),
        "emailAlreadyRegistered": MessageLookupByLibrary.simpleMessage(
            "El. paštas jau užregistruotas."),
        "emailNoEnteAccount": m33,
        "emailNotRegistered":
            MessageLookupByLibrary.simpleMessage("El. paštas neregistruotas."),
        "emailVerificationToggle":
            MessageLookupByLibrary.simpleMessage("El. pašto patvirtinimas"),
        "emailYourLogs": MessageLookupByLibrary.simpleMessage(
            "Atsiųskite žurnalus el. laišku"),
        "emergencyContacts":
            MessageLookupByLibrary.simpleMessage("Skubios pagalbos kontaktai"),
        "empty": MessageLookupByLibrary.simpleMessage("Ištuštinti"),
        "emptyTrash":
            MessageLookupByLibrary.simpleMessage("Ištuštinti šiukšlinę?"),
        "enable": MessageLookupByLibrary.simpleMessage("Įjungti"),
        "enableMLIndexingDesc": MessageLookupByLibrary.simpleMessage(
            "„Ente“ palaiko įrenginyje mašininį mokymąsi, skirtą veidų atpažinimui, magiškai paieškai ir kitoms išplėstinėms paieškos funkcijoms"),
        "enableMachineLearningBanner": MessageLookupByLibrary.simpleMessage(
            "Įjunkite mašininį mokymąsi magiškai paieškai ir veidų atpažinimui"),
        "enableMaps":
            MessageLookupByLibrary.simpleMessage("Įjungti žemėlapius"),
        "enableMapsDesc": MessageLookupByLibrary.simpleMessage(
            "Tai parodys jūsų nuotraukas pasaulio žemėlapyje.\n\nŠį žemėlapį talpina „OpenStreetMap“, o tiksliomis nuotraukų vietovėmis niekada nebendrinama.\n\nŠią funkciją bet kada galite išjungti iš nustatymų."),
        "enabled": MessageLookupByLibrary.simpleMessage("Įjungta"),
        "encryption": MessageLookupByLibrary.simpleMessage("Šifravimas"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Šifravimo raktai"),
        "endpointUpdatedMessage": MessageLookupByLibrary.simpleMessage(
            "Galutinis taškas sėkmingai atnaujintas"),
        "endtoendEncryptedByDefault": MessageLookupByLibrary.simpleMessage(
            "Pagal numatytąjį užšifruota visapusiškai"),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
            "„Ente“ <i>reikia leidimo</i> išsaugoti jūsų nuotraukas"),
        "enteSubscriptionPitch": MessageLookupByLibrary.simpleMessage(
            "„Ente“ išsaugo jūsų prisiminimus, todėl jie visada bus pasiekiami, net jei prarasite įrenginį."),
        "enteSubscriptionShareWithFamily": MessageLookupByLibrary.simpleMessage(
            "Į planą galima pridėti ir savo šeimą."),
        "enterAlbumName":
            MessageLookupByLibrary.simpleMessage("Įveskite albumo pavadinimą"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Įvesti kodą"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
            "Įveskite draugo pateiktą kodą, kad gautumėte nemokamą saugyklą abiem."),
        "enterDateOfBirth":
            MessageLookupByLibrary.simpleMessage("Gimtadienis (neprivaloma)"),
        "enterEmail":
            MessageLookupByLibrary.simpleMessage("Įveskite el. paštą"),
        "enterName": MessageLookupByLibrary.simpleMessage("Įveskite vardą"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Įveskite naują slaptažodį, kurį galime naudoti jūsų duomenims šifruoti"),
        "enterPassword":
            MessageLookupByLibrary.simpleMessage("Įveskite slaptažodį"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Įveskite slaptažodį, kurį galime naudoti jūsų duomenims šifruoti"),
        "enterPersonName":
            MessageLookupByLibrary.simpleMessage("Įveskite asmens vardą"),
        "enterPin": MessageLookupByLibrary.simpleMessage("Įveskite PIN"),
        "enterReferralCode": MessageLookupByLibrary.simpleMessage(
            "Įveskite rekomendacijos kodą"),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Įveskite 6 skaitmenų kodą\niš autentifikatoriaus programos"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "Įveskite tinkamą el. pašto adresą."),
        "enterYourEmailAddress": MessageLookupByLibrary.simpleMessage(
            "Įveskite savo el. pašto adresą"),
        "enterYourPassword":
            MessageLookupByLibrary.simpleMessage("Įveskite savo slaptažodį"),
        "enterYourRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Įveskite atkūrimo raktą"),
        "error": MessageLookupByLibrary.simpleMessage("Klaida"),
        "everywhere": MessageLookupByLibrary.simpleMessage("visur"),
        "exif": MessageLookupByLibrary.simpleMessage("EXIF"),
        "existingUser":
            MessageLookupByLibrary.simpleMessage("Esamas naudotojas"),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
            "Ši nuoroda nebegalioja. Pasirinkite naują galiojimo laiką arba išjunkite nuorodos galiojimo laiką."),
        "exportLogs":
            MessageLookupByLibrary.simpleMessage("Eksportuoti žurnalus"),
        "exportYourData":
            MessageLookupByLibrary.simpleMessage("Eksportuoti duomenis"),
        "extraPhotosFound": MessageLookupByLibrary.simpleMessage(
            "Rastos papildomos nuotraukos"),
        "extraPhotosFoundFor": m34,
        "faceNotClusteredYet": MessageLookupByLibrary.simpleMessage(
            "Veidas dar nesugrupuotas. Grįžkite vėliau."),
        "faceRecognition":
            MessageLookupByLibrary.simpleMessage("Veido atpažinimas"),
        "faces": MessageLookupByLibrary.simpleMessage("Veidai"),
        "failedToApplyCode":
            MessageLookupByLibrary.simpleMessage("Nepavyko pritaikyti kodo."),
        "failedToCancel":
            MessageLookupByLibrary.simpleMessage("Nepavyko atsisakyti"),
        "failedToFetchActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Nepavyko gauti aktyvių seansų."),
        "failedToFetchOriginalForEdit": MessageLookupByLibrary.simpleMessage(
            "Nepavyko gauti originalo redagavimui."),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "Nepavyksta gauti rekomendacijos informacijos. Bandykite dar kartą vėliau."),
        "failedToLoadAlbums":
            MessageLookupByLibrary.simpleMessage("Nepavyko įkelti albumų."),
        "failedToPlayVideo": MessageLookupByLibrary.simpleMessage(
            "Nepavyko paleisti vaizdo įrašą. "),
        "failedToRefreshStripeSubscription":
            MessageLookupByLibrary.simpleMessage(
                "Nepavyko atnaujinti prenumeratos."),
        "failedToVerifyPaymentStatus": MessageLookupByLibrary.simpleMessage(
            "Nepavyko patvirtinti mokėjimo būsenos"),
        "familyPlanPortalTitle": MessageLookupByLibrary.simpleMessage("Šeima"),
        "familyPlans": MessageLookupByLibrary.simpleMessage("Šeimos planai"),
        "faq": MessageLookupByLibrary.simpleMessage("DUK"),
        "faqs": MessageLookupByLibrary.simpleMessage("DUK"),
        "feedback": MessageLookupByLibrary.simpleMessage("Atsiliepimai"),
        "file": MessageLookupByLibrary.simpleMessage("Failas"),
        "fileInfoAddDescHint":
            MessageLookupByLibrary.simpleMessage("Pridėti aprašymą..."),
        "fileNotUploadedYet":
            MessageLookupByLibrary.simpleMessage("Failas dar neįkeltas."),
        "fileTypes": MessageLookupByLibrary.simpleMessage("Failų tipai"),
        "findPeopleByName": MessageLookupByLibrary.simpleMessage(
            "Greitai suraskite žmones pagal vardą"),
        "findThemQuickly":
            MessageLookupByLibrary.simpleMessage("Raskite juos greitai"),
        "forYourMemories":
            MessageLookupByLibrary.simpleMessage("jūsų prisiminimams"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Pamiršau slaptažodį"),
        "foundFaces": MessageLookupByLibrary.simpleMessage("Rasti veidai"),
        "freeStorageClaimed":
            MessageLookupByLibrary.simpleMessage("Gauta nemokama saugykla"),
        "freeStorageOnReferralSuccess": m4,
        "freeStorageUsable":
            MessageLookupByLibrary.simpleMessage("Naudojama nemokama saugykla"),
        "freeTrial": MessageLookupByLibrary.simpleMessage(
            "Nemokamas bandomasis laikotarpis"),
        "freeTrialValidTill": m37,
        "freeUpAmount": m39,
        "gallery": MessageLookupByLibrary.simpleMessage("Galerija"),
        "galleryMemoryLimitInfo": MessageLookupByLibrary.simpleMessage(
            "Galerijoje rodoma iki 1000 prisiminimų"),
        "general": MessageLookupByLibrary.simpleMessage("Bendrieji"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Generuojami šifravimo raktai..."),
        "genericProgress": m41,
        "goToSettings":
            MessageLookupByLibrary.simpleMessage("Eiti į nustatymus"),
        "googlePlayId":
            MessageLookupByLibrary.simpleMessage("„Google Play“ ID"),
        "grantPermission":
            MessageLookupByLibrary.simpleMessage("Suteikti leidimą"),
        "guestView": MessageLookupByLibrary.simpleMessage("Svečio peržiūra"),
        "guestViewEnablePreSteps": MessageLookupByLibrary.simpleMessage(
            "Kad įjungtumėte svečio peržiūrą, sistemos nustatymuose nustatykite įrenginio prieigos kodą arba ekrano užraktą."),
        "hearUsExplanation": MessageLookupByLibrary.simpleMessage(
            "Mes nesekame programų diegimų. Mums padėtų, jei pasakytumėte, kur mus radote."),
        "hearUsWhereTitle": MessageLookupByLibrary.simpleMessage(
            "Kaip išgirdote apie „Ente“? (nebūtina)"),
        "help": MessageLookupByLibrary.simpleMessage("Pagalba"),
        "hidden": MessageLookupByLibrary.simpleMessage("Paslėpti"),
        "hide": MessageLookupByLibrary.simpleMessage("Slėpti"),
        "hideContent": MessageLookupByLibrary.simpleMessage("Slėpti turinį"),
        "hideContentDescriptionAndroid": MessageLookupByLibrary.simpleMessage(
            "Paslepia programų turinį programų perjungiklyje ir išjungia ekrano kopijas"),
        "hideContentDescriptionIos": MessageLookupByLibrary.simpleMessage(
            "Paslepia programos turinį programos perjungiklyje"),
        "hideSharedItemsFromHomeGallery": MessageLookupByLibrary.simpleMessage(
            "Slėpti bendrinamus elementus iš pagrindinės galerijos"),
        "hiding": MessageLookupByLibrary.simpleMessage("Slepiama..."),
        "howItWorks": MessageLookupByLibrary.simpleMessage("Kaip tai veikia"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "Paprašykite jų ilgai paspausti savo el. pašto adresą nustatymų ekrane ir patvirtinti, kad abiejų įrenginių ID sutampa."),
        "iOSGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "Biometrinis tapatybės nustatymas jūsų įrenginyje nenustatytas. Telefone įjunkite „Touch ID“ arba „Face ID“."),
        "iOSLockOut": MessageLookupByLibrary.simpleMessage(
            "Biometrinis tapatybės nustatymas išjungtas. Kad jį įjungtumėte, užrakinkite ir atrakinkite ekraną."),
        "iOSOkButton": MessageLookupByLibrary.simpleMessage("Gerai"),
        "ignoreUpdate": MessageLookupByLibrary.simpleMessage("Ignoruoti"),
        "ignored": MessageLookupByLibrary.simpleMessage("ignoruota"),
        "imageNotAnalyzed":
            MessageLookupByLibrary.simpleMessage("Vaizdas neanalizuotas."),
        "immediately": MessageLookupByLibrary.simpleMessage("Iš karto"),
        "importing": MessageLookupByLibrary.simpleMessage("Importuojama...."),
        "incorrectCode":
            MessageLookupByLibrary.simpleMessage("Neteisingas kodas."),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Neteisingas slaptažodis"),
        "incorrectRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Neteisingas atkūrimo raktas"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "Įvestas atkūrimo raktas yra neteisingas."),
        "incorrectRecoveryKeyTitle":
            MessageLookupByLibrary.simpleMessage("Neteisingas atkūrimo raktas"),
        "indexedItems":
            MessageLookupByLibrary.simpleMessage("Indeksuoti elementai"),
        "indexingIsPaused": MessageLookupByLibrary.simpleMessage(
            "Indeksavimas pristabdytas. Jis bus automatiškai tęsiamas, kai įrenginys yra paruoštas."),
        "info": MessageLookupByLibrary.simpleMessage("Informacija"),
        "insecureDevice":
            MessageLookupByLibrary.simpleMessage("Nesaugus įrenginys"),
        "installManually":
            MessageLookupByLibrary.simpleMessage("Diegti rankiniu būdu"),
        "invalidEmailAddress": MessageLookupByLibrary.simpleMessage(
            "Netinkamas el. pašto adresas"),
        "invalidEndpoint":
            MessageLookupByLibrary.simpleMessage("Netinkamas galutinis taškas"),
        "invalidEndpointMessage": MessageLookupByLibrary.simpleMessage(
            "Atsiprašome, įvestas galutinis taškas netinkamas. Įveskite tinkamą galutinį tašką ir bandykite dar kartą."),
        "invalidKey":
            MessageLookupByLibrary.simpleMessage("Netinkamas raktas."),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Įvestas atkūrimo raktas yra netinkamas. Įsitikinkite, kad jame yra 24 žodžiai, ir patikrinkite kiekvieno iš jų rašybą.\n\nJei įvedėte senesnį atkūrimo kodą, įsitikinkite, kad jis yra 64 simbolių ilgio, ir patikrinkite kiekvieną iš jų."),
        "inviteToEnte":
            MessageLookupByLibrary.simpleMessage("Kviesti į „Ente“"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Kviesti savo draugus"),
        "itLooksLikeSomethingWentWrongPleaseRetryAfterSome":
            MessageLookupByLibrary.simpleMessage(
                "Atrodo, kad kažkas nutiko ne taip. Bandykite pakartotinai po kurio laiko. Jei klaida tęsiasi, susisiekite su mūsų palaikymo komanda."),
        "itemCount": m42,
        "itemsShowTheNumberOfDaysRemainingBeforePermanentDeletion":
            MessageLookupByLibrary.simpleMessage(
                "Elementai rodo likusių dienų skaičių iki visiško ištrynimo."),
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "Pasirinkti elementai bus pašalinti iš šio albumo"),
        "join": MessageLookupByLibrary.simpleMessage("Jungtis"),
        "joinAlbum":
            MessageLookupByLibrary.simpleMessage("Junkitės prie albumo"),
        "joinAlbumSubtext": MessageLookupByLibrary.simpleMessage(
            "kad peržiūrėtumėte ir pridėtumėte savo nuotraukas"),
        "joinAlbumSubtextViewer": MessageLookupByLibrary.simpleMessage(
            "kad pridėtumėte tai prie bendrinamų albumų"),
        "joinDiscord":
            MessageLookupByLibrary.simpleMessage("Jungtis prie „Discord“"),
        "keepPhotos":
            MessageLookupByLibrary.simpleMessage("Palikti nuotraukas"),
        "kiloMeterUnit": MessageLookupByLibrary.simpleMessage("km"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Maloniai padėkite mums su šia informacija."),
        "lastUpdated":
            MessageLookupByLibrary.simpleMessage("Paskutinį kartą atnaujintą"),
        "leave": MessageLookupByLibrary.simpleMessage("Palikti"),
        "leaveAlbum": MessageLookupByLibrary.simpleMessage("Palikti albumą"),
        "leaveFamily": MessageLookupByLibrary.simpleMessage("Palikti šeimą"),
        "leaveSharedAlbum":
            MessageLookupByLibrary.simpleMessage("Palikti bendrinamą albumą?"),
        "left": MessageLookupByLibrary.simpleMessage("Kairė"),
        "legacy": MessageLookupByLibrary.simpleMessage("Palikimas"),
        "legacyAccounts":
            MessageLookupByLibrary.simpleMessage("Palikimo paskyros"),
        "legacyInvite": m43,
        "legacyPageDesc": MessageLookupByLibrary.simpleMessage(
            "Palikimas leidžia patikimiems kontaktams pasiekti jūsų paskyrą jums nesant."),
        "legacyPageDesc2": MessageLookupByLibrary.simpleMessage(
            "Patikimi kontaktai gali pradėti paskyros atkūrimą, o jei per 30 dienų paskyra neužblokuojama, iš naujo nustatyti slaptažodį ir pasiekti paskyrą."),
        "light": MessageLookupByLibrary.simpleMessage("Šviesi"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("Šviesi"),
        "link": MessageLookupByLibrary.simpleMessage("Susieti"),
        "linkDeviceLimit":
            MessageLookupByLibrary.simpleMessage("Įrenginių riba"),
        "linkEmail": MessageLookupByLibrary.simpleMessage("Susieti el. paštą"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Įjungta"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Nebegalioja"),
        "linkExpiresOn": m44,
        "linkExpiry":
            MessageLookupByLibrary.simpleMessage("Nuorodos galiojimo laikas"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("Nuoroda nebegalioja"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Niekada"),
        "livePhotos": MessageLookupByLibrary.simpleMessage("Gyvos nuotraukos"),
        "loadMessage1": MessageLookupByLibrary.simpleMessage(
            "Galite bendrinti savo prenumeratą su šeima."),
        "loadMessage2": MessageLookupByLibrary.simpleMessage(
            "Iki šiol išsaugojome daugiau kaip 30 milijonų prisiminimų."),
        "loadMessage3": MessageLookupByLibrary.simpleMessage(
            "Laikome 3 jūsų duomenų kopijas, vieną iš jų – požeminėje priešgaisrinėje slėptuvėje."),
        "loadMessage4": MessageLookupByLibrary.simpleMessage(
            "Visos mūsų programos yra atvirojo kodo."),
        "loadMessage5": MessageLookupByLibrary.simpleMessage(
            "Mūsų šaltinio kodas ir kriptografija buvo išoriškai audituoti."),
        "loadMessage6": MessageLookupByLibrary.simpleMessage(
            "Galite bendrinti savo albumų nuorodas su artimaisiais."),
        "loadMessage7": MessageLookupByLibrary.simpleMessage(
            "Mūsų mobiliosios programos veikia fone, kad užšifruotų ir sukurtų atsarginę kopiją visų naujų nuotraukų, kurias spustelėjate."),
        "loadMessage8": MessageLookupByLibrary.simpleMessage(
            "web.ente.io turi sklandų įkėlėją"),
        "loadMessage9": MessageLookupByLibrary.simpleMessage(
            "Naudojame „Xchacha20Poly1305“, kad saugiai užšifruotume jūsų duomenis."),
        "loadingGallery":
            MessageLookupByLibrary.simpleMessage("Įkeliama galerija..."),
        "loadingModel":
            MessageLookupByLibrary.simpleMessage("Atsisiunčiami modeliai..."),
        "loadingYourPhotos":
            MessageLookupByLibrary.simpleMessage("Įkeliamos nuotraukos..."),
        "localGallery":
            MessageLookupByLibrary.simpleMessage("Vietinė galerija"),
        "localIndexing":
            MessageLookupByLibrary.simpleMessage("Vietinis indeksavimas"),
        "localSyncErrorMessage": MessageLookupByLibrary.simpleMessage(
            "Atrodo, kad kažkas nutiko ne taip, nes vietinių nuotraukų sinchronizavimas trunka ilgiau nei tikėtasi. Susisiekite su mūsų palaikymo komanda."),
        "location": MessageLookupByLibrary.simpleMessage("Vietovė"),
        "locationName":
            MessageLookupByLibrary.simpleMessage("Vietovės pavadinimas"),
        "locationTagFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "Vietos žymė grupuoja visas nuotraukas, kurios buvo padarytos tam tikru spinduliu nuo nuotraukos"),
        "locations": MessageLookupByLibrary.simpleMessage("Vietovės"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Užrakinti"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Prisijungti"),
        "loggingOut": MessageLookupByLibrary.simpleMessage("Atsijungiama..."),
        "loginSessionExpired":
            MessageLookupByLibrary.simpleMessage("Seansas baigėsi"),
        "loginSessionExpiredDetails": MessageLookupByLibrary.simpleMessage(
            "Jūsų seansas baigėsi. Prisijunkite iš naujo."),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "Spustelėjus Prisijungti sutinku su <u-terms>paslaugų sąlygomis</u-terms> ir <u-policy> privatumo politika</u-policy>"),
        "loginWithTOTP":
            MessageLookupByLibrary.simpleMessage("Prisijungti su TOTP"),
        "logout": MessageLookupByLibrary.simpleMessage("Atsijungti"),
        "logsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Tai nusiųs žurnalus, kurie padės mums išspręsti jūsų problemą. Atkreipkite dėmesį, kad failų pavadinimai bus įtraukti, kad būtų lengviau atsekti problemas su konkrečiais failais."),
        "longPressAnEmailToVerifyEndToEndEncryption":
            MessageLookupByLibrary.simpleMessage(
                "Ilgai paspauskite el. paštą, kad patvirtintumėte visapusį šifravimą."),
        "loopVideoOff": MessageLookupByLibrary.simpleMessage(
            "Išjungtas vaizdo įrašo ciklas"),
        "loopVideoOn": MessageLookupByLibrary.simpleMessage(
            "Įjungtas vaizdo įrašo ciklas"),
        "lostDevice":
            MessageLookupByLibrary.simpleMessage("Prarastas įrenginys?"),
        "machineLearning":
            MessageLookupByLibrary.simpleMessage("Mašininis mokymasis"),
        "magicSearch": MessageLookupByLibrary.simpleMessage("Magiška paieška"),
        "magicSearchHint": MessageLookupByLibrary.simpleMessage(
            "Magiška paieška leidžia ieškoti nuotraukų pagal jų turinį, pvz., „gėlė“, „raudonas automobilis“, „tapatybės dokumentai“"),
        "manage": MessageLookupByLibrary.simpleMessage("Tvarkyti"),
        "manageDeviceStorage":
            MessageLookupByLibrary.simpleMessage("Tvarkyti įrenginio podėlį"),
        "manageDeviceStorageDesc": MessageLookupByLibrary.simpleMessage(
            "Peržiūrėkite ir išvalykite vietinę podėlį."),
        "manageFamily": MessageLookupByLibrary.simpleMessage("Tvarkyti šeimą"),
        "manageLink": MessageLookupByLibrary.simpleMessage("Tvarkyti nuorodą"),
        "manageParticipants": MessageLookupByLibrary.simpleMessage("Tvarkyti"),
        "manageSubscription":
            MessageLookupByLibrary.simpleMessage("Tvarkyti prenumeratą"),
        "manualPairDesc": MessageLookupByLibrary.simpleMessage(
            "Susieti su PIN kodu veikia bet kuriame ekrane, kuriame norite peržiūrėti albumą."),
        "map": MessageLookupByLibrary.simpleMessage("Žemėlapis"),
        "maps": MessageLookupByLibrary.simpleMessage("Žemėlapiai"),
        "mastodon": MessageLookupByLibrary.simpleMessage("„Mastodon“"),
        "matrix": MessageLookupByLibrary.simpleMessage("„Matrix“"),
        "memoryCount": m5,
        "merchandise": MessageLookupByLibrary.simpleMessage("Atributika"),
        "mergeWithExisting":
            MessageLookupByLibrary.simpleMessage("Sujungti su esamais"),
        "mergedPhotos":
            MessageLookupByLibrary.simpleMessage("Sujungtos nuotraukos"),
        "mlConsent":
            MessageLookupByLibrary.simpleMessage("Įjungti mašininį mokymąsi"),
        "mlConsentConfirmation": MessageLookupByLibrary.simpleMessage(
            "Suprantu ir noriu įjungti mašininį mokymąsi"),
        "mlConsentDescription": MessageLookupByLibrary.simpleMessage(
            "Jei įjungsite mašininį mokymąsi, „Ente“ išsitrauks tokią informaciją kaip veido geometrija iš failų, įskaitant tuos, kuriais su jumis bendrinama.\n\nTai bus daroma jūsų įrenginyje, o visa sugeneruota biometrinė informacija bus visapusiškai užšifruota."),
        "mlConsentPrivacy": MessageLookupByLibrary.simpleMessage(
            "Spustelėkite čia dėl išsamesnės informacijos apie šią funkciją mūsų privatumo politikoje"),
        "mlConsentTitle":
            MessageLookupByLibrary.simpleMessage("Įjungti mašininį mokymąsi?"),
        "mlIndexingDescription": MessageLookupByLibrary.simpleMessage(
            "Atkreipkite dėmesį, kad mašininis mokymasis padidins pralaidumą ir akumuliatoriaus naudojimą, kol bus indeksuoti visi elementai. Apsvarstykite galimybę naudoti darbalaukio programą, kad indeksavimas būtų spartesnis – visi rezultatai bus sinchronizuojami automatiškai."),
        "mobileWebDesktop": MessageLookupByLibrary.simpleMessage(
            "Mobiliuosiuose, internete ir darbalaukyje"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Vidutinė"),
        "moments": MessageLookupByLibrary.simpleMessage("Akimirkos"),
        "month": MessageLookupByLibrary.simpleMessage("mėnesis"),
        "monthly": MessageLookupByLibrary.simpleMessage("Mėnesinis"),
        "moreDetails": MessageLookupByLibrary.simpleMessage(
            "Daugiau išsamios informacijos"),
        "mostRecent": MessageLookupByLibrary.simpleMessage("Naujausią"),
        "mostRelevant": MessageLookupByLibrary.simpleMessage("Aktualiausią"),
        "moveItem": m45,
        "movedToTrash":
            MessageLookupByLibrary.simpleMessage("Perkelta į šiukšlinę"),
        "name": MessageLookupByLibrary.simpleMessage("Pavadinimą"),
        "nameTheAlbum":
            MessageLookupByLibrary.simpleMessage("Pavadinkite albumą"),
        "networkConnectionRefusedErr": MessageLookupByLibrary.simpleMessage(
            "Nepavyksta prisijungti prie „Ente“. Bandykite dar kartą po kurio laiko. Jei klaida tęsiasi, susisiekite su palaikymo komanda."),
        "networkHostLookUpErr": MessageLookupByLibrary.simpleMessage(
            "Nepavyksta prisijungti prie „Ente“. Patikrinkite tinklo nustatymus ir susisiekite su palaikymo komanda, jei klaida tęsiasi."),
        "never": MessageLookupByLibrary.simpleMessage("Niekada"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Naujas albumas"),
        "newLocation": MessageLookupByLibrary.simpleMessage("Nauja vietovė"),
        "newPerson": MessageLookupByLibrary.simpleMessage("Naujas asmuo"),
        "newToEnte":
            MessageLookupByLibrary.simpleMessage("Naujas platformoje „Ente“"),
        "newest": MessageLookupByLibrary.simpleMessage("Naujausią"),
        "next": MessageLookupByLibrary.simpleMessage("Toliau"),
        "no": MessageLookupByLibrary.simpleMessage("Ne"),
        "noDeviceFound":
            MessageLookupByLibrary.simpleMessage("Įrenginys nerastas"),
        "noDeviceLimit": MessageLookupByLibrary.simpleMessage("Jokio"),
        "noDuplicates":
            MessageLookupByLibrary.simpleMessage("✨ Dublikatų nėra"),
        "noEnteAccountExclamation":
            MessageLookupByLibrary.simpleMessage("Nėra „Ente“ paskyros!"),
        "noExifData": MessageLookupByLibrary.simpleMessage("Nėra EXIF duomenų"),
        "noFacesFound": MessageLookupByLibrary.simpleMessage("Nerasta veidų."),
        "noImagesWithLocation":
            MessageLookupByLibrary.simpleMessage("Nėra vaizdų su vietove"),
        "noInternetConnection":
            MessageLookupByLibrary.simpleMessage("Nėra interneto ryšio"),
        "noQuickLinksSelected": MessageLookupByLibrary.simpleMessage(
            "Nėra pasirinktų sparčiųjų nuorodų"),
        "noRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Neturite atkūrimo rakto?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "Dėl mūsų visapusio šifravimo protokolo pobūdžio jūsų duomenų negalima iššifruoti be slaptažodžio arba atkūrimo rakto"),
        "noResults": MessageLookupByLibrary.simpleMessage("Rezultatų nėra."),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("Rezultatų nerasta."),
        "noSuggestionsForPerson": m47,
        "noSystemLockFound":
            MessageLookupByLibrary.simpleMessage("Nerastas sistemos užraktas"),
        "notPersonLabel": m48,
        "nothingSharedWithYouYet": MessageLookupByLibrary.simpleMessage(
            "Kol kas su jumis niekuo nesibendrinama."),
        "nothingToSeeHere": MessageLookupByLibrary.simpleMessage(
            "Čia nėra nieko, ką pamatyti. 👀"),
        "notifications": MessageLookupByLibrary.simpleMessage("Pranešimai"),
        "ok": MessageLookupByLibrary.simpleMessage("Gerai"),
        "onDevice": MessageLookupByLibrary.simpleMessage("Įrenginyje"),
        "onEnte": MessageLookupByLibrary.simpleMessage(
            "Saugykloje <branding>ente</branding>"),
        "onlyFamilyAdminCanChangeCode": m49,
        "onlyThem": MessageLookupByLibrary.simpleMessage("Tik jiems"),
        "oops": MessageLookupByLibrary.simpleMessage("Ups"),
        "oopsSomethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Ups, kažkas nutiko ne taip"),
        "openAlbumInBrowser":
            MessageLookupByLibrary.simpleMessage("Atverti albumą naršyklėje"),
        "openAlbumInBrowserTitle": MessageLookupByLibrary.simpleMessage(
            "Naudokite interneto programą, kad pridėtumėte nuotraukų į šį albumą."),
        "openFile": MessageLookupByLibrary.simpleMessage("Atverti failą"),
        "optionalAsShortAsYouLike": MessageLookupByLibrary.simpleMessage(
            "Nebūtina, trumpai, kaip jums patinka..."),
        "orMergeWithExistingPerson":
            MessageLookupByLibrary.simpleMessage("Arba sujunkite su esamais"),
        "orPickAnExistingOne":
            MessageLookupByLibrary.simpleMessage("Arba pasirinkite esamą"),
        "pair": MessageLookupByLibrary.simpleMessage("Susieti"),
        "pairWithPin": MessageLookupByLibrary.simpleMessage("Susieti su PIN"),
        "pairingComplete":
            MessageLookupByLibrary.simpleMessage("Susiejimas baigtas"),
        "panorama": MessageLookupByLibrary.simpleMessage("Panorama"),
        "passKeyPendingVerification": MessageLookupByLibrary.simpleMessage(
            "Vis dar laukiama patvirtinimo"),
        "passkey": MessageLookupByLibrary.simpleMessage("Slaptaraktis"),
        "passkeyAuthTitle":
            MessageLookupByLibrary.simpleMessage("Slaptarakčio patvirtinimas"),
        "password": MessageLookupByLibrary.simpleMessage("Slaptažodis"),
        "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
            "Slaptažodis sėkmingai pakeistas"),
        "passwordLock":
            MessageLookupByLibrary.simpleMessage("Slaptažodžio užraktas"),
        "passwordStrength": m0,
        "passwordStrengthInfo": MessageLookupByLibrary.simpleMessage(
            "Slaptažodžio stiprumas apskaičiuojamas atsižvelgiant į slaptažodžio ilgį, naudotus simbolius ir į tai, ar slaptažodis patenka į 10 000 dažniausiai naudojamų slaptažodžių."),
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Šio slaptažodžio nesaugome, todėl jei jį pamiršite, <underline>negalėsime iššifruoti jūsų duomenų</underline>"),
        "paymentDetails":
            MessageLookupByLibrary.simpleMessage("Mokėjimo duomenys"),
        "paymentFailed":
            MessageLookupByLibrary.simpleMessage("Mokėjimas nepavyko"),
        "paymentFailedMessage": MessageLookupByLibrary.simpleMessage(
            "Deja, jūsų mokėjimas nepavyko. Susisiekite su palaikymo komanda ir mes jums padėsime!"),
        "paymentFailedTalkToProvider": m50,
        "pendingItems":
            MessageLookupByLibrary.simpleMessage("Laukiami elementai"),
        "pendingSync":
            MessageLookupByLibrary.simpleMessage("Laukiama sinchronizacija"),
        "people": MessageLookupByLibrary.simpleMessage("Asmenys"),
        "peopleUsingYourCode": MessageLookupByLibrary.simpleMessage(
            "Asmenys, naudojantys jūsų kodą"),
        "permanentlyDelete":
            MessageLookupByLibrary.simpleMessage("Ištrinti negrįžtamai"),
        "permanentlyDeleteFromDevice": MessageLookupByLibrary.simpleMessage(
            "Ištrinti negrįžtamai iš įrenginio?"),
        "personName": MessageLookupByLibrary.simpleMessage("Asmens vardas"),
        "photoGridSize":
            MessageLookupByLibrary.simpleMessage("Nuotraukų tinklelio dydis"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("nuotrauka"),
        "photos": MessageLookupByLibrary.simpleMessage("Nuotraukos"),
        "photosAddedByYouWillBeRemovedFromTheAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Jūsų pridėtos nuotraukos bus pašalintos iš albumo"),
        "pinAlbum": MessageLookupByLibrary.simpleMessage("Prisegti albumą"),
        "pinLock": MessageLookupByLibrary.simpleMessage("PIN užrakinimas"),
        "playOnTv": MessageLookupByLibrary.simpleMessage(
            "Paleisti albumą televizoriuje"),
        "playStoreFreeTrialValidTill": m52,
        "playstoreSubscription":
            MessageLookupByLibrary.simpleMessage("„PlayStore“ prenumerata"),
        "pleaseCheckYourInternetConnectionAndTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Patikrinkite savo interneto ryšį ir bandykite dar kartą."),
        "pleaseGrantPermissions":
            MessageLookupByLibrary.simpleMessage("Suteikite leidimus."),
        "pleaseLoginAgain":
            MessageLookupByLibrary.simpleMessage("Prisijunkite iš naujo."),
        "pleaseSelectQuickLinksToRemove": MessageLookupByLibrary.simpleMessage(
            "Pasirinkite sparčiąsias nuorodas, kad pašalintumėte"),
        "pleaseSendTheLogsTo": m54,
        "pleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("Bandykite dar kartą."),
        "pleaseVerifyTheCodeYouHaveEntered":
            MessageLookupByLibrary.simpleMessage("Patvirtinkite įvestą kodą."),
        "pleaseWait": MessageLookupByLibrary.simpleMessage("Palaukite..."),
        "pleaseWaitForSometimeBeforeRetrying":
            MessageLookupByLibrary.simpleMessage(
                "Palaukite kurį laiką prieš bandydami pakartotinai"),
        "preparingLogs":
            MessageLookupByLibrary.simpleMessage("Ruošiami žurnalai..."),
        "pressAndHoldToPlayVideo": MessageLookupByLibrary.simpleMessage(
            "Paspauskite ir palaikykite, kad paleistumėte vaizdo įrašą"),
        "pressAndHoldToPlayVideoDetailed": MessageLookupByLibrary.simpleMessage(
            "Paspauskite ir palaikykite vaizdą, kad paleistumėte vaizdo įrašą"),
        "privacy": MessageLookupByLibrary.simpleMessage("Privatumas"),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Privatumo politika"),
        "privateBackups": MessageLookupByLibrary.simpleMessage(
            "Privačios atsarginės kopijos"),
        "privateSharing":
            MessageLookupByLibrary.simpleMessage("Privatus bendrinimas"),
        "proceed": MessageLookupByLibrary.simpleMessage("Tęsti"),
        "processed": MessageLookupByLibrary.simpleMessage("Apdorota"),
        "processingImport": m55,
        "publicLinkEnabled":
            MessageLookupByLibrary.simpleMessage("Įjungta viešoji nuoroda"),
        "raiseTicket": MessageLookupByLibrary.simpleMessage("Sukurti paraišką"),
        "rateTheApp": MessageLookupByLibrary.simpleMessage("Vertinti programą"),
        "rateUs": MessageLookupByLibrary.simpleMessage("Vertinti mus"),
        "rateUsOnStore": m56,
        "recover": MessageLookupByLibrary.simpleMessage("Atkurti"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("Atkurti paskyrą"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Atkurti"),
        "recoveryAccount":
            MessageLookupByLibrary.simpleMessage("Atkurti paskyrą"),
        "recoveryInitiated":
            MessageLookupByLibrary.simpleMessage("Pradėtas atkūrimas"),
        "recoveryInitiatedDesc": m57,
        "recoveryKey": MessageLookupByLibrary.simpleMessage("Atkūrimo raktas"),
        "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Nukopijuotas atkūrimo raktas į iškarpinę"),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
            "Jei pamiršote slaptažodį, vienintelis būdas atkurti duomenis – naudoti šį raktą."),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
            "Šio rakto nesaugome, todėl išsaugokite šį 24 žodžių raktą saugioje vietoje."),
        "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
            "Puiku! Jūsų atkūrimo raktas tinkamas. Dėkojame už patvirtinimą.\n\nNepamirškite sukurti saugią atkūrimo rakto atsarginę kopiją."),
        "recoveryKeyVerified": MessageLookupByLibrary.simpleMessage(
            "Patvirtintas atkūrimo raktas"),
        "recoveryKeyVerifyReason": MessageLookupByLibrary.simpleMessage(
            "Atkūrimo raktas – vienintelis būdas atkurti nuotraukas, jei pamiršote slaptažodį. Atkūrimo raktą galite rasti Nustatymose > Paskyra.\n\nĮveskite savo atkūrimo raktą čia, kad patvirtintumėte, ar teisingai jį išsaugojote."),
        "recoveryReady": m58,
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("Atkūrimas sėkmingas."),
        "recoveryWarning": MessageLookupByLibrary.simpleMessage(
            "Patikimas kontaktas bando pasiekti jūsų paskyrą."),
        "recoveryWarningBody": m59,
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "Dabartinis įrenginys nėra pakankamai galingas, kad patvirtintų jūsų slaptažodį, bet mes galime iš naujo sugeneruoti taip, kad jis veiktų su visais įrenginiais.\n\nPrisijunkite naudojant atkūrimo raktą ir sugeneruokite iš naujo slaptažodį (jei norite, galite vėl naudoti tą patį)."),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Iš naujo sukurti slaptažodį"),
        "reddit": MessageLookupByLibrary.simpleMessage("„Reddit“"),
        "reenterPassword": MessageLookupByLibrary.simpleMessage(
            "Įveskite slaptažodį iš naujo"),
        "reenterPin":
            MessageLookupByLibrary.simpleMessage("Įveskite PIN iš naujo"),
        "referFriendsAnd2xYourPlan": MessageLookupByLibrary.simpleMessage(
            "Rekomenduokite draugams ir 2 kartus padidinkite savo planą"),
        "referralStep1": MessageLookupByLibrary.simpleMessage(
            "1. Duokite šį kodą savo draugams"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "2. Jie užsiregistruoja mokamą planą"),
        "referralStep3": m60,
        "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
            "Šiuo metu rekomendacijos yra pristabdytos"),
        "rejectRecovery":
            MessageLookupByLibrary.simpleMessage("Atmesti atkūrimą"),
        "remindToEmptyDeviceTrash": MessageLookupByLibrary.simpleMessage(
            "Taip pat ištuštinkite Neseniai ištrinti iš Nustatymai -> Saugykla, kad atlaisvintumėte vietos."),
        "remindToEmptyEnteTrash": MessageLookupByLibrary.simpleMessage(
            "Taip pat ištuštinkite šiukšlinę, kad gautumėte laisvos vietos."),
        "remoteImages":
            MessageLookupByLibrary.simpleMessage("Nuotoliniai vaizdai"),
        "remoteThumbnails":
            MessageLookupByLibrary.simpleMessage("Nuotolinės miniatiūros"),
        "remoteVideos":
            MessageLookupByLibrary.simpleMessage("Nuotoliniai vaizdo įrašai"),
        "remove": MessageLookupByLibrary.simpleMessage("Šalinti"),
        "removeDuplicates":
            MessageLookupByLibrary.simpleMessage("Šalinti dublikatus"),
        "removeFromAlbum":
            MessageLookupByLibrary.simpleMessage("Šalinti iš albumo"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("Pašalinti iš albumo?"),
        "removeFromFavorite":
            MessageLookupByLibrary.simpleMessage("Šalinti iš mėgstamų"),
        "removeInvite":
            MessageLookupByLibrary.simpleMessage("Šalinti kvietimą"),
        "removeLink": MessageLookupByLibrary.simpleMessage("Šalinti nuorodą"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Šalinti dalyvį"),
        "removeParticipantBody": m61,
        "removePersonLabel":
            MessageLookupByLibrary.simpleMessage("Šalinti asmens žymą"),
        "removePublicLink":
            MessageLookupByLibrary.simpleMessage("Šalinti viešą nuorodą"),
        "removePublicLinks":
            MessageLookupByLibrary.simpleMessage("Šalinti viešąsias nuorodas"),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
            "Kai kuriuos elementus, kuriuos šalinate, pridėjo kiti asmenys, todėl prarasite prieigą prie jų"),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Šalinti?"),
        "removeYourselfAsTrustedContact": MessageLookupByLibrary.simpleMessage(
            "Šalinti save kaip patikimą kontaktą"),
        "removingFromFavorites":
            MessageLookupByLibrary.simpleMessage("Pašalinama iš mėgstamų..."),
        "rename": MessageLookupByLibrary.simpleMessage("Pervadinti"),
        "renameFile": MessageLookupByLibrary.simpleMessage("Pervadinti failą"),
        "renewSubscription":
            MessageLookupByLibrary.simpleMessage("Atnaujinti prenumeratą"),
        "renewsOn": m62,
        "reportABug":
            MessageLookupByLibrary.simpleMessage("Pranešti apie riktą"),
        "reportBug":
            MessageLookupByLibrary.simpleMessage("Pranešti apie riktą"),
        "resendEmail":
            MessageLookupByLibrary.simpleMessage("Iš naujo siųsti el. laišką"),
        "resetPasswordTitle": MessageLookupByLibrary.simpleMessage(
            "Nustatyti slaptažodį iš naujo"),
        "resetToDefault": MessageLookupByLibrary.simpleMessage(
            "Atkurti numatytąsias reikšmes"),
        "restore": MessageLookupByLibrary.simpleMessage("Atkurti"),
        "restoreToAlbum":
            MessageLookupByLibrary.simpleMessage("Atkurti į albumą"),
        "restoringFiles":
            MessageLookupByLibrary.simpleMessage("Atkuriami failai..."),
        "retry": MessageLookupByLibrary.simpleMessage("Kartoti"),
        "reviewDeduplicateItems": MessageLookupByLibrary.simpleMessage(
            "Peržiūrėkite ir ištrinkite elementus, kurie, jūsų manymu, yra dublikatai."),
        "reviewSuggestions":
            MessageLookupByLibrary.simpleMessage("Peržiūrėti pasiūlymus"),
        "right": MessageLookupByLibrary.simpleMessage("Dešinė"),
        "rotate": MessageLookupByLibrary.simpleMessage("Sukti"),
        "safelyStored": MessageLookupByLibrary.simpleMessage("Saugiai saugoma"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Išsaugoti raktą"),
        "savePerson": MessageLookupByLibrary.simpleMessage("Išsaugoti asmenį"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Išsaugokite atkūrimo raktą, jei dar to nepadarėte"),
        "savingEdits":
            MessageLookupByLibrary.simpleMessage("Išsaugomi redagavimai..."),
        "scanCode": MessageLookupByLibrary.simpleMessage("Skenuoti kodą"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Skenuokite šį QR kodą\nsu autentifikatoriaus programa"),
        "search": MessageLookupByLibrary.simpleMessage("Ieškokite"),
        "searchByExamples": MessageLookupByLibrary.simpleMessage(
            "• Albumų pavadinimai (pvz., „Fotoaparatas“)\n• Failų tipai (pvz., „Vaizdo įrašai“, „.gif“)\n• Metai ir mėnesiai (pvz., „2022“, „sausis“)\n• Šventės (pvz., „Kalėdos“)\n• Nuotraukų aprašymai (pvz., „#džiaugsmas“)"),
        "searchCaptionEmptySection": MessageLookupByLibrary.simpleMessage(
            "Pridėkite aprašymus, pavyzdžiui, „#kelionė“, į nuotraukos informaciją, kad greičiau jas čia rastumėte."),
        "searchDiscoverEmptySection": MessageLookupByLibrary.simpleMessage(
            "Vaizdai bus rodomi čia, kai bus užbaigtas apdorojimas ir sinchronizavimas."),
        "searchHint3": MessageLookupByLibrary.simpleMessage(
            "Albumai, failų pavadinimai ir tipai"),
        "searchHint4": MessageLookupByLibrary.simpleMessage("Vietovė"),
        "searchHint5": MessageLookupByLibrary.simpleMessage(
            "Jau netrukus: veidų ir magiškos paieškos ✨"),
        "searchLocationEmptySection": MessageLookupByLibrary.simpleMessage(
            "Grupės nuotraukos, kurios padarytos tam tikru spinduliu nuo nuotraukos"),
        "searchPeopleEmptySection": MessageLookupByLibrary.simpleMessage(
            "Pakvieskite asmenis ir čia matysite visas jų bendrinamas nuotraukas."),
        "searchPersonsEmptySection": MessageLookupByLibrary.simpleMessage(
            "Asmenys bus rodomi čia, kai bus užbaigtas apdorojimas ir sinchronizavimas."),
        "searchResultCount": m63,
        "searchSectionsLengthMismatch": m64,
        "security": MessageLookupByLibrary.simpleMessage("Saugumas"),
        "seePublicAlbumLinksInApp": MessageLookupByLibrary.simpleMessage(
            "Žiūrėti viešų albumų nuorodas programoje"),
        "selectALocation":
            MessageLookupByLibrary.simpleMessage("Pasirinkite vietovę"),
        "selectALocationFirst": MessageLookupByLibrary.simpleMessage(
            "Pirmiausia pasirinkite vietovę"),
        "selectAll": MessageLookupByLibrary.simpleMessage("Pasirinkti viską"),
        "selectAllShort": MessageLookupByLibrary.simpleMessage("Viskas"),
        "selectCoverPhoto": MessageLookupByLibrary.simpleMessage(
            "Pasirinkite viršelio nuotrauką"),
        "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
            "Pasirinkite aplankus atsarginėms kopijoms kurti"),
        "selectLanguage":
            MessageLookupByLibrary.simpleMessage("Pasirinkite kalbą"),
        "selectMailApp":
            MessageLookupByLibrary.simpleMessage("Pasirinkti pašto programą"),
        "selectReason":
            MessageLookupByLibrary.simpleMessage("Pasirinkite priežastį"),
        "selectYourPlan":
            MessageLookupByLibrary.simpleMessage("Pasirinkite planą"),
        "selectedFilesAreNotOnEnte": MessageLookupByLibrary.simpleMessage(
            "Pasirinkti failai nėra platformoje „Ente“"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "Pasirinkti aplankai bus užšifruoti ir sukurtos atsarginės kopijos."),
        "selectedPhotos": m6,
        "selectedPhotosWithYours": m65,
        "send": MessageLookupByLibrary.simpleMessage("Siųsti"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("Siųsti el. laišką"),
        "sendInvite": MessageLookupByLibrary.simpleMessage("Siųsti kvietimą"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Siųsti nuorodą"),
        "serverEndpoint":
            MessageLookupByLibrary.simpleMessage("Serverio galutinis taškas"),
        "sessionExpired":
            MessageLookupByLibrary.simpleMessage("Seansas baigėsi"),
        "sessionIdMismatch":
            MessageLookupByLibrary.simpleMessage("Seanso ID nesutampa."),
        "setAPassword":
            MessageLookupByLibrary.simpleMessage("Nustatyti slaptažodį"),
        "setAs": MessageLookupByLibrary.simpleMessage("Nustatyti kaip"),
        "setCover": MessageLookupByLibrary.simpleMessage("Nustatyti viršelį"),
        "setLabel": MessageLookupByLibrary.simpleMessage("Nustatyti"),
        "setNewPassword": MessageLookupByLibrary.simpleMessage(
            "Nustatykite naują slaptažodį"),
        "setNewPin":
            MessageLookupByLibrary.simpleMessage("Nustatykite naują PIN"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Nustatyti slaptažodį"),
        "setupComplete": MessageLookupByLibrary.simpleMessage("Sąranka baigta"),
        "share": MessageLookupByLibrary.simpleMessage("Bendrinti"),
        "shareALink":
            MessageLookupByLibrary.simpleMessage("Bendrinkite nuorodą"),
        "shareAlbumHint": MessageLookupByLibrary.simpleMessage(
            "Atidarykite albumą ir palieskite bendrinimo mygtuką viršuje dešinėje, kad bendrintumėte."),
        "shareAnAlbumNow":
            MessageLookupByLibrary.simpleMessage("Bendrinti albumą dabar"),
        "shareLink": MessageLookupByLibrary.simpleMessage("Bendrinti nuorodą"),
        "shareMyVerificationID": m66,
        "shareOnlyWithThePeopleYouWant": MessageLookupByLibrary.simpleMessage(
            "Bendrinkite tik su tais asmenimis, su kuriais norite"),
        "shareTextConfirmOthersVerificationID": m7,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Atsisiųskite „Ente“, kad galėtume lengvai bendrinti originalios kokybės nuotraukas ir vaizdo įrašus.\n\nhttps://ente.io"),
        "shareTextReferralCode": m67,
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
            "Bendrinkite su ne „Ente“ naudotojais."),
        "shareWithPeopleSectionTitle": m68,
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Sukurkite bendrinamus ir bendradarbiaujamus albumus su kitais „Ente“ naudotojais, įskaitant naudotojus nemokamuose planuose."),
        "sharedByYou":
            MessageLookupByLibrary.simpleMessage("Bendrinta iš jūsų"),
        "sharedPhotoNotifications": MessageLookupByLibrary.simpleMessage(
            "Naujos bendrintos nuotraukos"),
        "sharedPhotoNotificationsExplanation": MessageLookupByLibrary.simpleMessage(
            "Gaukite pranešimus, kai kas nors prideda nuotrauką į bendrinamą albumą, kuriame dalyvaujate."),
        "sharedWithMe":
            MessageLookupByLibrary.simpleMessage("Bendrinta su manimi"),
        "sharedWithYou":
            MessageLookupByLibrary.simpleMessage("Bendrinta su jumis"),
        "sharing": MessageLookupByLibrary.simpleMessage("Bendrinima..."),
        "showMemories":
            MessageLookupByLibrary.simpleMessage("Rodyti prisiminimus"),
        "showPerson": MessageLookupByLibrary.simpleMessage("Rodyti asmenį"),
        "signOutOtherBody": MessageLookupByLibrary.simpleMessage(
            "Jei manote, kad kas nors gali žinoti jūsų slaptažodį, galite priverstinai atsijungti iš visų kitų įrenginių, naudojančių jūsų paskyrą."),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "Sutinku su <u-terms>paslaugų sąlygomis</u-terms> ir <u-policy> privatumo politika</u-policy>"),
        "singleFileDeleteFromDevice": m70,
        "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
            "Jis bus ištrintas iš visų albumų."),
        "singleFileInBothLocalAndRemote": m71,
        "singleFileInRemoteOnly": m72,
        "skip": MessageLookupByLibrary.simpleMessage("Praleisti"),
        "social": MessageLookupByLibrary.simpleMessage("Socialinės"),
        "someOfTheFilesYouAreTryingToDeleteAre":
            MessageLookupByLibrary.simpleMessage(
                "Kai kurie failai, kuriuos bandote ištrinti, yra pasiekiami tik jūsų įrenginyje ir jų negalima atkurti, jei jie buvo ištrinti."),
        "someoneSharingAlbumsWithYouShouldSeeTheSameId":
            MessageLookupByLibrary.simpleMessage(
                "Asmuo, kuris bendrina albumus su jumis, savo įrenginyje turėtų matyti tą patį ID."),
        "somethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Kažkas nutiko ne taip"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Kažkas nutiko ne taip. Bandykite dar kartą."),
        "sorry": MessageLookupByLibrary.simpleMessage("Atsiprašome"),
        "sorryCouldNotAddToFavorites": MessageLookupByLibrary.simpleMessage(
            "Atsiprašome, nepavyko pridėti prie mėgstamų."),
        "sorryCouldNotRemoveFromFavorites":
            MessageLookupByLibrary.simpleMessage(
                "Atsiprašome, nepavyko pašalinti iš mėgstamų."),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "Atsiprašome, šiame įrenginyje nepavyko sugeneruoti saugių raktų.\n\nRegistruokitės iš kito įrenginio."),
        "sort": MessageLookupByLibrary.simpleMessage("Rikiuoti"),
        "sortAlbumsBy": MessageLookupByLibrary.simpleMessage("Rikiuoti pagal"),
        "sortNewestFirst":
            MessageLookupByLibrary.simpleMessage("Naujausią pirmiausiai"),
        "sortOldestFirst":
            MessageLookupByLibrary.simpleMessage("Seniausią pirmiausiai"),
        "sparkleSuccess": MessageLookupByLibrary.simpleMessage("✨ Sėkmė"),
        "startAccountRecoveryTitle":
            MessageLookupByLibrary.simpleMessage("Pradėti atkūrimą"),
        "startBackup": MessageLookupByLibrary.simpleMessage(
            "Pradėti kurti atsarginę kopiją"),
        "status": MessageLookupByLibrary.simpleMessage("Būsena"),
        "stopCastingBody": MessageLookupByLibrary.simpleMessage(
            "Ar norite sustabdyti perdavimą?"),
        "stopCastingTitle":
            MessageLookupByLibrary.simpleMessage("Stabdyti perdavimą"),
        "storage": MessageLookupByLibrary.simpleMessage("Saugykla"),
        "storageBreakupYou": MessageLookupByLibrary.simpleMessage("Jūs"),
        "storageInGB": m1,
        "storageLimitExceeded":
            MessageLookupByLibrary.simpleMessage("Viršyta saugyklos riba."),
        "strongStrength": MessageLookupByLibrary.simpleMessage("Stipri"),
        "subAlreadyLinkedErrMessage": m74,
        "subscribe": MessageLookupByLibrary.simpleMessage("Prenumeruoti"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "Kad įjungtumėte bendrinimą, reikia aktyvios mokamos prenumeratos."),
        "subscription": MessageLookupByLibrary.simpleMessage("Prenumerata"),
        "success": MessageLookupByLibrary.simpleMessage("Sėkmė"),
        "successfullyArchived":
            MessageLookupByLibrary.simpleMessage("Sėkmingai suarchyvuota"),
        "successfullyUnarchived":
            MessageLookupByLibrary.simpleMessage("Sėkmingai išarchyvuota"),
        "suggestFeatures":
            MessageLookupByLibrary.simpleMessage("Siūlyti funkcijas"),
        "support": MessageLookupByLibrary.simpleMessage("Palaikymas"),
        "syncProgress": m76,
        "syncStopped": MessageLookupByLibrary.simpleMessage(
            "Sinchronizavimas sustabdytas"),
        "syncing": MessageLookupByLibrary.simpleMessage("Sinchronizuojama..."),
        "systemTheme": MessageLookupByLibrary.simpleMessage("Sistemos"),
        "tapToCopy": MessageLookupByLibrary.simpleMessage(
            "palieskite, kad nukopijuotumėte"),
        "tapToEnterCode": MessageLookupByLibrary.simpleMessage(
            "Palieskite, kad įvestumėte kodą"),
        "tapToUnlock": MessageLookupByLibrary.simpleMessage(
            "Palieskite, kad atrakintumėte"),
        "tapToUpload":
            MessageLookupByLibrary.simpleMessage("Palieskite, kad įkeltumėte"),
        "tapToUploadIsIgnoredDue": m77,
        "tempErrorContactSupportIfPersists": MessageLookupByLibrary.simpleMessage(
            "Atrodo, kad kažkas nutiko ne taip. Bandykite dar kartą po kurio laiko. Jei klaida tęsiasi, susisiekite su mūsų palaikymo komanda."),
        "terminate": MessageLookupByLibrary.simpleMessage("Baigti"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Baigti seansą?"),
        "terms": MessageLookupByLibrary.simpleMessage("Sąlygos"),
        "termsOfServicesTitle": MessageLookupByLibrary.simpleMessage("Sąlygos"),
        "thankYou": MessageLookupByLibrary.simpleMessage("Dėkojame"),
        "theDownloadCouldNotBeCompleted": MessageLookupByLibrary.simpleMessage(
            "Atsisiuntimas negalėjo būti baigtas."),
        "theLinkYouAreTryingToAccessHasExpired":
            MessageLookupByLibrary.simpleMessage(
                "Nuoroda, kurią bandote pasiekti, nebegalioja."),
        "theRecoveryKeyYouEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "Įvestas atkūrimo raktas yra neteisingas."),
        "theme": MessageLookupByLibrary.simpleMessage("Tema"),
        "theyAlsoGetXGb": m8,
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "Tai gali būti naudojama paskyrai atkurti, jei prarandate dvigubo tapatybės nustatymą"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Šis įrenginys"),
        "thisEmailIsAlreadyInUse": MessageLookupByLibrary.simpleMessage(
            "Šis el. paštas jau naudojamas."),
        "thisImageHasNoExifData": MessageLookupByLibrary.simpleMessage(
            "Šis vaizdas neturi Exif duomenų"),
        "thisIsPersonVerificationId": m78,
        "thisIsYourVerificationId":
            MessageLookupByLibrary.simpleMessage("Tai – jūsų patvirtinimo ID"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Tai jus atjungs nuo toliau nurodyto įrenginio:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Tai jus atjungs nuo šio įrenginio."),
        "thisWillRemovePublicLinksOfAllSelectedQuickLinks":
            MessageLookupByLibrary.simpleMessage(
                "Tai pašalins visų pasirinktų sparčiųjų nuorodų viešąsias nuorodas."),
        "toEnableAppLockPleaseSetupDevicePasscodeOrScreen":
            MessageLookupByLibrary.simpleMessage(
                "Kad įjungtumėte programos užraktą, sistemos nustatymuose nustatykite įrenginio prieigos kodą arba ekrano užraktą."),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "Kad iš naujo nustatytumėte slaptažodį, pirmiausia patvirtinkite savo el. paštą."),
        "todaysLogs":
            MessageLookupByLibrary.simpleMessage("Šiandienos žurnalai"),
        "tooManyIncorrectAttempts": MessageLookupByLibrary.simpleMessage(
            "Per daug neteisingų bandymų."),
        "total": MessageLookupByLibrary.simpleMessage("iš viso"),
        "trash": MessageLookupByLibrary.simpleMessage("Šiukšlinė"),
        "trashDaysLeft": m79,
        "trim": MessageLookupByLibrary.simpleMessage("Trumpinti"),
        "trustedContacts":
            MessageLookupByLibrary.simpleMessage("Patikimi kontaktai"),
        "trustedInviteBody": m80,
        "tryAgain": MessageLookupByLibrary.simpleMessage("Bandyti dar kartą"),
        "twitter": MessageLookupByLibrary.simpleMessage("„Twitter“"),
        "twoMonthsFreeOnYearlyPlans": MessageLookupByLibrary.simpleMessage(
            "2 mėnesiai nemokamai metiniuose planuose"),
        "twofactor": MessageLookupByLibrary.simpleMessage(
            "Dvigubas tapatybės nustatymas"),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage(
                "Dvigubas tapatybės nustatymas"),
        "twofactorSetup": MessageLookupByLibrary.simpleMessage(
            "Dvigubo tapatybės nustatymo sąranka"),
        "typeOfGallerGallerytypeIsNotSupportedForRename": m81,
        "unarchive": MessageLookupByLibrary.simpleMessage("Išarchyvuoti"),
        "unarchiveAlbum":
            MessageLookupByLibrary.simpleMessage("Išarchyvuoti albumą"),
        "unarchiving":
            MessageLookupByLibrary.simpleMessage("Išarchyvuojama..."),
        "unavailableReferralCode": MessageLookupByLibrary.simpleMessage(
            "Atsiprašome, šis kodas nepasiekiamas."),
        "uncategorized":
            MessageLookupByLibrary.simpleMessage("Nekategorizuoti"),
        "unlock": MessageLookupByLibrary.simpleMessage("Atrakinti"),
        "unpinAlbum": MessageLookupByLibrary.simpleMessage("Atsegti albumą"),
        "unselectAll": MessageLookupByLibrary.simpleMessage("Nesirinkti visų"),
        "update": MessageLookupByLibrary.simpleMessage("Atnaujinti"),
        "updateAvailable":
            MessageLookupByLibrary.simpleMessage("Yra naujinimas"),
        "updatingFolderSelection": MessageLookupByLibrary.simpleMessage(
            "Atnaujinamas aplankų pasirinkimas..."),
        "upgrade": MessageLookupByLibrary.simpleMessage("Keisti planą"),
        "uploadIsIgnoredDueToIgnorereason": m82,
        "upto50OffUntil4thDec": MessageLookupByLibrary.simpleMessage(
            "Iki 50% nuolaida, gruodžio 4 d."),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "Naudojama saugykla ribojama pagal jūsų dabartinį planą. Perteklinė gauta saugykla automatiškai taps tinkama naudoti, kai pakeisite planą."),
        "useAsCover":
            MessageLookupByLibrary.simpleMessage("Naudoti kaip viršelį"),
        "useDifferentPlayerInfo": MessageLookupByLibrary.simpleMessage(
            "Turite problemų paleidžiant šį vaizdo įrašą? Ilgai paspauskite čia, kad išbandytumėte kitą leistuvę."),
        "usePublicLinksForPeopleNotOnEnte": MessageLookupByLibrary.simpleMessage(
            "Naudokite viešas nuorodas asmenimis, kurie nėra sistemoje „Ente“"),
        "useRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Naudoti atkūrimo raktą"),
        "usedSpace": MessageLookupByLibrary.simpleMessage("Naudojama vieta"),
        "validTill": m84,
        "verificationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Patvirtinimas nepavyko. Bandykite dar kartą."),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("Patvirtinimo ID"),
        "verify": MessageLookupByLibrary.simpleMessage("Patvirtinti"),
        "verifyEmail":
            MessageLookupByLibrary.simpleMessage("Patvirtinti el. paštą"),
        "verifyEmailID": m85,
        "verifyIDLabel": MessageLookupByLibrary.simpleMessage("Patvirtinti"),
        "verifyPasskey":
            MessageLookupByLibrary.simpleMessage("Patvirtinti slaptaraktį"),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Patvirtinkite slaptažodį"),
        "verifying": MessageLookupByLibrary.simpleMessage("Patvirtinama..."),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Patvirtinima atkūrimo raktą..."),
        "videoInfo":
            MessageLookupByLibrary.simpleMessage("Vaizdo įrašo informacija"),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("vaizdo įrašas"),
        "videos": MessageLookupByLibrary.simpleMessage("Vaizdo įrašai"),
        "viewAddOnButton":
            MessageLookupByLibrary.simpleMessage("Peržiūrėti priedus"),
        "viewAll": MessageLookupByLibrary.simpleMessage("Peržiūrėti viską"),
        "viewLogs": MessageLookupByLibrary.simpleMessage("Peržiūrėti žurnalus"),
        "viewRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Peržiūrėti atkūrimo raktą"),
        "viewer": MessageLookupByLibrary.simpleMessage("Žiūrėtojas"),
        "viewersSuccessfullyAdded": m86,
        "visitWebToManage": MessageLookupByLibrary.simpleMessage(
            "Aplankykite web.ente.io, kad tvarkytumėte savo prenumeratą"),
        "waitingForVerification":
            MessageLookupByLibrary.simpleMessage("Laukiama patvirtinimo..."),
        "waitingForWifi":
            MessageLookupByLibrary.simpleMessage("Laukiama „WiFi“..."),
        "warning": MessageLookupByLibrary.simpleMessage("Įspėjimas"),
        "weAreOpenSource":
            MessageLookupByLibrary.simpleMessage("Esame atviro kodo!"),
        "weDontSupportEditingPhotosAndAlbumsThatYouDont":
            MessageLookupByLibrary.simpleMessage(
                "Nepalaikome nuotraukų ir albumų redagavimo, kurių dar neturite."),
        "weHaveSendEmailTo": m2,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Silpna"),
        "welcomeBack": MessageLookupByLibrary.simpleMessage("Sveiki sugrįžę!"),
        "whatsNew": MessageLookupByLibrary.simpleMessage("Kas naujo"),
        "whyAddTrustContact": MessageLookupByLibrary.simpleMessage(
            "Patikimas kontaktas gali padėti atkurti jūsų duomenis."),
        "yearShort": MessageLookupByLibrary.simpleMessage("m."),
        "yearly": MessageLookupByLibrary.simpleMessage("Metinis"),
        "yearsAgo": m87,
        "yes": MessageLookupByLibrary.simpleMessage("Taip"),
        "yesCancel": MessageLookupByLibrary.simpleMessage("Taip, atsisakyti"),
        "yesConvertToViewer":
            MessageLookupByLibrary.simpleMessage("Taip, keisti į žiūrėtoją"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("Taip, ištrinti"),
        "yesLogout": MessageLookupByLibrary.simpleMessage("Taip, atsijungti"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("Taip, šalinti"),
        "yesResetPerson": MessageLookupByLibrary.simpleMessage(
            "Taip, nustatyti asmenį iš naujo"),
        "you": MessageLookupByLibrary.simpleMessage("Jūs"),
        "youAreOnTheLatestVersion":
            MessageLookupByLibrary.simpleMessage("Esate naujausioje versijoje"),
        "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "* Galite daugiausiai padvigubinti savo saugyklą."),
        "youCannotDowngradeToThisPlan": MessageLookupByLibrary.simpleMessage(
            "Negalite pakeisti į šį planą"),
        "youCannotShareWithYourself": MessageLookupByLibrary.simpleMessage(
            "Negalite bendrinti su savimi."),
        "youDontHaveAnyArchivedItems": MessageLookupByLibrary.simpleMessage(
            "Neturite jokių archyvuotų elementų."),
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("Jūsų paskyra ištrinta"),
        "yourMap": MessageLookupByLibrary.simpleMessage("Jūsų žemėlapis"),
        "yourStorageDetailsCouldNotBeFetched":
            MessageLookupByLibrary.simpleMessage(
                "Nepavyko gauti jūsų saugyklos duomenų."),
        "yourSubscriptionHasExpired":
            MessageLookupByLibrary.simpleMessage("Jūsų prenumerata baigėsi."),
        "yourVerificationCodeHasExpired": MessageLookupByLibrary.simpleMessage(
            "Jūsų patvirtinimo kodas nebegaliojantis."),
        "youveNoDuplicateFilesThatCanBeCleared":
            MessageLookupByLibrary.simpleMessage(
                "Neturite dubliuotų failų, kuriuos būtų galima išvalyti.")
      };
}
