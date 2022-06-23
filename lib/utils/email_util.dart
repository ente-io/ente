import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photos/core/error-reporting/super_logging.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/ui/common/dialogs.dart';
import 'package:photos/ui/log_file_viewer.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:share_plus/share_plus.dart';

final Logger _logger = Logger('email_util');

bool isValidEmail(String email) {
  return EmailValidator.validate(email);
}

Future<void> sendLogs(
  BuildContext context,
  String title,
  String toEmail, {
  Function postShare,
  String subject,
  String body,
}) async {
  final List<Widget> actions = [
    TextButton(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(
            Icons.feed_outlined,
            color: Theme.of(context).iconTheme.color.withOpacity(0.85),
          ),
          Padding(padding: EdgeInsets.all(4)),
          Text(
            "View logs",
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
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return LogFileViewer(SuperLogging.logFile);
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
          color: Theme.of(context).buttonColor,
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
        "This will send across logs to help us debug your issue. Please note that file names will be included to help track issues with specific files.",
        style: TextStyle(
          height: 1.5,
          fontSize: 16,
        ),
      ),
      Padding(padding: EdgeInsets.all(12)),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: actions,
      ),
    ],
  );
  final confirmation = AlertDialog(
    title: Text(
      title,
      style: TextStyle(
        fontSize: 18,
      ),
    ),
    content: SingleChildScrollView(
      child: ListBody(
        children: content,
      ),
    ),
  );
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
  String subject,
  String body,
) async {
  String zipFilePath = await getZippedLogsFile(context);
  final Email email = Email(
    recipients: [toEmail],
    subject: subject,
    body: body,
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
  final dialog = createProgressDialog(context, "Preparing logs...");
  await dialog.show();
  final tempPath = (await getTemporaryDirectory()).path;
  final zipFilePath = tempPath + "/logs.zip";
  final logsDirectory = Directory(tempPath + "/logs");
  var encoder = ZipFileEncoder();
  encoder.create(zipFilePath);
  encoder.addDirectory(logsDirectory);
  encoder.close();
  await dialog.hide();
  return zipFilePath;
}

Future<void> shareLogs(
  BuildContext context,
  String toEmail,
  String zipFilePath,
) async {
  final result = await showChoiceDialog(
    context,
    "Email logs",
    "Please send the logs to $toEmail",
    firstAction: "Copy email",
    secondAction: "Send",
  );
  if (result != null && result == DialogUserChoice.firstChoice) {
    await Clipboard.setData(ClipboardData(text: toEmail));
  }
  final Size size = MediaQuery.of(context).size;
  await Share.shareFiles(
    [zipFilePath],
    sharePositionOrigin: Rect.fromLTWH(0, 0, size.width, size.height / 2),
  );
}
