// EnteFile is base file entry for various type of files
// like DeviceFile,RemoteFile or TrashedFile

abstract class EnteFile {
  // returns cacheKey which should be used while caching entry related to
  // this file.
  String cacheKey();
}
