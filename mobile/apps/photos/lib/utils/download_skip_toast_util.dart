import "package:photos/models/file/file.dart";

String buildSingleFileDownloadSkippedToastMessage(
  EnteFile file, {
  required String folderName,
  required String fallbackFileName,
}) {
  final title = (file.title ?? "").trim();
  final displayName = file.displayName.trim();
  final fileName = title.isNotEmpty
      ? title
      : displayName.isNotEmpty
          ? displayName
          : fallbackFileName;

  return "$fileName is already available in the $folderName folder on your device";
}

String buildSingleFileDownloadSkippedInMultiSelectionToastMessage(
  EnteFile file, {
  required String folderName,
  required String fallbackFileName,
}) {
  final title = (file.title ?? "").trim();
  final displayName = file.displayName.trim();
  final fileName = title.isNotEmpty
      ? title
      : displayName.isNotEmpty
          ? displayName
          : fallbackFileName;

  return "Download of $fileName skipped as it is already available in the $folderName folder on your device";
}

String buildMultipleFilesDownloadSkippedToastMessage(int fileCount) {
  if (fileCount == 1) {
    return "Download of 1 file skipped as it is already on your device";
  }
  return "Download of $fileCount files skipped as they are already on your device";
}

Future<String> getLocalFolderNameForDownloadSkipToast(
  EnteFile file, {
  required String fallbackFolderName,
}) async {
  final String deviceFolder = (file.deviceFolder ?? "").trim();
  if (deviceFolder.isNotEmpty) {
    return _getLastPathSegment(deviceFolder);
  }

  final asset = await file.getAsset;
  if (asset != null && await asset.exists) {
    final String relativePath =
        (asset.relativePath ?? "").trim().replaceFirst(RegExp(r'[/\\]+$'), '');
    if (relativePath.isNotEmpty) {
      return _getLastPathSegment(relativePath);
    }
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
