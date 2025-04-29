import "package:ente_cast/src/model.dart";
import "package:flutter/widgets.dart";

abstract class CastService {
  bool get isSupported;
  Future<List<(String, Object)>> searchDevices();
  Future<void> connectDevice(
    BuildContext context,
    Object device, {
    int? collectionID,
    // callback that take a map of string, dynamic
    void Function(Map<CastMessageType, Map<String, dynamic>>)? onMessage,
  });
  // returns a map of sessionID to deviceNames
  Map<String, String> getActiveSessions();

  Future<void> closeActiveCasts();
}
