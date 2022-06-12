import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/sync_status_update_event.dart';
import 'package:photos/services/sync_service.dart';
import 'package:photos/ui/header/header_error_widget.dart';

const double kContainerHeight = 48;

class StatusBarWidget extends StatefulWidget {
  const StatusBarWidget({Key key}) : super(key: key);

  @override
  State<StatusBarWidget> createState() => _StatusBarWidgetState();
}

class _StatusBarWidgetState extends State<StatusBarWidget> {
  StreamSubscription<SyncStatusUpdate> _subscription;
  bool _showStatus = false;

  @override
  void initState() {
    _subscription = Bus.instance.on<SyncStatusUpdate>().listen((event) {
      if (event.status == SyncStatus.completed_first_gallery_import ||
          event.status == SyncStatus.completed_backup) {
        Future.delayed(Duration(milliseconds: 2000), () {
          if (mounted) {
            setState(() {
              _showStatus = false;
            });
          }
        });
      } else {
        setState(() {
          _showStatus = true;
        });
      }
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
    return Stack(
      children: [
        AnimatedOpacity(
          opacity: _showStatus ? 0 : 1,
          duration: Duration(milliseconds: 1000),
          child: StatusBarBrandingWidget(),
        ),
        AnimatedOpacity(
          opacity: _showStatus ? 1 : 0,
          duration: Duration(milliseconds: 1000),
          child: SyncStatusWidget(),
        ),
      ],
    );
  }
}

class SyncStatusWidget extends StatefulWidget {
  const SyncStatusWidget({Key key}) : super(key: key);

  @override
  _SyncStatusWidgetState createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget> {
  static const Duration kSleepDuration = Duration(milliseconds: 3000);
  static const _inProgressIcon = CircularProgressIndicator(
    strokeWidth: 2,
    valueColor: AlwaysStoppedAnimation<Color>(Color.fromRGBO(45, 194, 98, 1.0)),
  );

  SyncStatusUpdate _event;
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
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        height: kContainerHeight,
        color: Colors.transparent,
        child: _getContents(),
      ),
    );
  }

  Widget _getContents() {
    bool isNotOutdatedEvent = _event != null &&
        (_event.status == SyncStatus.completed_backup ||
            _event.status == SyncStatus.completed_first_gallery_import) &&
        (DateTime.now().microsecondsSinceEpoch - _event.timestamp >
            kSleepDuration.inMicroseconds);
    if (_event == null || isNotOutdatedEvent) {
      return Container();
    }
    if (_event.status == SyncStatus.error) {
      return HeaderErrorWidget(error: _event.error);
    }
    if (_event.status == SyncStatus.completed_backup) {
      return SyncStatusCompletedWidget();
    }
    return Container(
      height: kContainerHeight,
      width: double.infinity,
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
                  padding: EdgeInsets.all(2),
                  width: 22,
                  height: 22,
                  child: _inProgressIcon,
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

  String _getRefreshingText() {
    if (_event.status == SyncStatus.started_first_gallery_import ||
        _event.status == SyncStatus.completed_first_gallery_import) {
      return "Loading gallery...";
    }
    if (_event.status == SyncStatus.applying_remote_diff) {
      return "Syncing...";
    }
    if (_event.status == SyncStatus.preparing_for_upload) {
      return "Encrypting backup...";
    }
    if (_event.status == SyncStatus.in_progress) {
      return _event.completed.toString() +
          "/" +
          _event.total.toString() +
          " Memories preserved";
    }
    if (_event.status == SyncStatus.paused) {
      return _event.reason;
    }
    if (_event.status == SyncStatus.completed_backup) {
      if (_event.wasStopped) {
        return "Sync stopped";
      } else {
        return "All memories preserved";
      }
    }
    // _event.status == SyncStatus.error
    return _event.reason ?? "Upload failed";
  }
}

class StatusBarBrandingWidget extends StatelessWidget {
  const StatusBarBrandingWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kContainerHeight,
      padding: EdgeInsets.only(left: 12),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text(
          "ente",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
            fontSize: 28,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class SyncStatusCompletedWidget extends StatelessWidget {
  const SyncStatusCompletedWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(2),
              width: 22,
              height: 22,
              child: Icon(
                Icons.cloud_done_outlined,
                color: Theme.of(context).buttonColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 0, 0),
              child: Text("All memories preserved"),
            ),
          ],
        ),
        Padding(padding: EdgeInsets.all(4)),
        Divider(),
      ],
    );
  }
}
