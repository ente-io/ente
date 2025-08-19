class ShareableLink {
  final String linkID;
  final String url;
  final int ownerID;
  final int fileID;
  final int? validTill;
  final int? deviceLimit;
  final bool passwordEnabled;
  final String? nonce;
  final int? memLimit;
  final int? opsLimit;
  final bool enableDownload;
  final int createdAt;
  String? fullURL;

  ShareableLink({
    required this.linkID,
    required this.url,
    required this.ownerID,
    required this.fileID,
    this.validTill,
    this.deviceLimit,
    required this.passwordEnabled,
    this.nonce,
    this.memLimit,
    this.opsLimit,
    required this.enableDownload,
    required this.createdAt,
  });

  factory ShareableLink.fromJson(Map<String, dynamic> json) {
    return ShareableLink(
      linkID: json['linkID'] as String,
      url: json['url'] as String,
      ownerID: json['ownerID'] as int,
      fileID: json['fileID'] as int,
      validTill: json['validTill'] as int?,
      deviceLimit: json['deviceLimit'] as int?,
      passwordEnabled: json['passwordEnabled'] as bool,
      nonce: json['nonce'] as String?,
      memLimit: json['memLimit'] as int?,
      opsLimit: json['opsLimit'] as int?,
      enableDownload: json['enableDownload'] as bool,
      createdAt: json['createdAt'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'linkID': linkID,
      'url': url,
      'ownerID': ownerID,
      'fileID': fileID,
      if (validTill != null) 'validTill': validTill,
      if (deviceLimit != null) 'deviceLimit': deviceLimit,
      'passwordEnabled': passwordEnabled,
      if (nonce != null) 'nonce': nonce,
      if (memLimit != null) 'memLimit': memLimit,
      if (opsLimit != null) 'opsLimit': opsLimit,
      'enableDownload': enableDownload,
      'createdAt': createdAt,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShareableLink &&
        other.linkID == linkID &&
        other.url == url &&
        other.ownerID == ownerID &&
        other.fileID == fileID &&
        other.validTill == validTill &&
        other.deviceLimit == deviceLimit &&
        other.passwordEnabled == passwordEnabled &&
        other.nonce == nonce &&
        other.memLimit == memLimit &&
        other.opsLimit == opsLimit &&
        other.enableDownload == enableDownload &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      linkID,
      url,
      ownerID,
      fileID,
      validTill,
      deviceLimit,
      passwordEnabled,
      nonce,
      memLimit,
      opsLimit,
      enableDownload,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'FileUrl('
        'linkID: $linkID, '
        'url: $url, '
        'ownerID: $ownerID, '
        'fileID: $fileID, '
        'validTill: $validTill, '
        'deviceLimit: $deviceLimit, '
        'passwordEnabled: $passwordEnabled, '
        'nonce: $nonce, '
        'memLimit: $memLimit, '
        'opsLimit: $opsLimit, '
        'enableDownload: $enableDownload, '
        'createdAt: $createdAt'
        ')';
  }

  ShareableLink copyWith({
    String? linkID,
    String? url,
    int? ownerID,
    int? fileID,
    int? validTill,
    int? deviceLimit,
    bool? passwordEnabled,
    String? nonce,
    int? memLimit,
    int? opsLimit,
    bool? enableDownload,
    int? createdAt,
  }) {
    return ShareableLink(
      linkID: linkID ?? this.linkID,
      url: url ?? this.url,
      ownerID: ownerID ?? this.ownerID,
      fileID: fileID ?? this.fileID,
      validTill: validTill ?? this.validTill,
      deviceLimit: deviceLimit ?? this.deviceLimit,
      passwordEnabled: passwordEnabled ?? this.passwordEnabled,
      nonce: nonce ?? this.nonce,
      memLimit: memLimit ?? this.memLimit,
      opsLimit: opsLimit ?? this.opsLimit,
      enableDownload: enableDownload ?? this.enableDownload,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
