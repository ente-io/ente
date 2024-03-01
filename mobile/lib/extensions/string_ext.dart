const List<String> connectWords = [
  'a', 'an', 'the', // Articles

  'about', 'above', 'across', 'after', 'against', 'along', 'amid', 'among',
  'around', 'as', 'at', 'before', 'behind', 'below', 'beneath', 'beside',
  'between', 'beyond', 'by', 'concerning', 'considering', 'despite', 'down',
  'during', 'except', 'for', 'from', 'in', 'inside', 'into', 'like', 'near',
  'of', 'off', 'on', 'onto', 'out', 'outside', 'over', 'past', 'regarding',
  'round', 'since', 'through', 'to', 'toward', 'under', 'underneath', 'until',
  'unto', 'up', 'upon', 'with', 'within', 'without', // Prepositions

  'and', 'as', 'because', 'but', 'for', 'if', 'nor', 'or', 'since', 'so',
  'that', 'though', 'unless', 'until', 'when', 'whenever', 'where', 'whereas',
  'wherever', 'while', 'yet', // Conjunctions

  'i', 'you', 'he', 'she', 'it', 'we', 'they', 'me', 'him', 'her', 'us', 'them',
  'my', 'your', 'his', 'its', 'our', 'their', 'mine', 'yours', 'hers', 'ours',
  'theirs', 'who', 'whom', 'whose', 'which', 'what', // Pronouns

  'am', 'is', 'are', 'was', 'were', 'be', 'being', 'been', 'have', 'has', 'had',
  'do', 'does', 'did', 'will', 'would', 'shall', 'should', 'can', 'could',
  'may', 'might', 'must', // Auxiliary Verbs
];

extension StringExtensionsNullSafe on String? {
  int get sumAsciiValues {
    if (this == null) {
      return -1;
    }
    int sum = 0;
    for (int i = 0; i < this!.length; i++) {
      sum += this!.codeUnitAt(i);
    }
    return sum;
  }
}

extension DescriptionString on String? {
  bool get isAllConnectWords {
    if (this == null) {
      throw AssertionError("String cannot be null");
    }
    final subDescWords = this!.split(" ");
    return subDescWords.every(
      (subDescWord) => connectWords.any(
        (connectWord) => subDescWord.toLowerCase() == connectWord,
      ),
    );
  }

  bool get isLastWordConnectWord {
    if (this == null) {
      throw AssertionError("String cannot be null");
    }
    final subDescWords = this!.split(" ");
    return connectWords
        .any((element) => element == subDescWords.last.toLowerCase());
  }
}
