import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'libsodium.dart';

// ignore_for_file: non_constant_identifier_names

class CryptoStreamBindings {
  final int Function() crypto_stream_keybytes =
      libsodium.lookupSizet('crypto_stream_keybytes');

  final int Function() crypto_stream_noncebytes =
      libsodium.lookupSizet('crypto_stream_noncebytes');

  final int Function() crypto_stream_messagebytes_max =
      libsodium.lookupSizet('crypto_stream_messagebytes_max');

  final Pointer<Utf8> Function() crypto_stream_primitive = libsodium
      .lookup<NativeFunction<Pointer<Utf8> Function()>>(
          'crypto_stream_primitive')
      .asFunction();

  final int Function(
          Pointer<Uint8> c, int clen, Pointer<Uint8> n, Pointer<Uint8> k)
      crypto_stream = libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Uint8>, Uint64, Pointer<Uint8>,
                      Pointer<Uint8>)>>('crypto_stream')
          .asFunction();

  final int Function(Pointer<Uint8> c, Pointer<Uint8> m, int mlen,
          Pointer<Uint8> n, Pointer<Uint8> k) crypto_stream_xor =
      libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Uint8>, Pointer<Uint8>, Uint64,
                      Pointer<Uint8>, Pointer<Uint8>)>>('crypto_stream_xor')
          .asFunction();

  final void Function(Pointer<Uint8> k) crypto_stream_keygen = libsodium
      .lookup<NativeFunction<Void Function(Pointer<Uint8>)>>(
          'crypto_stream_keygen')
      .asFunction();
}
