import "package:exif_reader/exif_reader.dart";
import "package:photos/utils/image_dimension_util.dart";
import "package:test/test.dart";

void main() {
  group("ImageDimensionMetadata", () {
    test("derives display dimensions from raw rotated dimensions", () {
      final dimensions = ImageDimensionMetadata.fromRawDimensions(
        rawWidth: 16320,
        rawHeight: 12240,
        rotationDegrees: 90,
      );

      expect(dimensions.width, 12240);
      expect(dimensions.height, 16320);
      expect(dimensions.rawWidth, 16320);
      expect(dimensions.rawHeight, 12240);
      expect(dimensions.rotationDegrees, 90);
    });

    test("keeps display dimensions for non-sideways rotations", () {
      final dimensions = ImageDimensionMetadata.fromRawDimensions(
        rawWidth: 16320,
        rawHeight: 12240,
        rotationDegrees: 180,
      );

      expect(dimensions.width, 16320);
      expect(dimensions.height, 12240);
      expect(dimensions.rotationDegrees, 180);
    });

    test("normalizes rotation before deriving display dimensions", () {
      final dimensions = ImageDimensionMetadata.fromRawDimensions(
        rawWidth: 16320,
        rawHeight: 12240,
        rotationDegrees: 450,
      );

      expect(dimensions.width, 12240);
      expect(dimensions.height, 16320);
      expect(dimensions.rotationDegrees, 90);
    });

    test("tracks when only display dimensions are known", () {
      final dimensions = ImageDimensionMetadata.displayOnly(
        width: 4000,
        height: 3000,
      );

      expect(dimensions.width, 4000);
      expect(dimensions.height, 3000);
      expect(dimensions.rawWidth, isNull);
      expect(dimensions.rawHeight, isNull);
      expect(dimensions.rotationDegrees, isNull);
      expect(dimensions.hasRawDimensions, isFalse);
    });
  });

  group("rotationDegreesFromExifOrientation", () {
    test("maps EXIF orientation variants to normalized rotation degrees", () {
      expect(rotationDegreesFromExifOrientation(1), 0);
      expect(rotationDegreesFromExifOrientation(2), 0);
      expect(rotationDegreesFromExifOrientation(3), 180);
      expect(rotationDegreesFromExifOrientation(4), 180);
      expect(rotationDegreesFromExifOrientation(5), 270);
      expect(rotationDegreesFromExifOrientation(6), 90);
      expect(rotationDegreesFromExifOrientation(7), 90);
      expect(rotationDegreesFromExifOrientation(8), 270);
    });

    test("normalizes arbitrary rotation degrees", () {
      expect(normalizeRotationDegrees(0), 0);
      expect(normalizeRotationDegrees(360), 0);
      expect(normalizeRotationDegrees(450), 90);
      expect(normalizeRotationDegrees(-90), 270);
    });
  });

  group("imageDimensionMetadataFromExifOrFallback", () {
    test("prefers EXIF raw dimensions over fallback dimensions", () {
      final dimensions = imageDimensionMetadataFromExifOrFallback(
        {
          'EXIF ExifImageWidth': _intTag(16320),
          'EXIF ExifImageLength': _intTag(12240),
          'Image Orientation': _intTag(6),
        },
        fallbackWidth: 16320,
        fallbackHeight: 12240,
      );

      expect(dimensions, isNotNull);
      expect(dimensions!.width, 12240);
      expect(dimensions.height, 16320);
      expect(dimensions.rawWidth, 16320);
      expect(dimensions.rawHeight, 12240);
      expect(dimensions.rotationDegrees, 90);
    });

    test(
      "returns display-only metadata when EXIF dimensions are unavailable",
      () {
        final dimensions = imageDimensionMetadataFromExifOrFallback(
          null,
          fallbackWidth: 4000,
          fallbackHeight: 3000,
        );

        expect(dimensions, isNotNull);
        expect(dimensions!.width, 4000);
        expect(dimensions.height, 3000);
        expect(dimensions.hasRawDimensions, isFalse);
      },
    );

    test("can apply EXIF orientation to fallback dimensions", () {
      final dimensions = imageDimensionMetadataFromExifOrFallback(
        {'Image Orientation': _intTag(6)},
        fallbackWidth: 16320,
        fallbackHeight: 12240,
        applyExifOrientationToFallback: true,
      );

      expect(dimensions, isNotNull);
      expect(dimensions!.width, 12240);
      expect(dimensions.height, 16320);
      expect(dimensions.rotationDegrees, 90);
      expect(dimensions.hasRawDimensions, isFalse);
    });

    test(
      "does not apply EXIF orientation to fallback dimensions by default",
      () {
        final dimensions = imageDimensionMetadataFromExifOrFallback(
          {'Image Orientation': _intTag(6)},
          fallbackWidth: 16320,
          fallbackHeight: 12240,
        );

        expect(dimensions, isNotNull);
        expect(dimensions!.width, 16320);
        expect(dimensions.height, 12240);
        expect(dimensions.hasRawDimensions, isFalse);
      },
    );

    test(
      "returns null when neither EXIF nor fallback dimensions are available",
      () {
        final dimensions = imageDimensionMetadataFromExifOrFallback(null);

        expect(dimensions, isNull);
      },
    );

    test("ignores incomplete fallback dimensions", () {
      expect(
        imageDimensionMetadataFromExifOrFallback(null, fallbackWidth: 4000),
        isNull,
      );
      expect(
        imageDimensionMetadataFromExifOrFallback(null, fallbackHeight: 3000),
        isNull,
      );
    });
  });
}

IfdTag _intTag(int value) {
  return IfdTag(
    tag: 0,
    tagType: "LONG",
    printable: value.toString(),
    values: IfdInts([value]),
  );
}
