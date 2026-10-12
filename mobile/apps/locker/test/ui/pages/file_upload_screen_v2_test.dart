import 'dart:io';

import 'package:ente_components/ente_components.dart';
import 'package:ente_sharing/models/user.dart';
import 'package:ente_strings/ente_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/ui/components/collection_selection_widget_v2.dart';
import 'package:locker/ui/pages/file_upload_screen_v2.dart';

void main() {
  final files = [
    File('/upload/Passport_scan.pdf'),
    File('/upload/IMG_4821.png'),
  ];

  Future<void> showScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: StringsLocalizations.localizationsDelegates,
        supportedLocales: const [Locale('en')],
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    FileUploadScreenV2(files: files, collections: const []),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> openRowMenu(WidgetTester tester) async {
    await tester.tap(
      find
          .byWidgetPredicate(
            (w) =>
                w is HugeIcon && w.icon == HugeIcons.strokeRoundedMoreVertical,
          )
          .first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('removing every file shows the empty state instead of popping', (
    tester,
  ) async {
    await showScreen(tester);

    for (var i = 0; i < files.length; i++) {
      await openRowMenu(tester);
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
    }

    expect(find.byType(FileUploadScreenV2), findsOneWidget);
    expect(find.text('No items left to upload'), findsOneWidget);
    expect(find.text('Add items'), findsOneWidget);
    final save = tester.widget<ButtonComponent>(
      find.widgetWithText(ButtonComponent, 'Save'),
    );
    expect(save.isDisabled, isTrue);
  });

  testWidgets('rename from the row menu keeps the extension', (tester) async {
    await showScreen(tester);

    await openRowMenu(tester);
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Passport 2026');
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheetComponent),
        matching: find.text('Save'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Passport 2026.pdf'), findsOneWidget);
    expect(find.text('Passport_scan.pdf'), findsNothing);
  });

  testWidgets('back with items asks before discarding them', (tester) async {
    await showScreen(tester);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Discard upload?'), findsOneWidget);
    expect(find.byType(FileUploadScreenV2), findsOneWidget);

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byType(FileUploadScreenV2), findsNothing);
  });

  testWidgets('a removed file comes back with its original name', (
    tester,
  ) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('miguelruivo.flutter.plugins.filepicker'),
      (call) async => [
        {
          'name': 'Passport_scan.pdf',
          'path': '/upload/Passport_scan.pdf',
          'size': 1,
        },
      ],
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('miguelruivo.flutter.plugins.filepicker'),
        null,
      ),
    );
    await showScreen(tester);

    await openRowMenu(tester);
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Passport 2026');
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheetComponent),
        matching: find.text('Save'),
      ),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < files.length; i++) {
      await openRowMenu(tester);
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Add items'));
    await tester.pumpAndSettle();

    expect(find.text('Passport_scan.pdf'), findsOneWidget);
    expect(find.text('Passport 2026.pdf'), findsNothing);
  });

  Future<List<double>> cardHeights(
    WidgetTester tester, {
    required int files,
    required int collections,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: StringsLocalizations.localizationsDelegates,
        supportedLocales: const [Locale('en')],
        home: FileUploadScreenV2(
          key: ValueKey((files, collections)),
          files: [for (var i = 0; i < files; i++) File('/upload/f$i.pdf')],
          collections: [
            for (var i = 0; i < collections; i++)
              Collection(
                i,
                User(id: 1, email: 'a@b.c'),
                '',
                null,
                'Collection $i',
                null,
                null,
                CollectionType.folder,
                CollectionAttributes(),
                const [],
                const [],
                0,
              ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    return [
      for (final card in tester.widgetList(find.byType(ScrollCard)))
        tester.getSize(find.byWidget(card)).height,
    ];
  }

  testWidgets('long lists each stop at the same share of the screen', (
    tester,
  ) async {
    final heights = await cardHeights(tester, files: 10, collections: 10);
    expect(heights[0], moreOrLessEquals(heights[1]));
    expect(heights[0], lessThan(844 * 0.35));
  });

  testWidgets('a large batch only builds the visible file rows', (
    tester,
  ) async {
    await cardHeights(tester, files: 1000, collections: 0);
    expect(
      find.byType(MenuComponent, skipOffstage: false).evaluate().length,
      lessThan(50),
    );
  });

  testWidgets('large system text keeps Save on screen', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: StringsLocalizations.localizationsDelegates,
        supportedLocales: const [Locale('en')],
        home: FileUploadScreenV2(
          files: [for (var i = 0; i < 10; i++) File('/upload/f$i.pdf')],
          collections: const [],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Save').hitTestable(), findsOneWidget);
  });

  testWidgets('a short file list leaves the rest to collections', (
    tester,
  ) async {
    final heights = await cardHeights(tester, files: 1, collections: 10);
    expect(heights[1], greaterThan(heights[0] * 3));
  });

  testWidgets('a short portrait phone keeps collections reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: StringsLocalizations.localizationsDelegates,
        supportedLocales: const [Locale('en')],
        home: FileUploadScreenV2(
          files: [for (var i = 0; i < 10; i++) File('/upload/f$i.pdf')],
          collections: const [],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('New collection').hitTestable(), findsOneWidget);
  });
}
