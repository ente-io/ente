// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a pl locale. All the
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
  String get localeName => 'pl';

  static String m0(title) => "${title} (Ja)";

  static String m3(storageAmount, endDate) =>
      "Twój dodatek ${storageAmount} jest ważny do ${endDate}";

  static String m5(emailOrName) => "Dodane przez ${emailOrName}";

  static String m6(albumName) => "Pomyślnie dodano do  ${albumName}";

  static String m7(name) => "Podziwianie ${name}";

  static String m8(count) =>
      "${Intl.plural(count, zero: 'Brak Uczestników', one: '1 Uczestnik', other: '${count} Uczestników')}";

  static String m9(versionValue) => "Wersja: ${versionValue}";

  static String m10(freeAmount, storageUnit) =>
      "${freeAmount} ${storageUnit} wolne";

  static String m11(name) => "Piękne widoki z ${name}";

  static String m12(paymentProvider) =>
      "Prosimy najpierw anulować istniejącą subskrypcję z ${paymentProvider}";

  static String m13(user) =>
      "${user} nie będzie mógł dodać więcej zdjęć do tego albumu\n\nJednak nadal będą mogli usunąć istniejące zdjęcia, które dodali";

  static String m14(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true':
                'Twoja rodzina odebrała ${storageAmountInGb} GB do tej pory',
            'false': 'Odebrałeś ${storageAmountInGb} GB do tej pory',
            'other': 'Odebrałeś ${storageAmountInGb} GB do tej pory!'
          })}";

  static String m15(albumName) => "Utworzono link współpracy dla ${albumName}";

  static String m16(count) =>
      "${Intl.plural(count, zero: 'Dodano 0 współuczestników', one: 'Dodano 1 współuczestnika', other: 'Dodano ${count} współuczestników')}";

  static String m17(email, numOfDays) =>
      "Zamierzasz dodać ${email} jako zaufany kontakt. Będą mogli odzyskać Twoje konto, jeśli jesteś nieobecny przez ${numOfDays} dni.";

  static String m18(familyAdminEmail) =>
      "Prosimy skontaktować się z <green>${familyAdminEmail}</green>, by zarzadząć swoją subskrypcją";

  static String m19(provider) =>
      "Skontaktuj się z nami pod adresem support@ente.io, aby zarządzać subskrypcją ${provider}.";

  static String m20(endpoint) => "Połączono z ${endpoint}";

  static String m21(count) =>
      "${Intl.plural(count, one: 'Usuń ${count} element', few: 'Usuń ${count} elementy', many: 'Usuń ${count} elementów', other: 'Usuń ${count} elementu')}";

  static String m22(count) =>
      "Usunąć również zdjęcia (i filmy) obecne w tych albumach ${count} z <bold>wszystkich</bold> innych albumów, których są częścią?";

  static String m23(currentlyDeleting, totalCount) =>
      "Usuwanie ${currentlyDeleting} / ${totalCount}";

  static String m24(albumName) =>
      "Spowoduje to usunięcie publicznego linku dostępu do \"${albumName}\".";

  static String m25(supportEmail) =>
      "Wyślij wiadomość e-mail na ${supportEmail} z zarejestrowanego adresu e-mail";

  static String m26(count, storageSaved) =>
      "Wyczyszczono ${Intl.plural(count, one: '${count} zdduplikowany plik', other: '${count} zdduplikowane pliki')}, oszczędzając (${storageSaved}!)";

  static String m27(count, formattedSize) =>
      "${count} plików, każdy po ${formattedSize}";

  static String m28(name) => "Ten e-mail jest już powiązany z ${name}.";

  static String m29(newEmail) => "Adres e-mail został zmieniony na ${newEmail}";

  static String m30(email) => "${email} nie posiada konta Ente.";

  static String m31(email) =>
      "${email} nie posiada konta Ente.\n\nWyślij im zaproszenie do udostępniania zdjęć.";

  static String m33(text) => "Znaleziono dodatkowe zdjęcia dla ${text}";

  static String m34(name) => "Ucztowanie z ${name}";

  static String m35(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 plikowi', other: '${formattedNumber} plikom')} na tym urządzeniu została bezpiecznie utworzona kopia zapasowa";

  static String m36(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 plikowi', other: '${formattedNumber} plikom')} w tym albumie została bezpiecznie utworzona kopia zapasowa";

  static String m37(storageAmountInGB) =>
      "${storageAmountInGB} GB za każdym razem, gdy ktoś zarejestruje się w płatnym planie i użyje twojego kodu";

  static String m38(endDate) => "Okres próbny ważny do ${endDate}";

  static String m40(sizeInMBorGB) => "Zwolnij ${sizeInMBorGB}";

  static String m42(currentlyProcessing, totalCount) =>
      "Przetwarzanie ${currentlyProcessing} / ${totalCount}";

  static String m43(name) => "Wędrówka z ${name}";

  static String m44(count) =>
      "${Intl.plural(count, one: '${count} element', few: '${count} elementy', many: '${count} elementów', other: '${count} elementu')}";

  static String m45(name) => "Ostatnio z ${name}";

  static String m46(email) =>
      "${email} zaprosił Cię do zostania zaufanym kontaktem";

  static String m47(expiryTime) => "Link wygaśnie ${expiryTime}";

  static String m48(email) => "Połącz osobę z ${email}";

  static String m49(personName, email) =>
      "Spowoduje to powiązanie ${personName} z ${email}";

  static String m52(albumName) => "Pomyślnie przeniesiono do ${albumName}";

  static String m53(personName) => "Brak sugestii dla ${personName}";

  static String m54(name) => "Nie ${name}?";

  static String m55(familyAdminEmail) =>
      "Skontaktuj się z ${familyAdminEmail}, aby zmienić swój kod.";

  static String m57(passwordStrengthValue) =>
      "Siła hasła: ${passwordStrengthValue}";

  static String m58(providerName) =>
      "Porozmawiaj ze wsparciem ${providerName} jeśli zostałeś obciążony";

  static String m59(name, age) => "${name} ma ${age} lat!";

  static String m60(name, age) => "${name} wkrótce będzie mieć ${age} lat";

  static String m63(endDate) =>
      "Bezpłatny okres próbny ważny do ${endDate}.\nNastępnie możesz wybrać płatny plan.";

  static String m64(toEmail) =>
      "Prosimy o kontakt mailowy pod adresem ${toEmail}";

  static String m65(toEmail) => "Prosimy wysłać logi do ${toEmail}";

  static String m66(name) => "Pozowanie z ${name}";

  static String m67(folderName) => "Przetwarzanie ${folderName}...";

  static String m68(storeName) => "Oceń nas na ${storeName}";

  static String m69(name) => "Ponownie przypisano cię do ${name}";

  static String m70(days, email) =>
      "Możesz uzyskać dostęp do konta po dniu ${days} dni. Powiadomienie zostanie wysłane na ${email}.";

  static String m71(email) =>
      "Możesz teraz odzyskać konto ${email} poprzez ustawienie nowego hasła.";

  static String m72(email) => "${email} próbuje odzyskać Twoje konto.";

  static String m73(storageInGB) =>
      "3. Oboje otrzymujecie ${storageInGB} GB* za darmo";

  static String m74(userEmail) =>
      "${userEmail} zostanie usunięty z tego udostępnionego albumu\n\nWszelkie dodane przez nich zdjęcia zostaną usunięte z albumu";

  static String m75(endDate) => "Subskrypcja odnowi się ${endDate}";

  static String m76(name) => "Wycieczka z ${name}";

  static String m77(count) =>
      "${Intl.plural(count, one: 'Znaleziono ${count} wynik', few: 'Znaleziono ${count} wyniki', other: 'Znaleziono ${count} wyników')}";

  static String m78(snapshotLength, searchLength) =>
      "Niezgodność długości sekcji: ${snapshotLength} != ${searchLength}";

  static String m79(count) => "Wybrano ${count}";

  static String m80(count) => "Wybrano ${count}";

  static String m81(count, yourCount) =>
      "Wybrano ${count} (twoich ${yourCount})";

  static String m82(name) => "Selfie z ${name}";

  static String m83(verificationID) =>
      "Oto mój identyfikator weryfikacyjny: ${verificationID} dla ente.io.";

  static String m84(verificationID) =>
      "Hej, czy możesz potwierdzić, że to jest Twój identyfikator weryfikacyjny ente.io: ${verificationID}";

  static String m85(referralCode, referralStorageInGB) =>
      "Kod polecający: ${referralCode} \n\nZastosuj go w: Ustawienia → Ogólne → Polecanie, aby otrzymać ${referralStorageInGB} GB za darmo po zarejestrowaniu się w płatnym planie\n\nhttps://ente.io";

  static String m86(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Udostępnione określonym osobom', one: 'Udostępnione 1 osobie', other: 'Udostępnione ${numberOfPeople} osobom')}";

  static String m87(emailIDs) => "Udostępnione z ${emailIDs}";

  static String m88(fileType) =>
      "Ten ${fileType} zostanie usunięty z Twojego urządzenia.";

  static String m89(fileType) =>
      "Ten ${fileType} jest zarówno w Ente, jak i na twoim urządzeniu.";

  static String m90(fileType) => "Ten ${fileType} zostanie usunięty z Ente.";

  static String m91(name) => "Sport z ${name}";

  static String m92(name) => "Uwaga na ${name}";

  static String m93(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m94(
    usedAmount,
    usedStorageUnit,
    totalAmount,
    totalStorageUnit,
  ) =>
      "Użyto ${usedAmount} ${usedStorageUnit} z ${totalAmount} ${totalStorageUnit}";

  static String m95(id) =>
      "Twoje ${id} jest już połączony z innym kontem Ente.\nJeśli chcesz użyć swojego ${id} za pomocą tego konta, skontaktuj się z naszym wsparciem technicznym";

  static String m96(endDate) =>
      "Twoja subskrypcja zostanie anulowana dnia ${endDate}";

  static String m97(completed, total) =>
      "Zachowano ${completed}/${total} wspomnień";

  static String m98(ignoreReason) =>
      "Naciśnij, aby przesłać, przesyłanie jest obecnie ignorowane z powodu ${ignoreReason}";

  static String m99(storageAmountInGB) =>
      "Oni również otrzymują ${storageAmountInGB} GB";

  static String m100(email) => "To jest identyfikator weryfikacyjny ${email}";

  static String m102(dateFormat) => "${dateFormat} przez lata";

  static String m103(count) =>
      "${Intl.plural(count, zero: 'Wkrótce', one: '1 dzień', few: '${count} dni', other: '${count} dni')}";

  static String m104(year) => "Podróż w ${year}";

  static String m106(email) =>
      "Zostałeś zaproszony do bycia dziedzicznym kontaktem przez ${email}.";

  static String m107(galleryType) =>
      "Typ galerii ${galleryType} nie jest obsługiwany dla zmiany nazwy";

  static String m108(ignoreReason) =>
      "Przesyłanie jest ignorowane z powodu ${ignoreReason}";

  static String m109(count) => "Zachowywanie ${count} wspomnień...";

  static String m110(endDate) => "Ważne do ${endDate}";

  static String m111(email) => "Zweryfikuj ${email}";

  static String m112(name) => "Zobacz ${name}, aby odłączyć";

  static String m114(email) =>
      "Wysłaliśmy wiadomość na adres <green>${email}</green>";

  static String m115(name) => "Życz ${name} wszystkiego  najlepszego! 🎉";

  static String m116(count) =>
      "${Intl.plural(count, one: '${count} rok temu', few: '${count} lata temu', many: '${count} lat temu', other: '${count} lata temu')}";

  static String m117(name) => "Ty i ${name}";

  static String m118(storageSaved) => "Pomyślnie zwolniłeś/aś ${storageSaved}!";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable": MessageLookupByLibrary.simpleMessage(
          "Dostępna jest nowa wersja Ente.",
        ),
        "about": MessageLookupByLibrary.simpleMessage("O nas"),
        "acceptTrustInvite": MessageLookupByLibrary.simpleMessage(
          "Zaakceptuj Zaproszenie",
        ),
        "account": MessageLookupByLibrary.simpleMessage("Konto"),
        "accountIsAlreadyConfigured": MessageLookupByLibrary.simpleMessage(
          "Konto jest już skonfigurowane.",
        ),
        "accountOwnerPersonAppbarTitle": m0,
        "accountWelcomeBack": MessageLookupByLibrary.simpleMessage(
          "Witaj ponownie!",
        ),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
          "Rozumiem, że jeśli utracę hasło, mogę utracić dane, ponieważ moje dane są <underline>całkowicie zaszyfrowane</underline>.",
        ),
        "actionNotSupportedOnFavouritesAlbum":
            MessageLookupByLibrary.simpleMessage(
          "Akcja nie jest obsługiwana na Ulubionym albumie",
        ),
        "activeSessions": MessageLookupByLibrary.simpleMessage("Aktywne sesje"),
        "add": MessageLookupByLibrary.simpleMessage("Dodaj"),
        "addAName": MessageLookupByLibrary.simpleMessage("Dodaj nazwę"),
        "addANewEmail": MessageLookupByLibrary.simpleMessage(
          "Dodaj nowy adres e-mail",
        ),
        "addAlbumWidgetPrompt": MessageLookupByLibrary.simpleMessage(
          "Dodaj widżet albumu do ekranu głównego i wróć tutaj, aby dostosować.",
        ),
        "addCollaborator": MessageLookupByLibrary.simpleMessage(
          "Dodaj współuczestnika",
        ),
        "addFiles": MessageLookupByLibrary.simpleMessage("Dodaj Pliki"),
        "addFromDevice":
            MessageLookupByLibrary.simpleMessage("Dodaj z urządzenia"),
        "addLocation":
            MessageLookupByLibrary.simpleMessage("Dodaj lokalizację"),
        "addLocationButton": MessageLookupByLibrary.simpleMessage("Dodaj"),
        "addMemoriesWidgetPrompt": MessageLookupByLibrary.simpleMessage(
          "Dodaj widżet wspomnień do ekranu głównego i wróć tutaj, aby dostosować.",
        ),
        "addMore": MessageLookupByLibrary.simpleMessage("Dodaj więcej"),
        "addName": MessageLookupByLibrary.simpleMessage("Dodaj nazwę"),
        "addNameOrMerge": MessageLookupByLibrary.simpleMessage(
          "Dodaj nazwę lub scal",
        ),
        "addNew": MessageLookupByLibrary.simpleMessage("Dodaj nowe"),
        "addNewPerson":
            MessageLookupByLibrary.simpleMessage("Dodaj nową osobę"),
        "addOnPageSubtitle": MessageLookupByLibrary.simpleMessage(
          "Szczegóły dodatków",
        ),
        "addOnValidTill": m3,
        "addOns": MessageLookupByLibrary.simpleMessage("Dodatki"),
        "addParticipants": MessageLookupByLibrary.simpleMessage(
          "Dodaj uczestników",
        ),
        "addPeopleWidgetPrompt": MessageLookupByLibrary.simpleMessage(
          "Dodaj widżet ludzi do ekranu głównego i wróć tutaj, aby dostosować.",
        ),
        "addPhotos": MessageLookupByLibrary.simpleMessage("Dodaj zdjęcia"),
        "addSelected": MessageLookupByLibrary.simpleMessage("Dodaj zaznaczone"),
        "addToAlbum": MessageLookupByLibrary.simpleMessage("Dodaj do albumu"),
        "addToEnte": MessageLookupByLibrary.simpleMessage("Dodaj do Ente"),
        "addToHiddenAlbum": MessageLookupByLibrary.simpleMessage(
          "Dodaj do ukrytego albumu",
        ),
        "addTrustedContact": MessageLookupByLibrary.simpleMessage(
          "Dodaj Zaufany Kontakt",
        ),
        "addViewer": MessageLookupByLibrary.simpleMessage("Dodaj widza"),
        "addYourPhotosNow": MessageLookupByLibrary.simpleMessage(
          "Dodaj swoje zdjęcia teraz",
        ),
        "addedAs": MessageLookupByLibrary.simpleMessage("Dodano jako"),
        "addedBy": m5,
        "addedSuccessfullyTo": m6,
        "addingToFavorites": MessageLookupByLibrary.simpleMessage(
          "Dodawanie do ulubionych...",
        ),
        "admiringThem": m7,
        "advanced": MessageLookupByLibrary.simpleMessage("Zaawansowane"),
        "advancedSettings":
            MessageLookupByLibrary.simpleMessage("Zaawansowane"),
        "after1Day": MessageLookupByLibrary.simpleMessage("Po 1 dniu"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("Po 1 godzinie"),
        "after1Month": MessageLookupByLibrary.simpleMessage("Po 1 miesiącu"),
        "after1Week": MessageLookupByLibrary.simpleMessage("Po 1 tygodniu"),
        "after1Year": MessageLookupByLibrary.simpleMessage("Po 1 roku"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Właściciel"),
        "albumParticipantsCount": m8,
        "albumTitle": MessageLookupByLibrary.simpleMessage("Tytuł albumu"),
        "albumUpdated": MessageLookupByLibrary.simpleMessage(
          "Album został zaktualizowany",
        ),
        "albums": MessageLookupByLibrary.simpleMessage("Albumy"),
        "albumsWidgetDesc": MessageLookupByLibrary.simpleMessage(
          "Wybierz albumy, które chcesz zobaczyć na ekranie głównym.",
        ),
        "allClear":
            MessageLookupByLibrary.simpleMessage("✨ Wszystko wyczyszczone"),
        "allMemoriesPreserved": MessageLookupByLibrary.simpleMessage(
          "Wszystkie wspomnienia zachowane",
        ),
        "allPersonGroupingWillReset": MessageLookupByLibrary.simpleMessage(
          "Wszystkie grupy dla tej osoby zostaną zresetowane i stracisz wszystkie sugestie dla tej osoby",
        ),
        "allUnnamedGroupsWillBeMergedIntoTheSelectedPerson":
            MessageLookupByLibrary.simpleMessage(
          "Wszystkie nienazwane grupy zostaną scalone z wybraną osobą. To nadal może zostać cofnięte z przeglądu historii sugestii danej osoby.",
        ),
        "allWillShiftRangeBasedOnFirst": MessageLookupByLibrary.simpleMessage(
          "To jest pierwsze w grupie. Inne wybrane zdjęcia zostaną automatycznie przesunięte w oparciu o tę nową datę",
        ),
        "allow": MessageLookupByLibrary.simpleMessage("Zezwól"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
          "Pozwól osobom z linkiem na dodawania zdjęć do udostępnionego albumu.",
        ),
        "allowAddingPhotos": MessageLookupByLibrary.simpleMessage(
          "Pozwól na dodawanie zdjęć",
        ),
        "allowAppToOpenSharedAlbumLinks": MessageLookupByLibrary.simpleMessage(
          "Zezwalaj aplikacji na otwieranie udostępnianych linków do albumu",
        ),
        "allowDownloads": MessageLookupByLibrary.simpleMessage(
          "Zezwól na pobieranie",
        ),
        "allowPeopleToAddPhotos": MessageLookupByLibrary.simpleMessage(
          "Pozwól innym dodawać zdjęcia",
        ),
        "allowPermBody": MessageLookupByLibrary.simpleMessage(
          "Prosimy zezwolić na dostęp do swoich zdjęć w Ustawieniach, aby Ente mogło wyświetlać i tworzyć kopię zapasową Twojej biblioteki.",
        ),
        "allowPermTitle": MessageLookupByLibrary.simpleMessage(
          "Zezwól na dostęp do zdjęć",
        ),
        "androidBiometricHint": MessageLookupByLibrary.simpleMessage(
          "Potwierdź swoją tożsamość",
        ),
        "androidBiometricNotRecognized": MessageLookupByLibrary.simpleMessage(
          "Nie rozpoznano. Spróbuj ponownie.",
        ),
        "androidBiometricRequiredTitle": MessageLookupByLibrary.simpleMessage(
          "Wymagana biometria",
        ),
        "androidBiometricSuccess":
            MessageLookupByLibrary.simpleMessage("Sukces"),
        "androidCancelButton": MessageLookupByLibrary.simpleMessage("Anuluj"),
        "androidDeviceCredentialsRequiredTitle":
            MessageLookupByLibrary.simpleMessage(
          "Wymagane dane logowania urządzenia",
        ),
        "androidDeviceCredentialsSetupDescription":
            MessageLookupByLibrary.simpleMessage(
          "Wymagane dane logowania urządzenia",
        ),
        "androidGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
          "Uwierzytelnianie biometryczne nie jest skonfigurowane na tym urządzeniu. Przejdź do \'Ustawienia > Bezpieczeństwo\', aby dodać uwierzytelnianie biometryczne.",
        ),
        "androidIosWebDesktop": MessageLookupByLibrary.simpleMessage(
          "Android, iOS, Strona Internetowa, Aplikacja Komputerowa",
        ),
        "androidSignInTitle": MessageLookupByLibrary.simpleMessage(
          "Wymagane uwierzytelnienie",
        ),
        "appIcon": MessageLookupByLibrary.simpleMessage("Ikona aplikacji"),
        "appLock": MessageLookupByLibrary.simpleMessage(
          "Blokada dostępu do aplikacji",
        ),
        "appLockDescriptions": MessageLookupByLibrary.simpleMessage(
          "Wybierz między domyślnym ekranem blokady urządzenia a niestandardowym ekranem blokady z kodem PIN lub hasłem.",
        ),
        "appVersion": m9,
        "appleId": MessageLookupByLibrary.simpleMessage("Apple ID"),
        "apply": MessageLookupByLibrary.simpleMessage("Zastosuj"),
        "applyCodeTitle": MessageLookupByLibrary.simpleMessage("Użyj kodu"),
        "appstoreSubscription": MessageLookupByLibrary.simpleMessage(
          "Subskrypcja AppStore",
        ),
        "archive": MessageLookupByLibrary.simpleMessage("Archiwum"),
        "archiveAlbum":
            MessageLookupByLibrary.simpleMessage("Archiwizuj album"),
        "archiving": MessageLookupByLibrary.simpleMessage("Archiwizowanie..."),
        "areThey": MessageLookupByLibrary.simpleMessage("Czy są "),
        "areYouSureRemoveThisFaceFromPerson":
            MessageLookupByLibrary.simpleMessage(
          "Czy na pewno chcesz usunąć tę twarz z tej osoby?",
        ),
        "areYouSureThatYouWantToLeaveTheFamily":
            MessageLookupByLibrary.simpleMessage(
          "Czy jesteś pewien/pewna, że chcesz opuścić plan rodzinny?",
        ),
        "areYouSureYouWantToCancel": MessageLookupByLibrary.simpleMessage(
          "Czy na pewno chcesz anulować?",
        ),
        "areYouSureYouWantToChangeYourPlan":
            MessageLookupByLibrary.simpleMessage(
          "Czy na pewno chcesz zmienić swój plan?",
        ),
        "areYouSureYouWantToExit": MessageLookupByLibrary.simpleMessage(
          "Czy na pewno chcesz wyjść?",
        ),
        "areYouSureYouWantToIgnoreThesePersons":
            MessageLookupByLibrary.simpleMessage(
          "Czy na pewno chcesz zignorować te osoby?",
        ),
        "areYouSureYouWantToIgnoreThisPerson":
            MessageLookupByLibrary.simpleMessage(
          "Czy na pewno chcesz zignorować tę osobę?",
        ),
        "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
          "Czy na pewno chcesz się wylogować?",
        ),
        "areYouSureYouWantToMergeThem": MessageLookupByLibrary.simpleMessage(
          "Czy na pewno chcesz je scalić?",
        ),
        "areYouSureYouWantToRenew": MessageLookupByLibrary.simpleMessage(
          "Czy na pewno chcesz odnowić?",
        ),
        "areYouSureYouWantToResetThisPerson":
            MessageLookupByLibrary.simpleMessage(
          "Czy na pewno chcesz zresetować tę osobę?",
        ),
        "askCancelReason": MessageLookupByLibrary.simpleMessage(
          "Twoja subskrypcja została anulowana. Czy chcesz podzielić się powodem?",
        ),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
          "Jaka jest główna przyczyna usunięcia Twojego konta?",
        ),
        "askYourLovedOnesToShare": MessageLookupByLibrary.simpleMessage(
          "Poproś swoich bliskich o udostępnienie",
        ),
        "atAFalloutShelter": MessageLookupByLibrary.simpleMessage("w schronie"),
        "authToChangeEmailVerificationSetting":
            MessageLookupByLibrary.simpleMessage(
          "Prosimy uwierzytelnić się, aby zmienić weryfikację e-mail",
        ),
        "authToChangeLockscreenSetting": MessageLookupByLibrary.simpleMessage(
          "Prosimy uwierzytelnić się, aby zmienić ustawienia ekranu blokady",
        ),
        "authToChangeYourEmail": MessageLookupByLibrary.simpleMessage(
          "Prosimy uwierzytelnić się, aby zmienić swój adres e-mail",
        ),
        "authToChangeYourPassword": MessageLookupByLibrary.simpleMessage(
          "Prosimy uwierzytelnić się, aby zmienić hasło",
        ),
        "authToConfigureTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
          "Uwierzytelnij się, aby skonfigurować uwierzytelnianie dwustopniowe",
        ),
        "authToInitiateAccountDeletion": MessageLookupByLibrary.simpleMessage(
          "Prosimy uwierzytelnić się, aby zainicjować usuwanie konta",
        ),
        "authToManageLegacy": MessageLookupByLibrary.simpleMessage(
          "Prosimy uwierzytelnić się, aby zarządzać zaufanymi kontaktami",
        ),
        "authToViewPasskey": MessageLookupByLibrary.simpleMessage(
          "Prosimy uwierzytelnić się, aby wyświetlić swój klucz dostępu",
        ),
        "authToViewTrashedFiles": MessageLookupByLibrary.simpleMessage(
          "Prosimy uwierzytelnić się, aby wyświetlić swoje pliki w koszu",
        ),
        "authToViewYourActiveSessions": MessageLookupByLibrary.simpleMessage(
          "Prosimy uwierzytelnić się, aby wyświetlić swoje aktywne sesje",
        ),
        "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
          "Prosimy uwierzytelnić się, aby wyświetlić ukryte pliki",
        ),
        "authToViewYourMemories": MessageLookupByLibrary.simpleMessage(
          "Prosimy uwierzytelnić się, aby wyświetlić swoje wspomnienia",
        ),
        "authToViewYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
          "Prosimy uwierzytelnić się, aby wyświetlić swój klucz odzyskiwania",
        ),
        "authenticating": MessageLookupByLibrary.simpleMessage(
          "Uwierzytelnianie...",
        ),
        "authenticationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
          "Uwierzytelnianie nie powiodło się, prosimy spróbować ponownie",
        ),
        "authenticationSuccessful": MessageLookupByLibrary.simpleMessage(
          "Uwierzytelnianie powiodło się!",
        ),
        "autoCastDialogBody": MessageLookupByLibrary.simpleMessage(
          "Tutaj zobaczysz dostępne urządzenia Cast.",
        ),
        "autoCastiOSPermission": MessageLookupByLibrary.simpleMessage(
          "Upewnij się, że uprawnienia sieci lokalnej są włączone dla aplikacji Zdjęcia Ente w Ustawieniach.",
        ),
        "autoLock":
            MessageLookupByLibrary.simpleMessage("Automatyczna blokada"),
        "autoLockFeatureDescription": MessageLookupByLibrary.simpleMessage(
          "Czas, po którym aplikacja blokuje się po umieszczeniu jej w tle",
        ),
        "autoLogoutMessage": MessageLookupByLibrary.simpleMessage(
          "Z powodu technicznego błędu, zostałeś wylogowany. Przepraszamy za niedogodności.",
        ),
        "autoPair":
            MessageLookupByLibrary.simpleMessage("Automatyczne parowanie"),
        "autoPairDesc": MessageLookupByLibrary.simpleMessage(
          "Automatyczne parowanie działa tylko z urządzeniami obsługującymi Chromecast.",
        ),
        "available": MessageLookupByLibrary.simpleMessage("Dostępne"),
        "availableStorageSpace": m10,
        "backedUpFolders": MessageLookupByLibrary.simpleMessage(
          "Foldery kopii zapasowej",
        ),
        "backgroundWithThem": m11,
        "backup": MessageLookupByLibrary.simpleMessage("Kopia zapasowa"),
        "backupFailed": MessageLookupByLibrary.simpleMessage(
          "Tworzenie kopii zapasowej nie powiodło się",
        ),
        "backupFile": MessageLookupByLibrary.simpleMessage(
          "Zrób kopię zapasową pliku",
        ),
        "backupOverMobileData": MessageLookupByLibrary.simpleMessage(
          "Kopia zapasowa przez dane mobilne",
        ),
        "backupSettings": MessageLookupByLibrary.simpleMessage(
          "Ustawienia kopii zapasowej",
        ),
        "backupStatus": MessageLookupByLibrary.simpleMessage(
          "Status kopii zapasowej",
        ),
        "backupStatusDescription": MessageLookupByLibrary.simpleMessage(
          "Elementy, których kopia zapasowa została utworzona, zostaną wyświetlone w tym miejscu",
        ),
        "backupVideos": MessageLookupByLibrary.simpleMessage(
          "Utwórz kopię zapasową wideo",
        ),
        "beach": MessageLookupByLibrary.simpleMessage("Piasek i morze"),
        "birthday": MessageLookupByLibrary.simpleMessage("Urodziny"),
        "birthdayNotifications": MessageLookupByLibrary.simpleMessage(
          "Powiadomienia o urodzinach",
        ),
        "birthdays": MessageLookupByLibrary.simpleMessage("Urodziny"),
        "blackFridaySale": MessageLookupByLibrary.simpleMessage(
          "Wyprzedaż z okazji Czarnego Piątku",
        ),
        "blog": MessageLookupByLibrary.simpleMessage("Blog"),
        "cLDesc1": MessageLookupByLibrary.simpleMessage(
          "W związku z uruchomieniem wersji beta przesyłania strumieniowego wideo oraz pracami nad możliwością wznawiania przesyłania i pobierania plików, zwiększyliśmy limit przesyłanych plików do 10 GB. Jest to już dostępne zarówno w aplikacjach na komputery, jak i na urządzenia mobilne.",
        ),
        "cLDesc2": MessageLookupByLibrary.simpleMessage(
          "Funkcja przesyłania w tle jest teraz obsługiwana również na urządzeniach z systemem iOS, oprócz urządzeń z Androidem. Nie trzeba już otwierać aplikacji, aby utworzyć kopię zapasową najnowszych zdjęć i filmów.",
        ),
        "cLDesc3": MessageLookupByLibrary.simpleMessage(
          "Wprowadziliśmy istotne ulepszenia w funkcji wspomnień, w tym automatyczne odtwarzanie, przesuwanie do kolejnego wspomnienia i wiele innych.",
        ),
        "cLDesc4": MessageLookupByLibrary.simpleMessage(
          "Wraz z kilkoma ulepszeniami w mechanizmie teraz znacznie łatwiej jest widzieć wszystkie wykryte twarze, zapewniać informacje zwrotne o podobnych twarzach i dodawać/usuwać twarze z jednego zdjęcia.",
        ),
        "cLDesc5": MessageLookupByLibrary.simpleMessage(
          "Od teraz otrzymasz powiadomienie z możliwością rezygnacji dotyczące wszystkich zapisanych urodzin w Ente, wraz z kolekcją najlepszych zdjęć danej osoby.",
        ),
        "cLDesc6": MessageLookupByLibrary.simpleMessage(
          "Nie musisz już czekać na zakończenie przesyłania ani pobierania, żeby móc zamknąć aplikację. Wszystkie operacje przesyłania i pobierania można teraz wstrzymać w dowolnym momencie i wznowić od miejsca, w którym zostały przerwane.",
        ),
        "cLTitle1": MessageLookupByLibrary.simpleMessage(
          "Przesyłanie Dużych Plików Wideo",
        ),
        "cLTitle2": MessageLookupByLibrary.simpleMessage("Przesyłanie w Tle"),
        "cLTitle3": MessageLookupByLibrary.simpleMessage(
          "Automatyczne Odtwarzanie Wspomnień",
        ),
        "cLTitle4": MessageLookupByLibrary.simpleMessage(
          "Ulepszone Rozpoznawanie Twarzy",
        ),
        "cLTitle5": MessageLookupByLibrary.simpleMessage(
          "Powiadomienia o Urodzinach",
        ),
        "cLTitle6": MessageLookupByLibrary.simpleMessage(
          "Wznawialne Przesyłanie i Pobieranie Danych",
        ),
        "cachedData": MessageLookupByLibrary.simpleMessage(
          "Dane w pamięci podręcznej",
        ),
        "calculating": MessageLookupByLibrary.simpleMessage("Obliczanie..."),
        "canNotOpenBody": MessageLookupByLibrary.simpleMessage(
          "Przepraszamy, ten album nie może zostać otwarty w aplikacji.",
        ),
        "canNotOpenTitle": MessageLookupByLibrary.simpleMessage(
          "Nie można otworzyć tego albumu",
        ),
        "canNotUploadToAlbumsOwnedByOthers":
            MessageLookupByLibrary.simpleMessage(
          "Nie można przesłać do albumów należących do innych",
        ),
        "canOnlyCreateLinkForFilesOwnedByYou":
            MessageLookupByLibrary.simpleMessage(
          "Można tylko utworzyć link dla plików należących do Ciebie",
        ),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
          "Można usuwać tylko pliki należące do Ciebie",
        ),
        "cancel": MessageLookupByLibrary.simpleMessage("Anuluj"),
        "cancelAccountRecovery": MessageLookupByLibrary.simpleMessage(
          "Anuluj odzyskiwanie",
        ),
        "cancelAccountRecoveryBody": MessageLookupByLibrary.simpleMessage(
          "Czy na pewno chcesz anulować odzyskiwanie?",
        ),
        "cancelOtherSubscription": m12,
        "cancelSubscription": MessageLookupByLibrary.simpleMessage(
          "Anuluj subskrypcję",
        ),
        "cannotAddMorePhotosAfterBecomingViewer": m13,
        "cannotDeleteSharedFiles": MessageLookupByLibrary.simpleMessage(
          "Nie można usunąć udostępnionych plików",
        ),
        "castAlbum": MessageLookupByLibrary.simpleMessage("Odtwórz album"),
        "castIPMismatchBody": MessageLookupByLibrary.simpleMessage(
          "Upewnij się, że jesteś w tej samej sieci co telewizor.",
        ),
        "castIPMismatchTitle": MessageLookupByLibrary.simpleMessage(
          "Nie udało się wyświetlić albumu",
        ),
        "castInstruction": MessageLookupByLibrary.simpleMessage(
          "Odwiedź cast.ente.io na urządzeniu, które chcesz sparować.\n\nWprowadź poniższy kod, aby odtworzyć album na telewizorze.",
        ),
        "centerPoint": MessageLookupByLibrary.simpleMessage("Punkt środkowy"),
        "change": MessageLookupByLibrary.simpleMessage("Zmień"),
        "changeEmail":
            MessageLookupByLibrary.simpleMessage("Zmień adres e-mail"),
        "changeLocationOfSelectedItems": MessageLookupByLibrary.simpleMessage(
          "Zmienić lokalizację wybranych elementów?",
        ),
        "changePassword": MessageLookupByLibrary.simpleMessage("Zmień hasło"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Zmień hasło"),
        "changePermissions": MessageLookupByLibrary.simpleMessage(
          "Zmień uprawnienia?",
        ),
        "changeYourReferralCode": MessageLookupByLibrary.simpleMessage(
          "Zmień swój kod polecający",
        ),
        "checkForUpdates": MessageLookupByLibrary.simpleMessage(
          "Sprawdź dostępne aktualizacje",
        ),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
          "Sprawdź swoją skrzynkę odbiorczą (i spam), aby zakończyć weryfikację",
        ),
        "checkStatus": MessageLookupByLibrary.simpleMessage("Sprawdź stan"),
        "checking": MessageLookupByLibrary.simpleMessage("Sprawdzanie..."),
        "checkingModels": MessageLookupByLibrary.simpleMessage(
          "Sprawdzanie modeli...",
        ),
        "city": MessageLookupByLibrary.simpleMessage("W mieście"),
        "claimFreeStorage": MessageLookupByLibrary.simpleMessage(
          "Odbierz bezpłatną przestrzeń dyskową",
        ),
        "claimMore": MessageLookupByLibrary.simpleMessage("Zdobądź więcej!"),
        "claimed": MessageLookupByLibrary.simpleMessage("Odebrano"),
        "claimedStorageSoFar": m14,
        "cleanUncategorized": MessageLookupByLibrary.simpleMessage(
          "Wyczyść Nieskategoryzowane",
        ),
        "cleanUncategorizedDescription": MessageLookupByLibrary.simpleMessage(
          "Usuń wszystkie pliki z Nieskategoryzowanych, które są obecne w innych albumach",
        ),
        "clearCaches": MessageLookupByLibrary.simpleMessage(
          "Wyczyść pamięć podręczną",
        ),
        "clearIndexes": MessageLookupByLibrary.simpleMessage("Wyczyść indeksy"),
        "click": MessageLookupByLibrary.simpleMessage("• Kliknij"),
        "clickOnTheOverflowMenu": MessageLookupByLibrary.simpleMessage(
          "• Kliknij na menu przepełnienia",
        ),
        "clickToInstallOurBestVersionYet": MessageLookupByLibrary.simpleMessage(
          "Kliknij, aby zainstalować naszą najlepszą wersję",
        ),
        "close": MessageLookupByLibrary.simpleMessage("Zamknij"),
        "clubByCaptureTime": MessageLookupByLibrary.simpleMessage(
          "Club według czasu przechwycenia",
        ),
        "clubByFileName": MessageLookupByLibrary.simpleMessage(
          "Club według nazwy pliku",
        ),
        "clusteringProgress": MessageLookupByLibrary.simpleMessage(
          "Postęp tworzenia klastrów",
        ),
        "codeAppliedPageTitle": MessageLookupByLibrary.simpleMessage(
          "Kod został zastosowany",
        ),
        "codeChangeLimitReached": MessageLookupByLibrary.simpleMessage(
          "Przepraszamy, osiągnięto limit zmian kodu.",
        ),
        "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
          "Kod został skopiowany do schowka",
        ),
        "codeUsedByYou": MessageLookupByLibrary.simpleMessage(
          "Kod użyty przez Ciebie",
        ),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
          "Utwórz link, aby umożliwić innym dodawanie i przeglądanie zdjęć w udostępnionym albumie bez konieczności korzystania z aplikacji lub konta Ente. Świetne rozwiązanie do gromadzenia zdjęć ze wspólnych wydarzeń.",
        ),
        "collaborativeLink": MessageLookupByLibrary.simpleMessage(
          "Link do współpracy",
        ),
        "collaborativeLinkCreatedFor": m15,
        "collaborator": MessageLookupByLibrary.simpleMessage("Współuczestnik"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
          "Współuczestnicy mogą dodawać zdjęcia i wideo do udostępnionego albumu.",
        ),
        "collaboratorsSuccessfullyAdded": m16,
        "collageLayout": MessageLookupByLibrary.simpleMessage("Układ"),
        "collageSaved": MessageLookupByLibrary.simpleMessage(
          "Kolaż zapisano w galerii",
        ),
        "collect": MessageLookupByLibrary.simpleMessage("Zbieraj"),
        "collectEventPhotos": MessageLookupByLibrary.simpleMessage(
          "Zbierz zdjęcia z wydarzenia",
        ),
        "collectPhotos": MessageLookupByLibrary.simpleMessage("Zbierz zdjęcia"),
        "collectPhotosDescription": MessageLookupByLibrary.simpleMessage(
          "Utwórz link, w którym Twoi znajomi mogą przesyłać zdjęcia w oryginalnej jakości.",
        ),
        "color": MessageLookupByLibrary.simpleMessage("Kolor"),
        "configuration": MessageLookupByLibrary.simpleMessage("Konfiguracja"),
        "confirm": MessageLookupByLibrary.simpleMessage("Potwierdź"),
        "confirm2FADisable": MessageLookupByLibrary.simpleMessage(
          "Czy na pewno chcesz wyłączyć uwierzytelnianie dwustopniowe?",
        ),
        "confirmAccountDeletion": MessageLookupByLibrary.simpleMessage(
          "Potwierdź usunięcie konta",
        ),
        "confirmAddingTrustedContact": m17,
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
          "Tak, chcę trwale usunąć to konto i jego dane ze wszystkich aplikacji.",
        ),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Powtórz hasło"),
        "confirmPlanChange": MessageLookupByLibrary.simpleMessage(
          "Potwierdź zmianę planu",
        ),
        "confirmRecoveryKey": MessageLookupByLibrary.simpleMessage(
          "Potwierdź klucz odzyskiwania",
        ),
        "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
          "Potwierdź klucz odzyskiwania",
        ),
        "connectToDevice": MessageLookupByLibrary.simpleMessage(
          "Połącz z urządzeniem",
        ),
        "contactFamilyAdmin": m18,
        "contactSupport": MessageLookupByLibrary.simpleMessage(
          "Skontaktuj się z pomocą techniczną",
        ),
        "contactToManageSubscription": m19,
        "contacts": MessageLookupByLibrary.simpleMessage("Kontakty"),
        "contents": MessageLookupByLibrary.simpleMessage("Zawartość"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("Kontynuuj"),
        "continueOnFreeTrial": MessageLookupByLibrary.simpleMessage(
          "Kontynuuj bezpłatny okres próbny",
        ),
        "convertToAlbum": MessageLookupByLibrary.simpleMessage(
          "Konwertuj na album",
        ),
        "copyEmailAddress": MessageLookupByLibrary.simpleMessage(
          "Kopiuj adres e-mail",
        ),
        "copyLink": MessageLookupByLibrary.simpleMessage("Skopiuj link"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
          "Kopiuj, wklej ten kod\ndo swojej aplikacji uwierzytelniającej",
        ),
        "couldNotBackUpTryLater": MessageLookupByLibrary.simpleMessage(
          "Nie można utworzyć kopii zapasowej Twoich danych.\nSpróbujemy ponownie później.",
        ),
        "couldNotFreeUpSpace": MessageLookupByLibrary.simpleMessage(
          "Nie udało się zwolnić miejsca",
        ),
        "couldNotUpdateSubscription": MessageLookupByLibrary.simpleMessage(
          "Nie można było zaktualizować subskrybcji",
        ),
        "count": MessageLookupByLibrary.simpleMessage("Ilość"),
        "crashReporting":
            MessageLookupByLibrary.simpleMessage("Zgłaszanie awarii"),
        "create": MessageLookupByLibrary.simpleMessage("Utwórz"),
        "createAccount": MessageLookupByLibrary.simpleMessage("Stwórz konto"),
        "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
          "Przytrzymaj, aby wybrać zdjęcia i kliknij +, aby utworzyć album",
        ),
        "createCollaborativeLink": MessageLookupByLibrary.simpleMessage(
          "Utwórz link współpracy",
        ),
        "createCollage": MessageLookupByLibrary.simpleMessage("Utwórz kolaż"),
        "createNewAccount": MessageLookupByLibrary.simpleMessage(
          "Stwórz nowe konto",
        ),
        "createOrSelectAlbum": MessageLookupByLibrary.simpleMessage(
          "Utwórz lub wybierz album",
        ),
        "createPublicLink": MessageLookupByLibrary.simpleMessage(
          "Utwórz publiczny link",
        ),
        "creatingLink":
            MessageLookupByLibrary.simpleMessage("Tworzenie linku..."),
        "criticalUpdateAvailable": MessageLookupByLibrary.simpleMessage(
          "Dostępna jest krytyczna aktualizacja",
        ),
        "crop": MessageLookupByLibrary.simpleMessage("Kadruj"),
        "curatedMemories": MessageLookupByLibrary.simpleMessage(
          "Wyselekcjonowane wspomnienia",
        ),
        "currentUsageIs": MessageLookupByLibrary.simpleMessage(
          "Aktualne użycie to ",
        ),
        "currentlyRunning": MessageLookupByLibrary.simpleMessage(
          "aktualnie uruchomiony",
        ),
        "custom": MessageLookupByLibrary.simpleMessage("Niestandardowy"),
        "customEndpoint": m20,
        "darkTheme": MessageLookupByLibrary.simpleMessage("Ciemny"),
        "dayToday": MessageLookupByLibrary.simpleMessage("Dzisiaj"),
        "dayYesterday": MessageLookupByLibrary.simpleMessage("Wczoraj"),
        "declineTrustInvite": MessageLookupByLibrary.simpleMessage(
          "Odrzuć Zaproszenie",
        ),
        "decrypting": MessageLookupByLibrary.simpleMessage("Odszyfrowanie..."),
        "decryptingVideo": MessageLookupByLibrary.simpleMessage(
          "Odszyfrowywanie wideo...",
        ),
        "deduplicateFiles": MessageLookupByLibrary.simpleMessage(
          "Odduplikuj pliki",
        ),
        "delete": MessageLookupByLibrary.simpleMessage("Usuń"),
        "deleteAccount": MessageLookupByLibrary.simpleMessage("Usuń konto"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
          "Przykro nam, że odchodzisz. Wyjaśnij nam, dlaczego nas opuszczasz, aby pomóc ulepszać nasze usługi.",
        ),
        "deleteAccountPermanentlyButton": MessageLookupByLibrary.simpleMessage(
          "Usuń konto na stałe",
        ),
        "deleteAlbum": MessageLookupByLibrary.simpleMessage("Usuń album"),
        "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
          "Usunąć również zdjęcia (i wideo) znajdujące się w tym albumie ze <bold>wszystkich</bold> innych albumów, których są częścią?",
        ),
        "deleteAlbumsDialogBody": MessageLookupByLibrary.simpleMessage(
          "Spowoduje to usunięcie wszystkich pustych albumów. Jest to przydatne, gdy chcesz zmniejszyć ilość śmieci na liście albumów.",
        ),
        "deleteAll": MessageLookupByLibrary.simpleMessage("Usuń Wszystko"),
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
          "To konto jest połączone z innymi aplikacjami Ente, jeśli ich używasz. Twoje przesłane dane, we wszystkich aplikacjach Ente, zostaną zaplanowane do usunięcia, a Twoje konto zostanie trwale usunięte.",
        ),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
          "Wyślij wiadomość e-mail na <warning>account-deletion@ente.io</warning> z zarejestrowanego adresu e-mail.",
        ),
        "deleteEmptyAlbums": MessageLookupByLibrary.simpleMessage(
          "Usuń puste albumy",
        ),
        "deleteEmptyAlbumsWithQuestionMark":
            MessageLookupByLibrary.simpleMessage(
          "Usunąć puste albumy?",
        ),
        "deleteFromBoth": MessageLookupByLibrary.simpleMessage("Usuń z obu"),
        "deleteFromDevice": MessageLookupByLibrary.simpleMessage(
          "Usuń z urządzenia",
        ),
        "deleteFromEnte": MessageLookupByLibrary.simpleMessage("Usuń z Ente"),
        "deleteItemCount": m21,
        "deleteLocation":
            MessageLookupByLibrary.simpleMessage("Usuń lokalizację"),
        "deleteMultipleAlbumDialog": m22,
        "deletePhotos": MessageLookupByLibrary.simpleMessage("Usuń zdjęcia"),
        "deleteProgress": m23,
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
          "Brakuje kluczowej funkcji, której potrzebuję",
        ),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
          "Aplikacja lub określona funkcja nie zachowuje się tak, jak sądzę, że powinna",
        ),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
          "Znalazłem/am inną, lepszą usługę",
        ),
        "deleteReason4": MessageLookupByLibrary.simpleMessage(
          "Moja przyczyna nie jest wymieniona",
        ),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
          "Twoje żądanie zostanie przetworzone w ciągu 72 godzin.",
        ),
        "deleteSharedAlbum": MessageLookupByLibrary.simpleMessage(
          "Usunąć udostępniony album?",
        ),
        "deleteSharedAlbumDialogBody": MessageLookupByLibrary.simpleMessage(
          "Album zostanie usunięty dla wszystkich\n\nUtracisz dostęp do udostępnionych zdjęć w tym albumie, które są własnością innych osób",
        ),
        "deselectAll": MessageLookupByLibrary.simpleMessage("Odznacz wszystko"),
        "designedToOutlive": MessageLookupByLibrary.simpleMessage(
          "Zaprojektowane do przetrwania",
        ),
        "details": MessageLookupByLibrary.simpleMessage("Szczegóły"),
        "developerSettings": MessageLookupByLibrary.simpleMessage(
          "Ustawienia dla programistów",
        ),
        "developerSettingsWarning": MessageLookupByLibrary.simpleMessage(
          "Czy na pewno chcesz zmodyfikować ustawienia programisty?",
        ),
        "deviceCodeHint": MessageLookupByLibrary.simpleMessage("Wprowadź kod"),
        "deviceFilesAutoUploading": MessageLookupByLibrary.simpleMessage(
          "Pliki dodane do tego albumu urządzenia zostaną automatycznie przesłane do Ente.",
        ),
        "deviceLock":
            MessageLookupByLibrary.simpleMessage("Blokada urządzenia"),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
          "Wyłącz blokadę ekranu urządzenia, gdy Ente jest na pierwszym planie i w trakcie tworzenia kopii zapasowej. Zwykle nie jest to potrzebne, ale może pomóc w szybszym przesyłaniu i początkowym imporcie dużych bibliotek.",
        ),
        "deviceNotFound": MessageLookupByLibrary.simpleMessage(
          "Nie znaleziono urządzenia",
        ),
        "didYouKnow":
            MessageLookupByLibrary.simpleMessage("Czy wiedziałeś/aś?"),
        "different": MessageLookupByLibrary.simpleMessage("Inne"),
        "disableAutoLock": MessageLookupByLibrary.simpleMessage(
          "Wyłącz automatyczną blokadę",
        ),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
          "Widzowie mogą nadal robić zrzuty ekranu lub zapisywać kopie zdjęć za pomocą programów trzecich",
        ),
        "disableDownloadWarningTitle": MessageLookupByLibrary.simpleMessage(
          "Uwaga",
        ),
        "disableLinkMessage": m24,
        "disableTwofactor": MessageLookupByLibrary.simpleMessage(
          "Wyłącz uwierzytelnianie dwustopniowe",
        ),
        "disablingTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
          "Uwierzytelnianie dwustopniowe jest wyłączane...",
        ),
        "discord": MessageLookupByLibrary.simpleMessage("Discord"),
        "discover": MessageLookupByLibrary.simpleMessage("Odkryj"),
        "discover_babies": MessageLookupByLibrary.simpleMessage("Niemowlęta"),
        "discover_celebrations": MessageLookupByLibrary.simpleMessage(
          "Uroczystości",
        ),
        "discover_food": MessageLookupByLibrary.simpleMessage("Jedzenie"),
        "discover_greenery": MessageLookupByLibrary.simpleMessage("Zieleń"),
        "discover_hills": MessageLookupByLibrary.simpleMessage("Wzgórza"),
        "discover_identity": MessageLookupByLibrary.simpleMessage("Tożsamość"),
        "discover_memes": MessageLookupByLibrary.simpleMessage("Memy"),
        "discover_notes": MessageLookupByLibrary.simpleMessage("Notatki"),
        "discover_pets":
            MessageLookupByLibrary.simpleMessage("Zwierzęta domowe"),
        "discover_receipts": MessageLookupByLibrary.simpleMessage("Paragony"),
        "discover_screenshots": MessageLookupByLibrary.simpleMessage(
          "Zrzuty ekranu",
        ),
        "discover_selfies": MessageLookupByLibrary.simpleMessage("Selfie"),
        "discover_sunset":
            MessageLookupByLibrary.simpleMessage("Zachód słońca"),
        "discover_visiting_cards": MessageLookupByLibrary.simpleMessage(
          "Wizytówki",
        ),
        "discover_wallpapers": MessageLookupByLibrary.simpleMessage("Tapety"),
        "dismiss": MessageLookupByLibrary.simpleMessage("Odrzuć"),
        "distanceInKMUnit": MessageLookupByLibrary.simpleMessage("km"),
        "doNotSignOut":
            MessageLookupByLibrary.simpleMessage("Nie wylogowuj mnie"),
        "doThisLater": MessageLookupByLibrary.simpleMessage("Spróbuj później"),
        "doYouWantToDiscardTheEditsYouHaveMade":
            MessageLookupByLibrary.simpleMessage(
          "Czy chcesz odrzucić dokonane zmiany?",
        ),
        "done": MessageLookupByLibrary.simpleMessage("Gotowe"),
        "dontSave": MessageLookupByLibrary.simpleMessage("Nie zapisuj"),
        "doubleYourStorage": MessageLookupByLibrary.simpleMessage(
          "Podwój swoją przestrzeń dyskową",
        ),
        "download": MessageLookupByLibrary.simpleMessage("Pobierz"),
        "downloadFailed": MessageLookupByLibrary.simpleMessage(
          "Pobieranie nie powiodło się",
        ),
        "downloading": MessageLookupByLibrary.simpleMessage("Pobieranie..."),
        "dropSupportEmail": m25,
        "duplicateFileCountWithStorageSaved": m26,
        "duplicateItemsGroup": m27,
        "edit": MessageLookupByLibrary.simpleMessage("Edytuj"),
        "editEmailAlreadyLinked": m28,
        "editLocation":
            MessageLookupByLibrary.simpleMessage("Edytuj lokalizację"),
        "editLocationTagTitle": MessageLookupByLibrary.simpleMessage(
          "Edytuj lokalizację",
        ),
        "editPerson": MessageLookupByLibrary.simpleMessage("Edytuj osobę"),
        "editTime": MessageLookupByLibrary.simpleMessage("Edytuj czas"),
        "editsSaved": MessageLookupByLibrary.simpleMessage("Edycje zapisane"),
        "editsToLocationWillOnlyBeSeenWithinEnte":
            MessageLookupByLibrary.simpleMessage(
          "Edycje lokalizacji będą widoczne tylko w Ente",
        ),
        "eligible": MessageLookupByLibrary.simpleMessage("kwalifikujący się"),
        "email": MessageLookupByLibrary.simpleMessage("Adres e-mail"),
        "emailAlreadyRegistered": MessageLookupByLibrary.simpleMessage(
          "Adres e-mail jest już zarejestrowany.",
        ),
        "emailChangedTo": m29,
        "emailDoesNotHaveEnteAccount": m30,
        "emailNoEnteAccount": m31,
        "emailNotRegistered": MessageLookupByLibrary.simpleMessage(
          "Adres e-mail nie jest zarejestrowany.",
        ),
        "emailVerificationToggle": MessageLookupByLibrary.simpleMessage(
          "Weryfikacja e-mail",
        ),
        "emailYourLogs":
            MessageLookupByLibrary.simpleMessage("Wyślij mailem logi"),
        "emergencyContacts": MessageLookupByLibrary.simpleMessage(
          "Kontakty Alarmowe",
        ),
        "empty": MessageLookupByLibrary.simpleMessage("Opróżnij"),
        "emptyTrash": MessageLookupByLibrary.simpleMessage("Opróżnić kosz?"),
        "enable": MessageLookupByLibrary.simpleMessage("Włącz"),
        "enableMLIndexingDesc": MessageLookupByLibrary.simpleMessage(
          "Ente obsługuje nauczanie maszynowe na urządzeniu dla rozpoznawania twarzy, wyszukiwania magicznego i innych zaawansowanych funkcji wyszukiwania",
        ),
        "enableMachineLearningBanner": MessageLookupByLibrary.simpleMessage(
          "Włącz nauczanie maszynowe dla magicznego wyszukiwania i rozpoznawania twarzy",
        ),
        "enableMaps": MessageLookupByLibrary.simpleMessage("Włącz mapy"),
        "enableMapsDesc": MessageLookupByLibrary.simpleMessage(
          "To pokaże Twoje zdjęcia na mapie świata.\n\nTa mapa jest hostowana przez Open Street Map, a dokładne lokalizacje Twoich zdjęć nigdy nie są udostępniane.\n\nMożesz wyłączyć tę funkcję w każdej chwili w ustawieniach.",
        ),
        "enabled": MessageLookupByLibrary.simpleMessage("Włączone"),
        "encryptingBackup": MessageLookupByLibrary.simpleMessage(
          "Szyfrowanie kopii zapasowej...",
        ),
        "encryption": MessageLookupByLibrary.simpleMessage("Szyfrowanie"),
        "encryptionKeys": MessageLookupByLibrary.simpleMessage(
          "Klucze szyfrowania",
        ),
        "endpointUpdatedMessage": MessageLookupByLibrary.simpleMessage(
          "Punkt końcowy zaktualizowano pomyślnie",
        ),
        "endtoendEncryptedByDefault": MessageLookupByLibrary.simpleMessage(
          "Domyślnie zaszyfrowane metodą end-to-end",
        ),
        "enteCanEncryptAndPreserveFilesOnlyIfYouGrant":
            MessageLookupByLibrary.simpleMessage(
          "Ente może zaszyfrować i zachować pliki tylko wtedy, gdy udzielisz do nich dostępu",
        ),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
          "Ente <i>potrzebuje uprawnień</i> aby przechowywać twoje zdjęcia",
        ),
        "enteSubscriptionPitch": MessageLookupByLibrary.simpleMessage(
          "Ente zachowuje Twoje wspomnienia, więc są zawsze dostępne dla Ciebie, nawet jeśli zgubisz urządzenie.",
        ),
        "enteSubscriptionShareWithFamily": MessageLookupByLibrary.simpleMessage(
          "Twoja rodzina może być również dodana do Twojego planu.",
        ),
        "enterAlbumName": MessageLookupByLibrary.simpleMessage(
          "Wprowadź nazwę albumu",
        ),
        "enterCode": MessageLookupByLibrary.simpleMessage("Wprowadź kod"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
          "Wprowadź kod dostarczony przez znajomego, aby uzyskać bezpłatne miejsce dla was obojga",
        ),
        "enterDateOfBirth": MessageLookupByLibrary.simpleMessage(
          "Urodziny (nieobowiązkowo)",
        ),
        "enterEmail":
            MessageLookupByLibrary.simpleMessage("Wprowadź adres e-mail"),
        "enterFileName": MessageLookupByLibrary.simpleMessage(
          "Wprowadź nazwę pliku",
        ),
        "enterName": MessageLookupByLibrary.simpleMessage("Wprowadź nazwę"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
          "Wprowadź nowe hasło, którego możemy użyć do zaszyfrowania Twoich danych",
        ),
        "enterPassword": MessageLookupByLibrary.simpleMessage("Wprowadź hasło"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
          "Wprowadź hasło, którego możemy użyć do zaszyfrowania Twoich danych",
        ),
        "enterPersonName": MessageLookupByLibrary.simpleMessage(
          "Wprowadź imię osoby",
        ),
        "enterPin": MessageLookupByLibrary.simpleMessage("Wprowadź kod PIN"),
        "enterReferralCode": MessageLookupByLibrary.simpleMessage(
          "Wprowadź kod polecenia",
        ),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
          "Wprowadź 6-cyfrowy kod z\nTwojej aplikacji uwierzytelniającej",
        ),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
          "Prosimy podać prawidłowy adres e-mail.",
        ),
        "enterYourEmailAddress": MessageLookupByLibrary.simpleMessage(
          "Podaj swój adres e-mail",
        ),
        "enterYourNewEmailAddress": MessageLookupByLibrary.simpleMessage(
          "Podaj swój nowy adres e-mail",
        ),
        "enterYourPassword":
            MessageLookupByLibrary.simpleMessage("Wprowadź hasło"),
        "enterYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
          "Wprowadź swój klucz odzyskiwania",
        ),
        "error": MessageLookupByLibrary.simpleMessage("Błąd"),
        "everywhere": MessageLookupByLibrary.simpleMessage("wszędzie"),
        "exif": MessageLookupByLibrary.simpleMessage("EXIF"),
        "existingUser": MessageLookupByLibrary.simpleMessage(
          "Istniejący użytkownik",
        ),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
          "Ten link wygasł. Wybierz nowy czas wygaśnięcia lub wyłącz automatyczne wygasanie linku.",
        ),
        "exportLogs": MessageLookupByLibrary.simpleMessage("Eksportuj logi"),
        "exportYourData": MessageLookupByLibrary.simpleMessage(
          "Eksportuj swoje dane",
        ),
        "extraPhotosFound": MessageLookupByLibrary.simpleMessage(
          "Znaleziono dodatkowe zdjęcia",
        ),
        "extraPhotosFoundFor": m33,
        "faceNotClusteredYet": MessageLookupByLibrary.simpleMessage(
          "Twarz jeszcze nie zgrupowana, prosimy wrócić później",
        ),
        "faceRecognition": MessageLookupByLibrary.simpleMessage(
          "Rozpoznawanie twarzy",
        ),
        "faceThumbnailGenerationFailed": MessageLookupByLibrary.simpleMessage(
          "Nie można wygenerować miniaturek twarzy",
        ),
        "faces": MessageLookupByLibrary.simpleMessage("Twarze"),
        "failed": MessageLookupByLibrary.simpleMessage("Nie powiodło się"),
        "failedToApplyCode": MessageLookupByLibrary.simpleMessage(
          "Nie udało się zastosować kodu",
        ),
        "failedToCancel": MessageLookupByLibrary.simpleMessage(
          "Nie udało się anulować",
        ),
        "failedToDownloadVideo": MessageLookupByLibrary.simpleMessage(
          "Nie udało się pobrać wideo",
        ),
        "failedToFetchActiveSessions": MessageLookupByLibrary.simpleMessage(
          "Nie udało się pobrać aktywnych sesji",
        ),
        "failedToFetchOriginalForEdit": MessageLookupByLibrary.simpleMessage(
          "Nie udało się pobrać oryginału do edycji",
        ),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
          "Nie można pobrać szczegółów polecenia. Spróbuj ponownie później.",
        ),
        "failedToLoadAlbums": MessageLookupByLibrary.simpleMessage(
          "Nie udało się załadować albumów",
        ),
        "failedToPlayVideo": MessageLookupByLibrary.simpleMessage(
          "Nie udało się odtworzyć wideo",
        ),
        "failedToRefreshStripeSubscription":
            MessageLookupByLibrary.simpleMessage(
          "Nie udało się odświeżyć subskrypcji",
        ),
        "failedToRenew": MessageLookupByLibrary.simpleMessage(
          "Nie udało się odnowić",
        ),
        "failedToVerifyPaymentStatus": MessageLookupByLibrary.simpleMessage(
          "Nie udało się zweryfikować stanu płatności",
        ),
        "familyPlanOverview": MessageLookupByLibrary.simpleMessage(
          "Dodaj 5 członków rodziny do istniejącego planu bez dodatkowego płacenia.\n\nKażdy członek otrzymuje własną przestrzeń prywatną i nie widzi wzajemnie swoich plików, chyba że są one udostępnione.\n\nPlany rodzinne są dostępne dla klientów, którzy mają płatną subskrypcję Ente.\n\nSubskrybuj teraz, aby rozpocząć!",
        ),
        "familyPlanPortalTitle":
            MessageLookupByLibrary.simpleMessage("Rodzina"),
        "familyPlans": MessageLookupByLibrary.simpleMessage("Plany rodzinne"),
        "faq": MessageLookupByLibrary.simpleMessage(
          "FAQ – Często zadawane pytania",
        ),
        "faqs": MessageLookupByLibrary.simpleMessage(
          "FAQ – Często zadawane pytania",
        ),
        "favorite": MessageLookupByLibrary.simpleMessage("Dodaj do ulubionych"),
        "feastingWithThem": m34,
        "feedback": MessageLookupByLibrary.simpleMessage("Opinia"),
        "file": MessageLookupByLibrary.simpleMessage("Plik"),
        "fileAnalysisFailed": MessageLookupByLibrary.simpleMessage(
          "Nie można przeanalizować pliku",
        ),
        "fileFailedToSaveToGallery": MessageLookupByLibrary.simpleMessage(
          "Nie udało się zapisać pliku do galerii",
        ),
        "fileInfoAddDescHint": MessageLookupByLibrary.simpleMessage(
          "Dodaj opis...",
        ),
        "fileNotUploadedYet": MessageLookupByLibrary.simpleMessage(
          "Plik nie został jeszcze przesłany",
        ),
        "fileSavedToGallery": MessageLookupByLibrary.simpleMessage(
          "Plik zapisany do galerii",
        ),
        "fileTypes": MessageLookupByLibrary.simpleMessage("Rodzaje plików"),
        "fileTypesAndNames": MessageLookupByLibrary.simpleMessage(
          "Typy plików i nazwy",
        ),
        "filesBackedUpFromDevice": m35,
        "filesBackedUpInAlbum": m36,
        "filesDeleted": MessageLookupByLibrary.simpleMessage("Pliki usunięto"),
        "filesSavedToGallery": MessageLookupByLibrary.simpleMessage(
          "Pliki zapisane do galerii",
        ),
        "findPeopleByName": MessageLookupByLibrary.simpleMessage(
          "Szybko szukaj osób po imieniu",
        ),
        "findThemQuickly": MessageLookupByLibrary.simpleMessage(
          "Znajdź ich szybko",
        ),
        "flip": MessageLookupByLibrary.simpleMessage("Obróć"),
        "food": MessageLookupByLibrary.simpleMessage("Kulinarna rozkosz"),
        "forYourMemories": MessageLookupByLibrary.simpleMessage(
          "dla twoich wspomnień",
        ),
        "forgotPassword": MessageLookupByLibrary.simpleMessage(
          "Nie pamiętam hasła",
        ),
        "foundFaces": MessageLookupByLibrary.simpleMessage("Znaleziono twarze"),
        "freeStorageClaimed": MessageLookupByLibrary.simpleMessage(
          "Bezpłatna pamięć, którą odebrano",
        ),
        "freeStorageOnReferralSuccess": m37,
        "freeStorageUsable": MessageLookupByLibrary.simpleMessage(
          "Darmowa pamięć użyteczna",
        ),
        "freeTrial":
            MessageLookupByLibrary.simpleMessage("Darmowy okres próbny"),
        "freeTrialValidTill": m38,
        "freeUpAmount": m40,
        "freeUpDeviceSpace": MessageLookupByLibrary.simpleMessage(
          "Zwolnij miejsce na urządzeniu",
        ),
        "freeUpDeviceSpaceDesc": MessageLookupByLibrary.simpleMessage(
          "Oszczędzaj miejsce na urządzeniu poprzez wyczyszczenie plików, które zostały już przesłane.",
        ),
        "freeUpSpace": MessageLookupByLibrary.simpleMessage("Zwolnij miejsce"),
        "gallery": MessageLookupByLibrary.simpleMessage("Galeria"),
        "galleryMemoryLimitInfo": MessageLookupByLibrary.simpleMessage(
          "W galerii wyświetlane jest do 1000 pamięci",
        ),
        "general": MessageLookupByLibrary.simpleMessage("Ogólne"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
          "Generowanie kluczy szyfrujących...",
        ),
        "genericProgress": m42,
        "goToSettings":
            MessageLookupByLibrary.simpleMessage("Przejdź do ustawień"),
        "googlePlayId": MessageLookupByLibrary.simpleMessage(
          "Identyfikator Google Play",
        ),
        "grantFullAccessPrompt": MessageLookupByLibrary.simpleMessage(
          "Zezwól na dostęp do wszystkich zdjęć w aplikacji Ustawienia",
        ),
        "grantPermission": MessageLookupByLibrary.simpleMessage(
          "Przyznaj uprawnienie",
        ),
        "greenery": MessageLookupByLibrary.simpleMessage("Zielone życie"),
        "groupNearbyPhotos": MessageLookupByLibrary.simpleMessage(
          "Grupuj pobliskie zdjęcia",
        ),
        "guestView": MessageLookupByLibrary.simpleMessage("Widok gościa"),
        "guestViewEnablePreSteps": MessageLookupByLibrary.simpleMessage(
          "Aby włączyć widok gościa, należy skonfigurować hasło urządzenia lub blokadę ekranu w ustawieniach Twojego systemu.",
        ),
        "happyBirthday": MessageLookupByLibrary.simpleMessage(
          "Wszystkiego najlepszego! 🥳",
        ),
        "hearUsExplanation": MessageLookupByLibrary.simpleMessage(
          "Nie śledzimy instalacji aplikacji. Pomogłyby nam, gdybyś powiedział/a nam, gdzie nas znalazłeś/aś!",
        ),
        "hearUsWhereTitle": MessageLookupByLibrary.simpleMessage(
          "Jak usłyszałeś/aś o Ente? (opcjonalnie)",
        ),
        "help": MessageLookupByLibrary.simpleMessage("Pomoc"),
        "hidden": MessageLookupByLibrary.simpleMessage("Ukryte"),
        "hide": MessageLookupByLibrary.simpleMessage("Ukryj"),
        "hideContent": MessageLookupByLibrary.simpleMessage("Ukryj zawartość"),
        "hideContentDescriptionAndroid": MessageLookupByLibrary.simpleMessage(
          "Ukrywa zawartość aplikacji w przełączniku aplikacji i wyłącza zrzuty ekranu",
        ),
        "hideContentDescriptionIos": MessageLookupByLibrary.simpleMessage(
          "Ukrywa zawartość aplikacji w przełączniku aplikacji",
        ),
        "hideSharedItemsFromHomeGallery": MessageLookupByLibrary.simpleMessage(
          "Ukryj współdzielone elementy w galerii głównej",
        ),
        "hiding": MessageLookupByLibrary.simpleMessage("Ukrywanie..."),
        "hikingWithThem": m43,
        "hostedAtOsmFrance": MessageLookupByLibrary.simpleMessage(
          "Hostowane w OSM Francja",
        ),
        "howItWorks": MessageLookupByLibrary.simpleMessage("Jak to działa"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
          "Poproś ich o przytrzymanie swojego adresu e-mail na ekranie ustawień i sprawdzenie, czy identyfikatory na obu urządzeniach są zgodne.",
        ),
        "iOSGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
          "Uwierzytelnianie biometryczne nie jest skonfigurowane na Twoim urządzeniu. Prosimy włączyć Touch ID lub Face ID na swoim telefonie.",
        ),
        "iOSLockOut": MessageLookupByLibrary.simpleMessage(
          "Uwierzytelnianie biometryczne jest wyłączone. Prosimy zablokować i odblokować ekran, aby je włączyć.",
        ),
        "iOSOkButton": MessageLookupByLibrary.simpleMessage("OK"),
        "ignore": MessageLookupByLibrary.simpleMessage("Ignoruj"),
        "ignoreUpdate": MessageLookupByLibrary.simpleMessage("Ignoruj"),
        "ignored": MessageLookupByLibrary.simpleMessage("ignorowane"),
        "ignoredFolderUploadReason": MessageLookupByLibrary.simpleMessage(
          "Niektóre pliki w tym albumie są ignorowane podczas przesyłania, ponieważ zostały wcześniej usunięte z Ente.",
        ),
        "imageNotAnalyzed": MessageLookupByLibrary.simpleMessage(
          "Obraz nie został przeanalizowany",
        ),
        "immediately": MessageLookupByLibrary.simpleMessage("Natychmiast"),
        "importing": MessageLookupByLibrary.simpleMessage("Importowanie...."),
        "incorrectCode":
            MessageLookupByLibrary.simpleMessage("Nieprawidłowy kod"),
        "incorrectPasswordTitle": MessageLookupByLibrary.simpleMessage(
          "Nieprawidłowe hasło",
        ),
        "incorrectRecoveryKey": MessageLookupByLibrary.simpleMessage(
          "Nieprawidłowy klucz odzyskiwania",
        ),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
          "Kod jest nieprawidłowy",
        ),
        "incorrectRecoveryKeyTitle": MessageLookupByLibrary.simpleMessage(
          "Nieprawidłowy klucz odzyskiwania",
        ),
        "indexedItems": MessageLookupByLibrary.simpleMessage(
          "Zindeksowane elementy",
        ),
        "indexingPausedStatusDescription": MessageLookupByLibrary.simpleMessage(
          "Indeksowanie zostało wstrzymane. Zostanie automatycznie wznowione, gdy urządzenie będzie gotowe. Urządzenie uznaje się za gotowe, gdy poziom baterii, stan jej zdrowia oraz status termiczny znajdują się w bezpiecznym zakresie.",
        ),
        "ineligible":
            MessageLookupByLibrary.simpleMessage("Nie kwalifikuje się"),
        "info": MessageLookupByLibrary.simpleMessage("Informacje"),
        "insecureDevice": MessageLookupByLibrary.simpleMessage(
          "Niezabezpieczone urządzenie",
        ),
        "installManually": MessageLookupByLibrary.simpleMessage(
          "Zainstaluj manualnie",
        ),
        "invalidEmailAddress": MessageLookupByLibrary.simpleMessage(
          "Nieprawidłowy adres e-mail",
        ),
        "invalidEndpoint": MessageLookupByLibrary.simpleMessage(
          "Punkt końcowy jest nieprawidłowy",
        ),
        "invalidEndpointMessage": MessageLookupByLibrary.simpleMessage(
          "Niestety, wprowadzony punkt końcowy jest nieprawidłowy. Wprowadź prawidłowy punkt końcowy i spróbuj ponownie.",
        ),
        "invalidKey": MessageLookupByLibrary.simpleMessage(
          "Klucz jest nieprawidłowy",
        ),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
          "Wprowadzony klucz odzyskiwania jest nieprawidłowy. Upewnij się, że zawiera on 24 słowa i sprawdź pisownię każdego z nich.\n\nJeśli wprowadziłeś starszy kod odzyskiwania, upewnij się, że ma on 64 znaki i sprawdź każdy z nich.",
        ),
        "invite": MessageLookupByLibrary.simpleMessage("Zaproś"),
        "inviteToEnte": MessageLookupByLibrary.simpleMessage("Zaproś do Ente"),
        "inviteYourFriends": MessageLookupByLibrary.simpleMessage(
          "Zaproś znajomych",
        ),
        "inviteYourFriendsToEnte": MessageLookupByLibrary.simpleMessage(
          "Zaproś znajomych do Ente",
        ),
        "itLooksLikeSomethingWentWrongPleaseRetryAfterSome":
            MessageLookupByLibrary.simpleMessage(
          "Wygląda na to, że coś poszło nie tak. Spróbuj ponownie po pewnym czasie. Jeśli błąd będzie się powtarzał, skontaktuj się z naszym zespołem pomocy technicznej.",
        ),
        "itemCount": m44,
        "itemsShowTheNumberOfDaysRemainingBeforePermanentDeletion":
            MessageLookupByLibrary.simpleMessage(
          "Elementy pokazują liczbę dni pozostałych przed trwałym usunięciem",
        ),
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
          "Wybrane elementy zostaną usunięte z tego albumu",
        ),
        "join": MessageLookupByLibrary.simpleMessage("Dołącz"),
        "joinAlbum": MessageLookupByLibrary.simpleMessage("Dołącz do albumu"),
        "joinAlbumConfirmationDialogBody": MessageLookupByLibrary.simpleMessage(
          "Dołączenie do albumu sprawi, że Twój e-mail będzie widoczny dla jego uczestników.",
        ),
        "joinAlbumSubtext": MessageLookupByLibrary.simpleMessage(
          "aby wyświetlić i dodać swoje zdjęcia",
        ),
        "joinAlbumSubtextViewer": MessageLookupByLibrary.simpleMessage(
          "aby dodać to do udostępnionych albumów",
        ),
        "joinDiscord": MessageLookupByLibrary.simpleMessage(
          "Dołącz do serwera Discord",
        ),
        "keepPhotos": MessageLookupByLibrary.simpleMessage("Zachowaj Zdjęcia"),
        "kiloMeterUnit": MessageLookupByLibrary.simpleMessage("km"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
          "Pomóż nam z tą informacją",
        ),
        "language": MessageLookupByLibrary.simpleMessage("Język"),
        "lastTimeWithThem": m45,
        "lastUpdated": MessageLookupByLibrary.simpleMessage(
          "Ostatnio zaktualizowano",
        ),
        "lastYearsTrip": MessageLookupByLibrary.simpleMessage(
          "Zeszłoroczna podróż",
        ),
        "leave": MessageLookupByLibrary.simpleMessage("Wyjdź"),
        "leaveAlbum": MessageLookupByLibrary.simpleMessage("Opuść album"),
        "leaveFamily": MessageLookupByLibrary.simpleMessage("Opuść rodzinę"),
        "leaveSharedAlbum": MessageLookupByLibrary.simpleMessage(
          "Opuścić udostępniony album?",
        ),
        "left": MessageLookupByLibrary.simpleMessage("W lewo"),
        "legacy": MessageLookupByLibrary.simpleMessage("Dziedzictwo"),
        "legacyAccounts": MessageLookupByLibrary.simpleMessage(
          "Odziedziczone konta",
        ),
        "legacyInvite": m46,
        "legacyPageDesc": MessageLookupByLibrary.simpleMessage(
          "Dziedzictwo pozwala zaufanym kontaktom na dostęp do Twojego konta w razie Twojej nieobecności.",
        ),
        "legacyPageDesc2": MessageLookupByLibrary.simpleMessage(
          "Zaufane kontakty mogą rozpocząć odzyskiwanie konta, a jeśli nie zostaną zablokowane w ciągu 30 dni, zresetować Twoje hasło i uzyskać dostęp do Twojego konta.",
        ),
        "light": MessageLookupByLibrary.simpleMessage("Jasny"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("Jasny"),
        "linkCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
          "Link skopiowany do schowka",
        ),
        "linkDeviceLimit":
            MessageLookupByLibrary.simpleMessage("Limit urządzeń"),
        "linkEmail":
            MessageLookupByLibrary.simpleMessage("Połącz adres e-mail"),
        "linkEmailToContactBannerCaption": MessageLookupByLibrary.simpleMessage(
          "aby szybciej udostępniać",
        ),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Aktywny"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Wygasł"),
        "linkExpiresOn": m47,
        "linkExpiry": MessageLookupByLibrary.simpleMessage("Wygaśnięcie linku"),
        "linkHasExpired": MessageLookupByLibrary.simpleMessage("Link wygasł"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Nigdy"),
        "linkPersonToEmail": m48,
        "linkPersonToEmailConfirmation": m49,
        "livePhotos":
            MessageLookupByLibrary.simpleMessage("Zdjęcia Live Photo"),
        "loadMessage1": MessageLookupByLibrary.simpleMessage(
          "Możesz udostępnić swoją subskrypcję swojej rodzinie",
        ),
        "loadMessage2": MessageLookupByLibrary.simpleMessage(
          "Do tej pory zachowaliśmy ponad 200 milionów wspomnień",
        ),
        "loadMessage3": MessageLookupByLibrary.simpleMessage(
          "Przechowujemy 3 kopie Twoich danych, jedną w podziemnym schronie",
        ),
        "loadMessage4": MessageLookupByLibrary.simpleMessage(
          "Wszystkie nasze aplikacje są otwarto źródłowe",
        ),
        "loadMessage5": MessageLookupByLibrary.simpleMessage(
          "Nasz kod źródłowy i kryptografia zostały poddane zewnętrznemu audytowi",
        ),
        "loadMessage6": MessageLookupByLibrary.simpleMessage(
          "Możesz udostępniać linki do swoich albumów swoim bliskim",
        ),
        "loadMessage7": MessageLookupByLibrary.simpleMessage(
          "Nasze aplikacje mobilne działają w tle, aby zaszyfrować i wykonać kopię zapasową wszystkich nowych zdjęć, które klikniesz",
        ),
        "loadMessage8": MessageLookupByLibrary.simpleMessage(
          "web.ente.io ma zgrabny program do przesyłania",
        ),
        "loadMessage9": MessageLookupByLibrary.simpleMessage(
          "Używamy Xchacha20Poly1305 do bezpiecznego szyfrowania Twoich danych",
        ),
        "loadingExifData": MessageLookupByLibrary.simpleMessage(
          "Wczytywanie danych EXIF...",
        ),
        "loadingGallery": MessageLookupByLibrary.simpleMessage(
          "Ładowanie galerii...",
        ),
        "loadingMessage": MessageLookupByLibrary.simpleMessage(
          "Wczytywanie Twoich zdjęć...",
        ),
        "loadingModel": MessageLookupByLibrary.simpleMessage(
          "Pobieranie modeli...",
        ),
        "loadingYourPhotos": MessageLookupByLibrary.simpleMessage(
          "Wczytywanie Twoich zdjęć...",
        ),
        "localGallery": MessageLookupByLibrary.simpleMessage("Galeria lokalna"),
        "localIndexing": MessageLookupByLibrary.simpleMessage(
          "Indeksowanie lokalne",
        ),
        "localSyncErrorMessage": MessageLookupByLibrary.simpleMessage(
          "Wygląda na to, że coś poszło nie tak, ponieważ lokalna synchronizacja zdjęć zajmuje więcej czasu, niż oczekiwano. Skontaktuj się z naszym zespołem pomocy technicznej",
        ),
        "location": MessageLookupByLibrary.simpleMessage("Lokalizacja"),
        "locationName":
            MessageLookupByLibrary.simpleMessage("Nazwa lokalizacji"),
        "locationTagFeatureDescription": MessageLookupByLibrary.simpleMessage(
          "Znacznik lokalizacji grupuje wszystkie zdjęcia, które zostały zrobione w promieniu zdjęcia",
        ),
        "locations": MessageLookupByLibrary.simpleMessage("Lokalizacje"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Zablokuj"),
        "lockscreen": MessageLookupByLibrary.simpleMessage("Ekran blokady"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Zaloguj się"),
        "loggingOut": MessageLookupByLibrary.simpleMessage("Wylogowywanie..."),
        "loginSessionExpired": MessageLookupByLibrary.simpleMessage(
          "Sesja wygasła",
        ),
        "loginSessionExpiredDetails": MessageLookupByLibrary.simpleMessage(
          "Twoja sesja wygasła. Zaloguj się ponownie.",
        ),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
          "Klikając, zaloguj się, zgadzam się na <u-terms>regulamin</u-terms> i <u-policy>politykę prywatności</u-policy>",
        ),
        "loginWithTOTP": MessageLookupByLibrary.simpleMessage(
          "Zaloguj się za pomocą TOTP",
        ),
        "logout": MessageLookupByLibrary.simpleMessage("Wyloguj"),
        "logsDialogBody": MessageLookupByLibrary.simpleMessage(
          "Spowoduje to wysyłanie logów, aby pomóc nam w debugowaniu twojego problemu. Pamiętaj, że nazwy plików zostaną dołączone, aby pomóc w śledzeniu problemów z określonymi plikami.",
        ),
        "longPressAnEmailToVerifyEndToEndEncryption":
            MessageLookupByLibrary.simpleMessage(
          "Naciśnij i przytrzymaj e-mail, aby zweryfikować szyfrowanie end-to-end.",
        ),
        "longpressOnAnItemToViewInFullscreen":
            MessageLookupByLibrary.simpleMessage(
          "Długo naciśnij element, aby wyświetlić go na pełnym ekranie",
        ),
        "lookBackOnYourMemories": MessageLookupByLibrary.simpleMessage(
          "Spójrz ponownie na swoje wspomnienia 🌄",
        ),
        "loopVideoOff": MessageLookupByLibrary.simpleMessage(
          "Pętla wideo wyłączona",
        ),
        "loopVideoOn":
            MessageLookupByLibrary.simpleMessage("Pętla wideo włączona"),
        "lostDevice":
            MessageLookupByLibrary.simpleMessage("Utracono urządzenie?"),
        "machineLearning": MessageLookupByLibrary.simpleMessage(
          "Nauczanie maszynowe",
        ),
        "magicSearch": MessageLookupByLibrary.simpleMessage(
          "Magiczne wyszukiwanie",
        ),
        "magicSearchHint": MessageLookupByLibrary.simpleMessage(
          "Magiczne wyszukiwanie pozwala na wyszukiwanie zdjęć według ich zawartości, np. \"kwiat\", \"czerwony samochód\", \"dokumenty tożsamości\"",
        ),
        "manage": MessageLookupByLibrary.simpleMessage("Zarządzaj"),
        "manageDeviceStorage": MessageLookupByLibrary.simpleMessage(
          "Zarządzaj pamięcią podręczną urządzenia",
        ),
        "manageDeviceStorageDesc": MessageLookupByLibrary.simpleMessage(
          "Przejrzyj i wyczyść lokalną pamięć podręczną.",
        ),
        "manageFamily":
            MessageLookupByLibrary.simpleMessage("Zarządzaj Rodziną"),
        "manageLink": MessageLookupByLibrary.simpleMessage("Zarządzaj linkiem"),
        "manageParticipants": MessageLookupByLibrary.simpleMessage("Zarządzaj"),
        "manageSubscription": MessageLookupByLibrary.simpleMessage(
          "Zarządzaj subskrypcją",
        ),
        "manualPairDesc": MessageLookupByLibrary.simpleMessage(
          "Parowanie PIN-em działa z każdym ekranem, na którym chcesz wyświetlić swój album.",
        ),
        "map": MessageLookupByLibrary.simpleMessage("Mapa"),
        "maps": MessageLookupByLibrary.simpleMessage("Mapy"),
        "mastodon": MessageLookupByLibrary.simpleMessage("Mastodon"),
        "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
        "me": MessageLookupByLibrary.simpleMessage("Ja"),
        "memories": MessageLookupByLibrary.simpleMessage("Wspomnienia"),
        "memoriesWidgetDesc": MessageLookupByLibrary.simpleMessage(
          "Wybierz rodzaj wspomnień, które chcesz zobaczyć na ekranie głównym.",
        ),
        "merchandise": MessageLookupByLibrary.simpleMessage("Sklep"),
        "merge": MessageLookupByLibrary.simpleMessage("Scal"),
        "mergeWithExisting": MessageLookupByLibrary.simpleMessage(
          "Scal z istniejącym",
        ),
        "mergedPhotos": MessageLookupByLibrary.simpleMessage("Scalone zdjęcia"),
        "mlConsent": MessageLookupByLibrary.simpleMessage(
          "Włącz nauczanie maszynowe",
        ),
        "mlConsentConfirmation": MessageLookupByLibrary.simpleMessage(
          "Rozumiem i chcę włączyć nauczanie maszynowe",
        ),
        "mlConsentDescription": MessageLookupByLibrary.simpleMessage(
          "Jeśli włączysz nauczanie maszynowe, Ente wyodrębni informacje takie jak geometria twarzy z plików, w tym tych udostępnionych z Tobą.\n\nTo się stanie na Twoim urządzeniu i wygenerowane informacje biometryczne zostaną zaszyfrowane end-to-end.",
        ),
        "mlConsentPrivacy": MessageLookupByLibrary.simpleMessage(
          "Kliknij tutaj, aby uzyskać więcej informacji na temat tej funkcji w naszej polityce prywatności",
        ),
        "mlConsentTitle": MessageLookupByLibrary.simpleMessage(
          "Włączyć nauczanie maszynowe?",
        ),
        "mlIndexingDescription": MessageLookupByLibrary.simpleMessage(
          "Pamiętaj, że nauczanie maszynowe spowoduje większą przepustowość i zużycie baterii do czasu zindeksowania wszystkich elementów. Rozważ użycie aplikacji komputerowej do szybszego indeksowania, wszystkie wyniki zostaną automatycznie zsynchronizowane.",
        ),
        "mobileWebDesktop": MessageLookupByLibrary.simpleMessage(
          "Aplikacja Mobilna, Strona Internetowa, Aplikacja Komputerowa",
        ),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Umiarkowane"),
        "modifyYourQueryOrTrySearchingFor":
            MessageLookupByLibrary.simpleMessage(
          "Zmodyfikuj zapytanie lub spróbuj wyszukać",
        ),
        "moments": MessageLookupByLibrary.simpleMessage("Momenty"),
        "month": MessageLookupByLibrary.simpleMessage("miesiąc"),
        "monthly": MessageLookupByLibrary.simpleMessage("Miesięcznie"),
        "moon": MessageLookupByLibrary.simpleMessage("W świetle księżyca"),
        "moreDetails":
            MessageLookupByLibrary.simpleMessage("Więcej szczegółów"),
        "mostRecent": MessageLookupByLibrary.simpleMessage("Od najnowszych"),
        "mostRelevant":
            MessageLookupByLibrary.simpleMessage("Najbardziej trafne"),
        "mountains": MessageLookupByLibrary.simpleMessage("Na wzgórzach"),
        "moveSelectedPhotosToOneDate": MessageLookupByLibrary.simpleMessage(
          "Przenieś wybrane zdjęcia na jedną datę",
        ),
        "moveToAlbum":
            MessageLookupByLibrary.simpleMessage("Przenieś do albumu"),
        "moveToHiddenAlbum": MessageLookupByLibrary.simpleMessage(
          "Przenieś do ukrytego albumu",
        ),
        "movedSuccessfullyTo": m52,
        "movedToTrash": MessageLookupByLibrary.simpleMessage(
          "Przeniesiono do kosza",
        ),
        "movingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
          "Przenoszenie plików do albumów...",
        ),
        "name": MessageLookupByLibrary.simpleMessage("Nazwa"),
        "nameTheAlbum": MessageLookupByLibrary.simpleMessage("Nazwij album"),
        "networkConnectionRefusedErr": MessageLookupByLibrary.simpleMessage(
          "Nie można połączyć się z Ente, spróbuj ponownie po pewnym czasie. Jeśli błąd będzie się powtarzał, skontaktuj się z pomocą techniczną.",
        ),
        "networkHostLookUpErr": MessageLookupByLibrary.simpleMessage(
          "Nie można połączyć się z Ente, sprawdź ustawienia sieci i skontaktuj się z pomocą techniczną, jeśli błąd będzie się powtarzał.",
        ),
        "never": MessageLookupByLibrary.simpleMessage("Nigdy"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Nowy album"),
        "newLocation": MessageLookupByLibrary.simpleMessage("Nowa lokalizacja"),
        "newPerson": MessageLookupByLibrary.simpleMessage("Nowa osoba"),
        "newPhotosEmoji": MessageLookupByLibrary.simpleMessage(" nowe 📸"),
        "newRange": MessageLookupByLibrary.simpleMessage("Nowy zakres"),
        "newToEnte": MessageLookupByLibrary.simpleMessage("Nowy/a do Ente"),
        "newest": MessageLookupByLibrary.simpleMessage("Najnowsze"),
        "next": MessageLookupByLibrary.simpleMessage("Dalej"),
        "no": MessageLookupByLibrary.simpleMessage("Nie"),
        "noAlbumsSharedByYouYet": MessageLookupByLibrary.simpleMessage(
          "Brak jeszcze albumów udostępnianych przez Ciebie",
        ),
        "noDeviceFound": MessageLookupByLibrary.simpleMessage(
          "Nie znaleziono żadnego urządzenia",
        ),
        "noDeviceLimit": MessageLookupByLibrary.simpleMessage("Brak"),
        "noDeviceThatCanBeDeleted": MessageLookupByLibrary.simpleMessage(
          "Nie masz żadnych plików na tym urządzeniu, które można usunąć",
        ),
        "noDuplicates":
            MessageLookupByLibrary.simpleMessage("✨ Brak duplikatów"),
        "noEnteAccountExclamation": MessageLookupByLibrary.simpleMessage(
          "Brak konta Ente!",
        ),
        "noExifData": MessageLookupByLibrary.simpleMessage("Brak danych EXIF"),
        "noFacesFound": MessageLookupByLibrary.simpleMessage(
          "Nie znaleziono twarzy",
        ),
        "noHiddenPhotosOrVideos": MessageLookupByLibrary.simpleMessage(
          "Brak ukrytych zdjęć lub wideo",
        ),
        "noImagesWithLocation": MessageLookupByLibrary.simpleMessage(
          "Brak zdjęć z lokalizacją",
        ),
        "noInternetConnection": MessageLookupByLibrary.simpleMessage(
          "Brak połączenia z Internetem",
        ),
        "noPhotosAreBeingBackedUpRightNow":
            MessageLookupByLibrary.simpleMessage(
          "W tej chwili nie wykonuje się kopii zapasowej zdjęć",
        ),
        "noPhotosFoundHere": MessageLookupByLibrary.simpleMessage(
          "Nie znaleziono tutaj zdjęć",
        ),
        "noQuickLinksSelected": MessageLookupByLibrary.simpleMessage(
          "Nie wybrano żadnych szybkich linków",
        ),
        "noRecoveryKey": MessageLookupByLibrary.simpleMessage(
          "Brak klucza odzyskiwania?",
        ),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
          "Ze względu na charakter naszego protokołu szyfrowania end-to-end, dane nie mogą być odszyfrowane bez hasła lub klucza odzyskiwania",
        ),
        "noResults": MessageLookupByLibrary.simpleMessage("Brak wyników"),
        "noResultsFound": MessageLookupByLibrary.simpleMessage(
          "Nie znaleziono wyników",
        ),
        "noSuggestionsForPerson": m53,
        "noSystemLockFound": MessageLookupByLibrary.simpleMessage(
          "Nie znaleziono blokady systemowej",
        ),
        "notPersonLabel": m54,
        "notThisPerson": MessageLookupByLibrary.simpleMessage("Nie ta osoba?"),
        "nothingSharedWithYouYet": MessageLookupByLibrary.simpleMessage(
          "Nic Ci jeszcze nie udostępniono",
        ),
        "nothingToSeeHere": MessageLookupByLibrary.simpleMessage(
          "Nie ma tutaj nic do zobaczenia! 👀",
        ),
        "notifications": MessageLookupByLibrary.simpleMessage("Powiadomienia"),
        "ok": MessageLookupByLibrary.simpleMessage("Ok"),
        "onDevice": MessageLookupByLibrary.simpleMessage("Na urządzeniu"),
        "onEnte": MessageLookupByLibrary.simpleMessage(
          "W <branding>ente</branding>",
        ),
        "onTheRoad": MessageLookupByLibrary.simpleMessage("Znowu na drodze"),
        "onThisDay": MessageLookupByLibrary.simpleMessage("Tego dnia"),
        "onThisDayMemories": MessageLookupByLibrary.simpleMessage(
          "Wspomnienia z tego dnia",
        ),
        "onThisDayNotificationExplanation":
            MessageLookupByLibrary.simpleMessage(
          "Otrzymuj przypomnienia o wspomnieniach z tego dnia w poprzednich latach.",
        ),
        "onlyFamilyAdminCanChangeCode": m55,
        "onlyThem": MessageLookupByLibrary.simpleMessage("Tylko te"),
        "oops": MessageLookupByLibrary.simpleMessage("Ups"),
        "oopsCouldNotSaveEdits": MessageLookupByLibrary.simpleMessage(
          "Ups, nie udało się zapisać zmian",
        ),
        "oopsSomethingWentWrong": MessageLookupByLibrary.simpleMessage(
          "Ups, coś poszło nie tak",
        ),
        "openAlbumInBrowser": MessageLookupByLibrary.simpleMessage(
          "Otwórz album w przeglądarce",
        ),
        "openAlbumInBrowserTitle": MessageLookupByLibrary.simpleMessage(
          "Prosimy użyć aplikacji internetowej, aby dodać zdjęcia do tego albumu",
        ),
        "openFile": MessageLookupByLibrary.simpleMessage("Otwórz plik"),
        "openSettings":
            MessageLookupByLibrary.simpleMessage("Otwórz Ustawienia"),
        "openTheItem": MessageLookupByLibrary.simpleMessage("• Otwórz element"),
        "openstreetmapContributors": MessageLookupByLibrary.simpleMessage(
          "Współautorzy OpenStreetMap",
        ),
        "optionalAsShortAsYouLike": MessageLookupByLibrary.simpleMessage(
          "Opcjonalnie, tak krótko, jak chcesz...",
        ),
        "orMergeWithExistingPerson": MessageLookupByLibrary.simpleMessage(
          "Lub złącz z istniejącymi",
        ),
        "orPickAnExistingOne": MessageLookupByLibrary.simpleMessage(
          "Lub wybierz istniejący",
        ),
        "orPickFromYourContacts": MessageLookupByLibrary.simpleMessage(
          "lub wybierz ze swoich kontaktów",
        ),
        "otherDetectedFaces": MessageLookupByLibrary.simpleMessage(
          "Inne wykryte twarze",
        ),
        "pair": MessageLookupByLibrary.simpleMessage("Sparuj"),
        "pairWithPin": MessageLookupByLibrary.simpleMessage("Sparuj kodem PIN"),
        "pairingComplete": MessageLookupByLibrary.simpleMessage(
          "Parowanie zakończone",
        ),
        "panorama": MessageLookupByLibrary.simpleMessage("Panorama"),
        "passKeyPendingVerification": MessageLookupByLibrary.simpleMessage(
          "Weryfikacja jest nadal w toku",
        ),
        "passkey": MessageLookupByLibrary.simpleMessage("Klucz dostępu"),
        "passkeyAuthTitle": MessageLookupByLibrary.simpleMessage(
          "Weryfikacja kluczem dostępu",
        ),
        "password": MessageLookupByLibrary.simpleMessage("Hasło"),
        "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
          "Hasło zostało pomyślnie zmienione",
        ),
        "passwordLock": MessageLookupByLibrary.simpleMessage("Blokada hasłem"),
        "passwordStrength": m57,
        "passwordStrengthInfo": MessageLookupByLibrary.simpleMessage(
          "Siła hasła jest obliczana, biorąc pod uwagę długość hasła, użyte znaki, i czy hasło pojawi się w 10 000 najczęściej używanych haseł",
        ),
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
          "Nie przechowujemy tego hasła, więc jeśli go zapomnisz, <underline>nie będziemy w stanie odszyfrować Twoich danych</underline>",
        ),
        "pastYearsMemories": MessageLookupByLibrary.simpleMessage(
          "Wspomnienia z ubiegłych lat",
        ),
        "paymentDetails": MessageLookupByLibrary.simpleMessage(
          "Szczegóły płatności",
        ),
        "paymentFailed": MessageLookupByLibrary.simpleMessage(
          "Płatność się nie powiodła",
        ),
        "paymentFailedMessage": MessageLookupByLibrary.simpleMessage(
          "Niestety Twoja płatność nie powiodła się. Skontaktuj się z pomocą techniczną, a my Ci pomożemy!",
        ),
        "paymentFailedTalkToProvider": m58,
        "pendingItems":
            MessageLookupByLibrary.simpleMessage("Oczekujące elementy"),
        "pendingSync": MessageLookupByLibrary.simpleMessage(
          "Oczekująca synchronizacja",
        ),
        "people": MessageLookupByLibrary.simpleMessage("Ludzie"),
        "peopleUsingYourCode": MessageLookupByLibrary.simpleMessage(
          "Osoby używające twojego kodu",
        ),
        "peopleWidgetDesc": MessageLookupByLibrary.simpleMessage(
          "Wybierz osoby, które chcesz zobaczyć na ekranie głównym.",
        ),
        "permDeleteWarning": MessageLookupByLibrary.simpleMessage(
          "Wszystkie elementy w koszu zostaną trwale usunięte\n\nTej czynności nie można cofnąć",
        ),
        "permanentlyDelete":
            MessageLookupByLibrary.simpleMessage("Usuń trwale"),
        "permanentlyDeleteFromDevice": MessageLookupByLibrary.simpleMessage(
          "Trwale usunąć z urządzenia?",
        ),
        "personIsAge": m59,
        "personName": MessageLookupByLibrary.simpleMessage("Nazwa osoby"),
        "personTurningAge": m60,
        "pets": MessageLookupByLibrary.simpleMessage("Futrzani towarzysze"),
        "photoDescriptions":
            MessageLookupByLibrary.simpleMessage("Opisy zdjęć"),
        "photoGridSize": MessageLookupByLibrary.simpleMessage(
          "Rozmiar siatki zdjęć",
        ),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("zdjęcie"),
        "photos": MessageLookupByLibrary.simpleMessage("Zdjęcia"),
        "photosAddedByYouWillBeRemovedFromTheAlbum":
            MessageLookupByLibrary.simpleMessage(
          "Zdjęcia dodane przez Ciebie zostaną usunięte z albumu",
        ),
        "photosKeepRelativeTimeDifference":
            MessageLookupByLibrary.simpleMessage(
          "Zdjęcia zachowują względną różnicę czasu",
        ),
        "pickCenterPoint": MessageLookupByLibrary.simpleMessage(
          "Wybierz punkt środkowy",
        ),
        "pinAlbum": MessageLookupByLibrary.simpleMessage("Przypnij album"),
        "pinLock": MessageLookupByLibrary.simpleMessage("Blokada PIN"),
        "playOnTv": MessageLookupByLibrary.simpleMessage(
          "Odtwórz album na telewizorze",
        ),
        "playOriginal":
            MessageLookupByLibrary.simpleMessage("Odtwórz oryginał"),
        "playStoreFreeTrialValidTill": m63,
        "playstoreSubscription": MessageLookupByLibrary.simpleMessage(
          "Subskrypcja PlayStore",
        ),
        "pleaseCheckYourInternetConnectionAndTryAgain":
            MessageLookupByLibrary.simpleMessage(
          "Prosimy sprawdzić połączenie internetowe i spróbować ponownie.",
        ),
        "pleaseContactSupportAndWeWillBeHappyToHelp":
            MessageLookupByLibrary.simpleMessage(
          "Skontaktuj się z support@ente.io i z przyjemnością pomożemy!",
        ),
        "pleaseContactSupportIfTheProblemPersists":
            MessageLookupByLibrary.simpleMessage(
          "Skontaktuj się z pomocą techniczną, jeśli problem będzie się powtarzał",
        ),
        "pleaseEmailUsAt": m64,
        "pleaseGrantPermissions": MessageLookupByLibrary.simpleMessage(
          "Prosimy przyznać uprawnienia",
        ),
        "pleaseLoginAgain": MessageLookupByLibrary.simpleMessage(
          "Zaloguj się ponownie",
        ),
        "pleaseSelectQuickLinksToRemove": MessageLookupByLibrary.simpleMessage(
          "Prosimy wybrać szybkie linki do usunięcia",
        ),
        "pleaseSendTheLogsTo": m65,
        "pleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("Spróbuj ponownie"),
        "pleaseVerifyTheCodeYouHaveEntered":
            MessageLookupByLibrary.simpleMessage(
          "Prosimy zweryfikować wprowadzony kod",
        ),
        "pleaseWait": MessageLookupByLibrary.simpleMessage("Prosimy czekać..."),
        "pleaseWaitDeletingAlbum": MessageLookupByLibrary.simpleMessage(
          "Prosimy czekać, usuwanie albumu",
        ),
        "pleaseWaitForSometimeBeforeRetrying":
            MessageLookupByLibrary.simpleMessage(
          "Prosimy poczekać chwilę przed ponowną próbą",
        ),
        "pleaseWaitThisWillTakeAWhile": MessageLookupByLibrary.simpleMessage(
          "Prosimy czekać, to może zająć chwilę.",
        ),
        "posingWithThem": m66,
        "preparingLogs": MessageLookupByLibrary.simpleMessage(
          "Przygotowywanie logów...",
        ),
        "preserveMore": MessageLookupByLibrary.simpleMessage("Zachowaj więcej"),
        "pressAndHoldToPlayVideo": MessageLookupByLibrary.simpleMessage(
          "Naciśnij i przytrzymaj, aby odtworzyć wideo",
        ),
        "pressAndHoldToPlayVideoDetailed": MessageLookupByLibrary.simpleMessage(
          "Naciśnij i przytrzymaj obraz, aby odtworzyć wideo",
        ),
        "previous": MessageLookupByLibrary.simpleMessage("Poprzedni"),
        "privacy": MessageLookupByLibrary.simpleMessage("Prywatność"),
        "privacyPolicyTitle": MessageLookupByLibrary.simpleMessage(
          "Polityka Prywatności",
        ),
        "privateBackups": MessageLookupByLibrary.simpleMessage(
          "Prywatne kopie zapasowe",
        ),
        "privateSharing": MessageLookupByLibrary.simpleMessage(
          "Udostępnianie prywatne",
        ),
        "proceed": MessageLookupByLibrary.simpleMessage("Kontynuuj"),
        "processed": MessageLookupByLibrary.simpleMessage("Przetworzone"),
        "processing": MessageLookupByLibrary.simpleMessage("Przetwarzanie"),
        "processingImport": m67,
        "processingVideos": MessageLookupByLibrary.simpleMessage(
          "Przetwarzanie wideo",
        ),
        "publicLinkCreated": MessageLookupByLibrary.simpleMessage(
          "Utworzono publiczny link",
        ),
        "publicLinkEnabled": MessageLookupByLibrary.simpleMessage(
          "Publiczny link włączony",
        ),
        "questionmark": MessageLookupByLibrary.simpleMessage("?"),
        "queued": MessageLookupByLibrary.simpleMessage("W kolejce"),
        "quickLinks": MessageLookupByLibrary.simpleMessage("Szybkie linki"),
        "radius": MessageLookupByLibrary.simpleMessage("Promień"),
        "raiseTicket": MessageLookupByLibrary.simpleMessage("Zgłoś"),
        "rateTheApp": MessageLookupByLibrary.simpleMessage("Oceń aplikację"),
        "rateUs": MessageLookupByLibrary.simpleMessage("Oceń nas"),
        "rateUsOnStore": m68,
        "reassignedToName": m69,
        "receiveRemindersOnBirthdays": MessageLookupByLibrary.simpleMessage(
          "Otrzymuj przypomnienia, kiedy są czyjeś urodziny. Naciskając na powiadomienie zabierze Cię do zdjęć osoby, która ma urodziny.",
        ),
        "recover": MessageLookupByLibrary.simpleMessage("Odzyskaj"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("Odzyskaj konto"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Odzyskaj"),
        "recoveryAccount":
            MessageLookupByLibrary.simpleMessage("Odzyskaj konto"),
        "recoveryInitiated": MessageLookupByLibrary.simpleMessage(
          "Odzyskiwanie rozpoczęte",
        ),
        "recoveryInitiatedDesc": m70,
        "recoveryKey":
            MessageLookupByLibrary.simpleMessage("Klucz odzyskiwania"),
        "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
          "Klucz odzyskiwania został skopiowany do schowka",
        ),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
          "Jeśli zapomnisz hasła, jedynym sposobem odzyskania danych jest ten klucz.",
        ),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
          "Nie przechowujemy tego klucza, prosimy zapisać ten 24-słowny klucz w bezpiecznym miejscu.",
        ),
        "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
          "Znakomicie! Klucz odzyskiwania jest prawidłowy. Dziękujemy za weryfikację.\n\nPamiętaj, aby bezpiecznie przechowywać kopię zapasową klucza odzyskiwania.",
        ),
        "recoveryKeyVerified": MessageLookupByLibrary.simpleMessage(
          "Klucz odzyskiwania zweryfikowany",
        ),
        "recoveryKeyVerifyReason": MessageLookupByLibrary.simpleMessage(
          "Twój klucz odzyskiwania jest jedynym sposobem na odzyskanie zdjęć, jeśli zapomnisz hasła. Klucz odzyskiwania można znaleźć w Ustawieniach > Konto.\n\nWprowadź tutaj swój klucz odzyskiwania, aby sprawdzić, czy został zapisany poprawnie.",
        ),
        "recoveryReady": m71,
        "recoverySuccessful": MessageLookupByLibrary.simpleMessage(
          "Odzyskano pomyślnie!",
        ),
        "recoveryWarning": MessageLookupByLibrary.simpleMessage(
          "Zaufany kontakt próbuje uzyskać dostęp do Twojego konta",
        ),
        "recoveryWarningBody": m72,
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
          "Obecne urządzenie nie jest wystarczająco wydajne, aby zweryfikować hasło, ale możemy je wygenerować w sposób działający na wszystkich urządzeniach.\n\nZaloguj się przy użyciu klucza odzyskiwania i wygeneruj nowe hasło (jeśli chcesz, możesz ponownie użyć tego samego).",
        ),
        "recreatePasswordTitle": MessageLookupByLibrary.simpleMessage(
          "Ponownie utwórz hasło",
        ),
        "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
        "reenterPassword": MessageLookupByLibrary.simpleMessage(
          "Wprowadź ponownie hasło",
        ),
        "reenterPin": MessageLookupByLibrary.simpleMessage(
          "Wprowadź ponownie kod PIN",
        ),
        "referFriendsAnd2xYourPlan": MessageLookupByLibrary.simpleMessage(
          "Poleć znajomym i podwój swój plan",
        ),
        "referralStep1": MessageLookupByLibrary.simpleMessage(
          "1. Przekaż ten kod swoim znajomym",
        ),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
          "2. Wykupują płatny plan",
        ),
        "referralStep3": m73,
        "referrals": MessageLookupByLibrary.simpleMessage("Polecenia"),
        "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
          "Wysyłanie poleceń jest obecnie wstrzymane",
        ),
        "rejectRecovery": MessageLookupByLibrary.simpleMessage(
          "Odrzuć odzyskiwanie",
        ),
        "remindToEmptyDeviceTrash": MessageLookupByLibrary.simpleMessage(
          "Również opróżnij \"Ostatnio usunięte\" z \"Ustawienia\" -> \"Pamięć\", aby odebrać wolną przestrzeń",
        ),
        "remindToEmptyEnteTrash": MessageLookupByLibrary.simpleMessage(
          "Opróżnij również swój \"Kosz\", aby zwolnić miejsce",
        ),
        "remoteImages": MessageLookupByLibrary.simpleMessage("Zdjęcia zdalne"),
        "remoteThumbnails": MessageLookupByLibrary.simpleMessage(
          "Zdalne miniatury",
        ),
        "remoteVideos": MessageLookupByLibrary.simpleMessage("Zdalne wideo"),
        "remove": MessageLookupByLibrary.simpleMessage("Usuń"),
        "removeDuplicates":
            MessageLookupByLibrary.simpleMessage("Usuń duplikaty"),
        "removeDuplicatesDesc": MessageLookupByLibrary.simpleMessage(
          "Przejrzyj i usuń pliki, które są dokładnymi duplikatami.",
        ),
        "removeFromAlbum":
            MessageLookupByLibrary.simpleMessage("Usuń z albumu"),
        "removeFromAlbumTitle": MessageLookupByLibrary.simpleMessage(
          "Usunąć z albumu?",
        ),
        "removeFromFavorite": MessageLookupByLibrary.simpleMessage(
          "Usuń z ulubionych",
        ),
        "removeInvite":
            MessageLookupByLibrary.simpleMessage("Usuń zaproszenie"),
        "removeLink": MessageLookupByLibrary.simpleMessage("Usuń link"),
        "removeParticipant": MessageLookupByLibrary.simpleMessage(
          "Usuń użytkownika",
        ),
        "removeParticipantBody": m74,
        "removePersonLabel": MessageLookupByLibrary.simpleMessage(
          "Usuń etykietę osoby",
        ),
        "removePublicLink": MessageLookupByLibrary.simpleMessage(
          "Usuń link publiczny",
        ),
        "removePublicLinks": MessageLookupByLibrary.simpleMessage(
          "Usuń linki publiczne",
        ),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
          "Niektóre z usuwanych elementów zostały dodane przez inne osoby i utracisz do nich dostęp",
        ),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Usunąć?"),
        "removeYourselfAsTrustedContact": MessageLookupByLibrary.simpleMessage(
          "Usuń siebie z listy zaufanych kontaktów",
        ),
        "removingFromFavorites": MessageLookupByLibrary.simpleMessage(
          "Usuwanie z ulubionych...",
        ),
        "rename": MessageLookupByLibrary.simpleMessage("Zmień nazwę"),
        "renameAlbum":
            MessageLookupByLibrary.simpleMessage("Zmień nazwę albumu"),
        "renameFile": MessageLookupByLibrary.simpleMessage("Zmień nazwę pliku"),
        "renewSubscription": MessageLookupByLibrary.simpleMessage(
          "Odnów subskrypcję",
        ),
        "renewsOn": m75,
        "reportABug": MessageLookupByLibrary.simpleMessage("Zgłoś błąd"),
        "reportBug": MessageLookupByLibrary.simpleMessage("Zgłoś błąd"),
        "resendEmail": MessageLookupByLibrary.simpleMessage(
          "Wyślij e-mail ponownie",
        ),
        "reset": MessageLookupByLibrary.simpleMessage("Zresetuj"),
        "resetIgnoredFiles": MessageLookupByLibrary.simpleMessage(
          "Zresetuj zignorowane pliki",
        ),
        "resetPasswordTitle": MessageLookupByLibrary.simpleMessage(
          "Zresetuj hasło",
        ),
        "resetPerson": MessageLookupByLibrary.simpleMessage("Usuń"),
        "resetToDefault":
            MessageLookupByLibrary.simpleMessage("Przywróć domyślne"),
        "restore": MessageLookupByLibrary.simpleMessage("Przywróć"),
        "restoreToAlbum": MessageLookupByLibrary.simpleMessage(
          "Przywróć do albumu",
        ),
        "restoringFiles": MessageLookupByLibrary.simpleMessage(
          "Przywracanie plików...",
        ),
        "resumableUploads": MessageLookupByLibrary.simpleMessage(
          "Przesyłania wznawialne",
        ),
        "retry": MessageLookupByLibrary.simpleMessage("Spróbuj ponownie"),
        "review": MessageLookupByLibrary.simpleMessage("Przejrzyj"),
        "reviewDeduplicateItems": MessageLookupByLibrary.simpleMessage(
          "Przejrzyj i usuń elementy, które uważasz, że są duplikatami.",
        ),
        "reviewSuggestions": MessageLookupByLibrary.simpleMessage(
          "Przeglądaj sugestie",
        ),
        "right": MessageLookupByLibrary.simpleMessage("W prawo"),
        "roadtripWithThem": m76,
        "rotate": MessageLookupByLibrary.simpleMessage("Obróć"),
        "rotateLeft": MessageLookupByLibrary.simpleMessage("Obróć w lewo"),
        "rotateRight": MessageLookupByLibrary.simpleMessage("Obróć w prawo"),
        "safelyStored": MessageLookupByLibrary.simpleMessage(
          "Bezpiecznie przechowywane",
        ),
        "same": MessageLookupByLibrary.simpleMessage("Identyczne"),
        "sameperson": MessageLookupByLibrary.simpleMessage("Ta sama osoba?"),
        "save": MessageLookupByLibrary.simpleMessage("Zapisz"),
        "saveAsAnotherPerson": MessageLookupByLibrary.simpleMessage(
          "Zapisz jako inną osobę",
        ),
        "saveChangesBeforeLeavingQuestion":
            MessageLookupByLibrary.simpleMessage(
          "Zapisać zmiany przed wyjściem?",
        ),
        "saveCollage": MessageLookupByLibrary.simpleMessage("Zapisz kolaż"),
        "saveCopy": MessageLookupByLibrary.simpleMessage("Zapisz kopię"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Zapisz klucz"),
        "savePerson": MessageLookupByLibrary.simpleMessage("Zapisz osobę"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
          "Zapisz swój klucz odzyskiwania, jeśli jeszcze tego nie zrobiłeś",
        ),
        "saving": MessageLookupByLibrary.simpleMessage("Zapisywanie..."),
        "savingEdits":
            MessageLookupByLibrary.simpleMessage("Zapisywanie zmian..."),
        "scanCode": MessageLookupByLibrary.simpleMessage("Zeskanuj kod"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
          "Zeskanuj ten kod kreskowy używając\nswojej aplikacji uwierzytelniającej",
        ),
        "search": MessageLookupByLibrary.simpleMessage("Szukaj"),
        "searchAlbumsEmptySection":
            MessageLookupByLibrary.simpleMessage("Albumy"),
        "searchByAlbumNameHint": MessageLookupByLibrary.simpleMessage(
          "Nazwa albumu",
        ),
        "searchByExamples": MessageLookupByLibrary.simpleMessage(
          "• Nazwy albumów (np. \"Aparat\")\n• Rodzaje plików (np. \"Wideo\", \".gif\")\n• Lata i miesiące (np. \"2022\", \"Styczeń\")\n• Święta (np. \"Boże Narodzenie\")\n• Opisy zdjęć (np. \"#fun\")",
        ),
        "searchCaptionEmptySection": MessageLookupByLibrary.simpleMessage(
          "Dodaj opisy takie jak \"#trip\" w informacji o zdjęciu, aby szybko znaleźć je tutaj",
        ),
        "searchDatesEmptySection": MessageLookupByLibrary.simpleMessage(
          "Szukaj według daty, miesiąca lub roku",
        ),
        "searchDiscoverEmptySection": MessageLookupByLibrary.simpleMessage(
          "Obrazy będą wyświetlane tutaj po zakończeniu przetwarzania i synchronizacji",
        ),
        "searchFaceEmptySection": MessageLookupByLibrary.simpleMessage(
          "Po zakończeniu indeksowania ludzie będą tu wyświetlani",
        ),
        "searchFileTypesAndNamesEmptySection":
            MessageLookupByLibrary.simpleMessage(
          "Typy plików i nazwy",
        ),
        "searchHint1": MessageLookupByLibrary.simpleMessage(
          "Szybkie wyszukiwanie na urządzeniu",
        ),
        "searchHint2":
            MessageLookupByLibrary.simpleMessage("Daty zdjęć, opisy"),
        "searchHint3": MessageLookupByLibrary.simpleMessage(
          "Albumy, nazwy plików i typy",
        ),
        "searchHint4": MessageLookupByLibrary.simpleMessage("Lokalizacja"),
        "searchHint5": MessageLookupByLibrary.simpleMessage(
          "Wkrótce: Twarze i magiczne wyszukiwanie ✨",
        ),
        "searchLocationEmptySection": MessageLookupByLibrary.simpleMessage(
          "Grupuj zdjęcia zrobione w promieniu zdjęcia",
        ),
        "searchPeopleEmptySection": MessageLookupByLibrary.simpleMessage(
          "Zaproś ludzi, a zobaczysz tutaj wszystkie udostępnione przez nich zdjęcia",
        ),
        "searchPersonsEmptySection": MessageLookupByLibrary.simpleMessage(
          "Osoby będą wyświetlane tutaj po zakończeniu przetwarzania i synchronizacji",
        ),
        "searchResultCount": m77,
        "searchSectionsLengthMismatch": m78,
        "security": MessageLookupByLibrary.simpleMessage("Bezpieczeństwo"),
        "seePublicAlbumLinksInApp": MessageLookupByLibrary.simpleMessage(
          "Zobacz publiczne linki do albumów w aplikacji",
        ),
        "selectALocation": MessageLookupByLibrary.simpleMessage(
          "Wybierz lokalizację",
        ),
        "selectALocationFirst": MessageLookupByLibrary.simpleMessage(
          "Najpierw wybierz lokalizację",
        ),
        "selectAlbum": MessageLookupByLibrary.simpleMessage("Wybierz album"),
        "selectAll": MessageLookupByLibrary.simpleMessage("Zaznacz wszystko"),
        "selectAllShort": MessageLookupByLibrary.simpleMessage("Wszystko"),
        "selectCoverPhoto": MessageLookupByLibrary.simpleMessage(
          "Wybierz zdjęcie na okładkę",
        ),
        "selectDate": MessageLookupByLibrary.simpleMessage("Wybierz datę"),
        "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
          "Wybierz foldery do stworzenia kopii zapasowej",
        ),
        "selectItemsToAdd": MessageLookupByLibrary.simpleMessage(
          "Wybierz elementy do dodania",
        ),
        "selectLanguage": MessageLookupByLibrary.simpleMessage("Wybierz Język"),
        "selectMailApp": MessageLookupByLibrary.simpleMessage(
          "Wybierz aplikację pocztową",
        ),
        "selectMorePhotos": MessageLookupByLibrary.simpleMessage(
          "Wybierz więcej zdjęć",
        ),
        "selectOneDateAndTime": MessageLookupByLibrary.simpleMessage(
          "Wybierz jedną datę i czas",
        ),
        "selectOneDateAndTimeForAll": MessageLookupByLibrary.simpleMessage(
          "Wybierz jedną datę i czas dla wszystkich",
        ),
        "selectPersonToLink": MessageLookupByLibrary.simpleMessage(
          "Wybierz osobę do powiązania",
        ),
        "selectReason": MessageLookupByLibrary.simpleMessage("Wybierz powód"),
        "selectStartOfRange": MessageLookupByLibrary.simpleMessage(
          "Wybierz początek zakresu",
        ),
        "selectTime": MessageLookupByLibrary.simpleMessage("Wybierz czas"),
        "selectYourFace": MessageLookupByLibrary.simpleMessage(
          "Wybierz swoją twarz",
        ),
        "selectYourPlan":
            MessageLookupByLibrary.simpleMessage("Wybierz swój plan"),
        "selectedAlbums": m79,
        "selectedFilesAreNotOnEnte": MessageLookupByLibrary.simpleMessage(
          "Wybrane pliki nie są w Ente",
        ),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
          "Wybrane foldery zostaną zaszyforwane i zostanie utworzona ich kopia zapasowa",
        ),
        "selectedItemsWillBeDeletedFromAllAlbumsAndMoved":
            MessageLookupByLibrary.simpleMessage(
          "Wybrane elementy zostaną usunięte ze wszystkich albumów i przeniesione do kosza.",
        ),
        "selectedItemsWillBeRemovedFromThisPerson":
            MessageLookupByLibrary.simpleMessage(
          "Wybrane elementy zostaną usunięte z tej osoby, ale nie zostaną usunięte z Twojej biblioteki.",
        ),
        "selectedPhotos": m80,
        "selectedPhotosWithYours": m81,
        "selfiesWithThem": m82,
        "send": MessageLookupByLibrary.simpleMessage("Wyślij"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("Wyślij e-mail"),
        "sendInvite":
            MessageLookupByLibrary.simpleMessage("Wyślij zaproszenie"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Wyślij link"),
        "serverEndpoint": MessageLookupByLibrary.simpleMessage(
          "Punkt końcowy serwera",
        ),
        "sessionExpired": MessageLookupByLibrary.simpleMessage("Sesja wygasła"),
        "sessionIdMismatch": MessageLookupByLibrary.simpleMessage(
          "Niezgodność ID sesji",
        ),
        "setAPassword": MessageLookupByLibrary.simpleMessage("Ustaw hasło"),
        "setAs": MessageLookupByLibrary.simpleMessage("Ustaw jako"),
        "setCover": MessageLookupByLibrary.simpleMessage("Ustaw okładkę"),
        "setLabel": MessageLookupByLibrary.simpleMessage("Ustaw"),
        "setNewPassword":
            MessageLookupByLibrary.simpleMessage("Ustaw nowe hasło"),
        "setNewPin": MessageLookupByLibrary.simpleMessage("Ustaw nowy kod PIN"),
        "setPasswordTitle": MessageLookupByLibrary.simpleMessage("Ustaw hasło"),
        "setRadius": MessageLookupByLibrary.simpleMessage("Ustaw promień"),
        "setupComplete": MessageLookupByLibrary.simpleMessage(
          "Konfiguracja ukończona",
        ),
        "share": MessageLookupByLibrary.simpleMessage("Udostępnij"),
        "shareALink": MessageLookupByLibrary.simpleMessage("Udostępnij link"),
        "shareAlbumHint": MessageLookupByLibrary.simpleMessage(
          "Otwórz album i dotknij przycisk udostępniania w prawym górnym rogu, aby udostępnić.",
        ),
        "shareAnAlbumNow": MessageLookupByLibrary.simpleMessage(
          "Udostępnij teraz album",
        ),
        "shareLink": MessageLookupByLibrary.simpleMessage("Udostępnij link"),
        "shareMyVerificationID": m83,
        "shareOnlyWithThePeopleYouWant": MessageLookupByLibrary.simpleMessage(
          "Udostępnij tylko ludziom, którym chcesz",
        ),
        "shareTextConfirmOthersVerificationID": m84,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
          "Pobierz Ente, abyśmy mogli łatwo udostępniać zdjęcia i wideo w oryginalnej jakości\n\nhttps://ente.io",
        ),
        "shareTextReferralCode": m85,
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
          "Udostępnij użytkownikom bez konta Ente",
        ),
        "shareWithPeopleSectionTitle": m86,
        "shareYourFirstAlbum": MessageLookupByLibrary.simpleMessage(
          "Udostępnij swój pierwszy album",
        ),
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
          "Twórz wspólne albumy i współpracuj z innymi użytkownikami Ente, w tym z użytkownikami korzystającymi z bezpłatnych planów.",
        ),
        "sharedByMe": MessageLookupByLibrary.simpleMessage(
          "Udostępnione przeze mnie",
        ),
        "sharedByYou": MessageLookupByLibrary.simpleMessage(
          "Udostępnione przez Ciebie",
        ),
        "sharedPhotoNotifications": MessageLookupByLibrary.simpleMessage(
          "Nowe udostępnione zdjęcia",
        ),
        "sharedPhotoNotificationsExplanation":
            MessageLookupByLibrary.simpleMessage(
          "Otrzymuj powiadomienia, gdy ktoś doda zdjęcie do udostępnionego albumu, którego jesteś częścią",
        ),
        "sharedWith": m87,
        "sharedWithMe":
            MessageLookupByLibrary.simpleMessage("Udostępnione ze mną"),
        "sharedWithYou": MessageLookupByLibrary.simpleMessage(
          "Udostępnione z Tobą",
        ),
        "sharing": MessageLookupByLibrary.simpleMessage("Udostępnianie..."),
        "shiftDatesAndTime": MessageLookupByLibrary.simpleMessage(
          "Zmień daty i czas",
        ),
        "showLessFaces":
            MessageLookupByLibrary.simpleMessage("Pokaż mniej twarzy"),
        "showMemories":
            MessageLookupByLibrary.simpleMessage("Pokaż wspomnienia"),
        "showMoreFaces": MessageLookupByLibrary.simpleMessage(
          "Pokaż więcej twarzy",
        ),
        "showPerson": MessageLookupByLibrary.simpleMessage("Pokaż osobę"),
        "signOutFromOtherDevices": MessageLookupByLibrary.simpleMessage(
          "Wyloguj z pozostałych urządzeń",
        ),
        "signOutOtherBody": MessageLookupByLibrary.simpleMessage(
          "Jeśli uważasz, że ktoś może znać Twoje hasło, możesz wymusić wylogowanie na wszystkich innych urządzeniach korzystających z Twojego konta.",
        ),
        "signOutOtherDevices": MessageLookupByLibrary.simpleMessage(
          "Wyloguj z pozostałych urządzeń",
        ),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
          "Akceptuję <u-terms>warunki korzystania z usługi</u-terms> i <u-policy>politykę prywatności</u-policy>",
        ),
        "singleFileDeleteFromDevice": m88,
        "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
          "To zostanie usunięte ze wszystkich albumów.",
        ),
        "singleFileInBothLocalAndRemote": m89,
        "singleFileInRemoteOnly": m90,
        "skip": MessageLookupByLibrary.simpleMessage("Pomiń"),
        "social": MessageLookupByLibrary.simpleMessage("Społeczność"),
        "someItemsAreInBothEnteAndYourDevice":
            MessageLookupByLibrary.simpleMessage(
          "Niektóre elementy są zarówno w Ente, jak i na Twoim urządzeniu.",
        ),
        "someOfTheFilesYouAreTryingToDeleteAre":
            MessageLookupByLibrary.simpleMessage(
          "Niektóre z plików, które próbujesz usunąć, są dostępne tylko na Twoim urządzeniu i nie można ich odzyskać po usunięciu",
        ),
        "someoneSharingAlbumsWithYouShouldSeeTheSameId":
            MessageLookupByLibrary.simpleMessage(
          "Osoba udostępniająca albumy powinna widzieć ten sam identyfikator na swoim urządzeniu.",
        ),
        "somethingWentWrong": MessageLookupByLibrary.simpleMessage(
          "Coś poszło nie tak",
        ),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
          "Coś poszło nie tak, spróbuj ponownie",
        ),
        "sorry": MessageLookupByLibrary.simpleMessage("Przepraszamy"),
        "sorryBackupFailedDesc": MessageLookupByLibrary.simpleMessage(
          "Przepraszamy, nie mogliśmy utworzyć kopii zapasowej tego pliku teraz, spróbujemy ponownie później.",
        ),
        "sorryCouldNotAddToFavorites": MessageLookupByLibrary.simpleMessage(
          "Przepraszamy, nie udało się dodać do ulubionych!",
        ),
        "sorryCouldNotRemoveFromFavorites":
            MessageLookupByLibrary.simpleMessage(
          "Przepraszamy, nie udało się usunąć z ulubionych!",
        ),
        "sorryTheCodeYouveEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
          "Niestety, wprowadzony kod jest nieprawidłowy",
        ),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
          "Przepraszamy, nie mogliśmy wygenerować bezpiecznych kluczy na tym urządzeniu.\n\nZarejestruj się z innego urządzenia.",
        ),
        "sorryWeHadToPauseYourBackups": MessageLookupByLibrary.simpleMessage(
          "Przepraszamy, musieliśmy wstrzymać tworzenie kopii zapasowych",
        ),
        "sort": MessageLookupByLibrary.simpleMessage("Sortuj"),
        "sortAlbumsBy": MessageLookupByLibrary.simpleMessage("Sortuj według"),
        "sortNewestFirst":
            MessageLookupByLibrary.simpleMessage("Od najnowszych"),
        "sortOldestFirst":
            MessageLookupByLibrary.simpleMessage("Od najstarszych"),
        "sparkleSuccess": MessageLookupByLibrary.simpleMessage("✨ Sukces"),
        "sportsWithThem": m91,
        "spotlightOnThem": m92,
        "spotlightOnYourself": MessageLookupByLibrary.simpleMessage(
          "Uwaga na siebie",
        ),
        "startAccountRecoveryTitle": MessageLookupByLibrary.simpleMessage(
          "Rozpocznij odzyskiwanie",
        ),
        "startBackup": MessageLookupByLibrary.simpleMessage(
          "Uruchom tworzenie kopii zapasowej",
        ),
        "status": MessageLookupByLibrary.simpleMessage("Stan"),
        "stopCastingBody": MessageLookupByLibrary.simpleMessage(
          "Czy chcesz przestać wyświetlać?",
        ),
        "stopCastingTitle": MessageLookupByLibrary.simpleMessage(
          "Zatrzymaj wyświetlanie",
        ),
        "storage": MessageLookupByLibrary.simpleMessage("Pamięć"),
        "storageBreakupFamily": MessageLookupByLibrary.simpleMessage("Rodzina"),
        "storageBreakupYou": MessageLookupByLibrary.simpleMessage("Ty"),
        "storageInGB": m93,
        "storageLimitExceeded": MessageLookupByLibrary.simpleMessage(
          "Przekroczono limit pamięci",
        ),
        "storageUsageInfo": m94,
        "strongStrength": MessageLookupByLibrary.simpleMessage("Silne"),
        "subAlreadyLinkedErrMessage": m95,
        "subWillBeCancelledOn": m96,
        "subscribe": MessageLookupByLibrary.simpleMessage("Subskrybuj"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
          "Potrzebujesz aktywnej płatnej subskrypcji, aby włączyć udostępnianie.",
        ),
        "subscription": MessageLookupByLibrary.simpleMessage("Subskrypcja"),
        "success": MessageLookupByLibrary.simpleMessage("Sukces"),
        "successfullyArchived": MessageLookupByLibrary.simpleMessage(
          "Pomyślnie zarchiwizowano",
        ),
        "successfullyHid":
            MessageLookupByLibrary.simpleMessage("Pomyślnie ukryto"),
        "successfullyUnarchived": MessageLookupByLibrary.simpleMessage(
          "Pomyślnie przywrócono z archiwum",
        ),
        "successfullyUnhid": MessageLookupByLibrary.simpleMessage(
          "Pomyślnie odkryto",
        ),
        "suggestFeatures": MessageLookupByLibrary.simpleMessage(
          "Zaproponuj funkcje",
        ),
        "sunrise": MessageLookupByLibrary.simpleMessage("Na horyzoncie"),
        "support": MessageLookupByLibrary.simpleMessage("Wsparcie techniczne"),
        "syncProgress": m97,
        "syncStopped": MessageLookupByLibrary.simpleMessage(
          "Synchronizacja zatrzymana",
        ),
        "syncing": MessageLookupByLibrary.simpleMessage("Synchronizowanie..."),
        "systemTheme": MessageLookupByLibrary.simpleMessage("Systemowy"),
        "tapToCopy":
            MessageLookupByLibrary.simpleMessage("naciśnij aby skopiować"),
        "tapToEnterCode": MessageLookupByLibrary.simpleMessage(
          "Stuknij, aby wprowadzić kod",
        ),
        "tapToUnlock": MessageLookupByLibrary.simpleMessage(
          "Naciśnij, aby odblokować",
        ),
        "tapToUpload": MessageLookupByLibrary.simpleMessage(
          "Naciśnij, aby przesłać",
        ),
        "tapToUploadIsIgnoredDue": m98,
        "tempErrorContactSupportIfPersists":
            MessageLookupByLibrary.simpleMessage(
          "Wygląda na to, że coś poszło nie tak. Spróbuj ponownie po pewnym czasie. Jeśli błąd będzie się powtarzał, skontaktuj się z naszym zespołem pomocy technicznej.",
        ),
        "terminate": MessageLookupByLibrary.simpleMessage("Zakończ"),
        "terminateSession": MessageLookupByLibrary.simpleMessage(
          "Zakończyć sesję?",
        ),
        "terms": MessageLookupByLibrary.simpleMessage("Warunki"),
        "termsOfServicesTitle":
            MessageLookupByLibrary.simpleMessage("Regulamin"),
        "thankYou": MessageLookupByLibrary.simpleMessage("Dziękujemy"),
        "thankYouForSubscribing": MessageLookupByLibrary.simpleMessage(
          "Dziękujemy za subskrypcję!",
        ),
        "theDownloadCouldNotBeCompleted": MessageLookupByLibrary.simpleMessage(
          "Pobieranie nie mogło zostać ukończone",
        ),
        "theLinkYouAreTryingToAccessHasExpired":
            MessageLookupByLibrary.simpleMessage(
          "Link, do którego próbujesz uzyskać dostęp, wygasł.",
        ),
        "thePersonGroupsWillNotBeDisplayed":
            MessageLookupByLibrary.simpleMessage(
          "Grupy osób nie będą już wyświetlane w sekcji ludzi. Zdjęcia pozostaną nienaruszone.",
        ),
        "thePersonWillNotBeDisplayed": MessageLookupByLibrary.simpleMessage(
          "Osoba nie będzie już wyświetlana w sekcji ludzi. Zdjęcia pozostaną nienaruszone.",
        ),
        "theRecoveryKeyYouEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
          "Wprowadzony klucz odzyskiwania jest nieprawidłowy",
        ),
        "theme": MessageLookupByLibrary.simpleMessage("Motyw"),
        "theseItemsWillBeDeletedFromYourDevice":
            MessageLookupByLibrary.simpleMessage(
          "Te elementy zostaną usunięte z Twojego urządzenia.",
        ),
        "theyAlsoGetXGb": m99,
        "theyWillBeDeletedFromAllAlbums": MessageLookupByLibrary.simpleMessage(
          "Zostaną one usunięte ze wszystkich albumów.",
        ),
        "thisActionCannotBeUndone": MessageLookupByLibrary.simpleMessage(
          "Tej czynności nie można cofnąć",
        ),
        "thisAlbumAlreadyHDACollaborativeLink":
            MessageLookupByLibrary.simpleMessage(
          "Ten album posiada już link do współpracy",
        ),
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
          "Można go użyć do odzyskania konta w przypadku utraty swojej drugiej metody uwierzytelniania",
        ),
        "thisDevice": MessageLookupByLibrary.simpleMessage("To urządzenie"),
        "thisEmailIsAlreadyInUse": MessageLookupByLibrary.simpleMessage(
          "Ten e-mail jest już używany",
        ),
        "thisImageHasNoExifData": MessageLookupByLibrary.simpleMessage(
          "Ten obraz nie posiada danych exif",
        ),
        "thisIsMeExclamation": MessageLookupByLibrary.simpleMessage("To ja!"),
        "thisIsPersonVerificationId": m100,
        "thisIsYourVerificationId": MessageLookupByLibrary.simpleMessage(
          "To jest Twój Identyfikator Weryfikacji",
        ),
        "thisWeekThroughTheYears": MessageLookupByLibrary.simpleMessage(
          "Ten tydzień przez lata",
        ),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
          "To wyloguje Cię z tego urządzenia:",
        ),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
          "To wyloguje Cię z tego urządzenia!",
        ),
        "thisWillMakeTheDateAndTimeOfAllSelected":
            MessageLookupByLibrary.simpleMessage(
          "To sprawi, że data i czas wszystkich wybranych zdjęć będą takie same.",
        ),
        "thisWillRemovePublicLinksOfAllSelectedQuickLinks":
            MessageLookupByLibrary.simpleMessage(
          "Spowoduje to usunięcie publicznych linków wszystkich zaznaczonych szybkich linków.",
        ),
        "throughTheYears": m102,
        "toEnableAppLockPleaseSetupDevicePasscodeOrScreen":
            MessageLookupByLibrary.simpleMessage(
          "Aby włączyć blokadę aplikacji, należy skonfigurować hasło urządzenia lub blokadę ekranu w ustawieniach systemu.",
        ),
        "toHideAPhotoOrVideo": MessageLookupByLibrary.simpleMessage(
          "Aby ukryć zdjęcie lub wideo",
        ),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
          "Aby zresetować hasło, najpierw zweryfikuj swój adres e-mail.",
        ),
        "todaysLogs": MessageLookupByLibrary.simpleMessage("Dzisiejsze logi"),
        "tooManyIncorrectAttempts": MessageLookupByLibrary.simpleMessage(
          "Zbyt wiele błędnych prób",
        ),
        "total": MessageLookupByLibrary.simpleMessage("ogółem"),
        "totalSize": MessageLookupByLibrary.simpleMessage("Całkowity rozmiar"),
        "trash": MessageLookupByLibrary.simpleMessage("Kosz"),
        "trashDaysLeft": m103,
        "trim": MessageLookupByLibrary.simpleMessage("Przytnij"),
        "tripInYear": m104,
        "trustedContacts":
            MessageLookupByLibrary.simpleMessage("Zaufane kontakty"),
        "trustedInviteBody": m106,
        "tryAgain": MessageLookupByLibrary.simpleMessage("Spróbuj ponownie"),
        "turnOnBackupForAutoUpload": MessageLookupByLibrary.simpleMessage(
          "Włącz kopię zapasową, aby automatycznie przesyłać pliki dodane do folderu urządzenia do Ente.",
        ),
        "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
        "twoMonthsFreeOnYearlyPlans": MessageLookupByLibrary.simpleMessage(
          "2 miesiące za darmo na planach rocznych",
        ),
        "twofactor": MessageLookupByLibrary.simpleMessage(
          "Uwierzytelnianie dwustopniowe",
        ),
        "twofactorAuthenticationHasBeenDisabled":
            MessageLookupByLibrary.simpleMessage(
          "Uwierzytelnianie dwustopniowe zostało wyłączone",
        ),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage(
          "Uwierzytelnianie dwustopniowe",
        ),
        "twofactorAuthenticationSuccessfullyReset":
            MessageLookupByLibrary.simpleMessage(
          "Pomyślnie zresetowano uwierzytelnianie dwustopniowe",
        ),
        "twofactorSetup": MessageLookupByLibrary.simpleMessage(
          "Uwierzytelnianie dwustopniowe",
        ),
        "typeOfGallerGallerytypeIsNotSupportedForRename": m107,
        "unarchive":
            MessageLookupByLibrary.simpleMessage("Przywróć z archiwum"),
        "unarchiveAlbum": MessageLookupByLibrary.simpleMessage(
          "Przywróć album z archiwum",
        ),
        "unarchiving": MessageLookupByLibrary.simpleMessage(
          "Usuwanie z archiwum...",
        ),
        "unavailableReferralCode": MessageLookupByLibrary.simpleMessage(
          "Przepraszamy, ten kod jest niedostępny.",
        ),
        "uncategorized": MessageLookupByLibrary.simpleMessage("Bez kategorii"),
        "unhide": MessageLookupByLibrary.simpleMessage("Odkryj"),
        "unhideToAlbum":
            MessageLookupByLibrary.simpleMessage("Odkryj do albumu"),
        "unhiding": MessageLookupByLibrary.simpleMessage("Odkrywanie..."),
        "unhidingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
          "Odkrywanie plików do albumu",
        ),
        "unlock": MessageLookupByLibrary.simpleMessage("Odblokuj"),
        "unpinAlbum": MessageLookupByLibrary.simpleMessage("Odepnij album"),
        "unselectAll": MessageLookupByLibrary.simpleMessage("Odznacz wszystko"),
        "update": MessageLookupByLibrary.simpleMessage("Aktualizuj"),
        "updateAvailable": MessageLookupByLibrary.simpleMessage(
          "Dostępna jest aktualizacja",
        ),
        "updatingFolderSelection": MessageLookupByLibrary.simpleMessage(
          "Aktualizowanie wyboru folderu...",
        ),
        "upgrade": MessageLookupByLibrary.simpleMessage("Ulepsz"),
        "uploadIsIgnoredDueToIgnorereason": m108,
        "uploadingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
          "Przesyłanie plików do albumu...",
        ),
        "uploadingMultipleMemories": m109,
        "uploadingSingleMemory": MessageLookupByLibrary.simpleMessage(
          "Zachowywanie 1 wspomnienia...",
        ),
        "upto50OffUntil4thDec": MessageLookupByLibrary.simpleMessage(
          "Do 50% zniżki, do 4 grudnia.",
        ),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
          "Użyteczna przestrzeń dyskowa jest ograniczona przez Twój obecny plan. Nadmiar zadeklarowanej przestrzeni dyskowej stanie się automatycznie użyteczny po uaktualnieniu planu.",
        ),
        "useAsCover": MessageLookupByLibrary.simpleMessage("Użyj jako okładki"),
        "useDifferentPlayerInfo": MessageLookupByLibrary.simpleMessage(
          "Masz problem z odtwarzaniem tego wideo? Przytrzymaj tutaj, aby spróbować innego odtwarzacza.",
        ),
        "usePublicLinksForPeopleNotOnEnte":
            MessageLookupByLibrary.simpleMessage(
          "Użyj publicznych linków dla osób spoza Ente",
        ),
        "useRecoveryKey": MessageLookupByLibrary.simpleMessage(
          "Użyj kodu odzyskiwania",
        ),
        "useSelectedPhoto": MessageLookupByLibrary.simpleMessage(
          "Użyj zaznaczone zdjęcie",
        ),
        "usedSpace": MessageLookupByLibrary.simpleMessage("Zajęta przestrzeń"),
        "validTill": m110,
        "verificationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
          "Weryfikacja nie powiodła się, spróbuj ponownie",
        ),
        "verificationId": MessageLookupByLibrary.simpleMessage(
          "Identyfikator weryfikacyjny",
        ),
        "verify": MessageLookupByLibrary.simpleMessage("Zweryfikuj"),
        "verifyEmail": MessageLookupByLibrary.simpleMessage(
          "Zweryfikuj adres e-mail",
        ),
        "verifyEmailID": m111,
        "verifyIDLabel": MessageLookupByLibrary.simpleMessage("Zweryfikuj"),
        "verifyPasskey": MessageLookupByLibrary.simpleMessage(
          "Zweryfikuj klucz dostępu",
        ),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Zweryfikuj hasło"),
        "verifying": MessageLookupByLibrary.simpleMessage("Weryfikowanie..."),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
          "Weryfikowanie klucza odzyskiwania...",
        ),
        "videoInfo": MessageLookupByLibrary.simpleMessage("Informacje Wideo"),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("wideo"),
        "videoStreaming": MessageLookupByLibrary.simpleMessage(
          "Streamowalne wideo",
        ),
        "videos": MessageLookupByLibrary.simpleMessage("Wideo"),
        "viewActiveSessions": MessageLookupByLibrary.simpleMessage(
          "Zobacz aktywne sesje",
        ),
        "viewAddOnButton":
            MessageLookupByLibrary.simpleMessage("Zobacz dodatki"),
        "viewAll": MessageLookupByLibrary.simpleMessage("Pokaż wszystkie"),
        "viewAllExifData": MessageLookupByLibrary.simpleMessage(
          "Wyświetl wszystkie dane EXIF",
        ),
        "viewLargeFiles": MessageLookupByLibrary.simpleMessage("Duże pliki"),
        "viewLargeFilesDesc": MessageLookupByLibrary.simpleMessage(
          "Wyświetl pliki zużywające największą ilość pamięci.",
        ),
        "viewLogs": MessageLookupByLibrary.simpleMessage("Wyświetl logi"),
        "viewPersonToUnlink": m112,
        "viewRecoveryKey": MessageLookupByLibrary.simpleMessage(
          "Zobacz klucz odzyskiwania",
        ),
        "viewer": MessageLookupByLibrary.simpleMessage("Widz"),
        "visitWebToManage": MessageLookupByLibrary.simpleMessage(
          "Odwiedź stronę web.ente.io, aby zarządzać subskrypcją",
        ),
        "waitingForVerification": MessageLookupByLibrary.simpleMessage(
          "Oczekiwanie na weryfikację...",
        ),
        "waitingForWifi": MessageLookupByLibrary.simpleMessage(
          "Czekanie na WiFi...",
        ),
        "warning": MessageLookupByLibrary.simpleMessage("Uwaga"),
        "weAreOpenSource": MessageLookupByLibrary.simpleMessage(
          "Posiadamy otwarte źródło!",
        ),
        "weDontSupportEditingPhotosAndAlbumsThatYouDont":
            MessageLookupByLibrary.simpleMessage(
          "Nie wspieramy edycji zdjęć i albumów, których jeszcze nie posiadasz",
        ),
        "weHaveSendEmailTo": m114,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Słabe"),
        "welcomeBack": MessageLookupByLibrary.simpleMessage("Witaj ponownie!"),
        "whatsNew": MessageLookupByLibrary.simpleMessage("Co nowego"),
        "whyAddTrustContact": MessageLookupByLibrary.simpleMessage(
          "Zaufany kontakt może pomóc w odzyskaniu Twoich danych.",
        ),
        "widgets": MessageLookupByLibrary.simpleMessage("Widżety"),
        "wishThemAHappyBirthday": m115,
        "yearShort": MessageLookupByLibrary.simpleMessage("r"),
        "yearly": MessageLookupByLibrary.simpleMessage("Rocznie"),
        "yearsAgo": m116,
        "yes": MessageLookupByLibrary.simpleMessage("Tak"),
        "yesCancel": MessageLookupByLibrary.simpleMessage("Tak, anuluj"),
        "yesConvertToViewer": MessageLookupByLibrary.simpleMessage(
          "Tak, konwertuj na widza",
        ),
        "yesDelete": MessageLookupByLibrary.simpleMessage("Tak, usuń"),
        "yesDiscardChanges": MessageLookupByLibrary.simpleMessage(
          "Tak, odrzuć zmiany",
        ),
        "yesIgnore": MessageLookupByLibrary.simpleMessage("Tak, ignoruj"),
        "yesLogout": MessageLookupByLibrary.simpleMessage("Tak, wyloguj"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("Tak, usuń"),
        "yesRenew": MessageLookupByLibrary.simpleMessage("Tak, Odnów"),
        "yesResetPerson": MessageLookupByLibrary.simpleMessage(
          "Tak, zresetuj osobę",
        ),
        "you": MessageLookupByLibrary.simpleMessage("Ty"),
        "youAndThem": m117,
        "youAreOnAFamilyPlan": MessageLookupByLibrary.simpleMessage(
          "Jesteś w planie rodzinnym!",
        ),
        "youAreOnTheLatestVersion": MessageLookupByLibrary.simpleMessage(
          "Korzystasz z najnowszej wersji",
        ),
        "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
          "* Maksymalnie możesz podwoić swoją przestrzeń dyskową",
        ),
        "youCanManageYourLinksInTheShareTab":
            MessageLookupByLibrary.simpleMessage(
          "Możesz zarządzać swoimi linkami w zakładce udostępnianie.",
        ),
        "youCanTrySearchingForADifferentQuery":
            MessageLookupByLibrary.simpleMessage(
          "Możesz spróbować wyszukać inne zapytanie.",
        ),
        "youCannotDowngradeToThisPlan": MessageLookupByLibrary.simpleMessage(
          "Nie możesz przejść do tego planu",
        ),
        "youCannotShareWithYourself": MessageLookupByLibrary.simpleMessage(
          "Nie możesz udostępnić samemu sobie",
        ),
        "youDontHaveAnyArchivedItems": MessageLookupByLibrary.simpleMessage(
          "Nie masz żadnych zarchiwizowanych elementów.",
        ),
        "youHaveSuccessfullyFreedUp": m118,
        "yourAccountHasBeenDeleted": MessageLookupByLibrary.simpleMessage(
          "Twoje konto zostało usunięte",
        ),
        "yourMap": MessageLookupByLibrary.simpleMessage("Twoja mapa"),
        "yourPlanWasSuccessfullyDowngraded":
            MessageLookupByLibrary.simpleMessage(
          "Twój plan został pomyślnie obniżony",
        ),
        "yourPlanWasSuccessfullyUpgraded": MessageLookupByLibrary.simpleMessage(
          "Twój plan został pomyślnie ulepszony",
        ),
        "yourPurchaseWasSuccessful": MessageLookupByLibrary.simpleMessage(
          "Twój zakup zakończył się pomyślnie",
        ),
        "yourStorageDetailsCouldNotBeFetched":
            MessageLookupByLibrary.simpleMessage(
          "Nie można pobrać szczegółów pamięci",
        ),
        "yourSubscriptionHasExpired": MessageLookupByLibrary.simpleMessage(
          "Twoja subskrypcja wygasła",
        ),
        "yourSubscriptionWasUpdatedSuccessfully":
            MessageLookupByLibrary.simpleMessage(
          "Twoja subskrypcja została pomyślnie zaktualizowana",
        ),
        "yourVerificationCodeHasExpired": MessageLookupByLibrary.simpleMessage(
          "Twój kod weryfikacyjny wygasł",
        ),
        "youveNoDuplicateFilesThatCanBeCleared":
            MessageLookupByLibrary.simpleMessage(
          "Nie masz zduplikowanych plików, które można wyczyścić",
        ),
        "youveNoFilesInThisAlbumThatCanBeDeleted":
            MessageLookupByLibrary.simpleMessage(
          "Nie masz żadnych plików w tym albumie, które można usunąć",
        ),
        "zoomOutToSeePhotos": MessageLookupByLibrary.simpleMessage(
          "Pomniejsz, aby zobaczyć zdjęcia",
        ),
      };
}
