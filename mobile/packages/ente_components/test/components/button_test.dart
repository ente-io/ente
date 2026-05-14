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

      await tester.pump(const Duration(seconds: 2));
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
          state: IconButtonComponentState.pressed,
          onTap: () {},
        ),
      ),
    );

    final surfaceFinder = find.byKey(const ValueKey('icon-button-surface'));
    final surface = tester.widget<AnimatedContainer>(surfaceFinder);
    final decoration = surface.decoration! as BoxDecoration;

    expect(tester.getSize(surfaceFinder), const Size(36, 36));
    expect(decoration.color, ColorTokens.light.fillDarker);
  });

  testWidgets("IconButtonComponent default variant is secondary", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(IconButtonComponent(icon: const Icon(Icons.add), onTap: () {})),
    );

    expect(_iconButtonColor(tester), Colors.transparent);
  });

  testWidgets("IconButtonComponent maps loading and success affordances", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        IconButtonComponent(
          icon: const Icon(Icons.add),
          variant: IconButtonComponentVariant.green,
          isSuccess: true,
          onTap: () {},
        ),
      ),
    );

    final surface = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('icon-button-surface')),
    );
    final decoration = surface.decoration! as BoxDecoration;
    final successIcon = tester.widget<HugeIcon>(find.byType(HugeIcon));

    expect(decoration.color, ColorTokens.light.primary);
    expect(successIcon.color, ColorTokens.light.specialWhite);

    await tester.pumpWidget(
      _wrap(
        IconButtonComponent(
          icon: const Icon(Icons.add),
          isLoading: true,
          onTap: () {},
        ),
      ),
    );

    final loadingFinder = find.byKey(const ValueKey('loading'));
    expect(loadingFinder, findsOneWidget);
    expect(tester.widget(loadingFinder), isA<RotationTransition>());
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byIcon(Icons.add), findsNothing);
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

    await tester.pumpWidget(
      _wrap(
        IconButtonComponent(
          icon: const Icon(Icons.add),
          isLoading: true,
          onTap: () => tapCount += 1,
        ),
      ),
    );

    await tester.tap(find.byType(GestureDetector));
    await tester.pump();

    expect(tapCount, 1);
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

  testWidgets(
    "IconButtonComponent clears internal execution when parent takes control",
    (tester) async {
      final completer = Completer<void>();
      var externalLoading = false;

      Widget buildButton() {
        return _wrap(
          IconButtonComponent(
            icon: const Icon(Icons.add),
            isLoading: externalLoading,
            onTap: () => completer.future,
          ),
        );
      }

      await tester.pumpWidget(buildButton());
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const ValueKey('loading')), findsOneWidget);

      externalLoading = true;
      await tester.pumpWidget(buildButton());
      await tester.pump();

      expect(find.byKey(const ValueKey('loading')), findsOneWidget);

      externalLoading = false;
      await tester.pumpWidget(buildButton());
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const ValueKey('loading')), findsNothing);
      expect(find.byIcon(Icons.add), findsOneWidget);

      completer.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byKey(const ValueKey('success')), findsNothing);
      expect(find.byIcon(Icons.add), findsOneWidget);
    },
  );

  testWidgets(
    "IconButtonComponent is semantically disabled while success is visible",
    (tester) async {
      var tapCount = 0;

      await tester.pumpWidget(
        _wrap(
          IconButtonComponent(
            icon: const Icon(Icons.add),
            tooltip: "Add",
            shouldShowSuccessConfirmation: true,
            onTap: () => tapCount += 1,
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      expect(tapCount, 1);
      expect(find.byKey(const ValueKey('success')), findsOneWidget);

      final semantics = tester.widget<Semantics>(
        find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == "Add",
        ),
      );
      expect(semantics.properties.button, isTrue);
      expect(semantics.properties.enabled, isFalse);
    },
  );

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
