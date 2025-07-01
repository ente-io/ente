import "package:photos/events/event.dart";

class ToggleMemoryAnimationEvent extends Event {
  final int? uploadedFileID;
  final String? localID;
  final bool pause;

  ToggleMemoryAnimationEvent({
    required this.localID,
    required this.uploadedFileID,
    required this.pause,
  });

  bool isSamePhoto({required int? uploadedFileID, required String? localID}) {
    if (this.uploadedFileID == uploadedFileID && this.localID == localID) {
      return true;
    }
    return false;
  }
}
