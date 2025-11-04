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
  final String? encryptedFileKey;
  final String? encryptedFileKeyNonce;
  final String? kdfNonce;
  final int? kdfMemLimit;
  final int? kdfOpsLimit;
  final String? encryptedShareKey;

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
    this.encryptedFileKey,
    this.encryptedFileKeyNonce,
    this.kdfNonce,
    this.kdfMemLimit,
    this.kdfOpsLimit,
    this.encryptedShareKey,
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
      encryptedFileKey: json['encryptedFileKey'] as String?,
      encryptedFileKeyNonce: json['encryptedFileKeyNonce'] as String?,
      kdfNonce: json['kdfNonce'] as String?,
      kdfMemLimit: json['kdfMemLimit'] as int?,
      kdfOpsLimit: json['kdfOpsLimit'] as int?,
      encryptedShareKey: json['encryptedShareKey'] as String?,
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
      if (encryptedFileKey != null) 'encryptedFileKey': encryptedFileKey,
      if (encryptedFileKeyNonce != null)
        'encryptedFileKeyNonce': encryptedFileKeyNonce,
      if (kdfNonce != null) 'kdfNonce': kdfNonce,
      if (kdfMemLimit != null) 'kdfMemLimit': kdfMemLimit,
      if (kdfOpsLimit != null) 'kdfOpsLimit': kdfOpsLimit,
      if (encryptedShareKey != null) 'encryptedShareKey': encryptedShareKey,
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
        other.createdAt == createdAt &&
        other.encryptedFileKey == encryptedFileKey &&
        other.encryptedFileKeyNonce == encryptedFileKeyNonce &&
        other.kdfNonce == kdfNonce &&
        other.kdfMemLimit == kdfMemLimit &&
        other.kdfOpsLimit == kdfOpsLimit &&
        other.encryptedShareKey == encryptedShareKey;
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
      encryptedFileKey,
      encryptedFileKeyNonce,
      kdfNonce,
      kdfMemLimit,
      kdfOpsLimit,
      encryptedShareKey,
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
        'createdAt: $createdAt, '
        'encryptedFileKey: $encryptedFileKey, '
        'encryptedFileKeyNonce: $encryptedFileKeyNonce, '
        'kdfNonce: $kdfNonce, '
        'kdfMemLimit: $kdfMemLimit, '
        'kdfOpsLimit: $kdfOpsLimit, '
        'encryptedShareKey: $encryptedShareKey'
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
    String? encryptedFileKey,
    String? encryptedFileKeyNonce,
    String? kdfNonce,
    int? kdfMemLimit,
    int? kdfOpsLimit,
    String? encryptedShareKey,
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
      encryptedFileKey: encryptedFileKey ?? this.encryptedFileKey,
      encryptedFileKeyNonce:
          encryptedFileKeyNonce ?? this.encryptedFileKeyNonce,
      kdfNonce: kdfNonce ?? this.kdfNonce,
      kdfMemLimit: kdfMemLimit ?? this.kdfMemLimit,
      kdfOpsLimit: kdfOpsLimit ?? this.kdfOpsLimit,
      encryptedShareKey: encryptedShareKey ?? this.encryptedShareKey,
    );
  }
}
