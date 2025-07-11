class LocalAssetInfo {
  final String id;
  final String? hash;
  final String? title;
  final String? relativePath;
  final int state;

  LocalAssetInfo({
    required this.id,
    this.hash,
    this.title,
    this.relativePath,
    required this.state,
  });

  factory LocalAssetInfo.fromRow(Map<String, Object?> row) {
    return LocalAssetInfo(
      id: row['id'] as String,
      hash: row['hash'] as String?,
      title: row['title'] as String?,
      relativePath: row['relative_path'] as String?,
      state: row['scan_state'] as int,
    );
  }
}
