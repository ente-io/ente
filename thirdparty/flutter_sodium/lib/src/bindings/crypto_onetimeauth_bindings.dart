import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'libsodium.dart';

// ignore_for_file: non_constant_identifier_names

class CryptoOnetimeauthBindings {
  final int Function() crypto_onetimeauth_statebytes =
      libsodium.lookupSizet('crypto_onetimeauth_statebytes');

  final int Function() crypto_onetimeauth_bytes =
      libsodium.lookupSizet('crypto_onetimeauth_bytes');

  final int Function() crypto_onetimeauth_keybytes =
      libsodium.lookupSizet('crypto_onetimeauth_keybytes');

  final Pointer<Utf8> Function() crypto_onetimeauth_primitive = libsodium
      .lookup<NativeFunction<Pointer<Utf8> Function()>>(
          'crypto_onetimeauth_primitive')
      .asFunction();

  final int Function(
          Pointer<Uint8> out, Pointer<Uint8> i, int inlen, Pointer<Uint8> k)
      crypto_onetimeauth = libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Uint8>, Pointer<Uint8>, Uint64,
                      Pointer<Uint8>)>>('crypto_onetimeauth')
          .asFunction();

  final int Function(
          Pointer<Uint8> h, Pointer<Uint8> i, int inlen, Pointer<Uint8> k)
      crypto_onetimeauth_verify = libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Uint8>, Pointer<Uint8>, Uint64,
                      Pointer<Uint8>)>>('crypto_onetimeauth_verify')
          .asFunction();

  final int Function(
      Pointer<Uint8> state,
      Pointer<Uint8>
          key) crypto_onetimeauth_init = libsodium
      .lookup<NativeFunction<Int32 Function(Pointer<Uint8>, Pointer<Uint8>)>>(
          'crypto_onetimeauth_init')
      .asFunction();

  final int Function(Pointer<Uint8> state, Pointer<Uint8> i, int inlen)
      crypto_onetimeauth_update = libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Uint8>, Pointer<Uint8>,
                      Uint64)>>('crypto_onetimeauth_update')
          .asFunction();

  final int Function(
      Pointer<Uint8> state,
      Pointer<Uint8>
          out) crypto_onetimeauth_final = libsodium
      .lookup<NativeFunction<Int32 Function(Pointer<Uint8>, Pointer<Uint8>)>>(
          'crypto_onetimeauth_final')
      .asFunction();

  final void Function(Pointer<Uint8> k) crypto_onetimeauth_keygen = libsodium
      .lookup<NativeFunction<Void Function(Pointer<Uint8>)>>(
          'crypto_onetimeauth_keygen')
      .asFunction();
}
