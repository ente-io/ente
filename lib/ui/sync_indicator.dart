import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photos/core/errors.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/sync_status_update_event.dart';
import 'package:photos/services/sync_service.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/ui/subscription_page.dart';

class SyncIndicator extends StatefulWidget {
  const SyncIndicator({Key key}) : super(key: key);

  @override
  _SyncIndicatorState createState() => _SyncIndicatorState();
}

class _SyncIndicatorState extends State<SyncIndicator> {
  static const kSleepDuration = Duration(milliseconds: 3000);
  SyncStatusUpdate _event;
  double _containerHeight = 48;
  StreamSubscription<SyncStatusUpdate> _subscription;
  static const _inProgressIcon = CircularProgressIndicator(strokeWidth: 2);

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
    bool isNotOutdatedEvent = _event != null &&
        (_event.status == SyncStatus.completed_backup ||
            _event.status == SyncStatus.completed_first_gallery_import) &&
        (DateTime.now().microsecondsSinceEpoch - _event.timestamp >
            kSleepDuration.inMicroseconds);
    if (_event == null || isNotOutdatedEvent) {
      return Container();
    }
    if (_event.status == SyncStatus.error) {
      return _getErrorWidget();
    }
    if (_event.status == SyncStatus.completed_first_gallery_import ||
        _event.status == SyncStatus.completed_backup) {
      Future.delayed(kSleepDuration, () {
        if (mounted) {
          setState(() {
            _containerHeight = 0;
          });
        }
      });
    } else {
      _containerHeight = 48;
    }
    final icon = _event.status == SyncStatus.completed_backup
        ? Icon(
            Icons.cloud_done_outlined,
            color: Theme.of(context).buttonColor,
          )
        : _inProgressIcon;
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
                  padding: EdgeInsets.all(2),
                  width: 22,
                  height: 22,
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

  Widget _getErrorWidget() {
    if (_event.error is NoActiveSubscriptionError) {
      return Container(
        margin: EdgeInsets.only(top: 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).buttonColor,
                ),
                Padding(padding: EdgeInsets.all(4)),
                Text("your subscription has expired"),
              ],
            ),
            Padding(padding: EdgeInsets.all(6)),
            Container(
              width: double.infinity,
              height: 64,
              padding: const EdgeInsets.fromLTRB(80, 0, 80, 0),
              child: button("subscribe", onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (BuildContext context) {
                      return SubscriptionPage();
                    },
                  ),
                );
              }),
            ),
            Padding(padding: EdgeInsets.all(8)),
          ],
        ),
      );
    } else if (_event.error is StorageLimitExceededError) {
      return Container(
        margin: EdgeInsets.only(top: 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).buttonColor,
                ),
                Padding(padding: EdgeInsets.all(4)),
                Text("storage limit exceeded"),
              ],
            ),
            Padding(padding: EdgeInsets.all(6)),
            Container(
              width: double.infinity,
              height: 64,
              padding: const EdgeInsets.fromLTRB(80, 0, 80, 0),
              child: button("upgrade", onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (BuildContext context) {
                      return SubscriptionPage();
                    },
                  ),
                );
              }),
            ),
            Padding(padding: EdgeInsets.all(8)),
          ],
        ),
      );
    } else {
      return Container(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).buttonColor,
                ),
                Padding(padding: EdgeInsets.all(4)),
                Text(_event.reason ?? "upload failed"),
              ],
            ),
            Padding(padding: EdgeInsets.all(8)),
          ],
        ),
      );
    }
  }

  String _getRefreshingText() {
    if (_event.status == SyncStatus.started_first_gallery_import ||
        _event.status == SyncStatus.completed_first_gallery_import) {
      return "loading gallery...";
    }
    if (_event.status == SyncStatus.applying_remote_diff) {
      return "syncing...";
    }
    if (_event.status == SyncStatus.preparing_for_upload) {
      return "encrypting backup...";
    }
    if (_event.status == SyncStatus.in_progress) {
      return _event.completed.toString() +
          "/" +
          _event.total.toString() +
          " memories preserved";
    }
    if (_event.status == SyncStatus.paused) {
      return _event.reason;
    }
    if (_event.status == SyncStatus.completed_backup) {
      if (_event.wasStopped) {
        return "sync stopped";
      } else {
        return "all memories preserved";
      }
    }
    // _event.status == SyncStatus.error
    return _event.reason ?? "upload failed";
  }
}
