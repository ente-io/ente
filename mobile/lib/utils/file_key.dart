import "dart:typed_data";

import "package:computer/computer.dart";
import "package:ente_crypto/ente_crypto.dart";
import "package:photos/models/file/file.dart";
import "package:photos/services/collections_service.dart";

Uint8List getFileKey(EnteFile file) {
  final cf = file.cf!;
  final collectionKey =
      CollectionsService.instance.getCollectionKey(cf.collectionID);
  return CryptoUtil.decryptSync(
    cf.encFileKey,
    collectionKey,
    cf.encFileKeyNonce,
  );
}

Future<Uint8List> getFileKeyUsingBgWorker(EnteFile file) async {
  final cf = file.cf!;
  final collectionKey =
      CollectionsService.instance.getCollectionKey(cf.collectionID);
  return await Computer.shared().compute(
    _decryptFileKey,
    param: <String, dynamic>{
      "encryptedKey": cf.encFileKey,
      "keyDecryptionNonce": cf.encFileKeyNonce,
      "collectionKey": collectionKey,
    },
  );
}

Uint8List _decryptFileKey(Map<String, dynamic> args) {
  final encryptedKey = CryptoUtil.base642bin(args["encryptedKey"]);
  final nonce = CryptoUtil.base642bin(args["keyDecryptionNonce"]);
  return CryptoUtil.decryptSync(
    encryptedKey,
    args["collectionKey"],
    nonce,
  );
}
