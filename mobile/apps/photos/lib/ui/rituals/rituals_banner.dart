import "package:flutter/material.dart";
import "package:photos/models/rituals/ritual_models.dart";
import "package:photos/service_locator.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/rituals/all_rituals_screen.dart";
import "package:photos/utils/navigation_util.dart";

class RitualsBanner extends StatelessWidget {
  const RitualsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!flagService.ritualsFlag) {
      return const SizedBox.shrink();
    }
    return ValueListenableBuilder<RitualsState>(
      valueListenable: ritualsService.stateNotifier,
      builder: (context, state, _) {
        final ritualsCount = state.rituals.length;
        final colorScheme = getEnteColorScheme(context);
        final textTheme = getEnteTextTheme(context);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                routeToPage(context, const AllRitualsScreen());
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? colorScheme.backgroundElevated2
                      : const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.strokeFaint,
                    width: 1,
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 55,
                      height: 55,
                      child: Image.asset(
                        "assets/rituals/take_a_photo.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Rituals",
                            style: textTheme.bodyBold,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ritualsCount == 0
                                ? "Create reminders to take photos"
                                : "$ritualsCount ritual${ritualsCount == 1 ? "" : "s"}",
                            style: textTheme.smallMuted,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.blurStrokePressed,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
