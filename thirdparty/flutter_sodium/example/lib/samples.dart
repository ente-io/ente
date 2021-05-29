import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_sodium/flutter_sodium.dart';

class Samples {
  final salt = PasswordHash.randomSalt();

  void api1(Function(Object) print) {
    // BEGIN api1: Core API: Compute a password hash using the Core API with predefined salt.
    final p = utf8.encoder.convert('hello world');
    final h = Sodium.cryptoPwhash(
        Sodium.cryptoPwhashBytesMin,
        p,
        salt,
        Sodium.cryptoPwhashOpslimitInteractive,
        Sodium.cryptoPwhashMemlimitInteractive,
        Sodium.cryptoPwhashAlgDefault);

    print('salt: ${Sodium.bin2hex(salt)}');
    print('hash: ${Sodium.bin2hex(h)}');
    // END api1
  }

  void api2(Function(Object) print) {
    // BEGIN api2: High-level API: Compute a password hash using the high-level API with predefined salt.
    final p = 'hello world';
    final h = PasswordHash.hashString(p, salt);

    print('salt: ${Sodium.bin2hex(salt)}');
    print('hash: ${Sodium.bin2hex(h)}');
    // END api2
  }

  void random1(Function(Object) print) {
    // BEGIN random1: Random: Returns an unpredictable value between 0 and 0xffffffff (included).
    final r = RandomBytes.random();
    print(r.toRadixString(16));
    // END random1
  }

  void random2(Function(Object) print) {
    // BEGIN random2: Uniform: Generates an unpredictable value between 0 and upperBound (excluded)
    final r = RandomBytes.uniform(16);
    print(r);
    // END random2
  }

  void random3(Function(Object) print) {
    // BEGIN random3: Buffer: Generates an unpredictable sequence of bytes of specified size.
    final b = RandomBytes.buffer(16);
    print(Sodium.bin2hex(b));
    // END random3
  }

  void about1(Function(Object) print) {
    // BEGIN about1: Version: Retrieves the version details of the loaded libsodium library.
    final v = Sodium.versionString;
    final v1 = Sodium.libraryVersionMajor;
    final v2 = Sodium.libraryVersionMinor;
    final m = Sodium.libraryMinimal;

    print('$v ($v1.$v2), minimal: $m');
    // END about1
  }

  void about2(Function(Object) print) {
    // BEGIN about2: Primitives: Retrieves the names of the algorithms used in the various libsodium APIs.
    print('crypto_auth: ${Sodium.cryptoAuthPrimitive}');
    print('crypto_box: ${Sodium.cryptoBoxPrimitive}');
    print('crypto_generichash: ${Sodium.cryptoGenerichashPrimitive}');
    print('crypto_hash: ${Sodium.cryptoHashPrimitive}');
    print('crypto_kdf: ${Sodium.cryptoKdfPrimitive}');
    print('crypto_kx: ${Sodium.cryptoKxPrimitive}');
    print('crypto_onetimeauth: ${Sodium.cryptoOnetimeauthPrimitive}');
    print('crypto_pwhash: ${Sodium.cryptoPwhashPrimitive}');
    print('crypto_scalarmult: ${Sodium.cryptoScalarmultPrimitive}');
    print('crypto_secretbox: ${Sodium.cryptoSecretboxPrimitive}');
    print('crypto_shorthash: ${Sodium.cryptoShorthashPrimitive}');
    print('crypto_sign: ${Sodium.cryptoSignPrimitive}');
    print('crypto_stream: ${Sodium.cryptoStreamPrimitive}');
    print('randombytes: ${Sodium.randombytesImplementationName}');
    // END about2
  }

  void about3(Function(Object) print) {
    // BEGIN about3: Runtime: Retrieves CPU capabilities
    print('neon: ${Sodium.runtimeHasNeon}');
    //print('armcrypto: ${Sodium.runtimeHasArmcrypto}');
    print('sse2: ${Sodium.runtimeHasSse2}');
    print('sse3: ${Sodium.runtimeHasSse3}');
    print('ssse3: ${Sodium.runtimeHasSsse3}');
    print('sse41: ${Sodium.runtimeHasSse41}');
    print('avx: ${Sodium.runtimeHasAvx}');
    print('avx2: ${Sodium.runtimeHasAvx2}');
    print('avx512f: ${Sodium.runtimeHasAvx512f}');
    print('pclmul: ${Sodium.runtimeHasPclmul}');
    print('aesni: ${Sodium.runtimeHasAesni}');
    print('rdrand: ${Sodium.runtimeHasRdrand}');
    // END about3
  }

