import 'package:ente_components/ente_components.dart' show ComponentTheme;
import 'package:ente_components_catalog/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('catalog app mounts', (tester) async {
    await tester.pumpWidget(const ComponentsCatalogApp());

    expect(find.text('Components'), findsOneWidget);
  });

  testWidgets('button transition preview surfaces loading and success', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ComponentTheme.lightTheme(),
        home: const Scaffold(
          body: ButtonStateCyclePreview(),
        ),
      ),
    );

    final button = find.byKey(const ValueKey('button-cycle'));
    expect(button, findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 299));

    expect(find.byKey(const ValueKey('loading')), findsNothing);

    await tester.pump(const Duration(milliseconds: 1));

    expect(find.byKey(const ValueKey('loading')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump();

    expect(find.byKey(const ValueKey('success')), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text('Continue'), findsOneWidget);
  });
}
