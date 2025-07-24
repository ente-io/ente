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

  static String m0(title) => "${title} (Ich)";

  static String m1(count) =>
      "${Intl.plural(count, zero: 'Bearbeiter hinzufügen', one: 'Bearbeiter hinzufügen', other: 'Bearbeiter hinzufügen')}";

  static String m2(count) =>
      "${Intl.plural(count, one: 'Element hinzufügen', other: 'Elemente hinzufügen')}";

  static String m3(storageAmount, endDate) =>
      "Dein ${storageAmount} Add-on ist gültig bis ${endDate}";

  static String m4(count) =>
      "${Intl.plural(count, zero: 'Betrachter hinzufügen', one: 'Betrachter hinzufügen', other: 'Betrachter hinzufügen')}";

  static String m5(emailOrName) => "Von ${emailOrName} hinzugefügt";

  static String m6(albumName) => "Erfolgreich zu  ${albumName} hinzugefügt";

  static String m7(name) => "${name} wertschätzen";

  static String m8(count) =>
      "${Intl.plural(count, zero: 'Keine Teilnehmer', one: '1 Teilnehmer', other: '${count} Teilnehmer')}";

  static String m9(versionValue) => "Version: ${versionValue}";

  static String m10(freeAmount, storageUnit) =>
      "${freeAmount} ${storageUnit} frei";

  static String m11(name) => "Schöne Ausblicke mit ${name}";

  static String m12(paymentProvider) =>
      "Bitte kündige dein aktuelles Abo über ${paymentProvider} zuerst";

  static String m13(user) =>
      "Der Nutzer \"${user}\" wird keine weiteren Fotos zum Album hinzufügen können.\n\nJedoch kann er weiterhin vorhandene Bilder, welche durch ihn hinzugefügt worden sind, wieder entfernen";

  static String m14(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true':
                'Deine Familiengruppe hat bereits ${storageAmountInGb} GB erhalten',
            'false': 'Du hast bereits ${storageAmountInGb} GB erhalten',
            'other': 'Du hast bereits ${storageAmountInGb} GB erhalten!',
          })}";

  static String m15(albumName) =>
      "Kollaborativer Link für ${albumName} erstellt";

  static String m16(count) =>
      "${Intl.plural(count, zero: '0 Mitarbeiter hinzugefügt', one: '1 Mitarbeiter hinzugefügt', other: '${count} Mitarbeiter hinzugefügt')}";

  static String m17(email, numOfDays) =>
      "Du bist dabei, ${email} als vertrauenswürdigen Kontakt hinzuzufügen. Die Person wird in der Lage sein, dein Konto wiederherzustellen, wenn du für ${numOfDays} Tage abwesend bist.";

  static String m18(familyAdminEmail) =>
      "Bitte kontaktiere <green>${familyAdminEmail}</green> um dein Abo zu verwalten";

  static String m19(provider) =>
      "Bitte kontaktiere uns über support@ente.io, um dein ${provider} Abo zu verwalten.";

  static String m20(endpoint) => "Verbunden mit ${endpoint}";

  static String m21(count) =>
      "${Intl.plural(count, one: 'Lösche ${count} Element', other: 'Lösche ${count} Elemente')}";

  static String m22(count) =>
      "Sollen die Fotos (und Videos) aus diesen ${count} Alben auch aus <bold>allen</bold> anderen Alben gelöscht werden, in denen sie enthalten sind?";

  static String m23(currentlyDeleting, totalCount) =>
      "Lösche ${currentlyDeleting} / ${totalCount}";

  static String m24(albumName) =>
      "Der öffentliche Link zum Zugriff auf \"${albumName}\" wird entfernt.";

  static String m25(supportEmail) =>
      "Bitte sende eine E-Mail an ${supportEmail} von deiner registrierten E-Mail-Adresse";

  static String m26(count, storageSaved) =>
      "Du hast ${Intl.plural(count, one: '${count} duplizierte Datei', other: '${count} dupliziere Dateien')} gelöscht und (${storageSaved}!) freigegeben";

  static String m27(count, formattedSize) =>
      "${count} Dateien, ${formattedSize} jede";

  static String m28(name) => "Diese E-Mail ist bereits verknüpft mit ${name}.";

  static String m29(newEmail) => "E-Mail-Adresse geändert zu ${newEmail}";

  static String m30(email) => "${email} hat kein Ente-Konto.";

  static String m31(email) =>
      "${email} hat kein Ente-Konto.\n\nSende eine Einladung, um Fotos zu teilen.";

  static String m32(name) => "${name} umarmen";

  static String m33(text) => "Zusätzliche Fotos für ${text} gefunden";

  static String m34(name) => "Feiern mit ${name}";

  static String m35(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 Datei', other: '${formattedNumber} Dateien')} auf diesem Gerät wurde(n) sicher gespeichert";

  static String m36(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 Datei', other: '${formattedNumber} Dateien')} in diesem Album wurde(n) sicher gespeichert";

  static String m37(storageAmountInGB) =>
      "${storageAmountInGB} GB jedes Mal, wenn sich jemand mit deinem Code für einen bezahlten Tarif anmeldet";

  static String m38(endDate) => "Kostenlose Demo verfügbar bis zum ${endDate}";

  static String m39(count) =>
      "Du hast ${Intl.plural(count, one: 'darauf', other: 'auf sie')} weiterhin Zugriff, solange du ein aktives Abo hast";

  static String m40(sizeInMBorGB) => "${sizeInMBorGB} freigeben";

  static String m41(count, formattedSize) =>
      "${Intl.plural(count, one: 'Es kann vom Gerät gelöscht werden, um ${formattedSize} freizugeben', other: 'Sie können vom Gerät gelöscht werden, um ${formattedSize} freizugeben')}";

  static String m42(currentlyProcessing, totalCount) =>
      "Verarbeite ${currentlyProcessing} / ${totalCount}";

  static String m43(name) => "Wandern mit ${name}";

  static String m44(count) =>
      "${Intl.plural(count, one: '${count} Objekt', other: '${count} Objekte')}";

  static String m45(name) => "Zuletzt mit ${name}";

  static String m46(email) =>
      "${email} hat dich eingeladen, ein vertrauenswürdiger Kontakt zu werden";

  static String m47(expiryTime) => "Link läuft am ${expiryTime} ab";

  static String m48(email) => "Person mit ${email} verknüpfen";

  static String m49(personName, email) =>
      "Dies wird ${personName} mit ${email} verknüpfen";

  static String m50(count, formattedCount) =>
      "${Intl.plural(count, zero: 'keine Erinnerungen', one: '${formattedCount} Erinnerung', other: '${formattedCount} Erinnerungen')}";

  static String m51(count) =>
      "${Intl.plural(count, one: 'Element verschieben', other: 'Elemente verschieben')}";

  static String m52(albumName) => "Erfolgreich zu ${albumName} hinzugefügt";

  static String m53(personName) => "Keine Vorschläge für ${personName}";

  static String m54(name) => "Nicht ${name}?";

  static String m55(familyAdminEmail) =>
      "Bitte wende Dich an ${familyAdminEmail}, um den Code zu ändern.";

  static String m56(name) => "Party mit ${name}";

  static String m57(passwordStrengthValue) =>
      "Passwortstärke: ${passwordStrengthValue}";

  static String m58(providerName) =>
      "Bitte kontaktiere den Support von ${providerName}, falls etwas abgebucht wurde";

  static String m59(name, age) => "${name} ist ${age}!";

  static String m60(name, age) => "${name} wird bald ${age}";

  static String m61(count) =>
      "${Intl.plural(count, zero: 'Keine Fotos', one: 'Ein Foto', other: '${count} Fotos')}";

  static String m62(count) =>
      "${Intl.plural(count, zero: '0 Fotos', one: 'Ein Foto', other: '${count} Fotos')}";

  static String m63(endDate) =>
      "Kostenlose Testversion gültig bis ${endDate}.\nDu kannst anschließend ein bezahltes Paket auswählen.";

  static String m64(toEmail) => "Bitte sende uns eine E-Mail an ${toEmail}";

  static String m65(toEmail) => "Bitte sende die Protokolle an ${toEmail}";

  static String m66(name) => "Posieren mit ${name}";

  static String m67(folderName) => "Verarbeite ${folderName}...";

  static String m68(storeName) => "Bewerte uns auf ${storeName}";

  static String m69(name) => "Du wurdest an ${name} neu zugewiesen";

  static String m70(days, email) =>
      "Du kannst nach ${days} Tagen auf das Konto zugreifen. Eine Benachrichtigung wird an ${email} versendet.";

  static String m71(email) =>
      "Du kannst jetzt das Konto von ${email} wiederherstellen, indem du ein neues Passwort setzt.";

  static String m72(email) =>
      "${email} versucht, dein Konto wiederherzustellen.";

  static String m73(storageInGB) =>
      "3. Ihr beide erhaltet ${storageInGB} GB* kostenlos";

  static String m74(userEmail) =>
      "${userEmail} wird aus diesem geteilten Album entfernt\n\nAlle von ihnen hinzugefügte Fotos werden ebenfalls aus dem Album entfernt";

  static String m75(endDate) => "Erneuert am ${endDate}";

  static String m76(name) => "Roadtrip mit ${name}";

  static String m77(count) =>
      "${Intl.plural(count, one: '${count} Ergebnis gefunden', other: '${count} Ergebnisse gefunden')}";

  static String m78(snapshotLength, searchLength) =>
      "Abschnittslänge stimmt nicht überein: ${snapshotLength} != ${searchLength}";

  static String m79(count) => "${count} ausgewählt";

  static String m80(count) => "${count} ausgewählt";

  static String m81(count, yourCount) =>
      "${count} ausgewählt (${yourCount} von Ihnen)";

  static String m82(name) => "Selfies mit ${name}";

  static String m83(verificationID) =>
      "Hier ist meine Verifizierungs-ID: ${verificationID} für ente.io.";

  static String m84(verificationID) =>
      "Hey, kannst du bestätigen, dass dies deine ente.io Verifizierungs-ID ist: ${verificationID}";

  static String m85(referralCode, referralStorageInGB) =>
      "Ente Weiterempfehlungs-Code: ${referralCode} \n\nEinlösen unter Einstellungen → Allgemein → Weiterempfehlungen, um ${referralStorageInGB} GB kostenlos zu erhalten, sobald Sie einen kostenpflichtigen Tarif abgeschlossen haben\n\nhttps://ente.io";

  static String m86(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Teile mit bestimmten Personen', one: 'Teilen mit 1 Person', other: 'Teilen mit ${numberOfPeople} Personen')}";

  static String m87(emailIDs) => "Geteilt mit ${emailIDs}";

  static String m88(fileType) =>
      "Dieses ${fileType} wird von deinem Gerät gelöscht.";

  static String m89(fileType) =>
      "Diese Datei ist sowohl in Ente als auch auf deinem Gerät.";

  static String m90(fileType) => "Diese Datei wird von Ente gelöscht.";

  static String m91(name) => "Sport mit ${name}";

  static String m92(name) => "Spot auf ${name}";

  static String m93(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m94(
          usedAmount, usedStorageUnit, totalAmount, totalStorageUnit) =>
      "${usedAmount} ${usedStorageUnit} von ${totalAmount} ${totalStorageUnit} verwendet";

  static String m95(id) =>
      "Dein ${id} ist bereits mit einem anderen Ente-Konto verknüpft.\nWenn du deine ${id} mit diesem Konto verwenden möchtest, kontaktiere bitte unseren Support";

  static String m96(endDate) => "Dein Abo endet am ${endDate}";

  static String m97(completed, total) =>
      "${completed}/${total} Erinnerungsstücke gesichert";

  static String m98(ignoreReason) =>
      "Zum Hochladen tippen, Hochladen wird derzeit ignoriert, da ${ignoreReason}";

  static String m99(storageAmountInGB) =>
      "Diese erhalten auch ${storageAmountInGB} GB";

  static String m100(email) => "Dies ist ${email}s Verifizierungs-ID";

  static String m101(count) =>
      "${Intl.plural(count, one: 'Diese Woche, vor einem Jahr', other: 'Diese Woche, vor ${count} Jahren')}";

  static String m102(dateFormat) => "${dateFormat} über die Jahre";

  static String m103(count) =>
      "${Intl.plural(count, zero: 'Demnächst', one: '1 Tag', other: '${count} Tage')}";

  static String m104(year) => "Reise in ${year}";

  static String m105(location) => "Ausflug nach ${location}";

  static String m106(email) =>
      "Du wurdest von ${email} eingeladen, ein Kontakt für das digitale Erbe zu werden.";

  static String m107(galleryType) =>
      "Der Galerie-Typ ${galleryType} unterstützt kein Umbenennen";

  static String m108(ignoreReason) =>
      "Upload wird aufgrund von ${ignoreReason} ignoriert";

  static String m109(count) => "Sichere ${count} Erinnerungsstücke...";

  static String m110(endDate) => "Gültig bis ${endDate}";

  static String m111(email) => "Verifiziere ${email}";

  static String m112(name) => "${name} zum Entfernen des Links anzeigen";

  static String m113(count) =>
      "${Intl.plural(count, zero: '0 Betrachter hinzugefügt', one: 'Einen Betrachter hinzugefügt', other: '${count} Betrachter hinzugefügt')}";

  static String m114(email) =>
      "Wir haben eine E-Mail an <green>${email}</green> gesendet";

  static String m115(name) => "Wünsche ${name} alles Gute zum Geburtstag! 🎉";

  static String m116(count) =>
      "${Intl.plural(count, one: 'vor einem Jahr', other: 'vor ${count} Jahren')}";

  static String m117(name) => "Du und ${name}";

  static String m118(storageSaved) =>
      "Du hast ${storageSaved} erfolgreich freigegeben!";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable": MessageLookupByLibrary.simpleMessage(
            "Eine neue Version von Ente ist verfügbar."),
        "about":
            MessageLookupByLibrary.simpleMessage("Allgemeine Informationen"),
        "acceptTrustInvite":
            MessageLookupByLibrary.simpleMessage("Einladung annehmen"),
        "account": MessageLookupByLibrary.simpleMessage("Konto"),
        "accountIsAlreadyConfigured": MessageLookupByLibrary.simpleMessage(
            "Das Konto ist bereits konfiguriert."),
        "accountOwnerPersonAppbarTitle": m0,
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Willkommen zurück!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Ich verstehe, dass ich meine Daten verlieren kann, wenn ich mein Passwort vergesse, da meine Daten <underline>Ende-zu-Ende-verschlüsselt</underline> sind."),
        "actionNotSupportedOnFavouritesAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Aktion für das Favoritenalbum nicht unterstützt"),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Aktive Sitzungen"),
        "add": MessageLookupByLibrary.simpleMessage("Hinzufügen"),
        "addAName":
            MessageLookupByLibrary.simpleMessage("Füge einen Namen hinzu"),
        "addANewEmail": MessageLookupByLibrary.simpleMessage(
            "Neue E-Mail-Adresse hinzufügen"),
        "addAlbumWidgetPrompt": MessageLookupByLibrary.simpleMessage(
            "Füge ein Alben-Widget zu deiner Startseite hinzu und komm hierher zurück, um es anzupassen."),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Bearbeiter hinzufügen"),
        "addCollaborators": m1,
        "addFiles": MessageLookupByLibrary.simpleMessage("Dateien hinzufügen"),
        "addFromDevice":
            MessageLookupByLibrary.simpleMessage("Vom Gerät hinzufügen"),
        "addItem": m2,
        "addLocation": MessageLookupByLibrary.simpleMessage("Ort hinzufügen"),
        "addLocationButton": MessageLookupByLibrary.simpleMessage("Hinzufügen"),
        "addMemoriesWidgetPrompt": MessageLookupByLibrary.simpleMessage(
            "Füge ein Erinnerungs-Widget zu deiner Startseite hinzu und komm hierher zurück, um es anzupassen."),
        "addMore": MessageLookupByLibrary.simpleMessage("Mehr hinzufügen"),
        "addName": MessageLookupByLibrary.simpleMessage("Name hinzufügen"),
        "addNameOrMerge": MessageLookupByLibrary.simpleMessage(
            "Name hinzufügen oder zusammenführen"),
        "addNew": MessageLookupByLibrary.simpleMessage("Hinzufügen"),
        "addNewPerson":
            MessageLookupByLibrary.simpleMessage("Neue Person hinzufügen"),
        "addOnPageSubtitle":
            MessageLookupByLibrary.simpleMessage("Details der Add-ons"),
        "addOnValidTill": m3,
        "addOns": MessageLookupByLibrary.simpleMessage("Add-ons"),
        "addParticipants":
            MessageLookupByLibrary.simpleMessage("Teilnehmer hinzufügen"),
        "addPeopleWidgetPrompt": MessageLookupByLibrary.simpleMessage(
            "Füge ein Personen-Widget zu deiner Startseite hinzu und komm hierher zurück, um es anzupassen."),
        "addPhotos": MessageLookupByLibrary.simpleMessage("Fotos hinzufügen"),
        "addSelected":
            MessageLookupByLibrary.simpleMessage("Auswahl hinzufügen"),
        "addToAlbum":
            MessageLookupByLibrary.simpleMessage("Zum Album hinzufügen"),
        "addToEnte": MessageLookupByLibrary.simpleMessage("Zu Ente hinzufügen"),
        "addToHiddenAlbum": MessageLookupByLibrary.simpleMessage(
            "Zum versteckten Album hinzufügen"),
        "addTrustedContact": MessageLookupByLibrary.simpleMessage(
            "Vertrauenswürdigen Kontakt hinzufügen"),
        "addViewer": MessageLookupByLibrary.simpleMessage("Album teilen"),
        "addViewers": m4,
        "addYourPhotosNow":
            MessageLookupByLibrary.simpleMessage("Füge deine Foto jetzt hinzu"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Hinzugefügt als"),
        "addedBy": m5,
        "addedSuccessfullyTo": m6,
        "addingToFavorites": MessageLookupByLibrary.simpleMessage(
            "Wird zu Favoriten hinzugefügt..."),
        "admiringThem": m7,
        "advanced": MessageLookupByLibrary.simpleMessage("Erweitert"),
        "advancedSettings": MessageLookupByLibrary.simpleMessage("Erweitert"),
        "after1Day": MessageLookupByLibrary.simpleMessage("Nach einem Tag"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("Nach 1 Stunde"),
        "after1Month": MessageLookupByLibrary.simpleMessage("Nach 1 Monat"),
        "after1Week": MessageLookupByLibrary.simpleMessage("Nach 1 Woche"),
        "after1Year": MessageLookupByLibrary.simpleMessage("Nach 1 Jahr"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Besitzer"),
        "albumParticipantsCount": m8,
        "albumTitle": MessageLookupByLibrary.simpleMessage("Albumtitel"),
        "albumUpdated":
            MessageLookupByLibrary.simpleMessage("Album aktualisiert"),
        "albums": MessageLookupByLibrary.simpleMessage("Alben"),
        "albumsWidgetDesc": MessageLookupByLibrary.simpleMessage(
            "Wähle die Alben, die du auf der Startseite sehen möchtest."),
        "allClear": MessageLookupByLibrary.simpleMessage("✨ Alles klar"),
        "allMemoriesPreserved": MessageLookupByLibrary.simpleMessage(
            "Alle Erinnerungsstücke gesichert"),
        "allPersonGroupingWillReset": MessageLookupByLibrary.simpleMessage(
            "Alle Gruppierungen für diese Person werden zurückgesetzt und du wirst alle Vorschläge für diese Person verlieren"),
        "allUnnamedGroupsWillBeMergedIntoTheSelectedPerson":
            MessageLookupByLibrary.simpleMessage(
                "Alle unbenannten Gruppen werden zur ausgewählten Person zusammengeführt. Dies kann im Verlauf der Vorschläge für diese Person rückgängig gemacht werden."),
        "allWillShiftRangeBasedOnFirst": MessageLookupByLibrary.simpleMessage(
            "Dies ist die erste in der Gruppe. Andere ausgewählte Fotos werden automatisch nach diesem neuen Datum verschoben"),
        "allow": MessageLookupByLibrary.simpleMessage("Erlauben"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Erlaube Nutzern, mit diesem Link ebenfalls Fotos zu diesem geteilten Album hinzuzufügen."),
        "allowAddingPhotos": MessageLookupByLibrary.simpleMessage(
            "Hinzufügen von Fotos erlauben"),
        "allowAppToOpenSharedAlbumLinks": MessageLookupByLibrary.simpleMessage(
            "Erlaube der App, geteilte Album-Links zu öffnen"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("Downloads erlauben"),
        "allowPeopleToAddPhotos": MessageLookupByLibrary.simpleMessage(
            "Erlaube anderen das Hinzufügen von Fotos"),
        "allowPermBody": MessageLookupByLibrary.simpleMessage(
            "Bitte erlaube den Zugriff auf Deine Fotos in den Einstellungen, damit Ente sie anzeigen und sichern kann."),
        "allowPermTitle":
            MessageLookupByLibrary.simpleMessage("Zugriff auf Fotos erlauben"),
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
        "appIcon": MessageLookupByLibrary.simpleMessage("App-Symbol"),
        "appLock": MessageLookupByLibrary.simpleMessage("App-Sperre"),
        "appLockDescriptions": MessageLookupByLibrary.simpleMessage(
            "Wähle zwischen dem Standard-Sperrbildschirm deines Gerätes und einem eigenen Sperrbildschirm mit PIN oder Passwort."),
        "appVersion": m9,
        "appleId": MessageLookupByLibrary.simpleMessage("Apple ID"),
        "apply": MessageLookupByLibrary.simpleMessage("Anwenden"),
        "applyCodeTitle": MessageLookupByLibrary.simpleMessage("Code nutzen"),
        "appstoreSubscription":
            MessageLookupByLibrary.simpleMessage("AppStore Abo"),
        "archive": MessageLookupByLibrary.simpleMessage("Archiv"),
        "archiveAlbum":
            MessageLookupByLibrary.simpleMessage("Album archivieren"),
        "archiving": MessageLookupByLibrary.simpleMessage("Archiviere …"),
        "areThey": MessageLookupByLibrary.simpleMessage("Ist das "),
        "areYouSureRemoveThisFaceFromPerson": MessageLookupByLibrary.simpleMessage(
            "Bist du sicher, dass du dieses Gesicht von dieser Person entfernen möchtest?"),
        "areYouSureThatYouWantToLeaveTheFamily":
            MessageLookupByLibrary.simpleMessage(
                "Bist du sicher, dass du den Familien-Tarif verlassen möchtest?"),
        "areYouSureYouWantToCancel": MessageLookupByLibrary.simpleMessage(
            "Bist du sicher, dass du kündigen willst?"),
        "areYouSureYouWantToChangeYourPlan":
            MessageLookupByLibrary.simpleMessage(
                "Bist du sicher, dass du deinen Tarif ändern möchtest?"),
        "areYouSureYouWantToExit": MessageLookupByLibrary.simpleMessage(
            "Möchtest du Vorgang wirklich abbrechen?"),
        "areYouSureYouWantToIgnoreThesePersons":
            MessageLookupByLibrary.simpleMessage(
                "Bist du sicher, dass du diese Personen ignorieren willst?"),
        "areYouSureYouWantToIgnoreThisPerson":
            MessageLookupByLibrary.simpleMessage(
                "Bist du sicher, dass du diese Person ignorieren willst?"),
        "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
            "Bist Du sicher, dass du dich abmelden möchtest?"),
        "areYouSureYouWantToMergeThem": MessageLookupByLibrary.simpleMessage(
            "Bist du sicher, dass du sie zusammenführen willst?"),
        "areYouSureYouWantToRenew": MessageLookupByLibrary.simpleMessage(
            "Bist du sicher, dass du verlängern möchtest?"),
        "areYouSureYouWantToResetThisPerson":
            MessageLookupByLibrary.simpleMessage(
                "Bist du sicher, dass du diese Person zurücksetzen möchtest?"),
        "askCancelReason": MessageLookupByLibrary.simpleMessage(
            "Dein Abonnement wurde gekündigt. Möchtest du uns den Grund mitteilen?"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "Was ist der Hauptgrund für die Löschung deines Kontos?"),
        "askYourLovedOnesToShare": MessageLookupByLibrary.simpleMessage(
            "Bitte deine Liebsten ums Teilen"),
        "atAFalloutShelter": MessageLookupByLibrary.simpleMessage(
            "in einem ehemaligen Luftschutzbunker"),
        "authToChangeEmailVerificationSetting":
            MessageLookupByLibrary.simpleMessage(
                "Bitte authentifizieren, um die E-Mail-Bestätigung zu ändern"),
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
        "authToManageLegacy": MessageLookupByLibrary.simpleMessage(
            "Bitte authentifiziere dich, um deine vertrauenswürdigen Kontakte zu verwalten"),
        "authToViewPasskey": MessageLookupByLibrary.simpleMessage(
            "Bitte authentifizieren, um deinen Passkey zu sehen"),
        "authToViewTrashedFiles": MessageLookupByLibrary.simpleMessage(
            "Bitte authentifizieren, um die gelöschten Dateien anzuzeigen"),
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
        "autoLock":
            MessageLookupByLibrary.simpleMessage("Automatisches Sperren"),
        "autoLockFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "Zeit, nach der die App gesperrt wird, nachdem sie in den Hintergrund verschoben wurde"),
        "autoLogoutMessage": MessageLookupByLibrary.simpleMessage(
            "Du wurdest aufgrund technischer Störungen abgemeldet. Wir entschuldigen uns für die Unannehmlichkeiten."),
        "autoPair":
            MessageLookupByLibrary.simpleMessage("Automatisch verbinden"),
        "autoPairDesc": MessageLookupByLibrary.simpleMessage(
            "Automatisches Verbinden funktioniert nur mit Geräten, die Chromecast unterstützen."),
        "available": MessageLookupByLibrary.simpleMessage("Verfügbar"),
        "availableStorageSpace": m10,
        "backedUpFolders":
            MessageLookupByLibrary.simpleMessage("Gesicherte Ordner"),
        "backgroundWithThem": m11,
        "backup": MessageLookupByLibrary.simpleMessage("Backup"),
        "backupFailed":
            MessageLookupByLibrary.simpleMessage("Sicherung fehlgeschlagen"),
        "backupFile": MessageLookupByLibrary.simpleMessage("Datei sichern"),
        "backupOverMobileData":
            MessageLookupByLibrary.simpleMessage("Über mobile Daten sichern"),
        "backupSettings":
            MessageLookupByLibrary.simpleMessage("Backup-Einstellungen"),
        "backupStatus":
            MessageLookupByLibrary.simpleMessage("Sicherungsstatus"),
        "backupStatusDescription": MessageLookupByLibrary.simpleMessage(
            "Gesicherte Elemente werden hier angezeigt"),
        "backupVideos": MessageLookupByLibrary.simpleMessage("Videos sichern"),
        "beach": MessageLookupByLibrary.simpleMessage("Am Strand"),
        "birthday": MessageLookupByLibrary.simpleMessage("Geburtstag"),
        "birthdayNotifications": MessageLookupByLibrary.simpleMessage(
            "Geburtstagsbenachrichtigungen"),
        "birthdays": MessageLookupByLibrary.simpleMessage("Geburtstage"),
        "blackFridaySale":
            MessageLookupByLibrary.simpleMessage("Black-Friday-Aktion"),
        "blog": MessageLookupByLibrary.simpleMessage("Blog"),
        "cLDesc1": MessageLookupByLibrary.simpleMessage(
            "Zusammen mit der Beta-Version des Video-Streamings und der Arbeit an wiederaufnehmbarem Hoch- und Herunterladen haben wir jetzt das Limit für das Hochladen von Dateien auf 10 GB erhöht. Dies ist ab sofort sowohl in den Desktop- als auch Mobil-Apps verfügbar."),
        "cLDesc2": MessageLookupByLibrary.simpleMessage(
            "Das Hochladen im Hintergrund wird jetzt auch unter iOS unterstützt, zusätzlich zu Android-Geräten. Es ist nicht mehr notwendig, die App zu öffnen, um die letzten Fotos und Videos zu sichern."),
        "cLDesc3": MessageLookupByLibrary.simpleMessage(
            "Wir haben deutliche Verbesserungen an der Darstellung von Erinnerungen vorgenommen, u.a. automatische Wiedergabe, Wischen zur nächsten Erinnerung und vieles mehr."),
        "cLDesc4": MessageLookupByLibrary.simpleMessage(
            "Zusammen mit einer Reihe von Verbesserungen unter der Haube ist es jetzt viel einfacher, alle erkannten Gesichter zu sehen, Feedback zu ähnlichen Gesichtern geben und Gesichter für ein einzelnes Foto hinzuzufügen oder zu entfernen."),
        "cLDesc5": MessageLookupByLibrary.simpleMessage(
            "Du erhältst jetzt eine Opt-Out-Benachrichtigung für alle Geburtstage, die du bei Ente gespeichert hast, zusammen mit einer Sammlung der besten Fotos."),
        "cLDesc6": MessageLookupByLibrary.simpleMessage(
            "Kein Warten mehr auf das Hoch- oder Herunterladen, bevor du die App schließen kannst. Alle Übertragungen können jetzt mittendrin pausiert und fortgesetzt werden, wo du aufgehört hast."),
        "cLTitle1": MessageLookupByLibrary.simpleMessage(
            "Lade große Videodateien hoch"),
        "cLTitle2":
            MessageLookupByLibrary.simpleMessage("Hochladen im Hintergrund"),
        "cLTitle3": MessageLookupByLibrary.simpleMessage(
            "Automatische Wiedergabe von Erinnerungen"),
        "cLTitle4": MessageLookupByLibrary.simpleMessage(
            "Verbesserte Gesichtserkennung"),
        "cLTitle5": MessageLookupByLibrary.simpleMessage(
            "Geburtstags-Benachrichtigungen"),
        "cLTitle6": MessageLookupByLibrary.simpleMessage(
            "Wiederaufnehmbares Hoch- und Herunterladen"),
        "cachedData": MessageLookupByLibrary.simpleMessage("Daten im Cache"),
        "calculating":
            MessageLookupByLibrary.simpleMessage("Wird berechnet..."),
        "canNotOpenBody": MessageLookupByLibrary.simpleMessage(
            "Leider kann dieses Album nicht in der App geöffnet werden."),
        "canNotOpenTitle": MessageLookupByLibrary.simpleMessage(
            "Album kann nicht geöffnet werden"),
        "canNotUploadToAlbumsOwnedByOthers":
            MessageLookupByLibrary.simpleMessage(
                "Kann nicht auf Alben anderer Personen hochladen"),
        "canOnlyCreateLinkForFilesOwnedByYou":
            MessageLookupByLibrary.simpleMessage(
                "Sie können nur Links für Dateien erstellen, die Ihnen gehören"),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "Du kannst nur Dateien entfernen, die dir gehören"),
        "cancel": MessageLookupByLibrary.simpleMessage("Abbrechen"),
        "cancelAccountRecovery":
            MessageLookupByLibrary.simpleMessage("Wiederherstellung abbrechen"),
        "cancelAccountRecoveryBody": MessageLookupByLibrary.simpleMessage(
            "Bist du sicher, dass du die Wiederherstellung abbrechen möchtest?"),
        "cancelOtherSubscription": m12,
        "cancelSubscription":
            MessageLookupByLibrary.simpleMessage("Abonnement kündigen"),
        "cannotAddMorePhotosAfterBecomingViewer": m13,
        "cannotDeleteSharedFiles": MessageLookupByLibrary.simpleMessage(
            "Konnte geteilte Dateien nicht löschen"),
        "castAlbum": MessageLookupByLibrary.simpleMessage("Album übertragen"),
        "castIPMismatchBody": MessageLookupByLibrary.simpleMessage(
            "Stelle sicher, dass du im selben Netzwerk bist wie der Fernseher."),
        "castIPMismatchTitle": MessageLookupByLibrary.simpleMessage(
            "Album konnte nicht auf den Bildschirm übertragen werden"),
        "castInstruction": MessageLookupByLibrary.simpleMessage(
            "Besuche cast.ente.io auf dem Gerät, das du verbinden möchtest.\n\nGib den unten angegebenen Code ein, um das Album auf deinem Fernseher abzuspielen."),
        "centerPoint": MessageLookupByLibrary.simpleMessage("Mittelpunkt"),
        "change": MessageLookupByLibrary.simpleMessage("Ändern"),
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
        "changeYourReferralCode":
            MessageLookupByLibrary.simpleMessage("Empfehlungscode ändern"),
        "checkForUpdates": MessageLookupByLibrary.simpleMessage(
            "Nach Aktualisierungen suchen"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Bitte überprüfe deinen E-Mail-Posteingang (und Spam), um die Verifizierung abzuschließen"),
        "checkStatus":
            MessageLookupByLibrary.simpleMessage("Status überprüfen"),
        "checking": MessageLookupByLibrary.simpleMessage("Wird geprüft..."),
        "checkingModels":
            MessageLookupByLibrary.simpleMessage("Prüfe Modelle..."),
        "city": MessageLookupByLibrary.simpleMessage("In der Stadt"),
        "claimFreeStorage":
            MessageLookupByLibrary.simpleMessage("Freien Speicher einlösen"),
        "claimMore": MessageLookupByLibrary.simpleMessage("Mehr einlösen!"),
        "claimed": MessageLookupByLibrary.simpleMessage("Eingelöst"),
        "claimedStorageSoFar": m14,
        "cleanUncategorized":
            MessageLookupByLibrary.simpleMessage("Unkategorisiert leeren"),
        "cleanUncategorizedDescription": MessageLookupByLibrary.simpleMessage(
            "Entferne alle Dateien von \"Unkategorisiert\" die in anderen Alben vorhanden sind"),
        "clearCaches": MessageLookupByLibrary.simpleMessage("Cache löschen"),
        "clearIndexes": MessageLookupByLibrary.simpleMessage("Indexe löschen"),
        "click": MessageLookupByLibrary.simpleMessage("• Klick"),
        "clickOnTheOverflowMenu": MessageLookupByLibrary.simpleMessage(
            "• Klicken Sie auf das Überlaufmenü"),
        "clickToInstallOurBestVersionYet": MessageLookupByLibrary.simpleMessage(
            "Klicke, um unsere bisher beste Version zu installieren"),
        "close": MessageLookupByLibrary.simpleMessage("Schließen"),
        "clubByCaptureTime": MessageLookupByLibrary.simpleMessage(
            "Nach Aufnahmezeit gruppieren"),
        "clubByFileName":
            MessageLookupByLibrary.simpleMessage("Nach Dateiname gruppieren"),
        "clusteringProgress":
            MessageLookupByLibrary.simpleMessage("Fortschritt beim Clustering"),
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("Code eingelöst"),
        "codeChangeLimitReached": MessageLookupByLibrary.simpleMessage(
            "Entschuldigung, du hast das Limit der Code-Änderungen erreicht."),
        "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Code in Zwischenablage kopiert"),
        "codeUsedByYou":
            MessageLookupByLibrary.simpleMessage("Von dir benutzter Code"),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Erstelle einen Link, mit dem andere Fotos in dem geteilten Album sehen und selbst welche hinzufügen können - ohne dass sie die ein Ente-Konto oder die App benötigen. Ideal um gemeinsam Fotos von Events zu sammeln."),
        "collaborativeLink":
            MessageLookupByLibrary.simpleMessage("Gemeinschaftlicher Link"),
        "collaborativeLinkCreatedFor": m15,
        "collaborator": MessageLookupByLibrary.simpleMessage("Bearbeiter"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Bearbeiter können Fotos & Videos zu dem geteilten Album hinzufügen."),
        "collaboratorsSuccessfullyAdded": m16,
        "collageLayout": MessageLookupByLibrary.simpleMessage("Layout"),
        "collageSaved": MessageLookupByLibrary.simpleMessage(
            "Collage in Galerie gespeichert"),
        "collect": MessageLookupByLibrary.simpleMessage("Sammeln"),
        "collectEventPhotos": MessageLookupByLibrary.simpleMessage(
            "Gemeinsam Event-Fotos sammeln"),
        "collectPhotos": MessageLookupByLibrary.simpleMessage("Fotos sammeln"),
        "collectPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Erstelle einen Link, mit dem deine Freunde Fotos in Originalqualität hochladen können."),
        "color": MessageLookupByLibrary.simpleMessage("Farbe"),
        "configuration": MessageLookupByLibrary.simpleMessage("Konfiguration"),
        "confirm": MessageLookupByLibrary.simpleMessage("Bestätigen"),
        "confirm2FADisable": MessageLookupByLibrary.simpleMessage(
            "Bist du sicher, dass du die Zwei-Faktor-Authentifizierung (2FA) deaktivieren willst?"),
        "confirmAccountDeletion":
            MessageLookupByLibrary.simpleMessage("Kontolöschung bestätigen"),
        "confirmAddingTrustedContact": m17,
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Ja, ich möchte dieses Konto und alle enthaltenen Daten über alle Apps hinweg endgültig löschen."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Passwort wiederholen"),
        "confirmPlanChange":
            MessageLookupByLibrary.simpleMessage("Aboänderungen bestätigen"),
        "confirmRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Wiederherstellungsschlüssel bestätigen"),
        "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Bestätige deinen Wiederherstellungsschlüssel"),
        "connectToDevice":
            MessageLookupByLibrary.simpleMessage("Mit Gerät verbinden"),
        "contactFamilyAdmin": m18,
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("Support kontaktieren"),
        "contactToManageSubscription": m19,
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
        "curatedMemories":
            MessageLookupByLibrary.simpleMessage("Ausgewählte Erinnerungen"),
        "currentUsageIs":
            MessageLookupByLibrary.simpleMessage("Aktuell genutzt werden "),
        "currentlyRunning":
            MessageLookupByLibrary.simpleMessage("läuft gerade"),
        "custom": MessageLookupByLibrary.simpleMessage("Benutzerdefiniert"),
        "customEndpoint": m20,
        "darkTheme": MessageLookupByLibrary.simpleMessage("Dunkel"),
        "dayToday": MessageLookupByLibrary.simpleMessage("Heute"),
        "dayYesterday": MessageLookupByLibrary.simpleMessage("Gestern"),
        "declineTrustInvite":
            MessageLookupByLibrary.simpleMessage("Einladung ablehnen"),
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
            "Bitte sende eine E-Mail an <warning>account-deletion@ente.io</warning> von Ihrer bei uns hinterlegten E-Mail-Adresse."),
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
        "deleteItemCount": m21,
        "deleteLocation":
            MessageLookupByLibrary.simpleMessage("Standort löschen"),
        "deleteMultipleAlbumDialog": m22,
        "deletePhotos": MessageLookupByLibrary.simpleMessage("Fotos löschen"),
        "deleteProgress": m23,
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
        "deviceLock": MessageLookupByLibrary.simpleMessage("Gerätsperre"),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
            "Verhindern, dass der Bildschirm gesperrt wird, während die App im Vordergrund ist und eine Sicherung läuft. Das ist normalerweise nicht notwendig, kann aber dabei helfen, große Uploads wie einen Erstimport schneller abzuschließen."),
        "deviceNotFound":
            MessageLookupByLibrary.simpleMessage("Gerät nicht gefunden"),
        "didYouKnow": MessageLookupByLibrary.simpleMessage("Schon gewusst?"),
        "different": MessageLookupByLibrary.simpleMessage("Verschieden"),
        "disableAutoLock": MessageLookupByLibrary.simpleMessage(
            "Automatische Sperre deaktivieren"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Zuschauer können weiterhin Screenshots oder mit anderen externen Programmen Kopien der Bilder machen."),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Bitte beachten Sie:"),
        "disableLinkMessage": m24,
        "disableTwofactor": MessageLookupByLibrary.simpleMessage(
            "Zweiten Faktor (2FA) deaktivieren"),
        "disablingTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Zwei-Faktor-Authentifizierung (2FA) wird deaktiviert..."),
        "discord": MessageLookupByLibrary.simpleMessage("Discord"),
        "discover": MessageLookupByLibrary.simpleMessage("Entdecken"),
        "discover_babies": MessageLookupByLibrary.simpleMessage("Babys"),
        "discover_celebrations": MessageLookupByLibrary.simpleMessage("Feiern"),
        "discover_food": MessageLookupByLibrary.simpleMessage("Essen"),
        "discover_greenery": MessageLookupByLibrary.simpleMessage("Grün"),
        "discover_hills": MessageLookupByLibrary.simpleMessage("Berge"),
        "discover_identity": MessageLookupByLibrary.simpleMessage("Identität"),
        "discover_memes": MessageLookupByLibrary.simpleMessage("Memes"),
        "discover_notes": MessageLookupByLibrary.simpleMessage("Notizen"),
        "discover_pets": MessageLookupByLibrary.simpleMessage("Haustiere"),
        "discover_receipts": MessageLookupByLibrary.simpleMessage("Belege"),
        "discover_screenshots":
            MessageLookupByLibrary.simpleMessage("Bildschirmfotos"),
        "discover_selfies": MessageLookupByLibrary.simpleMessage("Selfies"),
        "discover_sunset":
            MessageLookupByLibrary.simpleMessage("Sonnenuntergang"),
        "discover_visiting_cards":
            MessageLookupByLibrary.simpleMessage("Visitenkarten"),
        "discover_wallpapers":
            MessageLookupByLibrary.simpleMessage("Hintergründe"),
        "dismiss": MessageLookupByLibrary.simpleMessage("Verwerfen"),
        "distanceInKMUnit": MessageLookupByLibrary.simpleMessage("km"),
        "doNotSignOut":
            MessageLookupByLibrary.simpleMessage("Melde dich nicht ab"),
        "doThisLater": MessageLookupByLibrary.simpleMessage("Später erledigen"),
        "doYouWantToDiscardTheEditsYouHaveMade":
            MessageLookupByLibrary.simpleMessage(
                "Möchtest du deine Änderungen verwerfen?"),
        "done": MessageLookupByLibrary.simpleMessage("Fertig"),
        "dontSave": MessageLookupByLibrary.simpleMessage("Nicht speichern"),
        "doubleYourStorage":
            MessageLookupByLibrary.simpleMessage("Speicherplatz verdoppeln"),
        "download": MessageLookupByLibrary.simpleMessage("Herunterladen"),
        "downloadFailed": MessageLookupByLibrary.simpleMessage(
            "Herunterladen fehlgeschlagen"),
        "downloading":
            MessageLookupByLibrary.simpleMessage("Wird heruntergeladen..."),
        "dropSupportEmail": m25,
        "duplicateFileCountWithStorageSaved": m26,
        "duplicateItemsGroup": m27,
        "edit": MessageLookupByLibrary.simpleMessage("Bearbeiten"),
        "editEmailAlreadyLinked": m28,
        "editLocation":
            MessageLookupByLibrary.simpleMessage("Standort bearbeiten"),
        "editLocationTagTitle":
            MessageLookupByLibrary.simpleMessage("Standort bearbeiten"),
        "editPerson": MessageLookupByLibrary.simpleMessage("Person bearbeiten"),
        "editTime": MessageLookupByLibrary.simpleMessage("Uhrzeit ändern"),
        "editsSaved":
            MessageLookupByLibrary.simpleMessage("Änderungen gespeichert"),
        "editsToLocationWillOnlyBeSeenWithinEnte":
            MessageLookupByLibrary.simpleMessage(
                "Edits to location will only be seen within Ente"),
        "eligible": MessageLookupByLibrary.simpleMessage("zulässig"),
        "email": MessageLookupByLibrary.simpleMessage("E-Mail"),
        "emailAlreadyRegistered": MessageLookupByLibrary.simpleMessage(
            "E-Mail ist bereits registriert."),
        "emailChangedTo": m29,
        "emailDoesNotHaveEnteAccount": m30,
        "emailNoEnteAccount": m31,
        "emailNotRegistered":
            MessageLookupByLibrary.simpleMessage("E-Mail nicht registriert."),
        "emailVerificationToggle":
            MessageLookupByLibrary.simpleMessage("E-Mail-Verifizierung"),
        "emailYourLogs": MessageLookupByLibrary.simpleMessage(
            "Protokolle per E-Mail senden"),
        "embracingThem": m32,
        "emergencyContacts":
            MessageLookupByLibrary.simpleMessage("Notfallkontakte"),
        "empty": MessageLookupByLibrary.simpleMessage("Leeren"),
        "emptyTrash":
            MessageLookupByLibrary.simpleMessage("Papierkorb leeren?"),
        "enable": MessageLookupByLibrary.simpleMessage("Aktivieren"),
        "enableMLIndexingDesc": MessageLookupByLibrary.simpleMessage(
            "Ente unterstützt maschinelles Lernen für Gesichtserkennung, magische Suche und andere erweiterte Suchfunktionen auf dem Gerät"),
        "enableMachineLearningBanner": MessageLookupByLibrary.simpleMessage(
            "Aktiviere maschinelles Lernen für die magische Suche und Gesichtserkennung"),
        "enableMaps": MessageLookupByLibrary.simpleMessage("Karten aktivieren"),
        "enableMapsDesc": MessageLookupByLibrary.simpleMessage(
            "Dies zeigt Ihre Fotos auf einer Weltkarte.\n\nDiese Karte wird von OpenStreetMap gehostet und die genauen Standorte Ihrer Fotos werden niemals geteilt.\n\nSie können diese Funktion jederzeit in den Einstellungen deaktivieren."),
        "enabled": MessageLookupByLibrary.simpleMessage("Aktiviert"),
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
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
            "Ente <i> benötigt Berechtigung, um </i> Ihre Fotos zu sichern"),
        "enteSubscriptionPitch": MessageLookupByLibrary.simpleMessage(
            "Ente sichert deine Erinnerungen, sodass sie dir nie verloren gehen, selbst wenn du dein Gerät verlierst."),
        "enteSubscriptionShareWithFamily": MessageLookupByLibrary.simpleMessage(
            "Deine Familie kann zu deinem Abo hinzugefügt werden."),
        "enterAlbumName":
            MessageLookupByLibrary.simpleMessage("Albumname eingeben"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Code eingeben"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
            "Gib den Code deines Freundes ein, damit sie beide kostenlosen Speicherplatz erhalten"),
        "enterDateOfBirth":
            MessageLookupByLibrary.simpleMessage("Geburtstag (optional)"),
        "enterEmail": MessageLookupByLibrary.simpleMessage("E-Mail eingeben"),
        "enterFileName":
            MessageLookupByLibrary.simpleMessage("Dateinamen eingeben"),
        "enterName": MessageLookupByLibrary.simpleMessage("Name eingeben"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Gib ein neues Passwort ein, mit dem wir deine Daten verschlüsseln können"),
        "enterPassword":
            MessageLookupByLibrary.simpleMessage("Passwort eingeben"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Gib ein Passwort ein, mit dem wir deine Daten verschlüsseln können"),
        "enterPersonName":
            MessageLookupByLibrary.simpleMessage("Namen der Person eingeben"),
        "enterPin": MessageLookupByLibrary.simpleMessage("PIN eingeben"),
        "enterReferralCode": MessageLookupByLibrary.simpleMessage(
            "Gib den Weiterempfehlungs-Code ein"),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Gib den 6-stelligen Code aus\ndeiner Authentifizierungs-App ein"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "Bitte gib eine gültige E-Mail-Adresse ein."),
        "enterYourEmailAddress": MessageLookupByLibrary.simpleMessage(
            "Gib deine E-Mail-Adresse ein"),
        "enterYourNewEmailAddress": MessageLookupByLibrary.simpleMessage(
            "Gib Deine neue E-Mail-Adresse ein"),
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
            "Dieser Link ist abgelaufen. Bitte wähle ein neues Ablaufdatum oder deaktiviere das Ablaufdatum des Links."),
        "exportLogs":
            MessageLookupByLibrary.simpleMessage("Protokolle exportieren"),
        "exportYourData":
            MessageLookupByLibrary.simpleMessage("Daten exportieren"),
        "extraPhotosFound":
            MessageLookupByLibrary.simpleMessage("Zusätzliche Fotos gefunden"),
        "extraPhotosFoundFor": m33,
        "faceNotClusteredYet": MessageLookupByLibrary.simpleMessage(
            "Gesicht ist noch nicht gruppiert, bitte komm später zurück"),
        "faceRecognition":
            MessageLookupByLibrary.simpleMessage("Gesichtserkennung"),
        "faceThumbnailGenerationFailed": MessageLookupByLibrary.simpleMessage(
            "Vorschaubilder konnten nicht erstellt werden"),
        "faces": MessageLookupByLibrary.simpleMessage("Gesichter"),
        "failed": MessageLookupByLibrary.simpleMessage("Fehlgeschlagen"),
        "failedToApplyCode": MessageLookupByLibrary.simpleMessage(
            "Der Code konnte nicht aktiviert werden"),
        "failedToCancel":
            MessageLookupByLibrary.simpleMessage("Kündigung fehlgeschlagen"),
        "failedToDownloadVideo": MessageLookupByLibrary.simpleMessage(
            "Herunterladen des Videos fehlgeschlagen"),
        "failedToFetchActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Fehler beim Abrufen der aktiven Sitzungen"),
        "failedToFetchOriginalForEdit": MessageLookupByLibrary.simpleMessage(
            "Fehler beim Abrufen des Originals zur Bearbeitung"),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "Die Weiterempfehlungs-Details können nicht abgerufen werden. Bitte versuche es später erneut."),
        "failedToLoadAlbums": MessageLookupByLibrary.simpleMessage(
            "Laden der Alben fehlgeschlagen"),
        "failedToPlayVideo": MessageLookupByLibrary.simpleMessage(
            "Fehler beim Abspielen des Videos"),
        "failedToRefreshStripeSubscription":
            MessageLookupByLibrary.simpleMessage(
                "Abonnement konnte nicht erneuert werden"),
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
        "feastingWithThem": m34,
        "feedback": MessageLookupByLibrary.simpleMessage("Rückmeldung"),
        "file": MessageLookupByLibrary.simpleMessage("Datei"),
        "fileAnalysisFailed": MessageLookupByLibrary.simpleMessage(
            "Datei konnte nicht analysiert werden"),
        "fileFailedToSaveToGallery": MessageLookupByLibrary.simpleMessage(
            "Fehler beim Speichern der Datei in der Galerie"),
        "fileInfoAddDescHint":
            MessageLookupByLibrary.simpleMessage("Beschreibung hinzufügen …"),
        "fileNotUploadedYet": MessageLookupByLibrary.simpleMessage(
            "Datei wurde noch nicht hochgeladen"),
        "fileSavedToGallery": MessageLookupByLibrary.simpleMessage(
            "Datei in Galerie gespeichert"),
        "fileTypes": MessageLookupByLibrary.simpleMessage("Dateitypen"),
        "fileTypesAndNames":
            MessageLookupByLibrary.simpleMessage("Dateitypen und -namen"),
        "filesBackedUpFromDevice": m35,
        "filesBackedUpInAlbum": m36,
        "filesDeleted":
            MessageLookupByLibrary.simpleMessage("Dateien gelöscht"),
        "filesSavedToGallery": MessageLookupByLibrary.simpleMessage(
            "Dateien in Galerie gespeichert"),
        "findPeopleByName": MessageLookupByLibrary.simpleMessage(
            "Finde Personen schnell nach Namen"),
        "findThemQuickly":
            MessageLookupByLibrary.simpleMessage("Finde sie schnell"),
        "flip": MessageLookupByLibrary.simpleMessage("Spiegeln"),
        "food": MessageLookupByLibrary.simpleMessage("Kulinarische Genüsse"),
        "forYourMemories":
            MessageLookupByLibrary.simpleMessage("Als Erinnerung"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Passwort vergessen"),
        "foundFaces":
            MessageLookupByLibrary.simpleMessage("Gesichter gefunden"),
        "freeStorageClaimed": MessageLookupByLibrary.simpleMessage(
            "Kostenlos hinzugefügter Speicherplatz"),
        "freeStorageOnReferralSuccess": m37,
        "freeStorageUsable": MessageLookupByLibrary.simpleMessage(
            "Freier Speicherplatz nutzbar"),
        "freeTrial":
            MessageLookupByLibrary.simpleMessage("Kostenlose Testphase"),
        "freeTrialValidTill": m38,
        "freeUpAccessPostDelete": m39,
        "freeUpAmount": m40,
        "freeUpDeviceSpace":
            MessageLookupByLibrary.simpleMessage("Gerätespeicher freiräumen"),
        "freeUpDeviceSpaceDesc": MessageLookupByLibrary.simpleMessage(
            "Spare Speicherplatz auf deinem Gerät, indem du Dateien löschst, die bereits gesichert wurden."),
        "freeUpSpace":
            MessageLookupByLibrary.simpleMessage("Speicherplatz freigeben"),
        "freeUpSpaceSaving": m41,
        "gallery": MessageLookupByLibrary.simpleMessage("Galerie"),
        "galleryMemoryLimitInfo": MessageLookupByLibrary.simpleMessage(
            "Bis zu 1000 Erinnerungsstücke angezeigt in der Galerie"),
        "general": MessageLookupByLibrary.simpleMessage("Allgemein"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Generierung von Verschlüsselungscodes..."),
        "genericProgress": m42,
        "goToSettings":
            MessageLookupByLibrary.simpleMessage("Zu den Einstellungen"),
        "googlePlayId": MessageLookupByLibrary.simpleMessage("Google Play ID"),
        "grantFullAccessPrompt": MessageLookupByLibrary.simpleMessage(
            "Bitte gewähre Zugang zu allen Fotos in der Einstellungen App"),
        "grantPermission":
            MessageLookupByLibrary.simpleMessage("Zugriff gewähren"),
        "greenery": MessageLookupByLibrary.simpleMessage("Im Grünen"),
        "groupNearbyPhotos": MessageLookupByLibrary.simpleMessage(
            "Fotos in der Nähe gruppieren"),
        "guestView": MessageLookupByLibrary.simpleMessage("Gastansicht"),
        "guestViewEnablePreSteps": MessageLookupByLibrary.simpleMessage(
            "Bitte richte einen Gerätepasscode oder eine Bildschirmsperre ein, um die Gastansicht zu nutzen."),
        "happyBirthday": MessageLookupByLibrary.simpleMessage(
            "Herzlichen Glückwunsch zum Geburtstag! 🥳"),
        "hearUsExplanation": MessageLookupByLibrary.simpleMessage(
            "Wir tracken keine App-Installationen. Es würde uns jedoch helfen, wenn du uns mitteilst, wie du von uns erfahren hast!"),
        "hearUsWhereTitle": MessageLookupByLibrary.simpleMessage(
            "Wie hast du von Ente erfahren? (optional)"),
        "help": MessageLookupByLibrary.simpleMessage("Hilfe"),
        "hidden": MessageLookupByLibrary.simpleMessage("Versteckt"),
        "hide": MessageLookupByLibrary.simpleMessage("Ausblenden"),
        "hideContent":
            MessageLookupByLibrary.simpleMessage("Inhalte verstecken"),
        "hideContentDescriptionAndroid": MessageLookupByLibrary.simpleMessage(
            "Versteckt Inhalte der App beim Wechseln zwischen Apps und deaktiviert Screenshots"),
        "hideContentDescriptionIos": MessageLookupByLibrary.simpleMessage(
            "Versteckt Inhalte der App beim Wechseln zwischen Apps"),
        "hideSharedItemsFromHomeGallery": MessageLookupByLibrary.simpleMessage(
            "Geteilte Elemente in der Home-Galerie ausblenden"),
        "hiding": MessageLookupByLibrary.simpleMessage("Verstecken..."),
        "hikingWithThem": m43,
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
        "ignore": MessageLookupByLibrary.simpleMessage("Ignorieren"),
        "ignoreUpdate": MessageLookupByLibrary.simpleMessage("Ignorieren"),
        "ignored": MessageLookupByLibrary.simpleMessage("ignoriert"),
        "ignoredFolderUploadReason": MessageLookupByLibrary.simpleMessage(
            "Ein paar Dateien in diesem Album werden nicht hochgeladen, weil sie in der Vergangenheit schonmal aus Ente gelöscht wurden."),
        "imageNotAnalyzed":
            MessageLookupByLibrary.simpleMessage("Bild nicht analysiert"),
        "immediately": MessageLookupByLibrary.simpleMessage("Sofort"),
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
        "indexingPausedStatusDescription": MessageLookupByLibrary.simpleMessage(
            "Die Indizierung ist pausiert. Sie wird automatisch fortgesetzt, wenn das Gerät bereit ist. Das Gerät wird als bereit angesehen, wenn sich der Akkustand, die Akkugesundheit und der thermische Zustand in einem gesunden Bereich befinden."),
        "ineligible": MessageLookupByLibrary.simpleMessage("Unzulässig"),
        "info": MessageLookupByLibrary.simpleMessage("Info"),
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
            "Der eingegebene Wiederherstellungsschlüssel ist nicht gültig. Bitte stelle sicher, dass er aus 24 Wörtern zusammengesetzt ist und jedes dieser Worte richtig geschrieben wurde.\n\nSolltest du den Wiederherstellungscode eingegeben haben, stelle bitte sicher, dass dieser 64 Zeichen lang ist und ebenfalls richtig geschrieben wurde."),
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
        "itemCount": m44,
        "itemsShowTheNumberOfDaysRemainingBeforePermanentDeletion":
            MessageLookupByLibrary.simpleMessage(
                "Elemente zeigen die Anzahl der Tage bis zum dauerhaften Löschen an"),
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "Ausgewählte Elemente werden aus diesem Album entfernt"),
        "join": MessageLookupByLibrary.simpleMessage("Beitreten"),
        "joinAlbum": MessageLookupByLibrary.simpleMessage("Album beitreten"),
        "joinAlbumConfirmationDialogBody": MessageLookupByLibrary.simpleMessage(
            "Wenn du einem Album beitrittst, wird deine E-Mail-Adresse für seine Teilnehmer sichtbar."),
        "joinAlbumSubtext": MessageLookupByLibrary.simpleMessage(
            "um deine Fotos anzuzeigen und hinzuzufügen"),
        "joinAlbumSubtextViewer": MessageLookupByLibrary.simpleMessage(
            "um dies zu geteilten Alben hinzuzufügen"),
        "joinDiscord":
            MessageLookupByLibrary.simpleMessage("Discord beitreten"),
        "keepPhotos": MessageLookupByLibrary.simpleMessage("Fotos behalten"),
        "kiloMeterUnit": MessageLookupByLibrary.simpleMessage("km"),
        "kindlyHelpUsWithThisInformation":
            MessageLookupByLibrary.simpleMessage("Bitte gib diese Daten ein"),
        "language": MessageLookupByLibrary.simpleMessage("Sprache"),
        "lastTimeWithThem": m45,
        "lastUpdated":
            MessageLookupByLibrary.simpleMessage("Zuletzt aktualisiert"),
        "lastYearsTrip":
            MessageLookupByLibrary.simpleMessage("Reise im letzten Jahr"),
        "leave": MessageLookupByLibrary.simpleMessage("Verlassen"),
        "leaveAlbum": MessageLookupByLibrary.simpleMessage("Album verlassen"),
        "leaveFamily":
            MessageLookupByLibrary.simpleMessage("Familienabo verlassen"),
        "leaveSharedAlbum":
            MessageLookupByLibrary.simpleMessage("Geteiltes Album verlassen?"),
        "left": MessageLookupByLibrary.simpleMessage("Links"),
        "legacy": MessageLookupByLibrary.simpleMessage("Digitales Erbe"),
        "legacyAccounts":
            MessageLookupByLibrary.simpleMessage("Digital geerbte Konten"),
        "legacyInvite": m46,
        "legacyPageDesc": MessageLookupByLibrary.simpleMessage(
            "Das digitale Erbe erlaubt vertrauenswürdigen Kontakten den Zugriff auf dein Konto in deiner Abwesenheit."),
        "legacyPageDesc2": MessageLookupByLibrary.simpleMessage(
            "Vertrauenswürdige Kontakte können eine Kontowiederherstellung einleiten und, wenn dies nicht innerhalb von 30 Tagen blockiert wird, dein Passwort und den Kontozugriff zurücksetzen."),
        "light": MessageLookupByLibrary.simpleMessage("Hell"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("Hell"),
        "link": MessageLookupByLibrary.simpleMessage("Verknüpfen"),
        "linkCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Link in Zwischenablage kopiert"),
        "linkDeviceLimit": MessageLookupByLibrary.simpleMessage("Geräte-Limit"),
        "linkEmail":
            MessageLookupByLibrary.simpleMessage("E-Mail-Adresse verknüpfen"),
        "linkEmailToContactBannerCaption":
            MessageLookupByLibrary.simpleMessage("für schnelleres Teilen"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Aktiviert"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Abgelaufen"),
        "linkExpiresOn": m47,
        "linkExpiry":
            MessageLookupByLibrary.simpleMessage("Ablaufdatum des Links"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("Link ist abgelaufen"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Niemals"),
        "linkPerson": MessageLookupByLibrary.simpleMessage("Person verknüpfen"),
        "linkPersonCaption": MessageLookupByLibrary.simpleMessage(
            "um besseres Teilen zu ermöglichen"),
        "linkPersonToEmail": m48,
        "linkPersonToEmailConfirmation": m49,
        "livePhotos": MessageLookupByLibrary.simpleMessage("Live-Fotos"),
        "loadMessage1": MessageLookupByLibrary.simpleMessage(
            "Du kannst dein Abonnement mit deiner Familie teilen"),
        "loadMessage2": MessageLookupByLibrary.simpleMessage(
            "Wir haben bereits über 200 Millionen Erinnerungen bewahrt"),
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
        "loadingYourPhotos":
            MessageLookupByLibrary.simpleMessage("Lade deine Fotos..."),
        "localGallery": MessageLookupByLibrary.simpleMessage("Lokale Galerie"),
        "localIndexing":
            MessageLookupByLibrary.simpleMessage("Lokale Indizierung"),
        "localSyncErrorMessage": MessageLookupByLibrary.simpleMessage(
            "Es sieht so aus, als ob etwas schiefgelaufen ist, da die lokale Foto-Synchronisierung länger dauert als erwartet. Bitte kontaktiere unser Support-Team"),
        "location": MessageLookupByLibrary.simpleMessage("Standort"),
        "locationName": MessageLookupByLibrary.simpleMessage("Standortname"),
        "locationTagFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "Ein Standort-Tag gruppiert alle Fotos, die in einem Radius eines Fotos aufgenommen wurden"),
        "locations": MessageLookupByLibrary.simpleMessage("Orte"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Sperren"),
        "lockscreen": MessageLookupByLibrary.simpleMessage("Sperrbildschirm"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Anmelden"),
        "loggingOut": MessageLookupByLibrary.simpleMessage("Abmeldung..."),
        "loginSessionExpired":
            MessageLookupByLibrary.simpleMessage("Sitzung abgelaufen"),
        "loginSessionExpiredDetails": MessageLookupByLibrary.simpleMessage(
            "Deine Sitzung ist abgelaufen. Bitte melde Dich erneut an."),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "Mit dem Klick auf \"Anmelden\" stimme ich den <u-terms>Nutzungsbedingungen</u-terms> und der <u-policy>Datenschutzerklärung</u-policy> zu"),
        "loginWithTOTP":
            MessageLookupByLibrary.simpleMessage("Mit TOTP anmelden"),
        "logout": MessageLookupByLibrary.simpleMessage("Ausloggen"),
        "logsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Dies wird über Logs gesendet, um uns zu helfen, Ihr Problem zu beheben. Bitte beachten Sie, dass Dateinamen aufgenommen werden, um Probleme mit bestimmten Dateien zu beheben."),
        "longPressAnEmailToVerifyEndToEndEncryption":
            MessageLookupByLibrary.simpleMessage(
                "Lange auf eine E-Mail drücken, um die Ende-zu-Ende-Verschlüsselung zu überprüfen."),
        "longpressOnAnItemToViewInFullscreen": MessageLookupByLibrary.simpleMessage(
            "Drücken Sie lange auf ein Element, um es im Vollbildmodus anzuzeigen"),
        "lookBackOnYourMemories": MessageLookupByLibrary.simpleMessage(
            "Schau zurück auf deine Erinnerungen 🌄"),
        "loopVideoOff":
            MessageLookupByLibrary.simpleMessage("Videoschleife aus"),
        "loopVideoOn": MessageLookupByLibrary.simpleMessage("Videoschleife an"),
        "lostDevice": MessageLookupByLibrary.simpleMessage("Gerät verloren?"),
        "machineLearning":
            MessageLookupByLibrary.simpleMessage("Maschinelles Lernen"),
        "magicSearch": MessageLookupByLibrary.simpleMessage("Magische Suche"),
        "magicSearchHint": MessageLookupByLibrary.simpleMessage(
            "Die magische Suche erlaubt das Durchsuchen von Fotos nach ihrem Inhalt, z.B. \'Blumen\', \'rotes Auto\', \'Ausweisdokumente\'"),
        "manage": MessageLookupByLibrary.simpleMessage("Verwalten"),
        "manageDeviceStorage":
            MessageLookupByLibrary.simpleMessage("Geräte-Cache verwalten"),
        "manageDeviceStorageDesc": MessageLookupByLibrary.simpleMessage(
            "Lokalen Cache-Speicher überprüfen und löschen."),
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
        "me": MessageLookupByLibrary.simpleMessage("Ich"),
        "memories": MessageLookupByLibrary.simpleMessage("Erinnerungen"),
        "memoriesWidgetDesc": MessageLookupByLibrary.simpleMessage(
            "Wähle die Arten von Erinnerungen, die du auf der Startseite sehen möchtest."),
        "memoryCount": m50,
        "merchandise": MessageLookupByLibrary.simpleMessage("Merchandise"),
        "merge": MessageLookupByLibrary.simpleMessage("Zusammenführen"),
        "mergeWithExisting": MessageLookupByLibrary.simpleMessage(
            "Mit vorhandenem zusammenführen"),
        "mergedPhotos":
            MessageLookupByLibrary.simpleMessage("Zusammengeführte Fotos"),
        "mlConsent": MessageLookupByLibrary.simpleMessage(
            "Maschinelles Lernen aktivieren"),
        "mlConsentConfirmation": MessageLookupByLibrary.simpleMessage(
            "Ich verstehe und möchte das maschinelle Lernen aktivieren"),
        "mlConsentDescription": MessageLookupByLibrary.simpleMessage(
            "Wenn du das maschinelle Lernen aktivierst, wird Ente Informationen wie etwa Gesichtsgeometrie aus Dateien extrahieren, einschließlich derjenigen, die mit dir geteilt werden.\n\nDies geschieht auf deinem Gerät und alle erzeugten biometrischen Informationen werden Ende-zu-Ende-verschlüsselt."),
        "mlConsentPrivacy": MessageLookupByLibrary.simpleMessage(
            "Bitte klicke hier für weitere Details zu dieser Funktion in unserer Datenschutzerklärung"),
        "mlConsentTitle": MessageLookupByLibrary.simpleMessage(
            "Maschinelles Lernen aktivieren?"),
        "mlIndexingDescription": MessageLookupByLibrary.simpleMessage(
            "Bitte beachte, dass das maschinelle Lernen zu einem höheren Daten- und Akkuverbrauch führen wird, bis alle Elemente indiziert sind. Du kannst die Desktop-App für eine schnellere Indizierung verwenden, alle Ergebnisse werden automatisch synchronisiert."),
        "mobileWebDesktop":
            MessageLookupByLibrary.simpleMessage("Mobil, Web, Desktop"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Mittel"),
        "modifyYourQueryOrTrySearchingFor":
            MessageLookupByLibrary.simpleMessage(
                "Ändere deine Suchanfrage oder suche nach"),
        "moments": MessageLookupByLibrary.simpleMessage("Momente"),
        "month": MessageLookupByLibrary.simpleMessage("Monat"),
        "monthly": MessageLookupByLibrary.simpleMessage("Monatlich"),
        "moon": MessageLookupByLibrary.simpleMessage("Bei Mondschein"),
        "moreDetails": MessageLookupByLibrary.simpleMessage("Weitere Details"),
        "mostRecent": MessageLookupByLibrary.simpleMessage("Neuste"),
        "mostRelevant": MessageLookupByLibrary.simpleMessage("Nach Relevanz"),
        "mountains": MessageLookupByLibrary.simpleMessage("Über den Bergen"),
        "moveItem": m51,
        "moveSelectedPhotosToOneDate": MessageLookupByLibrary.simpleMessage(
            "Ausgewählte Fotos auf ein Datum verschieben"),
        "moveToAlbum":
            MessageLookupByLibrary.simpleMessage("Zum Album verschieben"),
        "moveToHiddenAlbum": MessageLookupByLibrary.simpleMessage(
            "Zu verstecktem Album verschieben"),
        "movedSuccessfullyTo": m52,
        "movedToTrash": MessageLookupByLibrary.simpleMessage(
            "In den Papierkorb verschoben"),
        "movingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Verschiebe Dateien in Album..."),
        "name": MessageLookupByLibrary.simpleMessage("Name"),
        "nameTheAlbum": MessageLookupByLibrary.simpleMessage("Album benennen"),
        "networkConnectionRefusedErr": MessageLookupByLibrary.simpleMessage(
            "Ente ist im Moment nicht erreichbar. Bitte versuchen Sie es später erneut. Sollte das Problem bestehen bleiben, wenden Sie sich bitte an den Support."),
        "networkHostLookUpErr": MessageLookupByLibrary.simpleMessage(
            "Ente ist im Moment nicht erreichbar. Bitte überprüfen Sie Ihre Netzwerkeinstellungen. Sollte das Problem bestehen bleiben, wenden Sie sich bitte an den Support."),
        "never": MessageLookupByLibrary.simpleMessage("Niemals"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Neues Album"),
        "newLocation": MessageLookupByLibrary.simpleMessage("Neuer Ort"),
        "newPerson": MessageLookupByLibrary.simpleMessage("Neue Person"),
        "newPhotosEmoji": MessageLookupByLibrary.simpleMessage(" neue 📸"),
        "newRange": MessageLookupByLibrary.simpleMessage("Neue Auswahl"),
        "newToEnte": MessageLookupByLibrary.simpleMessage("Neu bei Ente"),
        "newest": MessageLookupByLibrary.simpleMessage("Zuletzt"),
        "next": MessageLookupByLibrary.simpleMessage("Weiter"),
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
        "noEnteAccountExclamation":
            MessageLookupByLibrary.simpleMessage("Kein Ente-Konto!"),
        "noExifData": MessageLookupByLibrary.simpleMessage("Keine Exif-Daten"),
        "noFacesFound":
            MessageLookupByLibrary.simpleMessage("Keine Gesichter gefunden"),
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
        "noQuickLinksSelected": MessageLookupByLibrary.simpleMessage(
            "Keine schnellen Links ausgewählt"),
        "noRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Kein Wiederherstellungs-Schlüssel?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "Aufgrund unseres Ende-zu-Ende-Verschlüsselungsprotokolls können deine Daten nicht ohne dein Passwort oder deinen Wiederherstellungs-Schlüssel entschlüsselt werden"),
        "noResults": MessageLookupByLibrary.simpleMessage("Keine Ergebnisse"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("Keine Ergebnisse gefunden"),
        "noSuggestionsForPerson": m53,
        "noSystemLockFound":
            MessageLookupByLibrary.simpleMessage("Keine Systemsperre gefunden"),
        "notPersonLabel": m54,
        "notThisPerson":
            MessageLookupByLibrary.simpleMessage("Nicht diese Person?"),
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
        "onTheRoad": MessageLookupByLibrary.simpleMessage("Wieder unterwegs"),
        "onThisDay": MessageLookupByLibrary.simpleMessage("An diesem Tag"),
        "onThisDayMemories":
            MessageLookupByLibrary.simpleMessage("Erinnerungen an diesem Tag"),
        "onThisDayNotificationExplanation": MessageLookupByLibrary.simpleMessage(
            "Erhalte Erinnerungen von diesem Tag in den vergangenen Jahren."),
        "onlyFamilyAdminCanChangeCode": m55,
        "onlyThem": MessageLookupByLibrary.simpleMessage("Nur diese"),
        "oops": MessageLookupByLibrary.simpleMessage("Hoppla"),
        "oopsCouldNotSaveEdits": MessageLookupByLibrary.simpleMessage(
            "Hoppla, die Änderungen konnten nicht gespeichert werden"),
        "oopsSomethingWentWrong": MessageLookupByLibrary.simpleMessage(
            "Ups. Leider ist ein Fehler aufgetreten"),
        "openAlbumInBrowser":
            MessageLookupByLibrary.simpleMessage("Album im Browser öffnen"),
        "openAlbumInBrowserTitle": MessageLookupByLibrary.simpleMessage(
            "Bitte nutze die Web-App, um Fotos zu diesem Album hinzuzufügen"),
        "openFile": MessageLookupByLibrary.simpleMessage("Datei öffnen"),
        "openSettings":
            MessageLookupByLibrary.simpleMessage("Öffne Einstellungen"),
        "openTheItem": MessageLookupByLibrary.simpleMessage("• Element öffnen"),
        "openstreetmapContributors":
            MessageLookupByLibrary.simpleMessage("OpenStreetMap-Beitragende"),
        "optionalAsShortAsYouLike": MessageLookupByLibrary.simpleMessage(
            "Bei Bedarf auch so kurz wie du willst..."),
        "orMergeWithExistingPerson": MessageLookupByLibrary.simpleMessage(
            "Oder mit existierenden zusammenführen"),
        "orPickAnExistingOne": MessageLookupByLibrary.simpleMessage(
            "Oder eine vorherige auswählen"),
        "orPickFromYourContacts": MessageLookupByLibrary.simpleMessage(
            "oder wähle aus deinen Kontakten"),
        "otherDetectedFaces":
            MessageLookupByLibrary.simpleMessage("Andere erkannte Gesichter"),
        "pair": MessageLookupByLibrary.simpleMessage("Koppeln"),
        "pairWithPin":
            MessageLookupByLibrary.simpleMessage("Mit PIN verbinden"),
        "pairingComplete": MessageLookupByLibrary.simpleMessage("Verbunden"),
        "panorama": MessageLookupByLibrary.simpleMessage("Panorama"),
        "partyWithThem": m56,
        "passKeyPendingVerification": MessageLookupByLibrary.simpleMessage(
            "Verifizierung steht noch aus"),
        "passkey": MessageLookupByLibrary.simpleMessage("Passkey"),
        "passkeyAuthTitle":
            MessageLookupByLibrary.simpleMessage("Passkey-Verifizierung"),
        "password": MessageLookupByLibrary.simpleMessage("Passwort"),
        "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
            "Passwort erfolgreich geändert"),
        "passwordLock": MessageLookupByLibrary.simpleMessage("Passwort Sperre"),
        "passwordStrength": m57,
        "passwordStrengthInfo": MessageLookupByLibrary.simpleMessage(
            "Die Berechnung der Stärke des Passworts basiert auf dessen Länge, den verwendeten Zeichen, und ob es in den 10.000 am häufigsten verwendeten Passwörtern vorkommt"),
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Wir speichern dieses Passwort nicht. Wenn du es vergisst, <underline>können wir deine Daten nicht entschlüsseln</underline>"),
        "pastYearsMemories": MessageLookupByLibrary.simpleMessage(
            "Erinnerungen der letzten Jahre"),
        "paymentDetails":
            MessageLookupByLibrary.simpleMessage("Zahlungsdetails"),
        "paymentFailed":
            MessageLookupByLibrary.simpleMessage("Zahlung fehlgeschlagen"),
        "paymentFailedMessage": MessageLookupByLibrary.simpleMessage(
            "Leider ist deine Zahlung fehlgeschlagen. Wende dich an unseren Support und wir helfen dir weiter!"),
        "paymentFailedTalkToProvider": m58,
        "pendingItems":
            MessageLookupByLibrary.simpleMessage("Ausstehende Elemente"),
        "pendingSync":
            MessageLookupByLibrary.simpleMessage("Synchronisation anstehend"),
        "people": MessageLookupByLibrary.simpleMessage("Personen"),
        "peopleUsingYourCode": MessageLookupByLibrary.simpleMessage(
            "Leute, die deinen Code verwenden"),
        "peopleWidgetDesc": MessageLookupByLibrary.simpleMessage(
            "Wähle die Personen, die du auf der Startseite sehen möchtest."),
        "permDeleteWarning": MessageLookupByLibrary.simpleMessage(
            "Alle Elemente im Papierkorb werden dauerhaft gelöscht\n\nDiese Aktion kann nicht rückgängig gemacht werden"),
        "permanentlyDelete":
            MessageLookupByLibrary.simpleMessage("Dauerhaft löschen"),
        "permanentlyDeleteFromDevice": MessageLookupByLibrary.simpleMessage(
            "Endgültig vom Gerät löschen?"),
        "personIsAge": m59,
        "personName": MessageLookupByLibrary.simpleMessage("Name der Person"),
        "personTurningAge": m60,
        "pets": MessageLookupByLibrary.simpleMessage("Pelzige Begleiter"),
        "photoDescriptions":
            MessageLookupByLibrary.simpleMessage("Foto Beschreibungen"),
        "photoGridSize":
            MessageLookupByLibrary.simpleMessage("Fotorastergröße"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("Foto"),
        "photocountPhotos": m61,
        "photos": MessageLookupByLibrary.simpleMessage("Fotos"),
        "photosAddedByYouWillBeRemovedFromTheAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Von dir hinzugefügte Fotos werden vom Album entfernt"),
        "photosCount": m62,
        "photosKeepRelativeTimeDifference":
            MessageLookupByLibrary.simpleMessage(
                "Fotos behalten relativen Zeitunterschied"),
        "pickCenterPoint":
            MessageLookupByLibrary.simpleMessage("Mittelpunkt auswählen"),
        "pinAlbum": MessageLookupByLibrary.simpleMessage("Album anheften"),
        "pinLock": MessageLookupByLibrary.simpleMessage("PIN-Sperre"),
        "playOnTv": MessageLookupByLibrary.simpleMessage(
            "Album auf dem Fernseher wiedergeben"),
        "playOriginal":
            MessageLookupByLibrary.simpleMessage("Original abspielen"),
        "playStoreFreeTrialValidTill": m63,
        "playStream": MessageLookupByLibrary.simpleMessage("Stream abspielen"),
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
        "pleaseEmailUsAt": m64,
        "pleaseGrantPermissions": MessageLookupByLibrary.simpleMessage(
            "Bitte erteile die nötigen Berechtigungen"),
        "pleaseLoginAgain":
            MessageLookupByLibrary.simpleMessage("Bitte logge dich erneut ein"),
        "pleaseSelectQuickLinksToRemove": MessageLookupByLibrary.simpleMessage(
            "Bitte wähle die zu entfernenden schnellen Links"),
        "pleaseSendTheLogsTo": m65,
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
        "pleaseWaitThisWillTakeAWhile": MessageLookupByLibrary.simpleMessage(
            "Bitte warten, dies wird eine Weile dauern."),
        "posingWithThem": m66,
        "preparingLogs": MessageLookupByLibrary.simpleMessage(
            "Protokolle werden vorbereitet..."),
        "preserveMore":
            MessageLookupByLibrary.simpleMessage("Mehr Daten sichern"),
        "pressAndHoldToPlayVideo": MessageLookupByLibrary.simpleMessage(
            "Gedrückt halten, um Video abzuspielen"),
        "pressAndHoldToPlayVideoDetailed": MessageLookupByLibrary.simpleMessage(
            "Drücke und halte aufs Foto gedrückt um Video abzuspielen"),
        "previous": MessageLookupByLibrary.simpleMessage("Zurück"),
        "privacy": MessageLookupByLibrary.simpleMessage("Datenschutz"),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Datenschutzerklärung"),
        "privateBackups":
            MessageLookupByLibrary.simpleMessage("Private Sicherungen"),
        "privateSharing":
            MessageLookupByLibrary.simpleMessage("Privates Teilen"),
        "proceed": MessageLookupByLibrary.simpleMessage("Fortfahren"),
        "processed": MessageLookupByLibrary.simpleMessage("Verarbeitet"),
        "processing": MessageLookupByLibrary.simpleMessage("In Bearbeitung"),
        "processingImport": m67,
        "processingVideos":
            MessageLookupByLibrary.simpleMessage("Verarbeite Videos"),
        "publicLinkCreated":
            MessageLookupByLibrary.simpleMessage("Öffentlicher Link erstellt"),
        "publicLinkEnabled":
            MessageLookupByLibrary.simpleMessage("Öffentlicher Link aktiviert"),
        "questionmark": MessageLookupByLibrary.simpleMessage("?"),
        "queued": MessageLookupByLibrary.simpleMessage("In der Warteschlange"),
        "quickLinks": MessageLookupByLibrary.simpleMessage("Quick Links"),
        "radius": MessageLookupByLibrary.simpleMessage("Umkreis"),
        "raiseTicket": MessageLookupByLibrary.simpleMessage("Ticket erstellen"),
        "rateTheApp": MessageLookupByLibrary.simpleMessage("App bewerten"),
        "rateUs": MessageLookupByLibrary.simpleMessage("Bewerte uns"),
        "rateUsOnStore": m68,
        "reassignMe":
            MessageLookupByLibrary.simpleMessage("\"Ich\" neu zuweisen"),
        "reassignedToName": m69,
        "reassigningLoading":
            MessageLookupByLibrary.simpleMessage("Ordne neu zu..."),
        "receiveRemindersOnBirthdays": MessageLookupByLibrary.simpleMessage(
            "Erhalte Erinnerungen, wenn jemand Geburtstag hat. Ein Klick auf die Benachrichtigung bringt dich zu den Fotos der Person, die Geburtstag hat."),
        "recover": MessageLookupByLibrary.simpleMessage("Wiederherstellen"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("Konto wiederherstellen"),
        "recoverButton":
            MessageLookupByLibrary.simpleMessage("Wiederherstellen"),
        "recoveryAccount":
            MessageLookupByLibrary.simpleMessage("Konto wiederherstellen"),
        "recoveryInitiated":
            MessageLookupByLibrary.simpleMessage("Wiederherstellung gestartet"),
        "recoveryInitiatedDesc": m70,
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
            "Dein Wiederherstellungsschlüssel ist die einzige Möglichkeit, auf deine Fotos zuzugreifen, solltest du dein Passwort vergessen. Du findest ihn unter Einstellungen > Konto.\n\nBitte gib deinen Wiederherstellungsschlüssel hier ein, um sicherzugehen, dass du ihn korrekt gesichert hast."),
        "recoveryReady": m71,
        "recoverySuccessful": MessageLookupByLibrary.simpleMessage(
            "Wiederherstellung erfolgreich!"),
        "recoveryWarning": MessageLookupByLibrary.simpleMessage(
            "Ein vertrauenswürdiger Kontakt versucht, auf dein Konto zuzugreifen"),
        "recoveryWarningBody": m72,
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "Das aktuelle Gerät ist nicht leistungsfähig genug, um dein Passwort zu verifizieren, aber wir können es neu erstellen, damit es auf allen Geräten funktioniert.\n\nBitte melde dich mit deinem Wiederherstellungs-Schlüssel an und erstelle dein Passwort neu (Wenn du willst, kannst du dasselbe erneut verwenden)."),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Passwort wiederherstellen"),
        "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
        "reenterPassword":
            MessageLookupByLibrary.simpleMessage("Passwort erneut eingeben"),
        "reenterPin":
            MessageLookupByLibrary.simpleMessage("PIN erneut eingeben"),
        "referFriendsAnd2xYourPlan": MessageLookupByLibrary.simpleMessage(
            "Begeistere Freunde für uns und verdopple deinen Speicher"),
        "referralStep1": MessageLookupByLibrary.simpleMessage(
            "1. Gib diesen Code an deine Freunde"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "2. Sie schließen ein bezahltes Abo ab"),
        "referralStep3": m73,
        "referrals": MessageLookupByLibrary.simpleMessage("Weiterempfehlungen"),
        "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
            "Einlösungen sind derzeit pausiert"),
        "rejectRecovery":
            MessageLookupByLibrary.simpleMessage("Wiederherstellung ablehnen"),
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
        "removeInvite":
            MessageLookupByLibrary.simpleMessage("Einladung entfernen"),
        "removeLink": MessageLookupByLibrary.simpleMessage("Link entfernen"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Teilnehmer entfernen"),
        "removeParticipantBody": m74,
        "removePersonLabel":
            MessageLookupByLibrary.simpleMessage("Personenetikett entfernen"),
        "removePublicLink":
            MessageLookupByLibrary.simpleMessage("Öffentlichen Link entfernen"),
        "removePublicLinks":
            MessageLookupByLibrary.simpleMessage("Öffentliche Links entfernen"),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
            "Einige der Elemente, die du entfernst, wurden von anderen Nutzern hinzugefügt und du wirst den Zugriff auf sie verlieren"),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Entfernen?"),
        "removeYourselfAsTrustedContact": MessageLookupByLibrary.simpleMessage(
            "Entferne dich als vertrauenswürdigen Kontakt"),
        "removingFromFavorites": MessageLookupByLibrary.simpleMessage(
            "Wird aus Favoriten entfernt..."),
        "rename": MessageLookupByLibrary.simpleMessage("Umbenennen"),
        "renameAlbum": MessageLookupByLibrary.simpleMessage("Album umbenennen"),
        "renameFile": MessageLookupByLibrary.simpleMessage("Datei umbenennen"),
        "renewSubscription":
            MessageLookupByLibrary.simpleMessage("Abonnement erneuern"),
        "renewsOn": m75,
        "reportABug": MessageLookupByLibrary.simpleMessage("Fehler melden"),
        "reportBug": MessageLookupByLibrary.simpleMessage("Fehler melden"),
        "resendEmail":
            MessageLookupByLibrary.simpleMessage("E-Mail erneut senden"),
        "reset": MessageLookupByLibrary.simpleMessage("Zurücksetzen"),
        "resetIgnoredFiles": MessageLookupByLibrary.simpleMessage(
            "Ignorierte Dateien zurücksetzen"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Passwort zurücksetzen"),
        "resetPerson": MessageLookupByLibrary.simpleMessage("Entfernen"),
        "resetToDefault":
            MessageLookupByLibrary.simpleMessage("Standardwerte zurücksetzen"),
        "restore": MessageLookupByLibrary.simpleMessage("Wiederherstellen"),
        "restoreToAlbum":
            MessageLookupByLibrary.simpleMessage("Album wiederherstellen"),
        "restoringFiles": MessageLookupByLibrary.simpleMessage(
            "Dateien werden wiederhergestellt..."),
        "resumableUploads":
            MessageLookupByLibrary.simpleMessage("Fortsetzbares Hochladen"),
        "retry": MessageLookupByLibrary.simpleMessage("Erneut versuchen"),
        "review": MessageLookupByLibrary.simpleMessage("Überprüfen"),
        "reviewDeduplicateItems": MessageLookupByLibrary.simpleMessage(
            "Bitte überprüfe und lösche die Elemente, die du für Duplikate hältst."),
        "reviewSuggestions":
            MessageLookupByLibrary.simpleMessage("Vorschläge überprüfen"),
        "right": MessageLookupByLibrary.simpleMessage("Rechts"),
        "roadtripWithThem": m76,
        "rotate": MessageLookupByLibrary.simpleMessage("Drehen"),
        "rotateLeft": MessageLookupByLibrary.simpleMessage("Nach links drehen"),
        "rotateRight":
            MessageLookupByLibrary.simpleMessage("Nach rechts drehen"),
        "safelyStored": MessageLookupByLibrary.simpleMessage("Gesichert"),
        "same": MessageLookupByLibrary.simpleMessage("Gleich"),
        "sameperson": MessageLookupByLibrary.simpleMessage("Dieselbe Person?"),
        "save": MessageLookupByLibrary.simpleMessage("Speichern"),
        "saveAsAnotherPerson":
            MessageLookupByLibrary.simpleMessage("Als andere Person speichern"),
        "saveChangesBeforeLeavingQuestion":
            MessageLookupByLibrary.simpleMessage(
                "Änderungen vor dem Verlassen speichern?"),
        "saveCollage":
            MessageLookupByLibrary.simpleMessage("Collage speichern"),
        "saveCopy": MessageLookupByLibrary.simpleMessage("Kopie speichern"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Schlüssel speichern"),
        "savePerson": MessageLookupByLibrary.simpleMessage("Person speichern"),
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
        "searchDiscoverEmptySection": MessageLookupByLibrary.simpleMessage(
            "Bilder werden hier angezeigt, sobald Verarbeitung und Synchronisation abgeschlossen sind"),
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
        "searchPersonsEmptySection": MessageLookupByLibrary.simpleMessage(
            "Personen werden hier angezeigt, sobald Verarbeitung und Synchronisierung abgeschlossen sind"),
        "searchResultCount": m77,
        "searchSectionsLengthMismatch": m78,
        "security": MessageLookupByLibrary.simpleMessage("Sicherheit"),
        "seePublicAlbumLinksInApp": MessageLookupByLibrary.simpleMessage(
            "Öffentliche Album-Links in der App ansehen"),
        "selectALocation":
            MessageLookupByLibrary.simpleMessage("Standort auswählen"),
        "selectALocationFirst":
            MessageLookupByLibrary.simpleMessage("Wähle zuerst einen Standort"),
        "selectAlbum": MessageLookupByLibrary.simpleMessage("Album auswählen"),
        "selectAll": MessageLookupByLibrary.simpleMessage("Alle markieren"),
        "selectAllShort": MessageLookupByLibrary.simpleMessage("Alle"),
        "selectCoverPhoto":
            MessageLookupByLibrary.simpleMessage("Titelbild auswählen"),
        "selectDate": MessageLookupByLibrary.simpleMessage("Datum wählen"),
        "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
            "Ordner für Sicherung auswählen"),
        "selectItemsToAdd": MessageLookupByLibrary.simpleMessage(
            "Elemente zum Hinzufügen auswählen"),
        "selectLanguage":
            MessageLookupByLibrary.simpleMessage("Sprache auswählen"),
        "selectMailApp":
            MessageLookupByLibrary.simpleMessage("E-Mail-App auswählen"),
        "selectMorePhotos":
            MessageLookupByLibrary.simpleMessage("Mehr Fotos auswählen"),
        "selectOneDateAndTime": MessageLookupByLibrary.simpleMessage(
            "Wähle ein Datum und eine Uhrzeit"),
        "selectOneDateAndTimeForAll": MessageLookupByLibrary.simpleMessage(
            "Wähle ein Datum und eine Uhrzeit für alle"),
        "selectPersonToLink": MessageLookupByLibrary.simpleMessage(
            "Person zum Verknüpfen auswählen"),
        "selectReason": MessageLookupByLibrary.simpleMessage("Grund auswählen"),
        "selectStartOfRange": MessageLookupByLibrary.simpleMessage(
            "Anfang des Bereichs auswählen"),
        "selectTime": MessageLookupByLibrary.simpleMessage("Uhrzeit wählen"),
        "selectYourFace":
            MessageLookupByLibrary.simpleMessage("Wähle dein Gesicht"),
        "selectYourPlan":
            MessageLookupByLibrary.simpleMessage("Wähle dein Abo aus"),
        "selectedAlbums": m79,
        "selectedFilesAreNotOnEnte": MessageLookupByLibrary.simpleMessage(
            "Ausgewählte Dateien sind nicht auf Ente"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "Ausgewählte Ordner werden verschlüsselt und gesichert"),
        "selectedItemsWillBeDeletedFromAllAlbumsAndMoved":
            MessageLookupByLibrary.simpleMessage(
                "Ausgewählte Elemente werden aus allen Alben gelöscht und in den Papierkorb verschoben."),
        "selectedItemsWillBeRemovedFromThisPerson":
            MessageLookupByLibrary.simpleMessage(
                "Ausgewählte Elemente werden von dieser Person entfernt, aber nicht aus deiner Bibliothek gelöscht."),
        "selectedPhotos": m80,
        "selectedPhotosWithYours": m81,
        "selfiesWithThem": m82,
        "send": MessageLookupByLibrary.simpleMessage("Absenden"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("E-Mail senden"),
        "sendInvite": MessageLookupByLibrary.simpleMessage("Einladung senden"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Link senden"),
        "serverEndpoint":
            MessageLookupByLibrary.simpleMessage("Server Endpunkt"),
        "sessionExpired":
            MessageLookupByLibrary.simpleMessage("Sitzung abgelaufen"),
        "sessionIdMismatch": MessageLookupByLibrary.simpleMessage(
            "Sitzungs-ID stimmt nicht überein"),
        "setAPassword": MessageLookupByLibrary.simpleMessage("Passwort setzen"),
        "setAs": MessageLookupByLibrary.simpleMessage("Festlegen als"),
        "setCover": MessageLookupByLibrary.simpleMessage("Titelbild festlegen"),
        "setLabel": MessageLookupByLibrary.simpleMessage("Festlegen"),
        "setNewPassword":
            MessageLookupByLibrary.simpleMessage("Neues Passwort festlegen"),
        "setNewPin": MessageLookupByLibrary.simpleMessage("Neue PIN festlegen"),
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
        "shareMyVerificationID": m83,
        "shareOnlyWithThePeopleYouWant": MessageLookupByLibrary.simpleMessage(
            "Teile mit ausgewählten Personen"),
        "shareTextConfirmOthersVerificationID": m84,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Hol dir Ente, damit wir ganz einfach Fotos und Videos in Originalqualität teilen können\n\nhttps://ente.io"),
        "shareTextReferralCode": m85,
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
            "Mit Nicht-Ente-Benutzern teilen"),
        "shareWithPeopleSectionTitle": m86,
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
        "sharedWith": m87,
        "sharedWithMe": MessageLookupByLibrary.simpleMessage("Mit mir geteilt"),
        "sharedWithYou":
            MessageLookupByLibrary.simpleMessage("Mit dir geteilt"),
        "sharing": MessageLookupByLibrary.simpleMessage("Teilt..."),
        "shiftDatesAndTime": MessageLookupByLibrary.simpleMessage(
            "Datum und Uhrzeit verschieben"),
        "showLessFaces":
            MessageLookupByLibrary.simpleMessage("Weniger Gesichter zeigen"),
        "showMemories":
            MessageLookupByLibrary.simpleMessage("Erinnerungen anschauen"),
        "showMoreFaces":
            MessageLookupByLibrary.simpleMessage("Mehr Gesichter zeigen"),
        "showPerson": MessageLookupByLibrary.simpleMessage("Person anzeigen"),
        "signOutFromOtherDevices": MessageLookupByLibrary.simpleMessage(
            "Von anderen Geräten abmelden"),
        "signOutOtherBody": MessageLookupByLibrary.simpleMessage(
            "Falls du denkst, dass jemand dein Passwort kennen könnte, kannst du alle anderen Geräte von deinem Account abmelden."),
        "signOutOtherDevices":
            MessageLookupByLibrary.simpleMessage("Andere Geräte abmelden"),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "Ich stimme den <u-terms>Nutzungsbedingungen</u-terms> und der <u-policy>Datenschutzerklärung</u-policy> zu"),
        "singleFileDeleteFromDevice": m88,
        "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
            "Es wird aus allen Alben gelöscht."),
        "singleFileInBothLocalAndRemote": m89,
        "singleFileInRemoteOnly": m90,
        "skip": MessageLookupByLibrary.simpleMessage("Überspringen"),
        "smartMemories":
            MessageLookupByLibrary.simpleMessage("Smarte Erinnerungen"),
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
        "sorryBackupFailedDesc": MessageLookupByLibrary.simpleMessage(
            "Leider konnten wir diese Datei momentan nicht sichern, wir werden es später erneut versuchen."),
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
        "sorryWeHadToPauseYourBackups": MessageLookupByLibrary.simpleMessage(
            "Entschuldigung, wir mussten deine Sicherungen pausieren"),
        "sort": MessageLookupByLibrary.simpleMessage("Sortierung"),
        "sortAlbumsBy": MessageLookupByLibrary.simpleMessage("Sortieren nach"),
        "sortNewestFirst":
            MessageLookupByLibrary.simpleMessage("Neueste zuerst"),
        "sortOldestFirst":
            MessageLookupByLibrary.simpleMessage("Älteste zuerst"),
        "sparkleSuccess":
            MessageLookupByLibrary.simpleMessage("✨ Abgeschlossen"),
        "sportsWithThem": m91,
        "spotlightOnThem": m92,
        "spotlightOnYourself":
            MessageLookupByLibrary.simpleMessage("Spot auf dich selbst"),
        "startAccountRecoveryTitle":
            MessageLookupByLibrary.simpleMessage("Wiederherstellung starten"),
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
        "storageInGB": m93,
        "storageLimitExceeded": MessageLookupByLibrary.simpleMessage(
            "Speichergrenze überschritten"),
        "storageUsageInfo": m94,
        "streamDetails": MessageLookupByLibrary.simpleMessage("Stream-Details"),
        "strongStrength": MessageLookupByLibrary.simpleMessage("Stark"),
        "subAlreadyLinkedErrMessage": m95,
        "subWillBeCancelledOn": m96,
        "subscribe": MessageLookupByLibrary.simpleMessage("Abonnieren"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "Du benötigst ein aktives, bezahltes Abonnement, um das Teilen zu aktivieren."),
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
        "sunrise": MessageLookupByLibrary.simpleMessage("Am Horizont"),
        "support": MessageLookupByLibrary.simpleMessage("Support"),
        "syncProgress": m97,
        "syncStopped":
            MessageLookupByLibrary.simpleMessage("Synchronisierung angehalten"),
        "syncing": MessageLookupByLibrary.simpleMessage("Synchronisiere …"),
        "systemTheme": MessageLookupByLibrary.simpleMessage("System"),
        "tapToCopy":
            MessageLookupByLibrary.simpleMessage("zum Kopieren antippen"),
        "tapToEnterCode": MessageLookupByLibrary.simpleMessage(
            "Antippen, um den Code einzugeben"),
        "tapToUnlock":
            MessageLookupByLibrary.simpleMessage("Zum Entsperren antippen"),
        "tapToUpload":
            MessageLookupByLibrary.simpleMessage("Zum Hochladen antippen"),
        "tapToUploadIsIgnoredDue": m98,
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
        "theLinkYouAreTryingToAccessHasExpired":
            MessageLookupByLibrary.simpleMessage(
                "Der Link, den du aufrufen möchtest, ist abgelaufen."),
        "thePersonGroupsWillNotBeDisplayed": MessageLookupByLibrary.simpleMessage(
            "Diese Personengruppen werden im Personen-Abschnitt nicht mehr angezeigt. Die Fotos bleiben unverändert."),
        "thePersonWillNotBeDisplayed": MessageLookupByLibrary.simpleMessage(
            "Diese Person wird im Personen-Abschnitt nicht mehr angezeigt. Die Fotos bleiben unverändert."),
        "theRecoveryKeyYouEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "Der eingegebene Schlüssel ist ungültig"),
        "theme": MessageLookupByLibrary.simpleMessage("Theme"),
        "theseItemsWillBeDeletedFromYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Diese Elemente werden von deinem Gerät gelöscht."),
        "theyAlsoGetXGb": m99,
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
        "thisIsMeExclamation":
            MessageLookupByLibrary.simpleMessage("Das bin ich!"),
        "thisIsPersonVerificationId": m100,
        "thisIsYourVerificationId": MessageLookupByLibrary.simpleMessage(
            "Dies ist deine Verifizierungs-ID"),
        "thisWeekThroughTheYears":
            MessageLookupByLibrary.simpleMessage("Diese Woche über die Jahre"),
        "thisWeekXYearsAgo": m101,
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Dadurch wirst du von folgendem Gerät abgemeldet:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Dadurch wirst du von diesem Gerät abgemeldet!"),
        "thisWillMakeTheDateAndTimeOfAllSelected":
            MessageLookupByLibrary.simpleMessage(
                "Dadurch werden Datum und Uhrzeit aller ausgewählten Fotos gleich."),
        "thisWillRemovePublicLinksOfAllSelectedQuickLinks":
            MessageLookupByLibrary.simpleMessage(
                "Hiermit werden die öffentlichen Links aller ausgewählten schnellen Links entfernt."),
        "throughTheYears": m102,
        "toEnableAppLockPleaseSetupDevicePasscodeOrScreen":
            MessageLookupByLibrary.simpleMessage(
                "Um die App-Sperre zu aktivieren, konfiguriere bitte den Gerätepasscode oder die Bildschirmsperre in den Systemeinstellungen."),
        "toHideAPhotoOrVideo":
            MessageLookupByLibrary.simpleMessage("Foto oder Video verstecken"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "Um dein Passwort zurückzusetzen, verifiziere bitte zuerst deine E-Mail-Adresse."),
        "todaysLogs":
            MessageLookupByLibrary.simpleMessage("Heutiges Protokoll"),
        "tooManyIncorrectAttempts": MessageLookupByLibrary.simpleMessage(
            "Zu viele fehlerhafte Versuche"),
        "total": MessageLookupByLibrary.simpleMessage("Gesamt"),
        "totalSize": MessageLookupByLibrary.simpleMessage("Gesamtgröße"),
        "trash": MessageLookupByLibrary.simpleMessage("Papierkorb"),
        "trashDaysLeft": m103,
        "trim": MessageLookupByLibrary.simpleMessage("Schneiden"),
        "tripInYear": m104,
        "tripToLocation": m105,
        "trustedContacts":
            MessageLookupByLibrary.simpleMessage("Vertrauenswürdige Kontakte"),
        "trustedInviteBody": m106,
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
        "typeOfGallerGallerytypeIsNotSupportedForRename": m107,
        "unarchive": MessageLookupByLibrary.simpleMessage("Dearchivieren"),
        "unarchiveAlbum":
            MessageLookupByLibrary.simpleMessage("Album dearchivieren"),
        "unarchiving": MessageLookupByLibrary.simpleMessage("Dearchiviere …"),
        "unavailableReferralCode": MessageLookupByLibrary.simpleMessage(
            "Entschuldigung, dieser Code ist nicht verfügbar."),
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
        "uploadIsIgnoredDueToIgnorereason": m108,
        "uploadingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Dateien werden ins Album hochgeladen..."),
        "uploadingMultipleMemories": m109,
        "uploadingSingleMemory": MessageLookupByLibrary.simpleMessage(
            "Sichere ein Erinnerungsstück..."),
        "upto50OffUntil4thDec": MessageLookupByLibrary.simpleMessage(
            "Bis zu 50% Rabatt bis zum 4. Dezember."),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "Der verwendbare Speicherplatz ist von deinem aktuellen Abonnement eingeschränkt. Überschüssiger, beanspruchter Speicherplatz wird automatisch verwendbar werden, wenn du ein höheres Abonnement buchst."),
        "useAsCover":
            MessageLookupByLibrary.simpleMessage("Als Titelbild festlegen"),
        "useDifferentPlayerInfo": MessageLookupByLibrary.simpleMessage(
            "Hast du Probleme beim Abspielen dieses Videos? Halte hier gedrückt, um einen anderen Player auszuprobieren."),
        "usePublicLinksForPeopleNotOnEnte": MessageLookupByLibrary.simpleMessage(
            "Verwende öffentliche Links für Personen, die kein Ente-Konto haben"),
        "useRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Wiederherstellungs-Schlüssel verwenden"),
        "useSelectedPhoto":
            MessageLookupByLibrary.simpleMessage("Ausgewähltes Foto verwenden"),
        "usedSpace":
            MessageLookupByLibrary.simpleMessage("Belegter Speicherplatz"),
        "validTill": m110,
        "verificationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Verifizierung fehlgeschlagen, bitte versuchen Sie es erneut"),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("Verifizierungs-ID"),
        "verify": MessageLookupByLibrary.simpleMessage("Überprüfen"),
        "verifyEmail":
            MessageLookupByLibrary.simpleMessage("E-Mail-Adresse verifizieren"),
        "verifyEmailID": m111,
        "verifyIDLabel": MessageLookupByLibrary.simpleMessage("Überprüfen"),
        "verifyPasskey":
            MessageLookupByLibrary.simpleMessage("Passkey verifizieren"),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Passwort überprüfen"),
        "verifying": MessageLookupByLibrary.simpleMessage("Verifiziere …"),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Wiederherstellungs-Schlüssel wird überprüft..."),
        "videoInfo":
            MessageLookupByLibrary.simpleMessage("Video-Informationen"),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("Video"),
        "videoStreaming":
            MessageLookupByLibrary.simpleMessage("Streambare Videos"),
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
            "Dateien anzeigen, die den meisten Speicherplatz belegen."),
        "viewLogs": MessageLookupByLibrary.simpleMessage("Protokolle anzeigen"),
        "viewPersonToUnlink": m112,
        "viewRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Wiederherstellungsschlüssel anzeigen"),
        "viewer": MessageLookupByLibrary.simpleMessage("Zuschauer"),
        "viewersSuccessfullyAdded": m113,
        "visitWebToManage": MessageLookupByLibrary.simpleMessage(
            "Bitte rufe \"web.ente.io\" auf, um dein Abo zu verwalten"),
        "waitingForVerification":
            MessageLookupByLibrary.simpleMessage("Warte auf Bestätigung..."),
        "waitingForWifi":
            MessageLookupByLibrary.simpleMessage("Warte auf WLAN..."),
        "warning": MessageLookupByLibrary.simpleMessage("Warnung"),
        "weAreOpenSource": MessageLookupByLibrary.simpleMessage(
            "Unser Quellcode ist offen einsehbar!"),
        "weDontSupportEditingPhotosAndAlbumsThatYouDont":
            MessageLookupByLibrary.simpleMessage(
                "Wir unterstützen keine Bearbeitung von Fotos und Alben, die du noch nicht besitzt"),
        "weHaveSendEmailTo": m114,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Schwach"),
        "welcomeBack":
            MessageLookupByLibrary.simpleMessage("Willkommen zurück!"),
        "whatsNew": MessageLookupByLibrary.simpleMessage("Neue Funktionen"),
        "whyAddTrustContact": MessageLookupByLibrary.simpleMessage(
            "Ein vertrauenswürdiger Kontakt kann helfen, deine Daten wiederherzustellen."),
        "widgets": MessageLookupByLibrary.simpleMessage("Widgets"),
        "wishThemAHappyBirthday": m115,
        "yearShort": MessageLookupByLibrary.simpleMessage("Jahr"),
        "yearly": MessageLookupByLibrary.simpleMessage("Jährlich"),
        "yearsAgo": m116,
        "yes": MessageLookupByLibrary.simpleMessage("Ja"),
        "yesCancel": MessageLookupByLibrary.simpleMessage("Ja, kündigen"),
        "yesConvertToViewer": MessageLookupByLibrary.simpleMessage(
            "Ja, zu \"Beobachter\" ändern"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("Ja, löschen"),
        "yesDiscardChanges":
            MessageLookupByLibrary.simpleMessage("Ja, Änderungen verwerfen"),
        "yesIgnore": MessageLookupByLibrary.simpleMessage("Ja, ignorieren"),
        "yesLogout": MessageLookupByLibrary.simpleMessage("Ja, ausloggen"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("Ja, entfernen"),
        "yesRenew": MessageLookupByLibrary.simpleMessage("Ja, erneuern"),
        "yesResetPerson":
            MessageLookupByLibrary.simpleMessage("Ja, Person zurücksetzen"),
        "you": MessageLookupByLibrary.simpleMessage("Du"),
        "youAndThem": m117,
        "youAreOnAFamilyPlan":
            MessageLookupByLibrary.simpleMessage("Du bist im Familien-Tarif!"),
        "youAreOnTheLatestVersion": MessageLookupByLibrary.simpleMessage(
            "Du bist auf der neuesten Version"),
        "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "* Du kannst deinen Speicher maximal verdoppeln"),
        "youCanManageYourLinksInTheShareTab":
            MessageLookupByLibrary.simpleMessage(
                "Du kannst deine Links im \"Teilen\"-Tab verwalten."),
        "youCanTrySearchingForADifferentQuery":
            MessageLookupByLibrary.simpleMessage(
                "Sie können versuchen, nach einer anderen Abfrage suchen."),
        "youCannotDowngradeToThisPlan": MessageLookupByLibrary.simpleMessage(
            "Du kannst nicht auf diesen Tarif wechseln"),
        "youCannotShareWithYourself": MessageLookupByLibrary.simpleMessage(
            "Du kannst nicht mit dir selbst teilen"),
        "youDontHaveAnyArchivedItems": MessageLookupByLibrary.simpleMessage(
            "Du hast keine archivierten Elemente."),
        "youHaveSuccessfullyFreedUp": m118,
        "yourAccountHasBeenDeleted": MessageLookupByLibrary.simpleMessage(
            "Dein Benutzerkonto wurde gelöscht"),
        "yourMap": MessageLookupByLibrary.simpleMessage("Deine Karte"),
        "yourPlanWasSuccessfullyDowngraded":
            MessageLookupByLibrary.simpleMessage(
                "Dein Tarif wurde erfolgreich heruntergestuft"),
        "yourPlanWasSuccessfullyUpgraded": MessageLookupByLibrary.simpleMessage(
            "Dein Abo wurde erfolgreich hochgestuft"),
        "yourPurchaseWasSuccessful": MessageLookupByLibrary.simpleMessage(
            "Dein Einkauf war erfolgreich"),
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
