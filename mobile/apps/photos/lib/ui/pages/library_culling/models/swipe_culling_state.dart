import 'package:photos/models/file/file.dart';

enum SwipeDecision { keep, delete, undecided }

class SwipeAction {
  final EnteFile file;
  final SwipeDecision decision;
  final DateTime timestamp;
  final int groupIndex;

  SwipeAction({
    required this.file,
    required this.decision,
    required this.timestamp,
    required this.groupIndex,
  });
}

class GroupProgress {
  final int totalImages;
  final int reviewedImages;
  final int deletionCount;

  GroupProgress({
    required this.totalImages,
    required this.reviewedImages,
    required this.deletionCount,
  });

  bool get isComplete => reviewedImages == totalImages;
  double get progressPercentage => reviewedImages / totalImages;
}