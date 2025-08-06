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
  String get logsDialogBody =>
      'This will send across logs to help us debug your issue. Please note that file names will be included to help track issues with specific files.';

  @override
  String get viewLogs => 'View logs';

  @override
  String customEndpoint(String endpoint) {
    return '已连接至 $endpoint';
  }

  @override
  String get save => '保存';

  @override
  String get send => '发送';

  @override
  String get saveOrSendDescription =>
      '您想将其保存到您的内置存储（默认情况下为“下载”文件夹）还是将其发送到其他应用程序？';

  @override
  String get saveOnlyDescription => '您想将其保存到您的内置存储中（默认情况下为“下载”文件夹）吗？';

  @override
  String get enterNewEmailHint => 'Enter your new email address';

  @override
  String get email => '电子邮件地址';

  @override
  String get verify => '验证';

  @override
  String get invalidEmailTitle => '无效的电子邮件地址';

  @override
  String get invalidEmailMessage => '请输入一个有效的电子邮件地址。';

  @override
  String get pleaseWait => '请稍候...';

  @override
  String get verifyPassword => '验证密码';

  @override
  String get incorrectPasswordTitle => '密码错误';

  @override
  String get pleaseTryAgain => '请重试';

  @override
  String get enterPassword => '输入密码';

  @override
  String get enterYourPasswordHint => '输入您的密码';

  @override
  String get activeSessions => '已登录的设备';

  @override
  String get oops => '哎呀';

  @override
  String get somethingWentWrongPleaseTryAgain => '出了点问题，请重试';

  @override
  String get thisWillLogYouOutOfThisDevice => '这将使您登出该设备！';

  @override
  String get thisWillLogYouOutOfTheFollowingDevice => '这将使您登出以下设备：';

  @override
  String get terminateSession => '是否终止会话？';

  @override
  String get terminate => '终止';

  @override
  String get thisDevice => '此设备';

  @override
  String get createAccount => '创建账户';

  @override
  String get weakStrength => '弱';

  @override
  String get moderateStrength => '中';

  @override
  String get strongStrength => '强';

  @override
  String get deleteAccount => '删除账户';

  @override
  String get deleteAccountQuery => '我们很抱歉看到您离开。您面临一些问题？';

  @override
  String get yesSendFeedbackAction => '是，发送反馈';

  @override
  String get noDeleteAccountAction => '否，删除账户';

  @override
  String get initiateAccountDeleteTitle => '请进行身份验证以启动账户删除';

  @override
  String get confirmAccountDeleteTitle => '确认删除账户';

  @override
  String get confirmAccountDeleteMessage =>
      '如果您使用其他 Ente 应用程序，该账户将会与其他应用程序链接。\n\n在所有 Ente 应用程序中，您上传的数据将被安排用于删除，并且您的账户将被永久删除。';

  @override
  String get delete => '删除';

  @override
  String get createNewAccount => '创建新账号';

  @override
  String get password => '密码';

  @override
  String get confirmPassword => '请确认密码';

  @override
  String passwordStrength(String passwordStrengthValue) {
    return '密码强度： $passwordStrengthValue';
  }

  @override
  String get hearUsWhereTitle => '您是怎么知道 Ente 的？（可选）';

  @override
  String get hearUsExplanation => '我们不跟踪应用程序安装情况。如果您告诉我们您是在哪里找到我们的，将会有所帮助！';

  @override
  String get signUpTerms =>
      '我同意 <u-terms>服务条款</u-terms> 和 <u-policy>隐私政策</u-policy>';

  @override
  String get termsOfServicesTitle => '服务条款';

  @override
  String get privacyPolicyTitle => '隐私政策';

  @override
  String get ackPasswordLostWarning =>
      '我明白，如果我丢失密码，我可能会丢失我的数据，因为我的数据是 <underline>端到端加密的</underline>。';

  @override
  String get encryption => '加密';

  @override
  String get logInLabel => '登录';

  @override
  String get welcomeBack => '欢迎回来！';

  @override
  String get loginTerms =>
      '点击登录后，我同意 <u-terms>服务条款</u-terms> 和 <u-policy>隐私政策</u-policy>';

  @override
  String get noInternetConnection => '无互联网连接';

  @override
  String get pleaseCheckYourInternetConnectionAndTryAgain => '请检查您的互联网连接，然后重试。';

  @override
  String get verificationFailedPleaseTryAgain => '验证失败，请再试一次';

  @override
  String get recreatePasswordTitle => '重新创建密码';

  @override
  String get recreatePasswordBody =>
      '当前设备的功能不足以验证您的密码，但我们可以以适用于所有设备的方式重新生成。\n\n请使用您的恢复密钥登录并重新生成您的密码（如果您愿意，可以再次使用相同的密码）。';

  @override
  String get useRecoveryKey => '使用恢复密钥';

  @override
  String get forgotPassword => '忘记密码';

  @override
  String get changeEmail => '修改邮箱';

  @override
  String get verifyEmail => '验证电子邮件';

  @override
  String weHaveSendEmailTo(String email) {
    return '我们已经发送邮件到 <green>$email</green>';
  }

  @override
  String get toResetVerifyEmail => '要重置您的密码，请先验证您的电子邮件。';

  @override
  String get checkInboxAndSpamFolder => '请检查您的收件箱 (或者是在您的“垃圾邮件”列表内) 以完成验证';

  @override
  String get tapToEnterCode => '点击以输入代码';

  @override
  String get sendEmail => '发送电子邮件';

  @override
  String get resendEmail => '重新发送电子邮件';

  @override
  String get passKeyPendingVerification => '仍需验证';

  @override
  String get loginSessionExpired => '会话已过期';

  @override
  String get loginSessionExpiredDetails => '您的会话已过期。请重新登录。';

  @override
  String get passkeyAuthTitle => '通行密钥验证';

  @override
  String get waitingForVerification => '等待验证...';

  @override
  String get tryAgain => '请再试一次';

  @override
  String get checkStatus => '检查状态';

  @override
  String get loginWithTOTP => '使用 TOTP 登录';

  @override
  String get recoverAccount => '恢复账户';

  @override
  String get setPasswordTitle => '设置密码';

  @override
  String get changePasswordTitle => '修改密码';

  @override
  String get resetPasswordTitle => '重置密码';

  @override
  String get encryptionKeys => '加密密钥';

  @override
  String get enterPasswordToEncrypt => '输入我们可以用来加密您的数据的密码';

  @override
  String get enterNewPasswordToEncrypt => '输入我们可以用来加密您的数据的新密码';

  @override
  String get passwordWarning =>
      '我们不储存这个密码，所以如果忘记， <underline>我们不能解密您的数据</underline>';

  @override
  String get howItWorks => '工作原理';

  @override
  String get generatingEncryptionKeys => '正在生成加密密钥...';

  @override
  String get passwordChangedSuccessfully => '密码修改成功';

  @override
  String get signOutFromOtherDevices => '从其他设备登出';

  @override
  String get signOutOtherBody => '如果您认为有人可能知道您的密码，您可以强制所有其他使用您账户的设备登出。';

  @override
  String get signOutOtherDevices => '登出其他设备';

  @override
  String get doNotSignOut => '不要登出';

  @override
  String get generatingEncryptionKeysTitle => '正在生成加密密钥...';

  @override
  String get continueLabel => '继续';

  @override
  String get insecureDevice => '设备不安全';

  @override
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease =>
      '抱歉，我们无法在此设备上生成安全密钥。\n\n请使用其他设备注册。';

  @override
  String get recoveryKeyCopiedToClipboard => '恢复密钥已复制到剪贴板';

  @override
  String get recoveryKey => '恢复密钥';

  @override
  String get recoveryKeyOnForgotPassword => '如果您忘记了密码，恢复数据的唯一方法就是使用此密钥。';

  @override
  String get recoveryKeySaveDescription => '我们不会存储此密钥，请将此24个单词密钥保存在一个安全的地方。';

  @override
  String get doThisLater => '稍后再做';

  @override
  String get saveKey => '保存密钥';

  @override
  String get recoveryKeySaved => '恢复密钥已保存在下载文件夹中！';

  @override
  String get noRecoveryKeyTitle => '没有恢复密钥吗？';

  @override
  String get twoFactorAuthTitle => '两步验证';

  @override
  String get enterCodeHint => '从你的身份验证器应用中\n输入6位数字代码';

  @override
  String get lostDeviceTitle => '丢失了设备吗？';

  @override
  String get enterRecoveryKeyHint => '输入您的恢复密钥';

  @override
  String get recover => '恢复';

  @override
  String get loggingOut => '正在登出...';

  @override
  String get immediately => '立即';

  @override
  String get appLock => '应用锁';

  @override
  String get autoLock => '自动锁定';

  @override
  String get noSystemLockFound => '未找到系统锁';

  @override
  String get deviceLockEnablePreSteps => '要启用设备锁，请在系统设置中设置设备密码或屏幕锁。';

  @override
  String get appLockDescription => '在设备的默认锁定屏幕和带有 PIN 或密码的自定义锁定屏幕之间进行选择。';

  @override
  String get deviceLock => '设备锁';

  @override
  String get pinLock => 'Pin 锁定';

  @override
  String get autoLockFeatureDescription => '应用程序进入后台后锁定的时间';

  @override
  String get hideContent => '隐藏内容';

  @override
  String get hideContentDescriptionAndroid => '在应用切换器中隐藏应用内容并禁用屏幕截图';

  @override
  String get hideContentDescriptioniOS => '在应用切换器中隐藏应用内容';

  @override
  String get tooManyIncorrectAttempts => '错误的尝试次数过多';

  @override
  String get tapToUnlock => '点击解锁';

  @override
  String get areYouSureYouWantToLogout => '您确定要登出吗？';

  @override
  String get yesLogout => '是的，登出';

  @override
  String get authToViewSecrets => '请进行身份验证以查看您的密钥';

  @override
  String get next => '下一步';

  @override
  String get setNewPassword => '设置新密码';

  @override
  String get enterPin => '输入 PIN 码';

  @override
  String get setNewPin => '设置新 PIN 码';

  @override
  String get confirm => '确认';

  @override
  String get reEnterPassword => '再次输入密码';

  @override
  String get reEnterPin => '再次输入 PIN 码';

  @override
  String get androidBiometricHint => '验证身份';

  @override
  String get androidBiometricNotRecognized => '未能识别，请重试。';

  @override
  String get androidBiometricSuccess => '成功';

  @override
  String get androidCancelButton => '取消';

  @override
  String get androidSignInTitle => '需要进行身份验证';

  @override
  String get androidBiometricRequiredTitle => '需要进行生物识别认证';

  @override
  String get androidDeviceCredentialsRequiredTitle => '需要设备凭据';

  @override
  String get androidDeviceCredentialsSetupDescription => '需要设备凭据';

  @override
  String get goToSettings => '前往设置';

  @override
  String get androidGoToSettingsDescription =>
      '您的设备上未设置生物识别身份验证。转到“设置 > 安全”以添加生物识别身份验证。';

  @override
  String get iOSLockOut => '生物识别身份验证已禁用。请锁定并解锁屏幕以启用该功能。';

  @override
  String get iOSOkButton => '好';

  @override
  String get emailAlreadyRegistered => '电子邮件地址已被注册。';

  @override
  String get emailNotRegistered => '电子邮件地址未注册。';

  @override
  String get thisEmailIsAlreadyInUse => '该电子邮件已被使用';

  @override
  String emailChangedTo(String newEmail) {
    return '电子邮件已更改为 $newEmail';
  }

  @override
  String get authenticationFailedPleaseTryAgain => '认证失败，请重试';

  @override
  String get authenticationSuccessful => '认证成功！';

  @override
  String get sessionExpired => '会话已过期';

  @override
  String get incorrectRecoveryKey => '恢复密钥不正确';

  @override
  String get theRecoveryKeyYouEnteredIsIncorrect => '您输入的恢复密钥不正确';

  @override
  String get twofactorAuthenticationSuccessfullyReset => '两步验证已成功重置';

  @override
  String get noRecoveryKey => 'No recovery key';

  @override
  String get yourAccountHasBeenDeleted => 'Your account has been deleted';

  @override
  String get verificationId => 'Verification ID';

  @override
  String get yourVerificationCodeHasExpired => '您的验证码已过期';

  @override
  String get incorrectCode => '验证码错误';

  @override
  String get sorryTheCodeYouveEnteredIsIncorrect => '抱歉，您输入的验证码不正确';

  @override
  String get developerSettings => '开发者设置';

  @override
  String get serverEndpoint => '服务器端点';

  @override
  String get invalidEndpoint => '端点无效';

  @override
  String get invalidEndpointMessage => '抱歉，您输入的端点无效。请输入有效的端点，然后重试。';

  @override
  String get endpointUpdatedMessage => '端点更新成功';
}

