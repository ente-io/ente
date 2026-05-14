import "dart:async";

import "package:ente_components/ente_components.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hugeicons/hugeicons.dart";

void main() {
  testWidgets("ButtonComponent renders label, icons, and expected size", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        ButtonComponent(
          label: "Continue",
          leading: const Icon(Icons.arrow_back_rounded),
          trailing: const Icon(Icons.arrow_forward_rounded),
          onTap: () {},
        ),
      ),
    );

    expect(find.text("Continue"), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    expect(tester.getSize(find.byType(AnimatedContainer)).height, 52);
  });

  testWidgets("ButtonComponent calls onTap when tapped", (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      _wrap(
        ButtonComponent(
          label: "Save",
          onTap: () => tapCount += 1,
        ),
      ),
    );

    await tester.tap(find.text("Save"));
    await tester.pump();

    expect(tapCount, 1);
  });

  testWidgets(
      "Small ButtonComponent shrink-wraps content without a minimum width", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        ButtonComponent(
          label: "OK",
          onTap: () {},
        ),
      ),
    );

    final size = tester.getSize(find.byType(AnimatedContainer));
    expect(size.height, 52);
    expect(size.width, lessThan(100));
  });

  testWidgets(
      "ButtonComponent height grows with text scale instead of clipping", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        ButtonComponent(
          label: "Continue",
          onTap: () {},
        ),
      ),
    );

    final normalHeight = tester.getSize(find.byType(AnimatedContainer)).height;
    expect(normalHeight, 52);

    await tester.pumpWidget(
      _wrap(
        ButtonComponent(
          label: "Continue",
          onTap: () {},
        ),
        textScaler: const TextScaler.linear(2),
      ),
    );

    final scaledHeight = tester.getSize(find.byType(AnimatedContainer)).height;
    expect(scaledHeight, greaterThan(normalHeight));
  });

  testWidgets(
      "ButtonComponent surfaces loading after debounce and blocks repeat taps",
      (
    tester,
  ) async {
    var tapCount = 0;
    final completer = Completer<void>();

    await tester.pumpWidget(
      _wrap(
        ButtonComponent(
          label: "Uploading",
          onTap: () {
            tapCount += 1;
            return completer.future;
          },
        ),
      ),
    );

    await tester.tap(find.text("Uploading"));
    await tester.pump();

    expect(tapCount, 1);
    expect(find.byKey(const ValueKey('loading')), findsNothing);

    await tester.tap(find.text("Uploading"));
    await tester.pump();

    expect(tapCount, 1);

    await tester.pump(const Duration(milliseconds: 299));
    expect(find.byKey(const ValueKey('loading')), findsNothing);

    await tester.pump(const Duration(milliseconds: 1));

    final loadingFinder = find.byKey(const ValueKey('loading'));
    expect(loadingFinder, findsOneWidget);
    expect(
      find.descendant(
        of: loadingFinder,
        matching: find.byType(RotationTransition),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: loadingFinder, matching: find.byType(HugeIcon)),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text("Uploading"), findsNothing);
    expect(tester.getSize(find.byType(AnimatedContainer)).height, 52);

    completer.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const ValueKey('success')), findsOneWidget);
  });

  testWidgets(
      "ButtonComponent shows success confirmation for fast actions when enabled",
      (
    tester,
  ) async {
    var tapCount = 0;

    await tester.pumpWidget(
      _wrap(
        ButtonComponent(
          label: "Saved",
          shouldShowSuccessConfirmation: true,
          onTap: () => tapCount += 1,
        ),
      ),
    );

    await tester.tap(find.text("Saved"));
    await tester.pump();

    expect(tapCount, 1);
    expect(find.byType(HugeIcon), findsOneWidget);
    expect(find.text("Saved"), findsNothing);
    expect(tester.getSize(find.byType(AnimatedContainer)).height, 52);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text("Saved"), findsOneWidget);
  });

  testWidgets(
      "ButtonComponent can hide execution visuals while still blocking taps", (
    tester,
  ) async {
    var tapCount = 0;
    final completer = Completer<void>();

    await tester.pumpWidget(
      _wrap(
        ButtonComponent(
          label: "Silent",
          shouldSurfaceExecutionStates: false,
          onTap: () {
            tapCount += 1;
            return completer.future;
          },
        ),
      ),
    );

    await tester.tap(find.text("Silent"));
    await tester.pump(const Duration(milliseconds: 400));

    expect(tapCount, 1);
    expect(find.byKey(const ValueKey('loading')), findsNothing);
    expect(find.text("Silent"), findsOneWidget);

    await tester.tap(find.text("Silent"));
    await tester.pump();

    expect(tapCount, 1);

    completer.complete();
    await tester.pump();
  });

  testWidgets("ButtonComponent remains disabled when onTap is null or disabled",
      (
    tester,
  ) async {
    var tapCount = 0;

    await tester.pumpWidget(
      _wrap(
        Column(
          children: [
            const ButtonComponent(
              label: "No callback",
              onTap: null,
            ),
            ButtonComponent(
              label: "Disabled",
              isDisabled: true,
              onTap: () => tapCount += 1,
            ),
          ],
        ),
      ),
    );

    expect(find.text("No callback"), findsOneWidget);
    expect(find.text("Disabled"), findsOneWidget);
    await tester.tap(find.text("Disabled"));
    await tester.pump();

    expect(tapCount, 0);
  });

  testWidgets("ButtonComponent renders pressed visual state from gesture", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        ButtonComponent(
          label: "Continue",
          onTap: () {},
        ),
      ),
    );

    expect(_containerColor(tester), const Color(0xFF08C225));

    final gesture = await tester.startGesture(
      tester.getCenter(find.text("Continue")),
    );
    await tester.pump();

    expect(_containerColor(tester), const Color(0xFF057C18));

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 140));

    expect(_containerColor(tester), const Color(0xFF08C225));
  });

  testWidgets("Large secondary and link buttons match the catalog layout", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        ButtonComponent(
          label: "Cancel",
          variant: ButtonComponentVariant.secondary,
          size: ButtonComponentSize.large,
          onTap: () {},
        ),
      ),
    );

    expect(_containerColor(tester), const Color(0xFFE7F6E9));
    expect(tester.getSize(find.byType(AnimatedContainer)).height, 52);

    await tester.pumpWidget(
      _wrap(
        ButtonComponent(
          label: "Forgot password?",
          variant: ButtonComponentVariant.link,
          size: ButtonComponentSize.large,
          onTap: () {},
        ),
      ),
    );

    expect(tester.getSize(find.byType(AnimatedContainer)).height, 52);
  });

  testWidgets("IconButtonComponent renders Figma size and token-backed states",
      (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        IconButtonComponent(
          icon: const Icon(Icons.add),
          variant: IconButtonComponentVariant.primary,
          state: IconButtonComponentState.pressed,
          onPressed: () {},
        ),
      ),
    );

    final surfaceFinder = find.byKey(const ValueKey('icon-button-surface'));
    final surface = tester.widget<AnimatedContainer>(surfaceFinder);
    final decoration = surface.decoration! as BoxDecoration;

    expect(tester.getSize(surfaceFinder), const Size(38, 38));
    expect(decoration.color, ColorTokens.light.fillDarker);
  });

  testWidgets(
      "IconButtonComponent maps loading and success to designed affordances", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        IconButtonComponent(
          icon: const Icon(Icons.add),
          variant: IconButtonComponentVariant.green,
          isSuccess: true,
          onPressed: () {},
        ),
      ),
    );

    final surface = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('icon-button-surface')),
    );
    final decoration = surface.decoration! as BoxDecoration;
    final successIcon = tester.widget<Icon>(
      find.byIcon(Icons.check_circle_rounded),
    );

    expect(decoration.color, ColorTokens.light.primary);
    expect(successIcon.color, ColorTokens.light.specialWhite);

    await tester.pumpWidget(
      _wrap(
        IconButtonComponent(
          icon: const Icon(Icons.add),
          isLoading: true,
          onPressed: () {},
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);
  });

  testWidgets("IconButtonComponent calls taps only when enabled",
      (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      _wrap(
        IconButtonComponent(
          icon: const Icon(Icons.add),
          onPressed: () => tapCount += 1,
        ),
      ),
    );

    await tester.tap(find.byType(GestureDetector));
    await tester.pump();

    expect(tapCount, 1);

    await tester.pumpWidget(
      _wrap(
        IconButtonComponent(
          icon: const Icon(Icons.add),
          isLoading: true,
          onPressed: () => tapCount += 1,
        ),
      ),
    );

    await tester.tap(find.byType(GestureDetector));
    await tester.pump();

    expect(tapCount, 1);
  });
}

Widget _wrap(Widget child, {TextScaler textScaler = TextScaler.noScaling}) {
  return MaterialApp(
    theme: ComponentTheme.lightTheme(),
    home: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: Center(child: child),
      ),
    ),
  );
}

Color _containerColor(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(
    find.byType(AnimatedContainer),
  );
  return (container.decoration! as BoxDecoration).color!;
}
