import "package:photos/models/file/file.dart";

String getDownloadSkipToastFileName(
  EnteFile file, {
  required String fallbackFileName,
}) {
  final title = (file.title ?? "").trim();
  final displayName = file.displayName.trim();
  return title.isNotEmpty
      ? title
      : displayName.isNotEmpty
          ? displayName
          : fallbackFileName;
}

Future<String?> getExistingLocalFolderNameForDownloadSkipToast(
  EnteFile file, {
  required String fallbackFolderName,
}) async {
  if (file.localID == null) {
    return null;
  }
  final asset = await file.getAsset;
  if (asset == null || !(await asset.exists)) {
    return null;
  }
  final String relativePath =
      (asset.relativePath ?? "").trim().replaceFirst(RegExp(r'[/\\]+$'), '');
  if (relativePath.isNotEmpty) {
    return _getLastPathSegment(relativePath);
  }
  return fallbackFolderName;
}

String _getLastPathSegment(String path) {
  final normalized = path.trim().replaceFirst(RegExp(r'[/\\]+$'), '');
  if (normalized.isEmpty) {
    return normalized;
  }
  final segments = normalized
      .split(RegExp(r'[/\\]+'))
      .where((segment) => segment.trim().isNotEmpty)
      .toList();
  return segments.isEmpty ? normalized : segments.last;
}
