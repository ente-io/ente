import "package:flutter/material.dart";
import "package:photos/services/wrapped/models.dart";
import "package:photos/ui/wrapped/wrapped_rewind_banner_button.dart";

class WrappedDiscoverySection extends StatelessWidget {
  const WrappedDiscoverySection({
    required this.state,
    super.key,
  });

  final WrappedEntryState state;

  @override
  Widget build(BuildContext context) {
    final bool hasProgress = state.resumeIndex > 0 &&
        state.resumeIndex < (state.result?.cards.length ?? 0);
    final String semanticsLabel = hasProgress && !state.isComplete
        ? "Resume Ente Rewind 2025"
        : "Open Ente Rewind 2025";

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 32),
      child: SizedBox(
        width: double.infinity,
        child: WrappedRewindBannerButton(
          height: 164,
          semanticsLabel: semanticsLabel,
        ),
      ),
    );
  }
}
