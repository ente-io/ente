// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bulgarian (`bg`).
class StringsLocalizationsBg extends StringsLocalizations {
  StringsLocalizationsBg([String locale = 'bg']) : super(locale);

  @override
  String get networkHostLookUpErr =>
      'Не може да се свърже с Ente, моля, проверете мрежовите си настройки и се свържете с поддръжката, ако проблемът продължава.';

  @override
  String get networkConnectionRefusedErr =>
      'Не може да се свърже с Ente, моля, опитайте отново след известно време. Ако проблемът продължава, моля, свържете се с поддръжката.';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      'Изглежда нещо се обърка. Моля, опитайте отново след известно време. Ако грешката продължава, моля, свържете се с нашия екип за поддръжка.';

  @override
  String get error => 'Грешка';

  @override
  String get ok => 'Ок';

  @override
  String get faq => 'ЧЗВ';

  @override
  String get contactSupport => 'Свържете се с поддръжката';

  @override
  String get emailYourLogs => 'Изпратете Вашата история на действията на имейл';

  @override
  String pleaseSendTheLogsTo(String toEmail) {
    return 'Моля, изпратете историята на действията на \n$toEmail';
  }

  @override
  String get copyEmailAddress => 'Копиране на имейл адрес';

  @override
  String get exportLogs => 'Експорт на файловете с историята';

  @override
  String get cancel => 'Отказ';

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
  String get reportABug => 'Докладване на проблем';

  @override
  String get logsDialogBody =>
      'This will send across logs to help us debug your issue. Please note that file names will be included to help track issues with specific files.';

  @override
  String get viewLogs => 'View logs';

  @override
  String customEndpoint(String endpoint) {
    return 'Свързан към $endpoint';
  }

  @override
  String get save => 'Запазване';

  @override
  String get send => 'Изпращане';

  @override
  String get saveOrSendDescription =>
      'Искате ли да запазите това в хранилището си (папка за Изтегляния по подразбиране) или да го изпратите на други приложения?';

  @override
  String get saveOnlyDescription =>
      'Искате ли да запазите това в хранилището си (папка за Изтегляния по подразбиране)?';

  @override
  String get enterNewEmailHint => 'Enter your new email address';

  @override
  String get email => 'Имейл';

  @override
  String get verify => 'Потвърждаване';

  @override
  String get invalidEmailTitle => 'Невалиден имейл адрес';

  @override
  String get invalidEmailMessage => 'Моля, въведете валиден имейл адрес.';

  @override
  String get pleaseWait => 'Моля изчакайте...';

  @override
  String get verifyPassword => 'Потвърдете паролата';

  @override
  String get incorrectPasswordTitle => 'Грешна парола';

  @override
  String get pleaseTryAgain => 'Опитайте отново';

  @override
  String get enterPassword => 'Въведете парола';

  @override
  String get enterYourPasswordHint => 'Въведете паролата си';

  @override
  String get activeSessions => 'Активни сесии';

  @override
  String get oops => 'Опа';

  @override
  String get somethingWentWrongPleaseTryAgain =>
      'Нещо се обърка, моля опитайте отново';

  @override
  String get thisWillLogYouOutOfThisDevice =>
      'Това ще Ви изкара от профила на това устройство!';

  @override
  String get thisWillLogYouOutOfTheFollowingDevice =>
      'Това ще Ви изкара от профила на следното устройство:';

  @override
  String get terminateSession => 'Прекратяване на сесията?';

  @override
  String get terminate => 'Прекратяване';

  @override
  String get thisDevice => 'Това устройство';

  @override
  String get createAccount => 'Създаване на акаунт';

  @override
  String get weakStrength => 'Слаба';

  @override
  String get moderateStrength => 'Умерена';

  @override
  String get strongStrength => 'Силна';

  @override
  String get deleteAccount => 'Изтриване на акаунта';

  @override
  String get deleteAccountQuery =>
      'Ще съжаляваме да си тръгнете. Изправени ли сте пред някакъв проблем?';

  @override
  String get yesSendFeedbackAction => 'Да, изпращане на обратна връзка';

  @override
  String get noDeleteAccountAction => 'Не, изтриване на акаунта';