  void encoding1(Function(Object) print) {
    // BEGIN encoding1: Hexadecimal encoding: Converts byte sequence to hexadecimal string and vice versa.
    final r = Sodium.randombytesBuf(16);

    // to hex
    final h = Sodium.bin2hex(r);
    print(h);

    // and back to binary
    final b = Sodium.hex2bin(h);

    // assert equality
    assert(Sodium.memcmp(r, b));
    // END encoding1
  }

  void encoding2(Function(Object) print) {
    // BEGIN encoding2: Base64 encoding: Converts byte sequence to base64 string and vice versa. Support multiple base64 variants
    final r = Sodium.randombytesBuf(16);

    // to base64
    final h = Sodium.bin2base64(r);
    print(h);

    // and back to binary
    final b = Sodium.base642bin(h);

    // assert equality
    assert(Sodium.memcmp(r, b));
    // END encoding2
  }

  void padding1(Function(Object) print) {
    // BEGIN padding1: Usage: Appends padding data using the ISO/IEC 7816-4 padding algorithm.
    final b = Sodium.randombytesBuf(10);

    // add padding
    final p = Sodium.pad(b, 16);

    print(Sodium.bin2hex(b));
    print(Sodium.bin2hex(p));

    // remove padding
    final r = Sodium.unpad(p, 16);

    // b and r should be equal
    assert(Sodium.memcmp(b, r));
    // END padding1
  }

  void auth1(Function(Object) print) {
    // BEGIN auth1: Usage: Secret key authentication
    // generate secret
    final k = CryptoAuth.randomKey();

    // compute tag
    final m = 'hello world';
    final t = CryptoAuth.computeString(m, k);
    print(Sodium.bin2hex(t));

    // verify tag
    final v = CryptoAuth.verifyString(t, m, k);
    assert(v);
    // END auth1
  }

  void box1(Function(Object) print) {
    // BEGIN box1: Combined mode: The authentication tag and the encrypted message are stored together.
    // Generate key pairs
    final a = CryptoBox.randomKeys();
    final b = CryptoBox.randomKeys();
    final n = CryptoBox.randomNonce();

    // Alice encrypts message for Bob
    final m = 'hello world';
    final e = CryptoBox.encryptString(m, n, b.pk, a.sk);

    print(Sodium.bin2hex(e));

    // Bob decrypts message from Alice
    final d = CryptoBox.decryptString(e, n, a.pk, b.sk);

    assert(m == d);
    print('decrypted: $d');
    // END box1
  }

  void box2(Function(Object) print) {
    // BEGIN box2: Detached mode: The authentication tag and the encrypted message are detached so they can be stored at different locations.
    // Generate key pairs
    final a = CryptoBox.randomKeys();
    final b = CryptoBox.randomKeys();
    final n = CryptoBox.randomNonce();

    // Alice encrypts message for Bob
    final m = 'hello world';
    final c = CryptoBox.encryptStringDetached(m, n, b.pk, a.sk);

    print('cipher: ${Sodium.bin2hex(c.c)}');
    print('mac: ${Sodium.bin2hex(c.mac)}');

    // Bob decrypts message from Alice
    final d = CryptoBox.decryptStringDetached(c.c, c.mac, n, a.pk, b.sk);

    assert(m == d);
    print('decrypted: $d');
    // END box2
  }

  void box3(Function(Object) print) {
    // BEGIN box3: Precalculated combined mode: The authentication tag and the encrypted message are stored together.
    // Generate key pairs
    final a = CryptoBox.randomKeys();
    final b = CryptoBox.randomKeys();
    final n = CryptoBox.randomNonce();

    // Alice encrypts message for Bob
    final m = 'hello world';
    final e = CryptoBox.encryptString(m, n, b.pk, a.sk);

    print(Sodium.bin2hex(e));

    // Bob decrypts message from Alice (precalculated)
    final k = CryptoBox.sharedSecret(a.pk, b.sk);
    final d = CryptoBox.decryptStringAfternm(e, n, k);

    assert(m == d);
    print('decrypted: $d');
    // END box3
  }

