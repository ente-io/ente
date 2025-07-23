import "dart:developer" as dev;

import "package:cast/cast.dart";
import "package:ente_cast/ente_cast.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";

class CastServiceImpl extends CastService {
  final String _appId = 'F5BCEC64';
  final String _pairRequestNamespace = 'urn:x-cast:pair-request';
  final Map<int, String> collectionIDToSessions = {};

  @override
  Future<void> connectDevice(
    BuildContext context,
    Object device, {
    int? collectionID,
    void Function(Map<CastMessageType, Map<String, dynamic>>)? onMessage,
  }) async {
    final CastDevice castDevice = device as CastDevice;
    final session = await CastSessionManager().startSession(castDevice);
    session.messageStream.listen((message) {
      if (message['type'] == "RECEIVER_STATUS") {
        dev.log(
          "got RECEIVER_STATUS, Send request to pair",
          name: "CastServiceImpl",
        );
        session.sendMessage(_pairRequestNamespace, {
          "collectionID": collectionID,
        });
      } else {
        if (onMessage != null && message.containsKey("code")) {
          onMessage(
            {
              CastMessageType.pairCode: message,
            },
          );
        } else {
          if (kDebugMode) {
            print('receive message: $message');
          }
        }
      }
    });

    session.stateStream.listen((state) {
      if (state == CastSessionState.connected) {
        debugPrint("Send request to pair");
        session.sendMessage(_pairRequestNamespace, {});
      } else if (state == CastSessionState.closed) {
        dev.log('Session closed', name: 'CastServiceImpl');
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
    return CastDiscoveryService()
        .search(timeout: const Duration(seconds: 7))
        .then((devices) {
      return devices.map((device) => (device.name, device)).toList();
    });
  }

  @override
  bool get isSupported => true;

  @override
  Future<void> closeActiveCasts() {
    final sessions = CastSessionManager().sessions;
    for (final session in sessions) {
      debugPrint("send close message for ${session.sessionId}");
      Future(() {
        session.sendMessage(CastSession.kNamespaceConnection, {
          'type': 'CLOSE',
        });
      }).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('sendMessage timed out after 5 seconds');
        },
      );
      debugPrint("close session ${session.sessionId}");
      session.close();
    }
    CastSessionManager().sessions.clear();
    return Future.value();
  }

  @override
  Map<String, String> getActiveSessions() {
    final sessions = CastSessionManager().sessions;
    final Map<String, String> result = {};
    for (final session in sessions) {
      if (session.state == CastSessionState.connected) {
        result[session.sessionId] = session.state.toString();
      }
    }
    return result;
  }
}
