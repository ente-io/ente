// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class StringsLocalizationsUk extends StringsLocalizations {
  StringsLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get networkHostLookUpErr =>
      'Не вдалося приєднатися до Ente. Будь ласка, перевірте налаштування мережі. Зверніться до нашої команди підтримки, якщо помилка залишиться.';

  @override
  String get networkConnectionRefusedErr =>
      'Не вдалося приєднатися до Ente. Будь ласка, спробуйте ще раз через деякий час. Якщо помилка не зникне, зв\'яжіться з нашою командою підтримки.';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      'Схоже, що щось пішло не так. Будь ласка, спробуйте ще раз через деякий час. Якщо помилка не зникне, зв\'яжіться з нашою командою підтримки.';

  @override
  String get error => 'Помилка';

  @override
  String get ok => 'Ок';

  @override
  String get faq => 'Часті питання';

  @override
  String get contactSupport => 'Звернутися до служби підтримки';

  @override
  String get emailYourLogs => 'Відправте ваші журнали електронною поштою';

  @override
  String pleaseSendTheLogsTo(String toEmail) {
    return 'Будь ласка, надішліть журнали до електронної пошти $toEmail';
  }

  @override
  String get copyEmailAddress => 'Копіювати електронну адресу';

  @override
  String get exportLogs => 'Експортувати журнал';

  @override
  String get cancel => 'Скасувати';

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
  String get reportABug => 'Повідомити про помилку';

  @override
  String get logsDialogBody =>
      'This will send across logs to help us debug your issue. Please note that file names will be included to help track issues with specific files.';

  @override
  String get viewLogs => 'View logs';

  @override
  String customEndpoint(String endpoint) {
    return 'Приєднано до $endpoint';
  }

  @override
  String get save => 'Зберегти';

  @override
  String get send => 'Надіслати';

  @override
  String get saveOrSendDescription =>
      'Чи хочете ви зберегти це до свого сховища (типово тека Downloads), чи надіслати його в інші застосунки?';

  @override
  String get saveOnlyDescription =>
      'Чи хочете Ви зберегти це до свого сховища (тека Downloads за замовчуванням)?';

  @override
  String get enterNewEmailHint => 'Enter your new email address';

  @override
  String get email => 'Адреса електронної пошти';

  @override
  String get verify => 'Перевірити';

  @override
  String get invalidEmailTitle => 'Хибна адреса електронної пошти';

  @override
  String get invalidEmailMessage => 'Введіть дійсну адресу електронної пошти.';

  @override
  String get pleaseWait => 'Будь ласка, зачекайте...';

  @override
  String get verifyPassword => 'Підтвердження пароля';

  @override
  String get incorrectPasswordTitle => 'Невірний пароль';

  @override
  String get pleaseTryAgain => 'Будь ласка, спробуйте ще раз';

  @override
  String get enterPassword => 'Введіть пароль';

  @override
  String get enterYourPasswordHint => 'Введіть свій пароль';

  @override
  String get activeSessions => 'Активні сеанси';

  @override
  String get oops => 'От халепа';

  @override
  String get somethingWentWrongPleaseTryAgain =>
      'Щось пішло не так, спробуйте, будь ласка, знову';

  @override
  String get thisWillLogYouOutOfThisDevice =>
      'Це призведе до виходу на цьому пристрої!';

  @override
  String get thisWillLogYouOutOfTheFollowingDevice =>
      'Це призведе до виходу на наступному пристрої:';

  @override
  String get terminateSession => 'Припинити сеанс?';

  @override
  String get terminate => 'Припинити';

  @override
  String get thisDevice => 'Цей пристрій';

  @override
  String get createAccount => 'Створити обліковий запис';

  @override
  String get weakStrength => 'Слабкий';

  @override
  String get moderateStrength => 'Помірний';

  @override
  String get strongStrength => 'Надійний';

  @override
  String get deleteAccount => 'Видалити обліковий запис';

  @override
  String get deleteAccountQuery =>
      'Нам дуже шкода, що Ви залишаєте нас. Чи Ви зіткнулися з якоюсь проблемою?';

  @override
  String get yesSendFeedbackAction => 'Так, надіслати відгук';

  @override
  String get noDeleteAccountAction => 'Ні, видаліть мій обліковий запис';

  @override
  String get initiateAccountDeleteTitle =>
      'Будь ласка, авторизуйтесь, щоб розпочати видалення облікового запису';

  @override
  String get confirmAccountDeleteTitle =>
      'Підтвердіть видалення облікового запису';

  @override
  String get confirmAccountDeleteMessage =>
      'Цей обліковий запис є зв\'язаним з іншими програмами Ente, якщо ви використовуєте якісь з них.\n\nВаші завантажені дані у всіх програмах Ente будуть заплановані до видалення, а обліковий запис буде видалено назавжди.';

  @override
  String get delete => 'Видалити';

  @override
  String get createNewAccount => 'Створити новий обліковий запис';

  @override
  String get password => 'Пароль';

  @override
  String get confirmPassword => 'Підтвердити пароль';

  @override
  String passwordStrength(String passwordStrengthValue) {
    return 'Сила пароля: $passwordStrengthValue';
  }

  @override
  String get hearUsWhereTitle => 'Як ви дізналися про Ente? (опціонально)';

  @override
  String get hearUsExplanation =>
      'Ми не відстежуємо встановлення застосунків. Але, якщо ви скажете нам, де ви нас знайшли, це допоможе!';

  @override
  String get signUpTerms =>
      'Я приймаю <u-terms>умови використання</u-terms> і <u-policy>політику конфіденційності</u-policy>';

  @override
  String get termsOfServicesTitle => 'Умови';

  @override
  String get privacyPolicyTitle => 'Політика конфіденційності';

  @override
  String get ackPasswordLostWarning =>
      'Я розумію, що якщо я втрачу свій пароль, я можу втратити свої дані, тому що вони є захищені <underline>наскрізним шифруванням</underline>.';

  @override
  String get encryption => 'Шифрування';

  @override
  String get logInLabel => 'Увійти';

  @override
  String get welcomeBack => 'З поверненням!';

  @override
  String get loginTerms =>
      'Натискаючи «Увійти», я приймаю <u-terms>умови використання</u-terms> і <u-policy>політику конфіденційності</u-policy>';

  @override
  String get noInternetConnection => 'Немає підключення до Інтернету';

  @override
  String get pleaseCheckYourInternetConnectionAndTryAgain =>
      'Будь ласка, перевірте підключення до Інтернету та спробуйте ще раз.';

  @override
  String get verificationFailedPleaseTryAgain =>
      'Перевірка не вдалася, спробуйте ще';

  @override
  String get recreatePasswordTitle => 'Повторно створити пароль';

  @override
  String get recreatePasswordBody =>
      'Поточний пристрій не є достатньо потужним для підтвердження пароля, але ми можемо відновити його таким чином, щоб він працював на всіх пристроях.\n\nБудь ласка, увійдіть за допомогою вашого ключа відновлення і відновіть ваш пароль (ви можете знову використати той самий пароль, якщо бажаєте).';

  @override
  String get useRecoveryKey => 'Застосувати ключ відновлення';

  @override
  String get forgotPassword => 'Нагадати пароль';

  @override
  String get changeEmail => 'Змінити адресу електронної пошти';

  @override
  String get verifyEmail => 'Підтвердити електронну адресу';

  @override
  String weHaveSendEmailTo(String email) {
    return 'Ми надіслали листа на адресу електронної пошти <green>$email</green>';
  }

  @override
  String get toResetVerifyEmail =>
      'Щоб скинути пароль, будь ласка, спочатку підтвердіть адресу своєї електронної пошти.';

  @override
  String get checkInboxAndSpamFolder =>
      'Будь ласка, перевірте вашу скриньку електронної пошти (та спам), щоб завершити перевірку';

  @override
  String get tapToEnterCode => 'Натисніть, щоб ввести код';

  @override
  String get sendEmail => 'Надіслати електронного листа';

  @override
  String get resendEmail => 'Повторно надіслати лист на електронну пошту';

  @override
  String get passKeyPendingVerification => 'Підтвердження все ще в процесі';

  @override
  String get loginSessionExpired => 'Час сеансу минув';

  @override
  String get loginSessionExpiredDetails =>
      'Термін дії вашого сеансу завершився. Будь ласка, увійдіть знову.';

  @override
  String get passkeyAuthTitle => 'Перевірка секретного ключа';

  @override
  String get waitingForVerification => 'Очікується підтвердження...';

  @override
  String get tryAgain => 'Спробуйте ще раз';

  @override
  String get checkStatus => 'Перевірити стан';

  @override
  String get loginWithTOTP => 'Увійти за допомогою TOTP';

  @override
  String get recoverAccount => 'Відновити обліковий запис';

  @override
  String get setPasswordTitle => 'Встановити пароль';

  @override
  String get changePasswordTitle => 'Змінити пароль';

  @override
  String get resetPasswordTitle => 'Скинути пароль';

  @override
  String get encryptionKeys => 'Ключі шифрування';

  @override
  String get enterPasswordToEncrypt =>
      'Введіть пароль, який ми зможемо використати для шифрування ваших даних';

  @override
  String get enterNewPasswordToEncrypt =>
      'Введіть новий пароль, який ми зможемо використати для шифрування ваших даних';

  @override
  String get passwordWarning =>
      'Ми не зберігаємо цей пароль, тому, якщо ви його забудете, <underline>ми не зможемо розшифрувати Ваші дані</underline>';

  @override
  String get howItWorks => 'Як це працює';

  @override
  String get generatingEncryptionKeys => 'Створення ключів шифрування...';

  @override
  String get passwordChangedSuccessfully => 'Пароль успішно змінено';

  @override
  String get signOutFromOtherDevices => 'Вийти на інших пристроях';

  @override
  String get signOutOtherBody =>
      'Якщо ви думаєте, що хтось може знати ваш пароль, ви можете примусити всі інші пристрої, які використовують ваш обліковий запис, вийти з нього.';

  @override
  String get signOutOtherDevices => 'Вийти на інших пристроях';

  @override
  String get doNotSignOut => 'Не виходити';

  @override
  String get generatingEncryptionKeysTitle => 'Створення ключів шифрування...';

  @override
  String get continueLabel => 'Продовжити';

  @override
  String get insecureDevice => 'Незахищений пристрій';

  @override
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease =>
      'На жаль, нам не вдалося згенерувати захищені ключі на цьому пристрої.\n\nБудь ласка, увійдіть з іншого пристрою.';

  @override
  String get recoveryKeyCopiedToClipboard =>
      'Ключ відновлення скопійований в буфер обміну';

  @override
  String get recoveryKey => 'Ключ відновлення';

  @override
  String get recoveryKeyOnForgotPassword =>
      'Якщо ви забудете свій пароль, то єдиний спосіб відновити ваші дані – за допомогою цього ключа.';

  @override
  String get recoveryKeySaveDescription =>
      'Ми не зберігаємо цей ключ, будь ласка, збережіть цей ключ з 24 слів в надійному місці.';

  @override
  String get doThisLater => 'Зробити це пізніше';

  @override
  String get saveKey => 'Зберегти ключ';

  @override
  String get recoveryKeySaved =>
      'Ключ відновлення збережений у теці Downloads!';

  @override
  String get noRecoveryKeyTitle => 'Немає ключа відновлення?';

  @override
  String get twoFactorAuthTitle => 'Двоетапна автентифікація';

  @override
  String get enterCodeHint =>
      'Введіть нижче шестизначний код із застосунку для автентифікації';

  @override
  String get lostDeviceTitle => 'Загубили пристрій?';

  @override
  String get enterRecoveryKeyHint => 'Введіть ваш ключ відновлення';

  @override
  String get recover => 'Відновлення';

  @override
  String get loggingOut => 'Вихід із системи...';

  @override
  String get immediately => 'Негайно';

  @override
  String get appLock => 'Блокування';

  @override
  String get autoLock => 'Автоблокування';

  @override
  String get noSystemLockFound => 'Не знайдено системного блокування';

  @override
  String get deviceLockEnablePreSteps =>
      'Для увімкнення блокування програми, будь ласка, налаштуйте пароль пристрою або блокування екрана в системних налаштуваннях.';

  @override
  String get appLockDescription =>
      'Виберіть між типовим екраном блокування вашого пристрою та власним екраном блокування з PIN-кодом або паролем.';

  @override
  String get deviceLock => 'Блокування пристрою';

  @override
  String get pinLock => 'PIN-код';

  @override
  String get autoLockFeatureDescription =>
      'Час, через який застосунок буде заблоковано після розміщення у фоновому режимі';

  @override
  String get hideContent => 'Приховати вміст';

  @override
  String get hideContentDescriptionAndroid =>
      'Приховує вміст програми у перемикачі застосунків і вимикає знімки екрану';

  @override
  String get hideContentDescriptioniOS =>
      'Приховує вміст у перемикачі застосунків';

  @override
  String get tooManyIncorrectAttempts => 'Завелика кількість невірних спроб';

  @override
  String get tapToUnlock => 'Доторкніться, щоб розблокувати';

  @override
  String get areYouSureYouWantToLogout =>
      'Ви впевнені, що хочете вийти з системи?';

  @override
  String get yesLogout => 'Так, вийти з системи';

  @override
  String get authToViewSecrets =>
      'Будь ласка, пройдіть автентифікацію, щоб переглянути ваші секретні коди';

  @override
  String get next => 'Наступний';

  @override
  String get setNewPassword => 'Встановити новий пароль';

  @override
  String get enterPin => 'Введіть PIN-код';

  @override
  String get setNewPin => 'Встановити новий PIN-код';

  @override
  String get confirm => 'Підтвердити';

  @override
  String get reEnterPassword => 'Введіть пароль ще раз';

  @override
  String get reEnterPin => 'Введіть PIN-код ще раз';

  @override
  String get androidBiometricHint => 'Підтвердити ідентифікацію';

  @override
  String get androidBiometricNotRecognized =>
      'Не розпізнано. Спробуйте ще раз.';

  @override
  String get androidBiometricSuccess => 'Успіх';

  @override
  String get androidCancelButton => 'Скасувати';

  @override
  String get androidSignInTitle => 'Необхідна автентифікація';

  @override
  String get androidBiometricRequiredTitle =>
      'Потрібна біометрична автентифікація';

  @override
  String get androidDeviceCredentialsRequiredTitle =>
      'Необхідні облікові дані пристрою';

  @override
  String get androidDeviceCredentialsSetupDescription =>
      'Необхідні облікові дані пристрою';

  @override
  String get goToSettings => 'Перейти до налаштувань';

  @override
  String get androidGoToSettingsDescription =>
      'Біометрична автентифікація не налаштована на вашому пристрої. Перейдіть в «Налаштування > Безпека», щоб додати біометричну автентифікацію.';

  @override
  String get iOSLockOut =>
      'Біометрична автентифікація вимкнена. Будь ласка, заблокуйте і розблокуйте свій екран, щоб увімкнути її.';

  @override
  String get iOSOkButton => 'OK';

  @override
  String get emailAlreadyRegistered => 'Email already registered.';

  @override
  String get emailNotRegistered => 'Email not registered.';

  @override
  String get thisEmailIsAlreadyInUse =>
      'Ця адреса електронної пошти вже використовується';

  @override
  String emailChangedTo(String newEmail) {
    return 'Адресу електронної пошти змінено на $newEmail';
  }

  @override
  String get authenticationFailedPleaseTryAgain =>
      'Автентифікація не пройдена. Будь ласка, спробуйте ще раз';

  @override
  String get authenticationSuccessful => 'Автентифікацію виконано!';

  @override
  String get sessionExpired => 'Час сеансу минув';

  @override
  String get incorrectRecoveryKey => 'Неправильний ключ відновлення';

  @override
  String get theRecoveryKeyYouEnteredIsIncorrect =>
      'Ви ввели неправильний ключ відновлення';

  @override
  String get twofactorAuthenticationSuccessfullyReset =>
      'Двоетапна автентифікація успішно скинута';

  @override
  String get noRecoveryKey => 'No recovery key';

  @override
  String get yourAccountHasBeenDeleted => 'Your account has been deleted';

  @override
  String get verificationId => 'Verification ID';

  @override
  String get yourVerificationCodeHasExpired =>
      'Час дії коду підтвердження минув';

  @override
  String get incorrectCode => 'Невірний код';

  @override
  String get sorryTheCodeYouveEnteredIsIncorrect =>
      'Вибачте, але введений вами код є невірним';

  @override
  String get developerSettings => 'Налаштування розробника';

  @override
  String get serverEndpoint => 'Кінцева точка сервера';

  @override
  String get invalidEndpoint => 'Некоректна кінцева точка';

  @override
  String get invalidEndpointMessage =>
      'Вибачте, введена вами кінцева точка є недійсною. Введіть дійсну кінцеву точку та спробуйте ще раз.';

  @override
  String get endpointUpdatedMessage => 'Точка входу успішно оновлена';
}
