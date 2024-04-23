import "package:cast/cast.dart";
import "package:ente_cast/ente_cast.dart";
import "package:flutter/material.dart";

class CastServiceImpl extends CastService {
  @override
  Future<void> connectDevice(BuildContext context, Object device) async {
    final CastDevice castDevice = device as CastDevice;
    final session = await CastSessionManager().startSession(castDevice);

    session.stateStream.listen((state) {
      if (state == CastSessionState.connected) {
        const snackBar = SnackBar(content: Text('Connected'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        session.sendMessage('urn:x-cast:pair-request', {});
      }
    });
    session.messageStream.listen((message) {
      print('receive message: $message');
    });

    session.sendMessage(CastSession.kNamespaceReceiver, {
      'type': 'LAUNCH',
      'appId': 'F5BCEC64', // set the appId of your app here
    });
    session.sendMessage('urn:x-cast:pair-request', {});
  }

  @override
  Future<List<Object>> searchDevices() {
    // TODO: implement searchDevices
    throw UnimplementedError();
  }

  @override
  bool get isSupported => true;
}
