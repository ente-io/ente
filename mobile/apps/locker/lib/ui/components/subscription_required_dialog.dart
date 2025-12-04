import "package:ente_ui/components/title_bar_title_widget.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/ui/components/gradient_button.dart";

/// Shows a dialog indicating that a paid subscription is required
/// for the requested feature (e.g., sharing).
Future<void> showSubscriptionRequiredDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return const SubscriptionRequiredDialog();
    },
  );
}

class SubscriptionRequiredDialog extends StatelessWidget {
  const SubscriptionRequiredDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final l10n = context.l10n;

    return Dialog(
      backgroundColor: colorScheme.backgroundElevated2,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                  title: l10n.sorry,
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
              l10n.subscriptionRequiredForSharing,
              style: textTheme.body.copyWith(
                color: colorScheme.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                onTap: () {
                  // TODO: If we are having subscriptions for locker
                  // Navigator.of(context).push(
                  //   MaterialPageRoute(
                  //     builder: (BuildContext context) {
                  //       return getSubscriptionPage();
                  //     },
                  //   ),
                  // );
                  Navigator.of(context).pop();
                },
                text: l10n.ok,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
