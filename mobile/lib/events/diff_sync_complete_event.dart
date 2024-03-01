import "package:photos/events/event.dart";

// Creating a separate Event since modifying SyncStatusUpdateEvent has impact on
// StatusBarWidget
class DiffSyncCompleteEvent extends Event {}
