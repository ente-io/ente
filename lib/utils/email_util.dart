import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photos/ui/log_file_viewer.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:share/share.dart';
import 'package:super_logging/super_logging.dart';

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
            color: Colors.white.withOpacity(0.85),
          ),
          Padding(padding: EdgeInsets.all(4)),
          Text(
            "view logs",
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
      onPressed: () async {
        // routeToPage(context, LogFileViewer(SuperLogging.logFile));
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
        "this will send across logs and metrics that will help us debug your issue better",
        style: TextStyle(
          height: 1.5,
          fontFamily: 'Ubuntu',
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
    BuildContext context, String toEmail, String subject, String body) async {
  final dialog = createProgressDialog(context, "preparing logs...");
  await dialog.show();
  final tempPath = (await getTemporaryDirectory()).path;
  final zipFilePath = tempPath + "/logs.zip";
  final logsDirectory = Directory(tempPath + "/logs");
  var encoder = ZipFileEncoder();
  encoder.create(zipFilePath);
  encoder.addDirectory(logsDirectory);
  encoder.close();
  await dialog.hide();
  final Email email = Email(
    recipients: [toEmail],
    subject: subject,
    body: body,
    attachmentPaths: [zipFilePath],
    isHTML: false,
  );
  try {
    await FlutterEmailSender.send(email);
  } catch (e) {
    await Share.shareFiles([zipFilePath]);
  }
}
