import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'libsodium.dart';

// ignore_for_file: non_constant_identifier_names

class CryptoSignBindings {
  final int Function() crypto_sign_statebytes =
      libsodium.lookupSizet('crypto_sign_statebytes');

  final int Function() crypto_sign_bytes =
      libsodium.lookupSizet('crypto_sign_bytes');

  final int Function() crypto_sign_seedbytes =
      libsodium.lookupSizet('crypto_sign_seedbytes');

  final int Function() crypto_sign_publickeybytes =
      libsodium.lookupSizet('crypto_sign_publickeybytes');

  final int Function() crypto_sign_secretkeybytes =
      libsodium.lookupSizet('crypto_sign_secretkeybytes');

  final int Function() crypto_sign_messagebytes_max =
      libsodium.lookupSizet('crypto_sign_messagebytes_max');

  final int Function() crypto_sign_ed25519_publickeybytes =
      libsodium.lookupSizet('crypto_sign_ed25519_publickeybytes');

  final int Function() crypto_sign_ed25519_secretkeybytes =
      libsodium.lookupSizet('crypto_sign_ed25519_secretkeybytes');

  final Pointer<Utf8> Function() crypto_sign_primitive = libsodium
      .lookup<NativeFunction<Pointer<Utf8> Function()>>('crypto_sign_primitive')
      .asFunction();

  final int Function(Pointer<Uint8> pk, Pointer<Uint8> sk, Pointer<Uint8> seed)
      crypto_sign_seed_keypair = libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Uint8>, Pointer<Uint8>,
                      Pointer<Uint8>)>>('crypto_sign_seed_keypair')
          .asFunction();

  final int Function(
      Pointer<Uint8> pk,
      Pointer<Uint8>
          sk) crypto_sign_keypair = libsodium
      .lookup<NativeFunction<Int32 Function(Pointer<Uint8>, Pointer<Uint8>)>>(
          'crypto_sign_keypair')
      .asFunction();

  final int Function(Pointer<Uint8> sm, Pointer<Uint64> smlen_p,
          Pointer<Uint8> m, int mlen, Pointer<Uint8> sk) crypto_sign =
      libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Uint8>, Pointer<Uint64>,
                      Pointer<Uint8>, Uint64, Pointer<Uint8>)>>('crypto_sign')
          .asFunction();

  final int Function(Pointer<Uint8> m, Pointer<Uint64> mlen_p,
          Pointer<Uint8> sm, int smlen, Pointer<Uint8> pk) crypto_sign_open =
      libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Uint8>,
                      Pointer<Uint64>,
                      Pointer<Uint8>,
                      Uint64,
                      Pointer<Uint8>)>>('crypto_sign_open')
          .asFunction();

  final int Function(Pointer<Uint8> sig, Pointer<Uint64> siglen_p,
          Pointer<Uint8> m, int mlen, Pointer<Uint8> sk) crypto_sign_detached =
      libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Uint8>,
                      Pointer<Uint64>,
                      Pointer<Uint8>,
                      Uint64,
                      Pointer<Uint8>)>>('crypto_sign_detached')
          .asFunction();

  final int Function(
          Pointer<Uint8> sig, Pointer<Uint8> m, int mlen, Pointer<Uint8> pk)
      crypto_sign_verify_detached = libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Uint8>, Pointer<Uint8>, Uint64,
                      Pointer<Uint8>)>>('crypto_sign_verify_detached')
          .asFunction();

  final int Function(Pointer<Uint8> state) crypto_sign_init = libsodium
      .lookup<NativeFunction<Int32 Function(Pointer<Uint8>)>>(
          'crypto_sign_init')
      .asFunction();

  final int Function(Pointer<Uint8> state, Pointer<Uint8> m, int mlen)
      crypto_sign_update = libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Uint8>, Pointer<Uint8>,
                      Uint64)>>('crypto_sign_update')
          .asFunction();

  final int Function(Pointer<Uint8> state, Pointer<Uint8> sig,
          Pointer<Uint64> siglen_p, Pointer<Uint8> sk)
      crypto_sign_final_create = libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Uint8>,
                      Pointer<Uint8>,
                      Pointer<Uint64>,
                      Pointer<Uint8>)>>('crypto_sign_final_create')
          .asFunction();

  final int Function(
          Pointer<Uint8> state, Pointer<Uint8> sig, Pointer<Uint8> pk)
      crypto_sign_final_verify = libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Uint8>, Pointer<Uint8>,
                      Pointer<Uint8>)>>('crypto_sign_final_verify')
          .asFunction();

  final int Function(
      Pointer<Uint8> seed,
      Pointer<Uint8>
          sk) crypto_sign_ed25519_sk_to_seed = libsodium
      .lookup<NativeFunction<Int32 Function(Pointer<Uint8>, Pointer<Uint8>)>>(
          'crypto_sign_ed25519_sk_to_seed')
      .asFunction();

  final int Function(
      Pointer<Uint8> pk,
      Pointer<Uint8>
          sk) crypto_sign_ed25519_sk_to_pk = libsodium
      .lookup<NativeFunction<Int32 Function(Pointer<Uint8>, Pointer<Uint8>)>>(
          'crypto_sign_ed25519_sk_to_pk')
      .asFunction();

  final int Function(
      Pointer<Uint8> curve25519_pk,
      Pointer<Uint8>
          ed25519_pk) crypto_sign_ed25519_pk_to_curve25519 = libsodium
      .lookup<NativeFunction<Int32 Function(Pointer<Uint8>, Pointer<Uint8>)>>(
          'crypto_sign_ed25519_pk_to_curve25519')
      .asFunction();

  final int Function(
      Pointer<Uint8> curve25519_sk,
      Pointer<Uint8>
          ed25519_sk) crypto_sign_ed25519_sk_to_curve25519 = libsodium
      .lookup<NativeFunction<Int32 Function(Pointer<Uint8>, Pointer<Uint8>)>>(
          'crypto_sign_ed25519_sk_to_curve25519')
      .asFunction();
}
