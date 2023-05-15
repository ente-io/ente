import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:photos/main.dart" as app;
import "package:scrollable_positioned_list/scrollable_positioned_list.dart";

void main() {
  group("App test", () {
    final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
    testWidgets("Demo test", (tester) async {
      app.main();

      await tester.pumpAndSettle(const Duration(seconds: 5));

      await dismissUpdateAppDialog(tester);

      //Click the sign in button on the landing page
      final signInButton = find.byKey(const ValueKey("signInButton"));
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      //Enter the email address and click the login button
      final emailInputField = find.byKey(const ValueKey("emailInputField"));
      final logInButton = find.byKey(const ValueKey("logInButton"));
      await tester.tap(emailInputField);
      await tester.pumpAndSettle(const Duration(seconds: 20));
      await findAndTapFAB(tester, logInButton);

      //Enter OTT and click the verify button
      final ottVerificationInputField =
          find.byKey(const ValueKey("ottVerificationInputField"));
      final verifyOttButton = find.byKey(const ValueKey("verifyOttButton"));
      await tester.tap(ottVerificationInputField);
      await tester.pumpAndSettle(const Duration(seconds: 6));
      await findAndTapFAB(tester, verifyOttButton);

      //Enter password and click the verify button
      final passwordInputField =
          find.byKey(const ValueKey("passwordInputField"));
      final verifyPasswordButton =
          find.byKey(const ValueKey("verifyPasswordButton"));
      await tester.tap(passwordInputField);
      await tester.pumpAndSettle(const Duration(seconds: 10));
      await findAndTapFAB(tester, verifyPasswordButton);

      await tester.pumpAndSettle(const Duration(seconds: 1));
      await dismissUpdateAppDialog(tester);

      //Grant permission to access photos
      final grantPermissionButton =
          find.byKey(const ValueKey("grantPermissionButton"));
      await tester.tap(grantPermissionButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      //Manually grant permission to access photos within 3 seconds
      await tester.pumpAndSettle(const Duration(seconds: 3));

      //Skip backup
      final skipBackupButton = find.byKey(const ValueKey("skipBackupButton"));
      await tester.tap(skipBackupButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await binding.traceAction(
        () async {
          //scroll gallery
          final scrollablePositionedList =
              find.byType(ScrollablePositionedList);
          await tester.fling(
            scrollablePositionedList,
            const Offset(0, -5000),
            4500,
          );
          await tester.pumpAndSettle();
          await tester.fling(
            scrollablePositionedList,
            const Offset(0, 5000),
            4500,
          );

          await tester.fling(
            scrollablePositionedList,
            const Offset(0, -7000),
            4500,
          );
          await tester.pumpAndSettle();
          await tester.fling(
            scrollablePositionedList,
            const Offset(0, 7000),
            4500,
          );

          await tester.fling(
            scrollablePositionedList,
            const Offset(0, -9000),
            4500,
          );
          await tester.pumpAndSettle();
          await tester.fling(
            scrollablePositionedList,
            const Offset(0, 9000),
            4500,
          );
          await tester.pumpAndSettle();
        },
        reportKey: 'scrolling_summary',
      );
    });
  });
}

Future<void> findAndTapFAB(WidgetTester tester, Finder finder) async {
  final RenderBox box = tester.renderObject(finder);
  final Offset desiredOffset = Offset(box.size.width - 10, box.size.height / 2);
  // Calculate the global position of the desired offset within the widget.
  final Offset globalPosition = box.localToGlobal(desiredOffset);
  await tester.tapAt(globalPosition);
  await tester.pumpAndSettle(const Duration(seconds: 3));
}

Future<void> dismissUpdateAppDialog(WidgetTester tester) async {
  await tester.tapAt(const Offset(0, 0));
  await tester.pumpAndSettle();
}
