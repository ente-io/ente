import "package:ente_ui/components/title_bar_title_widget.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/utils/toast_util.dart";
import "package:ente_utils/share_utils.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/files/sync/models/file.dart";
import "package:locker/ui/components/delete_share_link_dialog.dart";
import "package:locker/ui/components/gradient_button.dart";

Future<void> showShareLinkDialog(
  BuildContext context,
  String url,
  String linkID,
  EnteFile file,
) async {
  // Capture the root context (with Scaffold) before showing dialog
  final rootContext = context;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return ShareLinkDialog(
        url: url,
        file: file,
        rootContext: rootContext,
      );
    },
  );
}

class ShareLinkDialog extends StatefulWidget {
  final String url;
  final EnteFile file;
  final BuildContext rootContext;

  const ShareLinkDialog({
    super.key,
    required this.url,
    required this.file,
    required this.rootContext,
  });

  @override
  State<ShareLinkDialog> createState() => _ShareLinkDialogState();
}

class _ShareLinkDialogState extends State<ShareLinkDialog> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final l10n = context.l10n;

    return Dialog(
      backgroundColor: colorScheme.backgroundElevated2,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TitleBarTitleWidget(
                  title: l10n.share,
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.fillFaint,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: colorScheme.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.shareThisLink,
              style: textTheme.body.copyWith(
                color: colorScheme.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.primary700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            widget.url,
                            style: textTheme.small.copyWith(
                              color: Colors.white,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Center(
                      child: IconButton(
                        onPressed: () => _copyToClipboard(),
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.copy_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        tooltip: 'Copy link',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                onTap: () async {
                  Navigator.of(context).pop();
                  await shareText(
                    widget.url,
                    context: widget.rootContext,
                  );
                },
                text: l10n.shareLink,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.warning500,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await deleteShareLink(
                    widget.rootContext,
                    widget.file.uploadedFileID!,
                  );
                },
                child: Text(
                  l10n.deleteLink,
                  style: textTheme.largeBold.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.url));
    if (mounted) {
      showShortToast(
        context,
        'Link copied to clipboard',
      );
    }
  }
}
