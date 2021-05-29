import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'libsodium.dart';

// ignore_for_file: non_constant_identifier_names

class SodiumBindings {
  final int Function() sodium_init = libsodium
      .lookup<NativeFunction<Int32 Function()>>('sodium_init')
      .asFunction();
  final Pointer<Utf8> Function() sodium_version_string = libsodium
      .lookup<NativeFunction<Pointer<Utf8> Function()>>('sodium_version_string')
      .asFunction();
  final int Function() sodium_library_version_major = libsodium
      .lookup<NativeFunction<Int32 Function()>>('sodium_library_version_major')
      .asFunction();
  final int Function() sodium_library_version_minor = libsodium
      .lookup<NativeFunction<Int32 Function()>>('sodium_library_version_minor')
      .asFunction();
  final int Function() sodium_library_minimal = libsodium
      .lookup<NativeFunction<Int32 Function()>>('sodium_library_minimal')
      .asFunction();

  final int Function() sodium_runtime_has_neon = libsodium
      .lookup<NativeFunction<Int32 Function()>>('sodium_runtime_has_neon')
      .asFunction();
  final int Function() sodium_runtime_has_sse2 = libsodium
      .lookup<NativeFunction<Int32 Function()>>('sodium_runtime_has_sse2')
      .asFunction();
  final int Function() sodium_runtime_has_sse3 = libsodium
      .lookup<NativeFunction<Int32 Function()>>('sodium_runtime_has_sse3')
      .asFunction();
  final int Function() sodium_runtime_has_ssse3 = libsodium
      .lookup<NativeFunction<Int32 Function()>>('sodium_runtime_has_ssse3')
      .asFunction();
  final int Function() sodium_runtime_has_sse41 = libsodium
      .lookup<NativeFunction<Int32 Function()>>('sodium_runtime_has_sse41')
      .asFunction();
  final int Function() sodium_runtime_has_avx = libsodium
      .lookup<NativeFunction<Int32 Function()>>('sodium_runtime_has_avx')
      .asFunction();
  final int Function() sodium_runtime_has_avx2 = libsodium
      .lookup<NativeFunction<Int32 Function()>>('sodium_runtime_has_avx2')
      .asFunction();
  final int Function() sodium_runtime_has_avx512f = libsodium
      .lookup<NativeFunction<Int32 Function()>>('sodium_runtime_has_avx512f')
      .asFunction();
  final int Function() sodium_runtime_has_pclmul = libsodium
      .lookup<NativeFunction<Int32 Function()>>('sodium_runtime_has_pclmul')
      .asFunction();
  final int Function() sodium_runtime_has_aesni = libsodium
      .lookup<NativeFunction<Int32 Function()>>('sodium_runtime_has_aesni')
      .asFunction();
  final int Function() sodium_runtime_has_rdrand = libsodium
      .lookup<NativeFunction<Int32 Function()>>('sodium_runtime_has_rdrand')
      .asFunction();

  final Pointer<Utf8> Function(
          Pointer<Uint8> hex, int hex_maxlen, Pointer<Uint8> bin, int bin_len)
      sodium_bin2hex = libsodium
          .lookup<
              NativeFunction<
                  Pointer<Utf8> Function(Pointer<Uint8>, IntPtr, Pointer<Uint8>,
                      IntPtr)>>('sodium_bin2hex')
          .asFunction();

  final int Function(
          Pointer<Uint8> bin,
          int bin_maxlen,
          Pointer<Utf8> hex,
          int hex_len,
          Pointer<Utf8> ignore,
          Pointer<Uint8> bin_len,
          Pointer<Uint8> hex_end) sodium_hex2bin =
      libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Uint8>,
                      IntPtr,
                      Pointer<Utf8>,
                      IntPtr,
                      Pointer<Utf8>,
                      Pointer<Uint8>,
                      Pointer<Uint8>)>>('sodium_hex2bin')
          .asFunction();

  final int Function(int bin_len, int variant) sodium_base64_encoded_len =
      libsodium
          .lookup<NativeFunction<Int32 Function(Uint32, Int32)>>(
              'sodium_base64_encoded_len')
          .asFunction();

  final Pointer<Utf8> Function(Pointer<Uint8> b64, int b64_maxlen,
          Pointer<Uint8> bin, int bin_len, int variant) sodium_bin2base64 =
      libsodium
          .lookup<
              NativeFunction<
                  Pointer<Utf8> Function(Pointer<Uint8>, IntPtr, Pointer<Uint8>,
                      IntPtr, Int32)>>('sodium_bin2base64')
          .asFunction();

  final int Function(
          Pointer<Uint8> bin,
          int bin_maxlen,
          Pointer<Utf8> b64,
          int b64_len,
          Pointer<Utf8> ignore,
          Pointer<Uint8> bin_len,
          Pointer<Uint8> b64_end,
          int variant) sodium_base642bin =
      libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Uint8>,
                      IntPtr,
                      Pointer<Utf8>,
                      IntPtr,
                      Pointer<Utf8>,
                      Pointer<Uint8>,
                      Pointer<Uint8>,
                      Int32)>>('sodium_base642bin')
          .asFunction();

  final int Function(Pointer<Uint8> b1_, Pointer<Uint8> b2_, int len)
      sodium_memcmp = libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(
                      Pointer<Uint8>, Pointer<Uint8>, IntPtr)>>('sodium_memcmp')
          .asFunction();

  final int Function(Pointer<Uint32> padded_buflen_p, Pointer<Uint8> buf,
          int unpadded_buflen, int blocksize, int max_buflen) sodium_pad =
      libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Uint32>, Pointer<Uint8>, IntPtr,
                      IntPtr, IntPtr)>>('sodium_pad')
          .asFunction();

  final int Function(Pointer<Uint32> unpadded_buflen_p, Pointer<Uint8> buf,
          int padded_buflen, int blocksize) sodium_unpad =
      libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Uint32>, Pointer<Uint8>, IntPtr,
                      IntPtr)>>('sodium_unpad')
          .asFunction();
}
