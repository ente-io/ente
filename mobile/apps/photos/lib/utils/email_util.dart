import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:email_validator/email_validator.dart';
import "package:file_saver/file_saver.dart";
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import "package:intl/intl.dart";
import 'package:logging/logging.dart';
import 'package:open_mail_app/open_mail_app.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/error-reporting/super_logging.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/ui/common/progress_dialog.dart";
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/dialog_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import 'package:photos/ui/notification/toast.dart';
import 'package:photos/ui/tools/debug/log_file_viewer.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

final Logger _logger = Logger('email_util');

bool isValidEmail(String? email) {
  if (email == null) {
    return false;
  }
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
  // ignore: unawaited_futures
  showDialogWidget(
    context: context,
    title: AppLocalizations.of(context).reportABug,
    icon: Icons.bug_report_outlined,
    body: AppLocalizations.of(context).logsDialogBody,
    buttons: [
      ButtonWidget(
        isInAlert: true,
        buttonType: ButtonType.neutral,
        labelText: AppLocalizations.of(context).reportABug,
        buttonAction: ButtonAction.first,
        shouldSurfaceExecutionStates: false,
        onTap: () async {
          await _sendLogs(context, toEmail, subject, body);
          if (postShare != null) {
            postShare();
          }
        },
      ),
      //isInAlert is false here as we don't want to the dialog to dismiss
      //on pressing this button
      ButtonWidget(
        buttonType: ButtonType.secondary,
        labelText: AppLocalizations.of(context).viewLogs,
        buttonAction: ButtonAction.second,
        onTap: () async {
          // ignore: unawaited_futures
          showDialog(
            useRootNavigator: false,
            context: context,
            builder: (BuildContext context) {
              return LogFileViewer(SuperLogging.logFile!);
            },
            barrierColor: Colors.black87,
            barrierDismissible: false,
          );
        },
      ),
      ButtonWidget(
        buttonType: ButtonType.secondary,
        labelText: AppLocalizations.of(context).exportLogs,
        buttonAction: ButtonAction.third,
        onTap: () async {
          final zipFilePath = await getZippedLogsFile(context);
          await exportLogs(context, zipFilePath);
        },
      ),
      ButtonWidget(
        isInAlert: true,
        buttonType: ButtonType.secondary,
        labelText: AppLocalizations.of(context).cancel,
        buttonAction: ButtonAction.cancel,
      ),
    ],
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
    Navigator.of(context).pop();
    await shareLogs(context, toEmail, zipFilePath);
  }
}

Future<void> triggerSendLogs(
  String toEmail,
  String? subject,
  String? body,
) async {
  final String zipFilePath = await getZippedLogsFile(null);
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
  }
}

Future<String> getZippedLogsFile(BuildContext? context) async {
  late final ProgressDialog dialog;
  if (context != null) {
    dialog = createProgressDialog(
      context,
      AppLocalizations.of(context).preparingLogs,
    );
    await dialog.show();
  }
  final logsPath = (await getApplicationSupportDirectory()).path;
  final logsDirectory = Directory(logsPath + "/logs");
  final tempPath = (await getTemporaryDirectory()).path;
  final zipFilePath =
      tempPath + "/logs-${Configuration.instance.getUserID() ?? 0}.zip";
  final encoder = ZipFileEncoder();
  encoder.create(zipFilePath);
  await encoder.addDirectory(logsDirectory);
  await encoder.close();
  if (context != null) {
    await dialog.hide();
  }
  return zipFilePath;
}

Future<void> shareLogs(
  BuildContext context,
  String toEmail,
  String zipFilePath,
) async {
  final result = await showDialogWidget(
    context: context,
    title: AppLocalizations.of(context).emailYourLogs,
    body: AppLocalizations.of(context).pleaseSendTheLogsTo(toEmail: toEmail),
    buttons: [
      ButtonWidget(
        buttonType: ButtonType.neutral,
        labelText: AppLocalizations.of(context).copyEmailAddress,
        isInAlert: true,
        buttonAction: ButtonAction.first,
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: toEmail));
        },
        shouldShowSuccessConfirmation: true,
      ),
      ButtonWidget(
        buttonType: ButtonType.neutral,
        labelText: AppLocalizations.of(context).exportLogs,
        isInAlert: true,
        buttonAction: ButtonAction.second,
      ),
      ButtonWidget(
        buttonType: ButtonType.secondary,
        labelText: AppLocalizations.of(context).cancel,
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
    final DateTime now = DateTime.now().toUtc();
    final String shortMonthName = DateFormat('MMM').format(now); // Short month
    final String logFileName =
        'ente-logs-${now.year}-$shortMonthName-${now.day}-${now.hour}-${now.minute}';
    await FileSaver.instance.saveAs(
      name: logFileName,
      filePath: zipFilePath,
      mimeType: MimeType.zip,
      ext: 'zip',
    );
  } else {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(zipFilePath, mimeType: 'application/zip')],
        sharePositionOrigin: Rect.fromLTWH(0, 0, size.width, size.height / 2),
      ),
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
    final EmailContent emailContent = EmailContent(
      to: [
        to,
      ],
      subject: subject ?? '[Support]',
      body: (body ?? '') + clientDebugInfo,
    );
    if (Platform.isAndroid) {
      // Special handling due to issue in proton mail android client
      // https://github.com/ente-io/photos-app/pull/253
      final Uri params = Uri(
        scheme: 'mailto',
        path: to,
        query: 'subject=${emailContent.subject}&body=${emailContent.body}',
      );
      if (await canLaunchUrl(params)) {
        await launchUrl(params);
      } else {
        // this will trigger _showNoMailAppsDialog
        throw Exception('Could not launch ${params.toString()}');
      }
    } else {
      final OpenMailAppResult result =
          await OpenMailApp.composeNewEmailInMailApp(
        nativePickerTitle: 'Select emailContent app',
        emailContent: emailContent,
      );
      if (!result.didOpen && !result.canOpen) {
        _showNoMailAppsDialog(context, to);
      } else if (!result.didOpen && result.canOpen) {
        await showCupertinoModalPopup(
          context: context,
          builder: (_) => CupertinoActionSheet(
            title: Text(AppLocalizations.of(context).selectMailApp + " \n $to"),
            actions: [
              for (var app in result.options)
                CupertinoActionSheetAction(
                  child: Text(app.name),
                  onPressed: () {
                    final content = emailContent;

                    OpenMailApp.composeNewEmailInSpecificMailApp(
                      mailApp: app,
                      emailContent: content,
                    );

                    Navigator.of(context).pop();
                  },
                ),
            ],
            cancelButton: CupertinoActionSheetAction(
              child: Text(AppLocalizations.of(context).cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      }
    }
  } catch (e) {
    _logger.severe("Failed to send emailContent to $to", e);
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
  showChoiceDialog(
    context,
    icon: Icons.email_outlined,
    title: AppLocalizations.of(context).pleaseEmailUsAt(toEmail: toEmail),
    firstButtonLabel: AppLocalizations.of(context).copyEmailAddress,
    secondButtonLabel: AppLocalizations.of(context).dismiss,
    firstButtonOnTap: () async {
      await Clipboard.setData(ClipboardData(text: toEmail));
      showShortToast(context, 'Copied');
    },
  );
}
