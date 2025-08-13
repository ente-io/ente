// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Serbian (`sr`).
class StringsLocalizationsSr extends StringsLocalizations {
  StringsLocalizationsSr([String locale = 'sr']) : super(locale);

  @override
  String get networkHostLookUpErr =>
      'Није могуће повезивање са Ente-ом, молимо вас да проверите мрежне поставке и контактирајте подршку ако грешка и даље постоји.';

  @override
  String get networkConnectionRefusedErr =>
      'Није могуће повезивање са Ente-ом, покушајте поново мало касније. Ако грешка настави, обратите се подршци.';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      'Изгледа да је нешто погрешно. Покушајте поново након неког времена. Ако грешка настави, обратите се нашем тиму за подршку.';

  @override
  String get error => 'Грешка';

  @override
  String get ok => 'У реду';

  @override
  String get faq => 'Питања';

  @override
  String get contactSupport => 'Контактирати подршку';

  @override
  String get emailYourLogs => 'Имејлирајте извештаје';

  @override
  String pleaseSendTheLogsTo(String toEmail) {
    return 'Пошаљите извештаје на \n$toEmail';
  }

  @override
  String get copyEmailAddress => 'Копирати имејл адресу';

  @override
  String get exportLogs => 'Извези изештаје';

  @override
  String get cancel => 'Откажи';

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
  String get reportABug => 'Пријави грешку';

  @override
  String get logsDialogBody =>
      'This will send across logs to help us debug your issue. Please note that file names will be included to help track issues with specific files.';

  @override
  String get viewLogs => 'View logs';

  @override
  String customEndpoint(String endpoint) {
    return 'Везано за $endpoint';
  }

  @override
  String get save => 'Сачувај';

  @override
  String get send => 'Пошаљи';

  @override
  String get saveOrSendDescription =>
      'Да ли желите да ово сачувате у складиште (фасцикли за преузимање подразумевано) или да га пошаљете другим апликацијама?';

  @override
  String get saveOnlyDescription =>
      'Да ли желите да ово сачувате у складиште (фасцикли за преузимање подразумевано)?';

  @override
  String get enterNewEmailHint => 'Унесите Ваш нови имејл';

  @override
  String get email => 'Имејл';

  @override
  String get verify => 'Верификуј';

  @override
  String get invalidEmailTitle => 'Погрешна имејл адреса';

  @override
  String get invalidEmailMessage => 'Унесите важећи имејл.';

  @override
  String get pleaseWait => 'Молимо сачекајте...';

  @override
  String get verifyPassword => 'Верификујте лозинку';

  @override
  String get incorrectPasswordTitle => 'Неисправна лозинка';

  @override
  String get pleaseTryAgain => 'Пробајте поново';

  @override
  String get enterPassword => 'Унеси лозинку';

  @override
  String get enterYourPasswordHint => 'Унесите лозинку';

  @override
  String get activeSessions => 'Активне сесије';

  @override
  String get oops => 'Упс';

  @override
  String get somethingWentWrongPleaseTryAgain =>
      'Нешто је пошло наопако. Покушајте поново';

  @override
  String get thisWillLogYouOutOfThisDevice =>
      'Ово ће вас одјавити из овог уређаја!';

  @override
  String get thisWillLogYouOutOfTheFollowingDevice =>
      'Ово ће вас одјавити из овог уређаја:';

  @override
  String get terminateSession => 'Прекинути сесију?';

  @override
  String get terminate => 'Прекини';

  @override
  String get thisDevice => 'Овај уређај';

  @override
  String get createAccount => 'Направи налог';

  @override
  String get weakStrength => 'Слабо';

  @override
  String get moderateStrength => 'Умерено';

  @override
  String get strongStrength => 'Јако';

  @override
  String get deleteAccount => 'Избриши налог';

  @override
  String get deleteAccountQuery =>
      'Жао нам је што одлазите. Да ли се суочавате са неком грешком?';

  @override
  String get yesSendFeedbackAction => 'Да, послати повратне информације';

  @override
  String get noDeleteAccountAction => 'Не, избрисати налог';

