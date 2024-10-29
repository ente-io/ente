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

  static String m8(count) =>
      "${Intl.plural(count, one: 'Pridėti žiūrėtoją', few: 'Pridėti žiūrėtojus', many: 'Pridėti žiūrėtojo', other: 'Pridėti žiūrėtojų')}";

  static String m12(versionValue) => "Versija: ${versionValue}";

  static String m20(endpoint) => "Prijungta prie ${endpoint}";

  static String m24(supportEmail) =>
      "Iš savo registruoto el. pašto adreso atsiųskite el. laišką adresu ${supportEmail}";

  static String m34(sizeInMBorGB) => "Atlaisvinti ${sizeInMBorGB}";

  static String m41(name) => "Ne ${name}?";

  static String m0(passwordStrengthValue) =>
      "Slaptažodžio stiprumas: ${passwordStrengthValue}";

  static String m47(folderName) => "Apdorojama ${folderName}...";

  static String m48(storeName) => "Vertinti mus parduotuvėje „${storeName}“";

  static String m52(count) =>
      "${Intl.plural(count, one: 'Rastas ${count} rezultatas', few: 'Rasti ${count} rezultatai', many: 'Rasta ${count} rezultato', other: 'Rasta ${count} rezultatų')}";

  static String m3(count) => "${count} pasirinkta";

  static String m53(count, yourCount) =>
      "${count} pasirinkta (${yourCount} jūsų)";

  static String m59(fileType) =>
      "Šis ${fileType} yra ir platformoje „Ente“ bei įrenginyje.";

  static String m60(fileType) => "Šis ${fileType} bus ištrintas iš „Ente“.";

  static String m61(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m65(completed, total) =>
      "${completed} / ${total} išsaugomi prisiminimai";

  static String m1(email) => "Išsiuntėme laišką į <green>${email}</green>";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "about": MessageLookupByLibrary.simpleMessage("Apie"),
        "account": MessageLookupByLibrary.simpleMessage("Paskyra"),
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Sveiki sugrįžę!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Suprantu, kad jei prarasiu slaptažodį, galiu prarasti savo duomenis, kadangi mano duomenys yra <underline>visapusiškai užšifruota</underline>."),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Aktyvūs seansai"),
        "add": MessageLookupByLibrary.simpleMessage("Pridėti"),
        "addAName": MessageLookupByLibrary.simpleMessage("Pridėti vardą"),
        "addANewEmail":
            MessageLookupByLibrary.simpleMessage("Pridėti naują el. paštą"),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Pridėti bendradarbį"),
        "addLocation": MessageLookupByLibrary.simpleMessage("Pridėti vietovę"),
        "addLocationButton": MessageLookupByLibrary.simpleMessage("Pridėti"),
        "addName": MessageLookupByLibrary.simpleMessage("Pridėti vardą"),
        "addNameOrMerge":
            MessageLookupByLibrary.simpleMessage("Pridėti vardą arba sujungti"),
        "addNew": MessageLookupByLibrary.simpleMessage("Pridėti naują"),
        "addNewPerson":
            MessageLookupByLibrary.simpleMessage("Pridėti naują asmenį"),
        "addViewer": MessageLookupByLibrary.simpleMessage("Pridėti žiūrėtoją"),
        "addViewers": m8,
        "advancedSettings":
            MessageLookupByLibrary.simpleMessage("Išplėstiniai"),
        "albums": MessageLookupByLibrary.simpleMessage("Albumai"),
        "allPersonGroupingWillReset": MessageLookupByLibrary.simpleMessage(
            "All groupings for this person will be reset, and you will lose all suggestions made for this person"),
        "appLock": MessageLookupByLibrary.simpleMessage("Programos užraktas"),
        "appLockDescriptions": MessageLookupByLibrary.simpleMessage(
            "Pasirinkite tarp numatytojo įrenginio užrakinimo ekrano ir pasirinktinio užrakinimo ekrano su PIN kodu arba slaptažodžiu."),
        "appVersion": m12,
        "appleId": MessageLookupByLibrary.simpleMessage("„Apple ID“"),
        "archiving": MessageLookupByLibrary.simpleMessage("Archyvuojama..."),
        "areYouSureYouWantToChangeYourPlan":
            MessageLookupByLibrary.simpleMessage(
                "Ar tikrai norite keisti planą?"),
        "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
            "Ar tikrai norite atsijungti?"),
        "areYouSureYouWantToResetThisPerson":
            MessageLookupByLibrary.simpleMessage(
                "Are you sure you want to reset this person?"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "Kokia yra pagrindinė priežastis, dėl kurios ištrinate savo paskyrą?"),
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
        "autoLock":
            MessageLookupByLibrary.simpleMessage("Automatinis užraktas"),
        "autoLockFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "Laikas, po kurio programa užrakinama perkėlus ją į foną"),
        "autoPair":
            MessageLookupByLibrary.simpleMessage("Automatiškai susieti"),
        "autoPairDesc": MessageLookupByLibrary.simpleMessage(
            "Automatinis susiejimas veikia tik su įrenginiais, kurie palaiko „Chromecast“."),
        "blog": MessageLookupByLibrary.simpleMessage("Tinklaraštis"),
        "cachedData":
            MessageLookupByLibrary.simpleMessage("Podėliuoti duomenis"),
        "cancel": MessageLookupByLibrary.simpleMessage("Atšaukti"),
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
        "checkForUpdates": MessageLookupByLibrary.simpleMessage(
            "Tikrinti, ar yra atnaujinimų"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Patikrinkite savo gautieją (ir šlamštą), kad užbaigtumėte patvirtinimą"),
        "checkStatus": MessageLookupByLibrary.simpleMessage("Tikrinti būseną"),
        "checking": MessageLookupByLibrary.simpleMessage("Tikrinama..."),
        "cleanUncategorized":
            MessageLookupByLibrary.simpleMessage("Valyti nekategorizuotą"),
        "cleanUncategorizedDescription": MessageLookupByLibrary.simpleMessage(
            "Pašalinkite iš nekategorizuotą visus failus, esančius kituose albumuose"),
        "clearCaches": MessageLookupByLibrary.simpleMessage("Valyti podėlius"),
        "close": MessageLookupByLibrary.simpleMessage("Uždaryti"),
        "clusteringProgress":
            MessageLookupByLibrary.simpleMessage("Sankaupos vykdymas"),
        "codeChangeLimitReached": MessageLookupByLibrary.simpleMessage(
            "Atsiprašome, pasiekėte kodo pakeitimų ribą."),
        "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Nukopijuotas kodas į iškarpinę"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Bendradarbiai gali pridėti nuotraukų ir vaizdo įrašų į bendrintą albumą."),
        "collect": MessageLookupByLibrary.simpleMessage("Rinkti"),
        "collectPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Sukurkite nuorodą, į kurią draugai gali įkelti originalios kokybės nuotraukas."),
        "color": MessageLookupByLibrary.simpleMessage("Spalva"),
        "configuration": MessageLookupByLibrary.simpleMessage("Konfiguracija"),
        "confirm": MessageLookupByLibrary.simpleMessage("Patvirtinti"),
        "confirmAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Patvirtinti paskyros ištrynimą"),
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Taip, noriu negrįžtamai ištrinti šią paskyrą ir jos duomenis per visas programas."),
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
        "creatingLink":
            MessageLookupByLibrary.simpleMessage("Kuriama nuoroda..."),
        "crop": MessageLookupByLibrary.simpleMessage("Apkirpti"),
        "custom": MessageLookupByLibrary.simpleMessage("Pasirinktinis"),
        "customEndpoint": m20,
        "darkTheme": MessageLookupByLibrary.simpleMessage("Tamsi"),
        "dayToday": MessageLookupByLibrary.simpleMessage("Šiandien"),
        "dayYesterday": MessageLookupByLibrary.simpleMessage("Vakar"),
        "decrypting": MessageLookupByLibrary.simpleMessage("Iššifruojama..."),
        "deleteAccount":
            MessageLookupByLibrary.simpleMessage("Ištrinti paskyrą"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "Apgailestaujame, kad išeinate. Pasidalykite savo atsiliepimais, kad padėtumėte mums tobulėti."),
        "deleteAccountPermanentlyButton": MessageLookupByLibrary.simpleMessage(
            "Ištrinti paskyrą negrįžtamai"),
        "deleteAlbum": MessageLookupByLibrary.simpleMessage("Ištrinti albumą"),
        "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
            "Taip pat ištrinti šiame albume esančias nuotraukas (ir vaizdo įrašus) iš <bold>visų</bold> kitų albumų, kuriuose jos yra dalis?"),
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
        "developerSettings":
            MessageLookupByLibrary.simpleMessage("Kūrėjo nustatymai"),
        "developerSettingsWarning": MessageLookupByLibrary.simpleMessage(
            "Ar tikrai norite modifikuoti kūrėjo nustatymus?"),
        "deviceCodeHint": MessageLookupByLibrary.simpleMessage("Įveskite kodą"),
        "deviceLock":
            MessageLookupByLibrary.simpleMessage("Įrenginio užraktas"),
        "deviceNotFound":
            MessageLookupByLibrary.simpleMessage("Įrenginys nerastas"),
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
        "download": MessageLookupByLibrary.simpleMessage("Atsisiųsti"),
        "dropSupportEmail": m24,
        "edit": MessageLookupByLibrary.simpleMessage("Redaguoti"),
        "editLocation":
            MessageLookupByLibrary.simpleMessage("Redaguoti vietovę"),
        "editLocationTagTitle":
            MessageLookupByLibrary.simpleMessage("Redaguoti vietovę"),
        "editsToLocationWillOnlyBeSeenWithinEnte":
            MessageLookupByLibrary.simpleMessage(
                "Vietovės pakeitimai bus matomi tik platformoje „Ente“"),
        "email": MessageLookupByLibrary.simpleMessage("El. paštas"),
        "emailVerificationToggle":
            MessageLookupByLibrary.simpleMessage("El. pašto patvirtinimas"),
        "empty": MessageLookupByLibrary.simpleMessage("Ištuštinti"),
        "emptyTrash":
            MessageLookupByLibrary.simpleMessage("Ištuštinti šiukšlinę?"),
        "enable": MessageLookupByLibrary.simpleMessage("Įjungti"),
        "enableMLIndexingDesc": MessageLookupByLibrary.simpleMessage(
            "„Ente“ palaiko įrenginyje mašininį mokymąsi, skirtą veidų atpažinimui, magiškai paieškai ir kitoms išplėstinėms paieškos funkcijoms"),
        "enableMapsDesc": MessageLookupByLibrary.simpleMessage(
            "Tai parodys jūsų nuotraukas pasaulio žemėlapyje.\n\nŠį žemėlapį talpina „OpenStreetMap“, o tiksliomis nuotraukų vietovėmis niekada nebendrinama.\n\nŠią funkciją bet kada galite išjungti iš nustatymų."),
        "enabled": MessageLookupByLibrary.simpleMessage("Įjungta"),
        "encryption": MessageLookupByLibrary.simpleMessage("Šifravimas"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Šifravimo raktai"),
        "endpointUpdatedMessage": MessageLookupByLibrary.simpleMessage(
            "Galutinis taškas sėkmingai atnaujintas"),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
            "„Ente“ <i>reikia leidimo</i> išsaugoti jūsų nuotraukas"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Įveskite kodą"),
        "enterEmail":
            MessageLookupByLibrary.simpleMessage("Įveskite el. paštą"),
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
        "exif": MessageLookupByLibrary.simpleMessage("EXIF"),
        "existingUser":
            MessageLookupByLibrary.simpleMessage("Esamas naudotojas"),
        "exportYourData":
            MessageLookupByLibrary.simpleMessage("Eksportuoti duomenis"),
        "extraPhotosFound": MessageLookupByLibrary.simpleMessage(
            "Rastos papildomos nuotraukos"),
        "extraPhotosFoundFor": MessageLookupByLibrary.simpleMessage(
            "Rastos papildomos nuotraukos, skirtos \$text"),
        "faceRecognition":
            MessageLookupByLibrary.simpleMessage("Veido atpažinimas"),
        "faces": MessageLookupByLibrary.simpleMessage("Veidai"),
        "failedToCancel":
            MessageLookupByLibrary.simpleMessage("Nepavyko atsisakyti"),
        "faq": MessageLookupByLibrary.simpleMessage("DUK"),
        "faqs": MessageLookupByLibrary.simpleMessage("DUK"),
        "feedback": MessageLookupByLibrary.simpleMessage("Atsiliepimai"),
        "findPeopleByName": MessageLookupByLibrary.simpleMessage(
            "Greitai suraskite žmones pagal vardą"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Pamiršau slaptažodį"),
        "foundFaces": MessageLookupByLibrary.simpleMessage("Rasti veidai"),
        "freeUpAmount": m34,
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Generuojami šifravimo raktai..."),
        "googlePlayId":
            MessageLookupByLibrary.simpleMessage("„Google Play“ ID"),
        "guestView": MessageLookupByLibrary.simpleMessage("Svečio peržiūra"),
        "guestViewEnablePreSteps": MessageLookupByLibrary.simpleMessage(
            "Kad įjungtumėte svečio peržiūrą, sistemos nustatymuose nustatykite įrenginio prieigos kodą arba ekrano užraktą."),
        "hidden": MessageLookupByLibrary.simpleMessage("Paslėpti"),
        "hideContent": MessageLookupByLibrary.simpleMessage("Slėpti turinį"),
        "hideContentDescriptionAndroid": MessageLookupByLibrary.simpleMessage(
            "Paslepia programų turinį programų perjungiklyje ir išjungia ekrano kopijas"),
        "hideContentDescriptionIos": MessageLookupByLibrary.simpleMessage(
            "Paslepia programos turinį programos perjungiklyje"),
        "howItWorks": MessageLookupByLibrary.simpleMessage("Kaip tai veikia"),
        "immediately": MessageLookupByLibrary.simpleMessage("Iš karto"),
        "importing": MessageLookupByLibrary.simpleMessage("Importuojama...."),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Neteisingas slaptažodis."),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "Įvestas atkūrimo raktas yra neteisingas."),
        "incorrectRecoveryKeyTitle":
            MessageLookupByLibrary.simpleMessage("Neteisingas atkūrimo raktas"),
        "indexedItems":
            MessageLookupByLibrary.simpleMessage("Indeksuoti elementai"),
        "indexingIsPaused": MessageLookupByLibrary.simpleMessage(
            "Indeksavimas pristabdytas. Jis bus automatiškai tęsiamas, kai įrenginys yra paruoštas."),
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
        "joinDiscord":
            MessageLookupByLibrary.simpleMessage("Jungtis prie „Discord“"),
        "keepPhotos":
            MessageLookupByLibrary.simpleMessage("Palikti nuotraukas"),
        "kiloMeterUnit": MessageLookupByLibrary.simpleMessage("km"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Maloniai padėkite mums su šia informacija"),
        "left": MessageLookupByLibrary.simpleMessage("Kairė"),
        "light": MessageLookupByLibrary.simpleMessage("Šviesi"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("Šviesi"),
        "loadingGallery":
            MessageLookupByLibrary.simpleMessage("Įkeliama galerija..."),
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
            "Magiška paieška leidžia ieškoti nuotraukų pagal jų turinį, pvz., „\"gėlė“, „raudonas automobilis“, „tapatybės dokumentai“"),
        "manageSubscription":
            MessageLookupByLibrary.simpleMessage("Tvarkyti prenumeratą"),
        "manualPairDesc": MessageLookupByLibrary.simpleMessage(
            "Susieti su PIN kodu veikia bet kuriame ekrane, kuriame norite peržiūrėti albumą."),
        "map": MessageLookupByLibrary.simpleMessage("Žemėlapis"),
        "mastodon": MessageLookupByLibrary.simpleMessage("„Mastodon“"),
        "matrix": MessageLookupByLibrary.simpleMessage("„Matrix“"),
        "merchandise": MessageLookupByLibrary.simpleMessage("Atributika"),
        "mergeWithExisting":
            MessageLookupByLibrary.simpleMessage("Sujungti su esamais"),
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
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Vidutinė"),
        "monthly": MessageLookupByLibrary.simpleMessage("Mėnesinis"),
        "moreDetails": MessageLookupByLibrary.simpleMessage(
            "Daugiau išsamios informacijos"),
        "mostRecent": MessageLookupByLibrary.simpleMessage("Naujausią"),
        "mostRelevant": MessageLookupByLibrary.simpleMessage("Aktualiausią"),
        "movedToTrash":
            MessageLookupByLibrary.simpleMessage("Perkelta į šiukšlinę"),
        "nameTheAlbum":
            MessageLookupByLibrary.simpleMessage("Pavadinti albumą"),
        "networkConnectionRefusedErr": MessageLookupByLibrary.simpleMessage(
            "Nepavyksta prisijungti prie „Ente“. Bandykite dar kartą po kurio laiko. Jei klaida tęsiasi, susisiekite su palaikymo komanda."),
        "networkHostLookUpErr": MessageLookupByLibrary.simpleMessage(
            "Nepavyksta prisijungti prie „Ente“. Patikrinkite tinklo nustatymus ir susisiekite su palaikymo komanda, jei klaida tęsiasi."),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Naujas albumas"),
        "newPerson": MessageLookupByLibrary.simpleMessage("Naujas asmuo"),
        "newToEnte":
            MessageLookupByLibrary.simpleMessage("Naujas platformoje „Ente“"),
        "next": MessageLookupByLibrary.simpleMessage("Sekantis"),
        "no": MessageLookupByLibrary.simpleMessage("Ne"),
        "noDeviceFound":
            MessageLookupByLibrary.simpleMessage("Įrenginys nerastas"),
        "noExifData": MessageLookupByLibrary.simpleMessage("Nėra EXIF duomenų"),
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
        "noResults": MessageLookupByLibrary.simpleMessage("Rezultatų nėra"),
        "noSystemLockFound":
            MessageLookupByLibrary.simpleMessage("Nerastas sistemos užraktas"),
        "notPersonLabel": m41,
        "ok": MessageLookupByLibrary.simpleMessage("Gerai"),
        "onDevice": MessageLookupByLibrary.simpleMessage("Įrenginyje"),
        "oops": MessageLookupByLibrary.simpleMessage("Ups"),
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
        "passwordStrength": m0,
        "passwordStrengthInfo": MessageLookupByLibrary.simpleMessage(
            "Slaptažodžio stiprumas apskaičiuojamas atsižvelgiant į slaptažodžio ilgį, naudotus simbolius ir į tai, ar slaptažodis patenka į 10 000 dažniausiai naudojamų slaptažodžių."),
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Šio slaptažodžio nesaugome, todėl jei jį pamiršite, <underline>negalėsime iššifruoti jūsų duomenų</underline>"),
        "pendingItems":
            MessageLookupByLibrary.simpleMessage("Laukiami elementai"),
        "pendingSync":
            MessageLookupByLibrary.simpleMessage("Laukiama sinchronizacija"),
        "people": MessageLookupByLibrary.simpleMessage("Asmenys"),
        "permanentlyDeleteFromDevice": MessageLookupByLibrary.simpleMessage(
            "Ištrinti negrįžtamai iš įrenginio?"),
        "personName": MessageLookupByLibrary.simpleMessage("Asmens vardas"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("nuotrauka"),
        "pinAlbum": MessageLookupByLibrary.simpleMessage("Prisegti albumą"),
        "pinLock": MessageLookupByLibrary.simpleMessage("PIN užrakinimas"),
        "playOnTv": MessageLookupByLibrary.simpleMessage(
            "Paleisti albumą televizoriuje"),
        "playstoreSubscription":
            MessageLookupByLibrary.simpleMessage("„PlayStore“ prenumerata"),
        "pleaseCheckYourInternetConnectionAndTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Patikrinkite savo interneto ryšį ir bandykite dar kartą."),
        "pleaseSelectQuickLinksToRemove": MessageLookupByLibrary.simpleMessage(
            "Pasirinkite sparčiąsias nuorodas, kad pašalintumėte"),
        "pleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("Bandykite dar kartą."),
        "pleaseWait": MessageLookupByLibrary.simpleMessage("Palaukite..."),
        "privacy": MessageLookupByLibrary.simpleMessage("Privatumas"),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Privatumo politika"),
        "processingImport": m47,
        "raiseTicket": MessageLookupByLibrary.simpleMessage("Sukurti paraišką"),
        "rateUsOnStore": m48,
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
        "removePersonLabel":
            MessageLookupByLibrary.simpleMessage("Pašalinti asmens žymą"),
        "removePublicLink":
            MessageLookupByLibrary.simpleMessage("Šalinti viešą nuorodą"),
        "removePublicLinks": MessageLookupByLibrary.simpleMessage(
            "Pašalinti viešąsias nuorodas"),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Šalinti?"),
        "renameFile": MessageLookupByLibrary.simpleMessage("Pervadinti failą"),
        "reportABug":
            MessageLookupByLibrary.simpleMessage("Pranešti apie riktą"),
        "reportBug":
            MessageLookupByLibrary.simpleMessage("Pranešti apie riktą"),
        "resendEmail":
            MessageLookupByLibrary.simpleMessage("Iš naujo siųsti el. laišką"),
        "resetPasswordTitle": MessageLookupByLibrary.simpleMessage(
            "Nustatyti slaptažodį iš naujo"),
        "resetPerson": MessageLookupByLibrary.simpleMessage("Reset person"),
        "reviewSuggestions":
            MessageLookupByLibrary.simpleMessage("Peržiūrėti pasiūlymus"),
        "right": MessageLookupByLibrary.simpleMessage("Dešinė"),
        "rotate": MessageLookupByLibrary.simpleMessage("Sukti"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Išsaugoti raktą"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Išsaugokite atkūrimo raktą, jei dar to nepadarėte"),
        "savingEdits":
            MessageLookupByLibrary.simpleMessage("Išsaugomi redagavimai..."),
        "scanCode": MessageLookupByLibrary.simpleMessage("Skenuoti kodą"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Skenuokite šį brūkšninį kodą\nsu autentifikatoriaus programa"),
        "search": MessageLookupByLibrary.simpleMessage("Ieškoti"),
        "searchHint4": MessageLookupByLibrary.simpleMessage("Vietovė"),
        "searchLocationEmptySection": MessageLookupByLibrary.simpleMessage(
            "Grupės nuotraukos, kurios padarytos tam tikru spinduliu nuo nuotraukos"),
        "searchResultCount": m52,
        "selectALocation":
            MessageLookupByLibrary.simpleMessage("Pasirinkite vietovę"),
        "selectALocationFirst": MessageLookupByLibrary.simpleMessage(
            "Pirmiausia pasirinkite vietovę"),
        "selectLanguage":
            MessageLookupByLibrary.simpleMessage("Pasirinkite kalbą"),
        "selectReason":
            MessageLookupByLibrary.simpleMessage("Pasirinkite priežastį"),
        "selectedFilesAreNotOnEnte": MessageLookupByLibrary.simpleMessage(
            "Pasirinkti failai nėra platformoje „Ente“"),
        "selectedPhotos": m3,
        "selectedPhotosWithYours": m53,
        "sendEmail": MessageLookupByLibrary.simpleMessage("Siųsti el. laišką"),
        "serverEndpoint":
            MessageLookupByLibrary.simpleMessage("Serverio galutinis taškas"),
        "setAs": MessageLookupByLibrary.simpleMessage("Nustatyti kaip"),
        "setLabel": MessageLookupByLibrary.simpleMessage("Nustatyti"),
        "setNewPassword": MessageLookupByLibrary.simpleMessage(
            "Nustatykite naują slaptažodį"),
        "setNewPin":
            MessageLookupByLibrary.simpleMessage("Nustatykite naują PIN"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Nustatyti slaptažodį"),
        "setupComplete": MessageLookupByLibrary.simpleMessage("Sąranka baigta"),
        "showPerson": MessageLookupByLibrary.simpleMessage("Rodyti asmenį"),
        "signOutOtherBody": MessageLookupByLibrary.simpleMessage(
            "Jei manote, kad kas nors gali žinoti jūsų slaptažodį, galite priverstinai atsijungti iš visų kitų įrenginių, naudojančių jūsų paskyrą."),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "Sutinku su <u-terms>paslaugų sąlygomis</u-terms> ir <u-policy> privatumo politika</u-policy>"),
        "singleFileInBothLocalAndRemote": m59,
        "singleFileInRemoteOnly": m60,
        "skip": MessageLookupByLibrary.simpleMessage("Praleisti"),
        "social": MessageLookupByLibrary.simpleMessage("Socialinės"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Kažkas nutiko ne taip. Bandykite dar kartą."),
        "sorry": MessageLookupByLibrary.simpleMessage("Atsiprašome"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "Atsiprašome, šiame įrenginyje nepavyko sugeneruoti saugių raktų.\n\nRegistruokitės iš kito įrenginio."),
        "sort": MessageLookupByLibrary.simpleMessage("Rikiuoti"),
        "status": MessageLookupByLibrary.simpleMessage("Būsena"),
        "stopCastingBody": MessageLookupByLibrary.simpleMessage(
            "Ar norite sustabdyti perdavimą?"),
        "stopCastingTitle":
            MessageLookupByLibrary.simpleMessage("Stabdyti perdavimą"),
        "storage": MessageLookupByLibrary.simpleMessage("Saugykla"),
        "storageBreakupYou": MessageLookupByLibrary.simpleMessage("Jūs"),
        "storageInGB": m61,
        "storageLimitExceeded":
            MessageLookupByLibrary.simpleMessage("Viršyta saugyklos riba."),
        "strongStrength": MessageLookupByLibrary.simpleMessage("Stipri"),
        "subscribe": MessageLookupByLibrary.simpleMessage("Prenumeruoti"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "Kad įjungtumėte bendrinimą, reikia aktyvios mokamos prenumeratos."),
        "suggestFeatures":
            MessageLookupByLibrary.simpleMessage("Siūlyti funkcijas"),
        "support": MessageLookupByLibrary.simpleMessage("Palaikymas"),
        "syncProgress": m65,
        "syncStopped": MessageLookupByLibrary.simpleMessage(
            "Sinchronizavimas sustabdytas"),
        "syncing": MessageLookupByLibrary.simpleMessage("Sinchronizuojama..."),
        "systemTheme": MessageLookupByLibrary.simpleMessage("Sistemos"),
        "tapToEnterCode": MessageLookupByLibrary.simpleMessage(
            "Palieskite, kad įvestumėte kodą"),
        "tapToUnlock": MessageLookupByLibrary.simpleMessage(
            "Palieskite, kad atrakintumėte"),
        "tempErrorContactSupportIfPersists": MessageLookupByLibrary.simpleMessage(
            "Atrodo, kad kažkas nutiko ne taip. Bandykite dar kartą po kurio laiko. Jei klaida tęsiasi, susisiekite su mūsų palaikymo komanda."),
        "terminate": MessageLookupByLibrary.simpleMessage("Baigti"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Baigti seansą?"),
        "terms": MessageLookupByLibrary.simpleMessage("Sąlygos"),
        "termsOfServicesTitle": MessageLookupByLibrary.simpleMessage("Sąlygos"),
        "theme": MessageLookupByLibrary.simpleMessage("Tema"),
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "Tai gali būti naudojama paskyrai atkurti, jei prarandate dvigubo tapatybės nustatymą"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Šis įrenginys"),
        "thisImageHasNoExifData": MessageLookupByLibrary.simpleMessage(
            "Šis vaizdas neturi Exif duomenų"),
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
        "unavailableReferralCode": MessageLookupByLibrary.simpleMessage(
            "Atsiprašome, šis kodas nepasiekiamas."),
        "uncategorized":
            MessageLookupByLibrary.simpleMessage("Nekategorizuoti"),
        "unpinAlbum": MessageLookupByLibrary.simpleMessage("Atsegti albumą"),
        "upgrade": MessageLookupByLibrary.simpleMessage("Keisti planą"),
        "useAsCover":
            MessageLookupByLibrary.simpleMessage("Naudoti kaip viršelį"),
        "useRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Naudoti atkūrimo raktą"),
        "usedSpace": MessageLookupByLibrary.simpleMessage("Naudojama vieta"),
        "verify": MessageLookupByLibrary.simpleMessage("Patvirtinti"),
        "verifyEmail":
            MessageLookupByLibrary.simpleMessage("Patvirtinti el. paštą"),
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
        "viewAll": MessageLookupByLibrary.simpleMessage("Peržiūrėti viską"),
        "viewLogs": MessageLookupByLibrary.simpleMessage("Peržiūrėti žurnalus"),
        "viewRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Peržiūrėti atkūrimo raktą"),
        "waitingForVerification":
            MessageLookupByLibrary.simpleMessage("Laukiama patvirtinimo..."),
        "weAreOpenSource":
            MessageLookupByLibrary.simpleMessage("Esame atviro kodo!"),
        "weHaveSendEmailTo": m1,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Silpna"),
        "welcomeBack": MessageLookupByLibrary.simpleMessage("Sveiki sugrįžę!"),
        "whatsNew": MessageLookupByLibrary.simpleMessage("Kas naujo"),
        "yearly": MessageLookupByLibrary.simpleMessage("Metinis"),
        "yes": MessageLookupByLibrary.simpleMessage("Taip"),
        "yesCancel": MessageLookupByLibrary.simpleMessage("Taip, atsisakyti"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("Taip, ištrinti"),
        "yesLogout": MessageLookupByLibrary.simpleMessage("Taip, atsijungti"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("Taip, šalinti"),
        "yesResetPerson":
            MessageLookupByLibrary.simpleMessage("Yes, reset person"),
        "youAreOnTheLatestVersion":
            MessageLookupByLibrary.simpleMessage("Esate naujausioje versijoje"),
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("Jūsų paskyra buvo ištrinta"),
        "yourStorageDetailsCouldNotBeFetched":
            MessageLookupByLibrary.simpleMessage(
                "Nepavyko gauti jūsų saugyklos duomenų.")
      };
}
