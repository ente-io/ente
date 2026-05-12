import "package:photos/models/file/file.dart";
import "package:photos/models/metadata/file_magic.dart";
import "package:test/test.dart";

void main() {
  group("PubMagicMetadata", () {
    test("parses display dimensions and rotation metadata", () {
      final metadata = PubMagicMetadata.fromMap({
        widthKey: "12240",
        heightKey: 16320,
        rotationDegreesKey: "90",
      }) as PubMagicMetadata;

      expect(metadata.w, 12240);
      expect(metadata.h, 16320);
      expect(metadata.rot, 90);
    });

    test("keeps legacy metadata valid when raw dimensions are missing", () {
      final metadata =
          PubMagicMetadata.fromMap({widthKey: 4000, heightKey: 3000})
              as PubMagicMetadata;

      expect(metadata.w, 4000);
      expect(metadata.h, 3000);
      expect(metadata.rot, isNull);
    });
  });

  group("EnteFile rotation metadata", () {
    test("tracks whether rotation metadata exists", () {
      final file = EnteFile()
        ..pubMagicMetadata = PubMagicMetadata(w: 12240, h: 16320);

      expect(file.rotationDegrees, isNull);
      expect(file.hasRotationDegrees, isFalse);

      file.pubMagicMetadata = PubMagicMetadata(w: 12240, h: 16320, rot: 90);

      expect(file.rotationDegrees, 90);
      expect(file.hasRotationDegrees, isTrue);
    });
  });
}
