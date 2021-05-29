import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'libsodium.dart';

// ignore_for_file: non_constant_identifier_names

class CryptoGenerichashBindings {
  final int Function() crypto_generichash_bytes_min =
      libsodium.lookupSizet('crypto_generichash_bytes_min');

  final int Function() crypto_generichash_bytes_max =
      libsodium.lookupSizet('crypto_generichash_bytes_max');

  final int Function() crypto_generichash_bytes =
      libsodium.lookupSizet('crypto_generichash_bytes');

  final int Function() crypto_generichash_keybytes_min =
      libsodium.lookupSizet('crypto_generichash_keybytes_min');

  final int Function() crypto_generichash_keybytes_max =
      libsodium.lookupSizet('crypto_generichash_keybytes_max');

  final int Function() crypto_generichash_keybytes =
      libsodium.lookupSizet('crypto_generichash_keybytes');

  final Pointer<Utf8> Function() crypto_generichash_primitive = libsodium
      .lookup<NativeFunction<Pointer<Utf8> Function()>>(
          'crypto_generichash_primitive')
      .asFunction();

  final int Function() crypto_generichash_statebytes =
      libsodium.lookupSizet('crypto_generichash_statebytes');

  final int Function(Pointer<Uint8> out, int outlen, Pointer<Uint8> i,
          int inlen, Pointer<Uint8> key, int keylen) crypto_generichash =
      libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Uint8>, IntPtr, Pointer<Uint8>, Uint64,
                      Pointer<Uint8>, IntPtr)>>('crypto_generichash')
          .asFunction();

  final int Function(
          Pointer<Uint8> state, Pointer<Uint8> key, int keylen, int outlen)
      crypto_generichash_init = libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Uint8>, Pointer<Uint8>, IntPtr,
                      IntPtr)>>('crypto_generichash_init')
          .asFunction();

  final int Function(Pointer<Uint8> state, Pointer<Uint8> i, int inlen)
      crypto_generichash_update = libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(
            Pointer<Uint8>,
            Pointer<Uint8>,
            Uint64,
          )>>('crypto_generichash_update')
          .asFunction();

  final int Function(Pointer<Uint8> state, Pointer<Uint8> out, int outlen)
      crypto_generichash_final = libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(
            Pointer<Uint8>,
            Pointer<Uint8>,
            IntPtr,
          )>>('crypto_generichash_final')
          .asFunction();

  final void Function(Pointer<Uint8> k) crypto_generichash_keygen = libsodium
      .lookup<NativeFunction<Void Function(Pointer<Uint8>)>>(
          'crypto_generichash_keygen')
      .asFunction();
}