  void box4(Function(Object) print) {
    // BEGIN box4: Precalculated detached mode: The authentication tag and the encrypted message are detached so they can be stored at different locations.
    // Generate key pairs
    final a = CryptoBox.randomKeys();
    final b = CryptoBox.randomKeys();
    final n = CryptoBox.randomNonce();

    // Alice encrypts message for Bob (precalculated)
    final k = CryptoBox.sharedSecret(b.pk, a.sk);
    final m = 'hello world';
    final c = CryptoBox.encryptStringDetachedAfternm(m, n, k);

    print('cipher: ${Sodium.bin2hex(c.c)}');
    print('mac: ${Sodium.bin2hex(c.mac)}');

    // Bob decrypts message from Alice
    final d = CryptoBox.decryptStringDetached(c.c, c.mac, n, a.pk, b.sk);

    assert(m == d);
    print('decrypted: $d');
    // END box4
  }

  void box5(Function(Object) print) {
    // BEGIN box5: Usage: Anonymous sender encrypts a message intended for recipient only.
    // Recipient creates a long-term key pair
    final k = SealedBox.randomKeys();

    // Anonymous sender encrypts a message using an ephemeral key pair and the recipient's public key
    final m = 'hello world';
    final c = SealedBox.sealString(m, k.pk);

    print('cipher: ${Sodium.bin2hex(c)}');

    // Recipient decrypts the ciphertext
    final d = SealedBox.openString(c, k);

    assert(m == d);
    print('decrypted: $d');
    // END box5
  }

  void secret1(Function(Object) print) {
    // BEGIN secret1: Combined mode: The authentication tag and the encrypted message are stored together.
    // Generate random secret and nonce
    final k = SecretBox.randomKey();
    final n = SecretBox.randomNonce();

    // encrypt
    final m = 'hello world';
    final e = SecretBox.encryptString(m, n, k);
    print(Sodium.bin2hex(e));

    // decrypt
    final d = SecretBox.decryptString(e, n, k);
    assert(m == d);
    // END secret1
  }

  void secret2(Function(Object) print) {
    // BEGIN secret2: Detached mode: The authentication tag and the encrypted message are detached so they can be stored at different locations.
    // Generate random secret and nonce
    final k = SecretBox.randomKey();
    final n = SecretBox.randomNonce();

    // encrypt
    final m = 'hello world';
    final c = SecretBox.encryptStringDetached(m, n, k);
    print('cipher: ${Sodium.bin2hex(c.c)}');
    print('mac: ${Sodium.bin2hex(c.mac)}');

    // decrypt
    final d = SecretBox.decryptStringDetached(c.c, c.mac, n, k);

    assert(m == d);
    // END secret2
  }

  void sign1(Function(Object) print) {
    // BEGIN sign1: Combined mode: Compute a signed message
    final m = 'hello world';
    final k = CryptoSign.randomKeys();

    // sign with secret key
    final s = CryptoSign.signString(m, k.sk);
    print('signed: ${Sodium.bin2hex(s)}');

    // verify with public key
    final u = CryptoSign.openString(s, k.pk);
    print('unsigned: $u');

    assert(m == u);
    // END sign1
  }

  void sign2(Function(Object) print) {
    // BEGIN sign2: Detached mode: Compute a signature
    // Author generates keypair
    final k = CryptoSign.randomKeys();

    // Author computes signature using secret key
    final m = 'hello world';
    final s = CryptoSign.signStringDetached(m, k.sk);
    print(Sodium.bin2hex(s));

    // Recipient verifies message was issued by author using public key
    final v = CryptoSign.verifyString(s, m, k.pk);

    assert(v);
    // END sign2
  }

  Future sign3(Function(Object) print) async {
    // BEGIN sign3: Multi-part message: Compute a signature for multiple messages.
    // Author generates keypair
    final k = CryptoSign.randomKeys();

    // Author computes signature using secret key
    final p = ['Arbitrary data to hash', 'is longer than expected'];
    final s = await CryptoSign.signStrings(Stream.fromIterable(p), k.sk);
    print(Sodium.bin2hex(s));

    // Recipient verifies message was issued by author using public key
    final v = await CryptoSign.verifyStrings(s, Stream.fromIterable(p), k.pk);

    assert(v);
    // END sign3
  }

