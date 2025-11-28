class FileShareUrl {
  final String id;
  final int fileID;
  final String url;
  final int validTill;
  final int deviceLimit;
  final bool enableDownload;
  final bool passwordEnabled;
  final bool isDisabled;
  final String? pwNonce;
  final int? opsLimit;
  final int? memLimit;
  final int createdAt;
  final int updatedAt;
  final String? encryptedFileKey;
  final String? encryptedFileKeyNonce;
  final String? kdfNonce;
  final int? kdfMemLimit;
  final int? kdfOpsLimit;
  final String? encryptedShareKey;

  FileShareUrl({
    required this.id,
    required this.fileID,
    required this.url,
    required this.validTill,
    required this.deviceLimit,
    required this.enableDownload,
    required this.passwordEnabled,
    required this.isDisabled,
    this.pwNonce,
    this.opsLimit,
    this.memLimit,
    required this.createdAt,
    required this.updatedAt,
    this.encryptedFileKey,
    this.encryptedFileKeyNonce,
    this.kdfNonce,
    this.kdfMemLimit,
    this.kdfOpsLimit,
    this.encryptedShareKey,
  });

  bool get hasExpiry => validTill != 0;

  bool get isExpired =>
      hasExpiry && validTill < DateTime.now().microsecondsSinceEpoch;

  factory FileShareUrl.fromMap(Map<String, dynamic> map) {
    return FileShareUrl(
      id: map['linkID'] as String,
      fileID: map['fileID'] as int,
      url: map['url'] as String,
      validTill: map['validTill'] as int? ?? 0,
      deviceLimit: map['deviceLimit'] as int? ?? 0,
      enableDownload: map['enableDownload'] as bool? ?? true,
      passwordEnabled: map['passwordEnabled'] as bool? ?? false,
      isDisabled: false,
      pwNonce: map['nonce'] as String?,
      opsLimit: map['opsLimit'] as int?,
      memLimit: map['memLimit'] as int?,
      createdAt: map['createdAt'] as int? ?? 0,
      updatedAt: map['createdAt'] as int? ?? 0,
      encryptedFileKey: map['encryptedFileKey'] as String?,
      encryptedFileKeyNonce: map['encryptedFileKeyNonce'] as String?,
      kdfNonce: map['kdfNonce'] as String?,
      kdfMemLimit: map['kdfMemLimit'] as int?,
      kdfOpsLimit: map['kdfOpsLimit'] as int?,
      encryptedShareKey: map['encryptedShareKey'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'linkID': id,
      'fileID': fileID,
      'url': url,
      'validTill': validTill,
      'deviceLimit': deviceLimit,
      'enableDownload': enableDownload,
      'passwordEnabled': passwordEnabled,
      'nonce': pwNonce,
      'opsLimit': opsLimit,
      'memLimit': memLimit,
      'createdAt': createdAt,
      'encryptedFileKey': encryptedFileKey,
      'encryptedFileKeyNonce': encryptedFileKeyNonce,
      'kdfNonce': kdfNonce,
      'kdfMemLimit': kdfMemLimit,
      'kdfOpsLimit': kdfOpsLimit,
      'encryptedShareKey': encryptedShareKey,
    };
  }
}
