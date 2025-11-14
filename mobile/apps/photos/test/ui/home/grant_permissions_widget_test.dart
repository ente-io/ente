import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photos/generated/l10n.dart';
import 'package:photos/ui/home/grant_permissions_widget.dart';

void main() {
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

      expect(find.byKey(const ValueKey("onlyNewPhotosButton")), findsOneWidget);
      expect(find.byKey(const ValueKey("selectFoldersButton")), findsOneWidget);
      expect(find.byKey(const ValueKey("skipForNowButton")), findsOneWidget);
    },
  );
}