  @override
  String get initiateAccountDeleteTitle =>
      'Молимо вас да се аутентификујете за брисање рачуна';

  @override
  String get confirmAccountDeleteTitle => 'Потврда брисања рачуна';

  @override
  String get confirmAccountDeleteMessage =>
      'Овај налог је повезан са другим Ente апликацијама, ако користите било коју.\n\nВаши преношени подаци, на свим Ente апликацијама биће заказани за брисање, и ваш рачун ће се трајно избрисати.';

  @override
  String get delete => 'Обриши';

  @override
  String get createNewAccount => 'Креирај нови налог';

  @override
  String get password => 'Лозинка';

  @override
  String get confirmPassword => 'Потврдите лозинку';

  @override
  String passwordStrength(String passwordStrengthValue) {
    return 'Снага лозинке: $passwordStrengthValue';
  }

  @override
  String get hearUsWhereTitle => 'Како сте чули о Ente? (опционо)';

  @override
  String get hearUsExplanation =>
      'Не пратимо инсталацију апликације. Помогло би да нам кажеш како си нас нашао!';

  @override
  String get signUpTerms =>
      'Прихватам <u-terms>услове сервиса</u-terms> и <u-policy>политику приватности</u-policy>';

  @override
  String get termsOfServicesTitle => 'Услови';

  @override
  String get privacyPolicyTitle => 'Политика приватности';

  @override
  String get ackPasswordLostWarning =>
      'Разумем да ако изгубим лозинку, могу изгубити своје податке пошто су <underline>шифрирани од краја до краја</underline>.';

  @override
  String get encryption => 'Шифровање';

  @override
  String get logInLabel => 'Пријави се';

  @override
  String get welcomeBack => 'Добродошли назад!';

  @override
  String get loginTerms =>
      'Кликом на пријаву, прихватам <u-terms>услове сервиса</u-terms> и <u-policy>политику приватности</u-policy>';

  @override
  String get noInternetConnection => 'Нема интернет везе';

  @override
  String get pleaseCheckYourInternetConnectionAndTryAgain =>
      'Провери своју везу са интернетом и покушај поново.';

  @override
  String get verificationFailedPleaseTryAgain =>
      'Неуспешна верификација, покушајте поново';

  @override
  String get recreatePasswordTitle => 'Поново креирати лозинку';

  @override
  String get recreatePasswordBody =>
      'Тренутни уређај није довољно моћан да потврди вашу лозинку, али можемо регенерирати на начин који ради са свим уређајима.\n\nПријавите се помоћу кључа за опоравак и обновите своју лозинку (можете поново користити исту ако желите).';

  @override
  String get useRecoveryKey => 'Користите кључ за опоравак';

  @override
  String get forgotPassword => 'Заборавио сам лозинку';

  @override
  String get changeEmail => 'Промени имејл';

  @override
  String get verifyEmail => 'Потврди имејл';

  @override
  String weHaveSendEmailTo(String email) {
    return 'Послали смо имејл на <green>$email</green>';
  }

  @override
  String get toResetVerifyEmail =>
      'Да бисте ресетовали лозинку, прво потврдите свој имејл.';

  @override
  String get checkInboxAndSpamFolder =>
      'Молимо вас да проверите примљену пошту (и нежељену пошту) да бисте довршили верификацију';

  @override
  String get tapToEnterCode => 'Пипните да бисте унели кôд';

  @override
  String get sendEmail => 'Шаљи имејл';

  @override
  String get resendEmail => 'Поново послати имејл';

  @override
  String get passKeyPendingVerification => 'Верификација је још у току';

  @override
  String get loginSessionExpired => 'Сесија је истекла';

  @override
  String get loginSessionExpiredDetails =>
      'Ваша сесија је истекла. Молимо пријавите се поново.';

  @override
  String get passkeyAuthTitle => 'Верификација сигурносном кључем';

  @override
  String get waitingForVerification => 'Чека се верификација...';

  @override
  String get tryAgain => 'Покушај поново';

  @override
  String get checkStatus => 'Провери статус';

  @override
  String get loginWithTOTP => 'Пријава са TOTP';

  @override
  String get recoverAccount => 'Опоравак налога';

