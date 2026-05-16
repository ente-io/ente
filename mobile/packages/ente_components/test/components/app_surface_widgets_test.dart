import 'dart:async';

import 'package:ente_components/components/app_bar_component.dart';
import 'package:ente_components/components/menu_component.dart';
import 'package:ente_components/theme/colors.dart';
import 'package:ente_components/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpComponent(
  WidgetTester tester,
  Widget child, {
  double width = 420,
  double? height,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ComponentTheme.lightTheme(),
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: width, height: height, child: child),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('MenuComponent renders slots, states, and handles taps', (
    tester,
  ) async {
    var tapped = false;

    await pumpComponent(
      tester,
      MenuComponent(
        title: 'Camera uploads',
        subtitle: 'Enabled on Wi-Fi',
        leading: const Icon(Icons.cloud_upload_outlined),
        trailing: Icon(
          Icons.chevron_right,
          color: ColorTokens.light.textLight,
          size: 18,
        ),
        selected: true,
        titleColor: ColorTokens.light.warning,
        iconColor: ColorTokens.light.primary,
        onTap: () async => tapped = true,
      ),
    );

    expect(find.text('Camera uploads'), findsOneWidget);
    expect(find.text('Enabled on Wi-Fi'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(tester.getSize(find.byType(MenuComponent)).height, 60);
    final surface = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('menu-item-surface')),
    );
    final decoration = surface.decoration! as BoxDecoration;
    expect(decoration.border, isNotNull);
    expect(tester.widget<Text>(find.text('Camera uploads')).maxLines, 2);
    expect(tester.widget<Text>(find.text('Enabled on Wi-Fi')).maxLines, 1);
    expect(
      tester.widget<Text>(find.text('Camera uploads')).style?.color,
      ColorTokens.light.warning,
    );
    expect(
      IconTheme.of(
        tester.element(find.byIcon(Icons.cloud_upload_outlined)),
      ).color,
      ColorTokens.light.primary,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.chevron_right)).color,
      ColorTokens.light.textLight,
    );

    await tester.tap(find.text('Camera uploads'));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets(
    'MenuComponent delays loading, blocks repeat taps, and shows success',
    (tester) async {
      final completer = Completer<void>();
      var tapCount = 0;

      await pumpComponent(
        tester,
        MenuComponent(
          title: 'Sync now',
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            tapCount += 1;
            return completer.future;
          },
        ),
      );

      await tester.tap(find.text('Sync now'));
      await tester.pump(const Duration(milliseconds: 299));
      expect(find.byKey(const ValueKey('menu-item-loading')), findsNothing);

      await tester.tap(find.text('Sync now'));
      await tester.pump(const Duration(milliseconds: 1));
      expect(tapCount, 1);
      expect(find.byKey(const ValueKey('menu-item-loading')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byIcon(Icons.chevron_right), findsNothing);

      completer.complete();
      await tester.pump();
      expect(find.byKey(const ValueKey('menu-item-success')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const ValueKey('menu-item-loading')), findsNothing);

      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    },
  );

  testWidgets('MenuComponent can show only loading without success', (
    tester,
  ) async {
    final completer = Completer<void>();

    await pumpComponent(
      tester,
      MenuComponent(
        title: 'Refresh',
        showOnlyLoadingState: true,
        onTap: () => completer.future,
      ),
    );

    await tester.tap(find.text('Refresh'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('menu-item-loading')), findsOneWidget);

    completer.complete();
    await tester.pump();
    expect(find.byKey(const ValueKey('menu-item-success')), findsNothing);
    expect(find.byKey(const ValueKey('menu-item-loading')), findsNothing);
  });

  testWidgets('MenuComponent can force success for fast actions', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      MenuComponent(
        title: 'Copy',
        shouldShowSuccessConfirmation: true,
        onTap: () async {},
      ),
    );

    await tester.tap(find.text('Copy'));
    await tester.pump();
    expect(find.byKey(const ValueKey('menu-item-success')), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('menu-item-success')), findsNothing);
  });

  testWidgets('MenuComponent resets to idle after async errors', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      MenuComponent(
        title: 'Fail',
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await Future<void>.delayed(const Duration(milliseconds: 400));
          throw StateError('failed');
        },
      ),
    );

    await tester.tap(find.text('Fail'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('menu-item-loading')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Fail'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(find.byKey(const ValueKey('menu-item-loading')), findsNothing);
    expect(find.byKey(const ValueKey('menu-item-success')), findsNothing);
  });

  testWidgets('MenuComponent can disable gestures for display-only rows', (
    tester,
  ) async {
    var tapCount = 0;

    await pumpComponent(
      tester,
      MenuComponent(
        title: 'Storage plan',
        isDisabled: true,
        onTap: () {
          tapCount += 1;
        },
      ),
    );

    await tester.tap(find.text('Storage plan'));
    await tester.pump();
    expect(tapCount, 0);
  });

  testWidgets('MenuComponent supports pressed and execution visuals', (
    tester,
  ) async {
    final loadingCompleter = Completer<void>();
    var tapCount = 0;
    await pumpComponent(
      tester,
      Column(
        children: [
          MenuComponent(
            title: 'Pressed row',
            onTap: () {
              tapCount += 1;
            },
          ),
          MenuComponent(
            title: 'Loading row',
            trailing: const Icon(Icons.chevron_right),
            showOnlyLoadingState: true,
            onTap: () => loadingCompleter.future,
          ),
          MenuComponent(
            title: 'Success row',
            trailing: const Icon(Icons.chevron_right),
            shouldShowSuccessConfirmation: true,
            onTap: () async {},
          ),
        ],
      ),
      height: 180,
    );

    await tester.press(find.text('Pressed row'));
    await tester.pump();
    await tester.tap(find.text('Loading row'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Success row'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final surfaces = tester.widgetList<AnimatedContainer>(
      find.byKey(const ValueKey('menu-item-surface')),
    );
    final pressedDecoration = surfaces.first.decoration! as BoxDecoration;
    expect(pressedDecoration.color, ColorTokens.light.fillDarker);
    expect(find.byKey(const ValueKey('menu-item-loading')), findsOneWidget);
    expect(find.byKey(const ValueKey('menu-item-success')), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    expect(tapCount, 0);
    loadingCompleter.complete();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('MenuComponent long text uses two title lines and one subtitle line', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      const MenuComponent(
        title:
            'Camera uploads from this device and shared albums waiting for review',
        subtitle:
            'This subtitle remains one line and truncates like app menu rows',
        leading: Icon(Icons.image_outlined),
        trailing: Icon(Icons.chevron_right),
      ),
      width: 260,
    );

    expect(
      tester
          .widget<Text>(
            find.text(
              'Camera uploads from this device and shared albums waiting for review',
            ),
          )
          .maxLines,
      2,
    );
    expect(
      tester
          .widget<Text>(
            find.text(
              'This subtitle remains one line and truncates like app menu rows',
            ),
          )
          .maxLines,
      1,
    );
    expect(tester.getSize(find.byType(MenuComponent)).height, greaterThan(60));
  });

  testWidgets('HeaderAppBarComponent scrolls without narrow width overflow', (
    tester,
  ) async {
    var addTapped = false;
    var leadingTapped = false;

    await pumpComponent(
      tester,
      CustomScrollView(
        slivers: [
          HeaderAppBarComponent(
            title: 'Menu items',
            subtitle: 'Scroll to collapse',
            onBack: () {},
            leading: GestureDetector(
              key: const ValueKey('header-leading'),
              behavior: HitTestBehavior.opaque,
              onTap: () => leadingTapped = true,
              child: const ColoredBox(color: Colors.blue),
            ),
            actions: [
              GestureDetector(
                key: const ValueKey('header-add-action'),
                behavior: HitTestBehavior.opaque,
                onTap: () => addTapped = true,
                child: const Icon(Icons.add),
              ),
              const Icon(Icons.dark_mode),
            ],
          ),
          SliverList.builder(
            itemCount: 24,
            itemBuilder: (context, index) {
              return SizedBox(height: 60, child: Text('Item $index'));
            },
          ),
        ],
      ),
      width: 390,
      height: 600,
    );

    expect(tester.takeException(), isNull);
    expect(tester.getCenter(find.byIcon(Icons.arrow_back)).dy, closeTo(28, 1));
    expect(tester.getSize(find.byIcon(Icons.arrow_back)).width, 24);
    expect(
      tester.getSize(find.byKey(const ValueKey('header-leading'))),
      const Size(38, 38),
    );
    expect(
      tester.getCenter(find.byKey(const ValueKey('header-leading'))).dy,
      closeTo(71, 1),
    );
    expect(tester.getCenter(find.byIcon(Icons.add)).dy, closeTo(67, 1));

    await tester.tap(find.byKey(const ValueKey('header-leading')));
    await tester.pump();
    expect(leadingTapped, isTrue);

    await tester.tap(find.byKey(const ValueKey('header-add-action')));
    await tester.pump();
    expect(addTapped, isTrue);

    for (var index = 0; index < 8; index++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -24));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -180));
    await tester.pump();

    leadingTapped = false;
    await tester.tap(
      find.byKey(const ValueKey('header-leading')),
      warnIfMissed: false,
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(leadingTapped, isFalse);
    expect(
      tester.getCenter(find.byIcon(Icons.add)).dy,
      closeTo(tester.getCenter(find.byIcon(Icons.arrow_back)).dy, 1),
    );
    expect(find.text('Menu items'), findsWidgets);
  });

  testWidgets('HeaderAppBarComponent adapts vertical space for large text', (
    tester,
  ) async {
    const title = 'A very large header title that should stay constrained';

    await pumpComponent(
      tester,
      CustomScrollView(
        slivers: [
          const HeaderAppBarComponent(
            title: title,
            subtitle: 'Large text subtitle',
            onBack: null,
            actions: [Icon(Icons.add)],
          ),
          SliverList.builder(
            itemCount: 12,
            itemBuilder: (context, index) {
              return SizedBox(height: 60, child: Text('Scaled item $index'));
            },
          ),
        ],
      ),
      width: 390,
      height: 600,
      textScaler: const TextScaler.linear(2.5),
    );

    expect(tester.takeException(), isNull);
    expect(find.text(title), findsOneWidget);
    expect(tester.getBottomLeft(find.text(title)).dy, lessThanOrEqualTo(118));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -240));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text(title), findsOneWidget);
  });
}
