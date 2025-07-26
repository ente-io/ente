// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a hu locale. All the
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
  String get localeName => 'hu';

  static String m8(count) =>
      "${Intl.plural(count, zero: 'Nincsenek résztvevők', one: '1 résztvevő', other: '${count} résztvevők')}";

  static String m13(user) =>
      "${user} nem tud több fotót hozzáadni ehhez az albumhoz.\n\nTovábbra is el tudja távolítani az általa hozzáadott meglévő fotókat";

  static String m14(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true':
                'A családod eddig ${storageAmountInGb} GB tárhelyet igényelt',
            'false': 'Eddig ${storageAmountInGb} GB tárhelyet igényelt',
            'other': 'Eddig ${storageAmountInGb} GB tárhelyet igényelt!',
          })}";

  static String m21(count) =>
      "${Intl.plural(count, one: 'Elem ${count} törlése', other: 'Elemek ${count} törlése')}";

  static String m24(albumName) =>
      "Ez eltávolítja a(z) „${albumName}” eléréséhez szükséges nyilvános linket.";

  static String m25(supportEmail) =>
      "Kérjük küldjön egy e-mailt a fiók regisztrálásakor megadott címről a következőre címre: ${supportEmail}";

  static String m27(count, formattedSize) =>
      "${count} fájl, ${formattedSize} mindegyik";

  static String m31(email) =>
      "${email} címnek nincs Ente fiókja.\n\nKüldjön nekik meghívót fotók megosztására.";

  static String m37(storageAmountInGB) =>
      "${storageAmountInGB} GB minden alkalommal, amikor valaki fizetős csomagra fizet elő és felhasználja a kódodat";

  static String m44(count) =>
      "${Intl.plural(count, one: '${count} elem', other: '${count} elem')}";

  static String m47(expiryTime) => "Hivatkozás lejár ${expiryTime} ";

  static String m50(count, formattedCount) =>
      "${Intl.plural(count, zero: 'nincsenek emlékek', one: '${formattedCount} emlék', other: '${formattedCount} emlékek')}";

  static String m55(familyAdminEmail) =>
      "Kérjük, vegye fel a kapcsolatot a ${familyAdminEmail} e-mail címmel a kód módosításához.";

  static String m57(passwordStrengthValue) =>
      "Jelszó erőssége: ${passwordStrengthValue}";

  static String m73(storageInGB) =>
      "3. Mindketten ${storageInGB} GB* ingyenes tárhelyet kaptok";

  static String m74(userEmail) =>
      "${userEmail} felhasználó el lesz távolítva ebből a megosztott albumból\n\nAz általa hozzáadott összes fotó is eltávolításra kerül az albumból.";

  static String m80(count) => "${count} kiválasztott";

  static String m81(count, yourCount) =>
      "${count} kiválasztott (${yourCount} a tiéd)";

  static String m83(verificationID) =>
      "Itt az ellenőrző azonosítóm: ${verificationID} az ente.io-hoz.";

  static String m84(verificationID) =>
      "Szia, meg tudnád erősíteni, hogy ez az ente.io ellenőrző azonosítód? ${verificationID}";

  static String m85(referralCode, referralStorageInGB) =>
      "Add meg a következő ajánlási kódot: ${referralCode}\n\nAlkalmazd a Beállítások → Általános → Ajánlások menüpontban, hogy ${referralStorageInGB} GB ingyenes tárhelyet kapj, miután regisztráltál egy fizetős csomagra\n\nhttps://ente.io";

  static String m86(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Megosztás adott személyekkel', one: '1 személlyel megosztva', other: '${numberOfPeople} személlyel megosztva')}";

  static String m88(fileType) =>
      "Ez a ${fileType} fájl törlődni fog az eszközéről.";

  static String m89(fileType) =>
      "Ez a ${fileType} fájltípus megtalálható mind az Enterben, mind az eszközödön.";

  static String m90(fileType) => "Ez a ${fileType} fájl törlődik az Ente-ből.";

  static String m93(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m99(storageAmountInGB) =>
      "Emellett ${storageAmountInGB} GB-ot kapnak";

  static String m100(email) => "Ez ${email} ellenőrző azonosítója";

  static String m114(email) =>
      "E-mailt küldtünk a következő címre: <green>${email}</green>";

  static String m116(count) =>
      "${Intl.plural(count, one: '${count} évvel ezelőtt', other: '${count} évekkel ezelőtt')}";

  static String m118(storageSaved) =>
      "Sikeresen felszabadítottál ${storageSaved} tárhelyet!";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable": MessageLookupByLibrary.simpleMessage(
            "Megjelent az Ente új verziója."),
        "about": MessageLookupByLibrary.simpleMessage("Rólunk"),
        "account": MessageLookupByLibrary.simpleMessage("Fiók"),
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Köszöntjük ismét!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Tudomásul veszem, hogy ha elveszítem a jelszavamat, elveszíthetem az adataimat, mivel adataim <underline>végponttól végpontig titkosítva vannak</underline>."),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Bejelentkezések"),
        "addANewEmail":
            MessageLookupByLibrary.simpleMessage("Új email cím hozzáadása"),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Együttműködő hozzáadása"),
        "addMore": MessageLookupByLibrary.simpleMessage("További hozzáadása"),
        "addViewer": MessageLookupByLibrary.simpleMessage(
            "Megtekintésre jogosult hozzáadása"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Hozzáadva mint"),
        "addingToFavorites":
            MessageLookupByLibrary.simpleMessage("Hozzáadás a kedvencekhez..."),
        "advancedSettings": MessageLookupByLibrary.simpleMessage("Haladó"),
        "after1Day": MessageLookupByLibrary.simpleMessage("Egy nap mólva"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("Egy óra múlva"),
        "after1Month": MessageLookupByLibrary.simpleMessage("Egy hónap múlva"),
        "after1Week": MessageLookupByLibrary.simpleMessage("Egy hét múlva"),
        "after1Year": MessageLookupByLibrary.simpleMessage("Egy év múlva"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Tulajdonos"),
        "albumParticipantsCount": m8,
        "albumUpdated": MessageLookupByLibrary.simpleMessage("Album módosítva"),
        "albums": MessageLookupByLibrary.simpleMessage("Album"),
        "allClear": MessageLookupByLibrary.simpleMessage("✨ Minden tiszta"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Engedélyezd a linkkel rendelkező személyeknek, hogy ők is hozzáadhassanak fotókat a megosztott albumhoz."),
        "allowAddingPhotos": MessageLookupByLibrary.simpleMessage(
            "Fotók hozzáadásának engedélyezése"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("Letöltések engedélyezése"),
        "apply": MessageLookupByLibrary.simpleMessage("Alkalmaz"),
        "applyCodeTitle":
            MessageLookupByLibrary.simpleMessage("Kód alkalmazása"),
        "archive": MessageLookupByLibrary.simpleMessage("Archívum"),
        "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
            "Biztos benne, hogy kijelentkezik?"),
        "askDeleteReason":
            MessageLookupByLibrary.simpleMessage("Miért törli a fiókját?"),
        "authToChangeEmailVerificationSetting":
            MessageLookupByLibrary.simpleMessage(
                "Kérjük, hitelesítse magát az e-mail-cím ellenőrzésének módosításához"),
        "authToChangeYourEmail": MessageLookupByLibrary.simpleMessage(
            "Kérjük, hitelesítse magát az e-mail címének módosításához"),
        "authToChangeYourPassword": MessageLookupByLibrary.simpleMessage(
            "Kérjük, hitelesítse magát a jelszó módosításához"),
        "authToInitiateAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Kérjük, hitelesítse magát a fiók törlésének megkezdéséhez"),
        "authToViewTrashedFiles": MessageLookupByLibrary.simpleMessage(
            "Kérjük, hitelesítse magát a kukába helyezett fájlok megtekintéséhez"),
        "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
            "Kérjük, hitelesítse magát a rejtett fájlok megtekintéséhez"),
        "backedUpFolders": MessageLookupByLibrary.simpleMessage(
            "Biztonsági másolatban lévő mappák"),
        "backup": MessageLookupByLibrary.simpleMessage("Biztonsági mentés"),
        "backupOverMobileData": MessageLookupByLibrary.simpleMessage(
            "Biztonsági mentés mobil adatkapcsolaton keresztül"),
        "backupSettings": MessageLookupByLibrary.simpleMessage(
            "Biztonsági mentés beállításai"),
        "backupStatus":
            MessageLookupByLibrary.simpleMessage("Biztonsági mentés állapota"),
        "backupStatusDescription": MessageLookupByLibrary.simpleMessage(
            "Azok az elemek jelennek meg itt, amelyekről biztonsági másolat készült"),
        "backupVideos": MessageLookupByLibrary.simpleMessage("Tartalék videók"),
        "canNotOpenBody": MessageLookupByLibrary.simpleMessage(
            "Sajnálom, ez az album nem nyitható meg ebben az applikációban."),
        "canNotOpenTitle":
            MessageLookupByLibrary.simpleMessage("Album nem nyitható meg"),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "Csak a saját tulajdonú fájlokat távolíthatja el"),
        "cancel": MessageLookupByLibrary.simpleMessage("Mégse"),
        "cannotAddMorePhotosAfterBecomingViewer": m13,
        "cannotDeleteSharedFiles": MessageLookupByLibrary.simpleMessage(
            "Nem lehet törölni a megosztott fájlokat"),
        "change": MessageLookupByLibrary.simpleMessage("Módosítás"),
        "changeEmail":
            MessageLookupByLibrary.simpleMessage("E-mail cím módosítása"),
        "changePassword":
            MessageLookupByLibrary.simpleMessage("Jelszó megváltoztatása"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Jelszó megváltoztatása"),
        "changePermissions":
            MessageLookupByLibrary.simpleMessage("Engedélyek módosítása?"),
        "changeYourReferralCode":
            MessageLookupByLibrary.simpleMessage("Módosítsa ajánló kódját"),
        "checkForUpdates":
            MessageLookupByLibrary.simpleMessage("Frissítések ellenőrzése"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Kérjük, ellenőrizze beérkező leveleit (és spam mappát) az ellenőrzés befejezéséhez"),
        "checkStatus":
            MessageLookupByLibrary.simpleMessage("Állapot ellenőrzése"),
        "checking": MessageLookupByLibrary.simpleMessage("Ellenőrzés..."),
        "claimFreeStorage": MessageLookupByLibrary.simpleMessage(
            "Igényeljen ingyenes tárhelyet"),
        "claimMore": MessageLookupByLibrary.simpleMessage("Igényelj többet!"),
        "claimed": MessageLookupByLibrary.simpleMessage("Megszerezve!"),
        "claimedStorageSoFar": m14,
        "clearIndexes": MessageLookupByLibrary.simpleMessage("Indexek törlése"),
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("Kód alkalmazva"),
        "codeChangeLimitReached": MessageLookupByLibrary.simpleMessage(
            "Sajnáljuk, elérted a kódmódosítások maximális számát."),
        "codeCopiedToClipboard":
            MessageLookupByLibrary.simpleMessage("A kód a vágólapra másolva"),
        "codeUsedByYou":
            MessageLookupByLibrary.simpleMessage("Ön által használt kód"),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Hozzon létre egy hivatkozást, amely lehetővé teszi az emberek számára, hogy fotókat adhassanak hozzá és tekintsenek meg megosztott albumában anélkül, hogy Ente alkalmazásra vagy fiókra lenne szükségük. Kiválóan alkalmas rendezvényfotók gyűjtésére."),
        "collaborativeLink":
            MessageLookupByLibrary.simpleMessage("Együttműködési hivatkozás"),
        "collaborator": MessageLookupByLibrary.simpleMessage("Együttműködő"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Az együttműködők hozzá adhatnak fotókat és videókat a megosztott albumban."),
        "collectPhotos": MessageLookupByLibrary.simpleMessage("Fotók gyűjtése"),
        "confirm": MessageLookupByLibrary.simpleMessage("Megerősítés"),
        "confirmAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Felhasználó Törlés Megerősítés"),
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Igen, szeretném véglegesen törölni ezt a felhasználót, minden adattal, az összes platformon."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Jelszó megerősítés"),
        "confirmRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Helyreállítási kulcs megerősítése"),
        "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Erősítse meg helyreállítási kulcsát"),
        "contactSupport": MessageLookupByLibrary.simpleMessage(
            "Lépj kapcsolatba az Ügyfélszolgálattal"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("Folytatás"),
        "copyLink": MessageLookupByLibrary.simpleMessage("Hivatkozás másolása"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Kód Másolása-Beillesztése az ön autentikátor alkalmazásába"),
        "createAccount":
            MessageLookupByLibrary.simpleMessage("Felhasználó létrehozás"),
        "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
            "Hosszan nyomva tartva kiválaszthatod a fotókat, majd a + jelre kattintva albumot hozhatsz létre"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("Új felhasználó létrehozás"),
        "createPublicLink": MessageLookupByLibrary.simpleMessage(
            "Nyilvános hivatkozás létrehozása"),
        "creatingLink":
            MessageLookupByLibrary.simpleMessage("Link létrehozása..."),
        "criticalUpdateAvailable":
            MessageLookupByLibrary.simpleMessage("Kritikus frissítés elérhető"),
        "custom": MessageLookupByLibrary.simpleMessage("Egyéni"),
        "decrypting": MessageLookupByLibrary.simpleMessage("Dekódolás..."),
        "deleteAccount": MessageLookupByLibrary.simpleMessage("Fiók törlése"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "Sajnáljuk, hogy távozik. Kérjük, ossza meg velünk visszajelzéseit, hogy segítsen nekünk a fejlődésben."),
        "deleteAccountPermanentlyButton": MessageLookupByLibrary.simpleMessage(
            "Felhasználó Végleges Törlése"),
        "deleteAlbum": MessageLookupByLibrary.simpleMessage("Album törlése"),
        "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
            "Törli az ebben az albumban található fotókat (és videókat) az <bold>összes</bold> többi albumból is, amelynek részét képezik?"),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "Kérem küldjön egy emailt a regisztrált email címéről, erre az emailcímre: <warning>account-deletion@ente.io</warning>."),
        "deleteFromBoth":
            MessageLookupByLibrary.simpleMessage("Törlés mindkettőből"),
        "deleteFromDevice":
            MessageLookupByLibrary.simpleMessage("Törlés az eszközről"),
        "deleteFromEnte":
            MessageLookupByLibrary.simpleMessage("Törlés az Ente-ből"),
        "deleteItemCount": m21,
        "deletePhotos": MessageLookupByLibrary.simpleMessage("Fotók törlése"),
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "Hiányoznak olyan funkciók, amikre szükségem lenne"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "Az applikáció vagy egy adott funkció nem úgy működik ahogy kellene"),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
            "Találtam egy jobb szolgáltatót"),
        "deleteReason4":
            MessageLookupByLibrary.simpleMessage("Nincs a listán az ok"),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
            "A kérése 72 órán belül feldolgozásra kerül."),
        "deleteSharedAlbum":
            MessageLookupByLibrary.simpleMessage("Törli a megosztott albumot?"),
        "deleteSharedAlbumDialogBody": MessageLookupByLibrary.simpleMessage(
            "Az album mindenki számára törlődik.\n\nElveszíti a hozzáférést az albumban található, mások tulajdonában lévő megosztott fotókhoz."),
        "details": MessageLookupByLibrary.simpleMessage("Részletek"),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
            "Disable the device screen lock when Ente is in the foreground and there is a backup in progress. This is normally not needed, but may help big uploads and initial imports of large libraries complete faster."),
        "disableAutoLock":
            MessageLookupByLibrary.simpleMessage("Automatikus zár letiltása"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "A nézők továbbra is készíthetnek képernyőképeket, vagy menthetnek másolatot a fotóidról külső eszközök segítségével"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Kérjük, vedd figyelembe"),
        "disableLinkMessage": m24,
        "discover": MessageLookupByLibrary.simpleMessage("Felfedezés"),
        "discover_babies": MessageLookupByLibrary.simpleMessage("Babák"),
        "discover_celebrations":
            MessageLookupByLibrary.simpleMessage("Ünnepségek"),
        "discover_food": MessageLookupByLibrary.simpleMessage("Étel"),
        "discover_greenery": MessageLookupByLibrary.simpleMessage("Lomb"),
        "discover_hills": MessageLookupByLibrary.simpleMessage("Dombok"),
        "discover_identity":
            MessageLookupByLibrary.simpleMessage("Személyazonosság"),
        "discover_memes": MessageLookupByLibrary.simpleMessage("Mémek"),
        "discover_notes": MessageLookupByLibrary.simpleMessage("Jegyzetek"),
        "discover_pets": MessageLookupByLibrary.simpleMessage("Kisállatok"),
        "discover_receipts": MessageLookupByLibrary.simpleMessage("Nyugták"),
        "discover_screenshots":
            MessageLookupByLibrary.simpleMessage("Képernyőképek"),
        "discover_selfies": MessageLookupByLibrary.simpleMessage("Szelfik"),
        "discover_sunset": MessageLookupByLibrary.simpleMessage("Napnyugta"),
        "discover_visiting_cards":
            MessageLookupByLibrary.simpleMessage("Névjegykártyák"),
        "discover_wallpapers":
            MessageLookupByLibrary.simpleMessage("Háttérképek"),
        "doThisLater": MessageLookupByLibrary.simpleMessage("Később"),
        "done": MessageLookupByLibrary.simpleMessage("Kész"),
        "downloading": MessageLookupByLibrary.simpleMessage("Letöltés..."),
        "dropSupportEmail": m25,
        "duplicateItemsGroup": m27,
        "eligible": MessageLookupByLibrary.simpleMessage("jogosult"),
        "email": MessageLookupByLibrary.simpleMessage("E-mail"),
        "emailAlreadyRegistered":
            MessageLookupByLibrary.simpleMessage("Az email cím már foglalt."),
        "emailNoEnteAccount": m31,
        "emailNotRegistered":
            MessageLookupByLibrary.simpleMessage("Nem regisztrált email cím."),
        "emailVerificationToggle":
            MessageLookupByLibrary.simpleMessage("E-mail cím ellenőrzése"),
        "encryption": MessageLookupByLibrary.simpleMessage("Titkosítás"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Titkosító kulcsok"),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
            "Az Entének <i>engedélyre van szüksége </i>, hogy tárolhassa fotóit"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Kód beírása"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
            "Add meg a barátod által megadott kódot, hogy mindkettőtöknek ingyenes tárhelyet igényelhess"),
        "enterEmail": MessageLookupByLibrary.simpleMessage("Email megadása"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Adjon meg egy új jelszót, amellyel titkosíthatjuk adatait"),
        "enterPassword":
            MessageLookupByLibrary.simpleMessage("Adja meg a jelszót"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Adjon meg egy jelszót, amellyel titkosíthatjuk adatait"),
        "enterReferralCode":
            MessageLookupByLibrary.simpleMessage("Adja meg az ajánló kódot"),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Írja be a 6 számjegyű kódot a hitelesítő alkalmazásból"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "Kérjük, adjon meg egy érvényes e-mail címet."),
        "enterYourEmailAddress":
            MessageLookupByLibrary.simpleMessage("Adja meg az e-mail címét"),
        "enterYourNewEmailAddress":
            MessageLookupByLibrary.simpleMessage("Add meg az új email címed"),
        "enterYourPassword":
            MessageLookupByLibrary.simpleMessage("Adja meg a jelszavát"),
        "enterYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Adja meg visszaállítási kulcsát"),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
            "Ez a link lejárt. Kérjük, válasszon új lejárati időt, vagy tiltsa le a link lejáratát."),
        "exportYourData":
            MessageLookupByLibrary.simpleMessage("Adatok exportálása"),
        "failedToApplyCode": MessageLookupByLibrary.simpleMessage(
            "Nem sikerült alkalmazni a kódot"),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "Nem sikerült lekérni a hivatkozási adatokat. Kérjük, próbálja meg később."),
        "failedToLoadAlbums": MessageLookupByLibrary.simpleMessage(
            "Nem sikerült betölteni az albumokat"),
        "faq": MessageLookupByLibrary.simpleMessage("GY. I. K."),
        "feedback": MessageLookupByLibrary.simpleMessage("Visszajelzés"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Elfelejtett jelszó"),
        "freeStorageClaimed":
            MessageLookupByLibrary.simpleMessage("Ingyenes tárhely igénylése"),
        "freeStorageOnReferralSuccess": m37,
        "freeStorageUsable": MessageLookupByLibrary.simpleMessage(
            "Ingyenesen használható tárhely"),
        "freeUpDeviceSpace":
            MessageLookupByLibrary.simpleMessage("Szabadítson fel tárhelyet"),
        "freeUpDeviceSpaceDesc": MessageLookupByLibrary.simpleMessage(
            "Takarítson meg helyet az eszközén a már mentett fájlok törlésével."),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Titkosítási kulcs generálása..."),
        "help": MessageLookupByLibrary.simpleMessage("Segítség"),
        "hidden": MessageLookupByLibrary.simpleMessage("Rejtett"),
        "howItWorks": MessageLookupByLibrary.simpleMessage("Hogyan működik"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "Kérje meg őket, hogy hosszan nyomják meg az e-mail címüket a beállítások képernyőn, és ellenőrizzék, hogy a két eszköz azonosítója megegyezik-e."),
        "ignoreUpdate":
            MessageLookupByLibrary.simpleMessage("Figyelem kívül hagyás"),
        "importing": MessageLookupByLibrary.simpleMessage("Importálás..."),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Érvénytelen jelszó"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "A megadott visszaállítási kulcs hibás"),
        "incorrectRecoveryKeyTitle":
            MessageLookupByLibrary.simpleMessage("Hibás visszaállítási kulcs"),
        "indexedItems": MessageLookupByLibrary.simpleMessage("Indexelt elemek"),
        "insecureDevice":
            MessageLookupByLibrary.simpleMessage("Nem biztonságos eszköz"),
        "installManually":
            MessageLookupByLibrary.simpleMessage("Manuális telepítés"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("Érvénytelen e-mail cím"),
        "invalidKey": MessageLookupByLibrary.simpleMessage("Érvénytelen kulcs"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "A megadott helyreállítási kulcs érvénytelen. Kérjük, győződjön meg róla, hogy 24 szót tartalmaz, és ellenőrizze mindegyik helyesírását.\n\nHa régebbi helyreállítási kódot adott meg, győződjön meg arról, hogy az 64 karakter hosszú, és ellenőrizze mindegyiket."),
        "inviteToEnte":
            MessageLookupByLibrary.simpleMessage("Meghívás az Ente-re"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Hívd meg a barátaidat"),
        "itemCount": m44,
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "A kiválasztott elemek eltávolításra kerülnek ebből az albumból."),
        "keepPhotos": MessageLookupByLibrary.simpleMessage("Fotók megőrzése"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Legyen kedves segítsen, ezzel az információval"),
        "linkDeviceLimit":
            MessageLookupByLibrary.simpleMessage("Készülékkorlát"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Engedélyezett"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Lejárt"),
        "linkExpiresOn": m47,
        "linkExpiry": MessageLookupByLibrary.simpleMessage("Link lejárata"),
        "linkHasExpired": MessageLookupByLibrary.simpleMessage(
            "A hivatkozás érvényességi ideje lejárt"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Soha"),
        "loadingModel":
            MessageLookupByLibrary.simpleMessage("Modellek letöltése..."),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Zárolás"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Bejelentkezés"),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "A bejelentkezés gombra kattintva elfogadom az <u-terms>szolgáltatási feltételeket</u-terms> és az <u-policy>adatvédelmi irányelveket</u-policy>"),
        "logout": MessageLookupByLibrary.simpleMessage("Kijelentkezés"),
        "lostDevice":
            MessageLookupByLibrary.simpleMessage("Elveszett a készüléked?"),
        "machineLearning": MessageLookupByLibrary.simpleMessage("Gépi tanulás"),
        "magicSearch":
            MessageLookupByLibrary.simpleMessage("Varázslatos keresés"),
        "manage": MessageLookupByLibrary.simpleMessage("Kezelés"),
        "manageDeviceStorage": MessageLookupByLibrary.simpleMessage(
            "Eszköz gyorsítótárának kezelése"),
        "manageDeviceStorageDesc": MessageLookupByLibrary.simpleMessage(
            "Tekintse át és törölje a helyi gyorsítótárat."),
        "manageLink":
            MessageLookupByLibrary.simpleMessage("Hivatkozás kezelése"),
        "manageParticipants": MessageLookupByLibrary.simpleMessage("Kezelés"),
        "manageSubscription":
            MessageLookupByLibrary.simpleMessage("Előfizetés kezelése"),
        "memoryCount": m50,
        "mlConsent":
            MessageLookupByLibrary.simpleMessage("Gépi tanulás engedélyezése"),
        "mlConsentConfirmation": MessageLookupByLibrary.simpleMessage(
            "Értem, és szeretném engedélyezni a gépi tanulást"),
        "mlConsentDescription": MessageLookupByLibrary.simpleMessage(
            "Ha engedélyezi a gépi tanulást, az Ente olyan információkat fog kinyerni, mint az arc geometriája, a fájlokból, beleértve azokat is, amelyeket Önnel megosztott.\n\nEz az Ön eszközén fog megtörténni, és minden generált biometrikus információ végponttól végpontig titkosítva lesz."),
        "mlConsentPrivacy": MessageLookupByLibrary.simpleMessage(
            "Kérjük, kattintson ide az adatvédelmi irányelveinkben található további részletekért erről a funkcióról."),
        "mlConsentTitle": MessageLookupByLibrary.simpleMessage(
            "Engedélyezi a gépi tanulást?"),
        "mlIndexingDescription": MessageLookupByLibrary.simpleMessage(
            "Kérjük, vegye figyelembe, hogy a gépi tanulás nagyobb sávszélességet és akkumulátorhasználatot eredményez, amíg az összes elem indexelése meg nem történik. A gyorsabb indexelés érdekében érdemes lehet asztali alkalmazást használni, mivel minden eredmény automatikusan szinkronizálódik."),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Közepes"),
        "movedToTrash":
            MessageLookupByLibrary.simpleMessage("Áthelyezve a kukába"),
        "never": MessageLookupByLibrary.simpleMessage("Soha"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Új album"),
        "noDeviceLimit": MessageLookupByLibrary.simpleMessage("Egyik sem"),
        "noDeviceThatCanBeDeleted": MessageLookupByLibrary.simpleMessage(
            "Nincsenek törölhető fájlok ezen az eszközön."),
        "noDuplicates":
            MessageLookupByLibrary.simpleMessage("✨ Nincsenek duplikátumok"),
        "noRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Nincs visszaállítási kulcsa?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "Az általunk használt végpontok közötti titkosítás miatt, az adatait nem lehet dekódolni a jelszava, vagy visszaállítási kulcsa nélkül"),
        "ok": MessageLookupByLibrary.simpleMessage("Rendben"),
        "onlyFamilyAdminCanChangeCode": m55,
        "oops": MessageLookupByLibrary.simpleMessage("Hoppá"),
        "oopsSomethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Hoppá, valami hiba történt"),
        "orPickAnExistingOne":
            MessageLookupByLibrary.simpleMessage("Vagy válasszon egy létezőt"),
        "password": MessageLookupByLibrary.simpleMessage("Jelszó"),
        "passwordChangedSuccessfully":
            MessageLookupByLibrary.simpleMessage("Jelszó módosítása sikeres!"),
        "passwordLock":
            MessageLookupByLibrary.simpleMessage("Kóddal történő lezárás"),
        "passwordStrength": m57,
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Ezt a jelszót nem tároljuk, így ha elfelejti, <underline>nem tudjuk visszafejteni adatait</underline>"),
        "pendingItems":
            MessageLookupByLibrary.simpleMessage("függőben lévő elemek"),
        "peopleUsingYourCode": MessageLookupByLibrary.simpleMessage(
            "Az emberek, akik a kódodat használják"),
        "photoGridSize":
            MessageLookupByLibrary.simpleMessage("Rács méret beállátás"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("fénykép"),
        "pleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("Kérjük, próbálja meg újra"),
        "pleaseWait": MessageLookupByLibrary.simpleMessage("Kérem várjon..."),
        "privacy": MessageLookupByLibrary.simpleMessage("Adatvédelem"),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Adatvédelmi irányelvek"),
        "publicLinkEnabled": MessageLookupByLibrary.simpleMessage(
            "Nyilvános hivatkozás engedélyezve"),
        "rateUs": MessageLookupByLibrary.simpleMessage("Értékeljen minket"),
        "recover": MessageLookupByLibrary.simpleMessage("Visszaállít"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("Fiók visszaállítása"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Visszaállít"),
        "recoveryKey":
            MessageLookupByLibrary.simpleMessage("Visszaállítási kulcs"),
        "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "A helyreállítási kulcs a vágólapra másolva"),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
            "Ha elfelejti jelszavát, csak ezzel a kulccsal tudja visszaállítani adatait."),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
            "Ezt a kulcsot nem tároljuk, kérjük, őrizze meg ezt a 24 szavas kulcsot egy biztonságos helyen."),
        "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
            "Nagyszerű! A helyreállítási kulcs érvényes. Köszönjük az igazolást.\n\nNe felejtsen el biztonsági másolatot készíteni helyreállítási kulcsáról."),
        "recoveryKeyVerified": MessageLookupByLibrary.simpleMessage(
            "A helyreállítási kulcs ellenőrizve"),
        "recoveryKeyVerifyReason": MessageLookupByLibrary.simpleMessage(
            "A helyreállítási kulcs az egyetlen módja annak, hogy visszaállítsa fényképeit, ha elfelejti jelszavát. A helyreállítási kulcsot a Beállítások > Fiók menüpontban találhatja meg.\n\nKérjük, írja be ide helyreállítási kulcsát annak ellenőrzéséhez, hogy megfelelően mentette-e el."),
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("Sikeres visszaállítás!"),
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "A jelenlegi eszköz nem elég erős a jelszavának ellenőrzéséhez, de újra tudjuk úgy generálni, hogy az minden eszközzel működjön.\n\nKérjük, jelentkezzen be helyreállítási kulcsával, és állítsa be újra jelszavát (ha szeretné, újra használhatja ugyanazt)."),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Új jelszó létrehozása"),
        "referralStep1": MessageLookupByLibrary.simpleMessage(
            "1. Add meg ezt a kódot a barátaidnak"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "2. Fizetős csomagra fizetnek elő"),
        "referralStep3": m73,
        "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
            "Az ajánlások jelenleg szünetelnek"),
        "remindToEmptyDeviceTrash": MessageLookupByLibrary.simpleMessage(
            "A felszabadult hely igényléséhez ürítsd ki a „Nemrég törölt” részt a „Beállítások” -> „Tárhely” menüpontban."),
        "remindToEmptyEnteTrash": MessageLookupByLibrary.simpleMessage(
            "Ürítsd ki a \"Kukát\" is, hogy visszaszerezd a felszabadult helyet."),
        "remove": MessageLookupByLibrary.simpleMessage("Eltávolítás"),
        "removeDuplicates": MessageLookupByLibrary.simpleMessage(
            "Távolítsa el a duplikációkat"),
        "removeDuplicatesDesc": MessageLookupByLibrary.simpleMessage(
            "Tekintse át és távolítsa el a pontos másolatokat tartalmazó fájlokat."),
        "removeFromAlbum":
            MessageLookupByLibrary.simpleMessage("Eltávolítás az albumból"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("Eltávolítás az albumból?"),
        "removeLink":
            MessageLookupByLibrary.simpleMessage("Hivatkozás eltávolítása"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Résztvevő eltávolítása"),
        "removeParticipantBody": m74,
        "removePublicLink": MessageLookupByLibrary.simpleMessage(
            "Nyilvános hivatkozás eltávolítása"),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
            "Néhány eltávolítandó elemet mások adtak hozzá, és elveszíted a hozzáférésedet hozzájuk."),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Eltávolítás?"),
        "removingFromFavorites": MessageLookupByLibrary.simpleMessage(
            "Eltávolítás a kedvencek közül..."),
        "resendEmail":
            MessageLookupByLibrary.simpleMessage("E-mail újraküldése"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Jelszó visszaállítása"),
        "retry": MessageLookupByLibrary.simpleMessage("Újrapróbálkozás"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Mentés"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Mentse el visszaállítási kulcsát, ha még nem tette"),
        "scanCode": MessageLookupByLibrary.simpleMessage("Kód beolvasása"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Olvassa le ezt a QR kódot az autentikátor alkalmazásával"),
        "selectAll": MessageLookupByLibrary.simpleMessage("Összes kijelölése"),
        "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
            "Mappák kiválasztása biztonsági mentéshez"),
        "selectReason": MessageLookupByLibrary.simpleMessage("Válasszon okot"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "A kiválasztott mappák titkosítva lesznek, és biztonsági másolat készül róluk."),
        "selectedPhotos": m80,
        "selectedPhotosWithYours": m81,
        "sendEmail": MessageLookupByLibrary.simpleMessage("Email küldése"),
        "sendInvite": MessageLookupByLibrary.simpleMessage("Meghívó küldése"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Hivatkozás küldése"),
        "setAPassword":
            MessageLookupByLibrary.simpleMessage("Állítson be egy jelszót"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Jelszó beállítás"),
        "setupComplete": MessageLookupByLibrary.simpleMessage("Beállítás kész"),
        "shareALink":
            MessageLookupByLibrary.simpleMessage("Hivatkozás megosztása"),
        "shareMyVerificationID": m83,
        "shareTextConfirmOthersVerificationID": m84,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Töltsd le az Ente-t, hogy könnyen megoszthassunk eredeti minőségű fotókat és videókat\n\nhttps://ente.io"),
        "shareTextReferralCode": m85,
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
            "Megosztás nem Ente felhasználókkal"),
        "shareWithPeopleSectionTitle": m86,
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Hozzon létre megosztott és együttműködő albumokat más Ente-felhasználókkal, beleértve az ingyenes csomagokat használó felhasználókat is."),
        "sharing": MessageLookupByLibrary.simpleMessage("Megosztás..."),
        "showMemories":
            MessageLookupByLibrary.simpleMessage("Emlékek megjelenítése"),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "Elfogadom az <u-terms>szolgáltatási feltételeket</u-terms> és az <u-policy>adatvédelmi irányelveket</u-policy>"),
        "singleFileDeleteFromDevice": m88,
        "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
            "Az összes albumból törlésre kerül."),
        "singleFileInBothLocalAndRemote": m89,
        "singleFileInRemoteOnly": m90,
        "skip": MessageLookupByLibrary.simpleMessage("Kihagyás"),
        "someoneSharingAlbumsWithYouShouldSeeTheSameId":
            MessageLookupByLibrary.simpleMessage(
                "Valaki, aki megoszt Önnel albumokat, ugyanazt az azonosítót fogja látni az eszközén."),
        "somethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Valami hiba történt"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Valami félre sikerült, próbálja újból"),
        "sorry": MessageLookupByLibrary.simpleMessage("Sajnálom"),
        "sorryCouldNotAddToFavorites": MessageLookupByLibrary.simpleMessage(
            "Sajnálom, nem sikerült hozzáadni a kedvencekhez!"),
        "sorryCouldNotRemoveFromFavorites":
            MessageLookupByLibrary.simpleMessage(
                "Sajnálom, nem sikerült eltávolítani a kedvencek közül!"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "Sajnáljuk, nem tudtunk biztonságos kulcsokat generálni ezen az eszközön.\n\nkérjük, regisztráljon egy másik eszközről."),
        "status": MessageLookupByLibrary.simpleMessage("Állapot"),
        "storageInGB": m93,
        "strongStrength": MessageLookupByLibrary.simpleMessage("Erős"),
        "subscribe": MessageLookupByLibrary.simpleMessage("Előfizetés"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "A megosztás engedélyezéséhez aktív fizetős előfizetésre van szükség."),
        "success": MessageLookupByLibrary.simpleMessage("Sikeres"),
        "tapToCopy":
            MessageLookupByLibrary.simpleMessage("érintse meg másoláshoz"),
        "tapToEnterCode":
            MessageLookupByLibrary.simpleMessage("Koppintson a kód beírásához"),
        "terminate": MessageLookupByLibrary.simpleMessage("Megszakít"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Megszakítja bejelentkezést?"),
        "terms": MessageLookupByLibrary.simpleMessage("Feltételek"),
        "termsOfServicesTitle":
            MessageLookupByLibrary.simpleMessage("Használati feltételek"),
        "theDownloadCouldNotBeCompleted":
            MessageLookupByLibrary.simpleMessage("A letöltés nem fejezhető be"),
        "theyAlsoGetXGb": m99,
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "Ezzel tudja visszaállítani felhasználóját ha elveszítené a kétlépcsős azonosítóját"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Ez az eszköz"),
        "thisIsPersonVerificationId": m100,
        "thisIsYourVerificationId":
            MessageLookupByLibrary.simpleMessage("Ez az ellenőrző azonosítód"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Ezzel kijelentkezik az alábbi eszközről:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Ezzel kijelentkezik az eszközről!"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "A Jelszó visszaállításához, kérjük először erősítse meg emailcímét."),
        "total": MessageLookupByLibrary.simpleMessage("összesen"),
        "trash": MessageLookupByLibrary.simpleMessage("Kuka"),
        "tryAgain": MessageLookupByLibrary.simpleMessage("Próbáld újra"),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage(
                "Kétlépcsős hitelesítés (2FA)"),
        "twofactorSetup": MessageLookupByLibrary.simpleMessage(
            "Kétlépcsős azonosító beállítás"),
        "unavailableReferralCode": MessageLookupByLibrary.simpleMessage(
            "Sajnáljuk, ez a kód nem érhető el."),
        "uncategorized":
            MessageLookupByLibrary.simpleMessage("Kategorizálatlan"),
        "unselectAll":
            MessageLookupByLibrary.simpleMessage("Összes kijelölés törlése"),
        "update": MessageLookupByLibrary.simpleMessage("Frissítés"),
        "updateAvailable":
            MessageLookupByLibrary.simpleMessage("Elérhető frissítés"),
        "updatingFolderSelection": MessageLookupByLibrary.simpleMessage(
            "Mappakijelölés frissítése..."),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "A felhasználható tárhelyet a jelenlegi előfizetése korlátozza. A feleslegesen igényelt tárhely automatikusan felhasználhatóvá válik, amikor frissítesz a csomagodra."),
        "useRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Helyreállítási kulcs használata"),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("Ellenőrző azonosító"),
        "verify": MessageLookupByLibrary.simpleMessage("Hitelesítés"),
        "verifyEmail":
            MessageLookupByLibrary.simpleMessage("Emailcím megerősítés"),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Jelszó megerősítése"),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Helyreállítási kulcs ellenőrzése..."),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("videó"),
        "viewLargeFiles": MessageLookupByLibrary.simpleMessage("Nagy fájlok"),
        "viewLargeFilesDesc": MessageLookupByLibrary.simpleMessage(
            "Tekintse meg a legtöbb tárhelyet foglaló fájlokat."),
        "viewRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Helyreállítási kulcs megtekintése"),
        "viewer": MessageLookupByLibrary.simpleMessage("Néző"),
        "waitingForWifi":
            MessageLookupByLibrary.simpleMessage("Várakozás a WiFi-re..."),
        "weAreOpenSource":
            MessageLookupByLibrary.simpleMessage("Nyílt forráskódúak vagyunk!"),
        "weHaveSendEmailTo": m114,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Gyenge"),
        "welcomeBack":
            MessageLookupByLibrary.simpleMessage("Köszöntjük ismét!"),
        "yearsAgo": m116,
        "yesConvertToViewer":
            MessageLookupByLibrary.simpleMessage("Igen, alakítsa nézővé"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("Igen, törlés"),
        "yesLogout":
            MessageLookupByLibrary.simpleMessage("Igen, kijelentkezés"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("Igen, eltávolítás"),
        "you": MessageLookupByLibrary.simpleMessage("Te"),
        "youAreOnTheLatestVersion": MessageLookupByLibrary.simpleMessage(
            "Ön a legújabb verziót használja"),
        "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "* Maximum megduplázhatod a tárhelyed"),
        "youCannotShareWithYourself":
            MessageLookupByLibrary.simpleMessage("Nem oszthatod meg magaddal"),
        "youHaveSuccessfullyFreedUp": m118,
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("A felhasználód törlődött"),
        "youveNoDuplicateFilesThatCanBeCleared":
            MessageLookupByLibrary.simpleMessage(
                "Nincsenek törölhető duplikált fájljaid")
      };
}
