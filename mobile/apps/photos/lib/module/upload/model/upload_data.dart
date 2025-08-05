class UploadMetadaData {
  final Map<String, dynamic> defaultMetadata;
  final Map<String, dynamic>? publicMetadata;
  final int? currentPublicMetadataVersion;

  UploadMetadaData({
    required this.defaultMetadata,
    required this.publicMetadata,
    required this.currentPublicMetadataVersion,
  });
}