  @override
  String get initiateAccountDeleteTitle =>
      'Моля, удостоверете се, за да инициирате изтриването на акаунта';

  @override
  String get confirmAccountDeleteTitle => 'Потвърдете изтриването на акаунта';

  @override
  String get confirmAccountDeleteMessage =>
      'Този акаунт е свързан с други приложения на Ente, ако използвате такива.\n\nВашите качени данни във всички приложения на Ente ще бъдат планирани за изтриване и акаунтът Ви ще бъде изтрит за постоянно.';

  @override
  String get delete => 'Изтриване';

  @override
  String get createNewAccount => 'Създаване на нов акаунт';

  @override
  String get password => 'Парола';

  @override
  String get confirmPassword => 'Потвърждаване на паролата';

  @override
  String passwordStrength(String passwordStrengthValue) {
    return 'Сила на паролата: $passwordStrengthValue';
  }

  @override
  String get hearUsWhereTitle => 'Как научихте за Ente? (по избор)';

  @override
  String get hearUsExplanation =>
      'Ние не проследяваме инсталиранията на приложения. Ще помогне, ако ни кажете къде ни намерихте!';

  @override
  String get signUpTerms =>
      'Съгласявам се с <u-terms>условията за ползване</u-terms> и <u-policy>политиката за поверителност</u-policy>';

  @override
  String get termsOfServicesTitle => 'Условия';

  @override
  String get privacyPolicyTitle => 'Политика за поверителност';

  @override
  String get ackPasswordLostWarning =>
      'Разбирам, че ако загубя паролата си, може да загубя данните си, тъй като данните ми са <underline>шифровани от край до край</underline>.';

  @override
  String get encryption => 'Шифроване';

  @override
  String get logInLabel => 'Вход';

  @override
  String get welcomeBack => 'Добре дошли отново!';

  @override
  String get loginTerms =>
      'С натискането на вход, се съгласявам с <u-terms>условията за ползване</u-terms> и <u-policy>политиката за поверителност</u-policy>';

  @override
  String get noInternetConnection => 'Няма връзка с интернет';

  @override
  String get pleaseCheckYourInternetConnectionAndTryAgain =>
      'Моля, проверете интернет връзката си и опитайте отново.';

  @override
  String get verificationFailedPleaseTryAgain =>
      'Неуспешно проверка, моля опитайте отново';

  @override
  String get recreatePasswordTitle => 'Създайте отново парола';

  @override
  String get recreatePasswordBody =>
      'Текущото устройство не е достатъчно мощно, за да потвърди паролата Ви, но можем да я регенерираме по начин, който работи с всички устройства.\n\nМоля, влезте с Вашия ключ за възстановяване и генерирайте отново паролата си (можете да използвате същата отново, ако желаете).';

  @override
  String get useRecoveryKey => 'Използвайте ключ за възстановяване';

  @override
  String get forgotPassword => 'Забравена парола';

  @override
  String get changeEmail => 'Промяна на имейл';

  @override
  String get verifyEmail => 'Потвърдете имейла';

  @override
  String weHaveSendEmailTo(String email) {
    return 'Изпратихме имейл до <green>$email</green>';
  }

  @override
  String get toResetVerifyEmail =>
      'За да нулирате паролата си, моля, първо потвърдете своя имейл.';

  @override
  String get checkInboxAndSpamFolder =>
      'Моля, проверете входящата си поща (и спама), за да завършите проверката';

  @override
  String get tapToEnterCode => 'Докоснете, за да въведете код';

  @override
  String get sendEmail => 'Изпратете имейл';

  @override
  String get resendEmail => 'Повторно изпращане на имейл';

  @override
  String get passKeyPendingVerification => 'Потвърждението все още се изчаква';

  @override
  String get loginSessionExpired => 'Сесията изтече';

  @override
  String get loginSessionExpiredDetails =>
      'Вашата сесия изтече. Моля влезте отново.';

  @override
  String get passkeyAuthTitle => 'Удостоверяване с ключ за парола';

  @override
  String get waitingForVerification => 'Изчаква се потвърждение...';

  @override
  String get tryAgain => 'Опитайте отново';

  @override
  String get checkStatus => 'Проверка на състоянието';

  @override
  String get loginWithTOTP => 'Влизане с еднократен код';

