import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'strings_localizations_ar.dart';
import 'strings_localizations_be.dart';
import 'strings_localizations_bg.dart';
import 'strings_localizations_ca.dart';
import 'strings_localizations_cs.dart';
import 'strings_localizations_da.dart';
import 'strings_localizations_de.dart';
import 'strings_localizations_el.dart';
import 'strings_localizations_en.dart';
import 'strings_localizations_es.dart';
import 'strings_localizations_et.dart';
import 'strings_localizations_fa.dart';
import 'strings_localizations_fi.dart';
import 'strings_localizations_fr.dart';
import 'strings_localizations_gu.dart';
import 'strings_localizations_he.dart';
import 'strings_localizations_hi.dart';
import 'strings_localizations_hu.dart';
import 'strings_localizations_id.dart';
import 'strings_localizations_it.dart';
import 'strings_localizations_ja.dart';
import 'strings_localizations_ka.dart';
import 'strings_localizations_km.dart';
import 'strings_localizations_ko.dart';
import 'strings_localizations_lt.dart';
import 'strings_localizations_lv.dart';
import 'strings_localizations_ml.dart';
import 'strings_localizations_nl.dart';
import 'strings_localizations_pl.dart';
import 'strings_localizations_pt.dart';
import 'strings_localizations_ro.dart';
import 'strings_localizations_ru.dart';
import 'strings_localizations_sk.dart';
import 'strings_localizations_sl.dart';
import 'strings_localizations_sr.dart';
import 'strings_localizations_sv.dart';
import 'strings_localizations_ti.dart';
import 'strings_localizations_tr.dart';
import 'strings_localizations_uk.dart';
import 'strings_localizations_vi.dart';
import 'strings_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of StringsLocalizations
/// returned by `StringsLocalizations.of(context)`.
///
/// Applications need to include `StringsLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/strings_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: StringsLocalizations.localizationsDelegates,
///   supportedLocales: StringsLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the StringsLocalizations.supportedLocales
/// property.
abstract class StringsLocalizations {
  StringsLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static StringsLocalizations of(BuildContext context) {
    return Localizations.of<StringsLocalizations>(
        context, StringsLocalizations)!;
  }

  static const LocalizationsDelegate<StringsLocalizations> delegate =
      _StringsLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('be'),
    Locale('bg'),
    Locale('ca'),
    Locale('cs'),
    Locale('da'),
    Locale('de'),
    Locale('el'),
    Locale('en'),
    Locale('es'),
    Locale('et'),
    Locale('fa'),
    Locale('fi'),
    Locale('fr'),
    Locale('gu'),
    Locale('he'),
    Locale('hi'),
    Locale('hu'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('ka'),
    Locale('km'),
    Locale('ko'),
    Locale('lt'),
    Locale('lv'),
    Locale('ml'),
    Locale('nl'),
    Locale('pl'),
    Locale('pt'),
    Locale('ro'),
    Locale('ru'),
    Locale('sk'),
    Locale('sl'),
    Locale('sr'),
    Locale('sv'),
    Locale('ti'),
    Locale('tr'),
    Locale('uk'),
    Locale('vi'),
    Locale('zh'),
    Locale('zh', 'CN'),
    Locale('zh', 'TW')
  ];

  /// Error message shown when the app cannot connect to Ente due to network host lookup failure
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to Ente, please check your network settings and contact support if the error persists.'**
  String get networkHostLookUpErr;

  /// Error message shown when the app cannot connect to Ente due to connection refused
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to Ente, please retry after sometime. If the error persists, please contact support.'**
  String get networkConnectionRefusedErr;

  /// Generic error message for temporary issues
  ///
  /// In en, this message translates to:
  /// **'It looks like something went wrong. Please retry after some time. If the error persists, please contact our support team.'**
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome;

  /// Generic error title
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Generic OK button label
  ///
  /// In en, this message translates to:
  /// **'Ok'**
  String get ok;

