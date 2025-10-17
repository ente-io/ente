import "package:logging/logging.dart";
import "package:photos/utils/isolate/isolate_operations.dart";
import "package:photos/utils/isolate/super_isolate.dart";

@pragma('vm:entry-point')
class WidgetImageIsolate extends SuperIsolate {
  WidgetImageIsolate._privateConstructor();
  static final WidgetImageIsolate instance =
      WidgetImageIsolate._privateConstructor();
  factory WidgetImageIsolate() => instance;

  final Logger _logger = Logger("WidgetImageIsolate");

  @override
  Logger get logger => _logger;

  @override
  bool get isDartUiIsolate => true;

  @override
  bool get shouldAutomaticDispose => true;

  @override
  String get isolateName => "WidgetImageIsolate";

  Future<({int width, int height})?> generateWidgetImage({
    required String sourcePath,
    required String cachePath,
    required double targetShortSide,
    required int quality,
  }) async {
    try {
      final dynamic result = await runInIsolate(
        IsolateOperation.generateWidgetImage,
        {
          'sourcePath': sourcePath,
          'cachePath': cachePath,
          'targetShortSide': targetShortSide,
          'quality': quality,
        },
      );
      if (result case {'width': final int width, 'height': final int height}) {
        return (width: width, height: height);
      }
    } catch (e, s) {
      _logger.warning(
        "Failed to generate widget image in isolate",
        e,
        s,
      );
    }
    return null;
  }

  Future<({int width, int height})?> readImageDimensions(
    String path,
  ) async {
    try {
      final dynamic result = await runInIsolate(
        IsolateOperation.readImageDimensions,
        {'path': path},
      );
      if (result case {'width': final int width, 'height': final int height}) {
        return (width: width, height: height);
      }
    } catch (e, s) {
      _logger.warning(
        "Failed to read widget image dimensions in isolate",
        e,
        s,
      );
    }
    return null;
  }
}
