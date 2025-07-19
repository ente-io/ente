// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class StringsLocalizationsFr extends StringsLocalizations {
  StringsLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get networkHostLookUpErr =>
      'Impossible de se connecter à Ente, veuillez vérifier vos paramètres réseau et contacter le support si l\'erreur persiste.';

  @override
  String get networkConnectionRefusedErr =>
      'Impossible de se connecter à Ente, veuillez réessayer après un certain temps. Si l\'erreur persiste, veuillez contacter le support.';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      'Il semble qu\'une erreur s\'est produite. Veuillez réessayer après un certain temps. Si l\'erreur persiste, veuillez contacter notre équipe d\'assistance.';

  @override
  String get error => 'Erreur';

  @override
  String get ok => 'Ok';

  @override
  String get faq => 'FAQ';

  @override
  String get contactSupport => 'Contacter le support';

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
  String customEndpoint(Object endpoint) {
    return 'Connected to $endpoint';
  }
}