  /// FAQ link label
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// Contact support button label
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get contactSupport;

  /// Title for emailing logs dialog
  ///
  /// In en, this message translates to:
  /// **'Email your logs'**
  String get emailYourLogs;

  /// Message asking user to send logs to email address
  ///
  /// In en, this message translates to:
  /// **'Please send the logs to \n{toEmail}'**
  String pleaseSendTheLogsTo(String toEmail);

  /// Button to copy email address to clipboard
  ///
  /// In en, this message translates to:
  /// **'Copy email address'**
  String get copyEmailAddress;

  /// Button to export logs
  ///
  /// In en, this message translates to:
  /// **'Export logs'**
  String get exportLogs;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Message showing email address for support
  ///
  /// In en, this message translates to:
  /// **'Email us at {toEmail}'**
  String pleaseEmailUsAt(String toEmail);

  /// Snackbar message when email address is copied
  ///
  /// In en, this message translates to:
  /// **'Email address copied'**
  String get emailAddressCopied;

  /// Default subject for support emails
  ///
  /// In en, this message translates to:
  /// **'[Support]'**
  String get supportEmailSubject;

  /// Label for debug information in emails
  ///
  /// In en, this message translates to:
  /// **'Following information can help us in debugging if you are facing any issue'**
  String get clientDebugInfoLabel;

  /// Label for registered email in debug info
  ///
  /// In en, this message translates to:
  /// **'Registered email:'**
  String get registeredEmailLabel;

  /// Label for client information in debug info
  ///
  /// In en, this message translates to:
  /// **'Client:'**
  String get clientLabel;

  /// Label for version information in debug info
  ///
  /// In en, this message translates to:
  /// **'Version :'**
  String get versionLabel;

  /// Not available text
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// Label for reporting a bug
  ///
  /// In en, this message translates to:
  /// **'Report a bug'**
  String get reportABug;

  /// Body text for the logs dialog explaining what will be sent
  ///
  /// In en, this message translates to:
  /// **'This will send across logs to help us debug your issue. Please note that file names will be included to help track issues with specific files.'**
  String get logsDialogBody;

  /// Button to view logs
  ///
  /// In en, this message translates to:
  /// **'View logs'**
  String get viewLogs;

  /// Text showing user is connected to a custom endpoint
  ///
  /// In en, this message translates to:
  /// **'Connected to {endpoint}'**
  String customEndpoint(String endpoint);

  /// Label for save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Label for send button
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// Description text asking user if they want to save to storage or share with other apps
  ///
  /// In en, this message translates to:
  /// **'Do you want to save this to your storage (Downloads folder by default) or send it to other apps?'**
  String get saveOrSendDescription;

  /// Description text asking user if they want to save to storage (for platforms that don't support sharing)
  ///
  /// In en, this message translates to:
  /// **'Do you want to save this to your storage (Downloads folder by default)?'**
  String get saveOnlyDescription;

  /// Hint text for entering new email address
  ///
  /// In en, this message translates to:
  /// **'Enter your new email address'**
  String get enterNewEmailHint;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Verify button label
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// Title for invalid email error dialog
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get invalidEmailTitle;

  /// Message for invalid email error dialog
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get invalidEmailMessage;

  /// Please wait message
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get pleaseWait;

  /// Verify password button label
  ///
  /// In en, this message translates to:
  /// **'Verify password'**
  String get verifyPassword;

  /// Title for incorrect password error
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get incorrectPasswordTitle;

  /// Message asking user to try again
  ///
  /// In en, this message translates to:
  /// **'Please try again'**
  String get pleaseTryAgain;

  /// Enter password field label
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enterPassword;

  /// Hint for password field
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPasswordHint;

  /// Title for active sessions page
  ///
  /// In en, this message translates to:
  /// **'Active sessions'**
  String get activeSessions;

  /// Oops error title
  ///
  /// In en, this message translates to:
  /// **'Oops'**
  String get oops;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Something went wrong, please try again'**
  String get somethingWentWrongPleaseTryAgain;

