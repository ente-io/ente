import "package:photos/events/event.dart";

class DetailsSheetEvent extends Event {
  final int? uploadedFileID;
  final String? localID;
  final bool opened;

  DetailsSheetEvent({
    required this.localID,
    required this.uploadedFileID,
    required this.opened,
  });

  bool isSameFile({required int? uploadedFileID, required String? localID}) {
    if (this.uploadedFileID == uploadedFileID && this.localID == localID) {
      return true;
    }
    return false;
  }
}
