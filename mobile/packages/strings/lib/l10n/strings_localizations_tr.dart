// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class StringsLocalizationsTr extends StringsLocalizations {
  StringsLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get networkHostLookUpErr =>
      'Ente\'ye bağlanılamıyor, lütfen ağ ayarlarınızı kontrol edin ve hata devam ederse desteğe başvurun.';

  @override
  String get networkConnectionRefusedErr =>
      'Ente\'ye bağlanılamıyor, lütfen daha sonra tekrar deneyin. Hata devam ederse, lütfen desteğe başvurun.';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      'Bir şeyler ters gitmiş gibi görünüyor. Lütfen bir süre sonra tekrar deneyin. Hata devam ederse, lütfen destek ekibimizle iletişime geçin.';

  @override
  String get error => 'Hata';

  @override
  String get ok => 'Tamam';

  @override
  String get faq => 'SSS';

  @override
  String get contactSupport => 'Destek ekibiyle iletişime geçin';

  @override
  String get emailYourLogs => 'Kayıtlarınızı e-postayla gönderin';

  @override
  String pleaseSendTheLogsTo(String toEmail) {
    return 'Lütfen kayıtları şu adrese gönderin\n$toEmail';
  }

  @override
  String get copyEmailAddress => 'E-posta adresini kopyala';

  @override
  String get exportLogs => 'Kayıtları dışa aktar';

  @override
  String get cancel => 'İptal Et';

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
  String get reportABug => 'Hata bildirin';

  @override
  String get logsDialogBody =>
      'This will send across logs to help us debug your issue. Please note that file names will be included to help track issues with specific files.';

  @override
  String get viewLogs => 'View logs';

  @override
  String customEndpoint(String endpoint) {
    return 'Bağlandı: $endpoint';
  }

  @override
  String get save => 'Kaydet';

  @override
  String get send => 'Gönder';

  @override
  String get saveOrSendDescription =>
      'Bunu belleğinize mi kaydedeceksiniz (İndirilenler klasörü varsayılandır) yoksa diğer uygulamalara mı göndereceksiniz?';

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
