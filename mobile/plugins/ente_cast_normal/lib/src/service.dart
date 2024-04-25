import "dart:developer" as dev;

import "package:cast/cast.dart";
import "package:ente_cast/ente_cast.dart";
import "package:flutter/material.dart";

class CastServiceImpl extends CastService {
  final String _appId = 'F5BCEC64';
  final String _pairRequestNamespace = 'urn:x-cast:pair-request';
  final Map<String, CastDevice> sessionIDToDeviceID = {};

  @override
  Future<void> connectDevice(BuildContext context, Object device) async {
    final CastDevice castDevice = device as CastDevice;
    final session = await CastSessionManager().startSession(castDevice);
    session.messageStream.listen((message) {
      if (message['type'] == "RECEIVER_STATUS") {
        dev.log(
          "got RECEIVER_STATUS, Send request to pair",
          name: "CastServiceImpl",
        );
        session.sendMessage(_pairRequestNamespace, {});
      } else {
        print('receive message: $message');
      }
    });

    session.stateStream.listen((state) {
      if (state == CastSessionState.connected) {
        const snackBar = SnackBar(content: Text('Connected'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        sessionIDToDeviceID[session.sessionId] = castDevice;
        debugPrint("Send request to pair");
        session.sendMessage(_pairRequestNamespace, {});
      } else if (state == CastSessionState.closed) {
        dev.log('Session closed', name: 'CastServiceImpl');
        sessionIDToDeviceID.remove(session.sessionId);
      }
    });

    debugPrint("Send request to launch");
    session.sendMessage(CastSession.kNamespaceReceiver, {
      'type': 'LAUNCH',
      'appId': _appId, // set the appId of your app here
    });
    // session.sendMessage('urn:x-cast:pair-request', {});
  }

  @override
  Future<List<(String, Object)>> searchDevices() {
    return CastDiscoveryService().search().then((devices) {
      return devices.map((device) => (device.name, device)).toList();
    });
  }

  @override
  bool get isSupported => true;
}
