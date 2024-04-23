import "package:flutter/widgets.dart";

abstract class CastService {
  bool get isSupported;
  Future<List<(String, Object)>> searchDevices();
  Future<void> connectDevice(BuildContext context, Object device);
}
