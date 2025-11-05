import "package:flutter/material.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/wrapped/models.dart";
import "package:photos/services/wrapped/wrapped_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/ui/wrapped/wrapped_viewer_page.dart";

class WrappedDiscoverySection extends StatelessWidget {
  const WrappedDiscoverySection({
    required this.state,
    super.key,
  });

  final WrappedEntryState state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    final bool hasProgress = state.resumeIndex > 0 &&
        state.resumeIndex < (state.result?.cards.length ?? 0);
    final String subtitle = state.isComplete
        ? "Replay the full story."
        : hasProgress
            ? "Resume from where you left off."
            : "Highlights from your 2025.";

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ente Rewind",
            style: textTheme.largeBold,
          ),
          const SizedBox(height: 12),
          Material(
            color: colorScheme.backgroundElevated,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _handleTap(context),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Row(
                  children: [
                    Icon(
                      Icons.play_circle_fill_rounded,
                      color: colorScheme.primary500,
                      size: 36,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.isComplete
                                ? "Watch again"
                                : hasProgress
                                    ? "Continue watching"
                                    : "View your recap",
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
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleTap(BuildContext context) {
    WrappedEntryState currentState = wrappedService.state;
    final WrappedResult? result = currentState.result;
    if (result == null || result.cards.isEmpty) {
      showShortToast(context, "Ente Rewind isn't ready yet");
      return;
    }
    final int cardCount = result.cards.length;
    if (cardCount > 1 &&
        currentState.resumeIndex >= cardCount - 1 &&
        currentState.resumeIndex != 0) {
      wrappedService.updateResumeIndex(0);
      currentState = wrappedService.state;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            WrappedViewerPage(initialState: currentState),
      ),
    );
  }
}
