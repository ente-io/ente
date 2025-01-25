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

  static String m6(count) =>
      "${Intl.plural(count, one: 'Добавьте соавтора', few: 'Добавьте соавторов', many: 'Добавьте соавторов', other: 'Добавьте соавторов')}";

  static String m7(count) =>
      "${Intl.plural(count, one: 'Добавить элемент', other: 'Добавить элементы')}";

  static String m8(storageAmount, endDate) =>
      "Ваше дополнение ${storageAmount} действительно по ${endDate}";

  static String m9(count) =>
      "${Intl.plural(count, one: 'Добавьте зрителя', few: 'Добавьте зрителей', many: 'Добавьте зрителей', other: 'Добавьте зрителей')}";

  static String m10(emailOrName) => "Добавлено ${emailOrName}";

  static String m11(albumName) => "Успешно добавлено в ${albumName}";

  static String m12(count) =>
      "${Intl.plural(count, zero: 'Нет Участников', one: '1 Участник', other: '${count} Участника')}";

  static String m13(versionValue) => "Версия: ${versionValue}";

  static String m14(freeAmount, storageUnit) =>
      "${freeAmount} ${storageUnit} свободно";

  static String m15(paymentProvider) =>
      "Пожалуйста, сначала отмените вашу существующую подписку от ${paymentProvider}";

  static String m16(user) =>
      "${user} больше не сможет добавлять фотографии в этот альбом\n\nОни все еще смогут удалять существующие фотографии, добавленные ими";

  static String m17(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true': 'Ваша семья получила ${storageAmountInGb} ГБ',
            'false': 'Вы уже получили ${storageAmountInGb} ГБ',
            'other': 'Вы уже получили ${storageAmountInGb} ГБ!',
          })}";

  static String m18(albumName) => "Совместная ссылка создана для ${albumName}";

  static String m19(count) =>
      "${Intl.plural(count, zero: 'Добавлено 0 соавторов', one: 'Добавлен 1 соавтор', other: 'Добавлено ${count} соавторов')}";

  static String m21(familyAdminEmail) =>
      "Пожалуйста, свяжитесь с <green>${familyAdminEmail}</green> для управления подпиской";

  static String m22(provider) =>
      "Пожалуйста, свяжитесь с нами по адресу support@ente.io для управления подпиской ${provider}.";

  static String m23(endpoint) => "Подключено к ${endpoint}";

  static String m24(count) =>
      "${Intl.plural(count, one: 'Удалена ${count} штука', other: 'Удалено ${count} штук')}";

  static String m25(currentlyDeleting, totalCount) =>
      "Удаление ${currentlyDeleting} / ${totalCount}";

  static String m26(albumName) =>
      "Это удалит публичную ссылку для доступа к \"${albumName}\".";

  static String m27(supportEmail) =>
      "Пожалуйста, отправьте электронное письмо на адрес ${supportEmail} с вашего зарегистрированного адреса электронной почты";

  static String m28(count, storageSaved) =>
      "Вы привели себя в порядок ${Intl.plural(count, one: '${count} duplicate file', other: '${count} duplicate files')}, экономия (${storageSaved}!)\n";

  static String m29(count, formattedSize) =>
      "${count} файлов, ${formattedSize}";

  static String m30(newEmail) =>
      "Адрес электронной почты изменен на ${newEmail}";

  static String m31(email) =>
      "У ${email} нет учетной записи Ente.\n\nОтправьте им приглашение для обмена фотографиями.";

  static String m32(text) => "Дополнительные фотографии найдены для ${text}";

  static String m33(count, formattedNumber) =>
      "${Intl.plural(count, one: 'для 1 файла было создан бекап', other: 'для ${formattedNumber} файлов были созданы бекапы')}";

  static String m34(count, formattedNumber) =>
      "${Intl.plural(count, one: 'для 1 файла было создан бекап', other: 'для ${formattedNumber} файлов были созданы бекапы')}";

  static String m35(storageAmountInGB) =>
      "${storageAmountInGB} Гигабайт каждый раз когда кто-то подписывается на платный план и применяет ваш код";

  static String m36(endDate) =>
      "Бесплатная пробная версия действительна до ${endDate}";

  static String m37(count) =>
      "Вы все еще можете получить доступ к ${Intl.plural(count, one: 'ниму', other: 'ним')} на Ente, пока у вас есть активная подписка";

  static String m38(sizeInMBorGB) => "Освободите ${sizeInMBorGB}";

  static String m39(count, formattedSize) =>
      "${Intl.plural(count, one: 'Это можно удалить с устройства, чтобы освободить ${formattedSize}', other: 'Их можно удалить с устройства, чтобы освободить ${formattedSize}')}";

  static String m40(currentlyProcessing, totalCount) =>
      "Обработка ${currentlyProcessing} / ${totalCount}";

  static String m41(count) =>
      "${Intl.plural(count, one: '${count} штука', other: '${count} штук')}";

  static String m43(expiryTime) => "Ссылка истечёт через ${expiryTime}";

  static String m3(count, formattedCount) =>
      "${Intl.plural(count, zero: 'нет воспоминаний', one: '${formattedCount} воспоминание', other: '${formattedCount} воспоминаний')}";

  static String m44(count) =>
      "${Intl.plural(count, one: 'Переместить элемент', other: 'Переместить элементы')}";

  static String m45(albumName) => "Успешно перемещено в ${albumName}";

  static String m46(personName) => "Нет предложений для ${personName}";

  static String m47(name) => "Не ${name}?";

  static String m0(passwordStrengthValue) =>
      "Мощность пароля: ${passwordStrengthValue}";

  static String m49(providerName) =>
      "Если с вас сняли оплату, обратитесь в службу поддержки ${providerName}";

  static String m50(count) =>
      "${Intl.plural(count, zero: '0 photo', one: '1 photo', other: '${count} photos')}";

  static String m51(endDate) =>
      "Бесплатный пробный период до ${endDate}.\nПосле, вы сможете выбрать платный план.";

  static String m52(toEmail) => "Пожалуйста, напишите нам на ${toEmail}";

  static String m53(toEmail) => "Пожалуйста, отправьте логи на \n${toEmail}";

  static String m54(folderName) => "Обработка ${folderName}...";

  static String m55(storeName) => "Оцените нас в ${storeName}";

  static String m59(storageInGB) =>
      "3. Вы оба получаете ${storageInGB} Гигабайт* бесплатно";

  static String m60(userEmail) =>
      "${userEmail} будет удален из этого общего альбома\n\nВсе добавленные им фотографии также будут удалены из альбома";

  static String m61(endDate) => "Обновление подписки на ${endDate}";

  static String m62(count) =>
      "${Intl.plural(count, one: '${count} результат найден', other: '${count} результатов найдено')}";

  static String m4(count) => "${count} выбрано";

  static String m64(count, yourCount) => "${count} выбрано (${yourCount} ваши)";

  static String m65(verificationID) =>
      "Вот мой проверочный ID: ${verificationID} для ente.io.";

  static String m5(verificationID) =>
      "Эй, вы можете подтвердить, что это ваш идентификатор подтверждения ente.io: ${verificationID}";

  static String m66(referralCode, referralStorageInGB) =>
      "Реферальный код Ente: ${referralCode} \n\nПримените его в разделе «Настройки» → «Основные» → «Рефералы», чтобы получить ${referralStorageInGB} Гигабайт бесплатно после того как вы подпишетесь на платный план";

  static String m67(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Поделится с конкретными людьми', one: 'Поделено с 1 человеком', other: 'Поделено с ${numberOfPeople} людьми')}";

  static String m68(emailIDs) => "Поделиться с ${emailIDs}";

  static String m69(fileType) =>
      "Это ${fileType} будет удалено с вашего устройства.";

  static String m70(fileType) =>
      "Этот ${fileType} есть и в Ente, и на вашем устройстве.";

  static String m71(fileType) => "Этот ${fileType} будет удалён из Ente.";

  static String m1(storageAmountInGB) => "${storageAmountInGB} Гигабайт";

  static String m72(
          usedAmount, usedStorageUnit, totalAmount, totalStorageUnit) =>
      "${usedAmount} ${usedStorageUnit} из ${totalAmount} ${totalStorageUnit} использовано";

  static String m73(id) =>
      "Ваш ${id} уже связан с другой учетной записью Ente.\nЕсли вы хотите использовать ${id} с этой учетной записью, пожалуйста, свяжитесь с нашей службой поддержки";

  static String m74(endDate) => "Ваша подписка будет отменена ${endDate}";

  static String m75(completed, total) => "${completed}/${total} сохранено";

  static String m77(storageAmountInGB) =>
      "Они тоже получат ${storageAmountInGB} Гигабайт";

  static String m78(email) =>
      "Этот идентификатор подтверждения пользователя ${email}";

  static String m81(galleryType) =>
      "Тип галереи ${galleryType} не поддерживается для переименования";

  static String m82(ignoreReason) =>
      "Загрузка игнорируется из-за ${ignoreReason}";

  static String m84(endDate) => "Действителен по ${endDate}";

  static String m85(email) => "Подтвердить ${email}";

  static String m86(count) =>
      "${Intl.plural(count, zero: 'Добавлено 0 зрителей', one: 'Добавлен 1 зритель', other: 'Добавлено ${count} зрителей')}";

  static String m2(email) => "Мы отправили письмо на <green>${email}</green>";

  static String m87(count) =>
      "${Intl.plural(count, one: '${count} год назад', other: '${count} лет назад')}";

  static String m88(storageSaved) => "Вы успешно освободили ${storageSaved}!";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable":
            MessageLookupByLibrary.simpleMessage("Доступна новая версия Ente."),
        "about": MessageLookupByLibrary.simpleMessage("О программе"),
        "acceptTrustInvite":
            MessageLookupByLibrary.simpleMessage("Принять приглашение"),
        "account": MessageLookupByLibrary.simpleMessage("Аккаунт"),
        "accountIsAlreadyConfigured":
            MessageLookupByLibrary.simpleMessage("Аккаунт уже настроен."),
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("С возвращением!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Я понимаю, что если я потеряю свой пароль, я могу потерять свои данные, так как мои данные в <underline>сквозном шифровании</underline>."),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Активные сеансы"),
        "add": MessageLookupByLibrary.simpleMessage("Добавить"),
        "addAName": MessageLookupByLibrary.simpleMessage("Добавить имя"),
        "addANewEmail": MessageLookupByLibrary.simpleMessage(
            "Добавить новый адрес эл. почты"),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Добавить соавтора"),
        "addCollaborators": m6,
        "addFiles": MessageLookupByLibrary.simpleMessage("Добавить файлы"),
        "addFromDevice":
            MessageLookupByLibrary.simpleMessage("Добавить с устройства"),
        "addItem": m7,
        "addLocation": MessageLookupByLibrary.simpleMessage("Добавить место"),
        "addLocationButton": MessageLookupByLibrary.simpleMessage("Добавить"),
        "addMore": MessageLookupByLibrary.simpleMessage("Добавить еще"),
        "addName": MessageLookupByLibrary.simpleMessage("Добавить имя"),
        "addNameOrMerge":
            MessageLookupByLibrary.simpleMessage("Добавить имя или объединить"),
        "addNew": MessageLookupByLibrary.simpleMessage("Добавить новое"),
        "addNewPerson":
            MessageLookupByLibrary.simpleMessage("Добавить новую персону"),
        "addOnPageSubtitle":
            MessageLookupByLibrary.simpleMessage("Подробнее о расширениях"),
        "addOnValidTill": m8,
        "addOns": MessageLookupByLibrary.simpleMessage("Расширения"),
        "addPhotos":
            MessageLookupByLibrary.simpleMessage("Добавить фотографии"),
        "addSelected":
            MessageLookupByLibrary.simpleMessage("Добавить выбранные"),
        "addToAlbum": MessageLookupByLibrary.simpleMessage("Добавить в альбом"),
        "addToEnte": MessageLookupByLibrary.simpleMessage("Добавить в Ente"),
        "addToHiddenAlbum":
            MessageLookupByLibrary.simpleMessage("Добавить в скрытый альбом"),
        "addTrustedContact":
            MessageLookupByLibrary.simpleMessage("Добавить доверенный контакт"),
        "addViewer":
            MessageLookupByLibrary.simpleMessage("Добавить наблюдателя"),
        "addViewers": m9,
        "addYourPhotosNow":
            MessageLookupByLibrary.simpleMessage("Добавьте ваши фотографии"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Добавлено как"),
        "addedBy": m10,
        "addedSuccessfullyTo": m11,
        "addingToFavorites":
            MessageLookupByLibrary.simpleMessage("Добавление в избранное..."),
        "advanced": MessageLookupByLibrary.simpleMessage("Дополнительно"),
        "advancedSettings":
            MessageLookupByLibrary.simpleMessage("Дополнительно"),
        "after1Day": MessageLookupByLibrary.simpleMessage("Через 1 день"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("Через 1 час"),
        "after1Month": MessageLookupByLibrary.simpleMessage("Через 1 месяц"),
        "after1Week": MessageLookupByLibrary.simpleMessage("Через неделю"),
        "after1Year": MessageLookupByLibrary.simpleMessage("Через 1 год"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Владелец"),
        "albumParticipantsCount": m12,
        "albumTitle": MessageLookupByLibrary.simpleMessage("Название альбома"),
        "albumUpdated": MessageLookupByLibrary.simpleMessage("Альбом обновлен"),
        "albums": MessageLookupByLibrary.simpleMessage("Альбомы"),
        "allClear": MessageLookupByLibrary.simpleMessage("✨ Все чисто"),
        "allMemoriesPreserved":
            MessageLookupByLibrary.simpleMessage("Все воспоминания сохранены"),
        "allPersonGroupingWillReset": MessageLookupByLibrary.simpleMessage(
            "Все группы этого человека будут сброшены, и вы потеряете все предложения, сделанные для этого человека"),
        "allow": MessageLookupByLibrary.simpleMessage("Разрешить"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Разрешить пользователям со ссылкой также добавлять фотографии в общий альбом."),
        "allowAddingPhotos":
            MessageLookupByLibrary.simpleMessage("Разрешить добавление фото"),
        "allowAppToOpenSharedAlbumLinks": MessageLookupByLibrary.simpleMessage(
            "Разрешить приложению открывать общие ссылки на альбомы"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("Разрешить загрузку"),
        "allowPeopleToAddPhotos": MessageLookupByLibrary.simpleMessage(
            "Разрешить пользователям добавлять фотографии"),
        "androidBiometricHint":
            MessageLookupByLibrary.simpleMessage("Верификация личности"),
        "androidBiometricNotRecognized": MessageLookupByLibrary.simpleMessage(
            "Не распознано. Попробуйте еще раз."),
        "androidBiometricRequiredTitle":
            MessageLookupByLibrary.simpleMessage("Требуется биометрия"),
        "androidBiometricSuccess":
            MessageLookupByLibrary.simpleMessage("Успешно"),
        "androidCancelButton": MessageLookupByLibrary.simpleMessage("Отменить"),
        "androidDeviceCredentialsRequiredTitle":
            MessageLookupByLibrary.simpleMessage(
                "Требуются учетные данные устройства"),
        "androidDeviceCredentialsSetupDescription":
            MessageLookupByLibrary.simpleMessage(
                "Требуются учетные данные устройства"),
        "androidGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "На вашем устройстве не настроена биометрия. Перейдите в «Настройки > Безопасность», чтобы добавить биометрическую аутентификацию."),
        "androidIosWebDesktop":
            MessageLookupByLibrary.simpleMessage("Android, iOS, Web, ПК"),
        "androidSignInTitle":
            MessageLookupByLibrary.simpleMessage("Требуется аутентификация"),
        "appLock":
            MessageLookupByLibrary.simpleMessage("Блокировка приложения"),
        "appLockDescriptions": MessageLookupByLibrary.simpleMessage(
            "Выберите между экраном блокировки вашего устройства и пользовательским экраном блокировки с PIN-кодом или паролем."),
        "appVersion": m13,
        "appleId": MessageLookupByLibrary.simpleMessage("Apple ID"),
        "apply": MessageLookupByLibrary.simpleMessage("Применить"),
        "applyCodeTitle": MessageLookupByLibrary.simpleMessage("Применить код"),
        "appstoreSubscription":
            MessageLookupByLibrary.simpleMessage("Подписка на AppStore"),
        "archive": MessageLookupByLibrary.simpleMessage("Архивировать"),
        "archiveAlbum":
            MessageLookupByLibrary.simpleMessage("Архивировать альбом"),
        "archiving": MessageLookupByLibrary.simpleMessage("Архивация..."),
        "areYouSureThatYouWantToLeaveTheFamily":
            MessageLookupByLibrary.simpleMessage(
                "Вы уверены, что хотите покинуть семейный план?"),
        "areYouSureYouWantToCancel": MessageLookupByLibrary.simpleMessage(
            "Вы уверены, что хотите отменить?"),
        "areYouSureYouWantToChangeYourPlan":
            MessageLookupByLibrary.simpleMessage(
                "Хотите сменить текущий план?"),
        "areYouSureYouWantToExit": MessageLookupByLibrary.simpleMessage(
            "Вы уверены, что хотите выйти?"),
        "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
            "Вы уверены, что хотите выйти?"),
        "areYouSureYouWantToRenew": MessageLookupByLibrary.simpleMessage(
            "Вы уверены, что хотите продлить?"),
        "areYouSureYouWantToResetThisPerson":
            MessageLookupByLibrary.simpleMessage(
                "Вы уверены, что хотите сбросить этого человека?"),
        "askCancelReason": MessageLookupByLibrary.simpleMessage(
            "Ваша подписка была отменена. Хотите рассказать почему?"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "Какова основная причина, по которой вы удаляете свой аккаунт?"),
        "askYourLovedOnesToShare": MessageLookupByLibrary.simpleMessage(
            "Попросите ваших близких поделиться"),
        "atAFalloutShelter": MessageLookupByLibrary.simpleMessage("в бункере"),
        "authToChangeEmailVerificationSetting":
            MessageLookupByLibrary.simpleMessage(
                "Пожалуйста, войдите, чтобы изменить настройку подтверждения электронной почты"),
        "authToChangeLockscreenSetting": MessageLookupByLibrary.simpleMessage(
            "Пожалуйста, авторизуйтесь, чтобы изменить настройки экрана блокировки"),
        "authToChangeYourEmail": MessageLookupByLibrary.simpleMessage(
            "Пожалуйста, авторизуйтесь, чтобы изменить адрес электронной почты"),
        "authToChangeYourPassword": MessageLookupByLibrary.simpleMessage(
            "Пожалуйста, авторизуйтесь, чтобы изменить пароль"),
        "authToConfigureTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Пожалуйста, авторизуйтесь для настройки двухфакторной аутентификации"),
        "authToInitiateAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Пожалуйста, авторизуйтесь, чтобы начать удаление аккаунта"),
        "authToViewPasskey": MessageLookupByLibrary.simpleMessage(
            "Пожалуйста, авторизуйтесь, чтобы просмотреть ваш пароль"),
        "authToViewYourActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Пожалуйста, авторизуйтесь для просмотра активных сессий"),
        "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
            "Пожалуйста, авторизуйтесь для просмотра скрытых файлов"),
        "authToViewYourMemories": MessageLookupByLibrary.simpleMessage(
            "Пожалуйста, авторизуйтесь для просмотра воспоминаний"),
        "authToViewYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Пожалуйста, авторизуйтесь для просмотра вашего ключа восстановления"),
        "authenticating":
            MessageLookupByLibrary.simpleMessage("Аутентификация..."),
        "authenticationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Аутентификация не удалась, попробуйте еще раз"),
        "authenticationSuccessful": MessageLookupByLibrary.simpleMessage(
            "Аутентификация прошла успешно!"),
        "autoCastDialogBody": MessageLookupByLibrary.simpleMessage(
            "Здесь вы увидите доступные устройства."),
        "autoCastiOSPermission": MessageLookupByLibrary.simpleMessage(
            "Убедитесь, что для приложения Ente Photos включены права доступа к локальной сети в настройках."),
        "autoLock": MessageLookupByLibrary.simpleMessage("Автоблокировка"),
        "autoLockFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "Время в фоне, после которого приложение блокируется"),
        "autoLogoutMessage": MessageLookupByLibrary.simpleMessage(
            "В связи с технической ошибкой вы вышли из системы. Приносим свои извинения."),
        "autoPair":
            MessageLookupByLibrary.simpleMessage("Автоматическое сопряжение"),
        "autoPairDesc": MessageLookupByLibrary.simpleMessage(
            "Автоматическое подключение работает только с устройствами, поддерживающими Chromecast."),
        "available": MessageLookupByLibrary.simpleMessage("Доступно"),
        "availableStorageSpace": m14,
        "backedUpFolders":
            MessageLookupByLibrary.simpleMessage("Резервное копирование папок"),
        "backup": MessageLookupByLibrary.simpleMessage("Резервное копирование"),
        "backupFailed": MessageLookupByLibrary.simpleMessage(
            "Ошибка резервного копирования"),
        "backupFile": MessageLookupByLibrary.simpleMessage("Резервный файл"),
        "backupOverMobileData": MessageLookupByLibrary.simpleMessage(
            "Резервное копирование через мобильную сеть"),
        "backupSettings": MessageLookupByLibrary.simpleMessage(
            "Настройки резервного копирования"),
        "backupStatusDescription": MessageLookupByLibrary.simpleMessage(
            "Здесь будут сохранены резервные копии"),
        "backupVideos":
            MessageLookupByLibrary.simpleMessage("Резервное копирование видео"),
        "birthday": MessageLookupByLibrary.simpleMessage("День рождения"),
        "blackFridaySale": MessageLookupByLibrary.simpleMessage(
            "Распродажа в \"Черную пятницу\""),
        "blog": MessageLookupByLibrary.simpleMessage("Блог"),
        "cachedData":
            MessageLookupByLibrary.simpleMessage("Кэшированные данные"),
        "calculating": MessageLookupByLibrary.simpleMessage("Расчёт..."),
        "canNotUploadToAlbumsOwnedByOthers":
            MessageLookupByLibrary.simpleMessage(
                "Невозможно загрузить в альбомы других людей"),
        "canOnlyCreateLinkForFilesOwnedByYou":
            MessageLookupByLibrary.simpleMessage(
                "Можно создать ссылку только для ваших файлов"),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "Можно удалять только файлы, принадлежащие вам"),
        "cancel": MessageLookupByLibrary.simpleMessage("Отменить"),
        "cancelOtherSubscription": m15,
        "cancelSubscription":
            MessageLookupByLibrary.simpleMessage("Отменить подписку"),
        "cannotAddMorePhotosAfterBecomingViewer": m16,
        "cannotDeleteSharedFiles": MessageLookupByLibrary.simpleMessage(
            "Невозможно удалить общие файлы"),
        "castAlbum": MessageLookupByLibrary.simpleMessage("Трансляция альбома"),
        "castIPMismatchBody": MessageLookupByLibrary.simpleMessage(
            "Пожалуйста, убедитесь, что вы находитесь в той же сети, что и ТВ."),
        "castIPMismatchTitle": MessageLookupByLibrary.simpleMessage(
            "Не удалось транслировать альбом"),
        "castInstruction": MessageLookupByLibrary.simpleMessage(
            "Посетите cast.ente.io на устройстве, которое вы хотите подключить.\n\nВведите код ниже, чтобы воспроизвести альбом на телевизоре."),
        "centerPoint":
            MessageLookupByLibrary.simpleMessage("Центральная точка"),
        "change": MessageLookupByLibrary.simpleMessage("Изменить"),
        "changeEmail": MessageLookupByLibrary.simpleMessage(
            "Изменить адрес электронной почты"),
        "changeLocationOfSelectedItems": MessageLookupByLibrary.simpleMessage(
            "Изменить местоположение выбранных элементов?"),
        "changeLogBackupStatusContent": MessageLookupByLibrary.simpleMessage(
            "Мы добавили журнал всех файлов, которые были загружены в Ente, включая сбои и очереди."),
        "changeLogBackupStatusTitle":
            MessageLookupByLibrary.simpleMessage("Состояние резервных копий"),
        "changeLogDiscoverContent": MessageLookupByLibrary.simpleMessage(
            "Ищете фотографии ваших идентификационных карт, заметок или даже мемов? Перейдите во вкладку поиска и проверьте \"Узнать\". Основываясь на нашем поиске, это место для поиска фотографий, которые могут быть важны для вас.\\n\\nдоступно только в том случае, если вы включили Машинное обучение."),
        "changeLogDiscoverTitle":
            MessageLookupByLibrary.simpleMessage("Узнать"),
        "changeLogMagicSearchImprovementContent":
            MessageLookupByLibrary.simpleMessage(
                "Мы улучшили Магический Поиск, чтобы искать гораздо быстрее, поэтому вам не нужно ждать, чтобы найти то, что вы ищете."),
        "changeLogMagicSearchImprovementTitle":
            MessageLookupByLibrary.simpleMessage(
                "Улучшение Магического Поиска"),
        "changePassword":
            MessageLookupByLibrary.simpleMessage("Изменить пароль"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Изменить пароль"),
        "changePermissions":
            MessageLookupByLibrary.simpleMessage("Изменить разрешения?"),
        "changeYourReferralCode": MessageLookupByLibrary.simpleMessage(
            "Изменить ваш реферальный код"),
        "checkForUpdates":
            MessageLookupByLibrary.simpleMessage("Проверить обновления"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Пожалуйста, проверьте свой почтовый ящик (и спам) для завершения верификации"),
        "checkStatus": MessageLookupByLibrary.simpleMessage("Проверить статус"),
        "checking": MessageLookupByLibrary.simpleMessage("Проверка..."),
        "checkingModels":
            MessageLookupByLibrary.simpleMessage("Проверка моделей..."),
        "claimFreeStorage": MessageLookupByLibrary.simpleMessage(
            "Получить бесплатное хранилище"),
        "claimMore": MessageLookupByLibrary.simpleMessage("Получите больше!"),
        "claimed": MessageLookupByLibrary.simpleMessage("Получено"),
        "claimedStorageSoFar": m17,
        "cleanUncategorized":
            MessageLookupByLibrary.simpleMessage("Очистить \"Без Категории\""),
        "cleanUncategorizedDescription": MessageLookupByLibrary.simpleMessage(
            "Удалить все файлы из \"Без Категории\", которые присутствуют в других альбомах"),
        "clearCaches": MessageLookupByLibrary.simpleMessage("Очистить кэш"),
        "clearIndexes":
            MessageLookupByLibrary.simpleMessage("Очистить индексы"),
        "click": MessageLookupByLibrary.simpleMessage("• Клик"),
        "clickOnTheOverflowMenu": MessageLookupByLibrary.simpleMessage(
            "• Нажмите на дополнительное меню"),
        "close": MessageLookupByLibrary.simpleMessage("Закрыть"),
        "clubByCaptureTime":
            MessageLookupByLibrary.simpleMessage("Клуб по времени захвата"),
        "clubByFileName":
            MessageLookupByLibrary.simpleMessage("Клуб по имени файла"),
        "clusteringProgress":
            MessageLookupByLibrary.simpleMessage("Прогресс кластеризации"),
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("Код применён"),
        "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Код скопирован в буфер обмена"),
        "codeUsedByYou":
            MessageLookupByLibrary.simpleMessage("Код использованный вами"),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Создайте ссылку, чтобы позволить людям добавлять и просматривать фотографии в вашем общем альбоме без приложения или учетной записи Ente. Отлично подходит для сбора фотографий событий."),
        "collaborativeLink":
            MessageLookupByLibrary.simpleMessage("Совместная ссылка"),
        "collaborativeLinkCreatedFor": m18,
        "collaborator": MessageLookupByLibrary.simpleMessage("Соавтор"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Соавторы могут добавлять фотографии и видео в общий альбом."),
        "collaboratorsSuccessfullyAdded": m19,
        "collageLayout": MessageLookupByLibrary.simpleMessage("Разметка"),
        "collageSaved":
            MessageLookupByLibrary.simpleMessage("Коллаж сохранен в галерее"),
        "collect": MessageLookupByLibrary.simpleMessage("Собрать"),
        "collectEventPhotos":
            MessageLookupByLibrary.simpleMessage("Собрать фото события"),
        "collectPhotos":
            MessageLookupByLibrary.simpleMessage("Собрать фотографии"),
        "collectPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Создайте ссылку, где ваши друзья смогут загружать фото в оригинальном качестве."),
        "color": MessageLookupByLibrary.simpleMessage("Цвет"),
        "configuration": MessageLookupByLibrary.simpleMessage("Настройки"),
        "confirm": MessageLookupByLibrary.simpleMessage("Подтвердить"),
        "confirm2FADisable": MessageLookupByLibrary.simpleMessage(
            "Вы уверены, что хотите отключить двухфакторную аутентификацию?"),
        "confirmAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Подтвердить удаление аккаунта"),
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Да, я хочу навсегда удалить эту учётную запись и все её данные во всех приложениях Ente."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Подтвердите пароль"),
        "confirmPlanChange":
            MessageLookupByLibrary.simpleMessage("Подтвердить изменение плана"),
        "confirmRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Подтвердите ключ восстановления"),
        "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Подтвердите ваш ключ восстановления"),
        "connectToDevice":
            MessageLookupByLibrary.simpleMessage("Подключиться к устройству"),
        "contactFamilyAdmin": m21,
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("Связаться с поддержкой"),
        "contactToManageSubscription": m22,
        "contacts": MessageLookupByLibrary.simpleMessage("Контакты"),
        "contents": MessageLookupByLibrary.simpleMessage("Содержимое"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("Далее"),
        "continueOnFreeTrial": MessageLookupByLibrary.simpleMessage(
            "Продолжить на пробной версии"),
        "convertToAlbum":
            MessageLookupByLibrary.simpleMessage("Преобразовать в альбом"),
        "copyEmailAddress": MessageLookupByLibrary.simpleMessage(
            "Копировать адрес электронной почты"),
        "copyLink": MessageLookupByLibrary.simpleMessage("Копировать ссылку"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Скопируйте этот код\nв ваше приложение для аутентификации"),
        "couldNotBackUpTryLater": MessageLookupByLibrary.simpleMessage(
            "Нам не удалось создать резервную копию ваших данных.\nМы повторим попытку позже."),
        "couldNotFreeUpSpace":
            MessageLookupByLibrary.simpleMessage("Не удалось освободить место"),
        "couldNotUpdateSubscription": MessageLookupByLibrary.simpleMessage(
            "Не удалось обновить подписку"),
        "count": MessageLookupByLibrary.simpleMessage("Количество"),
        "crashReporting":
            MessageLookupByLibrary.simpleMessage("Отчеты об ошибках"),
        "create": MessageLookupByLibrary.simpleMessage("Создать"),
        "createAccount":
            MessageLookupByLibrary.simpleMessage("Создать учетную запись"),
        "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
            "Нажмите и удерживайте, чтобы выбрать фотографии, и нажмите +, чтобы создать альбом"),
        "createCollaborativeLink":
            MessageLookupByLibrary.simpleMessage("Создать совместную ссылку"),
        "createCollage": MessageLookupByLibrary.simpleMessage("Создать коллаж"),
        "createNewAccount": MessageLookupByLibrary.simpleMessage(
            "Создать новую учетную запись"),
        "createOrSelectAlbum":
            MessageLookupByLibrary.simpleMessage("Создать или выбрать альбом"),
        "createPublicLink":
            MessageLookupByLibrary.simpleMessage("Создать публичную ссылку"),
        "creatingLink":
            MessageLookupByLibrary.simpleMessage("Создание ссылки..."),
        "criticalUpdateAvailable":
            MessageLookupByLibrary.simpleMessage("Доступно важное обновление"),
        "crop": MessageLookupByLibrary.simpleMessage("Обрезать"),
        "currentUsageIs":
            MessageLookupByLibrary.simpleMessage("Текущее использование "),
        "currentlyRunning":
            MessageLookupByLibrary.simpleMessage("сейчас запущено"),
        "custom": MessageLookupByLibrary.simpleMessage("Свой"),
        "customEndpoint": m23,
        "darkTheme": MessageLookupByLibrary.simpleMessage("Темная тема"),
        "dayToday": MessageLookupByLibrary.simpleMessage("Сегодня"),
        "dayYesterday": MessageLookupByLibrary.simpleMessage("Вчера"),
        "declineTrustInvite":
            MessageLookupByLibrary.simpleMessage("Отклонить приглашение"),
        "decrypting": MessageLookupByLibrary.simpleMessage("Расшифровка..."),
        "decryptingVideo":
            MessageLookupByLibrary.simpleMessage("Расшифровка видео..."),
        "deduplicateFiles":
            MessageLookupByLibrary.simpleMessage("Дедуплицировать файлы"),
        "delete": MessageLookupByLibrary.simpleMessage("Удалить"),
        "deleteAccount":
            MessageLookupByLibrary.simpleMessage("Удалить аккаунт"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "Сожалеем, что вы уходите. Пожалуйста, поделитесь своим отзывом, чтобы помочь нам улучшиться."),
        "deleteAccountPermanentlyButton":
            MessageLookupByLibrary.simpleMessage("Удалить аккаунт навсегда"),
        "deleteAlbum": MessageLookupByLibrary.simpleMessage("Удалить альбом"),
        "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
            "Также удалить фотографии (и видео), которые есть в этом альбоме из <bold>всех</bold> других альбомов, где они есть?"),
        "deleteAlbumsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Это удалит все пустые альбомы. Это полезно, если вы хотите меньше беспорядка в списке альбомов."),
        "deleteAll": MessageLookupByLibrary.simpleMessage("Удалить всё"),
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
            "Эта учетная запись связана с другими приложениями Ente, если вы ими пользуетесь. Загруженные вами данные во всех приложениях Ente будут запланированы к удалению, а ваша учетная запись будет удалена без возможности восстановления."),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "Пожалуйста, отправьте письмо на <warning>account-deletion@ente.io</warning> с вашего зарегистрированного адреса электронной почты."),
        "deleteEmptyAlbums":
            MessageLookupByLibrary.simpleMessage("Удалить пустые альбомы"),
        "deleteEmptyAlbumsWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Удалить пустые альбомы?"),
        "deleteFromBoth":
            MessageLookupByLibrary.simpleMessage("Удалить отовсюду"),
        "deleteFromDevice":
            MessageLookupByLibrary.simpleMessage("Удалить с устройства"),
        "deleteFromEnte":
            MessageLookupByLibrary.simpleMessage("Удалить из Ente"),
        "deleteItemCount": m24,
        "deleteLocation":
            MessageLookupByLibrary.simpleMessage("Удалить местоположение"),
        "deletePhotos": MessageLookupByLibrary.simpleMessage("Удалить фото"),
        "deleteProgress": m25,
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "У вас отсутствует важная функция, которая мне нужна"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "Приложение или его некоторые функции не ведут себя так, как я думаю"),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
            "Я нашел другой сервис, который мне нравится больше"),
        "deleteReason4": MessageLookupByLibrary.simpleMessage(
            "Моя причина не указана в списке"),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
            "Ваш запрос будет обработан в течение 72 часов."),
        "deleteSharedAlbum":
            MessageLookupByLibrary.simpleMessage("Удалить общий альбом?"),
        "deleteSharedAlbumDialogBody": MessageLookupByLibrary.simpleMessage(
            "Альбом будет удален для всех\n\nВы потеряете доступ к общим фотографиям других людей в этом альбоме"),
        "deselectAll": MessageLookupByLibrary.simpleMessage("Снять выделение"),
        "designedToOutlive":
            MessageLookupByLibrary.simpleMessage("Создан для вечной жизни"),
        "details": MessageLookupByLibrary.simpleMessage("Подробности"),
        "developerSettings":
            MessageLookupByLibrary.simpleMessage("Настройки для разработчиков"),
        "developerSettingsWarning": MessageLookupByLibrary.simpleMessage(
            "Вы уверены, что хотите изменить настройки для разработчиков?"),
        "deviceCodeHint": MessageLookupByLibrary.simpleMessage("Введите код"),
        "deviceFilesAutoUploading": MessageLookupByLibrary.simpleMessage(
            "Файлы, добавленные в этот альбом на устройстве, будут автоматически загружены в Ente."),
        "deviceLock":
            MessageLookupByLibrary.simpleMessage("Блокировка устройства"),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
            "Отключить блокировку экрана, когда Ente находится на переднем плане и выполняется резервное копирование. Обычно это не нужно, но это может ускорить загрузку и первоначальный импорт больших библиотек."),
        "deviceNotFound":
            MessageLookupByLibrary.simpleMessage("Устройство не найдено"),
        "didYouKnow": MessageLookupByLibrary.simpleMessage("А вы знали?"),
        "disableAutoLock":
            MessageLookupByLibrary.simpleMessage("Отключить автоблокировку"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Наблюдатели все еще могут делать скриншоты или копировать ваши фотографии с помощью других инструментов"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Обратите внимание"),
        "disableLinkMessage": m26,
        "disableTwofactor": MessageLookupByLibrary.simpleMessage(
            "Отключить двухфакторную аутентификацию"),
        "disablingTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Отключение двухфакторной аутентификации..."),
        "discord": MessageLookupByLibrary.simpleMessage("Discord"),
        "discover_babies": MessageLookupByLibrary.simpleMessage("Дети"),
        "discover_celebrations":
            MessageLookupByLibrary.simpleMessage("Поздравления"),
        "discover_food": MessageLookupByLibrary.simpleMessage("Еда"),
        "discover_greenery": MessageLookupByLibrary.simpleMessage("Зелень"),
        "discover_hills": MessageLookupByLibrary.simpleMessage("Горы"),
        "discover_memes": MessageLookupByLibrary.simpleMessage("Мемы"),
        "discover_notes": MessageLookupByLibrary.simpleMessage("Заметки"),
        "discover_pets": MessageLookupByLibrary.simpleMessage("Питомцы"),
        "discover_selfies": MessageLookupByLibrary.simpleMessage("Селфи"),
        "discover_sunset": MessageLookupByLibrary.simpleMessage("Закат"),
        "discover_wallpapers": MessageLookupByLibrary.simpleMessage("Обои"),
        "dismiss": MessageLookupByLibrary.simpleMessage("Отменить"),
        "distanceInKMUnit": MessageLookupByLibrary.simpleMessage("км"),
        "doNotSignOut": MessageLookupByLibrary.simpleMessage("Не выходить"),
        "doThisLater": MessageLookupByLibrary.simpleMessage("Сделать позже"),
        "doYouWantToDiscardTheEditsYouHaveMade":
            MessageLookupByLibrary.simpleMessage(
                "Вы хотите отменить сделанные изменения?"),
        "done": MessageLookupByLibrary.simpleMessage("Готово"),
        "doubleYourStorage":
            MessageLookupByLibrary.simpleMessage("Удвой своё хранилище"),
        "download": MessageLookupByLibrary.simpleMessage("Скачать"),
        "downloadFailed":
            MessageLookupByLibrary.simpleMessage("Загрузка не удалась"),
        "downloading": MessageLookupByLibrary.simpleMessage("Скачивание..."),
        "dropSupportEmail": m27,
        "duplicateFileCountWithStorageSaved": m28,
        "duplicateItemsGroup": m29,
        "edit": MessageLookupByLibrary.simpleMessage("Редактировать"),
        "editLocation":
            MessageLookupByLibrary.simpleMessage("Изменить местоположение"),
        "editLocationTagTitle":
            MessageLookupByLibrary.simpleMessage("Изменить местоположение"),
        "editPerson":
            MessageLookupByLibrary.simpleMessage("Отредактировать человека"),
        "editsSaved":
            MessageLookupByLibrary.simpleMessage("Изменения сохранены"),
        "editsToLocationWillOnlyBeSeenWithinEnte":
            MessageLookupByLibrary.simpleMessage(
                "Редактирования в местоположении будут видны только внутри Ente"),
        "eligible": MessageLookupByLibrary.simpleMessage("подходящий"),
        "email": MessageLookupByLibrary.simpleMessage("Электронная почта"),
        "emailChangedTo": m30,
        "emailNoEnteAccount": m31,
        "emailVerificationToggle":
            MessageLookupByLibrary.simpleMessage("Вход с кодом на почту"),
        "emailYourLogs": MessageLookupByLibrary.simpleMessage(
            "Отправить логи по электронной почте"),
        "emergencyContacts":
            MessageLookupByLibrary.simpleMessage("Экстренные контакты"),
        "empty": MessageLookupByLibrary.simpleMessage("Очистить"),
        "emptyTrash": MessageLookupByLibrary.simpleMessage("Очистить корзину?"),
        "enable": MessageLookupByLibrary.simpleMessage("Включить"),
        "enableMLIndexingDesc": MessageLookupByLibrary.simpleMessage(
            "Ente поддерживает машинное обучение на устройстве для распознавания лиц, умного поиска и других расширенных функций поиска"),
        "enableMachineLearningBanner": MessageLookupByLibrary.simpleMessage(
            "Включить автоматическое обучение для Магического Поиска и распознавания лица"),
        "enableMaps": MessageLookupByLibrary.simpleMessage("Включить карты"),
        "enableMapsDesc": MessageLookupByLibrary.simpleMessage(
            "Ваши фотографии будут показаны на карте мира.\n\nЭта карта размещена на Open Street Map, и точное местоположение ваших фотографий никогда не разглашается.\n\nВы можете отключить эту функцию в любое время в настройках."),
        "enabled": MessageLookupByLibrary.simpleMessage("Включено"),
        "encryptingBackup": MessageLookupByLibrary.simpleMessage(
            "Шифрование резервной копии..."),
        "encryption": MessageLookupByLibrary.simpleMessage("Шифрование"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Ключи шифрования"),
        "endpointUpdatedMessage": MessageLookupByLibrary.simpleMessage(
            "Конечная точка успешно обновлена"),
        "endtoendEncryptedByDefault": MessageLookupByLibrary.simpleMessage(
            "Сквозное шифрование по умолчанию"),
        "enteCanEncryptAndPreserveFilesOnlyIfYouGrant":
            MessageLookupByLibrary.simpleMessage(
                "Ente может шифровать и сохранять файлы только в том случае, если вы предоставите к ним доступ"),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
            "Ente <i>требуется разрешение для</i> сохранения ваших фотографий"),
        "enteSubscriptionPitch": MessageLookupByLibrary.simpleMessage(
            "Ente сохраняет ваши воспоминания, так что они всегда доступны для вас, даже если вы потеряете доступ к устройству."),
        "enteSubscriptionShareWithFamily": MessageLookupByLibrary.simpleMessage(
            "Ваша семья может быть добавлена в ваш план."),
        "enterAlbumName":
            MessageLookupByLibrary.simpleMessage("Введите имя альбома"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Введите код"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
            "Введите код, предоставленный вашим другом что бы получить бесплатное хранилище для вас обоих"),
        "enterDateOfBirth": MessageLookupByLibrary.simpleMessage(
            "Дата рождения (необязательно)"),
        "enterEmail":
            MessageLookupByLibrary.simpleMessage("Введите адрес эл. почты"),
        "enterFileName":
            MessageLookupByLibrary.simpleMessage("Введите имя файла"),
        "enterName": MessageLookupByLibrary.simpleMessage("Введите имя"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Введите новый пароль, который мы можем использовать для шифрования ваших данных"),
        "enterPassword": MessageLookupByLibrary.simpleMessage("Введите пароль"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Введите пароль, который мы можем использовать для шифрования ваших данных"),
        "enterPersonName": MessageLookupByLibrary.simpleMessage("Введите имя"),
        "enterPin": MessageLookupByLibrary.simpleMessage("Введите PIN"),
        "enterReferralCode":
            MessageLookupByLibrary.simpleMessage("Введите реферальный код"),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Введите 6-значный код из вашего приложения для аутентификации"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "Пожалуйста, введите действительный адрес электронной почты."),
        "enterYourEmailAddress": MessageLookupByLibrary.simpleMessage(
            "Введите свою электронную почту"),
        "enterYourPassword":
            MessageLookupByLibrary.simpleMessage("Введите пароль"),
        "enterYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Введите свой ключ восстановления"),
        "error": MessageLookupByLibrary.simpleMessage("Ошибка"),
        "everywhere": MessageLookupByLibrary.simpleMessage("везде"),
        "exif": MessageLookupByLibrary.simpleMessage("EXIF"),
        "existingUser":
            MessageLookupByLibrary.simpleMessage("Существующий пользователь"),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
            "Срок действия этой ссылки истек. Пожалуйста, выберите новое время действия или отключите истечение срока действия ссылки."),
        "exportLogs": MessageLookupByLibrary.simpleMessage("Экспорт логов"),
        "exportYourData":
            MessageLookupByLibrary.simpleMessage("Экспорт данных"),
        "extraPhotosFound": MessageLookupByLibrary.simpleMessage(
            "Найдены дополнительные фотографии"),
        "extraPhotosFoundFor": m32,
        "faceNotClusteredYet": MessageLookupByLibrary.simpleMessage(
            "Лицо еще не кластеризовано, пожалуйста, вернитесь позже"),
        "faceRecognition":
            MessageLookupByLibrary.simpleMessage("Распознавание лиц"),
        "faces": MessageLookupByLibrary.simpleMessage("Лица"),
        "failedToApplyCode":
            MessageLookupByLibrary.simpleMessage("Не удалось применить код"),
        "failedToCancel":
            MessageLookupByLibrary.simpleMessage("Не удалось отменить"),
        "failedToDownloadVideo":
            MessageLookupByLibrary.simpleMessage("Не удалось скачать видео"),
        "failedToFetchActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Не удалось получить активные сеансы"),
        "failedToFetchOriginalForEdit": MessageLookupByLibrary.simpleMessage(
            "Не удалось получить оригинал для редактирования"),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "Не удалось получить информацию о реферале. Пожалуйста, повторите попытку позже."),
        "failedToLoadAlbums": MessageLookupByLibrary.simpleMessage(
            "Не удалось загрузить альбомы"),
        "failedToPlayVideo": MessageLookupByLibrary.simpleMessage(
            "Не удалось воспроизвести видео"),
        "failedToRefreshStripeSubscription":
            MessageLookupByLibrary.simpleMessage(
                "Не удалось обновить подписку"),
        "failedToRenew":
            MessageLookupByLibrary.simpleMessage("Не удалось продлить"),
        "failedToVerifyPaymentStatus": MessageLookupByLibrary.simpleMessage(
            "Не удалось подтвердить статус платежа"),
        "familyPlanOverview": MessageLookupByLibrary.simpleMessage(
            "Добавьте 5 членов семьи к существующему плану без дополнительной оплаты.\n\nКаждый участник получает свое личное пространство и не может видеть файлы друг друга, если к ним не предоставлен общий доступ.\n\nСемейные планы доступны клиентам, имеющим платную подписку на Ente.\n\nПодпишитесь сейчас, чтобы начать!"),
        "familyPlanPortalTitle": MessageLookupByLibrary.simpleMessage("Семья"),
        "familyPlans": MessageLookupByLibrary.simpleMessage("Семейные планы"),
        "faq": MessageLookupByLibrary.simpleMessage("Ответы на ваши вопросы"),
        "faqs":
            MessageLookupByLibrary.simpleMessage("Часто задаваемые вопросы"),
        "favorite": MessageLookupByLibrary.simpleMessage("В избранное"),
        "feedback": MessageLookupByLibrary.simpleMessage("Обратная связь"),
        "file": MessageLookupByLibrary.simpleMessage("Файл"),
        "fileFailedToSaveToGallery": MessageLookupByLibrary.simpleMessage(
            "Не удалось сохранить файл в галерею"),
        "fileInfoAddDescHint":
            MessageLookupByLibrary.simpleMessage("Добавить описание..."),
        "fileNotUploadedYet":
            MessageLookupByLibrary.simpleMessage("Файл ещё не загружен"),
        "fileSavedToGallery":
            MessageLookupByLibrary.simpleMessage("Файл сохранён в галерею"),
        "fileTypes": MessageLookupByLibrary.simpleMessage("Типы файлов"),
        "fileTypesAndNames":
            MessageLookupByLibrary.simpleMessage("Типы файлов и имена"),
        "filesBackedUpFromDevice": m33,
        "filesBackedUpInAlbum": m34,
        "filesDeleted": MessageLookupByLibrary.simpleMessage("Файлы удалены"),
        "filesSavedToGallery":
            MessageLookupByLibrary.simpleMessage("Файлы сохранены в галерею"),
        "findPeopleByName": MessageLookupByLibrary.simpleMessage(
            "Быстрый поиск людей по имени"),
        "flip": MessageLookupByLibrary.simpleMessage("Перевернуть"),
        "forYourMemories":
            MessageLookupByLibrary.simpleMessage("для Ваших воспоминаний"),
        "forgotPassword": MessageLookupByLibrary.simpleMessage("Забыл пароль"),
        "foundFaces": MessageLookupByLibrary.simpleMessage("Найденные лица"),
        "freeStorageClaimed": MessageLookupByLibrary.simpleMessage(
            "Бесплатного хранилища получено"),
        "freeStorageOnReferralSuccess": m35,
        "freeStorageUsable": MessageLookupByLibrary.simpleMessage(
            "Бесплатного хранилища можно использовать"),
        "freeTrial":
            MessageLookupByLibrary.simpleMessage("Бесплатный пробный период"),
        "freeTrialValidTill": m36,
        "freeUpAccessPostDelete": m37,
        "freeUpAmount": m38,
        "freeUpDeviceSpace": MessageLookupByLibrary.simpleMessage(
            "Освободите место на устройстве"),
        "freeUpDeviceSpaceDesc": MessageLookupByLibrary.simpleMessage(
            "Сохраните место на вашем устройстве, очистив уже сохраненные файлы."),
        "freeUpSpace": MessageLookupByLibrary.simpleMessage("Освободить место"),
        "freeUpSpaceSaving": m39,
        "galleryMemoryLimitInfo": MessageLookupByLibrary.simpleMessage(
            "До 1000 воспоминаний, отображаемых в галерее"),
        "general": MessageLookupByLibrary.simpleMessage("Общее"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Генерируем ключи шифрования..."),
        "genericProgress": m40,
        "goToSettings":
            MessageLookupByLibrary.simpleMessage("Перейти в настройки"),
        "googlePlayId": MessageLookupByLibrary.simpleMessage("Google Play ID"),
        "grantFullAccessPrompt": MessageLookupByLibrary.simpleMessage(
            "Пожалуйста, разрешите доступ к вашим фотографиям в Настройках приложения"),
        "grantPermission":
            MessageLookupByLibrary.simpleMessage("Предоставить разрешение"),
        "groupNearbyPhotos": MessageLookupByLibrary.simpleMessage(
            "Группировать фотографии рядом"),
        "guestView": MessageLookupByLibrary.simpleMessage("Гостевой вид"),
        "guestViewEnablePreSteps": MessageLookupByLibrary.simpleMessage(
            "Чтобы включить гостевой вид, настройте пароль устройства или блокировку экрана в настройках системы."),
        "hearUsExplanation": MessageLookupByLibrary.simpleMessage(
            "Будет полезно, если вы укажете, где нашли нас, так как мы не отслеживаем установки приложения!"),
        "hearUsWhereTitle": MessageLookupByLibrary.simpleMessage(
            "Как вы узнали о Ente? (необязательно)"),
        "help": MessageLookupByLibrary.simpleMessage("Помощь"),
        "hidden": MessageLookupByLibrary.simpleMessage("Скрыто"),
        "hide": MessageLookupByLibrary.simpleMessage("Скрыть"),
        "hideContent":
            MessageLookupByLibrary.simpleMessage("Скрыть содержимое"),
        "hideContentDescriptionAndroid": MessageLookupByLibrary.simpleMessage(
            "Скрывает содержимое приложения в переключателе приложений и отключает скриншоты"),
        "hideContentDescriptionIos": MessageLookupByLibrary.simpleMessage(
            "Скрывает содержимое приложения в переключателе приложений"),
        "hiding": MessageLookupByLibrary.simpleMessage("Скрытие..."),
        "hostedAtOsmFrance":
            MessageLookupByLibrary.simpleMessage("Размещено на OSM France"),
        "howItWorks": MessageLookupByLibrary.simpleMessage("Как это работает"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "Пожалуйста, попросите их задержать палец на адресе электронной почты на экране настроек и убедитесь, что идентификаторы на обоих устройствах совпадают."),
        "iOSGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "Биометрическая аутентификация не настроена на вашем устройстве. Пожалуйста, включите Touch ID или Face ID на вашем телефоне."),
        "iOSLockOut": MessageLookupByLibrary.simpleMessage(
            "Биометрическая аутентификация отключена. Пожалуйста, заблокируйте и разблокируйте экран, чтобы включить ее."),
        "iOSOkButton": MessageLookupByLibrary.simpleMessage("ОК"),
        "ignoreUpdate":
            MessageLookupByLibrary.simpleMessage("Ничего не делать"),
        "ignored": MessageLookupByLibrary.simpleMessage("игнорировать"),
        "ignoredFolderUploadReason": MessageLookupByLibrary.simpleMessage(
            "Некоторые файлы в этом альбоме пропущены, потому что они ранее были удалены из Ente."),
        "imageNotAnalyzed": MessageLookupByLibrary.simpleMessage(
            "Изображение не анализировано"),
        "immediately": MessageLookupByLibrary.simpleMessage("Немедленно"),
        "importing": MessageLookupByLibrary.simpleMessage("Импорт...."),
        "incorrectCode": MessageLookupByLibrary.simpleMessage("Неверный код"),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Неверный пароль"),
        "incorrectRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Неправильный ключ восстановления"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "Введенный вами ключ восстановления неверен"),
        "incorrectRecoveryKeyTitle": MessageLookupByLibrary.simpleMessage(
            "Неправильный ключ восстановления"),
        "indexedItems":
            MessageLookupByLibrary.simpleMessage("Индексированные элементы"),
        "indexingIsPaused": MessageLookupByLibrary.simpleMessage(
            "Индексация приостановлена. Она автоматически возобновится, когда устройство будет готово."),
        "info": MessageLookupByLibrary.simpleMessage("Информация"),
        "insecureDevice":
            MessageLookupByLibrary.simpleMessage("Небезопасное устройство"),
        "installManually":
            MessageLookupByLibrary.simpleMessage("Установка вручную"),
        "invalidEmailAddress": MessageLookupByLibrary.simpleMessage(
            "Неверный адрес электронной почты"),
        "invalidEndpoint":
            MessageLookupByLibrary.simpleMessage("Неверная конечная точка"),
        "invalidEndpointMessage": MessageLookupByLibrary.simpleMessage(
            "Извините, введенная вами конечная точка неверна. Пожалуйста, введите корректную конечную точку и повторите попытку."),
        "invalidKey": MessageLookupByLibrary.simpleMessage("Неверный ключ"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Введенный ключ восстановления недействителен. Убедитесь, что он содержит 24 слова и проверьте написание каждого из них.\n\nЕсли вы ввели старый код восстановления, убедитесь, что он содержит 64 символа и проверьте каждый из них."),
        "invite": MessageLookupByLibrary.simpleMessage("Пригласить"),
        "inviteToEnte":
            MessageLookupByLibrary.simpleMessage("Пригласить в Ente"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Пригласить своих друзей"),
        "inviteYourFriendsToEnte": MessageLookupByLibrary.simpleMessage(
            "Пригласите своих друзей в Ente"),
        "itLooksLikeSomethingWentWrongPleaseRetryAfterSome":
            MessageLookupByLibrary.simpleMessage(
                "Похоже, что-то пошло не так. Пожалуйста, повторите попытку через некоторое время. Если ошибка повторится, обратитесь в нашу службу поддержки."),
        "itemCount": m41,
        "itemsShowTheNumberOfDaysRemainingBeforePermanentDeletion":
            MessageLookupByLibrary.simpleMessage(
                "Элементы показывают количество дней, оставшихся до окончательного удаления"),
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "Выбранные элементы будут удалены из этого альбома"),
        "joinDiscord":
            MessageLookupByLibrary.simpleMessage("Присоединиться в Discord"),
        "keepPhotos": MessageLookupByLibrary.simpleMessage("Оставить фото"),
        "kiloMeterUnit": MessageLookupByLibrary.simpleMessage("км"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Пожалуйста, помогите нам с этой информацией"),
        "language": MessageLookupByLibrary.simpleMessage("Язык"),
        "lastUpdated":
            MessageLookupByLibrary.simpleMessage("Последнее обновление"),
        "leave": MessageLookupByLibrary.simpleMessage("Выйти"),
        "leaveAlbum": MessageLookupByLibrary.simpleMessage("Покинуть альбом"),
        "leaveFamily": MessageLookupByLibrary.simpleMessage("Покинуть семью"),
        "leaveSharedAlbum":
            MessageLookupByLibrary.simpleMessage("Покинуть общий альбом?"),
        "left": MessageLookupByLibrary.simpleMessage("Влево"),
        "legacyPageDesc2": MessageLookupByLibrary.simpleMessage(
            "Доверенные контакты могут инициировать восстановление учетной записи, если они не будут заблокированы в течение 30 дней, сбросить пароль и получить доступ к вашей учетной записи."),
        "light": MessageLookupByLibrary.simpleMessage("Светлая тема"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("Светлая тема"),
        "linkCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Ссылка скопирована в буфер обмена"),
        "linkDeviceLimit":
            MessageLookupByLibrary.simpleMessage("Лимит устройств"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Разрешён"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Истекшая"),
        "linkExpiresOn": m43,
        "linkExpiry":
            MessageLookupByLibrary.simpleMessage("Срок действия ссылки истек"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("Ссылка устарела"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Никогда"),
        "livePhotos": MessageLookupByLibrary.simpleMessage("Живые Фото"),
        "loadMessage1": MessageLookupByLibrary.simpleMessage(
            "Вы можете поделиться своей подпиской со своей семьей"),
        "loadMessage2": MessageLookupByLibrary.simpleMessage(
            "На данный момент мы сохранили более 30 миллионов воспоминаний"),
        "loadMessage3": MessageLookupByLibrary.simpleMessage(
            "Мы храним 3 копии ваших данных, одну из них в подземном бункере"),
        "loadMessage4": MessageLookupByLibrary.simpleMessage(
            "Все наши приложения с открытым исходным кодом"),
        "loadMessage5": MessageLookupByLibrary.simpleMessage(
            "Наш исходный код и шифрование прошли проверку обществом"),
        "loadMessage6": MessageLookupByLibrary.simpleMessage(
            "Вы можете делиться ссылками на ваши альбомы со своими близкими"),
        "loadMessage7": MessageLookupByLibrary.simpleMessage(
            "Наши мобильные приложения работают в фоновом режиме для шифрования и резервного копирования новых фотографий, которые вы выберите"),
        "loadMessage8": MessageLookupByLibrary.simpleMessage(
            "В web.ente.io есть удобный загрузчик"),
        "loadMessage9": MessageLookupByLibrary.simpleMessage(
            "Мы используем Xchacha20Poly1305 для шифрования ваших данных"),
        "loadingExifData":
            MessageLookupByLibrary.simpleMessage("Загрузка EXIF данных..."),
        "loadingGallery":
            MessageLookupByLibrary.simpleMessage("Загрузка галереи..."),
        "loadingMessage":
            MessageLookupByLibrary.simpleMessage("Загрузка фотографий..."),
        "loadingModel":
            MessageLookupByLibrary.simpleMessage("Загрузка моделей..."),
        "loadingYourPhotos":
            MessageLookupByLibrary.simpleMessage("Загрузка фотографий..."),
        "localGallery":
            MessageLookupByLibrary.simpleMessage("Локальная галерея"),
        "localIndexing":
            MessageLookupByLibrary.simpleMessage("Локальное индексирование"),
        "localSyncErrorMessage": MessageLookupByLibrary.simpleMessage(
            "Похоже, что-то пошло не так, так как локальная синхронизация фото занимает больше времени, чем ожидалось. Пожалуйста, свяжитесь с нашей службой поддержки"),
        "location": MessageLookupByLibrary.simpleMessage("Местоположение"),
        "locationName":
            MessageLookupByLibrary.simpleMessage("Название локации"),
        "locationTagFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "Тег местоположения группирует все фотографии, сделанные в определенном радиусе от фотографии"),
        "locations": MessageLookupByLibrary.simpleMessage("Локации"),
        "lockButtonLabel":
            MessageLookupByLibrary.simpleMessage("Заблокировать"),
        "lockscreen": MessageLookupByLibrary.simpleMessage("Экран блокировки"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Войти"),
        "loggingOut": MessageLookupByLibrary.simpleMessage("Выход..."),
        "loginSessionExpired":
            MessageLookupByLibrary.simpleMessage("Сессия недействительная"),
        "loginSessionExpiredDetails": MessageLookupByLibrary.simpleMessage(
            "Сессия истекла. Зайдите снова."),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "Нажимая Войти, я принимаю <u-terms>условия использования</u-terms> и <u-policy>политику конфиденциальности</u-policy>"),
        "logout": MessageLookupByLibrary.simpleMessage("Выйти"),
        "logsDialogBody": MessageLookupByLibrary.simpleMessage(
            "Журналы будут отправлены, что поможет нам устранить вашу проблему. Обратите внимание, что имена файлов будут включены, чтобы помочь отслеживать проблемы с конкретными файлами."),
        "longPressAnEmailToVerifyEndToEndEncryption":
            MessageLookupByLibrary.simpleMessage(
                "Длительное нажатие на email для подтверждения сквозного шифрования."),
        "longpressOnAnItemToViewInFullscreen": MessageLookupByLibrary.simpleMessage(
            "Удерживайте нажатие на элемент для просмотра в полноэкранном режиме"),
        "loopVideoOff":
            MessageLookupByLibrary.simpleMessage("Цикл видео выключен"),
        "loopVideoOn":
            MessageLookupByLibrary.simpleMessage("Цикл видео включен"),
        "lostDevice":
            MessageLookupByLibrary.simpleMessage("Потеряли свое устройство?"),
        "machineLearning":
            MessageLookupByLibrary.simpleMessage("Machine learning"),
        "magicSearch": MessageLookupByLibrary.simpleMessage("Волшебный поиск"),
        "magicSearchHint": MessageLookupByLibrary.simpleMessage(
            "Умный поиск позволяет искать фотографии по их содержимому, например, \'цветок\', \'красная машина\', \'паспорт\', \'документы\'"),
        "manage": MessageLookupByLibrary.simpleMessage("Управление"),
        "manageFamily":
            MessageLookupByLibrary.simpleMessage("Управление семьёй"),
        "manageLink": MessageLookupByLibrary.simpleMessage("Управлять ссылкой"),
        "manageParticipants":
            MessageLookupByLibrary.simpleMessage("Управление"),
        "manageSubscription":
            MessageLookupByLibrary.simpleMessage("Управление подпиской"),
        "manualPairDesc": MessageLookupByLibrary.simpleMessage(
            "Пара с PIN-кодом работает с любым экраном, на котором вы хотите посмотреть ваш альбом."),
        "map": MessageLookupByLibrary.simpleMessage("Карта"),
        "maps": MessageLookupByLibrary.simpleMessage("Карты"),
        "mastodon": MessageLookupByLibrary.simpleMessage("Mastodon"),
        "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
        "memoryCount": m3,
        "merchandise": MessageLookupByLibrary.simpleMessage("Товары"),
        "mergeWithExisting":
            MessageLookupByLibrary.simpleMessage("Объединить с существующим"),
        "mergedPhotos":
            MessageLookupByLibrary.simpleMessage("Объединенные фото"),
        "mlConsent":
            MessageLookupByLibrary.simpleMessage("Включить машинное обучение"),
        "mlConsentConfirmation": MessageLookupByLibrary.simpleMessage(
            "Я понимаю и хочу включить машинное обучение"),
        "mlConsentDescription": MessageLookupByLibrary.simpleMessage(
            "Если вы включите машинное обучение, Ente будет извлекать информацию из файлов (например, геометрию лица), включая те, которыми с вами поделились.\n\nЭто будет происходить на вашем устройстве, и любая сгенерированная биометрическая информация будет зашифрована с использованием сквозного (End-to-End) шифрования между вашим устройством и сервером."),
        "mlConsentPrivacy": MessageLookupByLibrary.simpleMessage(
            "Пожалуйста, нажмите здесь, чтобы узнать больше об этой функции в нашей политике конфиденциальности"),
        "mlConsentTitle":
            MessageLookupByLibrary.simpleMessage("Включить машинное обучение?"),
        "mlIndexingDescription": MessageLookupByLibrary.simpleMessage(
            "Обратите внимание, что машинное обучение приведёт к повышенному потреблению трафика и батареи, пока все элементы не будут проиндексированы. Рекомендуем использовать ПК версию для более быстрого индексирования. Полученные результаты будут синхронизированы автоматически между устройствами."),
        "mobileWebDesktop":
            MessageLookupByLibrary.simpleMessage("Телефон, Web, ПК"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Средний"),
        "modifyYourQueryOrTrySearchingFor":
            MessageLookupByLibrary.simpleMessage(
                "Измените свой запрос или попробуйте поискать"),
        "moments": MessageLookupByLibrary.simpleMessage("Мгновения"),
        "month": MessageLookupByLibrary.simpleMessage("месяц"),
        "monthly": MessageLookupByLibrary.simpleMessage("Ежемесячно"),
        "moreDetails": MessageLookupByLibrary.simpleMessage("Подробнее"),
        "mostRecent": MessageLookupByLibrary.simpleMessage("Недавние"),
        "mostRelevant":
            MessageLookupByLibrary.simpleMessage("Сначала актуальные"),
        "moveItem": m44,
        "moveToAlbum":
            MessageLookupByLibrary.simpleMessage("Переместить в альбом"),
        "moveToHiddenAlbum": MessageLookupByLibrary.simpleMessage(
            "Переместить в скрытый альбом"),
        "movedSuccessfullyTo": m45,
        "movedToTrash":
            MessageLookupByLibrary.simpleMessage("Перемещено в корзину"),
        "movingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "Перемещение файлов в альбом..."),
        "name": MessageLookupByLibrary.simpleMessage("Имя"),
        "nameTheAlbum": MessageLookupByLibrary.simpleMessage("Назовите альбом"),
        "networkConnectionRefusedErr": MessageLookupByLibrary.simpleMessage(
            "Не удается подключиться к Ente, пожалуйста, повторите попытку через некоторое время. Если ошибка не устраняется, обратитесь в службу поддержки."),
        "networkHostLookUpErr": MessageLookupByLibrary.simpleMessage(
            "Не удается подключиться к Ente, пожалуйста, проверьте настройки своей сети и обратитесь в службу поддержки, если ошибка повторится."),
        "never": MessageLookupByLibrary.simpleMessage("Никогда"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Новый альбом"),
        "newLocation":
            MessageLookupByLibrary.simpleMessage("Новое местоположение"),
        "newPerson": MessageLookupByLibrary.simpleMessage("Новое лицо"),
        "newToEnte": MessageLookupByLibrary.simpleMessage("Впервые в Ente"),
        "newest": MessageLookupByLibrary.simpleMessage("Самые новые"),
        "next": MessageLookupByLibrary.simpleMessage("Далее"),
        "no": MessageLookupByLibrary.simpleMessage("Нет"),
        "noAlbumsSharedByYouYet":
            MessageLookupByLibrary.simpleMessage("У вас пока нет альбомов"),
        "noDeviceFound":
            MessageLookupByLibrary.simpleMessage("Устройства не обнаружены"),
        "noDeviceLimit":
            MessageLookupByLibrary.simpleMessage("Нет ограничений"),
        "noDeviceThatCanBeDeleted": MessageLookupByLibrary.simpleMessage(
            "У вас нет файлов на этом устройстве, которые могут быть удалены"),
        "noDuplicates":
            MessageLookupByLibrary.simpleMessage("✨ Дубликатов нет"),
        "noExifData": MessageLookupByLibrary.simpleMessage("Нет данных EXIF"),
        "noFacesFound": MessageLookupByLibrary.simpleMessage("Лица не найдены"),
        "noHiddenPhotosOrVideos":
            MessageLookupByLibrary.simpleMessage("Нет скрытых фото или видео"),
        "noImagesWithLocation": MessageLookupByLibrary.simpleMessage(
            "Нет изображений с местоположением"),
        "noInternetConnection":
            MessageLookupByLibrary.simpleMessage("Нет подключения к Интернету"),
        "noPhotosAreBeingBackedUpRightNow":
            MessageLookupByLibrary.simpleMessage(
                "На данный момент резервных копий нет"),
        "noPhotosFoundHere":
            MessageLookupByLibrary.simpleMessage("Здесь нет фотографий"),
        "noQuickLinksSelected":
            MessageLookupByLibrary.simpleMessage("Не выбрано быстрых ссылок"),
        "noRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Нет ключа восстановления?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "Из-за природы нашего сквозного протокола шифрования ваши данные не могут быть расшифрованы без вашего пароля или ключа восстановления"),
        "noResults": MessageLookupByLibrary.simpleMessage("Ничего не найденo"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("Ничего не найдено"),
        "noSuggestionsForPerson": m46,
        "noSystemLockFound": MessageLookupByLibrary.simpleMessage(
            "Системная блокировка не найдена"),
        "notPersonLabel": m47,
        "nothingSharedWithYouYet": MessageLookupByLibrary.simpleMessage(
            "Пока никто не поделился с вами"),
        "nothingToSeeHere":
            MessageLookupByLibrary.simpleMessage("Здесь нечего смотреть! 👀"),
        "notifications": MessageLookupByLibrary.simpleMessage("Уведомления"),
        "ok": MessageLookupByLibrary.simpleMessage("Хорошо"),
        "onDevice": MessageLookupByLibrary.simpleMessage("На устройстве"),
        "onEnte":
            MessageLookupByLibrary.simpleMessage("В <branding>ente</branding>"),
        "onlyThem": MessageLookupByLibrary.simpleMessage("Только их"),
        "oops": MessageLookupByLibrary.simpleMessage("Ой"),
        "oopsCouldNotSaveEdits": MessageLookupByLibrary.simpleMessage(
            "К сожалению, изменения не сохранены"),
        "oopsSomethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Ой! Что-то пошло не так"),
        "openAlbumInBrowser":
            MessageLookupByLibrary.simpleMessage("Открыть альбом в браузере"),
        "openAlbumInBrowserTitle": MessageLookupByLibrary.simpleMessage(
            "Пожалуйста, используйте веб-приложение, чтобы добавить фотографии в этот альбом"),
        "openFile": MessageLookupByLibrary.simpleMessage("Открыть файл"),
        "openSettings":
            MessageLookupByLibrary.simpleMessage("Открыть настройки"),
        "openTheItem":
            MessageLookupByLibrary.simpleMessage("• Открыть элемент"),
        "openstreetmapContributors":
            MessageLookupByLibrary.simpleMessage("Авторы OpenStreetMap"),
        "optionalAsShortAsYouLike": MessageLookupByLibrary.simpleMessage(
            "Необязательно, как вам нравится..."),
        "orMergeWithExistingPerson": MessageLookupByLibrary.simpleMessage(
            "Или объединить с существующими"),
        "orPickAnExistingOne": MessageLookupByLibrary.simpleMessage(
            "Или выберите уже существующий"),
        "pair": MessageLookupByLibrary.simpleMessage("Спарить"),
        "pairWithPin": MessageLookupByLibrary.simpleMessage("Соединить с PIN"),
        "pairingComplete":
            MessageLookupByLibrary.simpleMessage("Сопряжение завершено"),
        "panorama": MessageLookupByLibrary.simpleMessage("Панорама"),
        "passKeyPendingVerification": MessageLookupByLibrary.simpleMessage(
            "Верификация еще не завершена"),
        "passkey": MessageLookupByLibrary.simpleMessage("Ключ"),
        "passkeyAuthTitle":
            MessageLookupByLibrary.simpleMessage("Проверка с помощью ключа"),
        "password": MessageLookupByLibrary.simpleMessage("Пароль"),
        "passwordChangedSuccessfully":
            MessageLookupByLibrary.simpleMessage("Пароль успешно изменён"),
        "passwordLock":
            MessageLookupByLibrary.simpleMessage("Блокировка паролем"),
        "passwordStrength": m0,
        "passwordStrengthInfo": MessageLookupByLibrary.simpleMessage(
            "Надежность пароля рассчитывается с учетом длины пароля, используемых символов, и появлением пароля в 10 000 наиболее используемых"),
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Мы не храним этот пароль, поэтому если вы забудете его, <underline>мы не сможем расшифровать ваши данные</underline>"),
        "paymentDetails":
            MessageLookupByLibrary.simpleMessage("Детали платежа"),
        "paymentFailed": MessageLookupByLibrary.simpleMessage("Сбой платежа"),
        "paymentFailedMessage": MessageLookupByLibrary.simpleMessage(
            "К сожалению, ваш платеж не был выполнен. Пожалуйста, свяжитесь со службой поддержки, и мы вам поможем!"),
        "paymentFailedTalkToProvider": m49,
        "pendingItems":
            MessageLookupByLibrary.simpleMessage("Отложенные элементы"),
        "pendingSync":
            MessageLookupByLibrary.simpleMessage("Ожидание синхронизации"),
        "people": MessageLookupByLibrary.simpleMessage("Люди"),
        "peopleUsingYourCode":
            MessageLookupByLibrary.simpleMessage("Люди использующие ваш код"),
        "permDeleteWarning": MessageLookupByLibrary.simpleMessage(
            "Все элементы в корзине будут удалены навсегда\n\nЭто действие не может быть отменено"),
        "permanentlyDelete":
            MessageLookupByLibrary.simpleMessage("Удалить безвозвратно"),
        "permanentlyDeleteFromDevice": MessageLookupByLibrary.simpleMessage(
            "Удалить с устройства навсегда?"),
        "personName": MessageLookupByLibrary.simpleMessage("Имя человека"),
        "photoDescriptions":
            MessageLookupByLibrary.simpleMessage("Описание фотографии"),
        "photoGridSize":
            MessageLookupByLibrary.simpleMessage("Размер сетки фотографий"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("фото"),
        "photos": MessageLookupByLibrary.simpleMessage("Фотографии"),
        "photosAddedByYouWillBeRemovedFromTheAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Добавленные вами фотографии будут удалены из альбома"),
        "photosCount": m50,
        "pickCenterPoint":
            MessageLookupByLibrary.simpleMessage("Указать центральную точку"),
        "pinAlbum": MessageLookupByLibrary.simpleMessage("Закрепить альбом"),
        "pinLock": MessageLookupByLibrary.simpleMessage("Блокировка PIN-кодом"),
        "playOnTv":
            MessageLookupByLibrary.simpleMessage("Воспроизвести альбом на ТВ"),
        "playStoreFreeTrialValidTill": m51,
        "playstoreSubscription":
            MessageLookupByLibrary.simpleMessage("Подписка на PlayStore"),
        "pleaseCheckYourInternetConnectionAndTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Проверьте подключение к Интернету и повторите попытку."),
        "pleaseContactSupportAndWeWillBeHappyToHelp":
            MessageLookupByLibrary.simpleMessage(
                "Пожалуйста, свяжитесь с support@ente.io и мы Вам поможем!"),
        "pleaseContactSupportIfTheProblemPersists":
            MessageLookupByLibrary.simpleMessage(
                "Если проблема не устранена, обратитесь в службу поддержки"),
        "pleaseEmailUsAt": m52,
        "pleaseGrantPermissions":
            MessageLookupByLibrary.simpleMessage("Предоставьте разрешение"),
        "pleaseLoginAgain":
            MessageLookupByLibrary.simpleMessage("Пожалуйста, войдите снова"),
        "pleaseSelectQuickLinksToRemove": MessageLookupByLibrary.simpleMessage(
            "Пожалуйста, выберите быстрые ссылки для удаления"),
        "pleaseSendTheLogsTo": m53,
        "pleaseTryAgain": MessageLookupByLibrary.simpleMessage(
            "Пожалуйста, попробуйте ещё раз"),
        "pleaseVerifyTheCodeYouHaveEntered":
            MessageLookupByLibrary.simpleMessage(
                "Пожалуйста, подтвердите введенный код"),
        "pleaseWait":
            MessageLookupByLibrary.simpleMessage("Пожалуйста, подождите..."),
        "pleaseWaitDeletingAlbum": MessageLookupByLibrary.simpleMessage(
            "Пожалуйста, подождите. Удаление альбома"),
        "pleaseWaitForSometimeBeforeRetrying":
            MessageLookupByLibrary.simpleMessage(
                "Пожалуйста, подождите немного перед повторной попыткой"),
        "preparingLogs":
            MessageLookupByLibrary.simpleMessage("Подготовка логов..."),
        "preserveMore":
            MessageLookupByLibrary.simpleMessage("Сохранить больше"),
        "pressAndHoldToPlayVideo": MessageLookupByLibrary.simpleMessage(
            "Нажмите и удерживайте для воспроизведения видео"),
        "pressAndHoldToPlayVideoDetailed": MessageLookupByLibrary.simpleMessage(
            "Нажмите и удерживайте изображение для воспроизведения видео"),
        "privacy": MessageLookupByLibrary.simpleMessage("Конфиденциальность"),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Политика конфиденциальности"),
        "privateBackups":
            MessageLookupByLibrary.simpleMessage("Приватные резервные копии"),
        "privateSharing": MessageLookupByLibrary.simpleMessage("Личный доступ"),
        "processingImport": m54,
        "publicLinkCreated":
            MessageLookupByLibrary.simpleMessage("Публичная ссылка создана"),
        "publicLinkEnabled":
            MessageLookupByLibrary.simpleMessage("Публичная ссылка включена"),
        "quickLinks": MessageLookupByLibrary.simpleMessage("Ссылки"),
        "radius": MessageLookupByLibrary.simpleMessage("Радиус"),
        "raiseTicket": MessageLookupByLibrary.simpleMessage("Подать заявку"),
        "rateTheApp":
            MessageLookupByLibrary.simpleMessage("Оценить приложение"),
        "rateUs": MessageLookupByLibrary.simpleMessage("Оцените нас"),
        "rateUsOnStore": m55,
        "recover": MessageLookupByLibrary.simpleMessage("Восстановить"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("Восстановить аккаунт"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Восстановить"),
        "recoveryInitiated":
            MessageLookupByLibrary.simpleMessage("Восстановление запущено"),
        "recoveryKey":
            MessageLookupByLibrary.simpleMessage("Ключ восстановления"),
        "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Ключ восстановления скопирован в буфер обмена"),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
            "Если вы забыли свой пароль, то восстановить данные можно только с помощью этого ключа."),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
            "Мы не храним этот ключ, пожалуйста, сохраните этот ключ в безопасном месте."),
        "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
            "Отлично! Ваш ключ восстановления действителен. Спасибо за проверку.\n\nПожалуйста, не забудьте сохранить ключ восстановления в безопасном месте."),
        "recoveryKeyVerified": MessageLookupByLibrary.simpleMessage(
            "Ключ восстановления подтвержден"),
        "recoverySuccessful": MessageLookupByLibrary.simpleMessage(
            "Восстановление прошло успешно!"),
        "recoveryWarning": MessageLookupByLibrary.simpleMessage(
            "Доверенный контакт пытается получить доступ к вашей учетной записи"),
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "Текущее устройство недостаточно мощно для верификации пароля, но мы можем восстановить так, как это работает со всеми устройствами.\n\nПожалуйста, войдите, используя ваш ключ восстановления и сгенерируйте ваш пароль (вы можете использовать тот же пароль, если пожелаете)."),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Сбросить пароль"),
        "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
        "reenterPassword":
            MessageLookupByLibrary.simpleMessage("Подтвердите пароль"),
        "reenterPin":
            MessageLookupByLibrary.simpleMessage("Введите PIN-код ещё раз"),
        "referFriendsAnd2xYourPlan": MessageLookupByLibrary.simpleMessage(
            "Пригласите друзей и удвойте свой план"),
        "referralStep1": MessageLookupByLibrary.simpleMessage(
            "1. Дайте этот код своим друзьям"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "2. Они подписываются на платный план"),
        "referralStep3": m59,
        "referrals": MessageLookupByLibrary.simpleMessage("Рефералы"),
        "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
            "Рефералы в настоящее время приостановлены"),
        "rejectRecovery":
            MessageLookupByLibrary.simpleMessage("Отклонить восстановление"),
        "remindToEmptyDeviceTrash": MessageLookupByLibrary.simpleMessage(
            "Также очистите \"Недавно удалённые\" из \"Настройки\" -> \"Хранилище\", чтобы получить больше свободного места"),
        "remindToEmptyEnteTrash": MessageLookupByLibrary.simpleMessage(
            "Также очистите корзину для освобождения места"),
        "remoteImages":
            MessageLookupByLibrary.simpleMessage("Удалённые изображения"),
        "remoteThumbnails":
            MessageLookupByLibrary.simpleMessage("Удалённые миниатюры"),
        "remoteVideos": MessageLookupByLibrary.simpleMessage("Удалённые видео"),
        "remove": MessageLookupByLibrary.simpleMessage("Убрать"),
        "removeDuplicates":
            MessageLookupByLibrary.simpleMessage("Удаление дубликатов"),
        "removeDuplicatesDesc": MessageLookupByLibrary.simpleMessage(
            "Просмотрите и удалите точные дубликаты."),
        "removeFromAlbum":
            MessageLookupByLibrary.simpleMessage("Удалить из альбома"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("Удалить из альбома?"),
        "removeFromFavorite":
            MessageLookupByLibrary.simpleMessage("Удалить из избранного"),
        "removeInvite":
            MessageLookupByLibrary.simpleMessage("Удалить приглашение"),
        "removeLink": MessageLookupByLibrary.simpleMessage("Удалить ссылку"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Исключить участника"),
        "removeParticipantBody": m60,
        "removePersonLabel":
            MessageLookupByLibrary.simpleMessage("Удалить метку человека"),
        "removePublicLink":
            MessageLookupByLibrary.simpleMessage("Удалить публичную ссылку"),
        "removePublicLinks":
            MessageLookupByLibrary.simpleMessage("Удалить публичные ссылки"),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
            "Некоторые элементы, которые вы удаляете, были добавлены другими людьми, и вы потеряете к ним доступ"),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Удалить?"),
        "removeYourselfAsTrustedContact": MessageLookupByLibrary.simpleMessage(
            "Удалить себя как доверенный контакт"),
        "removingFromFavorites":
            MessageLookupByLibrary.simpleMessage("Удаление из избранного..."),
        "rename": MessageLookupByLibrary.simpleMessage("Переименовать"),
        "renameAlbum":
            MessageLookupByLibrary.simpleMessage("Переименовать альбом"),
        "renameFile":
            MessageLookupByLibrary.simpleMessage("Переименовать файл"),
        "renewSubscription":
            MessageLookupByLibrary.simpleMessage("Продлить подписку"),
        "renewsOn": m61,
        "reportABug":
            MessageLookupByLibrary.simpleMessage("Сообщить об ошибке"),
        "reportBug": MessageLookupByLibrary.simpleMessage("Сообщить об ошибке"),
        "resendEmail":
            MessageLookupByLibrary.simpleMessage("Отправить письмо еще раз"),
        "resetIgnoredFiles":
            MessageLookupByLibrary.simpleMessage("Сбросить игнорируемые файлы"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Сбросить пароль"),
        "resetPerson": MessageLookupByLibrary.simpleMessage("Убрать"),
        "resetToDefault":
            MessageLookupByLibrary.simpleMessage("Сброс по умолчанию"),
        "restore": MessageLookupByLibrary.simpleMessage("Восстановить"),
        "restoreToAlbum":
            MessageLookupByLibrary.simpleMessage("Восстановить в альбоме"),
        "restoringFiles":
            MessageLookupByLibrary.simpleMessage("Восстановление файлов..."),
        "resumableUploads": MessageLookupByLibrary.simpleMessage(
            "Поддержка дозагрузки файл(а/ов) при разрыве связи"),
        "retry": MessageLookupByLibrary.simpleMessage("Повторить"),
        "review": MessageLookupByLibrary.simpleMessage("Отзыв"),
        "reviewDeduplicateItems": MessageLookupByLibrary.simpleMessage(
            "Пожалуйста, проверьте и удалите те элементы, которые вы считаете что это дубликаты."),
        "reviewSuggestions":
            MessageLookupByLibrary.simpleMessage("Посмотреть предложения"),
        "right": MessageLookupByLibrary.simpleMessage("Вправо"),
        "rotate": MessageLookupByLibrary.simpleMessage("Повернуть"),
        "rotateLeft": MessageLookupByLibrary.simpleMessage("Повернуть влево"),
        "rotateRight": MessageLookupByLibrary.simpleMessage("Повернуть вправо"),
        "safelyStored":
            MessageLookupByLibrary.simpleMessage("Безопасное хранение"),
        "save": MessageLookupByLibrary.simpleMessage("Сохранить"),
        "saveCollage": MessageLookupByLibrary.simpleMessage("Сохранить коллаж"),
        "saveCopy": MessageLookupByLibrary.simpleMessage("Сохранить копию"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Сохранить ключ"),
        "savePerson":
            MessageLookupByLibrary.simpleMessage("Сохранить человека"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Сохраните ваш ключ восстановления, если вы еще не сделали этого"),
        "saving": MessageLookupByLibrary.simpleMessage("Сохранение..."),
        "savingEdits":
            MessageLookupByLibrary.simpleMessage("Сохранение изменений..."),
        "scanCode": MessageLookupByLibrary.simpleMessage("Сканировать код"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Просканируйте этот Qr-код вашим приложением для аутентификации"),
        "search": MessageLookupByLibrary.simpleMessage("Поиск"),
        "searchAlbumsEmptySection":
            MessageLookupByLibrary.simpleMessage("Альбомы"),
        "searchByAlbumNameHint":
            MessageLookupByLibrary.simpleMessage("Название альбома"),
        "searchByExamples": MessageLookupByLibrary.simpleMessage(
            "• Названия альбомов («Камера», ...)\n• Типы файлов («Видео», «.gif», ...)\n• Годы и месяцы («2022», «Январь», ...)\n• Праздники («Рождество», ...)\n• Описания фотографий («#fun», ...)"),
        "searchCaptionEmptySection": MessageLookupByLibrary.simpleMessage(
            "Добавьте описания типа \"#поездка\" в информацию о фото и быстро найдите их здесь"),
        "searchDatesEmptySection": MessageLookupByLibrary.simpleMessage(
            "Поиск по дате, месяцу или году"),
        "searchFaceEmptySection": MessageLookupByLibrary.simpleMessage(
            "Люди будут показаны здесь, как только будет выполнено индексирование"),
        "searchFileTypesAndNamesEmptySection":
            MessageLookupByLibrary.simpleMessage("Типы файлов и имена"),
        "searchHint1":
            MessageLookupByLibrary.simpleMessage("Быстрый поиск на устройстве"),
        "searchHint2":
            MessageLookupByLibrary.simpleMessage("Даты, описания фото"),
        "searchHint3": MessageLookupByLibrary.simpleMessage(
            "Альбомы, названия и типы файлов"),
        "searchHint4": MessageLookupByLibrary.simpleMessage("Местоположение"),
        "searchHint5": MessageLookupByLibrary.simpleMessage(
            "Скоро: Лица & магический поиск ✨"),
        "searchLocationEmptySection": MessageLookupByLibrary.simpleMessage(
            "Групповые фотографии, сделанные в некотором радиусе от фотографии"),
        "searchPeopleEmptySection": MessageLookupByLibrary.simpleMessage(
            "Пригласите людей, и вы увидите все фотографии, которыми они поделились здесь"),
        "searchResultCount": m62,
        "security": MessageLookupByLibrary.simpleMessage("Безопасность"),
        "seePublicAlbumLinksInApp": MessageLookupByLibrary.simpleMessage(
            "Смотреть ссылки публичного альбома в приложении"),
        "selectALocation":
            MessageLookupByLibrary.simpleMessage("Выбрать место"),
        "selectALocationFirst":
            MessageLookupByLibrary.simpleMessage("Сначала выберите место"),
        "selectAlbum": MessageLookupByLibrary.simpleMessage("Выбрать альбом"),
        "selectAll": MessageLookupByLibrary.simpleMessage("Выбрать все"),
        "selectAllShort": MessageLookupByLibrary.simpleMessage("Все"),
        "selectCoverPhoto":
            MessageLookupByLibrary.simpleMessage("Выберите обложку"),
        "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
            "Выберите папки для резервного копирования"),
        "selectItemsToAdd": MessageLookupByLibrary.simpleMessage(
            "Выберите предметы для добавления"),
        "selectLanguage": MessageLookupByLibrary.simpleMessage("Выбрать язык"),
        "selectMailApp":
            MessageLookupByLibrary.simpleMessage("Выберите приложение почты"),
        "selectMorePhotos":
            MessageLookupByLibrary.simpleMessage("Выбрать больше фотографий"),
        "selectReason":
            MessageLookupByLibrary.simpleMessage("Выберите причину"),
        "selectYourPlan": MessageLookupByLibrary.simpleMessage("Выберете план"),
        "selectedFilesAreNotOnEnte":
            MessageLookupByLibrary.simpleMessage("Выбранные файлы не на Ente"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "Выбранные папки будут зашифрованы и сохранены в резервной копии"),
        "selectedItemsWillBeDeletedFromAllAlbumsAndMoved":
            MessageLookupByLibrary.simpleMessage(
                "Выбранные элементы будут удалены из всех альбомов и перемещены в корзину."),
        "selectedPhotos": m4,
        "selectedPhotosWithYours": m64,
        "send": MessageLookupByLibrary.simpleMessage("Отправить"),
        "sendEmail": MessageLookupByLibrary.simpleMessage(
            "Отправить электронное письмо"),
        "sendInvite":
            MessageLookupByLibrary.simpleMessage("Отправить приглашение"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Отправить ссылку"),
        "serverEndpoint":
            MessageLookupByLibrary.simpleMessage("Конечная точка сервера"),
        "sessionExpired":
            MessageLookupByLibrary.simpleMessage("Сессия недействительная"),
        "sessionIdMismatch":
            MessageLookupByLibrary.simpleMessage("Несоответствие ID сеанса"),
        "setAPassword":
            MessageLookupByLibrary.simpleMessage("Установить пароль"),
        "setAs": MessageLookupByLibrary.simpleMessage("Установить как"),
        "setCover": MessageLookupByLibrary.simpleMessage("Установить обложку"),
        "setLabel": MessageLookupByLibrary.simpleMessage("Установить"),
        "setNewPassword":
            MessageLookupByLibrary.simpleMessage("Задать новый пароль"),
        "setNewPin":
            MessageLookupByLibrary.simpleMessage("Установите новый PIN"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Установить пароль"),
        "setRadius": MessageLookupByLibrary.simpleMessage("Установить радиус"),
        "setupComplete":
            MessageLookupByLibrary.simpleMessage("Установка завершена"),
        "share": MessageLookupByLibrary.simpleMessage("Поделиться"),
        "shareALink":
            MessageLookupByLibrary.simpleMessage("Поделиться ссылкой"),
        "shareAlbumHint": MessageLookupByLibrary.simpleMessage(
            "Откройте альбом и нажмите кнопку \"Поделиться\" в правом верхнем углу экрана."),
        "shareAnAlbumNow":
            MessageLookupByLibrary.simpleMessage("Поделиться альбомом сейчас"),
        "shareLink": MessageLookupByLibrary.simpleMessage("Поделиться ссылкой"),
        "shareMyVerificationID": m65,
        "shareOnlyWithThePeopleYouWant": MessageLookupByLibrary.simpleMessage(
            "Поделитесь только с теми людьми, с которыми вы хотите"),
        "shareTextConfirmOthersVerificationID": m5,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Скачай Ente, чтобы мы могли легко поделиться фотографиями и видео без сжатия\n\nhttps://ente.io"),
        "shareTextReferralCode": m66,
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
            "Поделится с пользователями без Ente"),
        "shareWithPeopleSectionTitle": m67,
        "shareYourFirstAlbum":
            MessageLookupByLibrary.simpleMessage("Поделиться первым альбомом"),
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Создавайте общие и совместные альбомы с другими пользователями Ente, в том числе с пользователями бесплатных планов."),
        "sharedByMe": MessageLookupByLibrary.simpleMessage("Поделился мной"),
        "sharedByYou": MessageLookupByLibrary.simpleMessage("Поделились вами"),
        "sharedPhotoNotifications":
            MessageLookupByLibrary.simpleMessage("Новые общие фотографии"),
        "sharedPhotoNotificationsExplanation": MessageLookupByLibrary.simpleMessage(
            "Получать уведомления, когда кто-то добавляет фото в общий альбом, в котором вы состоите"),
        "sharedWith": m68,
        "sharedWithMe":
            MessageLookupByLibrary.simpleMessage("Поделиться со мной"),
        "sharedWithYou":
            MessageLookupByLibrary.simpleMessage("Поделились с вами"),
        "sharing": MessageLookupByLibrary.simpleMessage("Отправка..."),
        "showMemories":
            MessageLookupByLibrary.simpleMessage("Показать воспоминания"),
        "showPerson": MessageLookupByLibrary.simpleMessage("Показать человека"),
        "signOutFromOtherDevices":
            MessageLookupByLibrary.simpleMessage("Выйти из других устройств"),
        "signOutOtherBody": MessageLookupByLibrary.simpleMessage(
            "Если вы думаете, что кто-то может знать ваш пароль, вы можете принудительно выйти из всех устройств."),
        "signOutOtherDevices":
            MessageLookupByLibrary.simpleMessage("Выйти из других устройств"),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "Я согласен с <u-terms>условиями предоставления услуг</u-terms> и <u-policy>политикой конфиденциальности</u-policy>"),
        "singleFileDeleteFromDevice": m69,
        "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
            "Он будет удален из всех альбомов."),
        "singleFileInBothLocalAndRemote": m70,
        "singleFileInRemoteOnly": m71,
        "skip": MessageLookupByLibrary.simpleMessage("Пропустить"),
        "social": MessageLookupByLibrary.simpleMessage("Соцсети"),
        "someItemsAreInBothEnteAndYourDevice": MessageLookupByLibrary.simpleMessage(
            "Некоторые элементы находятся как на Ente, так и в вашем устройстве."),
        "someOfTheFilesYouAreTryingToDeleteAre":
            MessageLookupByLibrary.simpleMessage(
                "Некоторые файлы, которые вы пытаетесь удалить, доступны только на вашем устройстве и не могут быть восстановлены при удалении"),
        "someoneSharingAlbumsWithYouShouldSeeTheSameId":
            MessageLookupByLibrary.simpleMessage(
                "Тот, кто делится альбомами с вами должны видеть такой же идентификатор на их устройстве."),
        "somethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Что-то пошло не так"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Что-то пошло не так. Попробуйте еще раз"),
        "sorry": MessageLookupByLibrary.simpleMessage("Извините"),
        "sorryCouldNotAddToFavorites": MessageLookupByLibrary.simpleMessage(
            "Извините, не удалось добавить в избранное!"),
        "sorryCouldNotRemoveFromFavorites":
            MessageLookupByLibrary.simpleMessage(
                "Извините, не удалось удалить из избранного!"),
        "sorryTheCodeYouveEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "Извините, введенный вами код неверный"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "К сожалению, мы не смогли сгенерировать безопасные ключи на этом устройстве.\n\nПожалуйста, зарегистрируйтесь с другого устройства."),
        "sort": MessageLookupByLibrary.simpleMessage("Сортировать"),
        "sortAlbumsBy": MessageLookupByLibrary.simpleMessage("Сортировать по"),
        "sortNewestFirst":
            MessageLookupByLibrary.simpleMessage("Сначала новые"),
        "sortOldestFirst":
            MessageLookupByLibrary.simpleMessage("Сначала старые"),
        "sparkleSuccess": MessageLookupByLibrary.simpleMessage("✨ Успешно"),
        "startBackup": MessageLookupByLibrary.simpleMessage(
            "Начать резервное копирование"),
        "status": MessageLookupByLibrary.simpleMessage("Статус"),
        "stopCastingBody": MessageLookupByLibrary.simpleMessage(
            "Желаете прекратить трансляцию?"),
        "stopCastingTitle":
            MessageLookupByLibrary.simpleMessage("Прекратить трансляцию"),
        "storage": MessageLookupByLibrary.simpleMessage("Хранилище"),
        "storageBreakupFamily": MessageLookupByLibrary.simpleMessage("Семья"),
        "storageBreakupYou": MessageLookupByLibrary.simpleMessage("Вы"),
        "storageInGB": m1,
        "storageLimitExceeded":
            MessageLookupByLibrary.simpleMessage("Превышен предел хранения"),
        "storageUsageInfo": m72,
        "strongStrength": MessageLookupByLibrary.simpleMessage("Сильный"),
        "subAlreadyLinkedErrMessage": m73,
        "subWillBeCancelledOn": m74,
        "subscribe": MessageLookupByLibrary.simpleMessage("Подписаться"),
        "subscription": MessageLookupByLibrary.simpleMessage("Подписка"),
        "success": MessageLookupByLibrary.simpleMessage("Успешно"),
        "successfullyArchived":
            MessageLookupByLibrary.simpleMessage("Успешно архивировано"),
        "successfullyHid":
            MessageLookupByLibrary.simpleMessage("Успешно скрыто"),
        "successfullyUnarchived":
            MessageLookupByLibrary.simpleMessage("Успешно разархивировано"),
        "successfullyUnhid":
            MessageLookupByLibrary.simpleMessage("Успешно показано"),
        "suggestFeatures":
            MessageLookupByLibrary.simpleMessage("Предложить идею"),
        "support": MessageLookupByLibrary.simpleMessage("Поддержка"),
        "syncProgress": m75,
        "syncStopped":
            MessageLookupByLibrary.simpleMessage("Синхронизация остановлена"),
        "syncing": MessageLookupByLibrary.simpleMessage("Синхронизация..."),
        "systemTheme": MessageLookupByLibrary.simpleMessage("Система"),
        "tapToCopy":
            MessageLookupByLibrary.simpleMessage("нажмите, чтобы скопировать"),
        "tapToEnterCode":
            MessageLookupByLibrary.simpleMessage("Нажмите, чтобы ввести код"),
        "tapToUnlock":
            MessageLookupByLibrary.simpleMessage("Нажмите для разблокировки"),
        "tempErrorContactSupportIfPersists": MessageLookupByLibrary.simpleMessage(
            "Похоже, что-то пошло не так. Пожалуйста, повторите попытку через некоторое время. Если ошибка повторится, обратитесь в нашу службу поддержки."),
        "terminate": MessageLookupByLibrary.simpleMessage("Завершить"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Завершить сеанс?"),
        "terms": MessageLookupByLibrary.simpleMessage("Условия использования"),
        "termsOfServicesTitle":
            MessageLookupByLibrary.simpleMessage("Условия использования"),
        "thankYou": MessageLookupByLibrary.simpleMessage("Спасибо"),
        "thankYouForSubscribing":
            MessageLookupByLibrary.simpleMessage("Спасибо за подписку!"),
        "theDownloadCouldNotBeCompleted": MessageLookupByLibrary.simpleMessage(
            "Загрузка не может быть завершена"),
        "theLinkYouAreTryingToAccessHasExpired":
            MessageLookupByLibrary.simpleMessage(
                "Ссылка, к которой вы пытаетесь получить доступ, устарела."),
        "theRecoveryKeyYouEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "Введен неправильный ключ восстановления"),
        "theme": MessageLookupByLibrary.simpleMessage("Тема"),
        "theseItemsWillBeDeletedFromYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Эти элементы будут удалено с вашего устройства."),
        "theyAlsoGetXGb": m77,
        "theyWillBeDeletedFromAllAlbums": MessageLookupByLibrary.simpleMessage(
            "Они будут удален из всех альбомов."),
        "thisActionCannotBeUndone": MessageLookupByLibrary.simpleMessage(
            "Это действие нельзя будет отменить"),
        "thisAlbumAlreadyHDACollaborativeLink":
            MessageLookupByLibrary.simpleMessage(
                "У этого альбома уже есть совместная ссылка"),
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "Это может быть использовано для восстановления вашей учетной записи, если вы потеряете свой аутентификатор"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Это устройство"),
        "thisEmailIsAlreadyInUse": MessageLookupByLibrary.simpleMessage(
            "Этот адрес электронной почты уже используется"),
        "thisImageHasNoExifData": MessageLookupByLibrary.simpleMessage(
            "Это изображение не имеет exif данных"),
        "thisIsPersonVerificationId": m78,
        "thisIsYourVerificationId": MessageLookupByLibrary.simpleMessage(
            "Это ваш идентификатор подтверждения"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Вы выйдете из списка следующих устройств:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Совершив это действие, Вы выйдете из своей учетной записи!"),
        "thisWillRemovePublicLinksOfAllSelectedQuickLinks":
            MessageLookupByLibrary.simpleMessage(
                "Это удалит публичные ссылки на все выбранные быстрые ссылки."),
        "toEnableAppLockPleaseSetupDevicePasscodeOrScreen":
            MessageLookupByLibrary.simpleMessage(
                "Чтобы включить блокировку, настройте пароль устройства или блокировку экрана в настройках системы."),
        "toHideAPhotoOrVideo":
            MessageLookupByLibrary.simpleMessage("Скрыть фото или видео"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "Чтобы сбросить пароль, сначала подтвердите свой адрес электронной почты."),
        "todaysLogs": MessageLookupByLibrary.simpleMessage("Сегодняшние логи"),
        "tooManyIncorrectAttempts": MessageLookupByLibrary.simpleMessage(
            "Слишком много неудачных попыток"),
        "total": MessageLookupByLibrary.simpleMessage("всего"),
        "totalSize": MessageLookupByLibrary.simpleMessage("Общий размер"),
        "trash": MessageLookupByLibrary.simpleMessage("Корзина"),
        "trim": MessageLookupByLibrary.simpleMessage("Сократить"),
        "trustedContacts":
            MessageLookupByLibrary.simpleMessage("Доверенные контакты"),
        "tryAgain": MessageLookupByLibrary.simpleMessage("Попробовать снова"),
        "turnOnBackupForAutoUpload": MessageLookupByLibrary.simpleMessage(
            "Включите резервное копирование, чтобы автоматически загружать файлы, добавленные в эту папку устройства, в Ente."),
        "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
        "twoMonthsFreeOnYearlyPlans": MessageLookupByLibrary.simpleMessage(
            "2 бесплатных месяца при годовом плане"),
        "twofactor": MessageLookupByLibrary.simpleMessage("Двухфакторная"),
        "twofactorAuthenticationHasBeenDisabled":
            MessageLookupByLibrary.simpleMessage(
                "Двухфакторная аутентификация отключена"),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage(
                "Двухфакторная аутентификация"),
        "twofactorAuthenticationSuccessfullyReset":
            MessageLookupByLibrary.simpleMessage(
                "Двухфакторная аутентификация успешно сброшена"),
        "twofactorSetup": MessageLookupByLibrary.simpleMessage("Вход с 2FA"),
        "typeOfGallerGallerytypeIsNotSupportedForRename": m81,
        "unarchive": MessageLookupByLibrary.simpleMessage("Разархивировать"),
        "unarchiveAlbum":
            MessageLookupByLibrary.simpleMessage("Разархивировать альбом"),
        "unarchiving":
            MessageLookupByLibrary.simpleMessage("Разархивирование..."),
        "unavailableReferralCode": MessageLookupByLibrary.simpleMessage(
            "Извините, такого кода не существует."),
        "uncategorized": MessageLookupByLibrary.simpleMessage("Без категории"),
        "unhide": MessageLookupByLibrary.simpleMessage("Показать"),
        "unhideToAlbum":
            MessageLookupByLibrary.simpleMessage("Показать в альбоме"),
        "unhiding": MessageLookupByLibrary.simpleMessage("Показ..."),
        "unhidingFilesToAlbum":
            MessageLookupByLibrary.simpleMessage("Раскрытие файлов в альбоме"),
        "unlock": MessageLookupByLibrary.simpleMessage("Разблокировать"),
        "unpinAlbum": MessageLookupByLibrary.simpleMessage("Открепить альбом"),
        "unselectAll": MessageLookupByLibrary.simpleMessage("Отменить выбор"),
        "update": MessageLookupByLibrary.simpleMessage("Обновить"),
        "updateAvailable":
            MessageLookupByLibrary.simpleMessage("Доступно обновление"),
        "updatingFolderSelection":
            MessageLookupByLibrary.simpleMessage("Обновление выбора папки..."),
        "upgrade": MessageLookupByLibrary.simpleMessage("Обновить"),
        "uploadIsIgnoredDueToIgnorereason": m82,
        "uploadingFilesToAlbum":
            MessageLookupByLibrary.simpleMessage("Загрузка файлов в альбом..."),
        "upto50OffUntil4thDec": MessageLookupByLibrary.simpleMessage(
            "Скидка 50%, до 4-го декабря."),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "Доступное хранилище ограничено вашим текущим планом. Избыточное полученное хранилище автоматически станет доступным для использования при улучшении плана."),
        "useAsCover":
            MessageLookupByLibrary.simpleMessage("Использовать для обложки"),
        "usePublicLinksForPeopleNotOnEnte":
            MessageLookupByLibrary.simpleMessage(
                "Использовать публичные ссылки для людей не на Ente"),
        "useRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Использовать ключ восстановления"),
        "useSelectedPhoto":
            MessageLookupByLibrary.simpleMessage("Использовать выбранное фото"),
        "usedSpace": MessageLookupByLibrary.simpleMessage("Использовано места"),
        "validTill": m84,
        "verificationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Проверка не удалась, попробуйте еще раз"),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("Идентификатор подтверждения"),
        "verify": MessageLookupByLibrary.simpleMessage("Подтвердить"),
        "verifyEmail": MessageLookupByLibrary.simpleMessage(
            "Подтвердить электронную почту"),
        "verifyEmailID": m85,
        "verifyIDLabel": MessageLookupByLibrary.simpleMessage("Подтверждение"),
        "verifyPasskey":
            MessageLookupByLibrary.simpleMessage("Подтвердить ключ"),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Подтверждение пароля"),
        "verifying": MessageLookupByLibrary.simpleMessage("Проверка..."),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Проверка ключа восстановления..."),
        "videoInfo": MessageLookupByLibrary.simpleMessage("Информация о видео"),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("видео"),
        "videos": MessageLookupByLibrary.simpleMessage("Видео"),
        "viewActiveSessions":
            MessageLookupByLibrary.simpleMessage("Просмотр активных сессий"),
        "viewAddOnButton":
            MessageLookupByLibrary.simpleMessage("Просмотр расширений"),
        "viewAll": MessageLookupByLibrary.simpleMessage("Просмотреть все"),
        "viewAllExifData":
            MessageLookupByLibrary.simpleMessage("Просмотреть все данные EXIF"),
        "viewLargeFiles": MessageLookupByLibrary.simpleMessage("Большие файлы"),
        "viewLogs": MessageLookupByLibrary.simpleMessage("Посмотреть логи"),
        "viewRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Просмотреть ключ восстановления"),
        "viewer": MessageLookupByLibrary.simpleMessage("Наблюдатель"),
        "viewersSuccessfullyAdded": m86,
        "visitWebToManage": MessageLookupByLibrary.simpleMessage(
            "Пожалуйста, посетите web.ente.io для управления вашей подпиской"),
        "waitingForVerification":
            MessageLookupByLibrary.simpleMessage("Ожидание подтверждения..."),
        "waitingForWifi":
            MessageLookupByLibrary.simpleMessage("Ожидание WiFi..."),
        "weAreOpenSource": MessageLookupByLibrary.simpleMessage(
            "У нас открытый исходный код!"),
        "weDontSupportEditingPhotosAndAlbumsThatYouDont":
            MessageLookupByLibrary.simpleMessage(
                "Мы не можем поддержать редактирование фотографий и альбомов, которыми вы не владеете"),
        "weHaveSendEmailTo": m2,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Слабый"),
        "welcomeBack": MessageLookupByLibrary.simpleMessage("С возвращением!"),
        "whatsNew": MessageLookupByLibrary.simpleMessage("Что нового"),
        "yearShort": MessageLookupByLibrary.simpleMessage("г."),
        "yearly": MessageLookupByLibrary.simpleMessage("Ежегодно"),
        "yearsAgo": m87,
        "yes": MessageLookupByLibrary.simpleMessage("Да"),
        "yesCancel": MessageLookupByLibrary.simpleMessage("Да, отменить"),
        "yesConvertToViewer":
            MessageLookupByLibrary.simpleMessage("Да, преобразовать в зрителя"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("Да, удалить"),
        "yesDiscardChanges":
            MessageLookupByLibrary.simpleMessage("Да, отменить изменения"),
        "yesLogout": MessageLookupByLibrary.simpleMessage("Да, выйти"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("Да, удалить"),
        "yesRenew": MessageLookupByLibrary.simpleMessage("Да, продлить"),
        "yesResetPerson":
            MessageLookupByLibrary.simpleMessage("Да, сбросить человека"),
        "you": MessageLookupByLibrary.simpleMessage("Вы"),
        "youAreOnAFamilyPlan":
            MessageLookupByLibrary.simpleMessage("Вы на семейном плане!"),
        "youAreOnTheLatestVersion": MessageLookupByLibrary.simpleMessage(
            "Вы используете последнюю версию"),
        "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "* Вы можете максимально удвоить объем хранилища"),
        "youCanManageYourLinksInTheShareTab":
            MessageLookupByLibrary.simpleMessage(
                "Вы можете управлять своими ссылками во вкладке \"Поделиться\"."),
        "youCanTrySearchingForADifferentQuery":
            MessageLookupByLibrary.simpleMessage(
                "Вы можете попробовать выполнить поиск по другому запросу."),
        "youCannotDowngradeToThisPlan": MessageLookupByLibrary.simpleMessage(
            "Вы не можете перейти к этому плану"),
        "youCannotShareWithYourself": MessageLookupByLibrary.simpleMessage(
            "Вы не можете поделиться с самим собой"),
        "youDontHaveAnyArchivedItems": MessageLookupByLibrary.simpleMessage(
            "У вас нет архивных элементов."),
        "youHaveSuccessfullyFreedUp": m88,
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("Ваш аккаунт был удален"),
        "yourMap": MessageLookupByLibrary.simpleMessage("Ваша карта"),
        "yourPlanWasSuccessfullyDowngraded":
            MessageLookupByLibrary.simpleMessage(
                "Ваш план был успешно изменен"),
        "yourPlanWasSuccessfullyUpgraded": MessageLookupByLibrary.simpleMessage(
            "Ваш план был успешно улучшен"),
        "yourPurchaseWasSuccessful":
            MessageLookupByLibrary.simpleMessage("Покупка прошла успешно"),
        "yourStorageDetailsCouldNotBeFetched":
            MessageLookupByLibrary.simpleMessage(
                "Не удалось получить сведения о вашем хранилище"),
        "yourSubscriptionHasExpired": MessageLookupByLibrary.simpleMessage(
            "Срок действия вашей подписки окончился"),
        "yourSubscriptionWasUpdatedSuccessfully":
            MessageLookupByLibrary.simpleMessage(
                "Ваша подписка успешно обновлена"),
        "yourVerificationCodeHasExpired": MessageLookupByLibrary.simpleMessage(
            "Срок действия вашего проверочного кода истек"),
        "youveNoDuplicateFilesThatCanBeCleared":
            MessageLookupByLibrary.simpleMessage(
                "У вас нет дубликатов файлов, которые можно очистить"),
        "youveNoFilesInThisAlbumThatCanBeDeleted":
            MessageLookupByLibrary.simpleMessage(
                "В этом альбоме нет файлов, которые можно удалить"),
        "zoomOutToSeePhotos": MessageLookupByLibrary.simpleMessage(
            "Увеличьте масштаб для просмотра фото")
      };
}
