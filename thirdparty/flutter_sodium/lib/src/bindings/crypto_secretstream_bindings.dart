import 'dart:ffi';
import 'libsodium.dart';

// ignore_for_file: non_constant_identifier_names

class CryptoSecretstreamBindings {
  final int Function() crypto_secretstream_xchacha20poly1305_abytes =
      libsodium.lookupSizet('crypto_secretstream_xchacha20poly1305_abytes');

  final int Function() crypto_secretstream_xchacha20poly1305_headerbytes =
      libsodium
          .lookupSizet('crypto_secretstream_xchacha20poly1305_headerbytes');

  final int Function() crypto_secretstream_xchacha20poly1305_keybytes =
      libsodium.lookupSizet('crypto_secretstream_xchacha20poly1305_keybytes');

  final int Function() crypto_secretstream_xchacha20poly1305_messagebytes_max =
      libsodium.lookupSizet(
          'crypto_secretstream_xchacha20poly1305_messagebytes_max');

  final int Function() crypto_secretstream_xchacha20poly1305_tag_message =
      libsodium
          .lookup<NativeFunction<Uint8 Function()>>(
              'crypto_secretstream_xchacha20poly1305_tag_message')
          .asFunction();

  final int Function() crypto_secretstream_xchacha20poly1305_tag_push =
      libsodium
          .lookup<NativeFunction<Uint8 Function()>>(
              'crypto_secretstream_xchacha20poly1305_tag_push')
          .asFunction();

  final int Function() crypto_secretstream_xchacha20poly1305_tag_rekey =
      libsodium
          .lookup<NativeFunction<Uint8 Function()>>(
              'crypto_secretstream_xchacha20poly1305_tag_rekey')
          .asFunction();

  final int Function() crypto_secretstream_xchacha20poly1305_tag_final =
      libsodium
          .lookup<NativeFunction<Uint8 Function()>>(
              'crypto_secretstream_xchacha20poly1305_tag_final')
          .asFunction();

  final int Function() crypto_secretstream_xchacha20poly1305_statebytes =
      libsodium.lookupSizet('crypto_secretstream_xchacha20poly1305_statebytes');

  final void Function(Pointer<Uint8> k)
      crypto_secretstream_xchacha20poly1305_keygen = libsodium
          .lookup<NativeFunction<Void Function(Pointer<Uint8>)>>(
              'crypto_secretstream_xchacha20poly1305_keygen')
          .asFunction();

  final int Function(
          Pointer<Uint8> state, Pointer<Uint8> header, Pointer<Uint8> k)
      crypto_secretstream_xchacha20poly1305_init_push = libsodium
          .lookup<
                  NativeFunction<
                      Int32 Function(
                          Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>)>>(
              'crypto_secretstream_xchacha20poly1305_init_push')
          .asFunction();

  final int Function(
          Pointer<Uint8> state,
          Pointer<Uint8> c,
          Pointer<Uint64> clen_p,
          Pointer<Uint8> m,
          int mlen,
          Pointer<Uint8> ad,
          int adlen,
          int tag) crypto_secretstream_xchacha20poly1305_push =
      libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Uint8>,
                      Pointer<Uint8>,
                      Pointer<Uint64>,
                      Pointer<Uint8>,
                      Uint64,
                      Pointer<Uint8>,
                      Uint64,
                      Uint8)>>('crypto_secretstream_xchacha20poly1305_push')
          .asFunction();

  final int Function(
          Pointer<Uint8> state, Pointer<Uint8> header, Pointer<Uint8> k)
      crypto_secretstream_xchacha20poly1305_init_pull = libsodium
          .lookup<
                  NativeFunction<
                      Int32 Function(
                          Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>)>>(
              'crypto_secretstream_xchacha20poly1305_init_pull')
          .asFunction();

  final int Function(
          Pointer<Uint8> state,
          Pointer<Uint8> m,
          Pointer<Uint64> mlen_p,
          Pointer<Uint8> tag_p,
          Pointer<Uint8> c,
          int clen,
          Pointer<Uint8> ad,
          int adlen) crypto_secretstream_xchacha20poly1305_pull =
      libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Uint8>,
                      Pointer<Uint8>,
                      Pointer<Uint64>,
                      Pointer<Uint8>,
                      Pointer<Uint8>,
                      Uint64,
                      Pointer<Uint8>,
                      Uint64)>>('crypto_secretstream_xchacha20poly1305_pull')
          .asFunction();

  final void Function(Pointer<Uint8> state)
      crypto_secretstream_xchacha20poly1305_rekey = libsodium
          .lookup<NativeFunction<Void Function(Pointer<Uint8>)>>(
              'crypto_secretstream_xchacha20poly1305_rekey')
          .asFunction();
}
