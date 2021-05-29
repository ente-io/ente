import 'dart:ffi';
import 'libsodium.dart';

// ignore_for_file: non_constant_identifier_names

class CryptoAeadBindings {
  final String name;
  final int Function() keybytes;
  final int Function() nsecbytes;
  final int Function() npubbytes;
  final int Function() abytes;
  final int Function() messagebytes_max;

  final int Function(
      Pointer<Uint8> c,
      Pointer<Uint64> clen_p,
      Pointer<Uint8> m,
      int mlen,
      Pointer<Uint8> ad,
      int adlen,
      Pointer<Uint8> nsec,
      Pointer<Uint8> npub,
      Pointer<Uint8> k) encrypt;

  final int Function(
      Pointer<Uint8> m,
      Pointer<Uint64> mlen_p,
      Pointer<Uint8> nsec,
      Pointer<Uint8> c,
      int clen,
      Pointer<Uint8> ad,
      int adlen,
      Pointer<Uint8> npub,
      Pointer<Uint8> k) decrypt;

  final int Function(
      Pointer<Uint8> c,
      Pointer<Uint8> mac,
      Pointer<Uint64> maclen_p,
      Pointer<Uint8> m,
      int mlen,
      Pointer<Uint8> ad,
      int adlen,
      Pointer<Uint8> nsec,
      Pointer<Uint8> npub,
      Pointer<Uint8> k) encrypt_detached;

  final int Function(
      Pointer<Uint8> m,
      Pointer<Uint8> nsec,
      Pointer<Uint8> c,
      int clen,
      Pointer<Uint8> mac,
      Pointer<Uint8> ad,
      int adlen,
      Pointer<Uint8> npub,
      Pointer<Uint8> k) decrypt_detached;

  final void Function(Pointer<Uint8> k) keygen;

  CryptoAeadBindings(this.name)
      : keybytes = libsodium.lookupSizet('${name}_keybytes'),
        nsecbytes = libsodium.lookupSizet('${name}_nsecbytes'),
        npubbytes = libsodium.lookupSizet('${name}_npubbytes'),
        abytes = libsodium.lookupSizet('${name}_abytes'),
        messagebytes_max = libsodium.lookupSizet('${name}_messagebytes_max'),
        encrypt = libsodium
            .lookup<
                NativeFunction<
                    Int32 Function(
                        Pointer<Uint8>,
                        Pointer<Uint64>,
                        Pointer<Uint8>,
                        Uint64,
                        Pointer<Uint8>,
                        Uint64,
                        Pointer<Uint8>,
                        Pointer<Uint8>,
                        Pointer<Uint8>)>>('${name}_encrypt')
            .asFunction(),
        decrypt = libsodium
            .lookup<
                NativeFunction<
                    Int32 Function(
                        Pointer<Uint8>,
                        Pointer<Uint64>,
                        Pointer<Uint8>,
                        Pointer<Uint8>,
                        Uint64,
                        Pointer<Uint8>,
                        Uint64,
                        Pointer<Uint8>,
                        Pointer<Uint8>)>>('${name}_decrypt')
            .asFunction(),
        encrypt_detached = libsodium
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
                        Pointer<Uint8>,
                        Pointer<Uint8>,
                        Pointer<Uint8>)>>('${name}_encrypt_detached')
            .asFunction(),
        decrypt_detached = libsodium
            .lookup<
                NativeFunction<
                    Int32 Function(
                        Pointer<Uint8>,
                        Pointer<Uint8>,
                        Pointer<Uint8>,
                        Uint64,
                        Pointer<Uint8>,
                        Pointer<Uint8>,
                        Uint64,
                        Pointer<Uint8>,
                        Pointer<Uint8>)>>('${name}_decrypt_detached')
            .asFunction(),
        keygen = libsodium
            .lookup<NativeFunction<Void Function(Pointer<Uint8>)>>(
                '${name}_keygen')
            .asFunction();
}
