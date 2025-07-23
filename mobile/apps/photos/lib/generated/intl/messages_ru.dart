// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ru locale. All the
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
  String get localeName => 'ru';

  static String m0(title) => "${title} (Я)";

  static String m1(count) =>
      "${Intl.plural(count, zero: 'Добавить соавтора', one: 'Добавить соавтора', other: 'Добавить соавторов')}";

  static String m2(count) =>
      "${Intl.plural(count, one: 'Добавить элемент', other: 'Добавить элементы')}";

  static String m3(storageAmount, endDate) =>
      "Ваше дополнение на ${storageAmount} действительно до ${endDate}";

  static String m4(count) =>
      "${Intl.plural(count, zero: 'Добавить зрителя', one: 'Добавить зрителя', other: 'Добавить зрителей')}";

  static String m5(emailOrName) => "Добавлено ${emailOrName}";

  static String m6(albumName) => "Успешно добавлено в ${albumName}";

  static String m7(name) => "Любуясь ${name}";

  static String m8(count) =>
      "${Intl.plural(count, zero: 'Нет участников', one: '${count} участник', other: '${count} участников')}";

  static String m9(versionValue) => "Версия: ${versionValue}";

  static String m10(freeAmount, storageUnit) =>
      "Свободно ${freeAmount} ${storageUnit}";

  static String m11(name) => "Красивые виды с ${name}";

  static String m12(paymentProvider) =>
      "Пожалуйста, сначала отмените существующую подписку через ${paymentProvider}";

  static String m13(user) =>
      "${user} не сможет добавлять новые фото в этот альбом\n\nЭтот пользователь всё ещё сможет удалять существующие фото, добавленные им";

  static String m14(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {'true': 'Ваша семья получила ${storageAmountInGb} ГБ на данный момент', 'false': 'Вы получили ${storageAmountInGb} ГБ на данный момент', 'other': 'Вы получили ${storageAmountInGb} ГБ на данный момент!'})}";

  static String m15(albumName) => "Совместная ссылка создана для ${albumName}";

  static String m16(count) =>
      "${Intl.plural(count, zero: 'Добавлено 0 соавторов', one: 'Добавлен 1 соавтор', other: 'Добавлено ${count} соавторов')}";

  static String m17(email, numOfDays) =>
      "Вы собираетесь добавить ${email} в качестве доверенного контакта. Доверенный контакт сможет восстановить ваш аккаунт, если вы будете отсутствовать ${numOfDays} дней.";

  static String m18(familyAdminEmail) =>
      "Пожалуйста, свяжитесь с <green>${familyAdminEmail}</green> для управления подпиской";

  static String m19(provider) =>
      "Пожалуйста, свяжитесь с нами по адресу support@ente.io для управления вашей подпиской ${provider}.";

  static String m20(endpoint) => "Подключено к ${endpoint}";

  static String m21(count) =>
      "${Intl.plural(count, one: 'Удалить ${count} элемент', other: 'Удалить ${count} элементов')}";

  static String m22(count) =>
      "Также удалить фото (и видео), находящиеся в этих ${count} альбомах, из <bold>всех</bold> других альбомов, частью которых они являются?";

  static String m23(currentlyDeleting, totalCount) =>
      "Удаление ${currentlyDeleting} / ${totalCount}";

  static String m24(albumName) =>
      "Это удалит публичную ссылку для доступа к \"${albumName}\".";

  static String m25(supportEmail) =>
      "Пожалуйста, отправьте письмо на ${supportEmail} с вашего зарегистрированного адреса электронной почты";

  static String m26(count, storageSaved) =>
      "Вы удалили ${Intl.plural(count, one: '${count} дубликат', other: '${count} дубликатов')}, освободив (${storageSaved}!)";

  static String m27(count, formattedSize) =>
      "${count} файлов, по ${formattedSize} каждый";

  static String m28(name) =>
      "Этот адрес электронной почты уже связан с ${name}.";

  static String m29(newEmail) => "Электронная почта изменена на ${newEmail}";

  static String m30(email) => "${email} не имеет аккаунта Ente.";

  static String m31(email) =>
      "У ${email} нет аккаунта Ente.\n\nОтправьте ему приглашение для обмена фото.";

  static String m32(name) => "Обнимая ${name}";

  static String m33(text) => "Дополнительные фото найдены для ${text}";

  static String m34(name) => "Пир с ${name}";

  static String m35(count, formattedNumber) =>
      "${Intl.plural(count, one: '${formattedNumber} файл на этом устройстве был успешно сохранён', other: '${formattedNumber} файлов на этом устройстве были успешно сохранены')}";

  static String m36(count, formattedNumber) =>
      "${Intl.plural(count, one: '${formattedNumber} файл в этом альбоме был успешно сохранён', other: '${formattedNumber} файлов в этом альбоме были успешно сохранены')}";

  static String m37(storageAmountInGB) =>
      "${storageAmountInGB} ГБ каждый раз, когда кто-то подписывается на платный тариф и применяет ваш код";

  static String m38(endDate) =>
      "Бесплатный пробный период действителен до ${endDate}";

  static String m39(count) =>
      "Вы всё ещё сможете получить доступ к ${Intl.plural(count, one: 'нему', other: 'ним')} в Ente, пока у вас активна подписка";

  static String m40(sizeInMBorGB) => "Освободить ${sizeInMBorGB}";

  static String m41(count, formattedSize) =>
      "${Intl.plural(count, one: 'Его можно удалить с устройства, чтобы освободить ${formattedSize}', other: 'Их можно удалить с устройства, чтобы освободить ${formattedSize}')}";

  static String m42(currentlyProcessing, totalCount) =>
      "Обработка ${currentlyProcessing} / ${totalCount}";

  static String m43(name) => "Поход с ${name}";

  static String m44(count) =>
      "${Intl.plural(count, one: '${count} элемент', other: '${count} элементов')}";

  static String m45(name) => "В последний раз с ${name}";

  static String m46(email) =>
      "${email} пригласил вас стать доверенным контактом";

  static String m47(expiryTime) => "Ссылка истечёт ${expiryTime}";

  static String m48(email) => "Связать человека с ${email}";

  static String m49(personName, email) => "Это свяжет ${personName} с ${email}";

  static String m50(count, formattedCount) =>
      "${Intl.plural(count, zero: 'нет воспоминаний', one: '${formattedCount} воспоминание', other: '${formattedCount} воспоминаний')}";

  static String m51(count) =>
      "${Intl.plural(count, one: 'Переместить элемент', other: 'Переместить элементы')}";

  static String m52(albumName) => "Успешно перемещено в ${albumName}";

  static String m53(personName) => "Нет предложений для ${personName}";

  static String m54(name) => "Не ${name}?";

  static String m55(familyAdminEmail) =>
      "Пожалуйста, свяжитесь с ${familyAdminEmail} для изменения кода.";

  static String m56(name) => "Вечеринка с ${name}";

  static String m57(passwordStrengthValue) =>
      "Надёжность пароля: ${passwordStrengthValue}";

  static String m58(providerName) =>
      "Пожалуйста, обратитесь в поддержку ${providerName}, если с вас сняли деньги";

  static String m59(name, age) => "${name} исполнилось ${age}!";

  static String m60(name, age) => "${name} скоро исполнится ${age}";

  static String m61(count) =>
      "${Intl.plural(count, zero: 'Нет фото', one: '1 фото', other: '${count} фото')}";

  static String m62(count) =>
      "${Intl.plural(count, zero: '0 фотографий', one: '1 фотография', other: '${count} фотографий')}";

  static String m63(endDate) =>
      "Бесплатный пробный период действителен до ${endDate}.\nПосле этого вы можете выбрать платный тариф.";

  static String m64(toEmail) => "Пожалуйста, напишите нам на ${toEmail}";

  static String m65(toEmail) => "Пожалуйста, отправьте логи на \n${toEmail}";

  static String m66(name) => "Позируя с ${name}";

  static String m67(folderName) => "Обработка ${folderName}...";

  static String m68(storeName) => "Оцените нас в ${storeName}";

  static String m69(name) => "Вы переназначены на ${name}";

  static String m70(days, email) =>
      "Вы сможете получить доступ к аккаунту через ${days} дней. Уведомление будет отправлено на ${email}.";

  static String m71(email) =>
      "Теперь вы можете восстановить аккаунт ${email}, установив новый пароль.";

  static String m72(email) => "${email} пытается восстановить ваш аккаунт.";

  static String m73(storageInGB) =>
      "3. Вы оба получаете ${storageInGB} ГБ* бесплатно";

  static String m74(userEmail) =>
      "${userEmail} будет удалён из этого общего альбома\n\nВсе фото, добавленные этим пользователем, также будут удалены из альбома";

  static String m75(endDate) => "Подписка будет продлена ${endDate}";

  static String m76(name) => "Путешествие с ${name}";

  static String m77(count) =>
      "${Intl.plural(count, one: '${count} результат найден', other: '${count} результатов найдено')}";

  static String m78(snapshotLength, searchLength) =>
      "Несоответствие длины разделов: ${snapshotLength} != ${searchLength}";

  static String m79(count) => "${count} выбрано";

  static String m80(count) => "${count} выбрано";

  static String m81(count, yourCount) =>
      "${count} выбрано (${yourCount} ваших)";

  static String m82(name) => "Селфи с ${name}";

  static String m83(verificationID) =>
      "Вот мой идентификатор подтверждения: ${verificationID} для ente.io.";

  static String m84(verificationID) =>
      "Привет, можешь подтвердить, что это твой идентификатор подтверждения ente.io: ${verificationID}";

  static String m85(referralCode, referralStorageInGB) =>
      "Реферальный код Ente: ${referralCode} \n\nПримените его в разделе «Настройки» → «Общие» → «Рефералы», чтобы получить ${referralStorageInGB} ГБ бесплатно после подписки на платный тариф\n\nhttps://ente.io";

  static String m86(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Поделиться с конкретными людьми', one: 'Доступно 1 человеку', other: 'Доступно ${numberOfPeople} людям')}";

  static String m87(emailIDs) => "Доступен для ${emailIDs}";

  static String m88(fileType) =>
      "Это ${fileType} будет удалено с вашего устройства.";

  static String m89(fileType) =>
      "Это ${fileType} есть и в Ente, и на вашем устройстве.";

  static String m90(fileType) => "Это ${fileType} будет удалено из Ente.";

  static String m91(name) => "Спорт с ${name}";

  static String m92(name) => "В центре внимания ${name}";

  static String m93(storageAmountInGB) => "${storageAmountInGB} ГБ";

  static String m94(
    usedAmount,
    usedStorageUnit,
    totalAmount,
    totalStorageUnit,
  ) =>
      "Использовано ${usedAmount} ${usedStorageUnit} из ${totalAmount} ${totalStorageUnit}";

  static String m95(id) =>
      "Ваш ${id} уже связан с другим аккаунтом Ente.\nЕсли вы хотите использовать ${id} с этим аккаунтом, пожалуйста, свяжитесь с нашей службой поддержки";

  static String m96(endDate) => "Ваша подписка будет отменена ${endDate}";

  static String m97(completed, total) =>
      "${completed}/${total} воспоминаний сохранено";

  static String m98(ignoreReason) =>
      "Нажмите для загрузки. Загрузка игнорируется из-за ${ignoreReason}";

  static String m99(storageAmountInGB) =>
      "Они тоже получат ${storageAmountInGB} ГБ";

  static String m100(email) => "Это идентификатор подтверждения ${email}";

  static String m101(count) =>
      "${Intl.plural(count, one: 'Эта неделя, ${count} год назад', other: 'Эта неделя, ${count} лет назад')}";

  static String m102(dateFormat) => "${dateFormat} сквозь годы";

  static String m103(count) =>
      "${Intl.plural(count, zero: 'Скоро', one: '1 день', other: '${count} дней')}";

  static String m104(year) => "Поездка в ${year}";

  static String m105(location) => "Поездка в ${location}";

  static String m106(email) =>
      "Вы приглашены стать доверенным контактом ${email}.";

  static String m107(galleryType) =>
      "Тип галереи ${galleryType} не поддерживает переименование";

  static String m108(ignoreReason) =>
      "Загрузка игнорируется из-за ${ignoreReason}";

  static String m109(count) => "Сохранение ${count} воспоминаний...";

  static String m110(endDate) => "Действительно до ${endDate}";

  static String m111(email) => "Подтвердить ${email}";

  static String m112(name) => "Посмотреть ${name} для отмены привязки";

  static String m113(count) =>
      "${Intl.plural(count, zero: 'Добавлено 0 зрителей', one: 'Добавлен 1 зритель', other: 'Добавлено ${count} зрителей')}";

  static String m114(email) => "Мы отправили письмо на <green>${email}</green>";

  static String m115(name) => "Поздравляем ${name} с днем ​​рождения! 🎉";

  static String m116(count) =>
      "${Intl.plural(count, one: '${count} год назад', few: '${count} года назад', other: '${count} лет назад')}";

  static String m117(name) => "Вы и ${name}";

  static String m118(storageSaved) => "Вы успешно освободили ${storageSaved}!";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "aNewVersionOfEnteIsAvailable": MessageLookupByLibrary.simpleMessage(
      "Доступна новая версия Ente.",
    ),
    "about": MessageLookupByLibrary.simpleMessage("О программе"),
    "acceptTrustInvite": MessageLookupByLibrary.simpleMessage(
      "Принять приглашение",
    ),
    "account": MessageLookupByLibrary.simpleMessage("Аккаунт"),
    "accountIsAlreadyConfigured": MessageLookupByLibrary.simpleMessage(
      "Аккаунт уже настроен.",
    ),
    "accountOwnerPersonAppbarTitle": m0,
    "accountWelcomeBack": MessageLookupByLibrary.simpleMessage(
      "С возвращением!",
    ),
    "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
      "Я понимаю, что если я потеряю пароль, я могу потерять свои данные, так как они <underline>защищены сквозным шифрованием</underline>.",
    ),
    "actionNotSupportedOnFavouritesAlbum": MessageLookupByLibrary.simpleMessage(
      "Действие не поддерживается в альбоме «Избранное»",
    ),
    "activeSessions": MessageLookupByLibrary.simpleMessage("Активные сеансы"),
    "add": MessageLookupByLibrary.simpleMessage("Добавить"),
    "addAName": MessageLookupByLibrary.simpleMessage("Добавить имя"),
    "addANewEmail": MessageLookupByLibrary.simpleMessage(
      "Добавьте новую электронную почту",
    ),
    "addAlbumWidgetPrompt": MessageLookupByLibrary.simpleMessage(
      "Добавьте виджет альбома на главный экран и вернитесь сюда, чтобы настроить его.",
    ),
    "addCollaborator": MessageLookupByLibrary.simpleMessage(
      "Добавить соавтора",
    ),
    "addCollaborators": m1,
    "addFiles": MessageLookupByLibrary.simpleMessage("Добавить файлы"),
    "addFromDevice": MessageLookupByLibrary.simpleMessage(
      "Добавить с устройства",
    ),
    "addItem": m2,
    "addLocation": MessageLookupByLibrary.simpleMessage(
      "Добавить местоположение",
    ),
    "addLocationButton": MessageLookupByLibrary.simpleMessage("Добавить"),
    "addMemoriesWidgetPrompt": MessageLookupByLibrary.simpleMessage(
      "Добавьте виджет воспоминаний на главный экран и вернитесь сюда, чтобы настроить его.",
    ),
    "addMore": MessageLookupByLibrary.simpleMessage("Добавить ещё"),
    "addName": MessageLookupByLibrary.simpleMessage("Добавить имя"),
    "addNameOrMerge": MessageLookupByLibrary.simpleMessage(
      "Добавить имя или объединить",
    ),
    "addNew": MessageLookupByLibrary.simpleMessage("Добавить новое"),
    "addNewPerson": MessageLookupByLibrary.simpleMessage(
      "Добавить нового человека",
    ),
    "addOnPageSubtitle": MessageLookupByLibrary.simpleMessage(
      "Подробности дополнений",
    ),
    "addOnValidTill": m3,
    "addOns": MessageLookupByLibrary.simpleMessage("Дополнения"),
    "addParticipants": MessageLookupByLibrary.simpleMessage(
      "Добавить участников",
    ),
    "addPeopleWidgetPrompt": MessageLookupByLibrary.simpleMessage(
      "Добавьте виджет людей на главный экран и вернитесь сюда, чтобы настроить его.",
    ),
    "addPhotos": MessageLookupByLibrary.simpleMessage("Добавить фото"),
    "addSelected": MessageLookupByLibrary.simpleMessage("Добавить выбранные"),
    "addToAlbum": MessageLookupByLibrary.simpleMessage("Добавить в альбом"),
    "addToEnte": MessageLookupByLibrary.simpleMessage("Добавить в Ente"),
    "addToHiddenAlbum": MessageLookupByLibrary.simpleMessage(
      "Добавить в скрытый альбом",
    ),
    "addTrustedContact": MessageLookupByLibrary.simpleMessage(
      "Добавить доверенный контакт",
    ),
    "addViewer": MessageLookupByLibrary.simpleMessage("Добавить зрителя"),
    "addViewers": m4,
    "addYourPhotosNow": MessageLookupByLibrary.simpleMessage(
      "Добавьте ваши фото",
    ),
    "addedAs": MessageLookupByLibrary.simpleMessage("Добавлен как"),
    "addedBy": m5,
    "addedSuccessfullyTo": m6,
    "addingToFavorites": MessageLookupByLibrary.simpleMessage(
      "Добавление в избранное...",
    ),
    "admiringThem": m7,
    "advanced": MessageLookupByLibrary.simpleMessage("Расширенные"),
    "advancedSettings": MessageLookupByLibrary.simpleMessage("Расширенные"),
    "after1Day": MessageLookupByLibrary.simpleMessage("Через 1 день"),
    "after1Hour": MessageLookupByLibrary.simpleMessage("Через 1 час"),
    "after1Month": MessageLookupByLibrary.simpleMessage("Через 1 месяц"),
    "after1Week": MessageLookupByLibrary.simpleMessage("Через 1 неделю"),
    "after1Year": MessageLookupByLibrary.simpleMessage("Через 1 год"),
    "albumOwner": MessageLookupByLibrary.simpleMessage("Владелец"),
    "albumParticipantsCount": m8,
    "albumTitle": MessageLookupByLibrary.simpleMessage("Название альбома"),
    "albumUpdated": MessageLookupByLibrary.simpleMessage("Альбом обновлён"),
    "albums": MessageLookupByLibrary.simpleMessage("Альбомы"),
    "albumsWidgetDesc": MessageLookupByLibrary.simpleMessage(
      "Выберите альбомы, которые вы хотите видеть на главном экране.",
    ),
    "allClear": MessageLookupByLibrary.simpleMessage("✨ Всё чисто"),
    "allMemoriesPreserved": MessageLookupByLibrary.simpleMessage(
      "Все воспоминания сохранены",
    ),
    "allPersonGroupingWillReset": MessageLookupByLibrary.simpleMessage(
      "Все группы этого человека будут сброшены, и вы потеряете все предложения для него",
    ),
    "allUnnamedGroupsWillBeMergedIntoTheSelectedPerson":
        MessageLookupByLibrary.simpleMessage(
          "Все неназванные группы будут объединены в выбранного человека. Это можно отменить в обзоре истории предложений для данного человека.",
        ),
    "allWillShiftRangeBasedOnFirst": MessageLookupByLibrary.simpleMessage(
      "Это первое фото в группе. Остальные выбранные фото автоматически сместятся на основе новой даты",
    ),
    "allow": MessageLookupByLibrary.simpleMessage("Разрешить"),
    "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
      "Разрешить людям с этой ссылкой добавлять фото в общий альбом.",
    ),
    "allowAddingPhotos": MessageLookupByLibrary.simpleMessage(
      "Разрешить добавление фото",
    ),
    "allowAppToOpenSharedAlbumLinks": MessageLookupByLibrary.simpleMessage(
      "Разрешить приложению открывать ссылки на общие альбомы",
    ),
    "allowDownloads": MessageLookupByLibrary.simpleMessage(
      "Разрешить скачивание",
    ),
    "allowPeopleToAddPhotos": MessageLookupByLibrary.simpleMessage(
      "Разрешить людям добавлять фото",
    ),
    "allowPermBody": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, разрешите доступ к вашим фото через настройки устройства, чтобы Ente мог отображать и сохранять вашу библиотеку.",
    ),
    "allowPermTitle": MessageLookupByLibrary.simpleMessage(
      "Разрешить доступ к фото",
    ),
    "androidBiometricHint": MessageLookupByLibrary.simpleMessage(
      "Подтвердите личность",
    ),
    "androidBiometricNotRecognized": MessageLookupByLibrary.simpleMessage(
      "Не распознано. Попробуйте снова.",
    ),
    "androidBiometricRequiredTitle": MessageLookupByLibrary.simpleMessage(
      "Требуется биометрия",
    ),
    "androidBiometricSuccess": MessageLookupByLibrary.simpleMessage("Успешно"),
    "androidCancelButton": MessageLookupByLibrary.simpleMessage("Отмена"),
    "androidDeviceCredentialsRequiredTitle":
        MessageLookupByLibrary.simpleMessage(
          "Требуются учётные данные устройства",
        ),
    "androidDeviceCredentialsSetupDescription":
        MessageLookupByLibrary.simpleMessage(
          "Требуются учётные данные устройства",
        ),
    "androidGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
      "Биометрическая аутентификация не настроена. Перейдите в «Настройки» → «Безопасность», чтобы добавить её.",
    ),
    "androidIosWebDesktop": MessageLookupByLibrary.simpleMessage(
      "Android, iOS, браузер, компьютер",
    ),
    "androidSignInTitle": MessageLookupByLibrary.simpleMessage(
      "Требуется аутентификация",
    ),
    "appIcon": MessageLookupByLibrary.simpleMessage("Иконка приложения"),
    "appLock": MessageLookupByLibrary.simpleMessage("Блокировка приложения"),
    "appLockDescriptions": MessageLookupByLibrary.simpleMessage(
      "Выберите между экраном блокировки устройства и пользовательским с PIN-кодом или паролем.",
    ),
    "appVersion": m9,
    "appleId": MessageLookupByLibrary.simpleMessage("Идентификатор Apple"),
    "apply": MessageLookupByLibrary.simpleMessage("Применить"),
    "applyCodeTitle": MessageLookupByLibrary.simpleMessage("Применить код"),
    "appstoreSubscription": MessageLookupByLibrary.simpleMessage(
      "Подписка AppStore",
    ),
    "archive": MessageLookupByLibrary.simpleMessage("Архив"),
    "archiveAlbum": MessageLookupByLibrary.simpleMessage("Архивировать альбом"),
    "archiving": MessageLookupByLibrary.simpleMessage("Архивация..."),
    "areThey": MessageLookupByLibrary.simpleMessage("Они "),
    "areYouSureRemoveThisFaceFromPerson": MessageLookupByLibrary.simpleMessage(
      "Вы уверены, что хотите удалить лицо этого человека?",
    ),
    "areYouSureThatYouWantToLeaveTheFamily":
        MessageLookupByLibrary.simpleMessage(
          "Вы уверены, что хотите покинуть семейный тариф?",
        ),
    "areYouSureYouWantToCancel": MessageLookupByLibrary.simpleMessage(
      "Вы уверены, что хотите отменить?",
    ),
    "areYouSureYouWantToChangeYourPlan": MessageLookupByLibrary.simpleMessage(
      "Вы уверены, что хотите сменить тариф?",
    ),
    "areYouSureYouWantToExit": MessageLookupByLibrary.simpleMessage(
      "Вы уверены, что хотите выйти?",
    ),
    "areYouSureYouWantToIgnoreThesePersons":
        MessageLookupByLibrary.simpleMessage(
          "Вы уверены, что хотите игнорировать этих людей?",
        ),
    "areYouSureYouWantToIgnoreThisPerson": MessageLookupByLibrary.simpleMessage(
      "Вы уверены, что хотите игнорировать этого человека?",
    ),
    "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
      "Вы уверены, что хотите выйти?",
    ),
    "areYouSureYouWantToMergeThem": MessageLookupByLibrary.simpleMessage(
      "Вы уверены, что хотите их объединить?",
    ),
    "areYouSureYouWantToRenew": MessageLookupByLibrary.simpleMessage(
      "Вы уверены, что хотите продлить?",
    ),
    "areYouSureYouWantToResetThisPerson": MessageLookupByLibrary.simpleMessage(
      "Вы уверены, что хотите сбросить данные этого человека?",
    ),
    "askCancelReason": MessageLookupByLibrary.simpleMessage(
      "Ваша подписка была отменена. Не хотели бы вы поделиться причиной?",
    ),
    "askDeleteReason": MessageLookupByLibrary.simpleMessage(
      "Какова основная причина удаления вашего аккаунта?",
    ),
    "askYourLovedOnesToShare": MessageLookupByLibrary.simpleMessage(
      "Попросите близких поделиться",
    ),
    "atAFalloutShelter": MessageLookupByLibrary.simpleMessage("в бункере"),
    "authToChangeEmailVerificationSetting": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, авторизуйтесь для изменения настроек подтверждения электронной почты",
    ),
    "authToChangeLockscreenSetting": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, авторизуйтесь для изменения настроек экрана блокировки",
    ),
    "authToChangeYourEmail": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, авторизуйтесь для смены электронной почты",
    ),
    "authToChangeYourPassword": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, авторизуйтесь для смены пароля",
    ),
    "authToConfigureTwofactorAuthentication":
        MessageLookupByLibrary.simpleMessage(
          "Пожалуйста, авторизуйтесь для настройки двухфакторной аутентификации",
        ),
    "authToInitiateAccountDeletion": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, авторизуйтесь для начала процедуры удаления аккаунта",
    ),
    "authToManageLegacy": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, авторизуйтесь для управления доверенными контактами",
    ),
    "authToViewPasskey": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, авторизуйтесь для просмотра ключа доступа",
    ),
    "authToViewTrashedFiles": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, авторизуйтесь для просмотра удалённых файлов",
    ),
    "authToViewYourActiveSessions": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, авторизуйтесь для просмотра активных сессий",
    ),
    "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, авторизуйтесь для просмотра скрытых файлов",
    ),
    "authToViewYourMemories": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, авторизуйтесь для просмотра воспоминаний",
    ),
    "authToViewYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, авторизуйтесь для просмотра ключа восстановления",
    ),
    "authenticating": MessageLookupByLibrary.simpleMessage("Аутентификация..."),
    "authenticationFailedPleaseTryAgain": MessageLookupByLibrary.simpleMessage(
      "Аутентификация не удалась, пожалуйста, попробуйте снова",
    ),
    "authenticationSuccessful": MessageLookupByLibrary.simpleMessage(
      "Аутентификация прошла успешно!",
    ),
    "autoCastDialogBody": MessageLookupByLibrary.simpleMessage(
      "Здесь вы увидите доступные устройства.",
    ),
    "autoCastiOSPermission": MessageLookupByLibrary.simpleMessage(
      "Убедитесь, что для приложения Ente Photos включены разрешения локальной сети в настройках.",
    ),
    "autoLock": MessageLookupByLibrary.simpleMessage("Автоблокировка"),
    "autoLockFeatureDescription": MessageLookupByLibrary.simpleMessage(
      "Спустя какое время приложение блокируется после перехода в фоновый режим",
    ),
    "autoLogoutMessage": MessageLookupByLibrary.simpleMessage(
      "Из-за технического сбоя вы были выведены из системы. Приносим извинения за неудобства.",
    ),
    "autoPair": MessageLookupByLibrary.simpleMessage("Автоподключение"),
    "autoPairDesc": MessageLookupByLibrary.simpleMessage(
      "Автоподключение работает только с устройствами, поддерживающими Chromecast.",
    ),
    "available": MessageLookupByLibrary.simpleMessage("Доступно"),
    "availableStorageSpace": m10,
    "backedUpFolders": MessageLookupByLibrary.simpleMessage(
      "Папки для резервного копирования",
    ),
    "backgroundWithThem": m11,
    "backup": MessageLookupByLibrary.simpleMessage("Резервное копирование"),
    "backupFailed": MessageLookupByLibrary.simpleMessage(
      "Резервное копирование не удалось",
    ),
    "backupFile": MessageLookupByLibrary.simpleMessage(
      "Резервное копирование файла",
    ),
    "backupOverMobileData": MessageLookupByLibrary.simpleMessage(
      "Резервное копирование через мобильный интернет",
    ),
    "backupSettings": MessageLookupByLibrary.simpleMessage(
      "Настройки резервного копирования",
    ),
    "backupStatus": MessageLookupByLibrary.simpleMessage(
      "Статус резервного копирования",
    ),
    "backupStatusDescription": MessageLookupByLibrary.simpleMessage(
      "Элементы, сохранённые в резервной копии, появятся здесь",
    ),
    "backupVideos": MessageLookupByLibrary.simpleMessage(
      "Резервное копирование видео",
    ),
    "beach": MessageLookupByLibrary.simpleMessage("Песок и море"),
    "birthday": MessageLookupByLibrary.simpleMessage("День рождения"),
    "birthdayNotifications": MessageLookupByLibrary.simpleMessage(
      "Уведомления о днях рождения",
    ),
    "birthdays": MessageLookupByLibrary.simpleMessage("Дни рождения"),
    "blackFridaySale": MessageLookupByLibrary.simpleMessage(
      "Распродажа в \"Черную пятницу\"",
    ),
    "blog": MessageLookupByLibrary.simpleMessage("Блог"),
    "cLDesc1": MessageLookupByLibrary.simpleMessage(
      "В результате бета-тестирования потоковой передачи видео и работы над возобновляемыми загрузками и скачиваниями мы увеличили лимит загружаемых файлов до 10 ГБ. Теперь это доступно как в настольных, так и в мобильных приложениях.",
    ),
    "cLDesc2": MessageLookupByLibrary.simpleMessage(
      "Фоновая загрузка теперь поддерживается не только на устройствах Android, но и на iOS. Не нужно открывать приложение для резервного копирования последних фотографий и видео.",
    ),
    "cLDesc3": MessageLookupByLibrary.simpleMessage(
      "Мы внесли значительные улучшения в работу с воспоминаниями, включая автовоспроизведение, переход к следующему воспоминанию и многое другое.",
    ),
    "cLDesc4": MessageLookupByLibrary.simpleMessage(
      "Наряду с рядом внутренних улучшений теперь стало гораздо проще просматривать все обнаруженные лица, оставлять отзывы о похожих лицах, а также добавлять/удалять лица с одной фотографии.",
    ),
    "cLDesc5": MessageLookupByLibrary.simpleMessage(
      "Теперь вы будете получать уведомления о всех днях рождениях, которые вы сохранили на Ente, а также коллекцию их лучших фотографий.",
    ),
    "cLDesc6": MessageLookupByLibrary.simpleMessage(
      "Больше не нужно ждать завершения загрузки/скачивания, прежде чем закрыть приложение. Все загрузки и скачивания теперь можно приостановить и возобновить с того места, где вы остановились.",
    ),
    "cLTitle1": MessageLookupByLibrary.simpleMessage(
      "Загрузка больших видеофайлов",
    ),
    "cLTitle2": MessageLookupByLibrary.simpleMessage("Фоновая загрузка"),
    "cLTitle3": MessageLookupByLibrary.simpleMessage(
      "Автовоспроизведение воспоминаний",
    ),
    "cLTitle4": MessageLookupByLibrary.simpleMessage(
      "Улучшенное распознавание лиц",
    ),
    "cLTitle5": MessageLookupByLibrary.simpleMessage(
      "Уведомления о днях рождения",
    ),
    "cLTitle6": MessageLookupByLibrary.simpleMessage(
      "Возобновляемые загрузки и скачивания",
    ),
    "cachedData": MessageLookupByLibrary.simpleMessage("Кэшированные данные"),
    "calculating": MessageLookupByLibrary.simpleMessage("Подсчёт..."),
    "canNotOpenBody": MessageLookupByLibrary.simpleMessage(
      "Извините, этот альбом не может быть открыт в приложении.",
    ),
    "canNotOpenTitle": MessageLookupByLibrary.simpleMessage(
      "Не удаётся открыть этот альбом",
    ),
    "canNotUploadToAlbumsOwnedByOthers": MessageLookupByLibrary.simpleMessage(
      "Нельзя загружать в альбомы, принадлежащие другим",
    ),
    "canOnlyCreateLinkForFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
      "Можно создать ссылку только для ваших файлов",
    ),
    "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
      "Можно удалять только файлы, принадлежащие вам",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("Отменить"),
    "cancelAccountRecovery": MessageLookupByLibrary.simpleMessage(
      "Отменить восстановление",
    ),
    "cancelAccountRecoveryBody": MessageLookupByLibrary.simpleMessage(
      "Вы уверены, что хотите отменить восстановление?",
    ),
    "cancelOtherSubscription": m12,
    "cancelSubscription": MessageLookupByLibrary.simpleMessage(
      "Отменить подписку",
    ),
    "cannotAddMorePhotosAfterBecomingViewer": m13,
    "cannotDeleteSharedFiles": MessageLookupByLibrary.simpleMessage(
      "Нельзя удалить общие файлы",
    ),
    "castAlbum": MessageLookupByLibrary.simpleMessage("Транслировать альбом"),
    "castIPMismatchBody": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, убедитесь, что вы находитесь в одной сети с телевизором.",
    ),
    "castIPMismatchTitle": MessageLookupByLibrary.simpleMessage(
      "Не удалось транслировать альбом",
    ),
    "castInstruction": MessageLookupByLibrary.simpleMessage(
      "Посетите cast.ente.io на устройстве, которое хотите подключить.\n\nВведите код ниже, чтобы воспроизвести альбом на телевизоре.",
    ),
    "centerPoint": MessageLookupByLibrary.simpleMessage("Центральная точка"),
    "change": MessageLookupByLibrary.simpleMessage("Изменить"),
    "changeEmail": MessageLookupByLibrary.simpleMessage(
      "Изменить адрес электронной почты",
    ),
    "changeLocationOfSelectedItems": MessageLookupByLibrary.simpleMessage(
      "Изменить местоположение выбранных элементов?",
    ),
    "changePassword": MessageLookupByLibrary.simpleMessage("Сменить пароль"),
    "changePasswordTitle": MessageLookupByLibrary.simpleMessage(
      "Изменить пароль",
    ),
    "changePermissions": MessageLookupByLibrary.simpleMessage(
      "Изменить разрешения?",
    ),
    "changeYourReferralCode": MessageLookupByLibrary.simpleMessage(
      "Изменить ваш реферальный код",
    ),
    "checkForUpdates": MessageLookupByLibrary.simpleMessage(
      "Проверить обновления",
    ),
    "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, проверьте ваш почтовый ящик (и спам) для завершения верификации",
    ),
    "checkStatus": MessageLookupByLibrary.simpleMessage("Проверить статус"),
    "checking": MessageLookupByLibrary.simpleMessage("Проверка..."),
    "checkingModels": MessageLookupByLibrary.simpleMessage(
      "Проверка моделей...",
    ),
    "city": MessageLookupByLibrary.simpleMessage("В городе"),
    "claimFreeStorage": MessageLookupByLibrary.simpleMessage(
      "Получить бесплатное хранилище",
    ),
    "claimMore": MessageLookupByLibrary.simpleMessage("Получите больше!"),
    "claimed": MessageLookupByLibrary.simpleMessage("Получено"),
    "claimedStorageSoFar": m14,
    "cleanUncategorized": MessageLookupByLibrary.simpleMessage(
      "Очистить «Без категории»",
    ),
    "cleanUncategorizedDescription": MessageLookupByLibrary.simpleMessage(
      "Удалить из «Без категории» все файлы, присутствующие в других альбомах",
    ),
    "clearCaches": MessageLookupByLibrary.simpleMessage("Очистить кэш"),
    "clearIndexes": MessageLookupByLibrary.simpleMessage("Удалить индексы"),
    "click": MessageLookupByLibrary.simpleMessage("• Нажмите"),
    "clickOnTheOverflowMenu": MessageLookupByLibrary.simpleMessage(
      "• Нажмите на меню дополнительных действий",
    ),
    "clickToInstallOurBestVersionYet": MessageLookupByLibrary.simpleMessage(
      "Нажмите, чтобы установить нашу лучшую версию",
    ),
    "close": MessageLookupByLibrary.simpleMessage("Закрыть"),
    "clubByCaptureTime": MessageLookupByLibrary.simpleMessage(
      "Группировать по времени съёмки",
    ),
    "clubByFileName": MessageLookupByLibrary.simpleMessage(
      "Группировать по имени файла",
    ),
    "clusteringProgress": MessageLookupByLibrary.simpleMessage(
      "Прогресс кластеризации",
    ),
    "codeAppliedPageTitle": MessageLookupByLibrary.simpleMessage(
      "Код применён",
    ),
    "codeChangeLimitReached": MessageLookupByLibrary.simpleMessage(
      "Извините, вы достигли лимита изменений кода.",
    ),
    "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
      "Код скопирован в буфер обмена",
    ),
    "codeUsedByYou": MessageLookupByLibrary.simpleMessage(
      "Код, использованный вами",
    ),
    "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
      "Создайте ссылку, чтобы люди могли добавлять и просматривать фото в вашем общем альбоме без использования приложения или аккаунта Ente. Это отлично подходит для сбора фото с мероприятий.",
    ),
    "collaborativeLink": MessageLookupByLibrary.simpleMessage(
      "Совместная ссылка",
    ),
    "collaborativeLinkCreatedFor": m15,
    "collaborator": MessageLookupByLibrary.simpleMessage("Соавтор"),
    "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
        MessageLookupByLibrary.simpleMessage(
          "Соавторы могут добавлять фото и видео в общий альбом.",
        ),
    "collaboratorsSuccessfullyAdded": m16,
    "collageLayout": MessageLookupByLibrary.simpleMessage("Макет"),
    "collageSaved": MessageLookupByLibrary.simpleMessage(
      "Коллаж сохранён в галерее",
    ),
    "collect": MessageLookupByLibrary.simpleMessage("Собрать"),
    "collectEventPhotos": MessageLookupByLibrary.simpleMessage(
      "Собрать фото с мероприятия",
    ),
    "collectPhotos": MessageLookupByLibrary.simpleMessage("Сбор фото"),
    "collectPhotosDescription": MessageLookupByLibrary.simpleMessage(
      "Создайте ссылку, по которой ваши друзья смогут загружать фото в оригинальном качестве.",
    ),
    "color": MessageLookupByLibrary.simpleMessage("Цвет"),
    "configuration": MessageLookupByLibrary.simpleMessage("Настройки"),
    "confirm": MessageLookupByLibrary.simpleMessage("Подтвердить"),
    "confirm2FADisable": MessageLookupByLibrary.simpleMessage(
      "Вы уверены, что хотите отключить двухфакторную аутентификацию?",
    ),
    "confirmAccountDeletion": MessageLookupByLibrary.simpleMessage(
      "Подтвердить удаление аккаунта",
    ),
    "confirmAddingTrustedContact": m17,
    "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
      "Да, я хочу навсегда удалить этот аккаунт и все его данные во всех приложениях.",
    ),
    "confirmPassword": MessageLookupByLibrary.simpleMessage(
      "Подтвердите пароль",
    ),
    "confirmPlanChange": MessageLookupByLibrary.simpleMessage(
      "Подтвердить смену тарифа",
    ),
    "confirmRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Подтвердить ключ восстановления",
    ),
    "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Подтвердите ваш ключ восстановления",
    ),
    "connectToDevice": MessageLookupByLibrary.simpleMessage(
      "Подключиться к устройству",
    ),
    "contactFamilyAdmin": m18,
    "contactSupport": MessageLookupByLibrary.simpleMessage(
      "Связаться с поддержкой",
    ),
    "contactToManageSubscription": m19,
    "contacts": MessageLookupByLibrary.simpleMessage("Контакты"),
    "contents": MessageLookupByLibrary.simpleMessage("Содержимое"),
    "continueLabel": MessageLookupByLibrary.simpleMessage("Продолжить"),
    "continueOnFreeTrial": MessageLookupByLibrary.simpleMessage(
      "Продолжить с бесплатным пробным периодом",
    ),
    "convertToAlbum": MessageLookupByLibrary.simpleMessage(
      "Преобразовать в альбом",
    ),
    "copyEmailAddress": MessageLookupByLibrary.simpleMessage(
      "Скопировать адрес электронной почты",
    ),
    "copyLink": MessageLookupByLibrary.simpleMessage("Скопировать ссылку"),
    "copypasteThisCodentoYourAuthenticatorApp":
        MessageLookupByLibrary.simpleMessage(
          "Скопируйте этот код\nв ваше приложение для аутентификации",
        ),
    "couldNotBackUpTryLater": MessageLookupByLibrary.simpleMessage(
      "Нам не удалось создать резервную копию ваших данных.\nМы повторим попытку позже.",
    ),
    "couldNotFreeUpSpace": MessageLookupByLibrary.simpleMessage(
      "Не удалось освободить место",
    ),
    "couldNotUpdateSubscription": MessageLookupByLibrary.simpleMessage(
      "Не удалось обновить подписку",
    ),
    "count": MessageLookupByLibrary.simpleMessage("Количество"),
    "crashReporting": MessageLookupByLibrary.simpleMessage("Отчёты об ошибках"),
    "create": MessageLookupByLibrary.simpleMessage("Создать"),
    "createAccount": MessageLookupByLibrary.simpleMessage("Создать аккаунт"),
    "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
      "Нажмите и удерживайте, чтобы выбрать фото, и нажмите «+», чтобы создать альбом",
    ),
    "createCollaborativeLink": MessageLookupByLibrary.simpleMessage(
      "Создать совместную ссылку",
    ),
    "createCollage": MessageLookupByLibrary.simpleMessage("Создать коллаж"),
    "createNewAccount": MessageLookupByLibrary.simpleMessage(
      "Создать новый аккаунт",
    ),
    "createOrSelectAlbum": MessageLookupByLibrary.simpleMessage(
      "Создать или выбрать альбом",
    ),
    "createPublicLink": MessageLookupByLibrary.simpleMessage(
      "Создать публичную ссылку",
    ),
    "creatingLink": MessageLookupByLibrary.simpleMessage("Создание ссылки..."),
    "criticalUpdateAvailable": MessageLookupByLibrary.simpleMessage(
      "Доступно критическое обновление",
    ),
    "crop": MessageLookupByLibrary.simpleMessage("Обрезать"),
    "curatedMemories": MessageLookupByLibrary.simpleMessage(
      "Отобранные воспоминания",
    ),
    "currentUsageIs": MessageLookupByLibrary.simpleMessage(
      "Текущее использование составляет ",
    ),
    "currentlyRunning": MessageLookupByLibrary.simpleMessage("выполняется"),
    "custom": MessageLookupByLibrary.simpleMessage("Пользовательский"),
    "customEndpoint": m20,
    "darkTheme": MessageLookupByLibrary.simpleMessage("Тёмная"),
    "dayToday": MessageLookupByLibrary.simpleMessage("Сегодня"),
    "dayYesterday": MessageLookupByLibrary.simpleMessage("Вчера"),
    "declineTrustInvite": MessageLookupByLibrary.simpleMessage(
      "Отклонить приглашение",
    ),
    "decrypting": MessageLookupByLibrary.simpleMessage("Расшифровка..."),
    "decryptingVideo": MessageLookupByLibrary.simpleMessage(
      "Расшифровка видео...",
    ),
    "deduplicateFiles": MessageLookupByLibrary.simpleMessage(
      "Удалить дубликаты файлов",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("Удалить"),
    "deleteAccount": MessageLookupByLibrary.simpleMessage("Удалить аккаунт"),
    "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
      "Нам жаль, что вы уходите. Пожалуйста, поделитесь мнением о том, как мы могли бы стать лучше.",
    ),
    "deleteAccountPermanentlyButton": MessageLookupByLibrary.simpleMessage(
      "Удалить аккаунт навсегда",
    ),
    "deleteAlbum": MessageLookupByLibrary.simpleMessage("Удалить альбом"),
    "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
      "Также удалить фото (и видео), находящиеся в этом альбоме, из <bold>всех</bold> других альбомов, частью которых они являются?",
    ),
    "deleteAlbumsDialogBody": MessageLookupByLibrary.simpleMessage(
      "Это удалит все пустые альбомы. Это может быть полезно, если вы хотите навести порядок в списке альбомов.",
    ),
    "deleteAll": MessageLookupByLibrary.simpleMessage("Удалить всё"),
    "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
      "Этот аккаунт связан с другими приложениями Ente, если вы их используете. Все загруженные данные во всех приложениях Ente будут поставлены в очередь на удаление, а ваш аккаунт будет удален навсегда.",
    ),
    "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, отправьте письмо на <warning>account-deletion@ente.io</warning> с вашего зарегистрированного адреса электронной почты.",
    ),
    "deleteEmptyAlbums": MessageLookupByLibrary.simpleMessage(
      "Удалить пустые альбомы",
    ),
    "deleteEmptyAlbumsWithQuestionMark": MessageLookupByLibrary.simpleMessage(
      "Удалить пустые альбомы?",
    ),
    "deleteFromBoth": MessageLookupByLibrary.simpleMessage(
      "Удалить из обоих мест",
    ),
    "deleteFromDevice": MessageLookupByLibrary.simpleMessage(
      "Удалить с устройства",
    ),
    "deleteFromEnte": MessageLookupByLibrary.simpleMessage("Удалить из Ente"),
    "deleteItemCount": m21,
    "deleteLocation": MessageLookupByLibrary.simpleMessage(
      "Удалить местоположение",
    ),
    "deleteMultipleAlbumDialog": m22,
    "deletePhotos": MessageLookupByLibrary.simpleMessage("Удалить фото"),
    "deleteProgress": m23,
    "deleteReason1": MessageLookupByLibrary.simpleMessage(
      "Отсутствует необходимая функция",
    ),
    "deleteReason2": MessageLookupByLibrary.simpleMessage(
      "Приложение или определённая функция работают не так, как я ожидал",
    ),
    "deleteReason3": MessageLookupByLibrary.simpleMessage(
      "Я нашёл другой сервис, который мне больше нравится",
    ),
    "deleteReason4": MessageLookupByLibrary.simpleMessage(
      "Моя причина не указана",
    ),
    "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
      "Ваш запрос будет обработан в течение 72 часов.",
    ),
    "deleteSharedAlbum": MessageLookupByLibrary.simpleMessage(
      "Удалить общий альбом?",
    ),
    "deleteSharedAlbumDialogBody": MessageLookupByLibrary.simpleMessage(
      "Альбом будет удалён для всех\n\nВы потеряете доступ к общим фото в этом альбоме, принадлежащим другим",
    ),
    "deselectAll": MessageLookupByLibrary.simpleMessage("Отменить выделение"),
    "designedToOutlive": MessageLookupByLibrary.simpleMessage(
      "Создано на века",
    ),
    "details": MessageLookupByLibrary.simpleMessage("Подробности"),
    "developerSettings": MessageLookupByLibrary.simpleMessage(
      "Настройки для разработчиков",
    ),
    "developerSettingsWarning": MessageLookupByLibrary.simpleMessage(
      "Вы уверены, что хотите изменить настройки для разработчиков?",
    ),
    "deviceCodeHint": MessageLookupByLibrary.simpleMessage("Введите код"),
    "deviceFilesAutoUploading": MessageLookupByLibrary.simpleMessage(
      "Файлы, добавленные в этот альбом на устройстве, будут автоматически загружены в Ente.",
    ),
    "deviceLock": MessageLookupByLibrary.simpleMessage("Блокировка устройства"),
    "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
      "Отключить блокировку экрана устройства, когда Ente на экране, и выполняется резервное копирование. Обычно это не требуется, но это может ускорить завершение больших загрузок и первоначального импортирования крупных библиотек.",
    ),
    "deviceNotFound": MessageLookupByLibrary.simpleMessage(
      "Устройство не найдено",
    ),
    "didYouKnow": MessageLookupByLibrary.simpleMessage("Знаете ли вы?"),
    "different": MessageLookupByLibrary.simpleMessage("Разные"),
    "disableAutoLock": MessageLookupByLibrary.simpleMessage(
      "Отключить автоблокировку",
    ),
    "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
      "Зрители всё ещё могут делать скриншоты или сохранять копии ваших фото с помощью внешних инструментов",
    ),
    "disableDownloadWarningTitle": MessageLookupByLibrary.simpleMessage(
      "Обратите внимание",
    ),
    "disableLinkMessage": m24,
    "disableTwofactor": MessageLookupByLibrary.simpleMessage(
      "Отключить двухфакторную аутентификацию",
    ),
    "disablingTwofactorAuthentication": MessageLookupByLibrary.simpleMessage(
      "Отключение двухфакторной аутентификации...",
    ),
    "discord": MessageLookupByLibrary.simpleMessage("Discord"),
    "discover": MessageLookupByLibrary.simpleMessage("Откройте для себя"),
    "discover_babies": MessageLookupByLibrary.simpleMessage("Малыши"),
    "discover_celebrations": MessageLookupByLibrary.simpleMessage("Праздники"),
    "discover_food": MessageLookupByLibrary.simpleMessage("Еда"),
    "discover_greenery": MessageLookupByLibrary.simpleMessage("Зелень"),
    "discover_hills": MessageLookupByLibrary.simpleMessage("Холмы"),
    "discover_identity": MessageLookupByLibrary.simpleMessage("Документы"),
    "discover_memes": MessageLookupByLibrary.simpleMessage("Мемы"),
    "discover_notes": MessageLookupByLibrary.simpleMessage("Заметки"),
    "discover_pets": MessageLookupByLibrary.simpleMessage("Питомцы"),
    "discover_receipts": MessageLookupByLibrary.simpleMessage("Чеки"),
    "discover_screenshots": MessageLookupByLibrary.simpleMessage("Скриншоты"),
    "discover_selfies": MessageLookupByLibrary.simpleMessage("Селфи"),
    "discover_sunset": MessageLookupByLibrary.simpleMessage("Закат"),
    "discover_visiting_cards": MessageLookupByLibrary.simpleMessage("Визитки"),
    "discover_wallpapers": MessageLookupByLibrary.simpleMessage("Обои"),
    "dismiss": MessageLookupByLibrary.simpleMessage("Отклонить"),
    "distanceInKMUnit": MessageLookupByLibrary.simpleMessage("км"),
    "doNotSignOut": MessageLookupByLibrary.simpleMessage("Не выходить"),
    "doThisLater": MessageLookupByLibrary.simpleMessage("Сделать это позже"),
    "doYouWantToDiscardTheEditsYouHaveMade":
        MessageLookupByLibrary.simpleMessage(
          "Хотите отменить сделанные изменения?",
        ),
    "done": MessageLookupByLibrary.simpleMessage("Готово"),
    "dontSave": MessageLookupByLibrary.simpleMessage("Не сохранять"),
    "doubleYourStorage": MessageLookupByLibrary.simpleMessage(
      "Удвойте своё хранилище",
    ),
    "download": MessageLookupByLibrary.simpleMessage("Скачать"),
    "downloadFailed": MessageLookupByLibrary.simpleMessage(
      "Скачивание не удалось",
    ),
    "downloading": MessageLookupByLibrary.simpleMessage("Скачивание..."),
    "dropSupportEmail": m25,
    "duplicateFileCountWithStorageSaved": m26,
    "duplicateItemsGroup": m27,
    "edit": MessageLookupByLibrary.simpleMessage("Редактировать"),
    "editEmailAlreadyLinked": m28,
    "editLocation": MessageLookupByLibrary.simpleMessage(
      "Изменить местоположение",
    ),
    "editLocationTagTitle": MessageLookupByLibrary.simpleMessage(
      "Изменить местоположение",
    ),
    "editPerson": MessageLookupByLibrary.simpleMessage(
      "Редактировать человека",
    ),
    "editTime": MessageLookupByLibrary.simpleMessage("Изменить время"),
    "editsSaved": MessageLookupByLibrary.simpleMessage("Изменения сохранены"),
    "editsToLocationWillOnlyBeSeenWithinEnte":
        MessageLookupByLibrary.simpleMessage(
          "Изменения в местоположении будут видны только в Ente",
        ),
    "eligible": MessageLookupByLibrary.simpleMessage("доступно"),
    "email": MessageLookupByLibrary.simpleMessage("Электронная почта"),
    "emailAlreadyRegistered": MessageLookupByLibrary.simpleMessage(
      "Электронная почта уже зарегистрирована.",
    ),
    "emailChangedTo": m29,
    "emailDoesNotHaveEnteAccount": m30,
    "emailNoEnteAccount": m31,
    "emailNotRegistered": MessageLookupByLibrary.simpleMessage(
      "Электронная почта не зарегистрирована.",
    ),
    "emailVerificationToggle": MessageLookupByLibrary.simpleMessage(
      "Подтверждение входа по почте",
    ),
    "emailYourLogs": MessageLookupByLibrary.simpleMessage(
      "Отправить логи по электронной почте",
    ),
    "embracingThem": m32,
    "emergencyContacts": MessageLookupByLibrary.simpleMessage(
      "Экстренные контакты",
    ),
    "empty": MessageLookupByLibrary.simpleMessage("Очистить"),
    "emptyTrash": MessageLookupByLibrary.simpleMessage("Очистить корзину?"),
    "enable": MessageLookupByLibrary.simpleMessage("Включить"),
    "enableMLIndexingDesc": MessageLookupByLibrary.simpleMessage(
      "Ente поддерживает машинное обучение прямо на устройстве для распознавания лиц, магического поиска и других поисковых функций",
    ),
    "enableMachineLearningBanner": MessageLookupByLibrary.simpleMessage(
      "Включите машинное обучение для магического поиска и распознавания лиц",
    ),
    "enableMaps": MessageLookupByLibrary.simpleMessage("Включить Карты"),
    "enableMapsDesc": MessageLookupByLibrary.simpleMessage(
      "Ваши фото будут отображены на карте мира.\n\nЭта карта размещена на OpenStreetMap, и точное местоположение ваших фото никогда не разглашается.\n\nВы можете отключить эту функцию в любое время в настройках.",
    ),
    "enabled": MessageLookupByLibrary.simpleMessage("Включено"),
    "encryptingBackup": MessageLookupByLibrary.simpleMessage(
      "Шифрование резервной копии...",
    ),
    "encryption": MessageLookupByLibrary.simpleMessage("Шифрование"),
    "encryptionKeys": MessageLookupByLibrary.simpleMessage("Ключи шифрования"),
    "endpointUpdatedMessage": MessageLookupByLibrary.simpleMessage(
      "Конечная точка успешно обновлена",
    ),
    "endtoendEncryptedByDefault": MessageLookupByLibrary.simpleMessage(
      "Сквозное шифрование по умолчанию",
    ),
    "enteCanEncryptAndPreserveFilesOnlyIfYouGrant":
        MessageLookupByLibrary.simpleMessage(
          "Ente может шифровать и сохранять файлы, только если вы предоставите к ним доступ",
        ),
    "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
      "Ente <i>требуется разрешение для</i> сохранения ваших фото",
    ),
    "enteSubscriptionPitch": MessageLookupByLibrary.simpleMessage(
      "Ente сохраняет ваши воспоминания, чтобы они всегда были доступны вам, даже если вы потеряете устройство.",
    ),
    "enteSubscriptionShareWithFamily": MessageLookupByLibrary.simpleMessage(
      "Ваша семья также может быть включена в ваш тариф.",
    ),
    "enterAlbumName": MessageLookupByLibrary.simpleMessage(
      "Введите название альбома",
    ),
    "enterCode": MessageLookupByLibrary.simpleMessage("Введите код"),
    "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
      "Введите код, предоставленный вашим другом, чтобы вы оба могли получить бесплатное хранилище",
    ),
    "enterDateOfBirth": MessageLookupByLibrary.simpleMessage(
      "Дата рождения (необязательно)",
    ),
    "enterEmail": MessageLookupByLibrary.simpleMessage(
      "Введите электронную почту",
    ),
    "enterFileName": MessageLookupByLibrary.simpleMessage(
      "Введите название файла",
    ),
    "enterName": MessageLookupByLibrary.simpleMessage("Введите имя"),
    "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
      "Введите новый пароль для шифрования ваших данных",
    ),
    "enterPassword": MessageLookupByLibrary.simpleMessage("Введите пароль"),
    "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
      "Введите пароль для шифрования ваших данных",
    ),
    "enterPersonName": MessageLookupByLibrary.simpleMessage(
      "Введите имя человека",
    ),
    "enterPin": MessageLookupByLibrary.simpleMessage("Введите PIN-код"),
    "enterReferralCode": MessageLookupByLibrary.simpleMessage(
      "Введите реферальный код",
    ),
    "enterThe6digitCodeFromnyourAuthenticatorApp":
        MessageLookupByLibrary.simpleMessage(
          "Введите 6-значный код из\nвашего приложения для аутентификации",
        ),
    "enterValidEmail": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, введите действительный адрес электронной почты.",
    ),
    "enterYourEmailAddress": MessageLookupByLibrary.simpleMessage(
      "Введите адрес вашей электронной почты",
    ),
    "enterYourNewEmailAddress": MessageLookupByLibrary.simpleMessage(
      "Введите ваш новый адрес электронной почты",
    ),
    "enterYourPassword": MessageLookupByLibrary.simpleMessage(
      "Введите ваш пароль",
    ),
    "enterYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Введите ваш ключ восстановления",
    ),
    "error": MessageLookupByLibrary.simpleMessage("Ошибка"),
    "everywhere": MessageLookupByLibrary.simpleMessage("везде"),
    "exif": MessageLookupByLibrary.simpleMessage("EXIF"),
    "existingUser": MessageLookupByLibrary.simpleMessage(
      "Существующий пользователь",
    ),
    "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
      "Срок действия этой ссылки истёк. Пожалуйста, выберите новый срок или отключите его.",
    ),
    "exportLogs": MessageLookupByLibrary.simpleMessage("Экспортировать логи"),
    "exportYourData": MessageLookupByLibrary.simpleMessage(
      "Экспортировать ваши данные",
    ),
    "extraPhotosFound": MessageLookupByLibrary.simpleMessage(
      "Найдены дополнительные фото",
    ),
    "extraPhotosFoundFor": m33,
    "faceNotClusteredYet": MessageLookupByLibrary.simpleMessage(
      "Лицо ещё не кластеризовано. Пожалуйста, попробуйте позже",
    ),
    "faceRecognition": MessageLookupByLibrary.simpleMessage(
      "Распознавание лиц",
    ),
    "faceThumbnailGenerationFailed": MessageLookupByLibrary.simpleMessage(
      "Не удалось создать миниатюры лиц",
    ),
    "faces": MessageLookupByLibrary.simpleMessage("Лица"),
    "failed": MessageLookupByLibrary.simpleMessage("Не удалось"),
    "failedToApplyCode": MessageLookupByLibrary.simpleMessage(
      "Не удалось применить код",
    ),
    "failedToCancel": MessageLookupByLibrary.simpleMessage(
      "Не удалось отменить",
    ),
    "failedToDownloadVideo": MessageLookupByLibrary.simpleMessage(
      "Не удалось скачать видео",
    ),
    "failedToFetchActiveSessions": MessageLookupByLibrary.simpleMessage(
      "Не удалось получить активные сессии",
    ),
    "failedToFetchOriginalForEdit": MessageLookupByLibrary.simpleMessage(
      "Не удалось скачать оригинал для редактирования",
    ),
    "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
      "Не удалось получить данные о рефералах. Пожалуйста, попробуйте позже.",
    ),
    "failedToLoadAlbums": MessageLookupByLibrary.simpleMessage(
      "Не удалось загрузить альбомы",
    ),
    "failedToPlayVideo": MessageLookupByLibrary.simpleMessage(
      "Не удалось воспроизвести видео",
    ),
    "failedToRefreshStripeSubscription": MessageLookupByLibrary.simpleMessage(
      "Не удалось обновить подписку",
    ),
    "failedToRenew": MessageLookupByLibrary.simpleMessage(
      "Не удалось продлить",
    ),
    "failedToVerifyPaymentStatus": MessageLookupByLibrary.simpleMessage(
      "Не удалось проверить статус платежа",
    ),
    "familyPlanOverview": MessageLookupByLibrary.simpleMessage(
      "Добавьте 5 членов семьи к существующему тарифу без дополнительной оплаты.\n\nКаждый участник получает своё личное пространство и не может видеть файлы других, если они не общедоступны.\n\nСемейные тарифы доступны клиентам с платной подпиской на Ente.\n\nПодпишитесь сейчас, чтобы начать!",
    ),
    "familyPlanPortalTitle": MessageLookupByLibrary.simpleMessage("Семья"),
    "familyPlans": MessageLookupByLibrary.simpleMessage("Семейные тарифы"),
    "faq": MessageLookupByLibrary.simpleMessage("Часто задаваемые вопросы"),
    "faqs": MessageLookupByLibrary.simpleMessage("Часто задаваемые вопросы"),
    "favorite": MessageLookupByLibrary.simpleMessage("В избранное"),
    "feastingWithThem": m34,
    "feedback": MessageLookupByLibrary.simpleMessage("Обратная связь"),
    "file": MessageLookupByLibrary.simpleMessage("Файл"),
    "fileAnalysisFailed": MessageLookupByLibrary.simpleMessage(
      "Не удалось проанализировать файл",
    ),
    "fileFailedToSaveToGallery": MessageLookupByLibrary.simpleMessage(
      "Не удалось сохранить файл в галерею",
    ),
    "fileInfoAddDescHint": MessageLookupByLibrary.simpleMessage(
      "Добавить описание...",
    ),
    "fileNotUploadedYet": MessageLookupByLibrary.simpleMessage(
      "Файл ещё не загружен",
    ),
    "fileSavedToGallery": MessageLookupByLibrary.simpleMessage(
      "Файл сохранён в галерею",
    ),
    "fileTypes": MessageLookupByLibrary.simpleMessage("Типы файлов"),
    "fileTypesAndNames": MessageLookupByLibrary.simpleMessage(
      "Типы и названия файлов",
    ),
    "filesBackedUpFromDevice": m35,
    "filesBackedUpInAlbum": m36,
    "filesDeleted": MessageLookupByLibrary.simpleMessage("Файлы удалены"),
    "filesSavedToGallery": MessageLookupByLibrary.simpleMessage(
      "Файлы сохранены в галерею",
    ),
    "findPeopleByName": MessageLookupByLibrary.simpleMessage(
      "С лёгкостью находите людей по имени",
    ),
    "findThemQuickly": MessageLookupByLibrary.simpleMessage(
      "С лёгкостью находите его",
    ),
    "flip": MessageLookupByLibrary.simpleMessage("Отразить"),
    "food": MessageLookupByLibrary.simpleMessage("Кулинарное наслаждение"),
    "forYourMemories": MessageLookupByLibrary.simpleMessage(
      "для ваших воспоминаний",
    ),
    "forgotPassword": MessageLookupByLibrary.simpleMessage("Забыл пароль"),
    "foundFaces": MessageLookupByLibrary.simpleMessage("Найденные лица"),
    "freeStorageClaimed": MessageLookupByLibrary.simpleMessage(
      "Полученное бесплатное хранилище",
    ),
    "freeStorageOnReferralSuccess": m37,
    "freeStorageUsable": MessageLookupByLibrary.simpleMessage(
      "Доступное бесплатное хранилище",
    ),
    "freeTrial": MessageLookupByLibrary.simpleMessage(
      "Бесплатный пробный период",
    ),
    "freeTrialValidTill": m38,
    "freeUpAccessPostDelete": m39,
    "freeUpAmount": m40,
    "freeUpDeviceSpace": MessageLookupByLibrary.simpleMessage(
      "Освободить место на устройстве",
    ),
    "freeUpDeviceSpaceDesc": MessageLookupByLibrary.simpleMessage(
      "Освободите место на устройстве, удалив файлы, которые уже сохранены в резервной копии.",
    ),
    "freeUpSpace": MessageLookupByLibrary.simpleMessage("Освободить место"),
    "freeUpSpaceSaving": m41,
    "gallery": MessageLookupByLibrary.simpleMessage("Галерея"),
    "galleryMemoryLimitInfo": MessageLookupByLibrary.simpleMessage(
      "В галерее отображается до 1000 воспоминаний",
    ),
    "general": MessageLookupByLibrary.simpleMessage("Общие"),
    "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
      "Генерация ключей шифрования...",
    ),
    "genericProgress": m42,
    "goToSettings": MessageLookupByLibrary.simpleMessage("Перейти в настройки"),
    "googlePlayId": MessageLookupByLibrary.simpleMessage(
      "Идентификатор Google Play",
    ),
    "grantFullAccessPrompt": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, разрешите доступ ко всем фото в настройках устройства",
    ),
    "grantPermission": MessageLookupByLibrary.simpleMessage(
      "Предоставить разрешение",
    ),
    "greenery": MessageLookupByLibrary.simpleMessage("Зелёная жизнь"),
    "groupNearbyPhotos": MessageLookupByLibrary.simpleMessage(
      "Группировать ближайшие фото",
    ),
    "guestView": MessageLookupByLibrary.simpleMessage("Гостевой просмотр"),
    "guestViewEnablePreSteps": MessageLookupByLibrary.simpleMessage(
      "Для включения гостевого просмотра, пожалуйста, настройте код или блокировку экрана в настройках устройства.",
    ),
    "happyBirthday": MessageLookupByLibrary.simpleMessage(
      "С днём рождения! 🥳",
    ),
    "hearUsExplanation": MessageLookupByLibrary.simpleMessage(
      "Мы не отслеживаем установки приложений. Нам поможет, если скажете, как вы нас нашли!",
    ),
    "hearUsWhereTitle": MessageLookupByLibrary.simpleMessage(
      "Как вы узнали об Ente? (необязательно)",
    ),
    "help": MessageLookupByLibrary.simpleMessage("Помощь"),
    "hidden": MessageLookupByLibrary.simpleMessage("Скрытые"),
    "hide": MessageLookupByLibrary.simpleMessage("Скрыть"),
    "hideContent": MessageLookupByLibrary.simpleMessage("Скрыть содержимое"),
    "hideContentDescriptionAndroid": MessageLookupByLibrary.simpleMessage(
      "Скрывает содержимое приложения при переключении между приложениями и отключает скриншоты",
    ),
    "hideContentDescriptionIos": MessageLookupByLibrary.simpleMessage(
      "Скрывает содержимое приложения при переключении между приложениями",
    ),
    "hideSharedItemsFromHomeGallery": MessageLookupByLibrary.simpleMessage(
      "Скрыть общие элементы из основной галереи",
    ),
    "hiding": MessageLookupByLibrary.simpleMessage("Скрытие..."),
    "hikingWithThem": m43,
    "hostedAtOsmFrance": MessageLookupByLibrary.simpleMessage(
      "Размещено на OSM France",
    ),
    "howItWorks": MessageLookupByLibrary.simpleMessage("Как это работает"),
    "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
      "Попросите их нажать с удержанием на адрес электронной почты на экране настроек и убедиться, что идентификаторы на обоих устройствах совпадают.",
    ),
    "iOSGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
      "Биометрическая аутентификация не настроена. Пожалуйста, включите Touch ID или Face ID на вашем устройстве.",
    ),
    "iOSLockOut": MessageLookupByLibrary.simpleMessage(
      "Биометрическая аутентификация отключена. Пожалуйста, заблокируйте и разблокируйте экран, чтобы включить её.",
    ),
    "iOSOkButton": MessageLookupByLibrary.simpleMessage("Хорошо"),
    "ignore": MessageLookupByLibrary.simpleMessage("Игнорировать"),
    "ignoreUpdate": MessageLookupByLibrary.simpleMessage("Игнорировать"),
    "ignored": MessageLookupByLibrary.simpleMessage("игнорируется"),
    "ignoredFolderUploadReason": MessageLookupByLibrary.simpleMessage(
      "Некоторые файлы в этом альбоме игнорируются, так как ранее они были удалены из Ente.",
    ),
    "imageNotAnalyzed": MessageLookupByLibrary.simpleMessage(
      "Изображение не проанализировано",
    ),
    "immediately": MessageLookupByLibrary.simpleMessage("Немедленно"),
    "importing": MessageLookupByLibrary.simpleMessage("Импортирование..."),
    "incorrectCode": MessageLookupByLibrary.simpleMessage("Неверный код"),
    "incorrectPasswordTitle": MessageLookupByLibrary.simpleMessage(
      "Неверный пароль",
    ),
    "incorrectRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Неверный ключ восстановления",
    ),
    "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
      "Введённый вами ключ восстановления неверен",
    ),
    "incorrectRecoveryKeyTitle": MessageLookupByLibrary.simpleMessage(
      "Неверный ключ восстановления",
    ),
    "indexedItems": MessageLookupByLibrary.simpleMessage(
      "Проиндексированные элементы",
    ),
    "indexingPausedStatusDescription": MessageLookupByLibrary.simpleMessage(
      "Индексирование приостановлено. Оно автоматически возобновится, когда устройство будет готово. Устройство считается готовым, когда уровень заряда батареи, её состояние и температура находятся в пределах нормы.",
    ),
    "ineligible": MessageLookupByLibrary.simpleMessage("Неподходящий"),
    "info": MessageLookupByLibrary.simpleMessage("Информация"),
    "insecureDevice": MessageLookupByLibrary.simpleMessage(
      "Небезопасное устройство",
    ),
    "installManually": MessageLookupByLibrary.simpleMessage(
      "Установить вручную",
    ),
    "invalidEmailAddress": MessageLookupByLibrary.simpleMessage(
      "Недействительный адрес электронной почты",
    ),
    "invalidEndpoint": MessageLookupByLibrary.simpleMessage(
      "Недействительная конечная точка",
    ),
    "invalidEndpointMessage": MessageLookupByLibrary.simpleMessage(
      "Извините, введённая вами конечная точка недействительна. Пожалуйста, введите корректную точку и попробуйте снова.",
    ),
    "invalidKey": MessageLookupByLibrary.simpleMessage("Недействительный ключ"),
    "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Введённый вами ключ восстановления недействителен. Убедитесь, что он содержит 24 слова, и проверьте правописание каждого из них.\n\nЕсли вы ввели старый код восстановления, убедитесь, что он состоит из 64 символов, и проверьте каждый из них.",
    ),
    "invite": MessageLookupByLibrary.simpleMessage("Пригласить"),
    "inviteToEnte": MessageLookupByLibrary.simpleMessage("Пригласить в Ente"),
    "inviteYourFriends": MessageLookupByLibrary.simpleMessage(
      "Пригласите своих друзей",
    ),
    "inviteYourFriendsToEnte": MessageLookupByLibrary.simpleMessage(
      "Пригласите друзей в Ente",
    ),
    "itLooksLikeSomethingWentWrongPleaseRetryAfterSome":
        MessageLookupByLibrary.simpleMessage(
          "Похоже, что-то пошло не так. Пожалуйста, повторите попытку через некоторое время. Если ошибка сохраняется, обратитесь в нашу службу поддержки.",
        ),
    "itemCount": m44,
    "itemsShowTheNumberOfDaysRemainingBeforePermanentDeletion":
        MessageLookupByLibrary.simpleMessage(
          "На элементах отображается количество дней, оставшихся до их безвозвратного удаления",
        ),
    "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
      "Выбранные элементы будут удалены из этого альбома",
    ),
    "join": MessageLookupByLibrary.simpleMessage("Присоединиться"),
    "joinAlbum": MessageLookupByLibrary.simpleMessage(
      "Присоединиться к альбому",
    ),
    "joinAlbumConfirmationDialogBody": MessageLookupByLibrary.simpleMessage(
      "Если вы присоединитесь к альбому, ваша электронная почта станет видимой для его участников.",
    ),
    "joinAlbumSubtext": MessageLookupByLibrary.simpleMessage(
      "чтобы просматривать и добавлять свои фото",
    ),
    "joinAlbumSubtextViewer": MessageLookupByLibrary.simpleMessage(
      "чтобы добавить это в общие альбомы",
    ),
    "joinDiscord": MessageLookupByLibrary.simpleMessage(
      "Присоединиться в Discord",
    ),
    "keepPhotos": MessageLookupByLibrary.simpleMessage("Оставить фото"),
    "kiloMeterUnit": MessageLookupByLibrary.simpleMessage("км"),
    "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, помогите нам с этой информацией",
    ),
    "language": MessageLookupByLibrary.simpleMessage("Язык"),
    "lastTimeWithThem": m45,
    "lastUpdated": MessageLookupByLibrary.simpleMessage("Последнее обновление"),
    "lastYearsTrip": MessageLookupByLibrary.simpleMessage(
      "Прошлогодняя поездка",
    ),
    "leave": MessageLookupByLibrary.simpleMessage("Покинуть"),
    "leaveAlbum": MessageLookupByLibrary.simpleMessage("Покинуть альбом"),
    "leaveFamily": MessageLookupByLibrary.simpleMessage("Покинуть семью"),
    "leaveSharedAlbum": MessageLookupByLibrary.simpleMessage(
      "Покинуть общий альбом?",
    ),
    "left": MessageLookupByLibrary.simpleMessage("Влево"),
    "legacy": MessageLookupByLibrary.simpleMessage("Наследие"),
    "legacyAccounts": MessageLookupByLibrary.simpleMessage(
      "Наследуемые аккаунты",
    ),
    "legacyInvite": m46,
    "legacyPageDesc": MessageLookupByLibrary.simpleMessage(
      "Наследие позволяет доверенным контактам получить доступ к вашему аккаунту в ваше отсутствие.",
    ),
    "legacyPageDesc2": MessageLookupByLibrary.simpleMessage(
      "Доверенные контакты могут начать восстановление аккаунта. Если не отменить это в течение 30 дней, то они смогут сбросить пароль и получить доступ.",
    ),
    "light": MessageLookupByLibrary.simpleMessage("Яркость"),
    "lightTheme": MessageLookupByLibrary.simpleMessage("Светлая"),
    "link": MessageLookupByLibrary.simpleMessage("Привязать"),
    "linkCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
      "Ссылка скопирована в буфер обмена",
    ),
    "linkDeviceLimit": MessageLookupByLibrary.simpleMessage(
      "Ограничение по количеству устройств",
    ),
    "linkEmail": MessageLookupByLibrary.simpleMessage(
      "Привязать электронную почту",
    ),
    "linkEmailToContactBannerCaption": MessageLookupByLibrary.simpleMessage(
      "чтобы быстрее делиться",
    ),
    "linkEnabled": MessageLookupByLibrary.simpleMessage("Включена"),
    "linkExpired": MessageLookupByLibrary.simpleMessage("Истекла"),
    "linkExpiresOn": m47,
    "linkExpiry": MessageLookupByLibrary.simpleMessage("Срок действия ссылки"),
    "linkHasExpired": MessageLookupByLibrary.simpleMessage(
      "Срок действия ссылки истёк",
    ),
    "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Никогда"),
    "linkPerson": MessageLookupByLibrary.simpleMessage("Связать человека"),
    "linkPersonCaption": MessageLookupByLibrary.simpleMessage(
      "чтобы было удобнее делиться",
    ),
    "linkPersonToEmail": m48,
    "linkPersonToEmailConfirmation": m49,
    "livePhotos": MessageLookupByLibrary.simpleMessage("Живые фото"),
    "loadMessage1": MessageLookupByLibrary.simpleMessage(
      "Вы можете поделиться подпиской с вашей семьёй",
    ),
    "loadMessage2": MessageLookupByLibrary.simpleMessage(
      "На сегодняшний день мы сохранили более 200 миллионов воспоминаний",
    ),
    "loadMessage3": MessageLookupByLibrary.simpleMessage(
      "Мы храним 3 копии ваших данных, одну из них — в бункере",
    ),
    "loadMessage4": MessageLookupByLibrary.simpleMessage(
      "Все наши приложения имеют открытый исходный код",
    ),
    "loadMessage5": MessageLookupByLibrary.simpleMessage(
      "Наш исходный код и криптография прошли внешний аудит",
    ),
    "loadMessage6": MessageLookupByLibrary.simpleMessage(
      "Вы можете делиться ссылками на свои альбомы с близкими",
    ),
    "loadMessage7": MessageLookupByLibrary.simpleMessage(
      "Наши мобильные приложения работают в фоновом режиме, чтобы шифровать и сохранять все новые фото, которые вы снимаете",
    ),
    "loadMessage8": MessageLookupByLibrary.simpleMessage(
      "На web.ente.io есть удобный загрузчик",
    ),
    "loadMessage9": MessageLookupByLibrary.simpleMessage(
      "Мы используем Xchacha20Poly1305 для безопасного шифрования ваших данных",
    ),
    "loadingExifData": MessageLookupByLibrary.simpleMessage(
      "Загрузка данных EXIF...",
    ),
    "loadingGallery": MessageLookupByLibrary.simpleMessage(
      "Загрузка галереи...",
    ),
    "loadingMessage": MessageLookupByLibrary.simpleMessage(
      "Загрузка ваших фото...",
    ),
    "loadingModel": MessageLookupByLibrary.simpleMessage("Загрузка моделей..."),
    "loadingYourPhotos": MessageLookupByLibrary.simpleMessage(
      "Загрузка ваших фото...",
    ),
    "localGallery": MessageLookupByLibrary.simpleMessage("Локальная галерея"),
    "localIndexing": MessageLookupByLibrary.simpleMessage(
      "Локальная индексация",
    ),
    "localSyncErrorMessage": MessageLookupByLibrary.simpleMessage(
      "Похоже, что-то пошло не так: синхронизация фото занимает больше времени, чем ожидалось. Пожалуйста, обратитесь в поддержку",
    ),
    "location": MessageLookupByLibrary.simpleMessage("Местоположение"),
    "locationName": MessageLookupByLibrary.simpleMessage(
      "Название местоположения",
    ),
    "locationTagFeatureDescription": MessageLookupByLibrary.simpleMessage(
      "Тег местоположения группирует все фото, снятые в определённом радиусе от фото",
    ),
    "locations": MessageLookupByLibrary.simpleMessage("Местоположения"),
    "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Заблокировать"),
    "lockscreen": MessageLookupByLibrary.simpleMessage("Экран блокировки"),
    "logInLabel": MessageLookupByLibrary.simpleMessage("Войти"),
    "loggingOut": MessageLookupByLibrary.simpleMessage("Выход..."),
    "loginSessionExpired": MessageLookupByLibrary.simpleMessage(
      "Сессия истекла",
    ),
    "loginSessionExpiredDetails": MessageLookupByLibrary.simpleMessage(
      "Ваша сессия истекла. Пожалуйста, войдите снова.",
    ),
    "loginTerms": MessageLookupByLibrary.simpleMessage(
      "Нажимая \"Войти\", я соглашаюсь с <u-terms>условиями предоставления услуг</u-terms> и <u-policy>политикой конфиденциальности</u-policy>",
    ),
    "loginWithTOTP": MessageLookupByLibrary.simpleMessage(
      "Войти с одноразовым кодом",
    ),
    "logout": MessageLookupByLibrary.simpleMessage("Выйти"),
    "logsDialogBody": MessageLookupByLibrary.simpleMessage(
      "Это отправит нам логи, чтобы помочь разобраться с вашей проблемой. Обратите внимание, что имена файлов будут включены для отслеживания проблем с конкретными файлами.",
    ),
    "longPressAnEmailToVerifyEndToEndEncryption":
        MessageLookupByLibrary.simpleMessage(
          "Нажмите с удержанием на электронную почту для подтверждения сквозного шифрования.",
        ),
    "longpressOnAnItemToViewInFullscreen": MessageLookupByLibrary.simpleMessage(
      "Нажмите с удержанием на элемент для просмотра в полноэкранном режиме",
    ),
    "lookBackOnYourMemories": MessageLookupByLibrary.simpleMessage(
      "Оглянитесь на ваши воспоминания 🌄",
    ),
    "loopVideoOff": MessageLookupByLibrary.simpleMessage("Видео не зациклено"),
    "loopVideoOn": MessageLookupByLibrary.simpleMessage("Видео зациклено"),
    "lostDevice": MessageLookupByLibrary.simpleMessage("Потеряли устройство?"),
    "machineLearning": MessageLookupByLibrary.simpleMessage(
      "Машинное обучение",
    ),
    "magicSearch": MessageLookupByLibrary.simpleMessage("Магический поиск"),
    "magicSearchHint": MessageLookupByLibrary.simpleMessage(
      "Магический поиск позволяет искать фото по содержимому, например, «цветок», «красная машина», «документы»",
    ),
    "manage": MessageLookupByLibrary.simpleMessage("Управлять"),
    "manageDeviceStorage": MessageLookupByLibrary.simpleMessage(
      "Управление кэшем устройства",
    ),
    "manageDeviceStorageDesc": MessageLookupByLibrary.simpleMessage(
      "Ознакомиться и очистить локальный кэш.",
    ),
    "manageFamily": MessageLookupByLibrary.simpleMessage("Управление семьёй"),
    "manageLink": MessageLookupByLibrary.simpleMessage("Управлять ссылкой"),
    "manageParticipants": MessageLookupByLibrary.simpleMessage("Управлять"),
    "manageSubscription": MessageLookupByLibrary.simpleMessage(
      "Управление подпиской",
    ),
    "manualPairDesc": MessageLookupByLibrary.simpleMessage(
      "Подключение с PIN-кодом работает с любым устройством, на котором вы хотите просматривать альбом.",
    ),
    "map": MessageLookupByLibrary.simpleMessage("Карта"),
    "maps": MessageLookupByLibrary.simpleMessage("Карты"),
    "mastodon": MessageLookupByLibrary.simpleMessage("Mastodon"),
    "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
    "me": MessageLookupByLibrary.simpleMessage("Я"),
    "memories": MessageLookupByLibrary.simpleMessage("Воспоминания"),
    "memoriesWidgetDesc": MessageLookupByLibrary.simpleMessage(
      "Выберите, какие воспоминания вы хотите видеть на главном экране.",
    ),
    "memoryCount": m50,
    "merchandise": MessageLookupByLibrary.simpleMessage("Мерч"),
    "merge": MessageLookupByLibrary.simpleMessage("Объединить"),
    "mergeWithExisting": MessageLookupByLibrary.simpleMessage(
      "Объединить с существующим",
    ),
    "mergedPhotos": MessageLookupByLibrary.simpleMessage("Объединённые фото"),
    "mlConsent": MessageLookupByLibrary.simpleMessage(
      "Включить машинное обучение",
    ),
    "mlConsentConfirmation": MessageLookupByLibrary.simpleMessage(
      "Я понимаю и хочу включить машинное обучение",
    ),
    "mlConsentDescription": MessageLookupByLibrary.simpleMessage(
      "Если вы включите машинное обучение, Ente будет извлекать информацию такую, как геометрия лица, из файлов, включая те, которыми с вами поделились.\n\nЭтот процесс будет происходить на вашем устройстве, и любая сгенерированная биометрическая информация будет защищена сквозным шифрованием.",
    ),
    "mlConsentPrivacy": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, нажмите здесь для получения подробностей об этой функции в нашей политике конфиденциальности",
    ),
    "mlConsentTitle": MessageLookupByLibrary.simpleMessage(
      "Включить машинное обучение?",
    ),
    "mlIndexingDescription": MessageLookupByLibrary.simpleMessage(
      "Обратите внимание, что машинное обучение увеличит использование трафика и батареи, пока все элементы не будут проиндексированы. Рассмотрите использование приложения для компьютера для более быстрой индексации. Результаты будут автоматически синхронизированы.",
    ),
    "mobileWebDesktop": MessageLookupByLibrary.simpleMessage(
      "Смартфон, браузер, компьютер",
    ),
    "moderateStrength": MessageLookupByLibrary.simpleMessage("Средняя"),
    "modifyYourQueryOrTrySearchingFor": MessageLookupByLibrary.simpleMessage(
      "Измените запрос или попробуйте поискать",
    ),
    "moments": MessageLookupByLibrary.simpleMessage("Моменты"),
    "month": MessageLookupByLibrary.simpleMessage("месяц"),
    "monthly": MessageLookupByLibrary.simpleMessage("Ежемесячно"),
    "moon": MessageLookupByLibrary.simpleMessage("В лунном свете"),
    "moreDetails": MessageLookupByLibrary.simpleMessage("Подробнее"),
    "mostRecent": MessageLookupByLibrary.simpleMessage("Самые последние"),
    "mostRelevant": MessageLookupByLibrary.simpleMessage("Самые актуальные"),
    "mountains": MessageLookupByLibrary.simpleMessage("За холмами"),
    "moveItem": m51,
    "moveSelectedPhotosToOneDate": MessageLookupByLibrary.simpleMessage(
      "Переместите выбранные фото на одну дату",
    ),
    "moveToAlbum": MessageLookupByLibrary.simpleMessage("Переместить в альбом"),
    "moveToHiddenAlbum": MessageLookupByLibrary.simpleMessage(
      "Переместить в скрытый альбом",
    ),
    "movedSuccessfullyTo": m52,
    "movedToTrash": MessageLookupByLibrary.simpleMessage(
      "Перемещено в корзину",
    ),
    "movingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
      "Перемещение файлов в альбом...",
    ),
    "name": MessageLookupByLibrary.simpleMessage("Имя"),
    "nameTheAlbum": MessageLookupByLibrary.simpleMessage(
      "Дайте название альбому",
    ),
    "networkConnectionRefusedErr": MessageLookupByLibrary.simpleMessage(
      "Не удалось подключиться к Ente. Повторите попытку через некоторое время. Если ошибка сохраняется, обратитесь в поддержку.",
    ),
    "networkHostLookUpErr": MessageLookupByLibrary.simpleMessage(
      "Не удалось подключиться к Ente. Проверьте настройки сети и обратитесь в поддержку, если ошибка сохраняется.",
    ),
    "never": MessageLookupByLibrary.simpleMessage("Никогда"),
    "newAlbum": MessageLookupByLibrary.simpleMessage("Новый альбом"),
    "newLocation": MessageLookupByLibrary.simpleMessage("Новое местоположение"),
    "newPerson": MessageLookupByLibrary.simpleMessage("Новый человек"),
    "newPhotosEmoji": MessageLookupByLibrary.simpleMessage(" новая 📸"),
    "newRange": MessageLookupByLibrary.simpleMessage("Новый диапазон"),
    "newToEnte": MessageLookupByLibrary.simpleMessage("Впервые в Ente"),
    "newest": MessageLookupByLibrary.simpleMessage("Недавние"),
    "next": MessageLookupByLibrary.simpleMessage("Далее"),
    "no": MessageLookupByLibrary.simpleMessage("Нет"),
    "noAlbumsSharedByYouYet": MessageLookupByLibrary.simpleMessage(
      "Вы пока не делились альбомами",
    ),
    "noDeviceFound": MessageLookupByLibrary.simpleMessage(
      "Устройства не обнаружены",
    ),
    "noDeviceLimit": MessageLookupByLibrary.simpleMessage("Нет"),
    "noDeviceThatCanBeDeleted": MessageLookupByLibrary.simpleMessage(
      "На этом устройстве нет файлов, которые можно удалить",
    ),
    "noDuplicates": MessageLookupByLibrary.simpleMessage("✨ Дубликатов нет"),
    "noEnteAccountExclamation": MessageLookupByLibrary.simpleMessage(
      "Нет аккаунта Ente!",
    ),
    "noExifData": MessageLookupByLibrary.simpleMessage("Нет данных EXIF"),
    "noFacesFound": MessageLookupByLibrary.simpleMessage("Лица не найдены"),
    "noHiddenPhotosOrVideos": MessageLookupByLibrary.simpleMessage(
      "Нет скрытых фото или видео",
    ),
    "noImagesWithLocation": MessageLookupByLibrary.simpleMessage(
      "Нет фото с местоположением",
    ),
    "noInternetConnection": MessageLookupByLibrary.simpleMessage(
      "Нет подключения к Интернету",
    ),
    "noPhotosAreBeingBackedUpRightNow": MessageLookupByLibrary.simpleMessage(
      "В данный момент фото не копируются",
    ),
    "noPhotosFoundHere": MessageLookupByLibrary.simpleMessage(
      "Здесь фото не найдены",
    ),
    "noQuickLinksSelected": MessageLookupByLibrary.simpleMessage(
      "Быстрые ссылки не выбраны",
    ),
    "noRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Нет ключа восстановления?",
    ),
    "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
      "Из-за особенностей нашего протокола сквозного шифрования ваши данные не могут быть расшифрованы без пароля или ключа восстановления",
    ),
    "noResults": MessageLookupByLibrary.simpleMessage("Нет результатов"),
    "noResultsFound": MessageLookupByLibrary.simpleMessage("Нет результатов"),
    "noSuggestionsForPerson": m53,
    "noSystemLockFound": MessageLookupByLibrary.simpleMessage(
      "Системная блокировка не найдена",
    ),
    "notPersonLabel": m54,
    "notThisPerson": MessageLookupByLibrary.simpleMessage("Не этот человек?"),
    "nothingSharedWithYouYet": MessageLookupByLibrary.simpleMessage(
      "С вами пока ничем не поделились",
    ),
    "nothingToSeeHere": MessageLookupByLibrary.simpleMessage(
      "Здесь ничего нет! 👀",
    ),
    "notifications": MessageLookupByLibrary.simpleMessage("Уведомления"),
    "ok": MessageLookupByLibrary.simpleMessage("Хорошо"),
    "onDevice": MessageLookupByLibrary.simpleMessage("На устройстве"),
    "onEnte": MessageLookupByLibrary.simpleMessage(
      "В <branding>ente</branding>",
    ),
    "onTheRoad": MessageLookupByLibrary.simpleMessage("Снова в пути"),
    "onThisDay": MessageLookupByLibrary.simpleMessage("В этот день"),
    "onThisDayMemories": MessageLookupByLibrary.simpleMessage(
      "В этот день воспоминания",
    ),
    "onThisDayNotificationExplanation": MessageLookupByLibrary.simpleMessage(
      "Получайте напоминания о воспоминаниях, связанных с этим днем в прошлые годы.",
    ),
    "onlyFamilyAdminCanChangeCode": m55,
    "onlyThem": MessageLookupByLibrary.simpleMessage("Только он(а)"),
    "oops": MessageLookupByLibrary.simpleMessage("Ой"),
    "oopsCouldNotSaveEdits": MessageLookupByLibrary.simpleMessage(
      "Ой, не удалось сохранить изменения",
    ),
    "oopsSomethingWentWrong": MessageLookupByLibrary.simpleMessage(
      "Ой, что-то пошло не так",
    ),
    "openAlbumInBrowser": MessageLookupByLibrary.simpleMessage(
      "Открыть альбом в браузере",
    ),
    "openAlbumInBrowserTitle": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, используйте веб-версию, чтобы добавить фото в этот альбом",
    ),
    "openFile": MessageLookupByLibrary.simpleMessage("Открыть файл"),
    "openSettings": MessageLookupByLibrary.simpleMessage("Открыть настройки"),
    "openTheItem": MessageLookupByLibrary.simpleMessage("• Откройте элемент"),
    "openstreetmapContributors": MessageLookupByLibrary.simpleMessage(
      "Участники OpenStreetMap",
    ),
    "optionalAsShortAsYouLike": MessageLookupByLibrary.simpleMessage(
      "Необязательно, насколько коротко пожелаете...",
    ),
    "orMergeWithExistingPerson": MessageLookupByLibrary.simpleMessage(
      "Или объединить с существующим",
    ),
    "orPickAnExistingOne": MessageLookupByLibrary.simpleMessage(
      "Или выберите существующую",
    ),
    "orPickFromYourContacts": MessageLookupByLibrary.simpleMessage(
      "или выберите из ваших контактов",
    ),
    "otherDetectedFaces": MessageLookupByLibrary.simpleMessage(
      "Другие найденные лица",
    ),
    "pair": MessageLookupByLibrary.simpleMessage("Подключить"),
    "pairWithPin": MessageLookupByLibrary.simpleMessage("Подключить с PIN"),
    "pairingComplete": MessageLookupByLibrary.simpleMessage(
      "Подключение завершено",
    ),
    "panorama": MessageLookupByLibrary.simpleMessage("Панорама"),
    "partyWithThem": m56,
    "passKeyPendingVerification": MessageLookupByLibrary.simpleMessage(
      "Проверка всё ещё ожидается",
    ),
    "passkey": MessageLookupByLibrary.simpleMessage("Ключ доступа"),
    "passkeyAuthTitle": MessageLookupByLibrary.simpleMessage(
      "Проверка ключа доступа",
    ),
    "password": MessageLookupByLibrary.simpleMessage("Пароль"),
    "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Пароль успешно изменён",
    ),
    "passwordLock": MessageLookupByLibrary.simpleMessage("Защита паролем"),
    "passwordStrength": m57,
    "passwordStrengthInfo": MessageLookupByLibrary.simpleMessage(
      "Надёжность пароля определяется его длиной, используемыми символами и присутствием среди 10000 самых популярных паролей",
    ),
    "passwordWarning": MessageLookupByLibrary.simpleMessage(
      "Мы не храним этот пароль, поэтому, если вы его забудете, <underline>мы не сможем расшифровать ваши данные</underline>",
    ),
    "pastYearsMemories": MessageLookupByLibrary.simpleMessage(
      "Воспоминания прошлых лет",
    ),
    "paymentDetails": MessageLookupByLibrary.simpleMessage("Платёжные данные"),
    "paymentFailed": MessageLookupByLibrary.simpleMessage("Платёж не удался"),
    "paymentFailedMessage": MessageLookupByLibrary.simpleMessage(
      "К сожалению, ваш платёж не удался. Пожалуйста, свяжитесь с поддержкой, и мы вам поможем!",
    ),
    "paymentFailedTalkToProvider": m58,
    "pendingItems": MessageLookupByLibrary.simpleMessage("Элементы в очереди"),
    "pendingSync": MessageLookupByLibrary.simpleMessage(
      "Ожидание синхронизации",
    ),
    "people": MessageLookupByLibrary.simpleMessage("Люди"),
    "peopleUsingYourCode": MessageLookupByLibrary.simpleMessage(
      "Люди, использующие ваш код",
    ),
    "peopleWidgetDesc": MessageLookupByLibrary.simpleMessage(
      "Выберите людей, которых вы хотите видеть на главном экране.",
    ),
    "permDeleteWarning": MessageLookupByLibrary.simpleMessage(
      "Все элементы в корзине будут удалены навсегда\n\nЭто действие нельзя отменить",
    ),
    "permanentlyDelete": MessageLookupByLibrary.simpleMessage(
      "Удалить безвозвратно",
    ),
    "permanentlyDeleteFromDevice": MessageLookupByLibrary.simpleMessage(
      "Удалить с устройства безвозвратно?",
    ),
    "personIsAge": m59,
    "personName": MessageLookupByLibrary.simpleMessage("Имя человека"),
    "personTurningAge": m60,
    "pets": MessageLookupByLibrary.simpleMessage("Пушистые спутники"),
    "photoDescriptions": MessageLookupByLibrary.simpleMessage("Описания фото"),
    "photoGridSize": MessageLookupByLibrary.simpleMessage("Размер сетки фото"),
    "photoSmallCase": MessageLookupByLibrary.simpleMessage("фото"),
    "photocountPhotos": m61,
    "photos": MessageLookupByLibrary.simpleMessage("Фото"),
    "photosAddedByYouWillBeRemovedFromTheAlbum":
        MessageLookupByLibrary.simpleMessage(
          "Добавленные вами фото будут удалены из альбома",
        ),
    "photosCount": m62,
    "photosKeepRelativeTimeDifference": MessageLookupByLibrary.simpleMessage(
      "Фото сохранят относительную разницу во времени",
    ),
    "pickCenterPoint": MessageLookupByLibrary.simpleMessage(
      "Выбрать центральную точку",
    ),
    "pinAlbum": MessageLookupByLibrary.simpleMessage("Закрепить альбом"),
    "pinLock": MessageLookupByLibrary.simpleMessage("Блокировка PIN-кодом"),
    "playOnTv": MessageLookupByLibrary.simpleMessage(
      "Воспроизвести альбом на ТВ",
    ),
    "playOriginal": MessageLookupByLibrary.simpleMessage(
      "Воспроизвести оригинал",
    ),
    "playStoreFreeTrialValidTill": m63,
    "playStream": MessageLookupByLibrary.simpleMessage("Воспроизвести поток"),
    "playstoreSubscription": MessageLookupByLibrary.simpleMessage(
      "Подписка PlayStore",
    ),
    "pleaseCheckYourInternetConnectionAndTryAgain":
        MessageLookupByLibrary.simpleMessage(
          "Пожалуйста, проверьте подключение к Интернету и попробуйте снова.",
        ),
    "pleaseContactSupportAndWeWillBeHappyToHelp":
        MessageLookupByLibrary.simpleMessage(
          "Пожалуйста, свяжитесь с support@ente.io, и мы будем рады помочь!",
        ),
    "pleaseContactSupportIfTheProblemPersists":
        MessageLookupByLibrary.simpleMessage(
          "Пожалуйста, обратитесь в поддержку, если проблема сохраняется",
        ),
    "pleaseEmailUsAt": m64,
    "pleaseGrantPermissions": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, предоставьте разрешения",
    ),
    "pleaseLoginAgain": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, войдите снова",
    ),
    "pleaseSelectQuickLinksToRemove": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, выберите быстрые ссылки для удаления",
    ),
    "pleaseSendTheLogsTo": m65,
    "pleaseTryAgain": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, попробуйте снова",
    ),
    "pleaseVerifyTheCodeYouHaveEntered": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, проверьте введённый вами код",
    ),
    "pleaseWait": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, подождите...",
    ),
    "pleaseWaitDeletingAlbum": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, подождите, альбом удаляется",
    ),
    "pleaseWaitForSometimeBeforeRetrying": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, подождите некоторое время перед повторной попыткой",
    ),
    "pleaseWaitThisWillTakeAWhile": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, подождите, это займёт некоторое время.",
    ),
    "posingWithThem": m66,
    "preparingLogs": MessageLookupByLibrary.simpleMessage(
      "Подготовка логов...",
    ),
    "preserveMore": MessageLookupByLibrary.simpleMessage("Сохранить больше"),
    "pressAndHoldToPlayVideo": MessageLookupByLibrary.simpleMessage(
      "Нажмите и удерживайте для воспроизведения видео",
    ),
    "pressAndHoldToPlayVideoDetailed": MessageLookupByLibrary.simpleMessage(
      "Нажмите с удержанием на изображение для воспроизведения видео",
    ),
    "previous": MessageLookupByLibrary.simpleMessage("Предыдущий"),
    "privacy": MessageLookupByLibrary.simpleMessage("Конфиденциальность"),
    "privacyPolicyTitle": MessageLookupByLibrary.simpleMessage(
      "Политика конфиденциальности",
    ),
    "privateBackups": MessageLookupByLibrary.simpleMessage(
      "Защищённые резервные копии",
    ),
    "privateSharing": MessageLookupByLibrary.simpleMessage("Защищённый обмен"),
    "proceed": MessageLookupByLibrary.simpleMessage("Продолжить"),
    "processed": MessageLookupByLibrary.simpleMessage("Обработано"),
    "processing": MessageLookupByLibrary.simpleMessage("Обработка"),
    "processingImport": m67,
    "processingVideos": MessageLookupByLibrary.simpleMessage("Обработка видео"),
    "publicLinkCreated": MessageLookupByLibrary.simpleMessage(
      "Публичная ссылка создана",
    ),
    "publicLinkEnabled": MessageLookupByLibrary.simpleMessage(
      "Публичная ссылка включена",
    ),
    "questionmark": MessageLookupByLibrary.simpleMessage("?"),
    "queued": MessageLookupByLibrary.simpleMessage("В очереди"),
    "quickLinks": MessageLookupByLibrary.simpleMessage("Быстрые ссылки"),
    "radius": MessageLookupByLibrary.simpleMessage("Радиус"),
    "raiseTicket": MessageLookupByLibrary.simpleMessage("Создать запрос"),
    "rateTheApp": MessageLookupByLibrary.simpleMessage("Оценить приложение"),
    "rateUs": MessageLookupByLibrary.simpleMessage("Оцените нас"),
    "rateUsOnStore": m68,
    "reassignMe": MessageLookupByLibrary.simpleMessage(
      "Переназначить \"Меня\"",
    ),
    "reassignedToName": m69,
    "reassigningLoading": MessageLookupByLibrary.simpleMessage(
      "Переназначение...",
    ),
    "receiveRemindersOnBirthdays": MessageLookupByLibrary.simpleMessage(
      "Получайте напоминания, когда у кого-то день рождения. Нажатие на уведомление перенесет вас к фотографиям именинника.",
    ),
    "recover": MessageLookupByLibrary.simpleMessage("Восстановить"),
    "recoverAccount": MessageLookupByLibrary.simpleMessage(
      "Восстановить аккаунт",
    ),
    "recoverButton": MessageLookupByLibrary.simpleMessage("Восстановить"),
    "recoveryAccount": MessageLookupByLibrary.simpleMessage(
      "Восстановить аккаунт",
    ),
    "recoveryInitiated": MessageLookupByLibrary.simpleMessage(
      "Восстановление начато",
    ),
    "recoveryInitiatedDesc": m70,
    "recoveryKey": MessageLookupByLibrary.simpleMessage("Ключ восстановления"),
    "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
      "Ключ восстановления скопирован в буфер обмена",
    ),
    "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
      "Если вы забудете пароль, единственный способ восстановить ваши данные — это использовать этот ключ.",
    ),
    "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
      "Мы не храним этот ключ. Пожалуйста, сохраните этот ключ из 24 слов в безопасном месте.",
    ),
    "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
      "Отлично! Ваш ключ восстановления действителен. Спасибо за проверку.\n\nПожалуйста, не забудьте сохранить ключ восстановления в безопасном месте.",
    ),
    "recoveryKeyVerified": MessageLookupByLibrary.simpleMessage(
      "Ключ восстановления подтверждён",
    ),
    "recoveryKeyVerifyReason": MessageLookupByLibrary.simpleMessage(
      "Ваш ключ восстановления — единственный способ восстановить ваши фото, если вы забудете пароль. Вы можете найти ключ восстановления в разделе «Настройки» → «Аккаунт».\n\nПожалуйста, введите ваш ключ восстановления здесь, чтобы убедиться, что вы сохранили его правильно.",
    ),
    "recoveryReady": m71,
    "recoverySuccessful": MessageLookupByLibrary.simpleMessage(
      "Успешное восстановление!",
    ),
    "recoveryWarning": MessageLookupByLibrary.simpleMessage(
      "Доверенный контакт пытается получить доступ к вашему аккаунту",
    ),
    "recoveryWarningBody": m72,
    "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
      "Текущее устройство недостаточно мощное для проверки вашего пароля, но мы можем сгенерировать его снова так, чтобы он работал на всех устройствах.\n\nПожалуйста, войдите, используя ваш ключ восстановления, и сгенерируйте пароль (при желании вы можете использовать тот же самый).",
    ),
    "recreatePasswordTitle": MessageLookupByLibrary.simpleMessage(
      "Пересоздать пароль",
    ),
    "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
    "reenterPassword": MessageLookupByLibrary.simpleMessage(
      "Подтвердите пароль",
    ),
    "reenterPin": MessageLookupByLibrary.simpleMessage(
      "Введите PIN-код ещё раз",
    ),
    "referFriendsAnd2xYourPlan": MessageLookupByLibrary.simpleMessage(
      "Пригласите друзей и удвойте свой тариф",
    ),
    "referralStep1": MessageLookupByLibrary.simpleMessage(
      "1. Даёте этот код своим друзьям",
    ),
    "referralStep2": MessageLookupByLibrary.simpleMessage(
      "2. Они подписываются на платный тариф",
    ),
    "referralStep3": m73,
    "referrals": MessageLookupByLibrary.simpleMessage("Рефералы"),
    "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
      "Реферальная программа временно приостановлена",
    ),
    "rejectRecovery": MessageLookupByLibrary.simpleMessage(
      "Отклонить восстановление",
    ),
    "remindToEmptyDeviceTrash": MessageLookupByLibrary.simpleMessage(
      "Также очистите «Недавно удалённые» в «Настройки» → «Хранилище», чтобы освободить место",
    ),
    "remindToEmptyEnteTrash": MessageLookupByLibrary.simpleMessage(
      "Также очистите «Корзину», чтобы освободить место",
    ),
    "remoteImages": MessageLookupByLibrary.simpleMessage(
      "Изображения вне устройства",
    ),
    "remoteThumbnails": MessageLookupByLibrary.simpleMessage(
      "Миниатюры вне устройства",
    ),
    "remoteVideos": MessageLookupByLibrary.simpleMessage(
      "Видео вне устройства",
    ),
    "remove": MessageLookupByLibrary.simpleMessage("Удалить"),
    "removeDuplicates": MessageLookupByLibrary.simpleMessage(
      "Удалить дубликаты",
    ),
    "removeDuplicatesDesc": MessageLookupByLibrary.simpleMessage(
      "Проверьте и удалите файлы, которые являются точными дубликатами.",
    ),
    "removeFromAlbum": MessageLookupByLibrary.simpleMessage(
      "Удалить из альбома",
    ),
    "removeFromAlbumTitle": MessageLookupByLibrary.simpleMessage(
      "Удалить из альбома?",
    ),
    "removeFromFavorite": MessageLookupByLibrary.simpleMessage(
      "Убрать из избранного",
    ),
    "removeInvite": MessageLookupByLibrary.simpleMessage("Удалить приглашение"),
    "removeLink": MessageLookupByLibrary.simpleMessage("Удалить ссылку"),
    "removeParticipant": MessageLookupByLibrary.simpleMessage(
      "Удалить участника",
    ),
    "removeParticipantBody": m74,
    "removePersonLabel": MessageLookupByLibrary.simpleMessage(
      "Удалить метку человека",
    ),
    "removePublicLink": MessageLookupByLibrary.simpleMessage(
      "Удалить публичную ссылку",
    ),
    "removePublicLinks": MessageLookupByLibrary.simpleMessage(
      "Удалить публичные ссылки",
    ),
    "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
      "Некоторые из удаляемых вами элементов были добавлены другими людьми, и вы потеряете к ним доступ",
    ),
    "removeWithQuestionMark": MessageLookupByLibrary.simpleMessage("Удалить?"),
    "removeYourselfAsTrustedContact": MessageLookupByLibrary.simpleMessage(
      "Удалить себя из доверенных контактов",
    ),
    "removingFromFavorites": MessageLookupByLibrary.simpleMessage(
      "Удаление из избранного...",
    ),
    "rename": MessageLookupByLibrary.simpleMessage("Переименовать"),
    "renameAlbum": MessageLookupByLibrary.simpleMessage("Переименовать альбом"),
    "renameFile": MessageLookupByLibrary.simpleMessage("Переименовать файл"),
    "renewSubscription": MessageLookupByLibrary.simpleMessage(
      "Продлить подписку",
    ),
    "renewsOn": m75,
    "reportABug": MessageLookupByLibrary.simpleMessage("Сообщить об ошибке"),
    "reportBug": MessageLookupByLibrary.simpleMessage("Сообщить об ошибке"),
    "resendEmail": MessageLookupByLibrary.simpleMessage(
      "Отправить письмо повторно",
    ),
    "reset": MessageLookupByLibrary.simpleMessage("Сбросить"),
    "resetIgnoredFiles": MessageLookupByLibrary.simpleMessage(
      "Сбросить игнорируемые файлы",
    ),
    "resetPasswordTitle": MessageLookupByLibrary.simpleMessage(
      "Сбросить пароль",
    ),
    "resetPerson": MessageLookupByLibrary.simpleMessage("Удалить"),
    "resetToDefault": MessageLookupByLibrary.simpleMessage(
      "Вернуть стандартную",
    ),
    "restore": MessageLookupByLibrary.simpleMessage("Восстановить"),
    "restoreToAlbum": MessageLookupByLibrary.simpleMessage(
      "Восстановить в альбом",
    ),
    "restoringFiles": MessageLookupByLibrary.simpleMessage(
      "Восстановление файлов...",
    ),
    "resumableUploads": MessageLookupByLibrary.simpleMessage(
      "Возобновляемые загрузки",
    ),
    "retry": MessageLookupByLibrary.simpleMessage("Повторить"),
    "review": MessageLookupByLibrary.simpleMessage("Предложения"),
    "reviewDeduplicateItems": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, проверьте и удалите элементы, которые считаете дубликатами.",
    ),
    "reviewSuggestions": MessageLookupByLibrary.simpleMessage(
      "Посмотреть предложения",
    ),
    "right": MessageLookupByLibrary.simpleMessage("Вправо"),
    "roadtripWithThem": m76,
    "rotate": MessageLookupByLibrary.simpleMessage("Повернуть"),
    "rotateLeft": MessageLookupByLibrary.simpleMessage("Повернуть влево"),
    "rotateRight": MessageLookupByLibrary.simpleMessage("Повернуть вправо"),
    "safelyStored": MessageLookupByLibrary.simpleMessage("Надёжно сохранены"),
    "same": MessageLookupByLibrary.simpleMessage("Такой же"),
    "sameperson": MessageLookupByLibrary.simpleMessage("Тот же человек?"),
    "save": MessageLookupByLibrary.simpleMessage("Сохранить"),
    "saveAsAnotherPerson": MessageLookupByLibrary.simpleMessage(
      "Сохранить как другого человека",
    ),
    "saveChangesBeforeLeavingQuestion": MessageLookupByLibrary.simpleMessage(
      "Сохранить изменения перед выходом?",
    ),
    "saveCollage": MessageLookupByLibrary.simpleMessage("Сохранить коллаж"),
    "saveCopy": MessageLookupByLibrary.simpleMessage("Сохранить копию"),
    "saveKey": MessageLookupByLibrary.simpleMessage("Сохранить ключ"),
    "savePerson": MessageLookupByLibrary.simpleMessage("Сохранить человека"),
    "saveYourRecoveryKeyIfYouHaventAlready":
        MessageLookupByLibrary.simpleMessage(
          "Сохраните ваш ключ восстановления, если вы ещё этого не сделали",
        ),
    "saving": MessageLookupByLibrary.simpleMessage("Сохранение..."),
    "savingEdits": MessageLookupByLibrary.simpleMessage(
      "Сохранение изменений...",
    ),
    "scanCode": MessageLookupByLibrary.simpleMessage("Сканировать код"),
    "scanThisBarcodeWithnyourAuthenticatorApp":
        MessageLookupByLibrary.simpleMessage(
          "Отсканируйте этот штрих-код\nс помощью вашего приложения для аутентификации",
        ),
    "search": MessageLookupByLibrary.simpleMessage("Поиск"),
    "searchAlbumsEmptySection": MessageLookupByLibrary.simpleMessage("Альбомы"),
    "searchByAlbumNameHint": MessageLookupByLibrary.simpleMessage(
      "Название альбома",
    ),
    "searchByExamples": MessageLookupByLibrary.simpleMessage(
      "• Названия альбомов (например, «Камера»)\n• Типы файлов (например, «Видео», «.gif»)\n• Годы и месяцы (например, «2022», «Январь»)\n• Праздники (например, «Рождество»)\n• Описания фото (например, «#веселье»)",
    ),
    "searchCaptionEmptySection": MessageLookupByLibrary.simpleMessage(
      "Добавляйте описания вроде «#поездка» в информацию о фото, чтобы быстро находить их здесь",
    ),
    "searchDatesEmptySection": MessageLookupByLibrary.simpleMessage(
      "Ищите по дате, месяцу или году",
    ),
    "searchDiscoverEmptySection": MessageLookupByLibrary.simpleMessage(
      "Изображения появятся здесь после завершения обработки и синхронизации",
    ),
    "searchFaceEmptySection": MessageLookupByLibrary.simpleMessage(
      "Люди появятся здесь после завершения индексации",
    ),
    "searchFileTypesAndNamesEmptySection": MessageLookupByLibrary.simpleMessage(
      "Типы и названия файлов",
    ),
    "searchHint1": MessageLookupByLibrary.simpleMessage(
      "Быстрый поиск прямо на устройстве",
    ),
    "searchHint2": MessageLookupByLibrary.simpleMessage("Даты, описания фото"),
    "searchHint3": MessageLookupByLibrary.simpleMessage(
      "Альбомы, названия и типы файлов",
    ),
    "searchHint4": MessageLookupByLibrary.simpleMessage("Местоположение"),
    "searchHint5": MessageLookupByLibrary.simpleMessage(
      "Скоро: Лица и магический поиск ✨",
    ),
    "searchLocationEmptySection": MessageLookupByLibrary.simpleMessage(
      "Группируйте фото, снятые в определённом радиусе от фото",
    ),
    "searchPeopleEmptySection": MessageLookupByLibrary.simpleMessage(
      "Приглашайте людей, и здесь появятся все фото, которыми они поделились",
    ),
    "searchPersonsEmptySection": MessageLookupByLibrary.simpleMessage(
      "Люди появятся здесь после завершения обработки и синхронизации",
    ),
    "searchResultCount": m77,
    "searchSectionsLengthMismatch": m78,
    "security": MessageLookupByLibrary.simpleMessage("Безопасность"),
    "seePublicAlbumLinksInApp": MessageLookupByLibrary.simpleMessage(
      "Просматривать публичные ссылки на альбомы в приложении",
    ),
    "selectALocation": MessageLookupByLibrary.simpleMessage(
      "Выбрать местоположение",
    ),
    "selectALocationFirst": MessageLookupByLibrary.simpleMessage(
      "Сначала выберите местоположение",
    ),
    "selectAlbum": MessageLookupByLibrary.simpleMessage("Выбрать альбом"),
    "selectAll": MessageLookupByLibrary.simpleMessage("Выбрать все"),
    "selectAllShort": MessageLookupByLibrary.simpleMessage("Все"),
    "selectCoverPhoto": MessageLookupByLibrary.simpleMessage(
      "Выберите обложку",
    ),
    "selectDate": MessageLookupByLibrary.simpleMessage("Выбрать дату"),
    "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
      "Выберите папки для резервного копирования",
    ),
    "selectItemsToAdd": MessageLookupByLibrary.simpleMessage(
      "Выберите элементы для добавления",
    ),
    "selectLanguage": MessageLookupByLibrary.simpleMessage("Выберите язык"),
    "selectMailApp": MessageLookupByLibrary.simpleMessage(
      "Выберите почтовое приложение",
    ),
    "selectMorePhotos": MessageLookupByLibrary.simpleMessage(
      "Выбрать больше фото",
    ),
    "selectOneDateAndTime": MessageLookupByLibrary.simpleMessage(
      "Выбрать одну дату и время",
    ),
    "selectOneDateAndTimeForAll": MessageLookupByLibrary.simpleMessage(
      "Выберите одну дату и время для всех",
    ),
    "selectPersonToLink": MessageLookupByLibrary.simpleMessage(
      "Выберите человека для привязки",
    ),
    "selectReason": MessageLookupByLibrary.simpleMessage("Выберите причину"),
    "selectStartOfRange": MessageLookupByLibrary.simpleMessage(
      "Выберите начало диапазона",
    ),
    "selectTime": MessageLookupByLibrary.simpleMessage("Выбрать время"),
    "selectYourFace": MessageLookupByLibrary.simpleMessage(
      "Выберите своё лицо",
    ),
    "selectYourPlan": MessageLookupByLibrary.simpleMessage("Выберите тариф"),
    "selectedAlbums": m79,
    "selectedFilesAreNotOnEnte": MessageLookupByLibrary.simpleMessage(
      "Выбранные файлы отсутствуют в Ente",
    ),
    "selectedFoldersWillBeEncryptedAndBackedUp":
        MessageLookupByLibrary.simpleMessage(
          "Выбранные папки будут зашифрованы и сохранены в резервной копии",
        ),
    "selectedItemsWillBeDeletedFromAllAlbumsAndMoved":
        MessageLookupByLibrary.simpleMessage(
          "Выбранные элементы будут удалены из всех альбомов и перемещены в корзину.",
        ),
    "selectedItemsWillBeRemovedFromThisPerson":
        MessageLookupByLibrary.simpleMessage(
          "Выбранные элементы будут отвязаны от этого человека, но не удалены из вашей библиотеки.",
        ),
    "selectedPhotos": m80,
    "selectedPhotosWithYours": m81,
    "selfiesWithThem": m82,
    "send": MessageLookupByLibrary.simpleMessage("Отправить"),
    "sendEmail": MessageLookupByLibrary.simpleMessage(
      "Отправить электронное письмо",
    ),
    "sendInvite": MessageLookupByLibrary.simpleMessage("Отправить приглашение"),
    "sendLink": MessageLookupByLibrary.simpleMessage("Отправить ссылку"),
    "serverEndpoint": MessageLookupByLibrary.simpleMessage(
      "Конечная точка сервера",
    ),
    "sessionExpired": MessageLookupByLibrary.simpleMessage("Сессия истекла"),
    "sessionIdMismatch": MessageLookupByLibrary.simpleMessage(
      "Несоответствие ID сессии",
    ),
    "setAPassword": MessageLookupByLibrary.simpleMessage("Установить пароль"),
    "setAs": MessageLookupByLibrary.simpleMessage("Установить как"),
    "setCover": MessageLookupByLibrary.simpleMessage("Установить обложку"),
    "setLabel": MessageLookupByLibrary.simpleMessage("Установить"),
    "setNewPassword": MessageLookupByLibrary.simpleMessage(
      "Установите новый пароль",
    ),
    "setNewPin": MessageLookupByLibrary.simpleMessage(
      "Установите новый PIN-код",
    ),
    "setPasswordTitle": MessageLookupByLibrary.simpleMessage(
      "Установить пароль",
    ),
    "setRadius": MessageLookupByLibrary.simpleMessage("Установить радиус"),
    "setupComplete": MessageLookupByLibrary.simpleMessage(
      "Настройка завершена",
    ),
    "share": MessageLookupByLibrary.simpleMessage("Поделиться"),
    "shareALink": MessageLookupByLibrary.simpleMessage("Поделиться ссылкой"),
    "shareAlbumHint": MessageLookupByLibrary.simpleMessage(
      "Откройте альбом и нажмите кнопку «Поделиться» в правом верхнем углу, чтобы поделиться.",
    ),
    "shareAnAlbumNow": MessageLookupByLibrary.simpleMessage(
      "Поделиться альбомом",
    ),
    "shareLink": MessageLookupByLibrary.simpleMessage("Поделиться ссылкой"),
    "shareMyVerificationID": m83,
    "shareOnlyWithThePeopleYouWant": MessageLookupByLibrary.simpleMessage(
      "Делитесь только с теми, с кем хотите",
    ),
    "shareTextConfirmOthersVerificationID": m84,
    "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
      "Скачай Ente, чтобы мы могли легко делиться фото и видео в оригинальном качестве\n\nhttps://ente.io",
    ),
    "shareTextReferralCode": m85,
    "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
      "Поделиться с пользователями, не использующими Ente",
    ),
    "shareWithPeopleSectionTitle": m86,
    "shareYourFirstAlbum": MessageLookupByLibrary.simpleMessage(
      "Поделитесь своим первым альбомом",
    ),
    "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
      "Создавайте общие и совместные альбомы с другими пользователями Ente, включая пользователей на бесплатных тарифах.",
    ),
    "sharedByMe": MessageLookupByLibrary.simpleMessage("Я поделился"),
    "sharedByYou": MessageLookupByLibrary.simpleMessage("Вы поделились"),
    "sharedPhotoNotifications": MessageLookupByLibrary.simpleMessage(
      "Новые общие фото",
    ),
    "sharedPhotoNotificationsExplanation": MessageLookupByLibrary.simpleMessage(
      "Получать уведомления, когда кто-то добавляет фото в общий альбом, в котором вы состоите",
    ),
    "sharedWith": m87,
    "sharedWithMe": MessageLookupByLibrary.simpleMessage("Со мной поделились"),
    "sharedWithYou": MessageLookupByLibrary.simpleMessage("Поделились с вами"),
    "sharing": MessageLookupByLibrary.simpleMessage("Отправка..."),
    "shiftDatesAndTime": MessageLookupByLibrary.simpleMessage(
      "Сместить даты и время",
    ),
    "showLessFaces": MessageLookupByLibrary.simpleMessage(
      "Показывать меньше лиц",
    ),
    "showMemories": MessageLookupByLibrary.simpleMessage(
      "Показывать воспоминания",
    ),
    "showMoreFaces": MessageLookupByLibrary.simpleMessage(
      "Показывать больше лиц",
    ),
    "showPerson": MessageLookupByLibrary.simpleMessage("Показать человека"),
    "signOutFromOtherDevices": MessageLookupByLibrary.simpleMessage(
      "Выйти с других устройств",
    ),
    "signOutOtherBody": MessageLookupByLibrary.simpleMessage(
      "Если вы считаете, что кто-то может знать ваш пароль, вы можете принудительно выйти с других устройств, использующих ваш аккаунт.",
    ),
    "signOutOtherDevices": MessageLookupByLibrary.simpleMessage(
      "Выйти с других устройств",
    ),
    "signUpTerms": MessageLookupByLibrary.simpleMessage(
      "Я согласен с <u-terms>условиями предоставления услуг</u-terms> и <u-policy>политикой конфиденциальности</u-policy>",
    ),
    "singleFileDeleteFromDevice": m88,
    "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
      "Оно будет удалено из всех альбомов.",
    ),
    "singleFileInBothLocalAndRemote": m89,
    "singleFileInRemoteOnly": m90,
    "skip": MessageLookupByLibrary.simpleMessage("Пропустить"),
    "smartMemories": MessageLookupByLibrary.simpleMessage("Умные воспоминания"),
    "social": MessageLookupByLibrary.simpleMessage("Социальные сети"),
    "someItemsAreInBothEnteAndYourDevice": MessageLookupByLibrary.simpleMessage(
      "Некоторые элементы находятся как в Ente, так и на вашем устройстве.",
    ),
    "someOfTheFilesYouAreTryingToDeleteAre": MessageLookupByLibrary.simpleMessage(
      "Некоторые файлы, которые вы пытаетесь удалить, доступны только на вашем устройстве и не могут быть восстановлены после удаления",
    ),
    "someoneSharingAlbumsWithYouShouldSeeTheSameId":
        MessageLookupByLibrary.simpleMessage(
          "Тот, кто делится с вами альбомами, должен видеть такой же идентификатор на своём устройстве.",
        ),
    "somethingWentWrong": MessageLookupByLibrary.simpleMessage(
      "Что-то пошло не так",
    ),
    "somethingWentWrongPleaseTryAgain": MessageLookupByLibrary.simpleMessage(
      "Что-то пошло не так. Пожалуйста, попробуйте снова",
    ),
    "sorry": MessageLookupByLibrary.simpleMessage("Извините"),
    "sorryBackupFailedDesc": MessageLookupByLibrary.simpleMessage(
      "К сожалению, мы не смогли сделать резервную копию этого файла сейчас, мы повторим попытку позже.",
    ),
    "sorryCouldNotAddToFavorites": MessageLookupByLibrary.simpleMessage(
      "Извините, не удалось добавить в избранное!",
    ),
    "sorryCouldNotRemoveFromFavorites": MessageLookupByLibrary.simpleMessage(
      "Извините, не удалось удалить из избранного!",
    ),
    "sorryTheCodeYouveEnteredIsIncorrect": MessageLookupByLibrary.simpleMessage(
      "Извините, введённый вами код неверен",
    ),
    "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
        MessageLookupByLibrary.simpleMessage(
          "К сожалению, мы не смогли сгенерировать безопасные ключи на этом устройстве.\n\nПожалуйста, зарегистрируйтесь с другого устройства.",
        ),
    "sorryWeHadToPauseYourBackups": MessageLookupByLibrary.simpleMessage(
      "Извините, нам пришлось приостановить резервное копирование",
    ),
    "sort": MessageLookupByLibrary.simpleMessage("Сортировать"),
    "sortAlbumsBy": MessageLookupByLibrary.simpleMessage("Сортировать по"),
    "sortNewestFirst": MessageLookupByLibrary.simpleMessage("Сначала новые"),
    "sortOldestFirst": MessageLookupByLibrary.simpleMessage("Сначала старые"),
    "sparkleSuccess": MessageLookupByLibrary.simpleMessage("✨ Успех"),
    "sportsWithThem": m91,
    "spotlightOnThem": m92,
    "spotlightOnYourself": MessageLookupByLibrary.simpleMessage(
      "Вы в центре внимания",
    ),
    "startAccountRecoveryTitle": MessageLookupByLibrary.simpleMessage(
      "Начать восстановление",
    ),
    "startBackup": MessageLookupByLibrary.simpleMessage(
      "Начать резервное копирование",
    ),
    "status": MessageLookupByLibrary.simpleMessage("Статус"),
    "stopCastingBody": MessageLookupByLibrary.simpleMessage(
      "Хотите остановить трансляцию?",
    ),
    "stopCastingTitle": MessageLookupByLibrary.simpleMessage(
      "Остановить трансляцию",
    ),
    "storage": MessageLookupByLibrary.simpleMessage("Хранилище"),
    "storageBreakupFamily": MessageLookupByLibrary.simpleMessage("Семья"),
    "storageBreakupYou": MessageLookupByLibrary.simpleMessage("Вы"),
    "storageInGB": m93,
    "storageLimitExceeded": MessageLookupByLibrary.simpleMessage(
      "Превышен лимит хранилища",
    ),
    "storageUsageInfo": m94,
    "streamDetails": MessageLookupByLibrary.simpleMessage(
      "Информация о потоке",
    ),
    "strongStrength": MessageLookupByLibrary.simpleMessage("Высокая"),
    "subAlreadyLinkedErrMessage": m95,
    "subWillBeCancelledOn": m96,
    "subscribe": MessageLookupByLibrary.simpleMessage("Подписаться"),
    "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
      "Вам нужна активная платная подписка, чтобы включить общий доступ.",
    ),
    "subscription": MessageLookupByLibrary.simpleMessage("Подписка"),
    "success": MessageLookupByLibrary.simpleMessage("Успех"),
    "successfullyArchived": MessageLookupByLibrary.simpleMessage(
      "Успешно архивировано",
    ),
    "successfullyHid": MessageLookupByLibrary.simpleMessage("Успешно скрыто"),
    "successfullyUnarchived": MessageLookupByLibrary.simpleMessage(
      "Успешно извлечено",
    ),
    "successfullyUnhid": MessageLookupByLibrary.simpleMessage(
      "Успешно раскрыто",
    ),
    "suggestFeatures": MessageLookupByLibrary.simpleMessage("Предложить идею"),
    "sunrise": MessageLookupByLibrary.simpleMessage("На горизонте"),
    "support": MessageLookupByLibrary.simpleMessage("Поддержка"),
    "syncProgress": m97,
    "syncStopped": MessageLookupByLibrary.simpleMessage(
      "Синхронизация остановлена",
    ),
    "syncing": MessageLookupByLibrary.simpleMessage("Синхронизация..."),
    "systemTheme": MessageLookupByLibrary.simpleMessage("Системная"),
    "tapToCopy": MessageLookupByLibrary.simpleMessage(
      "нажмите, чтобы скопировать",
    ),
    "tapToEnterCode": MessageLookupByLibrary.simpleMessage(
      "Нажмите, чтобы ввести код",
    ),
    "tapToUnlock": MessageLookupByLibrary.simpleMessage(
      "Нажмите для разблокировки",
    ),
    "tapToUpload": MessageLookupByLibrary.simpleMessage("Нажмите для загрузки"),
    "tapToUploadIsIgnoredDue": m98,
    "tempErrorContactSupportIfPersists": MessageLookupByLibrary.simpleMessage(
      "Похоже, что-то пошло не так. Пожалуйста, повторите попытку через некоторое время. Если ошибка сохраняется, обратитесь в нашу службу поддержки.",
    ),
    "terminate": MessageLookupByLibrary.simpleMessage("Завершить"),
    "terminateSession": MessageLookupByLibrary.simpleMessage(
      "Завершить сеанс?",
    ),
    "terms": MessageLookupByLibrary.simpleMessage("Условия"),
    "termsOfServicesTitle": MessageLookupByLibrary.simpleMessage(
      "Условия использования",
    ),
    "thankYou": MessageLookupByLibrary.simpleMessage("Спасибо"),
    "thankYouForSubscribing": MessageLookupByLibrary.simpleMessage(
      "Спасибо за подписку!",
    ),
    "theDownloadCouldNotBeCompleted": MessageLookupByLibrary.simpleMessage(
      "Скачивание не может быть завершено",
    ),
    "theLinkYouAreTryingToAccessHasExpired":
        MessageLookupByLibrary.simpleMessage(
          "Срок действия ссылки, к которой вы обращаетесь, истёк.",
        ),
    "thePersonGroupsWillNotBeDisplayed": MessageLookupByLibrary.simpleMessage(
      "Группы людей больше не будут отображаться в разделе людей. Фотографии останутся нетронутыми.",
    ),
    "thePersonWillNotBeDisplayed": MessageLookupByLibrary.simpleMessage(
      "Человек больше не будет отображаться в разделе людей. Фотографии останутся нетронутыми.",
    ),
    "theRecoveryKeyYouEnteredIsIncorrect": MessageLookupByLibrary.simpleMessage(
      "Введённый вами ключ восстановления неверен",
    ),
    "theme": MessageLookupByLibrary.simpleMessage("Тема"),
    "theseItemsWillBeDeletedFromYourDevice":
        MessageLookupByLibrary.simpleMessage(
          "Эти элементы будут удалены с вашего устройства.",
        ),
    "theyAlsoGetXGb": m99,
    "theyWillBeDeletedFromAllAlbums": MessageLookupByLibrary.simpleMessage(
      "Они будут удалены из всех альбомов.",
    ),
    "thisActionCannotBeUndone": MessageLookupByLibrary.simpleMessage(
      "Это действие нельзя отменить",
    ),
    "thisAlbumAlreadyHDACollaborativeLink":
        MessageLookupByLibrary.simpleMessage(
          "У этого альбома уже есть совместная ссылка",
        ),
    "thisCanBeUsedToRecoverYourAccountIfYou": MessageLookupByLibrary.simpleMessage(
      "Это можно использовать для восстановления вашего аккаунта, если вы потеряете свой аутентификатор",
    ),
    "thisDevice": MessageLookupByLibrary.simpleMessage("Это устройство"),
    "thisEmailIsAlreadyInUse": MessageLookupByLibrary.simpleMessage(
      "Эта электронная почта уже используется",
    ),
    "thisImageHasNoExifData": MessageLookupByLibrary.simpleMessage(
      "Это фото не имеет данных EXIF",
    ),
    "thisIsMeExclamation": MessageLookupByLibrary.simpleMessage("Это я!"),
    "thisIsPersonVerificationId": m100,
    "thisIsYourVerificationId": MessageLookupByLibrary.simpleMessage(
      "Это ваш идентификатор подтверждения",
    ),
    "thisWeekThroughTheYears": MessageLookupByLibrary.simpleMessage(
      "Эта неделя сквозь годы",
    ),
    "thisWeekXYearsAgo": m101,
    "thisWillLogYouOutOfTheFollowingDevice":
        MessageLookupByLibrary.simpleMessage(
          "Это завершит ваш сеанс на следующем устройстве:",
        ),
    "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
      "Это завершит ваш сеанс на этом устройстве!",
    ),
    "thisWillMakeTheDateAndTimeOfAllSelected":
        MessageLookupByLibrary.simpleMessage(
          "Это сделает дату и время всех выбранных фото одинаковыми.",
        ),
    "thisWillRemovePublicLinksOfAllSelectedQuickLinks":
        MessageLookupByLibrary.simpleMessage(
          "Это удалит публичные ссылки всех выбранных быстрых ссылок.",
        ),
    "throughTheYears": m102,
    "toEnableAppLockPleaseSetupDevicePasscodeOrScreen":
        MessageLookupByLibrary.simpleMessage(
          "Для блокировки приложения, пожалуйста, настройте код или экран блокировки в настройках устройства.",
        ),
    "toHideAPhotoOrVideo": MessageLookupByLibrary.simpleMessage(
      "Скрыть фото или видео",
    ),
    "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
      "Чтобы сбросить пароль, сначала подтвердите вашу электронную почту.",
    ),
    "todaysLogs": MessageLookupByLibrary.simpleMessage("Сегодняшние логи"),
    "tooManyIncorrectAttempts": MessageLookupByLibrary.simpleMessage(
      "Слишком много неудачных попыток",
    ),
    "total": MessageLookupByLibrary.simpleMessage("всего"),
    "totalSize": MessageLookupByLibrary.simpleMessage("Общий размер"),
    "trash": MessageLookupByLibrary.simpleMessage("Корзина"),
    "trashDaysLeft": m103,
    "trim": MessageLookupByLibrary.simpleMessage("Сократить"),
    "tripInYear": m104,
    "tripToLocation": m105,
    "trustedContacts": MessageLookupByLibrary.simpleMessage(
      "Доверенные контакты",
    ),
    "trustedInviteBody": m106,
    "tryAgain": MessageLookupByLibrary.simpleMessage("Попробовать снова"),
    "turnOnBackupForAutoUpload": MessageLookupByLibrary.simpleMessage(
      "Включите резервное копирование, чтобы автоматически загружать файлы из этой папки на устройстве в Ente.",
    ),
    "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
    "twoMonthsFreeOnYearlyPlans": MessageLookupByLibrary.simpleMessage(
      "2 месяца в подарок на годовом тарифе",
    ),
    "twofactor": MessageLookupByLibrary.simpleMessage(
      "Двухфакторная аутентификация",
    ),
    "twofactorAuthenticationHasBeenDisabled":
        MessageLookupByLibrary.simpleMessage(
          "Двухфакторная аутентификация отключена",
        ),
    "twofactorAuthenticationPageTitle": MessageLookupByLibrary.simpleMessage(
      "Двухфакторная аутентификация",
    ),
    "twofactorAuthenticationSuccessfullyReset":
        MessageLookupByLibrary.simpleMessage(
          "Двухфакторная аутентификация успешно сброшена",
        ),
    "twofactorSetup": MessageLookupByLibrary.simpleMessage(
      "Настройка двухфакторной аутентификации",
    ),
    "typeOfGallerGallerytypeIsNotSupportedForRename": m107,
    "unarchive": MessageLookupByLibrary.simpleMessage("Извлечь из архива"),
    "unarchiveAlbum": MessageLookupByLibrary.simpleMessage(
      "Извлечь альбом из архива",
    ),
    "unarchiving": MessageLookupByLibrary.simpleMessage("Извлечение..."),
    "unavailableReferralCode": MessageLookupByLibrary.simpleMessage(
      "Извините, этот код недоступен.",
    ),
    "uncategorized": MessageLookupByLibrary.simpleMessage("Без категории"),
    "unhide": MessageLookupByLibrary.simpleMessage("Не скрывать"),
    "unhideToAlbum": MessageLookupByLibrary.simpleMessage("Перенести в альбом"),
    "unhiding": MessageLookupByLibrary.simpleMessage("Раскрытие..."),
    "unhidingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
      "Перенос файлов в альбом",
    ),
    "unlock": MessageLookupByLibrary.simpleMessage("Разблокировать"),
    "unpinAlbum": MessageLookupByLibrary.simpleMessage("Открепить альбом"),
    "unselectAll": MessageLookupByLibrary.simpleMessage("Отменить выбор"),
    "update": MessageLookupByLibrary.simpleMessage("Обновить"),
    "updateAvailable": MessageLookupByLibrary.simpleMessage(
      "Доступно обновление",
    ),
    "updatingFolderSelection": MessageLookupByLibrary.simpleMessage(
      "Обновление выбора папок...",
    ),
    "upgrade": MessageLookupByLibrary.simpleMessage("Улучшить"),
    "uploadIsIgnoredDueToIgnorereason": m108,
    "uploadingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
      "Загрузка файлов в альбом...",
    ),
    "uploadingMultipleMemories": m109,
    "uploadingSingleMemory": MessageLookupByLibrary.simpleMessage(
      "Сохранение 1 воспоминания...",
    ),
    "upto50OffUntil4thDec": MessageLookupByLibrary.simpleMessage(
      "Скидки до 50% до 4 декабря",
    ),
    "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
      "Доступное хранилище ограничено вашим текущим тарифом. Избыточное полученное хранилище автоматически станет доступным при улучшении тарифа.",
    ),
    "useAsCover": MessageLookupByLibrary.simpleMessage(
      "Использовать для обложки",
    ),
    "useDifferentPlayerInfo": MessageLookupByLibrary.simpleMessage(
      "Проблемы с воспроизведением видео? Нажмите и удерживайте здесь, чтобы попробовать другой плеер.",
    ),
    "usePublicLinksForPeopleNotOnEnte": MessageLookupByLibrary.simpleMessage(
      "Используйте публичные ссылки для людей, не использующих Ente",
    ),
    "useRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Использовать ключ восстановления",
    ),
    "useSelectedPhoto": MessageLookupByLibrary.simpleMessage(
      "Использовать выбранное фото",
    ),
    "usedSpace": MessageLookupByLibrary.simpleMessage("Использовано места"),
    "validTill": m110,
    "verificationFailedPleaseTryAgain": MessageLookupByLibrary.simpleMessage(
      "Проверка не удалась, пожалуйста, попробуйте снова",
    ),
    "verificationId": MessageLookupByLibrary.simpleMessage(
      "Идентификатор подтверждения",
    ),
    "verify": MessageLookupByLibrary.simpleMessage("Подтвердить"),
    "verifyEmail": MessageLookupByLibrary.simpleMessage(
      "Подтвердить электронную почту",
    ),
    "verifyEmailID": m111,
    "verifyIDLabel": MessageLookupByLibrary.simpleMessage("Подтвердить"),
    "verifyPasskey": MessageLookupByLibrary.simpleMessage(
      "Подтвердить ключ доступа",
    ),
    "verifyPassword": MessageLookupByLibrary.simpleMessage(
      "Подтвердить пароль",
    ),
    "verifying": MessageLookupByLibrary.simpleMessage("Проверка..."),
    "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Проверка ключа восстановления...",
    ),
    "videoInfo": MessageLookupByLibrary.simpleMessage("Информация о видео"),
    "videoSmallCase": MessageLookupByLibrary.simpleMessage("видео"),
    "videoStreaming": MessageLookupByLibrary.simpleMessage("Потоковое видео"),
    "videos": MessageLookupByLibrary.simpleMessage("Видео"),
    "viewActiveSessions": MessageLookupByLibrary.simpleMessage(
      "Просмотр активных сессий",
    ),
    "viewAddOnButton": MessageLookupByLibrary.simpleMessage(
      "Посмотреть дополнения",
    ),
    "viewAll": MessageLookupByLibrary.simpleMessage("Посмотреть все"),
    "viewAllExifData": MessageLookupByLibrary.simpleMessage(
      "Посмотреть все данные EXIF",
    ),
    "viewLargeFiles": MessageLookupByLibrary.simpleMessage("Большие файлы"),
    "viewLargeFilesDesc": MessageLookupByLibrary.simpleMessage(
      "Узнайте, какие файлы занимают больше всего места.",
    ),
    "viewLogs": MessageLookupByLibrary.simpleMessage("Просмотреть логи"),
    "viewPersonToUnlink": m112,
    "viewRecoveryKey": MessageLookupByLibrary.simpleMessage(
      "Увидеть ключ восстановления",
    ),
    "viewer": MessageLookupByLibrary.simpleMessage("Зритель"),
    "viewersSuccessfullyAdded": m113,
    "visitWebToManage": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, посетите web.ente.io для управления вашей подпиской",
    ),
    "waitingForVerification": MessageLookupByLibrary.simpleMessage(
      "Ожидание подтверждения...",
    ),
    "waitingForWifi": MessageLookupByLibrary.simpleMessage("Ожидание Wi-Fi..."),
    "warning": MessageLookupByLibrary.simpleMessage("Предупреждение"),
    "weAreOpenSource": MessageLookupByLibrary.simpleMessage(
      "У нас открытый исходный код!",
    ),
    "weDontSupportEditingPhotosAndAlbumsThatYouDont":
        MessageLookupByLibrary.simpleMessage(
          "Мы не поддерживаем редактирование фото и альбомов, которые вам пока не принадлежат",
        ),
    "weHaveSendEmailTo": m114,
    "weakStrength": MessageLookupByLibrary.simpleMessage("Низкая"),
    "welcomeBack": MessageLookupByLibrary.simpleMessage("С возвращением!"),
    "whatsNew": MessageLookupByLibrary.simpleMessage("Что нового"),
    "whyAddTrustContact": MessageLookupByLibrary.simpleMessage(
      "Доверенный контакт может помочь в восстановлении ваших данных.",
    ),
    "widgets": MessageLookupByLibrary.simpleMessage("Виджеты"),
    "wishThemAHappyBirthday": m115,
    "yearShort": MessageLookupByLibrary.simpleMessage("год"),
    "yearly": MessageLookupByLibrary.simpleMessage("Ежегодно"),
    "yearsAgo": m116,
    "yes": MessageLookupByLibrary.simpleMessage("Да"),
    "yesCancel": MessageLookupByLibrary.simpleMessage("Да, отменить"),
    "yesConvertToViewer": MessageLookupByLibrary.simpleMessage(
      "Да, перевести в зрители",
    ),
    "yesDelete": MessageLookupByLibrary.simpleMessage("Да, удалить"),
    "yesDiscardChanges": MessageLookupByLibrary.simpleMessage(
      "Да, отменить изменения",
    ),
    "yesIgnore": MessageLookupByLibrary.simpleMessage("Да, игнорировать"),
    "yesLogout": MessageLookupByLibrary.simpleMessage("Да, выйти"),
    "yesRemove": MessageLookupByLibrary.simpleMessage("Да, удалить"),
    "yesRenew": MessageLookupByLibrary.simpleMessage("Да, продлить"),
    "yesResetPerson": MessageLookupByLibrary.simpleMessage(
      "Да, сбросить данные человека",
    ),
    "you": MessageLookupByLibrary.simpleMessage("Вы"),
    "youAndThem": m117,
    "youAreOnAFamilyPlan": MessageLookupByLibrary.simpleMessage(
      "Вы на семейном тарифе!",
    ),
    "youAreOnTheLatestVersion": MessageLookupByLibrary.simpleMessage(
      "Вы используете последнюю версию",
    ),
    "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
      "* Вы можете увеличить хранилище максимум в два раза",
    ),
    "youCanManageYourLinksInTheShareTab": MessageLookupByLibrary.simpleMessage(
      "Вы можете управлять своими ссылками на вкладке «Поделиться».",
    ),
    "youCanTrySearchingForADifferentQuery":
        MessageLookupByLibrary.simpleMessage(
          "Вы можете попробовать выполнить поиск по другому запросу.",
        ),
    "youCannotDowngradeToThisPlan": MessageLookupByLibrary.simpleMessage(
      "Вы не можете понизить до этого тарифа",
    ),
    "youCannotShareWithYourself": MessageLookupByLibrary.simpleMessage(
      "Вы не можете поделиться с самим собой",
    ),
    "youDontHaveAnyArchivedItems": MessageLookupByLibrary.simpleMessage(
      "У вас нет архивных элементов.",
    ),
    "youHaveSuccessfullyFreedUp": m118,
    "yourAccountHasBeenDeleted": MessageLookupByLibrary.simpleMessage(
      "Ваш аккаунт был удалён",
    ),
    "yourMap": MessageLookupByLibrary.simpleMessage("Ваша карта"),
    "yourPlanWasSuccessfullyDowngraded": MessageLookupByLibrary.simpleMessage(
      "Ваш тариф успешно понижен",
    ),
    "yourPlanWasSuccessfullyUpgraded": MessageLookupByLibrary.simpleMessage(
      "Ваш тариф успешно повышен",
    ),
    "yourPurchaseWasSuccessful": MessageLookupByLibrary.simpleMessage(
      "Ваша покупка прошла успешно",
    ),
    "yourStorageDetailsCouldNotBeFetched": MessageLookupByLibrary.simpleMessage(
      "Не удалось получить данные о вашем хранилище",
    ),
    "yourSubscriptionHasExpired": MessageLookupByLibrary.simpleMessage(
      "Срок действия вашей подписки истёк",
    ),
    "yourSubscriptionWasUpdatedSuccessfully":
        MessageLookupByLibrary.simpleMessage("Ваша подписка успешно обновлена"),
    "yourVerificationCodeHasExpired": MessageLookupByLibrary.simpleMessage(
      "Срок действия вашего кода подтверждения истёк",
    ),
    "youveNoDuplicateFilesThatCanBeCleared":
        MessageLookupByLibrary.simpleMessage(
          "У вас нет дубликатов файлов, которые можно удалить",
        ),
    "youveNoFilesInThisAlbumThatCanBeDeleted":
        MessageLookupByLibrary.simpleMessage(
          "В этом альбоме нет файлов, которые можно удалить",
        ),
    "zoomOutToSeePhotos": MessageLookupByLibrary.simpleMessage(
      "Уменьшите масштаб, чтобы увидеть фото",
    ),
  };
}