/// The translations for Chinese, as used in China (`zh_CN`).
class StringsLocalizationsZhCn extends StringsLocalizationsZh {
  StringsLocalizationsZhCn() : super('zh_CN');

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
  String get reportABug => '报告错误';

  @override
  String customEndpoint(String endpoint) {
    return '已连接至 $endpoint';
  }

  @override
  String get save => '保存';

  @override
  String get send => '发送';

  @override
  String get saveOrSendDescription =>
      '您想将其保存到您的内置存储（默认情况下为“下载”文件夹）还是将其发送到其他应用程序？';

  @override
  String get saveOnlyDescription => '您想将其保存到您的内置存储中（默认情况下为“下载”文件夹）吗？';

  @override
  String get enterNewEmailHint => '请输入您的新电子邮件地址';

  @override
  String get email => '电子邮件地址';

  @override
  String get verify => '验证';

  @override
  String get invalidEmailTitle => '无效的电子邮件地址';

  @override
  String get invalidEmailMessage => '请输入一个有效的电子邮件地址。';

  @override
  String get pleaseWait => '请稍候...';

  @override
  String get verifyPassword => '验证密码';

  @override
  String get incorrectPasswordTitle => '密码错误';

  @override
  String get pleaseTryAgain => '请重试';

  @override
  String get enterPassword => '输入密码';

