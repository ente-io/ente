import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'libsodium.dart';

// ignore_for_file: non_constant_identifier_names

class CryptoPwhashBindings {
  final int Function() crypto_pwhash_alg_argon2i13 = libsodium
      .lookup<NativeFunction<Int32 Function()>>('crypto_pwhash_alg_argon2i13')
      .asFunction();

  final int Function() crypto_pwhash_alg_argon2id13 = libsodium
      .lookup<NativeFunction<Int32 Function()>>('crypto_pwhash_alg_argon2id13')
      .asFunction();

  final int Function() crypto_pwhash_alg_default = libsodium
      .lookup<NativeFunction<Int32 Function()>>('crypto_pwhash_alg_default')
      .asFunction();

  final int Function() crypto_pwhash_bytes_min =
      libsodium.lookupSizet('crypto_pwhash_bytes_min');

  final int Function() crypto_pwhash_bytes_max =
      libsodium.lookupSizet('crypto_pwhash_bytes_max');

  final int Function() crypto_pwhash_passwd_min =
      libsodium.lookupSizet('crypto_pwhash_passwd_min');

  final int Function() crypto_pwhash_passwd_max =
      libsodium.lookupSizet('crypto_pwhash_passwd_max');

  final int Function() crypto_pwhash_saltbytes =
      libsodium.lookupSizet('crypto_pwhash_saltbytes');

  final int Function() crypto_pwhash_strbytes =
      libsodium.lookupSizet('crypto_pwhash_strbytes');

  final Pointer<Utf8> Function() crypto_pwhash_strprefix = libsodium
      .lookup<NativeFunction<Pointer<Utf8> Function()>>(
          'crypto_pwhash_strprefix')
      .asFunction();

  final int Function() crypto_pwhash_opslimit_min =
      libsodium.lookupSizet('crypto_pwhash_opslimit_min');

  final int Function() crypto_pwhash_opslimit_max =
      libsodium.lookupSizet('crypto_pwhash_opslimit_max');

  final int Function() crypto_pwhash_memlimit_min =
      libsodium.lookupSizet('crypto_pwhash_memlimit_min');

  final int Function() crypto_pwhash_memlimit_max =
      libsodium.lookupSizet('crypto_pwhash_memlimit_max');

  final int Function() crypto_pwhash_argon2i_opslimit_min =
      libsodium.lookupSizet('crypto_pwhash_argon2i_opslimit_min');

  final int Function() crypto_pwhash_argon2i_opslimit_max =
      libsodium.lookupSizet('crypto_pwhash_argon2i_opslimit_max');

  final int Function() crypto_pwhash_argon2i_memlimit_min =
      libsodium.lookupSizet('crypto_pwhash_argon2i_memlimit_min');

  final int Function() crypto_pwhash_argon2i_memlimit_max =
      libsodium.lookupSizet('crypto_pwhash_argon2i_memlimit_max');

  final int Function() crypto_pwhash_opslimit_interactive =
      libsodium.lookupSizet('crypto_pwhash_opslimit_interactive');

  final int Function() crypto_pwhash_memlimit_interactive =
      libsodium.lookupSizet('crypto_pwhash_memlimit_interactive');

  final int Function() crypto_pwhash_opslimit_moderate =
      libsodium.lookupSizet('crypto_pwhash_opslimit_moderate');

  final int Function() crypto_pwhash_memlimit_moderate =
      libsodium.lookupSizet('crypto_pwhash_memlimit_moderate');

  final int Function() crypto_pwhash_opslimit_sensitive =
      libsodium.lookupSizet('crypto_pwhash_opslimit_sensitive');

  final int Function() crypto_pwhash_memlimit_sensitive =
      libsodium.lookupSizet('crypto_pwhash_memlimit_sensitive');

  final Pointer<Utf8> Function() crypto_pwhash_primitive = libsodium
      .lookup<NativeFunction<Pointer<Utf8> Function()>>(
          'crypto_pwhash_primitive')
      .asFunction();

  final int Function(
          Pointer<Uint8> out,
          int,
          Pointer<Uint8> passwd,
          int passwdlen,
          Pointer<Uint8> salt,
          int opslimit,
          int memlimit,
          int alg) crypto_pwhash =
      libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Uint8>, Uint64, Pointer<Uint8>, Uint64,
                      Pointer<Uint8>, Uint64, IntPtr, Int32)>>('crypto_pwhash')
          .asFunction();

  final int Function(Pointer<Uint8> out, Pointer<Uint8> passwd, int passwdlen,
          int opslimit, int memlimit) crypto_pwhash_str =
      libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Uint8>, Pointer<Uint8>, Uint64, Uint64,
                      IntPtr)>>('crypto_pwhash_str')
          .asFunction();

  final int Function(Pointer<Uint8> out, Pointer<Uint8> passwd, int passwdlen,
          int opslimit, int memlimit, int alg) crypto_pwhash_str_alg =
      libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Uint8>, Pointer<Uint8>, Uint64, Uint64,
                      IntPtr, Int32)>>('crypto_pwhash_str_alg')
          .asFunction();

  final int Function(Pointer<Uint8> str, Pointer<Uint8> passwd, int passwdlen)
      crypto_pwhash_str_verify = libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Uint8>, Pointer<Uint8>,
                      Uint64)>>('crypto_pwhash_str_verify')
          .asFunction();

  final int Function(
      Pointer<Uint8> str,
      int opslimit,
      int
          memlimit) crypto_pwhash_str_needs_rehash = libsodium
      .lookup<NativeFunction<Int32 Function(Pointer<Uint8>, Uint64, IntPtr)>>(
          'crypto_pwhash_str_needs_rehash')
      .asFunction();
}
