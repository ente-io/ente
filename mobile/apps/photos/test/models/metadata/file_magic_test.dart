import "package:photos/models/file/file.dart";
import "package:photos/models/metadata/file_magic.dart";
import "package:test/test.dart";

void main() {
  group("PubMagicMetadata", () {
    test("parses raw dimensions and rotation metadata", () {
      final metadata =
          PubMagicMetadata.fromMap({
                widthKey: "12240",
                heightKey: 16320,
                rawWidthKey: "16320",
                rawHeightKey: 12240,
                rotationDegreesKey: "90",
              })
              as PubMagicMetadata;

      expect(metadata.w, 12240);
      expect(metadata.h, 16320);
      expect(metadata.rw, 16320);
      expect(metadata.rh, 12240);
      expect(metadata.rot, 90);
    });

    test("keeps legacy metadata valid when raw dimensions are missing", () {
      final metadata =
          PubMagicMetadata.fromMap({widthKey: 4000, heightKey: 3000})
              as PubMagicMetadata;

      expect(metadata.w, 4000);
      expect(metadata.h, 3000);
      expect(metadata.rw, isNull);
      expect(metadata.rh, isNull);
      expect(metadata.rot, isNull);
    });
  });

  group("EnteFile raw dimensions", () {
    test("requires positive raw dimensions", () {
      final file = EnteFile()
        ..pubMagicMetadata = PubMagicMetadata(rw: -16320, rh: 12240);

      expect(file.hasRawDimensions, isFalse);

      file.pubMagicMetadata = PubMagicMetadata(rw: 16320, rh: 12240);

      expect(file.hasRawDimensions, isTrue);
    });
  });
}
