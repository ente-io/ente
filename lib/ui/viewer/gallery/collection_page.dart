// @dart=2.9

import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/models/file_load_result.dart';
import 'package:photos/models/gallery_type.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/ignored_files_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/blur_menu_item_widget.dart';
import 'package:photos/ui/components/bottom_action_bar/bottom_action_bar_widget.dart';
import 'package:photos/ui/components/bottom_action_bar/expanded_menu_widget.dart';
import 'package:photos/ui/components/icon_button_widget.dart';
import 'package:photos/ui/viewer/gallery/empty_state.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';
import 'package:photos/ui/viewer/gallery/gallery_app_bar_widget.dart';
import 'package:photos/utils/delete_file_util.dart';
import 'package:photos/utils/share_util.dart';

class CollectionPage extends StatefulWidget {
  final CollectionWithThumbnail c;
  final String tagPrefix;
  final GalleryType appBarType;
  final bool hasVerifiedLock;

  const CollectionPage(
    this.c, {
    this.tagPrefix = "collection",
    this.appBarType = GalleryType.ownedCollection,
    this.hasVerifiedLock = false,
    Key key,
  }) : super(key: key);

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  final _selectedFiles = SelectedFiles();
  final GlobalKey shareButtonKey = GlobalKey();

  final ValueNotifier<double> _bottomPosition = ValueNotifier(-150.0);
  @override
  void initState() {
    _selectedFiles.addListener(_selectedFilesListener);
    super.initState();
  }

  @override
  void dispose() {
    _selectedFiles.removeListener(_selectedFilesListener);
    super.dispose();
  }

  @override
  Widget build(Object context) {
    if (widget.hasVerifiedLock == false && widget.c.collection.isHidden()) {
      return const EmptyState();
    }
    final initialFiles =
        widget.c.thumbnail != null ? [widget.c.thumbnail] : null;
    final gallery = Gallery(
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) async {
        final FileLoadResult result =
            await FilesDB.instance.getFilesInCollection(
          widget.c.collection.id,
          creationStartTime,
          creationEndTime,
          limit: limit,
          asc: asc,
        );
        // hide ignored files from home page UI
        final ignoredIDs = await IgnoredFilesService.instance.ignoredIDs;
        result.files.removeWhere(
          (f) =>
              f.uploadedFileID == null &&
              IgnoredFilesService.instance.shouldSkipUpload(ignoredIDs, f),
        );
        return result;
      },
      reloadEvent: Bus.instance
          .on<CollectionUpdatedEvent>()
          .where((event) => event.collectionID == widget.c.collection.id),
      removalEventTypes: const {
        EventType.deletedFromRemote,
        EventType.deletedFromEverywhere,
        EventType.hide,
      },
      tagPrefix: widget.tagPrefix,
      selectedFiles: _selectedFiles,
      initialFiles: initialFiles,
      albumName: widget.c.collection.name,
    );
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: GalleryAppBarWidget(
          widget.appBarType,
          widget.c.collection.name,
          _selectedFiles,
          collection: widget.c.collection,
        ),
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          gallery,
          // GalleryOverlayWidget(
          //   appBarType,
          //   _selectedFiles,
          //   collection: c.collection,
          // ),
          ValueListenableBuilder(
            valueListenable: _bottomPosition,
            builder: (context, value, child) {
              final colorScheme = getEnteColorScheme(context);
              return AnimatedPositioned(
                curve: Curves.easeInOutExpo,
                bottom: _bottomPosition.value,
                right: 0,
                left: 0,
                duration: const Duration(milliseconds: 400),
                child: BottomActionBarWidget(
                  selectedFiles: _selectedFiles,
                  expandedMenu: ExpandedMenuWidget(
                    items: [
                      [
                        BlurMenuItemWidget(
                          leadingIcon: Icons.add_outlined,
                          labelText: "One",
                          menuItemColor: colorScheme.fillFaint,
                        ),
                      ],
                    ],
                  ),
                  text: _selectedFiles.files.length.toString() + ' selected',
                  onCancel: () {
                    if (_selectedFiles.files.isNotEmpty) {
                      _selectedFiles.clearAll();
                    }
                  },
                  iconButtons: [
                    IconButtonWidget(
                      icon: Icons.delete_outlined,
                      iconButtonType: IconButtonType.primary,
                      onTap: () => showDeleteSheet(context, _selectedFiles),
                    ),
                    IconButtonWidget(
                      icon: Icons.ios_share_outlined,
                      iconButtonType: IconButtonType.primary,
                      onTap: () => shareSelected(
                        context,
                        shareButtonKey,
                        _selectedFiles.files,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  _selectedFilesListener() {
    _selectedFiles.files.isNotEmpty
        ? _bottomPosition.value = 0.0
        : _bottomPosition.value = -150.0;
  }
}
