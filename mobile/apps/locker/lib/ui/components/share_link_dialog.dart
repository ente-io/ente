import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_utils/share_utils.dart";
import "package:flutter/material.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/files/sync/models/file.dart";
import "package:locker/ui/components/button/copy_button.dart";
import "package:locker/ui/components/delete_share_link_dialog.dart";

Future<void> showShareLinkDialog(
  BuildContext context,
  String url,
  String linkID,
  EnteFile file,
) async {
  final colorScheme = getEnteColorScheme(context);
  final textTheme = getEnteTextTheme(context);
  // Capture the root context (with Scaffold) before showing dialog
  final rootContext = context;

  await showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              dialogContext.l10n.share,
              style: textTheme.largeBold,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dialogContext.l10n.shareThisLink,
                  style: textTheme.body,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.fillFaint,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.strokeFaint),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          url,
                          style: textTheme.small,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CopyButton(url: url),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await deleteShareLink(rootContext, file.uploadedFileID!);
                },
                child: Text(
                  dialogContext.l10n.deleteLink,
                  style: textTheme.body.copyWith(color: colorScheme.warning500),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  // Use system share sheet to share the URL
                  await shareText(
                    url,
                    context: rootContext,
                  );
                },
                child: Text(
                  dialogContext.l10n.shareLink,
                  style: textTheme.body.copyWith(color: colorScheme.primary500),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
