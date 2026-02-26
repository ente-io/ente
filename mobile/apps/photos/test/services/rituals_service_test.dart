import 'package:flutter_test/flutter_test.dart';
import 'package:photos/services/rituals/rituals_service.dart';

void main() {
  group('RitualsService.currentScheduledStreakFromDayKeys', () {
    test('keeps streak when today is enabled but incomplete', () {
      final service = RitualsService.instance;
      final todayMidnight = DateTime(2025, 6, 15);
      final daysOfWeek = List<bool>.filled(7, true);
      final dayKeys = <int>{};

      for (var offset = 1; offset <= 9; offset++) {
        dayKeys.add(
          DateTime(
            todayMidnight.year,
            todayMidnight.month,
            todayMidnight.day - offset,
          ).millisecondsSinceEpoch,
        );
      }

      final streak = service.currentScheduledStreakFromDayKeys(
        dayKeys,
        daysOfWeek,
        todayMidnight: todayMidnight,
      );

      expect(streak, 9);
    });

    test('increments streak after completing today', () {
      final service = RitualsService.instance;
      final todayMidnight = DateTime(2025, 6, 15);
      final daysOfWeek = List<bool>.filled(7, true);
      final dayKeys = <int>{todayMidnight.millisecondsSinceEpoch};

      for (var offset = 1; offset <= 9; offset++) {
        dayKeys.add(
          DateTime(
            todayMidnight.year,
            todayMidnight.month,
            todayMidnight.day - offset,
          ).millisecondsSinceEpoch,
        );
      }

      final streak = service.currentScheduledStreakFromDayKeys(
        dayKeys,
        daysOfWeek,
        todayMidnight: todayMidnight,
      );

      expect(streak, 10);
    });

    test('resets streak when a previous enabled day was missed', () {
      final service = RitualsService.instance;
      final todayMidnight = DateTime(2025, 6, 15);
      final daysOfWeek = List<bool>.filled(7, true);
      final dayKeys = <int>{};

      for (var offset = 2; offset <= 10; offset++) {
        dayKeys.add(
          DateTime(
            todayMidnight.year,
            todayMidnight.month,
            todayMidnight.day - offset,
          ).millisecondsSinceEpoch,
        );
      }

      final streak = service.currentScheduledStreakFromDayKeys(
        dayKeys,
        daysOfWeek,
        todayMidnight: todayMidnight,
      );

      expect(streak, 0);
    });

    test('skips disabled days while keeping streak', () {
      final service = RitualsService.instance;
      final todayMidnight = DateTime(2025, 6, 16); // Monday
      final daysOfWeek = <bool>[
        false, // Sunday
        true, // Monday
        true, // Tuesday
        true, // Wednesday
        true, // Thursday
        true, // Friday
        false, // Saturday
      ];

      final dayKeys = <int>{
        DateTime(2025, 6, 13).millisecondsSinceEpoch, // Friday
        DateTime(2025, 6, 12).millisecondsSinceEpoch, // Thursday
        DateTime(2025, 6, 11).millisecondsSinceEpoch, // Wednesday
        DateTime(2025, 6, 10).millisecondsSinceEpoch, // Tuesday
        DateTime(2025, 6, 9).millisecondsSinceEpoch, // Monday
      };

      final streak = service.currentScheduledStreakFromDayKeys(
        dayKeys,
        daysOfWeek,
        todayMidnight: todayMidnight,
      );

      expect(streak, 5);
    });
  });
}
