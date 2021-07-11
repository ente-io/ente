import 'dart:async';

import 'package:flutter/material.dart';
import 'package:loading_animations/loading_animations.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/sync_status_update_event.dart';
import 'package:photos/services/local_sync_service.dart';
import 'package:photos/ui/backup_folder_selection_page.dart';
import 'package:photos/utils/navigation_util.dart';

class LoadingPhotosWidget extends StatefulWidget {
  const LoadingPhotosWidget({Key key}) : super(key: key);

  @override
  _LoadingPhotosWidgetState createState() => _LoadingPhotosWidgetState();
}

class _LoadingPhotosWidgetState extends State<LoadingPhotosWidget> {
  StreamSubscription<SyncStatusUpdate> _firstImportEvent;
  int _currentPage = 0;
  PageController _pageController = PageController(
    initialPage: 0,
  );
  final List<String> _messages = [
    "web.ente.io has a slick uploader",
    "we have preserved over 100,000 files so far",
    "all our apps are open source",
    "our encryption protocols have been reviewed by engineers at Google, Apple, Amazon, and Facebook",
    "you can share files and folders with your loved ones, end-to-end encrypted",
    "our mobile apps run in the background to encrypt and backup new photos you take",
    "we use Xchacha20Poly1305 to safely encrypt your data",
    "one of our data centers is in a fall out shelter 25m underground",
  ];

  @override
  void initState() {
    super.initState();
    _firstImportEvent =
        Bus.instance.on<SyncStatusUpdate>().listen((event) async {
      if (mounted &&
          event.status == SyncStatus.completed_first_gallery_import) {
        if (LocalSyncService.instance.hasGrantedLimitedPermissions()) {
          // Do nothing, let HomeWidget refresh
        } else {
          routeToPage(context, BackupFolderSelectionPage(true));
        }
      }
    });

    Timer.periodic(Duration(seconds: 5), (Timer timer) {
      if (!mounted) {
        return;
      }
      if (_currentPage < _messages.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      _pageController.animateToPage(
        _currentPage,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    });
  }

  @override
  void dispose() {
    _firstImportEvent.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            LoadingBouncingGrid.square(
              inverted: true,
              backgroundColor: Theme.of(context).buttonColor,
              size: 64,
            ),
            Padding(padding: const EdgeInsets.all(20.0)),
            Text(
              "loading your gallery...",
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            Padding(padding: EdgeInsets.all(10)),
            Text(
              "this might take upto 30 seconds 🐣",
              style: TextStyle(color: Colors.white.withOpacity(0.3)),
            ),
            Padding(padding: const EdgeInsets.all(70)),
            Text(
              "did you know?",
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).buttonColor,
              ),
            ),
            Padding(padding: EdgeInsets.all(8)),
            Container(
              height: 80,
              child: PageView.builder(
                scrollDirection: Axis.vertical,
                controller: _pageController,
                itemBuilder: (context, index) {
                  return _getMessage(_messages[index]);
                },
                itemCount: _messages.length,
                physics: NeverScrollableScrollPhysics(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getMessage(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          height: 1.5,
        ),
      ),
    );
  }
}
