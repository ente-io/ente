import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/events/subscription_purchased_event.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/selected_files.dart';

enum GalleryOverlayType {
  homepage,
  archive,
  trash,
  local_folder,
  // indicator for gallery view of collections shared with the user
  shared_collection,
  owned_collection,
  search_results
}

class GalleryOverflowWidget extends StatefulWidget {
  final GalleryOverlayType type;
  final String title;
  final SelectedFiles selectedFiles;
  final String path;
  final Collection collection;

  GalleryOverflowWidget(
    this.type,
    this.title,
    this.selectedFiles, {
    this.path,
    this.collection,
  });

  @override
  _GalleryOverflowWidgetState createState() => _GalleryOverflowWidgetState();
}

class _GalleryOverflowWidgetState extends State<GalleryOverflowWidget> {
  final _logger = Logger("GalleryOverlay");
  StreamSubscription _userAuthEventSubscription;
  Function() _selectedFilesListener;
  String _appBarTitle;
  final GlobalKey shareButtonKey = GlobalKey();
  @override
  void initState() {
    _selectedFilesListener = () {
      setState(() {});
    };
    widget.selectedFiles.addListener(_selectedFilesListener);
    _userAuthEventSubscription =
        Bus.instance.on<SubscriptionPurchasedEvent>().listen((event) {
      setState(() {});
    });
    _appBarTitle = widget.title;
    super.initState();
  }

  @override
  void dispose() {
    _userAuthEventSubscription.cancel();
    widget.selectedFiles.removeListener(_selectedFilesListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedFiles.files.isNotEmpty) {
      return Container(
        height: 108,
        color: Colors.transparent,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                  child: Container(
                    color: Theme.of(context)
                        .colorScheme
                        .frostyBlurBackdropFilterColor
                        .withOpacity(0.6),
                    height: 46,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 32,
              width: 86,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color:
                      Theme.of(context).colorScheme.cancelSelectedButtonColor),
            ),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
