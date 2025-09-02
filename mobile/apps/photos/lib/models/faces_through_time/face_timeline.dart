import 'package:photos/models/faces_through_time/face_timeline_entry.dart';

class FaceTimeline {
  final String personId;
  final List<FaceTimelineEntry> entries;
  final DateTime generatedAt;
  final bool hasBeenViewed;
  final int version;

  FaceTimeline({
    required this.personId,
    required this.entries,
    required this.generatedAt,
    this.hasBeenViewed = false,
    this.version = 1,
  });

  Map<String, dynamic> toJson() => {
        'personId': personId,
        'generatedAt': generatedAt.toIso8601String(),
        'faceIds': entries.map((e) => e.faceId).toList(),
        'hasBeenViewed': hasBeenViewed,
        'version': version,
      };

  factory FaceTimeline.fromJson(Map<String, dynamic> json) {
    return FaceTimeline(
      personId: json['personId'],
      entries: (json['faceIds'] as List)
          .map((id) => FaceTimelineEntry(faceId: id))
          .toList(),
      generatedAt: DateTime.parse(json['generatedAt']),
      hasBeenViewed: json['hasBeenViewed'] ?? false,
      version: json['version'] ?? 1,
    );
  }

  bool get isValid {
    final age = DateTime.now().difference(generatedAt);
    return age.inDays < 365; // Cache valid for 1 year
  }

  int get totalFaces => entries.length;
}