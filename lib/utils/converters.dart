
import "dart:convert";
import "dart:typed_data";

// convert hex to base64
String hexToBase64(String hex) {
  final bytes = hexToBytes(hex);
  return base64Encode(bytes);
}

List<int> hexToBytes(String hex) {
  final result = <int>[];
  for (var i = 0; i < hex.length; i += 2) {
    result.add(int.parse(hex.substring(i, i + 2), radix: 16));
  }
  return result;
}

// convert base64 to hex
String base64ToHex(String base64) {
  final bytes = base64Decode(base64);
  return bytesToHex(bytes);
}



String bytesToHex(Uint8List bytes) {
  final result = StringBuffer();
  for (var i = 0; i < bytes.length; i++) {
    result.write(bytes[i].toRadixString(16).padLeft(2, '0'));
  }
  return result.toString();
}
