import "dart:convert";
import "dart:typed_data";

import "package:dio/dio.dart";
import "package:ente_icons/ente_icons.dart";
import "package:ente_strings/ente_strings.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:photos/app_mode.dart";
import "package:photos/core/cache/thumbnail_in_memory_cache.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/constants.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/ente_theme_data.dart";
import "package:photos/events/file_caption_updated_event.dart";
import "package:photos/events/local_photos_updated_event.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/models/file/trash_file.dart";
import "package:photos/models/file_load_result.dart";
import "package:photos/models/gallery_type.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/favorites_service.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/ui/viewer/gallery/component/gallery_file_indicators.dart";
import "package:photos/ui/viewer/gallery/component/gallery_file_widget.dart";
import "package:photos/ui/viewer/gallery/component/group/type.dart";
import "package:photos/ui/viewer/gallery/gallery.dart";
import "package:photos/ui/viewer/gallery/state/gallery_boundaries_provider.dart";
import "package:photos/ui/viewer/gallery/state/gallery_context_state.dart";
import "package:photos/ui/viewer/gallery/state/gallery_files_inherited_widget.dart";
import "package:shared_preferences/shared_preferences.dart";

class _Favorites extends Fake implements FavoritesService {
  bool favorite = false;

  @override
  bool isFavoriteCache(EnteFile file, {bool checkOnlyAlbum = false}) =>
      favorite;
}

EnteFile _file({int id = 1, String? json}) => EnteFile()
  ..generatedID = id
  ..uploadedFileID = id
  ..localID = "local-$id"
  ..creationTime = 1000000
  ..fileType = FileType.image
  ..title = "photo-$id.jpg"
  ..pubMmdEncodedJson = json;

Widget _host(Widget child) => MaterialApp(
  theme: lightThemeData,
  localizationsDelegates: StringsLocalizations.localizationsDelegates,
  supportedLocales: StringsLocalizations.supportedLocales,
  home: Scaffold(
    body: Align(alignment: Alignment.topLeft, child: child),
  ),
);

void _cacheThumbnail(EnteFile file) {
  ThumbnailInMemoryLruCache.put(
    file,
    Uint8List.fromList(
      base64Decode(
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQI12P4z8DwHwAFAAH/iZnRjQAAAABJRU5ErkJggg==",
      ),
    ),
    thumbnailSmallSize,
  );
}

