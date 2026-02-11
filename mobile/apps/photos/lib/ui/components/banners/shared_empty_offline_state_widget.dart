import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/home/landing_page_widget.dart";

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
              style: TextStyle(
                fontFamily: "Nunito",
                fontWeight: FontWeight.w900,
                fontSize: 28,
                letterSpacing: -1.0,
                color: colorScheme.textBase,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.offlineEnableSharingDesc,
              textAlign: TextAlign.center,
              style: textTheme.body.copyWith(
                color: colorScheme.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LandingPageWidget(),
                  ),
                );
              },
              child: Container(
                height: 48,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                decoration: BoxDecoration(
                  color: colorScheme.greenBase,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  l10n.offlineEnableBackupAction,
                  style: const TextStyle(
                    fontFamily: "Montserrat",
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    height: 16 / 13,
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
}
