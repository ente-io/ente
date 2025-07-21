// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Finnish (`fi`).
class StringsLocalizationsFi extends StringsLocalizations {
  StringsLocalizationsFi([String locale = 'fi']) : super(locale);

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
  String get error => 'Virhe';

  @override
  String get ok => 'Selvä';

  @override
  String get faq => 'Usein kysyttyä';

  @override
  String get contactSupport => 'Ota yhteyttä käyttötukeen';

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
  String get cancel => 'Keskeytä';

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
  String get reportABug => 'Ilmoita virhetoiminnosta';

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
  String get save => 'Tallenna';

  @override
  String get send => 'Lähetä';

  @override
  String get saveOrSendDescription =>
      'Do you want to save this to your storage (Downloads folder by default) or send it to other apps?';

  @override
  String get saveOnlyDescription =>
      'Do you want to save this to your storage (Downloads folder by default)?';

  @override
  String get enterNewEmailHint => 'Enter your new email address';

  @override
  String get email => 'Sähköposti';

  @override
  String get verify => 'Vahvista';

  @override
  String get invalidEmailTitle => 'Epäkelpo sähköpostiosoite';

  @override
  String get invalidEmailMessage => 'Syötä kelpoisa sähköpostiosoite.';

  @override
  String get pleaseWait => 'Odota hetki...';

  @override
  String get verifyPassword => 'Vahvista salasana';

  @override
  String get incorrectPasswordTitle => 'Salasana on väärin';

  @override
  String get pleaseTryAgain => 'Yritä uudestaan';

  @override
  String get enterPassword => 'Syötä salasana';

  @override
  String get enterYourPasswordHint => 'Syötä salasanasi';

  @override
  String get activeSessions => 'Active sessions';

  @override
  String get oops => 'Hupsista';

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
  String get createAccount => 'Luo tili';

  @override
  String get weakStrength => 'Heikko salasana';

  @override
  String get moderateStrength => 'Kohtalainen salasana';

  @override
  String get strongStrength => 'Vahva salasana';

  @override
  String get deleteAccount => 'Poista tili';

  @override
  String get deleteAccountQuery =>
      'Olemme pahoillamme että lähdet keskuudestamme. Kohtasitko käytössä jonkin ongelman?';

  @override
  String get yesSendFeedbackAction => 'Kyllä, lähetä palautetta';

  @override
  String get noDeleteAccountAction => 'En, poista tili';

  @override
  String get initiateAccountDeleteTitle =>
      'Ole hyvä ja tee todennus käynnistääksesi tilisi poistoprosessin';

  @override
  String get confirmAccountDeleteTitle => 'Confirm account deletion';

  @override
  String get confirmAccountDeleteMessage =>
      'This account is linked to other Ente apps, if you use any.\n\nYour uploaded data, across all Ente apps, will be scheduled for deletion, and your account will be permanently deleted.';

  @override
  String get delete => 'Poista';

  @override
  String get createNewAccount => 'Luo uusi tili';

  @override
  String get password => 'Salasana';

  @override
  String get confirmPassword => 'Vahvista salasana';

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
  String get encryption => 'Salaus';

  @override
  String get logInLabel => 'Kirjaudu sisään';

  @override
  String get welcomeBack => 'Tervetuloa takaisin!';

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
  String get useRecoveryKey => 'Käytä palautusavainta';

  @override
  String get forgotPassword => 'Olen unohtanut salasanani';

  @override
  String get changeEmail => 'vaihda sähköpostiosoitteesi';

  @override
  String get verifyEmail => 'Vahvista sähköpostiosoite';

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
  String get sendEmail => 'Lähetä sähköpostia';

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
  String get passkeyAuthTitle => 'Avainkoodin vahvistus';

  @override
  String get waitingForVerification => 'Waiting for verification...';

  @override
  String get tryAgain => 'Try again';

  @override
  String get checkStatus => 'Check status';

  @override
  String get loginWithTOTP => 'Login with TOTP';

  @override
  String get recoverAccount => 'Palauta tilisi';

  @override
  String get setPasswordTitle => 'Luo salasana';

  @override
  String get changePasswordTitle => 'Vaihda salasana';

  @override
  String get resetPasswordTitle => 'Nollaa salasana';

  @override
  String get encryptionKeys => 'Salausavaimet';

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
  String get generatingEncryptionKeys => 'Luodaan salausavaimia...';

  @override
  String get passwordChangedSuccessfully => 'Salasana vaihdettu onnistuneesti';

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
  String get generatingEncryptionKeysTitle => 'Luodaan salausavaimia...';

  @override
  String get continueLabel => 'Jatka';

  @override
  String get insecureDevice => 'Insecure device';

  @override
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease =>
      'Sorry, we could not generate secure keys on this device.\n\nplease sign up from a different device.';

  @override
  String get recoveryKeyCopiedToClipboard =>
      'Palautusavain kopioitu leikepöydälle';

  @override
  String get recoveryKey => 'Palautusavain';

  @override
  String get recoveryKeyOnForgotPassword =>
      'Jos unohdat salasanasi, ainoa tapa palauttaa tietosi on tällä avaimella.';

  @override
  String get recoveryKeySaveDescription =>
      'Emme tallenna tätä avainta, ole hyvä ja tallenna tämä 24 sanan avain turvalliseen paikkaan.';

  @override
  String get doThisLater => 'Tee tämä myöhemmin';

  @override
  String get saveKey => 'Tallenna avain';

  @override
  String get recoveryKeySaved => 'Recovery key saved in Downloads folder!';

  @override
  String get noRecoveryKeyTitle => 'Ei palautusavainta?';

  @override
  String get twoFactorAuthTitle => 'Kaksivaiheinen vahvistus';

  @override
  String get enterCodeHint =>
      'Syötä 6-merkkinen koodi varmennussovelluksestasi';

  @override
  String get lostDeviceTitle => 'Kadonnut laite?';

  @override
  String get enterRecoveryKeyHint => 'Syötä palautusavaimesi';

  @override
  String get recover => 'Palauta';

  @override
  String get loggingOut => 'Kirjaudutaan ulos...';

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
  String get areYouSureYouWantToLogout => 'Are you sure you want to logout?';

  @override
  String get yesLogout => 'Kyllä, kirjaudu ulos';

  @override
  String get authToViewSecrets => 'Please authenticate to view your secrets';

  @override
  String get next => 'Next';

  @override
  String get setNewPassword => 'Set new password';

  @override
  String get enterPin => 'Enter PIN';

  @override
  String get setNewPin => 'Set new PIN';

  @override
  String get confirm => 'Confirm';

  @override
  String get reEnterPassword => 'Re-enter password';

  @override
  String get reEnterPin => 'Re-enter PIN';

  @override
  String get androidBiometricHint => 'Verify identity';

  @override
  String get androidBiometricNotRecognized => 'Not recognized. Try again.';

  @override
  String get androidBiometricSuccess => 'Kirjautuminen onnistui';

  @override
  String get androidCancelButton => 'Peruuta';

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
  String get goToSettings => 'Mene asetuksiin';

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
    return 'Email changed to $newEmail';
  }

  @override
  String get authenticationFailedPleaseTryAgain =>
      'Authentication failed, please try again';

  @override
  String get authenticationSuccessful => 'Authentication successful!';

  @override
  String get sessionExpired => 'Istunto on vanheutunut';

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
