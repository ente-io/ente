import "dart:typed_data";

import "package:ente_crypto/ente_crypto.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/remote/collection_file.dart";
import "package:photos/services/collections_service.dart";

Uint8List getFileKey(EnteFile file) {
  return getKeyFromCF(file.cf!);
}

Uint8List getKeyFromCF(CollectionFile cf) {
  final collectionKey =
      CollectionsService.instance.getCollectionKey(cf.collectionID);
  return CryptoUtil.decryptSync(
    cf.encFileKey,
    collectionKey,
    cf.encFileKeyNonce,
  );
}

Future<Uint8List> getFileKeyAsync(EnteFile file) async {
  final cf = file.cf!;
  final collectionKey =
      CollectionsService.instance.getCollectionKey(cf.collectionID);
  return CryptoUtil.decrypt(
    cf.encFileKey,
    collectionKey,
    cf.encFileKeyNonce,
  );
}
