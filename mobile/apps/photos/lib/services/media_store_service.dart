import "package:flutter/services.dart";

/// Android MediaStore permission helpers.
class MediaStoreService {
  static const _methodChannel = MethodChannel("io.ente.photos/media_store");

  /// Returns whether Ente can manage shared media without user confirmation.
  static Future<bool> canManageMedia() async {
    final result = await _methodChannel.invokeMethod<bool>("canManageMedia");
    if (result == null) {
      throw AssertionError("canManageMedia returned null");
    }
    return result;
  }
}
