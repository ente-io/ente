import "package:flutter/material.dart";
import "package:photos/models/activity/activity_models.dart";
import "package:photos/service_locator.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/theme/text_style.dart";
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
        final textTheme = getEnteTextTheme(context);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                routeToPage(context, const ActivityScreen());
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const double baseCell = 30;
                          const double minCell = baseCell * 0.8; // 24
                          const double maxCell = baseCell * 1.2; // 36
                          const double spacing = 4;
                          double cellWidth =
                              (constraints.maxWidth - (6 * spacing)) / 7;
                          cellWidth = cellWidth.clamp(minCell, maxCell);
                          final today = DateTime.now();

                          return Row(
                            mainAxisSize: MainAxisSize.max,
                            children: seven.asMap().entries.map((entry) {
                              final bool isLast = entry.key == seven.length - 1;
                              final bool active =
                                  entry.value.hasActivity || hasFire;
                              final bool isToday =
                                  _isSameDay(entry.value.date, today);
                              final String label = _dayLabel(entry.value.date);
                              final Widget pill = _DayPill(
                                label: label,
                                active: active,
                                width: cellWidth,
                                textTheme: textTheme,
                                colorScheme: colorScheme,
                              );
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: isLast ? 0 : spacing,
                                ),
                                child: SizedBox(
                                  width: cellWidth,
                                  height: cellWidth,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Positioned.fill(child: pill),
                                      if (isToday)
                                        Positioned(
                                          bottom: -(cellWidth * 0.4),
                                          left: (cellWidth - 6) / 2,
                                          child: Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: colorScheme.primary500,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
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

  String _dayLabel(DateTime date) {
    const labels = ["S", "M", "T", "W", "T", "F", "S"];
    return labels[date.weekday % 7];
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.label,
    required this.active,
    required this.width,
    required this.textTheme,
    required this.colorScheme,
  });

  final String label;
  final bool active;
  final double width;
  final EnteTextTheme textTheme;
  final EnteColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color inactiveBackground =
        isDark ? colorScheme.fillFaintPressed : colorScheme.fillFaint;
    final Color backgroundColor =
        active ? const Color(0xFF1DB954) : inactiveBackground;
    final Color textColor = active ? Colors.white : colorScheme.textBase;

    return Container(
      width: width,
      height: 32,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active ? Colors.transparent : colorScheme.strokeFaint,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: textTheme.miniBold.copyWith(
          color: textColor,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.05,
        ),
      ),
    );
  }
}
