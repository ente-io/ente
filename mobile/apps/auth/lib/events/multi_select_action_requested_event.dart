enum MultiSelectAction {
  pinToggle,
  unpin,
  addTag,
  trash,
  restore,
  deleteForever,
}

class MultiSelectActionRequestedEvent {
  MultiSelectActionRequestedEvent(this.action);

  final MultiSelectAction action;
}
