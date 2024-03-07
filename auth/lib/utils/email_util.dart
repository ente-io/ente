import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:email_validator/email_validator.dart';
import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/core/logging/super_logging.dart';
import 'package:ente_auth/ente_theme_data.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/ui/components/buttons/button_widget.dart';
import 'package:ente_auth/ui/components/dialog_widget.dart';
import 'package:ente_auth/ui/components/models/button_type.dart';
import 'package:ente_auth/ui/tools/debug/log_file_viewer.dart';
// import 'package:ente_auth/ui/tools/debug/log_file_viewer.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:ente_auth/utils/toast_util.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
// import 'package:open_mail_app/open_mail_app.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

final Logger _logger = Logger('email_util');

bool isValidEmail(String email) {
  return EmailValidator.validate(email);
}

Future<void> sendLogs(
  BuildContext context,
  String title,
  String toEmail, {
  Function? postShare,
  String? subject,
  String? body,
}) async {
  final l10n = context.l10n;
  final List<Widget> actions = [
    TextButton(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(
            Icons.feed_outlined,
            color: Theme.of(context).iconTheme.color?.withOpacity(0.85),
          ),
          const Padding(padding: EdgeInsets.all(4)),
          Text(
            l10n.viewLogsAction,
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .defaultTextColor
                  .withOpacity(0.85),
            ),
          ),
        ],
      ),
      onPressed: () async {
        // ignore: unawaited_futures
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return LogFileViewer(SuperLogging.logFile!);
          },
          barrierColor: Colors.black87,
          barrierDismissible: false,
        );
      },
    ),
    TextButton(
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.alternativeColor,
        ),
      ),
      onPressed: () async {
        Navigator.of(context, rootNavigator: true).pop('dialog');
        await _sendLogs(context, toEmail, subject, body);
        if (postShare != null) {
          postShare();
        }
      },
    ),
  ];
  final List<Widget> content = [];
  content.addAll(
    [
      Text(
        l10n.sendLogsDescription,
        style: const TextStyle(
          height: 1.5,
          fontSize: 16,
        ),
      ),
      const Padding(padding: EdgeInsets.all(12)),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: actions,
      ),
    ],
  );
  final confirmation = AlertDialog(
    title: Text(
      title,
      style: const TextStyle(
        fontSize: 18,
      ),
    ),
    content: SingleChildScrollView(
      child: ListBody(
        children: content,
      ),
    ),
  );
  // ignore: unawaited_futures
  showDialog(
    context: context,
    builder: (_) {
      return confirmation;
    },
  );
}

Future<void> _sendLogs(
  BuildContext context,
  String toEmail,
  String? subject,
  String? body,
) async {
  final String zipFilePath = await getZippedLogsFile(context);
  final Email email = Email(
    recipients: [toEmail],
    subject: subject ?? '',
    body: body ?? '',
    attachmentPaths: [zipFilePath],
    isHTML: false,
  );
  try {
    await FlutterEmailSender.send(email);
  } catch (e, s) {
    _logger.severe('email sender failed', e, s);
    await shareLogs(context, toEmail, zipFilePath);
  }
}

Future<String> getZippedLogsFile(BuildContext context) async {
  final l10n = context.l10n;
  final dialog = createProgressDialog(context, l10n.preparingLogsTitle);
  await dialog.show();
  final logsPath = (await getApplicationSupportDirectory()).path;
  final logsDirectory = Directory(logsPath + "/logs");
  final tempPath = (await getTemporaryDirectory()).path;
  final zipFilePath =
      tempPath + "/logs-${Configuration.instance.getUserID() ?? 0}.zip";
  final encoder = ZipFileEncoder();
  encoder.create(zipFilePath);
  await encoder.addDirectory(logsDirectory);
  encoder.close();
  await dialog.hide();
  return zipFilePath;
}

Future<void> shareLogs(
  BuildContext context,
  String toEmail,
  String zipFilePath,
) async {
  final result = await showDialogWidget(
    context: context,
    title: context.l10n.emailYourLogs,
    body: context.l10n.pleaseSendTheLogsTo(toEmail),
    buttons: [
      ButtonWidget(
        buttonType: ButtonType.neutral,
        labelText: context.l10n.copyEmailAddress,
        isInAlert: true,
        buttonAction: ButtonAction.first,
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: toEmail));
        },
        shouldShowSuccessConfirmation: true,
      ),
      ButtonWidget(
        buttonType: ButtonType.neutral,
        labelText: context.l10n.exportLogs,
        isInAlert: true,
        buttonAction: ButtonAction.second,
      ),
      ButtonWidget(
        buttonType: ButtonType.secondary,
        labelText: context.l10n.cancel,
        isInAlert: true,
        buttonAction: ButtonAction.cancel,
      ),
    ],
  );
  if (result?.action != null && result!.action == ButtonAction.second) {
    await exportLogs(context, zipFilePath);
  }
}

Future<void> exportLogs(BuildContext context, String zipFilePath) async {
  final Size size = MediaQuery.of(context).size;
  if (Platform.isAndroid) {
    DateTime now = DateTime.now().toUtc();
    String shortMonthName = DateFormat('MMM').format(now); // Short month name
    String logFileName =
        'ente-logs-${now.year}-$shortMonthName-${now.day}-${now.hour}-${now.minute}';
    await FileSaver.instance.saveAs(
      name: logFileName,
      filePath: zipFilePath,
      mimeType: MimeType.zip,
      ext: 'zip',
    );
  } else {
    await Share.shareXFiles(
      [XFile(zipFilePath, mimeType: 'application/zip')],
      sharePositionOrigin: Rect.fromLTWH(0, 0, size.width, size.height / 2),
    );
  }
}

Future<void> sendEmail(
  BuildContext context, {
  required String to,
  String? subject,
  String? body,
}) async {
  try {
    final String clientDebugInfo = await _clientInfo();
    final String _subject = subject ?? '[Support]';
    final String _body = (body ?? '') + clientDebugInfo;
    // final EmailContent email = EmailContent(
    //   to: [
    //     to,
    //   ],
    //   subject: subject ?? '[Support]',
    //   body: (body ?? '') + clientDebugInfo,
    // );
    if (Platform.isAndroid) {
      // Special handling due to issue in proton mail android client
      // https://github.com/ente-io/frame/pull/253
      final Uri params = Uri(
        scheme: 'mailto',
        path: to,
        query: 'subject=$_subject&body=$_body',
      );
      if (await canLaunchUrl(params)) {
        await launchUrl(params);
      } else {
        // this will trigger _showNoMailAppsDialog
        throw Exception('Could not launch ${params.toString()}');
      }
    } else {
      _showNoMailAppsDialog(context, to);
    }
  } catch (e) {
    _logger.severe("Failed to send email to $to", e);
    _showNoMailAppsDialog(context, to);
  }
}

Future<String> _clientInfo() async {
  final packageInfo = await PackageInfo.fromPlatform();
  final String debugInfo =
      '\n\n\n\n ------------------- \nFollowing information can '
      'help us in debugging if you are facing any issue '
      '\nRegistered email: ${Configuration.instance.getEmail()}'
      '\nClient: ${packageInfo.packageName}'
      '\nVersion : ${packageInfo.version}';
  return debugInfo;
}

void _showNoMailAppsDialog(BuildContext context, String toEmail) {
  final l10n = context.l10n;
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(l10n.emailUsMessage(toEmail)),
        actions: <Widget>[
          TextButton(
            child: Text(l10n.copyEmailAction),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: toEmail));
              showShortToast(context, l10n.copied);
            },
          ),
          TextButton(
            child: Text(l10n.ok),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      );
    },
  );
}
