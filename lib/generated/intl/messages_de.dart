// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a de locale. All the
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
  String get localeName => 'de';

  static String m0(paymentProvider) =>
      "Bitte kündigen Sie Ihr aktuelles Abo über ${paymentProvider} zuerst";

  static String m1(user) =>
      "Der Nutzer \"${user}\" wird keine weiteren Fotos zum Album hinzufügen können.\n\nJedoch kann er weiterhin vorhandene Bilder, welche durch ihn hinzugefügt worden sind, wieder entfernen";

  static String m2(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true':
                'Deine Familiengruppe hat bereits ${storageAmountInGb} GB erhalten',
            'false': 'Du hast bereits ${storageAmountInGb} GB erhalten',
            'other': 'Du hast bereits ${storageAmountInGb} GB erhalten!',
          })}";

  static String m3(familyAdminEmail) =>
      "Bitte kontaktiere <green>${familyAdminEmail}</green> um dein Abo zu verwalten";

  static String m4(provider) =>
      "Bitte kontaktieren Sie uns über support@ente.io, um Ihr ${provider} Abo zu verwalten.";

  static String m5(albumName) =>
      "Der öffentliche Link zum Zugriff auf \"${albumName}\" wird entfernt.";

  static String m6(supportEmail) =>
      "Bitte sende eine E-Mail an ${supportEmail} von deiner registrierten E-Mail-Adresse";

  static String m7(count, storageSaved) =>
      "Du hast ${Intl.plural(count, one: '${count} duplizierte Datei', other: '${count} dupliziere Dateien')} gelöscht und (${storageSaved}!) freigegeben";

  static String m8(email) =>
      "${email} hat kein Ente-Konto.\n\nSenden Sie eine Einladung, um Fotos zu teilen.";

  static String m9(storageAmountInGB) =>
      "${storageAmountInGB} GB jedes Mal, wenn sich jemand mit deinem Code für einen bezahlten Tarif anmeldet";

  static String m10(endDate) => "Kostenlose Demo verfügbar bis zum ${endDate}";

  static String m11(count) =>
      "${Intl.plural(count, one: '${count} Objekt', other: '${count} Objekte')}";

  static String m12(expiryTime) => "Link läuft am ${expiryTime} ab";

  static String m13(maxValue) =>
      "Wenn auf den Höchstwert von ${maxValue} gesetzt, dann wird das Limit gelockert um potenzielle Höchstlasten unterstützen zu können.";

  static String m14(count, formattedCount) =>
      "${Intl.plural(count, zero: 'keine Erinnerungsstücke', one: '${formattedCount} Erinnerung', other: '${formattedCount} Erinnerungsstücke')}";

  static String m15(passwordStrengthValue) =>
      "Passwortstärke: ${passwordStrengthValue}";

  static String m16(providerName) =>
      "Bitte kontaktiere den Support von ${providerName}, falls etwas abgebucht wurde";

  static String m17(reason) =>
      "Leider ist deine Zahlung aus folgendem Grund fehlgeschlagen: ${reason}";

  static String m18(storeName) => "Bewerte uns auf ${storeName}";

  static String m19(storageInGB) =>
      "3. Ihr beide erhaltet ${storageInGB} GB* kostenlos";

  static String m20(userEmail) =>
      "${userEmail} wird aus diesem geteilten Album entfernt\n\nAlle von ihnen hinzugefügte Fotos werden ebenfalls aus dem Album entfernt";

  static String m21(endDate) => "Erneuert am ${endDate}";

  static String m22(count) => "${count} ausgewählt";

  static String m23(count, yourCount) =>
      "${count} ausgewählt (${yourCount} von Ihnen)";

  static String m24(verificationID) =>
      "Hier ist meine Verifizierungs-ID: ${verificationID} für ente.io.";

  static String m25(verificationID) =>
      "Hey, kannst du bestätigen, dass dies deine ente.io Verifizierungs-ID ist: ${verificationID}";

  static String m26(referralCode, referralStorageInGB) =>
      "ente Weiterempfehlungs-Code: ${referralCode} \n\nEinlösen unter Einstellungen → Allgemein → Weiterempfehlungen, um ${referralStorageInGB} GB kostenlos zu erhalten, sobald Sie einen kostenpflichtigen Tarif abgeschlossen haben\n\nhttps://ente.io";

  static String m27(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Teile mit bestimmten Personen', one: 'Teilen mit 1 Person', other: 'Teilen mit ${numberOfPeople} Personen')}";

  static String m28(emailIDs) => "Geteilt mit ${emailIDs}";

  static String m29(fileType) =>
      "Dieses ${fileType} wird von deinem Gerät gelöscht.";

  static String m30(fileType) =>
      "Dieses ${fileType} existiert auf ente.io und deinem Gerät.";

  static String m31(fileType) =>
      "Dieses ${fileType} wird auf ente.io gelöscht.";

  static String m32(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m33(id) =>
      "Ihr ${id} ist bereits mit einem anderen \'ente\'-Konto verknüpft.\nWenn Sie Ihre ${id} mit diesem Konto verwenden möchten, kontaktieren Sie bitte unseren Support\'";

  static String m34(endDate) => "Ihr Abo endet am ${endDate}";

  static String m35(completed, total) =>
      "${completed}/${total} Erinnerungsstücke gesichert";

  static String m36(storageAmountInGB) =>
      "Diese erhalten auch ${storageAmountInGB} GB";

  static String m37(email) => "Dies ist ${email}s Verifizierungs-ID";

  static String m38(email) => "Verifiziere ${email}";

  static String m39(email) =>
      "Wir haben eine E-Mail an <green>${email}</green> gesendet";

  static String m40(count) =>
      "${Intl.plural(count, one: 'vor einem Jahr', other: 'vor ${count} Jahren')}";

  static String m41(storageSaved) =>
      "Du hast ${storageSaved} erfolgreich freigegeben!";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable": MessageLookupByLibrary.simpleMessage(
            "Eine neuere Version von \'ente\' ist verfügbar."),
        "about":
            MessageLookupByLibrary.simpleMessage("Allgemeine Informationen"),
        "account": MessageLookupByLibrary.simpleMessage("Konto"),
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Willkommen zurück!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Ich verstehe, dass ich meine Daten verlieren kann, wenn ich mein Passwort vergesse, da meine Daten <underline>Ende-zu-Ende-verschlüsselt</underline> sind."),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Aktive Sitzungen"),
        "addANewEmail": MessageLookupByLibrary.simpleMessage(
            "Neue E-Mail-Adresse hinzufügen"),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Bearbeiter hinzufügen"),
        "addMore": MessageLookupByLibrary.simpleMessage("Mehr hinzufügen"),
        "addToAlbum":
            MessageLookupByLibrary.simpleMessage("Zum Album hinzufügen"),
        "addToEnte": MessageLookupByLibrary.simpleMessage("Zu ente hinzufügen"),
        "addViewer": MessageLookupByLibrary.simpleMessage("Album teilen"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Hinzugefügt als"),
        "addingToFavorites": MessageLookupByLibrary.simpleMessage(
            "Wird zu Favoriten hinzugefügt..."),
        "advanced": MessageLookupByLibrary.simpleMessage("Erweitert"),
        "advancedSettings": MessageLookupByLibrary.simpleMessage("Erweitert"),
        "after1Day": MessageLookupByLibrary.simpleMessage("Nach einem Tag"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("Nach 1. Stunde"),
        "after1Month": MessageLookupByLibrary.simpleMessage("Nach 1 Monat"),
        "after1Week": MessageLookupByLibrary.simpleMessage("Nach 1 Woche"),
        "after1Year": MessageLookupByLibrary.simpleMessage("Nach 1 Jahr"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Besitzer"),
        "albumTitle": MessageLookupByLibrary.simpleMessage("Albumtitel"),
        "albumUpdated":
            MessageLookupByLibrary.simpleMessage("Album aktualisiert"),
        "albums": MessageLookupByLibrary.simpleMessage("Alben"),
        "allClear": MessageLookupByLibrary.simpleMessage("✨ Alles klar"),
        "allMemoriesPreserved": MessageLookupByLibrary.simpleMessage(
            "Alle Erinnerungsstücke gesichert"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Erlaube Nutzern mit diesem Link ebenfalls Fotos zu diesem geteilten Album hinzuzufügen."),
        "allowAddingPhotos": MessageLookupByLibrary.simpleMessage(
            "Hinzufügen von Fotos erlauben"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("Downloads erlauben"),
        "allowPeopleToAddPhotos": MessageLookupByLibrary.simpleMessage(
            "Erlaube anderen das Hinzufügen von Fotos"),
        "androidIosWebDesktop":
            MessageLookupByLibrary.simpleMessage("Android, iOS, Web, Desktop"),
        "appleId": MessageLookupByLibrary.simpleMessage("Apple ID"),
        "apply": MessageLookupByLibrary.simpleMessage("Anwenden"),
        "applyCodeTitle": MessageLookupByLibrary.simpleMessage("Code nutzen"),
        "appstoreSubscription":
            MessageLookupByLibrary.simpleMessage("AppStore Abo"),
        "archive": MessageLookupByLibrary.simpleMessage("Archiv"),
        "archiveAlbum":
            MessageLookupByLibrary.simpleMessage("Album archivieren"),
        "areYouSureThatYouWantToLeaveTheFamily":
            MessageLookupByLibrary.simpleMessage(
                "Bist du sicher, dass du den Familien-Tarif verlassen möchtest?"),
        "areYouSureYouWantToCancel": MessageLookupByLibrary.simpleMessage(
            "Bist du sicher, dass du kündigen willst?"),
        "areYouSureYouWantToChangeYourPlan":
            MessageLookupByLibrary.simpleMessage(
                "Sind Sie sicher, dass Sie Ihren Tarif ändern möchten?"),
        "areYouSureYouWantToExit": MessageLookupByLibrary.simpleMessage(
            "Möchtest du Vorgang wirklich abbrechen?"),
        "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
            "Sind sie sicher, dass Sie sich abmelden wollen?"),
        "areYouSureYouWantToRenew": MessageLookupByLibrary.simpleMessage(
            "Bist du sicher, dass du verlängern möchtest?"),
        "askCancelReason": MessageLookupByLibrary.simpleMessage(
            "Ihr Abonnement wurde gekündigt. Möchten Sie uns den Grund mitteilen?"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "Was ist der Hauptgrund für die Löschung deines Kontos?"),
        "atAFalloutShelter": MessageLookupByLibrary.simpleMessage(
            "in einem ehemaligen Luftschutzbunker"),
        "authToChangeLockscreenSetting": MessageLookupByLibrary.simpleMessage(
            "Bitte authentifizieren, um die Sperrbildschirm-Einstellung zu ändern"),
        "authToChangeYourEmail": MessageLookupByLibrary.simpleMessage(
            "Bitte authentifizieren, um deine E-Mail-Adresse zu ändern"),
        "authToChangeYourPassword": MessageLookupByLibrary.simpleMessage(
            "Bitte authentifizieren, um das Passwort zu ändern"),
        "authToConfigureTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Bitte authentifizieren, um Zwei-Faktor-Authentifizierung zu konfigurieren"),
        "authToInitiateAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Bitte authentifizieren, um die Löschung des Kontos einzuleiten"),
        "authToViewYourActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Bitte authentifizieren, um die aktiven Sitzungen anzusehen"),
        "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
            "Bitte authentifizieren, um die versteckten Dateien anzusehen"),
        "authToViewYourMemories": MessageLookupByLibrary.simpleMessage(
            "Bitte authentifizieren, um deine Erinnerungsstücke anzusehen"),
        "authToViewYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Bitte authentifizieren, um deinen Wiederherstellungs-Schlüssel anzusehen"),
        "available": MessageLookupByLibrary.simpleMessage("Verfügbar"),
        "backedUpFolders":
            MessageLookupByLibrary.simpleMessage("Gesicherte Ordner"),
        "backup": MessageLookupByLibrary.simpleMessage("Backup"),
        "backupFailed":
            MessageLookupByLibrary.simpleMessage("Sicherung fehlgeschlagen"),
        "backupOverMobileData":
            MessageLookupByLibrary.simpleMessage("Über mobile Daten sichern"),
        "backupSettings":
            MessageLookupByLibrary.simpleMessage("Backup-Einstellungen"),
        "backupVideos": MessageLookupByLibrary.simpleMessage("Videos sichern"),
        "blog": MessageLookupByLibrary.simpleMessage("Blog"),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "Du kannst nur Dateien entfernen, die dir gehören"),
        "cancel": MessageLookupByLibrary.simpleMessage("Abbrechen"),
        "cancelOtherSubscription": m0,
        "cancelSubscription":
            MessageLookupByLibrary.simpleMessage("Abonnement kündigen"),
        "cannotAddMorePhotosAfterBecomingViewer": m1,
        "changeEmail":
            MessageLookupByLibrary.simpleMessage("E-Mail-Adresse ändern"),
        "changePassword":
            MessageLookupByLibrary.simpleMessage("Passwort ändern"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Passwort ändern"),
        "changePermissions":
            MessageLookupByLibrary.simpleMessage("Berechtigungen ändern?"),
        "checkForUpdates": MessageLookupByLibrary.simpleMessage(
            "Nach Aktualisierungen suchen"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Bitte überprüfe deinen E-Mail-Posteingang (und Spam), um die Verifizierung abzuschließen"),
        "checking": MessageLookupByLibrary.simpleMessage("Wird geprüft..."),
        "claimFreeStorage":
            MessageLookupByLibrary.simpleMessage("Freien Speicher einlösen"),
        "claimMore": MessageLookupByLibrary.simpleMessage("Mehr einlösen!"),
        "claimed": MessageLookupByLibrary.simpleMessage("Eingelöst"),
        "claimedStorageSoFar": m2,
        "close": MessageLookupByLibrary.simpleMessage("Schließen"),
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("Code eingelöst"),
        "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Code in Zwischenablage kopiert"),
        "codeUsedByYou":
            MessageLookupByLibrary.simpleMessage("Von dir benutzter Code"),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Erstelle einen Link, um anderen zu ermöglichen, Fotos in deinem geteilten Album hinzuzufügen und zu sehen - ohne dass diese ein Konto von ente.io oder die App benötigen. Ideal, um Fotos von Events zu sammeln."),
        "collaborativeLink":
            MessageLookupByLibrary.simpleMessage("Gemeinschaftlicher Link"),
        "collaborator": MessageLookupByLibrary.simpleMessage("Bearbeiter"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Bearbeiter können Fotos & Videos zu dem geteilten Album hinzufügen."),
        "collectEventPhotos": MessageLookupByLibrary.simpleMessage(
            "Gemeinsam Event-Fotos sammeln"),
        "collectPhotos": MessageLookupByLibrary.simpleMessage("Fotos sammeln"),
        "color": MessageLookupByLibrary.simpleMessage("Farbe"),
        "confirm": MessageLookupByLibrary.simpleMessage("Bestätigen"),
        "confirm2FADisable": MessageLookupByLibrary.simpleMessage(
            "Bist du sicher, dass du die Zwei-Faktor-Authentifizierung (2FA) deaktivieren willst?"),
        "confirmAccountDeletion":
            MessageLookupByLibrary.simpleMessage("Kontolöschung bestätigen"),
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Ja, ich möchte dieses Konto und alle enthaltenen Daten endgültig und unwiderruflich löschen."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Passwort wiederholen"),
        "confirmPlanChange":
            MessageLookupByLibrary.simpleMessage("Aboänderungen bestätigen"),
        "confirmRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Wiederherstellungsschlüssel bestätigen"),
        "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Bestätigen Sie ihren Wiederherstellungsschlüssel"),
        "contactFamilyAdmin": m3,
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("Support kontaktieren"),
        "contactToManageSubscription": m4,
        "continueLabel": MessageLookupByLibrary.simpleMessage("Weiter"),
        "continueOnFreeTrial": MessageLookupByLibrary.simpleMessage(
            "Mit kostenloser Testversion fortfahren"),
        "copyLink": MessageLookupByLibrary.simpleMessage("Link kopieren"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Kopiere diesen Code\nin deine Authentifizierungs-App"),
        "couldNotBackUpTryLater": MessageLookupByLibrary.simpleMessage(
            "Deine Daten konnten nicht gesichert werden.\nWir versuchen es später erneut."),
        "couldNotUpdateSubscription": MessageLookupByLibrary.simpleMessage(
            "Abo konnte nicht aktualisiert werden"),
        "createAccount":
            MessageLookupByLibrary.simpleMessage("Konto erstellen"),
        "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
            "Drücke lange um Fotos auszuwählen und klicke + um ein Album zu erstellen"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("Neues Konto erstellen"),
        "createPublicLink":
            MessageLookupByLibrary.simpleMessage("Öffentlichen Link erstellen"),
        "creatingLink":
            MessageLookupByLibrary.simpleMessage("Erstelle Link..."),
        "criticalUpdateAvailable": MessageLookupByLibrary.simpleMessage(
            "Kritisches Update ist verfügbar!"),
        "currentUsageIs":
            MessageLookupByLibrary.simpleMessage("Aktuell genutzt werden "),
        "custom": MessageLookupByLibrary.simpleMessage("Benutzerdefiniert"),
        "darkTheme": MessageLookupByLibrary.simpleMessage("Dunkel"),
        "decrypting":
            MessageLookupByLibrary.simpleMessage("Wird entschlüsselt..."),
        "delete": MessageLookupByLibrary.simpleMessage("Löschen"),
        "deleteAccount": MessageLookupByLibrary.simpleMessage("Konto löschen"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "Wir bedauern sehr, dass du dein Konto löschen möchtest. Du würdest uns sehr helfen, wenn du uns kurz einige Gründe hierfür nennen könntest."),
        "deleteAccountPermanentlyButton": MessageLookupByLibrary.simpleMessage(
            "Konto unwiderruflich löschen"),
        "deleteAlbum": MessageLookupByLibrary.simpleMessage("Album löschen"),
        "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
            "Auch die Fotos (und Videos) in diesem Album aus <bold>allen</bold> anderen Alben löschen, die sie enthalten?"),
        "deleteAlbumsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Damit werden alle leeren Alben gelöscht. Dies ist nützlich, wenn du das Durcheinander in deiner Albenliste verringern möchtest."),
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
            "Du bist dabei, dein Konto und alle gespeicherten Daten dauerhaft zu löschen.\nDiese Aktion ist unwiderrufbar."),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "Bitte sende eine E-Mail an <warning>account-deletion@ente.io</warning> von Deiner bei uns hinterlegten E-Mail-Adresse."),
        "deleteEmptyAlbums":
            MessageLookupByLibrary.simpleMessage("Leere Alben löschen"),
        "deleteEmptyAlbumsWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Leere Alben löschen?"),
        "deleteFromBoth":
            MessageLookupByLibrary.simpleMessage("Aus beidem löschen"),
        "deleteFromDevice":
            MessageLookupByLibrary.simpleMessage("Vom Gerät löschen"),
        "deleteFromEnte":
            MessageLookupByLibrary.simpleMessage("Auf ente.io löschen"),
        "deletePhotos": MessageLookupByLibrary.simpleMessage("Fotos löschen"),
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "Es fehlt eine zentrale Funktion, die ich benötige"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "Die App oder eine bestimmte Funktion verhält sich nicht so wie gedacht"),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
            "Ich habe einen anderen Dienst gefunden, der mir mehr zusagt"),
        "deleteReason4": MessageLookupByLibrary.simpleMessage(
            "Mein Grund ist nicht aufgeführt"),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
            "Deine Anfrage wird innerhalb von 72 Stunden bearbeitet."),
        "deleteSharedAlbum":
            MessageLookupByLibrary.simpleMessage("Geteiltes Album löschen?"),
        "deleteSharedAlbumDialogBody": MessageLookupByLibrary.simpleMessage(
            "Dieses Album wird für alle gelöscht\n\nDu wirst den Zugriff auf geteilte Fotos in diesem Album, die anderen gehören, verlieren"),
        "designedToOutlive":
            MessageLookupByLibrary.simpleMessage("Entwickelt um zu bewahren"),
        "details": MessageLookupByLibrary.simpleMessage("Details"),
        "devAccountChanged": MessageLookupByLibrary.simpleMessage(
            "Das Entwicklerkonto, das wir verwenden, um ente im App Store zu veröffentlichen, hat sich geändert. Aus diesem Grund musst du dich erneut anmelden.\n\nWir entschuldigen uns für die Unannehmlichkeiten, aber das war unvermeidlich."),
        "deviceFilesAutoUploading": MessageLookupByLibrary.simpleMessage(
            "Dateien, die zu diesem Album hinzugefügt werden, werden automatisch zu ente hochgeladen."),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
            "Das Sperren des Gerätes verhindern, solange \'ente\' im Vordergrund geöffnet ist und eine Sicherung läuft. \nDies wird für gewöhnlich nicht benötigt, kann aber dabei helfen große Transfers schneller durchzuführen."),
        "disableAutoLock": MessageLookupByLibrary.simpleMessage(
            "Automatische Sperre deaktivieren"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Zuschauer können weiterhin Screenshots oder mit anderen externen Programmen Kopien der Bilder machen."),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Bitte beachten Sie:"),
        "disableLinkMessage": m5,
        "disableTwofactor": MessageLookupByLibrary.simpleMessage(
            "Zweiten Faktor (2FA) deaktivieren"),
        "disablingTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Zwei-Faktor-Authentifizierung (2FA) wird deaktiviert..."),
        "discord": MessageLookupByLibrary.simpleMessage("Discord"),
        "doThisLater": MessageLookupByLibrary.simpleMessage("Später machen"),
        "doYouWantToDiscardTheEditsYouHaveMade":
            MessageLookupByLibrary.simpleMessage(
                "Möchtest du deine Änderungen verwerfen?"),
        "done": MessageLookupByLibrary.simpleMessage("Fertig"),
        "doubleYourStorage":
            MessageLookupByLibrary.simpleMessage("Speicherplatz verdoppeln"),
        "download": MessageLookupByLibrary.simpleMessage("Herunterladen"),
        "downloadFailed": MessageLookupByLibrary.simpleMessage(
            "Herunterladen fehlgeschlagen"),
        "downloading":
            MessageLookupByLibrary.simpleMessage("Wird heruntergeladen..."),
        "dropSupportEmail": m6,
        "duplicateFileCountWithStorageSaved": m7,
        "editsSaved":
            MessageLookupByLibrary.simpleMessage("Änderungen gespeichert"),
        "eligible": MessageLookupByLibrary.simpleMessage("zulässig"),
        "email": MessageLookupByLibrary.simpleMessage("E-Mail"),
        "emailNoEnteAccount": m8,
        "encryption": MessageLookupByLibrary.simpleMessage("Verschlüsselung"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Verschlüsselungscode"),
        "endtoendEncryptedByDefault": MessageLookupByLibrary.simpleMessage(
            "Automatisch Ende-zu-Ende-verschlüsselt"),
        "enteCanEncryptAndPreserveFilesOnlyIfYouGrant":
            MessageLookupByLibrary.simpleMessage(
                "ente kann Dateien nur verschlüsselt sichern, wenn du uns darauf Zugriff gewährst"),
        "enteSubscriptionPitch": MessageLookupByLibrary.simpleMessage(
            "ente sichert deine Erinnerungsstücke, sodass sie immer für dich verfügbar sind, auch wenn du dein Gerät verlieren solltest."),
        "enteSubscriptionShareWithFamily": MessageLookupByLibrary.simpleMessage(
            "Deine Familie kann zu deinem Abo hinzugefügt werden."),
        "enterAlbumName":
            MessageLookupByLibrary.simpleMessage("Albumname eingeben"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Code eingeben"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
            "Gib den Code deines Freundes ein, damit sie beide kostenlosen Speicherplatz erhalten"),
        "enterEmail": MessageLookupByLibrary.simpleMessage("E-Mail eingeben"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Gib ein neues Passwort ein, mit dem wir deine Daten verschlüsseln können"),
        "enterPassword":
            MessageLookupByLibrary.simpleMessage("Passwort eingeben"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Gib ein Passwort ein, mit dem wir deine Daten verschlüsseln können"),
        "enterReferralCode": MessageLookupByLibrary.simpleMessage(
            "Gib den Weiterempfehlungs-Code ein"),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Gib den 6-stelligen Code aus\ndeiner Authentifizierungs-App ein"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "Bitte gib eine gültige E-Mail-Adresse ein."),
        "enterYourEmailAddress": MessageLookupByLibrary.simpleMessage(
            "Gib deine E-Mail-Adresse ein"),
        "enterYourPassword":
            MessageLookupByLibrary.simpleMessage("Passwort eingeben"),
        "enterYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Gib deinen Wiederherstellungs-Schlüssel ein"),
        "everywhere": MessageLookupByLibrary.simpleMessage("überall"),
        "exif": MessageLookupByLibrary.simpleMessage("EXIF"),
        "existingUser":
            MessageLookupByLibrary.simpleMessage("Existierender Benutzer"),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
            "Dieser Link ist abgelaufen. Bitte wählen Sie ein neues Ablaufdatum oder deaktivieren Sie das Ablaufdatum des Links."),
        "exportYourData":
            MessageLookupByLibrary.simpleMessage("Daten exportieren"),
        "failedToApplyCode": MessageLookupByLibrary.simpleMessage(
            "Der Code konnte nicht aktiviert werden"),
        "failedToCancel":
            MessageLookupByLibrary.simpleMessage("Kündigung fehlgeschlagen"),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "Die Weiterempfehlungs-Details können nicht abgerufen werden. Bitte versuche es später erneut."),
        "failedToLoadAlbums": MessageLookupByLibrary.simpleMessage(
            "Laden der Alben fehlgeschlagen"),
        "failedToRenew":
            MessageLookupByLibrary.simpleMessage("Erneuern fehlgeschlagen"),
        "failedToVerifyPaymentStatus": MessageLookupByLibrary.simpleMessage(
            "Überprüfung des Zahlungsstatus fehlgeschlagen"),
        "familyPlans": MessageLookupByLibrary.simpleMessage("Familientarif"),
        "faq": MessageLookupByLibrary.simpleMessage("Häufig gestellte Fragen"),
        "faqs": MessageLookupByLibrary.simpleMessage("FAQs"),
        "favorite": MessageLookupByLibrary.simpleMessage("Favorit"),
        "feedback": MessageLookupByLibrary.simpleMessage("Rückmeldung"),
        "fileSavedToGallery": MessageLookupByLibrary.simpleMessage(
            "Datei in Galerie gespeichert"),
        "forYourMemories":
            MessageLookupByLibrary.simpleMessage("Als Erinnerung"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Passwort vergessen"),
        "freeStorageClaimed": MessageLookupByLibrary.simpleMessage(
            "Kostenlos hinzugefügter Speicherplatz"),
        "freeStorageOnReferralSuccess": m9,
        "freeStorageUsable": MessageLookupByLibrary.simpleMessage(
            "Freier Speicherplatz nutzbar"),
        "freeTrial":
            MessageLookupByLibrary.simpleMessage("Kostenlose Testphase"),
        "freeTrialValidTill": m10,
        "freeUpDeviceSpace":
            MessageLookupByLibrary.simpleMessage("Gerätespeicher freiräumen"),
        "galleryMemoryLimitInfo": MessageLookupByLibrary.simpleMessage(
            "Bis zu 1000 Erinnerungsstücke angezeigt in der Galerie"),
        "general": MessageLookupByLibrary.simpleMessage("Allgemein"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Generierung von Verschlüsselungscodes..."),
        "googlePlayId": MessageLookupByLibrary.simpleMessage("Google Play ID"),
        "grantPermission":
            MessageLookupByLibrary.simpleMessage("Zugriff gewähren"),
        "hidden": MessageLookupByLibrary.simpleMessage("Versteckt"),
        "howItWorks":
            MessageLookupByLibrary.simpleMessage("So funktioniert\'s"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "Bitte sie, auf den Einstellungs Bildschirm ihre E-Mail-Adresse lange anzuklicken und zu überprüfen, dass die IDs auf beiden Geräten übereinstimmen."),
        "ignoredFolderUploadReason": MessageLookupByLibrary.simpleMessage(
            "Einige Dateien in diesem Album werden beim Upload ignoriert, weil sie zuvor auf ente gelöscht wurden."),
        "importing": MessageLookupByLibrary.simpleMessage("Importiert...."),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Falsches Passwort"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "Der eingegebene Schlüssel ist ungültig"),
        "incorrectRecoveryKeyTitle": MessageLookupByLibrary.simpleMessage(
            "Falscher Wiederherstellungs-Schlüssel"),
        "insecureDevice":
            MessageLookupByLibrary.simpleMessage("Unsicheres Gerät"),
        "installManually":
            MessageLookupByLibrary.simpleMessage("Manuell installieren"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("Ungültige E-Mail-Adresse"),
        "invalidKey":
            MessageLookupByLibrary.simpleMessage("Ungültiger Schlüssel"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Der von Ihnen eingegebene Wiederherstellungsschlüssel ist nicht gültig. Bitte stellen Sie sicher das aus 24 Wörtern zusammen gesetzt ist und jedes dieser Worte richtig geschrieben wurde.\n\nSollten Sie den Wiederherstellungscode eingegeben haben, stellen Sie bitte sicher, dass dieser 64 Worte lang ist und ebenfall richtig geschrieben wurde."),
        "invite": MessageLookupByLibrary.simpleMessage("Einladen"),
        "inviteToEnte":
            MessageLookupByLibrary.simpleMessage("Zu ente einladen"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Lade deine Freunde ein"),
        "itemCount": m11,
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "Ausgewählte Elemente werden aus diesem Album entfernt"),
        "keepPhotos": MessageLookupByLibrary.simpleMessage("Fotos behalten"),
        "kindlyHelpUsWithThisInformation":
            MessageLookupByLibrary.simpleMessage("Bitte gib diese Daten ein"),
        "lastUpdated":
            MessageLookupByLibrary.simpleMessage("Zuletzt aktualisiert"),
        "leave": MessageLookupByLibrary.simpleMessage("Verlassen"),
        "leaveAlbum": MessageLookupByLibrary.simpleMessage("Album verlassen"),
        "leaveFamily":
            MessageLookupByLibrary.simpleMessage("Familienabo verlassen"),
        "leaveSharedAlbum":
            MessageLookupByLibrary.simpleMessage("Geteiltes Album verlassen?"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("Hell"),
        "linkDeviceLimit": MessageLookupByLibrary.simpleMessage("Geräte Limit"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Aktiviert"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Abgelaufen"),
        "linkExpiresOn": m12,
        "linkExpiry":
            MessageLookupByLibrary.simpleMessage("Ablaufdatum des Links"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("Link ist abgelaufen"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Niemals"),
        "loadMessage2": MessageLookupByLibrary.simpleMessage(
            "Wir haben bereits mehr als 10 Millionen Erinnerungsstücke gesichert"),
        "loadingExifData":
            MessageLookupByLibrary.simpleMessage("Lade Exif-Daten..."),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Sperren"),
        "lockScreenEnablePreSteps": MessageLookupByLibrary.simpleMessage(
            "Um den Sperrbildschirm zu aktivieren, legen Sie bitte den Geräte-Passcode oder die Bildschirmsperre in den Systemeinstellungen fest."),
        "lockscreen": MessageLookupByLibrary.simpleMessage("Sperrbildschirm"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Anmelden"),
        "loggingOut": MessageLookupByLibrary.simpleMessage("Abmeldung..."),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "Mit dem Klick auf \"Anmelden\" stimme ich den <u-terms>Nutzungsbedingungen</u-terms> und der <u-policy>Datenschutzerklärung</u-policy> zu"),
        "logout": MessageLookupByLibrary.simpleMessage("Ausloggen"),
        "lostDevice": MessageLookupByLibrary.simpleMessage("Gerät verloren?"),
        "manage": MessageLookupByLibrary.simpleMessage("Verwalten"),
        "manageDeviceStorage":
            MessageLookupByLibrary.simpleMessage("Gerätespeicher verwalten"),
        "manageFamily":
            MessageLookupByLibrary.simpleMessage("Familiengruppe verwalten"),
        "manageLink": MessageLookupByLibrary.simpleMessage("Link verwalten"),
        "manageParticipants": MessageLookupByLibrary.simpleMessage("Verwalten"),
        "manageSubscription":
            MessageLookupByLibrary.simpleMessage("Abonnement verwalten"),
        "mastodon": MessageLookupByLibrary.simpleMessage("Mastodon"),
        "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
        "maxDeviceLimitSpikeHandling": m13,
        "memoryCount": m14,
        "merchandise": MessageLookupByLibrary.simpleMessage("Merchandise"),
        "mobileWebDesktop":
            MessageLookupByLibrary.simpleMessage("Mobil, Web, Desktop"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Mittel"),
        "monthly": MessageLookupByLibrary.simpleMessage("Monatlich"),
        "moveToAlbum":
            MessageLookupByLibrary.simpleMessage("Zum Album verschieben"),
        "movedToTrash": MessageLookupByLibrary.simpleMessage(
            "In den Papierkorb verschoben"),
        "name": MessageLookupByLibrary.simpleMessage("Name"),
        "never": MessageLookupByLibrary.simpleMessage("Niemals"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Neues Album"),
        "newToEnte": MessageLookupByLibrary.simpleMessage("Neu bei ente"),
        "newest": MessageLookupByLibrary.simpleMessage("Zuletzt"),
        "no": MessageLookupByLibrary.simpleMessage("Nein"),
        "noDeviceThatCanBeDeleted": MessageLookupByLibrary.simpleMessage(
            "Du hast keine Dateien auf diesem Gerät, die gelöscht werden können"),
        "noDuplicates":
            MessageLookupByLibrary.simpleMessage("✨ Keine Duplikate"),
        "noExifData": MessageLookupByLibrary.simpleMessage("Keine Exif-Daten"),
        "noHiddenPhotosOrVideos": MessageLookupByLibrary.simpleMessage(
            "Keine versteckten Fotos oder Videos"),
        "noPhotosAreBeingBackedUpRightNow":
            MessageLookupByLibrary.simpleMessage(
                "Momentan werden keine Fotos gesichert"),
        "noRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Kein Wiederherstellungs-Schlüssel?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "Aufgrund unseres Ende-zu-Ende-Verschlüsselungsprotokolls können deine Daten nicht ohne dein Passwort oder deinen Wiederherstellungs-Schlüssel entschlüsselt werden"),
        "noResults": MessageLookupByLibrary.simpleMessage("Keine Ergebnisse"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("Keine Ergebnisse gefunden"),
        "nothingToSeeHere": MessageLookupByLibrary.simpleMessage(
            "Hier gibt es nichts zu sehen! 👀"),
        "ok": MessageLookupByLibrary.simpleMessage("Ok"),
        "onDevice": MessageLookupByLibrary.simpleMessage("Auf dem Gerät"),
        "oops": MessageLookupByLibrary.simpleMessage("Hoppla"),
        "oopsSomethingWentWrong": MessageLookupByLibrary.simpleMessage(
            "Ups. Leider ist ein Fehler aufgetreten"),
        "optionalAsShortAsYouLike": MessageLookupByLibrary.simpleMessage(
            "Bei Bedarf auch so kurz wie Sie wollen..."),
        "orPickAnExistingOne": MessageLookupByLibrary.simpleMessage(
            "Oder eine Vorherige auswählen"),
        "password": MessageLookupByLibrary.simpleMessage("Passwort"),
        "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
            "Passwort erfolgreich geändert"),
        "passwordLock": MessageLookupByLibrary.simpleMessage("Passwort Sperre"),
        "passwordStrength": m15,
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Wir speichern dieses Passwort nicht. Wenn du es vergisst, <underline>können wir deine Daten nicht entschlüsseln</underline>"),
        "paymentDetails":
            MessageLookupByLibrary.simpleMessage("Zahlungsdetails"),
        "paymentFailed":
            MessageLookupByLibrary.simpleMessage("Zahlung fehlgeschlagen"),
        "paymentFailedTalkToProvider": m16,
        "paymentFailedWithReason": m17,
        "peopleUsingYourCode": MessageLookupByLibrary.simpleMessage(
            "Leute, die deinen Code verwenden"),
        "photoGridSize":
            MessageLookupByLibrary.simpleMessage("Fotorastergröße"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("Foto"),
        "photosAddedByYouWillBeRemovedFromTheAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Von dir hinzugefügte Fotos werden vom Album entfernt"),
        "playstoreSubscription":
            MessageLookupByLibrary.simpleMessage("PlayStore Abo"),
        "pleaseContactSupportAndWeWillBeHappyToHelp":
            MessageLookupByLibrary.simpleMessage(
                "Bitte kontaktieren Sie uns über support@ente.io wo wir Ihnen gerne weiterhelfen."),
        "pleaseGrantPermissions": MessageLookupByLibrary.simpleMessage(
            "Bitte erteile die nötigen Berechtigungen"),
        "pleaseLoginAgain":
            MessageLookupByLibrary.simpleMessage("Bitte logge dich erneut ein"),
        "pleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("Bitte versuche es erneut"),
        "pleaseWait": MessageLookupByLibrary.simpleMessage("Bitte warten..."),
        "pleaseWaitDeletingAlbum": MessageLookupByLibrary.simpleMessage(
            "Bitte warten, Album wird gelöscht"),
        "pleaseWaitForSometimeBeforeRetrying":
            MessageLookupByLibrary.simpleMessage(
                "Bitte warte kurz, bevor du es erneut versuchst"),
        "preserveMore":
            MessageLookupByLibrary.simpleMessage("Mehr Daten sichern"),
        "privacy": MessageLookupByLibrary.simpleMessage("Datenschutz"),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Datenschutzerklärung"),
        "privateBackups":
            MessageLookupByLibrary.simpleMessage("Private Sicherungen"),
        "privateSharing":
            MessageLookupByLibrary.simpleMessage("Privates Teilen"),
        "publicLinkEnabled":
            MessageLookupByLibrary.simpleMessage("Öffentlicher Link aktiviert"),
        "rateTheApp": MessageLookupByLibrary.simpleMessage("App bewerten"),
        "rateUs": MessageLookupByLibrary.simpleMessage("Bewerte uns"),
        "rateUsOnStore": m18,
        "recover": MessageLookupByLibrary.simpleMessage("Wiederherstellen"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("Konto wiederherstellen"),
        "recoverButton":
            MessageLookupByLibrary.simpleMessage("Wiederherstellen"),
        "recoveryKey": MessageLookupByLibrary.simpleMessage(
            "Wiederherstellungs-Schlüssel"),
        "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Wiederherstellungs-Schlüssel in die Zwischenablage kopiert"),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
            "Falls du dein Passwort vergisst, kannst du deine Daten allein mit diesem Schlüssel wiederherstellen."),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
            "Wir speichern diesen Schlüssel nicht. Bitte speichere diese Schlüssel aus 24 Wörtern an einem sicheren Ort."),
        "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
            "Sehr gut! Ihr Wiederherstellungsschlüssel ist gültig. Vielen Dank für die Verifizierung.\n\nBitte vergessen Sie nicht eine Kopie Ihres Wiederherstellungsschlüssels sicher aufzubewahren."),
        "recoveryKeyVerified": MessageLookupByLibrary.simpleMessage(
            "Wiederherstellungs-Schlüssel überprüft"),
        "recoveryKeyVerifyReason": MessageLookupByLibrary.simpleMessage(
            "Ihr Wiederherstellungsschlüssel ist die einzige Möglichkeit Ihre Fotos wieder herzustellen, sollten Sie Ihr Passwort vergessen haben. Sie können diesen unter \"Einstellungen\" und dann \"Konto\" wieder finden.\n\nBitte geben Sie unten Ihren Wiederherstellungsschlüssel ein um sicher zu stellen, dass Sie ihn korrekt hinterlegt haben."),
        "recoverySuccessful": MessageLookupByLibrary.simpleMessage(
            "Wiederherstellung erfolgreich!"),
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "Das aktuelle Gerät ist nicht leistungsfähig genug, um dein Passwort zu verifizieren, aber wir können es neu erstellen, damit es auf allen Geräten funktioniert.\n\nBitte melde dich mit deinem Wiederherstellungs-Schlüssel an und erstelle dein Passwort neu (Wenn du willst, kannst du dasselbe erneut verwenden)."),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Passwort wiederherstellen"),
        "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
        "referFriendsAnd2xYourPlan": MessageLookupByLibrary.simpleMessage(
            "Begeistere Freunde für uns und verdopple deinen Speicher"),
        "referralStep1": MessageLookupByLibrary.simpleMessage(
            "1. Gib diesen Code an deine Freunde"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "2. Sie schließen ein bezahltes Abo ab"),
        "referralStep3": m19,
        "referrals": MessageLookupByLibrary.simpleMessage("Weiterempfehlungen"),
        "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
            "Einlösungen sind derzeit pausiert"),
        "remindToEmptyDeviceTrash": MessageLookupByLibrary.simpleMessage(
            "Lösche auch Dateien aus \"Kürzlich gelöscht\" unter \"Einstellungen\" -> \"Speicher\" um freien Speicher zu erhalten"),
        "remindToEmptyEnteTrash": MessageLookupByLibrary.simpleMessage(
            "Leere auch deinen \"Papierkorb\", um freien Platz zu erhalten"),
        "remove": MessageLookupByLibrary.simpleMessage("Entfernen"),
        "removeDuplicates":
            MessageLookupByLibrary.simpleMessage("Duplikate entfernen"),
        "removeFromAlbum":
            MessageLookupByLibrary.simpleMessage("Aus Album entfernen"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("Aus Album entfernen?"),
        "removeLink": MessageLookupByLibrary.simpleMessage("Link entfernen"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Teilnehmer entfernen"),
        "removeParticipantBody": m20,
        "removePublicLink":
            MessageLookupByLibrary.simpleMessage("Öffentlichen Link entfernen"),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
            "Einige der Elemente, die du entfernst, wurden von anderen Nutzern hinzugefügt und du wirst den Zugriff auf sie verlieren"),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Entfernen?"),
        "removingFromFavorites": MessageLookupByLibrary.simpleMessage(
            "Wird aus Favoriten entfernt..."),
        "rename": MessageLookupByLibrary.simpleMessage("Umbenennen"),
        "renameAlbum": MessageLookupByLibrary.simpleMessage("Album umbenennen"),
        "renewSubscription":
            MessageLookupByLibrary.simpleMessage("Abonnement erneuern"),
        "renewsOn": m21,
        "reportABug": MessageLookupByLibrary.simpleMessage("Fehler melden"),
        "reportBug": MessageLookupByLibrary.simpleMessage("Fehler melden"),
        "resendEmail":
            MessageLookupByLibrary.simpleMessage("E-Mail erneut senden"),
        "resetIgnoredFiles": MessageLookupByLibrary.simpleMessage(
            "Ignorierte Dateien zurücksetzen"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Passwort zurücksetzen"),
        "restore": MessageLookupByLibrary.simpleMessage("Wiederherstellen"),
        "restoringFiles": MessageLookupByLibrary.simpleMessage(
            "Dateien werden wiederhergestellt..."),
        "retry": MessageLookupByLibrary.simpleMessage("Erneut versuchen"),
        "rotateRight":
            MessageLookupByLibrary.simpleMessage("Nach rechts drehen"),
        "safelyStored": MessageLookupByLibrary.simpleMessage("Gesichert"),
        "saveCopy": MessageLookupByLibrary.simpleMessage("Kopie speichern"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Schlüssel speichern"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Sichere deinen Wiederherstellungs-Schlüssel, falls noch nicht geschehen"),
        "saving": MessageLookupByLibrary.simpleMessage("Speichern..."),
        "scanCode": MessageLookupByLibrary.simpleMessage("Code scannen"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Scanne diesen Code mit \ndeiner Authentifizierungs-App"),
        "searchByAlbumNameHint":
            MessageLookupByLibrary.simpleMessage("Name des Albums"),
        "security": MessageLookupByLibrary.simpleMessage("Sicherheit"),
        "selectAll": MessageLookupByLibrary.simpleMessage("Alle markieren"),
        "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
            "Ordner für Sicherung auswählen"),
        "selectReason": MessageLookupByLibrary.simpleMessage("Grund auswählen"),
        "selectYourPlan":
            MessageLookupByLibrary.simpleMessage("Wähle dein Abo aus"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "Ausgewählte Ordner werden verschlüsselt und gesichert"),
        "selectedPhotos": m22,
        "selectedPhotosWithYours": m23,
        "send": MessageLookupByLibrary.simpleMessage("Absenden"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("E-Mail senden"),
        "sendInvite": MessageLookupByLibrary.simpleMessage("Einladung senden"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Link senden"),
        "sessionExpired":
            MessageLookupByLibrary.simpleMessage("Sitzung abgelaufen"),
        "setAPassword": MessageLookupByLibrary.simpleMessage("Passwort setzen"),
        "setAs": MessageLookupByLibrary.simpleMessage("Festlegen als"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Passwort festlegen"),
        "setupComplete":
            MessageLookupByLibrary.simpleMessage("Einrichtung abgeschlossen"),
        "share": MessageLookupByLibrary.simpleMessage("Teilen"),
        "shareALink": MessageLookupByLibrary.simpleMessage("Einen Link teilen"),
        "shareAlbumHint": MessageLookupByLibrary.simpleMessage(
            "Öffne ein Album und tippe auf den Teilen-Button oben rechts, um zu teilen."),
        "shareAnAlbumNow":
            MessageLookupByLibrary.simpleMessage("Teile jetzt ein Album"),
        "shareLink": MessageLookupByLibrary.simpleMessage("Link teilen"),
        "shareMyVerificationID": m24,
        "shareOnlyWithThePeopleYouWant": MessageLookupByLibrary.simpleMessage(
            "Teile mit ausgewählten Personen"),
        "shareTextConfirmOthersVerificationID": m25,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Lade ente herunter, damit wir einfach Fotos und Videos in höchster Qualität teilen können\n\nhttps://ente.io"),
        "shareTextReferralCode": m26,
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
            "Mit Nicht-Ente-Benutzern teilen"),
        "shareWithPeopleSectionTitle": m27,
        "shareYourFirstAlbum":
            MessageLookupByLibrary.simpleMessage("Teile dein erstes Album"),
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Erstelle gemeinsame Alben mit anderen ente Benutzern, einschließlich solchen im kostenlosen Tarif."),
        "sharedByMe": MessageLookupByLibrary.simpleMessage("Von mir geteilt"),
        "sharedWith": m28,
        "sharedWithMe": MessageLookupByLibrary.simpleMessage("Mit mir geteilt"),
        "sharing": MessageLookupByLibrary.simpleMessage("Teilt..."),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "Ich stimme den <u-terms>Nutzungsbedingungen</u-terms> und der <u-policy>Datenschutzerklärung</u-policy> zu"),
        "singleFileDeleteFromDevice": m29,
        "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
            "Es wird aus allen Alben gelöscht."),
        "singleFileInBothLocalAndRemote": m30,
        "singleFileInRemoteOnly": m31,
        "skip": MessageLookupByLibrary.simpleMessage("Überspringen"),
        "social": MessageLookupByLibrary.simpleMessage("Social Media"),
        "someoneSharingAlbumsWithYouShouldSeeTheSameId":
            MessageLookupByLibrary.simpleMessage(
                "Jemand, der Alben mit dir teilt, sollte die gleiche ID auf seinem Gerät sehen."),
        "somethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Irgendetwas ging schief"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Ein Fehler ist aufgetreten, bitte versuche es erneut"),
        "sorry": MessageLookupByLibrary.simpleMessage("Entschuldigung"),
        "sorryCouldNotAddToFavorites": MessageLookupByLibrary.simpleMessage(
            "Konnte leider nicht zu den Favoriten hinzugefügt werden!"),
        "sorryCouldNotRemoveFromFavorites":
            MessageLookupByLibrary.simpleMessage(
                "Konnte leider nicht aus den Favoriten entfernt werden!"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "Es tut uns leid, wir konnten keine sicheren Schlüssel auf diesem Gerät generieren.\n\nBitte starte die Registrierung auf einem anderen Gerät."),
        "sparkleSuccess":
            MessageLookupByLibrary.simpleMessage("✨ Abgeschlossen"),
        "startBackup":
            MessageLookupByLibrary.simpleMessage("Sicherung starten"),
        "storageInGB": m32,
        "storageLimitExceeded": MessageLookupByLibrary.simpleMessage(
            "Speichergrenze überschritten"),
        "strongStrength": MessageLookupByLibrary.simpleMessage("Stark"),
        "subAlreadyLinkedErrMessage": m33,
        "subWillBeCancelledOn": m34,
        "subscribe": MessageLookupByLibrary.simpleMessage("Abonnieren"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "Sieht aus, als sei dein Abonnement abgelaufen. Bitte abonniere, um das Teilen zu aktivieren."),
        "subscription": MessageLookupByLibrary.simpleMessage("Abonnement"),
        "success": MessageLookupByLibrary.simpleMessage("Abgeschlossen"),
        "suggestFeatures":
            MessageLookupByLibrary.simpleMessage("Verbesserung vorschlagen"),
        "support": MessageLookupByLibrary.simpleMessage("Support"),
        "syncProgress": m35,
        "systemTheme": MessageLookupByLibrary.simpleMessage("System"),
        "tapToCopy":
            MessageLookupByLibrary.simpleMessage("zum Kopieren antippen"),
        "tapToEnterCode": MessageLookupByLibrary.simpleMessage(
            "Antippen, um den Code einzugeben"),
        "terminate": MessageLookupByLibrary.simpleMessage("Beenden"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Sitzungen beenden?"),
        "terms": MessageLookupByLibrary.simpleMessage("Nutzungsbedingungen"),
        "termsOfServicesTitle":
            MessageLookupByLibrary.simpleMessage("Nutzungsbedingungen"),
        "thankYou": MessageLookupByLibrary.simpleMessage("Vielen Dank"),
        "thankYouForSubscribing":
            MessageLookupByLibrary.simpleMessage("Danke fürs Abonnieren!"),
        "theDownloadCouldNotBeCompleted": MessageLookupByLibrary.simpleMessage(
            "Der Download konnte nicht abgeschlossen werden"),
        "theme": MessageLookupByLibrary.simpleMessage("Theme"),
        "theyAlsoGetXGb": m36,
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "Dies kann verwendet werden, um dein Konto wiederherzustellen, wenn du deinen zweiten Faktor (2FA) verlierst"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Dieses Gerät"),
        "thisImageHasNoExifData": MessageLookupByLibrary.simpleMessage(
            "Dieses Bild hat keine Exif-Daten"),
        "thisIsPersonVerificationId": m37,
        "thisIsYourVerificationId": MessageLookupByLibrary.simpleMessage(
            "Dies ist deine Verifizierungs-ID"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Dadurch wirst du von folgendem Gerät abgemeldet:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Dadurch wirst du von diesem Gerät abgemeldet!"),
        "total": MessageLookupByLibrary.simpleMessage("Gesamt"),
        "trash": MessageLookupByLibrary.simpleMessage("Papierkorb"),
        "tryAgain": MessageLookupByLibrary.simpleMessage("Erneut versuchen"),
        "turnOnBackupForAutoUpload": MessageLookupByLibrary.simpleMessage(
            "Aktiviere die Sicherung, um automatisch neu hinzugefügte Dateien dieses Ordners auf ente hochzuladen."),
        "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
        "twoMonthsFreeOnYearlyPlans": MessageLookupByLibrary.simpleMessage(
            "2 Monate kostenlos beim jährlichen Bezahlen"),
        "twofactor": MessageLookupByLibrary.simpleMessage("Zwei-Faktor"),
        "twofactorAuthenticationHasBeenDisabled":
            MessageLookupByLibrary.simpleMessage(
                "Zwei-Faktor-Authentifizierung (2FA) wurde deaktiviert"),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage(
                "Zwei-Faktor-Authentifizierung"),
        "twofactorAuthenticationSuccessfullyReset":
            MessageLookupByLibrary.simpleMessage(
                "Zwei-Faktor-Authentifizierung (2FA) erfolgreich zurückgesetzt"),
        "twofactorSetup": MessageLookupByLibrary.simpleMessage(
            "Zweiten Faktor (2FA) einrichten"),
        "unarchive": MessageLookupByLibrary.simpleMessage("Dearchivieren"),
        "unarchiveAlbum":
            MessageLookupByLibrary.simpleMessage("Album dearchivieren"),
        "uncategorized":
            MessageLookupByLibrary.simpleMessage("Unkategorisiert"),
        "unselectAll": MessageLookupByLibrary.simpleMessage("Alle demarkieren"),
        "update": MessageLookupByLibrary.simpleMessage("Updaten"),
        "updateAvailable":
            MessageLookupByLibrary.simpleMessage("Update verfügbar"),
        "updatingFolderSelection": MessageLookupByLibrary.simpleMessage(
            "Ordnerauswahl wird aktualisiert..."),
        "upgrade": MessageLookupByLibrary.simpleMessage("Upgrade"),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "Der verwendbare Speicherplatz ist von deinem aktuellen Abonnement eingeschränkt. Überschüssiger, beanspruchter Speicherplatz wird automatisch verwendbar werden, wenn du ein höheres Abonnement buchst."),
        "usePublicLinksForPeopleNotOnEnte":
            MessageLookupByLibrary.simpleMessage(
                "Nutze öffentliche Links für Personen ohne ente.io Konto"),
        "useRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Wiederherstellungs-Schlüssel verwenden"),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("Verifizierungs-ID"),
        "verify": MessageLookupByLibrary.simpleMessage("Überprüfen"),
        "verifyEmail":
            MessageLookupByLibrary.simpleMessage("E-Mail-Adresse verifizieren"),
        "verifyEmailID": m38,
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Passwort überprüfen"),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Wiederherstellungs-Schlüssel wird überprüft..."),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("Video"),
        "viewActiveSessions":
            MessageLookupByLibrary.simpleMessage("Aktive Sitzungen anzeigen"),
        "viewAllExifData":
            MessageLookupByLibrary.simpleMessage("Alle Exif-Daten anzeigen"),
        "viewRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Wiederherstellungsschlüssel anzeigen"),
        "viewer": MessageLookupByLibrary.simpleMessage("Zuschauer"),
        "visitWebToManage": MessageLookupByLibrary.simpleMessage(
            "Bitte rufen Sie \"web.ente.io\" auf um ihr Abo zu verwalten"),
        "weAreOpenSource": MessageLookupByLibrary.simpleMessage(
            "Unser Quellcode ist offen einsehbar!"),
        "weHaveSendEmailTo": m39,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Schwach"),
        "welcomeBack":
            MessageLookupByLibrary.simpleMessage("Willkommen zurück!"),
        "yearly": MessageLookupByLibrary.simpleMessage("Jährlich"),
        "yearsAgo": m40,
        "yes": MessageLookupByLibrary.simpleMessage("Ja"),
        "yesCancel": MessageLookupByLibrary.simpleMessage("Ja, kündigen"),
        "yesConvertToViewer": MessageLookupByLibrary.simpleMessage(
            "Ja, zu \"Beobachter\" ändern"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("Ja, löschen"),
        "yesDiscardChanges":
            MessageLookupByLibrary.simpleMessage("Ja, Änderungen verwerfen"),
        "yesLogout": MessageLookupByLibrary.simpleMessage("Ja, ausloggen"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("Ja, entfernen"),
        "yesRenew": MessageLookupByLibrary.simpleMessage("Ja, erneuern"),
        "you": MessageLookupByLibrary.simpleMessage("Sie"),
        "youAreOnAFamilyPlan":
            MessageLookupByLibrary.simpleMessage("Du bist im Familien-Tarif!"),
        "youAreOnTheLatestVersion": MessageLookupByLibrary.simpleMessage(
            "Sie sind auf der neuesten Version"),
        "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "* Du kannst deinen Speicher maximal verdoppeln"),
        "youCannotDowngradeToThisPlan": MessageLookupByLibrary.simpleMessage(
            "Sie können nicht auf diesen Tarif wechseln"),
        "youCannotShareWithYourself": MessageLookupByLibrary.simpleMessage(
            "Du kannst nicht mit dir selbst teilen"),
        "youDontHaveAnyArchivedItems": MessageLookupByLibrary.simpleMessage(
            "Du hast keine archivierten Elemente."),
        "youHaveSuccessfullyFreedUp": m41,
        "yourAccountHasBeenDeleted": MessageLookupByLibrary.simpleMessage(
            "Dein Benutzerkonto wurde gelöscht"),
        "yourPlanWasSuccessfullyDowngraded":
            MessageLookupByLibrary.simpleMessage(
                "Ihr Tarif wurde erfolgreich heruntergestuft"),
        "yourPlanWasSuccessfullyUpgraded": MessageLookupByLibrary.simpleMessage(
            "Ihr Abo wurde erfolgreich aufgestuft"),
        "yourPurchaseWasSuccessful": MessageLookupByLibrary.simpleMessage(
            "Ihr Einkauf war erfolgreich!"),
        "yourStorageDetailsCouldNotBeFetched":
            MessageLookupByLibrary.simpleMessage(
                "Details zum Speicherplatz konnten nicht abgerufen werden"),
        "yourSubscriptionHasExpired": MessageLookupByLibrary.simpleMessage(
            "Dein Abonnement ist abgelaufen"),
        "yourSubscriptionWasUpdatedSuccessfully":
            MessageLookupByLibrary.simpleMessage(
                "Dein Abonnement wurde erfolgreich aktualisiert."),
        "youveNoDuplicateFilesThatCanBeCleared":
            MessageLookupByLibrary.simpleMessage(
                "Du hast keine Duplikate, die gelöscht werden können"),
        "youveNoFilesInThisAlbumThatCanBeDeleted":
            MessageLookupByLibrary.simpleMessage(
                "Du hast keine Dateien in diesem Album, die gelöscht werden können")
      };
}
