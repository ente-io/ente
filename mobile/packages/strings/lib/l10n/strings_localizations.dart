import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'strings_localizations_ar.dart';
import 'strings_localizations_bg.dart';
import 'strings_localizations_cs.dart';
import 'strings_localizations_da.dart';
import 'strings_localizations_el.dart';
import 'strings_localizations_en.dart';
import 'strings_localizations_es.dart';
import 'strings_localizations_fr.dart';
import 'strings_localizations_id.dart';
import 'strings_localizations_ja.dart';
import 'strings_localizations_ko.dart';
import 'strings_localizations_lt.dart';
import 'strings_localizations_nl.dart';
import 'strings_localizations_pl.dart';
import 'strings_localizations_pt.dart';
import 'strings_localizations_ru.dart';
import 'strings_localizations_sk.dart';
import 'strings_localizations_sr.dart';
import 'strings_localizations_sv.dart';
import 'strings_localizations_tr.dart';
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
    Locale('bg'),
    Locale('cs'),
    Locale('da'),
    Locale('el'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('id'),
    Locale('ja'),
    Locale('ko'),
    Locale('lt'),
    Locale('nl'),
    Locale('pl'),
    Locale('pt'),
    Locale('ru'),
    Locale('sk'),
    Locale('sr'),
    Locale('sv'),
    Locale('tr'),
    Locale('vi'),
    Locale('zh'),
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

  /// Prefix for log file names
  ///
  /// In en, this message translates to:
  /// **'ente-logs-'**
  String get enteLogsPrefix;

  /// Name of logs directory
  ///
  /// In en, this message translates to:
  /// **'logs'**
  String get logsDirectoryName;

  /// Name of zipped log file
  ///
  /// In en, this message translates to:
  /// **'logs.zip'**
  String get logsZipFileName;

  /// File extension for zip files
  ///
  /// In en, this message translates to:
  /// **'zip'**
  String get zipFileExtension;

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

  /// No description provided for @customEndpoint.
  ///
  /// In en, this message translates to:
  /// **'Connected to {endpoint}'**
  String customEndpoint(Object endpoint);
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
        'bg',
        'cs',
        'da',
        'el',
        'en',
        'es',
        'fr',
        'id',
        'ja',
        'ko',
        'lt',
        'nl',
        'pl',
        'pt',
        'ru',
        'sk',
        'sr',
        'sv',
        'tr',
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
    case 'bg':
      return StringsLocalizationsBg();
    case 'cs':
      return StringsLocalizationsCs();
    case 'da':
      return StringsLocalizationsDa();
    case 'el':
      return StringsLocalizationsEl();
    case 'en':
      return StringsLocalizationsEn();
    case 'es':
      return StringsLocalizationsEs();
    case 'fr':
      return StringsLocalizationsFr();
    case 'id':
      return StringsLocalizationsId();
    case 'ja':
      return StringsLocalizationsJa();
    case 'ko':
      return StringsLocalizationsKo();
    case 'lt':
      return StringsLocalizationsLt();
    case 'nl':
      return StringsLocalizationsNl();
    case 'pl':
      return StringsLocalizationsPl();
    case 'pt':
      return StringsLocalizationsPt();
    case 'ru':
      return StringsLocalizationsRu();
    case 'sk':
      return StringsLocalizationsSk();
    case 'sr':
      return StringsLocalizationsSr();
    case 'sv':
      return StringsLocalizationsSv();
    case 'tr':
      return StringsLocalizationsTr();
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
