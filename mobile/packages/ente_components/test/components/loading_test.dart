import "package:ente_components/ente_components.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  Widget app(Widget child) => MaterialApp(
    theme: ComponentTheme.lightTheme(),
    home: Scaffold(body: Center(child: child)),
  );
  final paint = find.descendant(
    of: find.byType(LoadingComponent),
    matching: find.byType(CustomPaint),
  );
  const tick = Duration(milliseconds: 1);

  testWidgets("LoadingComponent paints a ring; large shows the %", (
    tester,
  ) async {
    await tester.pumpWidget(app(const LoadingComponent()));
    expect(paint, findsOneWidget);
    await tester.pumpWidget(
      app(
        const LoadingComponent(size: LoadingComponentSize.large, value: 0.45),
      ),
    );
    expect(find.text("45%"), findsOneWidget);
  });

  testWidgets("showLoadingComponent updates in place and hides", (
    tester,
  ) async {
    await tester.pumpWidget(app(const SizedBox()));
    final handle = showLoadingComponent(
      tester.element(find.byType(Scaffold)),
      "Deleting 3 items",
    );
    await tester.pump();
    await tester.pump(Motion.standard);
    expect(handle.isShowing(), isTrue);
    expect(find.text("Deleting 3 items"), findsOneWidget);

    handle.update(message: "Almost done", value: 0.45);
    await tester.pump();
    expect(find.text("Almost done"), findsOneWidget);

    final hidden = handle.hide();
    await tester.pump();
    await tester.pump(Motion.standard);
    await tester.pump(tick);
    await hidden;
    expect(handle.isShowing(), isFalse);
    expect(find.byType(LoadingComponent), findsNothing);
  });

  testWidgets("showLoadingComponent honours isDismissible", (tester) async {
    await tester.pumpWidget(app(const SizedBox()));
    final context = tester.element(find.byType(Scaffold));

    final fixed = showLoadingComponent(context, "Creating link");
    await tester.pump();
    await tester.pump(Motion.standard);
    await tester.pump(tick);
    await tester.tapAt(const Offset(5, 5));
    await tester.pump();
    await tester.pump(Motion.standard);
    expect(find.text("Creating link"), findsOneWidget);
    final hidden = fixed.hide();
    await tester.pump();
    await tester.pump(Motion.standard);
    await tester.pump(tick);
    await hidden;

    final dismissible = showLoadingComponent(
      context,
      "Creating link",
      isDismissible: true,
    );
    await tester.pump();
    await tester.pump(Motion.standard);
    await tester.tapAt(const Offset(5, 5));
    await tester.pump();
    await tester.pump(Motion.standard);
    await tester.pump(tick);
    expect(find.text("Creating link"), findsNothing);
    expect(dismissible.isShowing(), isFalse);
    dismissible.update(message: "Still safe after dismissal");
    await dismissible.hide();
  });

  testWidgets("LoadingComponent exposes its label and progress to semantics", (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      app(const LoadingComponent(value: 0.45, semanticsLabel: "Downloading")),
    );
    expect(
      tester.getSemantics(find.byType(LoadingComponent)),
      isSemantics(label: "Downloading", value: "45%"),
    );
    handle.dispose();
  });

  testWidgets("showLoadingComponent uses the caller's theme for every part", (
    tester,
  ) async {
    final local = ComponentTheme.darkTheme(app: ComponentApp.locker);
    final colors = local.extension<ComponentColorTokens>()!.colors;
    await tester.pumpWidget(
      MaterialApp(
        theme: ComponentTheme.lightTheme(),
        home: Theme(
          data: local,
          child: const Scaffold(body: SizedBox()),
        ),
      ),
    );
    showLoadingComponent(tester.element(find.byType(Scaffold)), "Opening");
    await tester.pump();
    await tester.pump(Motion.standard);

    final ring = tester.widget<CustomPaint>(paint);
    expect((ring.painter! as dynamic).color, colors.primary);
    final card = tester.widget<Container>(
      find.ancestor(of: find.text("Opening"), matching: find.byType(Container)),
    );
    expect((card.decoration! as BoxDecoration).color, colors.backgroundBase);
  });
}