  @override
  String get setPasswordTitle => 'Постави лозинку';

  @override
  String get changePasswordTitle => 'Промени лозинку';

  @override
  String get resetPasswordTitle => 'Ресетуј лозинку';

  @override
  String get encryptionKeys => 'Кључеве шифровања';

  @override
  String get enterPasswordToEncrypt =>
      'Унесите лозинку за употребу за шифровање ваших података';

  @override
  String get enterNewPasswordToEncrypt =>
      'Унесите нову лозинку за употребу за шифровање ваших података';

  @override
  String get passwordWarning =>
      'Не чувамо ову лозинку, па ако је заборавите, <underline>не можемо дешифрирати ваше податке</underline>';

  @override
  String get howItWorks => 'Како то функционише';

  @override
  String get generatingEncryptionKeys => 'Генерисање кључева за шифровање...';

  @override
  String get passwordChangedSuccessfully => 'Лозинка је успешно промењена';

  @override
  String get signOutFromOtherDevices => 'Одјави се из других уређаја';

  @override
  String get signOutOtherBody =>
      'Ако мислиш да неко може знати твоју лозинку, можеш приморати одјављивање све остале уређаје које користе твој налог.';

  @override
  String get signOutOtherDevices => 'Одјави друге уређаје';

  @override
  String get doNotSignOut => 'Не одјави';

  @override
  String get generatingEncryptionKeysTitle =>
      'Генерисање кључева за шифровање...';

  @override
  String get continueLabel => 'Настави';

  @override
  String get insecureDevice => 'Уређај није сигуран';

  @override
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease =>
      'Извините, не можемо да генеришемо сигурне кључеве на овом уређају.\n\nМолимо пријавите се са другог уређаја.';

  @override
  String get recoveryKeyCopiedToClipboard =>
      'Кључ за опоравак копирано у остави';

  @override
  String get recoveryKey => 'Резервни Кључ';

  @override
  String get recoveryKeyOnForgotPassword =>
      'Ако заборавите лозинку, једини начин на који можете повратити податке је са овим кључем.';

  @override
  String get recoveryKeySaveDescription =>
      'Не чувамо овај кључ, молимо да сачувате кључ од 24 речи на сигурном месту.';

  @override
  String get doThisLater => 'Уради то касније';

  @override
  String get saveKey => 'Сачувај кључ';

  @override
  String get recoveryKeySaved =>
      'Кључ за опоравак сачуван у фасцикли за преузимање!';

  @override
  String get noRecoveryKeyTitle => 'Немате кључ за опоравак?';

  @override
  String get twoFactorAuthTitle => 'Дво-факторска аутентификација';

  @override
  String get enterCodeHint =>
      'Унесите 6-цифрени кôд из\nапликације за аутентификацију';

  @override
  String get lostDeviceTitle => 'Узгубили сте уређај?';

  @override
  String get enterRecoveryKeyHint => 'Унети кључ за опоравак';

  @override
  String get recover => 'Опорави';

  @override
  String get loggingOut => 'Одјављивање...';

  @override
  String get immediately => 'Одмах';

  @override
  String get appLock => 'Закључавање апликације';

  @override
  String get autoLock => 'Ауто-закључавање';

  @override
  String get noSystemLockFound => 'Није пронађено ниједно закључавање система';

  @override
  String get deviceLockEnablePreSteps =>
      'Да бисте омогућили закључавање уређаја, молимо вас да подесите шифру уређаја или закључавање екрана у системским подешавањима.';

  @override
  String get appLockDescription =>
      'Изаберите између заданог закључавање екрана вашег уређаја и прилагођени екран за закључавање са ПИН-ом или лозинком.';

  @override
  String get deviceLock => 'Закључавање уређаја';

  @override
  String get pinLock => 'ПИН клокирање';

  @override
  String get autoLockFeatureDescription =>
      'Време након којег се апликација блокира након што је постављенеа у позадину';

  @override
  String get hideContent => 'Сакриј садржај';

  @override
  String get hideContentDescriptionAndroid =>
      'Сакрива садржај апликације у пребацивање апликација и онемогућује снимке екрана';