Widget _tile(
  EnteFile file, {
  GalleryType? type,
  GroupType groupType = GroupType.day,
  bool picker = false,
}) {
  _cacheThumbnail(file);
  return GalleryContextState(
    sortOrderAsc: false,
    galleryType: type,
    type: groupType,
    child: SizedBox(
      width: 87,
      height: 87,
      child: GalleryFileWidget(
        file: file,
        selectedFiles: null,
        limitSelectionToOne: picker,
        tag: "caption_",
        photoGridSize: 4,
        currentUserID: null,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final originalFavorites = FavoritesService.instance;
  late _Favorites favorites;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    ServiceLocator.instance.init(
      preferences,
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
    try {
      await Configuration.instance.init(preferences);
    } catch (_) {}
    expect(flagService.internalUser, isTrue);
  });

  setUp(() {
    favorites = _Favorites();
    FavoritesService.instance = favorites;
  });

  tearDown(() async {
    FavoritesService.instance = originalFavorites;
    await localSettings.setInternalUserDisabled(false);
  });

  testWidgets(
    "caption events refresh duplicate entries without replacing the image loader",
    (tester) async {
      final file = _file(json: '{"mvi":1}');
      await tester.pumpWidget(_host(_tile(file)));
      await tester.pump();
      final thumbnailState = tester.state(find.byType(ThumbnailWidget));
      final thumbnail = tester.widget<ThumbnailWidget>(
        find.byType(ThumbnailWidget),
      );
      expect(find.byIcon(Icons.notes_rounded), findsNothing);

      Bus.instance.fire(
        FileCaptionUpdatedEvent(
          file.generatedID!,
          uploadedFileID: 2,
          caption: "Unrelated photo",
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.notes_rounded), findsNothing);

      Bus.instance.fire(
        FileCaptionUpdatedEvent(
          99,
          uploadedFileID: file.uploadedFileID!,
          caption: "Private description",
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.notes_rounded), findsOneWidget);
      expect(find.byIcon(Icons.album_outlined), findsOneWidget);
      expect(find.text("Private description"), findsNothing);
      expect(tester.state(find.byType(ThumbnailWidget)), same(thumbnailState));
      expect(
        tester.widget<ThumbnailWidget>(find.byType(ThumbnailWidget)),
        same(thumbnail),
      );

      final captionIcon = tester.widget<Icon>(find.byIcon(Icons.notes_rounded));
      Bus.instance.fire(
        FileCaptionUpdatedEvent(
          99,
          uploadedFileID: file.uploadedFileID!,
          caption: "Edited description",
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<Icon>(find.byIcon(Icons.notes_rounded)),
        same(captionIcon),
      );
      await tester.pumpWidget(_host(_tile(file)));
      expect(find.byIcon(Icons.notes_rounded), findsOneWidget);
      Bus.instance.fire(
        FileCaptionUpdatedEvent(
          99,
          uploadedFileID: file.uploadedFileID!,
          caption: "  ",
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.notes_rounded), findsNothing);
      expect(tester.state(find.byType(ThumbnailWidget)), same(thumbnailState));
      Bus.instance.fire(
        FileCaptionUpdatedEvent(
          99,
          uploadedFileID: file.uploadedFileID!,
          caption: "Saved again",
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.notes_rounded), findsOneWidget);
      final otherFile = _file(id: 2, json: '{"mvi":1}');
      await tester.pumpWidget(_host(_tile(otherFile)));
      expect(find.byIcon(Icons.notes_rounded), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      ThumbnailInMemoryLruCache.clearCache(file);
      ThumbnailInMemoryLruCache.clearCache(otherFile);
    },
  );

  testWidgets("only readable nonblank uploaded captions get a badge", (
    tester,
  ) async {
    for (final json in [
      null,
      jsonEncode({"caption": " \n "}),
      '{"caption":[]}',
      'not-json',
    ]) {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 60,
            height: 60,
            child: GalleryFileIndicators(file: _file(json: json)),
          ),
        ),
      );
      expect(find.byIcon(Icons.notes_rounded), findsNothing);
      expect(tester.takeException(), isNull);
    }
    final local = _file(json: '{"caption":"cached caption","mvi":1}')
      ..uploadedFileID = null;
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 60,
          height: 60,
          child: GalleryFileIndicators(file: local),
        ),
      ),
    );
    expect(find.byIcon(Icons.notes_rounded), findsNothing);
    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    expect(find.byIcon(Icons.album_outlined), findsOneWidget);
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 60,
          height: 60,
          child: GalleryFileIndicators(file: _file(json: '{"caption":42}')),
        ),
      ),
    );
    expect(find.byIcon(Icons.notes_rounded), findsOneWidget);
  });

  testWidgets(
    "dense footers keep both left combinations and Live inside the tile",
    (tester) async {
      favorites.favorite = true;
      for (final direction in TextDirection.values) {
        for (final (gridSize, width) in [
          (3, 116.0),
          (4, 87.0),
          (5, 69.0),
          (6, 58.0),
          (2, 45.0),
        ]) {
          for (final uploaded in [true, false]) {
            final file = _file(json: '{"caption":"text","mvi":1}');
            if (!uploaded) file.uploadedFileID = null;
            await tester.pumpWidget(
              _host(
                Directionality(
                  textDirection: direction,
                  child: SizedBox(
                    width: width,
                    height: width,
                    child: GalleryFileIndicators(
                      file: file,
                      photoGridSize: gridSize,
                    ),
                  ),
                ),
              ),
            );
            final tile = tester.getRect(find.byType(GalleryFileIndicators));
            Rect footprint(IconData icon) => tester.getRect(
              find.ancestor(
                of: find.byIcon(icon),
                matching: find.byType(ClipRect),
              ),
            );
            final first = footprint(
              uploaded ? EnteIcons.favoriteFilled : Icons.cloud_off_outlined,
            );
            final second = footprint(
              uploaded ? Icons.notes_rounded : EnteIcons.favoriteFilled,
            );
            final live = tester.getRect(find.byIcon(Icons.album_outlined));
            expect(first.left, greaterThanOrEqualTo(tile.left));
            expect(first.right, lessThan(second.left));
            expect(second.right, lessThan(live.left));
            expect(live.right, lessThanOrEqualTo(tile.right));
            expect(live.bottom, lessThanOrEqualTo(tile.bottom));
            expect(
              tester.widget<Icon>(find.byIcon(EnteIcons.favoriteFilled)).size,
              greaterThanOrEqualTo(12),
            );
            expect(tester.takeException(), isNull);
          }
        }
      }
    },
  );

  testWidgets(
    "disabled internal features and excluded tiles retain existing overlays",
    (tester) async {
      final file = _file(json: '{"caption":"private"}');
      await localSettings.setInternalUserDisabled(true);
      await tester.pumpWidget(_host(_tile(file)));
      expect(find.byType(GalleryFileIndicators), findsNothing);
      final thumbnail = tester.widget<ThumbnailWidget>(
        find.byType(ThumbnailWidget),
      );
      expect(thumbnail.shouldShowFavoriteIcon, isTrue);
      expect(thumbnail.shouldShowLivePhotoOverlay, isTrue);
      expect(thumbnail.shouldShowSyncStatus, isTrue);
      await localSettings.setInternalUserDisabled(false);
      await tester.pumpWidget(_host(_tile(file)));
      expect(find.byType(GalleryFileIndicators), findsOneWidget);
      expect(find.byIcon(Icons.notes_rounded), findsOneWidget);
      await tester.pumpWidget(
        _host(_tile(file, type: GalleryType.sharedPublicCollection)),
      );
      expect(find.byIcon(Icons.notes_rounded), findsOneWidget);
      final trashed = DeviceTrashFile.from(
        file,
        deleteBy: DateTime.now()
            .add(const Duration(days: 30))
            .microsecondsSinceEpoch,
      );
      for (final (entry, groupType) in [
        (trashed, GroupType.day),
        (file, GroupType.size),
        (_file()..debugCaption = "debug", GroupType.day),
      ]) {
        await tester.pumpWidget(_host(_tile(entry, groupType: groupType)));
        expect(find.byType(GalleryFileIndicators), findsNothing);
      }
      await tester.pumpWidget(_host(_tile(file, picker: true)));
      expect(find.byType(GalleryFileIndicators), findsNothing);
      await localSettings.setAppMode(AppMode.localGallery);
      await tester.pumpWidget(_host(_tile(file)));
      expect(find.byType(GalleryFileIndicators), findsNothing);
      await localSettings.setAppMode(AppMode.enteGallery);
      file.fileType = FileType.video;
      await tester.pumpWidget(_host(_tile(file)));
      expect(find.byType(GalleryFileIndicators), findsNothing);
      expect(
        tester
            .widget<ThumbnailWidget>(find.byType(ThumbnailWidget))
            .shouldShowVideoDuration,
        isTrue,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      ThumbnailInMemoryLruCache.clearCache(file);
    },
  );

  testWidgets("remote gallery reloads refresh caption indicators", (
    tester,
  ) async {
    final initial = _file();
    _cacheThumbnail(initial);
    var files = [initial];
    await tester.pumpWidget(
      _host(
        GalleryBoundariesProvider(
          child: GalleryFilesState(
            child: Gallery(
              tagPrefix: "caption_reload_",
              galleryType: GalleryType.searchResults,
              groupType: GroupType.none,
              reloadEvent: Bus.instance.on<LocalPhotosUpdatedEvent>(),
              asyncLoader: (start, end, {limit, asc}) async =>
                  FileLoadResult(files, false),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.notes_rounded), findsNothing);
    for (final caption in ["Saved remotely", ""]) {
      final refreshed = _file(json: jsonEncode({"caption": caption}));
      _cacheThumbnail(refreshed);
      files = [refreshed];
      Bus.instance.fire(
        LocalPhotosUpdatedEvent(files, source: "syncUpdateFromRemote"),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(
        find.byIcon(Icons.notes_rounded),
        caption.isEmpty ? findsNothing : findsOneWidget,
      );
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
    ThumbnailInMemoryLruCache.clearCache(initial);
  });
}
