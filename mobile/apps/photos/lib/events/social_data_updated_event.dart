import "package:photos/events/event.dart";

/// Event fired when social data (comments, reactions) has been synced.
///
/// Used to notify UI components that they should refresh their display.
class SocialDataUpdatedEvent extends Event {
  /// The collection ID that was synced, or null if multiple collections were synced.
  final int? collectionID;

  /// Whether new comments were synced.
  final bool hasNewComments;

  /// Whether new reactions were synced.
  final bool hasNewReactions;

  SocialDataUpdatedEvent({
    this.collectionID,
    this.hasNewComments = false,
    this.hasNewReactions = false,
  });

  @override
  String get reason =>
      'SocialDataUpdatedEvent{collectionID: $collectionID, comments: $hasNewComments, reactions: $hasNewReactions}';
}
