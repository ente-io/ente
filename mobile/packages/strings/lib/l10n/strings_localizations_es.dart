// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class StringsLocalizationsEs extends StringsLocalizations {
  StringsLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get networkHostLookUpErr =>
      'No se puede conectar a Ente, por favor verifica tu configuración de red y ponte en contacto con el soporte si el error persiste.';

  @override
  String get networkConnectionRefusedErr =>
      'No se puede conectar a Ente. Por favor, vuelve a intentarlo pasado un tiempo. Si el error persiste, ponte en contacto con el soporte técnico.';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      'Parece que algo salió mal. Por favor, vuelve a intentarlo pasado un tiempo. Si el error persiste, ponte en contacto con nuestro equipo de soporte.';

  @override
  String get error => 'Error';

  @override
  String get ok => 'Ok';

  @override
  String get faq => 'Preguntas Frecuentes';

  @override
  String get contactSupport => 'Ponerse en contacto con el equipo de soporte';

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
}
