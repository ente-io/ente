import "dart:io";

import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/button_widget_v2.dart";
import "package:photos/ui/components/text_input_widget_v2.dart";
import "package:photos/ui/components/toggle_switch_widget.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/ui/settings/support/no_mail_app_sheet.dart";
import "package:photos/utils/email_util.dart";

class ReportIssuePage extends StatefulWidget {
  const ReportIssuePage({super.key});

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  static final _logger = Logger("ReportIssuePage");
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _attachLogs = true;
  bool _isSending = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final pageBackgroundColor =
        isDarkMode ? const Color(0xFF161616) : const Color(0xFFFAFAFA);

    return Scaffold(
      backgroundColor: pageBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(
                  Icons.arrow_back,
                  color: colorScheme.strokeBase,
                  size: 24,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.reportAnIssue,
                style: textTheme.h3Bold,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextInputWidgetV2(
                        label: l10n.subject,
                        hintText: l10n.oneLineAboutTheIssue,
                        textEditingController: _subjectController,
                        textCapitalization: TextCapitalization.sentences,
                        isClearable: true,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 16),
                      TextInputWidgetV2(
                        label: l10n.description,
                        hintText: l10n.detailsAboutTheIssue,
                        textEditingController: _descriptionController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 6,
                        minLines: 6,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.fill,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.attachLogs,
                                    style: textTheme.small,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    l10n.attachLogsHelper,
                                    style: textTheme.miniMuted,
                                  ),
                                ],
                              ),
                            ),
                            ToggleSwitchWidget(
                              value: () => _attachLogs,
                              onChanged: () async {
                                setState(() {
                                  _attachLogs = !_attachLogs;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.deviceInfoNote,
                        style: textTheme.miniMuted,
                      ),
                      const SizedBox(height: 24),
                      ButtonWidgetV2(
                        buttonType: ButtonTypeV2.primary,
                        labelText: l10n.send,
                        isDisabled: _isSending,
                        shouldSurfaceExecutionStates: false,
                        onTap: _onSend,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onSend() async {
    if (_isSending) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final subject = _subjectController.text.trim();
    final description = _descriptionController.text.trim();
    if (subject.isEmpty) {
      showShortToast(context, l10n.pleaseEnterASubject);
      return;
    }
    if (description.isEmpty) {
      showShortToast(context, l10n.pleaseEnterADescription);
      return;
    }

    setState(() {
      _isSending = true;
    });

    final bugsEmail =
        Platform.isAndroid ? "android-bugs@ente.io" : "ios-bugs@ente.io";
    String? logsZipFilePath;
    String? logsLabel;

    try {
      final deviceInfo = await getSupportDeviceInfo();
      final body = buildSupportEmailBody(
        message: description,
        deviceInfo: deviceInfo,
      );

      if (_attachLogs) {
        logsZipFilePath = await getZippedLogsFile(context);
        logsLabel = l10n.export;
      }

      final didOpenComposer = _attachLogs
          ? await sendLogsWithSubjectAndBody(
              context,
              toEmail: bugsEmail,
              subject: subject,
              body: body,
              zipFilePath: logsZipFilePath,
            )
          : await sendComposedEmail(
              context,
              to: bugsEmail,
              subject: subject,
              body: body,
            );

      if (!didOpenComposer && mounted) {
        await showNoMailAppSheet(
          context,
          toEmail: bugsEmail,
          subject: subject,
          message: description,
          deviceInfo: deviceInfo,
          logsLabel: logsLabel,
          logsFilePath: logsZipFilePath,
        );
      }
    } catch (e, s) {
      _logger.severe("Failed to report issue", e, s);
      if (mounted) {
        showShortToast(context, l10n.somethingWentWrong);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }
}
