import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'libsodium.dart';

// ignore_for_file: non_constant_identifier_names

class CryptoBoxBindings {
  final int Function() crypto_box_seedbytes =
      libsodium.lookupSizet('crypto_box_seedbytes');

  final int Function() crypto_box_publickeybytes =
      libsodium.lookupSizet('crypto_box_publickeybytes');

  final int Function() crypto_box_secretkeybytes =
      libsodium.lookupSizet('crypto_box_secretkeybytes');

  final int Function() crypto_box_noncebytes =
      libsodium.lookupSizet('crypto_box_noncebytes');

  final int Function() crypto_box_macbytes =
      libsodium.lookupSizet('crypto_box_macbytes');

  final int Function() crypto_box_messagebytes_max =
      libsodium.lookupSizet('crypto_box_messagebytes_max');

  final int Function() crypto_box_sealbytes =
      libsodium.lookupSizet('crypto_box_sealbytes');

  final int Function() crypto_box_beforenmbytes =
      libsodium.lookupSizet('crypto_box_beforenmbytes');

  final Pointer<Utf8> Function() crypto_box_primitive = libsodium
      .lookup<NativeFunction<Pointer<Utf8> Function()>>('crypto_box_primitive')
      .asFunction();

  final int Function(Pointer<Uint8> pk, Pointer<Uint8> sk, Pointer<Uint8> seed)
      crypto_box_seed_keypair = libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Uint8>, Pointer<Uint8>,
                      Pointer<Uint8>)>>('crypto_box_seed_keypair')
          .asFunction();

  final int Function(
      Pointer<Uint8> pk,
      Pointer<Uint8>
          sk) crypto_box_keypair = libsodium
      .lookup<NativeFunction<Int32 Function(Pointer<Uint8>, Pointer<Uint8>)>>(
          'crypto_box_keypair')
      .asFunction();

  final int Function(Pointer<Uint8> c, Pointer<Uint8> m, int mlen,
          Pointer<Uint8> n, Pointer<Uint8> pk, Pointer<Uint8> sk)
      crypto_box_easy = libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Uint8>,
                      Pointer<Uint8>,
                      Uint64,
                      Pointer<Uint8>,
                      Pointer<Uint8>,
                      Pointer<Uint8>)>>('crypto_box_easy')
          .asFunction();

  final int Function(Pointer<Uint8> m, Pointer<Uint8> c, int clen,
          Pointer<Uint8> n, Pointer<Uint8> pk, Pointer<Uint8> sk)
      crypto_box_open_easy = libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Uint8>,
                      Pointer<Uint8>,
                      Uint64,
                      Pointer<Uint8>,
                      Pointer<Uint8>,
                      Pointer<Uint8>)>>('crypto_box_open_easy')
          .asFunction();

  final int Function(Pointer<Uint8> c, Pointer<Uint8> mac, Pointer<Uint8> m,
          int mlen, Pointer<Uint8> n, Pointer<Uint8> pk, Pointer<Uint8> sk)
      crypto_box_detached = libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Uint8>,
                      Pointer<Uint8>,
                      Pointer<Uint8>,
                      Uint64,
                      Pointer<Uint8>,
                      Pointer<Uint8>,
                      Pointer<Uint8>)>>('crypto_box_detached')
          .asFunction();

  final int Function(Pointer<Uint8> m, Pointer<Uint8> c, Pointer<Uint8> mac,
          int clen, Pointer<Uint8> n, Pointer<Uint8> pk, Pointer<Uint8> sk)
      crypto_box_open_detached = libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Uint8>,
                      Pointer<Uint8>,
                      Pointer<Uint8>,
                      Uint64,
                      Pointer<Uint8>,
                      Pointer<Uint8>,
                      Pointer<Uint8>)>>('crypto_box_open_detached')
          .asFunction();

  final int Function(
          Pointer<Uint8> c, Pointer<Uint8> m, int mlen, Pointer<Uint8> pk)
      crypto_box_seal = libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Uint8>, Pointer<Uint8>, Uint64,
                      Pointer<Uint8>)>>('crypto_box_seal')
          .asFunction();

  final int Function(Pointer<Uint8> m, Pointer<Uint8> c, int clen,
          Pointer<Uint8> pk, Pointer<Uint8> sk) crypto_box_seal_open =
      libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Uint8>, Pointer<Uint8>, Uint64,
                      Pointer<Uint8>, Pointer<Uint8>)>>('crypto_box_seal_open')
          .asFunction();

  final int Function(Pointer<Uint8> k, Pointer<Uint8> pk, Pointer<Uint8> sk)
      crypto_box_beforenm = libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Uint8>, Pointer<Uint8>,
                      Pointer<Uint8>)>>('crypto_box_beforenm')
          .asFunction();

  final int Function(Pointer<Uint8> c, Pointer<Uint8> m, int mlen,
          Pointer<Uint8> n, Pointer<Uint8> k) crypto_box_easy_afternm =
      libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Uint8>,
                      Pointer<Uint8>,
                      Uint64,
                      Pointer<Uint8>,
                      Pointer<Uint8>)>>('crypto_box_easy_afternm')
          .asFunction();

  final int Function(Pointer<Uint8> m, Pointer<Uint8> c, int clen,
          Pointer<Uint8> n, Pointer<Uint8> k) crypto_box_open_easy_afternm =
      libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Uint8>,
                      Pointer<Uint8>,
                      Uint64,
                      Pointer<Uint8>,
                      Pointer<Uint8>)>>('crypto_box_open_easy_afternm')
          .asFunction();

  final int Function(Pointer<Uint8> c, Pointer<Uint8> mac, Pointer<Uint8> m,
          int mlen, Pointer<Uint8> n, Pointer<Uint8> k)
      crypto_box_detached_afternm = libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Uint8>,
                      Pointer<Uint8>,
                      Pointer<Uint8>,
                      Uint64,
                      Pointer<Uint8>,
                      Pointer<Uint8>)>>('crypto_box_detached_afternm')
          .asFunction();

  final int Function(Pointer<Uint8> m, Pointer<Uint8> c, Pointer<Uint8> mac,
          int clen, Pointer<Uint8> n, Pointer<Uint8> k)
      crypto_box_open_detached_afternm = libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Uint8>,
                      Pointer<Uint8>,
                      Pointer<Uint8>,
                      Uint64,
                      Pointer<Uint8>,
                      Pointer<Uint8>)>>('crypto_box_open_detached_afternm')
          .asFunction();
}
