import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'libsodium.dart';

// ignore_for_file: non_constant_identifier_names

class CryptoScalarmultBindings {
  final int Function() crypto_scalarmult_bytes =
      libsodium.lookupSizet('crypto_scalarmult_bytes');

  final int Function() crypto_scalarmult_scalarbytes =
      libsodium.lookupSizet('crypto_scalarmult_scalarbytes');

  final int Function() crypto_scalarmult_curve25519_bytes =
      libsodium.lookupSizet('crypto_scalarmult_curve25519_bytes');

  final Pointer<Utf8> Function() crypto_scalarmult_primitive = libsodium
      .lookup<NativeFunction<Pointer<Utf8> Function()>>(
          'crypto_scalarmult_primitive')
      .asFunction();

  final int Function(
      Pointer<Uint8> q,
      Pointer<Uint8>
          n) crypto_scalarmult_base = libsodium
      .lookup<NativeFunction<Int32 Function(Pointer<Uint8>, Pointer<Uint8>)>>(
          'crypto_scalarmult_base')
      .asFunction();

  final int Function(Pointer<Uint8> q, Pointer<Uint8> n, Pointer<Uint8> p)
      crypto_scalarmult = libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Uint8>, Pointer<Uint8>,
                      Pointer<Uint8>)>>('crypto_scalarmult')
          .asFunction();
}
