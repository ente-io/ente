import "dart:typed_data";

import "package:computer/computer.dart";
import "package:ente_crypto/ente_crypto.dart";
import "package:photos/models/file/file.dart";
import "package:photos/services/collections_service.dart";

Uint8List getFileKey(EnteFile file) {
  final encryptedKey = CryptoUtil.base642bin(file.encryptedKey!);
  final nonce = CryptoUtil.base642bin(file.keyDecryptionNonce!);
  final collectionKey =
      CollectionsService.instance.getCollectionKey(file.collectionID!);
  return CryptoUtil.decryptSync(encryptedKey, collectionKey, nonce);
}

Future<Uint8List> getFileKeyUsingBgWorker(EnteFile file) async {
  final collectionKey =
      CollectionsService.instance.getCollectionKey(file.collectionID!);
  return await Computer.shared().compute(
    _decryptFileKey,
    param: <String, dynamic>{
      "encryptedKey": file.encryptedKey,
      "keyDecryptionNonce": file.keyDecryptionNonce,
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
