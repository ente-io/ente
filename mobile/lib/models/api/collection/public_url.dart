class PublicURL {
  String url;
  int deviceLimit;
  int validTill;
  bool enableDownload;
  bool enableCollect;
  bool passwordEnabled;

  PublicURL({
    required this.url,
    required this.deviceLimit,
    required this.validTill,
    this.enableDownload = true,
    this.passwordEnabled = false,
    this.enableCollect = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'deviceLimit': deviceLimit,
      'validTill': validTill,
      'enableDownload': enableDownload,
      'passwordEnabled': passwordEnabled,
      'enableCollect': enableCollect,
    };
  }

  bool get hasExpiry => validTill != 0;

  // isExpired indicates whether the link has expired or not
  bool get isExpired =>
      hasExpiry && validTill < DateTime.now().microsecondsSinceEpoch;

  static fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;

    return PublicURL(
      url: map['url'],
      deviceLimit: map['deviceLimit'],
      validTill: map['validTill'] ?? 0,
      enableDownload: map['enableDownload'] ?? true,
      passwordEnabled: map['passwordEnabled'] ?? false,
      enableCollect: map['enableCollect'] ?? false,
    );
  }
}
