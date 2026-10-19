import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:photos/ui/tools/similar_image_file_info.dart";

void main() {
  testWidgets("missing size keeps the filename without a size label", (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SimilarImageFileInfo(displayName: "photo.jpg", fileSize: null),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text("photo.jpg"), findsOneWidget);
    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets("known size retains its formatted label", (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SimilarImageFileInfo(
            displayName: "photo.jpg",
            fileSize: 1572864,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text("photo.jpg"), findsOneWidget);
    expect(find.text("1.50 MB"), findsOneWidget);
  });
}