  /// Warning message for logging out of current device
  ///
  /// In en, this message translates to:
  /// **'This will log you out of this device!'**
  String get thisWillLogYouOutOfThisDevice;

  /// Warning message for logging out of another device
  ///
  /// In en, this message translates to:
  /// **'This will log you out of the following device:'**
  String get thisWillLogYouOutOfTheFollowingDevice;

  /// Title for terminate session dialog
  ///
  /// In en, this message translates to:
  /// **'Terminate session?'**
  String get terminateSession;

  /// Terminate button label
  ///
  /// In en, this message translates to:
  /// **'Terminate'**
  String get terminate;

  /// Label for current device
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get thisDevice;

  /// Create account button label
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// Weak password strength label
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get weakStrength;

  /// Moderate password strength label
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get moderateStrength;

  /// Strong password strength label
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get strongStrength;

  /// Delete account button label
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// Message asking user why they want to delete account
  ///
  /// In en, this message translates to:
  /// **'We\'ll be sorry to see you go. Are you facing some issue?'**
  String get deleteAccountQuery;

  /// Button to confirm sending feedback
  ///
  /// In en, this message translates to:
  /// **'Yes, send feedback'**
  String get yesSendFeedbackAction;

  /// Button to proceed with account deletion
  ///
  /// In en, this message translates to:
  /// **'No, delete account'**
  String get noDeleteAccountAction;

  /// Title for authentication dialog before account deletion
  ///
  /// In en, this message translates to:
  /// **'Please authenticate to initiate account deletion'**
  String get initiateAccountDeleteTitle;

  /// Title for account deletion confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Confirm account deletion'**
  String get confirmAccountDeleteTitle;

  /// Message warning about account deletion consequences
  ///
  /// In en, this message translates to:
  /// **'This account is linked to other Ente apps, if you use any.\n\nYour uploaded data, across all Ente apps, will be scheduled for deletion, and your account will be permanently deleted.'**
  String get confirmAccountDeleteMessage;

  /// Delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Create new account button label
  ///
  /// In en, this message translates to:
  /// **'Create new account'**
  String get createNewAccount;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// Text to indicate the password strength
  ///
  /// In en, this message translates to:
  /// **'Password strength: {passwordStrengthValue}'**
  String passwordStrength(String passwordStrengthValue);

  /// Title asking how user heard about Ente
  ///
  /// In en, this message translates to:
  /// **'How did you hear about Ente? (optional)'**
  String get hearUsWhereTitle;

  /// Explanation for asking how user heard about Ente
  ///
  /// In en, this message translates to:
  /// **'We don\'t track app installs. It\'d help if you told us where you found us!'**
  String get hearUsExplanation;

  /// Terms agreement text for sign up
  ///
  /// In en, this message translates to:
  /// **'I agree to the <u-terms>terms of service</u-terms> and <u-policy>privacy policy</u-policy>'**
  String get signUpTerms;

  /// Terms of service title
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get termsOfServicesTitle;

  /// Privacy policy title
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyTitle;

  /// Warning about password loss
  ///
  /// In en, this message translates to:
  /// **'I understand that if I lose my password, I may lose my data since my data is <underline>end-to-end encrypted</underline>.'**
  String get ackPasswordLostWarning;

  /// Encryption label
  ///
  /// In en, this message translates to:
  /// **'Encryption'**
  String get encryption;

  /// Log in button label
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logInLabel;

  /// Welcome back message
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get welcomeBack;

  /// Terms agreement text for login
  ///
  /// In en, this message translates to:
  /// **'By clicking log in, I agree to the <u-terms>terms of service</u-terms> and <u-policy>privacy policy</u-policy>'**
  String get loginTerms;

  /// No internet connection error message
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// Message asking user to check internet connection
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection and try again.'**
  String get pleaseCheckYourInternetConnectionAndTryAgain;

