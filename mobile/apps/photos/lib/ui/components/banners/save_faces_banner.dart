import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photos/generated/intl/app_localizations.dart";
import "package:photos/service_locator.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/account/email_entry_page.dart";

class SaveFacesBanner extends StatefulWidget {
  const SaveFacesBanner({super.key});

  @override
  State<SaveFacesBanner> createState() => _SaveFacesBannerState();
}

class _SaveFacesBannerState extends State<SaveFacesBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    if (!isOfflineMode) return const SizedBox.shrink();
    if (localSettings.isOfflineFacesBannerDismissed) {
      return const SizedBox.shrink();
    }

    final colorScheme = getEnteColorScheme(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: colorScheme.backgroundColour,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      l10n.offlineFacesBannerTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: "Nunito",
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        height: 20 / 16,
                        letterSpacing: -1.0,
                        color: colorScheme.textBase,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _onDismiss,
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedCancel01,
                          color: colorScheme.contentLight,
                          size: 18,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 250),
              child: Text(
                l10n.offlineFacesBannerSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                  height: 16 / 10,
                  color: colorScheme.contentLight,
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const EmailEntryPage(),
                  ),
                );
              },
              child: Container(
                width: 140,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.greenBase,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                ),
                child: Text(
                  l10n.signUp,
                  style: const TextStyle(
                    fontFamily: "Montserrat",
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    height: 12 / 10,
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

  void _onDismiss() {
    setState(() {
      _dismissed = true;
    });
    localSettings.setOfflineFacesBannerDismissed(true);
  }
}
