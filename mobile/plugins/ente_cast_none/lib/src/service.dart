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
    // TODO: implement searchDevices
    throw UnimplementedError();
  }

  @override
  Future<void> closeActiveCasts() {
    // TODO: implement closeActiveCasts
    throw UnimplementedError();
  }

  @override
  Map<String, String> getActiveSessions() {
    // TODO: implement getActiveSessions
    throw UnimplementedError();
  }
}