  /// Verification failed error message
  ///
  /// In en, this message translates to:
  /// **'Verification failed, please try again'**
  String get verificationFailedPleaseTryAgain;

  /// Title for recreate password dialog
  ///
  /// In en, this message translates to:
  /// **'Recreate password'**
  String get recreatePasswordTitle;

  /// Body text for recreate password dialog
  ///
  /// In en, this message translates to:
  /// **'The current device is not powerful enough to verify your password, but we can regenerate in a way that works with all devices.\n\nPlease login using your recovery key and regenerate your password (you can use the same one again if you wish).'**
  String get recreatePasswordBody;

  /// Use recovery key button label
  ///
  /// In en, this message translates to:
  /// **'Use recovery key'**
  String get useRecoveryKey;

  /// Forgot password link label
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get forgotPassword;

  /// Change email button label
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get changeEmail;

  /// Verify email title
  ///
  /// In en, this message translates to:
  /// **'Verify email'**
  String get verifyEmail;

  /// Text to indicate that we have sent a mail to the user
  ///
  /// In en, this message translates to:
  /// **'We have sent a mail to <green>{email}</green>'**
  String weHaveSendEmailTo(String email);

  /// Message asking user to verify email before password reset
  ///
  /// In en, this message translates to:
  /// **'To reset your password, please verify your email first.'**
  String get toResetVerifyEmail;

  /// Message asking user to check inbox and spam folder
  ///
  /// In en, this message translates to:
  /// **'Please check your inbox (and spam) to complete verification'**
  String get checkInboxAndSpamFolder;

  /// Hint for entering verification code
  ///
  /// In en, this message translates to:
  /// **'Tap to enter code'**
  String get tapToEnterCode;

  /// No description provided for @sendEmail.
  ///
  /// In en, this message translates to:
  /// **'Send email'**
  String get sendEmail;

  /// Resend email button label
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get resendEmail;

  /// Message when passkey verification is pending
  ///
  /// In en, this message translates to:
  /// **'Verification is still pending'**
  String get passKeyPendingVerification;

  /// Login session expired title
  ///
  /// In en, this message translates to:
  /// **'Session expired'**
  String get loginSessionExpired;

  /// Login session expired details
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please login again.'**
  String get loginSessionExpiredDetails;

  /// Passkey authentication title
  ///
  /// In en, this message translates to:
  /// **'Passkey verification'**
  String get passkeyAuthTitle;

  /// Waiting for verification message
  ///
  /// In en, this message translates to:
  /// **'Waiting for verification...'**
  String get waitingForVerification;

  /// Try again button label
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// Check status button label
  ///
  /// In en, this message translates to:
  /// **'Check status'**
  String get checkStatus;

  /// Login with TOTP button label
  ///
  /// In en, this message translates to:
  /// **'Login with TOTP'**
  String get loginWithTOTP;

  /// Recover account button label
  ///
  /// In en, this message translates to:
  /// **'Recover account'**
  String get recoverAccount;

  /// Set password title
  ///
  /// In en, this message translates to:
  /// **'Set password'**
  String get setPasswordTitle;

  /// Change password title
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordTitle;

  /// Reset password title
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordTitle;

  /// Encryption keys title
  ///
  /// In en, this message translates to:
  /// **'Encryption keys'**
  String get encryptionKeys;

  /// Prompt to enter password for encryption
  ///
  /// In en, this message translates to:
  /// **'Enter a password we can use to encrypt your data'**
  String get enterPasswordToEncrypt;

  /// Prompt to enter new password for encryption
  ///
  /// In en, this message translates to:
  /// **'Enter a new password we can use to encrypt your data'**
  String get enterNewPasswordToEncrypt;

  /// Warning about password storage
  ///
  /// In en, this message translates to:
  /// **'We don\'t store this password, so if you forget, <underline>we cannot decrypt your data</underline>'**
  String get passwordWarning;

  /// How it works button label
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get howItWorks;

