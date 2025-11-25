import "package:flutter/material.dart";
import "package:photos/models/activity/activity_models.dart";
import "package:photos/service_locator.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/activity/activity_screen.dart";
import "package:photos/utils/navigation_util.dart";

class ActivityBanner extends StatelessWidget {
  const ActivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!flagService.ritualsFlag) {
      return const SizedBox.shrink();
    }
    return ValueListenableBuilder<ActivityState>(
      valueListenable: activityService.stateNotifier,
      builder: (context, state, _) {
        final summary = state.summary;
        final seven = summary?.last7Days ??
            List.generate(
              7,
              (index) => ActivityDay(
                date: DateTime.now().subtract(Duration(days: 6 - index)),
                hasActivity: false,
              ),
            );
        final hasFire = summary?.hasSevenDayFire ?? false;

        final colorScheme = getEnteColorScheme(context);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Material(
            color: colorScheme.backgroundElevated,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                routeToPage(context, const ActivityScreen());
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Image.asset(
                        "assets/rituals/take_a_photo.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ...seven.asMap().entries.map(
                            (entry) {
                              final isLast = entry.key == seven.length - 1;
                              final active = entry.value.hasActivity;
                              if (isLast && hasFire) {
                                return _FireDot();
                              }
                              return _DayDot(
                                label: _dayLabel(entry.value.date),
                                active: active,
                              );
                            },
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
        );
      },
    );
  }

  String _dayLabel(DateTime date) {
    const labels = ["S", "M", "T", "W", "T", "F", "S"];
    return labels[date.weekday % 7];
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.label,
    required this.active,
  });

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color inactiveTextColor =
        isDark ? colorScheme.textMuted : colorScheme.textBase;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: active ? colorScheme.primary500 : colorScheme.fillFaintPressed,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : inactiveTextColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _FireDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: colorScheme.warning500.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.local_fire_department_rounded,
        color: colorScheme.warning500,
      ),
    );
  }
}