  void sign4(Function(Object) print) {
    // BEGIN sign4: Secret key extraction: Extracts seed and public key from a secret key.
    final s = CryptoSign.randomSeed();
    final k = CryptoSign.seedKeys(s);

    print('seed: ${Sodium.bin2hex(s)}');
    print('pk: ${Sodium.bin2hex(k.pk)}');
    print('sk: ${Sodium.bin2hex(k.sk)}');

    final s2 = CryptoSign.extractSeed(k.sk);
    final pk = CryptoSign.extractPublicKey(k.sk);

    // assert equality
    assert(Sodium.memcmp(s, s2));
    assert(Sodium.memcmp(pk, k.pk));
    // END sign4
  }

  void sign5(Function(Object) print) {
    // BEGIN sign5: Usage: Converts an Ed25519 key pair to a Curve25519 key pair.
    final k = CryptoSign.randomKeys();
    print('ed25519 pk: ${Sodium.bin2hex(k.pk)}');
    print('ed25519 sk: ${Sodium.bin2hex(k.sk)}');

    final pk = Sodium.cryptoSignEd25519PkToCurve25519(k.pk);
    final sk = Sodium.cryptoSignEd25519SkToCurve25519(k.sk);
    print('curve25519 pk: ${Sodium.bin2hex(pk)}');
    print('curve25519 sk: ${Sodium.bin2hex(sk)}');
    // END sign5
  }

  void generic1(Function(Object) print) {
    // BEGIN generic1: Single-part without a key:
    final v = 'Arbitrary data to hash';
    final h = GenericHash.hashString(v);

    print(Sodium.bin2hex(h));
    // END generic1
  }

  void generic2(Function(Object) print) {
    // BEGIN generic2: Single-part with a key:
    final v = 'Arbitrary data to hash';
    final k = GenericHash.randomKey();

    final h = GenericHash.hashString(v, key: k);

    print(Sodium.bin2hex(h));
    // END generic2
  }

  Future generic3(Function(Object) print) async {
    // BEGIN generic3: Multi-part without a key: Should result in a hash equal to the single-part without a key sample.
    final s = Stream.fromIterable(['Arbitrary data ', 'to hash']);

    final h = await GenericHash.hashStrings(s);

    print(Sodium.bin2hex(h));
    // END generic3
  }

  Future generic4(Function(Object) print) async {
    // BEGIN generic4: Multi-part with a key:
    final s = Stream.fromIterable(
        ['Arbitrary data to hash', 'is longer than expected']);
    final k = GenericHash.randomKey();

    final h = await GenericHash.hashStrings(s, key: k);

    print(Sodium.bin2hex(h));
    // END generic4
  }

  void pwhash1(Function(Object) print) {
    // BEGIN pwhash1: Hash: Derives a hash from given password and salt.
    final p = 'hello world';
    final s = PasswordHash.randomSalt();
    final h = PasswordHash.hashString(p, s);

    print(Sodium.bin2hex(h));
    // END pwhash1
  }

  void pwhash2(Function(Object) print) {
    // BEGIN pwhash2: Hash storage: Computes a password verification string for given password.
    final p = 'hello world';
    final s = PasswordHash.hashStringStorage(p);
    print(s);

    // verify storage string
    final v = PasswordHash.verifyStorage(s, p);
    print('Valid: $v');
    // END pwhash2
  }

  Future pwhash3(Function(Object) print) async {
    // BEGIN pwhash3: Hash storage async: Execute long running hash operation in background using Flutter's compute.
    // time operation
    final w = Stopwatch();
    w.start();

    // compute hash
    final p = 'hello world';
    final s = await compute(PasswordHash.hashStringStorageModerate, p);

    print(s);
    print('Compute took ${w.elapsedMilliseconds}ms');
    w.stop();
    // END pwhash3
  }

  void shorthash1(Function(Object) print) {
    // BEGIN shorthash1: Usage: Computes a fixed-size fingerprint for given string value and key.
    final m = 'hello world';
    final k = ShortHash.randomKey();
    final h = ShortHash.hashString(m, k);

    print(Sodium.bin2hex(h));
    // END shorthash1
  }

  void kdf1(Function(Object) print) {
    // BEGIN kdf1: Usage: Derive subkeys.
    // random master key
    final k = KeyDerivation.randomKey();

    // derives subkeys of various lengths
    final k1 = KeyDerivation.derive(k, 1, subKeyLength: 32);
    final k2 = KeyDerivation.derive(k, 2, subKeyLength: 32);
    final k3 = KeyDerivation.derive(k, 3, subKeyLength: 64);

    print('subkey1: ${Sodium.bin2hex(k1)}');
    print('subkey2: ${Sodium.bin2hex(k2)}');
    print('subkey3: ${Sodium.bin2hex(k3)}');
    // END kdf1
  }

