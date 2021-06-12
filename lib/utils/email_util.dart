import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:email_validator/email_validator.dart';
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
  String toEmail, [
  String subject,
  String body,
]) async {
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
