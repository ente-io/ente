import "package:photos/models/ml/ml_versions.dart";
import "package:photos/services/face_ml/face_feedback.dart/feedback_types.dart";
import "package:uuid/uuid.dart";

abstract class Feedback {
  final FeedbackType type;
  final String feedbackID;
  final DateTime timestamp;
  final int madeOnFaceMlVersion;
  final int madeOnClusterMlVersion;

  get typeString => type.toValueString();

  get timestampString => timestamp.toIso8601String();

  Feedback(
    this.type, {
    String? feedbackID,
    DateTime? timestamp,
    int? madeOnFaceMlVersion,
    int? madeOnClusterMlVersion,
  })  : feedbackID = feedbackID ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now(),
        madeOnFaceMlVersion = madeOnFaceMlVersion ?? faceMlVersion,
        madeOnClusterMlVersion = madeOnClusterMlVersion ?? clusterMlVersion;

  Map<String, dynamic> toJson();

  String toJsonString();

  // Feedback fromJson(Map<String, dynamic> json);

  // Feedback fromJsonString(String jsonString);
}