  void kx1(Function(Object) print) {
    // BEGIN kx1: Usage: Compute a set of shared keys.
    // generate key pairs
    final c = KeyExchange.randomKeys();
    final s = KeyExchange.randomKeys();

    // compute session keys
    final ck = KeyExchange.computeClientSessionKeys(c, s.pk);
    final sk = KeyExchange.computeServerSessionKeys(s, c.pk);

    // assert keys do match
    assert(Sodium.memcmp(ck.rx, sk.tx));
    assert(Sodium.memcmp(ck.tx, sk.rx));

    print('client rx: ${Sodium.bin2hex(ck.rx)}');
    print('client tx: ${Sodium.bin2hex(ck.tx)}');
    // END kx1
  }

  Future scalarmult1(Function(Object) print) async {
    // BEGIN scalarmult1: Usage: Computes a shared secret.
    // client keys
    final csk = ScalarMult.randomSecretKey();
    final cpk = ScalarMult.computePublicKey(csk);

    // server keys
    final ssk = ScalarMult.randomSecretKey();
    final spk = ScalarMult.computePublicKey(ssk);

    // client derives shared key
    final cq = ScalarMult.computeSharedSecret(csk, spk);
    final cs =
        await GenericHash.hashStream(Stream.fromIterable([cq, cpk, spk]));

    // server derives shared key
    final sq = ScalarMult.computeSharedSecret(ssk, cpk);
    final ss =
        await GenericHash.hashStream(Stream.fromIterable([sq, cpk, spk]));

    // assert shared keys do match
    assert(Sodium.memcmp(cs, ss));

    print(Sodium.bin2hex(cs));
    // END scalarmult1
  }

  void chacha1(Function(Object) print) {
    // BEGIN chacha1: Combined mode: The authentication tag is directly appended to the encrypted message.
    // random nonce and key
    final n = ChaCha20Poly1305.randomNonce();
    final k = ChaCha20Poly1305.randomKey();
    print('nonce: ${Sodium.bin2hex(n)}');
    print('key: ${Sodium.bin2hex(k)}');

    // encrypt
    final m = 'hello world';
    final d = '123456';
    final c = ChaCha20Poly1305.encryptString(m, n, k, additionalData: d);

    print('cipher: ${Sodium.bin2hex(c)}');

    // decrypt
    final s = ChaCha20Poly1305.decryptString(c, n, k, additionalData: d);

    assert(m == s);
    // END chacha1
  }

  void chacha2(Function(Object) print) {
    // BEGIN chacha2: Detached mode: The authentication tag and the encrypted message are detached so they can be stored at different locations.
    // random nonce and key
    final n = ChaCha20Poly1305.randomNonce();
    final k = ChaCha20Poly1305.randomKey();
    print('nonce: ${Sodium.bin2hex(n)}');
    print('key: ${Sodium.bin2hex(k)}');

    // encrypt
    final m = 'hello world';
    final d = '123456';
    final c =
        ChaCha20Poly1305.encryptStringDetached(m, n, k, additionalData: d);

    print('cipher: ${Sodium.bin2hex(c.c)}');
    print('mac: ${Sodium.bin2hex(c.mac)}');

    // decrypt
    final s = ChaCha20Poly1305.decryptStringDetached(c.c, c.mac, n, k,
        additionalData: d);

    assert(m == s);
    // END chacha2
  }

  void chachaietf1(Function(Object) print) {
    // BEGIN chachaietf1: Combined mode: The authentication tag is directly appended to the encrypted message.
    // random nonce and key
    final n = ChaCha20Poly1305Ietf.randomNonce();
    final k = ChaCha20Poly1305Ietf.randomKey();
    print('nonce: ${Sodium.bin2hex(n)}');
    print('key: ${Sodium.bin2hex(k)}');

    // encrypt
    final m = 'hello world';
    final d = '123456';
    final c = ChaCha20Poly1305Ietf.encryptString(m, n, k, additionalData: d);

    print('cipher: ${Sodium.bin2hex(c)}');

    // decrypt
    final s = ChaCha20Poly1305Ietf.decryptString(c, n, k, additionalData: d);

    assert(m == s);
    // END chachaietf1
  }

