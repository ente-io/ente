import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/photo_upload_event.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class SyncIndicator extends StatefulWidget {
  @override
  _SyncIndicatorState createState() => _SyncIndicatorState();
}

class _SyncIndicatorState extends State<SyncIndicator> {
  PhotoUploadEvent _event;
  StreamSubscription<PhotoUploadEvent> _subscription;

  @override
  void initState() {
    _subscription = Bus.instance.on<PhotoUploadEvent>().listen((event) {
      setState(() {
        _event = event;
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
    return ClassicHeader(
      idleText: "Pull down to sync.",
      refreshingText: _getRefreshingText(),
      releaseText: "Release to sync.",
      completeText: "Sync completed.",
      failedText: "Sync unsuccessful.",
      completeDuration: const Duration(milliseconds: 600),
      refreshStyle: RefreshStyle.UnFollow,
    );
  }

  String _getRefreshingText() {
    if (_event == null) {
      return "Syncing...";
    } else {
      var s;
      if (_event.hasError) {
        s = "Upload failed.";
      } else {
        s = "Uploading " +
            _event.completed.toString() +
            "/" +
            _event.total.toString();
      }
      _event = null;
      return s;
    }
  }
}
