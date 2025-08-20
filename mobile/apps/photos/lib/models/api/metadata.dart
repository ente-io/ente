class UpdateMagicMetadataRequest {
  final int id;
  final MetadataRequest? magicMetadata;

  UpdateMagicMetadataRequest({required this.id, required this.magicMetadata});

  factory UpdateMagicMetadataRequest.fromJson(dynamic json) {
    return UpdateMagicMetadataRequest(
      id: json['id'],
      magicMetadata: json['magicMetadata'] != null
          ? MetadataRequest.fromJson(json['magicMetadata'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    if (magicMetadata != null) {
      map['magicMetadata'] = magicMetadata!.toJson();
    }
    return map;
  }
}

class MetadataRequest {
  int? version;
  int? count;
  String? data;
  String? header;

  MetadataRequest({
    required this.version,
    required this.count,
    required this.data,
    required this.header,
  });

  MetadataRequest.fromJson(dynamic json) {
    version = json['version'];
    count = json['count'];
    data = json['data'];
    header = json['header'];
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['version'] = version;
    map['count'] = count;
    map['data'] = data;
    map['header'] = header;
    return map;
  }
}
