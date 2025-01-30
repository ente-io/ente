// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a it locale. All the
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
  String get localeName => 'it';

  static String m9(count) =>
      "${Intl.plural(count, zero: 'Aggiungi collaboratore', one: 'Aggiungi collaboratore', other: 'Aggiungi collaboratori')}";

  static String m10(count) =>
      "${Intl.plural(count, one: 'Aggiungi elemento', other: 'Aggiungi elementi')}";

  static String m11(storageAmount, endDate) =>
      "Il tuo spazio aggiuntivo di ${storageAmount} è valido fino al ${endDate}";

  static String m12(count) =>
      "${Intl.plural(count, zero: 'Aggiungi visualizzatore', one: 'Aggiungi visualizzatore', other: 'Aggiungi visualizzatori')}";

  static String m13(emailOrName) => "Aggiunto da ${emailOrName}";

  static String m14(albumName) => "Aggiunto con successo su ${albumName}";

  static String m15(count) =>
      "${Intl.plural(count, zero: 'Nessun partecipante', one: '1 Partecipante', other: '${count} Partecipanti')}";

  static String m16(versionValue) => "Versione: ${versionValue}";

  static String m17(freeAmount, storageUnit) =>
      "${freeAmount} ${storageUnit} liberi";

  static String m18(paymentProvider) =>
      "Annulla prima il tuo abbonamento esistente da ${paymentProvider}";

  static String m3(user) =>
      "${user} non sarà più in grado di aggiungere altre foto a questo album\n\nSarà ancora in grado di rimuovere le foto esistenti aggiunte da lui o lei";

  static String m19(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true':
                'Il tuo piano famiglia ha già richiesto ${storageAmountInGb} GB finora',
            'false': 'Hai già richiesto ${storageAmountInGb} GB finora',
            'other': 'Hai già richiesto ${storageAmountInGb} GB finora!',
          })}";

  static String m20(albumName) => "Link collaborativo creato per ${albumName}";

  static String m21(count) =>
      "${Intl.plural(count, zero: 'Aggiunti 0 collaboratori', one: 'Aggiunto 1 collaboratore', other: 'Aggiunti ${count} collaboratori')}";

  static String m22(email, numOfDays) =>
      "Stai per aggiungere ${email} come contatto fidato. Potranno recuperare il tuo account se sei assente per ${numOfDays} giorni.";

  static String m23(familyAdminEmail) =>
      "Contatta <green>${familyAdminEmail}</green> per gestire il tuo abbonamento";

  static String m24(provider) =>
      "Scrivi all\'indirizzo support@ente.io per gestire il tuo abbonamento ${provider}.";

  static String m25(endpoint) => "Connesso a ${endpoint}";

  static String m26(count) =>
      "${Intl.plural(count, one: 'Elimina ${count} elemento', other: 'Elimina ${count} elementi')}";

  static String m27(currentlyDeleting, totalCount) =>
      "Eliminazione di ${currentlyDeleting} / ${totalCount}";

  static String m28(albumName) =>
      "Questo rimuoverà il link pubblico per accedere a \"${albumName}\".";

  static String m29(supportEmail) =>
      "Per favore invia un\'email a ${supportEmail} dall\'indirizzo email con cui ti sei registrato";

  static String m30(count, storageSaved) =>
      "Hai ripulito ${Intl.plural(count, one: '${count} doppione', other: '${count} doppioni')}, salvando (${storageSaved}!)";

  static String m31(count, formattedSize) =>
      "${count} file, ${formattedSize} l\'uno";

  static String m32(newEmail) => "Email cambiata in ${newEmail}";

  static String m33(email) =>
      "${email} non ha un account Ente.\n\nInvia un invito per condividere foto.";

  static String m34(text) => "Trovate foto aggiuntive per ${text}";

  static String m35(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 file', other: '${formattedNumber} file')} di quest\'album sono stati salvati in modo sicuro";

  static String m36(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 file', other: '${formattedNumber} file')} di quest\'album sono stati salvati in modo sicuro";

  static String m4(storageAmountInGB) =>
      "${storageAmountInGB} GB ogni volta che qualcuno si iscrive a un piano a pagamento e applica il tuo codice";

  static String m37(endDate) => "La prova gratuita termina il ${endDate}";

  static String m38(count) =>
      "Puoi ancora accedere a ${Intl.plural(count, one: '', other: 'loro')} su ente finché hai un abbonamento attivo";

  static String m39(sizeInMBorGB) => "Libera ${sizeInMBorGB}";

  static String m40(count, formattedSize) =>
      "${Intl.plural(count, one: 'Può essere cancellata per liberare ${formattedSize}', other: 'Possono essere cancellati per liberare ${formattedSize}')}";

  static String m41(currentlyProcessing, totalCount) =>
      "Elaborazione ${currentlyProcessing} / ${totalCount}";

  static String m42(count) =>
      "${Intl.plural(count, one: '${count} elemento', other: '${count} elementi')}";

  static String m43(email) =>
      "${email} ti ha invitato a essere un contatto fidato";

  static String m44(expiryTime) => "Il link scadrà il ${expiryTime}";

  static String m5(count, formattedCount) =>
      "${Intl.plural(count, one: '${formattedCount} ricordo', other: '${formattedCount} ricordi')}";

  static String m45(count) =>
      "${Intl.plural(count, one: 'Sposta elemento', other: 'Sposta elementi')}";

  static String m46(albumName) => "Spostato con successo su ${albumName}";

  static String m47(personName) => "Nessun suggerimento per ${personName}";

  static String m48(name) => "Non è ${name}?";

  static String m49(familyAdminEmail) =>
      "Per favore contatta ${familyAdminEmail} per cambiare il tuo codice.";

  static String m0(passwordStrengthValue) =>
      "Sicurezza password: ${passwordStrengthValue}";

  static String m50(providerName) =>
      "Si prega di parlare con il supporto di ${providerName} se ti è stato addebitato qualcosa";

  static String m51(count) =>
      "${Intl.plural(count, zero: '0 foto', one: '1 foto', other: '${count} foto')}";

  static String m52(endDate) =>
      "Prova gratuita valida fino al ${endDate}.\nIn seguito potrai scegliere un piano a pagamento.";

  static String m53(toEmail) => "Per favore invia un\'email a ${toEmail}";

  static String m54(toEmail) => "Invia i log a \n${toEmail}";

  static String m55(folderName) => "Elaborando ${folderName}...";

  static String m56(storeName) => "Valutaci su ${storeName}";

  static String m57(days, email) =>
      "Puoi accedere all\'account dopo ${days} giorni. Una notifica verrà inviata a ${email}.";

  static String m58(email) =>
      "Ora puoi recuperare l\'account di ${email} impostando una nuova password.";

  static String m59(email) =>
      "${email} sta cercando di recuperare il tuo account.";

  static String m60(storageInGB) =>
      "3. Ottenete entrambi ${storageInGB} GB* gratis";

  static String m61(userEmail) =>
      "${userEmail} verrà rimosso da questo album condiviso\n\nQualsiasi foto aggiunta dall\'utente verrà rimossa dall\'album";

  static String m62(endDate) => "Si rinnova il ${endDate}";

  static String m63(count) =>
      "${Intl.plural(count, one: '${count} risultato trovato', other: '${count} risultati trovati')}";

  static String m6(count) => "${count} selezionati";

  static String m65(count, yourCount) =>
      "${count} selezionato (${yourCount} tuoi)";

  static String m66(verificationID) =>
      "Ecco il mio ID di verifica: ${verificationID} per ente.io.";

  static String m7(verificationID) =>
      "Hey, puoi confermare che questo è il tuo ID di verifica: ${verificationID} su ente.io";

  static String m67(referralCode, referralStorageInGB) =>
      "Codice invito Ente: ${referralCode} \n\nInseriscilo in Impostazioni → Generali → Inviti per ottenere ${referralStorageInGB} GB gratis dopo la sottoscrizione a un piano a pagamento\n\nhttps://ente.io";

  static String m68(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Condividi con persone specifiche', one: 'Condividi con una persona', other: 'Condividi con ${numberOfPeople} persone')}";

  static String m69(emailIDs) => "Condiviso con ${emailIDs}";

  static String m70(fileType) =>
      "Questo ${fileType} verrà eliminato dal tuo dispositivo.";

  static String m71(fileType) =>
      "Questo ${fileType} è sia su Ente che sul tuo dispositivo.";

  static String m72(fileType) => "Questo ${fileType} verrà eliminato da Ente.";

  static String m1(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m73(
          usedAmount, usedStorageUnit, totalAmount, totalStorageUnit) =>
      "${usedAmount} ${usedStorageUnit} di ${totalAmount} ${totalStorageUnit} utilizzati";

  static String m74(id) =>
      "Il tuo ${id} è già collegato a un altro account Ente.\nSe desideri utilizzare il tuo ${id} con questo account, per favore contatta il nostro supporto\'\'";

  static String m75(endDate) => "L\'abbonamento verrà cancellato il ${endDate}";

  static String m76(completed, total) =>
      "${completed}/${total} ricordi conservati";

  static String m77(ignoreReason) =>
      "Tocca per caricare, il caricamento è attualmente ignorato a causa di ${ignoreReason}";

  static String m8(storageAmountInGB) =>
      "Anche loro riceveranno ${storageAmountInGB} GB";

  static String m78(email) => "Questo è l\'ID di verifica di ${email}";

  static String m79(count) =>
      "${Intl.plural(count, zero: 'Presto', one: '1 giorno', other: '${count} giorni')}";

  static String m80(email) =>
      "Sei stato invitato a essere un contatto Legacy da ${email}.";

  static String m82(ignoreReason) =>
      "Il caricamento è ignorato a causa di ${ignoreReason}";

  static String m83(count) => "Conservando ${count} ricordi...";

  static String m84(endDate) => "Valido fino al ${endDate}";

  static String m85(email) => "Verifica ${email}";

  static String m86(count) =>
      "${Intl.plural(count, zero: 'Aggiunti 0 visualizzatori', one: 'Aggiunto 1 visualizzatore', other: 'Aggiunti ${count} visualizzatori')}";

  static String m2(email) =>
      "Abbiamo inviato una mail a <green>${email}</green>";

  static String m87(count) =>
      "${Intl.plural(count, one: '${count} anno fa', other: '${count} anni fa')}";

  static String m88(storageSaved) =>
      "Hai liberato con successo ${storageSaved}!";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable": MessageLookupByLibrary.simpleMessage(
            "Una nuova versione di Ente è disponibile."),
        "about": MessageLookupByLibrary.simpleMessage("Info"),
        "acceptTrustInvite":
            MessageLookupByLibrary.simpleMessage("Accetta l\'invito"),
        "account": MessageLookupByLibrary.simpleMessage("Account"),
        "accountIsAlreadyConfigured": MessageLookupByLibrary.simpleMessage(
            "L\'account è già configurato."),
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Bentornato!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Comprendo che se perdo la password potrei perdere l\'accesso ai miei dati poiché sono <underline>criptati end-to-end</underline>."),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Sessioni attive"),
        "add": MessageLookupByLibrary.simpleMessage("Aggiungi"),
        "addAName": MessageLookupByLibrary.simpleMessage("Aggiungi un nome"),
        "addANewEmail":
            MessageLookupByLibrary.simpleMessage("Aggiungi una nuova email"),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Aggiungi collaboratore"),
        "addCollaborators": m9,
        "addFiles": MessageLookupByLibrary.simpleMessage("Aggiungi File"),
        "addFromDevice":
            MessageLookupByLibrary.simpleMessage("Aggiungi dal dispositivo"),
        "addItem": m10,
        "addLocation": MessageLookupByLibrary.simpleMessage("Aggiungi luogo"),
        "addLocationButton": MessageLookupByLibrary.simpleMessage("Aggiungi"),
        "addMore": MessageLookupByLibrary.simpleMessage("Aggiungi altri"),
        "addName": MessageLookupByLibrary.simpleMessage("Aggiungi nome"),
        "addNameOrMerge":
            MessageLookupByLibrary.simpleMessage("Aggiungi nome o unisci"),
        "addNew": MessageLookupByLibrary.simpleMessage("Aggiungi nuovo"),
        "addNewPerson":
            MessageLookupByLibrary.simpleMessage("Aggiungi nuova persona"),
        "addOnPageSubtitle": MessageLookupByLibrary.simpleMessage(
            "Dettagli dei componenti aggiuntivi"),
        "addOnValidTill": m11,
        "addOns": MessageLookupByLibrary.simpleMessage("Componenti aggiuntivi"),
        "addPhotos": MessageLookupByLibrary.simpleMessage("Aggiungi foto"),
        "addSelected":
            MessageLookupByLibrary.simpleMessage("Aggiungi selezionate"),
        "addToAlbum":
            MessageLookupByLibrary.simpleMessage("Aggiungi all\'album"),
        "addToEnte": MessageLookupByLibrary.simpleMessage("Aggiungi a Ente"),
        "addToHiddenAlbum":
            MessageLookupByLibrary.simpleMessage("Aggiungi ad album nascosto"),
        "addTrustedContact":
            MessageLookupByLibrary.simpleMessage("Aggiungi contatto fidato"),
        "addViewer":
            MessageLookupByLibrary.simpleMessage("Aggiungi in sola lettura"),
        "addViewers": m12,
        "addYourPhotosNow":
            MessageLookupByLibrary.simpleMessage("Aggiungi le tue foto ora"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Aggiunto come"),
        "addedBy": m13,
        "addedSuccessfullyTo": m14,
        "addingToFavorites":
            MessageLookupByLibrary.simpleMessage("Aggiunto ai preferiti..."),
        "advanced": MessageLookupByLibrary.simpleMessage("Avanzate"),
        "advancedSettings": MessageLookupByLibrary.simpleMessage("Avanzate"),
        "after1Day": MessageLookupByLibrary.simpleMessage("Dopo un giorno"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("Dopo un’ora "),
        "after1Month": MessageLookupByLibrary.simpleMessage("Dopo un mese"),
        "after1Week":
            MessageLookupByLibrary.simpleMessage("Dopo una settimana"),
        "after1Year": MessageLookupByLibrary.simpleMessage("Dopo un anno"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Proprietario"),
        "albumParticipantsCount": m15,
        "albumTitle": MessageLookupByLibrary.simpleMessage("Titolo album"),
        "albumUpdated":
            MessageLookupByLibrary.simpleMessage("Album aggiornato"),
        "albums": MessageLookupByLibrary.simpleMessage("Album"),
        "allClear": MessageLookupByLibrary.simpleMessage("✨ Tutto pulito"),
        "allMemoriesPreserved":
            MessageLookupByLibrary.simpleMessage("Tutti i ricordi conservati"),
        "allPersonGroupingWillReset": MessageLookupByLibrary.simpleMessage(
            "Tutti i raggruppamenti per questa persona saranno resettati e perderai tutti i suggerimenti fatti per questa persona"),
        "allow": MessageLookupByLibrary.simpleMessage("Consenti"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Permetti anche alle persone con il link di aggiungere foto all\'album condiviso."),
        "allowAddingPhotos": MessageLookupByLibrary.simpleMessage(
            "Consenti l\'aggiunta di foto"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("Consenti download"),
        "allowPeopleToAddPhotos": MessageLookupByLibrary.simpleMessage(
            "Permetti alle persone di aggiungere foto"),
        "allowPermTitle": MessageLookupByLibrary.simpleMessage(
            "Consenti l\'accesso alle foto"),
        "androidBiometricHint":
            MessageLookupByLibrary.simpleMessage("Verifica l\'identità"),
        "androidBiometricNotRecognized":
            MessageLookupByLibrary.simpleMessage("Non riconosciuto. Riprova."),
        "androidBiometricRequiredTitle":
            MessageLookupByLibrary.simpleMessage("Autenticazione biometrica"),
        "androidBiometricSuccess":
            MessageLookupByLibrary.simpleMessage("Operazione riuscita"),
        "androidCancelButton": MessageLookupByLibrary.simpleMessage("Annulla"),
        "androidDeviceCredentialsRequiredTitle":
            MessageLookupByLibrary.simpleMessage(
                "Inserisci le credenziali del dispositivo"),
        "androidDeviceCredentialsSetupDescription":
            MessageLookupByLibrary.simpleMessage(
                "Inserisci le credenziali del dispositivo"),
        "androidGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "L\'autenticazione biometrica non è impostata sul tuo dispositivo. Vai a \'Impostazioni > Sicurezza\' per impostarla."),
        "androidIosWebDesktop":
            MessageLookupByLibrary.simpleMessage("Android, iOS, Web, Desktop"),
        "androidSignInTitle":
            MessageLookupByLibrary.simpleMessage("Autenticazione necessaria"),
        "appLock": MessageLookupByLibrary.simpleMessage("Blocco app"),
        "appLockDescriptions": MessageLookupByLibrary.simpleMessage(
            "Scegli tra la schermata di blocco predefinita del dispositivo e una schermata di blocco personalizzata con PIN o password."),
        "appVersion": m16,
        "appleId": MessageLookupByLibrary.simpleMessage("Apple ID"),
        "apply": MessageLookupByLibrary.simpleMessage("Applica"),
        "applyCodeTitle":
            MessageLookupByLibrary.simpleMessage("Applica codice"),
        "appstoreSubscription":
            MessageLookupByLibrary.simpleMessage("abbonamento AppStore"),
        "archive": MessageLookupByLibrary.simpleMessage("Archivio"),
        "archiveAlbum": MessageLookupByLibrary.simpleMessage("Archivia album"),
        "archiving": MessageLookupByLibrary.simpleMessage("Archiviazione..."),
        "areYouSureThatYouWantToLeaveTheFamily":
            MessageLookupByLibrary.simpleMessage(
                "Sei sicuro di voler uscire dal piano famiglia?"),
        "areYouSureYouWantToCancel": MessageLookupByLibrary.simpleMessage(
            "Sicuro di volerlo cancellare?"),
        "areYouSureYouWantToChangeYourPlan":
            MessageLookupByLibrary.simpleMessage(
                "Sei sicuro di voler cambiare il piano?"),
        "areYouSureYouWantToExit":
            MessageLookupByLibrary.simpleMessage("Sei sicuro di voler uscire?"),
        "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
            "Sei sicuro di volerti disconnettere?"),
        "areYouSureYouWantToRenew": MessageLookupByLibrary.simpleMessage(
            "Sei sicuro di volere rinnovare?"),
        "areYouSureYouWantToResetThisPerson":
            MessageLookupByLibrary.simpleMessage(
                "Sei sicuro di voler resettare questa persona?"),
        "askCancelReason": MessageLookupByLibrary.simpleMessage(
            "Il tuo abbonamento è stato annullato. Vuoi condividere il motivo?"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "Qual è il motivo principale per cui stai cancellando il tuo account?"),
        "askYourLovedOnesToShare": MessageLookupByLibrary.simpleMessage(
            "Invita amici, amiche e parenti su ente"),
        "atAFalloutShelter":
            MessageLookupByLibrary.simpleMessage("in un rifugio antiatomico"),
        "authToChangeEmailVerificationSetting":
            MessageLookupByLibrary.simpleMessage(
                "Autenticati per modificare la verifica email"),
        "authToChangeLockscreenSetting": MessageLookupByLibrary.simpleMessage(
            "Autenticati per modificare le impostazioni della schermata di blocco"),
        "authToChangeYourEmail": MessageLookupByLibrary.simpleMessage(
            "Autenticati per cambiare la tua email"),
        "authToChangeYourPassword": MessageLookupByLibrary.simpleMessage(
            "Autenticati per cambiare la tua password"),
        "authToConfigureTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Autenticati per configurare l\'autenticazione a due fattori"),
        "authToInitiateAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Autenticati per avviare l\'eliminazione dell\'account"),
        "authToManageLegacy": MessageLookupByLibrary.simpleMessage(
            "Autenticati per gestire i tuoi contatti fidati"),
        "authToViewPasskey": MessageLookupByLibrary.simpleMessage(
            "Autenticati per visualizzare le tue passkey"),
        "authToViewTrashedFiles": MessageLookupByLibrary.simpleMessage(
            "Autenticati per visualizzare i file cancellati"),
        "authToViewYourActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Autenticati per visualizzare le sessioni attive"),
        "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
            "Autenticati per visualizzare i file nascosti"),
        "authToViewYourMemories": MessageLookupByLibrary.simpleMessage(
            "Autenticati per visualizzare le tue foto"),
        "authToViewYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Autenticati per visualizzare la tua chiave di recupero"),
        "authenticating":
            MessageLookupByLibrary.simpleMessage("Autenticazione..."),
        "authenticationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Autenticazione non riuscita, prova di nuovo"),
        "authenticationSuccessful":
            MessageLookupByLibrary.simpleMessage("Autenticazione riuscita!"),
        "autoCastDialogBody": MessageLookupByLibrary.simpleMessage(
            "Qui vedrai i dispositivi disponibili per la trasmissione."),
        "autoCastiOSPermission": MessageLookupByLibrary.simpleMessage(
            "Assicurarsi che le autorizzazioni della rete locale siano attivate per l\'app Ente Photos nelle Impostazioni."),
        "autoLock": MessageLookupByLibrary.simpleMessage("Blocco automatico"),
        "autoLockFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "Tempo dopo il quale l\'applicazione si blocca dopo essere stata messa in background"),
        "autoLogoutMessage": MessageLookupByLibrary.simpleMessage(
            "A causa di problemi tecnici, sei stato disconnesso. Ci scusiamo per l\'inconveniente."),
        "autoPair":
            MessageLookupByLibrary.simpleMessage("Associazione automatica"),
        "autoPairDesc": MessageLookupByLibrary.simpleMessage(
            "L\'associazione automatica funziona solo con i dispositivi che supportano Chromecast."),
        "available": MessageLookupByLibrary.simpleMessage("Disponibile"),
        "availableStorageSpace": m17,
        "backedUpFolders":
            MessageLookupByLibrary.simpleMessage("Cartelle salvate"),
        "backup": MessageLookupByLibrary.simpleMessage("Backup"),
        "backupFailed": MessageLookupByLibrary.simpleMessage("Backup fallito"),
        "backupOverMobileData":
            MessageLookupByLibrary.simpleMessage("Backup su dati mobili"),
        "backupSettings":
            MessageLookupByLibrary.simpleMessage("Impostazioni backup"),
        "backupStatus": MessageLookupByLibrary.simpleMessage("Stato backup"),
        "backupStatusDescription": MessageLookupByLibrary.simpleMessage(
            "Gli elementi che sono stati sottoposti a backup verranno mostrati qui"),
        "backupVideos":
            MessageLookupByLibrary.simpleMessage("Backup dei video"),
        "birthday": MessageLookupByLibrary.simpleMessage("Compleanno"),
        "blackFridaySale":
            MessageLookupByLibrary.simpleMessage("Offerta del Black Friday"),
        "blog": MessageLookupByLibrary.simpleMessage("Blog"),
        "cachedData": MessageLookupByLibrary.simpleMessage("Dati nella cache"),
        "calculating": MessageLookupByLibrary.simpleMessage("Calcolando..."),
        "canNotOpenBody": MessageLookupByLibrary.simpleMessage(
            "Spiacente, questo album non può essere aperto nell\'app."),
        "canNotOpenTitle": MessageLookupByLibrary.simpleMessage(
            "Impossibile aprire questo album"),
        "canNotUploadToAlbumsOwnedByOthers":
            MessageLookupByLibrary.simpleMessage(
                "Impossibile caricare su album di proprietà altrui"),
        "canOnlyCreateLinkForFilesOwnedByYou":
            MessageLookupByLibrary.simpleMessage(
                "Puoi creare solo link per i file di tua proprietà"),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "Puoi rimuovere solo i file di tua proprietà"),
        "cancel": MessageLookupByLibrary.simpleMessage("Annulla"),
        "cancelAccountRecovery":
            MessageLookupByLibrary.simpleMessage("Annulla il recupero"),
        "cancelAccountRecoveryBody": MessageLookupByLibrary.simpleMessage(
            "Sei sicuro di voler annullare il recupero?"),
        "cancelOtherSubscription": m18,
        "cancelSubscription":
            MessageLookupByLibrary.simpleMessage("Annulla abbonamento"),
        "cannotAddMorePhotosAfterBecomingViewer": m3,
        "cannotDeleteSharedFiles": MessageLookupByLibrary.simpleMessage(
            "Impossibile eliminare i file condivisi"),
        "castAlbum": MessageLookupByLibrary.simpleMessage("Trasmetti album"),
        "castIPMismatchBody": MessageLookupByLibrary.simpleMessage(
            "Assicurati di essere sulla stessa rete della TV."),
        "castIPMismatchTitle": MessageLookupByLibrary.simpleMessage(
            "Errore nel trasmettere l\'album"),
        "castInstruction": MessageLookupByLibrary.simpleMessage(
            "Visita cast.ente.io sul dispositivo che vuoi abbinare.\n\nInserisci il codice qui sotto per riprodurre l\'album sulla tua TV."),
        "centerPoint": MessageLookupByLibrary.simpleMessage("Punto centrale"),
        "change": MessageLookupByLibrary.simpleMessage("Cambia"),
        "changeEmail": MessageLookupByLibrary.simpleMessage("Modifica email"),
        "changeLocationOfSelectedItems": MessageLookupByLibrary.simpleMessage(
            "Cambiare la posizione degli elementi selezionati?"),
        "changeLogBackupStatusTitle":
            MessageLookupByLibrary.simpleMessage("Stato Backup"),
        "changeLogDiscoverTitle":
            MessageLookupByLibrary.simpleMessage("Esplora"),
        "changeLogMagicSearchImprovementContent":
            MessageLookupByLibrary.simpleMessage(
                "Abbiamo migliorato la ricerca magica per renderla molto più veloce, così non devi aspettare per trovare quello che cerchi."),
        "changeLogMagicSearchImprovementTitle":
            MessageLookupByLibrary.simpleMessage(
                "Miglioramento della Ricerca Magica"),
        "changePassword":
            MessageLookupByLibrary.simpleMessage("Cambia password"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Modifica password"),
        "changePermissions":
            MessageLookupByLibrary.simpleMessage("Cambio i permessi?"),
        "changeYourReferralCode":
            MessageLookupByLibrary.simpleMessage("Cambia il tuo codice invito"),
        "checkForUpdates":
            MessageLookupByLibrary.simpleMessage("Controlla aggiornamenti"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Per favore, controlla la tua casella di posta (e lo spam) per completare la verifica"),
        "checkStatus": MessageLookupByLibrary.simpleMessage("Verifica stato"),
        "checking":
            MessageLookupByLibrary.simpleMessage("Controllo in corso..."),
        "checkingModels":
            MessageLookupByLibrary.simpleMessage("Verifica dei modelli..."),
        "claimFreeStorage":
            MessageLookupByLibrary.simpleMessage("Richiedi spazio gratuito"),
        "claimMore": MessageLookupByLibrary.simpleMessage("Richiedine di più!"),
        "claimed": MessageLookupByLibrary.simpleMessage("Riscattato"),
        "claimedStorageSoFar": m19,
        "cleanUncategorized":
            MessageLookupByLibrary.simpleMessage("Pulisci Senza Categoria"),
        "cleanUncategorizedDescription": MessageLookupByLibrary.simpleMessage(
            "Rimuovi tutti i file da Senza Categoria che sono presenti in altri album"),
        "clearCaches": MessageLookupByLibrary.simpleMessage("Svuota cache"),
        "clearIndexes": MessageLookupByLibrary.simpleMessage("Cancella indici"),
        "click": MessageLookupByLibrary.simpleMessage("• Clic"),
        "clickOnTheOverflowMenu":
            MessageLookupByLibrary.simpleMessage("• Fai clic sul menu"),
        "close": MessageLookupByLibrary.simpleMessage("Chiudi"),
        "clubByCaptureTime":
            MessageLookupByLibrary.simpleMessage("Club per tempo di cattura"),
        "clubByFileName":
            MessageLookupByLibrary.simpleMessage("Unisci per nome file"),
        "clusteringProgress": MessageLookupByLibrary.simpleMessage(
            "Progresso del raggruppamento"),
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("Codice applicato"),
        "codeChangeLimitReached": MessageLookupByLibrary.simpleMessage(
            "Siamo spiacenti, hai raggiunto il limite di modifiche del codice."),
        "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Codice copiato negli appunti"),
        "codeUsedByYou":
            MessageLookupByLibrary.simpleMessage("Codice utilizzato da te"),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Crea un link per consentire alle persone di aggiungere e visualizzare foto nel tuo album condiviso senza bisogno di un\'applicazione o di un account Ente. Ottimo per raccogliere foto di un evento."),
        "collaborativeLink":
            MessageLookupByLibrary.simpleMessage("Link collaborativo"),
        "collaborativeLinkCreatedFor": m20,
        "collaborator": MessageLookupByLibrary.simpleMessage("Collaboratore"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "I collaboratori possono aggiungere foto e video all\'album condiviso."),
        "collaboratorsSuccessfullyAdded": m21,
        "collageLayout": MessageLookupByLibrary.simpleMessage("Disposizione"),
        "collageSaved": MessageLookupByLibrary.simpleMessage(
            "Collage salvato nella galleria"),
        "collect": MessageLookupByLibrary.simpleMessage("Raccogli"),
        "collectEventPhotos": MessageLookupByLibrary.simpleMessage(
            "Raccogli le foto di un evento"),
        "collectPhotos":
            MessageLookupByLibrary.simpleMessage("Raccogli le foto"),
        "collectPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Crea un link dove i tuoi amici possono caricare le foto in qualità originale."),
        "color": MessageLookupByLibrary.simpleMessage("Colore"),
        "configuration": MessageLookupByLibrary.simpleMessage("Configurazione"),
        "confirm": MessageLookupByLibrary.simpleMessage("Conferma"),
        "confirm2FADisable": MessageLookupByLibrary.simpleMessage(
            "Sei sicuro di voler disattivare l\'autenticazione a due fattori?"),
        "confirmAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Conferma eliminazione account"),
        "confirmAddingTrustedContact": m22,
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Sì, voglio eliminare definitivamente questo account e i dati associati a esso su tutte le applicazioni."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Conferma password"),
        "confirmPlanChange": MessageLookupByLibrary.simpleMessage(
            "Conferma le modifiche al piano"),
        "confirmRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Conferma chiave di recupero"),
        "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Conferma la tua chiave di recupero"),
        "connectToDevice":
            MessageLookupByLibrary.simpleMessage("Connetti al dispositivo"),
        "contactFamilyAdmin": m23,
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("Contatta il supporto"),
        "contactToManageSubscription": m24,
        "contacts": MessageLookupByLibrary.simpleMessage("Contatti"),
        "contents": MessageLookupByLibrary.simpleMessage("Contenuti"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("Continua"),
        "continueOnFreeTrial":
            MessageLookupByLibrary.simpleMessage("Continua la prova gratuita"),
        "convertToAlbum":
            MessageLookupByLibrary.simpleMessage("Converti in album"),
        "copyEmailAddress":
            MessageLookupByLibrary.simpleMessage("Copia indirizzo email"),
        "copyLink": MessageLookupByLibrary.simpleMessage("Copia link"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Copia-incolla questo codice\nnella tua app di autenticazione"),
        "couldNotBackUpTryLater": MessageLookupByLibrary.simpleMessage(
            "Impossibile eseguire il backup dei tuoi dati.\nRiproveremo più tardi."),
        "couldNotFreeUpSpace": MessageLookupByLibrary.simpleMessage(
            "Impossibile liberare lo spazio"),
        "couldNotUpdateSubscription": MessageLookupByLibrary.simpleMessage(
            "Impossibile aggiornare l\'abbonamento"),
        "count": MessageLookupByLibrary.simpleMessage("Conteggio"),
        "crashReporting":
            MessageLookupByLibrary.simpleMessage("Segnalazione di crash"),
        "create": MessageLookupByLibrary.simpleMessage("Crea"),
        "createAccount": MessageLookupByLibrary.simpleMessage("Crea account"),
        "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
            "Premi a lungo per selezionare le foto e fai clic su + per creare un album"),
        "createCollaborativeLink":
            MessageLookupByLibrary.simpleMessage("Crea link collaborativo"),
        "createCollage":
            MessageLookupByLibrary.simpleMessage("Crea un collage"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("Crea un nuovo account"),
        "createOrSelectAlbum":
            MessageLookupByLibrary.simpleMessage("Crea o seleziona album"),
        "createPublicLink":
            MessageLookupByLibrary.simpleMessage("Crea link pubblico"),
        "creatingLink":
            MessageLookupByLibrary.simpleMessage("Creazione link..."),
        "criticalUpdateAvailable": MessageLookupByLibrary.simpleMessage(
            "Un aggiornamento importante è disponibile"),
        "crop": MessageLookupByLibrary.simpleMessage("Ritaglia"),
        "currentUsageIs": MessageLookupByLibrary.simpleMessage(
            "Spazio attualmente utilizzato "),
        "currentlyRunning":
            MessageLookupByLibrary.simpleMessage("attualmente in esecuzione"),
        "custom": MessageLookupByLibrary.simpleMessage("Personalizza"),
        "customEndpoint": m25,
        "darkTheme": MessageLookupByLibrary.simpleMessage("Scuro"),
        "dayToday": MessageLookupByLibrary.simpleMessage("Oggi"),
        "dayYesterday": MessageLookupByLibrary.simpleMessage("Ieri"),
        "declineTrustInvite":
            MessageLookupByLibrary.simpleMessage("Rifiuta l\'invito"),
        "decrypting": MessageLookupByLibrary.simpleMessage("Decriptando..."),
        "decryptingVideo":
            MessageLookupByLibrary.simpleMessage("Decifratura video..."),
        "deduplicateFiles":
            MessageLookupByLibrary.simpleMessage("File Duplicati"),
        "delete": MessageLookupByLibrary.simpleMessage("Cancella"),
        "deleteAccount":
            MessageLookupByLibrary.simpleMessage("Elimina account"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "Ci dispiace vederti andare via. Facci sapere se hai bisogno di aiuto o se vuoi aiutarci a migliorare."),
        "deleteAccountPermanentlyButton": MessageLookupByLibrary.simpleMessage(
            "Cancella definitivamente il tuo account"),
        "deleteAlbum": MessageLookupByLibrary.simpleMessage("Elimina album"),
        "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
            "Eliminare anche le foto (e i video) presenti in questo album da <bold>tutti</bold> gli altri album di cui fanno parte?"),
        "deleteAlbumsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Questo eliminerà tutti gli album vuoti. È utile quando si desidera ridurre l\'ingombro nella lista degli album."),
        "deleteAll": MessageLookupByLibrary.simpleMessage("Elimina tutto"),
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
            "Questo account è collegato ad altre app di Ente, se ne utilizzi. I tuoi dati caricati, su tutte le app di Ente, saranno pianificati per la cancellazione e il tuo account verrà eliminato definitivamente."),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "Invia un\'email a <warning>account-deletion@ente.io</warning> dal tuo indirizzo email registrato."),
        "deleteEmptyAlbums":
            MessageLookupByLibrary.simpleMessage("Elimina gli album vuoti"),
        "deleteEmptyAlbumsWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Eliminare gli album vuoti?"),
        "deleteFromBoth":
            MessageLookupByLibrary.simpleMessage("Elimina da entrambi"),
        "deleteFromDevice":
            MessageLookupByLibrary.simpleMessage("Elimina dal dispositivo"),
        "deleteFromEnte":
            MessageLookupByLibrary.simpleMessage("Elimina da Ente"),
        "deleteItemCount": m26,
        "deleteLocation":
            MessageLookupByLibrary.simpleMessage("Elimina posizione"),
        "deletePhotos": MessageLookupByLibrary.simpleMessage("Elimina foto"),
        "deleteProgress": m27,
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "Manca una caratteristica chiave di cui ho bisogno"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "L\'app o una determinata funzionalità non si comporta come dovrebbe"),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
            "Ho trovato un altro servizio che mi piace di più"),
        "deleteReason4":
            MessageLookupByLibrary.simpleMessage("Il motivo non è elencato"),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
            "La tua richiesta verrà elaborata entro 72 ore."),
        "deleteSharedAlbum": MessageLookupByLibrary.simpleMessage(
            "Eliminare l\'album condiviso?"),
        "deleteSharedAlbumDialogBody": MessageLookupByLibrary.simpleMessage(
            "L\'album verrà eliminato per tutti\n\nPerderai l\'accesso alle foto condivise in questo album che sono di proprietà di altri"),
        "deselectAll":
            MessageLookupByLibrary.simpleMessage("Deseleziona tutti"),
        "designedToOutlive":
            MessageLookupByLibrary.simpleMessage("Progettato per sopravvivere"),
        "details": MessageLookupByLibrary.simpleMessage("Dettagli"),
        "developerSettings":
            MessageLookupByLibrary.simpleMessage("Impostazioni sviluppatore"),
        "developerSettingsWarning": MessageLookupByLibrary.simpleMessage(
            "Sei sicuro di voler modificare le Impostazioni sviluppatore?"),
        "deviceCodeHint":
            MessageLookupByLibrary.simpleMessage("Inserisci il codice"),
        "deviceFilesAutoUploading": MessageLookupByLibrary.simpleMessage(
            "I file aggiunti a questo album del dispositivo verranno automaticamente caricati su Ente."),
        "deviceLock":
            MessageLookupByLibrary.simpleMessage("Blocco del dispositivo"),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
            "Disabilita il blocco schermo del dispositivo quando Ente è in primo piano e c\'è un backup in corso. Questo normalmente non è necessario ma può aiutare a completare più velocemente grossi caricamenti e l\'importazione iniziale di grandi librerie."),
        "deviceNotFound":
            MessageLookupByLibrary.simpleMessage("Dispositivo non trovato"),
        "didYouKnow": MessageLookupByLibrary.simpleMessage("Lo sapevi che?"),
        "disableAutoLock": MessageLookupByLibrary.simpleMessage(
            "Disabilita blocco automatico"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "I visualizzatori possono scattare screenshot o salvare una copia delle foto utilizzando strumenti esterni"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Nota bene"),
        "disableLinkMessage": m28,
        "disableTwofactor": MessageLookupByLibrary.simpleMessage(
            "Disabilita autenticazione a due fattori"),
        "disablingTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Disattivazione autenticazione a due fattori..."),
        "discord": MessageLookupByLibrary.simpleMessage("Discord"),
        "discover": MessageLookupByLibrary.simpleMessage("Scopri"),
        "discover_babies": MessageLookupByLibrary.simpleMessage("Neonati"),
        "discover_celebrations":
            MessageLookupByLibrary.simpleMessage("Festeggiamenti"),
        "discover_food": MessageLookupByLibrary.simpleMessage("Cibo"),
        "discover_greenery":
            MessageLookupByLibrary.simpleMessage("Vegetazione"),
        "discover_hills": MessageLookupByLibrary.simpleMessage("Colline"),
        "discover_identity": MessageLookupByLibrary.simpleMessage("Identità"),
        "discover_memes": MessageLookupByLibrary.simpleMessage("Meme"),
        "discover_notes": MessageLookupByLibrary.simpleMessage("Note"),
        "discover_pets":
            MessageLookupByLibrary.simpleMessage("Animali domestici"),
        "discover_receipts": MessageLookupByLibrary.simpleMessage("Ricette"),
        "discover_screenshots":
            MessageLookupByLibrary.simpleMessage("Schermate"),
        "discover_selfies": MessageLookupByLibrary.simpleMessage("Selfie"),
        "discover_sunset": MessageLookupByLibrary.simpleMessage("Tramonto"),
        "discover_visiting_cards":
            MessageLookupByLibrary.simpleMessage("Biglietti da Visita"),
        "discover_wallpapers": MessageLookupByLibrary.simpleMessage("Sfondi"),
        "dismiss": MessageLookupByLibrary.simpleMessage("Ignora"),
        "distanceInKMUnit": MessageLookupByLibrary.simpleMessage("km"),
        "doNotSignOut": MessageLookupByLibrary.simpleMessage("Non uscire"),
        "doThisLater": MessageLookupByLibrary.simpleMessage("In seguito"),
        "doYouWantToDiscardTheEditsYouHaveMade":
            MessageLookupByLibrary.simpleMessage(
                "Vuoi scartare le modifiche che hai fatto?"),
        "done": MessageLookupByLibrary.simpleMessage("Completato"),
        "doubleYourStorage":
            MessageLookupByLibrary.simpleMessage("Raddoppia il tuo spazio"),
        "download": MessageLookupByLibrary.simpleMessage("Scarica"),
        "downloadFailed":
            MessageLookupByLibrary.simpleMessage("Scaricamento fallito"),
        "downloading":
            MessageLookupByLibrary.simpleMessage("Scaricamento in corso..."),
        "dropSupportEmail": m29,
        "duplicateFileCountWithStorageSaved": m30,
        "duplicateItemsGroup": m31,
        "edit": MessageLookupByLibrary.simpleMessage("Modifica"),
        "editLocation": MessageLookupByLibrary.simpleMessage("Modifica luogo"),
        "editLocationTagTitle":
            MessageLookupByLibrary.simpleMessage("Modifica luogo"),
        "editPerson": MessageLookupByLibrary.simpleMessage("Modifica persona"),
        "editsSaved": MessageLookupByLibrary.simpleMessage("Modifiche salvate"),
        "editsToLocationWillOnlyBeSeenWithinEnte":
            MessageLookupByLibrary.simpleMessage(
                "Le modifiche alla posizione saranno visibili solo all\'interno di Ente"),
        "eligible": MessageLookupByLibrary.simpleMessage("idoneo"),
        "email": MessageLookupByLibrary.simpleMessage("Email"),
        "emailChangedTo": m32,
        "emailNoEnteAccount": m33,
        "emailVerificationToggle":
            MessageLookupByLibrary.simpleMessage("Verifica Email"),
        "emailYourLogs": MessageLookupByLibrary.simpleMessage(
            "Invia una mail con i tuoi log"),
        "emergencyContacts":
            MessageLookupByLibrary.simpleMessage("Contatti di emergenza"),
        "empty": MessageLookupByLibrary.simpleMessage("Svuota"),
        "emptyTrash":
            MessageLookupByLibrary.simpleMessage("Vuoi svuotare il cestino?"),
        "enable": MessageLookupByLibrary.simpleMessage("Abilita"),
        "enableMLIndexingDesc": MessageLookupByLibrary.simpleMessage(
            "Ente supporta l\'apprendimento automatico eseguito sul dispositivo per il riconoscimento dei volti, la ricerca magica e altre funzioni di ricerca avanzata"),
        "enableMachineLearningBanner": MessageLookupByLibrary.simpleMessage(
            "Abilita l\'apprendimento automatico per la ricerca magica e il riconoscimento facciale"),
        "enableMaps": MessageLookupByLibrary.simpleMessage("Abilita le Mappe"),
        "enableMapsDesc": MessageLookupByLibrary.simpleMessage(
            "Questo mostrerà le tue foto su una mappa del mondo.\n\nQuesta mappa è ospitata da Open Street Map e le posizioni esatte delle tue foto non sono mai condivise.\n\nPuoi disabilitare questa funzionalità in qualsiasi momento, dalle Impostazioni."),
        "enabled": MessageLookupByLibrary.simpleMessage("Abilitato"),
        "encryptingBackup":
            MessageLookupByLibrary.simpleMessage("Crittografando il backup..."),
        "encryption": MessageLookupByLibrary.simpleMessage("Crittografia"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Chiavi di crittografia"),
        "endpointUpdatedMessage": MessageLookupByLibrary.simpleMessage(
            "Endpoint aggiornato con successo"),
        "endtoendEncryptedByDefault":
            MessageLookupByLibrary.simpleMessage("Crittografia end-to-end"),
        "enteCanEncryptAndPreserveFilesOnlyIfYouGrant":
            MessageLookupByLibrary.simpleMessage(
                "Ente può criptare e conservare i file solo se gliene concedi l\'accesso"),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
            "Ente <i>necessita del permesso per</i> preservare le tue foto"),
        "enteSubscriptionPitch": MessageLookupByLibrary.simpleMessage(
            "Ente conserva i tuoi ricordi in modo che siano sempre a disposizione, anche se perdi il tuo dispositivo."),
        "enteSubscriptionShareWithFamily": MessageLookupByLibrary.simpleMessage(
            "Aggiungi la tua famiglia al tuo piano."),
        "enterAlbumName": MessageLookupByLibrary.simpleMessage(
            "Inserisci il nome dell\'album"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Inserisci codice"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
            "Inserisci il codice fornito dal tuo amico per richiedere spazio gratuito per entrambi"),
        "enterDateOfBirth":
            MessageLookupByLibrary.simpleMessage("Compleanno (Opzionale)"),
        "enterEmail": MessageLookupByLibrary.simpleMessage("Inserisci email"),
        "enterFileName": MessageLookupByLibrary.simpleMessage(
            "Inserisci un nome per il file"),
        "enterName": MessageLookupByLibrary.simpleMessage("Aggiungi nome"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Inserisci una nuova password per criptare i tuoi dati"),
        "enterPassword":
            MessageLookupByLibrary.simpleMessage("Inserisci password"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Inserisci una password per criptare i tuoi dati"),
        "enterPersonName": MessageLookupByLibrary.simpleMessage(
            "Inserisci il nome della persona"),
        "enterPin": MessageLookupByLibrary.simpleMessage("Inserisci PIN"),
        "enterReferralCode": MessageLookupByLibrary.simpleMessage(
            "Inserisci il codice di invito"),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Inserisci il codice di 6 cifre\ndalla tua app di autenticazione"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "Inserisci un indirizzo email valido."),
        "enterYourEmailAddress": MessageLookupByLibrary.simpleMessage(
            "Inserisci il tuo indirizzo email"),
        "enterYourPassword":
            MessageLookupByLibrary.simpleMessage("Inserisci la tua password"),
        "enterYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Inserisci la tua chiave di recupero"),
        "error": MessageLookupByLibrary.simpleMessage("Errore"),
        "everywhere": MessageLookupByLibrary.simpleMessage("ovunque"),
        "exif": MessageLookupByLibrary.simpleMessage("EXIF"),
        "existingUser": MessageLookupByLibrary.simpleMessage("Accedi"),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
            "Questo link è scaduto. Si prega di selezionare un nuovo orario di scadenza o disabilitare la scadenza del link."),
        "exportLogs": MessageLookupByLibrary.simpleMessage("Esporta log"),
        "exportYourData": MessageLookupByLibrary.simpleMessage("Esporta dati"),
        "extraPhotosFound":
            MessageLookupByLibrary.simpleMessage("Trovate foto aggiuntive"),
        "extraPhotosFoundFor": m34,
        "faceNotClusteredYet": MessageLookupByLibrary.simpleMessage(
            "Faccia non ancora raggruppata, per favore torna più tardi"),
        "faceRecognition":
            MessageLookupByLibrary.simpleMessage("Riconoscimento facciale"),
        "faces": MessageLookupByLibrary.simpleMessage("Volti"),
        "failedToApplyCode": MessageLookupByLibrary.simpleMessage(
            "Impossibile applicare il codice"),
        "failedToCancel":
            MessageLookupByLibrary.simpleMessage("Impossibile annullare"),
        "failedToDownloadVideo": MessageLookupByLibrary.simpleMessage(
            "Download del video non riuscito"),
        "failedToFetchActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Recupero delle sessioni attive non riuscito"),
        "failedToFetchOriginalForEdit": MessageLookupByLibrary.simpleMessage(
            "Impossibile recuperare l\'originale per la modifica"),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "Impossibile recuperare i dettagli. Per favore, riprova più tardi."),
        "failedToLoadAlbums": MessageLookupByLibrary.simpleMessage(
            "Impossibile caricare gli album"),
        "failedToPlayVideo": MessageLookupByLibrary.simpleMessage(
            "Impossibile riprodurre il video"),
        "failedToRefreshStripeSubscription":
            MessageLookupByLibrary.simpleMessage(
                "Impossibile aggiornare l\'abbonamento"),
        "failedToRenew":
            MessageLookupByLibrary.simpleMessage("Rinnovo fallito"),
        "failedToVerifyPaymentStatus": MessageLookupByLibrary.simpleMessage(
            "Impossibile verificare lo stato del pagamento"),
        "familyPlanOverview": MessageLookupByLibrary.simpleMessage(
            "Aggiungi 5 membri della famiglia al tuo piano esistente senza pagare extra.\n\nOgni membro ottiene il proprio spazio privato e non può vedere i file dell\'altro a meno che non siano condivisi.\n\nI piani familiari sono disponibili per i clienti che hanno un abbonamento Ente a pagamento.\n\nIscriviti ora per iniziare!"),
        "familyPlanPortalTitle":
            MessageLookupByLibrary.simpleMessage("Famiglia"),
        "familyPlans": MessageLookupByLibrary.simpleMessage("Piano famiglia"),
        "faq": MessageLookupByLibrary.simpleMessage("FAQ"),
        "faqs": MessageLookupByLibrary.simpleMessage("FAQ"),
        "favorite": MessageLookupByLibrary.simpleMessage("Preferito"),
        "feedback": MessageLookupByLibrary.simpleMessage("Suggerimenti"),
        "file": MessageLookupByLibrary.simpleMessage("File"),
        "fileFailedToSaveToGallery": MessageLookupByLibrary.simpleMessage(
            "Impossibile salvare il file nella galleria"),
        "fileInfoAddDescHint":
            MessageLookupByLibrary.simpleMessage("Aggiungi descrizione..."),
        "fileNotUploadedYet":
            MessageLookupByLibrary.simpleMessage("File non ancora caricato"),
        "fileSavedToGallery":
            MessageLookupByLibrary.simpleMessage("File salvato nella galleria"),
        "fileTypes": MessageLookupByLibrary.simpleMessage("Tipi di file"),
        "fileTypesAndNames":
            MessageLookupByLibrary.simpleMessage("Tipi e nomi di file"),
        "filesBackedUpFromDevice": m35,
        "filesBackedUpInAlbum": m36,
        "filesDeleted": MessageLookupByLibrary.simpleMessage("File eliminati"),
        "filesSavedToGallery":
            MessageLookupByLibrary.simpleMessage("File salvati nella galleria"),
        "findPeopleByName": MessageLookupByLibrary.simpleMessage(
            "Trova rapidamente le persone per nome"),
        "findThemQuickly":
            MessageLookupByLibrary.simpleMessage("Trovali rapidamente"),
        "flip": MessageLookupByLibrary.simpleMessage("Capovolgi"),
        "forYourMemories":
            MessageLookupByLibrary.simpleMessage("per i tuoi ricordi"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Password dimenticata"),
        "foundFaces": MessageLookupByLibrary.simpleMessage("Volti trovati"),
        "freeStorageClaimed":
            MessageLookupByLibrary.simpleMessage("Spazio gratuito richiesto"),
        "freeStorageOnReferralSuccess": m4,
        "freeStorageUsable":
            MessageLookupByLibrary.simpleMessage("Spazio libero utilizzabile"),
        "freeTrial": MessageLookupByLibrary.simpleMessage("Prova gratuita"),
        "freeTrialValidTill": m37,
        "freeUpAccessPostDelete": m38,
        "freeUpAmount": m39,
        "freeUpDeviceSpace":
            MessageLookupByLibrary.simpleMessage("Libera spazio"),
        "freeUpDeviceSpaceDesc": MessageLookupByLibrary.simpleMessage(
            "Risparmia spazio sul tuo dispositivo cancellando i file che sono già stati salvati online."),
        "freeUpSpace": MessageLookupByLibrary.simpleMessage("Libera spazio"),
        "freeUpSpaceSaving": m40,
        "gallery": MessageLookupByLibrary.simpleMessage("Galleria"),
        "galleryMemoryLimitInfo": MessageLookupByLibrary.simpleMessage(
            "Fino a 1000 ricordi mostrati nella galleria"),
        "general": MessageLookupByLibrary.simpleMessage("Generali"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Generazione delle chiavi di crittografia..."),
        "genericProgress": m41,
        "goToSettings":
            MessageLookupByLibrary.simpleMessage("Vai alle impostazioni"),
        "googlePlayId": MessageLookupByLibrary.simpleMessage("Google Play ID"),
        "grantFullAccessPrompt": MessageLookupByLibrary.simpleMessage(
            "Consenti l\'accesso a tutte le foto nelle Impostazioni"),
        "grantPermission":
            MessageLookupByLibrary.simpleMessage("Concedi il permesso"),
        "groupNearbyPhotos": MessageLookupByLibrary.simpleMessage(
            "Raggruppa foto nelle vicinanze"),
        "guestView": MessageLookupByLibrary.simpleMessage("Vista ospite"),
        "guestViewEnablePreSteps": MessageLookupByLibrary.simpleMessage(
            "Per abilitare la vista ospite, configura il codice di accesso del dispositivo o il blocco schermo nelle impostazioni di sistema."),
        "hearUsExplanation": MessageLookupByLibrary.simpleMessage(
            "Non teniamo traccia del numero di installazioni dell\'app. Sarebbe utile se ci dicesse dove ci ha trovato!"),
        "hearUsWhereTitle": MessageLookupByLibrary.simpleMessage(
            "Come hai sentito parlare di Ente? (opzionale)"),
        "help": MessageLookupByLibrary.simpleMessage("Aiuto"),
        "hidden": MessageLookupByLibrary.simpleMessage("Nascosti"),
        "hide": MessageLookupByLibrary.simpleMessage("Nascondi"),
        "hideContent":
            MessageLookupByLibrary.simpleMessage("Nascondi il contenuto"),
        "hideContentDescriptionAndroid": MessageLookupByLibrary.simpleMessage(
            "Nasconde il contenuto nel selettore delle app e disabilita gli screenshot"),
        "hideContentDescriptionIos": MessageLookupByLibrary.simpleMessage(
            "Nasconde il contenuto nel selettore delle app"),
        "hideSharedItemsFromHomeGallery": MessageLookupByLibrary.simpleMessage(
            "Nascondi gli elementi condivisi dalla galleria principale"),
        "hiding": MessageLookupByLibrary.simpleMessage("Nascondendo..."),
        "hostedAtOsmFrance":
            MessageLookupByLibrary.simpleMessage("Ospitato presso OSM France"),
        "howItWorks": MessageLookupByLibrary.simpleMessage("Come funziona"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "Chiedi di premere a lungo il loro indirizzo email nella schermata delle impostazioni e verificare che gli ID su entrambi i dispositivi corrispondano."),
        "iOSGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "L\'autenticazione biometrica non è impostata sul tuo dispositivo. Abilita Touch ID o Face ID sul tuo telefono."),
        "iOSLockOut": MessageLookupByLibrary.simpleMessage(
            "L\'autenticazione biometrica è disabilitata. Blocca e sblocca lo schermo per abilitarla."),
        "iOSOkButton": MessageLookupByLibrary.simpleMessage("OK"),
        "ignoreUpdate": MessageLookupByLibrary.simpleMessage("Ignora"),
        "ignored": MessageLookupByLibrary.simpleMessage("ignorato"),
        "ignoredFolderUploadReason": MessageLookupByLibrary.simpleMessage(
            "Alcuni file in questo album vengono ignorati dal caricamento perché erano stati precedentemente eliminati da Ente."),
        "imageNotAnalyzed":
            MessageLookupByLibrary.simpleMessage("Immagine non analizzata"),
        "immediately": MessageLookupByLibrary.simpleMessage("Immediatamente"),
        "importing":
            MessageLookupByLibrary.simpleMessage("Importazione in corso...."),
        "incorrectCode":
            MessageLookupByLibrary.simpleMessage("Codice sbagliato"),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Password sbagliata"),
        "incorrectRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Chiave di recupero errata"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "Il codice che hai inserito non è corretto"),
        "incorrectRecoveryKeyTitle":
            MessageLookupByLibrary.simpleMessage("Chiave di recupero errata"),
        "indexedItems":
            MessageLookupByLibrary.simpleMessage("Elementi indicizzati"),
        "indexingIsPaused": MessageLookupByLibrary.simpleMessage(
            "L\'indicizzazione è in pausa. Riprenderà automaticamente quando il dispositivo è pronto."),
        "info": MessageLookupByLibrary.simpleMessage("Info"),
        "insecureDevice":
            MessageLookupByLibrary.simpleMessage("Dispositivo non sicuro"),
        "installManually":
            MessageLookupByLibrary.simpleMessage("Installa manualmente"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("Indirizzo email non valido"),
        "invalidEndpoint":
            MessageLookupByLibrary.simpleMessage("Endpoint invalido"),
        "invalidEndpointMessage": MessageLookupByLibrary.simpleMessage(
            "Spiacenti, l\'endpoint inserito non è valido. Inserisci un endpoint valido e riprova."),
        "invalidKey": MessageLookupByLibrary.simpleMessage("Chiave non valida"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "La chiave di recupero che hai inserito non è valida. Assicurati che contenga 24 parole e controlla l\'ortografia di ciascuna parola.\n\nSe hai inserito un vecchio codice di recupero, assicurati che sia lungo 64 caratteri e controlla ciascuno di essi."),
        "invite": MessageLookupByLibrary.simpleMessage("Invita"),
        "inviteToEnte": MessageLookupByLibrary.simpleMessage("Invita su Ente"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Invita i tuoi amici"),
        "inviteYourFriendsToEnte":
            MessageLookupByLibrary.simpleMessage("Invita i tuoi amici a Ente"),
        "itLooksLikeSomethingWentWrongPleaseRetryAfterSome":
            MessageLookupByLibrary.simpleMessage(
                "Sembra che qualcosa sia andato storto. Riprova tra un po\'. Se l\'errore persiste, contatta il nostro team di supporto."),
        "itemCount": m42,
        "itemsShowTheNumberOfDaysRemainingBeforePermanentDeletion":
            MessageLookupByLibrary.simpleMessage(
                "Gli elementi mostrano il numero di giorni rimanenti prima della cancellazione permanente"),
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "Gli elementi selezionati saranno rimossi da questo album"),
        "joinDiscord":
            MessageLookupByLibrary.simpleMessage("Unisciti a Discord"),
        "keepPhotos": MessageLookupByLibrary.simpleMessage("Mantieni foto"),
        "kiloMeterUnit": MessageLookupByLibrary.simpleMessage("km"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Aiutaci con queste informazioni"),
        "language": MessageLookupByLibrary.simpleMessage("Lingua"),
        "lastUpdated":
            MessageLookupByLibrary.simpleMessage("Ultimo aggiornamento"),
        "leave": MessageLookupByLibrary.simpleMessage("Lascia"),
        "leaveAlbum":
            MessageLookupByLibrary.simpleMessage("Abbandona l\'album"),
        "leaveFamily":
            MessageLookupByLibrary.simpleMessage("Abbandona il piano famiglia"),
        "leaveSharedAlbum": MessageLookupByLibrary.simpleMessage(
            "Abbandonare l\'album condiviso?"),
        "left": MessageLookupByLibrary.simpleMessage("Sinistra"),
        "legacy": MessageLookupByLibrary.simpleMessage("Legacy"),
        "legacyAccounts":
            MessageLookupByLibrary.simpleMessage("Account Legacy"),
        "legacyInvite": m43,
        "legacyPageDesc": MessageLookupByLibrary.simpleMessage(
            "Legacy consente ai contatti fidati di accedere al tuo account in tua assenza."),
        "legacyPageDesc2": MessageLookupByLibrary.simpleMessage(
            "I contatti fidati possono avviare il recupero dell\'account e, se non sono bloccati entro 30 giorni, reimpostare la password e accedere al tuo account."),
        "light": MessageLookupByLibrary.simpleMessage("Chiaro"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("Chiaro"),
        "linkCopiedToClipboard":
            MessageLookupByLibrary.simpleMessage("Link copiato negli appunti"),
        "linkDeviceLimit":
            MessageLookupByLibrary.simpleMessage("Limite dei dispositivi"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Attivato"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Scaduto"),
        "linkExpiresOn": m44,
        "linkExpiry": MessageLookupByLibrary.simpleMessage("Scadenza del link"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("Il link è scaduto"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Mai"),
        "livePhotos": MessageLookupByLibrary.simpleMessage("Live Photo"),
        "loadMessage1": MessageLookupByLibrary.simpleMessage(
            "Puoi condividere il tuo abbonamento con la tua famiglia"),
        "loadMessage2": MessageLookupByLibrary.simpleMessage(
            "Fino ad oggi abbiamo conservato oltre 30 milioni di ricordi"),
        "loadMessage3": MessageLookupByLibrary.simpleMessage(
            "Teniamo 3 copie dei tuoi dati, uno in un rifugio sotterraneo antiatomico"),
        "loadMessage4": MessageLookupByLibrary.simpleMessage(
            "Tutte le nostre app sono open source"),
        "loadMessage5": MessageLookupByLibrary.simpleMessage(
            "Il nostro codice sorgente e la crittografia hanno ricevuto audit esterni"),
        "loadMessage6": MessageLookupByLibrary.simpleMessage(
            "Puoi condividere i link ai tuoi album con i tuoi cari"),
        "loadMessage7": MessageLookupByLibrary.simpleMessage(
            "Le nostre app per smartphone vengono eseguite in background per crittografare e eseguire il backup di qualsiasi nuova foto o video"),
        "loadMessage8": MessageLookupByLibrary.simpleMessage(
            "web.ente.io ha un uploader intuitivo"),
        "loadMessage9": MessageLookupByLibrary.simpleMessage(
            "Usiamo Xchacha20Poly1305 per crittografare in modo sicuro i tuoi dati"),
        "loadingExifData":
            MessageLookupByLibrary.simpleMessage("Caricamento dati EXIF..."),
        "loadingGallery":
            MessageLookupByLibrary.simpleMessage("Caricamento galleria..."),
        "loadingMessage":
            MessageLookupByLibrary.simpleMessage("Caricando le tue foto..."),
        "loadingModel":
            MessageLookupByLibrary.simpleMessage("Scaricamento modelli..."),
        "loadingYourPhotos":
            MessageLookupByLibrary.simpleMessage("Caricando le tue foto..."),
        "localGallery": MessageLookupByLibrary.simpleMessage("Galleria locale"),
        "localIndexing":
            MessageLookupByLibrary.simpleMessage("Indicizzazione locale"),
        "localSyncErrorMessage": MessageLookupByLibrary.simpleMessage(
            "Sembra che qualcosa sia andato storto dal momento che la sincronizzazione delle foto locali richiede più tempo del previsto. Si prega di contattare il nostro team di supporto"),
        "location": MessageLookupByLibrary.simpleMessage("Luogo"),
        "locationName":
            MessageLookupByLibrary.simpleMessage("Nome della località"),
        "locationTagFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "Un tag di localizzazione raggruppa tutte le foto scattate entro il raggio di una foto"),
        "locations": MessageLookupByLibrary.simpleMessage("Luoghi"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Blocca"),
        "lockscreen":
            MessageLookupByLibrary.simpleMessage("Schermata di blocco"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Accedi"),
        "loggingOut": MessageLookupByLibrary.simpleMessage("Disconnessione..."),
        "loginSessionExpired":
            MessageLookupByLibrary.simpleMessage("Sessione scaduta"),
        "loginSessionExpiredDetails": MessageLookupByLibrary.simpleMessage(
            "La sessione è scaduta. Si prega di accedere nuovamente."),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "Cliccando sul pulsante Accedi, accetti i <u-terms>termini di servizio</u-terms> e la <u-policy>politica sulla privacy</u-policy>"),
        "logout": MessageLookupByLibrary.simpleMessage("Disconnetti"),
        "logsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Invia i log per aiutarci a risolvere il tuo problema. Si prega di notare che i nomi dei file saranno inclusi per aiutare a tenere traccia di problemi con file specifici."),
        "longPressAnEmailToVerifyEndToEndEncryption":
            MessageLookupByLibrary.simpleMessage(
                "Premi a lungo un\'email per verificare la crittografia end to end."),
        "longpressOnAnItemToViewInFullscreen":
            MessageLookupByLibrary.simpleMessage(
                "Premi a lungo su un elemento per visualizzarlo a schermo intero"),
        "loopVideoOff":
            MessageLookupByLibrary.simpleMessage("Loop video disattivo"),
        "loopVideoOn":
            MessageLookupByLibrary.simpleMessage("Loop video attivo"),
        "lostDevice":
            MessageLookupByLibrary.simpleMessage("Dispositivo perso?"),
        "machineLearning": MessageLookupByLibrary.simpleMessage(
            "Apprendimento automatico (ML)"),
        "magicSearch": MessageLookupByLibrary.simpleMessage("Ricerca magica"),
        "magicSearchHint": MessageLookupByLibrary.simpleMessage(
            "La ricerca magica ti permette di cercare le foto in base al loro contenuto, ad esempio \'fiore\', \'auto rossa\', \'documenti d\'identità\'"),
        "manage": MessageLookupByLibrary.simpleMessage("Gestisci"),
        "manageDeviceStorage":
            MessageLookupByLibrary.simpleMessage("Gestisci cache dispositivo"),
        "manageDeviceStorageDesc": MessageLookupByLibrary.simpleMessage(
            "Verifica e svuota la memoria cache locale."),
        "manageFamily":
            MessageLookupByLibrary.simpleMessage("Gestisci Piano famiglia"),
        "manageLink": MessageLookupByLibrary.simpleMessage("Gestisci link"),
        "manageParticipants": MessageLookupByLibrary.simpleMessage("Gestisci"),
        "manageSubscription":
            MessageLookupByLibrary.simpleMessage("Gestisci abbonamento"),
        "manualPairDesc": MessageLookupByLibrary.simpleMessage(
            "L\'associazione con PIN funziona con qualsiasi schermo dove desideri visualizzare il tuo album."),
        "map": MessageLookupByLibrary.simpleMessage("Mappa"),
        "maps": MessageLookupByLibrary.simpleMessage("Mappe"),
        "mastodon": MessageLookupByLibrary.simpleMessage("Mastodon"),
        "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
        "memoryCount": m5,
        "merchandise": MessageLookupByLibrary.simpleMessage("Merchandise"),
        "mergeWithExisting":
            MessageLookupByLibrary.simpleMessage("Unisci con esistente"),
        "mlConsent": MessageLookupByLibrary.simpleMessage(
            "Abilita l\'apprendimento automatico"),
        "mlConsentConfirmation": MessageLookupByLibrary.simpleMessage(
            "Comprendo e desidero abilitare l\'apprendimento automatico"),
        "mlConsentDescription": MessageLookupByLibrary.simpleMessage(
            "Se abiliti il Machine Learning, Ente estrarrà informazioni come la geometria del volto dai file, inclusi quelli condivisi con te.\n\nQuesto accadrà sul tuo dispositivo, e qualsiasi informazione biometrica generata sarà crittografata end-to-end."),
        "mlConsentPrivacy": MessageLookupByLibrary.simpleMessage(
            "Clicca qui per maggiori dettagli su questa funzione nella nostra informativa sulla privacy"),
        "mlConsentTitle": MessageLookupByLibrary.simpleMessage(
            "Abilita l\'apprendimento automatico?"),
        "mlIndexingDescription": MessageLookupByLibrary.simpleMessage(
            "Si prega di notare che l\'attivazione dell\'apprendimento automatico si tradurrà in un maggior utilizzo della connessione e della batteria fino a quando tutti gli elementi non saranno indicizzati. Valuta di utilizzare l\'applicazione desktop per un\'indicizzazione più veloce, tutti i risultati verranno sincronizzati automaticamente."),
        "mobileWebDesktop":
            MessageLookupByLibrary.simpleMessage("Mobile, Web, Desktop"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Mediocre"),
        "modifyYourQueryOrTrySearchingFor":
            MessageLookupByLibrary.simpleMessage(
                "Modifica la tua ricerca o prova con"),
        "moments": MessageLookupByLibrary.simpleMessage("Momenti"),
        "month": MessageLookupByLibrary.simpleMessage("mese"),
        "monthly": MessageLookupByLibrary.simpleMessage("Mensile"),
        "moreDetails": MessageLookupByLibrary.simpleMessage("Più dettagli"),
        "mostRecent": MessageLookupByLibrary.simpleMessage("Più recenti"),
        "mostRelevant": MessageLookupByLibrary.simpleMessage("Più rilevanti"),
        "moveItem": m45,
        "moveToAlbum":
            MessageLookupByLibrary.simpleMessage("Sposta nell\'album"),
        "moveToHiddenAlbum":
            MessageLookupByLibrary.simpleMessage("Sposta in album nascosto"),
        "movedSuccessfullyTo": m46,
        "movedToTrash":
            MessageLookupByLibrary.simpleMessage("Spostato nel cestino"),
        "movingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Spostamento dei file nell\'album..."),
        "name": MessageLookupByLibrary.simpleMessage("Nome"),
        "nameTheAlbum":
            MessageLookupByLibrary.simpleMessage("Dai un nome all\'album"),
        "networkConnectionRefusedErr": MessageLookupByLibrary.simpleMessage(
            "Impossibile connettersi a Ente, riprova tra un po\' di tempo. Se l\'errore persiste, contatta l\'assistenza."),
        "networkHostLookUpErr": MessageLookupByLibrary.simpleMessage(
            "Impossibile connettersi a Ente, controlla le impostazioni di rete e contatta l\'assistenza se l\'errore persiste."),
        "never": MessageLookupByLibrary.simpleMessage("Mai"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Nuovo album"),
        "newLocation": MessageLookupByLibrary.simpleMessage("Nuova posizione"),
        "newPerson": MessageLookupByLibrary.simpleMessage("Nuova persona"),
        "newToEnte":
            MessageLookupByLibrary.simpleMessage("Prima volta con Ente"),
        "newest": MessageLookupByLibrary.simpleMessage("Più recenti"),
        "next": MessageLookupByLibrary.simpleMessage("Successivo"),
        "no": MessageLookupByLibrary.simpleMessage("No"),
        "noAlbumsSharedByYouYet": MessageLookupByLibrary.simpleMessage(
            "Ancora nessun album condiviso da te"),
        "noDeviceFound":
            MessageLookupByLibrary.simpleMessage("Nessun dispositivo trovato"),
        "noDeviceLimit": MessageLookupByLibrary.simpleMessage("Nessuno"),
        "noDeviceThatCanBeDeleted": MessageLookupByLibrary.simpleMessage(
            "Non hai file su questo dispositivo che possono essere eliminati"),
        "noDuplicates":
            MessageLookupByLibrary.simpleMessage("✨ Nessun doppione"),
        "noExifData": MessageLookupByLibrary.simpleMessage("Nessun dato EXIF"),
        "noFacesFound":
            MessageLookupByLibrary.simpleMessage("Nessun volto trovato"),
        "noHiddenPhotosOrVideos": MessageLookupByLibrary.simpleMessage(
            "Nessuna foto o video nascosti"),
        "noImagesWithLocation": MessageLookupByLibrary.simpleMessage(
            "Nessuna immagine con posizione"),
        "noInternetConnection": MessageLookupByLibrary.simpleMessage(
            "Nessuna connessione internet"),
        "noPhotosAreBeingBackedUpRightNow":
            MessageLookupByLibrary.simpleMessage(
                "Il backup delle foto attualmente non viene eseguito"),
        "noPhotosFoundHere":
            MessageLookupByLibrary.simpleMessage("Nessuna foto trovata"),
        "noQuickLinksSelected": MessageLookupByLibrary.simpleMessage(
            "Nessun link rapido selezionato"),
        "noRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Nessuna chiave di recupero?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "A causa della natura del nostro protocollo di crittografia end-to-end, i tuoi dati non possono essere decifrati senza password o chiave di ripristino"),
        "noResults": MessageLookupByLibrary.simpleMessage("Nessun risultato"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("Nessun risultato trovato"),
        "noSuggestionsForPerson": m47,
        "noSystemLockFound": MessageLookupByLibrary.simpleMessage(
            "Nessun blocco di sistema trovato"),
        "notPersonLabel": m48,
        "nothingSharedWithYouYet": MessageLookupByLibrary.simpleMessage(
            "Ancora nulla di condiviso con te"),
        "nothingToSeeHere":
            MessageLookupByLibrary.simpleMessage("Nulla da vedere qui! 👀"),
        "notifications": MessageLookupByLibrary.simpleMessage("Notifiche"),
        "ok": MessageLookupByLibrary.simpleMessage("Ok"),
        "onDevice": MessageLookupByLibrary.simpleMessage("Sul dispositivo"),
        "onEnte": MessageLookupByLibrary.simpleMessage(
            "Su <branding>ente</branding>"),
        "onlyFamilyAdminCanChangeCode": m49,
        "onlyThem": MessageLookupByLibrary.simpleMessage("Solo loro"),
        "oops": MessageLookupByLibrary.simpleMessage("Oops"),
        "oopsCouldNotSaveEdits": MessageLookupByLibrary.simpleMessage(
            "Ops, impossibile salvare le modifiche"),
        "oopsSomethingWentWrong": MessageLookupByLibrary.simpleMessage(
            "Oops! Qualcosa è andato storto"),
        "openFile": MessageLookupByLibrary.simpleMessage("Apri file"),
        "openSettings":
            MessageLookupByLibrary.simpleMessage("Apri Impostazioni"),
        "openTheItem":
            MessageLookupByLibrary.simpleMessage("• Apri la foto o il video"),
        "openstreetmapContributors": MessageLookupByLibrary.simpleMessage(
            "Collaboratori di OpenStreetMap"),
        "optionalAsShortAsYouLike": MessageLookupByLibrary.simpleMessage(
            "Facoltativo, breve quanto vuoi..."),
        "orMergeWithExistingPerson":
            MessageLookupByLibrary.simpleMessage("O unisci con esistente"),
        "orPickAnExistingOne": MessageLookupByLibrary.simpleMessage(
            "Oppure scegline una esistente"),
        "pair": MessageLookupByLibrary.simpleMessage("Abbina"),
        "pairWithPin": MessageLookupByLibrary.simpleMessage("Associa con PIN"),
        "pairingComplete":
            MessageLookupByLibrary.simpleMessage("Associazione completata"),
        "panorama": MessageLookupByLibrary.simpleMessage("Panorama"),
        "passKeyPendingVerification": MessageLookupByLibrary.simpleMessage(
            "La verifica è ancora in corso"),
        "passkey": MessageLookupByLibrary.simpleMessage("Passkey"),
        "passkeyAuthTitle":
            MessageLookupByLibrary.simpleMessage("Verifica della passkey"),
        "password": MessageLookupByLibrary.simpleMessage("Password"),
        "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
            "Password modificata con successo"),
        "passwordLock":
            MessageLookupByLibrary.simpleMessage("Blocco con password"),
        "passwordStrength": m0,
        "passwordStrengthInfo": MessageLookupByLibrary.simpleMessage(
            "La sicurezza della password viene calcolata considerando la lunghezza della password, i caratteri usati e se la password appare o meno nelle prime 10.000 password più usate"),
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Noi non memorizziamo la tua password, quindi se te la dimentichi, <underline>non possiamo decriptare i tuoi dati</underline>"),
        "paymentDetails":
            MessageLookupByLibrary.simpleMessage("Dettagli di Pagamento"),
        "paymentFailed":
            MessageLookupByLibrary.simpleMessage("Pagamento non riuscito"),
        "paymentFailedMessage": MessageLookupByLibrary.simpleMessage(
            "Purtroppo il tuo pagamento non è riuscito. Contatta l\'assistenza e ti aiuteremo!"),
        "paymentFailedTalkToProvider": m50,
        "pendingItems":
            MessageLookupByLibrary.simpleMessage("Elementi in sospeso"),
        "pendingSync":
            MessageLookupByLibrary.simpleMessage("Sincronizzazione in sospeso"),
        "people": MessageLookupByLibrary.simpleMessage("Persone"),
        "peopleUsingYourCode": MessageLookupByLibrary.simpleMessage(
            "Persone che hanno usato il tuo codice"),
        "permDeleteWarning": MessageLookupByLibrary.simpleMessage(
            "Tutti gli elementi nel cestino verranno eliminati definitivamente\n\nQuesta azione non può essere annullata"),
        "permanentlyDelete":
            MessageLookupByLibrary.simpleMessage("Elimina definitivamente"),
        "permanentlyDeleteFromDevice": MessageLookupByLibrary.simpleMessage(
            "Eliminare definitivamente dal dispositivo?"),
        "personName":
            MessageLookupByLibrary.simpleMessage("Nome della persona"),
        "photoDescriptions":
            MessageLookupByLibrary.simpleMessage("Descrizioni delle foto"),
        "photoGridSize":
            MessageLookupByLibrary.simpleMessage("Dimensione griglia foto"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("foto"),
        "photos": MessageLookupByLibrary.simpleMessage("Foto"),
        "photosAddedByYouWillBeRemovedFromTheAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Le foto aggiunte da te verranno rimosse dall\'album"),
        "photosCount": m51,
        "pickCenterPoint": MessageLookupByLibrary.simpleMessage(
            "Selezionare il punto centrale"),
        "pinAlbum": MessageLookupByLibrary.simpleMessage("Fissa l\'album"),
        "pinLock": MessageLookupByLibrary.simpleMessage("Blocco con PIN"),
        "playOnTv":
            MessageLookupByLibrary.simpleMessage("Riproduci album sulla TV"),
        "playStoreFreeTrialValidTill": m52,
        "playstoreSubscription":
            MessageLookupByLibrary.simpleMessage("Abbonamento su PlayStore"),
        "pleaseCheckYourInternetConnectionAndTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Si prega di verificare la propria connessione Internet e riprovare."),
        "pleaseContactSupportAndWeWillBeHappyToHelp":
            MessageLookupByLibrary.simpleMessage(
                "Contatta support@ente.io e saremo felici di aiutarti!"),
        "pleaseContactSupportIfTheProblemPersists":
            MessageLookupByLibrary.simpleMessage(
                "Riprova. Se il problema persiste, ti invitiamo a contattare l\'assistenza"),
        "pleaseEmailUsAt": m53,
        "pleaseGrantPermissions":
            MessageLookupByLibrary.simpleMessage("Concedi i permessi"),
        "pleaseLoginAgain": MessageLookupByLibrary.simpleMessage(
            "Effettua nuovamente l\'accesso"),
        "pleaseSelectQuickLinksToRemove": MessageLookupByLibrary.simpleMessage(
            "Si prega di selezionare i link rapidi da rimuovere"),
        "pleaseSendTheLogsTo": m54,
        "pleaseTryAgain": MessageLookupByLibrary.simpleMessage("Riprova"),
        "pleaseVerifyTheCodeYouHaveEntered":
            MessageLookupByLibrary.simpleMessage(
                "Verifica il codice che hai inserito"),
        "pleaseWait": MessageLookupByLibrary.simpleMessage("Attendere..."),
        "pleaseWaitDeletingAlbum": MessageLookupByLibrary.simpleMessage(
            "Attendere, sto eliminando l\'album"),
        "pleaseWaitForSometimeBeforeRetrying":
            MessageLookupByLibrary.simpleMessage("Riprova tra qualche minuto"),
        "preparingLogs":
            MessageLookupByLibrary.simpleMessage("Preparando i log..."),
        "preserveMore": MessageLookupByLibrary.simpleMessage("Salva più foto"),
        "pressAndHoldToPlayVideo": MessageLookupByLibrary.simpleMessage(
            "Tieni premuto per riprodurre il video"),
        "pressAndHoldToPlayVideoDetailed": MessageLookupByLibrary.simpleMessage(
            "Tieni premuto sull\'immagine per riprodurre il video"),
        "privacy": MessageLookupByLibrary.simpleMessage("Privacy"),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Privacy Policy"),
        "privateBackups":
            MessageLookupByLibrary.simpleMessage("Backup privato"),
        "privateSharing":
            MessageLookupByLibrary.simpleMessage("Condivisioni private"),
        "proceed": MessageLookupByLibrary.simpleMessage("Prosegui"),
        "processingImport": m55,
        "publicLinkCreated":
            MessageLookupByLibrary.simpleMessage("Link pubblico creato"),
        "publicLinkEnabled":
            MessageLookupByLibrary.simpleMessage("Link pubblico abilitato"),
        "quickLinks":
            MessageLookupByLibrary.simpleMessage("Collegamenti rapidi"),
        "radius": MessageLookupByLibrary.simpleMessage("Raggio"),
        "raiseTicket": MessageLookupByLibrary.simpleMessage("Invia ticket"),
        "rateTheApp": MessageLookupByLibrary.simpleMessage("Valuta l\'app"),
        "rateUs": MessageLookupByLibrary.simpleMessage("Lascia una recensione"),
        "rateUsOnStore": m56,
        "recover": MessageLookupByLibrary.simpleMessage("Recupera"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("Recupera account"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Recupera"),
        "recoveryAccount":
            MessageLookupByLibrary.simpleMessage("Recupera l\'account"),
        "recoveryInitiated":
            MessageLookupByLibrary.simpleMessage("Recupero avviato"),
        "recoveryInitiatedDesc": m57,
        "recoveryKey":
            MessageLookupByLibrary.simpleMessage("Chiave di recupero"),
        "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Chiave di recupero copiata negli appunti"),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
            "Se dimentichi la password, questa chiave è l\'unico modo per recuperare i tuoi dati."),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
            "Noi non memorizziamo questa chiave, per favore salva queste 24 parole in un posto sicuro."),
        "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
            "Ottimo! La tua chiave di recupero è valida. Grazie per averla verificata.\n\nRicordati di salvare la tua chiave di recupero in un posto sicuro."),
        "recoveryKeyVerified": MessageLookupByLibrary.simpleMessage(
            "Chiave di recupero verificata"),
        "recoveryKeyVerifyReason": MessageLookupByLibrary.simpleMessage(
            "Se hai dimenticato la password, la tua chiave di ripristino è l\'unico modo per recuperare le tue foto. La puoi trovare in Impostazioni > Account.\n\nInserisci la tua chiave di recupero per verificare di averla salvata correttamente."),
        "recoveryReady": m58,
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("Recupero riuscito!"),
        "recoveryWarning": MessageLookupByLibrary.simpleMessage(
            "Un contatto fidato sta tentando di accedere al tuo account"),
        "recoveryWarningBody": m59,
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "Il dispositivo attuale non è abbastanza potente per verificare la tua password, ma la possiamo rigenerare in un modo che funzioni su tutti i dispositivi.\n\nEffettua il login utilizzando la tua chiave di recupero e rigenera la tua password (puoi utilizzare nuovamente la stessa se vuoi)."),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Reimposta password"),
        "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
        "reenterPassword":
            MessageLookupByLibrary.simpleMessage("Reinserisci la password"),
        "reenterPin":
            MessageLookupByLibrary.simpleMessage("Reinserisci il PIN"),
        "referFriendsAnd2xYourPlan": MessageLookupByLibrary.simpleMessage(
            "Invita un amico e raddoppia il tuo spazio"),
        "referralStep1": MessageLookupByLibrary.simpleMessage(
            "1. Condividi questo codice con i tuoi amici"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "2. Si iscrivono per un piano a pagamento"),
        "referralStep3": m60,
        "referrals": MessageLookupByLibrary.simpleMessage("Invita un Amico"),
        "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
            "I referral code sono attualmente in pausa"),
        "rejectRecovery":
            MessageLookupByLibrary.simpleMessage("Rifiuta il recupero"),
        "remindToEmptyDeviceTrash": MessageLookupByLibrary.simpleMessage(
            "Vuota anche \"Cancellati di recente\" da \"Impostazioni\" -> \"Storage\" per avere più spazio libero"),
        "remindToEmptyEnteTrash": MessageLookupByLibrary.simpleMessage(
            "Svuota anche il tuo \"Cestino\" per avere più spazio libero"),
        "remoteImages": MessageLookupByLibrary.simpleMessage("Immagini remote"),
        "remoteThumbnails":
            MessageLookupByLibrary.simpleMessage("Miniature remote"),
        "remoteVideos": MessageLookupByLibrary.simpleMessage("Video remoti"),
        "remove": MessageLookupByLibrary.simpleMessage("Rimuovi"),
        "removeDuplicates":
            MessageLookupByLibrary.simpleMessage("Rimuovi i doppioni"),
        "removeDuplicatesDesc": MessageLookupByLibrary.simpleMessage(
            "Verifica e rimuovi i file che sono esattamente duplicati."),
        "removeFromAlbum":
            MessageLookupByLibrary.simpleMessage("Rimuovi dall\'album"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("Rimuovi dall\'album?"),
        "removeFromFavorite":
            MessageLookupByLibrary.simpleMessage("Rimuovi dai preferiti"),
        "removeInvite": MessageLookupByLibrary.simpleMessage("Rimuovi invito"),
        "removeLink": MessageLookupByLibrary.simpleMessage("Elimina link"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Rimuovi partecipante"),
        "removeParticipantBody": m61,
        "removePersonLabel":
            MessageLookupByLibrary.simpleMessage("Rimuovi etichetta persona"),
        "removePublicLink":
            MessageLookupByLibrary.simpleMessage("Rimuovi link pubblico"),
        "removePublicLinks":
            MessageLookupByLibrary.simpleMessage("Rimuovi i link pubblici"),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
            "Alcuni degli elementi che stai rimuovendo sono stati aggiunti da altre persone e ne perderai l\'accesso"),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Rimuovi?"),
        "removeYourselfAsTrustedContact": MessageLookupByLibrary.simpleMessage(
            "Rimuovi te stesso come contatto fidato"),
        "removingFromFavorites":
            MessageLookupByLibrary.simpleMessage("Rimosso dai preferiti..."),
        "rename": MessageLookupByLibrary.simpleMessage("Rinomina"),
        "renameAlbum": MessageLookupByLibrary.simpleMessage("Rinomina album"),
        "renameFile": MessageLookupByLibrary.simpleMessage("Rinomina file"),
        "renewSubscription":
            MessageLookupByLibrary.simpleMessage("Rinnova abbonamento"),
        "renewsOn": m62,
        "reportABug": MessageLookupByLibrary.simpleMessage("Segnala un bug"),
        "reportBug": MessageLookupByLibrary.simpleMessage("Segnala un bug"),
        "resendEmail": MessageLookupByLibrary.simpleMessage("Rinvia email"),
        "resetIgnoredFiles":
            MessageLookupByLibrary.simpleMessage("Ripristina i file ignorati"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Reimposta password"),
        "resetPerson": MessageLookupByLibrary.simpleMessage("Rimuovi"),
        "resetToDefault":
            MessageLookupByLibrary.simpleMessage("Ripristina predefinita"),
        "restore": MessageLookupByLibrary.simpleMessage("Ripristina"),
        "restoreToAlbum":
            MessageLookupByLibrary.simpleMessage("Ripristina l\'album"),
        "restoringFiles":
            MessageLookupByLibrary.simpleMessage("Ripristinando file..."),
        "resumableUploads":
            MessageLookupByLibrary.simpleMessage("Caricamenti riattivabili"),
        "retry": MessageLookupByLibrary.simpleMessage("Riprova"),
        "review": MessageLookupByLibrary.simpleMessage("Revisiona"),
        "reviewDeduplicateItems": MessageLookupByLibrary.simpleMessage(
            "Controlla ed elimina gli elementi che credi siano dei doppioni."),
        "reviewSuggestions":
            MessageLookupByLibrary.simpleMessage("Esamina i suggerimenti"),
        "right": MessageLookupByLibrary.simpleMessage("Destra"),
        "rotate": MessageLookupByLibrary.simpleMessage("Ruota"),
        "rotateLeft": MessageLookupByLibrary.simpleMessage("Ruota a sinistra"),
        "rotateRight": MessageLookupByLibrary.simpleMessage("Ruota a destra"),
        "safelyStored":
            MessageLookupByLibrary.simpleMessage("Salvati in sicurezza"),
        "save": MessageLookupByLibrary.simpleMessage("Salva"),
        "saveCollage": MessageLookupByLibrary.simpleMessage("Salva il collage"),
        "saveCopy": MessageLookupByLibrary.simpleMessage("Salva una copia"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Salva chiave"),
        "savePerson": MessageLookupByLibrary.simpleMessage("Salva persona"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Salva la tua chiave di recupero se non l\'hai ancora fatto"),
        "saving": MessageLookupByLibrary.simpleMessage("Salvataggio..."),
        "savingEdits":
            MessageLookupByLibrary.simpleMessage("Salvataggio modifiche..."),
        "scanCode": MessageLookupByLibrary.simpleMessage("Scansiona codice"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Scansione questo codice QR\ncon la tua app di autenticazione"),
        "search": MessageLookupByLibrary.simpleMessage("Cerca"),
        "searchAlbumsEmptySection":
            MessageLookupByLibrary.simpleMessage("Album"),
        "searchByAlbumNameHint":
            MessageLookupByLibrary.simpleMessage("Nome album"),
        "searchByExamples": MessageLookupByLibrary.simpleMessage(
            "• Nomi degli album (es. \"Camera\")\n• Tipi di file (es. \"Video\", \".gif\")\n• Anni e mesi (e.. \"2022\", \"gennaio\")\n• Vacanze (ad es. \"Natale\")\n• Descrizioni delle foto (ad es. “#mare”)"),
        "searchCaptionEmptySection": MessageLookupByLibrary.simpleMessage(
            "Aggiungi descrizioni come \"#viaggio\" nelle informazioni delle foto per trovarle rapidamente qui"),
        "searchDatesEmptySection": MessageLookupByLibrary.simpleMessage(
            "Ricerca per data, mese o anno"),
        "searchDiscoverEmptySection": MessageLookupByLibrary.simpleMessage(
            "Le immagini saranno mostrate qui una volta che l\'elaborazione e la sincronizzazione saranno completate"),
        "searchFaceEmptySection": MessageLookupByLibrary.simpleMessage(
            "Le persone saranno mostrate qui una volta completata l\'indicizzazione"),
        "searchFileTypesAndNamesEmptySection":
            MessageLookupByLibrary.simpleMessage("Tipi e nomi di file"),
        "searchHint1": MessageLookupByLibrary.simpleMessage(
            "Ricerca rapida sul dispositivo"),
        "searchHint2": MessageLookupByLibrary.simpleMessage(
            "Date delle foto, descrizioni"),
        "searchHint3":
            MessageLookupByLibrary.simpleMessage("Album, nomi di file e tipi"),
        "searchHint4": MessageLookupByLibrary.simpleMessage("Luogo"),
        "searchHint5": MessageLookupByLibrary.simpleMessage(
            "In arrivo: Facce & ricerca magica ✨"),
        "searchLocationEmptySection": MessageLookupByLibrary.simpleMessage(
            "Raggruppa foto scattate entro un certo raggio da una foto"),
        "searchPeopleEmptySection": MessageLookupByLibrary.simpleMessage(
            "Invita persone e vedrai qui tutte le foto condivise da loro"),
        "searchPersonsEmptySection": MessageLookupByLibrary.simpleMessage(
            "Le persone saranno mostrate qui una volta che l\'elaborazione e la sincronizzazione saranno completate"),
        "searchResultCount": m63,
        "security": MessageLookupByLibrary.simpleMessage("Sicurezza"),
        "selectALocation":
            MessageLookupByLibrary.simpleMessage("Seleziona un luogo"),
        "selectALocationFirst":
            MessageLookupByLibrary.simpleMessage("Scegli prima una posizione"),
        "selectAlbum": MessageLookupByLibrary.simpleMessage("Seleziona album"),
        "selectAll": MessageLookupByLibrary.simpleMessage("Seleziona tutto"),
        "selectCoverPhoto":
            MessageLookupByLibrary.simpleMessage("Seleziona foto di copertina"),
        "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
            "Seleziona cartelle per il backup"),
        "selectItemsToAdd": MessageLookupByLibrary.simpleMessage(
            "Seleziona gli elementi da aggiungere"),
        "selectLanguage":
            MessageLookupByLibrary.simpleMessage("Seleziona una lingua"),
        "selectMorePhotos":
            MessageLookupByLibrary.simpleMessage("Seleziona più foto"),
        "selectReason":
            MessageLookupByLibrary.simpleMessage("Seleziona un motivo"),
        "selectYourPlan":
            MessageLookupByLibrary.simpleMessage("Seleziona un piano"),
        "selectedFilesAreNotOnEnte": MessageLookupByLibrary.simpleMessage(
            "I file selezionati non sono su Ente"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "Le cartelle selezionate verranno crittografate e salvate su ente"),
        "selectedItemsWillBeDeletedFromAllAlbumsAndMoved":
            MessageLookupByLibrary.simpleMessage(
                "Gli elementi selezionati verranno eliminati da tutti gli album e spostati nel cestino."),
        "selectedPhotos": m6,
        "selectedPhotosWithYours": m65,
        "send": MessageLookupByLibrary.simpleMessage("Invia"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("Invia email"),
        "sendInvite": MessageLookupByLibrary.simpleMessage("Invita"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Invia link"),
        "serverEndpoint":
            MessageLookupByLibrary.simpleMessage("Endpoint del server"),
        "sessionExpired":
            MessageLookupByLibrary.simpleMessage("Sessione scaduta"),
        "sessionIdMismatch": MessageLookupByLibrary.simpleMessage(
            "ID sessione non corrispondente"),
        "setAPassword":
            MessageLookupByLibrary.simpleMessage("Imposta una password"),
        "setAs": MessageLookupByLibrary.simpleMessage("Imposta come"),
        "setCover": MessageLookupByLibrary.simpleMessage("Imposta copertina"),
        "setLabel": MessageLookupByLibrary.simpleMessage("Imposta"),
        "setNewPassword":
            MessageLookupByLibrary.simpleMessage("Imposta una nuova password"),
        "setNewPin":
            MessageLookupByLibrary.simpleMessage("Imposta un nuovo PIN"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Imposta password"),
        "setRadius": MessageLookupByLibrary.simpleMessage("Imposta raggio"),
        "setupComplete":
            MessageLookupByLibrary.simpleMessage("Configurazione completata"),
        "share": MessageLookupByLibrary.simpleMessage("Condividi"),
        "shareALink": MessageLookupByLibrary.simpleMessage("Condividi un link"),
        "shareAlbumHint": MessageLookupByLibrary.simpleMessage(
            "Apri un album e tocca il pulsante di condivisione in alto a destra per condividerlo."),
        "shareAnAlbumNow":
            MessageLookupByLibrary.simpleMessage("Condividi un album"),
        "shareLink": MessageLookupByLibrary.simpleMessage("Condividi link"),
        "shareMyVerificationID": m66,
        "shareOnlyWithThePeopleYouWant": MessageLookupByLibrary.simpleMessage(
            "Condividi solo con le persone che vuoi"),
        "shareTextConfirmOthersVerificationID": m7,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Scarica Ente in modo da poter facilmente condividere foto e video in qualità originale\n\nhttps://ente.io"),
        "shareTextReferralCode": m67,
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
            "Condividi con utenti che non hanno un account Ente"),
        "shareWithPeopleSectionTitle": m68,
        "shareYourFirstAlbum": MessageLookupByLibrary.simpleMessage(
            "Condividi il tuo primo album"),
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Crea album condivisi e collaborativi con altri utenti di Ente, inclusi gli utenti con piani gratuiti."),
        "sharedByMe": MessageLookupByLibrary.simpleMessage("Condiviso da me"),
        "sharedByYou": MessageLookupByLibrary.simpleMessage("Condivise da te"),
        "sharedPhotoNotifications":
            MessageLookupByLibrary.simpleMessage("Nuove foto condivise"),
        "sharedPhotoNotificationsExplanation": MessageLookupByLibrary.simpleMessage(
            "Ricevi notifiche quando qualcuno aggiunge una foto a un album condiviso, di cui fai parte"),
        "sharedWith": m69,
        "sharedWithMe":
            MessageLookupByLibrary.simpleMessage("Condivisi con me"),
        "sharedWithYou":
            MessageLookupByLibrary.simpleMessage("Condivise con te"),
        "sharing":
            MessageLookupByLibrary.simpleMessage("Condivisione in corso..."),
        "showMemories": MessageLookupByLibrary.simpleMessage("Mostra ricordi"),
        "showPerson": MessageLookupByLibrary.simpleMessage("Mostra persona"),
        "signOutFromOtherDevices": MessageLookupByLibrary.simpleMessage(
            "Esci dagli altri dispositivi"),
        "signOutOtherBody": MessageLookupByLibrary.simpleMessage(
            "Se pensi che qualcuno possa conoscere la tua password, puoi forzare tutti gli altri dispositivi che usano il tuo account ad uscire."),
        "signOutOtherDevices": MessageLookupByLibrary.simpleMessage(
            "Esci dagli altri dispositivi"),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "Accetto i <u-terms>termini di servizio</u-terms> e la <u-policy>politica sulla privacy</u-policy>"),
        "singleFileDeleteFromDevice": m70,
        "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
            "Verrà eliminato da tutti gli album."),
        "singleFileInBothLocalAndRemote": m71,
        "singleFileInRemoteOnly": m72,
        "skip": MessageLookupByLibrary.simpleMessage("Salta"),
        "social": MessageLookupByLibrary.simpleMessage("Social"),
        "someItemsAreInBothEnteAndYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Alcuni elementi sono sia su Ente che sul tuo dispositivo."),
        "someOfTheFilesYouAreTryingToDeleteAre":
            MessageLookupByLibrary.simpleMessage(
                "Alcuni dei file che si sta tentando di eliminare sono disponibili solo sul dispositivo e non possono essere recuperati se cancellati"),
        "someoneSharingAlbumsWithYouShouldSeeTheSameId":
            MessageLookupByLibrary.simpleMessage(
                "Chi condivide gli album con te deve vedere lo stesso ID sul proprio dispositivo."),
        "somethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Qualcosa è andato storto"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Qualcosa è andato storto, per favore riprova"),
        "sorry": MessageLookupByLibrary.simpleMessage("Siamo spiacenti"),
        "sorryCouldNotAddToFavorites": MessageLookupByLibrary.simpleMessage(
            "Spiacenti, non è stato possibile aggiungere ai preferiti!"),
        "sorryCouldNotRemoveFromFavorites": MessageLookupByLibrary.simpleMessage(
            "Siamo spiacenti, non è stato possibile rimuovere dai preferiti!"),
        "sorryTheCodeYouveEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "Il codice immesso non è corretto"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "Siamo spiacenti, non possiamo generare le chiavi sicure su questo dispositivo.\n\nPer favore, accedi da un altro dispositivo."),
        "sort": MessageLookupByLibrary.simpleMessage("Ordina"),
        "sortAlbumsBy": MessageLookupByLibrary.simpleMessage("Ordina per"),
        "sortNewestFirst":
            MessageLookupByLibrary.simpleMessage("Prima le più nuove"),
        "sortOldestFirst":
            MessageLookupByLibrary.simpleMessage("Prima le più vecchie"),
        "sparkleSuccess":
            MessageLookupByLibrary.simpleMessage("✨ Operazione riuscita"),
        "startAccountRecoveryTitle":
            MessageLookupByLibrary.simpleMessage("Avvia il recupero"),
        "startBackup": MessageLookupByLibrary.simpleMessage("Avvia backup"),
        "status": MessageLookupByLibrary.simpleMessage("Stato"),
        "stopCastingBody": MessageLookupByLibrary.simpleMessage(
            "Vuoi interrompere la trasmissione?"),
        "stopCastingTitle":
            MessageLookupByLibrary.simpleMessage("Interrompi la trasmissione"),
        "storage":
            MessageLookupByLibrary.simpleMessage("Spazio di archiviazione"),
        "storageBreakupFamily":
            MessageLookupByLibrary.simpleMessage("Famiglia"),
        "storageBreakupYou": MessageLookupByLibrary.simpleMessage("Tu"),
        "storageInGB": m1,
        "storageLimitExceeded": MessageLookupByLibrary.simpleMessage(
            "Limite d\'archiviazione superato"),
        "storageUsageInfo": m73,
        "strongStrength": MessageLookupByLibrary.simpleMessage("Forte"),
        "subAlreadyLinkedErrMessage": m74,
        "subWillBeCancelledOn": m75,
        "subscribe": MessageLookupByLibrary.simpleMessage("Iscriviti"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "È necessario un abbonamento a pagamento attivo per abilitare la condivisione."),
        "subscription": MessageLookupByLibrary.simpleMessage("Abbonamento"),
        "success": MessageLookupByLibrary.simpleMessage("Operazione riuscita"),
        "successfullyArchived":
            MessageLookupByLibrary.simpleMessage("Archiviato correttamente"),
        "successfullyHid":
            MessageLookupByLibrary.simpleMessage("Nascosta con successo"),
        "successfullyUnarchived": MessageLookupByLibrary.simpleMessage(
            "Rimosso dall\'archivio correttamente"),
        "successfullyUnhid": MessageLookupByLibrary.simpleMessage(
            "Rimossa dal nascondiglio con successo"),
        "suggestFeatures":
            MessageLookupByLibrary.simpleMessage("Suggerisci una funzionalità"),
        "support": MessageLookupByLibrary.simpleMessage("Assistenza"),
        "syncProgress": m76,
        "syncStopped":
            MessageLookupByLibrary.simpleMessage("Sincronizzazione interrotta"),
        "syncing": MessageLookupByLibrary.simpleMessage(
            "Sincronizzazione in corso..."),
        "systemTheme": MessageLookupByLibrary.simpleMessage("Sistema"),
        "tapToCopy": MessageLookupByLibrary.simpleMessage("tocca per copiare"),
        "tapToEnterCode": MessageLookupByLibrary.simpleMessage(
            "Tocca per inserire il codice"),
        "tapToUnlock":
            MessageLookupByLibrary.simpleMessage("Tocca per sbloccare"),
        "tapToUpload":
            MessageLookupByLibrary.simpleMessage("Premi per caricare"),
        "tapToUploadIsIgnoredDue": m77,
        "tempErrorContactSupportIfPersists": MessageLookupByLibrary.simpleMessage(
            "Sembra che qualcosa sia andato storto. Riprova tra un po\'. Se l\'errore persiste, contatta il nostro team di supporto."),
        "terminate": MessageLookupByLibrary.simpleMessage("Terminata"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Termina sessione?"),
        "terms": MessageLookupByLibrary.simpleMessage("Termini d\'uso"),
        "termsOfServicesTitle":
            MessageLookupByLibrary.simpleMessage("Termini d\'uso"),
        "thankYou": MessageLookupByLibrary.simpleMessage("Grazie"),
        "thankYouForSubscribing": MessageLookupByLibrary.simpleMessage(
            "Grazie per esserti iscritto!"),
        "theDownloadCouldNotBeCompleted": MessageLookupByLibrary.simpleMessage(
            "Il download non può essere completato"),
        "theRecoveryKeyYouEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "La chiave di recupero inserita non è corretta"),
        "theme": MessageLookupByLibrary.simpleMessage("Tema"),
        "theseItemsWillBeDeletedFromYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Questi file verranno eliminati dal tuo dispositivo."),
        "theyAlsoGetXGb": m8,
        "theyWillBeDeletedFromAllAlbums": MessageLookupByLibrary.simpleMessage(
            "Verranno eliminati da tutti gli album."),
        "thisActionCannotBeUndone": MessageLookupByLibrary.simpleMessage(
            "Questa azione non può essere annullata"),
        "thisAlbumAlreadyHDACollaborativeLink":
            MessageLookupByLibrary.simpleMessage(
                "Questo album ha già un link collaborativo"),
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "Può essere utilizzata per recuperare il tuo account in caso tu non possa usare l\'autenticazione a due fattori"),
        "thisDevice":
            MessageLookupByLibrary.simpleMessage("Questo dispositivo"),
        "thisEmailIsAlreadyInUse": MessageLookupByLibrary.simpleMessage(
            "Questo indirizzo email è già registrato"),
        "thisImageHasNoExifData": MessageLookupByLibrary.simpleMessage(
            "Questa immagine non ha dati EXIF"),
        "thisIsPersonVerificationId": m78,
        "thisIsYourVerificationId": MessageLookupByLibrary.simpleMessage(
            "Questo è il tuo ID di verifica"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Verrai disconnesso dai seguenti dispositivi:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Verrai disconnesso dal tuo dispositivo!"),
        "thisWillRemovePublicLinksOfAllSelectedQuickLinks":
            MessageLookupByLibrary.simpleMessage(
                "Questo rimuoverà i link pubblici di tutti i link rapidi selezionati."),
        "toEnableAppLockPleaseSetupDevicePasscodeOrScreen":
            MessageLookupByLibrary.simpleMessage(
                "Per abilitare il blocco dell\'app, configura il codice di accesso del dispositivo o il blocco schermo nelle impostazioni di sistema."),
        "toHideAPhotoOrVideo": MessageLookupByLibrary.simpleMessage(
            "Per nascondere una foto o un video"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "Per reimpostare la tua password, verifica prima la tua email."),
        "todaysLogs": MessageLookupByLibrary.simpleMessage("Log di oggi"),
        "tooManyIncorrectAttempts":
            MessageLookupByLibrary.simpleMessage("Troppi tentativi errati"),
        "total": MessageLookupByLibrary.simpleMessage("totale"),
        "totalSize": MessageLookupByLibrary.simpleMessage("Dimensioni totali"),
        "trash": MessageLookupByLibrary.simpleMessage("Cestino"),
        "trashDaysLeft": m79,
        "trim": MessageLookupByLibrary.simpleMessage("Taglia"),
        "trustedContacts":
            MessageLookupByLibrary.simpleMessage("Contatti fidati"),
        "trustedInviteBody": m80,
        "tryAgain": MessageLookupByLibrary.simpleMessage("Riprova"),
        "turnOnBackupForAutoUpload": MessageLookupByLibrary.simpleMessage(
            "Attiva il backup per caricare automaticamente i file aggiunti a questa cartella del dispositivo su Ente."),
        "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
        "twoMonthsFreeOnYearlyPlans": MessageLookupByLibrary.simpleMessage(
            "2 mesi gratis sui piani annuali"),
        "twofactor": MessageLookupByLibrary.simpleMessage("Due fattori"),
        "twofactorAuthenticationHasBeenDisabled":
            MessageLookupByLibrary.simpleMessage(
                "L\'autenticazione a due fattori è stata disabilitata"),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage(
                "Autenticazione a due fattori"),
        "twofactorAuthenticationSuccessfullyReset":
            MessageLookupByLibrary.simpleMessage(
                "Autenticazione a due fattori resettata con successo"),
        "twofactorSetup": MessageLookupByLibrary.simpleMessage(
            "Configura autenticazione a due fattori"),
        "unarchive":
            MessageLookupByLibrary.simpleMessage("Rimuovi dall\'archivio"),
        "unarchiveAlbum": MessageLookupByLibrary.simpleMessage(
            "Rimuovi album dall\'archivio"),
        "unarchiving":
            MessageLookupByLibrary.simpleMessage("Togliendo dall\'archivio..."),
        "unavailableReferralCode": MessageLookupByLibrary.simpleMessage(
            "Siamo spiacenti, questo codice non è disponibile."),
        "uncategorized":
            MessageLookupByLibrary.simpleMessage("Senza categoria"),
        "unhide": MessageLookupByLibrary.simpleMessage("Mostra"),
        "unhideToAlbum":
            MessageLookupByLibrary.simpleMessage("Non nascondere l\'album"),
        "unhiding": MessageLookupByLibrary.simpleMessage("Rivelando..."),
        "unhidingFilesToAlbum":
            MessageLookupByLibrary.simpleMessage("Mostra i file nell\'album"),
        "unlock": MessageLookupByLibrary.simpleMessage("Sblocca"),
        "unpinAlbum": MessageLookupByLibrary.simpleMessage("Non fissare album"),
        "unselectAll":
            MessageLookupByLibrary.simpleMessage("Deseleziona tutto"),
        "update": MessageLookupByLibrary.simpleMessage("Aggiorna"),
        "updateAvailable":
            MessageLookupByLibrary.simpleMessage("Aggiornamento disponibile"),
        "updatingFolderSelection": MessageLookupByLibrary.simpleMessage(
            "Aggiornamento della selezione delle cartelle..."),
        "upgrade":
            MessageLookupByLibrary.simpleMessage("Acquista altro spazio"),
        "uploadIsIgnoredDueToIgnorereason": m82,
        "uploadingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Caricamento dei file nell\'album..."),
        "uploadingMultipleMemories": m83,
        "uploadingSingleMemory":
            MessageLookupByLibrary.simpleMessage("Conservando 1 ricordo..."),
        "upto50OffUntil4thDec": MessageLookupByLibrary.simpleMessage(
            "Sconto del 50%, fino al 4 dicembre."),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "Lo spazio disponibile è limitato dal tuo piano corrente. L\'archiviazione in eccesso diventerà automaticamente utilizzabile quando aggiornerai il tuo piano."),
        "useAsCover":
            MessageLookupByLibrary.simpleMessage("Usa come copertina"),
        "useDifferentPlayerInfo": MessageLookupByLibrary.simpleMessage(
            "Hai problemi a riprodurre questo video? Premi a lungo qui per provare un altro lettore."),
        "usePublicLinksForPeopleNotOnEnte":
            MessageLookupByLibrary.simpleMessage(
                "Usa link pubblici per persone non registrate su Ente"),
        "useRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Utilizza un codice di recupero"),
        "useSelectedPhoto":
            MessageLookupByLibrary.simpleMessage("Usa la foto selezionata"),
        "usedSpace": MessageLookupByLibrary.simpleMessage("Spazio utilizzato"),
        "validTill": m84,
        "verificationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Verifica fallita, per favore prova di nuovo"),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("ID di verifica"),
        "verify": MessageLookupByLibrary.simpleMessage("Verifica"),
        "verifyEmail": MessageLookupByLibrary.simpleMessage("Verifica email"),
        "verifyEmailID": m85,
        "verifyIDLabel": MessageLookupByLibrary.simpleMessage("Verifica"),
        "verifyPasskey":
            MessageLookupByLibrary.simpleMessage("Verifica passkey"),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Verifica password"),
        "verifying":
            MessageLookupByLibrary.simpleMessage("Verifica in corso..."),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Verifica della chiave di recupero..."),
        "videoInfo": MessageLookupByLibrary.simpleMessage("Informazioni video"),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("video"),
        "videos": MessageLookupByLibrary.simpleMessage("Video"),
        "viewActiveSessions":
            MessageLookupByLibrary.simpleMessage("Visualizza sessioni attive"),
        "viewAddOnButton": MessageLookupByLibrary.simpleMessage(
            "Visualizza componenti aggiuntivi"),
        "viewAll": MessageLookupByLibrary.simpleMessage("Visualizza tutte"),
        "viewAllExifData":
            MessageLookupByLibrary.simpleMessage("Mostra tutti i dati EXIF"),
        "viewLargeFiles":
            MessageLookupByLibrary.simpleMessage("File di grandi dimensioni"),
        "viewLargeFilesDesc": MessageLookupByLibrary.simpleMessage(
            "Visualizza i file che stanno occupando la maggior parte dello spazio di archiviazione."),
        "viewLogs": MessageLookupByLibrary.simpleMessage("Visualizza i log"),
        "viewRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Visualizza chiave di recupero"),
        "viewer": MessageLookupByLibrary.simpleMessage("Sola lettura"),
        "viewersSuccessfullyAdded": m86,
        "visitWebToManage": MessageLookupByLibrary.simpleMessage(
            "Visita web.ente.io per gestire il tuo abbonamento"),
        "waitingForVerification":
            MessageLookupByLibrary.simpleMessage("In attesa di verifica..."),
        "waitingForWifi":
            MessageLookupByLibrary.simpleMessage("In attesa del WiFi..."),
        "warning": MessageLookupByLibrary.simpleMessage("Attenzione"),
        "weAreOpenSource":
            MessageLookupByLibrary.simpleMessage("Siamo open source!"),
        "weDontSupportEditingPhotosAndAlbumsThatYouDont":
            MessageLookupByLibrary.simpleMessage(
                "Non puoi modificare foto e album che non possiedi"),
        "weHaveSendEmailTo": m2,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Debole"),
        "welcomeBack": MessageLookupByLibrary.simpleMessage("Bentornato/a!"),
        "whatsNew": MessageLookupByLibrary.simpleMessage("Novità"),
        "whyAddTrustContact": MessageLookupByLibrary.simpleMessage(
            "Un contatto fidato può aiutare a recuperare i tuoi dati."),
        "yearShort": MessageLookupByLibrary.simpleMessage("anno"),
        "yearly": MessageLookupByLibrary.simpleMessage("Annuale"),
        "yearsAgo": m87,
        "yes": MessageLookupByLibrary.simpleMessage("Si"),
        "yesCancel": MessageLookupByLibrary.simpleMessage("Sì, cancella"),
        "yesConvertToViewer": MessageLookupByLibrary.simpleMessage(
            "Sì, converti in sola lettura"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("Sì, elimina"),
        "yesDiscardChanges":
            MessageLookupByLibrary.simpleMessage("Sì, ignora le mie modifiche"),
        "yesLogout": MessageLookupByLibrary.simpleMessage("Sì, disconnetti"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("Sì, rimuovi"),
        "yesRenew": MessageLookupByLibrary.simpleMessage("Sì, Rinnova"),
        "yesResetPerson":
            MessageLookupByLibrary.simpleMessage("Sì, resetta persona"),
        "you": MessageLookupByLibrary.simpleMessage("Tu"),
        "youAreOnAFamilyPlan": MessageLookupByLibrary.simpleMessage(
            "Sei un utente con piano famiglia!"),
        "youAreOnTheLatestVersion": MessageLookupByLibrary.simpleMessage(
            "Stai utilizzando l\'ultima versione"),
        "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "* Puoi al massimo raddoppiare il tuo spazio"),
        "youCanManageYourLinksInTheShareTab":
            MessageLookupByLibrary.simpleMessage(
                "Puoi gestire i tuoi link nella scheda condivisione."),
        "youCanTrySearchingForADifferentQuery":
            MessageLookupByLibrary.simpleMessage(
                "Prova con una ricerca differente."),
        "youCannotDowngradeToThisPlan": MessageLookupByLibrary.simpleMessage(
            "Non puoi effettuare il downgrade su questo piano"),
        "youCannotShareWithYourself": MessageLookupByLibrary.simpleMessage(
            "Non puoi condividere con te stesso"),
        "youDontHaveAnyArchivedItems": MessageLookupByLibrary.simpleMessage(
            "Non hai nulla di archiviato."),
        "youHaveSuccessfullyFreedUp": m88,
        "yourAccountHasBeenDeleted": MessageLookupByLibrary.simpleMessage(
            "Il tuo account è stato eliminato"),
        "yourMap": MessageLookupByLibrary.simpleMessage("La tua mappa"),
        "yourPlanWasSuccessfullyDowngraded":
            MessageLookupByLibrary.simpleMessage(
                "Il tuo piano è stato aggiornato con successo"),
        "yourPlanWasSuccessfullyUpgraded": MessageLookupByLibrary.simpleMessage(
            "Il tuo piano è stato aggiornato con successo"),
        "yourPurchaseWasSuccessful":
            MessageLookupByLibrary.simpleMessage("Acquisto andato a buon fine"),
        "yourStorageDetailsCouldNotBeFetched":
            MessageLookupByLibrary.simpleMessage(
                "Impossibile recuperare i dettagli di archiviazione"),
        "yourSubscriptionHasExpired": MessageLookupByLibrary.simpleMessage(
            "Il tuo abbonamento è scaduto"),
        "yourSubscriptionWasUpdatedSuccessfully":
            MessageLookupByLibrary.simpleMessage(
                "Il tuo abbonamento è stato modificato correttamente"),
        "yourVerificationCodeHasExpired": MessageLookupByLibrary.simpleMessage(
            "Il tuo codice di verifica è scaduto"),
        "youveNoDuplicateFilesThatCanBeCleared":
            MessageLookupByLibrary.simpleMessage(
                "Non hai file duplicati che possono essere cancellati"),
        "youveNoFilesInThisAlbumThatCanBeDeleted":
            MessageLookupByLibrary.simpleMessage(
                "Non hai file in questo album che possono essere eliminati"),
        "zoomOutToSeePhotos": MessageLookupByLibrary.simpleMessage(
            "Zoom indietro per visualizzare le foto")
      };
}
