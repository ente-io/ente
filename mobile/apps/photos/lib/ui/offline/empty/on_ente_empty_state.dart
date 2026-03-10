import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/account/email_entry_page.dart";
import "package:photos/ui/components/banners/banner_action_button.dart";

class EmptyOnEnteSection extends StatelessWidget {
  const EmptyOnEnteSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final l10n = AppLocalizations.of(context);
    final titleStyle = textTheme.largeBold.copyWith(
      fontFamily: "Nunito",
      fontWeight: FontWeight.w800,
      fontSize: 20,
      height: 24 / 18,
      letterSpacing: -1,
      color: colorScheme.content,
    );

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        decoration: BoxDecoration(
          color: colorScheme.fillDark,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 140,
              child: Image.asset(
                "assets/photo_backup.png",
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.offlineEnableBackupTitle,
              textAlign: TextAlign.center,
              style: titleStyle,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.offlineEnableBackupDesc,
              textAlign: TextAlign.center,
              style: textTheme.smallMuted,
            ),
            const SizedBox(height: 28),
            BannerActionButton(
              label: l10n.getStarted,
              stickTagToLightTheme: false,
              showTag: true,
              variant: BannerActionButtonVariant.primary,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const EmailEntryPage(
                      showReferralSourceField: false,
                      referralSource: "Offline",
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
