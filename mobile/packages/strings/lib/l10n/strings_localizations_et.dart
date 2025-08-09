// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Estonian (`et`).
class StringsLocalizationsEt extends StringsLocalizations {
  StringsLocalizationsEt([String locale = 'et']) : super(locale);

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
  String get error => 'Viga';

  @override
  String get ok => 'Sobib';

  @override
  String get faq => 'KKK';

  @override
  String get contactSupport => 'Võtke ühendust klienditoega';

  @override
  String get emailYourLogs => 'Email your logs';

  @override
  String pleaseSendTheLogsTo(String toEmail) {
    return 'Please send the logs to \n$toEmail';
  }

  @override
  String get copyEmailAddress => 'Copy email address';

  @override
  String get exportLogs => 'Export logs';

  @override
  String get cancel => 'Katkesta';

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
  String get reportABug => 'Teata veast';

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
  String get save => 'Salvesta';

  @override
  String get send => 'Saada';

  @override
  String get saveOrSendDescription =>
      'Do you want to save this to your storage (Downloads folder by default) or send it to other apps?';

  @override
  String get saveOnlyDescription =>
      'Do you want to save this to your storage (Downloads folder by default)?';

  @override
  String get enterNewEmailHint => 'Sisesta oma uus e-posti aadress';

  @override
  String get email => 'E-post';

  @override
  String get verify => 'Kinnita';

  @override
  String get invalidEmailTitle => 'Vigane e-posti aadress';

  @override
  String get invalidEmailMessage => 'Palun sisesta korrektne e-posti aadress.';

  @override
  String get pleaseWait => 'Palun oota...';

  @override
  String get verifyPassword => 'Korda salasõna';

  @override
  String get incorrectPasswordTitle => 'Vale salasõna';

  @override
  String get pleaseTryAgain => 'Palun proovi uuesti';

  @override
  String get enterPassword => 'Sisesta salasõna';

  @override
  String get enterYourPasswordHint => 'Sisesta oma salasõna';

  @override
  String get activeSessions => 'Active sessions';

  @override
  String get oops => 'Vaat kus lops!';

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
  String get weakStrength => 'Nõrk';

  @override
  String get moderateStrength => 'Keskmine';

  @override
  String get strongStrength => 'Tugev';

  @override
  String get deleteAccount => 'Kustuta kasutajakonto';

  @override
  String get deleteAccountQuery =>
      'Meil on kahju, et soovid lahkuda. Kas sul tekkis mõni viga või probleem?';

  @override
  String get yesSendFeedbackAction => 'Jah, saadan tagasisidet';

  @override
  String get noDeleteAccountAction => 'Ei, kustuta kasutajakonto';

  @override
  String get initiateAccountDeleteTitle =>
      'Kasutajakonto kustutamiseks palun tuvasta end';

  @override
  String get confirmAccountDeleteTitle => 'Confirm account deletion';

  @override
  String get confirmAccountDeleteMessage =>
      'This account is linked to other Ente apps, if you use any.\n\nYour uploaded data, across all Ente apps, will be scheduled for deletion, and your account will be permanently deleted.';

  @override
  String get delete => 'Kustuta';

  @override
  String get createNewAccount => 'Loo uus kasutajakonto';

  @override
  String get password => 'Salasõna';

  @override
  String get confirmPassword => 'Korda salasõna';

