import "package:ente_cast/ente_cast.dart";
import "package:flutter/widgets.dart";

class CastServiceImpl extends CastService {
  @override
  Future<void> connectDevice(BuildContext context, Object device) {
    throw UnimplementedError();
  }

  @override
  bool get isSupported => false;

  @override
  Future<List<(String, Object)>> searchDevices() {
    // TODO: implement searchDevices
    throw UnimplementedError();
  }
}