  @override
  String get recoverAccount => 'Възстановяване на акаунт';

  @override
  String get setPasswordTitle => 'Задаване на парола';

  @override
  String get changePasswordTitle => 'Промяна на паролата';

  @override
  String get resetPasswordTitle => 'Нулиране на паролата';

  @override
  String get encryptionKeys => 'Ключове за шифроване';

  @override
  String get enterPasswordToEncrypt =>
      'Въведете парола, която да използваме за шифроване на Вашите данни';

  @override
  String get enterNewPasswordToEncrypt =>
      'Въведете нова парола, която да използваме за шифроване на Вашите данни';

  @override
  String get passwordWarning =>
      'Ние не съхраняваме тази парола, така че ако я забравите, <underline>не можем да дешифрираме Вашите данни</underline>';

  @override
  String get howItWorks => 'Как работи';

  @override
  String get generatingEncryptionKeys =>
      'Генериране на ключове за шифроване...';

  @override
  String get passwordChangedSuccessfully => 'Паролата е променена успешно';

  @override
  String get signOutFromOtherDevices => 'Излизане от други устройства';

  @override
  String get signOutOtherBody =>
      'Ако смятате, че някой може да знае паролата Ви, можете да принудите всички други устройства, използващи Вашия акаунт, да излязат.';

  @override
  String get signOutOtherDevices => 'Излизане от други устройства';

  @override
  String get doNotSignOut => 'Не излизайте';

  @override
  String get generatingEncryptionKeysTitle =>
      'Генерират се ключове за шифроване...';

  @override
  String get continueLabel => 'Продължете';

  @override
  String get insecureDevice => 'Несигурно устройство';

  @override
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease =>
      'За съжаление не можахме да генерираме защитени ключове на това устройство.\n\nМоля, регистрирайте се от друго устройство.';

  @override
  String get recoveryKeyCopiedToClipboard =>
      'Ключът за възстановяване е копиран в буферната памет';

  @override
  String get recoveryKey => 'Ключ за възстановяване';

  @override
  String get recoveryKeyOnForgotPassword =>
      'Ако забравите паролата си, единственият начин да възстановите данните си е с този ключ.';

  @override
  String get recoveryKeySaveDescription =>
      'Ние не съхраняваме този ключ, моля, запазете този ключ от 24 думи на сигурно място.';

  @override
  String get doThisLater => 'Направете това по-късно';

  @override
  String get saveKey => 'Запазване на ключа';

  @override
  String get recoveryKeySaved =>
      'Ключът за възстановяване е запазен в папка за Изтегляния!';

  @override
  String get noRecoveryKeyTitle => 'Няма ключ за възстановяване?';

  @override
  String get twoFactorAuthTitle => 'Двуфакторно удостоверяване';

  @override
  String get enterCodeHint =>
      'Въведете 6-цифрения код от\nВашето приложение за удостоверяване';

  @override
  String get lostDeviceTitle => 'Загубено устройство?';

  @override
  String get enterRecoveryKeyHint => 'Въведете Вашия ключ за възстановяване';

  @override
  String get recover => 'Възстановяване';

  @override
  String get loggingOut => 'Излизане от профила...';

  @override
  String get immediately => 'Незабавно';

  @override
  String get appLock => 'Заключване на приложението';

  @override
  String get autoLock => 'Автоматично заключване';

  @override
  String get noSystemLockFound => 'Не е намерено заключване на системата';

  @override
  String get deviceLockEnablePreSteps =>
      'За да активирате заключването на устройството, моля, задайте парола за устройството или заключване на екрана в системните настройки.';

  @override
  String get appLockDescription =>
      'Изберете между заключен екран по подразбиране на Вашето устройство и персонализиран заключен екран с ПИН код или парола.';

  @override
  String get deviceLock => 'Заключване на устройството';

  @override
  String get pinLock => 'Заключване с ПИН код';

  @override
  String get autoLockFeatureDescription =>
      'Време, след което приложението се заключва, след като е поставено на заден план';

  @override
  String get hideContent => 'Скриване на съдържанието';

  @override
  String get hideContentDescriptionAndroid =>
      'Скрива съдържанието на приложението в превключвателя на приложения и деактивира екранните снимки';

