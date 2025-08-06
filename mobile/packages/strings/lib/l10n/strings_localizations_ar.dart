// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class StringsLocalizationsAr extends StringsLocalizations {
  StringsLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get networkHostLookUpErr =>
      'تعذر الاتصال بـEnte، فضلا تحقق من إعدادات الشبكة الخاصة بك وتواصل مع الدعم إذا استمر الخطأ.';

  @override
  String get networkConnectionRefusedErr =>
      'تعذر الإتصال بـEnte، فضلا أعد المحاولة لاحقا. إذا استمر الخطأ، فضلا تواصل مع الدعم.';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      'يبدو أنه حدث خطأ ما. الرجاء إعادة المحاولة لاحقا. إذا استمر الخطأ، يرجى الاتصال بفريق الدعم.';

  @override
  String get error => 'خطأ';

  @override
  String get ok => 'حسناً';

  @override
  String get faq => 'الأسئلة الأكثر شيوعاً';

  @override
  String get contactSupport => 'الاتصال بالدعم';

  @override
  String get emailYourLogs => 'إرسال السجلات عبر البريد الإلكتروني';

  @override
  String pleaseSendTheLogsTo(String toEmail) {
    return 'الرجاء إرسال السجلات إلى $toEmail';
  }

  @override
  String get copyEmailAddress => 'نسخ عنوان البريد الإلكتروني';

  @override
  String get exportLogs => 'تصدير السجلات';

  @override
  String get cancel => 'إلغاء';

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
  String get reportABug => 'ألإبلاغ عن خلل تقني';

  @override
  String get logsDialogBody =>
      'This will send across logs to help us debug your issue. Please note that file names will be included to help track issues with specific files.';

  @override
  String get viewLogs => 'View logs';

  @override
  String customEndpoint(String endpoint) {
    return 'متصل بـ$endpoint';
  }

  @override
  String get save => 'حفظ';

  @override
  String get send => 'إرسال';

  @override
  String get saveOrSendDescription =>
      'هل تريد حفظه إلى السعة التخزينية الخاصة بك (مجلد التنزيلات افتراضيا) أم إرساله إلى تطبيقات أخرى؟';

  @override
  String get saveOnlyDescription =>
      'هل تريد حفظه إلى السعة التخزينية الخاصة بك (مجلد التنزيلات افتراضيا)؟';

  @override
  String get enterNewEmailHint => 'أدخل عنوان بريدك الإلكتروني الجديد';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get verify => 'التحقق';

  @override
  String get invalidEmailTitle => 'عنوان البريد الإلكتروني غير صالح';

  @override
  String get invalidEmailMessage => 'الرجاء إدخال بريد إلكتروني صالح.';

  @override
  String get pleaseWait => 'انتظر قليلاً...';

  @override
  String get verifyPassword => 'التحقق من كلمة المرور';

  @override
  String get incorrectPasswordTitle => 'كلمة المرور غير صحيحة';

  @override
  String get pleaseTryAgain => 'يرجى المحاولة مرة أخرى';

  @override
  String get enterPassword => 'أدخل كلمة المرور';

  @override
  String get enterYourPasswordHint => 'أدخل كلمة المرور الخاصة بك';

  @override
  String get activeSessions => 'الجلسات النشطة';

  @override
  String get oops => 'عذرًا';

  @override
  String get somethingWentWrongPleaseTryAgain =>
      'حدث خطأ ما، يرجى المحاولة مرة أخرى';

  @override
  String get thisWillLogYouOutOfThisDevice =>
      'سيؤدي هذا إلى تسجيل خروجك من هذا الجهاز!';

  @override
  String get thisWillLogYouOutOfTheFollowingDevice =>
      'سيؤدي هذا إلى تسجيل خروجك من هذا الجهاز:';

  @override
  String get terminateSession => 'إنهاء الجلسة؟';

  @override
  String get terminate => 'إنهاء';

  @override
  String get thisDevice => 'هذا الجهاز';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get weakStrength => 'ضعيف';

  @override
  String get moderateStrength => 'متوسط';

  @override
  String get strongStrength => 'قوي';

  @override
  String get deleteAccount => 'إزالة الحساب';

  @override
  String get deleteAccountQuery =>
      'سوف نأسف لرؤيتك تذهب. هل تواجه بعض المشاكل؟';

  @override
  String get yesSendFeedbackAction => 'نعم، ارسل الملاحظات';

  @override
  String get noDeleteAccountAction => 'لا، حذف الحساب';

  @override
  String get initiateAccountDeleteTitle => 'الرجاء المصادقة لبدء حذف الحساب';

  @override
  String get confirmAccountDeleteTitle => 'تأكيد حذف الحساب';

  @override
  String get confirmAccountDeleteMessage =>
      'هذا الحساب مرتبط بتطبيقات Ente أخرى، إذا كنت تستخدم أحدها.\n\nسنضع موعدا لحذف بياناتك المرفوعة عبر كل تطبيقات Ente، وسيتم حذف حسابك بصورة دائمة.';

  @override
  String get delete => 'حذف';

  @override
  String get createNewAccount => 'إنشاء حساب جديد';

  @override
  String get password => 'كلمة المرور';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String passwordStrength(String passwordStrengthValue) {
    return 'قوة كلمة المرور: $passwordStrengthValue';
  }

  @override
  String get hearUsWhereTitle => 'كيف سمعت عن Ente؟ (اختياري)';

  @override
  String get hearUsExplanation =>
      'نحن لا نتتبع تثبيت التطبيق. سيكون من المفيد إذا أخبرتنا أين وجدتنا!';

  @override
  String get signUpTerms =>
      'أوافق على <u-terms>شروط الخدمة</u-terms> و<u-policy>سياسة الخصوصية</u-policy>';

  @override
  String get termsOfServicesTitle => 'الشروط';

  @override
  String get privacyPolicyTitle => 'سياسة الخصوصية';

  @override
  String get ackPasswordLostWarning =>
      'أنا أفهم أنه إذا فقدت كلمة المرور الخاصة بي، قد أفقد بياناتي لأن بياناتي هي <underline>مشفرة من الند للند</underline>.';

  @override
  String get encryption => 'التشفير';

  @override
  String get logInLabel => 'تسجيل الدخول';

  @override
  String get welcomeBack => 'مرحبًا مجددًا!';

  @override
  String get loginTerms =>
      'بالنقر على تسجيل الدخول، أوافق على شروط الخدمة <u-terms></u-terms> و <u-policy>سياسة الخصوصية</u-policy>';

  @override
  String get noInternetConnection => 'لا يوجد اتصال بالإنترنت';

  @override
  String get pleaseCheckYourInternetConnectionAndTryAgain =>
      'يرجى التحقق من اتصالك بالإنترنت ثم المحاولة من جديد.';

  @override
  String get verificationFailedPleaseTryAgain =>
      'فشل في المصادقة ، يرجى المحاولة مرة أخرى في وقت لاحق';

  @override
  String get recreatePasswordTitle => 'إعادة كتابة كلمة المرور';

  @override
  String get recreatePasswordBody =>
      'الجهاز الحالي ليس قويًا بما يكفي للتحقق من كلمة المرور الخاصة بك، لذا نحتاج إلى إعادة إنشائها مرة واحدة بطريقة تعمل مع جميع الأجهزة.\n\nالرجاء تسجيل الدخول باستخدام مفتاح الاسترداد وإعادة إنشاء كلمة المرور الخاصة بك (يمكنك استخدام نفس كلمة المرور مرة أخرى إذا كنت ترغب في ذلك).';

  @override
  String get useRecoveryKey => 'استخدم مفتاح الاسترداد';

  @override
  String get forgotPassword => 'هل نسيت كلمة المرور';

  @override
  String get changeEmail => 'غير البريد الإلكتروني';

  @override
  String get verifyEmail => 'تأكيد البريد الإلكتروني';

  @override
  String weHaveSendEmailTo(String email) {
    return 'لقد أرسلنا رسالة إلى <green>$email</green>';
  }

  @override
  String get toResetVerifyEmail =>
      'لإعادة تعيين كلمة المرور الخاصة بك، يرجى التحقق من بريدك الإلكتروني أولاً.';

  @override
  String get checkInboxAndSpamFolder =>
      'الرجاء التحقق من صندوق الوارد (والرسائل غير المرغوب فيها) لإكمال التحقق';

  @override
  String get tapToEnterCode => 'انقر لإدخال الرمز';

  @override
  String get sendEmail => 'إرسال بريد إلكتروني';

  @override
  String get resendEmail => 'إعادة إرسال البريد الإلكتروني';

  @override
  String get passKeyPendingVerification => 'التحقق ما زال جارٍ';

  @override
  String get loginSessionExpired => 'انتهت صلاحية الجلسة';

  @override
  String get loginSessionExpiredDetails =>
      'انتهت صلاحية جلستك. فضلا أعد تسجيل الدخول.';

  @override
  String get passkeyAuthTitle => 'التحقق من مفتاح المرور';

  @override
  String get waitingForVerification => 'بانتظار التحقق...';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get checkStatus => 'تحقق من الحالة';

  @override
  String get loginWithTOTP => '';

  @override
  String get recoverAccount => 'إسترجاع الحساب';

  @override
  String get setPasswordTitle => 'تعيين كلمة المرور';

  @override
  String get changePasswordTitle => 'تغيير كلمة المرور';

  @override
  String get resetPasswordTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get encryptionKeys => 'مفاتيح التشفير';

  @override
  String get enterPasswordToEncrypt =>
      'أدخل كلمة المرور التي يمكننا استخدامها لتشفير بياناتك';

  @override
  String get enterNewPasswordToEncrypt =>
      'أدخل كلمة مرور جديدة يمكننا استخدامها لتشفير بياناتك';

  @override
  String get passwordWarning =>
      'نحن لا نقوم بتخزين كلمة المرور هذه، لذا إذا نسيتها، <underline>لا يمكننا فك تشفير بياناتك</underline>';

  @override
  String get howItWorks => 'كيف يعمل';

  @override
  String get generatingEncryptionKeys => 'توليد مفاتيح التشفير...';

  @override
  String get passwordChangedSuccessfully => 'تم تغيير كلمة المرور بنجاح';

  @override
  String get signOutFromOtherDevices => 'تسجيل الخروج من الأجهزة الأخرى';

  @override
  String get signOutOtherBody =>
      'إذا كنت تعتقد أن شخصا ما يعرف كلمة المرور الخاصة بك، يمكنك إجبار جميع الأجهزة الأخرى الستخدمة حاليا لحسابك على تسجيل الخروج.';

  @override
  String get signOutOtherDevices => 'تسجيل الخروج من الأجهزة الأخرى';

  @override
  String get doNotSignOut => 'لا تقم بتسجيل الخروج';

  @override
  String get generatingEncryptionKeysTitle => 'توليد مفاتيح التشفير...';

  @override
  String get continueLabel => 'المتابعة';

  @override
  String get insecureDevice => 'جهاز غير آمن';

  @override
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease =>
      'عذرًا، لم نتمكن من إنشاء مفاتيح آمنة على هذا الجهاز.\n\nيرجى التسجيل من جهاز مختلف.';

  @override
  String get recoveryKeyCopiedToClipboard => 'تم نسخ عبارة الاسترداد للحافظة';

  @override
  String get recoveryKey => 'مفتاح الاسترداد';

  @override
  String get recoveryKeyOnForgotPassword =>
      'إذا نسيت كلمة المرور الخاصة بك، فالطريقة الوحيدة التي يمكنك بها استرداد بياناتك هي بهذا المفتاح.';

  @override
  String get recoveryKeySaveDescription =>
      'نحن لا نخزن هذا المفتاح، يرجى حفظ مفتاح الـ 24 كلمة هذا في مكان آمن.';

  @override
  String get doThisLater => 'قم بهذا لاحقاً';

  @override
  String get saveKey => 'حفظ المفتاح';

  @override
  String get recoveryKeySaved => 'حُفِظ مفتاح الاستعادة في مجلد التنزيلات!';

  @override
  String get noRecoveryKeyTitle => 'لا يوجد مفتاح استرجاع؟';

  @override
  String get twoFactorAuthTitle => 'المصادقة الثنائية';

  @override
  String get enterCodeHint => 'أدخل الرمز المكون من 6 أرقام من\nتطبيق المصادقة';

  @override
  String get lostDeviceTitle => 'جهاز مفقود ؟';

  @override
  String get enterRecoveryKeyHint => 'أدخل رمز الاسترداد';

  @override
  String get recover => 'استرداد';

  @override
  String get loggingOut => 'جاري تسجيل الخروج...';

  @override
  String get immediately => 'فورًا';

  @override
  String get appLock => 'قُفْل التطبيق';

  @override
  String get autoLock => 'قفل تلقائي';

  @override
  String get noSystemLockFound => 'لا يوجد قفل نظام';

  @override
  String get deviceLockEnablePreSteps =>
      'لتفعيل قُفْل الجهاز، اضبط رمز مرور أو قُفْل الشاشة من الإعدادات';

  @override
  String get appLockDescription => 'اختر نوع قُفْل الشاشة: افتراضي أو مخصص.';

  @override
  String get deviceLock => 'قفل الجهاز';

  @override
  String get pinLock => 'قفل رقم التعريف الشخصي';

  @override
  String get autoLockFeatureDescription =>
      'الوقت الذي بعده ينقفل التطبيق بعدما يوضع في الخلفية';

  @override
  String get hideContent => 'أخفِ المحتوى';

  @override
  String get hideContentDescriptionAndroid =>
      'يخفي محتوى التطبيق في مبدل التطبيقات ويمنع لقطات الشاشة';

  @override
  String get hideContentDescriptioniOS =>
      'يخفي محتوى التطبيق في مبدل التطبيقات';

  @override
  String get tooManyIncorrectAttempts => 'محاولات خاطئة أكثر من المسموح';

  @override
  String get tapToUnlock => 'المس لإلغاء القفل';

  @override
  String get areYouSureYouWantToLogout =>
      'هل أنت متأكد من أنك تريد تسجيل الخروج؟';

  @override
  String get yesLogout => 'نعم، تسجيل الخروج';

  @override
  String get authToViewSecrets =>
      'الرجاء المصادقة لعرض مفتاح الاسترداد الخاص بك';

  @override
  String get next => 'التالي';

  @override
  String get setNewPassword => 'عين كلمة مرور جديدة';

  @override
  String get enterPin => 'أدخل رقم التعريف الشخصي';

  @override
  String get setNewPin => 'عين رقم تعريف شخصي جديد';

  @override
  String get confirm => 'تأكيد';

  @override
  String get reEnterPassword => 'أعد إدخال كلمة المرور';

  @override
  String get reEnterPin => 'أعد إدخال رقم التعريف الشخصي';

  @override
  String get androidBiometricHint => 'التحقق من الهوية';

  @override
  String get androidBiometricNotRecognized =>
      'لم يتم التعرف عليه. حاول مرة أخرى.';

  @override
  String get androidBiometricSuccess => 'تم بنجاح';

  @override
  String get androidCancelButton => 'إلغاء';

  @override
  String get androidSignInTitle => 'المصادقة مطلوبة';

  @override
  String get androidBiometricRequiredTitle => 'البيومترية مطلوبة';

  @override
  String get androidDeviceCredentialsRequiredTitle =>
      'بيانات اعتماد الجهاز مطلوبة';

  @override
  String get androidDeviceCredentialsSetupDescription =>
      'بيانات اعتماد الجهاز مطلوبة';

  @override
  String get goToSettings => 'الانتقال إلى الإعدادات';

  @override
  String get androidGoToSettingsDescription =>
      'لم يتم إعداد المصادقة الحيوية على جهازك. انتقل إلى \'الإعدادات > الأمن\' لإضافة المصادقة البيومترية.';

  @override
  String get iOSLockOut =>
      'المصادقة البيومترية معطلة. الرجاء قفل الشاشة وفتح القفل لتفعيلها.';

  @override
  String get iOSOkButton => 'حسناً';

  @override
  String get emailAlreadyRegistered => 'البريد الإلكتروني مُسَجَّل من قبل.';

  @override
  String get emailNotRegistered => 'البريد الإلكتروني غير مُسَجَّل.';

  @override
  String get thisEmailIsAlreadyInUse => 'هذا البريد مستخدم مسبقاً';

  @override
  String emailChangedTo(String newEmail) {
    return 'تم تغيير البريد الإلكتروني إلى $newEmail';
  }

  @override
  String get authenticationFailedPleaseTryAgain =>
      'فشلت المصادقة. الرجاء المحاولة مرة أخرى';

  @override
  String get authenticationSuccessful => 'تمت المصادقة بنجاح!';

  @override
  String get sessionExpired => 'انتهت صَلاحِيَة الجِلسة';

  @override
  String get incorrectRecoveryKey => 'مفتاح الاسترداد غير صحيح';

  @override
  String get theRecoveryKeyYouEnteredIsIncorrect =>
      'مفتاح الاسترداد الذي أدخلته غير صحيح';

  @override
  String get twofactorAuthenticationSuccessfullyReset =>
      'تم تحديث المصادقة الثنائية بنجاح';

  @override
  String get noRecoveryKey => 'No recovery key';

  @override
  String get yourAccountHasBeenDeleted => 'Your account has been deleted';

  @override
  String get verificationId => 'Verification ID';

  @override
  String get yourVerificationCodeHasExpired => 'انتهت صلاحية رمز التحقق';

  @override
  String get incorrectCode => 'رمز غير صحيح';

  @override
  String get sorryTheCodeYouveEnteredIsIncorrect =>
      'عذراً، الرمز الذي أدخلته غير صحيح';

  @override
  String get developerSettings => 'اعدادات المطور';

  @override
  String get serverEndpoint => 'نقطة طرف الخادم';

  @override
  String get invalidEndpoint => 'نقطة طرف غير صالحة';

  @override
  String get invalidEndpointMessage =>
      'عذرا، نقطة الطرف التي أدخلتها غير صالحة. فضلا أدخل نقطة طرف صالحة وأعد المحاولة.';

  @override
  String get endpointUpdatedMessage => 'حُدِّثَت نقطة الطرف بنجاح';
}
