import "dart:async";

import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/wrapped/models.dart";
import "package:photos/services/wrapped/wrapped_cache_service.dart";
import "package:photos/services/wrapped/wrapped_engine.dart";
import "package:synchronized/synchronized.dart";

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

class WrappedService {
  WrappedService._()
      : _logger = Logger("WrappedService"),
        _cacheService = WrappedCacheService.instance,
        _computeLock = Lock(),
        _state = ValueNotifier<WrappedEntryState>(
          WrappedEntryState(
            result: null,
            resumeIndex: 0,
            isComplete: localSettings.wrapped2025Complete(),
          ),
        );

  static final WrappedService instance = WrappedService._();

  static const Duration _kInitialDelay = Duration(seconds: 5);
  static const int _kWrappedYear = 2025;

  final Logger _logger;
  final WrappedCacheService _cacheService;
  final Lock _computeLock;
  final ValueNotifier<WrappedEntryState> _state;
  bool _initialLoadScheduled = false;

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

  void scheduleInitialLoad() {
    if (!isEnabled) {
      return;
    }
    if (_initialLoadScheduled) {
      return;
    }
    _initialLoadScheduled = true;
    _logger.info("Scheduling Wrapped initial load after $_kInitialDelay");
    unawaited(Future<void>.delayed(_kInitialDelay, _bootstrap));
  }

  Future<void> _bootstrap() async {
    try {
      final WrappedResult? cached =
          await _cacheService.read(year: _kWrappedYear);
      if (cached != null) {
        _logger.info(
          "Loaded Wrapped cache for $_kWrappedYear with "
          "${cached.cards.length} cards",
        );
        updateResult(cached);
        return;
      }
    } catch (error, stackTrace) {
      _logger.severe("Failed to load Wrapped cache", error, stackTrace);
    }

    if (!isEnabled) {
      _logger.info(
        "Wrapped flag disabled; skipping initial compute for $_kWrappedYear",
      );
      return;
    }

    await _runCompute(reason: "initial", bypassFlag: false);
  }

  Future<void> forceRecompute() async {
    _logger.warning("Force recompute requested for $_kWrappedYear");
    await _computeLock.synchronized(() async {
      await _cacheService.clear(year: _kWrappedYear);
      updateResult(null);
      await _computeAndPersist(reason: "forced", bypassFlag: true);
    });
  }

  Future<void> _runCompute({
    required String reason,
    required bool bypassFlag,
  }) async {
    await _computeLock.synchronized(
      () async => _computeAndPersist(
        reason: reason,
        bypassFlag: bypassFlag,
      ),
    );
  }

  Future<void> _computeAndPersist({
    required String reason,
    required bool bypassFlag,
  }) async {
    if (!bypassFlag && !isEnabled) {
      _logger.info(
        "Wrapped flag disabled; skipping compute for $_kWrappedYear ($reason)",
      );
      return;
    }

    _logger.info("Starting Wrapped compute ($reason) for $_kWrappedYear");
    try {
      final WrappedResult result =
          await WrappedEngine.compute(year: _kWrappedYear);
      await _cacheService.write(result: result);
      updateResult(result);
      _logger.info("Wrapped compute completed ($reason)");
    } catch (error, stackTrace) {
      _logger.severe("Wrapped compute failed ($reason)", error, stackTrace);
    }
  }

  void updateResult(WrappedResult? result) {
    if (result == null || result.cards.isEmpty) {
      unawaited(localSettings.setWrapped2025ResumeIndex(0));
      final bool isComplete = localSettings.wrapped2025Complete();
      _state.value = WrappedEntryState(
        result: null,
        resumeIndex: 0,
        isComplete: isComplete,
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

  void markComplete() {
    if (!state.hasResult) {
      return;
    }

    final bool wasComplete = localSettings.wrapped2025Complete();
    if (!state.isComplete) {
      if (!wasComplete) {
        unawaited(localSettings.setWrapped2025Complete());
      }
      _state.value = WrappedEntryState(
        result: state.result,
        resumeIndex: state.resumeIndex,
        isComplete: true,
      );
    } else if (!wasComplete) {
      // Keep storage in sync if state already reflects completion.
      unawaited(localSettings.setWrapped2025Complete());
    }
  }
}
