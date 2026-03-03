import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/base_bottom_sheet.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/utils/share_util.dart";
import "package:url_launcher/url_launcher.dart";

Future<void> showQrCodeContentSheet(
  BuildContext context, {
  required String content,
}) {
  return showBaseBottomSheet(
    context,
    title: AppLocalizations.of(context).qrCode,
    child: _QrCodeContentBody(content: content),
  );
}

class _QrCodeContentBody extends StatelessWidget {
  final String content;

  const _QrCodeContentBody({required this.content});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final l10n = AppLocalizations.of(context);
    final Uri? parsedUri = Uri.tryParse(content);
    final bool isUrl = parsedUri != null &&
        (parsedUri.scheme == "http" || parsedUri.scheme == "https");

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.fillDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SelectableText(
            content,
            style: textTheme.body.copyWith(color: colorScheme.textBase),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _ActionButton(
              icon: Icons.copy,
              label: l10n.copyLink,
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: content));
                if (context.mounted) {
                  showShortToast(context, l10n.copied);
                }
              },
            ),
            if (isUrl) ...[
              const SizedBox(width: 12),
              _ActionButton(
                icon: Icons.open_in_new,
                label: l10n.openFile,
                onTap: () => launchUrl(parsedUri),
              ),
            ],
            const SizedBox(width: 12),
            _ActionButton(
              icon: Icons.share,
              label: l10n.share,
              onTap: () => shareText(content, context: context),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.fillDark,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: colorScheme.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: textTheme.mini.copyWith(color: colorScheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
