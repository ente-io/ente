import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/sync_status_update_event.dart';
import 'package:photos/services/sync_service.dart';

class SyncIndicator extends StatefulWidget {
  const SyncIndicator({Key key}) : super(key: key);

  @override
  _SyncIndicatorState createState() => _SyncIndicatorState();
}

class _SyncIndicatorState extends State<SyncIndicator> {
  SyncStatusUpdate _event;
  double _containerHeight = 48;
  StreamSubscription<SyncStatusUpdate> _subscription;

  @override
  void initState() {
    _subscription = Bus.instance.on<SyncStatusUpdate>().listen((event) {
      setState(() {
        _event = event;
      });
    });
    _event = SyncService.instance.getLastSyncStatusEvent();
    super.initState();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Configuration.instance.hasConfiguredAccount() && _event != null) {
      if (_event.status == SyncStatus.completed) {
        Future.delayed(Duration(milliseconds: 3000), () {
          setState(() {
            _containerHeight = 0;
          });
        });
      } else {
        _containerHeight = 48;
      }
      var icon;
      if (_event.status == SyncStatus.completed) {
        icon = Icon(
          Icons.cloud_done_outlined,
          color: Theme.of(context).accentColor,
        );
      } else if (_event.status == SyncStatus.error) {
        icon = Icon(
          Icons.error_outline,
          color: Theme.of(context).accentColor,
        );
      } else {
        icon = CircularProgressIndicator(strokeWidth: 2);
      }
      return AnimatedContainer(
        duration: Duration(milliseconds: 300),
        height: _containerHeight,
        width: double.infinity,
        padding: EdgeInsets.all(8),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    child: icon,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 0, 0),
                    child: Text(_getRefreshingText()),
                  ),
                ],
              ),
              Padding(padding: EdgeInsets.all(4)),
              Divider(),
            ],
          ),
        ),
      );
    }
    return Container();
  }

  String _getRefreshingText() {
    if (_event == null ||
        _event.status == SyncStatus.applying_local_diff ||
        _event.status == SyncStatus.applying_remote_diff) {
      return "Syncing...";
    }
    if (_event.status == SyncStatus.preparing_for_upload) {
      return "Encrypting backup...";
    }
    if (_event.status == SyncStatus.in_progress) {
      return _event.completed.toString() +
          "/" +
          _event.total.toString() +
          " memories preserved.";
    }
    if (_event.status == SyncStatus.paused) {
      return _event.reason;
    }
    if (_event.status == SyncStatus.completed) {
      if (_event.wasStopped) {
        return "Sync stopped.";
      } else {
        return "All memories preserved.";
      }
    }
    // _event.status == SyncStatus.error)
    return "Upload failed.";
  }
}
