// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Khmer Central Khmer (`km`).
class StringsLocalizationsKm extends StringsLocalizations {
  StringsLocalizationsKm([String locale = 'km']) : super(locale);

  @override
  String get networkHostLookUpErr =>
      'Unable to connect to Ente, please check your network settings and contact support if the error persists.';

  @override
  String get networkConnectionRefusedErr =>
      'Unable to connect to Ente, please retry after sometime. If the error persists, please contact support.';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      'It looks like something went wrong. Please retry after some time. If the error persists, please contact our support team.';

  @override
  String get error => 'មានកំហុស';

  @override
  String get ok => 'យល់ព្រម';

  @override
  String get faq => 'សំនួរ-ចម្លើយ';

  @override
  String get contactSupport => 'ទំនាក់ទំនងសេវា';

  @override
  String get emailYourLogs => 'Email your logs';

  @override
  String pleaseSendTheLogsTo(String toEmail) {
    return 'Please send the logs to \n$toEmail';
  }

  @override
  String get copyEmailAddress => 'ចម្លង​អាសយដ្ឋាន​អ៊ីមែល';

  @override
  String get exportLogs => 'នាំចេញកំណត់ហេតុ';

  @override
  String get cancel => 'បោះបង់';

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
  String get save => 'រក្សាទុក';

  @override
  String get send => 'ផ្ញើរចេញ';

  @override
  String get saveOrSendDescription =>
      'Do you want to save this to your storage (Downloads folder by default) or send it to other apps?';

  @override
  String get saveOnlyDescription =>
      'Do you want to save this to your storage (Downloads folder by default)?';

  @override
  String get enterNewEmailHint => 'Enter your new email address';

  @override
  String get email => 'អ៊ីម៉ែល';

  @override
  String get verify => 'ផ្ទៀងផ្ទាត់';

  @override
  String get invalidEmailTitle => 'អ៊ីម៉ែលនេះមិនត្រឹមត្រូវទេ';

  @override
  String get invalidEmailMessage => 'Please enter a valid email address.';

  @override
  String get pleaseWait => 'Please wait...';

  @override
  String get verifyPassword => 'ផ្ទៀងផ្ទាត់ពាក្យសម្ងាត់';

  @override
  String get incorrectPasswordTitle => 'Incorrect password';

  @override
  String get pleaseTryAgain => 'សូមសាកល្បងម្តងទៀត';

  @override
  String get enterPassword => 'វាយបញ្ចូល​ពាក្យ​សម្ងាត់';

  @override
  String get enterYourPasswordHint => 'Enter your password';

  @override
  String get activeSessions => 'សកម្មភាពគណនី';

  @override
  String get oops => 'Oops';

  @override
  String get somethingWentWrongPleaseTryAgain =>
      'មាន​អ្វីមួយ​មិន​ប្រក្រតី។ សូម​ព្យាយាម​ម្តង​ទៀត';

  @override
  String get thisWillLogYouOutOfThisDevice =>
      'This will log you out of this device!';

  @override
  String get thisWillLogYouOutOfTheFollowingDevice =>
      'This will log you out of the following device:';

  @override
  String get terminateSession => 'កាត់់ផ្តាច់សកម្មភាពគណនីនេះ?';

  @override
  String get terminate => 'កាត់ផ្តាច់';

  @override
  String get thisDevice => 'ទូរស័ព្ទនេះ';

  @override
  String get createAccount => 'បង្កើតគណនី';

  @override
  String get weakStrength => 'ខ្សោយ';

  @override
  String get moderateStrength => 'មធ្យម';

  @override
  String get strongStrength => 'ខ្លាំង';

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
  String get createNewAccount => 'បង្កើតគណនីថ្មី';

  @override
  String get password => 'ពាក្យសម្ងាត់';

  @override
  String get confirmPassword => 'បញ្ជាក់ពាក្យសម្ងាត់';

