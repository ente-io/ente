import "package:flutter/material.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/theme/ente_theme.dart";

class FacesTimelineBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const FacesTimelineBanner({
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: colorScheme.backgroundElevated2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.strokeFaint),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.fillFaint,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.play_circle_outline,
                size: 28,
                color: colorScheme.primary500,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.bodyBold),
                  const SizedBox(height: 6),
                  Text(subtitle, style: textTheme.miniMuted),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class FacesTimelineBannerSection extends StatelessWidget {
  final bool showBanner;
  final PersonEntity person;
  final VoidCallback? onTap;

  const FacesTimelineBannerSection({
    required this.showBanner,
    required this.person,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!showBanner || onTap == null) {
      return const SizedBox.shrink();
    }
    return FacesTimelineBanner(
      title: context.l10n.facesTimelineBannerTitle,
      subtitle: context.l10n.facesTimelineBannerSubtitle(
        name: person.data.name,
      ),
      onTap: onTap!,
    );
  }
}
