import 'dart:async';

import 'package:ente_components/components/app_bar_component.dart';
import 'package:ente_components/components/menu_component.dart';
import 'package:ente_components/components/menu_group_component.dart';
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
          shouldSurfaceExecutionStates: true,
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
        shouldSurfaceExecutionStates: true,
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
        shouldSurfaceExecutionStates: true,
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

  testWidgets('MenuGroupComponent shapes a list of menu items', (tester) async {
    var tapped = false;
    var disabledTapped = false;

    await pumpComponent(
      tester,
      MenuGroupComponent(
        backgroundColor: Colors.orange,
        items: [
          MenuComponent(
            title: 'Account',
            leading: const Icon(Icons.person_outline),
            selected: true,
            titleColor: ColorTokens.light.warning,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => tapped = true,
          ),
          MenuComponent(
            title: 'Security',
            leading: const Icon(Icons.lock_outline),
            isDisabled: true,
            onTap: () => disabledTapped = true,
          ),
          const MenuComponent(
            title: 'Appearance',
            leading: Icon(Icons.palette_outlined),
          ),
        ],
      ),
      height: 180,
    );

    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Security'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Account')).style?.color,
      ColorTokens.light.warning,
    );

    final groupSurface = tester.widget<Container>(
      find.byKey(const ValueKey('menu-group-surface')),
    );
    final groupDecoration = groupSurface.decoration! as BoxDecoration;
    expect(
      groupDecoration.borderRadius,
      const BorderRadius.all(Radius.circular(20)),
    );

    final itemSurfaces = tester.widgetList<AnimatedContainer>(
      find.byKey(const ValueKey('menu-item-surface')),
    );
    final itemRadii = itemSurfaces
        .map((surface) => (surface.decoration! as BoxDecoration).borderRadius)
        .toList();
    final itemColors = itemSurfaces
        .map((surface) => (surface.decoration! as BoxDecoration).color)
        .toList();

    expect(itemRadii[0], const BorderRadius.vertical(top: Radius.circular(20)));
    expect(itemRadii[1], BorderRadius.zero);
    expect(
      itemRadii[2],
      const BorderRadius.vertical(bottom: Radius.circular(20)),
    );
    expect(itemColors, everyElement(Colors.orange));

    await tester.tap(find.text('Account'));
    await tester.tap(find.text('Security'));
    await tester.pump();

    expect(tapped, isTrue);
    expect(disabledTapped, isFalse);
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
            shouldSurfaceExecutionStates: true,
            onTap: () => loadingCompleter.future,
          ),
          MenuComponent(
            title: 'Success row',
            trailing: const Icon(Icons.chevron_right),
            shouldSurfaceExecutionStates: true,
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