  /// Generating encryption keys message
  ///
  /// In en, this message translates to:
  /// **'Generating encryption keys...'**
  String get generatingEncryptionKeys;

  /// Password changed successfully message
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccessfully;

  /// Sign out from other devices title
  ///
  /// In en, this message translates to:
  /// **'Sign out from other devices'**
  String get signOutFromOtherDevices;

  /// Sign out other devices explanation
  ///
  /// In en, this message translates to:
  /// **'If you think someone might know your password, you can force all other devices using your account to sign out.'**
  String get signOutOtherBody;

  /// Sign out other devices button label
  ///
  /// In en, this message translates to:
  /// **'Sign out other devices'**
  String get signOutOtherDevices;

  /// Do not sign out button label
  ///
  /// In en, this message translates to:
  /// **'Do not sign out'**
  String get doNotSignOut;

  /// Generating encryption keys title
  ///
  /// In en, this message translates to:
  /// **'Generating encryption keys...'**
  String get generatingEncryptionKeysTitle;

  /// Continue button label
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// Insecure device warning title
  ///
  /// In en, this message translates to:
  /// **'Insecure device'**
  String get insecureDevice;

  /// Error message for insecure device
  ///
  /// In en, this message translates to:
  /// **'Sorry, we could not generate secure keys on this device.\n\nplease sign up from a different device.'**
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease;

  /// Recovery key copied message
  ///
  /// In en, this message translates to:
  /// **'Recovery key copied to clipboard'**
  String get recoveryKeyCopiedToClipboard;

  /// Recovery key label
  ///
  /// In en, this message translates to:
  /// **'Recovery key'**
  String get recoveryKey;

  /// Recovery key importance explanation
  ///
  /// In en, this message translates to:
  /// **'If you forget your password, the only way you can recover your data is with this key.'**
  String get recoveryKeyOnForgotPassword;

  /// Recovery key save description
  ///
  /// In en, this message translates to:
  /// **'We don\'t store this key, please save this 24 word key in a safe place.'**
  String get recoveryKeySaveDescription;

  /// Do this later button label
  ///
  /// In en, this message translates to:
  /// **'Do this later'**
  String get doThisLater;

  /// Save key button label
  ///
  /// In en, this message translates to:
  /// **'Save key'**
  String get saveKey;

  /// Recovery key saved confirmation message
  ///
  /// In en, this message translates to:
  /// **'Recovery key saved in Downloads folder!'**
  String get recoveryKeySaved;

  /// No recovery key title
  ///
  /// In en, this message translates to:
  /// **'No recovery key?'**
  String get noRecoveryKeyTitle;

  /// Two-factor authentication title
  ///
  /// In en, this message translates to:
  /// **'Two-factor authentication'**
  String get twoFactorAuthTitle;

  /// Hint for entering 2FA code
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code from\nyour authenticator app'**
  String get enterCodeHint;

  /// Lost device title
  ///
  /// In en, this message translates to:
  /// **'Lost device?'**
  String get lostDeviceTitle;

  /// Hint for entering recovery key
  ///
  /// In en, this message translates to:
  /// **'Enter your recovery key'**
  String get enterRecoveryKeyHint;

  /// Recover button label
  ///
  /// In en, this message translates to:
  /// **'Recover'**
  String get recover;

  /// Message shown while logging out
  ///
  /// In en, this message translates to:
  /// **'Logging out...'**
  String get loggingOut;

  /// Immediately option for auto lock timing
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get immediately;

  /// App lock setting title
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get appLock;

  /// Auto lock setting title
  ///
  /// In en, this message translates to:
  /// **'Auto lock'**
  String get autoLock;

  /// Error when no system lock is found
  ///
  /// In en, this message translates to:
  /// **'No system lock found'**
  String get noSystemLockFound;

  /// Instructions for enabling device lock
  ///
  /// In en, this message translates to:
  /// **'To enable device lock, please setup device passcode or screen lock in your system settings.'**
  String get deviceLockEnablePreSteps;

