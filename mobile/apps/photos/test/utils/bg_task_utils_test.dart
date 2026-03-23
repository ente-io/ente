import "package:flutter_test/flutter_test.dart";
import "package:photos/utils/bg_task_utils.dart";

void main() {
  group("BgTaskUtils.nextIOSBackgroundProcessingSchedule", () {
    test("returns null when handoff flag is disabled", () {
      final schedule = BgTaskUtils.nextIOSBackgroundProcessingSchedule(
        isBackgroundHandoffEnabled: false,
        hasActiveUploads: true,
        isBackupEligible: true,
      );

      expect(schedule, isNull);
    });

    test("returns continuation schedule when uploads are active", () {
      final schedule = BgTaskUtils.nextIOSBackgroundProcessingSchedule(
        isBackgroundHandoffEnabled: true,
        hasActiveUploads: true,
        isBackupEligible: false,
      );

      expect(schedule, isNotNull);
      expect(
        schedule!.reason,
        BgTaskUtils.iOSBackgroundProcessingReasonContinuation,
      );
      expect(schedule.delay, BgTaskUtils.continuationDelay());
    });

    test("returns maintenance schedule when backup remains eligible", () {
      final schedule = BgTaskUtils.nextIOSBackgroundProcessingSchedule(
        isBackgroundHandoffEnabled: true,
        hasActiveUploads: false,
        isBackupEligible: true,
      );

      expect(schedule, isNotNull);
      expect(
        schedule!.reason,
        BgTaskUtils.iOSBackgroundProcessingReasonMaintenance,
      );
      expect(schedule.delay, BgTaskUtils.maintenanceDelay());
    });
  });
}
