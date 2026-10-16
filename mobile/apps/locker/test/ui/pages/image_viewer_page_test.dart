import "dart:async";
import "dart:convert";
import "dart:io";

import "package:ente_components/ente_components.dart";
import "package:ente_strings/ente_strings.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:locker/ui/pages/image_viewer_page.dart";

void main() {
  final png = base64Decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+ip1sAAAAASUVORK5CYII=",
  );
  late Directory dir;
  var openedExternally = 0;

  setUp(() {
    dir = Directory.systemTemp.createTempSync("image_viewer_test");
    openedExternally = 0;
  });

  tearDown(() => dir.deleteSync(recursive: true));

  File write(String name, List<int> bytes) =>
      File("${dir.path}/$name")..writeAsBytesSync(bytes);

  Future<void> pumpViewer(WidgetTester tester, File file) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ComponentTheme.lightTheme(app: ComponentApp.locker),
          localizationsDelegates: StringsLocalizations.localizationsDelegates,
          supportedLocales: const [Locale("en")],
          home: ImageViewerPage(
            localFile: file,
            fileName: file.uri.pathSegments.last,
            onOpenExternally: (_) async => openedExternally++,
          ),
        ),
      );
      final decoded = Completer<void>();
      final stream = ResizeImage(
        FileImage(file),
        width: 3072,
        height: 3072,
        policy: ResizeImagePolicy.fit,
      ).resolve(ImageConfiguration.empty);
      final listener = ImageStreamListener(
        (_, _) => decoded.complete(),
        onError: (_, _) => decoded.complete(),
      );
      stream.addListener(listener);
      await decoded.future.timeout(const Duration(seconds: 10));
      stream.removeListener(listener);
    });
    await tester.pump();
    await tester.pump();
  }

  Future<void> doubleTapAt(WidgetTester tester, Offset position) async {
    await tester.tapAt(position);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tapAt(position);
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets("shows a decoded image without the loading or error state", (
    tester,
  ) async {
    await pumpViewer(tester, write("photo.png", png));
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(LoadingComponent), findsNothing);
    expect(find.text("Error opening item"), findsNothing);
  });

  testWidgets("a file that cannot be decoded offers the external app", (
    tester,
  ) async {
    await pumpViewer(tester, write("broken.jpg", utf8.encode("nope")));
    expect(find.text("Error opening item"), findsOneWidget);
    await tester.tap(find.text("Open in another app"));
    await tester.pump(const Duration(milliseconds: 400));
    expect(openedExternally, 1);
  });

  testWidgets("a viewport change while zoomed resets the zoom", (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpViewer(tester, write("photo.png", png));
    final viewer = find.byType(InteractiveViewer);
    final controller = tester
        .widget<InteractiveViewer>(viewer)
        .transformationController!;
    await doubleTapAt(tester, const Offset(1100, 300));
    expect(controller.value.getTranslation().x, lessThan(-1000));

    tester.view.physicalSize = const Size(2400, 1200);
    await tester.pump();
    await tester.pump();
    expect(controller.value, Matrix4.identity());
  });

  testWidgets("double tap zooms around the tap and zooms back out", (
    tester,
  ) async {
    await pumpViewer(tester, write("photo.png", png));
    final viewer = find.byType(InteractiveViewer);
    final controller = tester
        .widget<InteractiveViewer>(viewer)
        .transformationController!;
    final tap = tester.getCenter(viewer) + const Offset(120, 180);
    final focus = controller.toScene(tap);

    await doubleTapAt(tester, tap);
    expect(controller.value.getMaxScaleOnAxis(), closeTo(2.5, 0.001));
    expect(controller.toScene(tap).dx, closeTo(focus.dx, 0.5));
    expect(controller.toScene(tap).dy, closeTo(focus.dy, 0.5));

    await doubleTapAt(tester, tap);
    expect(controller.value.getMaxScaleOnAxis(), closeTo(1, 0.001));
    expect(controller.value.getTranslation().x, 0);
    expect(controller.value.getTranslation().y, 0);
  });
}
