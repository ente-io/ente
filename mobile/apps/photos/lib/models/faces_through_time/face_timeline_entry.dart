import 'dart:typed_data';

class FaceTimelineEntry {
  final String faceId;
  final int fileId;
  final DateTime timestamp;
  final String? ageText;
  final String? relativeTimeText;
  Uint8List? thumbnail;

  FaceTimelineEntry({
    required this.faceId,
    this.fileId = 0,
    DateTime? timestamp,
    this.ageText,
    this.relativeTimeText,
    this.thumbnail,
  }) : timestamp = timestamp ?? DateTime.now();

  String get displayText => ageText ?? relativeTimeText ?? '';

  bool get hasThumbnail => thumbnail != null;

  // For JSON serialization
  Map<String, dynamic> toJson() => {
        'faceId': faceId,
        'fileId': fileId,
        'timestamp': timestamp.toIso8601String(),
        'ageText': ageText,
        'relativeTimeText': relativeTimeText,
      };

  factory FaceTimelineEntry.fromJson(Map<String, dynamic> json) {
    return FaceTimelineEntry(
      faceId: json['faceId'],
      fileId: json['fileId'] ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      ageText: json['ageText'],
      relativeTimeText: json['relativeTimeText'],
    );
  }
}