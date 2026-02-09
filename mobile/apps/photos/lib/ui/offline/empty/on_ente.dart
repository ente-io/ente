import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/home/landing_page_widget.dart";

class EmptyOnEnteSection extends StatelessWidget {
  final List<Collection> collections;

  const EmptyOnEnteSection({
    super.key,
    required this.collections,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        height: 156,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: colorScheme.backgroundElevated,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.offlineEnableBackupTitle,
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
            const SizedBox(height: 8),
            Text(
              l10n.offlineEnableBackupDesc,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Inter",
                fontWeight: FontWeight.w500,
                fontSize: 10,
                height: 16 / 10,
                color: colorScheme.textBase.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LandingPageWidget(),
                  ),
                );
              },
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: getEnteColorScheme(context).greenBase,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text(
                  "Start with 10 GB FREE",
                  style: TextStyle(
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
}
