import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photos/generated/l10n.dart';
import 'package:photos/service_locator.dart';
import 'package:photos/ui/home/grant_permissions_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final mockPackageInfo = PackageInfo(
      appName: "Test",
      packageName: "io.ente.test",
      version: "1.0.0",
      buildNumber: "1",
    );
    ServiceLocator.instance.init(
      prefs,
      Dio(),
      Dio(),
      mockPackageInfo,
    );
  });

  testWidgets(
    "permission screen shows all three actions",
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const GrantPermissionsWidget(),
        ),
      );

      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 6));

      expect(find.byKey(const ValueKey("onlyNewPhotosButton")), findsOneWidget);
      expect(find.byKey(const ValueKey("selectFoldersButton")), findsOneWidget);
      expect(find.byKey(const ValueKey("skipForNowButton")), findsOneWidget);
    },
  );
}