  /// Description of app lock feature
  ///
  /// In en, this message translates to:
  /// **'Choose between your device\'s default lock screen and a custom lock screen with a PIN or password.'**
  String get appLockDescription;

  /// Device lock option title
  ///
  /// In en, this message translates to:
  /// **'Device lock'**
  String get deviceLock;

  /// PIN lock option title
  ///
  /// In en, this message translates to:
  /// **'Pin lock'**
  String get pinLock;

  /// Description of auto lock feature
  ///
  /// In en, this message translates to:
  /// **'Time after which the app locks after being put in the background'**
  String get autoLockFeatureDescription;

  /// Hide content setting title
  ///
  /// In en, this message translates to:
  /// **'Hide content'**
  String get hideContent;

  /// Description of hide content feature on Android
  ///
  /// In en, this message translates to:
  /// **'Hides app content in the app switcher and disables screenshots'**
  String get hideContentDescriptionAndroid;

  /// Description of hide content feature on iOS
  ///
  /// In en, this message translates to:
  /// **'Hides app content in the app switcher'**
  String get hideContentDescriptioniOS;

  /// Message shown when too many incorrect attempts are made
  ///
  /// In en, this message translates to:
  /// **'Too many incorrect attempts'**
  String get tooManyIncorrectAttempts;

  /// Message prompting user to tap to unlock
  ///
  /// In en, this message translates to:
  /// **'Tap to unlock'**
  String get tapToUnlock;

  /// Confirmation message before logout
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get areYouSureYouWantToLogout;

  /// Confirmation button for logout
  ///
  /// In en, this message translates to:
  /// **'Yes, logout'**
  String get yesLogout;

  /// Message prompting authentication to view secrets
  ///
  /// In en, this message translates to:
  /// **'Please authenticate to view your secrets'**
  String get authToViewSecrets;

  /// Next button label
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Set new password title
  ///
  /// In en, this message translates to:
  /// **'Set new password'**
  String get setNewPassword;

  /// Enter PIN prompt
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get enterPin;

  /// Set new PIN title
  ///
  /// In en, this message translates to:
  /// **'Set new PIN'**
  String get setNewPin;

  /// Confirm button label
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Re-enter password prompt
  ///
  /// In en, this message translates to:
  /// **'Re-enter password'**
  String get reEnterPassword;

  /// Re-enter PIN prompt
  ///
  /// In en, this message translates to:
  /// **'Re-enter PIN'**
  String get reEnterPin;

  /// Hint message advising the user how to authenticate with biometrics. It is used on Android side. Maximum 60 characters.
  ///
  /// In en, this message translates to:
  /// **'Verify identity'**
  String get androidBiometricHint;

  /// Message to let the user know that authentication was failed. It is used on Android side. Maximum 60 characters.
  ///
  /// In en, this message translates to:
  /// **'Not recognized. Try again.'**
  String get androidBiometricNotRecognized;

  /// Message to let the user know that authentication was successful. It is used on Android side. Maximum 60 characters.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get androidBiometricSuccess;

  /// Message showed on a button that the user can click to leave the current dialog. It is used on Android side. Maximum 30 characters.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get androidCancelButton;

  /// Message showed as a title in a dialog which indicates the user that they need to scan biometric to continue. It is used on Android side. Maximum 60 characters.
  ///
  /// In en, this message translates to:
  /// **'Authentication required'**
  String get androidSignInTitle;

  /// Message showed as a title in a dialog which indicates the user has not set up biometric authentication on their device. It is used on Android side. Maximum 60 characters.
  ///
  /// In en, this message translates to:
  /// **'Biometric required'**
  String get androidBiometricRequiredTitle;

  /// Message showed as a title in a dialog which indicates the user has not set up credentials authentication on their device. It is used on Android side. Maximum 60 characters.
  ///
  /// In en, this message translates to:
  /// **'Device credentials required'**
  String get androidDeviceCredentialsRequiredTitle;

