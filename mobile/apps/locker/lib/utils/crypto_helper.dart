import "dart:typed_data";

import "package:ente_crypto_dart/ente_crypto_dart.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/services/configuration.dart";

class CryptoHelper {
  CryptoHelper._privateConstructor();
  static final CryptoHelper instance = CryptoHelper._privateConstructor();

  Uint8List getFileKey(
    String encryptedKey,
    String keyDecryptionNonce,
    Uint8List collectionKey,
  ) {
    final eKey = CryptoUtil.base642bin(encryptedKey);
    final nonce = CryptoUtil.base642bin(keyDecryptionNonce);
    return CryptoUtil.decryptSync(eKey, collectionKey, nonce);
  }

  Uint8List getCollectionKey(Collection collection) {
    final encryptedKey = CryptoUtil.base642bin(collection.encryptedKey);
    Uint8List? collectionKey;
    if (collection.owner.id == Configuration.instance.getUserID()) {
      // If the collection is owned by the user, decrypt with the master key
      if (Configuration.instance.getKey() == null) {
        // Possible during AppStore account migration, where SecureStorage
        // would become inaccessible to the new Developer Account
        throw Exception("key can not be null");
      }
      collectionKey = CryptoUtil.decryptSync(
        encryptedKey,
        Configuration.instance.getKey()!,
        CryptoUtil.base642bin(collection.keyDecryptionNonce!),
      );
    } else {
      // If owned by a different user, decrypt with the public key
      collectionKey = CryptoUtil.openSealSync(
        encryptedKey,
        CryptoUtil.base642bin(
          Configuration.instance.getKeyAttributes()!.publicKey,
        ),
        Configuration.instance.getSecretKey()!,
      );
    }
    return collectionKey;
  }
}
