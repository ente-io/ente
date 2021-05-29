import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'libsodium.dart';

// ignore_for_file: non_constant_identifier_names

class RandombytesBindings {
  final int Function() randombytes_seedbytes = libsodium
      .lookup<NativeFunction<IntPtr Function()>>('randombytes_seedbytes')
      .asFunction();

  final void Function(Pointer<Uint8> buf, int size) randombytes_buf = libsodium
      .lookup<NativeFunction<Void Function(Pointer<Uint8>, IntPtr)>>(
          'randombytes_buf')
      .asFunction();

  final void Function(Pointer<Uint8> buf, int size, Pointer<Uint8> seed)
      randombytes_buf_deterministic = libsodium
          .lookup<
              NativeFunction<
                  Void Function(Pointer<Uint8>, IntPtr,
                      Pointer<Uint8>)>>('randombytes_buf_deterministic')
          .asFunction();

  final int Function() randombytes_random = libsodium
      .lookup<NativeFunction<Uint32 Function()>>('randombytes_random')
      .asFunction();

  final int Function(int upper_bound) randombytes_uniform = libsodium
      .lookup<NativeFunction<Uint32 Function(Uint32)>>('randombytes_uniform')
      .asFunction();

  final void Function() randombytes_stir = libsodium
      .lookup<NativeFunction<Void Function()>>('randombytes_stir')
      .asFunction();

  final void Function() randombytes_close = libsodium
      .lookup<NativeFunction<Void Function()>>('randombytes_close')
      .asFunction();

  final Pointer<Utf8> Function() randombytes_implementation_name = libsodium
      .lookup<NativeFunction<Pointer<Utf8> Function()>>(
          'randombytes_implementation_name')
      .asFunction();
}
