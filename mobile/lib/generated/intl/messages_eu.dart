// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a eu locale. All the
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
  String get localeName => 'eu';

  static String m8(count) =>
      "${Intl.plural(count, zero: 'Parte hartzailerik ez', one: 'Parte hartzaile 1', other: '${count} Parte hartzaile')}";

  static String m13(user) =>
      "${user}-(e)k ezin izango du argazki gehiago gehitu album honetan \n\nBaina haiek gehitutako argazkiak kendu ahal izango dituzte";

  static String m14(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true': 'Zure familiak ${storageAmountInGb} GB eskatu du dagoeneko',
            'false': 'Zuk ${storageAmountInGb} GB eskatu duzu dagoeneko',
            'other': 'Zuk ${storageAmountInGb} GB eskatu duzu dagoeneko!',
          })}";

  static String m24(albumName) =>
      "Honen bidez ${albumName} eskuratzeko esteka publikoa ezabatuko da.";

  static String m25(supportEmail) =>
      "Mesedez, bidali e-maila ${supportEmail}-era zure erregistratutako e-mail helbidetik";

  static String m31(email) =>
      "${email}-(e)k ez du Ente konturik. \n\nBidali gonbidapena argazkiak partekatzeko.";

  static String m37(storageAmountInGB) =>
      "${storageAmountInGB} GB norbaitek ordainpeko plan batean sartzen denean zure kodea aplikatzen badu";

  static String m47(expiryTime) =>
      "Esteka epe honetan iraungiko da: ${expiryTime}";

  static String m50(count, formattedCount) =>
      "${Intl.plural(count, zero: 'oroitzapenik ez', one: 'oroitzapen ${formattedCount}', other: '${formattedCount} oroitzapen')}";

  static String m55(familyAdminEmail) =>
      "Mesedez, jarri harremanetan ${familyAdminEmail}-(r)ekin zure kodea aldatzeko.";

  static String m57(passwordStrengthValue) =>
      "Pasahitzaren indarra: ${passwordStrengthValue}";

  static String m73(storageInGB) =>
      "3. Bai zuk bai haiek ${storageInGB} GB* dohainik izango duzue";

  static String m74(userEmail) =>
      "${userEmail} partekatutako album honetatik ezabatuko da \n\nHaiek gehitutako argazki guztiak ere ezabatuak izango dira albumetik";

  static String m80(count) => "${count} hautatuta";

  static String m81(count, yourCount) =>
      "${count} hautatuta (${yourCount} zureak)";

  static String m83(verificationID) =>
      "Hau da nire Egiaztatze IDa: ${verificationID} ente.io-rako.";

  static String m84(verificationID) =>
      "Ei, baieztatu ahal duzu hau dela zure ente.io Egiaztatze IDa?: ${verificationID}";

  static String m85(referralCode, referralStorageInGB) =>
      "Sartu erreferentzia kodea: ${referralCode}\n\nAplikatu hemen: Ezarpenak → Orokorra→ Erreferentziak, ${referralStorageInGB} GB dohainik izateko ordainpeko plan batean \n\nhttps://ente.io";

  static String m86(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Partekatu pertsona zehatz batzuekin', one: 'Partekatu pertsona batekin', other: 'Partekatu ${numberOfPeople} pertsonarekin')}";

  static String m88(fileType) => "${fileType} hau zure gailutik ezabatuko da.";

  static String m89(fileType) =>
      "${fileType} hau Ente-n eta zure gailuan dago.";

  static String m90(fileType) => "${fileType} hau Ente-tik ezabatuko da.";

  static String m93(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m99(storageAmountInGB) =>
      "Haiek ere lortuko dute ${storageAmountInGB} GB";

  static String m100(email) => "Hau da ${email}-(r)en Egiaztatze IDa";

  static String m111(email) => "Egiaztatu ${email}";

  static String m114(email) =>
      "Mezua bidali dugu <green>${email}</green> helbidera";

  static String m115(name) => "Wish \$${name} a happy birthday! 🎉";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Ongi etorri berriro!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Nire datuak <underline>puntutik puntura zifratuta</underline> daudenez, pasahitza ahaztuz gero nire datuak gal ditzakedala ulertzen dut."),
        "activeSessions": MessageLookupByLibrary.simpleMessage("Saio aktiboak"),
        "addANewEmail":
            MessageLookupByLibrary.simpleMessage("Gehitu e-mail berria"),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Gehitu laguntzailea"),
        "addMore": MessageLookupByLibrary.simpleMessage("Gehitu gehiago"),
        "addViewer": MessageLookupByLibrary.simpleMessage("Gehitu ikuslea"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Honela gehituta:"),
        "addingToFavorites":
            MessageLookupByLibrary.simpleMessage("Gogokoetan gehitzen..."),
        "advancedSettings": MessageLookupByLibrary.simpleMessage("Aurreratuak"),
        "after1Day": MessageLookupByLibrary.simpleMessage("Egun bat barru"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("Ordubete barru"),
        "after1Month":
            MessageLookupByLibrary.simpleMessage("Hilabete bat barru"),
        "after1Week": MessageLookupByLibrary.simpleMessage("Astebete barru"),
        "after1Year": MessageLookupByLibrary.simpleMessage("Urtebete barru"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Jabea"),
        "albumParticipantsCount": m8,
        "albumUpdated":
            MessageLookupByLibrary.simpleMessage("Albuma eguneratuta"),
        "albums": MessageLookupByLibrary.simpleMessage("Albumak"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Utzi esteka duen jendeari ere album partekatuan argazkiak gehitzen."),
        "allowAddingPhotos":
            MessageLookupByLibrary.simpleMessage("Baimendu argazkiak gehitzea"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("Baimendu jaitsierak"),
        "apply": MessageLookupByLibrary.simpleMessage("Aplikatu"),
        "applyCodeTitle":
            MessageLookupByLibrary.simpleMessage("Aplikatu kodea"),
        "archive": MessageLookupByLibrary.simpleMessage("Artxiboa"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "Zein da zure kontua ezabatzeko arrazoi nagusia?"),
        "authToChangeEmailVerificationSetting":
            MessageLookupByLibrary.simpleMessage(
                "Mesedez, autentifikatu emailaren egiaztatzea aldatzeko"),
        "authToChangeLockscreenSetting": MessageLookupByLibrary.simpleMessage(
            "Mesedez, autentifikatu pantaila blokeatzeko ezarpenak aldatzeko"),
        "authToChangeYourEmail": MessageLookupByLibrary.simpleMessage(
            "Mesedez, autentifikatu zure emaila aldatzeko"),
        "authToChangeYourPassword": MessageLookupByLibrary.simpleMessage(
            "Mesedez, autentifikatu zure pasahitza aldatzeko"),
        "authToConfigureTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Mesedez, autentifikatu faktore biko autentifikazioa konfiguratzeko"),
        "authToInitiateAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Mesedez, autentifikatu kontu ezabaketa hasteko"),
        "authToViewTrashedFiles": MessageLookupByLibrary.simpleMessage(
            "Mesedez, autentifikatu paperontzira botatako zure fitxategiak ikusteko"),
        "authToViewYourActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Mesedez, autentifikatu indarrean dauden zure saioak ikusteko"),
        "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
            "Mesedez, autentifikatu zure ezkutatutako fitxategiak ikusteko"),
        "authToViewYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Mesedez, autentifikatu zure berreskuratze giltza ikusteko"),
        "canNotOpenBody": MessageLookupByLibrary.simpleMessage(
            "Sentitzen dugu, album hau ezin da aplikazioan ireki."),
        "canNotOpenTitle":
            MessageLookupByLibrary.simpleMessage("Ezin dut album hau ireki"),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "Zure fitxategiak baino ezin duzu ezabatu"),
        "cancel": MessageLookupByLibrary.simpleMessage("Utzi"),
        "cannotAddMorePhotosAfterBecomingViewer": m13,
        "change": MessageLookupByLibrary.simpleMessage("Aldatu"),
        "changeEmail": MessageLookupByLibrary.simpleMessage("Aldatu e-maila"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Aldatu pasahitza"),
        "changePermissions":
            MessageLookupByLibrary.simpleMessage("Baimenak aldatu nahi?"),
        "changeYourReferralCode": MessageLookupByLibrary.simpleMessage(
            "Aldatu zure erreferentzia kodea"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Mesedez, aztertu zure inbox (eta spam) karpetak egiaztatzea osotzeko"),
        "claimFreeStorage": MessageLookupByLibrary.simpleMessage(
            "Eskatu debaldeko biltegiratzea"),
        "claimMore": MessageLookupByLibrary.simpleMessage("Eskatu gehiago!"),
        "claimed": MessageLookupByLibrary.simpleMessage("Eskatuta"),
        "claimedStorageSoFar": m14,
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("Kodea aplikatuta"),
        "codeChangeLimitReached": MessageLookupByLibrary.simpleMessage(
            "Sentitzen dugu, zure kode aldaketa muga gainditu duzu."),
        "codeCopiedToClipboard":
            MessageLookupByLibrary.simpleMessage("Kodea arbelean kopiatuta"),
        "codeUsedByYou":
            MessageLookupByLibrary.simpleMessage("Zuk erabilitako kodea"),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Sortu esteka bat beste pertsona batzuei zure album partekatuan arriskuak gehitu eta ikusten uzteko, naiz eta Ente aplikazio edo kontua ez izan. Oso egokia gertakizun bateko argazkiak biltzeko."),
        "collaborativeLink":
            MessageLookupByLibrary.simpleMessage("Parte hartzeko esteka"),
        "collaborator": MessageLookupByLibrary.simpleMessage("Laguntzailea"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Laguntzaileek argazkiak eta bideoak gehitu ahal dituzte album partekatuan."),
        "collectPhotos":
            MessageLookupByLibrary.simpleMessage("Bildu argazkiak"),
        "confirm": MessageLookupByLibrary.simpleMessage("Baieztatu"),
        "confirm2FADisable": MessageLookupByLibrary.simpleMessage(
            "Seguru zaude faktore biko autentifikazioa deuseztatu nahi duzula?"),
        "confirmAccountDeletion":
            MessageLookupByLibrary.simpleMessage("Baieztatu Kontu Ezabaketa"),
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Bai, betiko ezabatu nahi dut kontu hau eta berarekiko data aplikazio guztietan zehar."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Egiaztatu pasahitza"),
        "confirmRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Egiaztatu berreskuratze kodea"),
        "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Egiaztatu zure berreskuratze giltza"),
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("Kontaktatu laguntza"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("Jarraitu"),
        "copyLink": MessageLookupByLibrary.simpleMessage("Kopiatu esteka"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Kopiatu eta itsatsi kode hau zure autentifikazio aplikaziora"),
        "createAccount": MessageLookupByLibrary.simpleMessage("Sortu kontua"),
        "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
            "Luze klikatu argazkiak hautatzeko eta klikatu + albuma sortzeko"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("Sortu kontu berria"),
        "createPublicLink":
            MessageLookupByLibrary.simpleMessage("Sortu esteka publikoa"),
        "creatingLink":
            MessageLookupByLibrary.simpleMessage("Esteka sortzen..."),
        "custom": MessageLookupByLibrary.simpleMessage("Aukeran"),
        "decrypting": MessageLookupByLibrary.simpleMessage("Deszifratzen..."),
        "deleteAccount":
            MessageLookupByLibrary.simpleMessage("Ezabatu zure kontua"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "Sentitzen dugu zu joateaz. Mesedez, utziguzu zure feedbacka hobetzen laguntzeko."),
        "deleteAccountPermanentlyButton":
            MessageLookupByLibrary.simpleMessage("Ezabatu Kontua Betiko"),
        "deleteAlbum": MessageLookupByLibrary.simpleMessage("Ezabatu albuma"),
        "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
            "Ezabatu nahi dituzu album honetan dauden argazkiak (eta bideoak) parte diren beste album <bold>guztietatik</bold> ere?"),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "Mesedez, bidali e-mail bat <warning>account-deletion@ente.io</warning> helbidea zure erregistatutako helbidetik."),
        "deleteFromBoth":
            MessageLookupByLibrary.simpleMessage("Ezabatu bietatik"),
        "deleteFromDevice":
            MessageLookupByLibrary.simpleMessage("Ezabatu gailutik"),
        "deleteFromEnte":
            MessageLookupByLibrary.simpleMessage("Ezabatu Ente-tik"),
        "deletePhotos":
            MessageLookupByLibrary.simpleMessage("Ezabatu argazkiak"),
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "Behar dudan ezaugarre nagusiren bat falta zaio"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "Aplikazioak edo ezaugarriren batek ez du funtzionatzen nik espero nuenez"),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
            "Gustukoago dudan beste zerbitzu bat aurkitu dut"),
        "deleteReason4": MessageLookupByLibrary.simpleMessage(
            "Nire arrazoia ez dago zerrendan"),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
            "Zure eskaera 72 ordutan prozesatua izango da."),
        "deleteSharedAlbum": MessageLookupByLibrary.simpleMessage(
            "Partekatutako albuma ezabatu?"),
        "deleteSharedAlbumDialogBody": MessageLookupByLibrary.simpleMessage(
            "Albuma guztiontzat ezabatuko da \n\nAlbum honetan dauden beste pertsonek partekatutako argazkiak ezin izango dituzu eskuratu"),
        "details": MessageLookupByLibrary.simpleMessage("Detaileak"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Ikusleek pantaila-irudiak atera ahal dituzte, edo kanpoko tresnen bidez zure argazkien kopiak gorde"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Mesedez, ohartu"),
        "disableLinkMessage": m24,
        "discover": MessageLookupByLibrary.simpleMessage("Aurkitu"),
        "discover_babies": MessageLookupByLibrary.simpleMessage("Umeak"),
        "discover_celebrations":
            MessageLookupByLibrary.simpleMessage("Ospakizunak"),
        "discover_food": MessageLookupByLibrary.simpleMessage("Janaria"),
        "discover_greenery": MessageLookupByLibrary.simpleMessage("Hostoa"),
        "discover_hills": MessageLookupByLibrary.simpleMessage("Muinoak"),
        "discover_identity": MessageLookupByLibrary.simpleMessage("Nortasuna"),
        "discover_memes": MessageLookupByLibrary.simpleMessage("Memeak"),
        "discover_notes": MessageLookupByLibrary.simpleMessage("Oharrak"),
        "discover_pets": MessageLookupByLibrary.simpleMessage("Etxe-animaliak"),
        "discover_receipts":
            MessageLookupByLibrary.simpleMessage("Ordainagiriak"),
        "discover_screenshots":
            MessageLookupByLibrary.simpleMessage("Pantaila argazkiak"),
        "discover_selfies": MessageLookupByLibrary.simpleMessage("Selfiak"),
        "discover_sunset":
            MessageLookupByLibrary.simpleMessage("Eguzki-sartzea"),
        "discover_visiting_cards":
            MessageLookupByLibrary.simpleMessage("Bisita txartelak"),
        "discover_wallpapers":
            MessageLookupByLibrary.simpleMessage("Horma-paperak"),
        "doThisLater": MessageLookupByLibrary.simpleMessage("Egin hau geroago"),
        "done": MessageLookupByLibrary.simpleMessage("Eginda"),
        "dropSupportEmail": m25,
        "eligible": MessageLookupByLibrary.simpleMessage("aukerakoak"),
        "email": MessageLookupByLibrary.simpleMessage("E-maila"),
        "emailAlreadyRegistered": MessageLookupByLibrary.simpleMessage(
            "Helbide hau badago erregistratuta lehendik."),
        "emailNoEnteAccount": m31,
        "emailNotRegistered": MessageLookupByLibrary.simpleMessage(
            "Helbide hau ez dago erregistratuta."),
        "encryption": MessageLookupByLibrary.simpleMessage("Zifratzea"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Zifratze giltzak"),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
            "Ente-k <i>zure baimena behar du</i> zure argazkiak gordetzeko"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Sartu kodea"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
            "Sartu zure lagunak emandako kodea, biontzat debaldeko biltegiratzea lortzeko"),
        "enterEmail": MessageLookupByLibrary.simpleMessage("Sartu e-maila"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Sartu pasahitz berri bat, zure data zifratu ahal izateko"),
        "enterPassword":
            MessageLookupByLibrary.simpleMessage("Sartu pasahitza"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Sartu pasahitz bat, zure data deszifratu ahal izateko"),
        "enterReferralCode":
            MessageLookupByLibrary.simpleMessage("Sartu erreferentzia kodea"),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Sartu 6 digituko kodea zure autentifikazio aplikaziotik"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "Mesedez, sartu zuzena den helbidea."),
        "enterYourEmailAddress": MessageLookupByLibrary.simpleMessage(
            "Sartu zure helbide elektronikoa"),
        "enterYourPassword":
            MessageLookupByLibrary.simpleMessage("Sartu zure pasahitza"),
        "enterYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Sartu zure berreskuratze giltza"),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
            "Esteka hau iraungi da. Mesedez, aukeratu beste epemuga bat edo deuseztatu estekaren epemuga."),
        "failedToApplyCode":
            MessageLookupByLibrary.simpleMessage("Akatsa kodea aplikatzean"),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "Ezin dugu zure erreferentziaren detailerik lortu. Mesedez, saiatu berriro geroago."),
        "failedToLoadAlbums":
            MessageLookupByLibrary.simpleMessage("Errorea albumak kargatzen"),
        "faq": MessageLookupByLibrary.simpleMessage("FAQ"),
        "feedback": MessageLookupByLibrary.simpleMessage("Feedbacka"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Ahaztu pasahitza"),
        "freeStorageClaimed": MessageLookupByLibrary.simpleMessage(
            "Debaldeko biltegiratzea eskatuta"),
        "freeStorageOnReferralSuccess": m37,
        "freeStorageUsable": MessageLookupByLibrary.simpleMessage(
            "Debaldeko biltegiratzea erabilgarri"),
        "generatingEncryptionKeys":
            MessageLookupByLibrary.simpleMessage("Zifratze giltzak sortzen..."),
        "help": MessageLookupByLibrary.simpleMessage("Laguntza"),
        "hidden": MessageLookupByLibrary.simpleMessage("Ezkutatuta"),
        "howItWorks":
            MessageLookupByLibrary.simpleMessage("Nola funtzionatzen duen"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "Mesedez, eska iezaiozu ezarpenen landutako bere e-mail helbidean luze klikatzeko, eta egiaztatu gailu bietako IDak bat direla."),
        "iOSLockOut": MessageLookupByLibrary.simpleMessage(
            "Autentifikazio biometrikoa deuseztatuta dago. Mesedez, blokeatu eta desblokeatu zure pantaila indarrean jartzeko."),
        "importing": MessageLookupByLibrary.simpleMessage("Inportatzen...."),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Pasahitz okerra"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "Sartu duzun berreskuratze giltza ez da zuzena"),
        "incorrectRecoveryKeyTitle": MessageLookupByLibrary.simpleMessage(
            "Berreskuratze giltza ez da zuzena"),
        "insecureDevice":
            MessageLookupByLibrary.simpleMessage("Gailua ez da segurua"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("Helbide hau ez da zuzena"),
        "invalidKey": MessageLookupByLibrary.simpleMessage("Kode okerra"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Sartu duzun berreskuratze kodea ez da zuzena. Mesedez, ziurtatu 24 hitz duela, eta egiaztatu hitz bakoitzaren idazkera. \n\nBerreskuratze kode zaharren bat sartu baduzu, ziurtatu 64 karaktere duela, eta egiaztatu horietako bakoitza."),
        "inviteToEnte":
            MessageLookupByLibrary.simpleMessage("Gonbidatu Ente-ra"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Gonbidatu zure lagunak"),
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "Hautatutako elementuak album honetatik kenduko dira"),
        "keepPhotos": MessageLookupByLibrary.simpleMessage("Gorde Argazkiak"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Mesedez, lagun gaitzazu informazio honekin"),
        "linkDeviceLimit": MessageLookupByLibrary.simpleMessage("Gailu muga"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Indarrean"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Iraungita"),
        "linkExpiresOn": m47,
        "linkExpiry": MessageLookupByLibrary.simpleMessage("Estekaren epemuga"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("Esteka iraungi da"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Inoiz ez"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Blokeatu"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Sartu"),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "Sartzeko klikatuz, <u-terms>zerbitzu baldintzak</u-terms> eta <u-policy>pribatutasun politikak</u-policy> onartzen ditut"),
        "lostDevice":
            MessageLookupByLibrary.simpleMessage("Gailua galdu duzu?"),
        "machineLearning":
            MessageLookupByLibrary.simpleMessage("Ikasketa automatikoa"),
        "magicSearch": MessageLookupByLibrary.simpleMessage("Bilaketa magikoa"),
        "manage": MessageLookupByLibrary.simpleMessage("Kudeatu"),
        "manageDeviceStorage":
            MessageLookupByLibrary.simpleMessage("Kudeatu gailuaren katxea"),
        "manageDeviceStorageDesc": MessageLookupByLibrary.simpleMessage(
            "Berrikusi eta garbitu katxe lokalaren biltegiratzea."),
        "manageLink": MessageLookupByLibrary.simpleMessage("Kudeatu esteka"),
        "manageParticipants": MessageLookupByLibrary.simpleMessage("Kudeatu"),
        "memoryCount": m50,
        "mlConsent": MessageLookupByLibrary.simpleMessage(
            "Aktibatu ikasketa automatikoa"),
        "mlConsentConfirmation": MessageLookupByLibrary.simpleMessage(
            "Ulertzen dut, eta ikasketa automatikoa aktibatu nahi dut"),
        "mlConsentDescription": MessageLookupByLibrary.simpleMessage(
            "Ikasketa automatikoa aktibatuz gero, Ente-k fitxategietatik informazioa aterako du (ad. argazkien geometria), zurekin partekatutako argazkietatik ere.\n\nHau zure gailuan gertatuko da, eta sortutako informazio biometrikoa puntutik puntura zifratuta egongo da."),
        "mlConsentPrivacy": MessageLookupByLibrary.simpleMessage(
            "Mesedez, klikatu hemen gure pribatutasun politikan ezaugarri honi buruz detaile gehiago izateko"),
        "mlConsentTitle": MessageLookupByLibrary.simpleMessage(
            "Ikasketa automatikoa aktibatuko?"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Ertaina"),
        "movedToTrash": MessageLookupByLibrary.simpleMessage("Zarama mugituta"),
        "never": MessageLookupByLibrary.simpleMessage("Inoiz ez"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Album berria"),
        "noDeviceLimit": MessageLookupByLibrary.simpleMessage("Bat ere ez"),
        "noRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Berreskuratze giltzarik ez?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "Gure puntutik-puntura zifratze protokoloa dela eta, zure data ezin da deszifratu zure pasahitza edo berreskuratze giltzarik gabe"),
        "ok": MessageLookupByLibrary.simpleMessage("Ondo"),
        "onlyFamilyAdminCanChangeCode": m55,
        "oops": MessageLookupByLibrary.simpleMessage("Ai!"),
        "oopsSomethingWentWrong": MessageLookupByLibrary.simpleMessage(
            "Oops, zerbait txarto joan da"),
        "orPickAnExistingOne":
            MessageLookupByLibrary.simpleMessage("Edo aukeratu lehengo bat"),
        "password": MessageLookupByLibrary.simpleMessage("Pasahitza"),
        "passwordChangedSuccessfully":
            MessageLookupByLibrary.simpleMessage("Pasahitza zuzenki aldatuta"),
        "passwordLock":
            MessageLookupByLibrary.simpleMessage("Pasahitza blokeoa"),
        "passwordStrength": m57,
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Ezin dugu zure pasahitza gorde, beraz, ahazten baduzu, <underline>ezin dugu zure data deszifratu</underline>"),
        "peopleUsingYourCode": MessageLookupByLibrary.simpleMessage(
            "Jendea zure kodea erabiltzen"),
        "photoGridSize":
            MessageLookupByLibrary.simpleMessage("Argazki sarearen tamaina"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("argazkia"),
        "pleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("Saiatu berriro, mesedez"),
        "pleaseWait":
            MessageLookupByLibrary.simpleMessage("Mesedez, itxaron..."),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Pribatutasun Politikak"),
        "publicLinkEnabled":
            MessageLookupByLibrary.simpleMessage("Esteka publikoa indarrean"),
        "recover": MessageLookupByLibrary.simpleMessage("Berreskuratu"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("Berreskuratu kontua"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Berreskuratu"),
        "recoveryKey":
            MessageLookupByLibrary.simpleMessage("Berreskuratze giltza"),
        "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Berreskuratze giltza arbelean kopiatu da"),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
            "Zure pasahitza ahazten baduzu, zure datuak berreskuratzeko modu bakarra gailu honen bidez izango da."),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
            "Guk ez dugu gailu hau gordetzen; mesedez, gorde 24 hitzeko giltza hau lege seguru batean."),
        "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
            "Primeran! Zure berreskuratze giltza zuzena da. Eskerrik asko egiaztatzeagatik.\n\nMesedez, gogoratu zure berreskuratze giltza leku seguruan gordetzea."),
        "recoveryKeyVerified": MessageLookupByLibrary.simpleMessage(
            "Berreskuratze giltza egiaztatuta"),
        "recoveryKeyVerifyReason": MessageLookupByLibrary.simpleMessage(
            "Pasahitza ahazten baduzu, zure berreskuratze giltza argazkiak berreskuratzeko modu bakarra da. Berreskuratze giltza hemen aurkitu ahal duzu Ezarpenak > Kontua.\n\nMesedez sartu hemen zure berreskuratze giltza ondo gorde duzula egiaztatzeko."),
        "recoverySuccessful": MessageLookupByLibrary.simpleMessage(
            "Berreskurapen arrakastatsua!"),
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "Gailu hau ez da zure pasahitza egiaztatzeko bezain indartsua, baina gailu guztietan funtzionatzen duen modu batean birsortu ahal dugu. \n\nMesedez sartu zure berreskuratze giltza erabiliz eta birsortu zure pasahitza (aurreko berbera erabili ahal duzu nahi izanez gero)."),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Berrezarri pasahitza"),
        "referralStep1": MessageLookupByLibrary.simpleMessage(
            "1. Eman kode hau zure lagunei"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "2. Haiek ordainpeko plan batean sinatu behar dute"),
        "referralStep3": m73,
        "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
            "Erreferentziak momentuz geldituta daude"),
        "remove": MessageLookupByLibrary.simpleMessage("Kendu"),
        "removeFromAlbum":
            MessageLookupByLibrary.simpleMessage("Kendu albumetik"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("Albumetik kendu?"),
        "removeLink": MessageLookupByLibrary.simpleMessage("Ezabatu esteka"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Kendu parte hartzailea"),
        "removeParticipantBody": m74,
        "removePublicLink":
            MessageLookupByLibrary.simpleMessage("Ezabatu esteka publikoa"),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
            "Kentzen ari zaren elementu batzuk beste pertsona batzuek gehitu zituzten, beraz ezin izango dituzu eskuratu"),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Ezabatuko?"),
        "removingFromFavorites":
            MessageLookupByLibrary.simpleMessage("Gogokoetatik kentzen..."),
        "resendEmail":
            MessageLookupByLibrary.simpleMessage("Birbidali e-maila"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Berrezarri pasahitza"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Gorde giltza"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Gorde zure berreskuratze giltza ez baduzu oraindik egin"),
        "scanCode": MessageLookupByLibrary.simpleMessage("Eskaneatu kodea"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Eskaneatu barra kode hau zure autentifikazio aplikazioaz"),
        "selectReason":
            MessageLookupByLibrary.simpleMessage("Aukeratu arrazoia"),
        "selectedPhotos": m80,
        "selectedPhotosWithYours": m81,
        "sendEmail": MessageLookupByLibrary.simpleMessage("Bidali mezua"),
        "sendInvite":
            MessageLookupByLibrary.simpleMessage("Bidali gonbidapena"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Bidali esteka"),
        "setAPassword":
            MessageLookupByLibrary.simpleMessage("Ezarri pasahitza"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Ezarri pasahitza"),
        "setupComplete":
            MessageLookupByLibrary.simpleMessage("Prestaketa burututa"),
        "shareALink": MessageLookupByLibrary.simpleMessage("Partekatu esteka"),
        "shareMyVerificationID": m83,
        "shareTextConfirmOthersVerificationID": m84,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Jaitsi Ente argazkiak eta bideoak jatorrizko kalitatean errez partekatu ahal izateko \n\nhttps://ente.io"),
        "shareTextReferralCode": m85,
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
            "Partekatu Ente erabiltzen ez dutenekin"),
        "shareWithPeopleSectionTitle": m86,
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Sortu partekatutako eta parte hartzeko albumak beste Ente erabiltzaileekin, debaldeko planak dituztenak barne."),
        "sharing": MessageLookupByLibrary.simpleMessage("Partekatzen..."),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "<u-terms>Zerbitzu baldintzak</u-terms> eta <u-policy>pribatutasun politikak</u-policy> onartzen ditut"),
        "singleFileDeleteFromDevice": m88,
        "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
            "Album guztietatik ezabatuko da."),
        "singleFileInBothLocalAndRemote": m89,
        "singleFileInRemoteOnly": m90,
        "someoneSharingAlbumsWithYouShouldSeeTheSameId":
            MessageLookupByLibrary.simpleMessage(
                "Zurekin albumak partekatzen dituen norbaitek ID berbera ikusi beharko luke bere gailuan."),
        "somethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Zerbait oker joan da"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Zerbait ez da ondo joan, mesedez, saiatu berriro"),
        "sorry": MessageLookupByLibrary.simpleMessage("Barkatu"),
        "sorryCouldNotAddToFavorites": MessageLookupByLibrary.simpleMessage(
            "Sentitzen dut, ezin izan dugu zure gogokoetan gehitu!"),
        "sorryCouldNotRemoveFromFavorites":
            MessageLookupByLibrary.simpleMessage(
                "Sentitzen dugu, ezin izan dugu zure gogokoetatik kendu!"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "Tamalez, ezin dugu giltza segururik sortu gailu honetan. \n\nMesedez, eman izena beste gailu batetik."),
        "storageInGB": m93,
        "strongStrength": MessageLookupByLibrary.simpleMessage("Gogorra"),
        "subscribe": MessageLookupByLibrary.simpleMessage("Harpidetu"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "Ordainpeko harpidetza behar duzu partekatzea aktibatzeko."),
        "tapToCopy": MessageLookupByLibrary.simpleMessage("jo kopiatzeko"),
        "tapToEnterCode":
            MessageLookupByLibrary.simpleMessage("Klikatu kodea sartzeko"),
        "terminate": MessageLookupByLibrary.simpleMessage("Bukatu"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Saioa bukatu?"),
        "termsOfServicesTitle":
            MessageLookupByLibrary.simpleMessage("Baldintzak"),
        "theyAlsoGetXGb": m99,
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "Hau zure kontua berreskuratzeko erabili ahal duzu, zure bigarren faktorea ahaztuz gero"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Gailu hau"),
        "thisIsPersonVerificationId": m100,
        "thisIsYourVerificationId":
            MessageLookupByLibrary.simpleMessage("Hau da zure Egiaztatze IDa"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Hau egiteak hurrengo gailutik aterako zaitu:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Hau egiteak gailu honetatik aterako zaitu!"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "Zure pasahitza berrezartzeko, mesedez egiaztatu zure e-maila lehenengoz."),
        "total": MessageLookupByLibrary.simpleMessage("osotara"),
        "trash": MessageLookupByLibrary.simpleMessage("Zarama"),
        "tryAgain": MessageLookupByLibrary.simpleMessage("Saiatu berriro"),
        "twofactorAuthenticationHasBeenDisabled":
            MessageLookupByLibrary.simpleMessage(
                "Faktore biko autentifikazioa deuseztatua izan da"),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage(
                "Faktore biko autentifikatzea"),
        "twofactorSetup":
            MessageLookupByLibrary.simpleMessage("Faktore biko ezarpena"),
        "unavailableReferralCode": MessageLookupByLibrary.simpleMessage(
            "Sentitzen dugu, kode hau ezin da erabili."),
        "uncategorized":
            MessageLookupByLibrary.simpleMessage("Kategori gabekoa"),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "Biltegiratze erabilgarria zure oraingo planaren arabera mugatuta dago. Soberan eskatutako biltegiratzea automatikoki erabili ahal izango duzu zure plan gaurkotzen duzunean."),
        "useRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Erabili berreskuratze giltza"),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("Egiaztatze IDa"),
        "verify": MessageLookupByLibrary.simpleMessage("Egiaztatu"),
        "verifyEmail":
            MessageLookupByLibrary.simpleMessage("Egiaztatu e-maila"),
        "verifyEmailID": m111,
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Egiaztatu pasahitza"),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Berreskuratze giltza egiaztatuz..."),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("bideoa"),
        "viewRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Ikusi berreskuratze kodea"),
        "viewer": MessageLookupByLibrary.simpleMessage("Ikuslea"),
        "weHaveSendEmailTo": m114,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Ahula"),
        "welcomeBack":
            MessageLookupByLibrary.simpleMessage("Ongi etorri berriro!"),
        "wishThemAHappyBirthday": m115,
        "yesConvertToViewer":
            MessageLookupByLibrary.simpleMessage("Bai, egin ikusle"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("Bai, ezabatu"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("Bai, ezabatu"),
        "you": MessageLookupByLibrary.simpleMessage("Zu"),
        "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "* Gehienez zure biltegiratzea bikoiztu ahal duzu"),
        "youCannotShareWithYourself": MessageLookupByLibrary.simpleMessage(
            "Ezin duzu zeure buruarekin partekatu"),
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("Zure kontua ezabatua izan da")
      };
}
