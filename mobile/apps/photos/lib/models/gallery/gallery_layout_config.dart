import "package:photos/settings/local_settings.dart";

const isJustifiedLayoutAvailable = true;

GalleryLayoutType resolveGalleryLayoutType(
  GalleryLayoutType preferredLayoutType, {
  bool? justifiedLayoutAvailable,
}) {
  final isAvailable = justifiedLayoutAvailable ?? isJustifiedLayoutAvailable;
  if (preferredLayoutType == GalleryLayoutType.justified && !isAvailable) {
    return GalleryLayoutType.grid;
  }
  return preferredLayoutType;
}
