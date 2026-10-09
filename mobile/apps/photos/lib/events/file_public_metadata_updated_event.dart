import "package:photos/events/event.dart";
import "package:photos/models/file/file.dart";

class FilePublicMetadataUpdatedEvent extends Event {
  final Map<int, FilePublicMetadataUpdate> updates;

  FilePublicMetadataUpdatedEvent(Iterable<EnteFile> files)
    : updates = Map.unmodifiable({
        for (final file in files)
          if (file.uploadedFileID != null)
            file.uploadedFileID!: FilePublicMetadataUpdate(
              uploadedFileID: file.uploadedFileID!,
              encodedJson: file.pubMmdEncodedJson,
              version: file.pubMmdVersion,
            ),
      });
}

class FilePublicMetadataUpdate {
  final int uploadedFileID;
  final String? encodedJson;
  final int version;

  const FilePublicMetadataUpdate({
    required this.uploadedFileID,
    required this.encodedJson,
    required this.version,
  });

  bool applyTo(EnteFile file) {
    if (file.uploadedFileID != uploadedFileID ||
        file.pubMmdVersion >= version) {
      return false;
    }
    file
      ..pubMmdEncodedJson = encodedJson
      ..pubMmdVersion = version;
    return true;
  }
}
