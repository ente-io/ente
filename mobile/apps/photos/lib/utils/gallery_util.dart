import "package:photos/service_locator.dart";

double get galleryCacheExtent {
  final int photoGridSize = localSettings.getPhotoGridSize();
  switch (photoGridSize) {
    case 2:
    case 3:
      return 1000;
    case 4:
      return 850;
    case 5:
      return 600;
    case 6:
      return 300;
    default:
      throw StateError('Invalid photo grid size configuration: $photoGridSize');
  }
}
