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

  static String m6(count) =>
      "${Intl.plural(count, one: 'Pridėti bendradarbį', few: 'Pridėti bendradarbius', many: 'Pridėti bendradarbio', other: 'Pridėti bendradarbių')}";

  static String m9(count) =>
      "${Intl.plural(count, one: 'Pridėti žiūrėtoją', few: 'Pridėti žiūrėtojus', many: 'Pridėti žiūrėtojo', other: 'Pridėti žiūrėtojų')}";

  static String m13(versionValue) => "Versija: ${versionValue}";

  static String m15(paymentProvider) =>
      "Pirmiausia atsisakykite esamos prenumeratos iš ${paymentProvider}";

  static String m16(user) =>
      "${user} negalės pridėti daugiau nuotraukų į šį albumą\n\nJie vis tiek galės pašalinti esamas pridėtas nuotraukas";

  static String m21(endpoint) => "Prijungta prie ${endpoint}";

  static String m25(supportEmail) =>
      "Iš savo registruoto el. pašto adreso atsiųskite el. laišką adresu ${supportEmail}";

  static String m27(count, formattedSize) =>
      "${count} failai (-ų), kiekvienas ${formattedSize}";

  static String m29(email) =>
      "${email} neturi „Ente“ paskyros.\n\nSiųskite jiems kvietimą bendrinti nuotraukas.";

  static String m30(text) => "Rastos papildomos nuotraukos, skirtos ${text}";

  static String m34(endDate) =>
      "Nemokamas bandomasis laikotarpis galioja iki ${endDate}";

  static String m36(sizeInMBorGB) => "Atlaisvinti ${sizeInMBorGB}";

  static String m38(currentlyProcessing, totalCount) =>
      "Apdorojama ${currentlyProcessing} / ${totalCount}";

  static String m41(count) =>
      "${Intl.plural(count, one: 'Perkelti elementą', few: 'Perkelti elementus', many: 'Perkelti elemento', other: 'Perkelti elementų')}";

  static String m44(name) => "Ne ${name}?";

  static String m0(passwordStrengthValue) =>
      "Slaptažodžio stiprumas: ${passwordStrengthValue}";

  static String m46(providerName) =>
      "Kreipkitės į ${providerName} palaikymo komandą, jei jums buvo nuskaičiuota.";

  static String m50(folderName) => "Apdorojama ${folderName}...";

  static String m51(storeName) => "Vertinti mus parduotuvėje „${storeName}“";

  static String m53(userEmail) =>
      "${userEmail} bus pašalintas iš šio bendrinamo albumo\n\nVisos jų pridėtos nuotraukos taip pat bus pašalintos iš albumo";

  static String m55(count) =>
      "${Intl.plural(count, one: 'Rastas ${count} rezultatas', few: 'Rasti ${count} rezultatai', many: 'Rasta ${count} rezultato', other: 'Rasta ${count} rezultatų')}";

  static String m4(count) => "${count} pasirinkta";

  static String m57(count, yourCount) =>
      "${count} pasirinkta (${yourCount} jūsų)";

  static String m58(verificationID) =>
      "Štai mano patvirtinimo ID: ${verificationID}, skirta ente.io.";

  static String m5(verificationID) =>
      "Ei, ar galite patvirtinti, kad tai yra jūsų ente.io patvirtinimo ID: ${verificationID}";

  static String m63(fileType) =>
      "Šis ${fileType} yra ir saugykloje „Ente“ bei įrenginyje.";

  static String m64(fileType) => "Šis ${fileType} bus ištrintas iš „Ente“.";

  static String m1(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m66(id) =>
      "Jūsų ${id} jau susietas su kita „Ente“ paskyra.\nJei norite naudoti savo ${id} su šia paskyra, susisiekite su mūsų palaikymo komanda.";

  static String m68(completed, total) =>
      "${completed} / ${total} išsaugomi prisiminimai";

  static String m69(ignoreReason) =>
      "Palieskite, kad įkeltumėte. Įkėlimas šiuo metu ignoruojamas dėl ${ignoreReason}.";

  static String m71(email) => "Tai – ${email} patvirtinimo ID";

  static String m73(galleryType) =>
      "Galerijos tipas ${galleryType} nepalaikomas pervadinimui.";

  static String m74(ignoreReason) =>
      "Įkėlimas ignoruojamas dėl ${ignoreReason}.";

  static String m76(endDate) => "Galioja iki ${endDate}";

  static String m77(email) => "Patvirtinti ${email}";

  static String m2(email) => "Išsiuntėme laišką adresu <green>${email}</green>";

  static String m79(count) =>
      "${Intl.plural(count, one: 'prieš ${count} metus', few: 'prieš ${count} metus', many: 'prieš ${count} metų', other: 'prieš ${count} metų')}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "about": MessageLookupByLibrary.simpleMessage("Apie"),
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
        "addCollaborators": m6,
        "addFiles": MessageLookupByLibrary.simpleMessage("Pridėti failus"),
        "addLocation": MessageLookupByLibrary.simpleMessage("Pridėti vietovę"),
        "addLocationButton": MessageLookupByLibrary.simpleMessage("Pridėti"),
        "addMore": MessageLookupByLibrary.simpleMessage("Pridėti daugiau"),
        "addName": MessageLookupByLibrary.simpleMessage("Pridėti vardą"),
        "addNameOrMerge":
            MessageLookupByLibrary.simpleMessage("Pridėti vardą arba sujungti"),
        "addNew": MessageLookupByLibrary.simpleMessage("Pridėti naują"),
        "addNewPerson":
            MessageLookupByLibrary.simpleMessage("Pridėti naują asmenį"),
        "addToAlbum": MessageLookupByLibrary.simpleMessage("Pridėti į albumą"),
        "addToEnte": MessageLookupByLibrary.simpleMessage("Pridėti į „Ente“"),
        "addViewer": MessageLookupByLibrary.simpleMessage("Pridėti žiūrėtoją"),
        "addViewers": m9,
        "addedAs": MessageLookupByLibrary.simpleMessage("Pridėta kaip"),
        "advancedSettings":
            MessageLookupByLibrary.simpleMessage("Išplėstiniai"),
        "after1Day": MessageLookupByLibrary.simpleMessage("Po 1 dienos"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("Po 1 valandos"),
        "after1Month": MessageLookupByLibrary.simpleMessage("Po 1 mėnesio"),
        "after1Week": MessageLookupByLibrary.simpleMessage("Po 1 savaitės"),
        "after1Year": MessageLookupByLibrary.simpleMessage("Po 1 metų"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Savininkas"),
        "albumUpdated":
            MessageLookupByLibrary.simpleMessage("Atnaujintas albumas"),
        "albums": MessageLookupByLibrary.simpleMessage("Albumai"),
        "allPersonGroupingWillReset": MessageLookupByLibrary.simpleMessage(
            "Visi šio asmens grupavimai bus iš naujo nustatyti, o jūs neteksite visų šiam asmeniui pateiktų pasiūlymų"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Leiskite nuorodą turintiems asmenims taip pat pridėti nuotraukų į bendrinamą albumą."),
        "allowAddingPhotos":
            MessageLookupByLibrary.simpleMessage("Leisti pridėti nuotraukų"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("Leisti atsisiuntimus"),
        "allowPeopleToAddPhotos": MessageLookupByLibrary.simpleMessage(
            "Leiskite asmenims pridėti nuotraukų"),
        "androidBiometricHint":
            MessageLookupByLibrary.simpleMessage("Patvirtinkite tapatybę"),
        "androidCancelButton": MessageLookupByLibrary.simpleMessage("Atšaukti"),
        "androidIosWebDesktop": MessageLookupByLibrary.simpleMessage(
            "„Android“, „iOS“, internete ir darbalaukyje"),
        "androidSignInTitle": MessageLookupByLibrary.simpleMessage(
            "Privalomas tapatybės nustatymas"),
        "appLock": MessageLookupByLibrary.simpleMessage("Programos užraktas"),
        "appLockDescriptions": MessageLookupByLibrary.simpleMessage(
            "Pasirinkite tarp numatytojo įrenginio užrakinimo ekrano ir pasirinktinio užrakinimo ekrano su PIN kodu arba slaptažodžiu."),
        "appVersion": m13,
        "appleId": MessageLookupByLibrary.simpleMessage("„Apple ID“"),
        "apply": MessageLookupByLibrary.simpleMessage("Taikyti"),
        "applyCodeTitle": MessageLookupByLibrary.simpleMessage("Taikyti kodą"),
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
        "authToViewPasskey": MessageLookupByLibrary.simpleMessage(
            "Nustatykite tapatybę, kad peržiūrėtumėte savo slaptaraktą"),
        "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
            "Nustatykite tapatybę, kad peržiūrėtumėte paslėptus failus"),
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
        "birthday": MessageLookupByLibrary.simpleMessage("Gimtadienis"),
        "blog": MessageLookupByLibrary.simpleMessage("Tinklaraštis"),
        "cachedData":
            MessageLookupByLibrary.simpleMessage("Podėliuoti duomenis"),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "Galima pašalinti tik jums priklausančius failus"),
        "cancel": MessageLookupByLibrary.simpleMessage("Atšaukti"),
        "cancelOtherSubscription": m15,
        "cancelSubscription":
            MessageLookupByLibrary.simpleMessage("Atsisakyti prenumeratos"),
        "cannotAddMorePhotosAfterBecomingViewer": m16,
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
        "changePassword":
            MessageLookupByLibrary.simpleMessage("Keisti slaptažodį"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Keisti slaptažodį"),
        "changePermissions":
            MessageLookupByLibrary.simpleMessage("Keisti leidimus?"),
        "checkForUpdates": MessageLookupByLibrary.simpleMessage(
            "Tikrinti, ar yra atnaujinimų"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Patikrinkite savo gautieją (ir šlamštą), kad užbaigtumėte patvirtinimą"),
        "checkStatus": MessageLookupByLibrary.simpleMessage("Tikrinti būseną"),
        "checking": MessageLookupByLibrary.simpleMessage("Tikrinama..."),
        "checkingModels":
            MessageLookupByLibrary.simpleMessage("Tikrinami modeliai..."),
        "cleanUncategorized":
            MessageLookupByLibrary.simpleMessage("Valyti nekategorizuotus"),
        "cleanUncategorizedDescription": MessageLookupByLibrary.simpleMessage(
            "Pašalinkite iš nekategorizuotus visus failus, esančius kituose albumuose"),
        "clearCaches": MessageLookupByLibrary.simpleMessage("Valyti podėlius"),
        "close": MessageLookupByLibrary.simpleMessage("Uždaryti"),
        "clusteringProgress":
            MessageLookupByLibrary.simpleMessage("Sankaupos vykdymas"),
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("Pritaikytas kodas"),
        "codeChangeLimitReached": MessageLookupByLibrary.simpleMessage(
            "Atsiprašome, pasiekėte kodo pakeitimų ribą."),
        "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Nukopijuotas kodas į iškarpinę"),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Sukurkite nuorodą, kad asmenys galėtų pridėti ir peržiūrėti nuotraukas bendrinamame albume, nereikalaujant „Ente“ programos ar paskyros. Puikiai tinka įvykių nuotraukoms rinkti."),
        "collaborator": MessageLookupByLibrary.simpleMessage("Bendradarbis"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Bendradarbiai gali pridėti nuotraukų ir vaizdo įrašų į bendrintą albumą."),
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
        "confirmAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Patvirtinti paskyros ištrynimą"),
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
        "copyLink": MessageLookupByLibrary.simpleMessage("Kopijuoti nuorodą"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Nukopijuokite ir įklijuokite šį kodą\nį autentifikatoriaus programą"),
        "couldNotFreeUpSpace": MessageLookupByLibrary.simpleMessage(
            "Nepavyko atlaisvinti vietos."),
        "create": MessageLookupByLibrary.simpleMessage("Kurti"),
        "createAccount": MessageLookupByLibrary.simpleMessage("Kurti paskyrą"),
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
        "crop": MessageLookupByLibrary.simpleMessage("Apkirpti"),
        "currentUsageIs":
            MessageLookupByLibrary.simpleMessage("Dabartinis naudojimas – "),
        "custom": MessageLookupByLibrary.simpleMessage("Pasirinktinis"),
        "customEndpoint": m21,
        "darkTheme": MessageLookupByLibrary.simpleMessage("Tamsi"),
        "dayToday": MessageLookupByLibrary.simpleMessage("Šiandien"),
        "dayYesterday": MessageLookupByLibrary.simpleMessage("Vakar"),
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
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
            "Ši paskyra susieta su kitomis „Ente“ programomis, jei jas naudojate. Jūsų įkelti duomenys per visas „Ente“ programas bus planuojama ištrinti, o jūsų paskyra bus ištrinta negrįžtamai."),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "Iš savo registruoto el. pašto adreso siųskite el. laišką adresu <warning>account-deletion@ente.io</warning>."),
        "deleteFromBoth":
            MessageLookupByLibrary.simpleMessage("Ištrinti iš abiejų"),
        "deleteFromDevice":
            MessageLookupByLibrary.simpleMessage("Ištrinti iš įrenginio"),
        "deleteFromEnte":
            MessageLookupByLibrary.simpleMessage("Ištrinti iš „Ente“"),
        "deleteLocation":
            MessageLookupByLibrary.simpleMessage("Ištrinti vietovę"),
        "deletePhotos":
            MessageLookupByLibrary.simpleMessage("Ištrinti nuotraukas"),
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
        "descriptions": MessageLookupByLibrary.simpleMessage("Aprašymai"),
        "designedToOutlive":
            MessageLookupByLibrary.simpleMessage("Sukurta išgyventi"),
        "developerSettings":
            MessageLookupByLibrary.simpleMessage("Kūrėjo nustatymai"),
        "developerSettingsWarning": MessageLookupByLibrary.simpleMessage(
            "Ar tikrai norite modifikuoti kūrėjo nustatymus?"),
        "deviceCodeHint": MessageLookupByLibrary.simpleMessage("Įveskite kodą"),
        "deviceLock":
            MessageLookupByLibrary.simpleMessage("Įrenginio užraktas"),
        "deviceNotFound":
            MessageLookupByLibrary.simpleMessage("Įrenginys nerastas"),
        "didYouKnow": MessageLookupByLibrary.simpleMessage("Ar žinojote?"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Žiūrėtojai vis tiek gali daryti ekrano kopijas arba išsaugoti nuotraukų kopijas naudojant išorinius įrankius"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Atkreipkite dėmesį"),
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
        "download": MessageLookupByLibrary.simpleMessage("Atsisiųsti"),
        "downloadFailed":
            MessageLookupByLibrary.simpleMessage("Atsisiuntimas nepavyko."),
        "dropSupportEmail": m25,
        "duplicateItemsGroup": m27,
        "edit": MessageLookupByLibrary.simpleMessage("Redaguoti"),
        "editLocation":
            MessageLookupByLibrary.simpleMessage("Redaguoti vietovę"),
        "editLocationTagTitle":
            MessageLookupByLibrary.simpleMessage("Redaguoti vietovę"),
        "editPerson": MessageLookupByLibrary.simpleMessage("Redaguoti asmenį"),
        "editsToLocationWillOnlyBeSeenWithinEnte":
            MessageLookupByLibrary.simpleMessage(
                "Vietovės pakeitimai bus matomi tik per „Ente“"),
        "email": MessageLookupByLibrary.simpleMessage("El. paštas"),
        "emailNoEnteAccount": m29,
        "emailVerificationToggle":
            MessageLookupByLibrary.simpleMessage("El. pašto patvirtinimas"),
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
        "enterAlbumName":
            MessageLookupByLibrary.simpleMessage("Įveskite albumo pavadinimą"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Įvesti kodą"),
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
        "exportYourData":
            MessageLookupByLibrary.simpleMessage("Eksportuoti duomenis"),
        "extraPhotosFound": MessageLookupByLibrary.simpleMessage(
            "Rastos papildomos nuotraukos"),
        "extraPhotosFoundFor": m30,
        "faceRecognition":
            MessageLookupByLibrary.simpleMessage("Veido atpažinimas"),
        "faces": MessageLookupByLibrary.simpleMessage("Veidai"),
        "failedToCancel":
            MessageLookupByLibrary.simpleMessage("Nepavyko atsisakyti"),
        "failedToFetchActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Nepavyko gauti aktyvių seansų."),
        "failedToPlayVideo": MessageLookupByLibrary.simpleMessage(
            "Nepavyko paleisti vaizdo įrašą. "),
        "failedToRefreshStripeSubscription":
            MessageLookupByLibrary.simpleMessage(
                "Nepavyko atnaujinti prenumeratos."),
        "failedToVerifyPaymentStatus": MessageLookupByLibrary.simpleMessage(
            "Nepavyko patvirtinti mokėjimo būsenos"),
        "faq": MessageLookupByLibrary.simpleMessage("DUK"),
        "faqs": MessageLookupByLibrary.simpleMessage("DUK"),
        "feedback": MessageLookupByLibrary.simpleMessage("Atsiliepimai"),
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
        "freeTrial": MessageLookupByLibrary.simpleMessage(
            "Nemokamas bandomasis laikotarpis"),
        "freeTrialValidTill": m34,
        "freeUpAmount": m36,
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Generuojami šifravimo raktai..."),
        "genericProgress": m38,
        "goToSettings":
            MessageLookupByLibrary.simpleMessage("Eiti į nustatymus"),
        "googlePlayId":
            MessageLookupByLibrary.simpleMessage("„Google Play“ ID"),
        "grantPermission":
            MessageLookupByLibrary.simpleMessage("Suteikti leidimą"),
        "guestView": MessageLookupByLibrary.simpleMessage("Svečio peržiūra"),
        "guestViewEnablePreSteps": MessageLookupByLibrary.simpleMessage(
            "Kad įjungtumėte svečio peržiūrą, sistemos nustatymuose nustatykite įrenginio prieigos kodą arba ekrano užraktą."),
        "hidden": MessageLookupByLibrary.simpleMessage("Paslėpti"),
        "hide": MessageLookupByLibrary.simpleMessage("Slėpti"),
        "hideContent": MessageLookupByLibrary.simpleMessage("Slėpti turinį"),
        "hideContentDescriptionAndroid": MessageLookupByLibrary.simpleMessage(
            "Paslepia programų turinį programų perjungiklyje ir išjungia ekrano kopijas"),
        "hideContentDescriptionIos": MessageLookupByLibrary.simpleMessage(
            "Paslepia programos turinį programos perjungiklyje"),
        "howItWorks": MessageLookupByLibrary.simpleMessage("Kaip tai veikia"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "Paprašykite jų ilgai paspausti savo el. pašto adresą nustatymų ekrane ir patvirtinkite, kad abiejų įrenginių ID sutampa."),
        "iOSGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "Biometrinis tapatybės nustatymas jūsų įrenginyje nenustatytas. Telefone įjunkite „Touch ID“ arba „Face ID“."),
        "iOSOkButton": MessageLookupByLibrary.simpleMessage("Gerai"),
        "imageNotAnalyzed":
            MessageLookupByLibrary.simpleMessage("Vaizdas neanalizuotas."),
        "immediately": MessageLookupByLibrary.simpleMessage("Iš karto"),
        "importing": MessageLookupByLibrary.simpleMessage("Importuojama...."),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Neteisingas slaptažodis"),
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
        "itemsShowTheNumberOfDaysRemainingBeforePermanentDeletion":
            MessageLookupByLibrary.simpleMessage(
                "Elementai rodo likusių dienų skaičių iki visiško ištrynimo."),
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "Pasirinkti elementai bus pašalinti iš šio albumo"),
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
        "left": MessageLookupByLibrary.simpleMessage("Kairė"),
        "light": MessageLookupByLibrary.simpleMessage("Šviesi"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("Šviesi"),
        "linkDeviceLimit":
            MessageLookupByLibrary.simpleMessage("Įrenginių riba"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Įjungta"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Nebegalioja"),
        "linkExpiry":
            MessageLookupByLibrary.simpleMessage("Nuorodos galiojimo laikas"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Niekada"),
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
        "loginSessionExpired":
            MessageLookupByLibrary.simpleMessage("Seansas baigėsi"),
        "loginSessionExpiredDetails": MessageLookupByLibrary.simpleMessage(
            "Jūsų seansas baigėsi. Prisijunkite iš naujo."),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "Spustelėjus Prisijungti sutinku su <u-terms>paslaugų sąlygomis</u-terms> ir <u-policy> privatumo politika</u-policy>"),
        "logout": MessageLookupByLibrary.simpleMessage("Atsijungti"),
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
        "mobileWebDesktop": MessageLookupByLibrary.simpleMessage(
            "Mobiliuosiuose, internete ir darbalaukyje"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Vidutinė"),
        "moments": MessageLookupByLibrary.simpleMessage("Akimirkos"),
        "monthly": MessageLookupByLibrary.simpleMessage("Mėnesinis"),
        "moreDetails": MessageLookupByLibrary.simpleMessage(
            "Daugiau išsamios informacijos"),
        "mostRecent": MessageLookupByLibrary.simpleMessage("Naujausią"),
        "mostRelevant": MessageLookupByLibrary.simpleMessage("Aktualiausią"),
        "moveItem": m41,
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
        "newPerson": MessageLookupByLibrary.simpleMessage("Naujas asmuo"),
        "newToEnte":
            MessageLookupByLibrary.simpleMessage("Naujas platformoje „Ente“"),
        "newest": MessageLookupByLibrary.simpleMessage("Naujausią"),
        "next": MessageLookupByLibrary.simpleMessage("Toliau"),
        "no": MessageLookupByLibrary.simpleMessage("Ne"),
        "noDeviceFound":
            MessageLookupByLibrary.simpleMessage("Įrenginys nerastas"),
        "noDeviceLimit": MessageLookupByLibrary.simpleMessage("Jokio"),
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
        "noSystemLockFound":
            MessageLookupByLibrary.simpleMessage("Nerastas sistemos užraktas"),
        "notPersonLabel": m44,
        "ok": MessageLookupByLibrary.simpleMessage("Gerai"),
        "onDevice": MessageLookupByLibrary.simpleMessage("Įrenginyje"),
        "onEnte": MessageLookupByLibrary.simpleMessage(
            "Saugykloje <branding>ente</branding>"),
        "onlyThem": MessageLookupByLibrary.simpleMessage("Tik jiems"),
        "oops": MessageLookupByLibrary.simpleMessage("Ups"),
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
        "passkey": MessageLookupByLibrary.simpleMessage("Slaptaraktas"),
        "passkeyAuthTitle":
            MessageLookupByLibrary.simpleMessage("Slaptarakto patvirtinimas"),
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
        "paymentFailedTalkToProvider": m46,
        "pendingItems":
            MessageLookupByLibrary.simpleMessage("Laukiami elementai"),
        "pendingSync":
            MessageLookupByLibrary.simpleMessage("Laukiama sinchronizacija"),
        "people": MessageLookupByLibrary.simpleMessage("Asmenys"),
        "permanentlyDeleteFromDevice": MessageLookupByLibrary.simpleMessage(
            "Ištrinti negrįžtamai iš įrenginio?"),
        "personName": MessageLookupByLibrary.simpleMessage("Asmens vardas"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("nuotrauka"),
        "photosAddedByYouWillBeRemovedFromTheAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Jūsų pridėtos nuotraukos bus pašalintos iš albumo"),
        "pinAlbum": MessageLookupByLibrary.simpleMessage("Prisegti albumą"),
        "pinLock": MessageLookupByLibrary.simpleMessage("PIN užrakinimas"),
        "playOnTv": MessageLookupByLibrary.simpleMessage(
            "Paleisti albumą televizoriuje"),
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
        "pleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("Bandykite dar kartą."),
        "pleaseVerifyTheCodeYouHaveEntered":
            MessageLookupByLibrary.simpleMessage("Patvirtinkite įvestą kodą."),
        "pleaseWait": MessageLookupByLibrary.simpleMessage("Palaukite..."),
        "pressAndHoldToPlayVideo": MessageLookupByLibrary.simpleMessage(
            "Paspauskite ir palaikykite, kad paleistumėte vaizdo įrašą"),
        "privacy": MessageLookupByLibrary.simpleMessage("Privatumas"),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Privatumo politika"),
        "privateBackups": MessageLookupByLibrary.simpleMessage(
            "Privačios atsarginės kopijos"),
        "privateSharing":
            MessageLookupByLibrary.simpleMessage("Privatus bendrinimas"),
        "processingImport": m50,
        "raiseTicket": MessageLookupByLibrary.simpleMessage("Sukurti paraišką"),
        "rateTheApp": MessageLookupByLibrary.simpleMessage("Vertinti programą"),
        "rateUsOnStore": m51,
        "recover": MessageLookupByLibrary.simpleMessage("Atkurti"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("Atkurti paskyrą"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Atkurti"),
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
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("Atkūrimas sėkmingas."),
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "Dabartinis įrenginys nėra pakankamai galingas, kad patvirtintų jūsų slaptažodį, bet mes galime iš naujo sugeneruoti taip, kad jis veiktų su visais įrenginiais.\n\nPrisijunkite naudojant atkūrimo raktą ir sugeneruokite iš naujo slaptažodį (jei norite, galite vėl naudoti tą patį)."),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Iš naujo sukurti slaptažodį"),
        "reddit": MessageLookupByLibrary.simpleMessage("„Reddit“"),
        "reenterPassword": MessageLookupByLibrary.simpleMessage(
            "Įveskite slaptažodį iš naujo"),
        "reenterPin":
            MessageLookupByLibrary.simpleMessage("Įveskite PIN iš naujo"),
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
        "removeLink": MessageLookupByLibrary.simpleMessage("Šalinti nuorodą"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Šalinti dalyvį"),
        "removeParticipantBody": m53,
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
        "rename": MessageLookupByLibrary.simpleMessage("Pervadinti"),
        "renameFile": MessageLookupByLibrary.simpleMessage("Pervadinti failą"),
        "renewSubscription":
            MessageLookupByLibrary.simpleMessage("Atnaujinti prenumeratą"),
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
            "Vaizdai bus rodomi čia, kai bus užbaigtas apdorojimas"),
        "searchHint3": MessageLookupByLibrary.simpleMessage(
            "Albumai, failų pavadinimai ir tipai"),
        "searchHint4": MessageLookupByLibrary.simpleMessage("Vietovė"),
        "searchLocationEmptySection": MessageLookupByLibrary.simpleMessage(
            "Grupės nuotraukos, kurios padarytos tam tikru spinduliu nuo nuotraukos"),
        "searchPeopleEmptySection": MessageLookupByLibrary.simpleMessage(
            "Pakvieskite asmenis ir čia matysite visas jų bendrinamas nuotraukas."),
        "searchPersonsEmptySection": MessageLookupByLibrary.simpleMessage(
            "Asmenys bus rodomi čia, kai bus užbaigtas apdorojimas"),
        "searchResultCount": m55,
        "selectALocation":
            MessageLookupByLibrary.simpleMessage("Pasirinkite vietovę"),
        "selectALocationFirst": MessageLookupByLibrary.simpleMessage(
            "Pirmiausia pasirinkite vietovę"),
        "selectLanguage":
            MessageLookupByLibrary.simpleMessage("Pasirinkite kalbą"),
        "selectReason":
            MessageLookupByLibrary.simpleMessage("Pasirinkite priežastį"),
        "selectYourPlan":
            MessageLookupByLibrary.simpleMessage("Pasirinkite planą"),
        "selectedFilesAreNotOnEnte": MessageLookupByLibrary.simpleMessage(
            "Pasirinkti failai nėra platformoje „Ente“"),
        "selectedPhotos": m4,
        "selectedPhotosWithYours": m57,
        "send": MessageLookupByLibrary.simpleMessage("Siųsti"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("Siųsti el. laišką"),
        "sendInvite": MessageLookupByLibrary.simpleMessage("Siųsti kvietimą"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Siųsti nuorodą"),
        "serverEndpoint":
            MessageLookupByLibrary.simpleMessage("Serverio galutinis taškas"),
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
        "shareAlbumHint": MessageLookupByLibrary.simpleMessage(
            "Atidarykite albumą ir palieskite bendrinimo mygtuką viršuje dešinėje, kad bendrintumėte."),
        "shareAnAlbumNow":
            MessageLookupByLibrary.simpleMessage("Bendrinti albumą dabar"),
        "shareMyVerificationID": m58,
        "shareOnlyWithThePeopleYouWant": MessageLookupByLibrary.simpleMessage(
            "Bendrinkite tik su tais asmenimis, su kuriais norite"),
        "shareTextConfirmOthersVerificationID": m5,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Atsisiųskite „Ente“, kad galėtume lengvai bendrinti originalios kokybės nuotraukas ir vaizdo įrašus.\n\nhttps://ente.io"),
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
            "Bendrinkite su ne „Ente“ naudotojais."),
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Sukurkite bendrinamus ir bendradarbiaujamus albumus su kitais „Ente“ naudotojais, įskaitant naudotojus nemokamuose planuose."),
        "sharing": MessageLookupByLibrary.simpleMessage("Bendrinima..."),
        "showPerson": MessageLookupByLibrary.simpleMessage("Rodyti asmenį"),
        "signOutOtherBody": MessageLookupByLibrary.simpleMessage(
            "Jei manote, kad kas nors gali žinoti jūsų slaptažodį, galite priverstinai atsijungti iš visų kitų įrenginių, naudojančių jūsų paskyrą."),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "Sutinku su <u-terms>paslaugų sąlygomis</u-terms> ir <u-policy> privatumo politika</u-policy>"),
        "singleFileInBothLocalAndRemote": m63,
        "singleFileInRemoteOnly": m64,
        "skip": MessageLookupByLibrary.simpleMessage("Praleisti"),
        "social": MessageLookupByLibrary.simpleMessage("Socialinės"),
        "someoneSharingAlbumsWithYouShouldSeeTheSameId":
            MessageLookupByLibrary.simpleMessage(
                "Asmuo, kuris bendrina albumus su jumis, savo įrenginyje turėtų matyti tą patį ID."),
        "somethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Kažkas nutiko ne taip"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Kažkas nutiko ne taip. Bandykite dar kartą."),
        "sorry": MessageLookupByLibrary.simpleMessage("Atsiprašome"),
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
        "subAlreadyLinkedErrMessage": m66,
        "subscribe": MessageLookupByLibrary.simpleMessage("Prenumeruoti"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "Kad įjungtumėte bendrinimą, reikia aktyvios mokamos prenumeratos."),
        "subscription": MessageLookupByLibrary.simpleMessage("Prenumerata"),
        "suggestFeatures":
            MessageLookupByLibrary.simpleMessage("Siūlyti funkcijas"),
        "support": MessageLookupByLibrary.simpleMessage("Palaikymas"),
        "syncProgress": m68,
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
        "tapToUploadIsIgnoredDue": m69,
        "tempErrorContactSupportIfPersists": MessageLookupByLibrary.simpleMessage(
            "Atrodo, kad kažkas nutiko ne taip. Bandykite dar kartą po kurio laiko. Jei klaida tęsiasi, susisiekite su mūsų palaikymo komanda."),
        "terminate": MessageLookupByLibrary.simpleMessage("Baigti"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Baigti seansą?"),
        "terms": MessageLookupByLibrary.simpleMessage("Sąlygos"),
        "termsOfServicesTitle": MessageLookupByLibrary.simpleMessage("Sąlygos"),
        "thankYou": MessageLookupByLibrary.simpleMessage("Dėkojame"),
        "theme": MessageLookupByLibrary.simpleMessage("Tema"),
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "Tai gali būti naudojama paskyrai atkurti, jei prarandate dvigubo tapatybės nustatymą"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Šis įrenginys"),
        "thisImageHasNoExifData": MessageLookupByLibrary.simpleMessage(
            "Šis vaizdas neturi Exif duomenų"),
        "thisIsPersonVerificationId": m71,
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
        "trim": MessageLookupByLibrary.simpleMessage("Trumpinti"),
        "tryAgain": MessageLookupByLibrary.simpleMessage("Bandyti dar kartą"),
        "twitter": MessageLookupByLibrary.simpleMessage("„Twitter“"),
        "twoMonthsFreeOnYearlyPlans": MessageLookupByLibrary.simpleMessage(
            "2 mėnesiai nemokamai metiniuose planuose"),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage(
                "Dvigubas tapatybės nustatymas"),
        "twofactorSetup": MessageLookupByLibrary.simpleMessage(
            "Dvigubo tapatybės nustatymo sąranka"),
        "typeOfGallerGallerytypeIsNotSupportedForRename": m73,
        "unavailableReferralCode": MessageLookupByLibrary.simpleMessage(
            "Atsiprašome, šis kodas nepasiekiamas."),
        "uncategorized":
            MessageLookupByLibrary.simpleMessage("Nekategorizuoti"),
        "unlock": MessageLookupByLibrary.simpleMessage("Atrakinti"),
        "unpinAlbum": MessageLookupByLibrary.simpleMessage("Atsegti albumą"),
        "upgrade": MessageLookupByLibrary.simpleMessage("Keisti planą"),
        "uploadIsIgnoredDueToIgnorereason": m74,
        "useAsCover":
            MessageLookupByLibrary.simpleMessage("Naudoti kaip viršelį"),
        "usePublicLinksForPeopleNotOnEnte": MessageLookupByLibrary.simpleMessage(
            "Naudokite viešas nuorodas asmenimis, kurie nėra sistemoje „Ente“"),
        "useRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Naudoti atkūrimo raktą"),
        "usedSpace": MessageLookupByLibrary.simpleMessage("Naudojama vieta"),
        "validTill": m76,
        "verificationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Patvirtinimas nepavyko. Bandykite dar kartą."),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("Patvirtinimo ID"),
        "verify": MessageLookupByLibrary.simpleMessage("Patvirtinti"),
        "verifyEmail":
            MessageLookupByLibrary.simpleMessage("Patvirtinti el. paštą"),
        "verifyEmailID": m77,
        "verifyIDLabel": MessageLookupByLibrary.simpleMessage("Patvirtinti"),
        "verifyPasskey":
            MessageLookupByLibrary.simpleMessage("Patvirtinti slaptaraktą"),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Patvirtinkite slaptažodį"),
        "verifying": MessageLookupByLibrary.simpleMessage("Patvirtinama..."),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Patvirtinima atkūrimo raktą..."),
        "videoInfo":
            MessageLookupByLibrary.simpleMessage("Vaizdo įrašo informacija"),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("vaizdo įrašas"),
        "viewAddOnButton":
            MessageLookupByLibrary.simpleMessage("Peržiūrėti priedus"),
        "viewAll": MessageLookupByLibrary.simpleMessage("Peržiūrėti viską"),
        "viewLogs": MessageLookupByLibrary.simpleMessage("Peržiūrėti žurnalus"),
        "viewRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Peržiūrėti atkūrimo raktą"),
        "viewer": MessageLookupByLibrary.simpleMessage("Žiūrėtojas"),
        "visitWebToManage": MessageLookupByLibrary.simpleMessage(
            "Aplankykite web.ente.io, kad tvarkytumėte savo prenumeratą"),
        "waitingForVerification":
            MessageLookupByLibrary.simpleMessage("Laukiama patvirtinimo..."),
        "weAreOpenSource":
            MessageLookupByLibrary.simpleMessage("Esame atviro kodo!"),
        "weHaveSendEmailTo": m2,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Silpna"),
        "welcomeBack": MessageLookupByLibrary.simpleMessage("Sveiki sugrįžę!"),
        "whatsNew": MessageLookupByLibrary.simpleMessage("Kas naujo"),
        "yearly": MessageLookupByLibrary.simpleMessage("Metinis"),
        "yearsAgo": m79,
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
        "youCannotDowngradeToThisPlan": MessageLookupByLibrary.simpleMessage(
            "Negalite pakeisti į šį planą"),
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("Jūsų paskyra ištrinta"),
        "yourMap": MessageLookupByLibrary.simpleMessage("Jūsų žemėlapis"),
        "yourStorageDetailsCouldNotBeFetched":
            MessageLookupByLibrary.simpleMessage(
                "Nepavyko gauti jūsų saugyklos duomenų."),
        "yourSubscriptionHasExpired":
            MessageLookupByLibrary.simpleMessage("Jūsų prenumerata baigėsi."),
        "yourVerificationCodeHasExpired": MessageLookupByLibrary.simpleMessage(
            "Jūsų patvirtinimo kodo laikas nebegaliojantis."),
        "youveNoDuplicateFilesThatCanBeCleared":
            MessageLookupByLibrary.simpleMessage(
                "Neturite dubliuotų failų, kuriuos būtų galima išvalyti")
      };
}
