import "dart:convert";

import "package:dio/dio.dart";
import "package:ente_components/ente_components.dart";
import "package:ente_strings/ente_strings.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:photos/core/cache/thumbnail_in_memory_cache.dart";
import "package:photos/core/constants.dart";
import "package:photos/ente_theme_data.dart";
import "package:photos/models/backup/backup_item.dart";
import "package:photos/models/backup/backup_item_status.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/service_locator.dart";
import "package:photos/ui/settings/backup/backup_item_card.dart";
import "package:photos/ui/settings/backup/backup_status_view.dart";
import "package:shared_preferences/shared_preferences.dart";

void main() {
  setUpAll(() async {
    for (final family in ["Inter", "Outfit"]) {
      final loader = FontLoader("packages/ente_components/$family");
      for (final weight in ["Regular", "Medium", "SemiBold", "Bold"]) {
        loader.addFont(
          rootBundle.load("packages/ente_components/fonts/$family-$weight.ttf"),
        );
      }
      await loader.load();
    }
    SharedPreferences.setMockInitialValues({});
    ServiceLocator.instance.init(
      await SharedPreferences.getInstance(),
      Dio(),
      Dio(),
      Dio(),
      PackageInfo(
        appName: "Photos",
        packageName: "photos",
        version: "1",
        buildNumber: "1",
      ),
    );
  });

  testWidgets("filters every upload state and reflects live status changes", (
    tester,
  ) async {
    final items = [
      for (final status in BackupItemStatus.values) _item(status.index, status),
    ];
    await tester.pumpWidget(_app(items));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(BackupItemCard), findsNWidgets(5));

    await tester.tap(find.text("Pending 3"));
    await tester.pump();
    expect(_visibleStatuses(tester), {
      BackupItemStatus.uploading,
      BackupItemStatus.inQueue,
      BackupItemStatus.inBackground,
    });
    await tester.tap(find.text("Failed 1"));
    await tester.pump();
    expect(_visibleStatuses(tester), {BackupItemStatus.retry});
    await tester.tap(find.widgetWithText(TagChipComponent, "Done"));
    await tester.pump();
    expect(_visibleStatuses(tester), {BackupItemStatus.uploaded});

    await tester.tap(find.text("Failed 1"));
    await tester.pump();
    await tester.pumpWidget(
      _app([
        for (final item in items)
          item.status == BackupItemStatus.retry
              ? item.withStatus(BackupItemStatus.uploading)
              : item,
      ]),
    );
    await tester.pump();
    expect(find.text("No failed backups"), findsOneWidget);
    expect(find.text("Failed 0"), findsOneWidget);
    expect(find.text("Pending 4"), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets(
    "keeps chips visible and reaches the final item without truncation",
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final items = List.generate(
        100,
        (index) => _item(index, BackupItemStatus.uploaded),
      );
      await tester.pumpWidget(_app(items));
      await tester.pump(const Duration(milliseconds: 600));
      final scrollable = find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text("photo-99.jpg"),
        500,
        scrollable: scrollable,
        maxScrolls: 25,
      );
      expect(find.text("photo-99.jpg").hitTestable(), findsOneWidget);
      expect(
        find.widgetWithText(TagChipComponent, "All").hitTestable(),
        findsOneWidget,
      );
      expect(find.byType(BackupItemCard).evaluate().length, lessThan(30));

      await tester.tap(find.text("Pending 0"));
      await tester.pump();
      expect(find.text("No pending backups").hitTestable(), findsOneWidget);
      await tester.ensureVisible(find.widgetWithText(TagChipComponent, "Done"));
      await tester.tap(find.widgetWithText(TagChipComponent, "Done"));
      await tester.pump();
      expect(find.text("photo-0.jpg").hitTestable(), findsOneWidget);
      await _dispose(tester);
    },
  );

  testWidgets("supports narrow screens and large text in both themes", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final dark in [false, true]) {
      await tester.pumpWidget(
        _app(
          [
            _item(0, BackupItemStatus.uploading),
            _item(1, BackupItemStatus.retry),
          ],
          dark: dark,
          scale: 2,
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip("Backup failed"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text("Contact support"), findsOneWidget);
      expect(find.text("OK").hitTestable(), findsOneWidget);
      await tester.tap(find.text("OK"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text("Contact support"), findsNothing);
      expect(tester.takeException(), isNull);
    }
    await _dispose(tester);
  });
}

Set<BackupItemStatus> _visibleStatuses(WidgetTester tester) => tester
    .widgetList<BackupItemCard>(find.byType(BackupItemCard))
    .map((card) => card.item.status)
    .toSet();

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

Widget _app(List<BackupItem> items, {bool dark = false, double scale = 1}) =>
    MaterialApp(
      theme: dark ? darkThemeData : lightThemeData,
      localizationsDelegates: StringsLocalizations.localizationsDelegates,
      supportedLocales: StringsLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: BackupStatusView(items: items),
    );

BackupItem _item(int index, BackupItemStatus status) {
  final file = EnteFile()
    ..generatedID = index
    ..localID = "local-$index"
    ..title = "photo-$index.jpg"
    ..deviceFolder = "Camera"
    ..fileType = FileType.image;
  ThumbnailInMemoryLruCache.put(
    file,
    base64Decode(
      "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+j6V8AAAAASUVORK5CYII=",
    ),
    thumbnailSmallSize,
  );
  return BackupItem(
    status: status,
    file: file,
    collectionID: 1,
    progressPercent: status == BackupItemStatus.uploading ? 68 : null,
    error: status == BackupItemStatus.retry ? Exception("Backup failed") : null,
  );
}
