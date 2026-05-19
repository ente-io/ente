import "dart:async";

import "package:ente_components/ente_components.dart";
import "package:flutter/cupertino.dart";
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

  testWidgets("RadioComponent toggles to the next selected value", (
    tester,
  ) async {
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

  testWidgets("ToggleSwitchComponent toggles to the next selected value", (
    tester,
  ) async {
    bool? nextValue;

    await tester.pumpWidget(
      _wrap(
        ToggleSwitchComponent(
          selected: false,
          onChanged: (value) => nextValue = value,
        ),
      ),
    );

    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(nextValue, isTrue);
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets("ToggleSwitchComponent shows async loading and success", (
    tester,
  ) async {
    var selected = false;
    final completer = Completer<void>();

    await tester.pumpWidget(
      _wrap(
        StatefulBuilder(
          builder: (context, setState) {
            return ToggleSwitchComponent.async(
              value: () => selected,
              onChanged: () async {
                await completer.future;
                setState(() => selected = !selected);
              },
            );
          },
        ),
      ),
    );

    await tester.tap(find.byType(Switch));
    await tester.pump(const Duration(milliseconds: 299));
    expect(find.byKey(const ValueKey('toggle-state-loading')), findsNothing);

    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(const ValueKey('toggle-state-loading')), findsOneWidget);

    completer.complete();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('toggle-state-success')), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(const ValueKey('toggle-state-idle')), findsOneWidget);
  });

  testWidgets("ToggleSwitchComponent blocks repeat taps while updating", (
    tester,
  ) async {
    var selected = false;
    var changeCount = 0;
    final completer = Completer<void>();

    await tester.pumpWidget(
      _wrap(
        StatefulBuilder(
          builder: (context, setState) {
            return ToggleSwitchComponent.async(
              value: () => selected,
              onChanged: () async {
                changeCount += 1;
                await completer.future;
                setState(() => selected = !selected);
              },
            );
          },
        ),
      ),
    );

    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(changeCount, 1);

    completer.complete();
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets("ToggleSwitchComponent rolls back when value is not confirmed", (
    tester,
  ) async {
    const selected = false;

    await tester.pumpWidget(
      _wrap(
        ToggleSwitchComponent.async(
          value: () => selected,
          onChanged: () async {},
        ),
      ),
    );

    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
  });

  testWidgets("ToggleSwitchComponent rolls back after async errors", (
    tester,
  ) async {
    const selected = false;
    final completer = Completer<void>();

    await tester.pumpWidget(
      _wrap(
        ToggleSwitchComponent.async(
          value: () => selected,
          loadingDelay: const Duration(milliseconds: 1),
          onChanged: () => completer.future,
        ),
      ),
    );

    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(const ValueKey('toggle-state-loading')), findsOneWidget);

    completer.completeError(StateError('failed'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(find.byKey(const ValueKey('toggle-state-idle')), findsOneWidget);
  });

  testWidgets("ToggleSwitchComponent uses Cupertino switch on iOS", (
    tester,
  ) async {
    bool? nextValue;

    await tester.pumpWidget(
      _wrap(
        ToggleSwitchComponent(
          selected: false,
          onChanged: (value) => nextValue = value,
        ),
        platform: TargetPlatform.iOS,
      ),
    );

    await tester.tap(find.byType(CupertinoSwitch));
    await tester.pump();

    expect(nextValue, isTrue);
    expect(find.byType(Switch), findsNothing);
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets("LabeledControlComponent renders label and subtitle", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const LabeledControlComponent(
          control: CheckboxComponent(selected: true, onChanged: null),
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

Widget _wrap(Widget child, {TargetPlatform platform = TargetPlatform.android}) {
  return MaterialApp(
    theme: ComponentTheme.lightTheme().copyWith(platform: platform),
    home: Scaffold(body: Center(child: child)),
  );
}
