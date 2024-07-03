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

  static String m0(count) =>
      "${Intl.plural(count, one: 'Teilnehmer', other: 'Teilnehmer')} hinzufügen";

  static String m2(count) =>
      "${Intl.plural(count, one: 'Element hinzufügen', other: 'Elemente hinzufügen')}";

  static String m3(storageAmount, endDate) =>
      "Dein ${storageAmount} Add-on ist gültig bis ${endDate}";

  static String m1(count) =>
      "${Intl.plural(count, one: 'Betrachter', other: 'Betrachter')} hinzufügen";

  static String m4(emailOrName) => "Von ${emailOrName} hinzugefügt";

  static String m5(albumName) => "Erfolgreich zu  ${albumName} hinzugefügt";

  static String m6(count) =>
      "${Intl.plural(count, zero: 'Keine Teilnehmer', one: '1 Teilnehmer', other: '${count} Teilnehmer')}";

  static String m7(versionValue) => "Version: ${versionValue}";

  static String m8(freeAmount, storageUnit) =>
      "${freeAmount} ${storageUnit} kostenlos";

  static String m9(paymentProvider) =>
      "Bitte kündigen Sie Ihr aktuelles Abo über ${paymentProvider} zuerst";

  static String m10(user) =>
      "Der Nutzer \"${user}\" wird keine weiteren Fotos zum Album hinzufügen können.\n\nJedoch kann er weiterhin vorhandene Bilder, welche durch ihn hinzugefügt worden sind, wieder entfernen";

  static String m11(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true':
                'Deine Familiengruppe hat bereits ${storageAmountInGb} GB erhalten',
            'false': 'Du hast bereits ${storageAmountInGb} GB erhalten',
            'other': 'Du hast bereits ${storageAmountInGb} GB erhalten!',
          })}";

  static String m12(albumName) =>
      "Kollaborativer Link für ${albumName} erstellt";

  static String m13(familyAdminEmail) =>
      "Bitte kontaktiere <green>${familyAdminEmail}</green> um dein Abo zu verwalten";

  static String m14(provider) =>
      "Bitte kontaktieren Sie uns über support@ente.io, um Ihr ${provider} Abo zu verwalten.";

  static String m15(endpoint) => "Verbunden mit ${endpoint}";

  static String m16(count) =>
      "${Intl.plural(count, one: 'Lösche ${count} Element', other: 'Lösche ${count} Elemente')}";

  static String m17(currentlyDeleting, totalCount) =>
      "Lösche ${currentlyDeleting} / ${totalCount}";

  static String m18(albumName) =>
      "Der öffentliche Link zum Zugriff auf \"${albumName}\" wird entfernt.";

  static String m19(supportEmail) =>
      "Bitte sende eine E-Mail an ${supportEmail} von deiner registrierten E-Mail-Adresse";

  static String m20(count, storageSaved) =>
      "Du hast ${Intl.plural(count, one: '${count} duplizierte Datei', other: '${count} dupliziere Dateien')} gelöscht und (${storageSaved}!) freigegeben";

  static String m21(count, formattedSize) =>
      "${count} Dateien, ${formattedSize} jede";

  static String m22(newEmail) => "E-Mail-Adresse geändert zu ${newEmail}";

  static String m23(email) =>
      "${email} hat kein Ente-Konto.\n\nSende eine Einladung, um Fotos zu teilen.";

  static String m24(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 Datei', other: '${formattedNumber} Dateien')} auf diesem Gerät wurde(n) sicher gespeichert";

  static String m25(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 Datei', other: '${formattedNumber} Dateien')} in diesem Album wurde(n) sicher gespeichert";

  static String m26(storageAmountInGB) =>
      "${storageAmountInGB} GB jedes Mal, wenn sich jemand mit deinem Code für einen bezahlten Tarif anmeldet";

  static String m27(endDate) => "Kostenlose Demo verfügbar bis zum ${endDate}";

  static String m28(count) =>
      "Du kannst immernoch über Ente ${Intl.plural(count, one: 'darauf', other: 'auf sie')} zugreifen, solange du ein aktives Abo hast";

  static String m29(sizeInMBorGB) => "${sizeInMBorGB} freigeben";

  static String m30(count, formattedSize) =>
      "${Intl.plural(count, one: 'Es kann vom Gerät gelöscht werden, um ${formattedSize} freizugeben', other: 'Sie können vom Gerät gelöscht werden, um ${formattedSize} freizugeben')}";

  static String m31(currentlyProcessing, totalCount) =>
      "Verarbeite ${currentlyProcessing} / ${totalCount}";

  static String m32(count) =>
      "${Intl.plural(count, one: '${count} Objekt', other: '${count} Objekte')}";

  static String m33(expiryTime) => "Link läuft am ${expiryTime} ab";

  static String m34(count, formattedCount) =>
      "${Intl.plural(count, zero: 'keine Erinnerungsstücke', one: '${formattedCount} Erinnerung', other: '${formattedCount} Erinnerungsstücke')}";

  static String m35(count) =>
      "${Intl.plural(count, one: 'Element verschieben', other: 'Elemente verschieben')}";

  static String m36(albumName) => "Erfolgreich zu ${albumName} hinzugefügt";

  static String m37(passwordStrengthValue) =>
      "Passwortstärke: ${passwordStrengthValue}";

  static String m38(providerName) =>
      "Bitte kontaktiere den Support von ${providerName}, falls etwas abgebucht wurde";

  static String m39(endDate) =>
      "Kostenlose Testversion gültig bis ${endDate}.\nSie können anschließend ein bezahltes Paket auswählen.";

  static String m40(toEmail) => "Bitte sende uns eine E-Mail an ${toEmail}";

  static String m41(toEmail) => "Bitte sende die Protokolle an ${toEmail}";

  static String m42(storeName) => "Bewerte uns auf ${storeName}";

  static String m43(storageInGB) =>
      "3. Ihr beide erhaltet ${storageInGB} GB* kostenlos";

  static String m44(userEmail) =>
      "${userEmail} wird aus diesem geteilten Album entfernt\n\nAlle von ihnen hinzugefügte Fotos werden ebenfalls aus dem Album entfernt";

  static String m45(endDate) => "Erneuert am ${endDate}";

  static String m46(count) =>
      "${Intl.plural(count, one: '${count} Ergebnis gefunden', other: '${count} Ergebnisse gefunden')}";

  static String m47(count) => "${count} ausgewählt";

  static String m48(count, yourCount) =>
      "${count} ausgewählt (${yourCount} von Ihnen)";

  static String m49(verificationID) =>
      "Hier ist meine Verifizierungs-ID: ${verificationID} für ente.io.";

  static String m50(verificationID) =>
      "Hey, kannst du bestätigen, dass dies deine ente.io Verifizierungs-ID ist: ${verificationID}";

  static String m51(referralCode, referralStorageInGB) =>
      "Ente Weiterempfehlungs-Code: ${referralCode} \n\nEinlösen unter Einstellungen → Allgemein → Weiterempfehlungen, um ${referralStorageInGB} GB kostenlos zu erhalten, sobald Sie einen kostenpflichtigen Tarif abgeschlossen haben\n\nhttps://ente.io";

  static String m52(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Teile mit bestimmten Personen', one: 'Teilen mit 1 Person', other: 'Teilen mit ${numberOfPeople} Personen')}";

  static String m53(emailIDs) => "Geteilt mit ${emailIDs}";

  static String m54(fileType) =>
      "Dieses ${fileType} wird von deinem Gerät gelöscht.";

  static String m55(fileType) =>
      "Diese Datei ist sowohl in Ente als auch auf deinem Gerät.";

  static String m56(fileType) => "Diese Datei wird von Ente gelöscht.";

  static String m57(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m58(
          usedAmount, usedStorageUnit, totalAmount, totalStorageUnit) =>
      "${usedAmount} ${usedStorageUnit} von ${totalAmount} ${totalStorageUnit} verwendet";

  static String m59(id) =>
      "Ihr ${id} ist bereits mit einem anderen Ente-Konto verknüpft.\nWenn Sie Ihre ${id} mit diesem Konto verwenden möchten, kontaktieren Sie bitte unseren Support";

  static String m60(endDate) => "Ihr Abo endet am ${endDate}";

  static String m61(completed, total) =>
      "${completed}/${total} Erinnerungsstücke gesichert";

  static String m62(storageAmountInGB) =>
      "Diese erhalten auch ${storageAmountInGB} GB";

  static String m63(email) => "Dies ist ${email}s Verifizierungs-ID";

  static String m64(count) =>
      "${Intl.plural(count, zero: '', one: '1 Tag', other: '${count} Tage')}";

  static String m65(endDate) => "Gültig bis ${endDate}";

  static String m66(email) => "Verifiziere ${email}";

  static String m67(email) =>
      "Wir haben eine E-Mail an <green>${email}</green> gesendet";

  static String m68(count) =>
      "${Intl.plural(count, one: 'vor einem Jahr', other: 'vor ${count} Jahren')}";

  static String m69(storageSaved) =>
      "Du hast ${storageSaved} erfolgreich freigegeben!";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable": MessageLookupByLibrary.simpleMessage(
            "Eine neue Version von Ente ist verfügbar."),
        "about":
            MessageLookupByLibrary.simpleMessage("Allgemeine Informationen"),
        "account": MessageLookupByLibrary.simpleMessage("Konto"),
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Willkommen zurück!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Ich verstehe, dass ich meine Daten verlieren kann, wenn ich mein Passwort vergesse, da meine Daten <underline>Ende-zu-Ende-verschlüsselt</underline> sind."),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Aktive Sitzungen"),
        "addAName":
            MessageLookupByLibrary.simpleMessage("Füge einen Namen hinzu"),
        "addANewEmail": MessageLookupByLibrary.simpleMessage(
            "Neue E-Mail-Adresse hinzufügen"),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Bearbeiter hinzufügen"),
        "addCollaborators": m0,
        "addFromDevice":
            MessageLookupByLibrary.simpleMessage("Vom Gerät hinzufügen"),
        "addItem": m2,
        "addLocation": MessageLookupByLibrary.simpleMessage("Ort hinzufügen"),
        "addLocationButton": MessageLookupByLibrary.simpleMessage("Hinzufügen"),
        "addMore": MessageLookupByLibrary.simpleMessage("Mehr hinzufügen"),
        "addNew": MessageLookupByLibrary.simpleMessage("Hinzufügen"),
        "addOnPageSubtitle":
            MessageLookupByLibrary.simpleMessage("Details der Add-ons"),
        "addOnValidTill": m3,
        "addOns": MessageLookupByLibrary.simpleMessage("Add-ons"),
        "addPhotos": MessageLookupByLibrary.simpleMessage("Fotos hinzufügen"),
        "addSelected":
            MessageLookupByLibrary.simpleMessage("Auswahl hinzufügen"),
        "addToAlbum":
            MessageLookupByLibrary.simpleMessage("Zum Album hinzufügen"),
        "addToEnte": MessageLookupByLibrary.simpleMessage("Zu Ente hinzufügen"),
        "addToHiddenAlbum": MessageLookupByLibrary.simpleMessage(
            "Zum versteckten Album hinzufügen"),
        "addViewer": MessageLookupByLibrary.simpleMessage("Album teilen"),
        "addViewers": m1,
        "addYourPhotosNow":
            MessageLookupByLibrary.simpleMessage("Füge deine Foto jetzt hinzu"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Hinzugefügt als"),
        "addedBy": m4,
        "addedSuccessfullyTo": m5,
        "addingToFavorites": MessageLookupByLibrary.simpleMessage(
            "Wird zu Favoriten hinzugefügt..."),
        "advanced": MessageLookupByLibrary.simpleMessage("Erweitert"),
        "advancedSettings": MessageLookupByLibrary.simpleMessage("Erweitert"),
        "after1Day": MessageLookupByLibrary.simpleMessage("Nach einem Tag"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("Nach 1 Stunde"),
        "after1Month": MessageLookupByLibrary.simpleMessage("Nach 1 Monat"),
        "after1Week": MessageLookupByLibrary.simpleMessage("Nach 1 Woche"),
        "after1Year": MessageLookupByLibrary.simpleMessage("Nach 1 Jahr"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Besitzer"),
        "albumParticipantsCount": m6,
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
        "androidBiometricHint":
            MessageLookupByLibrary.simpleMessage("Identität verifizieren"),
        "androidBiometricNotRecognized": MessageLookupByLibrary.simpleMessage(
            "Nicht erkannt. Versuchen Sie es erneut."),
        "androidBiometricRequiredTitle":
            MessageLookupByLibrary.simpleMessage("Biometrie erforderlich"),
        "androidBiometricSuccess":
            MessageLookupByLibrary.simpleMessage("Erfolgreich"),
        "androidCancelButton":
            MessageLookupByLibrary.simpleMessage("Abbrechen"),
        "androidDeviceCredentialsRequiredTitle":
            MessageLookupByLibrary.simpleMessage(
                "Geräteanmeldeinformationen erforderlich"),
        "androidDeviceCredentialsSetupDescription":
            MessageLookupByLibrary.simpleMessage(
                "Geräteanmeldeinformationen erforderlich"),
        "androidGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "Auf Ihrem Gerät ist keine biometrische Authentifizierung eingerichtet. Gehen Sie „Einstellungen“ > „Sicherheit“, um die biometrische Authentifizierung hinzuzufügen."),
        "androidIosWebDesktop":
            MessageLookupByLibrary.simpleMessage("Android, iOS, Web, Desktop"),
        "androidSignInTitle": MessageLookupByLibrary.simpleMessage(
            "Authentifizierung erforderlich"),
        "appVersion": m7,
        "appleId": MessageLookupByLibrary.simpleMessage("Apple ID"),
        "apply": MessageLookupByLibrary.simpleMessage("Anwenden"),
        "applyCodeTitle": MessageLookupByLibrary.simpleMessage("Code nutzen"),
        "appstoreSubscription":
            MessageLookupByLibrary.simpleMessage("AppStore Abo"),
        "archive": MessageLookupByLibrary.simpleMessage("Archiv"),
        "archiveAlbum":
            MessageLookupByLibrary.simpleMessage("Album archivieren"),
        "archiving": MessageLookupByLibrary.simpleMessage("Archiviere …"),
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
        "askYourLovedOnesToShare": MessageLookupByLibrary.simpleMessage(
            "Bitte deine Liebsten ums teilen"),
        "atAFalloutShelter": MessageLookupByLibrary.simpleMessage(
            "in einem ehemaligen Luftschutzbunker"),
        "authToChangeEmailVerificationSetting":
            MessageLookupByLibrary.simpleMessage(
                "Bitte Authentifizieren um die E-Mail Bestätigung zu ändern"),
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
        "authenticating":
            MessageLookupByLibrary.simpleMessage("Authentifiziere …"),
        "authenticationFailedPleaseTryAgain": MessageLookupByLibrary.simpleMessage(
            "Authentifizierung fehlgeschlagen, versuchen Sie es bitte erneut"),
        "authenticationSuccessful": MessageLookupByLibrary.simpleMessage(
            "Authentifizierung erfogreich!"),
        "autoCastDialogBody": MessageLookupByLibrary.simpleMessage(
            "Verfügbare Cast-Geräte werden hier angezeigt."),
        "autoCastiOSPermission": MessageLookupByLibrary.simpleMessage(
            "Stelle sicher, dass die Ente-App auf das lokale Netzwerk zugreifen darf. Das kannst du in den Einstellungen unter \"Datenschutz\"."),
        "autoLogoutMessage": MessageLookupByLibrary.simpleMessage(
            "Aufgrund technischer Störungen wurden Sie abgemeldet. Wir entschuldigen uns für die Unannehmlichkeiten."),
        "autoPair":
            MessageLookupByLibrary.simpleMessage("Automatisch verbinden"),
        "autoPairDesc": MessageLookupByLibrary.simpleMessage(
            "Automatisches Verbinden funktioniert nur mit Geräten, die Chromecast unterstützen."),
        "available": MessageLookupByLibrary.simpleMessage("Verfügbar"),
        "availableStorageSpace": m8,
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
        "blackFridaySale":
            MessageLookupByLibrary.simpleMessage("Black-Friday-Aktion"),
        "blog": MessageLookupByLibrary.simpleMessage("Blog"),
        "cachedData": MessageLookupByLibrary.simpleMessage("Daten im Cache"),
        "calculating":
            MessageLookupByLibrary.simpleMessage("Wird berechnet..."),
        "canNotUploadToAlbumsOwnedByOthers":
            MessageLookupByLibrary.simpleMessage(
                "Kann nicht auf Alben anderer Personen hochladen"),
        "canOnlyCreateLinkForFilesOwnedByYou":
            MessageLookupByLibrary.simpleMessage(
                "Sie können nur Links für Dateien erstellen, die Ihnen gehören"),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "Du kannst nur Dateien entfernen, die dir gehören"),
        "cancel": MessageLookupByLibrary.simpleMessage("Abbrechen"),
        "cancelOtherSubscription": m9,
        "cancelSubscription":
            MessageLookupByLibrary.simpleMessage("Abonnement kündigen"),
        "cannotAddMorePhotosAfterBecomingViewer": m10,
        "cannotDeleteSharedFiles": MessageLookupByLibrary.simpleMessage(
            "Konnte geteilte Dateien nicht löschen"),
        "castIPMismatchBody": MessageLookupByLibrary.simpleMessage(
            "Stelle sicher, dass du im selben Netzwerk bist wie der Fernseher."),
        "castIPMismatchTitle": MessageLookupByLibrary.simpleMessage(
            "Album konnte nicht auf den Bildschirm übertragen werden"),
        "castInstruction": MessageLookupByLibrary.simpleMessage(
            "Besuche cast.ente.io auf dem Gerät, das du verbinden möchtest.\n\nGib den unten angegebenen Code ein, um das Album auf deinem Fernseher abzuspielen."),
        "centerPoint": MessageLookupByLibrary.simpleMessage("Mittelpunkt"),
        "changeEmail":
            MessageLookupByLibrary.simpleMessage("E-Mail-Adresse ändern"),
        "changeLocationOfSelectedItems": MessageLookupByLibrary.simpleMessage(
            "Standort der gewählten Elemente ändern?"),
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
        "checkStatus":
            MessageLookupByLibrary.simpleMessage("Status überprüfen"),
        "checking": MessageLookupByLibrary.simpleMessage("Wird geprüft..."),
        "claimFreeStorage":
            MessageLookupByLibrary.simpleMessage("Freien Speicher einlösen"),
        "claimMore": MessageLookupByLibrary.simpleMessage("Mehr einlösen!"),
        "claimed": MessageLookupByLibrary.simpleMessage("Eingelöst"),
        "claimedStorageSoFar": m11,
        "cleanUncategorized":
            MessageLookupByLibrary.simpleMessage("Unkategorisiert leeren"),
        "cleanUncategorizedDescription": MessageLookupByLibrary.simpleMessage(
            "Entferne alle Dateien von \"Unkategorisiert\" die in anderen Alben vorhanden sind"),
        "clearCaches": MessageLookupByLibrary.simpleMessage("Cache löschen"),
        "clearIndexes": MessageLookupByLibrary.simpleMessage("Indexe löschen"),
        "click": MessageLookupByLibrary.simpleMessage("• Klick"),
        "clickOnTheOverflowMenu": MessageLookupByLibrary.simpleMessage(
            "• Klicken Sie auf das Überlaufmenü"),
        "close": MessageLookupByLibrary.simpleMessage("Schließen"),
        "clubByCaptureTime": MessageLookupByLibrary.simpleMessage(
            "Nach Aufnahmezeit gruppieren"),
        "clubByFileName":
            MessageLookupByLibrary.simpleMessage("Nach Dateiname gruppieren"),
        "clusteringProgress":
            MessageLookupByLibrary.simpleMessage("Fortschritt beim Clustering"),
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("Code eingelöst"),
        "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Code in Zwischenablage kopiert"),
        "codeUsedByYou":
            MessageLookupByLibrary.simpleMessage("Von dir benutzter Code"),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Erstelle einen Link, mit dem andere Fotos in dem geteilten Album sehen und selbst welche hinzufügen können - ohne dass sie die ein Ente-Konto oder die App benötigen. Ideal um gemeinsam Fotos von Events zu sammeln."),
        "collaborativeLink":
            MessageLookupByLibrary.simpleMessage("Gemeinschaftlicher Link"),
        "collaborativeLinkCreatedFor": m12,
        "collaborator": MessageLookupByLibrary.simpleMessage("Bearbeiter"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Bearbeiter können Fotos & Videos zu dem geteilten Album hinzufügen."),
        "collageLayout": MessageLookupByLibrary.simpleMessage("Layout"),
        "collageSaved": MessageLookupByLibrary.simpleMessage(
            "Collage in Galerie gespeichert"),
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
        "connectToDevice":
            MessageLookupByLibrary.simpleMessage("Mit Gerät verbinden"),
        "contactFamilyAdmin": m13,
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("Support kontaktieren"),
        "contactToManageSubscription": m14,
        "contacts": MessageLookupByLibrary.simpleMessage("Kontakte"),
        "contents": MessageLookupByLibrary.simpleMessage("Inhalte"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("Weiter"),
        "continueOnFreeTrial": MessageLookupByLibrary.simpleMessage(
            "Mit kostenloser Testversion fortfahren"),
        "convertToAlbum":
            MessageLookupByLibrary.simpleMessage("Konvertiere zum Album"),
        "copyEmailAddress":
            MessageLookupByLibrary.simpleMessage("E-Mail-Adresse kopieren"),
        "copyLink": MessageLookupByLibrary.simpleMessage("Link kopieren"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Kopiere diesen Code\nin deine Authentifizierungs-App"),
        "couldNotBackUpTryLater": MessageLookupByLibrary.simpleMessage(
            "Deine Daten konnten nicht gesichert werden.\nWir versuchen es später erneut."),
        "couldNotFreeUpSpace": MessageLookupByLibrary.simpleMessage(
            "Konnte Speicherplatz nicht freigeben"),
        "couldNotUpdateSubscription": MessageLookupByLibrary.simpleMessage(
            "Abo konnte nicht aktualisiert werden"),
        "count": MessageLookupByLibrary.simpleMessage("Anzahl"),
        "crashReporting":
            MessageLookupByLibrary.simpleMessage("Absturzbericht"),
        "create": MessageLookupByLibrary.simpleMessage("Erstellen"),
        "createAccount":
            MessageLookupByLibrary.simpleMessage("Konto erstellen"),
        "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
            "Drücke lange um Fotos auszuwählen und klicke + um ein Album zu erstellen"),
        "createCollaborativeLink": MessageLookupByLibrary.simpleMessage(
            "Gemeinschaftlichen Link erstellen"),
        "createCollage":
            MessageLookupByLibrary.simpleMessage("Collage erstellen"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("Neues Konto erstellen"),
        "createOrSelectAlbum": MessageLookupByLibrary.simpleMessage(
            "Album erstellen oder auswählen"),
        "createPublicLink":
            MessageLookupByLibrary.simpleMessage("Öffentlichen Link erstellen"),
        "creatingLink":
            MessageLookupByLibrary.simpleMessage("Erstelle Link..."),
        "criticalUpdateAvailable": MessageLookupByLibrary.simpleMessage(
            "Kritisches Update ist verfügbar!"),
        "crop": MessageLookupByLibrary.simpleMessage("Zuschneiden"),
        "currentUsageIs":
            MessageLookupByLibrary.simpleMessage("Aktuell genutzt werden "),
        "custom": MessageLookupByLibrary.simpleMessage("Benutzerdefiniert"),
        "customEndpoint": m15,
        "darkTheme": MessageLookupByLibrary.simpleMessage("Dunkel"),
        "dayToday": MessageLookupByLibrary.simpleMessage("Heute"),
        "dayYesterday": MessageLookupByLibrary.simpleMessage("Gestern"),
        "decrypting":
            MessageLookupByLibrary.simpleMessage("Wird entschlüsselt..."),
        "decryptingVideo":
            MessageLookupByLibrary.simpleMessage("Entschlüssele Video …"),
        "deduplicateFiles":
            MessageLookupByLibrary.simpleMessage("Dateien duplizieren"),
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
        "deleteAll": MessageLookupByLibrary.simpleMessage("Alle löschen"),
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
            "Dieses Konto ist mit anderen Ente-Apps verknüpft, falls du welche verwendest. Deine hochgeladenen Daten werden in allen Ente-Apps zur Löschung vorgemerkt und dein Konto wird endgültig gelöscht."),
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
            MessageLookupByLibrary.simpleMessage("Von Ente löschen"),
        "deleteItemCount": m16,
        "deleteLocation":
            MessageLookupByLibrary.simpleMessage("Standort löschen"),
        "deletePhotos": MessageLookupByLibrary.simpleMessage("Fotos löschen"),
        "deleteProgress": m17,
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
        "descriptions": MessageLookupByLibrary.simpleMessage("Beschreibungen"),
        "deselectAll": MessageLookupByLibrary.simpleMessage("Alle abwählen"),
        "designedToOutlive":
            MessageLookupByLibrary.simpleMessage("Entwickelt um zu bewahren"),
        "details": MessageLookupByLibrary.simpleMessage("Details"),
        "developerSettings":
            MessageLookupByLibrary.simpleMessage("Entwicklereinstellungen"),
        "developerSettingsWarning": MessageLookupByLibrary.simpleMessage(
            "Bist du sicher, dass du Entwicklereinstellungen bearbeiten willst?"),
        "deviceCodeHint": MessageLookupByLibrary.simpleMessage("Code eingeben"),
        "deviceFilesAutoUploading": MessageLookupByLibrary.simpleMessage(
            "Dateien, die zu diesem Album hinzugefügt werden, werden automatisch zu Ente hochgeladen."),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
            "Verhindern, dass der Bildschirm gesperrt wird, während die App im Vordergrund ist und eine Sicherung läuft. Das ist normalerweise nicht notwendig, kann aber dabei helfen, große Uploads wie einen Erstimport schneller abzuschließen."),
        "deviceNotFound":
            MessageLookupByLibrary.simpleMessage("Gerät nicht gefunden"),
        "didYouKnow": MessageLookupByLibrary.simpleMessage("Schon gewusst?"),
        "disableAutoLock": MessageLookupByLibrary.simpleMessage(
            "Automatische Sperre deaktivieren"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Zuschauer können weiterhin Screenshots oder mit anderen externen Programmen Kopien der Bilder machen."),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Bitte beachten Sie:"),
        "disableLinkMessage": m18,
        "disableTwofactor": MessageLookupByLibrary.simpleMessage(
            "Zweiten Faktor (2FA) deaktivieren"),
        "disablingTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Zwei-Faktor-Authentifizierung (2FA) wird deaktiviert..."),
        "discord": MessageLookupByLibrary.simpleMessage("Discord"),
        "dismiss": MessageLookupByLibrary.simpleMessage("Verwerfen"),
        "distanceInKMUnit": MessageLookupByLibrary.simpleMessage("km"),
        "doNotSignOut":
            MessageLookupByLibrary.simpleMessage("Melde dich nicht ab"),
        "doThisLater": MessageLookupByLibrary.simpleMessage("Später erledigen"),
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
        "dropSupportEmail": m19,
        "duplicateFileCountWithStorageSaved": m20,
        "duplicateItemsGroup": m21,
        "edit": MessageLookupByLibrary.simpleMessage("Bearbeiten"),
        "editLocation":
            MessageLookupByLibrary.simpleMessage("Standort bearbeiten"),
        "editLocationTagTitle":
            MessageLookupByLibrary.simpleMessage("Standort bearbeiten"),
        "editsSaved":
            MessageLookupByLibrary.simpleMessage("Änderungen gespeichert"),
        "editsToLocationWillOnlyBeSeenWithinEnte":
            MessageLookupByLibrary.simpleMessage(
                "Edits to location will only be seen within Ente"),
        "eligible": MessageLookupByLibrary.simpleMessage("zulässig"),
        "email": MessageLookupByLibrary.simpleMessage("E-Mail"),
        "emailChangedTo": m22,
        "emailNoEnteAccount": m23,
        "emailVerificationToggle":
            MessageLookupByLibrary.simpleMessage("E-Mail-Verifizierung"),
        "emailYourLogs": MessageLookupByLibrary.simpleMessage(
            "Protokolle per E-Mail senden"),
        "empty": MessageLookupByLibrary.simpleMessage("Leeren"),
        "emptyTrash":
            MessageLookupByLibrary.simpleMessage("Papierkorb leeren?"),
        "enableMaps": MessageLookupByLibrary.simpleMessage("Karten aktivieren"),
        "enableMapsDesc": MessageLookupByLibrary.simpleMessage(
            "Dies zeigt Ihre Fotos auf einer Weltkarte.\n\nDiese Karte wird von OpenStreetMap gehostet und die genauen Standorte Ihrer Fotos werden niemals geteilt.\n\nSie können diese Funktion jederzeit in den Einstellungen deaktivieren."),
        "encryptingBackup":
            MessageLookupByLibrary.simpleMessage("Verschlüssele Sicherung …"),
        "encryption": MessageLookupByLibrary.simpleMessage("Verschlüsselung"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Verschlüsselungscode"),
        "endpointUpdatedMessage": MessageLookupByLibrary.simpleMessage(
            "Endpunkt erfolgreich geändert"),
        "endtoendEncryptedByDefault": MessageLookupByLibrary.simpleMessage(
            "Automatisch Ende-zu-Ende-verschlüsselt"),
        "enteCanEncryptAndPreserveFilesOnlyIfYouGrant":
            MessageLookupByLibrary.simpleMessage(
                "Ente kann Dateien nur verschlüsseln und sichern, wenn du den Zugriff darauf gewährst"),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(""),
        "enteSubscriptionPitch": MessageLookupByLibrary.simpleMessage(
            "Ente sichert deine Erinnerungen, sodass sie dir nie verloren gehen, selbst wenn du dein Gerät verlierst."),
        "enteSubscriptionShareWithFamily": MessageLookupByLibrary.simpleMessage(
            "Deine Familie kann zu deinem Abo hinzugefügt werden."),
        "enterAlbumName":
            MessageLookupByLibrary.simpleMessage("Albumname eingeben"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Code eingeben"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
            "Gib den Code deines Freundes ein, damit sie beide kostenlosen Speicherplatz erhalten"),
        "enterEmail": MessageLookupByLibrary.simpleMessage("E-Mail eingeben"),
        "enterFileName":
            MessageLookupByLibrary.simpleMessage("Dateinamen eingeben"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Gib ein neues Passwort ein, mit dem wir deine Daten verschlüsseln können"),
        "enterPassword":
            MessageLookupByLibrary.simpleMessage("Passwort eingeben"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Gib ein Passwort ein, mit dem wir deine Daten verschlüsseln können"),
        "enterPersonName":
            MessageLookupByLibrary.simpleMessage("Namen der Person eingeben"),
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
        "error": MessageLookupByLibrary.simpleMessage("Fehler"),
        "everywhere": MessageLookupByLibrary.simpleMessage("überall"),
        "exif": MessageLookupByLibrary.simpleMessage("EXIF"),
        "existingUser":
            MessageLookupByLibrary.simpleMessage("Existierender Benutzer"),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
            "Dieser Link ist abgelaufen. Bitte wählen Sie ein neues Ablaufdatum oder deaktivieren Sie das Ablaufdatum des Links."),
        "exportLogs":
            MessageLookupByLibrary.simpleMessage("Protokolle exportieren"),
        "exportYourData":
            MessageLookupByLibrary.simpleMessage("Daten exportieren"),
        "faceRecognition":
            MessageLookupByLibrary.simpleMessage("Gesichtserkennung"),
        "faces": MessageLookupByLibrary.simpleMessage("Gesichter"),
        "failedToApplyCode": MessageLookupByLibrary.simpleMessage(
            "Der Code konnte nicht aktiviert werden"),
        "failedToCancel":
            MessageLookupByLibrary.simpleMessage("Kündigung fehlgeschlagen"),
        "failedToDownloadVideo": MessageLookupByLibrary.simpleMessage(
            "Herunterladen des Videos fehlgeschlagen"),
        "failedToFetchOriginalForEdit": MessageLookupByLibrary.simpleMessage(
            "Fehler beim Abrufen des Originals zur Bearbeitung"),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "Die Weiterempfehlungs-Details können nicht abgerufen werden. Bitte versuche es später erneut."),
        "failedToLoadAlbums": MessageLookupByLibrary.simpleMessage(
            "Laden der Alben fehlgeschlagen"),
        "failedToRenew":
            MessageLookupByLibrary.simpleMessage("Erneuern fehlgeschlagen"),
        "failedToVerifyPaymentStatus": MessageLookupByLibrary.simpleMessage(
            "Überprüfung des Zahlungsstatus fehlgeschlagen"),
        "familyPlanOverview": MessageLookupByLibrary.simpleMessage(
            "Füge kostenlos 5 Familienmitglieder zu deinem bestehenden Abo hinzu.\n\nJedes Mitglied bekommt seinen eigenen privaten Bereich und kann die Dateien der anderen nur sehen, wenn sie geteilt werden.\n\nFamilien-Abos stehen Nutzern mit einem Bezahltarif zur Verfügung.\n\nMelde dich jetzt an, um loszulegen!"),
        "familyPlanPortalTitle":
            MessageLookupByLibrary.simpleMessage("Familie"),
        "familyPlans": MessageLookupByLibrary.simpleMessage("Familientarif"),
        "faq": MessageLookupByLibrary.simpleMessage("Häufig gestellte Fragen"),
        "faqs": MessageLookupByLibrary.simpleMessage("FAQs"),
        "favorite": MessageLookupByLibrary.simpleMessage("Favorit"),
        "feedback": MessageLookupByLibrary.simpleMessage("Rückmeldung"),
        "fileFailedToSaveToGallery": MessageLookupByLibrary.simpleMessage(
            "Fehler beim Speichern der Datei in der Galerie"),
        "fileInfoAddDescHint":
            MessageLookupByLibrary.simpleMessage("Beschreibung hinzufügen …"),
        "fileSavedToGallery": MessageLookupByLibrary.simpleMessage(
            "Datei in Galerie gespeichert"),
        "fileTypes": MessageLookupByLibrary.simpleMessage("Dateitypen"),
        "fileTypesAndNames":
            MessageLookupByLibrary.simpleMessage("Dateitypen und -namen"),
        "filesBackedUpFromDevice": m24,
        "filesBackedUpInAlbum": m25,
        "filesDeleted":
            MessageLookupByLibrary.simpleMessage("Dateien gelöscht"),
        "filesSavedToGallery": MessageLookupByLibrary.simpleMessage(
            "Dateien in Galerie gespeichert"),
        "findPeopleByName": MessageLookupByLibrary.simpleMessage(
            "Finde Personen schnell nach Namen"),
        "flip": MessageLookupByLibrary.simpleMessage("Spiegeln"),
        "forYourMemories":
            MessageLookupByLibrary.simpleMessage("Als Erinnerung"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Passwort vergessen"),
        "foundFaces":
            MessageLookupByLibrary.simpleMessage("Gesichter gefunden"),
        "freeStorageClaimed": MessageLookupByLibrary.simpleMessage(
            "Kostenlos hinzugefügter Speicherplatz"),
        "freeStorageOnReferralSuccess": m26,
        "freeStorageUsable": MessageLookupByLibrary.simpleMessage(
            "Freier Speicherplatz nutzbar"),
        "freeTrial":
            MessageLookupByLibrary.simpleMessage("Kostenlose Testphase"),
        "freeTrialValidTill": m27,
        "freeUpAccessPostDelete": m28,
        "freeUpAmount": m29,
        "freeUpDeviceSpace":
            MessageLookupByLibrary.simpleMessage("Gerätespeicher freiräumen"),
        "freeUpDeviceSpaceDesc": MessageLookupByLibrary.simpleMessage(
            "Spare Speicherplatz auf deinem Gerät, indem du Dateien löschst, die bereits gesichert wurden."),
        "freeUpSpace":
            MessageLookupByLibrary.simpleMessage("Speicherplatz freigeben"),
        "freeUpSpaceSaving": m30,
        "galleryMemoryLimitInfo": MessageLookupByLibrary.simpleMessage(
            "Bis zu 1000 Erinnerungsstücke angezeigt in der Galerie"),
        "general": MessageLookupByLibrary.simpleMessage("Allgemein"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Generierung von Verschlüsselungscodes..."),
        "genericProgress": m31,
        "goToSettings":
            MessageLookupByLibrary.simpleMessage("Zu den Einstellungen"),
        "googlePlayId": MessageLookupByLibrary.simpleMessage("Google Play ID"),
        "grantFullAccessPrompt": MessageLookupByLibrary.simpleMessage(
            "Bitte gewähre Zugang zu allen Fotos in der Einstellungen App"),
        "grantPermission":
            MessageLookupByLibrary.simpleMessage("Zugriff gewähren"),
        "groupNearbyPhotos": MessageLookupByLibrary.simpleMessage(
            "Fotos in der Nähe gruppieren"),
        "hearUsExplanation": MessageLookupByLibrary.simpleMessage(
            "Wir tracken keine App-Installationen. Es würde uns jedoch helfen, wenn du uns mitteilst, wie du von uns erfahren hast!"),
        "hearUsWhereTitle": MessageLookupByLibrary.simpleMessage(
            "Wie hast du von Ente erfahren? (optional)"),
        "help": MessageLookupByLibrary.simpleMessage("Hilfe"),
        "hidden": MessageLookupByLibrary.simpleMessage("Versteckt"),
        "hide": MessageLookupByLibrary.simpleMessage("Ausblenden"),
        "hiding": MessageLookupByLibrary.simpleMessage("Verstecken..."),
        "hostedAtOsmFrance":
            MessageLookupByLibrary.simpleMessage("Gehostet bei OSM France"),
        "howItWorks":
            MessageLookupByLibrary.simpleMessage("So funktioniert\'s"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "Bitte sie, auf den Einstellungs Bildschirm ihre E-Mail-Adresse lange anzuklicken und zu überprüfen, dass die IDs auf beiden Geräten übereinstimmen."),
        "iOSGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "Auf Ihrem Gerät ist keine biometrische Authentifizierung eingerichtet. Bitte aktivieren Sie entweder Touch ID oder Face ID auf Ihrem Telefon."),
        "iOSLockOut": MessageLookupByLibrary.simpleMessage(
            "Die biometrische Authentifizierung ist deaktiviert. Bitte sperren und entsperren Sie Ihren Bildschirm, um sie zu aktivieren."),
        "iOSOkButton": MessageLookupByLibrary.simpleMessage("OK"),
        "ignoreUpdate": MessageLookupByLibrary.simpleMessage("Ignorieren"),
        "ignoredFolderUploadReason": MessageLookupByLibrary.simpleMessage(
            "Ein paar Dateien in diesem Album werden nicht hochgeladen, weil sie in der Vergangenheit schonmal aus Ente gelöscht wurden."),
        "importing": MessageLookupByLibrary.simpleMessage("Importiert...."),
        "incorrectCode": MessageLookupByLibrary.simpleMessage("Falscher Code"),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Falsches Passwort"),
        "incorrectRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Falscher Wiederherstellungs-Schlüssel"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "Der eingegebene Schlüssel ist ungültig"),
        "incorrectRecoveryKeyTitle": MessageLookupByLibrary.simpleMessage(
            "Falscher Wiederherstellungs-Schlüssel"),
        "indexedItems":
            MessageLookupByLibrary.simpleMessage("Indizierte Elemente"),
        "indexingIsPaused": MessageLookupByLibrary.simpleMessage(
            "Die Indizierung ist unterbrochen. Sie wird automatisch fortgesetzt, wenn das Gerät bereit ist."),
        "insecureDevice":
            MessageLookupByLibrary.simpleMessage("Unsicheres Gerät"),
        "installManually":
            MessageLookupByLibrary.simpleMessage("Manuell installieren"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("Ungültige E-Mail-Adresse"),
        "invalidEndpoint":
            MessageLookupByLibrary.simpleMessage("Ungültiger Endpunkt"),
        "invalidEndpointMessage": MessageLookupByLibrary.simpleMessage(
            "Der eingegebene Endpunkt ist ungültig. Gib einen gültigen Endpunkt ein und versuch es nochmal."),
        "invalidKey":
            MessageLookupByLibrary.simpleMessage("Ungültiger Schlüssel"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Der von Ihnen eingegebene Wiederherstellungsschlüssel ist nicht gültig. Bitte stellen Sie sicher das aus 24 Wörtern zusammen gesetzt ist und jedes dieser Worte richtig geschrieben wurde.\n\nSollten Sie den Wiederherstellungscode eingegeben haben, stellen Sie bitte sicher, dass dieser 64 Worte lang ist und ebenfall richtig geschrieben wurde."),
        "invite": MessageLookupByLibrary.simpleMessage("Einladen"),
        "inviteToEnte":
            MessageLookupByLibrary.simpleMessage("Zu Ente einladen"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Lade deine Freunde ein"),
        "inviteYourFriendsToEnte": MessageLookupByLibrary.simpleMessage(
            "Lade deine Freunde zu Ente ein"),
        "itLooksLikeSomethingWentWrongPleaseRetryAfterSome":
            MessageLookupByLibrary.simpleMessage(
                "Etwas ist schiefgelaufen. Bitte versuche es später noch einmal. Sollte der Fehler weiter bestehen, kontaktiere unser Supportteam."),
        "itemCount": m32,
        "itemsShowTheNumberOfDaysRemainingBeforePermanentDeletion":
            MessageLookupByLibrary.simpleMessage(
                "Elemente zeigen die Anzahl der Tage bis zum dauerhaften Löschen an"),
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "Ausgewählte Elemente werden aus diesem Album entfernt"),
        "joinDiscord":
            MessageLookupByLibrary.simpleMessage("Discord beitreten"),
        "keepPhotos": MessageLookupByLibrary.simpleMessage("Fotos behalten"),
        "kiloMeterUnit": MessageLookupByLibrary.simpleMessage("km"),
        "kindlyHelpUsWithThisInformation":
            MessageLookupByLibrary.simpleMessage("Bitte gib diese Daten ein"),
        "language": MessageLookupByLibrary.simpleMessage("Sprache"),
        "lastUpdated":
            MessageLookupByLibrary.simpleMessage("Zuletzt aktualisiert"),
        "leave": MessageLookupByLibrary.simpleMessage("Verlassen"),
        "leaveAlbum": MessageLookupByLibrary.simpleMessage("Album verlassen"),
        "leaveFamily":
            MessageLookupByLibrary.simpleMessage("Familienabo verlassen"),
        "leaveSharedAlbum":
            MessageLookupByLibrary.simpleMessage("Geteiltes Album verlassen?"),
        "left": MessageLookupByLibrary.simpleMessage("Links"),
        "light": MessageLookupByLibrary.simpleMessage("Hell"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("Hell"),
        "linkCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Link in Zwischenablage kopiert"),
        "linkDeviceLimit": MessageLookupByLibrary.simpleMessage("Geräte Limit"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Aktiviert"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Abgelaufen"),
        "linkExpiresOn": m33,
        "linkExpiry":
            MessageLookupByLibrary.simpleMessage("Ablaufdatum des Links"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("Link ist abgelaufen"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Niemals"),
        "livePhotos": MessageLookupByLibrary.simpleMessage("Live-Fotos"),
        "loadMessage1": MessageLookupByLibrary.simpleMessage(
            "Du kannst dein Abonnement mit deiner Familie teilen"),
        "loadMessage2": MessageLookupByLibrary.simpleMessage(
            "Wir haben bereits mehr als 30 Millionen Erinnerungsstücke gesichert"),
        "loadMessage3": MessageLookupByLibrary.simpleMessage(
            "Wir behalten 3 Kopien Ihrer Daten, eine in einem unterirdischen Schutzbunker"),
        "loadMessage4": MessageLookupByLibrary.simpleMessage(
            "Alle unsere Apps sind Open-Source"),
        "loadMessage5": MessageLookupByLibrary.simpleMessage(
            "Unser Quellcode und unsere Kryptografie wurden extern geprüft"),
        "loadMessage6": MessageLookupByLibrary.simpleMessage(
            "Du kannst Links zu deinen Alben mit deinen Geliebten teilen"),
        "loadMessage7": MessageLookupByLibrary.simpleMessage(
            "Unsere mobilen Apps laufen im Hintergrund, um neue Fotos zu verschlüsseln und zu sichern"),
        "loadMessage8": MessageLookupByLibrary.simpleMessage(
            "web.ente.io hat einen Spitzen-Uploader"),
        "loadMessage9": MessageLookupByLibrary.simpleMessage(
            "Wir verwenden Xchacha20Poly1305, um Ihre Daten sicher zu verschlüsseln"),
        "loadingExifData":
            MessageLookupByLibrary.simpleMessage("Lade Exif-Daten..."),
        "loadingGallery":
            MessageLookupByLibrary.simpleMessage("Lade Galerie …"),
        "loadingMessage":
            MessageLookupByLibrary.simpleMessage("Fotos werden geladen..."),
        "loadingModel":
            MessageLookupByLibrary.simpleMessage("Lade Modelle herunter..."),
        "localGallery": MessageLookupByLibrary.simpleMessage("Lokale Galerie"),
        "location": MessageLookupByLibrary.simpleMessage("Standort"),
        "locationName": MessageLookupByLibrary.simpleMessage("Standortname"),
        "locationTagFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "Ein Standort-Tag gruppiert alle Fotos, die in einem Radius eines Fotos aufgenommen wurden"),
        "locations": MessageLookupByLibrary.simpleMessage("Orte"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Sperren"),
        "lockScreenEnablePreSteps": MessageLookupByLibrary.simpleMessage(
            "Um den Sperrbildschirm zu aktivieren, legen Sie bitte den Geräte-Passcode oder die Bildschirmsperre in den Systemeinstellungen fest."),
        "lockscreen": MessageLookupByLibrary.simpleMessage("Sperrbildschirm"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Anmelden"),
        "loggingOut": MessageLookupByLibrary.simpleMessage("Abmeldung..."),
        "loginSessionExpired":
            MessageLookupByLibrary.simpleMessage("Sitzung abgelaufen"),
        "loginSessionExpiredDetails": MessageLookupByLibrary.simpleMessage(
            "Deine Sitzung ist abgelaufen. Bitte melde Dich erneut an."),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "Mit dem Klick auf \"Anmelden\" stimme ich den <u-terms>Nutzungsbedingungen</u-terms> und der <u-policy>Datenschutzerklärung</u-policy> zu"),
        "logout": MessageLookupByLibrary.simpleMessage("Ausloggen"),
        "logsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Dies wird über Logs gesendet, um uns zu helfen, Ihr Problem zu beheben. Bitte beachten Sie, dass Dateinamen aufgenommen werden, um Probleme mit bestimmten Dateien zu beheben."),
        "longPressAnEmailToVerifyEndToEndEncryption":
            MessageLookupByLibrary.simpleMessage(
                "Lange auf eine E-Mail drücken, um die Ende-zu-Ende-Verschlüsselung zu überprüfen."),
        "longpressOnAnItemToViewInFullscreen": MessageLookupByLibrary.simpleMessage(
            "Drücken Sie lange auf ein Element, um es im Vollbildmodus anzuzeigen"),
        "lostDevice": MessageLookupByLibrary.simpleMessage("Gerät verloren?"),
        "machineLearning":
            MessageLookupByLibrary.simpleMessage("Maschinelles Lernen"),
        "magicSearch": MessageLookupByLibrary.simpleMessage("Magische Suche"),
        "manage": MessageLookupByLibrary.simpleMessage("Verwalten"),
        "manageDeviceStorage":
            MessageLookupByLibrary.simpleMessage("Gerätespeicher verwalten"),
        "manageFamily":
            MessageLookupByLibrary.simpleMessage("Familiengruppe verwalten"),
        "manageLink": MessageLookupByLibrary.simpleMessage("Link verwalten"),
        "manageParticipants": MessageLookupByLibrary.simpleMessage("Verwalten"),
        "manageSubscription":
            MessageLookupByLibrary.simpleMessage("Abonnement verwalten"),
        "manualPairDesc": MessageLookupByLibrary.simpleMessage(
            "\"Mit PIN verbinden\" funktioniert mit jedem Bildschirm, auf dem du dein Album sehen möchtest."),
        "map": MessageLookupByLibrary.simpleMessage("Karte"),
        "maps": MessageLookupByLibrary.simpleMessage("Karten"),
        "mastodon": MessageLookupByLibrary.simpleMessage("Mastodon"),
        "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
        "memoryCount": m34,
        "merchandise": MessageLookupByLibrary.simpleMessage("Merchandise"),
        "mlIndexingDescription": MessageLookupByLibrary.simpleMessage(
            "Bitte beachten Sie, dass Machine Learning zu einem höheren Bandbreiten- und Batterieverbrauch führt, bis alle Elemente indiziert sind."),
        "mobileWebDesktop":
            MessageLookupByLibrary.simpleMessage("Mobil, Web, Desktop"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Mittel"),
        "modifyYourQueryOrTrySearchingFor":
            MessageLookupByLibrary.simpleMessage(
                "Ändere deine Suchanfrage oder suche nach"),
        "moments": MessageLookupByLibrary.simpleMessage("Momente"),
        "monthly": MessageLookupByLibrary.simpleMessage("Monatlich"),
        "moveItem": m35,
        "moveToAlbum":
            MessageLookupByLibrary.simpleMessage("Zum Album verschieben"),
        "moveToHiddenAlbum": MessageLookupByLibrary.simpleMessage(
            "Zu verstecktem Album verschieben"),
        "movedSuccessfullyTo": m36,
        "movedToTrash": MessageLookupByLibrary.simpleMessage(
            "In den Papierkorb verschoben"),
        "movingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Verschiebe Dateien in Album..."),
        "name": MessageLookupByLibrary.simpleMessage("Name"),
        "networkConnectionRefusedErr": MessageLookupByLibrary.simpleMessage(
            "Ente ist im Moment nicht erreichbar. Bitte versuchen Sie es später erneut. Sollte das Problem bestehen bleiben, wenden Sie sich bitte an den Support."),
        "networkHostLookUpErr": MessageLookupByLibrary.simpleMessage(
            "Ente ist im Moment nicht erreichbar. Bitte überprüfen Sie Ihre Netzwerkeinstellungen. Sollte das Problem bestehen bleiben, wenden Sie sich bitte an den Support."),
        "never": MessageLookupByLibrary.simpleMessage("Niemals"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Neues Album"),
        "newToEnte": MessageLookupByLibrary.simpleMessage("Neu bei Ente"),
        "newest": MessageLookupByLibrary.simpleMessage("Zuletzt"),
        "no": MessageLookupByLibrary.simpleMessage("Nein"),
        "noAlbumsSharedByYouYet": MessageLookupByLibrary.simpleMessage(
            "Noch keine Alben von dir geteilt"),
        "noDeviceFound":
            MessageLookupByLibrary.simpleMessage("Kein Gerät gefunden"),
        "noDeviceLimit": MessageLookupByLibrary.simpleMessage("Keins"),
        "noDeviceThatCanBeDeleted": MessageLookupByLibrary.simpleMessage(
            "Du hast keine Dateien auf diesem Gerät, die gelöscht werden können"),
        "noDuplicates":
            MessageLookupByLibrary.simpleMessage("✨ Keine Duplikate"),
        "noExifData": MessageLookupByLibrary.simpleMessage("Keine Exif-Daten"),
        "noHiddenPhotosOrVideos": MessageLookupByLibrary.simpleMessage(
            "Keine versteckten Fotos oder Videos"),
        "noImagesWithLocation":
            MessageLookupByLibrary.simpleMessage("Keine Bilder mit Standort"),
        "noInternetConnection":
            MessageLookupByLibrary.simpleMessage("Keine Internetverbindung"),
        "noPhotosAreBeingBackedUpRightNow":
            MessageLookupByLibrary.simpleMessage(
                "Momentan werden keine Fotos gesichert"),
        "noPhotosFoundHere":
            MessageLookupByLibrary.simpleMessage("Keine Fotos gefunden"),
        "noRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Kein Wiederherstellungs-Schlüssel?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "Aufgrund unseres Ende-zu-Ende-Verschlüsselungsprotokolls können deine Daten nicht ohne dein Passwort oder deinen Wiederherstellungs-Schlüssel entschlüsselt werden"),
        "noResults": MessageLookupByLibrary.simpleMessage("Keine Ergebnisse"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("Keine Ergebnisse gefunden"),
        "nothingSharedWithYouYet":
            MessageLookupByLibrary.simpleMessage("Noch nichts mit Dir geteilt"),
        "nothingToSeeHere": MessageLookupByLibrary.simpleMessage(
            "Hier gibt es nichts zu sehen! 👀"),
        "notifications":
            MessageLookupByLibrary.simpleMessage("Benachrichtigungen"),
        "ok": MessageLookupByLibrary.simpleMessage("Ok"),
        "onDevice": MessageLookupByLibrary.simpleMessage("Auf dem Gerät"),
        "onEnte": MessageLookupByLibrary.simpleMessage(
            "Auf <branding>ente</branding>"),
        "oops": MessageLookupByLibrary.simpleMessage("Hoppla"),
        "oopsCouldNotSaveEdits": MessageLookupByLibrary.simpleMessage(
            "Hoppla, die Änderungen konnten nicht gespeichert werden"),
        "oopsSomethingWentWrong": MessageLookupByLibrary.simpleMessage(
            "Ups. Leider ist ein Fehler aufgetreten"),
        "openSettings":
            MessageLookupByLibrary.simpleMessage("Öffne Einstellungen"),
        "openTheItem": MessageLookupByLibrary.simpleMessage("• Element öffnen"),
        "openstreetmapContributors":
            MessageLookupByLibrary.simpleMessage("OpenStreetMap-Beitragende"),
        "optionalAsShortAsYouLike": MessageLookupByLibrary.simpleMessage(
            "Bei Bedarf auch so kurz wie Sie wollen..."),
        "orPickAnExistingOne": MessageLookupByLibrary.simpleMessage(
            "Oder eine Vorherige auswählen"),
        "pair": MessageLookupByLibrary.simpleMessage("Koppeln"),
        "pairWithPin":
            MessageLookupByLibrary.simpleMessage("Mit PIN verbinden"),
        "pairingComplete": MessageLookupByLibrary.simpleMessage("Verbunden"),
        "passKeyPendingVerification": MessageLookupByLibrary.simpleMessage(
            "Verifizierung steht noch aus"),
        "passkey": MessageLookupByLibrary.simpleMessage("Passkey"),
        "passkeyAuthTitle":
            MessageLookupByLibrary.simpleMessage("Passkey-Verifizierung"),
        "password": MessageLookupByLibrary.simpleMessage("Passwort"),
        "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
            "Passwort erfolgreich geändert"),
        "passwordLock": MessageLookupByLibrary.simpleMessage("Passwort Sperre"),
        "passwordStrength": m37,
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Wir speichern dieses Passwort nicht. Wenn du es vergisst, <underline>können wir deine Daten nicht entschlüsseln</underline>"),
        "paymentDetails":
            MessageLookupByLibrary.simpleMessage("Zahlungsdetails"),
        "paymentFailed":
            MessageLookupByLibrary.simpleMessage("Zahlung fehlgeschlagen"),
        "paymentFailedMessage": MessageLookupByLibrary.simpleMessage(
            "Leider ist deine Zahlung fehlgeschlagen. Wende dich an unseren Support und wir helfen dir weiter!"),
        "paymentFailedTalkToProvider": m38,
        "pendingItems":
            MessageLookupByLibrary.simpleMessage("Ausstehende Elemente"),
        "pendingSync":
            MessageLookupByLibrary.simpleMessage("Synchronisation anstehend"),
        "people": MessageLookupByLibrary.simpleMessage("Personen"),
        "peopleUsingYourCode": MessageLookupByLibrary.simpleMessage(
            "Leute, die deinen Code verwenden"),
        "permDeleteWarning": MessageLookupByLibrary.simpleMessage(
            "Alle Elemente im Papierkorb werden dauerhaft gelöscht\n\nDiese Aktion kann nicht rückgängig gemacht werden"),
        "permanentlyDelete":
            MessageLookupByLibrary.simpleMessage("Dauerhaft löschen"),
        "permanentlyDeleteFromDevice": MessageLookupByLibrary.simpleMessage(
            "Endgültig vom Gerät löschen?"),
        "photoDescriptions":
            MessageLookupByLibrary.simpleMessage("Foto Beschreibungen"),
        "photoGridSize":
            MessageLookupByLibrary.simpleMessage("Fotorastergröße"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("Foto"),
        "photos": MessageLookupByLibrary.simpleMessage("Fotos"),
        "photosAddedByYouWillBeRemovedFromTheAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Von dir hinzugefügte Fotos werden vom Album entfernt"),
        "pickCenterPoint":
            MessageLookupByLibrary.simpleMessage("Mittelpunkt auswählen"),
        "pinAlbum": MessageLookupByLibrary.simpleMessage("Album anheften"),
        "playOnTv": MessageLookupByLibrary.simpleMessage(
            "Album auf dem Fernseher wiedergeben"),
        "playStoreFreeTrialValidTill": m39,
        "playstoreSubscription":
            MessageLookupByLibrary.simpleMessage("PlayStore Abo"),
        "pleaseCheckYourInternetConnectionAndTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Bitte überprüfe deine Internetverbindung und versuche es erneut."),
        "pleaseContactSupportAndWeWillBeHappyToHelp":
            MessageLookupByLibrary.simpleMessage(
                "Bitte kontaktieren Sie uns über support@ente.io wo wir Ihnen gerne weiterhelfen."),
        "pleaseContactSupportIfTheProblemPersists":
            MessageLookupByLibrary.simpleMessage(
                "Bitte wenden Sie sich an den Support, falls das Problem weiterhin besteht"),
        "pleaseEmailUsAt": m40,
        "pleaseGrantPermissions": MessageLookupByLibrary.simpleMessage(
            "Bitte erteile die nötigen Berechtigungen"),
        "pleaseLoginAgain":
            MessageLookupByLibrary.simpleMessage("Bitte logge dich erneut ein"),
        "pleaseSendTheLogsTo": m41,
        "pleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("Bitte versuche es erneut"),
        "pleaseVerifyTheCodeYouHaveEntered":
            MessageLookupByLibrary.simpleMessage(
                "Bitte bestätigen Sie den eingegebenen Code"),
        "pleaseWait": MessageLookupByLibrary.simpleMessage("Bitte warten..."),
        "pleaseWaitDeletingAlbum": MessageLookupByLibrary.simpleMessage(
            "Bitte warten, Album wird gelöscht"),
        "pleaseWaitForSometimeBeforeRetrying":
            MessageLookupByLibrary.simpleMessage(
                "Bitte warte kurz, bevor du es erneut versuchst"),
        "preparingLogs": MessageLookupByLibrary.simpleMessage(
            "Protokolle werden vorbereitet..."),
        "preserveMore":
            MessageLookupByLibrary.simpleMessage("Mehr Daten sichern"),
        "pressAndHoldToPlayVideo": MessageLookupByLibrary.simpleMessage(
            "Gedrückt halten, um Video abzuspielen"),
        "pressAndHoldToPlayVideoDetailed": MessageLookupByLibrary.simpleMessage(
            "Drücke und halte aufs Foto gedrückt um Video abzuspielen"),
        "privacy": MessageLookupByLibrary.simpleMessage("Datenschutz"),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Datenschutzerklärung"),
        "privateBackups":
            MessageLookupByLibrary.simpleMessage("Private Sicherungen"),
        "privateSharing":
            MessageLookupByLibrary.simpleMessage("Privates Teilen"),
        "publicLinkCreated":
            MessageLookupByLibrary.simpleMessage("Öffentlicher Link erstellt"),
        "publicLinkEnabled":
            MessageLookupByLibrary.simpleMessage("Öffentlicher Link aktiviert"),
        "quickLinks": MessageLookupByLibrary.simpleMessage("Quick Links"),
        "radius": MessageLookupByLibrary.simpleMessage("Umkreis"),
        "raiseTicket": MessageLookupByLibrary.simpleMessage("Ticket erstellen"),
        "rateTheApp": MessageLookupByLibrary.simpleMessage("App bewerten"),
        "rateUs": MessageLookupByLibrary.simpleMessage("Bewerte uns"),
        "rateUsOnStore": m42,
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
            "Sehr gut! Dein Wiederherstellungsschlüssel ist gültig. Vielen Dank für die Verifizierung.\n\nBitte vergiss nicht eine Kopie des Wiederherstellungsschlüssels sicher aufzubewahren."),
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
        "referralStep3": m43,
        "referrals": MessageLookupByLibrary.simpleMessage("Weiterempfehlungen"),
        "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
            "Einlösungen sind derzeit pausiert"),
        "remindToEmptyDeviceTrash": MessageLookupByLibrary.simpleMessage(
            "Lösche auch Dateien aus \"Kürzlich gelöscht\" unter \"Einstellungen\" -> \"Speicher\" um freien Speicher zu erhalten"),
        "remindToEmptyEnteTrash": MessageLookupByLibrary.simpleMessage(
            "Leere auch deinen \"Papierkorb\", um freien Platz zu erhalten"),
        "remoteImages": MessageLookupByLibrary.simpleMessage(
            "Grafiken aus externen Quellen"),
        "remoteThumbnails": MessageLookupByLibrary.simpleMessage(
            "Vorschaubilder aus externen Quellen"),
        "remoteVideos":
            MessageLookupByLibrary.simpleMessage("Videos aus externen Quellen"),
        "remove": MessageLookupByLibrary.simpleMessage("Entfernen"),
        "removeDuplicates":
            MessageLookupByLibrary.simpleMessage("Duplikate entfernen"),
        "removeDuplicatesDesc": MessageLookupByLibrary.simpleMessage(
            "Überprüfe und lösche Dateien, die exakte Duplikate sind."),
        "removeFromAlbum":
            MessageLookupByLibrary.simpleMessage("Aus Album entfernen"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("Aus Album entfernen?"),
        "removeFromFavorite":
            MessageLookupByLibrary.simpleMessage("Aus Favoriten entfernen"),
        "removeLink": MessageLookupByLibrary.simpleMessage("Link entfernen"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Teilnehmer entfernen"),
        "removeParticipantBody": m44,
        "removePersonLabel":
            MessageLookupByLibrary.simpleMessage("Personenetikett entfernen"),
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
        "renameFile": MessageLookupByLibrary.simpleMessage("Datei umbenennen"),
        "renewSubscription":
            MessageLookupByLibrary.simpleMessage("Abonnement erneuern"),
        "renewsOn": m45,
        "reportABug": MessageLookupByLibrary.simpleMessage("Fehler melden"),
        "reportBug": MessageLookupByLibrary.simpleMessage("Fehler melden"),
        "resendEmail":
            MessageLookupByLibrary.simpleMessage("E-Mail erneut senden"),
        "resetIgnoredFiles": MessageLookupByLibrary.simpleMessage(
            "Ignorierte Dateien zurücksetzen"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Passwort zurücksetzen"),
        "resetToDefault":
            MessageLookupByLibrary.simpleMessage("Standardwerte zurücksetzen"),
        "restore": MessageLookupByLibrary.simpleMessage("Wiederherstellen"),
        "restoreToAlbum":
            MessageLookupByLibrary.simpleMessage("Album wiederherstellen"),
        "restoringFiles": MessageLookupByLibrary.simpleMessage(
            "Dateien werden wiederhergestellt..."),
        "retry": MessageLookupByLibrary.simpleMessage("Erneut versuchen"),
        "reviewDeduplicateItems": MessageLookupByLibrary.simpleMessage(
            "Bitte überprüfe und lösche die Elemente, die du für Duplikate hältst."),
        "reviewSuggestions":
            MessageLookupByLibrary.simpleMessage("Vorschläge überprüfen"),
        "right": MessageLookupByLibrary.simpleMessage("Rechts"),
        "rotate": MessageLookupByLibrary.simpleMessage("Drehen"),
        "rotateLeft": MessageLookupByLibrary.simpleMessage("Nach links drehen"),
        "rotateRight":
            MessageLookupByLibrary.simpleMessage("Nach rechts drehen"),
        "safelyStored": MessageLookupByLibrary.simpleMessage("Gesichert"),
        "save": MessageLookupByLibrary.simpleMessage("Speichern"),
        "saveCollage":
            MessageLookupByLibrary.simpleMessage("Collage speichern"),
        "saveCopy": MessageLookupByLibrary.simpleMessage("Kopie speichern"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Schlüssel speichern"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Sichere deinen Wiederherstellungs-Schlüssel, falls noch nicht geschehen"),
        "saving": MessageLookupByLibrary.simpleMessage("Speichern..."),
        "savingEdits":
            MessageLookupByLibrary.simpleMessage("Speichere Änderungen..."),
        "scanCode": MessageLookupByLibrary.simpleMessage("Code scannen"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Scanne diesen Code mit \ndeiner Authentifizierungs-App"),
        "search": MessageLookupByLibrary.simpleMessage("Suche"),
        "searchAlbumsEmptySection":
            MessageLookupByLibrary.simpleMessage("Alben"),
        "searchByAlbumNameHint":
            MessageLookupByLibrary.simpleMessage("Name des Albums"),
        "searchByExamples": MessageLookupByLibrary.simpleMessage(
            "• Albumnamen (z.B. \"Kamera\")\n• Dateitypen (z.B. \"Videos\", \".gif\")\n• Jahre und Monate (z.B. \"2022\", \"Januar\")\n• Feiertage (z.B. \"Weihnachten\")\n• Fotobeschreibungen (z.B. \"#fun\")"),
        "searchCaptionEmptySection": MessageLookupByLibrary.simpleMessage(
            "Füge Beschreibungen wie \"#trip\" in der Fotoinfo hinzu um diese schnell hier wiederzufinden"),
        "searchDatesEmptySection": MessageLookupByLibrary.simpleMessage(
            "Suche nach Datum, Monat oder Jahr"),
        "searchFaceEmptySection": MessageLookupByLibrary.simpleMessage(
            "Personen werden hier angezeigt, sobald die Indizierung abgeschlossen ist"),
        "searchFileTypesAndNamesEmptySection":
            MessageLookupByLibrary.simpleMessage("Dateitypen und -namen"),
        "searchHint1": MessageLookupByLibrary.simpleMessage(
            "Schnell auf dem Gerät suchen"),
        "searchHint2":
            MessageLookupByLibrary.simpleMessage("Fotodaten, Beschreibungen"),
        "searchHint3": MessageLookupByLibrary.simpleMessage(
            "Alben, Dateinamen und -typen"),
        "searchHint4": MessageLookupByLibrary.simpleMessage("Ort"),
        "searchHint5": MessageLookupByLibrary.simpleMessage(
            "Demnächst: Gesichter & magische Suche ✨"),
        "searchLocationEmptySection": MessageLookupByLibrary.simpleMessage(
            "Gruppiere Fotos, die innerhalb des Radius eines bestimmten Fotos aufgenommen wurden"),
        "searchPeopleEmptySection": MessageLookupByLibrary.simpleMessage(
            "Laden Sie Personen ein, damit Sie geteilte Fotos hier einsehen können"),
        "searchResultCount": m46,
        "security": MessageLookupByLibrary.simpleMessage("Sicherheit"),
        "selectALocation":
            MessageLookupByLibrary.simpleMessage("Standort auswählen"),
        "selectALocationFirst":
            MessageLookupByLibrary.simpleMessage("Wähle zuerst einen Standort"),
        "selectAlbum": MessageLookupByLibrary.simpleMessage("Album auswählen"),
        "selectAll": MessageLookupByLibrary.simpleMessage("Alle markieren"),
        "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
            "Ordner für Sicherung auswählen"),
        "selectItemsToAdd": MessageLookupByLibrary.simpleMessage(
            "Elemente zum Hinzufügen auswählen"),
        "selectLanguage":
            MessageLookupByLibrary.simpleMessage("Sprache auswählen"),
        "selectMorePhotos":
            MessageLookupByLibrary.simpleMessage("Mehr Fotos auswählen"),
        "selectReason": MessageLookupByLibrary.simpleMessage("Grund auswählen"),
        "selectYourPlan":
            MessageLookupByLibrary.simpleMessage("Wähle dein Abo aus"),
        "selectedFilesAreNotOnEnte": MessageLookupByLibrary.simpleMessage(
            "Ausgewählte Dateien sind nicht auf Ente"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "Ausgewählte Ordner werden verschlüsselt und gesichert"),
        "selectedItemsWillBeDeletedFromAllAlbumsAndMoved":
            MessageLookupByLibrary.simpleMessage(
                "Ausgewählte Elemente werden aus allen Alben gelöscht und in den Papierkorb verschoben."),
        "selectedPhotos": m47,
        "selectedPhotosWithYours": m48,
        "send": MessageLookupByLibrary.simpleMessage("Absenden"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("E-Mail senden"),
        "sendInvite": MessageLookupByLibrary.simpleMessage("Einladung senden"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Link senden"),
        "serverEndpoint":
            MessageLookupByLibrary.simpleMessage("Server Endpunkt"),
        "sessionExpired":
            MessageLookupByLibrary.simpleMessage("Sitzung abgelaufen"),
        "setAPassword": MessageLookupByLibrary.simpleMessage("Passwort setzen"),
        "setAs": MessageLookupByLibrary.simpleMessage("Festlegen als"),
        "setCover": MessageLookupByLibrary.simpleMessage("Titelbild festlegen"),
        "setLabel": MessageLookupByLibrary.simpleMessage("Festlegen"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Passwort festlegen"),
        "setRadius": MessageLookupByLibrary.simpleMessage("Radius festlegen"),
        "setupComplete":
            MessageLookupByLibrary.simpleMessage("Einrichtung abgeschlossen"),
        "share": MessageLookupByLibrary.simpleMessage("Teilen"),
        "shareALink": MessageLookupByLibrary.simpleMessage("Einen Link teilen"),
        "shareAlbumHint": MessageLookupByLibrary.simpleMessage(
            "Öffne ein Album und tippe auf den Teilen-Button oben rechts, um zu teilen."),
        "shareAnAlbumNow":
            MessageLookupByLibrary.simpleMessage("Teile jetzt ein Album"),
        "shareLink": MessageLookupByLibrary.simpleMessage("Link teilen"),
        "shareMyVerificationID": m49,
        "shareOnlyWithThePeopleYouWant": MessageLookupByLibrary.simpleMessage(
            "Teile mit ausgewählten Personen"),
        "shareTextConfirmOthersVerificationID": m50,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Hol dir Ente, damit wir ganz einfach Fotos und Videos in Originalqualität teilen können\n\nhttps://ente.io"),
        "shareTextReferralCode": m51,
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
            "Mit Nicht-Ente-Benutzern teilen"),
        "shareWithPeopleSectionTitle": m52,
        "shareYourFirstAlbum":
            MessageLookupByLibrary.simpleMessage("Teile dein erstes Album"),
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Erstelle gemeinsam mit anderen Ente-Nutzern geteilte Alben, inkl. Nutzern ohne Bezahltarif."),
        "sharedByMe": MessageLookupByLibrary.simpleMessage("Von mir geteilt"),
        "sharedByYou": MessageLookupByLibrary.simpleMessage("Von dir geteilt"),
        "sharedPhotoNotifications":
            MessageLookupByLibrary.simpleMessage("Neue geteilte Fotos"),
        "sharedPhotoNotificationsExplanation": MessageLookupByLibrary.simpleMessage(
            "Erhalte Benachrichtigungen, wenn jemand ein Foto zu einem gemeinsam genutzten Album hinzufügt, dem du angehörst"),
        "sharedWith": m53,
        "sharedWithMe": MessageLookupByLibrary.simpleMessage("Mit mir geteilt"),
        "sharedWithYou":
            MessageLookupByLibrary.simpleMessage("Mit dir geteilt"),
        "sharing": MessageLookupByLibrary.simpleMessage("Teilt..."),
        "showMemories":
            MessageLookupByLibrary.simpleMessage("Erinnerungen anschauen"),
        "signOutFromOtherDevices": MessageLookupByLibrary.simpleMessage(
            "Von anderen Geräten abmelden"),
        "signOutOtherBody": MessageLookupByLibrary.simpleMessage(
            "Falls du denkst, dass jemand dein Passwort kennen könnte, kannst du alle anderen Geräte von deinem Account abmelden."),
        "signOutOtherDevices":
            MessageLookupByLibrary.simpleMessage("Andere Geräte abmelden"),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "Ich stimme den <u-terms>Nutzungsbedingungen</u-terms> und der <u-policy>Datenschutzerklärung</u-policy> zu"),
        "singleFileDeleteFromDevice": m54,
        "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
            "Es wird aus allen Alben gelöscht."),
        "singleFileInBothLocalAndRemote": m55,
        "singleFileInRemoteOnly": m56,
        "skip": MessageLookupByLibrary.simpleMessage("Überspringen"),
        "social": MessageLookupByLibrary.simpleMessage("Social Media"),
        "someItemsAreInBothEnteAndYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Einige Elemente sind sowohl auf Ente als auch auf deinem Gerät."),
        "someOfTheFilesYouAreTryingToDeleteAre":
            MessageLookupByLibrary.simpleMessage(
                "Einige der Dateien, die Sie löschen möchten, sind nur auf Ihrem Gerät verfügbar und können nicht wiederhergestellt werden, wenn sie gelöscht wurden"),
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
        "sorryTheCodeYouveEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "Leider ist der eingegebene Code falsch"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "Es tut uns leid, wir konnten keine sicheren Schlüssel auf diesem Gerät generieren.\n\nBitte starte die Registrierung auf einem anderen Gerät."),
        "sortAlbumsBy": MessageLookupByLibrary.simpleMessage("Sortieren nach"),
        "sortNewestFirst":
            MessageLookupByLibrary.simpleMessage("Neueste zuerst"),
        "sortOldestFirst":
            MessageLookupByLibrary.simpleMessage("Älteste zuerst"),
        "sparkleSuccess":
            MessageLookupByLibrary.simpleMessage("✨ Abgeschlossen"),
        "startBackup":
            MessageLookupByLibrary.simpleMessage("Sicherung starten"),
        "status": MessageLookupByLibrary.simpleMessage("Status"),
        "stopCastingBody": MessageLookupByLibrary.simpleMessage(
            "Möchtest du die Übertragung beenden?"),
        "stopCastingTitle":
            MessageLookupByLibrary.simpleMessage("Übertragung beenden"),
        "storage": MessageLookupByLibrary.simpleMessage("Speicherplatz"),
        "storageBreakupFamily": MessageLookupByLibrary.simpleMessage("Familie"),
        "storageBreakupYou": MessageLookupByLibrary.simpleMessage("Sie"),
        "storageInGB": m57,
        "storageLimitExceeded": MessageLookupByLibrary.simpleMessage(
            "Speichergrenze überschritten"),
        "storageUsageInfo": m58,
        "strongStrength": MessageLookupByLibrary.simpleMessage("Stark"),
        "subAlreadyLinkedErrMessage": m59,
        "subWillBeCancelledOn": m60,
        "subscribe": MessageLookupByLibrary.simpleMessage("Abonnieren"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "Sieht aus, als sei dein Abonnement abgelaufen. Bitte abonniere, um das Teilen zu aktivieren."),
        "subscription": MessageLookupByLibrary.simpleMessage("Abonnement"),
        "success": MessageLookupByLibrary.simpleMessage("Abgeschlossen"),
        "successfullyArchived":
            MessageLookupByLibrary.simpleMessage("Erfolgreich archiviert"),
        "successfullyHid":
            MessageLookupByLibrary.simpleMessage("Erfolgreich versteckt"),
        "successfullyUnarchived":
            MessageLookupByLibrary.simpleMessage("Erfolgreich dearchiviert"),
        "successfullyUnhid":
            MessageLookupByLibrary.simpleMessage("Erfolgreich eingeblendet"),
        "suggestFeatures":
            MessageLookupByLibrary.simpleMessage("Verbesserung vorschlagen"),
        "support": MessageLookupByLibrary.simpleMessage("Support"),
        "syncProgress": m61,
        "syncStopped":
            MessageLookupByLibrary.simpleMessage("Synchronisierung angehalten"),
        "syncing": MessageLookupByLibrary.simpleMessage("Synchronisiere …"),
        "systemTheme": MessageLookupByLibrary.simpleMessage("System"),
        "tapToCopy":
            MessageLookupByLibrary.simpleMessage("zum Kopieren antippen"),
        "tapToEnterCode": MessageLookupByLibrary.simpleMessage(
            "Antippen, um den Code einzugeben"),
        "tempErrorContactSupportIfPersists": MessageLookupByLibrary.simpleMessage(
            "Etwas ist schiefgelaufen. Bitte versuche es später noch einmal. Sollte der Fehler weiter bestehen, kontaktiere unser Supportteam."),
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
        "theRecoveryKeyYouEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "Der eingegebene Schlüssel ist ungültig"),
        "theme": MessageLookupByLibrary.simpleMessage("Theme"),
        "theseItemsWillBeDeletedFromYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Diese Elemente werden von deinem Gerät gelöscht."),
        "theyAlsoGetXGb": m62,
        "theyWillBeDeletedFromAllAlbums": MessageLookupByLibrary.simpleMessage(
            "Sie werden aus allen Alben gelöscht."),
        "thisActionCannotBeUndone": MessageLookupByLibrary.simpleMessage(
            "Diese Aktion kann nicht rückgängig gemacht werden"),
        "thisAlbumAlreadyHDACollaborativeLink":
            MessageLookupByLibrary.simpleMessage(
                "Dieses Album hat bereits einen kollaborativen Link"),
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "Dies kann verwendet werden, um dein Konto wiederherzustellen, wenn du deinen zweiten Faktor (2FA) verlierst"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Dieses Gerät"),
        "thisEmailIsAlreadyInUse": MessageLookupByLibrary.simpleMessage(
            "Diese E-Mail-Adresse wird bereits verwendet"),
        "thisImageHasNoExifData": MessageLookupByLibrary.simpleMessage(
            "Dieses Bild hat keine Exif-Daten"),
        "thisIsPersonVerificationId": m63,
        "thisIsYourVerificationId": MessageLookupByLibrary.simpleMessage(
            "Dies ist deine Verifizierungs-ID"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Dadurch wirst du von folgendem Gerät abgemeldet:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Dadurch wirst du von diesem Gerät abgemeldet!"),
        "toHideAPhotoOrVideo":
            MessageLookupByLibrary.simpleMessage("Foto oder Video verstecken"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "Um dein Passwort zurückzusetzen, verifiziere bitte zuerst deine E-Mail Adresse."),
        "todaysLogs":
            MessageLookupByLibrary.simpleMessage("Heutiges Protokoll"),
        "total": MessageLookupByLibrary.simpleMessage("Gesamt"),
        "totalSize": MessageLookupByLibrary.simpleMessage("Gesamtgröße"),
        "trash": MessageLookupByLibrary.simpleMessage("Papierkorb"),
        "trashDaysLeft": m64,
        "trim": MessageLookupByLibrary.simpleMessage("Schneiden"),
        "tryAgain": MessageLookupByLibrary.simpleMessage("Erneut versuchen"),
        "turnOnBackupForAutoUpload": MessageLookupByLibrary.simpleMessage(
            "Aktiviere die Sicherung, um neue Dateien in diesem Ordner automatisch zu Ente hochzuladen."),
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
        "unarchiving": MessageLookupByLibrary.simpleMessage("Dearchiviere …"),
        "uncategorized":
            MessageLookupByLibrary.simpleMessage("Unkategorisiert"),
        "unhide": MessageLookupByLibrary.simpleMessage("Einblenden"),
        "unhideToAlbum":
            MessageLookupByLibrary.simpleMessage("Im Album anzeigen"),
        "unhiding": MessageLookupByLibrary.simpleMessage("Einblenden..."),
        "unhidingFilesToAlbum":
            MessageLookupByLibrary.simpleMessage("Dateien im Album anzeigen"),
        "unlock": MessageLookupByLibrary.simpleMessage("Jetzt freischalten"),
        "unpinAlbum": MessageLookupByLibrary.simpleMessage("Album lösen"),
        "unselectAll": MessageLookupByLibrary.simpleMessage("Alle demarkieren"),
        "update": MessageLookupByLibrary.simpleMessage("Updaten"),
        "updateAvailable":
            MessageLookupByLibrary.simpleMessage("Update verfügbar"),
        "updatingFolderSelection": MessageLookupByLibrary.simpleMessage(
            "Ordnerauswahl wird aktualisiert..."),
        "upgrade": MessageLookupByLibrary.simpleMessage("Upgrade"),
        "uploadingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Dateien werden ins Album hochgeladen..."),
        "upto50OffUntil4thDec": MessageLookupByLibrary.simpleMessage(
            "Bis zu 50% Rabatt bis zum 4. Dezember."),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "Der verwendbare Speicherplatz ist von deinem aktuellen Abonnement eingeschränkt. Überschüssiger, beanspruchter Speicherplatz wird automatisch verwendbar werden, wenn du ein höheres Abonnement buchst."),
        "usePublicLinksForPeopleNotOnEnte": MessageLookupByLibrary.simpleMessage(
            "Verwenden Sie öffentliche Links für Personen, die kein Ente-Konto haben"),
        "useRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Wiederherstellungs-Schlüssel verwenden"),
        "useSelectedPhoto":
            MessageLookupByLibrary.simpleMessage("Ausgewähltes Foto verwenden"),
        "usedSpace":
            MessageLookupByLibrary.simpleMessage("Belegter Speicherplatz"),
        "validTill": m65,
        "verificationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Verifizierung fehlgeschlagen, bitte versuchen Sie es erneut"),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("Verifizierungs-ID"),
        "verify": MessageLookupByLibrary.simpleMessage("Überprüfen"),
        "verifyEmail":
            MessageLookupByLibrary.simpleMessage("E-Mail-Adresse verifizieren"),
        "verifyEmailID": m66,
        "verifyIDLabel": MessageLookupByLibrary.simpleMessage("Überprüfen"),
        "verifyPasskey":
            MessageLookupByLibrary.simpleMessage("Passkey verifizieren"),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Passwort überprüfen"),
        "verifying": MessageLookupByLibrary.simpleMessage("Verifiziere …"),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Wiederherstellungs-Schlüssel wird überprüft..."),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("Video"),
        "videos": MessageLookupByLibrary.simpleMessage("Videos"),
        "viewActiveSessions":
            MessageLookupByLibrary.simpleMessage("Aktive Sitzungen anzeigen"),
        "viewAddOnButton":
            MessageLookupByLibrary.simpleMessage("Zeige Add-ons"),
        "viewAll": MessageLookupByLibrary.simpleMessage("Alle anzeigen"),
        "viewAllExifData":
            MessageLookupByLibrary.simpleMessage("Alle Exif-Daten anzeigen"),
        "viewLargeFiles": MessageLookupByLibrary.simpleMessage("Große Dateien"),
        "viewLargeFilesDesc": MessageLookupByLibrary.simpleMessage(
            "Dateien anzeigen, die den meisten Speicherplatz belegen"),
        "viewLogs": MessageLookupByLibrary.simpleMessage("Protokolle anzeigen"),
        "viewRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Wiederherstellungsschlüssel anzeigen"),
        "viewer": MessageLookupByLibrary.simpleMessage("Zuschauer"),
        "visitWebToManage": MessageLookupByLibrary.simpleMessage(
            "Bitte rufen Sie \"web.ente.io\" auf um ihr Abo zu verwalten"),
        "waitingForVerification":
            MessageLookupByLibrary.simpleMessage("Warte auf Bestätigung..."),
        "waitingForWifi":
            MessageLookupByLibrary.simpleMessage("Warte auf WLAN..."),
        "weAreOpenSource": MessageLookupByLibrary.simpleMessage(
            "Unser Quellcode ist offen einsehbar!"),
        "weDontSupportEditingPhotosAndAlbumsThatYouDont":
            MessageLookupByLibrary.simpleMessage(
                "Wir unterstützen keine Bearbeitung von Fotos und Alben, die du noch nicht besitzt"),
        "weHaveSendEmailTo": m67,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Schwach"),
        "welcomeBack":
            MessageLookupByLibrary.simpleMessage("Willkommen zurück!"),
        "whatsNew": MessageLookupByLibrary.simpleMessage("Neue Funktionen"),
        "yearly": MessageLookupByLibrary.simpleMessage("Jährlich"),
        "yearsAgo": m68,
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
        "youCanManageYourLinksInTheShareTab":
            MessageLookupByLibrary.simpleMessage(
                "Sie können Ihre Links im \"Teilen\"-Tab verwalten."),
        "youCanTrySearchingForADifferentQuery":
            MessageLookupByLibrary.simpleMessage(
                "Sie können versuchen, nach einer anderen Abfrage suchen."),
        "youCannotDowngradeToThisPlan": MessageLookupByLibrary.simpleMessage(
            "Sie können nicht auf diesen Tarif wechseln"),
        "youCannotShareWithYourself": MessageLookupByLibrary.simpleMessage(
            "Du kannst nicht mit dir selbst teilen"),
        "youDontHaveAnyArchivedItems": MessageLookupByLibrary.simpleMessage(
            "Du hast keine archivierten Elemente."),
        "youHaveSuccessfullyFreedUp": m69,
        "yourAccountHasBeenDeleted": MessageLookupByLibrary.simpleMessage(
            "Dein Benutzerkonto wurde gelöscht"),
        "yourMap": MessageLookupByLibrary.simpleMessage("Deine Karte"),
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
        "yourVerificationCodeHasExpired": MessageLookupByLibrary.simpleMessage(
            "Ihr Bestätigungscode ist abgelaufen"),
        "youveNoDuplicateFilesThatCanBeCleared":
            MessageLookupByLibrary.simpleMessage(
                "Du hast keine Duplikate, die gelöscht werden können"),
        "youveNoFilesInThisAlbumThatCanBeDeleted":
            MessageLookupByLibrary.simpleMessage(
                "Du hast keine Dateien in diesem Album, die gelöscht werden können"),
        "zoomOutToSeePhotos": MessageLookupByLibrary.simpleMessage(
            "Verkleinern, um Fotos zu sehen")
      };
}