  @override
  String get enterYourPasswordHint => '输入您的密码';

  @override
  String get activeSessions => '已登录的设备';

  @override
  String get oops => '哎呀';

  @override
  String get somethingWentWrongPleaseTryAgain => '出了点问题，请重试';

  @override
  String get thisWillLogYouOutOfThisDevice => '这将使您登出该设备！';

  @override
  String get thisWillLogYouOutOfTheFollowingDevice => '这将使您登出以下设备：';

  @override
  String get terminateSession => '是否终止会话？';

  @override
  String get terminate => '终止';

  @override
  String get thisDevice => '此设备';

  @override
  String get createAccount => '创建账户';

  @override
  String get weakStrength => '弱';

  @override
  String get moderateStrength => '中';

  @override
  String get strongStrength => '强';

  @override
  String get deleteAccount => '删除账户';

  @override
  String get deleteAccountQuery => '我们很抱歉看到您离开。您面临一些问题？';

  @override
  String get yesSendFeedbackAction => '是，发送反馈';

  @override
  String get noDeleteAccountAction => '否，删除账户';

  @override
  String get initiateAccountDeleteTitle => '请进行身份验证以启动账户删除';

  @override
  String get confirmAccountDeleteTitle => '确认删除账户';

  @override
  String get confirmAccountDeleteMessage =>
      '如果您使用其他 Ente 应用程序，该账户将会与其他应用程序链接。\n\n在所有 Ente 应用程序中，您上传的数据将被安排用于删除，并且您的账户将被永久删除。';

