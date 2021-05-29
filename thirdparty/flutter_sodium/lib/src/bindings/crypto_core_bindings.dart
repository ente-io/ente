import 'dart:ffi';
import 'libsodium.dart';

// ignore_for_file: non_constant_identifier_names

class CryptoCoreBindings {
  final int Function() crypto_core_hchacha20_outputbytes =
      libsodium.lookupSizet('crypto_core_hchacha20_outputbytes');

  final int Function() crypto_core_hchacha20_inputbytes =
      libsodium.lookupSizet('crypto_core_hchacha20_inputbytes');

  final int Function() crypto_core_hchacha20_keybytes =
      libsodium.lookupSizet('crypto_core_hchacha20_keybytes');

  final int Function() crypto_core_hchacha20_constbytes =
      libsodium.lookupSizet('crypto_core_hchacha20_constbytes');

  final int Function(Pointer<Uint8> out, Pointer<Uint8> in_, Pointer<Uint8> k,
          Pointer<Uint8> c) crypto_core_hchacha20 =
      libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>,
                      Pointer<Uint8>)>>('crypto_core_hchacha20')
          .asFunction();

  final int Function() crypto_core_hsalsa20_outputbytes =
      libsodium.lookupSizet('crypto_core_hsalsa20_outputbytes');

  final int Function() crypto_core_hsalsa20_inputbytes =
      libsodium.lookupSizet('crypto_core_hsalsa20_inputbytes');

  final int Function() crypto_core_hsalsa20_keybytes =
      libsodium.lookupSizet('crypto_core_hsalsa20_keybytes');

  final int Function() crypto_core_hsalsa20_constbytes =
      libsodium.lookupSizet('crypto_core_hsalsa20_constbytes');

  final int Function(Pointer<Uint8> out, Pointer<Uint8> in_, Pointer<Uint8> k,
          Pointer<Uint8> c) crypto_core_hsalsa20 =
      libsodium
          .lookup<
              NativeFunction<
                  Int32 Function(Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>,
                      Pointer<Uint8>)>>('crypto_core_hsalsa20')
          .asFunction();
}
