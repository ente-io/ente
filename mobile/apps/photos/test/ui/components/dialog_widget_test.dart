import "package:ente_components/ente_components.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:photos/ente_theme_data.dart";
import "package:photos/models/button_result.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/dialog_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/utils/dialog_util.dart";

void main() {
  group("showDialogWidget", () {
    testWidgets("renders the compatibility sheet with ente components", (
      tester,
    ) async {
      await _pumpLauncher(
        tester,
        (context) => showDialogWidget(
          context: context,
          title: "Invite",
          body: "Share this invite with a friend.",
          icon: Icons.info_outline,
          buttons: const [
            ButtonWidget(
              buttonType: ButtonType.neutral,
              labelText: "Send invite",
              icon: Icons.share_outlined,
              isInAlert: true,
              buttonAction: ButtonAction.first,
            ),
            ButtonWidget(
              buttonType: ButtonType.secondary,
              labelText: "Cancel",
              isInAlert: true,
              buttonAction: ButtonAction.cancel,
            ),
          ],
        ),
      );

      await _openLauncher(tester);

      expect(find.byType(BottomSheetComponent), findsOneWidget);
      expect(find.byType(ButtonComponent), findsNWidgets(2));
      expect(find.byType(ButtonWidget), findsNothing);
      expect(find.byType(Dialog), findsNothing);
      expect(find.text("Invite"), findsOneWidget);
      expect(find.text("Share this invite with a friend."), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.byIcon(Icons.share_outlined), findsOneWidget);
      final button = tester.widget<ButtonComponent>(
        find.widgetWithText(ButtonComponent, "Send invite"),
      );
      expect(button.variant, ButtonComponentVariant.neutral);
      expect(button.leading, isNotNull);
    });

    testWidgets("returns the tapped button action", (tester) async {
      ButtonResult? result;

      await _pumpLauncher(tester, (context) async {
        result = await showDialogWidget(
          context: context,
          title: "Confirm",
          buttons: const [
            ButtonWidget(
              buttonType: ButtonType.neutral,
              labelText: "Continue",
              isInAlert: true,
              buttonAction: ButtonAction.first,
            ),
          ],
        );
      });

      await _openLauncher(tester);
      await tester.tap(find.text("Continue"));
      await tester.pumpAndSettle();

      expect(result?.action, ButtonAction.first);
      expect(result?.exception, isNull);
      expect(find.byType(BottomSheetComponent), findsNothing);
    });

    testWidgets("returns null when dismissed", (tester) async {
      ButtonResult? result;
      var completed = false;

      await _pumpLauncher(tester, (context) async {
        result = await showDialogWidget(
          context: context,
          title: "Dismissible",
          buttons: const [
            ButtonWidget(
              buttonType: ButtonType.secondary,
              labelText: "Cancel",
              isInAlert: true,
              buttonAction: ButtonAction.cancel,
            ),
          ],
        );
        completed = true;
      });

      await _openLauncher(tester);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      expect(result, isNull);
      expect(find.byType(BottomSheetComponent), findsNothing);
    });

    testWidgets("honors non-dismissible sheets", (tester) async {
      await _pumpLauncher(
        tester,
        (context) => showDialogWidget(
          context: context,
          title: "Required",
          isDismissible: false,
          buttons: const [
            ButtonWidget(
              buttonType: ButtonType.secondary,
              labelText: "OK",
              isInAlert: true,
              buttonAction: ButtonAction.first,
            ),
          ],
        ),
      );

      await _openLauncher(tester);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheetComponent), findsOneWidget);

      await tester.tap(find.text("OK"));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheetComponent), findsNothing);
    });

    testWidgets("returns an error result when a button callback throws", (
      tester,
    ) async {
      ButtonResult? result;

      await _pumpLauncher(tester, (context) async {
        result = await showDialogWidget(
          context: context,
          title: "Failure",
          buttons: [
            ButtonWidget(
              buttonType: ButtonType.neutral,
              labelText: "Fail",
              isInAlert: true,
              buttonAction: ButtonAction.first,
              onTap: () async {
                throw StateError("boom");
              },
            ),
          ],
        );
      });

      await _openLauncher(tester);
      await tester.tap(find.text("Fail"));
      await tester.pumpAndSettle();

      expect(result?.action, ButtonAction.error);
      expect(result?.exception, isA<Exception>());
      expect(find.byType(BottomSheetComponent), findsNothing);
    });
  });

  testWidgets("showChoiceDialog uses the migrated dialog sheet", (
    tester,
  ) async {
    ButtonResult? result;

    await _pumpLauncher(tester, (context) async {
      result = await showChoiceDialog(
        context,
        title: "Remove item?",
        body: "This can be restored later.",
        firstButtonLabel: "Remove",
        secondButtonLabel: "Keep",
        isCritical: true,
      );
    });

    await _openLauncher(tester);

    expect(find.byType(BottomSheetComponent), findsOneWidget);
    final removeButton = tester.widget<ButtonComponent>(
      find.widgetWithText(ButtonComponent, "Remove"),
    );
    expect(removeButton.variant, ButtonComponentVariant.critical);

    await tester.tap(find.text("Keep"));
    await tester.pumpAndSettle();

    expect(result?.action, ButtonAction.cancel);
    expect(find.byType(BottomSheetComponent), findsNothing);
  });
}

Future<void> _pumpLauncher(
  WidgetTester tester,
  Future<dynamic> Function(BuildContext context) onOpen,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: darkThemeData,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async => onOpen(context),
              child: const Text("Open dialog"),
            );
          },
        ),
      ),
    ),
  );
}

Future<void> _openLauncher(WidgetTester tester) async {
  await tester.tap(find.text("Open dialog"));
  await tester.pumpAndSettle();
}
