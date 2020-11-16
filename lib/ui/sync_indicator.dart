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
        Future.delayed(Duration(milliseconds: 5000), () {
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
        margin: EdgeInsets.all(8),
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
                    width: 24,
                    height: 24,
                    child: icon,
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
        ),
      );
    }
    return Container();
  }

  String _getRefreshingText() {
    if (_event == null || _event.status == SyncStatus.not_started) {
      return "Syncing...";
    } else {
      var s;
      if (_event.status == SyncStatus.error) {
        s = "Upload failed.";
      } else if (_event.status == SyncStatus.completed) {
        if (_event.wasStopped) {
          s = "Sync stopped.";
        } else {
          s = "All memories preserved.";
        }
      } else if (_event.status == SyncStatus.paused) {
        s = _event.reason;
      } else {
        s = _latestCompletedCount.toString() +
            "/" +
            _event.total.toString() +
            " memories preserved";
      }
      return s;
    }
  }
}
