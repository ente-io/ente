import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'libsodium.dart';

// ignore_for_file: non_constant_identifier_names

class CryptoShorthashBindings {
  final int Function() crypto_shorthash_bytes =
      libsodium.lookupSizet('crypto_shorthash_bytes');

  final int Function() crypto_shorthash_keybytes =
      libsodium.lookupSizet('crypto_shorthash_keybytes');

  final Pointer<Utf8> Function() crypto_shorthash_primitive = libsodium
      .lookup<NativeFunction<Pointer<Utf8> Function()>>(
          'crypto_shorthash_primitive')
      .asFunction();

  final int Function(
          Pointer<Uint8> out, Pointer<Uint8> i, int inlen, Pointer<Uint8> k)
      crypto_shorthash = libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Uint8>, Pointer<Uint8>, Uint64,
                      Pointer<Uint8>)>>('crypto_shorthash')
          .asFunction();

  final void Function(Pointer<Uint8> k) crypto_shorthash_keygen = libsodium
      .lookup<NativeFunction<Void Function(Pointer<Uint8>)>>(
          'crypto_shorthash_keygen')
      .asFunction();
}
