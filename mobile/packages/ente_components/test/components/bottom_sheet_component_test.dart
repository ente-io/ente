import 'package:ente_components/ente_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BottomSheetHeaderComponent renders title and close action', (
    tester,
  ) async {
    var closeCount = 0;

    await tester.pumpWidget(
      _wrap(
        BottomSheetHeaderComponent(
          title: 'Title',
          onClose: () => closeCount += 1,
        ),
      ),
    );

    expect(find.text('Title'), findsOneWidget);
    expect(find.byTooltip('Close'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pump();

    expect(closeCount, 1);
  });

  testWidgets('BottomSheetHeaderComponent supports close-only header', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const BottomSheetHeaderComponent()));

    expect(find.text('Title'), findsNothing);
    expect(find.byTooltip('Close'), findsOneWidget);
  });

  testWidgets('BottomSheetComponent renders content and stacked actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const BottomSheetComponent(
          title: 'Title',
          content: Text('Body copy'),
          actions: [
            ButtonComponent(label: 'Primary'),
            ButtonComponent(
              label: 'Secondary',
              variant: ButtonComponentVariant.secondary,
            ),
          ],
        ),
      ),
    );

    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Body copy'), findsOneWidget);
    expect(find.text('Primary'), findsOneWidget);
    expect(find.text('Secondary'), findsOneWidget);
  });

  testWidgets(
    'BottomSheetComponent renders centered illustration and message',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BottomSheetComponent(
            title: 'Title',
            message: 'Centered message',
            illustration: SizedBox(
              key: ValueKey('warning-illustration'),
              width: 80,
              height: 80,
            ),
            actions: [ButtonComponent(label: 'Button')],
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('warning-illustration')),
        findsOneWidget,
      );
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Centered message'), findsOneWidget);
      expect(find.text('Button'), findsOneWidget);

      final message = tester.widget<Text>(find.text('Centered message'));
      expect(message.textAlign, TextAlign.center);
    },
  );

  testWidgets('showErrorBottomSheetComponent presents error content', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ComponentTheme.lightTheme(),
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: ButtonComponent(
                label: 'Show error',
                onTap: () {
                  return showErrorBottomSheetComponent<void>(
                    context: context,
                    message: 'Something went wrong.',
                    actions: const [
                      ButtonComponent(
                        label: 'Contact support',
                        variant: ButtonComponentVariant.secondary,
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Show error'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Error'), findsOneWidget);
    expect(find.text('Something went wrong.'), findsOneWidget);
    expect(find.text('Contact support'), findsOneWidget);
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ComponentTheme.lightTheme(),
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 375, child: child),
      ),
    ),
  );
}
