import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:photos/ente_theme_data.dart";
import "package:photos/generated/intl/app_localizations.dart";
import "package:photos/ui/payment/subscription_common_widgets.dart";

void main() {
  group("SubscriptionToggle", () {
    testWidgets("uses the provided initial billing period", (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const SubscriptionToggle(
            isYearly: false,
            onToggle: _noopToggle,
          ),
        ),
      );

      final togglePosition =
          tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned));
      expect(togglePosition.left, greaterThan(0));
    });

    testWidgets("updates when the selected billing period changes", (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          const SubscriptionToggle(
            isYearly: false,
            onToggle: _noopToggle,
          ),
        ),
      );

      await tester.pumpWidget(
        _buildTestApp(
          const SubscriptionToggle(
            isYearly: true,
            onToggle: _noopToggle,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final togglePosition =
          tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned));
      expect(togglePosition.left, 0);
    });
  });
}

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    theme: darkThemeData,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SizedBox(
        width: 320,
        child: child,
      ),
    ),
  );
}

void _noopToggle(bool _) {}
