// EnteFile is base file entry for various type of files
// like DeviceFile,RemoteFile or TrashedFile

// @dart=2.9

abstract class EnteFile {
  // returns cacheKey which should be used while caching entry related to
  // this file.
  String cacheKey();

  // returns localIdentifier for the file on the host OS.
  // Can be null if the file only exist on remote
  String localIdentifier();
}