  @override
  String get delete => '删除';

  @override
  String get createNewAccount => '创建新账号';

  @override
  String get password => '密码';

  @override
  String get confirmPassword => '请确认密码';

  @override
  String passwordStrength(String passwordStrengthValue) {
    return '密码强度： $passwordStrengthValue';
  }

  @override
  String get hearUsWhereTitle => '您是怎么知道 Ente 的？（可选）';

  @override
  String get hearUsExplanation => '我们不跟踪应用程序安装情况。如果您告诉我们您是在哪里找到我们的，将会有所帮助！';

  @override
  String get signUpTerms =>
      '我同意 <u-terms>服务条款</u-terms> 和 <u-policy>隐私政策</u-policy>';

  @override
  String get termsOfServicesTitle => '服务条款';

  @override
  String get privacyPolicyTitle => '隐私政策';

  @override
  String get ackPasswordLostWarning =>
      '我明白，如果我丢失密码，我可能会丢失我的数据，因为我的数据是 <underline>端到端加密的</underline>。';

  @override
  String get encryption => '加密';

  @override
  String get logInLabel => '登录';

  @override
  String get welcomeBack => '欢迎回来！';

  @override
  String get loginTerms =>
      '点击登录后，我同意 <u-terms>服务条款</u-terms> 和 <u-policy>隐私政策</u-policy>';

  @override
  String get noInternetConnection => '无互联网连接';

