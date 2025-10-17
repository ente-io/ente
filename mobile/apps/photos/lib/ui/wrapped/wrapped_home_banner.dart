import "package:flutter/material.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/wrapped/wrapped_service.dart";
import "package:photos/theme/ente_theme.dart";

class WrappedHomeBanner extends StatelessWidget {
  const WrappedHomeBanner({
    required this.state,
    super.key,
  });

  final WrappedEntryState state;

  @override
  Widget build(BuildContext context) {
    final enteColorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final bool hasProgress = state.resumeIndex > 0 &&
        state.resumeIndex < (state.result?.cards.length ?? 0);

    final String title;
    final String subtitle;
    if (state.isComplete) {
      title = "Replay your 2025 Wrapped";
      subtitle = "Enjoy the full story again.";
    } else if (hasProgress) {
      title = "Continue your 2025 Wrapped";
      subtitle = "Jump back to where you left off.";
    } else {
      title = "Your 2025 Wrapped is ready";
      subtitle = "Tap to see your 2025 highlights.";
    }

    final int cardCount = state.result?.cards.length ?? 0;
    final String detail = cardCount > 0
        ? "$cardCount card${cardCount == 1 ? '' : 's'}"
        : "Preview";

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Material(
        color: enteColorScheme.backgroundElevated,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _handleTap(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: enteColorScheme.primary400.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: enteColorScheme.primary500,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: textTheme.largeBold,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: textTheme.smallMuted,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  detail,
                  style: textTheme.smallMuted.copyWith(
                    color: enteColorScheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    if (!wrappedService.shouldShowHomeBanner &&
        !wrappedService.shouldShowDiscoveryEntry) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Wrapped viewer coming soon."),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
