part of '../photo_manager.dart';

/// manage photo changes
///
/// 当相册发生变化时, 通知
class _NotifyManager {
  static const MethodChannel _channel =
      const MethodChannel("top.kikt/photo_manager/notify");

  /// callbacks
  var notifyCallback = <ValueChanged<MethodCall>>[];

  /// add callback
  void addCallback(ValueChanged<MethodCall> callback) =>
      notifyCallback.add(callback);

  /// remove callback
  void removeCallback(ValueChanged<MethodCall> callback) =>
      notifyCallback.remove(callback);

  /// start handle notify
  void startHandleNotify() {
    _channel.setMethodCallHandler(_notify);
    _plugin.notifyChange(start: true);
  }

  /// stop handle notify
  void stopHandleNotify() {
    _plugin.notifyChange(start: false);
    _channel.setMethodCallHandler(null);
  }

  Future<dynamic> _notify(MethodCall call) async {
    if (call.method == "change") {
      print(call.arguments);
      _onChange(call);
    } else if (call.method == "setAndroidQExperimental") {
      // PhotoManager.androidQExperimental = call.arguments["open"];
    }
    return 1;
  }

  Future<dynamic> _onChange(MethodCall methodCall) async {
    notifyCallback.forEach((callback) => callback.call(methodCall));
  }
}
