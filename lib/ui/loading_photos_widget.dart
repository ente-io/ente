import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/ente_theme_data.dart';
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
  // final int _currentPage = 0;
  // final PageController _pageController = PageController(
  //   initialPage: 0,
  // );

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
          routeToPage(
              context,
              BackupFolderSelectionPage(
                shouldSelectAll: true,
                buttonText: "Start backup",
              ));
        }
      }
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 56,
            ),
            Lottie.asset('assets/loadingGalleryLottie.json'),
            Text("Did you know?",
                style: Theme.of(context).textTheme.headline6.copyWith(
                    fontFamily: "Inter",
                    color: Theme.of(context)
                        .colorScheme
                        .defaultTextColor
                        .withOpacity(0.4))),
            SizedBox(
              height: 16,
            ),
            Text(
              "ente is amazing",
              style: Theme.of(context).textTheme.headline6.copyWith(
                  fontFamily: "Inter",
                  color: Theme.of(context).colorScheme.defaultTextColor),
            )
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
