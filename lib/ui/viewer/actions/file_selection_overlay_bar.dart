import 'package:flutter/material.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/device_collection.dart';
import 'package:photos/models/gallery_type.dart';
import 'package:photos/models/magic_metadata.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/collection_action_sheet.dart';
import 'package:photos/ui/components/bottom_action_bar/bottom_action_bar_widget.dart';
import 'package:photos/ui/components/icon_button_widget.dart';
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
    showDeleteOption = widget.galleryType.showDeleteIconOption();
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
      '$runtimeType building with ${widget.selectedFiles.files.length}',
    );
    final List<IconButtonWidget> iconsButton = [];
    final iconColor = getEnteColorScheme(context).blurStrokeBase;
    if (showDeleteOption) {
      iconsButton.add(
        IconButtonWidget(
          icon: Icons.delete_outlined,
          iconButtonType: IconButtonType.primary,
          iconColor: iconColor,
          onTap: () => showDeleteSheet(context, widget.selectedFiles),
        ),
      );
    }

    if (widget.galleryType.showUnArchiveOption()) {
      iconsButton.add(
        IconButtonWidget(
          icon: Icons.unarchive,
          iconButtonType: IconButtonType.primary,
          iconColor: iconColor,
          onTap: () => _onUnArchiveClick(),
        ),
      );
    }
    if (widget.galleryType.showUnHideOption()) {
      iconsButton.add(
        IconButtonWidget(
          icon: Icons.visibility_off_outlined,
          iconButtonType: IconButtonType.primary,
          iconColor: iconColor,
          onTap: () {
            showCollectionActionSheet(
              context,
              selectedFiles: widget.selectedFiles,
              actionType: CollectionActionType.unHide,
            );
          },
        ),
      );
    }
    if (widget.galleryType == GalleryType.trash) {
      iconsButton.add(
        IconButtonWidget(
          icon: Icons.delete_forever_outlined,
          iconButtonType: IconButtonType.primary,
          iconColor: iconColor,
          onTap: () async {
            if (await deleteFromTrash(
              context,
              widget.selectedFiles.files.toList(),
            )) {
              widget.selectedFiles.clearAll();
            }
          },
        ),
      );
    }
    iconsButton.add(
      IconButtonWidget(
        icon: Icons.adaptive.share_outlined,
        iconButtonType: IconButtonType.primary,
        iconColor: iconColor,
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

  _selectedFilesListener() {
    widget.selectedFiles.files.isNotEmpty
        ? _bottomPosition.value = 0.0
        : _bottomPosition.value = -150.0;
  }
}
