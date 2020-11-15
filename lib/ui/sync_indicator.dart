import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/photo_upload_event.dart';
import 'package:photos/services/sync_service.dart';

class SyncIndicator extends StatefulWidget {
  const SyncIndicator({Key key}) : super(key: key);

  @override
  _SyncIndicatorState createState() => _SyncIndicatorState();
}

class _SyncIndicatorState extends State<SyncIndicator> {
  SyncStatusUpdate _event;
  int _latestCompletedCount = 0;
  StreamSubscription<SyncStatusUpdate> _subscription;

  @override
  void initState() {
    _subscription = Bus.instance.on<SyncStatusUpdate>().listen((event) {
      setState(() {
        _event = event;
        if (_event.status == SyncStatus.in_progress &&
            _event.completed > _latestCompletedCount) {
          _latestCompletedCount = _event.completed;
        }
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Configuration.instance.hasConfiguredAccount()) {
      if (SyncService.instance.isSyncInProgress()) {
        return Container(
          height: 48,
          width: double.infinity,
          margin: EdgeInsets.all(8),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 0, 0),
                    child: Text(_getRefreshingText()),
                  ),
                ],
              ),
              Padding(padding: EdgeInsets.all(4)),
              Divider(),
            ],
          ),
        );
      }
    }
    return Container();
  }

  String _getRefreshingText() {
    if (_event == null || _event.status == SyncStatus.not_started) {
      return "Syncing...";
    } else {
      var s;
      // TODO: Display errors softly
      if (_event.status == SyncStatus.error) {
        s = "Upload failed.";
      } else if (_event.status == SyncStatus.completed && _event.wasStopped) {
        s = "Sync stopped.";
      } else {
        s = _latestCompletedCount.toString() +
            "/" +
            _event.total.toString() +
            " memories preserved";
      }
      _event = null;
      return s;
    }
  }
}
