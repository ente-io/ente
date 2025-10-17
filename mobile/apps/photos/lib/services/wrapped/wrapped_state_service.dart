import "dart:async";

import "package:flutter/foundation.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/wrapped/models.dart";

@immutable
class WrappedEntryState {
  const WrappedEntryState({
    required this.resumeIndex,
    required this.isComplete,
    this.result,
  });

  final WrappedResult? result;
  final int resumeIndex;
  final bool isComplete;

  bool get hasResult => result != null && result!.cards.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WrappedEntryState &&
        other.result == result &&
        other.resumeIndex == resumeIndex &&
        other.isComplete == isComplete;
  }

  @override
  int get hashCode => Object.hash(result, resumeIndex, isComplete);
}

class WrappedStateService {
  WrappedStateService._()
      : _state = ValueNotifier<WrappedEntryState>(
          WrappedEntryState(
            result: null,
            resumeIndex: 0,
            isComplete: localSettings.wrapped2025Complete(),
          ),
        );

  static final WrappedStateService instance = WrappedStateService._();

  final ValueNotifier<WrappedEntryState> _state;

  ValueListenable<WrappedEntryState> get stateListenable => _state;

  WrappedEntryState get state => _state.value;

  bool get isEnabled => flagService.enteWrapped;

  bool get shouldShowHomeBanner =>
      isEnabled && state.hasResult && !state.isComplete;

  bool get shouldShowDiscoveryEntry =>
      isEnabled &&
      state.hasResult &&
      state.isComplete &&
      DateTime.now().millisecondsSinceEpoch <
          DateTime(state.result!.year + 1, 01, 15, 23, 59, 59)
              .millisecondsSinceEpoch;

  void updateResult(WrappedResult? result) {
    if (result == null || result.cards.isEmpty) {
      unawaited(localSettings.setWrapped2025ResumeIndex(0));
      unawaited(localSettings.setWrapped2025Complete(false));
      _state.value = const WrappedEntryState(
        result: null,
        resumeIndex: 0,
        isComplete: false,
      );
      return;
    }

    final int cardCount = result.cards.length;

    int resumeIndex = localSettings.wrapped2025ResumeIndex();
    if (resumeIndex < 0) {
      resumeIndex = 0;
    } else if (resumeIndex >= cardCount) {
      resumeIndex = cardCount - 1;
    }

    final bool isComplete = localSettings.wrapped2025Complete();
    if (resumeIndex != localSettings.wrapped2025ResumeIndex()) {
      unawaited(localSettings.setWrapped2025ResumeIndex(resumeIndex));
    }

    _state.value = WrappedEntryState(
      result: result,
      resumeIndex: resumeIndex,
      isComplete: isComplete,
    );
  }

  void updateResumeIndex(int index) {
    if (!state.hasResult) {
      return;
    }
    final int safeIndex =
        index.clamp(0, state.result!.cards.length - 1).toInt();
    if (safeIndex == state.resumeIndex) {
      return;
    }

    unawaited(localSettings.setWrapped2025ResumeIndex(safeIndex));
    _state.value = WrappedEntryState(
      result: state.result,
      resumeIndex: safeIndex,
      isComplete: state.isComplete,
    );
  }

  void markComplete(bool isComplete) {
    if (!state.hasResult && !isComplete) {
      return;
    }

    unawaited(localSettings.setWrapped2025Complete(isComplete));
    _state.value = WrappedEntryState(
      result: state.result,
      resumeIndex: state.resumeIndex,
      isComplete: isComplete,
    );
  }
}