  /// Message advising the user to go to the settings and configure device credentials on their device. It shows in a dialog on Android side.
  ///
  /// In en, this message translates to:
  /// **'Device credentials required'**
  String get androidDeviceCredentialsSetupDescription;

  /// Message showed on a button that the user can click to go to settings pages from the current dialog. It is used on both Android and iOS side. Maximum 30 characters.
  ///
  /// In en, this message translates to:
  /// **'Go to settings'**
  String get goToSettings;

  /// Message advising the user to go to the settings and configure biometric on their device. It shows in a dialog on Android side.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication is not set up on your device. Go to \'Settings > Security\' to add biometric authentication.'**
  String get androidGoToSettingsDescription;

  /// Message advising the user to re-enable biometrics on their device. It shows in a dialog on iOS side.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication is disabled. Please lock and unlock your screen to enable it.'**
  String get iOSLockOut;

  /// Message showed on a button that the user can click to leave the current dialog. It is used on iOS side. Maximum 30 characters.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get iOSOkButton;

  /// Error message when email is already registered
  ///
  /// In en, this message translates to:
  /// **'Email already registered.'**
  String get emailAlreadyRegistered;

  /// Error message when email is not registered
  ///
  /// In en, this message translates to:
  /// **'Email not registered.'**
  String get emailNotRegistered;

  /// Error message when email is already in use
  ///
  /// In en, this message translates to:
  /// **'This email is already in use'**
  String get thisEmailIsAlreadyInUse;

  /// Message when email has been changed
  ///
  /// In en, this message translates to:
  /// **'Email changed to {newEmail}'**
  String emailChangedTo(String newEmail);

  /// Error message when authentication fails
  ///
  /// In en, this message translates to:
  /// **'Authentication failed, please try again'**
  String get authenticationFailedPleaseTryAgain;

  /// Success message when authentication is successful
  ///
  /// In en, this message translates to:
  /// **'Authentication successful!'**
  String get authenticationSuccessful;

  /// Error message when session has expired
  ///
  /// In en, this message translates to:
  /// **'Session expired'**
  String get sessionExpired;

  /// Error message when recovery key is incorrect
  ///
  /// In en, this message translates to:
  /// **'Incorrect recovery key'**
  String get incorrectRecoveryKey;

  /// Detailed error message when recovery key is incorrect
  ///
  /// In en, this message translates to:
  /// **'The recovery key you entered is incorrect'**
  String get theRecoveryKeyYouEnteredIsIncorrect;

  /// Message when two-factor authentication is successfully reset
  ///
  /// In en, this message translates to:
  /// **'Two-factor authentication successfully reset'**
  String get twofactorAuthenticationSuccessfullyReset;

  /// Error message when no recovery key is found
  ///
  /// In en, this message translates to:
  /// **'No recovery key'**
  String get noRecoveryKey;

  /// Confirmation message when account has been deleted
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted'**
  String get yourAccountHasBeenDeleted;

  /// Label for verification ID
  ///
  /// In en, this message translates to:
  /// **'Verification ID'**
  String get verificationId;

  /// Error message when verification code has expired
  ///
  /// In en, this message translates to:
  /// **'Your verification code has expired'**
  String get yourVerificationCodeHasExpired;

  /// Error message when code is incorrect
  ///
  /// In en, this message translates to:
  /// **'Incorrect code'**
  String get incorrectCode;

  /// Detailed error message when code is incorrect
  ///
  /// In en, this message translates to:
  /// **'Sorry, the code you\'ve entered is incorrect'**
  String get sorryTheCodeYouveEnteredIsIncorrect;

  /// Label for developer settings
  ///
  /// In en, this message translates to:
  /// **'Developer settings'**
  String get developerSettings;

  /// Label for server endpoint setting
  ///
  /// In en, this message translates to:
  /// **'Server endpoint'**
  String get serverEndpoint;

