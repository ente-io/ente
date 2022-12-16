import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

import 'package:photos/core/configuration.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/device_collection.dart';
import 'package:photos/models/gallery_type.dart';
import 'package:photos/models/magic_metadata.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/ui/components/bottom_action_bar/bottom_action_bar_widget.dart';
import 'package:photos/ui/components/icon_button_widget.dart';
import 'package:photos/ui/create_collection_page.dart';
import 'package:photos/ui/viewer/actions/file_selection_actions_widget.dart';
import 'package:photos/utils/delete_file_util.dart';
import 'package:photos/utils/magic_util.dart';
import 'package:photos/utils/share_util.dart';

class FileSelectionOverlayBar extends StatefulWidget {
  final GalleryType galleryType;
  final SelectedFiles selectedFiles;
  final Collection? collection;
  final DeviceCollection? deviceCollection;

  const FileSelectionOverlayBar(
    this.galleryType,
    this.selectedFiles, {
    this.collection,
    this.deviceCollection,
    Key? key,
  }) : super(key: key);

  @override
  State<FileSelectionOverlayBar> createState() =>
      _FileSelectionOverlayBarState();
}

class _FileSelectionOverlayBarState extends State<FileSelectionOverlayBar> {
  final GlobalKey shareButtonKey = GlobalKey();
  final ValueNotifier<double> _bottomPosition = ValueNotifier(-150.0);
  late bool showDeleteOption;

  @override
  void initState() {
    showDeleteOption = (widget.galleryType == GalleryType.homepage ||
        widget.galleryType == GalleryType.ownedCollection);
    widget.selectedFiles.addListener(_selectedFilesListener);
    super.initState();
  }

  @override
  void dispose() {
    widget.selectedFiles.removeListener(_selectedFilesListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        '$runtimeType building with ${widget.selectedFiles.files.length}');
    final List<IconButtonWidget> iconsButton = [];
    if (showDeleteOption) {
      iconsButton.add(
        IconButtonWidget(
          icon: Icons.delete_outlined,
          iconButtonType: IconButtonType.primary,
          onTap: () => showDeleteSheet(context, widget.selectedFiles),
        ),
      );
    }

    if (widget.galleryType.showUnArchiveOption()) {
      iconsButton.add(
        IconButtonWidget(
          icon: Icons.unarchive,
          iconButtonType: IconButtonType.primary,
          onTap: () => _onUnArchiveClick(),
        ),
      );
    }
    if (widget.galleryType.showUnHideOption()) {
      iconsButton.add(
        IconButtonWidget(
          icon: Icons.visibility_off_outlined,
          iconButtonType: IconButtonType.primary,
          onTap: () => _selectionCollectionForAction(
            CollectionActionType.unHide,
          ),
        ),
      );
    }
    iconsButton.add(
      IconButtonWidget(
        icon: Icons.ios_share_outlined,
        iconButtonType: IconButtonType.primary,
        onTap: () => shareSelected(
          context,
          shareButtonKey,
          widget.selectedFiles.files,
        ),
      ),
    );
    return ValueListenableBuilder(
      valueListenable: _bottomPosition,
      builder: (context, value, child) {
        return AnimatedPositioned(
          curve: Curves.easeInOutExpo,
          bottom: _bottomPosition.value,
          right: 0,
          left: 0,
          duration: const Duration(milliseconds: 400),
          child: BottomActionBarWidget(
            selectedFiles: widget.selectedFiles,
            hasSmallerBottomPadding: true,
            type: widget.galleryType,
            isCollaborator: _isCollaborator(),
            expandedMenu: FileSelectionActionWidget(
              widget.galleryType,
              widget.selectedFiles,
              collection: widget.collection,
            ),
            text: widget.selectedFiles.files.length.toString() + ' selected',
            onCancel: () {
              if (widget.selectedFiles.files.isNotEmpty) {
                widget.selectedFiles.clearAll();
              }
            },
            iconButtons: iconsButton,
          ),
        );
      },
    );
  }

  Future<void> _onUnArchiveClick() async {
    await changeVisibility(
      context,
      widget.selectedFiles.files.toList(),
      visibilityVisible,
    );
    widget.selectedFiles.clearAll();
  }

  Future<Object?> _selectionCollectionForAction(
    CollectionActionType type,
  ) async {
    return Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.bottomToTop,
        child: CreateCollectionPage(
          widget.selectedFiles,
          null,
          actionType: type,
        ),
      ),
    );
  }

  _selectedFilesListener() {
    widget.selectedFiles.files.isNotEmpty
        ? _bottomPosition.value = 0.0
        : _bottomPosition.value = -150.0;
  }

  bool _isCollaborator() {
    if (widget.collection == null) {
      return false;
    }
    if (widget.galleryType == GalleryType.ownedCollection) {
      return false;
    }
    final userID = Configuration.instance.getUserID();
    for (final user in widget.collection!.getSharees()) {
      if (user.id == userID) {
        return user.isCollaborator;
      }
    }
    return false;
  }
}
