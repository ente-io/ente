import 'package:flutter_test/flutter_test.dart';
import 'package:photos/core/configuration.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    Configuration.instance.overridePreferencesForTests(prefs);
  });

  test("only new backup flag stores timestamp", () async {
    expect(Configuration.instance.isOnlyNewBackupEnabled(), isFalse);
    expect(Configuration.instance.getOnlyNewSinceEpoch(), isNull);

    await Configuration.instance.setOnlyNewSinceNow();

    final timestamp = Configuration.instance.getOnlyNewSinceEpoch();
    expect(timestamp, isNotNull);
    expect(timestamp, greaterThan(0));
    expect(Configuration.instance.isOnlyNewBackupEnabled(), isTrue);

    await Configuration.instance.clearOnlyNewSince();
    expect(Configuration.instance.isOnlyNewBackupEnabled(), isFalse);
    expect(Configuration.instance.getOnlyNewSinceEpoch(), isNull);
  });

  test("onboarding skip flag persists", () async {
    expect(Configuration.instance.hasOnboardingPermissionSkipped(), isFalse);
    await Configuration.instance.setOnboardingPermissionSkipped(true);
    expect(Configuration.instance.hasOnboardingPermissionSkipped(), isTrue);
    await Configuration.instance.setOnboardingPermissionSkipped(false);
    expect(Configuration.instance.hasOnboardingPermissionSkipped(), isFalse);
  });

  test("manual folder selection flags persist", () async {
    expect(Configuration.instance.hasManualFolderSelection(), isFalse);
    expect(Configuration.instance.hasDismissedFolderSelection(), isFalse);

    await Configuration.instance.setHasManualFolderSelection(true);
    await Configuration.instance.setHasDismissedFolderSelection(true);

    expect(Configuration.instance.hasManualFolderSelection(), isTrue);
    expect(Configuration.instance.hasDismissedFolderSelection(), isTrue);

    await Configuration.instance.setHasManualFolderSelection(false);
    await Configuration.instance.setHasDismissedFolderSelection(false);

    expect(Configuration.instance.hasManualFolderSelection(), isFalse);
    expect(Configuration.instance.hasDismissedFolderSelection(), isFalse);
  });
}