  /// Error message when endpoint is invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid endpoint'**
  String get invalidEndpoint;

  /// Detailed error message when endpoint is invalid
  ///
  /// In en, this message translates to:
  /// **'Sorry, the endpoint you entered is invalid. Please enter a valid endpoint and try again.'**
  String get invalidEndpointMessage;

  /// Success message when endpoint is updated
  ///
  /// In en, this message translates to:
  /// **'Endpoint updated successfully'**
  String get endpointUpdatedMessage;
}

class _StringsLocalizationsDelegate
    extends LocalizationsDelegate<StringsLocalizations> {
  const _StringsLocalizationsDelegate();

  @override
  Future<StringsLocalizations> load(Locale locale) {
    return SynchronousFuture<StringsLocalizations>(
        lookupStringsLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'be',
        'bg',
        'ca',
        'cs',
        'da',
        'de',
        'el',
        'en',
        'es',
        'et',
        'fa',
        'fi',
        'fr',
        'gu',
        'he',
        'hi',
        'hu',
        'id',
        'it',
        'ja',
        'ka',
        'km',
        'ko',
        'lt',
        'lv',
        'ml',
        'nl',
        'pl',
        'pt',
        'ro',
        'ru',
        'sk',
        'sl',
        'sr',
        'sv',
        'ti',
        'tr',
        'uk',
        'vi',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_StringsLocalizationsDelegate old) => false;
}

StringsLocalizations lookupStringsLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'CN':
            return StringsLocalizationsZhCn();
          case 'TW':
            return StringsLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return StringsLocalizationsAr();
    case 'be':
      return StringsLocalizationsBe();
    case 'bg':
      return StringsLocalizationsBg();
    case 'ca':
      return StringsLocalizationsCa();
    case 'cs':
      return StringsLocalizationsCs();
    case 'da':
      return StringsLocalizationsDa();
    case 'de':
      return StringsLocalizationsDe();
    case 'el':
      return StringsLocalizationsEl();
    case 'en':
      return StringsLocalizationsEn();
    case 'es':
      return StringsLocalizationsEs();
    case 'et':
      return StringsLocalizationsEt();
    case 'fa':
      return StringsLocalizationsFa();
    case 'fi':
      return StringsLocalizationsFi();
    case 'fr':
      return StringsLocalizationsFr();
    case 'gu':
      return StringsLocalizationsGu();
    case 'he':
      return StringsLocalizationsHe();
    case 'hi':
      return StringsLocalizationsHi();
    case 'hu':
      return StringsLocalizationsHu();
    case 'id':
      return StringsLocalizationsId();
    case 'it':
      return StringsLocalizationsIt();
    case 'ja':
      return StringsLocalizationsJa();
    case 'ka':
      return StringsLocalizationsKa();
    case 'km':
      return StringsLocalizationsKm();
    case 'ko':
      return StringsLocalizationsKo();
    case 'lt':
      return StringsLocalizationsLt();
    case 'lv':
      return StringsLocalizationsLv();
    case 'ml':
      return StringsLocalizationsMl();
    case 'nl':
      return StringsLocalizationsNl();
    case 'pl':
      return StringsLocalizationsPl();
    case 'pt':
      return StringsLocalizationsPt();
    case 'ro':
      return StringsLocalizationsRo();
    case 'ru':
      return StringsLocalizationsRu();
    case 'sk':
      return StringsLocalizationsSk();
    case 'sl':
      return StringsLocalizationsSl();
    case 'sr':
      return StringsLocalizationsSr();
    case 'sv':
      return StringsLocalizationsSv();
    case 'ti':
      return StringsLocalizationsTi();
    case 'tr':
      return StringsLocalizationsTr();
    case 'uk':
      return StringsLocalizationsUk();
    case 'vi':
      return StringsLocalizationsVi();
    case 'zh':
      return StringsLocalizationsZh();
  }

  throw FlutterError(
      'StringsLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
