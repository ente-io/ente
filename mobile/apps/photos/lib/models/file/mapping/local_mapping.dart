class LocalAssetInfo {
  final String id;
  final String? hash;
  final String? name;
  final String? relativePath;
  final int state;

  LocalAssetInfo({
    required this.id,
    this.hash,
    this.name,
    this.relativePath,
    required this.state,
  });

  factory LocalAssetInfo.fromRow(Map<String, Object?> row) {
    return LocalAssetInfo(
      id: row['id'] as String,
      hash: row['hash'] as String?,
      name: row['name'] as String?,
      relativePath: row['relative_path'] as String?,
      state: row['state'] as int,
    );
  }
}
