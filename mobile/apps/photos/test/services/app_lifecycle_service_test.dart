import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:photos/services/app_lifecycle_service.dart";
import "package:shared_preferences/shared_preferences.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("AppLifecycleService", () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      AppLifecycleService.instance.isForeground = false;
    });

    test("foreground transition is pure bookkeeping before locator init",
        () async {
      Object? uncaughtError;

      await runZonedGuarded(() async {
        AppLifecycleService.instance.onAppInForeground("test");
        await Future<void>.delayed(Duration.zero);
      }, (error, stackTrace) {
        uncaughtError = error;
      });

      expect(uncaughtError, isNull);
      expect(AppLifecycleService.instance.isForeground, isTrue);
    });

    test("background transition updates open time without async side effects",
        () async {
      final prefs = await SharedPreferences.getInstance();
      AppLifecycleService.instance.init(prefs);
      AppLifecycleService.instance.isForeground = true;

      Object? uncaughtError;

      await runZonedGuarded(() async {
        AppLifecycleService.instance.onAppInBackground("test");
        await Future<void>.delayed(Duration.zero);
      }, (error, stackTrace) {
        uncaughtError = error;
      });

      expect(uncaughtError, isNull);
      expect(
        prefs.getInt(AppLifecycleService.keyLastAppOpenTime),
        isNotNull,
      );
      expect(AppLifecycleService.instance.isForeground, isFalse);
    });
  });
}