  @override
  String passwordStrength(String passwordStrengthValue) {
    return 'កម្លាំងពាក្យសម្ងាត់: $passwordStrengthValue';
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
  String get privacyPolicyTitle => 'គោលការណ៍​ភាព​ឯកជន';

  @override
  String get ackPasswordLostWarning =>
      'I understand that if I lose my password, I may lose my data since my data is <underline>end-to-end encrypted</underline>.';

  @override
  String get encryption => 'Encryption';

  @override
  String get logInLabel => 'ចូលគណនី';

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
  String get forgotPassword => 'ភ្លេចកូដសម្ងាត់';

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
  String get resendEmail => 'ផ្ញើអ៊ីមែលម្ដងទៀត';

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
  String get checkStatus => 'ពិនិត្យស្ថានភាព';

  @override
  String get loginWithTOTP => 'Login with TOTP';

  @override
  String get recoverAccount => 'Recover account';

  @override
  String get setPasswordTitle => 'Set password';

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get resetPasswordTitle => 'ផ្ដាស់ប្ដូរពាក្សសម្ងាត់';

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
  String get recover => 'សង្គ្រោះមកវិញ';

  @override
  String get loggingOut => 'Logging out...';

  @override
  String get immediately => 'ភ្លាមៗ';

  @override
  String get appLock => 'App lock';

  @override
  String get autoLock => 'Auto lock';

  @override
  String get noSystemLockFound => 'No system lock found';

  @override
  String get deviceLockEnablePreSteps =>
      'To enable device lock, please setup device passcode or screen lock in your system settings.';

  @override
  String get appLockDescription =>
      'Choose between your device\'s default lock screen and a custom lock screen with a PIN or password.';

  @override
  String get deviceLock => 'Device lock';

  @override
  String get pinLock => 'Pin lock';

  @override
  String get autoLockFeatureDescription =>
      'Time after which the app locks after being put in the background';

  @override
  String get hideContent => 'លាក់ពត័មាន';

  @override
  String get hideContentDescriptionAndroid =>
      'Hides app content in the app switcher and disables screenshots';

  @override
  String get hideContentDescriptioniOS =>
      'Hides app content in the app switcher';

  @override
  String get tooManyIncorrectAttempts => 'Too many incorrect attempts';

  @override
  String get tapToUnlock => 'ប៉ះដើម្បីដោះសោ';

  @override
  String get areYouSureYouWantToLogout => 'Are you sure you want to logout?';

  @override
  String get yesLogout => 'Yes, logout';

  @override
  String get authToViewSecrets => 'Please authenticate to view your secrets';

  @override
  String get next => 'Next';

  @override
  String get setNewPassword => 'Set new password';

  @override
  String get enterPin => 'វាយបញ្ចូល​លេខ​កូដ PIN';

  @override
  String get setNewPin => 'Set new PIN';

  @override
  String get confirm => 'Confirm';

  @override
  String get reEnterPassword => 'បញ្ចូលពាក្យសម្ងាត់ម្តងទៀត';

  @override
  String get reEnterPin => 'Re-enter PIN';

  @override
  String get androidBiometricHint => 'Verify identity';

  @override
  String get androidBiometricNotRecognized => 'Not recognized. Try again.';

  @override
  String get androidBiometricSuccess => 'Success';

  @override
  String get androidCancelButton => 'បោះបង់';

  @override
  String get androidSignInTitle => 'តម្រូវឱ្យមានការបញ្ជាក់ភាពត្រឹមត្រូវ';

  @override
  String get androidBiometricRequiredTitle => 'Biometric required';

  @override
  String get androidDeviceCredentialsRequiredTitle =>
      'Device credentials required';

  @override
  String get androidDeviceCredentialsSetupDescription =>
      'Device credentials required';

  @override
  String get goToSettings => 'Go to settings';

  @override
  String get androidGoToSettingsDescription =>
      'Biometric authentication is not set up on your device. Go to \'Settings > Security\' to add biometric authentication.';

  @override
  String get iOSLockOut =>
      'Biometric authentication is disabled. Please lock and unlock your screen to enable it.';

  @override
  String get iOSOkButton => 'OK';

  @override
  String get emailAlreadyRegistered => 'Email already registered.';

  @override
  String get emailNotRegistered => 'Email not registered.';

  @override
  String get thisEmailIsAlreadyInUse => 'This email is already in use';

  @override
  String emailChangedTo(String newEmail) {
    return 'អ៊ីម៉ែលត្រូវបានផ្លាស់ប្តូរទៅ$newEmail';
  }

  @override
  String get authenticationFailedPleaseTryAgain =>
      'Authentication failed, please try again';

  @override
  String get authenticationSuccessful => 'Authentication successful!';

  @override
  String get sessionExpired => 'Session expired';

  @override
  String get incorrectRecoveryKey => 'Incorrect recovery key';

  @override
  String get theRecoveryKeyYouEnteredIsIncorrect =>
      'The recovery key you entered is incorrect';

  @override
  String get twofactorAuthenticationSuccessfullyReset =>
      'Two-factor authentication successfully reset';

  @override
  String get noRecoveryKey => 'No recovery key';

  @override
  String get yourAccountHasBeenDeleted => 'Your account has been deleted';

  @override
  String get verificationId => 'Verification ID';

  @override
  String get yourVerificationCodeHasExpired =>
      'Your verification code has expired';

  @override
  String get incorrectCode => 'Incorrect code';

  @override
  String get sorryTheCodeYouveEnteredIsIncorrect =>
      'Sorry, the code you\'ve entered is incorrect';

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
