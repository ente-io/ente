import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/base_bottom_sheet.dart";
import "package:photos/ui/components/buttons/button_widget_v2.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/utils/email_util.dart";

Future<void> showNoMailAppSheet(
  BuildContext context, {
  required String toEmail,
  required String subject,
  required String message,
  String? deviceInfo,
  String? logsLabel,
  String? logsFilePath,
}) async {
  await showBaseBottomSheet<void>(
    context,
    title: AppLocalizations.of(context).noEmailAppFound,
    headerSpacing: 16,
    child: NoMailAppSheet(
      toEmail: toEmail,
      subject: subject,
      message: message,
      deviceInfo: deviceInfo,
      logsLabel: logsLabel,
      logsFilePath: logsFilePath,
    ),
  );
}

class NoMailAppSheet extends StatelessWidget {
  final String toEmail;
  final String subject;
  final String message;
  final String? deviceInfo;
  final String? logsLabel;
  final String? logsFilePath;

  const NoMailAppSheet({
    required this.toEmail,
    required this.subject,
    required this.message,
    this.deviceInfo,
    this.logsLabel,
    this.logsFilePath,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final copyFields = <_CopyFieldData>[
      _CopyFieldData(
        label: l10n.subject,
        value: subject,
      ),
      _CopyFieldData(
        label: l10n.message,
        value: message,
      ),
      if (deviceInfo != null && deviceInfo!.trim().isNotEmpty)
        _CopyFieldData(
          label: l10n.deviceInfo,
          value: deviceInfo!,
        ),
      if (logsLabel != null && logsLabel!.trim().isNotEmpty)
        _CopyFieldData(
          label: l10n.logs,
          value: logsLabel!,
          logsFilePath: logsFilePath,
          note: l10n.logsNotCopiedDownloadNote,
        ),
    ];
    final maxSheetBodyHeight = MediaQuery.sizeOf(context).height * 0.75;
    final estimatedSheetBodyHeight = 240 + (120 * copyFields.length);
    final sheetBodyHeight = estimatedSheetBodyHeight > maxSheetBodyHeight
        ? maxSheetBodyHeight
        : estimatedSheetBodyHeight.toDouble();

    return SizedBox(
      height: sheetBodyHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.noEmailAppBody(email: toEmail),
                    style: getEnteTextTheme(context).smallMuted,
                  ),
                  const SizedBox(height: 16),
                  for (int i = 0; i < copyFields.length; i++) ...[
                    _CopyField(
                      data: copyFields[i],
                      onCopy: () async {
                        await Clipboard.setData(
                          ClipboardData(text: copyFields[i].value),
                        );
                        if (context.mounted) {
                          showShortToast(context, l10n.copied);
                        }
                      },
                      onExport: copyFields[i].logsFilePath == null
                          ? null
                          : () async {
                              await exportLogs(
                                context,
                                copyFields[i].logsFilePath!,
                              );
                            },
                    ),
                    if (i != copyFields.length - 1) const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ButtonWidgetV2(
            buttonType: ButtonTypeV2.primary,
            labelText: l10n.copyAllToClipboard,
            onTap: () async {
              await Clipboard.setData(
                ClipboardData(text: _buildCopyAllPayload(l10n)),
              );
              if (context.mounted) {
                showShortToast(context, l10n.copied);
              }
            },
          ),
        ],
      ),
    );
  }

  String _buildCopyAllPayload(AppLocalizations l10n) {
    final shouldIncludeLogsInCopyAll = logsFilePath == null &&
        logsLabel != null &&
        logsLabel!.trim().isNotEmpty;
    final items = <String>[
      "${l10n.subject}: $subject",
      "${l10n.message}: $message",
      if (deviceInfo != null && deviceInfo!.trim().isNotEmpty)
        "${l10n.deviceInfo}: ${deviceInfo!.trim()}",
      if (shouldIncludeLogsInCopyAll) "${l10n.logs}: ${logsLabel!.trim()}",
    ];
    return items.join("\n\n");
  }
}

class _CopyFieldData {
  final String label;
  final String value;
  final String? logsFilePath;
  final String? note;

  const _CopyFieldData({
    required this.label,
    required this.value,
    this.logsFilePath,
    this.note,
  });
}

class _CopyField extends StatelessWidget {
  final _CopyFieldData data;
  final Future<void> Function() onCopy;
  final Future<void> Function()? onExport;

  const _CopyField({
    required this.data,
    required this.onCopy,
    this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final isExportAction = onExport != null;
    final onTap = isExportAction ? onExport! : onCopy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            data.label,
            style: textTheme.miniMuted,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.fillFaint,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  data.value,
                  style: textTheme.small,
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: colorScheme.fillMuted,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: onTap,
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: Icon(
                      isExportAction
                          ? Icons.download_outlined
                          : Icons.content_copy_outlined,
                      size: 18,
                      color: colorScheme.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (data.note != null && data.note!.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              data.note!,
              style: textTheme.miniMuted,
            ),
          ),
        ],
      ],
    );
  }
}
