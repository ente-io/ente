import "package:ente_cast/ente_cast.dart";
import "package:flutter/widgets.dart";

class CastServiceImpl extends CastService {
  @override
  Future<void> connectDevice(
    BuildContext context,
    Object device, {
    int? collectionID,
    void Function(Map<CastMessageType, Map<String, dynamic>>)? onMessage,
  }) {
    throw UnimplementedError();
  }

  @override
  bool get isSupported => false;

  @override
  Future<List<(String, Object)>> searchDevices() {
    throw UnimplementedError();
  }

  @override
  Future<void> closeActiveCasts() {
    throw UnimplementedError();
  }

  @override
  Map<String, String> getActiveSessions() {
    throw UnimplementedError();
  }
}