  @override
  String get hideContentDescriptioniOS =>
      'Скрива съдържанието на приложението в превключвателя на приложения';

  @override
  String get tooManyIncorrectAttempts => 'Твърде много неуспешни опити';

  @override
  String get tapToUnlock => 'Докоснете, за да отключите';

  @override
  String get areYouSureYouWantToLogout =>
      'Наистина ли искате да излезете от профила си?';

  @override
  String get yesLogout => 'Да, излез';

  @override
  String get authToViewSecrets =>
      'Моля, удостоверете се, за да видите Вашите кодове';

  @override
  String get next => 'Следващ';

  @override
  String get setNewPassword => 'Задаване на нова парола';

  @override
  String get enterPin => 'Въведете ПИН код';

  @override
  String get setNewPin => 'Задаване на нов ПИН код';

  @override
  String get confirm => 'Потвърждаване';

  @override
  String get reEnterPassword => 'Въведете отново паролата';

  @override
  String get reEnterPin => 'Въведете отново ПИН кода';

  @override
  String get androidBiometricHint => 'Потвърждаване на самоличността';

  @override
  String get androidBiometricNotRecognized =>
      'Не е разпознат. Опитайте отново.';

  @override
  String get androidBiometricSuccess => 'Успешно';

  @override
  String get androidCancelButton => 'Отказ';

  @override
  String get androidSignInTitle => 'Необходимо е удостоверяване';

  @override
  String get androidBiometricRequiredTitle => 'Изискват се биометрични данни';

  @override
  String get androidDeviceCredentialsRequiredTitle =>
      'Изискват се идентификационни данни за устройството';

  @override
  String get androidDeviceCredentialsSetupDescription =>
      'Изискват се идентификационни данни за устройството';

  @override
  String get goToSettings => 'Отваряне на настройките';

  @override
  String get androidGoToSettingsDescription =>
      'Биометричното удостоверяване не е настроено на Вашето устройство. Отидете на „Настройки > Сигурност“, за да добавите биометрично удостоверяване.';

  @override
  String get iOSLockOut =>
      'Биометричното удостоверяване е деактивирано. Моля, заключете и отключете екрана си, за да го активирате.';

  @override
  String get iOSOkButton => 'ОК';

  @override
  String get emailAlreadyRegistered => 'Имейлът вече е регистриран.';

  @override
  String get emailNotRegistered => 'Имейлът не е регистриран.';

  @override
  String get thisEmailIsAlreadyInUse => 'Този имейл вече се използва';

  @override
  String emailChangedTo(String newEmail) {
    return 'Имейлът е променен на $newEmail';
  }

  @override
  String get authenticationFailedPleaseTryAgain =>
      'Неуспешно удостоверяване, моля опитайте отново';

  @override
  String get authenticationSuccessful => 'Успешно удостоверяване!';

  @override
  String get sessionExpired => 'Сесията е изтекла';

  @override
  String get incorrectRecoveryKey => 'Неправилен ключ за възстановяване';

  @override
  String get theRecoveryKeyYouEnteredIsIncorrect =>
      'Въведеният от Вас ключ за възстановяване е неправилен';

  @override
  String get twofactorAuthenticationSuccessfullyReset =>
      'Двуфакторното удостоверяване бе успешно нулирано';

  @override
  String get noRecoveryKey => 'No recovery key';

  @override
  String get yourAccountHasBeenDeleted => 'Your account has been deleted';

  @override
  String get verificationId => 'Verification ID';

  @override
  String get yourVerificationCodeHasExpired =>
      'Вашият код за потвърждение е изтекъл';

  @override
  String get incorrectCode => 'Неправилен код';

  @override
  String get sorryTheCodeYouveEnteredIsIncorrect =>
      'За съжаление кодът, който сте въвели, е неправилен';

  @override
  String get developerSettings => 'Настройки за програмисти';

  @override
  String get serverEndpoint => 'Крайна точка на сървъра';

  @override
  String get invalidEndpoint => 'Невалидна крайна точка';

  @override
  String get invalidEndpointMessage =>
      'За съжаление въведената от Вас крайна точка е невалидна. Моля, въведете валидна крайна точка и опитайте отново.';

  @override
  String get endpointUpdatedMessage => 'Крайната точка е актуализирана успешно';
}
