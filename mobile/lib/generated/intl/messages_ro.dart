// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ro locale. All the
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
  String get localeName => 'ro';

  static String m6(count) =>
      "${Intl.plural(count, one: 'Adăugați observator', few: 'Adăugați observatori', other: 'Adăugați observatori')}";

  static String m9(count) =>
      "${Intl.plural(count, zero: 'Fără participanți', one: 'Un participant', few: '${count} participanți', other: '${count} de participanți')}";

  static String m13(user) =>
      "${user} nu va putea să mai adauge fotografii la acest album\n\nVa putea să elimine fotografii existente adăugate de el/ea";

  static String m14(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true':
                'Familia dvs. a revendicat ${storageAmountInGb} GB până acum',
            'false': 'Ați revendicat ${storageAmountInGb} GB până acum',
            'other': 'Ați revendicat ${storageAmountInGb} de GB până acum!',
          })}";

  static String m19(count) =>
      "${Intl.plural(count, one: 'Ștergeți ${count} articol', few: 'Ștergeți ${count} articole', other: 'Ștergeți ${count} de articole')}";

  static String m22(supportEmail) =>
      "Vă rugăm să trimiteți un e-mail la ${supportEmail} de pe adresa de e-mail înregistrată";

  static String m24(count, formattedSize) =>
      "${count} fișiere, ${formattedSize} fiecare";

  static String m26(email) =>
      "${email} nu are un cont Ente.\n\nTrimiteți-le o invitație pentru a distribui fotografii.";

  static String m29(storageAmountInGB) =>
      "${storageAmountInGB} GB de fiecare dată când cineva se înscrie pentru un plan plătit și aplică codul dvs.";

  static String m35(count) =>
      "${Intl.plural(count, one: '${count} articol', few: '${count} articole', other: '${count} de articole')}";

  static String m36(expiryTime) => "Linkul va expira pe ${expiryTime}";

  static String m40(familyAdminEmail) =>
      "Vă rugăm să contactați ${familyAdminEmail} pentru a vă schimba codul.";

  static String m41(passwordStrengthValue) =>
      "Complexitatea parolei: ${passwordStrengthValue}";

  static String m48(storageInGB) =>
      "3. Amândoi primiți ${storageInGB} GB* gratuit";

  static String m53(verificationID) =>
      "Acesta este ID-ul meu de verificare: ${verificationID} pentru ente.io.";

  static String m2(verificationID) =>
      "Poți confirma că acesta este ID-ul tău de verificare ente.io: ${verificationID}";

  static String m54(referralCode, referralStorageInGB) =>
      "Codul de recomandare Ente: ${referralCode}\n\nAplică-l în Setări → General → Recomandări pentru a obține ${referralStorageInGB} GB gratuit după ce te înscrii pentru un plan plătit\n\nhttps://ente.io";

  static String m55(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Distribuiți cu anumite persoane', one: 'Distribuit cu o persoană', few: 'Distribuit cu ${numberOfPeople} persoane', other: 'Distribuit cu ${numberOfPeople} de persoane')}";

  static String m60(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m65(storageAmountInGB) =>
      "De asemenea, va primii ${storageAmountInGB} GB";

  static String m66(email) => "Acesta este ID-ul de verificare al ${email}";

  static String m70(email) => "Verificare ${email}";

  static String m71(email) => "Am trimis un e-mail la <green>${email}</green>";

  static String m72(count) =>
      "${Intl.plural(count, one: 'acum ${count} an', few: 'acum ${count} ani', other: 'acum ${count} de ani')}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "about": MessageLookupByLibrary.simpleMessage("Despre"),
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Bine ați revenit!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Înțeleg că dacă îmi pierd parola, îmi pot pierde datele, deoarece datele mele sunt <underline>criptate integral</underline>."),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Sesiuni active"),
        "addANewEmail":
            MessageLookupByLibrary.simpleMessage("Adăugați un e-mail nou"),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Adăugare colaborator"),
        "addMore": MessageLookupByLibrary.simpleMessage("Adăugați mai mulți"),
        "addViewer":
            MessageLookupByLibrary.simpleMessage("Adăugare observator"),
        "addViewers": m6,
        "addedAs": MessageLookupByLibrary.simpleMessage("Adăugat ca"),
        "addingToFavorites":
            MessageLookupByLibrary.simpleMessage("Se adaugă la favorite..."),
        "advanced": MessageLookupByLibrary.simpleMessage("Avansat"),
        "after1Day": MessageLookupByLibrary.simpleMessage("După o zi"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("După o oră"),
        "after1Month": MessageLookupByLibrary.simpleMessage("După o lună"),
        "after1Week": MessageLookupByLibrary.simpleMessage("După o săptămâna"),
        "after1Year": MessageLookupByLibrary.simpleMessage("După un an"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Proprietar"),
        "albumParticipantsCount": m9,
        "albumUpdated":
            MessageLookupByLibrary.simpleMessage("Album actualizat"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Permiteți persoanelor care au linkul să adauge și fotografii la albumul distribuit."),
        "allowAddingPhotos": MessageLookupByLibrary.simpleMessage(
            "Permiteți adăugarea fotografiilor"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("Permiteți descărcările"),
        "apply": MessageLookupByLibrary.simpleMessage("Aplicare"),
        "applyCodeTitle":
            MessageLookupByLibrary.simpleMessage("Aplicați codul"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "Care este principalul motiv pentru care vă ștergeți contul?"),
        "authToConfigureTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Vă rugăm să vă autentificați pentru a configura autentificarea cu doi factori"),
        "authToViewYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Vă rugăm să vă autentificați pentru a vedea cheia de recuperare"),
        "backupOverMobileData": MessageLookupByLibrary.simpleMessage(
            "Efectuare copie de rezervă prin date mobile"),
        "backupSettings":
            MessageLookupByLibrary.simpleMessage("Setări copie de rezervă"),
        "backupStatus":
            MessageLookupByLibrary.simpleMessage("Stare copie de rezervă"),
        "backupStatusDescription": MessageLookupByLibrary.simpleMessage(
            "Articolele care au fost salvate vor apărea aici"),
        "backupVideos": MessageLookupByLibrary.simpleMessage(
            "Copie de rezervă videoclipuri"),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "Puteți elimina numai fișierele deținute de dvs."),
        "cancel": MessageLookupByLibrary.simpleMessage("Anulare"),
        "cannotAddMorePhotosAfterBecomingViewer": m13,
        "change": MessageLookupByLibrary.simpleMessage("Schimbați"),
        "changeEmail":
            MessageLookupByLibrary.simpleMessage("Schimbați e-mailul"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Schimbați parola"),
        "changePermissions":
            MessageLookupByLibrary.simpleMessage("Schimbați permisiunile?"),
        "changeYourReferralCode": MessageLookupByLibrary.simpleMessage(
            "Schimbați codul dvs. de recomandare"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Vă rugăm să verificaţi inbox-ul (şi spam) pentru a finaliza verificarea"),
        "claimFreeStorage":
            MessageLookupByLibrary.simpleMessage("Revendică spațiul gratuit"),
        "claimMore":
            MessageLookupByLibrary.simpleMessage("Revendicați mai multe!"),
        "claimed": MessageLookupByLibrary.simpleMessage("Revendicat"),
        "claimedStorageSoFar": m14,
        "clearIndexes":
            MessageLookupByLibrary.simpleMessage("Ștergeți indexul"),
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("Cod aplicat"),
        "codeChangeLimitReached": MessageLookupByLibrary.simpleMessage(
            "Ne pare rău, ați atins limita de modificări ale codului."),
        "codeCopiedToClipboard":
            MessageLookupByLibrary.simpleMessage("Cod copiat în clipboard"),
        "codeUsedByYou":
            MessageLookupByLibrary.simpleMessage("Cod folosit de dvs."),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Creați un link pentru a permite oamenilor să adauge și să vizualizeze fotografii în albumul dvs. distribuit, fără a avea nevoie de o aplicație sau un cont Ente. Excelent pentru colectarea fotografiilor de la evenimente."),
        "collaborativeLink":
            MessageLookupByLibrary.simpleMessage("Link colaborativ"),
        "collaborator": MessageLookupByLibrary.simpleMessage("Colaborator"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Colaboratorii pot adăuga fotografii și videoclipuri la albumul distribuit."),
        "collectPhotos":
            MessageLookupByLibrary.simpleMessage("Colectare fotografii"),
        "confirm": MessageLookupByLibrary.simpleMessage("Confirmare"),
        "confirmAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Confirmați ștergerea contului"),
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Da, doresc să șterg definitiv acest cont și toate datele sale din toate aplicațiile."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Confirmare parolă"),
        "confirmRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Confirmați cheia de recuperare"),
        "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Confirmați cheia de recuperare"),
        "contactSupport": MessageLookupByLibrary.simpleMessage(
            "Contactați serviciul de asistență"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("Continuare"),
        "copyLink": MessageLookupByLibrary.simpleMessage("Copere link"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Copiați acest cod\nîn aplicația de autentificare"),
        "createAccount": MessageLookupByLibrary.simpleMessage("Creare cont"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("Creare cont nou"),
        "createPublicLink":
            MessageLookupByLibrary.simpleMessage("Creare link public"),
        "creatingLink":
            MessageLookupByLibrary.simpleMessage("Se crează linkul..."),
        "custom": MessageLookupByLibrary.simpleMessage("Particularizat"),
        "decrypting": MessageLookupByLibrary.simpleMessage("Se decriptează..."),
        "deleteAccount": MessageLookupByLibrary.simpleMessage("Ștergere cont"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "Ne pare rău că plecați. Vă rugăm să împărtășiți feedback-ul dvs. pentru a ne ajuta să ne îmbunătățim."),
        "deleteAccountPermanentlyButton":
            MessageLookupByLibrary.simpleMessage("Ștergeți contul definitiv"),
        "deleteAlbum": MessageLookupByLibrary.simpleMessage("Ştergeţi albumul"),
        "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
            "De asemenea, ștergeți fotografiile (și videoclipurile) prezente în acest album din <bold>toate</bold> celelalte albume din care fac parte?"),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "Vă rugăm să trimiteți un e-mail la <warning>account-deletion@ente.io</warning> de pe adresa dvs. de e-mail înregistrată."),
        "deleteItemCount": m19,
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "Lipsește o funcție cheie de care am nevoie"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "Aplicația sau o anumită funcție nu se comportă așa cum cred eu că ar trebui"),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
            "Am găsit un alt serviciu care îmi place mai mult"),
        "deleteReason4":
            MessageLookupByLibrary.simpleMessage("Motivul meu nu este listat"),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
            "Solicitarea dvs. va fi procesată în 72 de ore."),
        "deleteSharedAlbum": MessageLookupByLibrary.simpleMessage(
            "Ștergeți albumul distribuit?"),
        "deleteSharedAlbumDialogBody": MessageLookupByLibrary.simpleMessage(
            "Albumul va fi șters pentru toată lumea\n\nVeți pierde accesul la fotografiile distribuite din acest album care sunt deținute de alții"),
        "details": MessageLookupByLibrary.simpleMessage("Detalii"),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
            "Dezactivați blocarea ecranului dispozitivului atunci când Ente este în prim-plan și există o copie de rezervă în curs de desfășurare. În mod normal, acest lucru nu este necesar, dar poate ajuta la finalizarea mai rapidă a încărcărilor mari și a importurilor inițiale de biblioteci mari."),
        "disableAutoLock": MessageLookupByLibrary.simpleMessage(
            "Dezactivare blocare automată"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Observatorii pot să facă capturi de ecran sau să salveze o copie a fotografiilor dvs. folosind instrumente externe"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Rețineți"),
        "discover": MessageLookupByLibrary.simpleMessage("Descoperire"),
        "discover_babies": MessageLookupByLibrary.simpleMessage("Bebeluși"),
        "discover_celebrations":
            MessageLookupByLibrary.simpleMessage("Celebrări"),
        "discover_food": MessageLookupByLibrary.simpleMessage("Mâncare"),
        "discover_greenery": MessageLookupByLibrary.simpleMessage("Verdeață"),
        "discover_hills": MessageLookupByLibrary.simpleMessage("Dealuri"),
        "discover_identity": MessageLookupByLibrary.simpleMessage("Identitate"),
        "discover_memes": MessageLookupByLibrary.simpleMessage("Meme-uri"),
        "discover_notes": MessageLookupByLibrary.simpleMessage("Notițe"),
        "discover_pets": MessageLookupByLibrary.simpleMessage("Animale"),
        "discover_receipts": MessageLookupByLibrary.simpleMessage("Bonuri"),
        "discover_screenshots":
            MessageLookupByLibrary.simpleMessage("Capturi de ecran"),
        "discover_selfies": MessageLookupByLibrary.simpleMessage("Selfie-uri"),
        "discover_sunset": MessageLookupByLibrary.simpleMessage("Apusuri"),
        "discover_visiting_cards":
            MessageLookupByLibrary.simpleMessage("Carte de vizită"),
        "discover_wallpapers":
            MessageLookupByLibrary.simpleMessage("Imagini de fundal"),
        "doThisLater": MessageLookupByLibrary.simpleMessage("Mai târziu"),
        "done": MessageLookupByLibrary.simpleMessage("Finalizat"),
        "dropSupportEmail": m22,
        "duplicateItemsGroup": m24,
        "eligible": MessageLookupByLibrary.simpleMessage("eligibil"),
        "email": MessageLookupByLibrary.simpleMessage("E-mail"),
        "emailNoEnteAccount": m26,
        "encryption": MessageLookupByLibrary.simpleMessage("Criptarea"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Chei de criptare"),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
            "Ente <i>are nevoie de permisiune</i> pentru a vă păstra fotografiile"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Introduceți codul"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
            "Introduceți codul oferit de prietenul dvs. pentru a beneficia de spațiu gratuit pentru amândoi"),
        "enterEmail":
            MessageLookupByLibrary.simpleMessage("Introduceți e-mailul"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Introduceți o parolă nouă pe care o putem folosi pentru a cripta datele"),
        "enterPassword":
            MessageLookupByLibrary.simpleMessage("Introduceți parola"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Introduceți o parolă pe care o putem folosi pentru a decripta datele"),
        "enterReferralCode": MessageLookupByLibrary.simpleMessage(
            "Introduceţi codul de recomandare"),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Introduceți codul de 6 cifre\ndin aplicația de autentificare"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "Vă rugăm să introduceți o adresă de e-mail validă."),
        "enterYourEmailAddress": MessageLookupByLibrary.simpleMessage(
            "Introduceți adresa de e-mail"),
        "enterYourPassword":
            MessageLookupByLibrary.simpleMessage("Introduceţi parola"),
        "enterYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Introduceți cheia de recuperare"),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
            "Acest link a expirat. Vă rugăm să selectați un nou termen de expirare sau să dezactivați expirarea linkului."),
        "failedToApplyCode":
            MessageLookupByLibrary.simpleMessage("Codul nu a putut fi aplicat"),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "Nu se pot obține detaliile recomandării. Vă rugăm să încercați din nou mai târziu."),
        "faq": MessageLookupByLibrary.simpleMessage("Întrebări frecvente"),
        "feedback": MessageLookupByLibrary.simpleMessage("Feedback"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Am uitat parola"),
        "freeStorageClaimed":
            MessageLookupByLibrary.simpleMessage("Spațiu gratuit revendicat"),
        "freeStorageOnReferralSuccess": m29,
        "freeStorageUsable":
            MessageLookupByLibrary.simpleMessage("Spațiu gratuit utilizabil"),
        "general": MessageLookupByLibrary.simpleMessage("General"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Se generează cheile de criptare..."),
        "help": MessageLookupByLibrary.simpleMessage("Asistență"),
        "howItWorks": MessageLookupByLibrary.simpleMessage("Cum funcţionează"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "Rugați-i să țină apăsat pe adresa de e-mail din ecranul de setări și să verifice dacă ID-urile de pe ambele dispozitive se potrivesc."),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Parolă incorectă"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "Cheia de recuperare introdusă este incorectă"),
        "incorrectRecoveryKeyTitle": MessageLookupByLibrary.simpleMessage(
            "Cheie de recuperare incorectă"),
        "indexedItems":
            MessageLookupByLibrary.simpleMessage("Elemente indexate"),
        "insecureDevice":
            MessageLookupByLibrary.simpleMessage("Dispozitiv nesigur"),
        "invalidEmailAddress": MessageLookupByLibrary.simpleMessage(
            "Adresa e-mail nu este validă"),
        "invalidKey": MessageLookupByLibrary.simpleMessage("Cheie invalidă"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Cheia de recuperare pe care ați introdus-o nu este validă. Vă rugăm să vă asigurați că aceasta conține 24 de cuvinte și să verificați ortografia fiecăruia.\n\nDacă ați introdus un cod de recuperare mai vechi, asigurați-vă că acesta conține 64 de caractere și verificați fiecare dintre ele."),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Invitați-vă prietenii"),
        "itemCount": m35,
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "Articolele selectate vor fi eliminate din acest album"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Vă rugăm să ne ajutați cu aceste informații"),
        "linkDeviceLimit":
            MessageLookupByLibrary.simpleMessage("Limită de dispozitive"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Activat"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Expirat"),
        "linkExpiresOn": m36,
        "linkExpiry":
            MessageLookupByLibrary.simpleMessage("Expirarea linkului"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("Linkul a expirat"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Niciodată"),
        "loadingModel":
            MessageLookupByLibrary.simpleMessage("Se descarcă modelele..."),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Blocat"),
        "lockscreen": MessageLookupByLibrary.simpleMessage("Ecran de blocare"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Conectare"),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "Apăsând pe „Conectare”, sunteți de acord cu <u-terms>termenii de prestare ai serviciului</u-terms> și <u-policy>politica de confidenţialitate</u-policy>"),
        "lostDevice":
            MessageLookupByLibrary.simpleMessage("Dispozitiv pierdut?"),
        "machineLearning":
            MessageLookupByLibrary.simpleMessage("Învățare automată"),
        "magicSearch": MessageLookupByLibrary.simpleMessage("Căutare magică"),
        "manage": MessageLookupByLibrary.simpleMessage("Gestionare"),
        "manageDeviceStorage": MessageLookupByLibrary.simpleMessage(
            "Gestionați spațiul dispozitivului"),
        "manageLink": MessageLookupByLibrary.simpleMessage("Gestionați linkul"),
        "manageParticipants":
            MessageLookupByLibrary.simpleMessage("Gestionare"),
        "mlConsent":
            MessageLookupByLibrary.simpleMessage("Activați învățarea automată"),
        "mlConsentConfirmation": MessageLookupByLibrary.simpleMessage(
            "Înțeleg și doresc să activez învățarea automată"),
        "mlConsentDescription": MessageLookupByLibrary.simpleMessage(
            "Dacă activați învățarea automată, Ente va extrage informații precum geometria fețelor din fișiere, inclusiv din cele distribuite cu dvs.\n\nAcest lucru se va întâmpla pe dispozitivul dvs., iar orice informații biometrice generate vor fi criptate integral."),
        "mlConsentPrivacy": MessageLookupByLibrary.simpleMessage(
            "Vă rugăm să faceți clic aici pentru mai multe detalii despre această funcție în politica de confidențialitate"),
        "mlConsentTitle": MessageLookupByLibrary.simpleMessage(
            "Activați învățarea automată?"),
        "mlIndexingDescription": MessageLookupByLibrary.simpleMessage(
            "Vă rugăm să rețineți că învățarea automată va duce la o utilizare mai mare a lățimii de bandă și a bateriei până când toate elementele sunt indexate. Luați în considerare utilizarea aplicației desktop pentru o indexare mai rapidă, toate rezultatele vor fi sincronizate automat."),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Moderată"),
        "never": MessageLookupByLibrary.simpleMessage("Niciodată"),
        "noDeviceLimit": MessageLookupByLibrary.simpleMessage("Niciuna"),
        "noRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Nu aveți cheia de recuperare?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "Datorită naturii protocolului nostru de criptare integrală, datele dvs. nu pot fi decriptate fără parola sau cheia dvs. de recuperare"),
        "ok": MessageLookupByLibrary.simpleMessage("Ok"),
        "onlyFamilyAdminCanChangeCode": m40,
        "oops": MessageLookupByLibrary.simpleMessage("Ups"),
        "oopsSomethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Hopa, ceva nu a mers bine"),
        "orPickAnExistingOne":
            MessageLookupByLibrary.simpleMessage("Sau alegeți unul existent"),
        "password": MessageLookupByLibrary.simpleMessage("Parolă"),
        "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
            "Parola a fost schimbată cu succes"),
        "passwordLock":
            MessageLookupByLibrary.simpleMessage("Blocare cu parolă"),
        "passwordStrength": m41,
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Nu reținem această parolă, deci dacă o uitați <underline>nu vă putem decripta datele</underline>"),
        "pendingItems":
            MessageLookupByLibrary.simpleMessage("Elemente în așteptare"),
        "peopleUsingYourCode": MessageLookupByLibrary.simpleMessage(
            "Persoane care folosesc codul dvs."),
        "pleaseTryAgain": MessageLookupByLibrary.simpleMessage(
            "Vă rugăm să încercați din nou"),
        "pleaseWait":
            MessageLookupByLibrary.simpleMessage("Vă rugăm așteptați..."),
        "privacyPolicyTitle": MessageLookupByLibrary.simpleMessage(
            "Politică de confidențialitate"),
        "publicLinkEnabled":
            MessageLookupByLibrary.simpleMessage("Link public activat"),
        "recover": MessageLookupByLibrary.simpleMessage("Recuperare"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("Recuperare cont"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Recuperare"),
        "recoveryKey":
            MessageLookupByLibrary.simpleMessage("Cheie de recuperare"),
        "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Cheie de recuperare copiată în clipboard"),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
            "Dacă vă uitați parola, singura cale de a vă recupera datele este folosind această cheie."),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
            "Nu reținem această cheie, vă rugăm să păstrați această cheie de 24 de cuvinte într-un loc sigur."),
        "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
            "Super! Cheia dvs. de recuperare este validă. Vă mulțumim pentru verificare.\n\nVă rugăm să nu uitați să păstrați cheia de recuperare în siguranță."),
        "recoveryKeyVerified": MessageLookupByLibrary.simpleMessage(
            "Cheie de recuperare verificată"),
        "recoveryKeyVerifyReason": MessageLookupByLibrary.simpleMessage(
            "Cheia dvs. de recuperare este singura modalitate de a vă recupera fotografiile dacă uitați parola. Puteți găsi cheia dvs. de recuperare în Setări > Cont.\n\nVă rugăm să introduceți aici cheia de recuperare pentru a verifica dacă ați salvat-o corect."),
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("Recuperare reușită!"),
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "Dispozitivul actual nu este suficient de puternic pentru a vă verifica parola, dar o putem regenera într-un mod care să funcționeze cu toate dispozitivele.\n\nVă rugăm să vă conectați utilizând cheia de recuperare și să vă regenerați parola (dacă doriți, o puteți utiliza din nou pe aceeași)."),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Refaceți parola"),
        "referralStep1": MessageLookupByLibrary.simpleMessage(
            "1. Dați acest cod prietenilor"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "2. Aceștia se înscriu la un plan cu plată"),
        "referralStep3": m48,
        "referrals": MessageLookupByLibrary.simpleMessage("Recomandări"),
        "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
            "Recomandările sunt momentan întrerupte"),
        "remove": MessageLookupByLibrary.simpleMessage("Eliminare"),
        "removeFromAlbum":
            MessageLookupByLibrary.simpleMessage("Eliminați din album"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("Eliminați din album?"),
        "removeLink": MessageLookupByLibrary.simpleMessage("Eliminați linkul"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Eliminați participantul"),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
            "Unele dintre articolele pe care le eliminați au fost adăugate de alte persoane și veți pierde accesul la acestea"),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Eliminați?"),
        "removingFromFavorites":
            MessageLookupByLibrary.simpleMessage("Se elimină din favorite..."),
        "resendEmail":
            MessageLookupByLibrary.simpleMessage("Retrimitere e-mail"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Resetați parola"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Salvați cheia"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Salvați cheia de recuperare, dacă nu ați făcut-o deja"),
        "scanCode": MessageLookupByLibrary.simpleMessage("Scanare cod"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Scanați acest cod de bare\ncu aplicația de autentificare"),
        "security": MessageLookupByLibrary.simpleMessage("Securitate"),
        "selectAll": MessageLookupByLibrary.simpleMessage("Selectare totală"),
        "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
            "Selectați folderele pentru copie de rezervă"),
        "selectReason":
            MessageLookupByLibrary.simpleMessage("Selectați motivul"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "Dosarele selectate vor fi criptate și salvate"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("Trimiteți e-mail"),
        "sendInvite":
            MessageLookupByLibrary.simpleMessage("Trimiteți invitația"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Trimitere link"),
        "setAPassword": MessageLookupByLibrary.simpleMessage("Setați o parolă"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Setați parola"),
        "setupComplete":
            MessageLookupByLibrary.simpleMessage("Configurare finalizată"),
        "shareALink":
            MessageLookupByLibrary.simpleMessage("Distribuiți un link"),
        "shareMyVerificationID": m53,
        "shareTextConfirmOthersVerificationID": m2,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Descarcă Ente pentru a putea distribui cu ușurință fotografii și videoclipuri în calitate originală\n\nhttps://ente.io"),
        "shareTextReferralCode": m54,
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
            "Distribuiți cu utilizatori din afara Ente"),
        "shareWithPeopleSectionTitle": m55,
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Creați albume distribuite și colaborative cu alți utilizatori Ente, inclusiv cu utilizatorii planurilor gratuite."),
        "sharedPhotoNotifications":
            MessageLookupByLibrary.simpleMessage("Fotografii partajate noi"),
        "sharedPhotoNotificationsExplanation": MessageLookupByLibrary.simpleMessage(
            "Primiți notificări atunci când cineva adaugă o fotografie la un album distribuit din care faceți parte"),
        "showMemories":
            MessageLookupByLibrary.simpleMessage("Afișare amintiri"),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "Sunt de acord cu <u-terms>termenii de prestare ai serviciului</u-terms> și <u-policy>politica de confidențialitate</u-policy>"),
        "skip": MessageLookupByLibrary.simpleMessage("Omiteți"),
        "someoneSharingAlbumsWithYouShouldSeeTheSameId":
            MessageLookupByLibrary.simpleMessage(
                "Cineva care distribuie albume cu dvs. ar trebui să vadă același ID pe dispozitivul său."),
        "somethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Ceva nu a funcţionat corect"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Ceva nu a mers bine, vă rugăm să încercați din nou"),
        "sorry": MessageLookupByLibrary.simpleMessage("Ne pare rău"),
        "sorryCouldNotAddToFavorites": MessageLookupByLibrary.simpleMessage(
            "Ne pare rău, nu s-a putut adăuga la favorite!"),
        "sorryCouldNotRemoveFromFavorites":
            MessageLookupByLibrary.simpleMessage(
                "Ne pare rău, nu s-a putut elimina din favorite!"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "Ne pare rău, nu am putut genera chei securizate pe acest dispozitiv.\n\nvă rugăm să vă înregistrați de pe un alt dispozitiv."),
        "status": MessageLookupByLibrary.simpleMessage("Status"),
        "storageInGB": m60,
        "strongStrength": MessageLookupByLibrary.simpleMessage("Puternică"),
        "subscribe": MessageLookupByLibrary.simpleMessage("Abonare"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "Aveți nevoie de un abonament plătit activ pentru a activa distribuirea."),
        "tapToCopy":
            MessageLookupByLibrary.simpleMessage("atingeți pentru a copia"),
        "tapToEnterCode": MessageLookupByLibrary.simpleMessage(
            "Atingeți pentru a introduce codul"),
        "terminate": MessageLookupByLibrary.simpleMessage("Terminare"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Terminați sesiunea?"),
        "termsOfServicesTitle": MessageLookupByLibrary.simpleMessage("Termeni"),
        "theyAlsoGetXGb": m65,
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "Aceasta poate fi utilizată pentru a vă recupera contul în cazul în care pierdeți al doilea factor"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Acest dispozitiv"),
        "thisIsPersonVerificationId": m66,
        "thisIsYourVerificationId": MessageLookupByLibrary.simpleMessage(
            "Acesta este ID-ul dvs. de verificare"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Urmează să vă deconectați de pe următorul dispozitiv:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Urmează să vă deconectați de pe acest dispozitiv!"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "Pentru a reseta parola, vă rugăm să verificați mai întâi e-mailul."),
        "total": MessageLookupByLibrary.simpleMessage("total"),
        "tryAgain": MessageLookupByLibrary.simpleMessage("Încercați din nou"),
        "twofactor": MessageLookupByLibrary.simpleMessage("Doi factori"),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage(
                "Autentificare cu doi factori"),
        "twofactorSetup":
            MessageLookupByLibrary.simpleMessage("Configurare doi factori"),
        "unavailableReferralCode": MessageLookupByLibrary.simpleMessage(
            "Ne pare rău, acest cod nu este disponibil."),
        "unselectAll":
            MessageLookupByLibrary.simpleMessage("Deselectare totală"),
        "updatingFolderSelection": MessageLookupByLibrary.simpleMessage(
            "Se actualizează selecția dosarelor..."),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "Spațiul utilizabil este limitat de planul dvs. actual. Spațiul suplimentar revendicat va deveni automat utilizabil atunci când vă îmbunătățiți planul."),
        "useRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Folosiți cheia de recuperare"),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("ID de verificare"),
        "verify": MessageLookupByLibrary.simpleMessage("Verificare"),
        "verifyEmail":
            MessageLookupByLibrary.simpleMessage("Verificare e-mail"),
        "verifyEmailID": m70,
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Verificați parola"),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Se verifică cheia de recuperare..."),
        "viewRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Vizualizați cheia de recuperare"),
        "viewer": MessageLookupByLibrary.simpleMessage("Observator"),
        "waitingForWifi":
            MessageLookupByLibrary.simpleMessage("Se așteaptă WiFi..."),
        "weAreOpenSource":
            MessageLookupByLibrary.simpleMessage("Suntem open source!"),
        "weHaveSendEmailTo": m71,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Slabă"),
        "welcomeBack":
            MessageLookupByLibrary.simpleMessage("Bine ați revenit!"),
        "yearsAgo": m72,
        "yesConvertToViewer":
            MessageLookupByLibrary.simpleMessage("Da, covertiți la observator"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("Da, elimină"),
        "you": MessageLookupByLibrary.simpleMessage("Dvs."),
        "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "* Cel mult vă puteți dubla spațiul"),
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("Contul dvs. a fost șters")
      };
}
