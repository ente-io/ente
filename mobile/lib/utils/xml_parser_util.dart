// ignore_for_file: implementation_imports

import "package:xml/src/xml/entities/named_entities.dart";
import "package:xml/xml.dart";

// used for classes that can be converted to xml
abstract class XmlParsableObject {
  Map<String, dynamic> toMap();
  String get elementName;
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

// for building the xml node tree recursively
void buildXml(XmlBuilder builder, dynamic node) {
  if (node is Map<String, dynamic>) {
    node.forEach((key, value) {
      builder.element(key, nest: () => buildXml(builder, value));
    });
  } else if (node is List<dynamic>) {
    for (var item in node) {
      buildXml(builder, item);
    }
  } else if (node is XmlParsableObject) {
    builder.element(
      node.elementName,
      nest: () {
        buildXml(builder, node.toMap());
      },
    );
  } else {
    builder.text(node.toString());
  }
}

// for removing the &quot; from the xml string response.
// couldn't find better way to do this
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