  void chachaietf2(Function(Object) print) {
    // BEGIN chachaietf2: Detached mode: The authentication tag and the encrypted message are detached so they can be stored at different locations.
    // random nonce and key
    final n = ChaCha20Poly1305Ietf.randomNonce();
    final k = ChaCha20Poly1305Ietf.randomKey();
    print('nonce: ${Sodium.bin2hex(n)}');
    print('key: ${Sodium.bin2hex(k)}');

    // encrypt
    final m = 'hello world';
    final d = '123456';
    final c =
        ChaCha20Poly1305Ietf.encryptStringDetached(m, n, k, additionalData: d);

    print('cipher: ${Sodium.bin2hex(c.c)}');
    print('mac: ${Sodium.bin2hex(c.mac)}');

    // decrypt
    final s = ChaCha20Poly1305Ietf.decryptStringDetached(c.c, c.mac, n, k,
        additionalData: d);

    assert(m == s);
    // END chachaietf2
  }

  void xchachaietf1(Function(Object) print) {
    // BEGIN xchachaietf1: Combined mode: The authentication tag is directly appended to the encrypted message.
    // random nonce and key
    final n = XChaCha20Poly1305Ietf.randomNonce();
    final k = XChaCha20Poly1305Ietf.randomKey();
    print('nonce: ${Sodium.bin2hex(n)}');
    print('key: ${Sodium.bin2hex(k)}');

    // encrypt
    final m = 'hello world';
    final d = '123456';
    final c = XChaCha20Poly1305Ietf.encryptString(m, n, k, additionalData: d);

    print('cipher: ${Sodium.bin2hex(c)}');

    // decrypt
    final s = XChaCha20Poly1305Ietf.decryptString(c, n, k, additionalData: d);

    assert(m == s);
    // END xchachaietf1
  }

  void xchachaietf2(Function(Object) print) {
    // BEGIN xchachaietf2: Detached mode: The authentication tag and the encrypted message are detached so they can be stored at different locations.
    // random nonce and key
    final n = XChaCha20Poly1305Ietf.randomNonce();
    final k = XChaCha20Poly1305Ietf.randomKey();
    print('nonce: ${Sodium.bin2hex(n)}');
    print('key: ${Sodium.bin2hex(k)}');

    // encrypt
    final m = 'hello world';
    final d = '123456';
    final c =
        XChaCha20Poly1305Ietf.encryptStringDetached(m, n, k, additionalData: d);

    print('cipher: ${Sodium.bin2hex(c.c)}');
    print('mac: ${Sodium.bin2hex(c.mac)}');

    // decrypt
    final s = XChaCha20Poly1305Ietf.decryptStringDetached(c.c, c.mac, n, k,
        additionalData: d);

    assert(m == s);
    // END xchachaietf2
  }

  void onetime1(Function(Object) print) {
    // BEGIN onetime1: Single-part:
    final m = 'hello world';
    final k = OnetimeAuth.randomKey();
    final t = OnetimeAuth.computeString(m, k);
    print(Sodium.bin2hex(t));

    // verify tag
    final valid = OnetimeAuth.verifyString(t, m, k);
    assert(valid);
    // END onetime1
  }

  Future onetime2(Function(Object) print) async {
    // BEGIN onetime2: Multi-part:
    final i = Stream.fromIterable(['Muti-part', 'data']);
    final k = OnetimeAuth.randomKey();
    final t = await OnetimeAuth.computeStrings(i, k);
    print(Sodium.bin2hex(t));
    // END onetime2
  }

  void hash1(Function(Object) print) {
    // BEGIN hash1: Usage: SHA-512 hashing
    final m = 'hello world';
    final h = Hash.hashString(m);
    print(Sodium.bin2hex(h));
    // END hash1
  }

  void stream1(Function(Object) print) {
    // BEGIN stream1: Usage: Generate pseudo random bytes using a nonce and a secret key
    // random key and nonce
    final n = CryptoStream.randomNonce();
    final k = CryptoStream.randomKey();

    // generate 16 bytes
    var c = CryptoStream.stream(16, n, k);
    print(Sodium.bin2hex(c));

    // use same nonce and key yields same bytes
    var c2 = CryptoStream.stream(16, n, k);

    // assert equality
    assert(Sodium.memcmp(c, c2));
    // END stream1
  }
}
