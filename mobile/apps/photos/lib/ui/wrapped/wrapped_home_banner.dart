import "package:flutter/material.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/wrapped/models.dart";
import "package:photos/services/wrapped/wrapped_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/ui/wrapped/wrapped_viewer_page.dart";

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

    const String title = "Your 2025 Wrapped";
    final String subtitle = hasProgress && !state.isComplete
        ? "Resume where you left off"
        : "See your 2025 highlights";

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
                Icon(
                  Icons.chevron_right_rounded,
                  color: enteColorScheme.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    final WrappedEntryState currentState = wrappedService.state;
    final WrappedResult? result = currentState.result;
    if (result == null || result.cards.isEmpty) {
      showShortToast(context, "Wrapped isn’t ready yet");
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => WrappedViewerPage(
          initialState: currentState,
        ),
      ),
    );
  }
}
