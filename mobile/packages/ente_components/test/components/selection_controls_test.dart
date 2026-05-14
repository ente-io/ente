import "package:ente_components/ente_components.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  testWidgets("CheckboxComponent toggles to the next selected value", (
    tester,
  ) async {
    bool? nextValue;

    await tester.pumpWidget(
      _wrap(
        CheckboxComponent(
          selected: false,
          onChanged: (value) => nextValue = value,
        ),
      ),
    );

    await tester.tap(find.byType(InkWell));
    await tester.pump();

    expect(nextValue, isTrue);
  });

  testWidgets("RadioComponent toggles to the next selected value",
      (tester) async {
    bool? nextValue;

    await tester.pumpWidget(
      _wrap(
        RadioComponent(
          selected: false,
          onChanged: (value) => nextValue = value,
        ),
      ),
    );

    await tester.tap(find.byType(InkWell));
    await tester.pump();

    expect(nextValue, isTrue);
  });

  testWidgets("ToggleSwitchComponent toggles to the next selected value",
      (tester) async {
    bool? nextValue;

    await tester.pumpWidget(
      _wrap(
        ToggleSwitchComponent(
          selected: false,
          onChanged: (value) => nextValue = value,
        ),
      ),
    );

    await tester.tap(find.byType(InkWell));
    await tester.pump();

    expect(nextValue, isTrue);
  });

  testWidgets("LabeledControlComponent renders label and subtitle",
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const LabeledControlComponent(
          control: CheckboxComponent(
            selected: true,
            onChanged: null,
          ),
          label: "Back up automatically",
          subtitle: "Includes new photos",
        ),
      ),
    );

    expect(find.text("Back up automatically"), findsOneWidget);
    expect(find.text("Includes new photos"), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets("FilterChipComponent renders selected state with token colors", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const FilterChipComponent(
          label: "Faces",
          state: FilterChipComponentState.selected,
        ),
      ),
    );

    final surfaceFinder = find.byKey(const ValueKey("filter-chip-surface"));
    final surface = tester.widget<AnimatedContainer>(surfaceFinder);
    final decoration = surface.decoration! as BoxDecoration;
    final label = tester.widget<Text>(find.text("Faces"));

    expect(tester.getSize(surfaceFinder).height, 40);
    expect(decoration.color, ColorTokens.light.primaryLight);
    expect(label.style?.color, ColorTokens.light.primary);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });

  testWidgets("FilterChipComponent toggles only when enabled", (tester) async {
    bool? nextValue;

    await tester.pumpWidget(
      _wrap(
        FilterChipComponent(
          label: "Albums",
          state: FilterChipComponentState.unselected,
          onChanged: (value) => nextValue = value,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey("filter-chip-surface")));
    await tester.pump();

    expect(nextValue, isTrue);

    await tester.pumpWidget(
      _wrap(
        FilterChipComponent(
          label: "Albums",
          state: FilterChipComponentState.disabled,
          onChanged: (value) => nextValue = value,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey("filter-chip-surface")));
    await tester.pump();

    expect(nextValue, isTrue);
  });

  testWidgets("FilterChipComponent clips avatar content", (tester) async {
    await tester.pumpWidget(
      _wrap(
        const FilterChipComponent(
          label: "Mira",
          avatar: ColoredBox(color: Colors.purple),
          state: FilterChipComponentState.unselected,
        ),
      ),
    );

    expect(find.byType(ClipRRect), findsOneWidget);
    expect(find.text("Mira"), findsOneWidget);
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ComponentTheme.lightTheme(),
    home: Scaffold(
      body: Center(child: child),
    ),
  );
}
