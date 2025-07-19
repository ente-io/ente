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
      'غير قادر على الاتصال بـ Ente، يرجى إعادة المحاولة بعد فترة. إذا استمر الخطأ، يرجى الاتصال بالدعم.';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      'يبدو أن خطأ ما حدث. يرجى إعادة المحاولة بعد بعض الوقت. إذا استمر الخطأ، يرجى الاتصال بفريق الدعم.';

  @override
  String get error => 'خطأ';

  @override
  String get ok => 'موافق';

  @override
  String get faq => 'الأسئلة الشائعة';

  @override
  String get contactSupport => 'اتصل بالدعم';

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
  String get cancel => 'Cancel';

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
  String get enteLogsPrefix => 'ente-logs-';

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
  String get save => 'Save';

  @override
  String get send => 'Send';

  @override
  String get saveOrSendDescription =>
      'Do you want to save this to your storage (Downloads folder by default) or send it to other apps?';

  @override
  String get saveOnlyDescription =>
      'Do you want to save this to your storage (Downloads folder by default)?';
}
