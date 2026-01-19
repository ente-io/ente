import 'dart:convert';

class LocalFileAttributes {
  final int? width;
  final int? height;
  final int? fileSize;
  final String? hash;
  final double? latitude;
  final double? longitude;
  final String? cameraMake;
  final String? cameraModel;
  final int? motionPhotoStartIndex;
  final bool? isPanorama;
  final bool? noThumb;
  final String? dateTime;
  final String? offsetTime;

  const LocalFileAttributes({
    this.width,
    this.height,
    this.fileSize,
    this.hash,
    this.latitude,
    this.longitude,
    this.cameraMake,
    this.cameraModel,
    this.motionPhotoStartIndex,
    this.isPanorama,
    this.noThumb,
    this.dateTime,
    this.offsetTime,
  });

  String toEncodedJson() => jsonEncode(toJson());

  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
      'fileSize': fileSize,
      'hash': hash,
      'latitude': latitude,
      'longitude': longitude,
      'cameraMake': cameraMake,
      'cameraModel': cameraModel,
      'motionPhotoStartIndex': motionPhotoStartIndex,
      'isPanorama': isPanorama,
      'noThumb': noThumb,
      'dateTime': dateTime,
      'offsetTime': offsetTime,
    };
  }

  static LocalFileAttributes? fromEncodedJson(String? encodedJson) {
    if (encodedJson == null || encodedJson.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(encodedJson);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    return fromJson(decoded);
  }

  static LocalFileAttributes? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return LocalFileAttributes(
      width: json['width'],
      height: json['height'],
      fileSize: json['fileSize'],
      hash: json['hash'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      cameraMake: json['cameraMake'],
      cameraModel: json['cameraModel'],
      motionPhotoStartIndex: json['motionPhotoStartIndex'],
      isPanorama: json['isPanorama'],
      noThumb: json['noThumb'],
      dateTime: json['dateTime'],
      offsetTime: json['offsetTime'],
    );
  }
}