  @override
  String get pleaseCheckYourInternetConnectionAndTryAgain => '请检查您的互联网连接，然后重试。';

  @override
  String get verificationFailedPleaseTryAgain => '验证失败，请再试一次';

  @override
  String get recreatePasswordTitle => '重新创建密码';

  @override
  String get recreatePasswordBody =>
      '当前设备的功能不足以验证您的密码，但我们可以以适用于所有设备的方式重新生成。\n\n请使用您的恢复密钥登录并重新生成您的密码（如果您愿意，可以再次使用相同的密码）。';

  @override
  String get useRecoveryKey => '使用恢复密钥';

  @override
  String get forgotPassword => '忘记密码';

  @override
  String get changeEmail => '修改邮箱';

  @override
  String get verifyEmail => '验证电子邮件';

  @override
  String weHaveSendEmailTo(String email) {
    return '我们已经发送邮件到 <green>$email</green>';
  }

  @override
  String get toResetVerifyEmail => '要重置您的密码，请先验证您的电子邮件。';

  @override
  String get checkInboxAndSpamFolder => '请检查您的收件箱 (或者是在您的“垃圾邮件”列表内) 以完成验证';

  @override
  String get tapToEnterCode => '点击以输入代码';

  @override
  String get sendEmail => '发送电子邮件';

  @override
  String get resendEmail => '重新发送电子邮件';

  @override
  String get passKeyPendingVerification => '仍需验证';

  @override
  String get loginSessionExpired => '会话已过期';

  @override
  String get loginSessionExpiredDetails => '您的会话已过期。请重新登录。';

  @override
  String get passkeyAuthTitle => '通行密钥验证';

  @override
  String get waitingForVerification => '等待验证...';

  @override
  String get tryAgain => '请再试一次';

  @override
  String get checkStatus => '检查状态';

  @override
  String get loginWithTOTP => '使用 TOTP 登录';

  @override
  String get recoverAccount => '恢复账户';

  @override
  String get setPasswordTitle => '设置密码';

  @override
  String get changePasswordTitle => '修改密码';

  @override
  String get resetPasswordTitle => '重置密码';

  @override
  String get encryptionKeys => '加密密钥';

  @override
  String get enterPasswordToEncrypt => '输入我们可以用来加密您的数据的密码';

  @override
  String get enterNewPasswordToEncrypt => '输入我们可以用来加密您的数据的新密码';

  @override
  String get passwordWarning =>
      '我们不储存这个密码，所以如果忘记， <underline>我们不能解密您的数据</underline>';

  @override
  String get howItWorks => '工作原理';

  @override
  String get generatingEncryptionKeys => '正在生成加密密钥...';

  @override
  String get passwordChangedSuccessfully => '密码修改成功';

  @override
  String get signOutFromOtherDevices => '从其他设备登出';

  @override
  String get signOutOtherBody => '如果您认为有人可能知道您的密码，您可以强制所有其他使用您账户的设备登出。';

  @override
  String get signOutOtherDevices => '登出其他设备';

  @override
  String get doNotSignOut => '不要登出';

  @override
  String get generatingEncryptionKeysTitle => '正在生成加密密钥...';

  @override
  String get continueLabel => '继续';

  @override
  String get insecureDevice => '设备不安全';

  @override
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease =>
      '抱歉，我们无法在此设备上生成安全密钥。\n\n请使用其他设备注册。';

  @override
  String get recoveryKeyCopiedToClipboard => '恢复密钥已复制到剪贴板';

  @override
  String get recoveryKey => '恢复密钥';

  @override
  String get recoveryKeyOnForgotPassword => '如果您忘记了密码，恢复数据的唯一方法就是使用此密钥。';

  @override
  String get recoveryKeySaveDescription => '我们不会存储此密钥，请将此24个单词密钥保存在一个安全的地方。';

  @override
  String get doThisLater => '稍后再做';

  @override
  String get saveKey => '保存密钥';

  @override
  String get recoveryKeySaved => '恢复密钥已保存在下载文件夹中！';

  @override
  String get noRecoveryKeyTitle => '没有恢复密钥吗？';

  @override
  String get twoFactorAuthTitle => '两步验证';

  @override
  String get enterCodeHint => '从你的身份验证器应用中\n输入6位数字代码';

  @override
  String get lostDeviceTitle => '丢失了设备吗？';

