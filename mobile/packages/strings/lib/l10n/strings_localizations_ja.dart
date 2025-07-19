// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class StringsLocalizationsJa extends StringsLocalizations {
  StringsLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get networkHostLookUpErr =>
      'Enteに接続できませんでした。ネットワーク設定を確認し、エラーが解決しない場合はサポートにお問い合わせください。';

  @override
  String get networkConnectionRefusedErr =>
      'Enteに接続できません。しばらくしてから再試行してください。エラーが継続する場合は、サポートにお問い合わせください。';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      '問題が発生したようです。しばらくしてから再試行してください。エラーが継続する場合は、サポートチームにお問い合わせください。';

  @override
  String get error => 'エラー';

  @override
  String get ok => 'OK';

  @override
  String get faq => 'FAQ';

  @override
  String get contactSupport => 'サポートに連絡する';

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
}
