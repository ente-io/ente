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

  static String m24(supportEmail) =>
      "Mesedez, bidali e-maila ${supportEmail}-era zure erregistratutako e-mail helbidetik";

  static String m29(email) =>
      "${email}-(e)k ez du Ente konturik. \n\nBidali gonbidapena argazkiak partekatzeko.";

  static String m35(storageAmountInGB) =>
      "${storageAmountInGB} GB norbaitek ordainpeko plan batean sartzen denean zure kodea aplikatzen badu";

  static String m45(expiryTime) =>
      "Esteka epe honetan iraungiko da: ${expiryTime}";

  static String m53(familyAdminEmail) =>
      "Mesedez, jarri harremanetan ${familyAdminEmail}-(r)ekin zure kodea aldatzeko.";

  static String m55(passwordStrengthValue) =>
      "Pasahitzaren indarra: ${passwordStrengthValue}";

  static String m80(verificationID) =>
      "Hau da nire Egiaztatze IDa: ${verificationID} ente.io-rako.";

  static String m81(verificationID) =>
      "Ei, baieztatu ahal duzu hau dela zure ente.io Egiaztatze IDa?: ${verificationID}";

  static String m83(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Partekatu pertsona zehatz batzuekin', one: 'Partekatu pertsona batekin', other: 'Partekatu ${numberOfPeople} pertsonarekin')}";

  static String m90(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m96(storageAmountInGB) =>
      "Haiek ere lortuko dute ${storageAmountInGB} GB";

  static String m97(email) => "Hau da ${email}-(r)en Egiaztatze IDa";

  static String m108(email) => "Egiaztatu ${email}";

  static String m110(email) =>
      "Mezua bidali dugu <green>${email}</green> helbidera";

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
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Utzi esteka duen jendeari ere album partekatuan argazkiak gehitzen."),
        "allowAddingPhotos":
            MessageLookupByLibrary.simpleMessage("Baimendu argazkiak gehitzea"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("Baimendu jaitsierak"),
        "apply": MessageLookupByLibrary.simpleMessage("Aplikatu"),
        "applyCodeTitle":
            MessageLookupByLibrary.simpleMessage("Aplikatu kodea"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "Zein da zure kontua ezabatzeko arrazoi nagusia?"),
        "canNotOpenBody": MessageLookupByLibrary.simpleMessage(
            "Sentitzen dugu, album hau ezin da aplikazioan ireki."),
        "canNotOpenTitle":
            MessageLookupByLibrary.simpleMessage("Ezin dut album hau ireki"),
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
        "claimMore": MessageLookupByLibrary.simpleMessage("Eskatu gehiago!"),
        "claimed": MessageLookupByLibrary.simpleMessage("Eskatuta"),
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("Kodea aplikatuta"),
        "codeChangeLimitReached": MessageLookupByLibrary.simpleMessage(
            "Sentitzen dugu, zure kode aldaketa muga gainditu duzu."),
        "codeCopiedToClipboard":
            MessageLookupByLibrary.simpleMessage("Kodea arbelean kopiatuta"),
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
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("Sortu kontu berria"),
        "createPublicLink":
            MessageLookupByLibrary.simpleMessage("Sortu esteka publikoa"),
        "custom": MessageLookupByLibrary.simpleMessage("Aukeran"),
        "decrypting": MessageLookupByLibrary.simpleMessage("Deszifratzen..."),
        "deleteAccount":
            MessageLookupByLibrary.simpleMessage("Ezabatu zure kontua"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "Sentitzen dugu zu joateaz. Mesedez, utziguzu zure feedbacka hobetzen laguntzeko."),
        "deleteAccountPermanentlyButton":
            MessageLookupByLibrary.simpleMessage("Ezabatu Kontua Betiko"),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "Mesedez, bidali e-mail bat <warning>account-deletion@ente.io</warning> helbidea zure erregistatutako helbidetik."),
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
        "details": MessageLookupByLibrary.simpleMessage("Detaileak"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Ikusleek pantaila-irudiak atera ahal dituzte, edo kanpoko tresnen bidez zure argazkien kopiak gorde"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Mesedez, ohartu"),
        "doThisLater": MessageLookupByLibrary.simpleMessage("Egin hau geroago"),
        "done": MessageLookupByLibrary.simpleMessage("Eginda"),
        "dropSupportEmail": m24,
        "email": MessageLookupByLibrary.simpleMessage("E-maila"),
        "emailAlreadyRegistered": MessageLookupByLibrary.simpleMessage(
            "Helbide hau badago erregistratuta lehendik."),
        "emailNoEnteAccount": m29,
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
        "feedback": MessageLookupByLibrary.simpleMessage("Feedbacka"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Ahaztu pasahitza"),
        "freeStorageOnReferralSuccess": m35,
        "generatingEncryptionKeys":
            MessageLookupByLibrary.simpleMessage("Zifratze giltzak sortzen..."),
        "howItWorks":
            MessageLookupByLibrary.simpleMessage("Nola funtzionatzen duen"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "Mesedez, eska iezaiozu ezarpenen landutako bere e-mail helbidean luze klikatzeko, eta egiaztatu gailu bietako IDak bat direla."),
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
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Mesedez, lagun gaitzazu informazio honekin"),
        "linkDeviceLimit": MessageLookupByLibrary.simpleMessage("Gailu muga"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Indarrean"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Iraungita"),
        "linkExpiresOn": m45,
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
        "manage": MessageLookupByLibrary.simpleMessage("Kudeatu"),
        "manageLink": MessageLookupByLibrary.simpleMessage("Kudeatu esteka"),
        "manageParticipants": MessageLookupByLibrary.simpleMessage("Kudeatu"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Ertaina"),
        "never": MessageLookupByLibrary.simpleMessage("Inoiz ez"),
        "noDeviceLimit": MessageLookupByLibrary.simpleMessage("Bat ere ez"),
        "noRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Berreskuratze giltzarik ez?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "Gure puntutik-puntura zifratze protokoloa dela eta, zure data ezin da deszifratu zure pasahitza edo berreskuratze giltzarik gabe"),
        "ok": MessageLookupByLibrary.simpleMessage("Ondo"),
        "onlyFamilyAdminCanChangeCode": m53,
        "oops": MessageLookupByLibrary.simpleMessage("Ai!"),
        "orPickAnExistingOne":
            MessageLookupByLibrary.simpleMessage("Edo aukeratu lehengo bat"),
        "password": MessageLookupByLibrary.simpleMessage("Pasahitza"),
        "passwordChangedSuccessfully":
            MessageLookupByLibrary.simpleMessage("Pasahitza zuzenki aldatuta"),
        "passwordLock":
            MessageLookupByLibrary.simpleMessage("Pasahitza blokeoa"),
        "passwordStrength": m55,
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Ezin dugu zure pasahitza gorde, beraz, ahazten baduzu, <underline>ezin dugu zure data deszifratu</underline>"),
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
        "remove": MessageLookupByLibrary.simpleMessage("Kendu"),
        "removeLink": MessageLookupByLibrary.simpleMessage("Ezabatu esteka"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Kendu parte hartzailea"),
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
        "shareMyVerificationID": m80,
        "shareTextConfirmOthersVerificationID": m81,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Jaitsi Ente argazkiak eta bideoak jatorrizko kalitatean errez partekatu ahal izateko \n\nhttps://ente.io"),
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
            "Partekatu Ente erabiltzen ez dutenekin"),
        "shareWithPeopleSectionTitle": m83,
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Sortu partekatutako eta parte hartzeko albumak beste Ente erabiltzaileekin, debaldeko planak dituztenak barne."),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "<u-terms>Zerbitzu baldintzak</u-terms> eta <u-policy>pribatutasun politikak</u-policy> onartzen ditut"),
        "someoneSharingAlbumsWithYouShouldSeeTheSameId":
            MessageLookupByLibrary.simpleMessage(
                "Zurekin albumak partekatzen dituen norbaitek ID berbera ikusi beharko luke bere gailuan."),
        "somethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Zerbait oker joan da"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Zerbait ez da ondo joan, mesedez, saiatu berriro"),
        "sorry": MessageLookupByLibrary.simpleMessage("Barkatu"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "Tamalez, ezin dugu giltza segururik sortu gailu honetan. \n\nMesedez, eman izena beste gailu batetik."),
        "storageInGB": m90,
        "strongStrength": MessageLookupByLibrary.simpleMessage("Gogorra"),
        "tapToCopy": MessageLookupByLibrary.simpleMessage("jo kopiatzeko"),
        "tapToEnterCode":
            MessageLookupByLibrary.simpleMessage("Klikatu kodea sartzeko"),
        "terminate": MessageLookupByLibrary.simpleMessage("Bukatu"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Saioa bukatu?"),
        "termsOfServicesTitle":
            MessageLookupByLibrary.simpleMessage("Baldintzak"),
        "theyAlsoGetXGb": m96,
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "Hau zure kontua berreskuratzeko erabili ahal duzu, zure bigarren faktorea ahaztuz gero"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Gailu hau"),
        "thisIsPersonVerificationId": m97,
        "thisIsYourVerificationId":
            MessageLookupByLibrary.simpleMessage("Hau da zure Egiaztatze IDa"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Hau egiteak hurrengo gailutik aterako zaitu:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Hau egiteak gailu honetatik aterako zaitu!"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "Zure pasahitza berrezartzeko, mesedez egiaztatu zure e-maila lehenengoz."),
        "tryAgain": MessageLookupByLibrary.simpleMessage("Saiatu berriro"),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage(
                "Faktore biko autentifikatzea"),
        "twofactorSetup":
            MessageLookupByLibrary.simpleMessage("Faktore biko ezarpena"),
        "unavailableReferralCode": MessageLookupByLibrary.simpleMessage(
            "Sentitzen dugu, kode hau ezin da erabili."),
        "useRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Erabili berreskuratze giltza"),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("Egiaztatze IDa"),
        "verify": MessageLookupByLibrary.simpleMessage("Egiaztatu"),
        "verifyEmail":
            MessageLookupByLibrary.simpleMessage("Egiaztatu e-maila"),
        "verifyEmailID": m108,
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Egiaztatu pasahitza"),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Berreskuratze giltza egiaztatuz..."),
        "viewRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Ikusi berreskuratze kodea"),
        "viewer": MessageLookupByLibrary.simpleMessage("Ikuslea"),
        "weHaveSendEmailTo": m110,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Ahula"),
        "welcomeBack":
            MessageLookupByLibrary.simpleMessage("Ongi etorri berriro!"),
        "yesConvertToViewer":
            MessageLookupByLibrary.simpleMessage("Bai, egin ikusle"),
        "you": MessageLookupByLibrary.simpleMessage("Zu"),
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("Zure kontua ezabatua izan da")
      };
}
