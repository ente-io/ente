// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class StringsLocalizationsHe extends StringsLocalizations {
  StringsLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get networkHostLookUpErr =>
      'Unable to connect to Ente, please check your network settings and contact support if the error persists.';

  @override
  String get networkConnectionRefusedErr =>
      'Unable to connect to Ente, please retry after sometime. If the error persists, please contact support.';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      'נראה שמשהו לא פעל כשורה. אנא נסה שוב אחרי כמה זמן. אם הבעיה ממשיכה, אנא צור קשר עם צוות התמיכה שלנו.';

  @override
  String get error => 'שגיאה';

  @override
  String get ok => 'אוקיי';

  @override
  String get faq => 'שאלות נפוצות';

  @override
  String get contactSupport => 'צור קשר עם התמיכה';

  @override
  String get emailYourLogs => 'שלח באימייל את הלוגים שלך';

  @override
  String pleaseSendTheLogsTo(String toEmail) {
    return 'אנא שלחו את הלוגים האלו ל-$toEmail';
  }

  @override
  String get copyEmailAddress => 'העתק כתובת דוא\"ל';

  @override
  String get exportLogs => 'ייצוא לוגים';

  @override
  String get cancel => 'בטל';

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
  String get reportABug => 'דווח על באג';

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
  String get save => 'שמור';

  @override
  String get send => 'שלח';

  @override
  String get saveOrSendDescription =>
      'Do you want to save this to your storage (Downloads folder by default) or send it to other apps?';

  @override
  String get saveOnlyDescription =>
      'Do you want to save this to your storage (Downloads folder by default)?';

  @override
  String get enterNewEmailHint => 'Enter your new email address';

  @override
  String get email => 'דוא\"ל';

  @override
  String get verify => 'אמת';

  @override
  String get invalidEmailTitle => 'כתובת דוא״ל לא תקינה';

  @override
  String get invalidEmailMessage => 'אנא הכנס כתובת דוא\"ל תקינה.';

  @override
  String get pleaseWait => 'אנא המתן...';

  @override
  String get verifyPassword => 'אמת סיסמא';

  @override
  String get incorrectPasswordTitle => 'סיסמא לא נכונה';

  @override
  String get pleaseTryAgain => 'אנא נסה שנית';

  @override
  String get enterPassword => 'הזן את הסיסמה';

  @override
  String get enterYourPasswordHint => 'הכנס סיסמא';

  @override
  String get activeSessions => 'חיבורים פעילים';

  @override
  String get oops => 'אופס';

  @override
  String get somethingWentWrongPleaseTryAgain => 'משהו השתבש, אנא נסה שנית';

  @override
  String get thisWillLogYouOutOfThisDevice => 'זה ינתק אותך במכשיר זה!';

  @override
  String get thisWillLogYouOutOfTheFollowingDevice =>
      'זה ינתק אותך מהמכשיר הבא:';

  @override
  String get terminateSession => 'סיים חיבור?';

  @override
  String get terminate => 'סיים';

  @override
  String get thisDevice => 'מכשיר זה';

  @override
  String get createAccount => 'צור חשבון';

  @override
  String get weakStrength => 'חלש';

  @override
  String get moderateStrength => 'מתון';

  @override
  String get strongStrength => 'חזק';

  @override
  String get deleteAccount => 'מחק חשבון';

  @override
  String get deleteAccountQuery =>
      'אנו מצטערים שאתה עוזב. האם יש בעיות שאתה חווה?';

  @override
  String get yesSendFeedbackAction => 'כן, שלח משוב';

  @override
  String get noDeleteAccountAction => 'לא, מחק את החשבון';

  @override
  String get initiateAccountDeleteTitle =>
      'אנא אמת על מנת להתחיל את מחיקת החשבון שלך';

  @override
  String get confirmAccountDeleteTitle => 'אישור מחיקת חשבון';

  @override
  String get confirmAccountDeleteMessage =>
      'This account is linked to other Ente apps, if you use any.\n\nYour uploaded data, across all Ente apps, will be scheduled for deletion, and your account will be permanently deleted.';

  @override
  String get delete => 'למחוק';

  @override
  String get createNewAccount => 'צור חשבון חדש';

  @override
  String get password => 'סיסמא';

  @override
  String get confirmPassword => 'אמת סיסמא';

  @override
  String passwordStrength(String passwordStrengthValue) {
    return 'חוזק הסיסמא: $passwordStrengthValue';
  }

  @override
  String get hearUsWhereTitle => 'How did you hear about Ente? (optional)';

  @override
  String get hearUsExplanation =>
      'We don\'t track app installs. It\'d help if you told us where you found us!';

  @override
  String get signUpTerms =>
      'אני מסכים ל<u-terms>תנאי שירות</u-terms> ול<u-policy>מדיניות הפרטיות</u-policy>';

  @override
  String get termsOfServicesTitle => 'תנאים';

  @override
  String get privacyPolicyTitle => 'מדיניות פרטיות';

  @override
  String get ackPasswordLostWarning =>
      'אני מבין שאם אאבד את הסיסמא, אני עלול לאבד את המידע שלי מכיוון שהמידע שלי <underline>מוצפן מקצה אל קצה</underline>.';

  @override
  String get encryption => 'הצפנה';

  @override
  String get logInLabel => 'התחבר';

  @override
  String get welcomeBack => 'ברוך שובך!';

  @override
  String get loginTerms =>
      'על ידי לחיצה על התחברות, אני מסכים ל<u-terms>תנאי שירות</u-terms> ול<u-policy>מדיניות הפרטיות</u-policy>';

  @override
  String get noInternetConnection => 'אין חיבור לאינטרנט';

  @override
  String get pleaseCheckYourInternetConnectionAndTryAgain =>
      'אנא בדוק את חיבור האינטרנט שלך ונסה שוב.';

  @override
  String get verificationFailedPleaseTryAgain => 'אימות נכשל, אנא נסה שנית';

  @override
  String get recreatePasswordTitle => 'צור סיסמא מחדש';

  @override
  String get recreatePasswordBody =>
      'המכשיר הנוכחי אינו חזק מספיק כדי לאמת את הסיסמא שלך, אבל אנחנו יכולים ליצור מחדש בצורה שתעבוד עם כל המכשירים.\n\nאנא התחבר בעזרת המפתח שחזור שלך וצור מחדש את הסיסמא שלך (אתה יכול להשתמש באותה אחת אם אתה רוצה).';

  @override
  String get useRecoveryKey => 'השתמש במפתח שחזור';

  @override
  String get forgotPassword => 'שכחתי סיסמה';

  @override
  String get changeEmail => 'שנה דוא\"ל';

  @override
  String get verifyEmail => 'אימות דוא\"ל';

  @override
  String weHaveSendEmailTo(String email) {
    return 'שלחנו דוא\"ל ל<green>$email</green>';
  }

  @override
  String get toResetVerifyEmail =>
      'כדי לאפס את הסיסמא שלך, אנא אמת את האימייל שלך קודם.';

  @override
  String get checkInboxAndSpamFolder =>
      'אנא בדוק את תיבת הדואר שלך (והספאם) כדי להשלים את האימות';

  @override
  String get tapToEnterCode => 'הקש כדי להזין את הקוד';

  @override
  String get sendEmail => 'שלח אימייל';

  @override
  String get resendEmail => 'שלח דוא\"ל מחדש';

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
  String get tryAgain => 'נסה שוב';

  @override
  String get checkStatus => 'בדוק סטטוס';

  @override
  String get loginWithTOTP => 'Login with TOTP';

  @override
  String get recoverAccount => 'שחזר חשבון';

  @override
  String get setPasswordTitle => 'הגדר סיסמא';

  @override
  String get changePasswordTitle => 'שנה סיסמה';

  @override
  String get resetPasswordTitle => 'איפוס סיסמה';

  @override
  String get encryptionKeys => 'מפתחות ההצפנה';

  @override
  String get enterPasswordToEncrypt =>
      'הזן סיסמא כדי שנוכל להצפין את המידע שלך';

  @override
  String get enterNewPasswordToEncrypt =>
      'הכנס סיסמא חדשה כדי שנוכל להצפין את המידע שלך';

  @override
  String get passwordWarning =>
      'אנחנו לא שומרים את הסיסמא הזו, לכן אם אתה שוכח אותה, <underline>אנחנו לא יכולים לפענח את המידע שלך</underline>';

  @override
  String get howItWorks => 'איך זה עובד';

  @override
  String get generatingEncryptionKeys => 'יוצר מפתחות הצפנה...';

  @override
  String get passwordChangedSuccessfully => 'הסיסמה הוחלפה בהצלחה';

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
  String get generatingEncryptionKeysTitle => 'יוצר מפתחות הצפנה...';

  @override
  String get continueLabel => 'המשך';

  @override
  String get insecureDevice => 'מכשיר בלתי מאובטח';

  @override
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease =>
      'אנחנו מצטערים, לא הצלחנו ליצור מפתחות מאובטחים על מכשיר זה.\n\nאנא הירשם ממכשיר אחר.';

  @override
  String get recoveryKeyCopiedToClipboard => 'מפתח השחזור הועתק ללוח';

  @override
  String get recoveryKey => 'מפתח שחזור';

  @override
  String get recoveryKeyOnForgotPassword =>
      'אם אתה שוכח את הסיסמא שלך, הדרך היחידה שתוכל לשחזר את המידע שלך היא עם המפתח הזה.';

  @override
  String get recoveryKeySaveDescription =>
      'אנחנו לא מאחסנים את המפתח הזה, אנא שמור את המפתח 24 מילים הזה במקום בטוח.';

  @override
  String get doThisLater => 'עשה זאת מאוחר יותר';

  @override
  String get saveKey => 'שמור מפתח';

  @override
  String get recoveryKeySaved => 'Recovery key saved in Downloads folder!';

  @override
  String get noRecoveryKeyTitle => 'אין מפתח שחזור?';

  @override
  String get twoFactorAuthTitle => 'אימות דו-שלבי';

  @override
  String get enterCodeHint =>
      'הכנס את הקוד בעל 6 ספרות מתוך\nאפליקציית האימות שלך';

  @override
  String get lostDeviceTitle => 'איבדת את המכשיר?';

  @override
  String get enterRecoveryKeyHint => 'הזן את מפתח השחזור שלך';

  @override
  String get recover => 'שחזר';

  @override
  String get loggingOut => 'מתנתק...';

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
  String get areYouSureYouWantToLogout => 'האם את/ה בטוח/ה שאת/ה רוצה לצאת?';

  @override
  String get yesLogout => 'כן, התנתק';

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
  String get confirm => 'אשר';

  @override
  String get reEnterPassword => 'Re-enter password';

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
  String get emailAlreadyRegistered => 'Email already registered.';

  @override
  String get emailNotRegistered => 'Email not registered.';

  @override
  String get thisEmailIsAlreadyInUse =>
      'כתובת דואר אלקטרוני זאת כבר נמצאת בשימוש';

  @override
  String emailChangedTo(String newEmail) {
    return 'אימייל שונה ל-$newEmail';
  }

  @override
  String get authenticationFailedPleaseTryAgain => 'אימות נכשל, אנא נסה שוב';

  @override
  String get authenticationSuccessful => 'אימות הצליח!';

  @override
  String get sessionExpired => 'זמן החיבור הסתיים';

  @override
  String get incorrectRecoveryKey => 'מפתח שחזור שגוי';

  @override
  String get theRecoveryKeyYouEnteredIsIncorrect => 'המפתח שחזור שהזנת שגוי';

  @override
  String get twofactorAuthenticationSuccessfullyReset =>
      'אימות דו-שלבי אופס בהצלחה';

  @override
  String get noRecoveryKey => 'No recovery key';

  @override
  String get yourAccountHasBeenDeleted => 'Your account has been deleted';

  @override
  String get verificationId => 'Verification ID';

  @override
  String get yourVerificationCodeHasExpired => 'קוד האימות שלך פג תוקף';

  @override
  String get incorrectCode => 'קוד שגוי';

  @override
  String get sorryTheCodeYouveEnteredIsIncorrect =>
      'אנו מתנצלים, אבל הקוד שהזנת איננו נכון';

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
