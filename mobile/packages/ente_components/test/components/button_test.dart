import "dart:async";

import "package:ente_components/ente_components.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hugeicons/hugeicons.dart";

void main() {
  testWidgets("ButtonComponent renders label and expected size", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(ButtonComponent(label: "Continue", onTap: () {})),
    );

    expect(find.text("Continue"), findsOneWidget);
    expect(tester.getSize(find.byType(AnimatedContainer)).height, 52);
  });

  testWidgets("ButtonComponent calls onTap when tapped", (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      _wrap(ButtonComponent(label: "Save", onTap: () => tapCount += 1)),
    );

    await tester.tap(find.text("Save"));
    await tester.pump();

    expect(tapCount, 1);
  });

  testWidgets(
    "Small ButtonComponent shrink-wraps content without a minimum width",
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          ButtonComponent(
            label: "OK",
            size: ButtonComponentSize.small,
            onTap: () {},
          ),
        ),
      );

      final size = tester.getSize(find.byType(AnimatedContainer));
      expect(size.height, 52);
      expect(size.width, lessThan(100));
    },
  );

  testWidgets(
    "ButtonComponent surfaces loading after debounce and blocks repeat taps",
    (tester) async {
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
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text("Uploading"), findsOneWidget);
      expect(tester.getSize(find.byType(AnimatedContainer)).height, 52);

      completer.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const ValueKey('success')), findsOneWidget);
    },
  );

  testWidgets(
    "Small ButtonComponent keeps idle width when parent rebuilds during loading",
    (tester) async {
      final completer = Completer<void>();
      var rebuildToken = 0;

      Widget buildButton() {
        return _wrap(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Parent rebuild $rebuildToken"),
              ButtonComponent(
                label: "Uploading",
                size: ButtonComponentSize.small,
                onTap: () => completer.future,
              ),
            ],
          ),
        );
      }

      await tester.pumpWidget(buildButton());
      await tester.pump();

      final idleWidth = tester.getSize(find.byType(AnimatedContainer)).width;

      await tester.tap(find.text("Uploading"));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 200));

      rebuildToken += 1;
      await tester.pumpWidget(buildButton());
      await tester.pump();

      expect(find.byKey(const ValueKey('loading')), findsOneWidget);
      expect(find.text("Uploading"), findsOneWidget);
      expect(tester.getSize(find.byType(AnimatedContainer)).width, idleWidth);

      completer.complete();
    },
  );

  testWidgets(
    "ButtonComponent shows success confirmation for fast actions when enabled",
    (tester) async {
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
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text("Saved"), findsOneWidget);
      expect(tester.getSize(find.byType(AnimatedContainer)).height, 52);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text("Saved"), findsOneWidget);
    },
  );

  testWidgets(
    "ButtonComponent can hide execution visuals while still blocking taps",
    (tester) async {
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
    },
  );

  testWidgets("ButtonComponent resets state after async errors", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        ButtonComponent(
          label: "Fail",
          onTap: () async => throw StateError("failed"),
        ),
      ),
    );

    await tester.tap(find.text("Fail"));
    await tester.pump();

    expect(find.text("Fail"), findsOneWidget);
    expect(find.byKey(const ValueKey('loading')), findsNothing);
    expect(find.byKey(const ValueKey('success')), findsNothing);
  });

  testWidgets(
    "ButtonComponent remains disabled when onTap is null or disabled",
    (tester) async {
      var tapCount = 0;

      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              const ButtonComponent(label: "No callback", onTap: null),
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
    },
  );

  testWidgets("ButtonComponent renders pressed visual state from gesture", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(ButtonComponent(label: "Continue", onTap: () {})),
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

    expect(_containerColor(tester), ColorTokens.light.primaryLight);
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

  testWidgets("IconButtonComponent renders Figma size and pressed state", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        IconButtonComponent(
          icon: const Icon(Icons.add),
          variant: IconButtonComponentVariant.primary,
          onTap: () {},
        ),
      ),
    );

    final surfaceFinder = find.byKey(const ValueKey('icon-button-surface'));
    final surface = tester.widget<AnimatedContainer>(surfaceFinder);
    final decoration = surface.decoration! as BoxDecoration;

    expect(tester.getSize(surfaceFinder), const Size(36, 36));
    expect(decoration.color, ColorTokens.light.fillLight);

    final gesture = await tester.startGesture(tester.getCenter(surfaceFinder));
    await tester.pump(const Duration(milliseconds: 200));

    final pressedSurface = tester.widget<AnimatedContainer>(surfaceFinder);
    final pressedDecoration = pressedSurface.decoration! as BoxDecoration;
    expect(pressedDecoration.color, ColorTokens.light.fillDarker);

    await gesture.up();
  });

  testWidgets("IconButtonComponent default variant is secondary", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(IconButtonComponent(icon: const Icon(Icons.add), onTap: () {})),
    );

    expect(_iconButtonColor(tester), Colors.transparent);
  });

  testWidgets("IconButtonComponent calls taps only when enabled", (
    tester,
  ) async {
    var tapCount = 0;

    await tester.pumpWidget(
      _wrap(
        IconButtonComponent(
          icon: const Icon(Icons.add),
          onTap: () => tapCount += 1,
        ),
      ),
    );

    await tester.tap(find.byType(GestureDetector));
    await tester.pump();

    expect(tapCount, 1);
  });

  testWidgets("IconButtonComponent mutes disabled foreground", (tester) async {
    await tester.pumpWidget(
      _wrap(
        const IconButtonComponent(
          icon: Icon(Icons.add),
          variant: IconButtonComponentVariant.primary,
          onTap: null,
        ),
      ),
    );

    final iconTheme = tester.widget<IconTheme>(
      find.descendant(
        of: find.byKey(const ValueKey('icon-button-surface')),
        matching: find.byType(IconTheme),
      ),
    );
    expect(iconTheme.data.color, ColorTokens.light.textLighter);
  });

  testWidgets("IconButtonComponent resets state after async errors", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        IconButtonComponent(
          icon: const Icon(Icons.add),
          onTap: () async => throw StateError("failed"),
        ),
      ),
    );

    await tester.tap(find.byType(GestureDetector));
    await tester.pump();

    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byKey(const ValueKey('loading')), findsNothing);
    expect(find.byKey(const ValueKey('success')), findsNothing);
  });

  testWidgets("IconButtonComponent surfaces async execution states", (
    tester,
  ) async {
    var tapCount = 0;
    final completer = Completer<void>();

    await tester.pumpWidget(
      _wrap(
        IconButtonComponent(
          icon: const Icon(Icons.add),
          onTap: () {
            tapCount += 1;
            return completer.future;
          },
        ),
      ),
    );

    await tester.tap(find.byType(GestureDetector));
    await tester.pump();

    expect(tapCount, 1);
    expect(find.byKey(const ValueKey('loading')), findsNothing);

    await tester.tap(find.byType(GestureDetector));
    await tester.pump();

    expect(tapCount, 1);

    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('loading')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byIcon(Icons.add), findsNothing);

    completer.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const ValueKey('success')), findsOneWidget);
  });

  testWidgets("IconButtonComponent can show success for fast actions", (
    tester,
  ) async {
    var tapCount = 0;

    await tester.pumpWidget(
      _wrap(
        IconButtonComponent(
          icon: const Icon(Icons.add),
          shouldShowSuccessConfirmation: true,
          onTap: () => tapCount += 1,
        ),
      ),
    );

    await tester.tap(find.byType(GestureDetector));
    await tester.pump();

    expect(tapCount, 1);
    expect(find.byKey(const ValueKey('success')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byIcon(Icons.add), findsNothing);
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ComponentTheme.lightTheme(),
    home: Scaffold(body: Center(child: child)),
  );
}

Color _containerColor(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(
    find.byType(AnimatedContainer),
  );
  return (container.decoration! as BoxDecoration).color!;
}

Color _iconButtonColor(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(
    find.byKey(const ValueKey('icon-button-surface')),
  );
  return (container.decoration! as BoxDecoration).color!;
}
