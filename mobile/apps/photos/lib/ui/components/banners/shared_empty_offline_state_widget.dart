import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/account/email_entry_page.dart";
import "package:photos/ui/components/banners/banner_action_button.dart";

class SharedEmptyOfflineStateWidget extends StatelessWidget {
  const SharedEmptyOfflineStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/ducky_share.png",
              height: 180,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(height: 180);
              },
            ),
            Text(
              l10n.offlineEnableSharingTitle,
              style: textTheme.largeBold.copyWith(
                fontFamily: "Nunito",
                fontWeight: FontWeight.w800,
                fontSize: 20,
                height: 24 / 18,
                letterSpacing: -1,
                color: colorScheme.content,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.offlineEnableSharingDesc,
              textAlign: TextAlign.center,
              style: textTheme.smallMuted,
            ),
            const SizedBox(height: 28),
            BannerActionButton(
              label: l10n.getStarted,
              showTag: true,
              stickTagToLightTheme: false,
              variant: BannerActionButtonVariant.primary,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const EmailEntryPage(),
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
