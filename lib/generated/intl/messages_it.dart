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

  static String m0(count) =>
      "${Intl.plural(count, one: 'Aggiungi elemento', other: 'Aggiungi elementi')}";

  static String m1(emailOrName) => "Aggiunto da ${emailOrName}";

  static String m2(albumName) => "Aggiunto con successo su ${albumName}";

  static String m3(count) =>
      "${Intl.plural(count, zero: 'Nessun partecipante', one: '1 Partecipante', other: '${count} Partecipanti')}";

  static String m4(versionValue) => "Versione: ${versionValue}";

  static String m5(paymentProvider) =>
      "Annulla prima il tuo abbonamento esistente da ${paymentProvider}";

  static String m6(user) =>
      "${user} non sarà più in grado di aggiungere altre foto a questo album\n\nSarà ancora in grado di rimuovere le foto esistenti aggiunte da lui o lei";

  static String m7(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true':
                'Il tuo piano famiglia ha già richiesto ${storageAmountInGb} GB finora',
            'false': 'Hai già richiesto ${storageAmountInGb} GB finora',
            'other': 'Hai già richiesto ${storageAmountInGb} GB finora!',
          })}";

  static String m8(albumName) => "Link collaborativo creato per ${albumName}";

  static String m9(familyAdminEmail) =>
      "Contatta <green>${familyAdminEmail}</green> per gestire il tuo abbonamento";

  static String m10(provider) =>
      "Scrivi all\'indirizzo support@ente.io per gestire il tuo abbonamento ${provider}.";

  static String m62(count) =>
      "${Intl.plural(count, one: 'Elimina ${count} elemento', other: 'Elimina ${count} elementi')}";

  static String m11(currentlyDeleting, totalCount) =>
      "Eliminazione di ${currentlyDeleting} / ${totalCount}";

  static String m12(albumName) =>
      "Questo rimuoverà il link pubblico per accedere a \"${albumName}\".";

  static String m13(supportEmail) =>
      "Per favore invia un\'email a ${supportEmail} dall\'indirizzo email con cui ti sei registrato";

  static String m14(count, storageSaved) =>
      "Hai ripulito ${Intl.plural(count, one: '${count} doppione', other: '${count} doppioni')}, salvando (${storageSaved}!)";

  static String m63(count, formattedSize) =>
      "${count} file, ${formattedSize} l\'uno";

  static String m15(newEmail) => "Email cambiata in ${newEmail}";

  static String m16(email) =>
      "${email} non ha un account su ente.\n\nInvia un invito per condividere foto.";

  static String m17(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 file', other: '${formattedNumber} file')} di quest\'album sono stati salvati in modo sicuro";

  static String m18(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 file', other: '${formattedNumber} file')} di quest\'album sono stati salvati in modo sicuro";

  static String m19(storageAmountInGB) =>
      "${storageAmountInGB} GB ogni volta che qualcuno si iscrive a un piano a pagamento e applica il tuo codice";

  static String m20(freeAmount, storageUnit) =>
      "${freeAmount} ${storageUnit} liberi";

  static String m21(endDate) => "La prova gratuita termina il ${endDate}";

  static String m22(count) =>
      "Puoi ancora accedere a ${Intl.plural(count, one: '', other: 'loro')} su ente finché hai un abbonamento attivo";

  static String m23(sizeInMBorGB) => "Libera ${sizeInMBorGB}";

  static String m24(count, formattedSize) =>
      "${Intl.plural(count, one: 'Può essere cancellata per liberare ${formattedSize}', other: 'Possono essere cancellati per liberare ${formattedSize}')}";

  static String m25(count) =>
      "${Intl.plural(count, one: '${count} elemento', other: '${count} elementi')}";

  static String m26(expiryTime) => "Il link scadrà il ${expiryTime}";

  static String m27(maxValue) =>
      "Se impostato al massimo (${maxValue}), il limite del dispositivo verrà ridotto per consentire picchi temporanei di un numero elevato di visualizzatori.";

  static String m28(count, formattedCount) =>
      "${Intl.plural(count, one: '${formattedCount} ricordo', other: '${formattedCount} ricordi')}";

  static String m29(count) =>
      "${Intl.plural(count, one: 'Sposta elemento', other: 'Sposta elementi')}";

  static String m30(albumName) => "Spostato con successo su ${albumName}";

  static String m31(passwordStrengthValue) =>
      "Sicurezza password: ${passwordStrengthValue}";

  static String m32(providerName) =>
      "Si prega di parlare con il supporto di ${providerName} se ti è stato addebitato qualcosa";

  static String m33(reason) =>
      "Purtroppo il tuo pagamento non è riuscito a causa di ${reason}";

  static String m64(endDate) =>
      "Prova gratuita valida fino al ${endDate}.\nPuoi scegliere un piano a pagamento in seguito.";

  static String m34(toEmail) => "Per favore invia un\'email a ${toEmail}";

  static String m35(toEmail) => "Invia i log a \n${toEmail}";

  static String m36(storeName) => "Valutaci su ${storeName}";

  static String m37(storageInGB) =>
      "3. Ottenete entrambi ${storageInGB} GB* gratis";

  static String m38(userEmail) =>
      "${userEmail} verrà rimosso da questo album condiviso\n\nQualsiasi foto aggiunta dall\'utente verrà rimossa dall\'album";

  static String m39(endDate) => "Si rinnova il ${endDate}";

  static String m40(count) => "${count} selezionati";

  static String m41(count, yourCount) =>
      "${count} selezionato (${yourCount} tuoi)";

  static String m42(verificationID) =>
      "Ecco il mio ID di verifica: ${verificationID} per ente.io.";

  static String m43(verificationID) =>
      "Hey, puoi confermare che questo è il tuo ID di verifica: ${verificationID} su ente.io";

  static String m44(referralCode, referralStorageInGB) =>
      "ente referral code: ${referralCode} \n\nApplicalo in Impostazioni → Generale → Referral per ottenere ${referralStorageInGB} GB gratis dopo la registrazione di un piano a pagamento\n\nhttps://ente.io";

  static String m45(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Condividi con persone specifiche', one: 'Condividi con una persona', other: 'Condividi con ${numberOfPeople} persone')}";

  static String m46(emailIDs) => "Condiviso con ${emailIDs}";

  static String m47(fileType) =>
      "Questo ${fileType} verrà eliminato dal tuo dispositivo.";

  static String m48(fileType) =>
      "Questo ${fileType} è sia su ente che sul tuo dispositivo.";

  static String m49(fileType) => "Questo ${fileType} verrà eliminato su ente.";

  static String m50(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m51(
          usedAmount, usedStorageUnit, totalAmount, totalStorageUnit) =>
      "${usedAmount} ${usedStorageUnit} di ${totalAmount} ${totalStorageUnit} utilizzati";

  static String m52(id) =>
      "Il tuo ${id} è già collegato ad un altro account ente.\nSe desideri utilizzare il tuo ${id} con questo account, contatta il nostro supporto\'\'";

  static String m53(endDate) => "L\'abbonamento verrà cancellato il ${endDate}";

  static String m54(completed, total) =>
      "${completed}/${total} ricordi conservati";

  static String m55(storageAmountInGB) =>
      "Anche loro riceveranno ${storageAmountInGB} GB";

  static String m56(email) => "Questo è l\'ID di verifica di ${email}";

  static String m57(count) =>
      "${Intl.plural(count, zero: '', one: '1 giorno', other: '${count} giorni')}";

  static String m58(email) => "Verifica ${email}";

  static String m59(email) =>
      "Abbiamo inviato una mail a <green>${email}</green>";

  static String m60(count) =>
      "${Intl.plural(count, one: '${count} anno fa', other: '${count} anni fa')}";

  static String m61(storageSaved) =>
      "Hai liberato con successo ${storageSaved}!";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable": MessageLookupByLibrary.simpleMessage(
            "Una nuova versione di ente è disponibile."),
        "about": MessageLookupByLibrary.simpleMessage("Info"),
        "account": MessageLookupByLibrary.simpleMessage("Account"),
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Bentornato!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Comprendo che se perdo la password potrei perdere l\'accesso ai miei dati poiché sono <underline>criptati end-to-end</underline>."),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Sessioni attive"),
        "addANewEmail":
            MessageLookupByLibrary.simpleMessage("Aggiungi una nuova email"),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Aggiungi collaboratore"),
        "addItem": m0,
        "addLocation": MessageLookupByLibrary.simpleMessage("Aggiungi luogo"),
        "addLocationButton": MessageLookupByLibrary.simpleMessage("Aggiungi"),
        "addMore": MessageLookupByLibrary.simpleMessage("Aggiungi altri"),
        "addToAlbum":
            MessageLookupByLibrary.simpleMessage("Aggiungi all\'album"),
        "addToEnte": MessageLookupByLibrary.simpleMessage("Aggiungi su ente"),
        "addViewer":
            MessageLookupByLibrary.simpleMessage("Aggiungi in sola lettura"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Aggiunto come"),
        "addedBy": m1,
        "addedSuccessfullyTo": m2,
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
        "albumParticipantsCount": m3,
        "albumTitle": MessageLookupByLibrary.simpleMessage("Titolo album"),
        "albumUpdated":
            MessageLookupByLibrary.simpleMessage("Album aggiornato"),
        "albums": MessageLookupByLibrary.simpleMessage("Album"),
        "allClear": MessageLookupByLibrary.simpleMessage("✨ Tutto pulito"),
        "allMemoriesPreserved":
            MessageLookupByLibrary.simpleMessage("Tutti i ricordi conservati"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Permetti anche alle persone con il link di aggiungere foto all\'album condiviso."),
        "allowAddingPhotos": MessageLookupByLibrary.simpleMessage(
            "Consenti l\'aggiunta di foto"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("Consenti download"),
        "allowPeopleToAddPhotos": MessageLookupByLibrary.simpleMessage(
            "Permetti alle persone di aggiungere foto"),
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
        "appVersion": m4,
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
        "askCancelReason": MessageLookupByLibrary.simpleMessage(
            "Il tuo abbonamento è stato annullato. Vuoi condividere il motivo?"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "Qual è il motivo principale per cui stai cancellando il tuo account?"),
        "askYourLovedOnesToShare": MessageLookupByLibrary.simpleMessage(
            "Invita amici, amiche e parenti su ente"),
        "atAFalloutShelter":
            MessageLookupByLibrary.simpleMessage("in un rifugio antiatomico"),
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
        "available": MessageLookupByLibrary.simpleMessage("Disponibile"),
        "backedUpFolders":
            MessageLookupByLibrary.simpleMessage("Cartelle salvate"),
        "backup": MessageLookupByLibrary.simpleMessage("Backup"),
        "backupFailed": MessageLookupByLibrary.simpleMessage("Backup fallito"),
        "backupOverMobileData":
            MessageLookupByLibrary.simpleMessage("Backup su dati mobili"),
        "backupSettings":
            MessageLookupByLibrary.simpleMessage("Impostazioni backup"),
        "backupVideos":
            MessageLookupByLibrary.simpleMessage("Backup dei video"),
        "blog": MessageLookupByLibrary.simpleMessage("Blog"),
        "cachedData": MessageLookupByLibrary.simpleMessage("Dati nella cache"),
        "calculating": MessageLookupByLibrary.simpleMessage("Calcolando..."),
        "canNotUploadToAlbumsOwnedByOthers":
            MessageLookupByLibrary.simpleMessage(
                "Impossibile caricare su album di proprietà altrui"),
        "canOnlyCreateLinkForFilesOwnedByYou":
            MessageLookupByLibrary.simpleMessage(
                "Puoi creare solo link per i file di tua proprietà"),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "Puoi rimuovere solo i file di tua proprietà"),
        "cancel": MessageLookupByLibrary.simpleMessage("Annulla"),
        "cancelOtherSubscription": m5,
        "cancelSubscription":
            MessageLookupByLibrary.simpleMessage("Annulla abbonamento"),
        "cannotAddMorePhotosAfterBecomingViewer": m6,
        "centerPoint": MessageLookupByLibrary.simpleMessage("Punto centrale"),
        "changeEmail": MessageLookupByLibrary.simpleMessage("Modifica email"),
        "changePassword":
            MessageLookupByLibrary.simpleMessage("Cambia password"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Modifica password"),
        "changePermissions":
            MessageLookupByLibrary.simpleMessage("Cambio i permessi?"),
        "checkForUpdates":
            MessageLookupByLibrary.simpleMessage("Controlla aggiornamenti"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Per favore, controlla la tua casella di posta (e lo spam) per completare la verifica"),
        "checking":
            MessageLookupByLibrary.simpleMessage("Controllo in corso..."),
        "claimFreeStorage":
            MessageLookupByLibrary.simpleMessage("Richiedi spazio gratuito"),
        "claimMore": MessageLookupByLibrary.simpleMessage("Richiedine di più!"),
        "claimed": MessageLookupByLibrary.simpleMessage("Riscattato"),
        "claimedStorageSoFar": m7,
        "clearCaches": MessageLookupByLibrary.simpleMessage("Svuota cache"),
        "click": MessageLookupByLibrary.simpleMessage("• Clic"),
        "clickOnTheOverflowMenu":
            MessageLookupByLibrary.simpleMessage("• Fai clic sul menu"),
        "close": MessageLookupByLibrary.simpleMessage("Chiudi"),
        "clubByCaptureTime":
            MessageLookupByLibrary.simpleMessage("Club per tempo di cattura"),
        "clubByFileName":
            MessageLookupByLibrary.simpleMessage("Unisci per nome file"),
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("Codice applicato"),
        "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Codice copiato negli appunti"),
        "codeUsedByYou":
            MessageLookupByLibrary.simpleMessage("Codice utilizzato da te"),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Crea un link per consentire alle persone di aggiungere e visualizzare foto nel tuo album condiviso senza bisogno di un\'applicazione o di un account ente. Ottimo per raccogliere foto di un evento."),
        "collaborativeLink":
            MessageLookupByLibrary.simpleMessage("Link collaborativo"),
        "collaborativeLinkCreatedFor": m8,
        "collaborator": MessageLookupByLibrary.simpleMessage("Collaboratore"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "I collaboratori possono aggiungere foto e video all\'album condiviso."),
        "collageLayout": MessageLookupByLibrary.simpleMessage("Disposizione"),
        "collageSaved": MessageLookupByLibrary.simpleMessage(
            "Collage salvato nella galleria"),
        "collectEventPhotos": MessageLookupByLibrary.simpleMessage(
            "Raccogli le foto di un evento"),
        "collectPhotos":
            MessageLookupByLibrary.simpleMessage("Raccogli le foto"),
        "color": MessageLookupByLibrary.simpleMessage("Colore"),
        "confirm": MessageLookupByLibrary.simpleMessage("Conferma"),
        "confirm2FADisable": MessageLookupByLibrary.simpleMessage(
            "Sei sicuro di voler disattivare l\'autenticazione a due fattori?"),
        "confirmAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Conferma eliminazione account"),
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Sì, voglio eliminare definitivamente questo account e tutti i suoi dati."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Conferma password"),
        "confirmPlanChange": MessageLookupByLibrary.simpleMessage(
            "Conferma le modifiche al piano"),
        "confirmRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Conferma chiave di recupero"),
        "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Conferma la tua chiave di recupero"),
        "contactFamilyAdmin": m9,
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("Contatta il supporto"),
        "contactToManageSubscription": m10,
        "continueLabel": MessageLookupByLibrary.simpleMessage("Continua"),
        "continueOnFreeTrial":
            MessageLookupByLibrary.simpleMessage("Continua la prova gratuita"),
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
        "createAccount": MessageLookupByLibrary.simpleMessage("Crea account"),
        "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
            "Premi a lungo per selezionare le foto e fai clic su + per creare un album"),
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
        "currentUsageIs": MessageLookupByLibrary.simpleMessage(
            "Spazio attualmente utilizzato "),
        "custom": MessageLookupByLibrary.simpleMessage("Personalizza"),
        "darkTheme": MessageLookupByLibrary.simpleMessage("Scuro"),
        "dayToday": MessageLookupByLibrary.simpleMessage("Oggi"),
        "dayYesterday": MessageLookupByLibrary.simpleMessage("Ieri"),
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
            "Stai per eliminare definitivamente il tuo account e tutti i suoi dati.\nQuesta azione è irreversibile."),
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
            MessageLookupByLibrary.simpleMessage("Elimina da ente"),
        "deleteItemCount": m62,
        "deleteLocation":
            MessageLookupByLibrary.simpleMessage("Elimina posizione"),
        "deletePhotos": MessageLookupByLibrary.simpleMessage("Elimina foto"),
        "deleteProgress": m11,
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
        "devAccountChanged": MessageLookupByLibrary.simpleMessage(
            "L\'account sviluppatore che utilizziamo per pubblicare ente su App Store è cambiato. Per questo motivo dovrai effettuare nuovamente il login.\n\nCi dispiace per il disagio, ma era inevitabile."),
        "deviceFilesAutoUploading": MessageLookupByLibrary.simpleMessage(
            "I file aggiunti in questa cartella del dispositivo verranno automaticamente caricati su ente."),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
            "Disabilita il blocco schermo del dispositivo quando ente è in primo piano e c\'è un backup in corso. Questo normalmente non è necessario, ma può aiutare durante grossi caricamenti e le importazioni iniziali di grandi librerie si completano più velocemente."),
        "didYouKnow": MessageLookupByLibrary.simpleMessage("Lo sapevi che?"),
        "disableAutoLock": MessageLookupByLibrary.simpleMessage(
            "Disabilita blocco automatico"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "I visualizzatori possono scattare screenshot o salvare una copia delle foto utilizzando strumenti esterni"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Nota bene"),
        "disableLinkMessage": m12,
        "disableTwofactor": MessageLookupByLibrary.simpleMessage(
            "Disabilita autenticazione a due fattori"),
        "disablingTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Disattivazione autenticazione a due fattori..."),
        "discord": MessageLookupByLibrary.simpleMessage("Discord"),
        "dismiss": MessageLookupByLibrary.simpleMessage("Ignora"),
        "distanceInKMUnit": MessageLookupByLibrary.simpleMessage("km"),
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
        "dropSupportEmail": m13,
        "duplicateFileCountWithStorageSaved": m14,
        "duplicateItemsGroup": m63,
        "edit": MessageLookupByLibrary.simpleMessage("Modifica"),
        "editLocationTagTitle":
            MessageLookupByLibrary.simpleMessage("Modifica luogo"),
        "editsSaved": MessageLookupByLibrary.simpleMessage("Modifiche salvate"),
        "eligible": MessageLookupByLibrary.simpleMessage("idoneo"),
        "email": MessageLookupByLibrary.simpleMessage("Email"),
        "emailChangedTo": m15,
        "emailNoEnteAccount": m16,
        "emailYourLogs": MessageLookupByLibrary.simpleMessage(
            "Invia una mail con i tuoi log"),
        "empty": MessageLookupByLibrary.simpleMessage("Vuoto"),
        "emptyTrash":
            MessageLookupByLibrary.simpleMessage("Vuoi svuotare il cestino?"),
        "enableMaps": MessageLookupByLibrary.simpleMessage("Abilita le Mappe"),
        "enableMapsDesc": MessageLookupByLibrary.simpleMessage(
            "Questo mostrerà le tue foto su una mappa del mondo.\n\nQuesta mappa è ospitata da Open Street Map e le posizioni esatte delle tue foto non sono mai condivise.\n\nPuoi disabilitare questa funzionalità in qualsiasi momento, dalle Impostazioni."),
        "encryptingBackup":
            MessageLookupByLibrary.simpleMessage("Crittografando il backup..."),
        "encryption": MessageLookupByLibrary.simpleMessage("Crittografia"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Chiavi di crittografia"),
        "endtoendEncryptedByDefault":
            MessageLookupByLibrary.simpleMessage("Crittografia end-to-end"),
        "enteCanEncryptAndPreserveFilesOnlyIfYouGrant":
            MessageLookupByLibrary.simpleMessage(
                "ente può criptare e preservare i file solo se concedi l\'accesso alle foto e ai video"),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
            "ente <i>necessita del permesso per</i> preservare le tue foto"),
        "enteSubscriptionPitch": MessageLookupByLibrary.simpleMessage(
            "ente conserva i tuoi ricordi, in modo che siano sempre a disposizione, anche se perdi il dispositivo."),
        "enteSubscriptionShareWithFamily": MessageLookupByLibrary.simpleMessage(
            "Aggiungi la tua famiglia al tuo piano."),
        "enterAlbumName": MessageLookupByLibrary.simpleMessage(
            "Inserisci il nome dell\'album"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Inserisci codice"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
            "Inserisci il codice fornito dal tuo amico per richiedere spazio gratuito per entrambi"),
        "enterEmail": MessageLookupByLibrary.simpleMessage("Inserisci email"),
        "enterFileName": MessageLookupByLibrary.simpleMessage(
            "Inserisci un nome per il file"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Inserisci una nuova password per criptare i tuoi dati"),
        "enterPassword":
            MessageLookupByLibrary.simpleMessage("Inserisci password"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Inserisci una password per criptare i tuoi dati"),
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
        "failedToApplyCode": MessageLookupByLibrary.simpleMessage(
            "Impossibile applicare il codice"),
        "failedToCancel":
            MessageLookupByLibrary.simpleMessage("Impossibile annullare"),
        "failedToDownloadVideo":
            MessageLookupByLibrary.simpleMessage("Failed to download video"),
        "failedToFetchOriginalForEdit": MessageLookupByLibrary.simpleMessage(
            "Impossibile recuperare l\'originale per la modifica"),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "Impossibile recuperare i dettagli. Per favore, riprova più tardi."),
        "failedToLoadAlbums": MessageLookupByLibrary.simpleMessage(
            "Impossibile caricare gli album"),
        "failedToRenew":
            MessageLookupByLibrary.simpleMessage("Rinnovo fallito"),
        "failedToVerifyPaymentStatus": MessageLookupByLibrary.simpleMessage(
            "Impossibile verificare lo stato del pagamento"),
        "familyPlanOverview": MessageLookupByLibrary.simpleMessage(
            "Aggiungi 5 membri della famiglia al tuo piano esistente senza pagare extra.\n\nOgni membro ottiene il proprio spazio privato e non può vedere i file dell\'altro a meno che non siano condivisi.\n\nI piani familiari sono disponibili per i clienti che hanno un abbonamento ente a pagamento.\n\nIscriviti ora per iniziare!"),
        "familyPlanPortalTitle":
            MessageLookupByLibrary.simpleMessage("Famiglia"),
        "familyPlans": MessageLookupByLibrary.simpleMessage("Piano famiglia"),
        "faq": MessageLookupByLibrary.simpleMessage("FAQ"),
        "faqs": MessageLookupByLibrary.simpleMessage("FAQ"),
        "favorite": MessageLookupByLibrary.simpleMessage("Preferito"),
        "feedback": MessageLookupByLibrary.simpleMessage("Suggerimenti"),
        "fileFailedToSaveToGallery": MessageLookupByLibrary.simpleMessage(
            "Impossibile salvare il file nella galleria"),
        "fileInfoAddDescHint":
            MessageLookupByLibrary.simpleMessage("Aggiungi descrizione..."),
        "fileSavedToGallery":
            MessageLookupByLibrary.simpleMessage("File salvato nella galleria"),
        "filesBackedUpFromDevice": m17,
        "filesBackedUpInAlbum": m18,
        "filesDeleted": MessageLookupByLibrary.simpleMessage("File eliminati"),
        "flip": MessageLookupByLibrary.simpleMessage("Capovolgi"),
        "forYourMemories":
            MessageLookupByLibrary.simpleMessage("per i tuoi ricordi"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Password dimenticata"),
        "freeStorageClaimed":
            MessageLookupByLibrary.simpleMessage("Spazio gratuito richiesto"),
        "freeStorageOnReferralSuccess": m19,
        "freeStorageSpace": m20,
        "freeStorageUsable":
            MessageLookupByLibrary.simpleMessage("Spazio libero utilizzabile"),
        "freeTrial": MessageLookupByLibrary.simpleMessage("Prova gratuita"),
        "freeTrialValidTill": m21,
        "freeUpAccessPostDelete": m22,
        "freeUpAmount": m23,
        "freeUpDeviceSpace":
            MessageLookupByLibrary.simpleMessage("Libera spazio"),
        "freeUpSpace": MessageLookupByLibrary.simpleMessage("Libera spazio"),
        "freeUpSpaceSaving": m24,
        "galleryMemoryLimitInfo": MessageLookupByLibrary.simpleMessage(
            "Fino a 1000 ricordi mostrati nella galleria"),
        "general": MessageLookupByLibrary.simpleMessage("Generali"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Generazione delle chiavi di crittografia..."),
        "goToSettings":
            MessageLookupByLibrary.simpleMessage("Vai alle impostazioni"),
        "googlePlayId": MessageLookupByLibrary.simpleMessage("Google Play ID"),
        "grantPermission":
            MessageLookupByLibrary.simpleMessage("Concedi il permesso"),
        "groupNearbyPhotos": MessageLookupByLibrary.simpleMessage(
            "Raggruppa foto nelle vicinanze"),
        "hidden": MessageLookupByLibrary.simpleMessage("Nascosti"),
        "hide": MessageLookupByLibrary.simpleMessage("Nascondi"),
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
        "ignoredFolderUploadReason": MessageLookupByLibrary.simpleMessage(
            "Alcuni file in questo album vengono ignorati dal caricamento perché erano stati precedentemente cancellati da ente."),
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
        "insecureDevice":
            MessageLookupByLibrary.simpleMessage("Dispositivo non sicuro"),
        "installManually":
            MessageLookupByLibrary.simpleMessage("Installa manualmente"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("Indirizzo email non valido"),
        "invalidKey": MessageLookupByLibrary.simpleMessage("Chiave non valida"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "La chiave di recupero che hai inserito non è valida. Assicurati che contenga 24 parole e controlla l\'ortografia di ciascuna parola.\n\nSe hai inserito un vecchio codice di recupero, assicurati che sia lungo 64 caratteri e controlla ciascuno di essi."),
        "invite": MessageLookupByLibrary.simpleMessage("Invita"),
        "inviteToEnte": MessageLookupByLibrary.simpleMessage("Invita su ente"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Invita i tuoi amici"),
        "inviteYourFriendsToEnte":
            MessageLookupByLibrary.simpleMessage("Invite your friends to ente"),
        "itLooksLikeSomethingWentWrongPleaseRetryAfterSome":
            MessageLookupByLibrary.simpleMessage(
                "Sembra che qualcosa sia andato storto. Riprova tra un po\'. Se l\'errore persiste, contatta il nostro team di supporto."),
        "itemCount": m25,
        "itemsShowTheNumberOfDaysRemainingBeforePermanentDeletion":
            MessageLookupByLibrary.simpleMessage(
                "Gli elementi mostrano il numero di giorni rimanenti prima della cancellazione permanente"),
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "Gli elementi selezionati saranno rimossi da questo album"),
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
        "light": MessageLookupByLibrary.simpleMessage("Chiaro"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("Chiaro"),
        "linkCopiedToClipboard":
            MessageLookupByLibrary.simpleMessage("Link copiato negli appunti"),
        "linkDeviceLimit":
            MessageLookupByLibrary.simpleMessage("Limite dei dispositivi"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Attivato"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Scaduto"),
        "linkExpiresOn": m26,
        "linkExpiry": MessageLookupByLibrary.simpleMessage("Scadenza del link"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("Il link è scaduto"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Mai"),
        "loadMessage1": MessageLookupByLibrary.simpleMessage(
            "Puoi condividere il tuo abbonamento con la tua famiglia"),
        "loadMessage2": MessageLookupByLibrary.simpleMessage(
            "Fino ad oggi abbiamo conservato oltre 10 milioni di ricordi"),
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
        "localGallery": MessageLookupByLibrary.simpleMessage("Galleria locale"),
        "location": MessageLookupByLibrary.simpleMessage("Luogo"),
        "locationName":
            MessageLookupByLibrary.simpleMessage("Nome della località"),
        "locationTagFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "Un tag di localizzazione raggruppa tutte le foto scattate entro il raggio di una foto"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Blocca"),
        "lockScreenEnablePreSteps": MessageLookupByLibrary.simpleMessage(
            "Per abilitare la schermata di blocco, configura il codice di accesso del dispositivo o il blocco schermo nelle impostazioni di sistema."),
        "lockscreen":
            MessageLookupByLibrary.simpleMessage("Schermata di blocco"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Accedi"),
        "loggingOut": MessageLookupByLibrary.simpleMessage("Disconnessione..."),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "Cliccando sul pulsante Accedi, accetti i <u-terms>termini di servizio</u-terms> e la <u-policy>politica sulla privacy</u-policy>"),
        "logout": MessageLookupByLibrary.simpleMessage("Disconnetti"),
        "logsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Invia i log per aiutarci a risolvere il tuo problema. Si prega di notare che i nomi dei file saranno inclusi per aiutare a tenere traccia di problemi con file specifici."),
        "longpressOnAnItemToViewInFullscreen":
            MessageLookupByLibrary.simpleMessage(
                "Premi a lungo su un elemento per visualizzarlo a schermo intero"),
        "lostDevice":
            MessageLookupByLibrary.simpleMessage("Dispositivo perso?"),
        "manage": MessageLookupByLibrary.simpleMessage("Gestisci"),
        "manageDeviceStorage": MessageLookupByLibrary.simpleMessage(
            "Gestisci memoria dispositivo"),
        "manageFamily":
            MessageLookupByLibrary.simpleMessage("Gestisci Piano famiglia"),
        "manageLink": MessageLookupByLibrary.simpleMessage("Gestisci link"),
        "manageParticipants": MessageLookupByLibrary.simpleMessage("Gestisci"),
        "manageSubscription":
            MessageLookupByLibrary.simpleMessage("Gestisci abbonamento"),
        "map": MessageLookupByLibrary.simpleMessage("Mappa"),
        "maps": MessageLookupByLibrary.simpleMessage("Mappe"),
        "mastodon": MessageLookupByLibrary.simpleMessage("Mastodon"),
        "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
        "maxDeviceLimitSpikeHandling": m27,
        "memoryCount": m28,
        "merchandise": MessageLookupByLibrary.simpleMessage("Merchandise"),
        "mobileWebDesktop":
            MessageLookupByLibrary.simpleMessage("Mobile, Web, Desktop"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Mediocre"),
        "monthly": MessageLookupByLibrary.simpleMessage("Mensile"),
        "moveItem": m29,
        "moveToAlbum":
            MessageLookupByLibrary.simpleMessage("Sposta nell\'album"),
        "movedSuccessfullyTo": m30,
        "movedToTrash":
            MessageLookupByLibrary.simpleMessage("Spostato nel cestino"),
        "movingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Spostamento dei file nell\'album..."),
        "name": MessageLookupByLibrary.simpleMessage("Nome"),
        "never": MessageLookupByLibrary.simpleMessage("Mai"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Nuovo album"),
        "newToEnte": MessageLookupByLibrary.simpleMessage("Nuovo utente"),
        "newest": MessageLookupByLibrary.simpleMessage("Più recenti"),
        "no": MessageLookupByLibrary.simpleMessage("No"),
        "noAlbumsSharedByYouYet":
            MessageLookupByLibrary.simpleMessage("No albums shared by you yet"),
        "noDeviceThatCanBeDeleted": MessageLookupByLibrary.simpleMessage(
            "Non hai file su questo dispositivo che possono essere eliminati"),
        "noDuplicates":
            MessageLookupByLibrary.simpleMessage("✨ Nessun doppione"),
        "noExifData": MessageLookupByLibrary.simpleMessage("Nessun dato EXIF"),
        "noHiddenPhotosOrVideos": MessageLookupByLibrary.simpleMessage(
            "Nessuna foto o video nascosti"),
        "noPhotosAreBeingBackedUpRightNow":
            MessageLookupByLibrary.simpleMessage(
                "Il backup delle foto attualmente non viene eseguito"),
        "noRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Nessuna chiave di recupero?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "A causa della natura del nostro protocollo di crittografia end-to-end, i tuoi dati non possono essere decifrati senza password o chiave di ripristino"),
        "noResults": MessageLookupByLibrary.simpleMessage("Nessun risultato"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("Nessun risultato trovato"),
        "nothingSharedWithYouYet":
            MessageLookupByLibrary.simpleMessage("Nothing shared with you yet"),
        "nothingToSeeHere":
            MessageLookupByLibrary.simpleMessage("Nulla da vedere qui! 👀"),
        "notifications": MessageLookupByLibrary.simpleMessage("Notifiche"),
        "ok": MessageLookupByLibrary.simpleMessage("Ok"),
        "onDevice": MessageLookupByLibrary.simpleMessage("Sul dispositivo"),
        "onEnte": MessageLookupByLibrary.simpleMessage(
            "Su <branding>ente</branding>"),
        "oops": MessageLookupByLibrary.simpleMessage("Oops"),
        "oopsCouldNotSaveEdits": MessageLookupByLibrary.simpleMessage(
            "Ops, impossibile salvare le modifiche"),
        "oopsSomethingWentWrong": MessageLookupByLibrary.simpleMessage(
            "Oops! Qualcosa è andato storto"),
        "openTheItem":
            MessageLookupByLibrary.simpleMessage("• Apri la foto o il video"),
        "openstreetmapContributors": MessageLookupByLibrary.simpleMessage(
            "Collaboratori di OpenStreetMap"),
        "optionalAsShortAsYouLike": MessageLookupByLibrary.simpleMessage(
            "Facoltativo, breve quanto vuoi..."),
        "orPickAnExistingOne": MessageLookupByLibrary.simpleMessage(
            "Oppure scegline una esistente"),
        "password": MessageLookupByLibrary.simpleMessage("Password"),
        "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
            "Password modificata con successo"),
        "passwordLock":
            MessageLookupByLibrary.simpleMessage("Blocco con password"),
        "passwordStrength": m31,
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Noi non memorizziamo la tua password, quindi se te la dimentichi, <underline>non possiamo decriptare i tuoi dati</underline>"),
        "paymentDetails":
            MessageLookupByLibrary.simpleMessage("Dettagli di Pagamento"),
        "paymentFailed":
            MessageLookupByLibrary.simpleMessage("Pagamento non riuscito"),
        "paymentFailedTalkToProvider": m32,
        "paymentFailedWithReason": m33,
        "pendingSync":
            MessageLookupByLibrary.simpleMessage("Sincronizzazione in sospeso"),
        "peopleUsingYourCode": MessageLookupByLibrary.simpleMessage(
            "Persone che hanno usato il tuo codice"),
        "permDeleteWarning": MessageLookupByLibrary.simpleMessage(
            "Tutti gli elementi nel cestino verranno eliminati definitivamente\n\nQuesta azione non può essere annullata"),
        "permanentlyDelete":
            MessageLookupByLibrary.simpleMessage("Elimina definitivamente"),
        "permanentlyDeleteFromDevice": MessageLookupByLibrary.simpleMessage(
            "Eliminare definitivamente dal dispositivo?"),
        "photoGridSize":
            MessageLookupByLibrary.simpleMessage("Dimensione griglia foto"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("foto"),
        "photosAddedByYouWillBeRemovedFromTheAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Le foto aggiunte da te verranno rimosse dall\'album"),
        "pickCenterPoint": MessageLookupByLibrary.simpleMessage(
            "Selezionare il punto centrale"),
        "pinAlbum": MessageLookupByLibrary.simpleMessage("Fissa l\'album"),
        "playStoreFreeTrialValidTill": m64,
        "playstoreSubscription":
            MessageLookupByLibrary.simpleMessage("Abbonamento su PlayStore"),
        "pleaseContactSupportAndWeWillBeHappyToHelp":
            MessageLookupByLibrary.simpleMessage(
                "Contatta support@ente.io e saremo felici di aiutarti!"),
        "pleaseContactSupportIfTheProblemPersists":
            MessageLookupByLibrary.simpleMessage(
                "Riprova. Se il problema persiste, ti invitiamo a contattare l\'assistenza"),
        "pleaseEmailUsAt": m34,
        "pleaseGrantPermissions":
            MessageLookupByLibrary.simpleMessage("Concedi i permessi"),
        "pleaseLoginAgain": MessageLookupByLibrary.simpleMessage(
            "Effettua nuovamente l\'accesso"),
        "pleaseSendTheLogsTo": m35,
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
        "privacy": MessageLookupByLibrary.simpleMessage("Privacy"),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Privacy Policy"),
        "privateBackups":
            MessageLookupByLibrary.simpleMessage("Backup privato"),
        "privateSharing":
            MessageLookupByLibrary.simpleMessage("Condivisioni private"),
        "publicLinkCreated":
            MessageLookupByLibrary.simpleMessage("Link pubblico creato"),
        "publicLinkEnabled":
            MessageLookupByLibrary.simpleMessage("Link pubblico abilitato"),
        "radius": MessageLookupByLibrary.simpleMessage("Raggio"),
        "raiseTicket": MessageLookupByLibrary.simpleMessage("Invia ticket"),
        "rateTheApp": MessageLookupByLibrary.simpleMessage("Valuta l\'app"),
        "rateUs": MessageLookupByLibrary.simpleMessage("Lascia una recensione"),
        "rateUsOnStore": m36,
        "recover": MessageLookupByLibrary.simpleMessage("Recupera"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("Recupera account"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Recupera"),
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
            "La tua chiave di recupero è l\'unico modo per recuperare le foto se ti dimentichi la password. Puoi trovare la tua chiave di recupero in Impostazioni > Account.\n\nInserisci qui la tua chiave di recupero per verificare di averla salvata correttamente."),
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("Recupero riuscito!"),
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "Il dispositivo attuale non è abbastanza potente per verificare la tua password, ma la possiamo rigenerare in un modo che funzioni su tutti i dispositivi.\n\nEffettua il login utilizzando la tua chiave di recupero e rigenera la tua password (puoi utilizzare nuovamente la stessa se vuoi)."),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Reimposta password"),
        "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
        "referFriendsAnd2xYourPlan": MessageLookupByLibrary.simpleMessage(
            "Invita un amico e raddoppia il tuo spazio"),
        "referralStep1": MessageLookupByLibrary.simpleMessage(
            "1. Condividi questo codice con i tuoi amici"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "2. Si iscrivono per un piano a pagamento"),
        "referralStep3": m37,
        "referrals": MessageLookupByLibrary.simpleMessage("Invita un Amico"),
        "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
            "I referral code sono attualmente in pausa"),
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
        "removeFromAlbum":
            MessageLookupByLibrary.simpleMessage("Rimuovi dall\'album"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("Rimuovi dall\'album?"),
        "removeFromFavorite":
            MessageLookupByLibrary.simpleMessage("Rimuovi dai preferiti"),
        "removeLink": MessageLookupByLibrary.simpleMessage("Elimina link"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Rimuovi partecipante"),
        "removeParticipantBody": m38,
        "removePublicLink":
            MessageLookupByLibrary.simpleMessage("Rimuovi link pubblico"),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
            "Alcuni degli elementi che stai rimuovendo sono stati aggiunti da altre persone e ne perderai l\'accesso"),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Rimuovi?"),
        "removingFromFavorites":
            MessageLookupByLibrary.simpleMessage("Rimosso dai preferiti..."),
        "rename": MessageLookupByLibrary.simpleMessage("Rinomina"),
        "renameAlbum": MessageLookupByLibrary.simpleMessage("Rinomina album"),
        "renameFile": MessageLookupByLibrary.simpleMessage("Rinomina file"),
        "renewSubscription":
            MessageLookupByLibrary.simpleMessage("Rinnova abbonamento"),
        "renewsOn": m39,
        "reportABug": MessageLookupByLibrary.simpleMessage("Segnala un bug"),
        "reportBug": MessageLookupByLibrary.simpleMessage("Segnala un bug"),
        "resendEmail": MessageLookupByLibrary.simpleMessage("Rinvia email"),
        "resetIgnoredFiles":
            MessageLookupByLibrary.simpleMessage("Ripristina i file ignorati"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Reimposta password"),
        "restore": MessageLookupByLibrary.simpleMessage("Ripristina"),
        "restoreToAlbum":
            MessageLookupByLibrary.simpleMessage("Ripristina l\'album"),
        "restoringFiles":
            MessageLookupByLibrary.simpleMessage("Ripristinando file..."),
        "retry": MessageLookupByLibrary.simpleMessage("Riprova"),
        "reviewDeduplicateItems": MessageLookupByLibrary.simpleMessage(
            "Controlla ed elimina gli elementi che credi siano dei doppioni."),
        "rotateLeft": MessageLookupByLibrary.simpleMessage("Ruota a sinistra"),
        "rotateRight": MessageLookupByLibrary.simpleMessage("Ruota a destra"),
        "safelyStored":
            MessageLookupByLibrary.simpleMessage("Salvati in sicurezza"),
        "save": MessageLookupByLibrary.simpleMessage("Salva"),
        "saveCollage": MessageLookupByLibrary.simpleMessage("Salva il collage"),
        "saveCopy": MessageLookupByLibrary.simpleMessage("Salva una copia"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Salva chiave"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Salva la tua chiave di recupero se non l\'hai ancora fatto"),
        "saving": MessageLookupByLibrary.simpleMessage("Salvataggio..."),
        "scanCode": MessageLookupByLibrary.simpleMessage("Scansiona codice"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Scansione questo codice QR\ncon la tua app di autenticazione"),
        "searchByAlbumNameHint":
            MessageLookupByLibrary.simpleMessage("Nome album"),
        "searchByExamples": MessageLookupByLibrary.simpleMessage(
            "• Nomi degli album (es. \"Camera\")\n• Tipi di file (es. \"Video\", \".gif\")\n• Anni e mesi (e.. \"2022\", \"gennaio\")\n• Vacanze (ad es. \"Natale\")\n• Descrizioni delle foto (ad es. “#mare”)"),
        "searchHintText": MessageLookupByLibrary.simpleMessage(
            "Album, mesi, giorni, anni, ..."),
        "security": MessageLookupByLibrary.simpleMessage("Sicurezza"),
        "selectAlbum": MessageLookupByLibrary.simpleMessage("Seleziona album"),
        "selectAll": MessageLookupByLibrary.simpleMessage("Seleziona tutto"),
        "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
            "Seleziona cartelle per il backup"),
        "selectLanguage":
            MessageLookupByLibrary.simpleMessage("Seleziona una lingua"),
        "selectReason":
            MessageLookupByLibrary.simpleMessage("Seleziona un motivo"),
        "selectYourPlan":
            MessageLookupByLibrary.simpleMessage("Seleziona un piano"),
        "selectedFilesAreNotOnEnte": MessageLookupByLibrary.simpleMessage(
            "I file selezionati non sono su ente"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "Le cartelle selezionate verranno crittografate e salvate su ente"),
        "selectedItemsWillBeDeletedFromAllAlbumsAndMoved":
            MessageLookupByLibrary.simpleMessage(
                "Gli elementi selezionati verranno eliminati da tutti gli album e spostati nel cestino."),
        "selectedPhotos": m40,
        "selectedPhotosWithYours": m41,
        "send": MessageLookupByLibrary.simpleMessage("Invia"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("Invia email"),
        "sendInvite": MessageLookupByLibrary.simpleMessage("Invita"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Invia link"),
        "sessionExpired":
            MessageLookupByLibrary.simpleMessage("Sessione scaduta"),
        "setAPassword":
            MessageLookupByLibrary.simpleMessage("Imposta una password"),
        "setAs": MessageLookupByLibrary.simpleMessage("Imposta come"),
        "setCover": MessageLookupByLibrary.simpleMessage("Imposta copertina"),
        "setLabel": MessageLookupByLibrary.simpleMessage("Imposta"),
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
        "shareMyVerificationID": m42,
        "shareOnlyWithThePeopleYouWant": MessageLookupByLibrary.simpleMessage(
            "Condividi solo con le persone che vuoi"),
        "shareTextConfirmOthersVerificationID": m43,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Scarica ente in modo da poter facilmente condividere foto e video senza perdita di qualità\n\nhttps://ente.io"),
        "shareTextReferralCode": m44,
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
            "Condividi con utenti che non hanno un account ente"),
        "shareWithPeopleSectionTitle": m45,
        "shareYourFirstAlbum": MessageLookupByLibrary.simpleMessage(
            "Condividi il tuo primo album"),
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Crea album condivisi e collaborativi con altri utenti ente, inclusi utenti su piani gratuiti."),
        "sharedByMe": MessageLookupByLibrary.simpleMessage("Condiviso da me"),
        "sharedByYou": MessageLookupByLibrary.simpleMessage("Shared by you"),
        "sharedPhotoNotifications":
            MessageLookupByLibrary.simpleMessage("Nuove foto condivise"),
        "sharedPhotoNotificationsExplanation": MessageLookupByLibrary.simpleMessage(
            "Ricevi notifiche quando qualcuno aggiunge una foto a un album condiviso, di cui fai parte"),
        "sharedWith": m46,
        "sharedWithMe":
            MessageLookupByLibrary.simpleMessage("Condivisi con me"),
        "sharedWithYou":
            MessageLookupByLibrary.simpleMessage("Shared with you"),
        "sharing":
            MessageLookupByLibrary.simpleMessage("Condivisione in corso..."),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "Accetto i <u-terms>termini di servizio</u-terms> e la <u-policy>politica sulla privacy</u-policy>"),
        "singleFileDeleteFromDevice": m47,
        "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
            "Verrà eliminato da tutti gli album."),
        "singleFileInBothLocalAndRemote": m48,
        "singleFileInRemoteOnly": m49,
        "skip": MessageLookupByLibrary.simpleMessage("Salta"),
        "social": MessageLookupByLibrary.simpleMessage("Social"),
        "someItemsAreInBothEnteAndYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Alcuni elementi sono sia su ente che sul tuo dispositivo."),
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
        "sortAlbumsBy": MessageLookupByLibrary.simpleMessage("Ordina per"),
        "sortNewestFirst":
            MessageLookupByLibrary.simpleMessage("Prima le più nuove"),
        "sortOldestFirst":
            MessageLookupByLibrary.simpleMessage("Prima le più vecchie"),
        "sparkleSuccess":
            MessageLookupByLibrary.simpleMessage("✨ Operazione riuscita"),
        "startBackup": MessageLookupByLibrary.simpleMessage("Avvia backup"),
        "storage":
            MessageLookupByLibrary.simpleMessage("Spazio di archiviazione"),
        "storageBreakupFamily":
            MessageLookupByLibrary.simpleMessage("Famiglia"),
        "storageBreakupYou": MessageLookupByLibrary.simpleMessage("Tu"),
        "storageInGB": m50,
        "storageLimitExceeded": MessageLookupByLibrary.simpleMessage(
            "Limite d\'archiviazione superato"),
        "storageUsageInfo": m51,
        "strongStrength": MessageLookupByLibrary.simpleMessage("Forte"),
        "subAlreadyLinkedErrMessage": m52,
        "subWillBeCancelledOn": m53,
        "subscribe": MessageLookupByLibrary.simpleMessage("Iscriviti"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "Sembra che il tuo abbonamento sia scaduto. Iscriviti per abilitare la condivisione."),
        "subscription": MessageLookupByLibrary.simpleMessage("Abbonamento"),
        "success": MessageLookupByLibrary.simpleMessage("Operazione riuscita"),
        "successfullyArchived":
            MessageLookupByLibrary.simpleMessage("Archiviato correttamente"),
        "successfullyUnarchived": MessageLookupByLibrary.simpleMessage(
            "Rimosso dall\'archivio correttamente"),
        "suggestFeatures":
            MessageLookupByLibrary.simpleMessage("Suggerisci una funzionalità"),
        "support": MessageLookupByLibrary.simpleMessage("Assistenza"),
        "syncProgress": m54,
        "syncStopped":
            MessageLookupByLibrary.simpleMessage("Sincronizzazione interrotta"),
        "syncing": MessageLookupByLibrary.simpleMessage(
            "Sincronizzazione in corso..."),
        "systemTheme": MessageLookupByLibrary.simpleMessage("Sistema"),
        "tapToCopy": MessageLookupByLibrary.simpleMessage("tocca per copiare"),
        "tapToEnterCode": MessageLookupByLibrary.simpleMessage(
            "Tocca per inserire il codice"),
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
        "theyAlsoGetXGb": m55,
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
        "thisIsPersonVerificationId": m56,
        "thisIsYourVerificationId": MessageLookupByLibrary.simpleMessage(
            "Questo è il tuo ID di verifica"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Verrai disconnesso dai seguenti dispositivi:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Verrai disconnesso dal tuo dispositivo!"),
        "time": MessageLookupByLibrary.simpleMessage("Ora"),
        "toHideAPhotoOrVideo": MessageLookupByLibrary.simpleMessage(
            "Per nascondere una foto o un video"),
        "todaysLogs": MessageLookupByLibrary.simpleMessage("Log di oggi"),
        "total": MessageLookupByLibrary.simpleMessage("totale"),
        "totalSize": MessageLookupByLibrary.simpleMessage("Dimensioni totali"),
        "trash": MessageLookupByLibrary.simpleMessage("Cestino"),
        "trashDaysLeft": m57,
        "tryAgain": MessageLookupByLibrary.simpleMessage("Riprova"),
        "turnOnBackupForAutoUpload": MessageLookupByLibrary.simpleMessage(
            "Attiva il backup per caricare automaticamente i file aggiunti in questa cartella del dispositivo su ente."),
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
        "uncategorized":
            MessageLookupByLibrary.simpleMessage("Senza categoria"),
        "unhide": MessageLookupByLibrary.simpleMessage("Mostra"),
        "unhideToAlbum":
            MessageLookupByLibrary.simpleMessage("Non nascondere l\'album"),
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
        "uploadingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Caricamento dei file nell\'album..."),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "Lo spazio disponibile è limitato dal tuo piano corrente. L\'archiviazione in eccesso diventerà automaticamente utilizzabile quando aggiornerai il tuo piano."),
        "usePublicLinksForPeopleNotOnEnte":
            MessageLookupByLibrary.simpleMessage(
                "Usa link pubblici per persone non registrate su ente"),
        "useRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Utilizza un codice di recupero"),
        "useSelectedPhoto":
            MessageLookupByLibrary.simpleMessage("Usa la foto selezionata"),
        "usedSpace": MessageLookupByLibrary.simpleMessage("Spazio utilizzato"),
        "verificationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Verifica fallita, per favore prova di nuovo"),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("ID di verifica"),
        "verify": MessageLookupByLibrary.simpleMessage("Verifica"),
        "verifyEmail": MessageLookupByLibrary.simpleMessage("Verifica email"),
        "verifyEmailID": m58,
        "verifyIDLabel": MessageLookupByLibrary.simpleMessage("Verifica"),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Verifica password"),
        "verifying":
            MessageLookupByLibrary.simpleMessage("Verifica in corso..."),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Verifica della chiave di recupero..."),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("video"),
        "viewActiveSessions":
            MessageLookupByLibrary.simpleMessage("Visualizza sessioni attive"),
        "viewAllExifData":
            MessageLookupByLibrary.simpleMessage("Mostra tutti i dati EXIF"),
        "viewLogs": MessageLookupByLibrary.simpleMessage("Visualizza i log"),
        "viewRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Visualizza chiave di recupero"),
        "viewer": MessageLookupByLibrary.simpleMessage("Sola lettura"),
        "visitWebToManage": MessageLookupByLibrary.simpleMessage(
            "Visita web.ente.io per gestire il tuo abbonamento"),
        "weAreOpenSource":
            MessageLookupByLibrary.simpleMessage("Siamo open source!"),
        "weDontSupportEditingPhotosAndAlbumsThatYouDont":
            MessageLookupByLibrary.simpleMessage(
                "Non puoi modificare foto e album che non possiedi"),
        "weHaveSendEmailTo": m59,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Debole"),
        "welcomeBack": MessageLookupByLibrary.simpleMessage("Bentornato/a!"),
        "yearly": MessageLookupByLibrary.simpleMessage("Annuale"),
        "yearsAgo": m60,
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
        "youHaveSuccessfullyFreedUp": m61,
        "yourAccountHasBeenDeleted": MessageLookupByLibrary.simpleMessage(
            "Il tuo account è stato eliminato"),
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
                "Non hai file in questo album che possono essere eliminati")
      };
}