  @override
  String get hideContentDescriptioniOS =>
      'Сакрива садржај апликације у пребацивање апликација';

  @override
  String get tooManyIncorrectAttempts => 'Превише погрешних покушаја';

  @override
  String get tapToUnlock => 'Додирните да бисте откључали';

  @override
  String get areYouSureYouWantToLogout => 'Да ли сте сигурни да се одјавите?';

  @override
  String get yesLogout => 'Да, одјави ме';

  @override
  String get authToViewSecrets =>
      'Аутентификујте се да бисте прегледали Ваше тајне';

  @override
  String get next => 'Следеће';

  @override
  String get setNewPassword => 'Постави нову лозинку';

  @override
  String get enterPin => 'Унеси ПИН';

  @override
  String get setNewPin => 'Постави нови ПИН';

  @override
  String get confirm => 'Потврди';

  @override
  String get reEnterPassword => 'Поново унеси лозинку';

  @override
  String get reEnterPin => 'Поново унеси ПИН';

  @override
  String get androidBiometricHint => 'Потврдите идентитет';

  @override
  String get androidBiometricNotRecognized =>
      'Нисмо препознали. Покушати поново.';

  @override
  String get androidBiometricSuccess => 'Успех';

  @override
  String get androidCancelButton => 'Откажи';

  @override
  String get androidSignInTitle => 'Потребна аутентификација';

  @override
  String get androidBiometricRequiredTitle => 'Потребна је биометрија';

  @override
  String get androidDeviceCredentialsRequiredTitle =>
      'Потребни су акредитиви уређаја';

  @override
  String get androidDeviceCredentialsSetupDescription =>
      'Потребни су акредитиви уређаја';

  @override
  String get goToSettings => 'Иди на поставке';

  @override
  String get androidGoToSettingsDescription =>
      'Биометријска аутентификација није постављена на вашем уређају. Идите на \"Подешавања> Сигурност\" да бисте додали биометријску аутентификацију.';

  @override
  String get iOSLockOut =>
      'Биометријска аутентификација је онемогућена. Закључајте и откључите екран да бисте је омогућили.';

  @override
  String get iOSOkButton => 'У реду';

  @override
  String get emailAlreadyRegistered => 'Имејл је већ регистрован.';

  @override
  String get emailNotRegistered => 'Имејл није регистрован.';

  @override
  String get thisEmailIsAlreadyInUse => 'Овај имејл је већ у употреби';

  @override
  String emailChangedTo(String newEmail) {
    return 'Имејл промењен на $newEmail';
  }

  @override
  String get authenticationFailedPleaseTryAgain =>
      'Аутентификација није успела, покушајте поново';

  @override
  String get authenticationSuccessful => 'Успешна аутентификација!';

  @override
  String get sessionExpired => 'Сесија је истекла';

  @override
  String get incorrectRecoveryKey => 'Нетачан кључ за опоравак';

  @override
  String get theRecoveryKeyYouEnteredIsIncorrect =>
      'Унети кључ за опоравак је натачан';

  @override
  String get twofactorAuthenticationSuccessfullyReset =>
      'Двофакторска аутентификација успешно рисетирана';

  @override
  String get noRecoveryKey => 'No recovery key';

  @override
  String get yourAccountHasBeenDeleted => 'Your account has been deleted';

  @override
  String get verificationId => 'Verification ID';

  @override
  String get yourVerificationCodeHasExpired =>
      'Ваш верификациони кôд је истекао';

  @override
  String get incorrectCode => 'Погрешан кôд';

  @override
  String get sorryTheCodeYouveEnteredIsIncorrect => 'Унет кôд није добар';

  @override
  String get developerSettings => 'Подешавања за програмере';

  @override
  String get serverEndpoint => 'Крајња тачка сервера';

  @override
  String get invalidEndpoint => 'Погрешна крајња тачка';

  @override
  String get invalidEndpointMessage =>
      'Извини, крајња тачка коју си унео је неважећа. Унеси важећу крајњу тачку и покушај поново.';

  @override
  String get endpointUpdatedMessage => 'Крајна тачка успешно ажурирана';
}
