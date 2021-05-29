import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'libsodium.dart';

// ignore_for_file: non_constant_identifier_names

class CryptoSecretboxBindings {
  final int Function() crypto_secretbox_keybytes =
      libsodium.lookupSizet('crypto_secretbox_keybytes');

  final int Function() crypto_secretbox_noncebytes =
      libsodium.lookupSizet('crypto_secretbox_noncebytes');

  final int Function() crypto_secretbox_macbytes =
      libsodium.lookupSizet('crypto_secretbox_macbytes');

  final int Function() crypto_secretbox_messagebytes_max =
      libsodium.lookupSizet('crypto_secretbox_messagebytes_max');

  final Pointer<Utf8> Function() crypto_secretbox_primitive = libsodium
      .lookup<NativeFunction<Pointer<Utf8> Function()>>(
          'crypto_secretbox_primitive')
      .asFunction();

  final int Function(Pointer<Uint8> c, Pointer<Uint8> m, int mlen,
          Pointer<Uint8> n, Pointer<Uint8> k) crypto_secretbox_easy =
      libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Uint8>, Pointer<Uint8>, Uint64,
                      Pointer<Uint8>, Pointer<Uint8>)>>('crypto_secretbox_easy')
          .asFunction();

  final int Function(Pointer<Uint8> m, Pointer<Uint8> c, int clen,
          Pointer<Uint8> n, Pointer<Uint8> k) crypto_secretbox_open_easy =
      libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Uint8>,
                      Pointer<Uint8>,
                      Uint64,
                      Pointer<Uint8>,
                      Pointer<Uint8>)>>('crypto_secretbox_open_easy')
          .asFunction();

  final int Function(Pointer<Uint8> c, Pointer<Uint8> mac, Pointer<Uint8> m,
          int mlen, Pointer<Uint8> n, Pointer<Uint8> k)
      crypto_secretbox_detached = libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Uint8>,
                      Pointer<Uint8>,
                      Pointer<Uint8>,
                      Uint64,
                      Pointer<Uint8>,
                      Pointer<Uint8>)>>('crypto_secretbox_detached')
          .asFunction();

  final int Function(Pointer<Uint8> m, Pointer<Uint8> c, Pointer<Uint8> mac,
          int clen, Pointer<Uint8> n, Pointer<Uint8> k)
      crypto_secretbox_open_detached = libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Uint8>,
                      Pointer<Uint8>,
                      Pointer<Uint8>,
                      Uint64,
                      Pointer<Uint8>,
                      Pointer<Uint8>)>>('crypto_secretbox_open_detached')
          .asFunction();

  final void Function(Pointer<Uint8> k) crypto_secretbox_keygen = libsodium
      .lookup<NativeFunction<Void Function(Pointer<Uint8>)>>(
          'crypto_secretbox_keygen')
      .asFunction();
}
