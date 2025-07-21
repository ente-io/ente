// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class StringsLocalizationsZh extends StringsLocalizations {
  StringsLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get networkHostLookUpErr => '无法连接到 Ente，请检查您的网络设置，如果错误仍然存​​在，请联系支持。';

  @override
  String get networkConnectionRefusedErr =>
      '无法连接到 Ente，请稍后重试。如果错误仍然存​​在，请联系支持人员。';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      '看起来出了点问题。 请稍后重试。 如果错误仍然存在，请联系我们的支持团队。';

  @override
  String get error => '错误';

  @override
  String get ok => '确定';

  @override
  String get faq => '常见问题';

  @override
  String get contactSupport => '联系支持';

  @override
  String get emailYourLogs => '通过电子邮件发送您的日志';

  @override
  String pleaseSendTheLogsTo(String toEmail) {
    return '请将日志发送至 \n$toEmail';
  }

  @override
  String get copyEmailAddress => '复制电子邮件地址';

  @override
  String get exportLogs => '导出日志';

  @override
  String get cancel => '取消';

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
  String get reportABug => '报告错误';

  @override
  String get logsDirectoryName => 'logs';

  @override
  String get logsZipFileName => 'logs.zip';

  @override
  String get zipFileExtension => 'zip';

  @override
  String get reportABug => 'Report a bug';

  @override
  String get logsDialogBody =>
      'This will send across logs to help us debug your issue. Please note that file names will be included to help track issues with specific files.';

  @override
  String get viewLogs => 'View logs';

  @override
  String customEndpoint(String endpoint) {
    return 'Connected to $endpoint';
  }

  @override
  String get save => '保存';

  @override
  String get send => '发送';

  @override
  String get saveOrSendDescription =>
      '您想将其保存到您的内置存储（默认情况下为“下载”文件夹）还是将其发送到其他应用程序？';

  @override
  String get saveOnlyDescription =>
      'Do you want to save this to your storage (Downloads folder by default)?';

  @override
  String get enterNewEmailHint => 'Enter your new email address';

  @override
  String get email => 'Email';

  @override
  String get verify => 'Verify';

  @override
  String get invalidEmailTitle => 'Invalid email address';

  @override
  String get invalidEmailMessage => 'Please enter a valid email address.';

  @override
  String get pleaseWait => 'Please wait...';

  @override
  String get verifyPassword => 'Verify password';

  @override
  String get incorrectPasswordTitle => 'Incorrect password';

  @override
  String get pleaseTryAgain => 'Please try again';

  @override
  String get enterPassword => 'Enter password';

  @override
  String get enterYourPasswordHint => 'Enter your password';

  @override
  String get activeSessions => 'Active sessions';

  @override
  String get oops => 'Oops';

  @override
  String get somethingWentWrongPleaseTryAgain =>
      'Something went wrong, please try again';

  @override
  String get thisWillLogYouOutOfThisDevice =>
      'This will log you out of this device!';

  @override
  String get thisWillLogYouOutOfTheFollowingDevice =>
      'This will log you out of the following device:';

  @override
  String get terminateSession => 'Terminate session?';

  @override
  String get terminate => 'Terminate';

  @override
  String get thisDevice => 'This device';

  @override
  String get createAccount => 'Create account';

  @override
  String get weakStrength => 'Weak';

  @override
  String get moderateStrength => 'Moderate';

  @override
  String get strongStrength => 'Strong';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountQuery =>
      'We\'ll be sorry to see you go. Are you facing some issue?';

  @override
  String get yesSendFeedbackAction => 'Yes, send feedback';

  @override
  String get noDeleteAccountAction => 'No, delete account';

  @override
  String get initiateAccountDeleteTitle =>
      'Please authenticate to initiate account deletion';

  @override
  String get confirmAccountDeleteTitle => 'Confirm account deletion';

  @override
  String get confirmAccountDeleteMessage =>
      'This account is linked to other Ente apps, if you use any.\n\nYour uploaded data, across all Ente apps, will be scheduled for deletion, and your account will be permanently deleted.';

  @override
  String get delete => 'Delete';

  @override
  String get createNewAccount => 'Create new account';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String passwordStrength(String passwordStrengthValue) {
    return 'Password strength: $passwordStrengthValue';
  }

  @override
  String get hearUsWhereTitle => 'How did you hear about Ente? (optional)';

  @override
  String get hearUsExplanation =>
      'We don\'t track app installs. It\'d help if you told us where you found us!';

  @override
  String get signUpTerms =>
      'I agree to the <u-terms>terms of service</u-terms> and <u-policy>privacy policy</u-policy>';

  @override
  String get termsOfServicesTitle => 'Terms';

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get ackPasswordLostWarning =>
      'I understand that if I lose my password, I may lose my data since my data is <underline>end-to-end encrypted</underline>.';

  @override
  String get encryption => 'Encryption';

  @override
  String get logInLabel => 'Log in';

  @override
  String get welcomeBack => 'Welcome back!';

  @override
  String get loginTerms =>
      'By clicking log in, I agree to the <u-terms>terms of service</u-terms> and <u-policy>privacy policy</u-policy>';

  @override
  String get noInternetConnection => 'No internet connection';

  @override
  String get pleaseCheckYourInternetConnectionAndTryAgain =>
      'Please check your internet connection and try again.';

  @override
  String get verificationFailedPleaseTryAgain =>
      'Verification failed, please try again';

  @override
  String get recreatePasswordTitle => 'Recreate password';

  @override
  String get recreatePasswordBody =>
      'The current device is not powerful enough to verify your password, but we can regenerate in a way that works with all devices.\n\nPlease login using your recovery key and regenerate your password (you can use the same one again if you wish).';

  @override
  String get useRecoveryKey => 'Use recovery key';

  @override
  String get forgotPassword => 'Forgot password';

  @override
  String get changeEmail => 'Change email';

  @override
  String get verifyEmail => 'Verify email';

  @override
  String weHaveSendEmailTo(String email) {
    return 'We have sent a mail to <green>$email</green>';
  }

  @override
  String get toResetVerifyEmail =>
      'To reset your password, please verify your email first.';

  @override
  String get checkInboxAndSpamFolder =>
      'Please check your inbox (and spam) to complete verification';

  @override
  String get tapToEnterCode => 'Tap to enter code';

  @override
  String get sendEmail => 'Send email';

  @override
  String get resendEmail => 'Resend email';

  @override
  String get passKeyPendingVerification => 'Verification is still pending';

  @override
  String get loginSessionExpired => 'Session expired';

  @override
  String get loginSessionExpiredDetails =>
      'Your session has expired. Please login again.';

  @override
  String get passkeyAuthTitle => 'Passkey verification';

  @override
  String get waitingForVerification => 'Waiting for verification...';

  @override
  String get tryAgain => 'Try again';

  @override
  String get checkStatus => 'Check status';

  @override
  String get loginWithTOTP => 'Login with TOTP';

  @override
  String get recoverAccount => 'Recover account';

  @override
  String get setPasswordTitle => 'Set password';

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get resetPasswordTitle => 'Reset password';

  @override
  String get encryptionKeys => 'Encryption keys';

  @override
  String get enterPasswordToEncrypt =>
      'Enter a password we can use to encrypt your data';

  @override
  String get enterNewPasswordToEncrypt =>
      'Enter a new password we can use to encrypt your data';

  @override
  String get passwordWarning =>
      'We don\'t store this password, so if you forget, <underline>we cannot decrypt your data</underline>';

  @override
  String get howItWorks => 'How it works';

  @override
  String get generatingEncryptionKeys => 'Generating encryption keys...';

  @override
  String get passwordChangedSuccessfully => 'Password changed successfully';

  @override
  String get signOutFromOtherDevices => 'Sign out from other devices';

  @override
  String get signOutOtherBody =>
      'If you think someone might know your password, you can force all other devices using your account to sign out.';

  @override
  String get signOutOtherDevices => 'Sign out other devices';

  @override
  String get doNotSignOut => 'Do not sign out';

  @override
  String get generatingEncryptionKeysTitle => 'Generating encryption keys...';

  @override
  String get continueLabel => 'Continue';

  @override
  String get insecureDevice => 'Insecure device';

  @override
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease =>
      'Sorry, we could not generate secure keys on this device.\n\nplease sign up from a different device.';

  @override
  String get recoveryKeyCopiedToClipboard => 'Recovery key copied to clipboard';

  @override
  String get recoveryKey => 'Recovery key';

  @override
  String get recoveryKeyOnForgotPassword =>
      'If you forget your password, the only way you can recover your data is with this key.';

  @override
  String get recoveryKeySaveDescription =>
      'We don\'t store this key, please save this 24 word key in a safe place.';

  @override
  String get doThisLater => 'Do this later';

  @override
  String get saveKey => 'Save key';

  @override
  String get recoveryKeySaved => 'Recovery key saved in Downloads folder!';

  @override
  String get noRecoveryKeyTitle => 'No recovery key?';

  @override
  String get twoFactorAuthTitle => 'Two-factor authentication';

  @override
  String get enterCodeHint =>
      'Enter the 6-digit code from\nyour authenticator app';

  @override
  String get lostDeviceTitle => 'Lost device?';

  @override
  String get enterRecoveryKeyHint => 'Enter your recovery key';

  @override
  String get recover => 'Recover';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class StringsLocalizationsZhTw extends StringsLocalizationsZh {
  StringsLocalizationsZhTw() : super('zh_TW');

  @override
  String get networkHostLookUpErr => '無法連接到 Ente，請檢查您的網路設定，如果錯誤仍然存​​在，請聯絡支援。';

  @override
  String get networkConnectionRefusedErr =>
      '無法連接到 Ente，請稍後重試。如果錯誤仍然存​​在，請聯絡支援人員。';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      '看起來出了點問題。 請稍後重試。 如果錯誤仍然存在，請聯絡我們的支援團隊。';

  @override
  String get error => '錯誤';

  @override
  String get ok => '確定';

  @override
  String get faq => '常見問題';

  @override
  String get contactSupport => '聯絡支援';

  @override
  String get emailYourLogs => '通過電子郵件傳送您的日誌';

  @override
  String pleaseSendTheLogsTo(String toEmail) {
    return '請將日誌傳送至 \n$toEmail';
  }

  @override
  String get copyEmailAddress => '複製電子郵件地址';

  @override
  String get exportLogs => '匯出日誌';

  @override
  String get cancel => '取消';

  @override
  String get reportABug => '報告錯誤';

  @override
  String customEndpoint(String endpoint) {
    return '已連接至 $endpoint';
  }

  @override
  String get save => '儲存';

  @override
  String get send => '傳送';

  @override
  String get saveOrSendDescription =>
      '您想將其儲存到您的內建儲存（預設情況下為“下載”資料夾）還是將其傳送到其他APP？';

  @override
  String get saveOnlyDescription => '您想將其儲存到您的內建儲存中（預設情況下為“下載”資料夾）嗎？';

  @override
  String get enterNewEmailHint => '輸入你的新電子郵件地址';

  @override
  String get email => '電子郵件地址';

  @override
  String get verify => '驗證';

  @override
  String get invalidEmailTitle => '無效的電子郵件地址';

  @override
  String get invalidEmailMessage => '請輸入一個有效的電子郵件地址。';

  @override
  String get pleaseWait => '請稍候...';

  @override
  String get verifyPassword => '驗證密碼';

  @override
  String get incorrectPasswordTitle => '密碼錯誤';

  @override
  String get pleaseTryAgain => '請重試';

  @override
  String get enterPassword => '輸入密碼';

  @override
  String get enterYourPasswordHint => '輸入您的密碼';

  @override
  String get activeSessions => '已登錄的裝置';

  @override
  String get oops => '哎呀';

  @override
  String get somethingWentWrongPleaseTryAgain => '出了點問題，請重試';

  @override
  String get thisWillLogYouOutOfThisDevice => '這將使您登出該裝置！';

  @override
  String get thisWillLogYouOutOfTheFollowingDevice => '這將使您登出以下裝置：';

  @override
  String get terminateSession => '是否終止工作階段？';

  @override
  String get terminate => '終止';

  @override
  String get thisDevice => '此裝置';

  @override
  String get createAccount => '建立帳戶';

  @override
  String get weakStrength => '弱';

  @override
  String get moderateStrength => '中';

  @override
  String get strongStrength => '強';

  @override
  String get deleteAccount => '刪除帳戶';

  @override
  String get deleteAccountQuery => '我們很抱歉看到您要刪除帳戶。您似乎面臨著一些問題？';

  @override
  String get yesSendFeedbackAction => '是，傳送回饋';

  @override
  String get noDeleteAccountAction => '否，刪除帳戶';

  @override
  String get initiateAccountDeleteTitle => '請進行身份驗證以啟動帳戶刪除';

  @override
  String get confirmAccountDeleteTitle => '確認刪除帳戶';

  @override
  String get confirmAccountDeleteMessage =>
      '如果您使用其他 Ente APP，該帳戶將會與其他APP連結。\n\n在所有 Ente APP中，您上傳的資料將被安排用於刪除，並且您的帳戶將被永久刪除。';

  @override
  String get delete => '刪除';

  @override
  String get createNewAccount => '建立新帳號';

  @override
  String get password => '密碼';

  @override
  String get confirmPassword => '請確認密碼';

  @override
  String passwordStrength(String passwordStrengthValue) {
    return '密碼強度： $passwordStrengthValue';
  }

  @override
  String get hearUsWhereTitle => '您是怎麼知道 Ente 的？（可選）';

  @override
  String get hearUsExplanation => '我們不跟蹤APP安裝情況。如果您告訴我們您是在哪裡找到我們的，將會有所幫助！';

  @override
  String get signUpTerms =>
      '我同意 <u-terms>服務條款</u-terms> 和 <u-policy>隱私政策</u-policy>';

  @override
  String get termsOfServicesTitle => '服務條款';

  @override
  String get privacyPolicyTitle => '隱私政策';

  @override
  String get ackPasswordLostWarning =>
      '我明白，如果我遺失密碼，我可能會遺失我的資料，因為我的資料是 <underline>端到端加密的</underline>。';

  @override
  String get encryption => '加密';

  @override
  String get logInLabel => '登錄';

  @override
  String get welcomeBack => '歡迎回來！';

  @override
  String get loginTerms =>
      '點選登錄後，我同意 <u-terms>服務條款</u-terms> 和 <u-policy>隱私政策</u-policy>';

  @override
  String get noInternetConnection => '無網際網路連接';

  @override
  String get pleaseCheckYourInternetConnectionAndTryAgain =>
      '請檢查您的網際網路連接，然後重試。';

  @override
  String get verificationFailedPleaseTryAgain => '驗證失敗，請再試一次';

  @override
  String get recreatePasswordTitle => '重新建立密碼';

  @override
  String get recreatePasswordBody =>
      '目前裝置的功能不足以驗證您的密碼，但我們可以以適用於所有裝置的方式重新產生。\n\n請使用您的復原密鑰登錄並重新產生您的密碼（如果您願意，可以再次使用相同的密碼）。';

  @override
  String get useRecoveryKey => '使用復原密鑰';

  @override
  String get forgotPassword => '忘記密碼';

  @override
  String get changeEmail => '修改信箱';

  @override
  String get verifyEmail => '驗證電子郵件';

  @override
  String weHaveSendEmailTo(String email) {
    return '我們已經傳送郵件到 <green>$email</green>';
  }

  @override
  String get toResetVerifyEmail => '要重設您的密碼，請先驗證您的電子郵件。';

  @override
  String get checkInboxAndSpamFolder => '請檢查您的收件箱 (或者是在您的“垃圾郵件”列表內) 以完成驗證';

  @override
  String get tapToEnterCode => '點選以輸入程式碼';

  @override
  String get sendEmail => '傳送電子郵件';

  @override
  String get resendEmail => '重新傳送電子郵件';

  @override
  String get passKeyPendingVerification => '仍需驗證';

  @override
  String get loginSessionExpired => '工作階段已過期';

  @override
  String get loginSessionExpiredDetails => '您的工作階段已過期。請重新登錄。';

  @override
  String get passkeyAuthTitle => '通行金鑰驗證';

  @override
  String get waitingForVerification => '等待驗證...';

  @override
  String get tryAgain => '請再試一次';

  @override
  String get checkStatus => '檢查狀態';

  @override
  String get loginWithTOTP => '使用 TOTP 登錄';

  @override
  String get recoverAccount => '恢復帳戶';

  @override
  String get setPasswordTitle => '設定密碼';

  @override
  String get changePasswordTitle => '修改密碼';

  @override
  String get resetPasswordTitle => '重設密碼';

  @override
  String get encryptionKeys => '加密金鑰';

  @override
  String get enterPasswordToEncrypt => '輸入我們可以用來加密您的資料的密碼';

  @override
  String get enterNewPasswordToEncrypt => '輸入我們可以用來加密您的資料的新密碼';

  @override
  String get passwordWarning =>
      '我們不會儲存這個密碼，所以如果忘記， <underline>我們無法解密您的資料</underline>';

  @override
  String get howItWorks => '工作原理';

  @override
  String get generatingEncryptionKeys => '正在產生加密金鑰...';

  @override
  String get passwordChangedSuccessfully => '密碼修改成功';

  @override
  String get signOutFromOtherDevices => '從其他裝置登出';

  @override
  String get signOutOtherBody => '如果您認為有人可能知道您的密碼，您可以強制所有其他使用您帳戶的裝置登出。';

  @override
  String get signOutOtherDevices => '登出其他裝置';

  @override
  String get doNotSignOut => '不要登出';

  @override
  String get generatingEncryptionKeysTitle => '正在產生加密金鑰...';

  @override
  String get continueLabel => '繼續';

  @override
  String get insecureDevice => '裝置不安全';

  @override
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease =>
      '抱歉，我們無法在此裝置上產生安全金鑰。\n\n請使用其他裝置註冊。';

  @override
  String get recoveryKeyCopiedToClipboard => '復原密鑰已複製到剪貼簿';

  @override
  String get recoveryKey => '復原密鑰';

  @override
  String get recoveryKeyOnForgotPassword => '如果您忘記了密碼，恢復資料的唯一方法就是使用此金鑰。';

  @override
  String get recoveryKeySaveDescription => '我們不會儲存此金鑰，請將此24個單詞金鑰儲存在一個安全的地方。';

  @override
  String get doThisLater => '稍後再做';

  @override
  String get saveKey => '儲存金鑰';

  @override
  String get recoveryKeySaved => '復原密鑰已儲存在下載資料夾中！';

  @override
  String get noRecoveryKeyTitle => '沒有復原密鑰嗎？';

  @override
  String get twoFactorAuthTitle => '二步驟驗證';

  @override
  String get enterCodeHint => '從你的身份驗證器APP中\n輸入6位數字程式碼';

  @override
  String get lostDeviceTitle => '遺失了裝置嗎？';

  @override
  String get enterRecoveryKeyHint => '輸入您的復原密鑰';

  @override
  String get recover => '恢復';

  @override
  String get loggingOut => '正在登出...';

  @override
  String get immediately => '立即';

  @override
  String get appLock => 'APP鎖';

  @override
  String get autoLock => '自動鎖定';

  @override
  String get noSystemLockFound => '未找到系統鎖';

  @override
  String get deviceLockEnablePreSteps => '要啟用裝置鎖，請在系統設定中設定裝置密碼或螢幕鎖。';

  @override
  String get appLockDescription => '在裝置的預設鎖定螢幕和帶有 PIN 或密碼的自訂鎖定螢幕之間進行選擇。';

  @override
  String get deviceLock => '裝置鎖';

  @override
  String get pinLock => 'Pin 鎖定';

  @override
  String get autoLockFeatureDescription => 'APP進入後台後鎖定的時間';

  @override
  String get hideContent => '隱藏內容';

  @override
  String get hideContentDescriptionAndroid => '在APP切換器中隱藏APP內容並停用螢幕截圖';

  @override
  String get hideContentDescriptioniOS => '在APP切換器中隱藏APP內容';

  @override
  String get tooManyIncorrectAttempts => '錯誤的嘗試次數過多';

  @override
  String get tapToUnlock => '點選解鎖';

  @override
  String get areYouSureYouWantToLogout => '您確定要登出嗎？';

  @override
  String get yesLogout => '是的，登出';

  @override
  String get authToViewSecrets => '請進行身份驗證以查看您的金鑰';

  @override
  String get next => '下一步';

  @override
  String get setNewPassword => '設定新密碼';

  @override
  String get enterPin => '輸入 PIN 碼';

  @override
  String get setNewPin => '設定新 PIN 碼';

  @override
  String get confirm => '確認';

  @override
  String get reEnterPassword => '再次輸入密碼';

  @override
  String get reEnterPin => '再次輸入 PIN 碼';

  @override
  String get androidBiometricHint => '驗證身份';

  @override
  String get androidBiometricNotRecognized => '未能辨識，請重試。';

  @override
  String get androidBiometricSuccess => '成功';

  @override
  String get androidCancelButton => '取消';

  @override
  String get androidSignInTitle => '需要進行身份驗證';

  @override
  String get androidBiometricRequiredTitle => '需要進行生物辨識認證';

  @override
  String get androidDeviceCredentialsRequiredTitle => '需要裝置憑據';

  @override
  String get androidDeviceCredentialsSetupDescription => '需要裝置憑據';

  @override
  String get goToSettings => '前往設定';

  @override
  String get androidGoToSettingsDescription =>
      '您的裝置上未設定生物辨識身份驗證。轉到“設定 > 安全”以加入生物辨識身份驗證。';

  @override
  String get iOSLockOut => '生物辨識身份驗證已停用。請鎖定並解鎖螢幕以啟用該功能。';

  @override
  String get iOSOkButton => '好';

  @override
  String get emailAlreadyRegistered => '電子郵件地址已被註冊。';

  @override
  String get emailNotRegistered => '電子郵件地址未註冊。';

  @override
  String get thisEmailIsAlreadyInUse => '該電子郵件已被使用';

  @override
  String emailChangedTo(String newEmail) {
    return '電子郵件已更改為 $newEmail';
  }

  @override
  String get authenticationFailedPleaseTryAgain => '認證失敗，請重試';

  @override
  String get authenticationSuccessful => '認證成功！';

  @override
  String get sessionExpired => '工作階段已過期';

  @override
  String get incorrectRecoveryKey => '復原密鑰不正確';

  @override
  String get theRecoveryKeyYouEnteredIsIncorrect => '您輸入的復原密鑰不正確';

  @override
  String get twofactorAuthenticationSuccessfullyReset => '二步驟驗證已成功重設';

  @override
  String get yourVerificationCodeHasExpired => '您的驗證碼已過期';

  @override
  String get incorrectCode => '驗證碼錯誤';

  @override
  String get sorryTheCodeYouveEnteredIsIncorrect => '抱歉，您輸入的驗證碼不正確';

  @override
  String get developerSettings => '開發者設定';

  @override
  String get serverEndpoint => '伺服器端點';

  @override
  String get invalidEndpoint => '端點無效';

  @override
  String get invalidEndpointMessage => '抱歉，您輸入的端點無效。請輸入有效的端點，然後重試。';

  @override
  String get endpointUpdatedMessage => '端點更新成功';
}
