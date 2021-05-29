import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'libsodium.dart';

// ignore_for_file: non_constant_identifier_names

class CryptoHashBindings {
  final String name;
  final int Function() bytes;
  final Pointer<Utf8> Function() primitive;

  final int Function(Pointer<Uint8> out, Pointer<Uint8> i, int inlen) hash;

  CryptoHashBindings(this.name)
      : bytes = libsodium.lookupSizet('${name}_bytes'),
        primitive = libsodium
            .lookup<NativeFunction<Pointer<Utf8> Function()>>(
                '${name}_primitive')
            .asFunction(),
        hash = libsodium
            .lookup<
                NativeFunction<
                    Int32 Function(
                        Pointer<Uint8>, Pointer<Uint8>, Uint64)>>(name)
            .asFunction();
}