  @override
  String get enterRecoveryKeyHint => '输入您的恢复密钥';

  @override
  String get recover => '恢复';

  @override
  String get loggingOut => '正在登出...';

  @override
  String get immediately => '立即';

  @override
  String get appLock => '应用锁';

  @override
  String get autoLock => '自动锁定';

  @override
  String get noSystemLockFound => '未找到系统锁';

  @override
  String get deviceLockEnablePreSteps => '要启用设备锁，请在系统设置中设置设备密码或屏幕锁。';

  @override
  String get appLockDescription => '在设备的默认锁定屏幕和带有 PIN 或密码的自定义锁定屏幕之间进行选择。';

  @override
  String get deviceLock => '设备锁';

  @override
  String get pinLock => 'Pin 锁定';

  @override
  String get autoLockFeatureDescription => '应用程序进入后台后锁定的时间';

  @override
  String get hideContent => '隐藏内容';

  @override
  String get hideContentDescriptionAndroid => '在应用切换器中隐藏应用内容并禁用屏幕截图';

  @override
  String get hideContentDescriptioniOS => '在应用切换器中隐藏应用内容';

  @override
  String get tooManyIncorrectAttempts => '错误的尝试次数过多';

  @override
  String get tapToUnlock => '点击解锁';

  @override
  String get areYouSureYouWantToLogout => '您确定要登出吗？';

  @override
  String get yesLogout => '是的，登出';

  @override
  String get authToViewSecrets => '请进行身份验证以查看您的密钥';

  @override
  String get next => '下一步';

  @override
  String get setNewPassword => '设置新密码';

  @override
  String get enterPin => '输入 PIN 码';

  @override
  String get setNewPin => '设置新 PIN 码';

  @override
  String get confirm => '确认';

  @override
  String get reEnterPassword => '再次输入密码';

  @override
  String get reEnterPin => '再次输入 PIN 码';

  @override
  String get androidBiometricHint => '验证身份';

  @override
  String get androidBiometricNotRecognized => '未能识别，请重试。';

  @override
  String get androidBiometricSuccess => '成功';

  @override
  String get androidCancelButton => '取消';

  @override
  String get androidSignInTitle => '需要进行身份验证';

  @override
  String get androidBiometricRequiredTitle => '需要进行生物识别认证';

  @override
  String get androidDeviceCredentialsRequiredTitle => '需要设备凭据';

  @override
  String get androidDeviceCredentialsSetupDescription => '需要设备凭据';

  @override
  String get goToSettings => '前往设置';

  @override
  String get androidGoToSettingsDescription =>
      '您的设备上未设置生物识别身份验证。转到“设置 > 安全”以添加生物识别身份验证。';

  @override
  String get iOSLockOut => '生物识别身份验证已禁用。请锁定并解锁屏幕以启用该功能。';

  @override
  String get iOSOkButton => '好';

  @override
  String get emailAlreadyRegistered => '电子邮件地址已被注册。';

  @override
  String get emailNotRegistered => '电子邮件地址未注册。';

  @override
  String get thisEmailIsAlreadyInUse => '该电子邮件已被使用';

  @override
  String emailChangedTo(String newEmail) {
    return '电子邮件已更改为 $newEmail';
  }

  @override
  String get authenticationFailedPleaseTryAgain => '认证失败，请重试';

  @override
  String get authenticationSuccessful => '认证成功！';

  @override
  String get sessionExpired => '会话已过期';

  @override
  String get incorrectRecoveryKey => '恢复密钥不正确';

  @override
  String get theRecoveryKeyYouEnteredIsIncorrect => '您输入的恢复密钥不正确';

  @override
  String get twofactorAuthenticationSuccessfullyReset => '两步验证已成功重置';

  @override
  String get yourVerificationCodeHasExpired => '您的验证码已过期';

  @override
  String get incorrectCode => '验证码错误';

  @override
  String get sorryTheCodeYouveEnteredIsIncorrect => '抱歉，您输入的验证码不正确';

  @override
  String get developerSettings => '开发者设置';

  @override
  String get serverEndpoint => '服务器端点';

  @override
  String get invalidEndpoint => '端点无效';

  @override
  String get invalidEndpointMessage => '抱歉，您输入的端点无效。请输入有效的端点，然后重试。';

  @override
  String get endpointUpdatedMessage => '端点更新成功';
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
