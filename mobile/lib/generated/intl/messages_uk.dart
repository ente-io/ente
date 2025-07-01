// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a uk locale. All the
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
  String get localeName => 'uk';

  static String m3(storageAmount, endDate) =>
      "Ваше доповнення ${storageAmount} діє до ${endDate}";

  static String m5(emailOrName) => "Додано ${emailOrName}";

  static String m6(albumName) => "Успішно додано до «${albumName}»";

  static String m8(count) =>
      "${Intl.plural(count, zero: 'Немає учасників', one: '1 учасник', other: '${count} учасників')}";

  static String m9(versionValue) => "Версія: ${versionValue}";

  static String m10(freeAmount, storageUnit) =>
      "${freeAmount} ${storageUnit} вільно";

  static String m12(paymentProvider) =>
      "Спочатку скасуйте вашу передплату від ${paymentProvider}";

  static String m13(user) =>
      "${user} не зможе додавати більше фотографій до цього альбому\n\nВони все ще зможуть видаляти додані ними фотографії";

  static String m14(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true': 'Ваша сім\'я отримала ${storageAmountInGb} ГБ',
            'false': 'Ви отримали ${storageAmountInGb} ГБ',
            'other': 'Ви отримали ${storageAmountInGb} ГБ!',
          })}";

  static String m15(albumName) =>
      "Створено спільне посилання для «${albumName}»";

  static String m17(email, numOfDays) =>
      "Ви збираєтеся додати ${email} як довірений контакт. Вони зможуть відновити ваш обліковий запис, якщо ви будете відсутні протягом ${numOfDays} днів.";

  static String m18(familyAdminEmail) =>
      "Зв\'яжіться з <green>${familyAdminEmail}</green> для керування вашою передплатою";

  static String m19(provider) =>
      "Зв\'яжіться з нами за адресою support@ente.io для управління вашою передплатою ${provider}.";

  static String m20(endpoint) => "Під\'єднано до ${endpoint}";

  static String m21(count) =>
      "${Intl.plural(count, one: 'Видалено ${count} елемент', other: 'Видалено ${count} елементів')}";

  static String m23(currentlyDeleting, totalCount) =>
      "Видалення ${currentlyDeleting} / ${totalCount}";

  static String m24(albumName) =>
      "Це видалить публічне посилання для доступу до «${albumName}».";

  static String m25(supportEmail) =>
      "Надішліть листа на ${supportEmail} з вашої зареєстрованої поштової адреси";

  static String m26(count, storageSaved) =>
      "Ви очистили ${Intl.plural(count, one: '${count} дублікат файлу', other: '${count} дублікатів файлів')}, збережено (${storageSaved}!)";

  static String m27(count, formattedSize) =>
      "${count} файлів, кожен по ${formattedSize}";

  static String m29(newEmail) => "Поштову адресу змінено на ${newEmail}";

  static String m31(email) =>
      "У ${email} немає облікового запису Ente.\n\nНадішліть їм запрошення для обміну фотографіями.";

  static String m33(text) => "Знайдено додаткові фотографії для ${text}";

  static String m35(count, formattedNumber) =>
      "${Intl.plural(count, one: 'Для 1 файлу', other: 'Для ${formattedNumber} файлів')} на цьому пристрої було створено резервну копію";

  static String m36(count, formattedNumber) =>
      "${Intl.plural(count, one: 'Для 1 файлу', other: 'Для ${formattedNumber} файлів')} у цьому альбомі було створено резервну копію";

  static String m37(storageAmountInGB) =>
      "${storageAmountInGB} ГБ щоразу, коли хтось оформлює передплату і застосовує ваш код";

  static String m38(endDate) => "Безплатна пробна версія діє до ${endDate}";

  static String m40(sizeInMBorGB) => "Звільніть ${sizeInMBorGB}";

  static String m42(currentlyProcessing, totalCount) =>
      "Обробка ${currentlyProcessing} / ${totalCount}";

  static String m44(count) =>
      "${Intl.plural(count, one: '${count} елемент', other: '${count} елементів')}";

  static String m46(email) => "${email} запросив вас стати довіреною особою";

  static String m47(expiryTime) => "Посилання закінчується через ${expiryTime}";

  static String m52(albumName) => "Успішно перенесено до «${albumName}»";

  static String m53(personName) => "Немає пропозицій для ${personName}";

  static String m54(name) => "Не ${name}?";

  static String m55(familyAdminEmail) =>
      "Зв\'яжіться з ${familyAdminEmail}, щоб змінити код.";

  static String m57(passwordStrengthValue) =>
      "Надійність пароля: ${passwordStrengthValue}";

  static String m58(providerName) =>
      "Зверніться до ${providerName}, якщо було знято платіж";

  static String m63(endDate) =>
      "Безплатна пробна версія діє до ${endDate}.\nПісля цього ви можете обрати платний план.";

  static String m64(toEmail) => "Напишіть нам на ${toEmail}";

  static String m65(toEmail) => "Надішліть журнали на \n${toEmail}";

  static String m67(folderName) => "Оброблюємо «${folderName}»...";

  static String m68(storeName) => "Оцініть нас в ${storeName}";

  static String m70(days, email) =>
      "Ви зможете отримати доступ до облікового запису через ${days} днів. Повідомлення буде надіслано на ${email}.";

  static String m71(email) =>
      "Тепер ви можете відновити обліковий запис ${email}, встановивши новий пароль.";

  static String m72(email) =>
      "${email} намагається відновити ваш обліковий запис.";

  static String m73(storageInGB) =>
      "3. Ви обоє отримуєте ${storageInGB} ГБ* безплатно";

  static String m74(userEmail) =>
      "${userEmail} буде видалено з цього спільного альбому\n\nБудь-які додані вами фото, будуть також видалені з альбому";

  static String m75(endDate) => "Передплата поновиться ${endDate}";

  static String m77(count) =>
      "${Intl.plural(count, one: 'Знайдено ${count} результат', other: 'Знайдено ${count} результати')}";

  static String m78(snapshotLength, searchLength) =>
      "Невідповідність довжини розділів: ${snapshotLength} != ${searchLength}";

  static String m80(count) => "${count} вибрано";

  static String m81(count, yourCount) => "${count} вибрано (${yourCount} ваші)";

  static String m83(verificationID) =>
      "Ось мій ідентифікатор підтвердження: ${verificationID} для ente.io.";

  static String m84(verificationID) =>
      "Гей, ви можете підтвердити, що це ваш ідентифікатор підтвердження: ${verificationID}";

  static String m85(referralCode, referralStorageInGB) =>
      "Реферальний код Ente: ${referralCode} \n\nЗастосуйте його в «Налаштування» → «Загальні» → «Реферали», щоб отримати ${referralStorageInGB} ГБ безплатно після переходу на платний тариф\n\nhttps://ente.io";

  static String m86(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Поділитися з конкретними людьми', one: 'Поділитися з 1 особою', other: 'Поділитися з ${numberOfPeople} людьми')}";

  static String m87(emailIDs) => "Поділилися з ${emailIDs}";

  static String m88(fileType) => "Цей ${fileType} буде видалено з пристрою.";

  static String m89(fileType) =>
      "Цей ${fileType} знаходиться і в Ente, і на вашому пристрої.";

  static String m90(fileType) => "Цей ${fileType} буде видалено з Ente.";

  static String m93(storageAmountInGB) => "${storageAmountInGB} ГБ";

  static String m94(
          usedAmount, usedStorageUnit, totalAmount, totalStorageUnit) =>
      "${usedAmount} ${usedStorageUnit} з ${totalAmount} ${totalStorageUnit} використано";

  static String m95(id) =>
      "Ваш ${id} вже пов\'язаний з іншим обліковим записом Ente.\nЯкщо ви хочете використовувати свій ${id} з цим обліковим записом, зверніться до нашої служби підтримки";

  static String m96(endDate) => "Вашу передплату буде скасовано ${endDate}";

  static String m97(completed, total) =>
      "${completed} / ${total} спогадів збережено";

  static String m98(ignoreReason) =>
      "Натисніть, щоб завантажити; завантаження наразі ігнорується через: ${ignoreReason}";

  static String m99(storageAmountInGB) =>
      "Вони також отримують ${storageAmountInGB} ГБ";

  static String m100(email) => "Це ідентифікатор підтвердження пошти ${email}";

  static String m103(count) =>
      "${Intl.plural(count, zero: 'Незабаром', one: '1 день', other: '${count} днів')}";

  static String m106(email) =>
      "Ви отримали запрошення стати спадковим контактом від ${email}.";

  static String m107(galleryType) =>
      "Тип галереї «${galleryType}» не підтримується для перейменування";

  static String m108(ignoreReason) =>
      "Завантаження проігноровано через: ${ignoreReason}";

  static String m109(count) => "Збереження ${count} спогадів...";

  static String m110(endDate) => "Діє до ${endDate}";

  static String m111(email) => "Підтвердити ${email}";

  static String m114(email) => "Ми надіслали листа на <green>${email}</green>";

  static String m115(name) => "Wish \$${name} a happy birthday! 🎉";

  static String m116(count) =>
      "${Intl.plural(count, one: '${count} рік тому', other: '${count} років тому')}";

  static String m118(storageSaved) => "Ви успішно звільнили ${storageSaved}!";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable":
            MessageLookupByLibrary.simpleMessage("Доступна нова версія Ente."),
        "about": MessageLookupByLibrary.simpleMessage("Про застосунок"),
        "acceptTrustInvite":
            MessageLookupByLibrary.simpleMessage("Прийняти запрошення"),
        "account": MessageLookupByLibrary.simpleMessage("Обліковий запис"),
        "accountIsAlreadyConfigured": MessageLookupByLibrary.simpleMessage(
            "Обліковий запис уже налаштовано."),
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("З поверненням!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Я розумію, що якщо я втрачу свій пароль, я можу втратити свої дані, тому що вони є захищені <underline>наскрізним шифруванням</underline>."),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Активні сеанси"),
        "add": MessageLookupByLibrary.simpleMessage("Додати"),
        "addAName": MessageLookupByLibrary.simpleMessage("Додати ім\'я"),
        "addANewEmail":
            MessageLookupByLibrary.simpleMessage("Додати нову пошту"),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Додати співавтора"),
        "addFiles": MessageLookupByLibrary.simpleMessage("Додати файли"),
        "addFromDevice":
            MessageLookupByLibrary.simpleMessage("Додати з пристрою"),
        "addLocation":
            MessageLookupByLibrary.simpleMessage("Додати розташування"),
        "addLocationButton": MessageLookupByLibrary.simpleMessage("Додати"),
        "addMore": MessageLookupByLibrary.simpleMessage("Додати більше"),
        "addName": MessageLookupByLibrary.simpleMessage("Додати ім\'я"),
        "addNameOrMerge":
            MessageLookupByLibrary.simpleMessage("Додати назву або об\'єднати"),
        "addNew": MessageLookupByLibrary.simpleMessage("Додати нове"),
        "addNewPerson":
            MessageLookupByLibrary.simpleMessage("Додати нову особу"),
        "addOnPageSubtitle":
            MessageLookupByLibrary.simpleMessage("Подробиці доповнень"),
        "addOnValidTill": m3,
        "addOns": MessageLookupByLibrary.simpleMessage("Доповнення"),
        "addPhotos": MessageLookupByLibrary.simpleMessage("Додати фотографії"),
        "addSelected": MessageLookupByLibrary.simpleMessage("Додати вибране"),
        "addToAlbum": MessageLookupByLibrary.simpleMessage("Додати до альбому"),
        "addToEnte": MessageLookupByLibrary.simpleMessage("Додати до Ente"),
        "addToHiddenAlbum": MessageLookupByLibrary.simpleMessage(
            "Додати до прихованого альбому"),
        "addTrustedContact":
            MessageLookupByLibrary.simpleMessage("Додати довірений контакт"),
        "addViewer": MessageLookupByLibrary.simpleMessage("Додати глядача"),
        "addYourPhotosNow":
            MessageLookupByLibrary.simpleMessage("Додайте свої фотографії"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Додано як"),
        "addedBy": m5,
        "addedSuccessfullyTo": m6,
        "addingToFavorites":
            MessageLookupByLibrary.simpleMessage("Додавання до обраного..."),
        "advanced": MessageLookupByLibrary.simpleMessage("Додатково"),
        "advancedSettings": MessageLookupByLibrary.simpleMessage("Додатково"),
        "after1Day": MessageLookupByLibrary.simpleMessage("Через 1 день"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("Через 1 годину"),
        "after1Month": MessageLookupByLibrary.simpleMessage("Через 1 місяць"),
        "after1Week": MessageLookupByLibrary.simpleMessage("Через 1 тиждень"),
        "after1Year": MessageLookupByLibrary.simpleMessage("Через 1 рік"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Власник"),
        "albumParticipantsCount": m8,
        "albumTitle": MessageLookupByLibrary.simpleMessage("Назва альбому"),
        "albumUpdated": MessageLookupByLibrary.simpleMessage("Альбом оновлено"),
        "albums": MessageLookupByLibrary.simpleMessage("Альбоми"),
        "allClear": MessageLookupByLibrary.simpleMessage("✨ Все чисто"),
        "allMemoriesPreserved":
            MessageLookupByLibrary.simpleMessage("Всі спогади збережені"),
        "allPersonGroupingWillReset": MessageLookupByLibrary.simpleMessage(
            "Усі групи для цієї особи будуть скинуті, і ви втратите всі пропозиції, зроблені для неї"),
        "allow": MessageLookupByLibrary.simpleMessage("Дозволити"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Дозволити людям з посиланням також додавати фотографії до спільного альбому."),
        "allowAddingPhotos": MessageLookupByLibrary.simpleMessage(
            "Дозволити додавати фотографії"),
        "allowAppToOpenSharedAlbumLinks": MessageLookupByLibrary.simpleMessage(
            "Дозволити застосунку відкривати спільні альбоми"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("Дозволити завантаження"),
        "allowPeopleToAddPhotos": MessageLookupByLibrary.simpleMessage(
            "Дозволити людям додавати фотографії"),
        "allowPermBody": MessageLookupByLibrary.simpleMessage(
            "Надайте доступ до ваших фотографій з налаштувань, щоб Ente міг показувати та створювати резервну копію вашої бібліотеки."),
        "allowPermTitle": MessageLookupByLibrary.simpleMessage(
            "Дозволити доступ до фотографій"),
        "androidBiometricHint":
            MessageLookupByLibrary.simpleMessage("Підтвердження особистості"),
        "androidBiometricNotRecognized": MessageLookupByLibrary.simpleMessage(
            "Не розпізнано. Спробуйте ще раз."),
        "androidBiometricRequiredTitle":
            MessageLookupByLibrary.simpleMessage("Потрібна біометрія"),
        "androidBiometricSuccess":
            MessageLookupByLibrary.simpleMessage("Успішно"),
        "androidCancelButton":
            MessageLookupByLibrary.simpleMessage("Скасувати"),
        "androidDeviceCredentialsRequiredTitle":
            MessageLookupByLibrary.simpleMessage(
                "Необхідні облікові дані пристрою"),
        "androidDeviceCredentialsSetupDescription":
            MessageLookupByLibrary.simpleMessage(
                "Необхідні облікові дані пристрою"),
        "androidGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "Біометрична перевірка не встановлена на вашому пристрої. Перейдіть в «Налаштування > Безпека», щоб додати біометричну перевірку."),
        "androidIosWebDesktop":
            MessageLookupByLibrary.simpleMessage("Android, iOS, Вебсайт, ПК"),
        "androidSignInTitle":
            MessageLookupByLibrary.simpleMessage("Необхідна перевірка"),
        "appLock":
            MessageLookupByLibrary.simpleMessage("Блокування застосунку"),
        "appLockDescriptions": MessageLookupByLibrary.simpleMessage(
            "Виберіть між типовим екраном блокування вашого пристрою та власним екраном блокування з PIN-кодом або паролем."),
        "appVersion": m9,
        "appleId": MessageLookupByLibrary.simpleMessage("Apple ID"),
        "apply": MessageLookupByLibrary.simpleMessage("Застосувати"),
        "applyCodeTitle":
            MessageLookupByLibrary.simpleMessage("Застосувати код"),
        "appstoreSubscription":
            MessageLookupByLibrary.simpleMessage("Передплата App Store"),
        "archive": MessageLookupByLibrary.simpleMessage("Архів"),
        "archiveAlbum":
            MessageLookupByLibrary.simpleMessage("Архівувати альбом"),
        "archiving": MessageLookupByLibrary.simpleMessage("Архівуємо..."),
        "areYouSureThatYouWantToLeaveTheFamily":
            MessageLookupByLibrary.simpleMessage(
                "Ви впевнені, що хочете залишити сімейний план?"),
        "areYouSureYouWantToCancel":
            MessageLookupByLibrary.simpleMessage("Ви дійсно хочете скасувати?"),
        "areYouSureYouWantToChangeYourPlan":
            MessageLookupByLibrary.simpleMessage(
                "Ви впевнені, що хочете змінити свій план?"),
        "areYouSureYouWantToExit": MessageLookupByLibrary.simpleMessage(
            "Ви впевнені, що хочете вийти?"),
        "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
            "Ви впевнені, що хочете вийти з облікового запису?"),
        "areYouSureYouWantToRenew": MessageLookupByLibrary.simpleMessage(
            "Ви впевнені, що хочете поновити?"),
        "areYouSureYouWantToResetThisPerson":
            MessageLookupByLibrary.simpleMessage(
                "Ви впевнені, що хочете скинути цю особу?"),
        "askCancelReason": MessageLookupByLibrary.simpleMessage(
            "Передплату було скасовано. Ви хотіли б поділитися причиною?"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "Яка основна причина видалення вашого облікового запису?"),
        "askYourLovedOnesToShare": MessageLookupByLibrary.simpleMessage(
            "Попросіть своїх близьких поділитися"),
        "atAFalloutShelter":
            MessageLookupByLibrary.simpleMessage("в бомбосховищі"),
        "authToChangeEmailVerificationSetting":
            MessageLookupByLibrary.simpleMessage(
                "Авторизуйтесь, щоб змінити перевірку через пошту"),
        "authToChangeLockscreenSetting": MessageLookupByLibrary.simpleMessage(
            "Авторизуйтесь для зміни налаштувань екрана блокування"),
        "authToChangeYourEmail": MessageLookupByLibrary.simpleMessage(
            "Авторизуйтесь, щоб змінити поштову адресу"),
        "authToChangeYourPassword": MessageLookupByLibrary.simpleMessage(
            "Авторизуйтесь, щоб змінити пароль"),
        "authToConfigureTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Авторизуйтесь, щоб налаштувати двоетапну перевірку"),
        "authToInitiateAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Авторизуйтесь, щоби розпочати видалення облікового запису"),
        "authToManageLegacy": MessageLookupByLibrary.simpleMessage(
            "Авторизуйтесь, щоби керувати довіреними контактами"),
        "authToViewPasskey": MessageLookupByLibrary.simpleMessage(
            "Авторизуйтесь, щоб переглянути свій ключ доступу"),
        "authToViewYourActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Авторизуйтесь, щоб переглянути активні сеанси"),
        "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
            "Авторизуйтеся, щоб переглянути приховані файли"),
        "authToViewYourMemories": MessageLookupByLibrary.simpleMessage(
            "Авторизуйтеся, щоб переглянути ваші спогади"),
        "authToViewYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Авторизуйтесь для перегляду вашого ключа відновлення"),
        "authenticating":
            MessageLookupByLibrary.simpleMessage("Автентифікація..."),
        "authenticationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Автентифікація не пройдена. Спробуйте ще раз"),
        "authenticationSuccessful": MessageLookupByLibrary.simpleMessage(
            "Автентифікація пройшла успішно!"),
        "autoCastDialogBody": MessageLookupByLibrary.simpleMessage(
            "Тут ви побачите доступні пристрої для трансляції."),
        "autoCastiOSPermission": MessageLookupByLibrary.simpleMessage(
            "Переконайтеся, що для застосунку «Фотографії Ente» увімкнено дозволи локальної мережі в налаштуваннях."),
        "autoLock": MessageLookupByLibrary.simpleMessage("Автоблокування"),
        "autoLockFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "Час, через який застосунок буде заблоковано у фоновому режимі"),
        "autoLogoutMessage": MessageLookupByLibrary.simpleMessage(
            "Через технічні збої ви вийшли з системи. Перепрошуємо за незручності."),
        "autoPair":
            MessageLookupByLibrary.simpleMessage("Автоматичне створення пари"),
        "autoPairDesc": MessageLookupByLibrary.simpleMessage(
            "Автоматичне створення пари працює лише з пристроями, що підтримують Chromecast."),
        "available": MessageLookupByLibrary.simpleMessage("Доступно"),
        "availableStorageSpace": m10,
        "backedUpFolders":
            MessageLookupByLibrary.simpleMessage("Резервне копіювання тек"),
        "backup": MessageLookupByLibrary.simpleMessage("Резервне копіювання"),
        "backupFailed": MessageLookupByLibrary.simpleMessage(
            "Помилка резервного копіювання"),
        "backupFile":
            MessageLookupByLibrary.simpleMessage("Файл резервної копії"),
        "backupOverMobileData": MessageLookupByLibrary.simpleMessage(
            "Резервне копіювання через мобільні дані"),
        "backupSettings": MessageLookupByLibrary.simpleMessage(
            "Налаштування резервного копіювання"),
        "backupStatus":
            MessageLookupByLibrary.simpleMessage("Стан резервного копіювання"),
        "backupStatusDescription": MessageLookupByLibrary.simpleMessage(
            "Елементи, для яких було створено резервну копію, показуватимуться тут"),
        "backupVideos":
            MessageLookupByLibrary.simpleMessage("Резервне копіювання відео"),
        "birthday": MessageLookupByLibrary.simpleMessage("День народження"),
        "blackFridaySale": MessageLookupByLibrary.simpleMessage(
            "Розпродаж у «Чорну п\'ятницю»"),
        "blog": MessageLookupByLibrary.simpleMessage("Блог"),
        "cachedData": MessageLookupByLibrary.simpleMessage("Кешовані дані"),
        "calculating": MessageLookupByLibrary.simpleMessage("Обчислення..."),
        "canNotUploadToAlbumsOwnedByOthers":
            MessageLookupByLibrary.simpleMessage(
                "Не можна завантажувати в альбоми, які належать іншим"),
        "canOnlyCreateLinkForFilesOwnedByYou":
            MessageLookupByLibrary.simpleMessage(
                "Можна створити лише посилання для файлів, що належать вам"),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "Ви можете видалити лише файли, що належать вам"),
        "cancel": MessageLookupByLibrary.simpleMessage("Скасувати"),
        "cancelAccountRecovery":
            MessageLookupByLibrary.simpleMessage("Скасувати відновлення"),
        "cancelAccountRecoveryBody": MessageLookupByLibrary.simpleMessage(
            "Ви впевнені, що хочете скасувати відновлення?"),
        "cancelOtherSubscription": m12,
        "cancelSubscription":
            MessageLookupByLibrary.simpleMessage("Скасувати передплату"),
        "cannotAddMorePhotosAfterBecomingViewer": m13,
        "cannotDeleteSharedFiles": MessageLookupByLibrary.simpleMessage(
            "Не можна видалити спільні файли"),
        "castAlbum": MessageLookupByLibrary.simpleMessage("Транслювати альбом"),
        "castIPMismatchBody": MessageLookupByLibrary.simpleMessage(
            "Переконайтеся, що ви перебуваєте в тій же мережі, що і телевізор."),
        "castIPMismatchTitle": MessageLookupByLibrary.simpleMessage(
            "Не вдалося транслювати альбом"),
        "castInstruction": MessageLookupByLibrary.simpleMessage(
            "Відвідайте cast.ente.io на пристрої, з яким ви хочете створити пару.\n\nВведіть код нижче, щоб відтворити альбом на телевізорі."),
        "centerPoint": MessageLookupByLibrary.simpleMessage("Центральна точка"),
        "change": MessageLookupByLibrary.simpleMessage("Змінити"),
        "changeEmail":
            MessageLookupByLibrary.simpleMessage("Змінити адресу пошти"),
        "changeLocationOfSelectedItems": MessageLookupByLibrary.simpleMessage(
            "Змінити розташування вибраних елементів?"),
        "changePassword":
            MessageLookupByLibrary.simpleMessage("Змінити пароль"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Змінити пароль"),
        "changePermissions":
            MessageLookupByLibrary.simpleMessage("Змінити дозволи?"),
        "changeYourReferralCode":
            MessageLookupByLibrary.simpleMessage("Змінити ваш реферальний код"),
        "checkForUpdates": MessageLookupByLibrary.simpleMessage(
            "Перевiрити наявнiсть оновлень"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Перевірте вашу поштову скриньку (та спам), щоб завершити перевірку"),
        "checkStatus": MessageLookupByLibrary.simpleMessage("Перевірити стан"),
        "checking": MessageLookupByLibrary.simpleMessage("Перевірка..."),
        "checkingModels":
            MessageLookupByLibrary.simpleMessage("Перевірка моделей..."),
        "claimFreeStorage":
            MessageLookupByLibrary.simpleMessage("Отримайте безплатне сховище"),
        "claimMore": MessageLookupByLibrary.simpleMessage("Отримайте більше!"),
        "claimed": MessageLookupByLibrary.simpleMessage("Отримано"),
        "claimedStorageSoFar": m14,
        "cleanUncategorized":
            MessageLookupByLibrary.simpleMessage("Очистити «Без категорії»"),
        "cleanUncategorizedDescription": MessageLookupByLibrary.simpleMessage(
            "Видалити всі файли з «Без категорії», що є в інших альбомах"),
        "clearCaches": MessageLookupByLibrary.simpleMessage("Очистити кеш"),
        "clearIndexes":
            MessageLookupByLibrary.simpleMessage("Очистити індекси"),
        "click": MessageLookupByLibrary.simpleMessage("• Натисніть"),
        "clickOnTheOverflowMenu": MessageLookupByLibrary.simpleMessage(
            "• Натисніть на меню переповнення"),
        "close": MessageLookupByLibrary.simpleMessage("Закрити"),
        "clubByCaptureTime":
            MessageLookupByLibrary.simpleMessage("Клуб за часом захоплення"),
        "clubByFileName":
            MessageLookupByLibrary.simpleMessage("Клуб за назвою файлу"),
        "clusteringProgress":
            MessageLookupByLibrary.simpleMessage("Прогрес кластеризації"),
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("Код застосовано"),
        "codeChangeLimitReached": MessageLookupByLibrary.simpleMessage(
            "На жаль, ви досягли ліміту змін коду."),
        "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Код скопійовано до буфера обміну"),
        "codeUsedByYou":
            MessageLookupByLibrary.simpleMessage("Код використано вами"),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Створіть посилання, щоб дозволити людям додавати й переглядати фотографії у вашому спільному альбомі без використання застосунку Ente або облікового запису. Чудово підходить для збору фотографій з подій."),
        "collaborativeLink":
            MessageLookupByLibrary.simpleMessage("Спільне посилання"),
        "collaborativeLinkCreatedFor": m15,
        "collaborator": MessageLookupByLibrary.simpleMessage("Співавтор"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Співавтори можуть додавати фотографії та відео до спільного альбому."),
        "collageLayout": MessageLookupByLibrary.simpleMessage("Макет"),
        "collageSaved":
            MessageLookupByLibrary.simpleMessage("Колаж збережено до галереї"),
        "collect": MessageLookupByLibrary.simpleMessage("Зібрати"),
        "collectEventPhotos":
            MessageLookupByLibrary.simpleMessage("Зібрати фотографії події"),
        "collectPhotos":
            MessageLookupByLibrary.simpleMessage("Зібрати фотографії"),
        "collectPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Створіть посилання, за яким ваші друзі зможуть завантажувати фотографії в оригінальній якості."),
        "color": MessageLookupByLibrary.simpleMessage("Колір"),
        "configuration": MessageLookupByLibrary.simpleMessage("Налаштування"),
        "confirm": MessageLookupByLibrary.simpleMessage("Підтвердити"),
        "confirm2FADisable": MessageLookupByLibrary.simpleMessage(
            "Ви впевнені, що хочете вимкнути двоетапну перевірку?"),
        "confirmAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Підтвердьте видалення облікового запису"),
        "confirmAddingTrustedContact": m17,
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Так, я хочу безповоротно видалити цей обліковий запис та його дані з усіх застосунків."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Підтвердити пароль"),
        "confirmPlanChange":
            MessageLookupByLibrary.simpleMessage("Підтвердити зміну плану"),
        "confirmRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Підтвердити ключ відновлення"),
        "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Підтвердіть ваш ключ відновлення"),
        "connectToDevice":
            MessageLookupByLibrary.simpleMessage("Під\'єднатися до пристрою"),
        "contactFamilyAdmin": m18,
        "contactSupport": MessageLookupByLibrary.simpleMessage(
            "Звернутися до служби підтримки"),
        "contactToManageSubscription": m19,
        "contacts": MessageLookupByLibrary.simpleMessage("Контакти"),
        "contents": MessageLookupByLibrary.simpleMessage("Вміст"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("Продовжити"),
        "continueOnFreeTrial": MessageLookupByLibrary.simpleMessage(
            "Продовжити безплатний пробний період"),
        "convertToAlbum":
            MessageLookupByLibrary.simpleMessage("Перетворити в альбом"),
        "copyEmailAddress":
            MessageLookupByLibrary.simpleMessage("Копіювати поштову адресу"),
        "copyLink": MessageLookupByLibrary.simpleMessage("Копіювати посилання"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Скопіюйте цей код\nу ваш застосунок для автентифікації"),
        "couldNotBackUpTryLater": MessageLookupByLibrary.simpleMessage(
            "Не вдалося створити резервну копію даних.\nМи спробуємо пізніше."),
        "couldNotFreeUpSpace":
            MessageLookupByLibrary.simpleMessage("Не вдалося звільнити місце"),
        "couldNotUpdateSubscription": MessageLookupByLibrary.simpleMessage(
            "Не вдалося оновити передплату"),
        "count": MessageLookupByLibrary.simpleMessage("Кількість"),
        "crashReporting":
            MessageLookupByLibrary.simpleMessage("Звіти про помилки"),
        "create": MessageLookupByLibrary.simpleMessage("Створити"),
        "createAccount":
            MessageLookupByLibrary.simpleMessage("Створити обліковий запис"),
        "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
            "Утримуйте, щоби вибрати фотографії, та натисніть «+», щоб створити альбом"),
        "createCollaborativeLink":
            MessageLookupByLibrary.simpleMessage("Створити спільне посилання"),
        "createCollage": MessageLookupByLibrary.simpleMessage("Створити колаж"),
        "createNewAccount": MessageLookupByLibrary.simpleMessage(
            "Створити новий обліковий запис"),
        "createOrSelectAlbum":
            MessageLookupByLibrary.simpleMessage("Створити або вибрати альбом"),
        "createPublicLink":
            MessageLookupByLibrary.simpleMessage("Створити публічне посилання"),
        "creatingLink":
            MessageLookupByLibrary.simpleMessage("Створення посилання..."),
        "criticalUpdateAvailable":
            MessageLookupByLibrary.simpleMessage("Доступне важливе оновлення"),
        "crop": MessageLookupByLibrary.simpleMessage("Обрізати"),
        "currentUsageIs":
            MessageLookupByLibrary.simpleMessage("Поточне використання "),
        "currentlyRunning":
            MessageLookupByLibrary.simpleMessage("зараз працює"),
        "custom": MessageLookupByLibrary.simpleMessage("Власне"),
        "customEndpoint": m20,
        "darkTheme": MessageLookupByLibrary.simpleMessage("Темна"),
        "dayToday": MessageLookupByLibrary.simpleMessage("Сьогодні"),
        "dayYesterday": MessageLookupByLibrary.simpleMessage("Вчора"),
        "declineTrustInvite":
            MessageLookupByLibrary.simpleMessage("Відхилити запрошення"),
        "decrypting": MessageLookupByLibrary.simpleMessage("Дешифрування..."),
        "decryptingVideo":
            MessageLookupByLibrary.simpleMessage("Розшифрування відео..."),
        "deduplicateFiles":
            MessageLookupByLibrary.simpleMessage("Усунути дублікати файлів"),
        "delete": MessageLookupByLibrary.simpleMessage("Видалити"),
        "deleteAccount":
            MessageLookupByLibrary.simpleMessage("Видалити обліковий запис"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "Нам шкода, що ви йдете. Будь ласка, поділіться своїм відгуком, щоб допомогти нам покращитися."),
        "deleteAccountPermanentlyButton": MessageLookupByLibrary.simpleMessage(
            "Остаточно видалити обліковий запис"),
        "deleteAlbum": MessageLookupByLibrary.simpleMessage("Видалити альбом"),
        "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
            "Також видалити фотографії (і відео), які є в цьому альбомі, зі <bold>всіх</bold> інших альбомів, з яких вони складаються?"),
        "deleteAlbumsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Це призведе до видалення всіх пустих альбомів. Це зручно, коли ви бажаєте зменшити засмічення в списку альбомів."),
        "deleteAll": MessageLookupByLibrary.simpleMessage("Видалити все"),
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
            "Цей обліковий запис пов\'язаний з іншими застосунками Ente, якщо ви ними користуєтесь. Завантажені вами дані з усіх застосунків Ente будуть заплановані до видалення, а ваш обліковий запис буде видалено назавжди."),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "Будь ласка, надішліть електронного листа на <warning>account-deletion@ente.io</warning> зі скриньки, зазначеної при реєстрації."),
        "deleteEmptyAlbums":
            MessageLookupByLibrary.simpleMessage("Видалити пусті альбоми"),
        "deleteEmptyAlbumsWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Видалити пусті альбоми?"),
        "deleteFromBoth":
            MessageLookupByLibrary.simpleMessage("Видалити з обох"),
        "deleteFromDevice":
            MessageLookupByLibrary.simpleMessage("Видалити з пристрою"),
        "deleteFromEnte":
            MessageLookupByLibrary.simpleMessage("Видалити з Ente"),
        "deleteItemCount": m21,
        "deleteLocation":
            MessageLookupByLibrary.simpleMessage("Видалити розташування"),
        "deletePhotos": MessageLookupByLibrary.simpleMessage("Видалити фото"),
        "deleteProgress": m23,
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "Мені бракує ключової функції"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "Застосунок або певна функція не поводяться так, як я думаю, вони повинні"),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
            "Я знайшов інший сервіс, який подобається мені більше"),
        "deleteReason4":
            MessageLookupByLibrary.simpleMessage("Причина не перерахована"),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
            "Ваш запит буде оброблений протягом 72 годин."),
        "deleteSharedAlbum":
            MessageLookupByLibrary.simpleMessage("Видалити спільний альбом?"),
        "deleteSharedAlbumDialogBody": MessageLookupByLibrary.simpleMessage(
            "Альбом буде видалено для всіх\n\nВи втратите доступ до спільних фотографій у цьому альбомі, які належать іншим"),
        "deselectAll": MessageLookupByLibrary.simpleMessage("Зняти виділення"),
        "designedToOutlive":
            MessageLookupByLibrary.simpleMessage("Створено, щоб пережити вас"),
        "details": MessageLookupByLibrary.simpleMessage("Подробиці"),
        "developerSettings": MessageLookupByLibrary.simpleMessage(
            "Налаштування для розробників"),
        "developerSettingsWarning": MessageLookupByLibrary.simpleMessage(
            "Ви впевнені, що хочете змінити налаштування для розробників?"),
        "deviceCodeHint": MessageLookupByLibrary.simpleMessage("Введіть код"),
        "deviceFilesAutoUploading": MessageLookupByLibrary.simpleMessage(
            "Файли, додані до цього альбому на пристрої, автоматично завантажаться до Ente."),
        "deviceLock":
            MessageLookupByLibrary.simpleMessage("Блокування пристрою"),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
            "Вимкніть блокування екрана пристрою, коли на передньому плані знаходиться Ente і виконується резервне копіювання. Зазвичай це не потрібно, але може допомогти швидше завершити великі вивантаження і початковий імпорт великих бібліотек."),
        "deviceNotFound":
            MessageLookupByLibrary.simpleMessage("Пристрій не знайдено"),
        "didYouKnow": MessageLookupByLibrary.simpleMessage("Чи знали ви?"),
        "disableAutoLock":
            MessageLookupByLibrary.simpleMessage("Вимкнути автоблокування"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Переглядачі все ще можуть робити знімки екрана або зберігати копію ваших фотографій за допомогою зовнішніх інструментів"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Зверніть увагу"),
        "disableLinkMessage": m24,
        "disableTwofactor": MessageLookupByLibrary.simpleMessage(
            "Вимкнути двоетапну перевірку"),
        "disablingTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Вимкнення двоетапної перевірки..."),
        "discord": MessageLookupByLibrary.simpleMessage("Discord"),
        "discover": MessageLookupByLibrary.simpleMessage("Відкрийте для себе"),
        "discover_babies": MessageLookupByLibrary.simpleMessage("Немовлята"),
        "discover_celebrations":
            MessageLookupByLibrary.simpleMessage("Святкування"),
        "discover_food": MessageLookupByLibrary.simpleMessage("Їжа"),
        "discover_greenery": MessageLookupByLibrary.simpleMessage("Зелень"),
        "discover_hills": MessageLookupByLibrary.simpleMessage("Пагорби"),
        "discover_identity":
            MessageLookupByLibrary.simpleMessage("Особистість"),
        "discover_memes": MessageLookupByLibrary.simpleMessage("Меми"),
        "discover_notes": MessageLookupByLibrary.simpleMessage("Нотатки"),
        "discover_pets":
            MessageLookupByLibrary.simpleMessage("Домашні тварини"),
        "discover_receipts": MessageLookupByLibrary.simpleMessage("Квитанції"),
        "discover_screenshots":
            MessageLookupByLibrary.simpleMessage("Знімки екрана"),
        "discover_selfies": MessageLookupByLibrary.simpleMessage("Селфі"),
        "discover_sunset": MessageLookupByLibrary.simpleMessage("Захід сонця"),
        "discover_visiting_cards":
            MessageLookupByLibrary.simpleMessage("Візитівки"),
        "discover_wallpapers": MessageLookupByLibrary.simpleMessage("Шпалери"),
        "dismiss": MessageLookupByLibrary.simpleMessage("Відхилити"),
        "distanceInKMUnit": MessageLookupByLibrary.simpleMessage("км"),
        "doNotSignOut": MessageLookupByLibrary.simpleMessage("Не виходити"),
        "doThisLater":
            MessageLookupByLibrary.simpleMessage("Зробити це пізніше"),
        "doYouWantToDiscardTheEditsYouHaveMade":
            MessageLookupByLibrary.simpleMessage(
                "Ви хочете відхилити внесені зміни?"),
        "done": MessageLookupByLibrary.simpleMessage("Готово"),
        "doubleYourStorage":
            MessageLookupByLibrary.simpleMessage("Подвоїти своє сховище"),
        "download": MessageLookupByLibrary.simpleMessage("Завантажити"),
        "downloadFailed":
            MessageLookupByLibrary.simpleMessage("Не вдалося завантажити"),
        "downloading": MessageLookupByLibrary.simpleMessage("Завантаження..."),
        "dropSupportEmail": m25,
        "duplicateFileCountWithStorageSaved": m26,
        "duplicateItemsGroup": m27,
        "edit": MessageLookupByLibrary.simpleMessage("Редагувати"),
        "editLocation":
            MessageLookupByLibrary.simpleMessage("Змінити розташування"),
        "editLocationTagTitle":
            MessageLookupByLibrary.simpleMessage("Змінити розташування"),
        "editPerson": MessageLookupByLibrary.simpleMessage("Редагувати особу"),
        "editsSaved": MessageLookupByLibrary.simpleMessage("Зміни збережено"),
        "editsToLocationWillOnlyBeSeenWithinEnte":
            MessageLookupByLibrary.simpleMessage(
                "Зміна розташування буде видима лише в Ente"),
        "eligible": MessageLookupByLibrary.simpleMessage("придатний"),
        "email":
            MessageLookupByLibrary.simpleMessage("Адреса електронної пошти"),
        "emailChangedTo": m29,
        "emailNoEnteAccount": m31,
        "emailVerificationToggle":
            MessageLookupByLibrary.simpleMessage("Підтвердження через пошту"),
        "emailYourLogs": MessageLookupByLibrary.simpleMessage(
            "Відправте ваші журнали поштою"),
        "emergencyContacts":
            MessageLookupByLibrary.simpleMessage("Екстрені контакти"),
        "empty": MessageLookupByLibrary.simpleMessage("Спорожнити"),
        "emptyTrash": MessageLookupByLibrary.simpleMessage("Очистити смітник?"),
        "enable": MessageLookupByLibrary.simpleMessage("Увімкнути"),
        "enableMLIndexingDesc": MessageLookupByLibrary.simpleMessage(
            "Ente підтримує машинне навчання для розпізнавання обличчя, магічний пошук та інші розширені функції пошуку"),
        "enableMachineLearningBanner": MessageLookupByLibrary.simpleMessage(
            "Увімкніть машинне навчання для магічного пошуку та розпізнавання облич"),
        "enableMaps": MessageLookupByLibrary.simpleMessage("Увімкнути мапи"),
        "enableMapsDesc": MessageLookupByLibrary.simpleMessage(
            "Це покаже ваші фотографії на мапі світу.\n\nЦя мапа розміщена на OpenStreetMap, і точне розташування ваших фотографій ніколи не розголошується.\n\nВи можете будь-коли вимкнути цю функцію в налаштуваннях."),
        "enabled": MessageLookupByLibrary.simpleMessage("Увімкнено"),
        "encryptingBackup":
            MessageLookupByLibrary.simpleMessage("Шифруємо резервну копію..."),
        "encryption": MessageLookupByLibrary.simpleMessage("Шифрування"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Ключі шифрування"),
        "endpointUpdatedMessage": MessageLookupByLibrary.simpleMessage(
            "Кінцева точка успішно оновлена"),
        "endtoendEncryptedByDefault": MessageLookupByLibrary.simpleMessage(
            "Наскрізне шифрування по стандарту"),
        "enteCanEncryptAndPreserveFilesOnlyIfYouGrant":
            MessageLookupByLibrary.simpleMessage(
                "Ente може зашифрувати та зберігати файли тільки в тому випадку, якщо ви надасте до них доступ"),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
            "Ente <i>потребує дозволу</i> до ваших світлин"),
        "enteSubscriptionPitch": MessageLookupByLibrary.simpleMessage(
            "Ente зберігає ваші спогади, тому вони завжди доступні для вас, навіть якщо ви втратите пристрій."),
        "enteSubscriptionShareWithFamily": MessageLookupByLibrary.simpleMessage(
            "Вашу сім\'ю також можна додати до вашого тарифу."),
        "enterAlbumName":
            MessageLookupByLibrary.simpleMessage("Введіть назву альбому"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Введіть код"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
            "Введіть код, наданий вашим другом, щоби отримати безплатне сховище для вас обох"),
        "enterDateOfBirth": MessageLookupByLibrary.simpleMessage(
            "День народження (необов\'язково)"),
        "enterEmail":
            MessageLookupByLibrary.simpleMessage("Введіть поштову адресу"),
        "enterFileName":
            MessageLookupByLibrary.simpleMessage("Введіть назву файлу"),
        "enterName": MessageLookupByLibrary.simpleMessage("Введіть ім\'я"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Введіть новий пароль, який ми зможемо використати для шифрування ваших даних"),
        "enterPassword": MessageLookupByLibrary.simpleMessage("Введіть пароль"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Введіть пароль, який ми зможемо використати для шифрування ваших даних"),
        "enterPersonName":
            MessageLookupByLibrary.simpleMessage("Введіть ім\'я особи"),
        "enterPin": MessageLookupByLibrary.simpleMessage("Введіть PIN-код"),
        "enterReferralCode":
            MessageLookupByLibrary.simpleMessage("Введіть реферальний код"),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Введіть 6-значний код з\nвашого застосунку для автентифікації"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "Будь ласка, введіть дійсну адресу електронної пошти."),
        "enterYourEmailAddress": MessageLookupByLibrary.simpleMessage(
            "Введіть вашу адресу електронної пошти"),
        "enterYourPassword":
            MessageLookupByLibrary.simpleMessage("Введіть пароль"),
        "enterYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Введіть ваш ключ відновлення"),
        "error": MessageLookupByLibrary.simpleMessage("Помилка"),
        "everywhere": MessageLookupByLibrary.simpleMessage("всюди"),
        "exif": MessageLookupByLibrary.simpleMessage("EXIF"),
        "existingUser":
            MessageLookupByLibrary.simpleMessage("Існуючий користувач"),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
            "Термін дії цього посилання минув. Будь ласка, виберіть новий час терміну дії або вимкніть це посилання."),
        "exportLogs":
            MessageLookupByLibrary.simpleMessage("Експортування журналів"),
        "exportYourData":
            MessageLookupByLibrary.simpleMessage("Експортувати дані"),
        "extraPhotosFound": MessageLookupByLibrary.simpleMessage(
            "Знайдено додаткові фотографії"),
        "extraPhotosFoundFor": m33,
        "faceNotClusteredYet": MessageLookupByLibrary.simpleMessage(
            "Обличчя ще не згруповані, поверніться пізніше"),
        "faceRecognition":
            MessageLookupByLibrary.simpleMessage("Розпізнавання обличчя"),
        "faces": MessageLookupByLibrary.simpleMessage("Обличчя"),
        "failedToApplyCode":
            MessageLookupByLibrary.simpleMessage("Не вдалося застосувати код"),
        "failedToCancel":
            MessageLookupByLibrary.simpleMessage("Не вдалося скасувати"),
        "failedToDownloadVideo": MessageLookupByLibrary.simpleMessage(
            "Не вдалося завантажити відео"),
        "failedToFetchActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Не вдалося отримати активні сеанси"),
        "failedToFetchOriginalForEdit": MessageLookupByLibrary.simpleMessage(
            "Не вдалося отримати оригінал для редагування"),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "Не вдається отримати відомості про реферала. Спробуйте ще раз пізніше."),
        "failedToLoadAlbums": MessageLookupByLibrary.simpleMessage(
            "Не вдалося завантажити альбоми"),
        "failedToPlayVideo":
            MessageLookupByLibrary.simpleMessage("Не вдалося відтворити відео"),
        "failedToRefreshStripeSubscription":
            MessageLookupByLibrary.simpleMessage(
                "Не вдалося поновити підписку"),
        "failedToRenew":
            MessageLookupByLibrary.simpleMessage("Не вдалося поновити"),
        "failedToVerifyPaymentStatus": MessageLookupByLibrary.simpleMessage(
            "Не вдалося перевірити стан платежу"),
        "familyPlanOverview": MessageLookupByLibrary.simpleMessage(
            "Додайте 5 членів сім\'ї до чинного тарифу без додаткової плати.\n\nКожен член сім\'ї отримає власний приватний простір і не зможе бачити файли інших, доки обидва не нададуть до них спільний доступ.\n\nСімейні плани доступні клієнтам, які мають платну підписку на Ente.\n\nПідпишіться зараз, щоби розпочати!"),
        "familyPlanPortalTitle": MessageLookupByLibrary.simpleMessage("Сім\'я"),
        "familyPlans": MessageLookupByLibrary.simpleMessage("Сімейні тарифи"),
        "faq": MessageLookupByLibrary.simpleMessage("ЧаПи"),
        "faqs": MessageLookupByLibrary.simpleMessage("ЧаПи"),
        "favorite":
            MessageLookupByLibrary.simpleMessage("Додати до улюбленого"),
        "feedback": MessageLookupByLibrary.simpleMessage("Зворотній зв’язок"),
        "file": MessageLookupByLibrary.simpleMessage("Файл"),
        "fileFailedToSaveToGallery": MessageLookupByLibrary.simpleMessage(
            "Не вдалося зберегти файл до галереї"),
        "fileInfoAddDescHint":
            MessageLookupByLibrary.simpleMessage("Додати опис..."),
        "fileNotUploadedYet":
            MessageLookupByLibrary.simpleMessage("Файл ще не завантажено"),
        "fileSavedToGallery":
            MessageLookupByLibrary.simpleMessage("Файл збережено до галереї"),
        "fileTypes": MessageLookupByLibrary.simpleMessage("Типи файлів"),
        "fileTypesAndNames":
            MessageLookupByLibrary.simpleMessage("Типи та назви файлів"),
        "filesBackedUpFromDevice": m35,
        "filesBackedUpInAlbum": m36,
        "filesDeleted": MessageLookupByLibrary.simpleMessage("Файли видалено"),
        "filesSavedToGallery":
            MessageLookupByLibrary.simpleMessage("Файли збережено до галереї"),
        "findPeopleByName": MessageLookupByLibrary.simpleMessage(
            "Швидко знаходьте людей за іменами"),
        "findThemQuickly":
            MessageLookupByLibrary.simpleMessage("Знайдіть їх швидко"),
        "flip": MessageLookupByLibrary.simpleMessage("Відзеркалити"),
        "forYourMemories":
            MessageLookupByLibrary.simpleMessage("для ваших спогадів"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Нагадати пароль"),
        "foundFaces": MessageLookupByLibrary.simpleMessage("Знайдені обличчя"),
        "freeStorageClaimed":
            MessageLookupByLibrary.simpleMessage("Безплатне сховище отримано"),
        "freeStorageOnReferralSuccess": m37,
        "freeStorageUsable": MessageLookupByLibrary.simpleMessage(
            "Безплатне сховище можна використовувати"),
        "freeTrial":
            MessageLookupByLibrary.simpleMessage("Безплатний пробний період"),
        "freeTrialValidTill": m38,
        "freeUpAmount": m40,
        "freeUpDeviceSpace":
            MessageLookupByLibrary.simpleMessage("Звільніть місце на пристрої"),
        "freeUpDeviceSpaceDesc": MessageLookupByLibrary.simpleMessage(
            "Збережіть місце на вашому пристрої, очистивши файли, які вже збережено."),
        "freeUpSpace": MessageLookupByLibrary.simpleMessage("Звільнити місце"),
        "galleryMemoryLimitInfo": MessageLookupByLibrary.simpleMessage(
            "До 1000 спогадів, показаних у галереї"),
        "general": MessageLookupByLibrary.simpleMessage("Загальні"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Створення ключів шифрування..."),
        "genericProgress": m42,
        "goToSettings":
            MessageLookupByLibrary.simpleMessage("Перейти до налаштувань"),
        "googlePlayId": MessageLookupByLibrary.simpleMessage("Google Play ID"),
        "grantFullAccessPrompt": MessageLookupByLibrary.simpleMessage(
            "Надайте доступ до всіх фотографій в налаштуваннях застосунку"),
        "grantPermission":
            MessageLookupByLibrary.simpleMessage("Надати дозвіл"),
        "groupNearbyPhotos": MessageLookupByLibrary.simpleMessage(
            "Групувати фотографії поблизу"),
        "guestView": MessageLookupByLibrary.simpleMessage("Гостьовий перегляд"),
        "guestViewEnablePreSteps": MessageLookupByLibrary.simpleMessage(
            "Щоб увімкнути гостьовий перегляд, встановіть пароль або блокування екрана в налаштуваннях системи."),
        "hearUsExplanation": MessageLookupByLibrary.simpleMessage(
            "Ми не відстежуємо встановлення застосунку. Але, якщо ви скажете нам, де ви нас знайшли, це допоможе!"),
        "hearUsWhereTitle": MessageLookupByLibrary.simpleMessage(
            "Як ви дізналися про Ente? (необов\'язково)"),
        "help": MessageLookupByLibrary.simpleMessage("Допомога"),
        "hidden": MessageLookupByLibrary.simpleMessage("Приховано"),
        "hide": MessageLookupByLibrary.simpleMessage("Приховати"),
        "hideContent": MessageLookupByLibrary.simpleMessage("Приховати вміст"),
        "hideContentDescriptionAndroid": MessageLookupByLibrary.simpleMessage(
            "Приховує вміст застосунку у перемикачі застосунків і вимикає знімки екрана"),
        "hideContentDescriptionIos": MessageLookupByLibrary.simpleMessage(
            "Приховує вміст застосунку у перемикачі застосунків"),
        "hiding": MessageLookupByLibrary.simpleMessage("Приховуємо..."),
        "hostedAtOsmFrance":
            MessageLookupByLibrary.simpleMessage("Розміщення на OSM Франція"),
        "howItWorks": MessageLookupByLibrary.simpleMessage("Як це працює"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "Попросіть їх довго утримувати палець на свій поштовій адресі на екрані налаштувань і переконайтеся, що ідентифікатори на обох пристроях збігаються."),
        "iOSGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "Біометрична перевірка не встановлена на вашому пристрої. Увімкніть TouchID або FaceID на вашому телефоні."),
        "iOSLockOut": MessageLookupByLibrary.simpleMessage(
            "Біометрична перевірка вимкнена. Заблокуйте і розблокуйте свій екран, щоб увімкнути її."),
        "iOSOkButton": MessageLookupByLibrary.simpleMessage("Гаразд"),
        "ignoreUpdate": MessageLookupByLibrary.simpleMessage("Ігнорувати"),
        "ignored": MessageLookupByLibrary.simpleMessage("ігнорується"),
        "ignoredFolderUploadReason": MessageLookupByLibrary.simpleMessage(
            "Деякі файли в цьому альбомі ігноруються після вивантаження, тому що вони раніше були видалені з Ente."),
        "imageNotAnalyzed": MessageLookupByLibrary.simpleMessage(
            "Зображення не проаналізовано"),
        "immediately": MessageLookupByLibrary.simpleMessage("Негайно"),
        "importing": MessageLookupByLibrary.simpleMessage("Імпортування..."),
        "incorrectCode": MessageLookupByLibrary.simpleMessage("Невірний код"),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Невірний пароль"),
        "incorrectRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Невірний ключ відновлення"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "Ви ввели невірний ключ відновлення"),
        "incorrectRecoveryKeyTitle":
            MessageLookupByLibrary.simpleMessage("Невірний ключ відновлення"),
        "indexedItems":
            MessageLookupByLibrary.simpleMessage("Індексовані елементи"),
        "indexingIsPaused": MessageLookupByLibrary.simpleMessage(
            "Індексація припинена. Автоматично продовжуватиметься, коли пристрій буде готовий."),
        "info": MessageLookupByLibrary.simpleMessage("Інформація"),
        "insecureDevice":
            MessageLookupByLibrary.simpleMessage("Незахищений пристрій"),
        "installManually":
            MessageLookupByLibrary.simpleMessage("Встановити вручну"),
        "invalidEmailAddress": MessageLookupByLibrary.simpleMessage(
            "Хибна адреса електронної пошти"),
        "invalidEndpoint":
            MessageLookupByLibrary.simpleMessage("Недійсна кінцева точка"),
        "invalidEndpointMessage": MessageLookupByLibrary.simpleMessage(
            "Введена вами кінцева точка є недійсною. Введіть дійсну кінцеву точку та спробуйте ще раз."),
        "invalidKey": MessageLookupByLibrary.simpleMessage("Невірний ключ"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Уведений вами ключ відновлення недійсний. Переконайтеся, що він містить 24 слова, і перевірте правильність написання кожного з них.\n\nЯкщо ви ввели старіший код відновлення, переконайтеся, що він складається з 64 символів, і перевірте кожен з них."),
        "invite": MessageLookupByLibrary.simpleMessage("Запросити"),
        "inviteToEnte":
            MessageLookupByLibrary.simpleMessage("Запросити до Ente"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Запросити своїх друзів"),
        "inviteYourFriendsToEnte": MessageLookupByLibrary.simpleMessage(
            "Запросіть своїх друзів до Ente"),
        "itLooksLikeSomethingWentWrongPleaseRetryAfterSome":
            MessageLookupByLibrary.simpleMessage(
                "Схоже, що щось пішло не так. Спробуйте ще раз через деякий час. Якщо помилка не зникне, зв\'яжіться з нашою командою підтримки."),
        "itemCount": m44,
        "itemsShowTheNumberOfDaysRemainingBeforePermanentDeletion":
            MessageLookupByLibrary.simpleMessage(
                "Елементи показують кількість днів, що залишилися до остаточного видалення"),
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "Вибрані елементи будуть видалені з цього альбому"),
        "joinDiscord": MessageLookupByLibrary.simpleMessage(
            "Приєднатися до Discord серверу"),
        "keepPhotos": MessageLookupByLibrary.simpleMessage("Залишити фото"),
        "kiloMeterUnit": MessageLookupByLibrary.simpleMessage("км"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Будь ласка, допоможіть нам із цією інформацією"),
        "language": MessageLookupByLibrary.simpleMessage("Мова"),
        "lastUpdated":
            MessageLookupByLibrary.simpleMessage("Востаннє оновлено"),
        "leave": MessageLookupByLibrary.simpleMessage("Покинути"),
        "leaveAlbum": MessageLookupByLibrary.simpleMessage("Покинути альбом"),
        "leaveFamily": MessageLookupByLibrary.simpleMessage("Покинути сім\'ю"),
        "leaveSharedAlbum":
            MessageLookupByLibrary.simpleMessage("Покинути спільний альбом?"),
        "left": MessageLookupByLibrary.simpleMessage("Ліворуч"),
        "legacy": MessageLookupByLibrary.simpleMessage("Спадок"),
        "legacyAccounts":
            MessageLookupByLibrary.simpleMessage("Облікові записи «Спадку»"),
        "legacyInvite": m46,
        "legacyPageDesc": MessageLookupByLibrary.simpleMessage(
            "«Спадок» дозволяє довіреним контактам отримати доступ до вашого облікового запису під час вашої відсутності."),
        "legacyPageDesc2": MessageLookupByLibrary.simpleMessage(
            "Довірені контакти можуть ініціювати відновлення облікового запису, і якщо його не буде заблоковано протягом 30 днів, скинути пароль і отримати доступ до нього."),
        "light": MessageLookupByLibrary.simpleMessage("Яскравість"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("Світла"),
        "linkCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Посилання скопійовано в буфер обміну"),
        "linkDeviceLimit":
            MessageLookupByLibrary.simpleMessage("Досягнуто ліміту пристроїв"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Увімкнено"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Закінчився"),
        "linkExpiresOn": m47,
        "linkExpiry": MessageLookupByLibrary.simpleMessage(
            "Термін дії посилання закінчився"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("Посилання прострочено"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Ніколи"),
        "livePhotos": MessageLookupByLibrary.simpleMessage("Живі фото"),
        "loadMessage1": MessageLookupByLibrary.simpleMessage(
            "Ви можете поділитися своєю передплатою з родиною"),
        "loadMessage3": MessageLookupByLibrary.simpleMessage(
            "Ми зберігаємо 3 копії ваших даних, одну в підземному бункері"),
        "loadMessage4": MessageLookupByLibrary.simpleMessage(
            "Всі наші застосунки мають відкритий код"),
        "loadMessage5": MessageLookupByLibrary.simpleMessage(
            "Наш вихідний код та шифрування пройшли перевірку спільнотою"),
        "loadMessage6": MessageLookupByLibrary.simpleMessage(
            "Ви можете поділитися посиланнями на свої альбоми з близькими"),
        "loadMessage7": MessageLookupByLibrary.simpleMessage(
            "Наші мобільні застосунки працюють у фоновому режимі для шифрування і створення резервних копій будь-яких нових фотографій, які ви виберете"),
        "loadMessage8": MessageLookupByLibrary.simpleMessage(
            "web.ente.io має зручний завантажувач"),
        "loadMessage9": MessageLookupByLibrary.simpleMessage(
            "Ми використовуємо Xchacha20Poly1305 для безпечного шифрування ваших даних"),
        "loadingExifData":
            MessageLookupByLibrary.simpleMessage("Завантаження даних EXIF..."),
        "loadingGallery":
            MessageLookupByLibrary.simpleMessage("Завантаження галереї..."),
        "loadingMessage": MessageLookupByLibrary.simpleMessage(
            "Завантажуємо ваші фотографії..."),
        "loadingModel":
            MessageLookupByLibrary.simpleMessage("Завантаження моделей..."),
        "loadingYourPhotos":
            MessageLookupByLibrary.simpleMessage("Завантажуємо фотографії..."),
        "localGallery":
            MessageLookupByLibrary.simpleMessage("Локальна галерея"),
        "localIndexing":
            MessageLookupByLibrary.simpleMessage("Локальне індексування"),
        "localSyncErrorMessage": MessageLookupByLibrary.simpleMessage(
            "Схоже, щось пішло не так, оскільки локальна синхронізація фотографій займає більше часу, ніж очікувалося. Зверніться до нашої служби підтримки"),
        "location": MessageLookupByLibrary.simpleMessage("Розташування"),
        "locationName":
            MessageLookupByLibrary.simpleMessage("Назва місце розташування"),
        "locationTagFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "Тег розташування групує всі фотографії, які були зроблені в певному радіусі від фотографії"),
        "locations": MessageLookupByLibrary.simpleMessage("Розташування"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Заблокувати"),
        "lockscreen": MessageLookupByLibrary.simpleMessage("Екран блокування"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Увійти"),
        "loggingOut":
            MessageLookupByLibrary.simpleMessage("Вихід із системи..."),
        "loginSessionExpired":
            MessageLookupByLibrary.simpleMessage("Час сеансу минув"),
        "loginSessionExpiredDetails": MessageLookupByLibrary.simpleMessage(
            "Термін дії вашого сеансу завершився. Увійдіть знову."),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "Натискаючи «Увійти», я приймаю <u-terms>умови використання</u-terms> і <u-policy>політику приватності</u-policy>"),
        "loginWithTOTP":
            MessageLookupByLibrary.simpleMessage("Увійти за допомогою TOTP"),
        "logout": MessageLookupByLibrary.simpleMessage("Вийти"),
        "logsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Це призведе до надсилання журналів, які допоможуть нам усунути вашу проблему. Зверніть увагу, що назви файлів будуть включені, щоби допомогти відстежувати проблеми з конкретними файлами."),
        "longPressAnEmailToVerifyEndToEndEncryption":
            MessageLookupByLibrary.simpleMessage(
                "Довго утримуйте поштову адресу, щоб перевірити наскрізне шифрування."),
        "longpressOnAnItemToViewInFullscreen": MessageLookupByLibrary.simpleMessage(
            "Натисніть і утримуйте елемент для перегляду в повноекранному режимі"),
        "loopVideoOff":
            MessageLookupByLibrary.simpleMessage("Вимкнено зациклювання відео"),
        "loopVideoOn": MessageLookupByLibrary.simpleMessage(
            "Увімкнено зациклювання відео"),
        "lostDevice":
            MessageLookupByLibrary.simpleMessage("Загубили пристрій?"),
        "machineLearning":
            MessageLookupByLibrary.simpleMessage("Машинне навчання"),
        "magicSearch": MessageLookupByLibrary.simpleMessage("Магічний пошук"),
        "magicSearchHint": MessageLookupByLibrary.simpleMessage(
            "Магічний пошук дозволяє шукати фотографії за їхнім вмістом, наприклад «квітка», «червоне авто» «паспорт»"),
        "manage": MessageLookupByLibrary.simpleMessage("Керування"),
        "manageDeviceStorage":
            MessageLookupByLibrary.simpleMessage("Керування кешем пристрою"),
        "manageDeviceStorageDesc": MessageLookupByLibrary.simpleMessage(
            "Переглянути та очистити локальне сховище кешу."),
        "manageFamily":
            MessageLookupByLibrary.simpleMessage("Керування сім\'єю"),
        "manageLink":
            MessageLookupByLibrary.simpleMessage("Керувати посиланням"),
        "manageParticipants": MessageLookupByLibrary.simpleMessage("Керування"),
        "manageSubscription":
            MessageLookupByLibrary.simpleMessage("Керування передплатою"),
        "manualPairDesc": MessageLookupByLibrary.simpleMessage(
            "Створення пари з PIN-кодом працює з будь-яким екраном, на яку ви хочете переглянути альбом."),
        "map": MessageLookupByLibrary.simpleMessage("Мапа"),
        "maps": MessageLookupByLibrary.simpleMessage("Мапи"),
        "mastodon": MessageLookupByLibrary.simpleMessage("Mastodon"),
        "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
        "merchandise": MessageLookupByLibrary.simpleMessage("Товари"),
        "mergeWithExisting":
            MessageLookupByLibrary.simpleMessage("Об\'єднати з наявним"),
        "mergedPhotos":
            MessageLookupByLibrary.simpleMessage("Об\'єднані фотографії"),
        "mlConsent":
            MessageLookupByLibrary.simpleMessage("Увімкнути машинне навчання"),
        "mlConsentConfirmation": MessageLookupByLibrary.simpleMessage(
            "Я розумію, та бажаю увімкнути машинне навчання"),
        "mlConsentDescription": MessageLookupByLibrary.simpleMessage(
            "Якщо увімкнути машинне навчання, Ente вилучатиме інформацію, наприклад геометрію обличчя з файлів, включно з тими, хто поділився з вами.\n\nЦе відбуватиметься на вашому пристрої, і будь-яка згенерована біометрична інформація буде наскрізно зашифрована."),
        "mlConsentPrivacy": MessageLookupByLibrary.simpleMessage(
            "Натисніть тут для більш детальної інформації про цю функцію в нашій політиці приватності"),
        "mlConsentTitle":
            MessageLookupByLibrary.simpleMessage("Увімкнути машинне навчання?"),
        "mlIndexingDescription": MessageLookupByLibrary.simpleMessage(
            "Зверніть увагу, що машинне навчання призведе до збільшення пропускної здатності та споживання заряду батареї, поки не будуть проіндексовані всі елементи. Для прискорення індексації скористайтеся настільним застосунком, всі результати будуть синхронізовані автоматично."),
        "mobileWebDesktop":
            MessageLookupByLibrary.simpleMessage("Смартфон, Вебсайт, ПК"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Середній"),
        "modifyYourQueryOrTrySearchingFor":
            MessageLookupByLibrary.simpleMessage(
                "Змініть ваш запит або спробуйте знайти"),
        "moments": MessageLookupByLibrary.simpleMessage("Моменти"),
        "month": MessageLookupByLibrary.simpleMessage("місяць"),
        "monthly": MessageLookupByLibrary.simpleMessage("Щомісяця"),
        "moreDetails": MessageLookupByLibrary.simpleMessage("Детальніше"),
        "mostRecent": MessageLookupByLibrary.simpleMessage("Останні"),
        "mostRelevant": MessageLookupByLibrary.simpleMessage("Найактуальніші"),
        "moveToAlbum":
            MessageLookupByLibrary.simpleMessage("Перемістити до альбому"),
        "moveToHiddenAlbum": MessageLookupByLibrary.simpleMessage(
            "Перемістити до прихованого альбому"),
        "movedSuccessfullyTo": m52,
        "movedToTrash":
            MessageLookupByLibrary.simpleMessage("Переміщено у смітник"),
        "movingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Переміщуємо файли до альбому..."),
        "name": MessageLookupByLibrary.simpleMessage("Назва"),
        "nameTheAlbum": MessageLookupByLibrary.simpleMessage("Назвіть альбом"),
        "networkConnectionRefusedErr": MessageLookupByLibrary.simpleMessage(
            "Не вдалося під\'єднатися до Ente. Спробуйте ще раз через деякий час. Якщо помилка не зникне, зв\'яжіться з нашою командою підтримки."),
        "networkHostLookUpErr": MessageLookupByLibrary.simpleMessage(
            "Не вдалося під\'єднатися до Ente. Перевірте налаштування мережі. Зверніться до нашої команди підтримки, якщо помилка залишиться."),
        "never": MessageLookupByLibrary.simpleMessage("Ніколи"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Новий альбом"),
        "newLocation":
            MessageLookupByLibrary.simpleMessage("Нове розташування"),
        "newPerson": MessageLookupByLibrary.simpleMessage("Нова особа"),
        "newToEnte": MessageLookupByLibrary.simpleMessage("Уперше на Ente"),
        "newest": MessageLookupByLibrary.simpleMessage("Найновіші"),
        "next": MessageLookupByLibrary.simpleMessage("Далі"),
        "no": MessageLookupByLibrary.simpleMessage("Ні"),
        "noAlbumsSharedByYouYet": MessageLookupByLibrary.simpleMessage(
            "Ви ще не поділилися жодним альбомом"),
        "noDeviceFound": MessageLookupByLibrary.simpleMessage(
            "Не знайдено жодного пристрою"),
        "noDeviceLimit": MessageLookupByLibrary.simpleMessage("Немає"),
        "noDeviceThatCanBeDeleted": MessageLookupByLibrary.simpleMessage(
            "У вас не маєте файлів на цьому пристрої, які можна видалити"),
        "noDuplicates":
            MessageLookupByLibrary.simpleMessage("✨ Немає дублікатів"),
        "noExifData": MessageLookupByLibrary.simpleMessage("Немає даних EXIF"),
        "noFacesFound":
            MessageLookupByLibrary.simpleMessage("Обличчя не знайдено"),
        "noHiddenPhotosOrVideos": MessageLookupByLibrary.simpleMessage(
            "Немає прихованих фотографій чи відео"),
        "noImagesWithLocation": MessageLookupByLibrary.simpleMessage(
            "Немає зображень з розташуванням"),
        "noInternetConnection":
            MessageLookupByLibrary.simpleMessage("Немає з’єднання з мережею"),
        "noPhotosAreBeingBackedUpRightNow":
            MessageLookupByLibrary.simpleMessage(
                "Наразі немає резервних копій фотографій"),
        "noPhotosFoundHere":
            MessageLookupByLibrary.simpleMessage("Тут немає фотографій"),
        "noQuickLinksSelected":
            MessageLookupByLibrary.simpleMessage("Не вибрано швидких посилань"),
        "noRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Немає ключа відновлення?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "Через природу нашого кінцевого протоколу шифрування, ваші дані не можуть бути розшифровані без вашого пароля або ключа відновлення"),
        "noResults": MessageLookupByLibrary.simpleMessage("Немає результатів"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("Нічого не знайдено"),
        "noSuggestionsForPerson": m53,
        "noSystemLockFound": MessageLookupByLibrary.simpleMessage(
            "Не знайдено системного блокування"),
        "notPersonLabel": m54,
        "nothingSharedWithYouYet": MessageLookupByLibrary.simpleMessage(
            "Поки що з вами ніхто не поділився"),
        "nothingToSeeHere": MessageLookupByLibrary.simpleMessage(
            "Тут немає на що дивитися! 👀"),
        "notifications": MessageLookupByLibrary.simpleMessage("Сповіщення"),
        "ok": MessageLookupByLibrary.simpleMessage("Добре"),
        "onDevice": MessageLookupByLibrary.simpleMessage("На пристрої"),
        "onEnte":
            MessageLookupByLibrary.simpleMessage("В <branding>Ente</branding>"),
        "onlyFamilyAdminCanChangeCode": m55,
        "onlyThem": MessageLookupByLibrary.simpleMessage("Тільки вони"),
        "oops": MessageLookupByLibrary.simpleMessage("От халепа"),
        "oopsCouldNotSaveEdits": MessageLookupByLibrary.simpleMessage(
            "Ой, не вдалося зберегти зміни"),
        "oopsSomethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Йой, щось пішло не так"),
        "openAlbumInBrowser":
            MessageLookupByLibrary.simpleMessage("Відкрити альбом у браузері"),
        "openAlbumInBrowserTitle": MessageLookupByLibrary.simpleMessage(
            "Використовуйте вебзастосунок, щоби додавати фотографії до цього альбому"),
        "openFile": MessageLookupByLibrary.simpleMessage("Відкрити файл"),
        "openSettings":
            MessageLookupByLibrary.simpleMessage("Відкрити налаштування"),
        "openTheItem":
            MessageLookupByLibrary.simpleMessage("• Відкрити елемент"),
        "openstreetmapContributors":
            MessageLookupByLibrary.simpleMessage("Учасники OpenStreetMap"),
        "optionalAsShortAsYouLike": MessageLookupByLibrary.simpleMessage(
            "Необов\'язково, так коротко, як ви хочете..."),
        "orMergeWithExistingPerson":
            MessageLookupByLibrary.simpleMessage("Або об\'єднати з наявними"),
        "orPickAnExistingOne":
            MessageLookupByLibrary.simpleMessage("Або виберіть наявну"),
        "pair": MessageLookupByLibrary.simpleMessage("Створити пару"),
        "pairWithPin":
            MessageLookupByLibrary.simpleMessage("Під’єднатися через PIN-код"),
        "pairingComplete":
            MessageLookupByLibrary.simpleMessage("Створення пари завершено"),
        "panorama": MessageLookupByLibrary.simpleMessage("Панорама"),
        "passKeyPendingVerification":
            MessageLookupByLibrary.simpleMessage("Перевірка все ще триває"),
        "passkey": MessageLookupByLibrary.simpleMessage("Ключ доступу"),
        "passkeyAuthTitle": MessageLookupByLibrary.simpleMessage(
            "Перевірка через ключ доступу"),
        "password": MessageLookupByLibrary.simpleMessage("Пароль"),
        "passwordChangedSuccessfully":
            MessageLookupByLibrary.simpleMessage("Пароль успішно змінено"),
        "passwordLock":
            MessageLookupByLibrary.simpleMessage("Блокування паролем"),
        "passwordStrength": m57,
        "passwordStrengthInfo": MessageLookupByLibrary.simpleMessage(
            "Надійність пароля розраховується з урахуванням довжини пароля, використаних символів, а також того, чи входить пароль у топ 10 000 найбільш використовуваних паролів"),
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Ми не зберігаємо цей пароль, тому, якщо ви його забудете, <underline>ми не зможемо розшифрувати ваші дані</underline>"),
        "paymentDetails":
            MessageLookupByLibrary.simpleMessage("Деталі платежу"),
        "paymentFailed":
            MessageLookupByLibrary.simpleMessage("Не вдалося оплатити"),
        "paymentFailedMessage": MessageLookupByLibrary.simpleMessage(
            "На жаль, ваш платіж не вдався. Зв\'яжіться зі службою підтримки і ми вам допоможемо!"),
        "paymentFailedTalkToProvider": m58,
        "pendingItems":
            MessageLookupByLibrary.simpleMessage("Елементи на розгляді"),
        "pendingSync":
            MessageLookupByLibrary.simpleMessage("Очікування синхронізації"),
        "people": MessageLookupByLibrary.simpleMessage("Люди"),
        "peopleUsingYourCode": MessageLookupByLibrary.simpleMessage(
            "Люди, які використовують ваш код"),
        "permDeleteWarning": MessageLookupByLibrary.simpleMessage(
            "Усі елементи смітника будуть остаточно видалені\n\nЦю дію не можна скасувати"),
        "permanentlyDelete":
            MessageLookupByLibrary.simpleMessage("Остаточно видалити"),
        "permanentlyDeleteFromDevice": MessageLookupByLibrary.simpleMessage(
            "Остаточно видалити з пристрою?"),
        "personName": MessageLookupByLibrary.simpleMessage("Ім\'я особи"),
        "photoDescriptions":
            MessageLookupByLibrary.simpleMessage("Опис фотографії"),
        "photoGridSize":
            MessageLookupByLibrary.simpleMessage("Розмір сітки фотографій"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("фото"),
        "photos": MessageLookupByLibrary.simpleMessage("Фото"),
        "photosAddedByYouWillBeRemovedFromTheAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Додані вами фотографії будуть видалені з альбому"),
        "pickCenterPoint":
            MessageLookupByLibrary.simpleMessage("Вкажіть центральну точку"),
        "pinAlbum": MessageLookupByLibrary.simpleMessage("Закріпити альбом"),
        "pinLock": MessageLookupByLibrary.simpleMessage("Блокування PIN-кодом"),
        "playOnTv":
            MessageLookupByLibrary.simpleMessage("Відтворити альбом на ТБ"),
        "playStoreFreeTrialValidTill": m63,
        "playstoreSubscription":
            MessageLookupByLibrary.simpleMessage("Передплата Play Store"),
        "pleaseCheckYourInternetConnectionAndTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Перевірте з\'єднання з мережею та спробуйте ще раз."),
        "pleaseContactSupportAndWeWillBeHappyToHelp":
            MessageLookupByLibrary.simpleMessage(
                "Зв\'яжіться з support@ente.io і ми будемо раді допомогти!"),
        "pleaseContactSupportIfTheProblemPersists":
            MessageLookupByLibrary.simpleMessage(
                "Зверніться до служби підтримки, якщо проблема не зникне"),
        "pleaseEmailUsAt": m64,
        "pleaseGrantPermissions":
            MessageLookupByLibrary.simpleMessage("Надайте дозволи"),
        "pleaseLoginAgain":
            MessageLookupByLibrary.simpleMessage("Увійдіть знову"),
        "pleaseSelectQuickLinksToRemove": MessageLookupByLibrary.simpleMessage(
            "Виберіть посилання для видалення"),
        "pleaseSendTheLogsTo": m65,
        "pleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("Спробуйте ще раз"),
        "pleaseVerifyTheCodeYouHaveEntered":
            MessageLookupByLibrary.simpleMessage("Підтвердьте введений код"),
        "pleaseWait":
            MessageLookupByLibrary.simpleMessage("Будь ласка, зачекайте..."),
        "pleaseWaitDeletingAlbum": MessageLookupByLibrary.simpleMessage(
            "Зачекайте на видалення альбому"),
        "pleaseWaitForSometimeBeforeRetrying":
            MessageLookupByLibrary.simpleMessage(
                "Зачекайте деякий час перед повторною спробою"),
        "preparingLogs":
            MessageLookupByLibrary.simpleMessage("Підготовка журналів..."),
        "preserveMore": MessageLookupByLibrary.simpleMessage("Зберегти більше"),
        "pressAndHoldToPlayVideo": MessageLookupByLibrary.simpleMessage(
            "Натисніть та утримуйте, щоб відтворити відео"),
        "pressAndHoldToPlayVideoDetailed": MessageLookupByLibrary.simpleMessage(
            "Натисніть та утримуйте на зображення, щоби відтворити відео"),
        "privacy": MessageLookupByLibrary.simpleMessage("Приватність"),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Політика приватності"),
        "privateBackups":
            MessageLookupByLibrary.simpleMessage("Приватні резервні копії"),
        "privateSharing":
            MessageLookupByLibrary.simpleMessage("Приватне поширення"),
        "proceed": MessageLookupByLibrary.simpleMessage("Продовжити"),
        "processingImport": m67,
        "publicLinkCreated":
            MessageLookupByLibrary.simpleMessage("Публічне посилання створено"),
        "publicLinkEnabled": MessageLookupByLibrary.simpleMessage(
            "Публічне посилання увімкнено"),
        "quickLinks": MessageLookupByLibrary.simpleMessage("Швидкі посилання"),
        "radius": MessageLookupByLibrary.simpleMessage("Радіус"),
        "raiseTicket": MessageLookupByLibrary.simpleMessage("Подати заявку"),
        "rateTheApp":
            MessageLookupByLibrary.simpleMessage("Оцініть застосунок"),
        "rateUs": MessageLookupByLibrary.simpleMessage("Оцініть нас"),
        "rateUsOnStore": m68,
        "recover": MessageLookupByLibrary.simpleMessage("Відновити"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("Відновити обліковий запис"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Відновлення"),
        "recoveryAccount":
            MessageLookupByLibrary.simpleMessage("Відновити обліковий запис"),
        "recoveryInitiated":
            MessageLookupByLibrary.simpleMessage("Почато відновлення"),
        "recoveryInitiatedDesc": m70,
        "recoveryKey": MessageLookupByLibrary.simpleMessage("Ключ відновлення"),
        "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Ключ відновлення скопійовано в буфер обміну"),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
            "Якщо ви забудете свій пароль, то єдиний спосіб відновити ваші дані – за допомогою цього ключа."),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
            "Ми не зберігаємо цей ключ, збережіть цей ключ із 24 слів в надійному місці."),
        "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
            "Чудово! Ваш ключ відновлення дійсний. Дякуємо за перевірку.\n\nНе забувайте надійно зберігати ключ відновлення."),
        "recoveryKeyVerified":
            MessageLookupByLibrary.simpleMessage("Ключ відновлення перевірено"),
        "recoveryKeyVerifyReason": MessageLookupByLibrary.simpleMessage(
            "Ключ відновлення — це єдиний спосіб відновити фотографії, якщо ви забули пароль. Ви можете знайти свій ключ в розділі «Налаштування» > «Обліковий запис».\n\nВведіть ключ відновлення тут, щоб перевірити, чи правильно ви його зберегли."),
        "recoveryReady": m71,
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("Відновлення успішне!"),
        "recoveryWarning": MessageLookupByLibrary.simpleMessage(
            "Довірений контакт намагається отримати доступ до вашого облікового запису"),
        "recoveryWarningBody": m72,
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "Ваш пристрій недостатньо потужний для перевірки пароля, але ми можемо відновити його таким чином, щоб він працював на всіх пристроях.\n\nУвійдіть за допомогою ключа відновлення та відновіть свій пароль (за бажанням ви можете використати той самий ключ знову)."),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Повторно створити пароль"),
        "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
        "reenterPassword":
            MessageLookupByLibrary.simpleMessage("Введіть пароль ще раз"),
        "reenterPin":
            MessageLookupByLibrary.simpleMessage("Введіть PIN-код ще раз"),
        "referFriendsAnd2xYourPlan": MessageLookupByLibrary.simpleMessage(
            "Запросіть друзів та подвойте свій план"),
        "referralStep1":
            MessageLookupByLibrary.simpleMessage("1. Дайте цей код друзям"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "2. Вони оформлюють передплату"),
        "referralStep3": m73,
        "referrals": MessageLookupByLibrary.simpleMessage("Реферали"),
        "referralsAreCurrentlyPaused":
            MessageLookupByLibrary.simpleMessage("Реферали зараз призупинені"),
        "rejectRecovery":
            MessageLookupByLibrary.simpleMessage("Відхилити відновлення"),
        "remindToEmptyDeviceTrash": MessageLookupByLibrary.simpleMessage(
            "Також очистьте «Нещодавно видалено» в «Налаштування» -> «Сховище», щоб отримати вільне місце"),
        "remindToEmptyEnteTrash": MessageLookupByLibrary.simpleMessage(
            "Також очистьте «Смітник», щоб звільнити місце"),
        "remoteImages":
            MessageLookupByLibrary.simpleMessage("Віддалені зображення"),
        "remoteThumbnails":
            MessageLookupByLibrary.simpleMessage("Віддалені мініатюри"),
        "remoteVideos": MessageLookupByLibrary.simpleMessage("Віддалені відео"),
        "remove": MessageLookupByLibrary.simpleMessage("Вилучити"),
        "removeDuplicates":
            MessageLookupByLibrary.simpleMessage("Вилучити дублікати"),
        "removeDuplicatesDesc": MessageLookupByLibrary.simpleMessage(
            "Перегляньте та видаліть файли, які є точними дублікатами."),
        "removeFromAlbum":
            MessageLookupByLibrary.simpleMessage("Видалити з альбому"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("Видалити з альбому?"),
        "removeFromFavorite":
            MessageLookupByLibrary.simpleMessage("Вилучити з улюбленого"),
        "removeInvite":
            MessageLookupByLibrary.simpleMessage("Видалити запрошення"),
        "removeLink":
            MessageLookupByLibrary.simpleMessage("Вилучити посилання"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Видалити учасника"),
        "removeParticipantBody": m74,
        "removePersonLabel":
            MessageLookupByLibrary.simpleMessage("Видалити мітку особи"),
        "removePublicLink":
            MessageLookupByLibrary.simpleMessage("Видалити публічне посилання"),
        "removePublicLinks":
            MessageLookupByLibrary.simpleMessage("Видалити публічні посилання"),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
            "Деякі речі, які ви видаляєте були додані іншими людьми, ви втратите доступ до них"),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Видалити?"),
        "removeYourselfAsTrustedContact": MessageLookupByLibrary.simpleMessage(
            "Видалити себе як довірений контакт"),
        "removingFromFavorites":
            MessageLookupByLibrary.simpleMessage("Видалення з обраного..."),
        "rename": MessageLookupByLibrary.simpleMessage("Перейменувати"),
        "renameAlbum":
            MessageLookupByLibrary.simpleMessage("Перейменувати альбом"),
        "renameFile":
            MessageLookupByLibrary.simpleMessage("Перейменувати файл"),
        "renewSubscription":
            MessageLookupByLibrary.simpleMessage("Поновити передплату"),
        "renewsOn": m75,
        "reportABug":
            MessageLookupByLibrary.simpleMessage("Повідомити про помилку"),
        "reportBug":
            MessageLookupByLibrary.simpleMessage("Повідомити про помилку"),
        "resendEmail":
            MessageLookupByLibrary.simpleMessage("Повторно надіслати лист"),
        "resetIgnoredFiles":
            MessageLookupByLibrary.simpleMessage("Скинути ігноровані файли"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Скинути пароль"),
        "resetPerson": MessageLookupByLibrary.simpleMessage("Вилучити"),
        "resetToDefault":
            MessageLookupByLibrary.simpleMessage("Скинути до типових"),
        "restore": MessageLookupByLibrary.simpleMessage("Відновити"),
        "restoreToAlbum":
            MessageLookupByLibrary.simpleMessage("Відновити в альбомі"),
        "restoringFiles":
            MessageLookupByLibrary.simpleMessage("Відновлюємо файли..."),
        "resumableUploads": MessageLookupByLibrary.simpleMessage(
            "Завантаження з можливістю відновлення"),
        "retry": MessageLookupByLibrary.simpleMessage("Повторити"),
        "review": MessageLookupByLibrary.simpleMessage("Оцінити"),
        "reviewDeduplicateItems": MessageLookupByLibrary.simpleMessage(
            "Перегляньте та видаліть елементи, які, на вашу думку, є дублікатами."),
        "reviewSuggestions":
            MessageLookupByLibrary.simpleMessage("Переглянути пропозиції"),
        "right": MessageLookupByLibrary.simpleMessage("Праворуч"),
        "rotate": MessageLookupByLibrary.simpleMessage("Обернути"),
        "rotateLeft": MessageLookupByLibrary.simpleMessage("Повернути ліворуч"),
        "rotateRight":
            MessageLookupByLibrary.simpleMessage("Повернути праворуч"),
        "safelyStored":
            MessageLookupByLibrary.simpleMessage("Безпечне збереження"),
        "save": MessageLookupByLibrary.simpleMessage("Зберегти"),
        "saveCollage": MessageLookupByLibrary.simpleMessage("Зберегти колаж"),
        "saveCopy": MessageLookupByLibrary.simpleMessage("Зберегти копію"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Зберегти ключ"),
        "savePerson": MessageLookupByLibrary.simpleMessage("Зберегти особу"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Збережіть ваш ключ відновлення, якщо ви ще цього не зробили"),
        "saving": MessageLookupByLibrary.simpleMessage("Зберігаємо..."),
        "savingEdits":
            MessageLookupByLibrary.simpleMessage("Зберігаємо зміни..."),
        "scanCode": MessageLookupByLibrary.simpleMessage("Сканувати код"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Зіскануйте цей штрихкод за допомогою\nвашого застосунку для автентифікації"),
        "search": MessageLookupByLibrary.simpleMessage("Пошук"),
        "searchAlbumsEmptySection":
            MessageLookupByLibrary.simpleMessage("Альбоми"),
        "searchByAlbumNameHint":
            MessageLookupByLibrary.simpleMessage("Назва альбому"),
        "searchByExamples": MessageLookupByLibrary.simpleMessage(
            "• Назви альбомів (наприклад, «Камера»)\n• Типи файлів (наприклад, «Відео», «.gif»)\n• Роки та місяці (наприклад, «2022», «січень»)\n• Свята (наприклад, «Різдво»)\n• Описи фотографій (наприклад, «#fun»)"),
        "searchCaptionEmptySection": MessageLookupByLibrary.simpleMessage(
            "Додавайте такі описи як «#подорож» в інформацію про фотографію, щоб швидко знайти їх тут"),
        "searchDatesEmptySection": MessageLookupByLibrary.simpleMessage(
            "Шукати за датою, місяцем або роком"),
        "searchDiscoverEmptySection": MessageLookupByLibrary.simpleMessage(
            "Зображення будуть показані тут після завершення оброблення та синхронізації"),
        "searchFaceEmptySection": MessageLookupByLibrary.simpleMessage(
            "Люди будуть показані тут після завершення індексації"),
        "searchFileTypesAndNamesEmptySection":
            MessageLookupByLibrary.simpleMessage("Типи та назви файлів"),
        "searchHint1":
            MessageLookupByLibrary.simpleMessage("Швидкий пошук на пристрої"),
        "searchHint2": MessageLookupByLibrary.simpleMessage("Дати, описи фото"),
        "searchHint3": MessageLookupByLibrary.simpleMessage(
            "Альбоми, назви та типи файлів"),
        "searchHint4": MessageLookupByLibrary.simpleMessage("Розташування"),
        "searchHint5": MessageLookupByLibrary.simpleMessage(
            "Незабаром: Обличчя і магічний пошук ✨"),
        "searchLocationEmptySection": MessageLookupByLibrary.simpleMessage(
            "Групові фотографії, які зроблені в певному радіусі від фотографії"),
        "searchPeopleEmptySection": MessageLookupByLibrary.simpleMessage(
            "Запросіть людей, і ви побачите всі фотографії, якими вони поділилися, тут"),
        "searchPersonsEmptySection": MessageLookupByLibrary.simpleMessage(
            "Люди будуть показані тут після завершення оброблення та синхронізації"),
        "searchResultCount": m77,
        "searchSectionsLengthMismatch": m78,
        "security": MessageLookupByLibrary.simpleMessage("Безпека"),
        "seePublicAlbumLinksInApp": MessageLookupByLibrary.simpleMessage(
            "Посилання на публічні альбоми в застосунку"),
        "selectALocation":
            MessageLookupByLibrary.simpleMessage("Виберіть місце"),
        "selectALocationFirst": MessageLookupByLibrary.simpleMessage(
            "Спочатку виберіть розташування"),
        "selectAlbum": MessageLookupByLibrary.simpleMessage("Вибрати альбом"),
        "selectAll": MessageLookupByLibrary.simpleMessage("Вибрати все"),
        "selectAllShort": MessageLookupByLibrary.simpleMessage("Усі"),
        "selectCoverPhoto":
            MessageLookupByLibrary.simpleMessage("Вибрати обкладинку"),
        "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
            "Оберіть теки для резервного копіювання"),
        "selectItemsToAdd": MessageLookupByLibrary.simpleMessage(
            "Виберіть елементи для додавання"),
        "selectLanguage": MessageLookupByLibrary.simpleMessage("Виберіть мову"),
        "selectMailApp":
            MessageLookupByLibrary.simpleMessage("Вибрати застосунок пошти"),
        "selectMorePhotos":
            MessageLookupByLibrary.simpleMessage("Вибрати більше фотографій"),
        "selectReason": MessageLookupByLibrary.simpleMessage("Оберіть причину"),
        "selectYourPlan": MessageLookupByLibrary.simpleMessage("Оберіть тариф"),
        "selectedFilesAreNotOnEnte":
            MessageLookupByLibrary.simpleMessage("Вибрані файли не на Ente"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "Вибрані теки будуть зашифровані й створені резервні копії"),
        "selectedItemsWillBeDeletedFromAllAlbumsAndMoved":
            MessageLookupByLibrary.simpleMessage(
                "Вибрані елементи будуть видалені з усіх альбомів і переміщені в смітник."),
        "selectedPhotos": m80,
        "selectedPhotosWithYours": m81,
        "send": MessageLookupByLibrary.simpleMessage("Надіслати"),
        "sendEmail": MessageLookupByLibrary.simpleMessage(
            "Надіслати електронного листа"),
        "sendInvite":
            MessageLookupByLibrary.simpleMessage("Надіслати запрошення"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Надіслати посилання"),
        "serverEndpoint":
            MessageLookupByLibrary.simpleMessage("Кінцева точка сервера"),
        "sessionExpired":
            MessageLookupByLibrary.simpleMessage("Час сеансу минув"),
        "sessionIdMismatch": MessageLookupByLibrary.simpleMessage(
            "Невідповідність ідентифікатора сеансу"),
        "setAPassword":
            MessageLookupByLibrary.simpleMessage("Встановити пароль"),
        "setAs": MessageLookupByLibrary.simpleMessage("Встановити як"),
        "setCover":
            MessageLookupByLibrary.simpleMessage("Встановити обкладинку"),
        "setLabel": MessageLookupByLibrary.simpleMessage("Встановити"),
        "setNewPassword":
            MessageLookupByLibrary.simpleMessage("Встановити новий пароль"),
        "setNewPin":
            MessageLookupByLibrary.simpleMessage("Встановити новий PIN-код"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Встановити пароль"),
        "setRadius": MessageLookupByLibrary.simpleMessage("Встановити радіус"),
        "setupComplete":
            MessageLookupByLibrary.simpleMessage("Налаштування завершено"),
        "share": MessageLookupByLibrary.simpleMessage("Поділитися"),
        "shareALink":
            MessageLookupByLibrary.simpleMessage("Поділитися посиланням"),
        "shareAlbumHint": MessageLookupByLibrary.simpleMessage(
            "Відкрийте альбом та натисніть кнопку «Поділитися» у верхньому правому куті."),
        "shareAnAlbumNow":
            MessageLookupByLibrary.simpleMessage("Поділитися альбомом зараз"),
        "shareLink":
            MessageLookupByLibrary.simpleMessage("Поділитися посиланням"),
        "shareMyVerificationID": m83,
        "shareOnlyWithThePeopleYouWant": MessageLookupByLibrary.simpleMessage(
            "Поділіться тільки з тими людьми, якими ви хочете"),
        "shareTextConfirmOthersVerificationID": m84,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Завантажте Ente для того, щоб легко поділитися фотографіями оригінальної якості та відео\n\nhttps://ente.io"),
        "shareTextReferralCode": m85,
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
            "Поділитися з користувачами без Ente"),
        "shareWithPeopleSectionTitle": m86,
        "shareYourFirstAlbum": MessageLookupByLibrary.simpleMessage(
            "Поділитися вашим першим альбомом"),
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Створюйте спільні альбоми з іншими користувачами Ente, включно з користувачами безплатних тарифів."),
        "sharedByMe": MessageLookupByLibrary.simpleMessage("Поділився мною"),
        "sharedByYou": MessageLookupByLibrary.simpleMessage("Поділилися вами"),
        "sharedPhotoNotifications":
            MessageLookupByLibrary.simpleMessage("Нові спільні фотографії"),
        "sharedPhotoNotificationsExplanation": MessageLookupByLibrary.simpleMessage(
            "Отримувати сповіщення, коли хтось додасть фото до спільного альбому, в якому ви перебуваєте"),
        "sharedWith": m87,
        "sharedWithMe":
            MessageLookupByLibrary.simpleMessage("Поділитися зі мною"),
        "sharedWithYou":
            MessageLookupByLibrary.simpleMessage("Поділилися з вами"),
        "sharing": MessageLookupByLibrary.simpleMessage("Відправлення..."),
        "showMemories":
            MessageLookupByLibrary.simpleMessage("Показати спогади"),
        "showPerson": MessageLookupByLibrary.simpleMessage("Показати особу"),
        "signOutFromOtherDevices":
            MessageLookupByLibrary.simpleMessage("Вийти на інших пристроях"),
        "signOutOtherBody": MessageLookupByLibrary.simpleMessage(
            "Якщо ви думаєте, що хтось може знати ваш пароль, ви можете примусити всі інші пристрої, які використовують ваш обліковий запис, вийти із системи."),
        "signOutOtherDevices":
            MessageLookupByLibrary.simpleMessage("Вийти на інших пристроях"),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "Я приймаю <u-terms>умови використання</u-terms> і <u-policy>політику приватності</u-policy>"),
        "singleFileDeleteFromDevice": m88,
        "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
            "Воно буде видалено з усіх альбомів."),
        "singleFileInBothLocalAndRemote": m89,
        "singleFileInRemoteOnly": m90,
        "skip": MessageLookupByLibrary.simpleMessage("Пропустити"),
        "social": MessageLookupByLibrary.simpleMessage("Соцмережі"),
        "someItemsAreInBothEnteAndYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Деякі елементи знаходяться на Ente та вашому пристрої."),
        "someOfTheFilesYouAreTryingToDeleteAre":
            MessageLookupByLibrary.simpleMessage(
                "Деякі файли, які ви намагаєтеся видалити, доступні лише на вашому пристрої, і їх неможливо відновити"),
        "someoneSharingAlbumsWithYouShouldSeeTheSameId":
            MessageLookupByLibrary.simpleMessage(
                "Той, хто ділиться з вами альбомами, повинен бачити той самий ідентифікатор на своєму пристрої."),
        "somethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Щось пішло не так"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Щось пішло не так, будь ласка, спробуйте знову"),
        "sorry": MessageLookupByLibrary.simpleMessage("Пробачте"),
        "sorryCouldNotAddToFavorites": MessageLookupByLibrary.simpleMessage(
            "Неможливо додати до обраного!"),
        "sorryCouldNotRemoveFromFavorites":
            MessageLookupByLibrary.simpleMessage(
                "Не вдалося видалити з обраного!"),
        "sorryTheCodeYouveEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "Вибачте, але введений вами код є невірним"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "На жаль, на цьому пристрої не вдалося створити безпечні ключі.\n\nЗареєструйтесь з іншого пристрою."),
        "sort": MessageLookupByLibrary.simpleMessage("Сортувати"),
        "sortAlbumsBy": MessageLookupByLibrary.simpleMessage("Сортувати за"),
        "sortNewestFirst":
            MessageLookupByLibrary.simpleMessage("Спочатку найновіші"),
        "sortOldestFirst":
            MessageLookupByLibrary.simpleMessage("Спочатку найстаріші"),
        "sparkleSuccess": MessageLookupByLibrary.simpleMessage("✨ Успішно"),
        "startAccountRecoveryTitle":
            MessageLookupByLibrary.simpleMessage("Почати відновлення"),
        "startBackup":
            MessageLookupByLibrary.simpleMessage("Почати резервне копіювання"),
        "status": MessageLookupByLibrary.simpleMessage("Стан"),
        "stopCastingBody": MessageLookupByLibrary.simpleMessage(
            "Ви хочете припинити трансляцію?"),
        "stopCastingTitle":
            MessageLookupByLibrary.simpleMessage("Припинити трансляцію"),
        "storage": MessageLookupByLibrary.simpleMessage("Сховище"),
        "storageBreakupFamily": MessageLookupByLibrary.simpleMessage("Сім\'я"),
        "storageBreakupYou": MessageLookupByLibrary.simpleMessage("Ви"),
        "storageInGB": m93,
        "storageLimitExceeded":
            MessageLookupByLibrary.simpleMessage("Перевищено ліміт сховища"),
        "storageUsageInfo": m94,
        "strongStrength": MessageLookupByLibrary.simpleMessage("Надійний"),
        "subAlreadyLinkedErrMessage": m95,
        "subWillBeCancelledOn": m96,
        "subscribe": MessageLookupByLibrary.simpleMessage("Передплачувати"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "Вам потрібна активна передплата, щоб увімкнути спільне поширення."),
        "subscription": MessageLookupByLibrary.simpleMessage("Передплата"),
        "success": MessageLookupByLibrary.simpleMessage("Успішно"),
        "successfullyArchived":
            MessageLookupByLibrary.simpleMessage("Успішно архівовано"),
        "successfullyHid":
            MessageLookupByLibrary.simpleMessage("Успішно приховано"),
        "successfullyUnarchived":
            MessageLookupByLibrary.simpleMessage("Успішно розархівовано"),
        "successfullyUnhid":
            MessageLookupByLibrary.simpleMessage("Успішно показано"),
        "suggestFeatures":
            MessageLookupByLibrary.simpleMessage("Запропонувати нові функції"),
        "support": MessageLookupByLibrary.simpleMessage("Підтримка"),
        "syncProgress": m97,
        "syncStopped":
            MessageLookupByLibrary.simpleMessage("Синхронізацію зупинено"),
        "syncing": MessageLookupByLibrary.simpleMessage("Синхронізуємо..."),
        "systemTheme": MessageLookupByLibrary.simpleMessage("Як в системі"),
        "tapToCopy":
            MessageLookupByLibrary.simpleMessage("натисніть, щоб скопіювати"),
        "tapToEnterCode":
            MessageLookupByLibrary.simpleMessage("Натисніть, щоб ввести код"),
        "tapToUnlock": MessageLookupByLibrary.simpleMessage(
            "Торкніться, щоби розблокувати"),
        "tapToUpload":
            MessageLookupByLibrary.simpleMessage("Натисніть, щоб завантажити"),
        "tapToUploadIsIgnoredDue": m98,
        "tempErrorContactSupportIfPersists": MessageLookupByLibrary.simpleMessage(
            "Схоже, що щось пішло не так. Спробуйте ще раз через деякий час. Якщо помилка не зникне, зв\'яжіться з нашою командою підтримки."),
        "terminate": MessageLookupByLibrary.simpleMessage("Припинити"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Припинити сеанс?"),
        "terms": MessageLookupByLibrary.simpleMessage("Умови"),
        "termsOfServicesTitle": MessageLookupByLibrary.simpleMessage("Умови"),
        "thankYou": MessageLookupByLibrary.simpleMessage("Дякуємо"),
        "thankYouForSubscribing":
            MessageLookupByLibrary.simpleMessage("Спасибі за передплату!"),
        "theDownloadCouldNotBeCompleted": MessageLookupByLibrary.simpleMessage(
            "Завантаження не може бути завершено"),
        "theLinkYouAreTryingToAccessHasExpired":
            MessageLookupByLibrary.simpleMessage(
                "Термін дії посилання, за яким ви намагаєтеся отримати доступ, закінчився."),
        "theRecoveryKeyYouEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "Ви ввели невірний ключ відновлення"),
        "theme": MessageLookupByLibrary.simpleMessage("Тема"),
        "theseItemsWillBeDeletedFromYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Ці елементи будуть видалені з пристрою."),
        "theyAlsoGetXGb": m99,
        "theyWillBeDeletedFromAllAlbums": MessageLookupByLibrary.simpleMessage(
            "Вони будуть видалені з усіх альбомів."),
        "thisActionCannotBeUndone": MessageLookupByLibrary.simpleMessage(
            "Цю дію не можна буде скасувати"),
        "thisAlbumAlreadyHDACollaborativeLink":
            MessageLookupByLibrary.simpleMessage(
                "Цей альбом вже має спільне посилання"),
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "Це може бути використано для відновлення вашого облікового запису, якщо ви втратите свій автентифікатор"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Цей пристрій"),
        "thisEmailIsAlreadyInUse": MessageLookupByLibrary.simpleMessage(
            "Ця поштова адреса вже використовується"),
        "thisImageHasNoExifData": MessageLookupByLibrary.simpleMessage(
            "Це зображення не має даних exif"),
        "thisIsPersonVerificationId": m100,
        "thisIsYourVerificationId": MessageLookupByLibrary.simpleMessage(
            "Це ваш Ідентифікатор підтвердження"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Це призведе до виходу на наступному пристрої:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Це призведе до виходу на цьому пристрої!"),
        "thisWillRemovePublicLinksOfAllSelectedQuickLinks":
            MessageLookupByLibrary.simpleMessage(
                "Це видалить публічні посилання з усіх вибраних швидких посилань."),
        "toEnableAppLockPleaseSetupDevicePasscodeOrScreen":
            MessageLookupByLibrary.simpleMessage(
                "Для увімкнення блокування застосунку, налаштуйте пароль пристрою або блокування екрана в системних налаштуваннях."),
        "toHideAPhotoOrVideo": MessageLookupByLibrary.simpleMessage(
            "Щоб приховати фото або відео"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "Щоб скинути пароль, спочатку підтвердьте адресу своєї пошти."),
        "todaysLogs":
            MessageLookupByLibrary.simpleMessage("Сьогоднішні журнали"),
        "tooManyIncorrectAttempts": MessageLookupByLibrary.simpleMessage(
            "Завелика кількість невірних спроб"),
        "total": MessageLookupByLibrary.simpleMessage("всього"),
        "totalSize": MessageLookupByLibrary.simpleMessage("Загальний розмір"),
        "trash": MessageLookupByLibrary.simpleMessage("Смітник"),
        "trashDaysLeft": m103,
        "trim": MessageLookupByLibrary.simpleMessage("Вирізати"),
        "trustedContacts":
            MessageLookupByLibrary.simpleMessage("Довірені контакти"),
        "trustedInviteBody": m106,
        "tryAgain": MessageLookupByLibrary.simpleMessage("Спробувати знову"),
        "turnOnBackupForAutoUpload": MessageLookupByLibrary.simpleMessage(
            "Увімкніть резервну копію для автоматичного завантаження файлів, доданих до теки пристрою в Ente."),
        "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
        "twoMonthsFreeOnYearlyPlans": MessageLookupByLibrary.simpleMessage(
            "2 місяці безплатно на щорічних планах"),
        "twofactor": MessageLookupByLibrary.simpleMessage("Двоетапна"),
        "twofactorAuthenticationHasBeenDisabled":
            MessageLookupByLibrary.simpleMessage(
                "Двоетапну перевірку вимкнено"),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage("Двоетапна перевірка"),
        "twofactorAuthenticationSuccessfullyReset":
            MessageLookupByLibrary.simpleMessage(
                "Двоетапну перевірку успішно скинуто"),
        "twofactorSetup": MessageLookupByLibrary.simpleMessage(
            "Налаштування двоетапної перевірки"),
        "typeOfGallerGallerytypeIsNotSupportedForRename": m107,
        "unarchive": MessageLookupByLibrary.simpleMessage("Розархівувати"),
        "unarchiveAlbum":
            MessageLookupByLibrary.simpleMessage("Розархівувати альбом"),
        "unarchiving": MessageLookupByLibrary.simpleMessage("Розархівуємо..."),
        "unavailableReferralCode": MessageLookupByLibrary.simpleMessage(
            "На жаль, цей код недоступний."),
        "uncategorized": MessageLookupByLibrary.simpleMessage("Без категорії"),
        "unhide": MessageLookupByLibrary.simpleMessage("Показати"),
        "unhideToAlbum":
            MessageLookupByLibrary.simpleMessage("Показати в альбомі"),
        "unhiding": MessageLookupByLibrary.simpleMessage("Показуємо..."),
        "unhidingFilesToAlbum":
            MessageLookupByLibrary.simpleMessage("Розкриваємо файли в альбомі"),
        "unlock": MessageLookupByLibrary.simpleMessage("Розблокувати"),
        "unpinAlbum": MessageLookupByLibrary.simpleMessage("Відкріпити альбом"),
        "unselectAll": MessageLookupByLibrary.simpleMessage("Зняти виділення"),
        "update": MessageLookupByLibrary.simpleMessage("Оновити"),
        "updateAvailable":
            MessageLookupByLibrary.simpleMessage("Доступне оновлення"),
        "updatingFolderSelection":
            MessageLookupByLibrary.simpleMessage("Оновлення вибору теки..."),
        "upgrade": MessageLookupByLibrary.simpleMessage("Покращити"),
        "uploadIsIgnoredDueToIgnorereason": m108,
        "uploadingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Завантажуємо файли до альбому..."),
        "uploadingMultipleMemories": m109,
        "uploadingSingleMemory":
            MessageLookupByLibrary.simpleMessage("Зберігаємо 1 спогад..."),
        "upto50OffUntil4thDec":
            MessageLookupByLibrary.simpleMessage("Знижки до 50%, до 4 грудня."),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "Доступний обсяг пам\'яті обмежений вашим поточним тарифом. Надлишок заявленого обсягу автоматично стане доступним, коли ви покращите тариф."),
        "useAsCover":
            MessageLookupByLibrary.simpleMessage("Використати як обкладинку"),
        "useDifferentPlayerInfo": MessageLookupByLibrary.simpleMessage(
            "Виникли проблеми з відтворенням цього відео? Натисніть і утримуйте тут, щоб спробувати інший плеєр."),
        "usePublicLinksForPeopleNotOnEnte":
            MessageLookupByLibrary.simpleMessage(
                "Використовувати публічні посилання для людей не з Ente"),
        "useRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Застосувати ключ відновлення"),
        "useSelectedPhoto":
            MessageLookupByLibrary.simpleMessage("Використати вибране фото"),
        "usedSpace": MessageLookupByLibrary.simpleMessage("Використано місця"),
        "validTill": m110,
        "verificationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Перевірка не вдалася, спробуйте ще раз"),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("Ідентифікатор підтвердження"),
        "verify": MessageLookupByLibrary.simpleMessage("Підтвердити"),
        "verifyEmail":
            MessageLookupByLibrary.simpleMessage("Підтвердити пошту"),
        "verifyEmailID": m111,
        "verifyIDLabel": MessageLookupByLibrary.simpleMessage("Підтвердження"),
        "verifyPasskey":
            MessageLookupByLibrary.simpleMessage("Підтвердити ключ доступу"),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Підтвердження пароля"),
        "verifying": MessageLookupByLibrary.simpleMessage("Перевіряємо..."),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Перевірка ключа відновлення..."),
        "videoInfo":
            MessageLookupByLibrary.simpleMessage("Інформація про відео"),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("відео"),
        "videos": MessageLookupByLibrary.simpleMessage("Відео"),
        "viewActiveSessions":
            MessageLookupByLibrary.simpleMessage("Показати активні сеанси"),
        "viewAddOnButton":
            MessageLookupByLibrary.simpleMessage("Переглянути доповнення"),
        "viewAll": MessageLookupByLibrary.simpleMessage("Переглянути все"),
        "viewAllExifData":
            MessageLookupByLibrary.simpleMessage("Переглянути всі дані EXIF"),
        "viewLargeFiles": MessageLookupByLibrary.simpleMessage("Великі файли"),
        "viewLargeFilesDesc": MessageLookupByLibrary.simpleMessage(
            "Перегляньте файли, які займають найбільше місця у сховищі."),
        "viewLogs": MessageLookupByLibrary.simpleMessage("Переглянути журнали"),
        "viewRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Переглянути ключ відновлення"),
        "viewer": MessageLookupByLibrary.simpleMessage("Глядач"),
        "visitWebToManage": MessageLookupByLibrary.simpleMessage(
            "Відвідайте web.ente.io, щоб керувати передплатою"),
        "waitingForVerification":
            MessageLookupByLibrary.simpleMessage("Очікується підтвердження..."),
        "waitingForWifi":
            MessageLookupByLibrary.simpleMessage("Очікування на Wi-Fi..."),
        "warning": MessageLookupByLibrary.simpleMessage("Увага"),
        "weAreOpenSource": MessageLookupByLibrary.simpleMessage(
            "У нас відкритий вихідний код!"),
        "weDontSupportEditingPhotosAndAlbumsThatYouDont":
            MessageLookupByLibrary.simpleMessage(
                "Ми не підтримуємо редагування фотографій та альбомів, якими ви ще не володієте"),
        "weHaveSendEmailTo": m114,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Слабкий"),
        "welcomeBack": MessageLookupByLibrary.simpleMessage("З поверненням!"),
        "whatsNew": MessageLookupByLibrary.simpleMessage("Що нового"),
        "whyAddTrustContact": MessageLookupByLibrary.simpleMessage(
            "Довірений контакт може допомогти у відновленні ваших даних."),
        "wishThemAHappyBirthday": m115,
        "yearShort": MessageLookupByLibrary.simpleMessage("рік"),
        "yearly": MessageLookupByLibrary.simpleMessage("Щороку"),
        "yearsAgo": m116,
        "yes": MessageLookupByLibrary.simpleMessage("Так"),
        "yesCancel": MessageLookupByLibrary.simpleMessage("Так, скасувати"),
        "yesConvertToViewer":
            MessageLookupByLibrary.simpleMessage("Так, перетворити в глядача"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("Так, видалити"),
        "yesDiscardChanges":
            MessageLookupByLibrary.simpleMessage("Так, відхилити зміни"),
        "yesLogout": MessageLookupByLibrary.simpleMessage(
            "Так, вийти з облікового запису"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("Так, видалити"),
        "yesRenew": MessageLookupByLibrary.simpleMessage("Так, поновити"),
        "yesResetPerson":
            MessageLookupByLibrary.simpleMessage("Так, скинути особу"),
        "you": MessageLookupByLibrary.simpleMessage("Ви"),
        "youAreOnAFamilyPlan":
            MessageLookupByLibrary.simpleMessage("Ви на сімейному плані!"),
        "youAreOnTheLatestVersion": MessageLookupByLibrary.simpleMessage(
            "Ви використовуєте останню версію"),
        "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "* Ви можете максимально подвоїти своє сховище"),
        "youCanManageYourLinksInTheShareTab":
            MessageLookupByLibrary.simpleMessage(
                "Ви можете керувати посиланнями на вкладці «Поділитися»."),
        "youCanTrySearchingForADifferentQuery":
            MessageLookupByLibrary.simpleMessage(
                "Ви можете спробувати пошукати за іншим запитом."),
        "youCannotDowngradeToThisPlan": MessageLookupByLibrary.simpleMessage(
            "Ви не можете перейти до цього плану"),
        "youCannotShareWithYourself": MessageLookupByLibrary.simpleMessage(
            "Ви не можете поділитися із собою"),
        "youDontHaveAnyArchivedItems": MessageLookupByLibrary.simpleMessage(
            "У вас немає жодних архівних елементів."),
        "youHaveSuccessfullyFreedUp": m118,
        "yourAccountHasBeenDeleted": MessageLookupByLibrary.simpleMessage(
            "Ваш обліковий запис видалено"),
        "yourMap": MessageLookupByLibrary.simpleMessage("Ваша мапа"),
        "yourPlanWasSuccessfullyDowngraded":
            MessageLookupByLibrary.simpleMessage(
                "Ваш план був успішно знижено"),
        "yourPlanWasSuccessfullyUpgraded":
            MessageLookupByLibrary.simpleMessage("Ваш план успішно покращено"),
        "yourPurchaseWasSuccessful": MessageLookupByLibrary.simpleMessage(
            "Ваша покупка пройшла успішно"),
        "yourStorageDetailsCouldNotBeFetched":
            MessageLookupByLibrary.simpleMessage(
                "Не вдалося отримати деталі про ваше сховище"),
        "yourSubscriptionHasExpired": MessageLookupByLibrary.simpleMessage(
            "Термін дії вашої передплати скінчився"),
        "yourSubscriptionWasUpdatedSuccessfully":
            MessageLookupByLibrary.simpleMessage(
                "Вашу передплату успішно оновлено"),
        "yourVerificationCodeHasExpired": MessageLookupByLibrary.simpleMessage(
            "Термін дії коду підтвердження минув"),
        "youveNoFilesInThisAlbumThatCanBeDeleted":
            MessageLookupByLibrary.simpleMessage(
                "У цьому альбомі немає файлів, які можуть бути видалені"),
        "zoomOutToSeePhotos": MessageLookupByLibrary.simpleMessage(
            "Збільште, щоб побачити фотографії")
      };
}
