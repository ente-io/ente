import "dart:convert";
import "dart:typed_data";

const String _ALPHABET = "0123456789abcdef";

/// An instance of the default implementation of the [HexCodec].
const HEX = const HexCodec();

/// A codec for encoding and decoding byte arrays to and from
/// hexadecimal strings.
class HexCodec extends Codec<List<int>, String> {
  const HexCodec();

  @override
  Converter<List<int>, String> get encoder => const HexEncoder();

  @override
  Converter<String, List<int>> get decoder => const HexDecoder();
}

/// A converter to encode byte arrays into hexadecimal strings.
class HexEncoder extends Converter<List<int>, String> {
  /// If true, the encoder will encode into uppercase hexadecimal strings.
  final bool upperCase;

  const HexEncoder({bool this.upperCase: false});

  @override
  String convert(List<int> bytes) {
    StringBuffer buffer = new StringBuffer();
    for (int part in bytes) {
      if (part & 0xff != part) {
        throw new FormatException("Non-byte integer detected");
      }
      buffer.write('${part < 16 ? '0' : ''}${part.toRadixString(16)}');
    }
    if (upperCase) {
      return buffer.toString().toUpperCase();
    } else {
      return buffer.toString();
    }
  }
}

/// A converter to decode hexadecimal strings into byte arrays.
class HexDecoder extends Converter<String, List<int>> {
  const HexDecoder();

  @override
  List<int> convert(String hex) {
    String str = hex.replaceAll(" ", "");
    str = str.toLowerCase();
    if (str.length % 2 != 0) {
      str = "0" + str;
    }
    Uint8List result = new Uint8List(str.length ~/ 2);
    for (int i = 0; i < result.length; i++) {
      int firstDigit = _ALPHABET.indexOf(str[i * 2]);
      int secondDigit = _ALPHABET.indexOf(str[i * 2 + 1]);
      if (firstDigit == -1 || secondDigit == -1) {
        throw new FormatException("Non-hex character detected in $hex");
      }
      result[i] = (firstDigit << 4) + secondDigit;
    }
    return result;
  }
}
