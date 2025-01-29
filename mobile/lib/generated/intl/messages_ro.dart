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

  static String m9(count) =>
      "${Intl.plural(count, one: 'Adăugați un colaborator', few: 'Adăugați colaboratori', other: 'Adăugați colaboratori')}";

  static String m10(count) =>
      "${Intl.plural(count, one: 'Adăugați articolul', few: 'Adăugați articolele', other: 'Adăugați articolele')}";

  static String m11(storageAmount, endDate) =>
      "Suplimentul de ${storageAmount} este valabil până pe ${endDate}";

  static String m12(count) =>
      "${Intl.plural(count, one: 'Adăugați observator', few: 'Adăugați observatori', other: 'Adăugați observatori')}";

  static String m13(emailOrName) => "Adăugat de ${emailOrName}";

  static String m14(albumName) => "S-au adăugat cu succes la ${albumName}";

  static String m15(count) =>
      "${Intl.plural(count, zero: 'Fără participanți', one: '1 participant', other: '${count} de participanți')}";

  static String m16(versionValue) => "Versiune: ${versionValue}";

  static String m17(freeAmount, storageUnit) =>
      "${freeAmount} ${storageUnit} liber";

  static String m18(paymentProvider) =>
      "Vă rugăm să vă anulați mai întâi abonamentul existent de la ${paymentProvider}";

  static String m3(user) =>
      "${user} nu va putea să mai adauge fotografii la acest album\n\nVa putea să elimine fotografii existente adăugate de el/ea";

  static String m19(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true':
                'Familia dvs. a revendicat ${storageAmountInGb} GB până acum',
            'false': 'Ați revendicat ${storageAmountInGb} GB până acum',
            'other': 'Ați revendicat ${storageAmountInGb} de GB până acum!',
          })}";

  static String m20(albumName) => "Link colaborativ creat pentru ${albumName}";

  static String m21(count) =>
      "${Intl.plural(count, zero: 'S-au adăugat 0 colaboratori', one: 'S-a adăugat 1 colaborator', few: 'S-au adăugat ${count} colaboratori', other: 'S-au adăugat ${count} de colaboratori')}";

  static String m22(email, numOfDays) =>
      "Sunteți pe cale să adăugați ${email} ca persoană de contact de încredere. Acesta va putea să vă recupereze contul dacă lipsiți timp de ${numOfDays} de zile.";

  static String m23(familyAdminEmail) =>
      "Vă rugăm să contactați <green>${familyAdminEmail}</green> pentru a gestiona abonamentul";

  static String m24(provider) =>
      "Vă rugăm să ne contactați la support@ente.io pentru a vă gestiona abonamentul ${provider}.";

  static String m25(endpoint) => "Conectat la ${endpoint}";

  static String m26(count) =>
      "${Intl.plural(count, one: 'Ștergeți ${count} articol', other: 'Ștergeți ${count} de articole')}";

  static String m27(currentlyDeleting, totalCount) =>
      "Se șterg ${currentlyDeleting} / ${totalCount}";

  static String m28(albumName) =>
      "Urmează să eliminați linkul public pentru accesarea „${albumName}”.";

  static String m29(supportEmail) =>
      "Vă rugăm să trimiteți un e-mail la ${supportEmail} de pe adresa de e-mail înregistrată";

  static String m30(count, storageSaved) =>
      "Ați curățat ${Intl.plural(count, one: '${count} dublură', few: '${count} dubluri', other: '${count} de dubluri')}, economisind (${storageSaved}!)";

  static String m31(count, formattedSize) =>
      "${count} fișiere, ${formattedSize} fiecare";

  static String m32(newEmail) => "E-mail modificat în ${newEmail}";

  static String m33(email) =>
      "${email} nu are un cont Ente.\n\nTrimiteți-le o invitație pentru a distribui fotografii.";

  static String m34(text) => "S-au găsit fotografii extra pentru ${text}";

  static String m35(count, formattedNumber) =>
      "${Intl.plural(count, one: 'Un fișier de pe acest dispozitiv a fost deja salvat în siguranță', few: '${formattedNumber} fișiere de pe acest dispozitiv au fost deja salvate în siguranță', other: '${formattedNumber} de fișiere de pe acest dispozitiv fost deja salvate în siguranță')}";

  static String m36(count, formattedNumber) =>
      "${Intl.plural(count, one: 'Un fișier din acest album a fost deja salvat în siguranță', few: '${formattedNumber} fișiere din acest album au fost deja salvate în siguranță', other: '${formattedNumber} de fișiere din acest album au fost deja salvate în siguranță')}";

  static String m4(storageAmountInGB) =>
      "${storageAmountInGB} GB de fiecare dată când cineva se înscrie pentru un plan plătit și aplică codul dvs.";

  static String m37(endDate) =>
      "Perioadă de încercare valabilă până pe ${endDate}";

  static String m38(count) =>
      "Încă ${Intl.plural(count, one: 'îl puteți', few: 'le puteți', other: 'le puteți')} accesa pe Ente cât timp aveți un abonament activ";

  static String m39(sizeInMBorGB) => "Eliberați ${sizeInMBorGB}";

  static String m40(count, formattedSize) =>
      "${Intl.plural(count, one: 'Poate fi șters de pe dispozitiv pentru a elibera ${formattedSize}', few: 'Pot fi șterse de pe dispozitiv pentru a elibera ${formattedSize}', other: 'Pot fi șterse de pe dispozitiv pentru a elibera ${formattedSize}')}";

  static String m41(currentlyProcessing, totalCount) =>
      "Se procesează ${currentlyProcessing} / ${totalCount}";

  static String m42(count) =>
      "${Intl.plural(count, one: '${count} articol', few: '${count} articole', other: '${count} de articole')}";

  static String m43(email) =>
      "${email} v-a invitat să fiți un contact de încredere";

  static String m44(expiryTime) => "Linkul va expira pe ${expiryTime}";

  static String m5(count, formattedCount) =>
      "${Intl.plural(count, one: '${formattedCount} amintire', few: '${formattedCount} amintiri', other: '${formattedCount} de amintiri')}";

  static String m45(count) =>
      "${Intl.plural(count, one: 'Mutați articolul', few: 'Mutați articole', other: 'Mutați articolele')}";

  static String m46(albumName) => "S-au mutat cu succes în ${albumName}";

  static String m47(personName) => "Nicio sugestie pentru ${personName}";

  static String m48(name) => "Nu este ${name}?";

  static String m49(familyAdminEmail) =>
      "Vă rugăm să contactați ${familyAdminEmail} pentru a vă schimba codul.";

  static String m0(passwordStrengthValue) =>
      "Complexitatea parolei: ${passwordStrengthValue}";

  static String m50(providerName) =>
      "Vă rugăm să vorbiți cu asistența ${providerName} dacă ați fost taxat";

  static String m51(count) =>
      "${Intl.plural(count, zero: '0 fotografii', one: '1 fotografie', few: '${count} fotografii', other: '${count} de fotografii')}";

  static String m52(endDate) =>
      "Perioada de încercare gratuită valabilă până pe ${endDate}.\nUlterior, puteți opta pentru un plan plătit.";

  static String m53(toEmail) =>
      "Vă rugăm să ne trimiteți un e-mail la ${toEmail}";

  static String m54(toEmail) =>
      "Vă rugăm să trimiteți jurnalele la \n${toEmail}";

  static String m55(folderName) => "Se procesează ${folderName}...";

  static String m56(storeName) => "Evaluați-ne pe ${storeName}";

  static String m57(days, email) =>
      "Puteți accesa contul după ${days} zile. O notificare va fi trimisă la ${email}.";

  static String m58(email) =>
      "Acum puteți recupera contul ${email} setând o nouă parolă.";

  static String m59(email) => "${email} încearcă să vă recupereze contul.";

  static String m60(storageInGB) =>
      "3. Amândoi primiți ${storageInGB} GB* gratuit";

  static String m61(userEmail) =>
      "${userEmail} va fi eliminat din acest album distribuit\n\nOrice fotografii adăugate de acesta vor fi, de asemenea, eliminate din album";

  static String m62(endDate) => "Abonamentul se reînnoiește pe ${endDate}";

  static String m63(count) =>
      "${Intl.plural(count, one: '${count} rezultat găsit', few: '${count} rezultate găsite', other: '${count} de rezultate găsite')}";

  static String m64(snapshotLength, searchLength) =>
      "Lungimea secțiunilor nu se potrivesc: ${snapshotLength} != ${searchLength}";

  static String m6(count) => "${count} selectate";

  static String m65(count, yourCount) =>
      "${count} selectate (${yourCount} ale dvs.)";

  static String m66(verificationID) =>
      "Acesta este ID-ul meu de verificare: ${verificationID} pentru ente.io.";

  static String m7(verificationID) =>
      "Poți confirma că acesta este ID-ul tău de verificare ente.io: ${verificationID}";

  static String m67(referralCode, referralStorageInGB) =>
      "Codul de recomandare Ente: ${referralCode}\n\nAplică-l în Setări → General → Recomandări pentru a obține ${referralStorageInGB} GB gratuit după ce te înscrii pentru un plan plătit\n\nhttps://ente.io";

  static String m68(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Distribuiți cu anumite persoane', one: 'Distribuit cu o persoană', other: 'Distribuit cu ${numberOfPeople} de persoane')}";

  static String m69(emailIDs) => "Distribuit cu ${emailIDs}";

  static String m70(fileType) =>
      "Fișierul de tip ${fileType} va fi șters din dispozitivul dvs.";

  static String m71(fileType) =>
      "Fișierul de tip ${fileType} este atât în Ente, cât și în dispozitivul dvs.";

  static String m72(fileType) =>
      "Fișierul de tip ${fileType} va fi șters din Ente.";

  static String m1(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m73(
          usedAmount, usedStorageUnit, totalAmount, totalStorageUnit) =>
      "${usedAmount} ${usedStorageUnit} din ${totalAmount} ${totalStorageUnit} utilizat";

  static String m74(id) =>
      "${id} este deja legat la un alt cont Ente.\nDacă doriți să folosiți ${id} cu acest cont, vă rugăm să contactați asistența noastră";

  static String m75(endDate) => "Abonamentul dvs. va fi anulat pe ${endDate}";

  static String m76(completed, total) =>
      "${completed}/${total} amintiri salvate";

  static String m77(ignoreReason) =>
      "Atingeți pentru a încărca, încărcarea este ignorată în prezent datorită ${ignoreReason}";

  static String m8(storageAmountInGB) =>
      "De asemenea, va primii ${storageAmountInGB} GB";

  static String m78(email) => "Acesta este ID-ul de verificare al ${email}";

  static String m79(count) =>
      "${Intl.plural(count, zero: 'Curând', one: 'O zi', other: '${count} de zile')}";

  static String m80(email) =>
      "Ați fost învitat să fiți un contact de moștenire de către ${email}.";

  static String m81(galleryType) =>
      "Tipul de galerie ${galleryType} nu este acceptat pentru redenumire";

  static String m82(ignoreReason) =>
      "Încărcare ignorată din motivul ${ignoreReason}";

  static String m83(count) => "Se salvează ${count} amintiri...";

  static String m84(endDate) => "Valabil până pe ${endDate}";

  static String m85(email) => "Verificare ${email}";

  static String m86(count) =>
      "${Intl.plural(count, zero: 'S-au adăugat 0 observatori', one: 'S-a adăugat 1 observator', few: 'S-au adăugat ${count} observatori', other: 'S-au adăugat ${count} de observatori')}";

  static String m2(email) => "Am trimis un e-mail la <green>${email}</green>";

  static String m87(count) =>
      "${Intl.plural(count, one: 'acum ${count} an', few: 'acum ${count} ani', other: 'acum ${count} de ani')}";

  static String m88(storageSaved) => "Ați eliberat cu succes ${storageSaved}!";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable": MessageLookupByLibrary.simpleMessage(
            "Este disponibilă o nouă versiune de Ente."),
        "about": MessageLookupByLibrary.simpleMessage("Despre"),
        "acceptTrustInvite":
            MessageLookupByLibrary.simpleMessage("Acceptați invitația"),
        "account": MessageLookupByLibrary.simpleMessage("Cont"),
        "accountIsAlreadyConfigured": MessageLookupByLibrary.simpleMessage(
            "Contul este deja configurat."),
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Bine ați revenit!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Înțeleg că dacă îmi pierd parola, îmi pot pierde datele, deoarece datele mele sunt <underline>criptate integral</underline>."),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Sesiuni active"),
        "add": MessageLookupByLibrary.simpleMessage("Adăugare"),
        "addAName": MessageLookupByLibrary.simpleMessage("Adăugați un nume"),
        "addANewEmail":
            MessageLookupByLibrary.simpleMessage("Adăugați un e-mail nou"),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Adăugare colaborator"),
        "addCollaborators": m9,
        "addFiles": MessageLookupByLibrary.simpleMessage("Adăugați fișiere"),
        "addFromDevice":
            MessageLookupByLibrary.simpleMessage("Adăugați de pe dispozitiv"),
        "addItem": m10,
        "addLocation": MessageLookupByLibrary.simpleMessage("Adăugare locație"),
        "addLocationButton": MessageLookupByLibrary.simpleMessage("Adăugare"),
        "addMore": MessageLookupByLibrary.simpleMessage("Adăugați mai mulți"),
        "addName": MessageLookupByLibrary.simpleMessage("Adăugare nume"),
        "addNameOrMerge":
            MessageLookupByLibrary.simpleMessage("Adăugare nume sau îmbinare"),
        "addNew": MessageLookupByLibrary.simpleMessage("Adăugare nou"),
        "addNewPerson":
            MessageLookupByLibrary.simpleMessage("Adăugare persoană nouă"),
        "addOnPageSubtitle":
            MessageLookupByLibrary.simpleMessage("Detaliile suplimentelor"),
        "addOnValidTill": m11,
        "addOns": MessageLookupByLibrary.simpleMessage("Suplimente"),
        "addPhotos":
            MessageLookupByLibrary.simpleMessage("Adăugați fotografii"),
        "addSelected":
            MessageLookupByLibrary.simpleMessage("Adăugați selectate"),
        "addToAlbum": MessageLookupByLibrary.simpleMessage("Adăugare la album"),
        "addToEnte": MessageLookupByLibrary.simpleMessage("Adăugare la Ente"),
        "addToHiddenAlbum":
            MessageLookupByLibrary.simpleMessage("Adăugați la album ascuns"),
        "addTrustedContact": MessageLookupByLibrary.simpleMessage(
            "Adăugare contact de încredere"),
        "addViewer":
            MessageLookupByLibrary.simpleMessage("Adăugare observator"),
        "addViewers": m12,
        "addYourPhotosNow": MessageLookupByLibrary.simpleMessage(
            "Adăugați-vă fotografiile acum"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Adăugat ca"),
        "addedBy": m13,
        "addedSuccessfullyTo": m14,
        "addingToFavorites":
            MessageLookupByLibrary.simpleMessage("Se adaugă la favorite..."),
        "advanced": MessageLookupByLibrary.simpleMessage("Avansat"),
        "advancedSettings": MessageLookupByLibrary.simpleMessage("Avansat"),
        "after1Day": MessageLookupByLibrary.simpleMessage("După o zi"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("După o oră"),
        "after1Month": MessageLookupByLibrary.simpleMessage("După o lună"),
        "after1Week": MessageLookupByLibrary.simpleMessage("După o săptămâna"),
        "after1Year": MessageLookupByLibrary.simpleMessage("După un an"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Proprietar"),
        "albumParticipantsCount": m15,
        "albumTitle": MessageLookupByLibrary.simpleMessage("Titlu album"),
        "albumUpdated":
            MessageLookupByLibrary.simpleMessage("Album actualizat"),
        "albums": MessageLookupByLibrary.simpleMessage("Albume"),
        "allClear": MessageLookupByLibrary.simpleMessage("✨ Totul e curat"),
        "allMemoriesPreserved": MessageLookupByLibrary.simpleMessage(
            "S-au salvat toate amintirile"),
        "allPersonGroupingWillReset": MessageLookupByLibrary.simpleMessage(
            "Toate grupările pentru această persoană vor fi resetate și veți pierde toate sugestiile făcute pentru această persoană"),
        "allow": MessageLookupByLibrary.simpleMessage("Permiteți"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Permiteți persoanelor care au linkul să adauge și fotografii la albumul distribuit."),
        "allowAddingPhotos": MessageLookupByLibrary.simpleMessage(
            "Permiteți adăugarea fotografiilor"),
        "allowAppToOpenSharedAlbumLinks": MessageLookupByLibrary.simpleMessage(
            "Permiteți aplicației să deschidă link-uri de album partajate"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("Permiteți descărcările"),
        "allowPeopleToAddPhotos": MessageLookupByLibrary.simpleMessage(
            "Permiteți persoanelor să adauge fotografii"),
        "allowPermBody": MessageLookupByLibrary.simpleMessage(
            "Vă rugăm să permiteți accesul la fotografiile dvs. din Setări, astfel încât Ente să vă poată afișa și salva biblioteca."),
        "allowPermTitle": MessageLookupByLibrary.simpleMessage(
            "Permiteți accesul la fotografii"),
        "androidBiometricHint":
            MessageLookupByLibrary.simpleMessage("Verificați-vă identitatea"),
        "androidBiometricNotRecognized": MessageLookupByLibrary.simpleMessage(
            "Neidentificat. Încercați din nou."),
        "androidBiometricRequiredTitle":
            MessageLookupByLibrary.simpleMessage("Biometrice necesare"),
        "androidBiometricSuccess":
            MessageLookupByLibrary.simpleMessage("Succes"),
        "androidCancelButton": MessageLookupByLibrary.simpleMessage("Anulare"),
        "androidDeviceCredentialsRequiredTitle":
            MessageLookupByLibrary.simpleMessage(
                "Sunt necesare acreditările dispozitivului"),
        "androidDeviceCredentialsSetupDescription":
            MessageLookupByLibrary.simpleMessage(
                "Sunt necesare acreditările dispozitivului"),
        "androidGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "Autentificarea biometrică nu este configurată pe dispozitivul dvs. Mergeți la „Setări > Securitate” pentru a adăuga autentificarea biometrică."),
        "androidIosWebDesktop":
            MessageLookupByLibrary.simpleMessage("Android, iOS, Web, Desktop"),
        "androidSignInTitle":
            MessageLookupByLibrary.simpleMessage("Autentificare necesară"),
        "appLock": MessageLookupByLibrary.simpleMessage("Blocare aplicație"),
        "appLockDescriptions": MessageLookupByLibrary.simpleMessage(
            "Alegeți între ecranul de blocare implicit al dispozitivului dvs. și un ecran de blocare personalizat cu PIN sau parolă."),
        "appVersion": m16,
        "appleId": MessageLookupByLibrary.simpleMessage("Apple ID"),
        "apply": MessageLookupByLibrary.simpleMessage("Aplicare"),
        "applyCodeTitle":
            MessageLookupByLibrary.simpleMessage("Aplicați codul"),
        "appstoreSubscription":
            MessageLookupByLibrary.simpleMessage("Abonament AppStore"),
        "archive": MessageLookupByLibrary.simpleMessage("Arhivă"),
        "archiveAlbum": MessageLookupByLibrary.simpleMessage("Arhivare album"),
        "archiving": MessageLookupByLibrary.simpleMessage("Se arhivează..."),
        "areYouSureThatYouWantToLeaveTheFamily":
            MessageLookupByLibrary.simpleMessage(
                "Sunteți sigur că doriți să părăsiți planul de familie?"),
        "areYouSureYouWantToCancel": MessageLookupByLibrary.simpleMessage(
            "Sunteți sigur că doriți să anulați?"),
        "areYouSureYouWantToChangeYourPlan":
            MessageLookupByLibrary.simpleMessage(
                "Sunteți sigur că doriți să vă schimbați planul?"),
        "areYouSureYouWantToExit":
            MessageLookupByLibrary.simpleMessage("Sigur doriți să ieșiți?"),
        "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
            "Sunteți sigur că doriți să vă deconectați?"),
        "areYouSureYouWantToRenew": MessageLookupByLibrary.simpleMessage(
            "Sunteți sigur că doriți să reînnoiți?"),
        "areYouSureYouWantToResetThisPerson":
            MessageLookupByLibrary.simpleMessage(
                "Sunteți sigur că doriți să resetaţi această persoană?"),
        "askCancelReason": MessageLookupByLibrary.simpleMessage(
            "Abonamentul dvs. a fost anulat. Doriți să ne comunicați motivul?"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "Care este principalul motiv pentru care vă ștergeți contul?"),
        "askYourLovedOnesToShare": MessageLookupByLibrary.simpleMessage(
            "Cereți-le celor dragi să distribuie"),
        "atAFalloutShelter":
            MessageLookupByLibrary.simpleMessage("la un adăpost antiatomic"),
        "authToChangeEmailVerificationSetting":
            MessageLookupByLibrary.simpleMessage(
                "Vă rugăm să vă autentificați pentru a schimba verificarea prin e-mail"),
        "authToChangeLockscreenSetting": MessageLookupByLibrary.simpleMessage(
            "Vă rugăm să vă autentificați pentru a schimba setarea ecranului de blocare"),
        "authToChangeYourEmail": MessageLookupByLibrary.simpleMessage(
            "Vă rugăm să vă autentificați pentru a vă schimba adresa de e-mail"),
        "authToChangeYourPassword": MessageLookupByLibrary.simpleMessage(
            "Vă rugăm să vă autentificați pentru a vă schimba parola"),
        "authToConfigureTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Vă rugăm să vă autentificați pentru a configura autentificarea cu doi factori"),
        "authToInitiateAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Vă rugăm să vă autentificați pentru a iniția ștergerea contului"),
        "authToManageLegacy": MessageLookupByLibrary.simpleMessage(
            "Vă rugăm să vă autentificați pentru a gestiona contactele de încredere"),
        "authToViewPasskey": MessageLookupByLibrary.simpleMessage(
            "Vă rugăm să vă autentificați pentru a vizualiza cheia de acces"),
        "authToViewTrashedFiles": MessageLookupByLibrary.simpleMessage(
            "Vă rugăm să vă autentificați pentru a vedea fișierele din coșul de gunoi"),
        "authToViewYourActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Vă rugăm să vă autentificați pentru a vedea sesiunile active"),
        "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
            "Vă rugăm să vă autentificați pentru a vedea fișierele ascunse"),
        "authToViewYourMemories": MessageLookupByLibrary.simpleMessage(
            "Vă rugăm să vă autentificați pentru a vă vizualiza amintirile"),
        "authToViewYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Vă rugăm să vă autentificați pentru a vedea cheia de recuperare"),
        "authenticating":
            MessageLookupByLibrary.simpleMessage("Autentificare..."),
        "authenticationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Autentificare eșuată, încercați din nou"),
        "authenticationSuccessful":
            MessageLookupByLibrary.simpleMessage("Autentificare cu succes!"),
        "autoCastDialogBody": MessageLookupByLibrary.simpleMessage(
            "Veți vedea dispozitivele disponibile pentru Cast aici."),
        "autoCastiOSPermission": MessageLookupByLibrary.simpleMessage(
            "Asigurați-vă că permisiunile de rețea locală sunt activate pentru aplicația Ente Foto, în Setări."),
        "autoLock": MessageLookupByLibrary.simpleMessage("Blocare automată"),
        "autoLockFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "Timpul după care aplicația se blochează după ce a fost pusă în fundal"),
        "autoLogoutMessage": MessageLookupByLibrary.simpleMessage(
            "Din cauza unei probleme tehnice, ați fost deconectat. Ne cerem scuze pentru neplăcerile create."),
        "autoPair": MessageLookupByLibrary.simpleMessage("Asociere automată"),
        "autoPairDesc": MessageLookupByLibrary.simpleMessage(
            "Asocierea automată funcționează numai cu dispozitive care acceptă Chromecast."),
        "available": MessageLookupByLibrary.simpleMessage("Disponibil"),
        "availableStorageSpace": m17,
        "backedUpFolders":
            MessageLookupByLibrary.simpleMessage("Foldere salvate"),
        "backup": MessageLookupByLibrary.simpleMessage("Copie de rezervă"),
        "backupFailed":
            MessageLookupByLibrary.simpleMessage("Copie de rezervă eșuată"),
        "backupFile": MessageLookupByLibrary.simpleMessage("Salvare fișier"),
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
        "birthday": MessageLookupByLibrary.simpleMessage("Ziua de naștere"),
        "blackFridaySale":
            MessageLookupByLibrary.simpleMessage("Ofertă Black Friday"),
        "blog": MessageLookupByLibrary.simpleMessage("Blog"),
        "cachedData": MessageLookupByLibrary.simpleMessage(
            "Date salvate în memoria cache"),
        "calculating": MessageLookupByLibrary.simpleMessage("Se calculează..."),
        "canNotOpenBody": MessageLookupByLibrary.simpleMessage(
            "Ne pare rău, acest album nu poate fi deschis în aplicație."),
        "canNotOpenTitle": MessageLookupByLibrary.simpleMessage(
            "Nu se poate deschide acest album"),
        "canNotUploadToAlbumsOwnedByOthers":
            MessageLookupByLibrary.simpleMessage(
                "Nu se poate încărca în albumele deținute de alții"),
        "canOnlyCreateLinkForFilesOwnedByYou":
            MessageLookupByLibrary.simpleMessage(
                "Se pot crea linkuri doar pentru fișiere deținute de dvs."),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "Puteți elimina numai fișierele deținute de dvs."),
        "cancel": MessageLookupByLibrary.simpleMessage("Anulare"),
        "cancelAccountRecovery":
            MessageLookupByLibrary.simpleMessage("Anulare recuperare"),
        "cancelAccountRecoveryBody": MessageLookupByLibrary.simpleMessage(
            "Sunteți sigur că doriți să anulați recuperarea?"),
        "cancelOtherSubscription": m18,
        "cancelSubscription":
            MessageLookupByLibrary.simpleMessage("Anulare abonament"),
        "cannotAddMorePhotosAfterBecomingViewer": m3,
        "cannotDeleteSharedFiles": MessageLookupByLibrary.simpleMessage(
            "Nu se pot șterge fișierele distribuite"),
        "castAlbum": MessageLookupByLibrary.simpleMessage("Difuzați albumul"),
        "castIPMismatchBody": MessageLookupByLibrary.simpleMessage(
            "Vă rugăm să vă asigurați că sunteți în aceeași rețea cu televizorul."),
        "castIPMismatchTitle": MessageLookupByLibrary.simpleMessage(
            "Nu s-a reușit proiectarea albumului"),
        "castInstruction": MessageLookupByLibrary.simpleMessage(
            "Accesați cast.ente.io de pe dispozitivul pe care doriți să îl asociați.\n\nIntroduceți codul de mai jos pentru a reda albumul pe TV."),
        "centerPoint": MessageLookupByLibrary.simpleMessage("Punctul central"),
        "change": MessageLookupByLibrary.simpleMessage("Schimbați"),
        "changeEmail":
            MessageLookupByLibrary.simpleMessage("Schimbați e-mailul"),
        "changeLocationOfSelectedItems": MessageLookupByLibrary.simpleMessage(
            "Schimbați locația articolelor selectate?"),
        "changeLogBackupStatusContent": MessageLookupByLibrary.simpleMessage(
            "Am adăugat un jurnal al tuturor fișierelor care au fost încărcate pe Ente, inclusiv eșecurile și coada de așteptare."),
        "changeLogBackupStatusTitle":
            MessageLookupByLibrary.simpleMessage("Starea copiei de rezervă"),
        "changeLogDiscoverContent": MessageLookupByLibrary.simpleMessage(
            "Căutați fotografii ale cărților de identitate, notițe sau chiar meme-uri? Mergeți la fila de căutare și dați o privire la Descoperire. Bazat pe căutarea noastră semantică, este un loc în care puteți găsi fotografii care ar putea fi importante pentru dvs.\\n\\nEste disponibilă numai dacă ați activat învățarea automată."),
        "changeLogDiscoverTitle":
            MessageLookupByLibrary.simpleMessage("Descoperire"),
        "changeLogMagicSearchImprovementContent":
            MessageLookupByLibrary.simpleMessage(
                "Am îmbunătățit căutarea magică pentru a deveni mult mai rapidă, astfel încât să nu trebuiască să așteptați pentru a găsi ceea ce căutați."),
        "changeLogMagicSearchImprovementTitle":
            MessageLookupByLibrary.simpleMessage(
                "Îmbunătățire a căutării magice"),
        "changePassword":
            MessageLookupByLibrary.simpleMessage("Schimbare parolă"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Schimbați parola"),
        "changePermissions":
            MessageLookupByLibrary.simpleMessage("Schimbați permisiunile?"),
        "changeYourReferralCode": MessageLookupByLibrary.simpleMessage(
            "Schimbați codul dvs. de recomandare"),
        "checkForUpdates":
            MessageLookupByLibrary.simpleMessage("Căutați actualizări"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Vă rugăm să verificaţi inbox-ul (şi spam) pentru a finaliza verificarea"),
        "checkStatus":
            MessageLookupByLibrary.simpleMessage("Verificați starea"),
        "checking": MessageLookupByLibrary.simpleMessage("Se verifică..."),
        "checkingModels":
            MessageLookupByLibrary.simpleMessage("Se verifică modelele..."),
        "claimFreeStorage":
            MessageLookupByLibrary.simpleMessage("Revendică spațiul gratuit"),
        "claimMore":
            MessageLookupByLibrary.simpleMessage("Revendicați mai multe!"),
        "claimed": MessageLookupByLibrary.simpleMessage("Revendicat"),
        "claimedStorageSoFar": m19,
        "cleanUncategorized":
            MessageLookupByLibrary.simpleMessage("Curățare Necategorisite"),
        "cleanUncategorizedDescription": MessageLookupByLibrary.simpleMessage(
            "Eliminați toate fișierele din „Fără categorie” care sunt prezente în alte albume"),
        "clearCaches":
            MessageLookupByLibrary.simpleMessage("Ștergeți memoria cache"),
        "clearIndexes":
            MessageLookupByLibrary.simpleMessage("Ștergeți indexul"),
        "click": MessageLookupByLibrary.simpleMessage("• Apăsați"),
        "clickOnTheOverflowMenu": MessageLookupByLibrary.simpleMessage(
            "• Apăsați pe meniul suplimentar"),
        "close": MessageLookupByLibrary.simpleMessage("Închidere"),
        "clubByCaptureTime": MessageLookupByLibrary.simpleMessage(
            "Grupare după timpul capturării"),
        "clubByFileName": MessageLookupByLibrary.simpleMessage(
            "Grupare după numele fișierului"),
        "clusteringProgress":
            MessageLookupByLibrary.simpleMessage("Progres grupare"),
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
        "collaborativeLinkCreatedFor": m20,
        "collaborator": MessageLookupByLibrary.simpleMessage("Colaborator"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Colaboratorii pot adăuga fotografii și videoclipuri la albumul distribuit."),
        "collaboratorsSuccessfullyAdded": m21,
        "collageLayout": MessageLookupByLibrary.simpleMessage("Aspect"),
        "collageSaved":
            MessageLookupByLibrary.simpleMessage("Colaj salvat în galerie"),
        "collect": MessageLookupByLibrary.simpleMessage("Colectare"),
        "collectEventPhotos": MessageLookupByLibrary.simpleMessage(
            "Strângeți imagini de la evenimente"),
        "collectPhotos":
            MessageLookupByLibrary.simpleMessage("Colectare fotografii"),
        "collectPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Creați un link unde prietenii dvs. pot încărca fotografii la calitatea originală."),
        "color": MessageLookupByLibrary.simpleMessage("Culoare"),
        "configuration": MessageLookupByLibrary.simpleMessage("Configurare"),
        "confirm": MessageLookupByLibrary.simpleMessage("Confirmare"),
        "confirm2FADisable": MessageLookupByLibrary.simpleMessage(
            "Sigur doriți dezactivarea autentificării cu doi factori?"),
        "confirmAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Confirmați ștergerea contului"),
        "confirmAddingTrustedContact": m22,
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Da, doresc să șterg definitiv acest cont și toate datele sale din toate aplicațiile."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Confirmare parolă"),
        "confirmPlanChange": MessageLookupByLibrary.simpleMessage(
            "Confirmați schimbarea planului"),
        "confirmRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Confirmați cheia de recuperare"),
        "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Confirmați cheia de recuperare"),
        "connectToDevice":
            MessageLookupByLibrary.simpleMessage("Conectați-vă la dispozitiv"),
        "contactFamilyAdmin": m23,
        "contactSupport": MessageLookupByLibrary.simpleMessage(
            "Contactați serviciul de asistență"),
        "contactToManageSubscription": m24,
        "contacts": MessageLookupByLibrary.simpleMessage("Contacte"),
        "contents": MessageLookupByLibrary.simpleMessage("Conținuturi"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("Continuare"),
        "continueOnFreeTrial": MessageLookupByLibrary.simpleMessage(
            "Continuați în perioada de încercare gratuită"),
        "convertToAlbum":
            MessageLookupByLibrary.simpleMessage("Convertire în album"),
        "copyEmailAddress":
            MessageLookupByLibrary.simpleMessage("Copiați adresa de e-mail"),
        "copyLink": MessageLookupByLibrary.simpleMessage("Copere link"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Copiați acest cod\nîn aplicația de autentificare"),
        "couldNotBackUpTryLater": MessageLookupByLibrary.simpleMessage(
            "Nu s-a putut face copie de rezervă datelor.\nSe va reîncerca mai târziu."),
        "couldNotFreeUpSpace":
            MessageLookupByLibrary.simpleMessage("Nu s-a putut elibera spațiu"),
        "couldNotUpdateSubscription": MessageLookupByLibrary.simpleMessage(
            "Nu s-a putut actualiza abonamentul"),
        "count": MessageLookupByLibrary.simpleMessage("Total"),
        "crashReporting":
            MessageLookupByLibrary.simpleMessage("Raportarea problemelor"),
        "create": MessageLookupByLibrary.simpleMessage("Creare"),
        "createAccount": MessageLookupByLibrary.simpleMessage("Creare cont"),
        "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
            "Apăsați lung pentru a selecta fotografii și apăsați pe + pentru a crea un album"),
        "createCollaborativeLink":
            MessageLookupByLibrary.simpleMessage("Creați un link colaborativ"),
        "createCollage": MessageLookupByLibrary.simpleMessage("Creați colaj"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("Creare cont nou"),
        "createOrSelectAlbum": MessageLookupByLibrary.simpleMessage(
            "Creați sau selectați un album"),
        "createPublicLink":
            MessageLookupByLibrary.simpleMessage("Creare link public"),
        "creatingLink":
            MessageLookupByLibrary.simpleMessage("Se crează linkul..."),
        "criticalUpdateAvailable": MessageLookupByLibrary.simpleMessage(
            "Actualizare critică disponibilă"),
        "crop": MessageLookupByLibrary.simpleMessage("Decupare"),
        "currentUsageIs":
            MessageLookupByLibrary.simpleMessage("Utilizarea actuală este "),
        "currentlyRunning":
            MessageLookupByLibrary.simpleMessage("rulează în prezent"),
        "custom": MessageLookupByLibrary.simpleMessage("Particularizat"),
        "customEndpoint": m25,
        "darkTheme": MessageLookupByLibrary.simpleMessage("Întunecată"),
        "dayToday": MessageLookupByLibrary.simpleMessage("Astăzi"),
        "dayYesterday": MessageLookupByLibrary.simpleMessage("Ieri"),
        "declineTrustInvite":
            MessageLookupByLibrary.simpleMessage("Refuzați invitația"),
        "decrypting": MessageLookupByLibrary.simpleMessage("Se decriptează..."),
        "decryptingVideo": MessageLookupByLibrary.simpleMessage(
            "Se decriptează videoclipul..."),
        "deduplicateFiles":
            MessageLookupByLibrary.simpleMessage("Elim. dubluri fișiere"),
        "delete": MessageLookupByLibrary.simpleMessage("Ștergere"),
        "deleteAccount": MessageLookupByLibrary.simpleMessage("Ștergere cont"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "Ne pare rău că plecați. Vă rugăm să împărtășiți feedback-ul dvs. pentru a ne ajuta să ne îmbunătățim."),
        "deleteAccountPermanentlyButton":
            MessageLookupByLibrary.simpleMessage("Ștergeți contul definitiv"),
        "deleteAlbum": MessageLookupByLibrary.simpleMessage("Ştergeţi albumul"),
        "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
            "De asemenea, ștergeți fotografiile (și videoclipurile) prezente în acest album din <bold>toate</bold> celelalte albume din care fac parte?"),
        "deleteAlbumsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Urmează să ștergeți toate albumele goale. Este util atunci când doriți să reduceți dezordinea din lista de albume."),
        "deleteAll": MessageLookupByLibrary.simpleMessage("Ștergeți tot"),
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
            "Acest cont este legat de alte aplicații Ente, dacă utilizați vreuna. Datele dvs. încărcate în toate aplicațiile Ente vor fi programate pentru ștergere, iar contul dvs. va fi șters definitiv."),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "Vă rugăm să trimiteți un e-mail la <warning>account-deletion@ente.io</warning> de pe adresa dvs. de e-mail înregistrată."),
        "deleteEmptyAlbums":
            MessageLookupByLibrary.simpleMessage("Ștergeți albumele goale"),
        "deleteEmptyAlbumsWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Ștergeți albumele goale?"),
        "deleteFromBoth":
            MessageLookupByLibrary.simpleMessage("Ștergeți din ambele"),
        "deleteFromDevice":
            MessageLookupByLibrary.simpleMessage("Ștergeți de pe dispozitiv"),
        "deleteFromEnte":
            MessageLookupByLibrary.simpleMessage("Ștergeți din Ente"),
        "deleteItemCount": m26,
        "deleteLocation":
            MessageLookupByLibrary.simpleMessage("Ștergeți locația"),
        "deletePhotos":
            MessageLookupByLibrary.simpleMessage("Ștergeți fotografiile"),
        "deleteProgress": m27,
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
        "deselectAll":
            MessageLookupByLibrary.simpleMessage("Deselectare totală"),
        "designedToOutlive": MessageLookupByLibrary.simpleMessage(
            "Conceput pentru a supraviețui"),
        "details": MessageLookupByLibrary.simpleMessage("Detalii"),
        "developerSettings":
            MessageLookupByLibrary.simpleMessage("Setări dezvoltator"),
        "developerSettingsWarning": MessageLookupByLibrary.simpleMessage(
            "Sunteți sigur că doriți să modificați setările pentru dezvoltatori?"),
        "deviceCodeHint":
            MessageLookupByLibrary.simpleMessage("Introduceți codul"),
        "deviceFilesAutoUploading": MessageLookupByLibrary.simpleMessage(
            "Fișierele adăugate la acest album de pe dispozitiv vor fi încărcate automat pe Ente."),
        "deviceLock":
            MessageLookupByLibrary.simpleMessage("Blocare dispozitiv"),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
            "Dezactivați blocarea ecranului dispozitivului atunci când Ente este în prim-plan și există o copie de rezervă în curs de desfășurare. În mod normal, acest lucru nu este necesar, dar poate ajuta la finalizarea mai rapidă a încărcărilor mari și a importurilor inițiale de biblioteci mari."),
        "deviceNotFound": MessageLookupByLibrary.simpleMessage(
            "Dispozitivul nu a fost găsit"),
        "didYouKnow": MessageLookupByLibrary.simpleMessage("Știați că?"),
        "disableAutoLock": MessageLookupByLibrary.simpleMessage(
            "Dezactivare blocare automată"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Observatorii pot să facă capturi de ecran sau să salveze o copie a fotografiilor dvs. folosind instrumente externe"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Rețineți"),
        "disableLinkMessage": m28,
        "disableTwofactor": MessageLookupByLibrary.simpleMessage(
            "Dezactivați al doilea factor"),
        "disablingTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Se dezactivează autentificarea cu doi factori..."),
        "discord": MessageLookupByLibrary.simpleMessage("Discord"),
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
        "dismiss": MessageLookupByLibrary.simpleMessage("Renunțați"),
        "distanceInKMUnit": MessageLookupByLibrary.simpleMessage("km"),
        "doNotSignOut": MessageLookupByLibrary.simpleMessage("Nu deconectați"),
        "doThisLater": MessageLookupByLibrary.simpleMessage("Mai târziu"),
        "doYouWantToDiscardTheEditsYouHaveMade":
            MessageLookupByLibrary.simpleMessage(
                "Doriți să renunțați la editările efectuate?"),
        "done": MessageLookupByLibrary.simpleMessage("Finalizat"),
        "doubleYourStorage":
            MessageLookupByLibrary.simpleMessage("Dublați-vă spațiul"),
        "download": MessageLookupByLibrary.simpleMessage("Descărcare"),
        "downloadFailed":
            MessageLookupByLibrary.simpleMessage("Descărcarea nu a reușit"),
        "downloading": MessageLookupByLibrary.simpleMessage("Se descarcă..."),
        "dropSupportEmail": m29,
        "duplicateFileCountWithStorageSaved": m30,
        "duplicateItemsGroup": m31,
        "edit": MessageLookupByLibrary.simpleMessage("Editare"),
        "editLocation": MessageLookupByLibrary.simpleMessage("Editare locaţie"),
        "editLocationTagTitle":
            MessageLookupByLibrary.simpleMessage("Editare locaţie"),
        "editPerson": MessageLookupByLibrary.simpleMessage("Editați persoana"),
        "editsSaved": MessageLookupByLibrary.simpleMessage("Editări salvate"),
        "editsToLocationWillOnlyBeSeenWithinEnte":
            MessageLookupByLibrary.simpleMessage(
                "Editările locației vor fi vizibile doar pe Ente"),
        "eligible": MessageLookupByLibrary.simpleMessage("eligibil"),
        "email": MessageLookupByLibrary.simpleMessage("E-mail"),
        "emailAlreadyRegistered":
            MessageLookupByLibrary.simpleMessage("E-mail deja înregistrat."),
        "emailChangedTo": m32,
        "emailNoEnteAccount": m33,
        "emailNotRegistered": MessageLookupByLibrary.simpleMessage(
            "E-mailul nu este înregistrat."),
        "emailVerificationToggle": MessageLookupByLibrary.simpleMessage(
            "Verificarea adresei de e-mail"),
        "emailYourLogs": MessageLookupByLibrary.simpleMessage(
            "Trimiteți jurnalele prin e-mail"),
        "emergencyContacts":
            MessageLookupByLibrary.simpleMessage("Contacte de urgență"),
        "empty": MessageLookupByLibrary.simpleMessage("Gol"),
        "emptyTrash":
            MessageLookupByLibrary.simpleMessage("Goliți coșul de gunoi?"),
        "enable": MessageLookupByLibrary.simpleMessage("Activare"),
        "enableMLIndexingDesc": MessageLookupByLibrary.simpleMessage(
            "Ente acceptă învățarea automată pe dispozitiv pentru recunoaștere facială, căutarea magică și alte funcții avansate de căutare"),
        "enableMachineLearningBanner": MessageLookupByLibrary.simpleMessage(
            "Activați învățarea automată pentru a folosi căutarea magică și recunoașterea facială"),
        "enableMaps": MessageLookupByLibrary.simpleMessage("Activare hărți"),
        "enableMapsDesc": MessageLookupByLibrary.simpleMessage(
            "Se va afișa fotografiile dvs. pe o hartă a lumii.\n\nAceastă hartă este găzduită de Open Street Map, iar locațiile exacte ale fotografiilor dvs. nu sunt niciodată partajate.\n\nPuteți dezactiva această funcție oricând din Setări."),
        "enabled": MessageLookupByLibrary.simpleMessage("Activat"),
        "encryptingBackup": MessageLookupByLibrary.simpleMessage(
            "Criptare copie de rezervă..."),
        "encryption": MessageLookupByLibrary.simpleMessage("Criptarea"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Chei de criptare"),
        "endpointUpdatedMessage": MessageLookupByLibrary.simpleMessage(
            "Endpoint actualizat cu succes"),
        "endtoendEncryptedByDefault": MessageLookupByLibrary.simpleMessage(
            "Criptare integrală implicită"),
        "enteCanEncryptAndPreserveFilesOnlyIfYouGrant":
            MessageLookupByLibrary.simpleMessage(
                "Ente poate cripta și păstra fișiere numai dacă acordați accesul la acestea"),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
            "Ente <i>are nevoie de permisiune</i> pentru a vă păstra fotografiile"),
        "enteSubscriptionPitch": MessageLookupByLibrary.simpleMessage(
            "Ente vă păstrează amintirile, astfel încât acestea să vă fie întotdeauna disponibile, chiar dacă vă pierdeți dispozitivul."),
        "enteSubscriptionShareWithFamily": MessageLookupByLibrary.simpleMessage(
            "La planul dvs. vi se poate alătura și familia."),
        "enterAlbumName": MessageLookupByLibrary.simpleMessage(
            "Introduceți numele albumului"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Introduceți codul"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
            "Introduceți codul oferit de prietenul dvs. pentru a beneficia de spațiu gratuit pentru amândoi"),
        "enterDateOfBirth":
            MessageLookupByLibrary.simpleMessage("Ziua de naștere (opțional)"),
        "enterEmail":
            MessageLookupByLibrary.simpleMessage("Introduceți e-mailul"),
        "enterFileName": MessageLookupByLibrary.simpleMessage(
            "Introduceți numele fișierului"),
        "enterName": MessageLookupByLibrary.simpleMessage("Introduceți numele"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Introduceți o parolă nouă pe care o putem folosi pentru a cripta datele"),
        "enterPassword":
            MessageLookupByLibrary.simpleMessage("Introduceți parola"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Introduceți o parolă pe care o putem folosi pentru a decripta datele"),
        "enterPersonName": MessageLookupByLibrary.simpleMessage(
            "Introduceți numele persoanei"),
        "enterPin":
            MessageLookupByLibrary.simpleMessage("Introduceţi codul PIN"),
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
        "error": MessageLookupByLibrary.simpleMessage("Eroare"),
        "everywhere": MessageLookupByLibrary.simpleMessage("pretutindeni"),
        "exif": MessageLookupByLibrary.simpleMessage("EXIF"),
        "existingUser":
            MessageLookupByLibrary.simpleMessage("Utilizator existent"),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
            "Acest link a expirat. Vă rugăm să selectați un nou termen de expirare sau să dezactivați expirarea linkului."),
        "exportLogs":
            MessageLookupByLibrary.simpleMessage("Exportați jurnalele"),
        "exportYourData":
            MessageLookupByLibrary.simpleMessage("Export de date"),
        "extraPhotosFound":
            MessageLookupByLibrary.simpleMessage("S-au găsit fotografii extra"),
        "extraPhotosFoundFor": m34,
        "faceNotClusteredYet": MessageLookupByLibrary.simpleMessage(
            "Fața nu este încă grupată, vă rugăm să reveniți mai târziu"),
        "faceRecognition":
            MessageLookupByLibrary.simpleMessage("Recunoaștere facială"),
        "faces": MessageLookupByLibrary.simpleMessage("Fețe"),
        "failedToApplyCode":
            MessageLookupByLibrary.simpleMessage("Codul nu a putut fi aplicat"),
        "failedToCancel":
            MessageLookupByLibrary.simpleMessage("Nu s-a reușit anularea"),
        "failedToDownloadVideo": MessageLookupByLibrary.simpleMessage(
            "Descărcarea videoclipului nu a reușit"),
        "failedToFetchActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Nu s-a reușit preluarea sesiunilor active"),
        "failedToFetchOriginalForEdit": MessageLookupByLibrary.simpleMessage(
            "Nu s-a reușit preluarea originalului pentru editare"),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "Nu se pot obține detaliile recomandării. Vă rugăm să încercați din nou mai târziu."),
        "failedToLoadAlbums": MessageLookupByLibrary.simpleMessage(
            "Încărcarea albumelor nu a reușit"),
        "failedToPlayVideo": MessageLookupByLibrary.simpleMessage(
            "Eroare la redarea videoclipului"),
        "failedToRefreshStripeSubscription":
            MessageLookupByLibrary.simpleMessage(
                "Nu s-a reușit reîmprospătarea abonamentului"),
        "failedToRenew":
            MessageLookupByLibrary.simpleMessage("Nu s-a reușit reînnoirea"),
        "failedToVerifyPaymentStatus": MessageLookupByLibrary.simpleMessage(
            "Verificarea stării plății nu a reușit"),
        "familyPlanOverview": MessageLookupByLibrary.simpleMessage(
            "Adăugați 5 membri ai familiei la planul dvs. existent fără a plăti suplimentar.\n\nFiecare membru primește propriul spațiu privat și nu poate vedea fișierele celuilalt decât dacă acestea sunt partajate.\n\nPlanurile de familie sunt disponibile pentru clienții care au un abonament Ente plătit.\n\nAbonați-vă acum pentru a începe!"),
        "familyPlanPortalTitle":
            MessageLookupByLibrary.simpleMessage("Familie"),
        "familyPlans":
            MessageLookupByLibrary.simpleMessage("Planuri de familie"),
        "faq": MessageLookupByLibrary.simpleMessage("Întrebări frecvente"),
        "faqs": MessageLookupByLibrary.simpleMessage("Întrebări frecvente"),
        "favorite": MessageLookupByLibrary.simpleMessage("Favorit"),
        "feedback": MessageLookupByLibrary.simpleMessage("Feedback"),
        "file": MessageLookupByLibrary.simpleMessage("Fișier"),
        "fileFailedToSaveToGallery": MessageLookupByLibrary.simpleMessage(
            "Salvarea fișierului în galerie nu a reușit"),
        "fileInfoAddDescHint":
            MessageLookupByLibrary.simpleMessage("Adăugați o descriere..."),
        "fileNotUploadedYet": MessageLookupByLibrary.simpleMessage(
            "Fișierul nu a fost încărcat încă"),
        "fileSavedToGallery":
            MessageLookupByLibrary.simpleMessage("Fișier salvat în galerie"),
        "fileTypes": MessageLookupByLibrary.simpleMessage("Tipuri de fișiere"),
        "fileTypesAndNames": MessageLookupByLibrary.simpleMessage(
            "Tipuri de fișiere și denumiri"),
        "filesBackedUpFromDevice": m35,
        "filesBackedUpInAlbum": m36,
        "filesDeleted": MessageLookupByLibrary.simpleMessage("Fișiere șterse"),
        "filesSavedToGallery":
            MessageLookupByLibrary.simpleMessage("Fișiere salvate în galerie"),
        "findPeopleByName": MessageLookupByLibrary.simpleMessage(
            "Găsiți rapid persoane după nume"),
        "findThemQuickly": MessageLookupByLibrary.simpleMessage("Găsiți rapid"),
        "flip": MessageLookupByLibrary.simpleMessage("Răsturnare"),
        "forYourMemories":
            MessageLookupByLibrary.simpleMessage("pentru amintirile dvs."),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Am uitat parola"),
        "foundFaces": MessageLookupByLibrary.simpleMessage("S-au găsit fețe"),
        "freeStorageClaimed":
            MessageLookupByLibrary.simpleMessage("Spațiu gratuit revendicat"),
        "freeStorageOnReferralSuccess": m4,
        "freeStorageUsable":
            MessageLookupByLibrary.simpleMessage("Spațiu gratuit utilizabil"),
        "freeTrial": MessageLookupByLibrary.simpleMessage(
            "Perioadă de încercare gratuită"),
        "freeTrialValidTill": m37,
        "freeUpAccessPostDelete": m38,
        "freeUpAmount": m39,
        "freeUpDeviceSpace": MessageLookupByLibrary.simpleMessage(
            "Eliberați spațiu pe dispozitiv"),
        "freeUpDeviceSpaceDesc": MessageLookupByLibrary.simpleMessage(
            "Economisiți spațiu pe dispozitivul dvs. prin ștergerea fișierelor cărora li s-a făcut copie de rezervă."),
        "freeUpSpace": MessageLookupByLibrary.simpleMessage("Eliberați spațiu"),
        "freeUpSpaceSaving": m40,
        "gallery": MessageLookupByLibrary.simpleMessage("Galerie"),
        "galleryMemoryLimitInfo": MessageLookupByLibrary.simpleMessage(
            "Până la 1000 de amintiri afișate în galerie"),
        "general": MessageLookupByLibrary.simpleMessage("General"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Se generează cheile de criptare..."),
        "genericProgress": m41,
        "goToSettings":
            MessageLookupByLibrary.simpleMessage("Mergeți la setări"),
        "googlePlayId": MessageLookupByLibrary.simpleMessage("ID Google Play"),
        "grantFullAccessPrompt": MessageLookupByLibrary.simpleMessage(
            "Vă rugăm să permiteți accesul la toate fotografiile în aplicația Setări"),
        "grantPermission":
            MessageLookupByLibrary.simpleMessage("Acordați permisiunea"),
        "groupNearbyPhotos": MessageLookupByLibrary.simpleMessage(
            "Grupare fotografii apropiate"),
        "guestView": MessageLookupByLibrary.simpleMessage("Mod oaspete"),
        "guestViewEnablePreSteps": MessageLookupByLibrary.simpleMessage(
            "Pentru a activa modul oaspete, vă rugăm să configurați codul de acces al dispozitivului sau blocarea ecranului în setările sistemului."),
        "hearUsExplanation": MessageLookupByLibrary.simpleMessage(
            "Nu urmărim instalările aplicației. Ne-ar ajuta dacă ne-ați spune unde ne-ați găsit!"),
        "hearUsWhereTitle": MessageLookupByLibrary.simpleMessage(
            "Cum ați auzit de Ente? (opțional)"),
        "help": MessageLookupByLibrary.simpleMessage("Asistență"),
        "hidden": MessageLookupByLibrary.simpleMessage("Ascunse"),
        "hide": MessageLookupByLibrary.simpleMessage("Ascundere"),
        "hideContent":
            MessageLookupByLibrary.simpleMessage("Ascundeți conținutul"),
        "hideContentDescriptionAndroid": MessageLookupByLibrary.simpleMessage(
            "Ascunde conținutul aplicației în comutatorul de aplicații și dezactivează capturile de ecran"),
        "hideContentDescriptionIos": MessageLookupByLibrary.simpleMessage(
            "Ascunde conținutul aplicației în comutatorul de aplicații"),
        "hideSharedItemsFromHomeGallery": MessageLookupByLibrary.simpleMessage(
            "Ascundeți elementele distribuite din galeria principală"),
        "hiding": MessageLookupByLibrary.simpleMessage("Se ascunde..."),
        "hostedAtOsmFrance":
            MessageLookupByLibrary.simpleMessage("Găzduit la OSM Franţa"),
        "howItWorks": MessageLookupByLibrary.simpleMessage("Cum funcţionează"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "Rugați-i să țină apăsat pe adresa de e-mail din ecranul de setări și să verifice dacă ID-urile de pe ambele dispozitive se potrivesc."),
        "iOSGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "Autentificarea biometrică nu este configurată pe dispozitivul dvs. Vă rugăm să activați Touch ID sau Face ID pe telefonul dvs."),
        "iOSLockOut": MessageLookupByLibrary.simpleMessage(
            "Autentificarea biometrică este dezactivată. Vă rugăm să blocați și să deblocați ecranul pentru a o activa."),
        "iOSOkButton": MessageLookupByLibrary.simpleMessage("OK"),
        "ignoreUpdate": MessageLookupByLibrary.simpleMessage("Ignorare"),
        "ignored": MessageLookupByLibrary.simpleMessage("ignorat"),
        "ignoredFolderUploadReason": MessageLookupByLibrary.simpleMessage(
            "Unele fișiere din acest album sunt excluse de la încărcare deoarece au fost șterse anterior din Ente."),
        "imageNotAnalyzed": MessageLookupByLibrary.simpleMessage(
            "Imaginea nu a fost analizată"),
        "immediately": MessageLookupByLibrary.simpleMessage("Imediat"),
        "importing": MessageLookupByLibrary.simpleMessage("Se importă...."),
        "incorrectCode": MessageLookupByLibrary.simpleMessage("Cod incorect"),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Parolă incorectă"),
        "incorrectRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Cheie de recuperare incorectă"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "Cheia de recuperare introdusă este incorectă"),
        "incorrectRecoveryKeyTitle": MessageLookupByLibrary.simpleMessage(
            "Cheie de recuperare incorectă"),
        "indexedItems":
            MessageLookupByLibrary.simpleMessage("Elemente indexate"),
        "indexingIsPaused": MessageLookupByLibrary.simpleMessage(
            "Indexarea este în pauză. Va relua automat când dispozitivul este pregătit."),
        "info": MessageLookupByLibrary.simpleMessage("Informații"),
        "insecureDevice":
            MessageLookupByLibrary.simpleMessage("Dispozitiv nesigur"),
        "installManually":
            MessageLookupByLibrary.simpleMessage("Instalare manuală"),
        "invalidEmailAddress": MessageLookupByLibrary.simpleMessage(
            "Adresa e-mail nu este validă"),
        "invalidEndpoint":
            MessageLookupByLibrary.simpleMessage("Endpoint invalid"),
        "invalidEndpointMessage": MessageLookupByLibrary.simpleMessage(
            "Ne pare rău, endpoint-ul introdus nu este valabil. Vă rugăm să introduceți un endpoint valid și să încercați din nou."),
        "invalidKey": MessageLookupByLibrary.simpleMessage("Cheie invalidă"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Cheia de recuperare pe care ați introdus-o nu este validă. Vă rugăm să vă asigurați că aceasta conține 24 de cuvinte și să verificați ortografia fiecăruia.\n\nDacă ați introdus un cod de recuperare mai vechi, asigurați-vă că acesta conține 64 de caractere și verificați fiecare dintre ele."),
        "invite": MessageLookupByLibrary.simpleMessage("Invitați"),
        "inviteToEnte":
            MessageLookupByLibrary.simpleMessage("Invitați la Ente"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Invitați-vă prietenii"),
        "inviteYourFriendsToEnte": MessageLookupByLibrary.simpleMessage(
            "Invitați-vă prietenii la Ente"),
        "itLooksLikeSomethingWentWrongPleaseRetryAfterSome":
            MessageLookupByLibrary.simpleMessage(
                "Se pare că ceva nu a mers bine. Vă rugăm să încercați din nou după ceva timp. Dacă eroarea persistă, vă rugăm să contactați echipa noastră de asistență."),
        "itemCount": m42,
        "itemsShowTheNumberOfDaysRemainingBeforePermanentDeletion":
            MessageLookupByLibrary.simpleMessage(
                "Articolele afișează numărul de zile rămase până la ștergerea definitivă"),
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "Articolele selectate vor fi eliminate din acest album"),
        "join": MessageLookupByLibrary.simpleMessage("Alăturare"),
        "joinAlbum":
            MessageLookupByLibrary.simpleMessage("Alăturați-vă albumului"),
        "joinAlbumSubtext": MessageLookupByLibrary.simpleMessage(
            "pentru a vedea și a adăuga fotografii"),
        "joinAlbumSubtextViewer": MessageLookupByLibrary.simpleMessage(
            "pentru a adăuga la albumele distribuite"),
        "joinDiscord":
            MessageLookupByLibrary.simpleMessage("Alăturați-vă pe Discord"),
        "keepPhotos":
            MessageLookupByLibrary.simpleMessage("Păstrați fotografiile"),
        "kiloMeterUnit": MessageLookupByLibrary.simpleMessage("km"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Vă rugăm să ne ajutați cu aceste informații"),
        "language": MessageLookupByLibrary.simpleMessage("Limbă"),
        "lastUpdated":
            MessageLookupByLibrary.simpleMessage("Ultima actualizare"),
        "leave": MessageLookupByLibrary.simpleMessage("Părăsiți"),
        "leaveAlbum": MessageLookupByLibrary.simpleMessage("Părăsiți albumul"),
        "leaveFamily": MessageLookupByLibrary.simpleMessage("Părăsiți familia"),
        "leaveSharedAlbum": MessageLookupByLibrary.simpleMessage(
            "Părăsiți albumul distribuit?"),
        "left": MessageLookupByLibrary.simpleMessage("Stânga"),
        "legacy": MessageLookupByLibrary.simpleMessage("Moștenire"),
        "legacyAccounts":
            MessageLookupByLibrary.simpleMessage("Conturi de moștenire"),
        "legacyInvite": m43,
        "legacyPageDesc": MessageLookupByLibrary.simpleMessage(
            "Moștenirea permite contactelor de încredere să vă acceseze contul în absența dvs."),
        "legacyPageDesc2": MessageLookupByLibrary.simpleMessage(
            "Persoanele de contact de încredere pot iniția recuperarea contului și, dacă nu este blocată în termen de 30 de zile, vă pot reseta parola și accesa contul."),
        "light": MessageLookupByLibrary.simpleMessage("Lumină"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("Luminoasă"),
        "linkCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Linkul a fost copiat în clipboard"),
        "linkDeviceLimit":
            MessageLookupByLibrary.simpleMessage("Limită de dispozitive"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Activat"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Expirat"),
        "linkExpiresOn": m44,
        "linkExpiry":
            MessageLookupByLibrary.simpleMessage("Expirarea linkului"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("Linkul a expirat"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Niciodată"),
        "livePhotos": MessageLookupByLibrary.simpleMessage("Fotografii live"),
        "loadMessage1": MessageLookupByLibrary.simpleMessage(
            "Puteți împărți abonamentul cu familia dvs."),
        "loadMessage2": MessageLookupByLibrary.simpleMessage(
            "Am păstrat până acum peste 30 de milioane de amintiri"),
        "loadMessage3": MessageLookupByLibrary.simpleMessage(
            "Păstrăm 3 copii ale datelor dvs., dintre care una într-un adăpost antiatomic subteran"),
        "loadMessage4": MessageLookupByLibrary.simpleMessage(
            "Toate aplicațiile noastre sunt open source"),
        "loadMessage5": MessageLookupByLibrary.simpleMessage(
            "Codul nostru sursă și criptografia au fost evaluate extern"),
        "loadMessage6": MessageLookupByLibrary.simpleMessage(
            "Puteți distribui linkuri către albumele dvs. celor dragi"),
        "loadMessage7": MessageLookupByLibrary.simpleMessage(
            "Aplicațiile noastre mobile rulează în fundal pentru a cripta și salva orice fotografie nouă pe care o realizați"),
        "loadMessage8": MessageLookupByLibrary.simpleMessage(
            "web.ente.io are un instrument de încărcare sofisticat"),
        "loadMessage9": MessageLookupByLibrary.simpleMessage(
            "Folosim Xchacha20Poly1305 pentru a vă cripta datele în siguranță"),
        "loadingExifData":
            MessageLookupByLibrary.simpleMessage("Se încarcă date EXIF..."),
        "loadingGallery":
            MessageLookupByLibrary.simpleMessage("Se încarcă galeria..."),
        "loadingMessage":
            MessageLookupByLibrary.simpleMessage("Se încarcă fotografiile..."),
        "loadingModel":
            MessageLookupByLibrary.simpleMessage("Se descarcă modelele..."),
        "loadingYourPhotos": MessageLookupByLibrary.simpleMessage(
            "Se încarcă fotografiile dvs..."),
        "localGallery": MessageLookupByLibrary.simpleMessage("Galerie locală"),
        "localIndexing":
            MessageLookupByLibrary.simpleMessage("Indexare locală"),
        "localSyncErrorMessage": MessageLookupByLibrary.simpleMessage(
            "Se pare că ceva nu a mers bine, deoarece sincronizarea fotografiilor locale durează mai mult decât ne așteptam. Vă rugăm să contactați echipa noastră de asistență"),
        "location": MessageLookupByLibrary.simpleMessage("Locație"),
        "locationName": MessageLookupByLibrary.simpleMessage("Numele locației"),
        "locationTagFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "O etichetă de locație grupează toate fotografiile care au fost făcute pe o anumită rază a unei fotografii"),
        "locations": MessageLookupByLibrary.simpleMessage("Locații"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Blocat"),
        "lockscreen": MessageLookupByLibrary.simpleMessage("Ecran de blocare"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Conectare"),
        "loggingOut":
            MessageLookupByLibrary.simpleMessage("Se deconectează..."),
        "loginSessionExpired":
            MessageLookupByLibrary.simpleMessage("Sesiune expirată"),
        "loginSessionExpiredDetails": MessageLookupByLibrary.simpleMessage(
            "Sesiunea a expirat. Vă rugăm să vă autentificați din nou."),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "Apăsând pe „Conectare”, sunteți de acord cu <u-terms>termenii de prestare ai serviciului</u-terms> și <u-policy>politica de confidenţialitate</u-policy>"),
        "loginWithTOTP": MessageLookupByLibrary.simpleMessage(
            "Autentificare cu parolă unică (TOTP)"),
        "logout": MessageLookupByLibrary.simpleMessage("Deconectare"),
        "logsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Aceasta va trimite jurnalele pentru a ne ajuta să depistăm problema. Vă rugăm să rețineți că numele fișierelor vor fi incluse pentru a ne ajuta să urmărim problemele cu anumite fișiere."),
        "longPressAnEmailToVerifyEndToEndEncryption":
            MessageLookupByLibrary.simpleMessage(
                "Apăsați lung un e-mail pentru a verifica criptarea integrală."),
        "longpressOnAnItemToViewInFullscreen":
            MessageLookupByLibrary.simpleMessage(
                "Apăsați lung pe un articol pentru a-l vizualiza pe tot ecranul"),
        "loopVideoOff":
            MessageLookupByLibrary.simpleMessage("Repetare video dezactivată"),
        "loopVideoOn":
            MessageLookupByLibrary.simpleMessage("Repetare video activată"),
        "lostDevice":
            MessageLookupByLibrary.simpleMessage("Dispozitiv pierdut?"),
        "machineLearning":
            MessageLookupByLibrary.simpleMessage("Învățare automată"),
        "magicSearch": MessageLookupByLibrary.simpleMessage("Căutare magică"),
        "magicSearchHint": MessageLookupByLibrary.simpleMessage(
            "Căutarea magică permite căutarea fotografiilor după conținutul lor, de exemplu, „floare”, „mașină roșie”, „documente de identitate”"),
        "manage": MessageLookupByLibrary.simpleMessage("Gestionare"),
        "manageDeviceStorage": MessageLookupByLibrary.simpleMessage(
            "Gestionați memoria cache a dispozitivului"),
        "manageDeviceStorageDesc": MessageLookupByLibrary.simpleMessage(
            "Revizuiți și ștergeți spațiul din memoria cache locală."),
        "manageFamily":
            MessageLookupByLibrary.simpleMessage("Administrați familia"),
        "manageLink": MessageLookupByLibrary.simpleMessage("Gestionați linkul"),
        "manageParticipants":
            MessageLookupByLibrary.simpleMessage("Gestionare"),
        "manageSubscription":
            MessageLookupByLibrary.simpleMessage("Gestionare abonament"),
        "manualPairDesc": MessageLookupByLibrary.simpleMessage(
            "Asocierea cu PIN funcționează cu orice ecran pe care doriți să vizualizați albumul."),
        "map": MessageLookupByLibrary.simpleMessage("Hartă"),
        "maps": MessageLookupByLibrary.simpleMessage("Hărţi"),
        "mastodon": MessageLookupByLibrary.simpleMessage("Mastodon"),
        "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
        "memoryCount": m5,
        "merchandise": MessageLookupByLibrary.simpleMessage("Produse"),
        "mergeWithExisting":
            MessageLookupByLibrary.simpleMessage("Îmbinare cu unul existent"),
        "mergedPhotos":
            MessageLookupByLibrary.simpleMessage("Fotografii combinate"),
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
        "mobileWebDesktop":
            MessageLookupByLibrary.simpleMessage("Mobil, Web, Desktop"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Moderată"),
        "modifyYourQueryOrTrySearchingFor":
            MessageLookupByLibrary.simpleMessage(
                "Modificați interogarea sau încercați să căutați"),
        "moments": MessageLookupByLibrary.simpleMessage("Momente"),
        "month": MessageLookupByLibrary.simpleMessage("lună"),
        "monthly": MessageLookupByLibrary.simpleMessage("Lunar"),
        "moreDetails":
            MessageLookupByLibrary.simpleMessage("Mai multe detalii"),
        "mostRecent": MessageLookupByLibrary.simpleMessage("Cele mai recente"),
        "mostRelevant":
            MessageLookupByLibrary.simpleMessage("Cele mai relevante"),
        "moveItem": m45,
        "moveToAlbum": MessageLookupByLibrary.simpleMessage("Mutare în album"),
        "moveToHiddenAlbum":
            MessageLookupByLibrary.simpleMessage("Mutați în albumul ascuns"),
        "movedSuccessfullyTo": m46,
        "movedToTrash":
            MessageLookupByLibrary.simpleMessage("S-a mutat în coșul de gunoi"),
        "movingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Se mută fișierele în album..."),
        "name": MessageLookupByLibrary.simpleMessage("Nume"),
        "nameTheAlbum":
            MessageLookupByLibrary.simpleMessage("Denumiți albumul"),
        "networkConnectionRefusedErr": MessageLookupByLibrary.simpleMessage(
            "Nu se poate conecta la Ente, vă rugăm să reîncercați după un timp. Dacă eroarea persistă, contactați asistența."),
        "networkHostLookUpErr": MessageLookupByLibrary.simpleMessage(
            "Nu se poate conecta la Ente, vă rugăm să verificați setările de rețea și să contactați asistenta dacă eroarea persistă."),
        "never": MessageLookupByLibrary.simpleMessage("Niciodată"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Album nou"),
        "newLocation": MessageLookupByLibrary.simpleMessage("Locație nouă"),
        "newPerson": MessageLookupByLibrary.simpleMessage("Persoană nouă"),
        "newToEnte": MessageLookupByLibrary.simpleMessage("Nou la Ente"),
        "newest": MessageLookupByLibrary.simpleMessage("Cele mai noi"),
        "next": MessageLookupByLibrary.simpleMessage("Înainte"),
        "no": MessageLookupByLibrary.simpleMessage("Nu"),
        "noAlbumsSharedByYouYet": MessageLookupByLibrary.simpleMessage(
            "Niciun album nu a fost distribuit de dvs. încă"),
        "noDeviceFound":
            MessageLookupByLibrary.simpleMessage("Niciun dispozitiv găsit"),
        "noDeviceLimit": MessageLookupByLibrary.simpleMessage("Niciuna"),
        "noDeviceThatCanBeDeleted": MessageLookupByLibrary.simpleMessage(
            "Nu aveți fișiere pe acest dispozitiv care pot fi șterse"),
        "noDuplicates": MessageLookupByLibrary.simpleMessage("✨ Fără dubluri"),
        "noExifData":
            MessageLookupByLibrary.simpleMessage("Nu există date EXIF"),
        "noFacesFound":
            MessageLookupByLibrary.simpleMessage("Nu au fost găsite fețe"),
        "noHiddenPhotosOrVideos": MessageLookupByLibrary.simpleMessage(
            "Fără poze sau videoclipuri ascunse"),
        "noImagesWithLocation":
            MessageLookupByLibrary.simpleMessage("Nicio imagine cu locație"),
        "noInternetConnection": MessageLookupByLibrary.simpleMessage(
            "Nu există conexiune la internet"),
        "noPhotosAreBeingBackedUpRightNow":
            MessageLookupByLibrary.simpleMessage(
                "Nicio fotografie nu este salvată în acest moment"),
        "noPhotosFoundHere": MessageLookupByLibrary.simpleMessage(
            "Nu s-au găsit fotografii aici"),
        "noQuickLinksSelected": MessageLookupByLibrary.simpleMessage(
            "Nu au fost găsite linkuri rapide"),
        "noRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Nu aveți cheia de recuperare?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "Datorită naturii protocolului nostru de criptare integrală, datele dvs. nu pot fi decriptate fără parola sau cheia dvs. de recuperare"),
        "noResults": MessageLookupByLibrary.simpleMessage("Niciun rezultat"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("Nu s-au găsit rezultate"),
        "noSuggestionsForPerson": m47,
        "noSystemLockFound": MessageLookupByLibrary.simpleMessage(
            "Nu s-a găsit nicio blocare de sistem"),
        "notPersonLabel": m48,
        "nothingSharedWithYouYet": MessageLookupByLibrary.simpleMessage(
            "Nimic distribuit cu dvs. încă"),
        "nothingToSeeHere":
            MessageLookupByLibrary.simpleMessage("Nimic de văzut aici! 👀"),
        "notifications": MessageLookupByLibrary.simpleMessage("Notificări"),
        "ok": MessageLookupByLibrary.simpleMessage("Ok"),
        "onDevice": MessageLookupByLibrary.simpleMessage("Pe dispozitiv"),
        "onEnte": MessageLookupByLibrary.simpleMessage(
            "Pe <branding>ente</branding>"),
        "onlyFamilyAdminCanChangeCode": m49,
        "onlyThem": MessageLookupByLibrary.simpleMessage("Numai el/ea"),
        "oops": MessageLookupByLibrary.simpleMessage("Ups"),
        "oopsCouldNotSaveEdits": MessageLookupByLibrary.simpleMessage(
            "Hopa, nu s-au putut salva editările"),
        "oopsSomethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Hopa, ceva nu a mers bine"),
        "openAlbumInBrowser": MessageLookupByLibrary.simpleMessage(
            "Deschideți albumul în browser"),
        "openAlbumInBrowserTitle": MessageLookupByLibrary.simpleMessage(
            "Vă rugăm să utilizați aplicația web pentru a adăuga fotografii la acest album"),
        "openFile": MessageLookupByLibrary.simpleMessage("Deschidere fișier"),
        "openSettings":
            MessageLookupByLibrary.simpleMessage("Deschideți Setări"),
        "openTheItem":
            MessageLookupByLibrary.simpleMessage("• Deschideți articolul"),
        "openstreetmapContributors":
            MessageLookupByLibrary.simpleMessage("Contribuitori OpenStreetMap"),
        "optionalAsShortAsYouLike": MessageLookupByLibrary.simpleMessage(
            "Opțional, cât de scurt doriți..."),
        "orMergeWithExistingPerson": MessageLookupByLibrary.simpleMessage(
            "Sau îmbinați cu cele existente"),
        "orPickAnExistingOne":
            MessageLookupByLibrary.simpleMessage("Sau alegeți unul existent"),
        "pair": MessageLookupByLibrary.simpleMessage("Asociere"),
        "pairWithPin": MessageLookupByLibrary.simpleMessage("Asociere cu PIN"),
        "pairingComplete":
            MessageLookupByLibrary.simpleMessage("Asociere reușită"),
        "panorama": MessageLookupByLibrary.simpleMessage("Panoramă"),
        "passKeyPendingVerification": MessageLookupByLibrary.simpleMessage(
            "Verificarea este încă în așteptare"),
        "passkey": MessageLookupByLibrary.simpleMessage("Cheie de acces"),
        "passkeyAuthTitle":
            MessageLookupByLibrary.simpleMessage("Verificare cheie de acces"),
        "password": MessageLookupByLibrary.simpleMessage("Parolă"),
        "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
            "Parola a fost schimbată cu succes"),
        "passwordLock":
            MessageLookupByLibrary.simpleMessage("Blocare cu parolă"),
        "passwordStrength": m0,
        "passwordStrengthInfo": MessageLookupByLibrary.simpleMessage(
            "Puterea parolei este calculată luând în considerare lungimea parolei, caracterele utilizate și dacă parola apare sau nu în top 10.000 cele mai utilizate parole"),
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Nu reținem această parolă, deci dacă o uitați <underline>nu vă putem decripta datele</underline>"),
        "paymentDetails":
            MessageLookupByLibrary.simpleMessage("Detalii de plată"),
        "paymentFailed":
            MessageLookupByLibrary.simpleMessage("Plata nu a reușit"),
        "paymentFailedMessage": MessageLookupByLibrary.simpleMessage(
            "Din păcate, plata dvs. nu a reușit. Vă rugăm să contactați asistență și vom fi bucuroși să vă ajutăm!"),
        "paymentFailedTalkToProvider": m50,
        "pendingItems":
            MessageLookupByLibrary.simpleMessage("Elemente în așteptare"),
        "pendingSync":
            MessageLookupByLibrary.simpleMessage("Sincronizare în așteptare"),
        "people": MessageLookupByLibrary.simpleMessage("Persoane"),
        "peopleUsingYourCode": MessageLookupByLibrary.simpleMessage(
            "Persoane care folosesc codul dvs."),
        "permDeleteWarning": MessageLookupByLibrary.simpleMessage(
            "Toate articolele din coșul de gunoi vor fi șterse definitiv\n\nAceastă acțiune nu poate fi anulată"),
        "permanentlyDelete":
            MessageLookupByLibrary.simpleMessage("Ștergere definitivă"),
        "permanentlyDeleteFromDevice": MessageLookupByLibrary.simpleMessage(
            "Ștergeți permanent de pe dispozitiv?"),
        "personName": MessageLookupByLibrary.simpleMessage("Numele persoanei"),
        "photoDescriptions":
            MessageLookupByLibrary.simpleMessage("Descrieri fotografie"),
        "photoGridSize":
            MessageLookupByLibrary.simpleMessage("Dimensiunea grilei foto"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("fotografie"),
        "photos": MessageLookupByLibrary.simpleMessage("Fotografii"),
        "photosAddedByYouWillBeRemovedFromTheAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Fotografiile adăugate de dvs. vor fi eliminate din album"),
        "photosCount": m51,
        "pickCenterPoint":
            MessageLookupByLibrary.simpleMessage("Alegeți punctul central"),
        "pinAlbum": MessageLookupByLibrary.simpleMessage("Fixați albumul"),
        "pinLock": MessageLookupByLibrary.simpleMessage("Blocare PIN"),
        "playOnTv": MessageLookupByLibrary.simpleMessage("Redare album pe TV"),
        "playStoreFreeTrialValidTill": m52,
        "playstoreSubscription":
            MessageLookupByLibrary.simpleMessage("Abonament PlayStore"),
        "pleaseCheckYourInternetConnectionAndTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Vă rugăm să verificați conexiunea la internet și să încercați din nou."),
        "pleaseContactSupportAndWeWillBeHappyToHelp":
            MessageLookupByLibrary.simpleMessage(
                "Vă rugăm să contactați support@ente.io și vom fi bucuroși să vă ajutăm!"),
        "pleaseContactSupportIfTheProblemPersists":
            MessageLookupByLibrary.simpleMessage(
                "Vă rugăm să contactați asistența dacă problema persistă"),
        "pleaseEmailUsAt": m53,
        "pleaseGrantPermissions": MessageLookupByLibrary.simpleMessage(
            "Vă rugăm să acordați permisiuni"),
        "pleaseLoginAgain": MessageLookupByLibrary.simpleMessage(
            "Vă rugăm, autentificați-vă din nou"),
        "pleaseSelectQuickLinksToRemove": MessageLookupByLibrary.simpleMessage(
            "Vă rugăm să selectați linkurile rapide de eliminat"),
        "pleaseSendTheLogsTo": m54,
        "pleaseTryAgain": MessageLookupByLibrary.simpleMessage(
            "Vă rugăm să încercați din nou"),
        "pleaseVerifyTheCodeYouHaveEntered":
            MessageLookupByLibrary.simpleMessage(
                "Vă rugăm să verificați codul introdus"),
        "pleaseWait":
            MessageLookupByLibrary.simpleMessage("Vă rugăm așteptați..."),
        "pleaseWaitDeletingAlbum": MessageLookupByLibrary.simpleMessage(
            "Vă rugăm așteptați, se șterge albumul"),
        "pleaseWaitForSometimeBeforeRetrying":
            MessageLookupByLibrary.simpleMessage(
                "Vă rugăm să așteptați un moment înainte să reîncercați"),
        "preparingLogs":
            MessageLookupByLibrary.simpleMessage("Se pregătesc jurnalele..."),
        "preserveMore":
            MessageLookupByLibrary.simpleMessage("Păstrați mai multe"),
        "pressAndHoldToPlayVideo": MessageLookupByLibrary.simpleMessage(
            "Apăsați lung pentru a reda videoclipul"),
        "pressAndHoldToPlayVideoDetailed": MessageLookupByLibrary.simpleMessage(
            "Apăsați lung pe imagine pentru a reda videoclipul"),
        "privacy": MessageLookupByLibrary.simpleMessage("Confidențialitate"),
        "privacyPolicyTitle": MessageLookupByLibrary.simpleMessage(
            "Politică de confidențialitate"),
        "privateBackups":
            MessageLookupByLibrary.simpleMessage("Copii de rezervă private"),
        "privateSharing":
            MessageLookupByLibrary.simpleMessage("Distribuire privată"),
        "proceed": MessageLookupByLibrary.simpleMessage("Continuați"),
        "processed": MessageLookupByLibrary.simpleMessage("Procesate"),
        "processingImport": m55,
        "publicLinkCreated":
            MessageLookupByLibrary.simpleMessage("Link public creat"),
        "publicLinkEnabled":
            MessageLookupByLibrary.simpleMessage("Link public activat"),
        "quickLinks": MessageLookupByLibrary.simpleMessage("Link-uri rapide"),
        "radius": MessageLookupByLibrary.simpleMessage("Rază"),
        "raiseTicket":
            MessageLookupByLibrary.simpleMessage("Solicitați asistență"),
        "rateTheApp":
            MessageLookupByLibrary.simpleMessage("Evaluați aplicația"),
        "rateUs": MessageLookupByLibrary.simpleMessage("Evaluați-ne"),
        "rateUsOnStore": m56,
        "recover": MessageLookupByLibrary.simpleMessage("Recuperare"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("Recuperare cont"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Recuperare"),
        "recoveryAccount":
            MessageLookupByLibrary.simpleMessage("Recuperare cont"),
        "recoveryInitiated":
            MessageLookupByLibrary.simpleMessage("Recuperare inițiată"),
        "recoveryInitiatedDesc": m57,
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
        "recoveryReady": m58,
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("Recuperare reușită!"),
        "recoveryWarning": MessageLookupByLibrary.simpleMessage(
            "Un contact de încredere încearcă să vă acceseze contul"),
        "recoveryWarningBody": m59,
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "Dispozitivul actual nu este suficient de puternic pentru a vă verifica parola, dar o putem regenera într-un mod care să funcționeze cu toate dispozitivele.\n\nVă rugăm să vă conectați utilizând cheia de recuperare și să vă regenerați parola (dacă doriți, o puteți utiliza din nou pe aceeași)."),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Refaceți parola"),
        "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
        "reenterPassword":
            MessageLookupByLibrary.simpleMessage("Reintroduceți parola"),
        "reenterPin":
            MessageLookupByLibrary.simpleMessage("Reintroduceți codul PIN"),
        "referFriendsAnd2xYourPlan": MessageLookupByLibrary.simpleMessage(
            "Recomandați un prieten și dublați-vă planul"),
        "referralStep1": MessageLookupByLibrary.simpleMessage(
            "1. Dați acest cod prietenilor"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "2. Aceștia se înscriu la un plan cu plată"),
        "referralStep3": m60,
        "referrals": MessageLookupByLibrary.simpleMessage("Recomandări"),
        "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
            "Recomandările sunt momentan întrerupte"),
        "rejectRecovery":
            MessageLookupByLibrary.simpleMessage("Respingeți recuperarea"),
        "remindToEmptyDeviceTrash": MessageLookupByLibrary.simpleMessage(
            "De asemenea, goliți dosarul „Șterse recent” din „Setări” -> „Spațiu” pentru a recupera spațiul eliberat"),
        "remindToEmptyEnteTrash": MessageLookupByLibrary.simpleMessage(
            "De asemenea, goliți „Coșul de gunoi” pentru a revendica spațiul eliberat"),
        "remoteImages":
            MessageLookupByLibrary.simpleMessage("Imagini la distanță"),
        "remoteThumbnails":
            MessageLookupByLibrary.simpleMessage("Miniaturi la distanță"),
        "remoteVideos":
            MessageLookupByLibrary.simpleMessage("Videoclipuri la distanță"),
        "remove": MessageLookupByLibrary.simpleMessage("Eliminare"),
        "removeDuplicates":
            MessageLookupByLibrary.simpleMessage("Eliminați dublurile"),
        "removeDuplicatesDesc": MessageLookupByLibrary.simpleMessage(
            "Revizuiți și eliminați fișierele care sunt dubluri exacte."),
        "removeFromAlbum":
            MessageLookupByLibrary.simpleMessage("Eliminați din album"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("Eliminați din album?"),
        "removeFromFavorite":
            MessageLookupByLibrary.simpleMessage("Eliminați din favorite"),
        "removeInvite":
            MessageLookupByLibrary.simpleMessage("Eliminare invitație"),
        "removeLink": MessageLookupByLibrary.simpleMessage("Eliminați linkul"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Eliminați participantul"),
        "removeParticipantBody": m61,
        "removePersonLabel": MessageLookupByLibrary.simpleMessage(
            "Eliminați eticheta persoanei"),
        "removePublicLink":
            MessageLookupByLibrary.simpleMessage("Eliminați linkul public"),
        "removePublicLinks":
            MessageLookupByLibrary.simpleMessage("Eliminați linkurile publice"),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
            "Unele dintre articolele pe care le eliminați au fost adăugate de alte persoane și veți pierde accesul la acestea"),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Eliminați?"),
        "removeYourselfAsTrustedContact": MessageLookupByLibrary.simpleMessage(
            "Eliminați-vă ca persoană de contact de încredere"),
        "removingFromFavorites":
            MessageLookupByLibrary.simpleMessage("Se elimină din favorite..."),
        "rename": MessageLookupByLibrary.simpleMessage("Redenumire"),
        "renameAlbum": MessageLookupByLibrary.simpleMessage("Redenumire album"),
        "renameFile":
            MessageLookupByLibrary.simpleMessage("Redenumiți fișierul"),
        "renewSubscription":
            MessageLookupByLibrary.simpleMessage("Reînnoire abonament"),
        "renewsOn": m62,
        "reportABug":
            MessageLookupByLibrary.simpleMessage("Raportați o eroare"),
        "reportBug": MessageLookupByLibrary.simpleMessage("Raportare eroare"),
        "resendEmail":
            MessageLookupByLibrary.simpleMessage("Retrimitere e-mail"),
        "resetIgnoredFiles":
            MessageLookupByLibrary.simpleMessage("Resetare fișiere ignorate"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Resetați parola"),
        "resetPerson": MessageLookupByLibrary.simpleMessage("Eliminare"),
        "resetToDefault": MessageLookupByLibrary.simpleMessage(
            "Resetare la valori implicite"),
        "restore": MessageLookupByLibrary.simpleMessage("Restaurare"),
        "restoreToAlbum":
            MessageLookupByLibrary.simpleMessage("Restaurare în album"),
        "restoringFiles":
            MessageLookupByLibrary.simpleMessage("Se restaurează fișierele..."),
        "resumableUploads":
            MessageLookupByLibrary.simpleMessage("Reluare încărcări"),
        "retry": MessageLookupByLibrary.simpleMessage("Încercați din nou"),
        "review": MessageLookupByLibrary.simpleMessage("Examinați"),
        "reviewDeduplicateItems": MessageLookupByLibrary.simpleMessage(
            "Vă rugăm să revizuiți și să ștergeți articolele pe care le considerați a fi dubluri."),
        "reviewSuggestions":
            MessageLookupByLibrary.simpleMessage("Revizuire sugestii"),
        "right": MessageLookupByLibrary.simpleMessage("Dreapta"),
        "rotate": MessageLookupByLibrary.simpleMessage("Rotire"),
        "rotateLeft": MessageLookupByLibrary.simpleMessage("Rotire la stânga"),
        "rotateRight":
            MessageLookupByLibrary.simpleMessage("Rotire la dreapta"),
        "safelyStored":
            MessageLookupByLibrary.simpleMessage("Stocare în siguranță"),
        "save": MessageLookupByLibrary.simpleMessage("Salvare"),
        "saveCollage": MessageLookupByLibrary.simpleMessage("Salvați colajul"),
        "saveCopy": MessageLookupByLibrary.simpleMessage("Salvare copie"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Salvați cheia"),
        "savePerson": MessageLookupByLibrary.simpleMessage("Salvați persoana"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Salvați cheia de recuperare, dacă nu ați făcut-o deja"),
        "saving": MessageLookupByLibrary.simpleMessage("Se salvează..."),
        "savingEdits":
            MessageLookupByLibrary.simpleMessage("Se salvează editările..."),
        "scanCode": MessageLookupByLibrary.simpleMessage("Scanare cod"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Scanați acest cod de bare\ncu aplicația de autentificare"),
        "search": MessageLookupByLibrary.simpleMessage("Căutare"),
        "searchAlbumsEmptySection":
            MessageLookupByLibrary.simpleMessage("Albume"),
        "searchByAlbumNameHint":
            MessageLookupByLibrary.simpleMessage("Nume album"),
        "searchByExamples": MessageLookupByLibrary.simpleMessage(
            "• Nume de album (ex. „Cameră”)\n• Tipuri de fișiere (ex. „Videoclipuri”, „.gif”)\n• Ani și luni (ex. „2022”, „Ianuarie”)\n• Sărbători (ex. „Crăciun”)\n• Descrieri ale fotografiilor (ex. „#distracție”)"),
        "searchCaptionEmptySection": MessageLookupByLibrary.simpleMessage(
            "Adăugați descrieri precum „#excursie” în informațiile fotografiilor pentru a le găsi ușor aici"),
        "searchDatesEmptySection": MessageLookupByLibrary.simpleMessage(
            "Căutare după o dată, o lună sau un an"),
        "searchDiscoverEmptySection": MessageLookupByLibrary.simpleMessage(
            "Imaginile vor fi afișate aici odată ce procesarea și sincronizarea este completă"),
        "searchFaceEmptySection": MessageLookupByLibrary.simpleMessage(
            "Persoanele vor fi afișate aici odată ce indexarea este finalizată"),
        "searchFileTypesAndNamesEmptySection":
            MessageLookupByLibrary.simpleMessage(
                "Tipuri de fișiere și denumiri"),
        "searchHint1": MessageLookupByLibrary.simpleMessage(
            "Căutare rapidă, pe dispozitiv"),
        "searchHint2": MessageLookupByLibrary.simpleMessage(
            "Date, descrieri ale fotografiilor"),
        "searchHint3": MessageLookupByLibrary.simpleMessage(
            "Albume, numele fișierelor și tipuri"),
        "searchHint4": MessageLookupByLibrary.simpleMessage("Locație"),
        "searchHint5": MessageLookupByLibrary.simpleMessage(
            "În curând: chipuri și căutare magică ✨"),
        "searchLocationEmptySection": MessageLookupByLibrary.simpleMessage(
            "Grupare fotografii realizate în raza unei fotografii"),
        "searchPeopleEmptySection": MessageLookupByLibrary.simpleMessage(
            "Invitați persoane și veți vedea aici toate fotografiile distribuite de acestea"),
        "searchPersonsEmptySection": MessageLookupByLibrary.simpleMessage(
            "Persoanele vor fi afișate aici odată ce procesarea și sincronizarea este completă"),
        "searchResultCount": m63,
        "searchSectionsLengthMismatch": m64,
        "security": MessageLookupByLibrary.simpleMessage("Securitate"),
        "seePublicAlbumLinksInApp": MessageLookupByLibrary.simpleMessage(
            "Vedeți linkurile albumelor publice în aplicație"),
        "selectALocation":
            MessageLookupByLibrary.simpleMessage("Selectați o locație"),
        "selectALocationFirst": MessageLookupByLibrary.simpleMessage(
            "Selectați mai întâi o locație"),
        "selectAlbum": MessageLookupByLibrary.simpleMessage("Selectare album"),
        "selectAll": MessageLookupByLibrary.simpleMessage("Selectare totală"),
        "selectAllShort": MessageLookupByLibrary.simpleMessage("Toate"),
        "selectCoverPhoto": MessageLookupByLibrary.simpleMessage(
            "Selectați fotografia de copertă"),
        "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
            "Selectați folderele pentru copie de rezervă"),
        "selectItemsToAdd": MessageLookupByLibrary.simpleMessage(
            "Selectați elementele de adăugat"),
        "selectLanguage":
            MessageLookupByLibrary.simpleMessage("Selectaţi limba"),
        "selectMailApp": MessageLookupByLibrary.simpleMessage(
            "Selectați aplicația de e-mail"),
        "selectMorePhotos": MessageLookupByLibrary.simpleMessage(
            "Selectați mai multe fotografii"),
        "selectReason":
            MessageLookupByLibrary.simpleMessage("Selectați motivul"),
        "selectYourPlan":
            MessageLookupByLibrary.simpleMessage("Selectați planul"),
        "selectedFilesAreNotOnEnte": MessageLookupByLibrary.simpleMessage(
            "Fișierele selectate nu sunt pe Ente"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "Dosarele selectate vor fi criptate și salvate"),
        "selectedItemsWillBeDeletedFromAllAlbumsAndMoved":
            MessageLookupByLibrary.simpleMessage(
                "Articolele selectate vor fi șterse din toate albumele și mutate în coșul de gunoi."),
        "selectedPhotos": m6,
        "selectedPhotosWithYours": m65,
        "send": MessageLookupByLibrary.simpleMessage("Trimitere"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("Trimiteți e-mail"),
        "sendInvite":
            MessageLookupByLibrary.simpleMessage("Trimiteți invitația"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Trimitere link"),
        "serverEndpoint": MessageLookupByLibrary.simpleMessage(
            "Adresa (endpoint) server-ului"),
        "sessionExpired":
            MessageLookupByLibrary.simpleMessage("Sesiune expirată"),
        "sessionIdMismatch":
            MessageLookupByLibrary.simpleMessage("Nepotrivire ID sesiune"),
        "setAPassword": MessageLookupByLibrary.simpleMessage("Setați o parolă"),
        "setAs": MessageLookupByLibrary.simpleMessage("Setare ca"),
        "setCover": MessageLookupByLibrary.simpleMessage("Setare copertă"),
        "setLabel": MessageLookupByLibrary.simpleMessage("Setare"),
        "setNewPassword":
            MessageLookupByLibrary.simpleMessage("Setați parola noua"),
        "setNewPin":
            MessageLookupByLibrary.simpleMessage("Setați un cod nou PIN"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Setați parola"),
        "setRadius": MessageLookupByLibrary.simpleMessage("Setare rază"),
        "setupComplete":
            MessageLookupByLibrary.simpleMessage("Configurare finalizată"),
        "share": MessageLookupByLibrary.simpleMessage("Distribuire"),
        "shareALink":
            MessageLookupByLibrary.simpleMessage("Distribuiți un link"),
        "shareAlbumHint": MessageLookupByLibrary.simpleMessage(
            "Deschideți un album și atingeți butonul de distribuire din dreapta sus pentru a distribui."),
        "shareAnAlbumNow":
            MessageLookupByLibrary.simpleMessage("Distribuiți un album acum"),
        "shareLink": MessageLookupByLibrary.simpleMessage("Distribuiți linkul"),
        "shareMyVerificationID": m66,
        "shareOnlyWithThePeopleYouWant": MessageLookupByLibrary.simpleMessage(
            "Distribuiți numai cu persoanele pe care le doriți"),
        "shareTextConfirmOthersVerificationID": m7,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Descarcă Ente pentru a putea distribui cu ușurință fotografii și videoclipuri în calitate originală\n\nhttps://ente.io"),
        "shareTextReferralCode": m67,
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
            "Distribuiți cu utilizatori din afara Ente"),
        "shareWithPeopleSectionTitle": m68,
        "shareYourFirstAlbum":
            MessageLookupByLibrary.simpleMessage("Distribuiți primul album"),
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Creați albume distribuite și colaborative cu alți utilizatori Ente, inclusiv cu utilizatorii planurilor gratuite."),
        "sharedByMe":
            MessageLookupByLibrary.simpleMessage("Distribuit de către mine"),
        "sharedByYou":
            MessageLookupByLibrary.simpleMessage("Distribuite de dvs."),
        "sharedPhotoNotifications":
            MessageLookupByLibrary.simpleMessage("Fotografii partajate noi"),
        "sharedPhotoNotificationsExplanation": MessageLookupByLibrary.simpleMessage(
            "Primiți notificări atunci când cineva adaugă o fotografie la un album distribuit din care faceți parte"),
        "sharedWith": m69,
        "sharedWithMe": MessageLookupByLibrary.simpleMessage("Distribuit mie"),
        "sharedWithYou":
            MessageLookupByLibrary.simpleMessage("Distribuite cu dvs."),
        "sharing": MessageLookupByLibrary.simpleMessage("Se distribuie..."),
        "showMemories":
            MessageLookupByLibrary.simpleMessage("Afișare amintiri"),
        "showPerson": MessageLookupByLibrary.simpleMessage("Afișare persoană"),
        "signOutFromOtherDevices": MessageLookupByLibrary.simpleMessage(
            "Deconectare de pe alte dispozitive"),
        "signOutOtherBody": MessageLookupByLibrary.simpleMessage(
            "Dacă credeți că cineva ar putea să vă cunoască parola, puteți forța toate celelalte dispozitive care utilizează contul dvs. să se deconecteze."),
        "signOutOtherDevices": MessageLookupByLibrary.simpleMessage(
            "Deconectați alte dispozitive"),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "Sunt de acord cu <u-terms>termenii de prestare ai serviciului</u-terms> și <u-policy>politica de confidențialitate</u-policy>"),
        "singleFileDeleteFromDevice": m70,
        "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
            "Acesta va fi șters din toate albumele."),
        "singleFileInBothLocalAndRemote": m71,
        "singleFileInRemoteOnly": m72,
        "skip": MessageLookupByLibrary.simpleMessage("Omiteți"),
        "social": MessageLookupByLibrary.simpleMessage("Rețele socializare"),
        "someItemsAreInBothEnteAndYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Anumite articole se află atât în Ente, cât și în dispozitiv."),
        "someOfTheFilesYouAreTryingToDeleteAre":
            MessageLookupByLibrary.simpleMessage(
                "Unele dintre fișierele pe care încercați să le ștergeți sunt disponibile numai pe dispozitivul dvs. și nu pot fi recuperate dacă sunt șterse"),
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
        "sorryTheCodeYouveEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "Ne pare rău, codul introdus este incorect"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "Ne pare rău, nu am putut genera chei securizate pe acest dispozitiv.\n\nvă rugăm să vă înregistrați de pe un alt dispozitiv."),
        "sort": MessageLookupByLibrary.simpleMessage("Sortare"),
        "sortAlbumsBy": MessageLookupByLibrary.simpleMessage("Sortare după"),
        "sortNewestFirst":
            MessageLookupByLibrary.simpleMessage("Cele mai noi primele"),
        "sortOldestFirst":
            MessageLookupByLibrary.simpleMessage("Cele mai vechi primele"),
        "sparkleSuccess": MessageLookupByLibrary.simpleMessage("✨ Succes"),
        "startAccountRecoveryTitle":
            MessageLookupByLibrary.simpleMessage("Începeți recuperarea"),
        "startBackup":
            MessageLookupByLibrary.simpleMessage("Începeți copia de rezervă"),
        "status": MessageLookupByLibrary.simpleMessage("Status"),
        "stopCastingBody": MessageLookupByLibrary.simpleMessage(
            "Doriți să opriți proiectarea?"),
        "stopCastingTitle":
            MessageLookupByLibrary.simpleMessage("Opriți proiectarea"),
        "storage": MessageLookupByLibrary.simpleMessage("Spațiu"),
        "storageBreakupFamily": MessageLookupByLibrary.simpleMessage("Familie"),
        "storageBreakupYou": MessageLookupByLibrary.simpleMessage("Dvs."),
        "storageInGB": m1,
        "storageLimitExceeded":
            MessageLookupByLibrary.simpleMessage("Limita de spațiu depășită"),
        "storageUsageInfo": m73,
        "strongStrength": MessageLookupByLibrary.simpleMessage("Puternică"),
        "subAlreadyLinkedErrMessage": m74,
        "subWillBeCancelledOn": m75,
        "subscribe": MessageLookupByLibrary.simpleMessage("Abonare"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "Aveți nevoie de un abonament plătit activ pentru a activa distribuirea."),
        "subscription": MessageLookupByLibrary.simpleMessage("Abonament"),
        "success": MessageLookupByLibrary.simpleMessage("Succes"),
        "successfullyArchived":
            MessageLookupByLibrary.simpleMessage("Arhivat cu succes"),
        "successfullyHid":
            MessageLookupByLibrary.simpleMessage("S-a ascuns cu succes"),
        "successfullyUnarchived":
            MessageLookupByLibrary.simpleMessage("Dezarhivat cu succes"),
        "successfullyUnhid":
            MessageLookupByLibrary.simpleMessage("S-a reafișat cu succes"),
        "suggestFeatures":
            MessageLookupByLibrary.simpleMessage("Sugerați funcționalități"),
        "support": MessageLookupByLibrary.simpleMessage("Asistență"),
        "syncProgress": m76,
        "syncStopped":
            MessageLookupByLibrary.simpleMessage("Sincronizare oprită"),
        "syncing": MessageLookupByLibrary.simpleMessage("Sincronizare..."),
        "systemTheme": MessageLookupByLibrary.simpleMessage("Sistem"),
        "tapToCopy":
            MessageLookupByLibrary.simpleMessage("atingeți pentru a copia"),
        "tapToEnterCode": MessageLookupByLibrary.simpleMessage(
            "Atingeți pentru a introduce codul"),
        "tapToUnlock":
            MessageLookupByLibrary.simpleMessage("Atingeți pentru a debloca"),
        "tapToUpload":
            MessageLookupByLibrary.simpleMessage("Atingeți pentru a încărca"),
        "tapToUploadIsIgnoredDue": m77,
        "tempErrorContactSupportIfPersists": MessageLookupByLibrary.simpleMessage(
            "Se pare că ceva nu a mers bine. Vă rugăm să încercați din nou după ceva timp. Dacă eroarea persistă, vă rugăm să contactați echipa noastră de asistență."),
        "terminate": MessageLookupByLibrary.simpleMessage("Terminare"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Terminați sesiunea?"),
        "terms": MessageLookupByLibrary.simpleMessage("Termeni"),
        "termsOfServicesTitle": MessageLookupByLibrary.simpleMessage("Termeni"),
        "thankYou": MessageLookupByLibrary.simpleMessage("Vă mulțumim"),
        "thankYouForSubscribing":
            MessageLookupByLibrary.simpleMessage("Mulțumim pentru abonare!"),
        "theDownloadCouldNotBeCompleted": MessageLookupByLibrary.simpleMessage(
            "Descărcarea nu a putut fi finalizată"),
        "theLinkYouAreTryingToAccessHasExpired":
            MessageLookupByLibrary.simpleMessage(
                "Linkul pe care încercați să îl accesați a expirat."),
        "theRecoveryKeyYouEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "Cheia de recuperare introdusă este incorectă"),
        "theme": MessageLookupByLibrary.simpleMessage("Temă"),
        "theseItemsWillBeDeletedFromYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Aceste articole vor fi șterse din dispozitivul dvs."),
        "theyAlsoGetXGb": m8,
        "theyWillBeDeletedFromAllAlbums": MessageLookupByLibrary.simpleMessage(
            "Acestea vor fi șterse din toate albumele."),
        "thisActionCannotBeUndone": MessageLookupByLibrary.simpleMessage(
            "Această acțiune nu poate fi anulată"),
        "thisAlbumAlreadyHDACollaborativeLink":
            MessageLookupByLibrary.simpleMessage(
                "Acest album are deja un link colaborativ"),
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "Aceasta poate fi utilizată pentru a vă recupera contul în cazul în care pierdeți al doilea factor"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Acest dispozitiv"),
        "thisEmailIsAlreadyInUse": MessageLookupByLibrary.simpleMessage(
            "Această adresă de e-mail este deja folosită"),
        "thisImageHasNoExifData": MessageLookupByLibrary.simpleMessage(
            "Această imagine nu are date exif"),
        "thisIsPersonVerificationId": m78,
        "thisIsYourVerificationId": MessageLookupByLibrary.simpleMessage(
            "Acesta este ID-ul dvs. de verificare"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Urmează să vă deconectați de pe următorul dispozitiv:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Urmează să vă deconectați de pe acest dispozitiv!"),
        "thisWillRemovePublicLinksOfAllSelectedQuickLinks":
            MessageLookupByLibrary.simpleMessage(
                "Se vor elimina linkurile publice ale linkurilor rapide selectate."),
        "toEnableAppLockPleaseSetupDevicePasscodeOrScreen":
            MessageLookupByLibrary.simpleMessage(
                "Pentru a activa blocarea aplicației, vă rugăm să configurați codul de acces al dispozitivului sau blocarea ecranului în setările sistemului."),
        "toHideAPhotoOrVideo": MessageLookupByLibrary.simpleMessage(
            "Pentru a ascunde o fotografie sau un videoclip"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "Pentru a reseta parola, vă rugăm să verificați mai întâi e-mailul."),
        "todaysLogs":
            MessageLookupByLibrary.simpleMessage("Jurnalele de astăzi"),
        "tooManyIncorrectAttempts": MessageLookupByLibrary.simpleMessage(
            "Prea multe încercări incorecte"),
        "total": MessageLookupByLibrary.simpleMessage("total"),
        "totalSize": MessageLookupByLibrary.simpleMessage("Dimensiune totală"),
        "trash": MessageLookupByLibrary.simpleMessage("Coș de gunoi"),
        "trashDaysLeft": m79,
        "trim": MessageLookupByLibrary.simpleMessage("Decupare"),
        "trustedContacts":
            MessageLookupByLibrary.simpleMessage("Contacte de încredere"),
        "trustedInviteBody": m80,
        "tryAgain": MessageLookupByLibrary.simpleMessage("Încercați din nou"),
        "turnOnBackupForAutoUpload": MessageLookupByLibrary.simpleMessage(
            "Activați copia de rezervă pentru a încărca automat fișierele adăugate la acest dosar de pe dispozitiv în Ente."),
        "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
        "twoMonthsFreeOnYearlyPlans": MessageLookupByLibrary.simpleMessage(
            "2 luni gratuite la planurile anuale"),
        "twofactor": MessageLookupByLibrary.simpleMessage("Doi factori"),
        "twofactorAuthenticationHasBeenDisabled":
            MessageLookupByLibrary.simpleMessage(
                "Autentificarea cu doi factori a fost dezactivată"),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage(
                "Autentificare cu doi factori"),
        "twofactorAuthenticationSuccessfullyReset":
            MessageLookupByLibrary.simpleMessage(
                "Autentificarea cu doi factori a fost resetată cu succes"),
        "twofactorSetup":
            MessageLookupByLibrary.simpleMessage("Configurare doi factori"),
        "typeOfGallerGallerytypeIsNotSupportedForRename": m81,
        "unarchive": MessageLookupByLibrary.simpleMessage("Dezarhivare"),
        "unarchiveAlbum":
            MessageLookupByLibrary.simpleMessage("Dezarhivare album"),
        "unarchiving":
            MessageLookupByLibrary.simpleMessage("Se dezarhivează..."),
        "unavailableReferralCode": MessageLookupByLibrary.simpleMessage(
            "Ne pare rău, acest cod nu este disponibil."),
        "uncategorized": MessageLookupByLibrary.simpleMessage("Necategorisite"),
        "unhide": MessageLookupByLibrary.simpleMessage("Reafişare"),
        "unhideToAlbum":
            MessageLookupByLibrary.simpleMessage("Reafișare în album"),
        "unhiding": MessageLookupByLibrary.simpleMessage("Se reafișează..."),
        "unhidingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Se reafișează fișierele în album"),
        "unlock": MessageLookupByLibrary.simpleMessage("Deblocare"),
        "unpinAlbum":
            MessageLookupByLibrary.simpleMessage("Anulați fixarea albumului"),
        "unselectAll":
            MessageLookupByLibrary.simpleMessage("Deselectare totală"),
        "update": MessageLookupByLibrary.simpleMessage("Actualizare"),
        "updateAvailable":
            MessageLookupByLibrary.simpleMessage("Actualizare disponibilă"),
        "updatingFolderSelection": MessageLookupByLibrary.simpleMessage(
            "Se actualizează selecția dosarelor..."),
        "upgrade": MessageLookupByLibrary.simpleMessage("Îmbunătățire"),
        "uploadIsIgnoredDueToIgnorereason": m82,
        "uploadingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Se încarcă fișiere în album..."),
        "uploadingMultipleMemories": m83,
        "uploadingSingleMemory":
            MessageLookupByLibrary.simpleMessage("Se salvează o amintire..."),
        "upto50OffUntil4thDec": MessageLookupByLibrary.simpleMessage(
            "Reducere de până la 50%, până pe 4 decembrie"),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "Spațiul utilizabil este limitat de planul dvs. actual. Spațiul suplimentar revendicat va deveni automat utilizabil atunci când vă îmbunătățiți planul."),
        "useAsCover":
            MessageLookupByLibrary.simpleMessage("Utilizați ca și copertă"),
        "useDifferentPlayerInfo": MessageLookupByLibrary.simpleMessage(
            "Aveți probleme cu redarea acestui videoclip? Apăsați lung aici pentru a încerca un alt player."),
        "usePublicLinksForPeopleNotOnEnte": MessageLookupByLibrary.simpleMessage(
            "Folosiți linkuri publice pentru persoanele care nu sunt pe Ente"),
        "useRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Folosiți cheia de recuperare"),
        "useSelectedPhoto": MessageLookupByLibrary.simpleMessage(
            "Folosiți fotografia selectată"),
        "usedSpace": MessageLookupByLibrary.simpleMessage("Spațiu utilizat"),
        "validTill": m84,
        "verificationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Verificare eșuată, încercați din nou"),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("ID de verificare"),
        "verify": MessageLookupByLibrary.simpleMessage("Verificare"),
        "verifyEmail":
            MessageLookupByLibrary.simpleMessage("Verificare e-mail"),
        "verifyEmailID": m85,
        "verifyIDLabel": MessageLookupByLibrary.simpleMessage("Verificare"),
        "verifyPasskey":
            MessageLookupByLibrary.simpleMessage("Verificați cheia de acces"),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Verificați parola"),
        "verifying": MessageLookupByLibrary.simpleMessage("Se verifică..."),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Se verifică cheia de recuperare..."),
        "videoInfo": MessageLookupByLibrary.simpleMessage("Informaţii video"),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("videoclip"),
        "videos": MessageLookupByLibrary.simpleMessage("Videoclipuri"),
        "viewActiveSessions":
            MessageLookupByLibrary.simpleMessage("Vedeți sesiunile active"),
        "viewAddOnButton":
            MessageLookupByLibrary.simpleMessage("Vizualizare suplimente"),
        "viewAll": MessageLookupByLibrary.simpleMessage("Vizualizați tot"),
        "viewAllExifData": MessageLookupByLibrary.simpleMessage(
            "Vizualizați toate datele EXIF"),
        "viewLargeFiles": MessageLookupByLibrary.simpleMessage("Fișiere mari"),
        "viewLargeFilesDesc": MessageLookupByLibrary.simpleMessage(
            "Vizualizați fișierele care consumă cel mai mult spațiu."),
        "viewLogs": MessageLookupByLibrary.simpleMessage("Afișare jurnale"),
        "viewRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Vizualizați cheia de recuperare"),
        "viewer": MessageLookupByLibrary.simpleMessage("Observator"),
        "viewersSuccessfullyAdded": m86,
        "visitWebToManage": MessageLookupByLibrary.simpleMessage(
            "Vă rugăm să vizitați web.ente.io pentru a vă gestiona abonamentul"),
        "waitingForVerification":
            MessageLookupByLibrary.simpleMessage("Se așteaptă verificarea..."),
        "waitingForWifi":
            MessageLookupByLibrary.simpleMessage("Se așteaptă WiFi..."),
        "warning": MessageLookupByLibrary.simpleMessage("Atenție"),
        "weAreOpenSource":
            MessageLookupByLibrary.simpleMessage("Suntem open source!"),
        "weDontSupportEditingPhotosAndAlbumsThatYouDont":
            MessageLookupByLibrary.simpleMessage(
                "Nu se acceptă editarea fotografiilor sau albumelor pe care nu le dețineți încă"),
        "weHaveSendEmailTo": m2,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Slabă"),
        "welcomeBack":
            MessageLookupByLibrary.simpleMessage("Bine ați revenit!"),
        "whatsNew": MessageLookupByLibrary.simpleMessage("Noutăți"),
        "whyAddTrustContact": MessageLookupByLibrary.simpleMessage(
            "Contactul de încredere vă poate ajuta la recuperarea datelor."),
        "yearShort": MessageLookupByLibrary.simpleMessage("an"),
        "yearly": MessageLookupByLibrary.simpleMessage("Anual"),
        "yearsAgo": m87,
        "yes": MessageLookupByLibrary.simpleMessage("Da"),
        "yesCancel": MessageLookupByLibrary.simpleMessage("Da, anulează"),
        "yesConvertToViewer":
            MessageLookupByLibrary.simpleMessage("Da, covertiți la observator"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("Da, șterge"),
        "yesDiscardChanges":
            MessageLookupByLibrary.simpleMessage("Da, renunțați la modificări"),
        "yesLogout": MessageLookupByLibrary.simpleMessage("Da, mă deconectez"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("Da, elimină"),
        "yesRenew": MessageLookupByLibrary.simpleMessage("Da, reînnoiește"),
        "yesResetPerson":
            MessageLookupByLibrary.simpleMessage("Da, resetează persoana"),
        "you": MessageLookupByLibrary.simpleMessage("Dvs."),
        "youAreOnAFamilyPlan": MessageLookupByLibrary.simpleMessage(
            "Sunteți pe un plan de familie!"),
        "youAreOnTheLatestVersion": MessageLookupByLibrary.simpleMessage(
            "Sunteți pe cea mai recentă versiune"),
        "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "* Cel mult vă puteți dubla spațiul"),
        "youCanManageYourLinksInTheShareTab":
            MessageLookupByLibrary.simpleMessage(
                "Puteți gestiona link-urile în fila de distribuire."),
        "youCanTrySearchingForADifferentQuery":
            MessageLookupByLibrary.simpleMessage(
                "Puteți încerca să căutați altceva."),
        "youCannotDowngradeToThisPlan": MessageLookupByLibrary.simpleMessage(
            "Nu puteți retrograda la acest plan"),
        "youCannotShareWithYourself": MessageLookupByLibrary.simpleMessage(
            "Nu poți distribui cu tine însuți"),
        "youDontHaveAnyArchivedItems":
            MessageLookupByLibrary.simpleMessage("Nu aveți articole arhivate."),
        "youHaveSuccessfullyFreedUp": m88,
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("Contul dvs. a fost șters"),
        "yourMap": MessageLookupByLibrary.simpleMessage("Harta dvs."),
        "yourPlanWasSuccessfullyDowngraded":
            MessageLookupByLibrary.simpleMessage(
                "Planul dvs. a fost retrogradat cu succes"),
        "yourPlanWasSuccessfullyUpgraded": MessageLookupByLibrary.simpleMessage(
            "Planul dvs. a fost îmbunătățit cu succes"),
        "yourPurchaseWasSuccessful": MessageLookupByLibrary.simpleMessage(
            "Achiziția dvs. a fost efectuată cu succes"),
        "yourStorageDetailsCouldNotBeFetched":
            MessageLookupByLibrary.simpleMessage(
                "Detaliile privind spațiul de stocare nu au putut fi preluate"),
        "yourSubscriptionHasExpired":
            MessageLookupByLibrary.simpleMessage("Abonamentul dvs. a expirat"),
        "yourSubscriptionWasUpdatedSuccessfully":
            MessageLookupByLibrary.simpleMessage(
                "Abonamentul dvs. a fost actualizat cu succes"),
        "yourVerificationCodeHasExpired": MessageLookupByLibrary.simpleMessage(
            "Codul dvs. de verificare a expirat"),
        "youveNoDuplicateFilesThatCanBeCleared":
            MessageLookupByLibrary.simpleMessage(
                "Nu aveți dubluri care pot fi șterse"),
        "youveNoFilesInThisAlbumThatCanBeDeleted":
            MessageLookupByLibrary.simpleMessage(
                "Nu aveți fișiere în acest album care pot fi șterse"),
        "zoomOutToSeePhotos": MessageLookupByLibrary.simpleMessage(
            "Micșorați pentru a vedea fotografiile")
      };
}
