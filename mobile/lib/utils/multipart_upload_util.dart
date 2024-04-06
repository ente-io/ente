// ignore_for_file: implementation_imports

import "dart:io";

import "package:dio/dio.dart";
import "package:logging/logging.dart";
import "package:photos/core/constants.dart";
import "package:photos/core/network/network.dart";
import "package:xml/src/xml/entities/named_entities.dart";
import "package:xml/xml.dart";

final _enteDio = NetworkClient.instance.enteDio;
final _dio = NetworkClient.instance.getDio();

class MultipartUploadURLs {
  final String objectKey;
  final List<String> partsURLs;
  final String completeURL;

  MultipartUploadURLs({
    required this.objectKey,
    required this.partsURLs,
    required this.completeURL,
  });

  factory MultipartUploadURLs.fromMap(Map<String, dynamic> map) {
    return MultipartUploadURLs(
      objectKey: map["urls"]["objectKey"],
      partsURLs: (map["urls"]["partURLs"] as List).cast<String>(),
      completeURL: map["urls"]["completeURL"],
    );
  }
}

Future<int> calculatePartCount(int fileSize) async {
  final partCount = (fileSize / multipartPartSize).ceil();
  return partCount;
}

Future<MultipartUploadURLs> getMultipartUploadURLs(int count) async {
  try {
    final response = await _enteDio.get(
      "/files/multipart-upload-urls",
      queryParameters: {
        "count": count,
      },
    );

    return MultipartUploadURLs.fromMap(response.data);
  } on Exception catch (e) {
    Logger("MultipartUploadURL").severe(e);
    rethrow;
  }
}

Future<void> putMultipartFile(
  MultipartUploadURLs urls,
  File encryptedFile,
) async {
  // upload individual parts and get their etags
  final etags = await uploadParts(urls.partsURLs, encryptedFile);

  print(etags);

  // complete the multipart upload
  await completeMultipartUpload(etags, urls.completeURL);
}

Future<Map<int, String>> uploadParts(
  List<String> partsURLs,
  File encryptedFile,
) async {
  final partsLength = partsURLs.length;
  final etags = <int, String>{};

  for (int i = 0; i < partsLength; i++) {
    final partURL = partsURLs[i];
    final isLastPart = i == partsLength - 1;
    final fileSize = isLastPart
        ? encryptedFile.lengthSync() % multipartPartSize
        : multipartPartSize;

    final response = await _dio.put(
      partURL,
      data: encryptedFile.openRead(
        i * multipartPartSize,
        isLastPart ? null : multipartPartSize,
      ),
      options: Options(
        headers: {
          Headers.contentLengthHeader: fileSize,
        },
      ),
    );

    final eTag = response.headers.value("etag");

    if (eTag?.isEmpty ?? true) {
      throw Exception('ETAG_MISSING');
    }

    etags[i] = eTag!;
  }

  return etags;
}

Future<void> completeMultipartUpload(
  Map<int, String> partEtags,
  String completeURL,
) async {
  final body = convertJs2Xml({
    'CompleteMultipartUpload': partEtags.entries.toList(),
  });

  print(body);

  try {
    await _dio.post(
      completeURL,
      data: body,
      options: Options(
        contentType: "text/xml",
      ),
    );
  } catch (e) {
    Logger("MultipartUpload").severe(e);
    rethrow;
  }
}

// for converting the response to xml
String convertJs2Xml(Map<String, dynamic> json) {
  final builder = XmlBuilder();
  buildXml(builder, json);
  return builder.buildDocument().toXmlString(
        pretty: true,
        indent: '    ',
        entityMapping: defaultMyEntityMapping,
      );
}

void buildXml(XmlBuilder builder, dynamic node) {
  if (node is Map<String, dynamic>) {
    node.forEach((key, value) {
      builder.element(key, nest: () => buildXml(builder, value));
    });
  } else if (node is List<dynamic>) {
    for (var item in node) {
      buildXml(builder, item);
    }
  } else {
    builder.element(
      "Part",
      nest: () {
        builder.attribute(
          "PartNumber",
          (node as MapEntry<int, String>).key + 1,
        );
        print(node.value);
        builder.attribute("ETag", node.value);
      },
    );
  }
}

XmlEntityMapping defaultMyEntityMapping = MyXmlDefaultEntityMapping.xml();

class MyXmlDefaultEntityMapping extends XmlDefaultEntityMapping {
  MyXmlDefaultEntityMapping.xml() : this(xmlEntities);
  MyXmlDefaultEntityMapping.html() : this(htmlEntities);
  MyXmlDefaultEntityMapping.html5() : this(html5Entities);
  MyXmlDefaultEntityMapping(super.entities);

  @override
  String encodeText(String input) =>
      input.replaceAllMapped(_textPattern, _textReplace);

  @override
  String encodeAttributeValue(String input, XmlAttributeType type) {
    switch (type) {
      case XmlAttributeType.SINGLE_QUOTE:
        return input.replaceAllMapped(
          _singeQuoteAttributePattern,
          _singeQuoteAttributeReplace,
        );
      case XmlAttributeType.DOUBLE_QUOTE:
        return input.replaceAllMapped(
          _doubleQuoteAttributePattern,
          _doubleQuoteAttributeReplace,
        );
    }
  }
}

final _textPattern = RegExp(r'[&<>' + _highlyDiscouragedCharClass + r']');

String _textReplace(Match match) {
  final toEscape = match.group(0)!;
  switch (toEscape) {
    case '<':
      return '&lt;';
    case '&':
      return '&amp;';
    case '>':
      return '&gt;';
    default:
      return _asNumericCharacterReferences(toEscape);
  }
}

final _singeQuoteAttributePattern =
    RegExp(r"['&<>\n\r\t" + _highlyDiscouragedCharClass + r']');

String _singeQuoteAttributeReplace(Match match) {
  final toEscape = match.group(0)!;
  switch (toEscape) {
    case "'":
      return '';
    case '&':
      return '&amp;';
    case '<':
      return '&lt;';
    case '>':
      return '&gt;';
    default:
      return _asNumericCharacterReferences(toEscape);
  }
}

final _doubleQuoteAttributePattern =
    RegExp(r'["&<>\n\r\t' + _highlyDiscouragedCharClass + r']');

String _doubleQuoteAttributeReplace(Match match) {
  final toEscape = match.group(0)!;
  switch (toEscape) {
    case '"':
      return '';
    case '&':
      return '&amp;';
    case '<':
      return '&lt;';
    case '>':
      return '&gt;';
    default:
      return _asNumericCharacterReferences(toEscape);
  }
}

const _highlyDiscouragedCharClass =
    r'\u0001-\u0008\u000b\u000c\u000e-\u001f\u007f-\u0084\u0086-\u009f';

String _asNumericCharacterReferences(String toEscape) => toEscape.runes
    .map((rune) => '&#x${rune.toRadixString(16).toUpperCase()};')
    .join();
