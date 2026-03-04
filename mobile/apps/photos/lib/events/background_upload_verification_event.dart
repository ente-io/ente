import "package:photos/events/event.dart";
import "package:photos/models/file/file.dart";

enum BackgroundUploadVerificationOutcome { verified, failed }

class BackgroundUploadVerificationEvent extends Event {
  final EnteFile file;
  final BackgroundUploadVerificationOutcome outcome;
  final Object? error;

  BackgroundUploadVerificationEvent({
    required this.file,
    required this.outcome,
    this.error,
  });
}
