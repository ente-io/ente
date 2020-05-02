import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:path_provider/path_provider.dart';

Future<void> emailLogs() async {
  final tempPath = (await getTemporaryDirectory()).path;
  final zipFilePath = tempPath + "/logs.zip";
  Directory logsDirectory = Directory(tempPath + "/logs");
  var encoder = ZipFileEncoder();
  encoder.create(zipFilePath);
  encoder.addDirectory(logsDirectory);
  encoder.close();
  final Email email = Email(
    body: 'Logs attached.',
    subject: 'Error, error, share the terror.',
    recipients: ['android-support@ente.io'],
    cc: ['vishnumohandas@gmail.com'],
    attachmentPaths: [zipFilePath],
    isHTML: false,
  );
  await FlutterEmailSender.send(email);
}
