import 'package:flutter_test/flutter_test.dart';
import 'package:photos/utils/local_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LocalSettings optimized copy flags', () {
    late LocalSettings settings;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      settings = LocalSettings(prefs);
    });

    test('defaults are disabled', () {
      expect(settings.keepOptimizedCopy, isFalse);
      expect(settings.eagerLoadFullResolutionOnOpen, isFalse);
    });

    test('cannot enable eager loading when optimized copy is disabled',
        () async {
      await settings.setEagerLoadFullResolutionOnOpen(true);

      expect(settings.keepOptimizedCopy, isFalse);
      expect(settings.eagerLoadFullResolutionOnOpen, isFalse);
    });

    test('can enable eager loading only after optimized copy is enabled',
        () async {
      await settings.setKeepOptimizedCopy(true);
      await settings.setEagerLoadFullResolutionOnOpen(true);

      expect(settings.keepOptimizedCopy, isTrue);
      expect(settings.eagerLoadFullResolutionOnOpen, isTrue);
    });

    test('disabling optimized copy also disables eager loading', () async {
      await settings.setKeepOptimizedCopy(true);
      await settings.setEagerLoadFullResolutionOnOpen(true);

      await settings.setKeepOptimizedCopy(false);

      expect(settings.keepOptimizedCopy, isFalse);
      expect(settings.eagerLoadFullResolutionOnOpen, isFalse);
    });
  });
}
