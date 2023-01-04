

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/events/local_import_progress.dart';
import 'package:photos/events/sync_status_update_event.dart';
import 'package:photos/services/local_sync_service.dart';
import 'package:photos/ui/backup_folder_selection_page.dart';
import 'package:photos/ui/common/bottom_shadow.dart';
import 'package:photos/utils/navigation_util.dart';

class LoadingPhotosWidget extends StatefulWidget {
  const LoadingPhotosWidget({Key? key}) : super(key: key);

  @override
  State<LoadingPhotosWidget> createState() => _LoadingPhotosWidgetState();
}

class _LoadingPhotosWidgetState extends State<LoadingPhotosWidget> {
  late StreamSubscription<SyncStatusUpdate> _firstImportEvent;
  late StreamSubscription<LocalImportProgressEvent> _imprortProgressEvent;
  int _currentPage = 0;
  String _loadingMessage = "Loading your photos...";
  final PageController _pageController = PageController(
    initialPage: 0,
  );
  final List<String> _messages = [
    "You can share your plan with your family",
    "We have preserved over 5 million memories so far",
    "web.ente.io has a slick uploader",
    "All our apps are open source",
    "Our encryption protocols have been reviewed by engineers at Google, Apple, Amazon, and Facebook",
    "You can share links to your albums with your loved ones",
    "Our mobile apps run in the background to encrypt and backup new photos you take",
    "We use Xchacha20Poly1305 to safely encrypt your data",
    "One of our data centers is in an underground fall out shelter in Paris",
  ];

  @override
  void initState() {
    super.initState();
    _firstImportEvent =
        Bus.instance.on<SyncStatusUpdate>().listen((event) async {
      if (mounted && event.status == SyncStatus.completedFirstGalleryImport) {
        if (LocalSyncService.instance.hasGrantedLimitedPermissions()) {
          // Do nothing, let HomeWidget refresh
        } else {
          routeToPage(
            context,
            const BackupFolderSelectionPage(
              isOnboarding: true,
              buttonText: "Start backup",
            ),
          );
        }
      }
    });
    _imprortProgressEvent =
        Bus.instance.on<LocalImportProgressEvent>().listen((event) {
      if (Platform.isAndroid) {
        _loadingMessage = 'Processing ${event.folderName}...';
        if (mounted) {
          setState(() {});
        }
      }
    });
    Timer.periodic(const Duration(seconds: 5), (Timer timer) {
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
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    });
  }

  @override
  void dispose() {
    _firstImportEvent.cancel();
    _imprortProgressEvent.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLightMode =
        MediaQuery.of(context).platformBrightness == Brightness.light;
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    isLightMode
                        ? Image.asset(
                            'assets/loading_photos_background.png',
                            color: Colors.white.withOpacity(0.5),
                            colorBlendMode: BlendMode.modulate,
                          )
                        : Image.asset(
                            'assets/loading_photos_background_dark.png',
                            color: Colors.white.withOpacity(0.25),
                            colorBlendMode: BlendMode.modulate,
                          ),
                    Column(
                      children: [
                        const SizedBox(height: 24),
                        Lottie.asset(
                          'assets/loadingGalleryLottie.json',
                          height: 400,
                        ),
                      ],
                    )
                  ],
                ),
                Text(
                  _loadingMessage,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.subTextColor,
                  ),
                ),
                const SizedBox(height: 54),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "Did you know?",
                          style: Theme.of(context).textTheme.headline6!.copyWith(
                                color: Theme.of(context).colorScheme.greenText,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    SizedBox(
                      height: 175,
                      child: Stack(
                        children: [
                          PageView.builder(
                            scrollDirection: Axis.vertical,
                            controller: _pageController,
                            itemBuilder: (context, index) {
                              return _getMessage(_messages[index]);
                            },
                            itemCount: _messages.length,
                            physics: const NeverScrollableScrollPhysics(),
                          ),
                          const Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: BottomShadowWidget(),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getMessage(String text) {
    return Text(
      text,
      textAlign: TextAlign.start,
      style: Theme.of(context)
          .textTheme
          .headline5!
          .copyWith(color: Theme.of(context).colorScheme.defaultTextColor),
    );
  }
}
