// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class StringsLocalizationsRu extends StringsLocalizations {
  StringsLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get networkHostLookUpErr =>
      'Не удается подключиться к Ente, пожалуйста, проверьте настройки своей сети и обратитесь в службу поддержки, если ошибка повторится.';

  @override
  String get networkConnectionRefusedErr =>
      'Не удается подключиться к Ente, пожалуйста, повторите попытку через некоторое время. Если ошибка не устраняется, обратитесь в службу поддержки.';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      'Похоже, что-то пошло не так. Пожалуйста, повторите попытку через некоторое время. Если ошибка повторится, обратитесь в нашу службу поддержки.';

  @override
  String get error => 'Ошибка';

  @override
  String get ok => 'Ок';

  @override
  String get faq => 'ЧаВо';

  @override
  String get contactSupport => 'Связаться с поддержкой';

  @override
  String get emailYourLogs => 'Отправить свои журналы';

  @override
  String pleaseSendTheLogsTo(String toEmail) {
    return 'Пожалуйста, отправьте журналы на \n$toEmail';
  }

  @override
  String get copyEmailAddress => 'Копировать адрес электронной почты';

  @override
  String get exportLogs => 'Экспорт журналов';

  @override
  String get cancel => 'Отмена';

  @override
  String pleaseEmailUsAt(String toEmail) {
    return 'Email us at $toEmail';
  }

  @override
  String get emailAddressCopied => 'Email address copied';

  @override
  String get supportEmailSubject => '[Support]';

  @override
  String get clientDebugInfoLabel =>
      'Following information can help us in debugging if you are facing any issue';

  @override
  String get registeredEmailLabel => 'Registered email:';

  @override
  String get clientLabel => 'Client:';

  @override
  String get versionLabel => 'Version :';

  @override
  String get notAvailable => 'N/A';

  @override
  String get reportABug => 'Сообщить об ошибке';

  @override
  String get logsDialogBody =>
      'This will send across logs to help us debug your issue. Please note that file names will be included to help track issues with specific files.';

  @override
  String get viewLogs => 'View logs';

  @override
  String customEndpoint(String endpoint) {
    return 'Подключено к $endpoint';
  }

  @override
  String get save => 'Сохранить';

  @override
  String get send => 'Отправить';

  @override
  String get saveOrSendDescription =>
      'Вы хотите сохранить это в хранилище (папку загрузок по умолчанию) или отправить в другие приложения?';

  @override
  String get saveOnlyDescription =>
      'Вы хотите сохранить это в хранилище (по умолчанию папка загрузок)?';

  @override
  String get enterNewEmailHint => 'Введите ваш новый адрес электронной почты';

  @override
  String get email => 'Электронная почта';

  @override
  String get verify => 'Подтвердить';

  @override
  String get invalidEmailTitle => 'Неверный адрес электронной почты';

  @override
  String get invalidEmailMessage =>
      'Пожалуйста, введите действительный адрес электронной почты.';

  @override
  String get pleaseWait => 'Пожалуйста, подождите...';

  @override
  String get verifyPassword => 'Подтверждение пароля';

  @override
  String get incorrectPasswordTitle => 'Неправильный пароль';

  @override
  String get pleaseTryAgain => 'Пожалуйста, попробуйте ещё раз';

  @override
  String get enterPassword => 'Введите пароль';

  @override
  String get enterYourPasswordHint => 'Введите пароль';

  @override
  String get activeSessions => 'Активные сеансы';

  @override
  String get oops => 'Ой';

  @override
  String get somethingWentWrongPleaseTryAgain =>
      'Что-то пошло не так. Попробуйте еще раз';

  @override
  String get thisWillLogYouOutOfThisDevice => 'Вы выйдете из этого устройства!';

  @override
  String get thisWillLogYouOutOfTheFollowingDevice =>
      'Вы выйдете из списка следующих устройств:';

  @override
  String get terminateSession => 'Завершить сеанс?';

  @override
  String get terminate => 'Завершить';

  @override
  String get thisDevice => 'Это устройство';

  @override
  String get createAccount => 'Создать аккаунт';

  @override
  String get weakStrength => 'Слабый';

  @override
  String get moderateStrength => 'Средний';

  @override
  String get strongStrength => 'Сильный';

  @override
  String get deleteAccount => 'Удалить аккаунт';

  @override
  String get deleteAccountQuery =>
      'Нам будет жаль, если вы уйдете. Вы столкнулись с какой-то проблемой?';

  @override
  String get yesSendFeedbackAction => 'Да, отправить отзыв';

  @override
  String get noDeleteAccountAction => 'Нет, удалить аккаунт';

  @override
  String get initiateAccountDeleteTitle =>
      'Пожалуйста, авторизуйтесь, чтобы начать удаление аккаунта';

  @override
  String get confirmAccountDeleteTitle => 'Подтвердить удаление аккаунта';

  @override
  String get confirmAccountDeleteMessage =>
      'Эта учетная запись связана с другими приложениями Ente, если вы ими пользуетесь.\n\nЗагруженные вами данные во всех приложениях Ente будут запланированы к удалению, а ваша учетная запись будет удалена без возможности восстановления.';

  @override
  String get delete => 'Удалить';

  @override
  String get createNewAccount => 'Создать новый аккаунт';

  @override
  String get password => 'Пароль';

  @override
  String get confirmPassword => 'Подтвердить пароль';

  @override
  String passwordStrength(String passwordStrengthValue) {
    return 'Мощность пароля: $passwordStrengthValue';
  }

  @override
  String get hearUsWhereTitle => 'Как вы узнали о Ente? (необязательно)';

  @override
  String get hearUsExplanation =>
      'Мы не отслеживаем установки приложений. Было бы полезно, если бы вы сказали, где нас нашли!';

  @override
  String get signUpTerms =>
      'Я согласен с <u-terms>условиями предоставления услуг</u-terms> и <u-policy>политикой конфиденциальности</u-policy>';

  @override
  String get termsOfServicesTitle => 'Условия использования';

  @override
  String get privacyPolicyTitle => 'Политика конфиденциальности';

  @override
  String get ackPasswordLostWarning =>
      'Я понимаю, что если я потеряю свой пароль, я могу потерять свои данные, так как мои данные в <underline>сквозном шифровании</underline>.';

  @override
  String get encryption => 'Шифрование';

  @override
  String get logInLabel => 'Войти';

  @override
  String get welcomeBack => 'С возвращением!';

  @override
  String get loginTerms =>
      'Нажимая на логин, я принимаю <u-terms>условия использования</u-terms> и <u-policy>политику конфиденциальности</u-policy>';

  @override
  String get noInternetConnection => 'Нет подключения к Интернету';

  @override
  String get pleaseCheckYourInternetConnectionAndTryAgain =>
      'Проверьте подключение к Интернету и повторите попытку.';

  @override
  String get verificationFailedPleaseTryAgain =>
      'Проверка не удалась, попробуйте еще раз';

  @override
  String get recreatePasswordTitle => 'Пересоздать пароль';

  @override
  String get recreatePasswordBody =>
      'Текущее устройство недостаточно мощно для верификации пароля, но мы можем регенерировать так, как это работает со всеми устройствами.\n\nПожалуйста, войдите, используя ваш ключ восстановления и сгенерируйте ваш пароль (вы можете использовать тот же пароль, если пожелаете).';

  @override
  String get useRecoveryKey => 'Использовать ключ восстановления';

  @override
  String get forgotPassword => 'Забыл пароль';

  @override
  String get changeEmail => 'Изменить адрес электронной почты';

  @override
  String get verifyEmail => 'Подтвердить адрес электронной почты';

  @override
  String weHaveSendEmailTo(String email) {
    return 'Мы отправили письмо на <green>$email</green>';
  }

  @override
  String get toResetVerifyEmail =>
      'Подтвердите адрес электронной почты, чтобы сбросить пароль.';

  @override
  String get checkInboxAndSpamFolder =>
      'Пожалуйста, проверьте свой почтовый ящик (и спам) для завершения верификации';

  @override
  String get tapToEnterCode => 'Нажмите, чтобы ввести код';

  @override
  String get sendEmail => 'Отправить электронное письмо';

  @override
  String get resendEmail => 'Отправить письмо еще раз';

  @override
  String get passKeyPendingVerification => 'Верификация еще не завершена';

  @override
  String get loginSessionExpired => 'Сессия недействительна';

  @override
  String get loginSessionExpiredDetails => 'Сессия истекла. Войдите снова.';

  @override
  String get passkeyAuthTitle => 'Проверка с помощью ключа доступа';

  @override
  String get waitingForVerification => 'Ожидание подтверждения...';

  @override
  String get tryAgain => 'Попробовать снова';

  @override
  String get checkStatus => 'Проверить статус';

  @override
  String get loginWithTOTP => 'Войти с помощью TOTP';

  @override
  String get recoverAccount => 'Восстановить аккаунт';

  @override
  String get setPasswordTitle => 'Поставить пароль';

  @override
  String get changePasswordTitle => 'Изменить пароль';

  @override
  String get resetPasswordTitle => 'Сбросить пароль';

  @override
  String get encryptionKeys => 'Ключи шифрования';

  @override
  String get enterPasswordToEncrypt =>
      'Введите пароль, который мы можем использовать для шифрования ваших данных';

  @override
  String get enterNewPasswordToEncrypt =>
      'Введите новый пароль, который мы можем использовать для шифрования ваших данных';

  @override
  String get passwordWarning =>
      'Мы не храним этот пароль, поэтому если вы забудете его, <underline>мы не сможем расшифровать ваши данные</underline>';

  @override
  String get howItWorks => 'Как это работает';

  @override
  String get generatingEncryptionKeys => 'Генерируем ключи шифрования...';

  @override
  String get passwordChangedSuccessfully => 'Пароль успешно изменён';

  @override
  String get signOutFromOtherDevices => 'Выйти из других устройств';

  @override
  String get signOutOtherBody =>
      'Если вы думаете, что кто-то может знать ваш пароль, вы можете принудительно выйти из всех устройств.';

  @override
  String get signOutOtherDevices => 'Выйти из других устройств';

  @override
  String get doNotSignOut => 'Не выходить';

  @override
  String get generatingEncryptionKeysTitle => 'Генерируем ключи шифрования...';

  @override
  String get continueLabel => 'Далее';

  @override
  String get insecureDevice => 'Небезопасное устройство';

  @override
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease =>
      'К сожалению, мы не смогли сгенерировать безопасные ключи на этом устройстве.\n\nПожалуйста, зарегистрируйтесь с другого устройства.';

  @override
  String get recoveryKeyCopiedToClipboard =>
      'Ключ восстановления скопирован в буфер обмена';

  @override
  String get recoveryKey => 'Ключ восстановления';

  @override
  String get recoveryKeyOnForgotPassword =>
      'Если вы забыли свой пароль, то восстановить данные можно только с помощью этого ключа.';

  @override
  String get recoveryKeySaveDescription =>
      'Мы не храним этот ключ, пожалуйста, сохраните этот ключ в безопасном месте.';

  @override
  String get doThisLater => 'Сделать позже';

  @override
  String get saveKey => 'Сохранить ключ';

  @override
  String get recoveryKeySaved =>
      'Ключ восстановления сохранён в папке Загрузки!';

  @override
  String get noRecoveryKeyTitle => 'Нет ключа восстановления?';

  @override
  String get twoFactorAuthTitle => 'Двухфакторная аутентификация';

  @override
  String get enterCodeHint =>
      'Введите 6-значный код из\nвашего приложения-аутентификатора';

  @override
  String get lostDeviceTitle => 'Потеряно устройство?';

  @override
  String get enterRecoveryKeyHint => 'Введите ключ восстановления';

  @override
  String get recover => 'Восстановить';

  @override
  String get loggingOut => 'Выходим...';

  @override
  String get immediately => 'Немедленно';

  @override
  String get appLock => 'Блокировка приложения';

  @override
  String get autoLock => 'Автоблокировка';

  @override
  String get noSystemLockFound => 'Системная блокировка не найдена';

  @override
  String get deviceLockEnablePreSteps =>
      'Чтобы включить блокировку устройства, пожалуйста, настройте пароль или блокировку экрана в настройках системы.';

  @override
  String get appLockDescription =>
      'Выберите между экраном блокировки вашего устройства и пользовательским экраном блокировки с PIN-кодом или паролем.';

  @override
  String get deviceLock => 'Блокировка устройства';

  @override
  String get pinLock => 'Pin блокировка';

  @override
  String get autoLockFeatureDescription =>
      'Время в фоне, после которого приложение блокируется';

  @override
  String get hideContent => 'Скрыть содержимое';

  @override
  String get hideContentDescriptionAndroid =>
      'Скрывает содержимое приложения в переключателе приложений и отключает скриншоты';

  @override
  String get hideContentDescriptioniOS =>
      'Скрывает содержимое приложения в переключателе приложений';

  @override
  String get tooManyIncorrectAttempts => 'Слишком много неудачных попыток';

  @override
  String get tapToUnlock => 'Нажмите для разблокировки';

  @override
  String get areYouSureYouWantToLogout => 'Вы уверены, что хотите выйти?';

  @override
  String get yesLogout => 'Да, выйти';

  @override
  String get authToViewSecrets =>
      'Пожалуйста, авторизуйтесь для просмотра ваших секретов';

  @override
  String get next => 'Далее';

  @override
  String get setNewPassword => 'Задать новый пароль';

  @override
  String get enterPin => 'Введите PIN';

  @override
  String get setNewPin => 'Установите новый PIN';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get reEnterPassword => 'Подтвердите пароль';

  @override
  String get reEnterPin => 'Введите PIN-код ещё раз';

  @override
  String get androidBiometricHint => 'Подтвердите личность';

  @override
  String get androidBiometricNotRecognized =>
      'Не распознано. Попробуйте еще раз.';

  @override
  String get androidBiometricSuccess => 'Успешно';

  @override
  String get androidCancelButton => 'Отменить';

  @override
  String get androidSignInTitle => 'Требуется аутентификация';

  @override
  String get androidBiometricRequiredTitle => 'Требуется биометрия';

  @override
  String get androidDeviceCredentialsRequiredTitle =>
      'Требуются учетные данные устройства';

  @override
  String get androidDeviceCredentialsSetupDescription =>
      'Требуются учетные данные устройства';

  @override
  String get goToSettings => 'Перейдите к настройкам';

  @override
  String get androidGoToSettingsDescription =>
      'Биометрическая аутентификация не настроена на вашем устройстве. Перейдите в \"Настройки > Безопасность\", чтобы добавить биометрическую аутентификацию.';

  @override
  String get iOSLockOut =>
      'Биометрическая аутентификация отключена. Пожалуйста, заблокируйте и разблокируйте экран, чтобы включить ее.';

  @override
  String get iOSOkButton => 'ОК';

  @override
  String get emailAlreadyRegistered =>
      'Адрес электронной почты уже зарегистрирован.';

  @override
  String get emailNotRegistered =>
      'Адрес электронной почты не зарегистрирован.';

  @override
  String get thisEmailIsAlreadyInUse =>
      'Этот адрес электронной почты уже используется';

  @override
  String emailChangedTo(String newEmail) {
    return 'Адрес электронной почты изменен на $newEmail';
  }

  @override
  String get authenticationFailedPleaseTryAgain =>
      'Аутентификация не удалась, попробуйте еще раз';

  @override
  String get authenticationSuccessful => 'Аутентификация прошла успешно!';

  @override
  String get sessionExpired => 'Сеанс истек';

  @override
  String get incorrectRecoveryKey => 'Неправильный ключ восстановления';

  @override
  String get theRecoveryKeyYouEnteredIsIncorrect =>
      'Введен неправильный ключ восстановления';

  @override
  String get twofactorAuthenticationSuccessfullyReset =>
      'Двухфакторная аутентификация успешно сброшена';

  @override
  String get noRecoveryKey => 'No recovery key';

  @override
  String get yourAccountHasBeenDeleted => 'Your account has been deleted';

  @override
  String get verificationId => 'Verification ID';

  @override
  String get yourVerificationCodeHasExpired =>
      'Срок действия вашего проверочного кода истек';

  @override
  String get incorrectCode => 'Неверный код';

  @override
  String get sorryTheCodeYouveEnteredIsIncorrect =>
      'Извините, введенный вами код неверный';

  @override
  String get developerSettings => 'Настройки разработчика';

  @override
  String get serverEndpoint => 'Конечная точка сервера';

  @override
  String get invalidEndpoint => 'Неверная конечная точка';

  @override
  String get invalidEndpointMessage =>
      'Извините, введенная вами конечная точка неверна. Пожалуйста, введите корректную конечную точку и повторите попытку.';

  @override
  String get endpointUpdatedMessage => 'Конечная точка успешно обновлена';
}
