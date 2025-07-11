import "package:photos/models/file/file.dart";
import "package:photos/models/local/asset_upload_queue.dart";

class AssetUploadCandidates {
  // own presents files that needs to be uploaded to the user's own collection
  // shared presents files that needs to be uploaded to the user's shared collection
  // unknwon presents files that needs to be uploaded to a collection that is not found
  List<(AssetUploadQueue, EnteFile)> own = [];
  List<(AssetUploadQueue, EnteFile)> shared = [];
  List<(AssetUploadQueue, EnteFile)> unknwon = [];
  int ignored = 0;
  int skippedVideos = 0;
  int forcedVideos = 0;
  bool includeVideos = false;
  AssetUploadCandidates({
    this.own = const [],
    this.shared = const [],
    this.unknwon = const [],
    this.ignored = 0,
    this.skippedVideos = 0,
    this.forcedVideos = 0,
    this.includeVideos = false,
  });

  /// debugPrint entries in a readable format, only include counts for list, and non-default values
  /// for other fields
  /// This is used for debugging purposes.
  /// @return a string representation of the AssetUploadCandidates
  @override
  String toString() {
    final StringBuffer sb = StringBuffer();
    sb.writeln("AssetUploadCandidates:");
    if (own.isNotEmpty) {
      sb.writeln("  ownedCollection: ${own.length}");
    }
    if (shared.isNotEmpty) {
      sb.writeln("  sharedCollection: ${shared.length}");
    }
    if (unknwon.isNotEmpty) {
      sb.writeln("  missingCollection: ${unknwon.length}");
    }
    if (ignored > 0) {
      sb.writeln("  ignored: $ignored");
    }
    if (skippedVideos > 0) {
      sb.writeln("  skippedVideos: $skippedVideos");
    }
    if (forcedVideos > 0) {
      sb.writeln("  forcedVideos: $forcedVideos");
    }
    sb.writeln("  includeVideos: $includeVideos");
    return sb.toString();
  }
}
