import 'dart:typed_data';

import 'package:computer/computer.dart';
import 'package:ente_auth/models/derived_key_result.dart';
import 'package:ente_auth/models/encryption_result.dart';
import 'package:logging/logging.dart';
import 'package:sodium_libs/sodium_libs.dart';

Future<Uint8List> cryptoSecretboxEasy(Map<String, dynamic> args) async {
  final sodium = await SodiumInit.init();
  return sodium.crypto.secretBox
      .easy(message: args["source"], nonce: args["nonce"], key: args["key"]);
}

Future<Uint8List> cryptoSecretboxOpenEasy(Map<String, dynamic> args) async {
  final sodium = await SodiumInit.init();
  return sodium.crypto.secretBox.openEasy(
    cipherText: args["cipher"],
    nonce: args["nonce"],
    key: SecureKey.fromList(sodium, args["key"]),
  );
}

Future<Uint8List> cryptoPwHash(Map<String, dynamic> args) async {
  final sodium = await SodiumInit.init();
  Logger("CryptoUtil").info("Sodium initialized: " + sodium.version.toString());
  return CryptoUtil.sodium.crypto.pwhash
      .call(
        outLen: CryptoUtil.sodium.crypto.secretBox.keyBytes,
        password: args["password"],
        salt: args["salt"],
        opsLimit: args["opsLimit"],
        memLimit: args["memLimit"],
      )
      .extractBytes();
}

Future<EncryptionResult> chachaEncryptData(Map<String, dynamic> args) async {
  final sodium = await SodiumInit.init();

  Stream<SecretStreamPlainMessage> getStream(Uint8List data) async* {
    yield SecretStreamPlainMessage(data, tag: SecretStreamMessageTag.finalPush);
  }

  final resultStream = sodium.crypto.secretStream.pushEx(
    key: SecureKey.fromList(sodium, args["key"]),
    messageStream: getStream(args["source"]),
  );
  Uint8List? header, encryptedData;
  await for (final value in resultStream) {
    if (header == null) {
      header = value.message;
      continue;
    } else {
      encryptedData = value.message;
    }
  }
  return EncryptionResult(encryptedData: encryptedData, header: header);
}

Future<Uint8List> chachaDecryptData(Map<String, dynamic> args) async {
  final sodium = await SodiumInit.init();

  Stream<SecretStreamCipherMessage> getStream() async* {
    yield SecretStreamCipherMessage(args["header"]);
    yield SecretStreamCipherMessage(args["source"]);
  }

  final resultStream = sodium.crypto.secretStream.pullEx(
    key: SecureKey.fromList(sodium, args["key"]),
    cipherStream: getStream(),
  );

  await for (final result in resultStream) {
    return result.message;
  }
    return Uint8List(0);
}

class CryptoUtil {
  static final Computer _computer = Computer();
  static late Sodium sodium;

  static init() async {
    _computer.turnOn(workersCount: 4);
    // Sodium.init();
    sodium = await SodiumInit.init();
    Logger("CryptoUtil")
        .info("Sodium initialized: " + sodium.version.toString());
  }

  static Future<EncryptionResult> encrypt(
    Uint8List source,
    Uint8List key,
  ) async {
    final nonce = sodium.randombytes.buf(sodium.crypto.secretBox.nonceBytes);

    final args = <String, dynamic>{};
    args["source"] = source;
    args["nonce"] = nonce;
    args["key"] = key;
    final encryptedData = await cryptoSecretboxEasy(args);

    return EncryptionResult(
      key: key,
      nonce: nonce,
      encryptedData: encryptedData,
    );
  }

  static Future<Uint8List> decrypt(
    Uint8List cipher,
    Uint8List key,
    Uint8List nonce,
  ) async {
    final sodium = await SodiumInit.init();
    return sodium.crypto.secretBox.openEasy(
      cipherText: cipher,
      nonce: nonce,
      key: SecureKey.fromList(sodium, key),
    );
  }

  static Future<EncryptionResult> encryptChaCha(
    Uint8List source,
    Uint8List key,
  ) async {
    final args = <String, dynamic>{};
    args["source"] = source;
    args["key"] = key;
    return _computer.compute(chachaEncryptData, param: args);
  }

  static Future<Uint8List> decryptChaCha(
    Uint8List source,
    Uint8List key,
    Uint8List header,
  ) async {
    final args = <String, dynamic>{};
    args["source"] = source;
    args["key"] = key;
    args["header"] = header;
    return chachaDecryptData(args);
  }

  static Uint8List generateKey() {
    return sodium.crypto.secretBox.keygen().extractBytes();
  }

  static Uint8List getSaltToDeriveKey() {
    return sodium.randombytes.buf(sodium.crypto.pwhash.saltBytes);
  }

  static Future<KeyPair> generateKeyPair() async {
    return sodium.crypto.box.keyPair();
  }

  static Uint8List openSealSync(
    Uint8List input,
    Uint8List publicKey,
    Uint8List secretKey,
  ) {
    return sodium.crypto.box.sealOpen(
      cipherText: input,
      publicKey: publicKey,
      secretKey: SecureKey.fromList(sodium, secretKey),
    );
  }

  static Uint8List sealSync(Uint8List input, Uint8List publicKey) {
    return sodium.crypto.box.seal(message: input, publicKey: publicKey);
  }

  static Future<DerivedKeyResult> deriveSensitiveKey(
    Uint8List password,
    Uint8List salt,
  ) async {
    final logger = Logger("pwhash");
    int memLimit = sodium.crypto.pwhash.memLimitSensitive;
    int opsLimit = sodium.crypto.pwhash.opsLimitSensitive;
    Uint8List key;
    while (memLimit > sodium.crypto.pwhash.memLimitMin &&
        opsLimit < sodium.crypto.pwhash.opsLimitMax) {
      try {
        key = await deriveKey(password, salt, memLimit, opsLimit);
        return DerivedKeyResult(key, memLimit, opsLimit);
      } catch (e, s) {
        logger.severe(e, s);
      }
      memLimit = (memLimit / 2).round();
      opsLimit = opsLimit * 2;
    }
    throw UnsupportedError("Cannot perform this operation on this device");
  }

  static Future<Uint8List> deriveKey(
    Uint8List password,
    Uint8List salt,
    int memLimit,
    int opsLimit,
  ) async {
    final sodium = await SodiumInit.init();
    Logger("CryptoUtil")
        .info("Sodium initialized: " + sodium.version.toString());
    return sodium.crypto.pwhash
        .call(
          outLen: CryptoUtil.sodium.crypto.secretBox.keyBytes,
          password: Int8List.fromList(password),
          salt: salt,
          opsLimit: opsLimit,
          memLimit: memLimit,
        )
        .extractBytes();
    // return _computer.compute(
    //   cryptoPwHash,
    //   param: {
    //     "password": password,
    //     "salt": salt,
    //     "memLimit": memLimit,
    //     "opsLimit": opsLimit,
    //   },
    // );
  }
}
