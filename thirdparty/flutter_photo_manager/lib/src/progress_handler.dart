part of '../photo_manager.dart';

/// Only works in iOS.
class PMProgressHandler {
  /// Only works in iOS.
  PMProgressHandler() {
    final index = _index;
    _index = _index + 1;
    channelIndex = index;
    _channel = OptionalMethodChannel('top.kikt/photo_manager/progress/$index');
    _channel.setMethodCallHandler(this._onProgress);
  }

  static int _index = 0;

  StreamController<PMProgressState> _controller = StreamController.broadcast();

  /// Get the download progress and status of iCloud by monitoring the stream.
  Stream<PMProgressState> get stream => _controller.stream;

  /// For internal use of SDK, users should not use it.
  int channelIndex = 0;

  late final OptionalMethodChannel _channel;

  Future<dynamic> _onProgress(MethodCall call) async {
    switch (call.method) {
      case 'notifyProgress':
        final double progress = call.arguments['progress'];
        final int stateIndex = call.arguments['state'];
        final state = PMRequestState.values[stateIndex];
        _controller.add(PMProgressState(progress, state));
        break;
    }
    return;
  }
}

/// Status of progress for [PMProgressHandler].
class PMProgressState {
  /// Values range from 0.0 to 1.0.
  final double progress;

  /// See [PMRequestState]
  final PMRequestState state;

  PMProgressState(this.progress, this.state);
}

/// Current asset loading status
enum PMRequestState {
  prepare,
  loading,
  success,
  failed,
}
