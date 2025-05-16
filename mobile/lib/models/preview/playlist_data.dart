// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import "dart:io";

class PlaylistData {
  File preview;
  int? width;
  int? height;
  int? size;
  int? durationInSeconds;

  PlaylistData({
    required this.preview,
    this.width,
    this.height,
    this.size,
    this.durationInSeconds,
  });

  PlaylistData copyWith({
    File? preview,
    int? width,
    int? height,
    int? size,
    int? durationInSeconds,
  }) {
    return PlaylistData(
      preview: preview ?? this.preview,
      width: width ?? this.width,
      height: height ?? this.height,
      size: size ?? this.size,
      durationInSeconds: durationInSeconds ?? this.durationInSeconds,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'preview': preview.readAsStringSync(),
      'width': width,
      'height': height,
      'size': size,
      'durationInSeconds': durationInSeconds,
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return 'PlaylistData(preview: $preview, width: $width, height: $height, size: $size, durationInSeconds: $durationInSeconds)';
  }

  @override
  bool operator ==(covariant PlaylistData other) {
    if (identical(this, other)) return true;

    return other.preview == preview &&
        other.width == width &&
        other.height == height &&
        other.size == size;
  }

  @override
  int get hashCode {
    return preview.hashCode ^ width.hashCode ^ height.hashCode ^ size.hashCode;
  }
}
