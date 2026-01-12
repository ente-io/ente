import "package:photos/events/event.dart";

class CommentDeletedEvent extends Event {
  final String commentId;

  CommentDeletedEvent(this.commentId);
}
