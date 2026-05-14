import 'dart:async';

import 'package:ente_components/components/app_bar_component.dart';
import 'package:ente_components/components/header_component.dart';
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
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ComponentTheme.lightTheme(),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, height: height, child: child),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('MenuComponent renders slots, states, and handles taps',
      (tester) async {
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
      IconTheme.of(tester.element(find.byIcon(Icons.cloud_upload_outlined)))
          .color,
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
    expect(find.byIcon(Icons.chevron_right), findsNothing);

    completer.complete();
    await tester.pump();
    expect(find.byKey(const ValueKey('menu-item-success')), findsOneWidget);
    expect(find.byKey(const ValueKey('menu-item-loading')), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('MenuComponent can show only loading without success',
      (tester) async {
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

  testWidgets('MenuComponent can force success for fast actions',
      (tester) async {
    await pumpComponent(
      tester,
      MenuComponent(
        title: 'Copy',
        alwaysShowSuccessState: true,
        onTap: () async {},
      ),
    );

    await tester.tap(find.text('Copy'));
    await tester.pump();
    expect(find.byKey(const ValueKey('menu-item-success')), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(const ValueKey('menu-item-success')), findsNothing);
  });

  testWidgets('MenuComponent can disable gestures for display-only rows',
      (tester) async {
    var tapCount = 0;

    await pumpComponent(
      tester,
      MenuComponent(
        title: 'Storage plan',
        gesturesEnabled: false,
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
            alwaysShowSuccessState: true,
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
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets(
      'MenuComponent long text uses two title lines and one subtitle line', (
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

  testWidgets(
      'MenuComponent grows with text scale from typography-derived height', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ComponentTheme.lightTheme(),
        home: const MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(1.6),
          ),
          child: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 260,
                child: MenuComponent(
                  title: 'Camera uploads',
                  subtitle: 'Enabled on Wi-Fi',
                  leading: Icon(Icons.cloud_upload_outlined),
                  trailing: Icon(Icons.chevron_right),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(MenuComponent)).height, greaterThan(60));
  });

  testWidgets('TitleBarComponent renders heading and status variants',
      (tester) async {
    await pumpComponent(
      tester,
      const TitleBarComponent(
        variant: TitleBarComponentVariant.titleTopbar,
        title: 'Heading',
        leading: Icon(Icons.arrow_back),
        trailing: Icon(Icons.search),
      ),
      width: 327,
      height: 42,
    );

    expect(find.text('Heading'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(tester.getSize(find.byType(TitleBarComponent)), const Size(327, 42));
    expect(
      tester.getTopRight(find.byIcon(Icons.search)).dx,
      tester.getTopRight(find.byType(TitleBarComponent)).dx,
    );

    await pumpComponent(
      tester,
      const TitleBarComponent(
        variant: TitleBarComponentVariant.preserving,
        leading: Icon(Icons.menu),
        trailing: Icon(Icons.upload),
        statusIcon: Icon(Icons.sync),
      ),
      width: 327,
      height: 42,
    );

    expect(find.text('Preserving 3 memories'), findsOneWidget);
    expect(find.text('ente'), findsNothing);
    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.byIcon(Icons.upload), findsOneWidget);
    expect(
      tester.getTopRight(find.byIcon(Icons.upload)).dx,
      tester.getTopRight(find.byType(TitleBarComponent)).dx,
    );
  });

  testWidgets(
      'TitleBarComponent keeps title centered with multiple trailing actions', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      const TitleBarComponent(
        variant: TitleBarComponentVariant.titleTopbar,
        title: 'Buttons',
        leadingWidth: 44,
        trailingWidth: 88,
        leading: Icon(Icons.arrow_back),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.text_fields),
            Icon(Icons.dark_mode),
          ],
        ),
      ),
      width: 327,
      height: 42,
    );

    final titleCenter = tester.getCenter(find.text('Buttons')).dx;
    final barCenter = tester.getCenter(find.byType(TitleBarComponent)).dx;

    expect((titleCenter - barCenter).abs(), lessThan(1));
    expect(find.byIcon(Icons.text_fields), findsOneWidget);
    expect(find.byIcon(Icons.dark_mode), findsOneWidget);
  });

  testWidgets('HeaderComponent renders image, subtitle, and multiple actions', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      const HeaderComponent(
        title: 'Title',
        subtitle: 'Subtitle',
        leading: ColoredBox(
          key: ValueKey('header-image'),
          color: Colors.blue,
        ),
        actions: [
          Icon(Icons.add),
          Icon(Icons.more_horiz),
        ],
      ),
      width: 327,
    );

    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Subtitle'), findsOneWidget);
    expect(find.byKey(const ValueKey('header-image')), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz), findsOneWidget);

    final imageSize =
        tester.getSize(find.byKey(const ValueKey('header-image')));
    expect(imageSize, const Size(36, 36));
  });
}
