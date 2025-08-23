class Prompt {
  final String id;
  final int position;
  final String query;
  final double minScore;
  final double minSize;
  final String title;
  final bool showVideo;
  final bool recentFirst;

  Prompt({
    String? id,
    this.position = 0,
    required this.query,
    required this.minScore,
    required this.minSize,
    required this.title,
    this.showVideo = true,
    this.recentFirst = false,
  }) : id = id ?? title;

  // fromJson
  Prompt.fromJson(Map<String, dynamic> json)
      : id = json['id'] ?? json['title'],
        query = json['query'] ?? json['prompt'],
        minScore = json['minScore'] ?? json['minimumScore'] ?? 0.2,
        minSize = json['minSize'] ?? json['minimumSize'] ?? 0.0,
        position = json['position'] ?? 0,
        title = json['title'],
        recentFirst = json['recentFirst'] ?? false,
        showVideo = json['showVideo'] ?? true;
}
