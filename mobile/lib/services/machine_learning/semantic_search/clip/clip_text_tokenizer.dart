import "dart:convert";
import "dart:io" show File;
import "dart:math";

import "package:html_unescape/html_unescape.dart";
import "package:logging/logging.dart";
import "package:tuple/tuple.dart";

class ClipTextTokenizer {
  final _logger = Logger("ClipTextTokenizer");

  static const int totalTokens = 77;

  late String vocabulary;
  late Map<int, String> byteEncoder;
  late Map<String, int> byteDecoder;
  late Map<int, String> decoder;
  late Map<String, int> encoder;
  late Map<Tuple2<String, String>, int> bpeRanks;
  Map<String, String> cache = <String, String>{
    '<|startoftext|>': '<|startoftext|>',
    '<|endoftext|>': '<|endoftext|>',
  };

  // Dart RegExpt does not support Unicode identifiers (\p{L} and \p{N})
  RegExp pat = RegExp(
    r"""<\|startoftext\|>|<\|endoftext\|>|'s|'t|'re|'ve|'m|'ll|'d|[a-zA-Z]+|[0-9]+|[^\s\p{L}\p{N}]+""",
    caseSensitive: false,
    multiLine: false,
  );

  late int sot;
  late int eot;

  bool _isInitialized = false;

  // Singleton pattern
  ClipTextTokenizer._privateConstructor();
  static final instance = ClipTextTokenizer._privateConstructor();
  factory ClipTextTokenizer() => instance;

  Future<List<int>> tokenize(String text) async {
    var tokens = _encode(text);
    tokens =
        [sot] + tokens.sublist(0, min(totalTokens - 2, tokens.length)) + [eot];
    return tokens + List.filled(totalTokens - tokens.length, 0);
  }

  Future<void> init(String vocabPath) async {
    if (_isInitialized) return;
    final vocabFile = File(vocabPath);
    final String vocabulary = await vocabFile.readAsString();
    this.vocabulary = vocabulary;
    byteEncoder = _bytesToUnicode();
    byteDecoder = byteEncoder.map((k, v) => MapEntry(v, k));

    var split = vocabulary.split('\n');
    split = split.sublist(1, 49152 - 256 - 2 + 1);
    final merges = split
        .map((merge) => Tuple2(merge.split(' ')[0], merge.split(' ')[1]))
        .toList();

    final vocab = byteEncoder.values.toList();
    vocab.addAll(vocab.map((v) => '$v</w>').toList());

    for (var merge = 0; merge < merges.length; merge++) {
      vocab.add(merges[merge].item1 + merges[merge].item2);
    }
    vocab.addAll(['<|startoftext|>', '<|endoftext|>']);

    // asMap returns the map as a Map<int, String>
    decoder = vocab.asMap();
    encoder = decoder.map((k, v) => MapEntry(v, k));
    bpeRanks = Map.fromIterables(
      merges.map((merge) => merge),
      List.generate(merges.length, (i) => i),
    );

    sot = encoder['<|startoftext|>']!;
    eot = encoder['<|endoftext|>']!;
    _logger.info("Clip text tokenizer initialized");
    _isInitialized = true;
  }

  List<int> _encode(String text) {
    final List<int> bpeTokens = [];
    text = _whitespaceClean(_basicClean(text)).toLowerCase();
    for (Match match in pat.allMatches(text)) {
      String token = match[0]!;
      token = utf8.encode(token).map((b) => byteEncoder[b]).join();
      _bpe(token)
          .split(' ')
          .forEach((bpeToken) => bpeTokens.add(encoder[bpeToken]!));
    }
    return bpeTokens;
  }

  String _bpe(String token) {
    if (cache.containsKey(token)) {
      return cache[token]!;
    }
    var word = token.split('').map((char) => char).toList();
    word[word.length - 1] = '${word.last}</w>';
    var pairs = _getPairs(word);
    if (pairs.isEmpty) {
      return '$token</w>';
    }

    while (true) {
      Tuple2<String, String> bigram = pairs.first;
      for (var pair in pairs) {
        final rank1 = bpeRanks[pair] ?? double.infinity;
        final rank2 = bpeRanks[bigram] ?? double.infinity;

        if (rank1 < rank2) {
          bigram = pair;
        }
      }

      if (!bpeRanks.containsKey(bigram)) {
        break;
      }
      final first = bigram.item1;
      final second = bigram.item2;
      final newWord = <String>[];
      var i = 0;
      while (i < word.length) {
        final j = word.sublist(i).indexOf(first);
        if (j == -1) {
          newWord.addAll(word.sublist(i));
          break;
        }
        newWord.addAll(word.sublist(i, i + j));
        i = i + j;
        if (word[i] == first && i < word.length - 1 && word[i + 1] == second) {
          newWord.add(first + second);
          i += 2;
        } else {
          newWord.add(word[i]);
          i += 1;
        }
      }

      word = newWord;
      if (word.length == 1) {
        break;
      } else {
        pairs = _getPairs(word);
      }
    }
    final wordStr = word.join(' ');
    cache[token] = wordStr;
    return wordStr;
  }

  Map<int, String> _bytesToUnicode() {
    final List<int> bs = [];
    for (int i = '!'.codeUnitAt(0); i <= '~'.codeUnitAt(0); i++) {
      bs.add(i);
    }
    for (int i = '¡'.codeUnitAt(0); i <= '¬'.codeUnitAt(0); i++) {
      bs.add(i);
    }
    for (int i = '®'.codeUnitAt(0); i <= 'ÿ'.codeUnitAt(0); i++) {
      bs.add(i);
    }

    final List<int> cs = List.from(bs);
    int n = 0;
    for (int b = 0; b < 256; b++) {
      if (!bs.contains(b)) {
        bs.add(b);
        cs.add(256 + n);
        n += 1;
      }
    }

    final List<String> ds = cs.map((n) => String.fromCharCode(n)).toList();
    return Map.fromIterables(bs, ds);
  }

  Set<Tuple2<String, String>> _getPairs(List<String> word) {
    final Set<Tuple2<String, String>> pairs = {};
    String prevChar = word[0];
    for (var i = 1; i < word.length; i++) {
      pairs.add(Tuple2(prevChar, word[i]));
      prevChar = word[i];
    }
    return pairs;
  }

  String _basicClean(String text) {
    final unescape = HtmlUnescape();
    text = unescape.convert(unescape.convert(text));
    return text.trim();
  }

  String _whitespaceClean(String text) {
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    return text.trim();
  }
}
