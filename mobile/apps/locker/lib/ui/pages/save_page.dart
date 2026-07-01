import 'dart:async';

import "package:ente_components/ente_components.dart";
import "package:ente_ui/theme/colors.dart";
import 'package:ente_ui/theme/ente_theme.dart';
import "package:ente_ui/theme/text_style.dart";
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/models/info/info_item.dart';
import 'package:locker/ui/pages/account_credentials_page.dart';
import 'package:locker/ui/pages/personal_note_page.dart';
import 'package:locker/ui/pages/physical_records_page.dart';
import 'package:locker/utils/info_item_utils.dart';

enum SaveOptionType { document, note, physicalRecord, credentials }

Future<void> showSaveBottomSheet(
  BuildContext context, {
  required Future<bool> Function() onUploadDocument,
}) {
  return showBottomSheetComponent<void>(
    context: context,
    builder: (_) => SaveBottomSheet(
      rootContext: context,
      onUploadDocument: onUploadDocument,
    ),
  );
}

class SaveBottomSheet extends StatelessWidget {
  const SaveBottomSheet({
    super.key,
    required this.rootContext,
    required this.onUploadDocument,
  });

  final BuildContext rootContext;
  final Future<bool> Function() onUploadDocument;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.75;

    return BottomSheetComponent(
      title: context.l10n.saveToLocker,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.informationDescription,
            style: textTheme.smallMuted,
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSaveOption(
                    context,
                    rootContext: rootContext,
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedFileUpload,
                      size: 24,
                      color: colorScheme.primary700,
                    ),
                    title: context.l10n.saveDocumentTitle,
                    description: context.l10n.saveDocumentDescription,
                    type: SaveOptionType.document,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                  const SizedBox(height: 16),
                  _buildSaveOption(
                    context,
                    rootContext: rootContext,
                    icon: InfoItemUtils.getInfoIcon(
                      InfoType.note,
                      showBackground: false,
                      size: 24,
                    ),
                    title: context.l10n.personalNote,
                    description: context.l10n.personalNoteDescription,
                    type: SaveOptionType.note,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                  const SizedBox(height: 16),
                  _buildSaveOption(
                    context,
                    rootContext: rootContext,
                    icon: InfoItemUtils.getInfoIcon(
                      InfoType.physicalRecord,
                      showBackground: false,
                      size: 24,
                    ),
                    title: context.l10n.physicalRecords,
                    description: context.l10n.physicalRecordsDescription,
                    type: SaveOptionType.physicalRecord,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                  const SizedBox(height: 16),
                  _buildSaveOption(
                    context,
                    rootContext: rootContext,
                    icon: InfoItemUtils.getInfoIcon(
                      InfoType.accountCredential,
                      showBackground: false,
                      size: 24,
                    ),
                    title: context.l10n.accountCredentials,
                    description: context.l10n.accountCredentialsDescription,
                    type: SaveOptionType.credentials,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveOption(
    BuildContext sheetContext, {
    required BuildContext rootContext,
    required Widget icon,
    required String title,
    required String description,
    required SaveOptionType type,
    required EnteColorScheme colorScheme,
    required EnteTextTheme textTheme,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.of(sheetContext).pop();
        // Push the form route after the sheet has dismissed to avoid UI jank.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleSaveOption(rootContext, type);
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: colorScheme.backdropBase,
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.bodyBold),
                  const SizedBox(height: 4),
                  Text(description, style: textTheme.smallMuted),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colorScheme.textBase),
          ],
        ),
      ),
    );
  }

  void _handleSaveOption(BuildContext context, SaveOptionType type) {
    final navigator = Navigator.of(context);
    void reopenSheet() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!navigator.mounted) {
          return;
        }
        showSaveBottomSheet(
          navigator.context,
          onUploadDocument: onUploadDocument,
        );
      });
    }

    switch (type) {
      case SaveOptionType.document:
        unawaited(
          onUploadDocument().then((didUpload) {
            if (!didUpload) {
              reopenSheet();
            }
          }),
        );
        return;
      case SaveOptionType.note:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                PersonalNotePage(onCancelWithoutSaving: reopenSheet),
          ),
        );
        break;
      case SaveOptionType.physicalRecord:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                PhysicalRecordsPage(onCancelWithoutSaving: reopenSheet),
          ),
        );
        break;
      case SaveOptionType.credentials:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                AccountCredentialsPage(onCancelWithoutSaving: reopenSheet),
          ),
        );
        break;
    }
  }
}
