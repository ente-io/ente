import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:share/share.dart';

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
  final confirmation = AlertDialog(
    title: Text(
      title,
      style: TextStyle(
        fontSize: 18,
      ),
    ),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            "this will send across metrics and logs that will help us debug your issue better",
            style: TextStyle(
              height: 1.5,
              fontFamily: 'Ubuntu',
              fontSize: 16,
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        child: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).buttonColor,
          ),
        ),
        onPressed: () async {
          Navigator.of(context).pop();
          await _sendLogs(context, toEmail, subject, body);
          if (postShare != null) {
            postShare();
          }
        },
      ),
    ],
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