  @override
  String passwordStrength(String passwordStrengthValue) {
    return 'Salasõna tugevus: $passwordStrengthValue';
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
  String get termsOfServicesTitle => 'Kasutustingimused';

  @override
  String get privacyPolicyTitle => 'Privaatsusreeglid';

  @override
  String get ackPasswordLostWarning =>
      'Ma saan aru, et salasõna kaotamisel kaotan ka ligipääsu oma andmetele - minu andmed on ju <underline>läbivalt krüptitud</underline>.';

  @override
  String get encryption => 'Krüptimine';

  @override
  String get logInLabel => 'Logi sisse';

  @override
  String get welcomeBack => 'Tere tulemast tagasi!';

  @override
  String get loginTerms =>
      'Sisselogdes nõustun <u-terms>kasutustingimustega</u-terms> ja <u-policy>privaatsusreeglitega</u-policy>';

  @override
  String get noInternetConnection => 'No internet connection';

  @override
  String get pleaseCheckYourInternetConnectionAndTryAgain =>
      'Please check your internet connection and try again.';

  @override
  String get verificationFailedPleaseTryAgain =>
      'Verification failed, please try again';

  @override
  String get recreatePasswordTitle => 'Loo salasõna uuesti';

  @override
  String get recreatePasswordBody =>
      'The current device is not powerful enough to verify your password, but we can regenerate in a way that works with all devices.\n\nPlease login using your recovery key and regenerate your password (you can use the same one again if you wish).';

  @override
  String get useRecoveryKey => 'Kasuta taastevõtit';

  @override
  String get forgotPassword => 'Unustasin salasõna';

  @override
  String get changeEmail => 'Muuda e-posti aadressi';

  @override
  String get verifyEmail => 'Kinnita e-posti aadress';

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
  String get sendEmail => 'Saada e-kiri';

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
  String get tryAgain => 'Proovi uuesti';

  @override
  String get checkStatus => 'Kontrolli olekut';

  @override
  String get loginWithTOTP => 'Login with TOTP';

  @override
  String get recoverAccount => 'Taasta oma kasutajakonto';

  @override
  String get setPasswordTitle => 'Sisesta salasõna';

  @override
  String get changePasswordTitle => 'Muuda salasõna';

  @override
  String get resetPasswordTitle => 'Lähtesta salasõna';

  @override
  String get encryptionKeys => 'Krüptovõtmed';

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
  String get howItWorks => 'Kuidas see töötab';

  @override
  String get generatingEncryptionKeys => 'Generating encryption keys...';

  @override
  String get passwordChangedSuccessfully => 'Salasõna muutmine õnnestus';

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
  String get generatingEncryptionKeysTitle => 'Loon krüptovõtmeid...';

  @override
  String get continueLabel => 'Continue';

  @override
  String get insecureDevice => 'Insecure device';

  @override
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease =>
      'Sorry, we could not generate secure keys on this device.\n\nplease sign up from a different device.';

  @override
  String get recoveryKeyCopiedToClipboard =>
      'Taastevõti on kopeeritud lõikelauale';

  @override
  String get recoveryKey => 'Taastevõti';

  @override
  String get recoveryKeyOnForgotPassword =>
      'Kui unustad oma salasõna, siis see krüptovõti on ainus võimalus sinu andmete taastamiseks.';

  @override
  String get recoveryKeySaveDescription =>
      'We don\'t store this key, please save this 24 word key in a safe place.';

  @override
  String get doThisLater => 'Do this later';

  @override
  String get saveKey => 'Salvesta võti';

  @override
  String get recoveryKeySaved => 'Recovery key saved in Downloads folder!';

  @override
  String get noRecoveryKeyTitle => 'Sul pole taastevõtit?';

  @override
  String get twoFactorAuthTitle => 'Two-factor authentication';

  @override
  String get enterCodeHint =>
      'Sisesta oma autentimisrakendusest\n6-numbriline kood';

  @override
  String get lostDeviceTitle => 'Kas kaotasid oma seadme?';

  @override
  String get enterRecoveryKeyHint => 'Sisesta oma taastevõti';

  @override
  String get recover => 'Taasta';

  @override
  String get loggingOut => 'Väljalogimine...';

  @override
  String get immediately => 'Immediately';

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
  String get hideContent => 'Hide content';

  @override
  String get hideContentDescriptionAndroid =>
      'Hides app content in the app switcher and disables screenshots';

  @override
  String get hideContentDescriptioniOS =>
      'Hides app content in the app switcher';

  @override
  String get tooManyIncorrectAttempts => 'Too many incorrect attempts';

  @override
  String get tapToUnlock => 'Tap to unlock';

  @override
  String get areYouSureYouWantToLogout =>
      'Kas oled kindel, et soovid välja logida?';

  @override
  String get yesLogout => 'Jah, logi välja';

  @override
  String get authToViewSecrets => 'Please authenticate to view your secrets';

  @override
  String get next => 'Next';

  @override
  String get setNewPassword => 'Sisesta uus salasõna';

  @override
  String get enterPin => 'Sisesta PIN-kood';

  @override
  String get setNewPin => 'Määra uus PIN-kood';

  @override
  String get confirm => 'Confirm';

  @override
  String get reEnterPassword => 'Sisesta salasõna uuesti';

  @override
  String get reEnterPin => 'Re-enter PIN';

  @override
  String get androidBiometricHint => 'Verify identity';

  @override
  String get androidBiometricNotRecognized => 'Not recognized. Try again.';

  @override
  String get androidBiometricSuccess => 'Success';

  @override
  String get androidCancelButton => 'Cancel';

  @override
  String get androidSignInTitle => 'Authentication required';

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
  String get emailAlreadyRegistered =>
      'E-posti aadress on juba registreeritud.';

  @override
  String get emailNotRegistered => 'E-posti aadress pole registreeritud.';

  @override
  String get thisEmailIsAlreadyInUse => 'This email is already in use';

  @override
  String emailChangedTo(String newEmail) {
    return 'Email changed to $newEmail';
  }

  @override
  String get authenticationFailedPleaseTryAgain =>
      'Authentication failed, please try again';

  @override
  String get authenticationSuccessful => 'Authentication successful!';

  @override
  String get sessionExpired => 'Sessioon on aegunud';

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
