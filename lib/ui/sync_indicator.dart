import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/photo_upload_event.dart';
import 'package:photos/services/sync_service.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class SyncIndicator extends StatefulWidget {
  final RefreshController refreshController;

  const SyncIndicator(this.refreshController, {Key key}) : super(key: key);

  @override
  _SyncIndicatorState createState() => _SyncIndicatorState();
}

class _SyncIndicatorState extends State<SyncIndicator> {
  PhotoUploadEvent _event;
  StreamSubscription<PhotoUploadEvent> _subscription;
  String _completeText = "Sync completed.";

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
      completeText: _completeText,
      failedText: "Sync unsuccessful.",
      completeDuration: const Duration(milliseconds: 1000),
      refreshStyle: RefreshStyle.UnFollow,
      refreshingIcon: Container(
        width: 24,
        height: 24,
        child: GestureDetector(
          onTap: () {
            AlertDialog alert = AlertDialog(
              title: Text("Pause?"),
              content: Text(
                  "Are you sure that you want to pause backing up your memories?"),
              actions: [
                FlatButton(
                  child: Text("NO"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                FlatButton(
                  child: Text("YES"),
                  onPressed: () {
                    Navigator.of(context).pop();
                    SyncService.instance.stopSync();
                    _completeText = "Sync stopped.";
                    setState(() {});
                    widget.refreshController.refreshCompleted();
                  },
                ),
              ],
            );

            showDialog(
              context: context,
              builder: (BuildContext context) {
                return alert;
              },
            );
          },
          child: Stack(
            children: [
              Icon(
                Icons.pause_circle_outline,
                size: 24,
                color: Colors.pink,
              ),
              CircularProgressIndicator(strokeWidth: 2),
            ],
          ),
        ),
      ),
    );
  }

  String _getRefreshingText() {
    if (_event == null) {
      return "Syncing...";
    } else {
      var s;
      if (_event.hasError) {
        widget.refreshController.refreshFailed();
        s = "Upload failed.";
      } else if (_event.wasStopped) {
        s = "Sync stopped.";
      } else {
        s = _event.completed.toString() +
            "/" +
            _event.total.toString() +
            " memories preserved";
      }
      _event = null;
      return s;
    }
  }
}
