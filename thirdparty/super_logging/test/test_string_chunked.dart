import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:super_logging/super_logging.dart';

var random = Random();

void main() {
  final chunkSize = SuperLogging.logChunkSize;

  test('test with empty text', () {
    var text = randomText(0);

    var actual = text.chunked(chunkSize).toList();
    var expected = [];

    expect(expected, actual);
  });

  test('test with length < chunk size', () {
    var text = randomText(chunkSize ~/ 2.5);

    var actual = text.chunked(chunkSize).toList();
    var expected = [text];

    expect(expected, actual);
  });

  test('test with length = chunk size', () {
    var text = randomText(chunkSize);

    var actual = text.chunked(chunkSize).toList();
    var expected = [text];

    expect(expected, actual);
  });

  test('test with length > chunk size', () {
    var text = randomText((chunkSize * 2.5).toInt());

    var actual = text.chunked(chunkSize).toList();
    var expected = [
      text.substring(0, chunkSize),
      text.substring(chunkSize, chunkSize * 2),
      text.substring(chunkSize * 2)
    ];

    expect(expected, actual);
  });
}

String randomText(int len) {
  var charCodes = List.generate(len, (index) => random.nextInt(0x10FFFF));
  return String.fromCharCodes(charCodes).substring(0, len);
}
