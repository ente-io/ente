import "dart:convert" show utf8;
import "dart:io";

import "package:computer/computer.dart";
import "package:logging/logging.dart";

final _computer = Computer.shared();

final _logger = Logger("CacheUtil");

/// Writes data to a JSON file at the specified path using the provided method, inside computer.
/// The method should convert the data to a JSON string.
/// The JSON string is then UTF-8 encoded and written to the file.
Future<void> writeToJsonFile<P>(
  String filePath,
  P data,
  String Function(P) toJsonString,
) async {
  final args = {
    "filePath": filePath,
    "data": data,
    "toJsonString": toJsonString,
  };
  await _computer.compute<Map<String, dynamic>, void>(
    _writeToJsonFile<P>,
    param: args,
    taskName: "writeToJsonFile",
  );
}

Future<void> _writeToJsonFile<P>(Map<String, dynamic> args) async {
  try {
    final file = File(args["filePath"] as String);
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    final toJsonStringMethod = args["toJsonString"] as String Function(P);
    final jsonString = toJsonStringMethod(args["data"] as P);
    final encodedData = utf8.encode(jsonString);
    await file.writeAsBytes(encodedData);
  } catch (e, s) {
    _logger.severe("Error writing to JSON file with UTF-8", e, s);
  }
}

Future<void> writeToJsonFileUTF16<P>(
  String filePath,
  P data,
  String Function(P) toJsonString,
) async {
  try {
    final file = File(filePath);
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    final jsonString = toJsonString(data);
    final encodedData = jsonString.codeUnits; // UTF-16 encoding
    await file.writeAsBytes(encodedData);
  } catch (e, s) {
    _logger.severe("Error writing to JSON file with UTF-16", e, s);
  }
}

/// Reads a JSON file from the specified path using the provided method, inside computer.
/// The method should decode the JSON string into an object.
/// The JSON string is expected to be UTF-8 encoded.
Future<P?> decodeJsonFile<P>(
  String filePath,
  P Function(String) jsonDecodeMethod,
) async {
  final args = {
    "filePath": filePath,
    "jsonDecode": jsonDecodeMethod,
  };
  return await _computer.compute<Map<String, dynamic>, dynamic>(
    _decodeJsonFile<P>,
    param: args,
    taskName: "decodeJsonFile",
  );
}

Future<P?> _decodeJsonFile<P>(Map<String, dynamic> args) async {
  try {
    final file = File(args["filePath"] as String);
    if (!file.existsSync()) {
      _logger.warning("File does not exist: ${args["filePath"]}");
      return null;
    }
    final bytes = await file.readAsBytes();
    final jsonString = utf8.decode(bytes);
    final jsonDecodeMethod = args["jsonDecode"] as P Function(String);
    final decodedData = jsonDecodeMethod(jsonString);
    return decodedData;
  } catch (e, s) {
    _logger.severe("Error decoding JSON file of UTF-8", e, s);
    return null;
  }
}

Future<P?> decodeJsonFileUTF16<P>(
  String filePath,
  P Function(String) jsonDecodeMethod,
) async {
  try {
    final file = File(filePath);
    if (!file.existsSync()) {
      _logger.warning("File does not exist: $filePath");
      return null;
    }
    final bytes = await file.readAsBytes();
    final jsonString = String.fromCharCodes(bytes); // UTF-16 decoding
    final decodedData = jsonDecodeMethod(jsonString);
    return decodedData;
  } catch (e, s) {
    _logger.severe("Error decoding JSON file of UTF-16", e, s);
    return null;
  }
}
