import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:photos/services/machine_learning/semantic_search/clip/clip_text_tokenizer.dart";
import "package:photos/src/rust/api/ml_indexing_api.dart" as rust_ml;
import "package:photos/src/rust/frb_generated.dart";

const _kClipBpeMergeLineCount = 49152 - 256 - 2;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await EntePhotosRust.init();
  });

  test("Rust CLIP tokenizer matches Dart tokenizer", () async {
    final tempDir = await Directory.systemTemp.createTemp(
      "clip_tokenizer_parity_",
    );
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final vocabPath = "${tempDir.path}/bpe_simple_vocab_16e6.txt";
    await File(vocabPath)
        .writeAsString(_buildSyntheticClipVocab(), flush: true);
    await ClipTextTokenizer.instance.init(vocabPath);

    const queries = <String>[
      "hello world",
      "can't won't i'd we're",
      "multiple    spaces\\tand\\nlines",
      "&amp;lt;html&amp;gt; entities &amp;amp; symbols",
      "<|startoftext|> should be tokenized literally",
      "numbers 1234567890 and punctuation !!! ???",
      "long query long query long query long query long query long query long query long query long query long query",
    ];

    for (final query in queries) {
      final dartTokens = await ClipTextTokenizer.instance.tokenize(query);
      final rustTokens = await rust_ml.tokenizeClipTextRust(
        text: query,
        vocabPath: vocabPath,
      );
      expect(
        rustTokens.toList(growable: false),
        dartTokens,
        reason: "Tokenizer mismatch for query: '$query'",
      );
      expect(rustTokens.length, ClipTextTokenizer.totalTokens);
    }
  });
}

String _buildSyntheticClipVocab() {
  final buffer = StringBuffer("#version: 0.2");
  for (int i = 0; i < _kClipBpeMergeLineCount; i++) {
    buffer.write("\na b");
  }
  return buffer.toString();
}
