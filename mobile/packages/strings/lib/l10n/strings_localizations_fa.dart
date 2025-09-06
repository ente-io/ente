// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class StringsLocalizationsFa extends StringsLocalizations {
  StringsLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get networkHostLookUpErr =>
      'Unable to connect to Ente, please check your network settings and contact support if the error persists.';

  @override
  String get networkConnectionRefusedErr =>
      'Unable to connect to Ente, please retry after sometime. If the error persists, please contact support.';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      'به نظر می‌رسد مشکلی پیش آمده است. لطفا بعد از مدتی دوباره تلاش کنید. اگر همچنان با خطا مواجه می‌شوید، لطفا با تیم پشتیبانی ما ارتباط برقرار کنید.';

  @override
  String get error => 'خطا';

  @override
  String get ok => 'تایید';

  @override
  String get faq => 'سوالات متداول';

  @override
  String get contactSupport => 'ارتباط با پشتیبانی';

  @override
  String get emailYourLogs => 'لاگ‌های خود را ایمیل کنید';

  @override
  String pleaseSendTheLogsTo(String toEmail) {
    return 'لطفا لاگ‌ها را به ایمیل زیر ارسال کنید \n$toEmail';
  }

  @override
  String get copyEmailAddress => 'کپی آدرس ایمیل';

  @override
  String get exportLogs => 'صدور لاگ‌ها';

  @override
  String get cancel => 'لغو';

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
  String get reportABug => 'گزارش یک اشکال';

  @override
  String get logsDialogBody =>
      'This will send across logs to help us debug your issue. Please note that file names will be included to help track issues with specific files.';

  @override
  String get viewLogs => 'View logs';

  @override
  String customEndpoint(String endpoint) {
    return 'متصل شده به $endpoint';
  }

  @override
  String get save => 'ذخیره';

  @override
  String get send => 'ارسال';

  @override
  String get saveOrSendDescription =>
      'Do you want to save this to your storage (Downloads folder by default) or send it to other apps?';

  @override
  String get saveOnlyDescription =>
      'Do you want to save this to your storage (Downloads folder by default)?';

  @override
  String get enterNewEmailHint => 'Enter your new email address';

  @override
  String get email => 'ایمیل';

  @override
  String get verify => 'تایید';

  @override
  String get invalidEmailTitle => 'آدرس ایمیل نامعتبر است';

  @override
  String get invalidEmailMessage => 'لطفا یک آدرس ایمیل معتبر وارد کنید.';

  @override
  String get pleaseWait => 'لطفا صبر کنید...';

  @override
  String get verifyPassword => 'تایید رمز عبور';

  @override
  String get incorrectPasswordTitle => 'رمز عبور نادرست';

  @override
  String get pleaseTryAgain => 'لطفا دوباره تلاش کنید';

  @override
  String get enterPassword => 'رمز عبور را وارد کنید';

  @override
  String get enterYourPasswordHint => 'رمز عبور خود را وارد کنید';

  @override
  String get activeSessions => 'نشست های فعال';

  @override
  String get oops => 'اوه';

  @override
  String get somethingWentWrongPleaseTryAgain =>
      'مشکلی پیش آمده، لطفا دوباره تلاش کنید';

  @override
  String get thisWillLogYouOutOfThisDevice =>
      'این کار شما را از این دستگاه خارج می‌کند!';

  @override
  String get thisWillLogYouOutOfTheFollowingDevice =>
      'با این کار شما از دستگاه زیر خارج می‌شوید:';

  @override
  String get terminateSession => 'خروچ دستگاه؟';

  @override
  String get terminate => 'خروج';

  @override
  String get thisDevice => 'این دستگاه';

  @override
  String get createAccount => 'ایجاد حساب کاربری';

  @override
  String get weakStrength => 'ضعیف';

  @override
  String get moderateStrength => 'متوسط';

  @override
  String get strongStrength => 'قوی';

  @override
  String get deleteAccount => 'حذف حساب کاربری';

  @override
  String get deleteAccountQuery =>
      'از رفتن شما متاسفیم. آیا با مشکلی روبرو هستید؟';

  @override
  String get yesSendFeedbackAction => 'بله، ارسال بازخورد';

  @override
  String get noDeleteAccountAction => 'خیر، حساب کاربری را حذف کن';

  @override
  String get initiateAccountDeleteTitle =>
      'لطفا جهت شروع فرآیند حذف حساب کاربری، اعتبارسنجی کنید';

  @override
  String get confirmAccountDeleteTitle => 'تایید حذف حساب کاربری';

  @override
  String get confirmAccountDeleteMessage =>
      'This account is linked to other Ente apps, if you use any.\n\nYour uploaded data, across all Ente apps, will be scheduled for deletion, and your account will be permanently deleted.';

  @override
  String get delete => 'حذف';

  @override
  String get createNewAccount => 'ایجاد حساب کاربری جدید';

  @override
  String get password => 'رمز عبور';

  @override
  String get confirmPassword => 'تایید رمز عبور';

  @override
  String passwordStrength(String passwordStrengthValue) {
    return 'قدرت رمز عبور: $passwordStrengthValue';
  }

  @override
  String get hearUsWhereTitle => 'از کجا در مورد Ente شنیدی؟ (اختیاری)';

  @override
  String get hearUsExplanation =>
      'ما نصب برنامه را ردیابی نمی‌کنیم. اگر بگویید کجا ما را پیدا کردید، به ما کمک می‌کند!';

  @override
  String get signUpTerms =>
      'با <u-terms>شرایط استفاده از خدمات</u-terms> و <u-policy>سیاست حفظ حریم خصوصی</u-policy> موافقت می‌کنم';

  @override
  String get termsOfServicesTitle => 'شرایط و ضوابط';

  @override
  String get privacyPolicyTitle => 'سیاست حفظ حریم خصوصی';

  @override
  String get ackPasswordLostWarning =>
      'می‌دانم که اگر رمز عبور خود را گم کنم، از آنجایی که اطلاعات من <underline>رمزگذاری سرتاسری</underline> شده است، ممکن است اطلاعاتم را از دست بدهم.';

  @override
  String get encryption => 'رمزگذاری';

  @override
  String get logInLabel => 'ورود';

  @override
  String get welcomeBack => 'خوش آمدید!';

  @override
  String get loginTerms =>
      'با کلیک روی ورود، با <u-terms>شرایط استفاده از خدمات</u-terms> و <u-policy>سیاست حفظ حریم خصوصی</u-policy> موافقت می‌کنم';

  @override
  String get noInternetConnection => 'نبود اتصال اینترنت';

  @override
  String get pleaseCheckYourInternetConnectionAndTryAgain =>
      'لطفا اتصال اینترنت خود را بررسی کنید و دوباره امتحان کنید.';

  @override
  String get verificationFailedPleaseTryAgain =>
      'تایید ناموفق بود، لطفا مجددا تلاش کنید';

  @override
  String get recreatePasswordTitle => 'بازتولید رمز عبور';

  @override
  String get recreatePasswordBody =>
      'دستگاه فعلی جهت تایید رمز عبور شما به اندازه کافی قدرتمند نیست، اما ما میتوانیم آن را به گونه ای بازتولید کنیم که با همه دستگاه‌ها کار کند.\n\nلطفا با استفاده از کلید بازیابی خود وارد شوید و رمز عبور خود را دوباره ایجاد کنید (در صورت تمایل می‌توانید دوباره از همان رمز عبور استفاده کنید).';

  @override
  String get useRecoveryKey => 'از کلید بازیابی استفاده کنید';

  @override
  String get forgotPassword => 'فراموشی رمز عبور';

  @override
  String get changeEmail => 'تغییر ایمیل';

  @override
  String get verifyEmail => 'تایید ایمیل';

  @override
  String weHaveSendEmailTo(String email) {
    return 'ما یک ایمیل به <green>$email</green> ارسال کرده‌ایم';
  }

  @override
  String get toResetVerifyEmail =>
      'برای تنظیم مجدد رمز عبور، لطفا ابتدا ایمیل خود را تایید کنید.';

  @override
  String get checkInboxAndSpamFolder =>
      'لطفا صندوق ورودی (و هرزنامه) خود را برای تایید کامل بررسی کنید';

  @override
  String get tapToEnterCode => 'برای وارد کردن کد ضربه بزنید';

  @override
  String get sendEmail => 'ارسال ایمیل';

  @override
  String get resendEmail => 'ارسال مجدد ایمیل';

  @override
  String get passKeyPendingVerification => 'تأییدیه هنوز در انتظار است';

  @override
  String get loginSessionExpired => 'نشست منقضی شده است';

  @override
  String get loginSessionExpiredDetails =>
      'نشست شما منقضی شده. لطفا دوباره وارد شوید.';

  @override
  String get passkeyAuthTitle => 'تایید کردن پسکی';

  @override
  String get waitingForVerification => 'درانتظار تأییدیه...';

  @override
  String get tryAgain => 'دوباره امتحان کنید';

  @override
  String get checkStatus => 'بررسی وضعیت';

  @override
  String get loginWithTOTP => 'Login with TOTP';

  @override
  String get recoverAccount => 'بازیابی حساب کاربری';

  @override
  String get setPasswordTitle => 'تنظیم پسورد';

  @override
  String get changePasswordTitle => 'تغییر رمز عبور';

  @override
  String get resetPasswordTitle => 'بازنشانی رمز عبور';

  @override
  String get encryptionKeys => 'کلیدهای رمزنگاری';

  @override
  String get enterPasswordToEncrypt =>
      'رمز عبوری را وارد کنید که بتوانیم از آن برای رمزگذاری اطلاعات شما استفاده کنیم';

  @override
  String get enterNewPasswordToEncrypt =>
      'رمز عبور جدیدی را وارد کنید که بتوانیم از آن برای رمزگذاری اطلاعات شما استفاده کنیم';

  @override
  String get passwordWarning =>
      'We don\'t store this password, so if you forget, <underline>we cannot decrypt your data</underline>';

  @override
  String get howItWorks => 'چگونه کار می‌کند';

  @override
  String get generatingEncryptionKeys => 'در حال تولید کلیدهای رمزگذاری...';

  @override
  String get passwordChangedSuccessfully => 'رمز عبور با موفقیت تغییر کرد';

  @override
  String get signOutFromOtherDevices => 'از دستگاه های دیگر خارج شوید';

  @override
  String get signOutOtherBody =>
      'If you think someone might know your password, you can force all other devices using your account to sign out.';

  @override
  String get signOutOtherDevices => 'از دستگاه های دیگر خارج شوید';

  @override
  String get doNotSignOut => 'خارج نشوید';

  @override
  String get generatingEncryptionKeysTitle =>
      'در حال تولید کلید‌های رمزگذاری...';

  @override
  String get continueLabel => 'ادامه';

  @override
  String get insecureDevice => 'دستگاه ناامن';

  @override
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease =>
      'با عرض پوزش، ما نمی‌توانیم کلیدهای امن را در این دستگاه تولید کنیم.\n\nلطفا از دستگاه دیگری ثبت نام کنید.';

  @override
  String get recoveryKeyCopiedToClipboard =>
      'کلید بازیابی به حافظه موقت کپی شد';

  @override
  String get recoveryKey => 'کلید بازیابی';

  @override
  String get recoveryKeyOnForgotPassword =>
      'اگر رمز عبور خود را فراموش کرده‌اید، این کد تنها راهی است که با آن می‌توانید اطلاعات خود را بازیابی کنید.';

  @override
  String get recoveryKeySaveDescription =>
      'ما این کلید را ذخیره نمی‌کنیم، لطفا این کلید ۲۴ کلمه‌ای را در مکانی امن ذخیره کنید.';

  @override
  String get doThisLater => 'بعداً انجام شود';

  @override
  String get saveKey => 'ذخیره کلید';

  @override
  String get recoveryKeySaved => 'Recovery key saved in Downloads folder!';

  @override
  String get noRecoveryKeyTitle => 'کلید بازیابی ندارید؟';

  @override
  String get twoFactorAuthTitle => 'احراز هویت دو مرحله‌ای';

  @override
  String get enterCodeHint =>
      'کد تایید ۶ رقمی را از برنامه\nاحراز هویت خود وارد کنید';

  @override
  String get lostDeviceTitle => 'دستگاه را گم کرده‌اید؟';

  @override
  String get enterRecoveryKeyHint => 'کلید بازیابی خود را وارد کنید';

  @override
  String get recover => 'بازیابی';

  @override
  String get loggingOut => 'در حال خروج از سیستم...';

  @override
  String get immediately => 'فوری';

  @override
  String get appLock => 'قفل برنامه';

  @override
  String get autoLock => 'قفل خودکار';

  @override
  String get noSystemLockFound => 'هیج قبل سیستمی پیدا نشد';

  @override
  String get deviceLockEnablePreSteps =>
      'To enable device lock, please setup device passcode or screen lock in your system settings.';

  @override
  String get appLockDescription =>
      'Choose between your device\'s default lock screen and a custom lock screen with a PIN or password.';

  @override
  String get deviceLock => 'قفل دستگاه';

  @override
  String get pinLock => 'پین قفل';

  @override
  String get autoLockFeatureDescription =>
      'Time after which the app locks after being put in the background';

  @override
  String get hideContent => 'پنهان کردن محتوا';

  @override
  String get hideContentDescriptionAndroid =>
      'Hides app content in the app switcher and disables screenshots';

  @override
  String get hideContentDescriptioniOS =>
      'Hides app content in the app switcher';

  @override
  String get tooManyIncorrectAttempts => 'Too many incorrect attempts';

  @override
  String get tapToUnlock => 'برای باز کردن قفل ضربه بزنید';

  @override
  String get areYouSureYouWantToLogout => 'آیا مطمئنید که می‌خواهید خارج شوید؟';

  @override
  String get yesLogout => 'بله، خروج';

  @override
  String get authToViewSecrets => 'لطفا جهت دیدن راز های خود احراز هویت کنید';

  @override
  String get next => 'بعدی';

  @override
  String get setNewPassword => 'Set new password';

  @override
  String get enterPin => 'پین را وارد کنید';

  @override
  String get setNewPin => 'پین جدید انتخاب کنید';

  @override
  String get confirm => 'تایید';

  @override
  String get reEnterPassword => 'رمز عبور را مجدداً وارد کنید';

  @override
  String get reEnterPin => 'پین را مجدداً وارد کنید';

  @override
  String get androidBiometricHint => 'تایید هویت';

  @override
  String get androidBiometricNotRecognized => 'شناخته نشد. دوباره امتحان کنید.';

  @override
  String get androidBiometricSuccess => 'موفقیت';

  @override
  String get androidCancelButton => 'لغو';

  @override
  String get androidSignInTitle => 'احراز هویت لازم است';

  @override
  String get androidBiometricRequiredTitle => 'بیومتریک لازم است';

  @override
  String get androidDeviceCredentialsRequiredTitle => 'اعتبار دستگاه لازم است';

  @override
  String get androidDeviceCredentialsSetupDescription =>
      'اعتبار دستگاه لازم است';

  @override
  String get goToSettings => 'به تنظیمات بروید';

  @override
  String get androidGoToSettingsDescription =>
      'Biometric authentication is not set up on your device. Go to \'Settings > Security\' to add biometric authentication.';

  @override
  String get iOSLockOut =>
      'Biometric authentication is disabled. Please lock and unlock your screen to enable it.';

  @override
  String get iOSOkButton => 'تأیید';

  @override
  String get emailAlreadyRegistered => 'Email already registered.';

  @override
  String get emailNotRegistered => 'Email not registered.';

  @override
  String get thisEmailIsAlreadyInUse => 'این ایمیل درحال استفاده است';

  @override
  String emailChangedTo(String newEmail) {
    return 'ایمیل عوض شد به $newEmail';
  }

  @override
  String get authenticationFailedPleaseTryAgain =>
      'احراز هویت ناموفق بود، لطفا دوباره تلاش کنید';

  @override
  String get authenticationSuccessful => 'احراز هویت موفق آمیز!';

  @override
  String get sessionExpired => 'نشست منقضی شده است';

  @override
  String get incorrectRecoveryKey => 'کلید بازیابی درست نیست';

  @override
  String get theRecoveryKeyYouEnteredIsIncorrect =>
      'کلید بازیابی که وارد کردید درست نیست';

  @override
  String get twofactorAuthenticationSuccessfullyReset =>
      'احراز هویت دو مرحله با موفقیت بازنشانی شد';

  @override
  String get noRecoveryKey => 'No recovery key';

  @override
  String get yourAccountHasBeenDeleted => 'Your account has been deleted';

  @override
  String get verificationId => 'Verification ID';

  @override
  String get yourVerificationCodeHasExpired => 'کد تایید شما باطل شد';

  @override
  String get incorrectCode => 'کد اشتباه';

  @override
  String get sorryTheCodeYouveEnteredIsIncorrect =>
      'معظرت میخوام، کدی که شما وارد کردید اشتباه است';

  @override
  String get developerSettings => 'Developer settings';

  @override
  String get serverEndpoint => 'Server endpoint';

  @override
  String get invalidEndpoint => 'Invalid endpoint';

  @override
  String get invalidEndpointMessage =>
      'Sorry, the endpoint you entered is invalid. Please enter a valid endpoint and try again.';

  @override
  String get endpointUpdatedMessage => 'Endpoint updated successfully';
}
