import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/events/user_details_changed_event.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/duplicate_files.dart';
import 'package:photos/models/file.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/deduplication_service.dart';
import 'package:photos/ui/viewer/file/detail_page.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';
import 'package:photos/ui/viewer/gallery/empty_state.dart';
import 'package:photos/utils/data_util.dart';
import 'package:photos/utils/delete_file_util.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:photos/utils/toast_util.dart';

class DeduplicatePage extends StatefulWidget {
  final List<DuplicateFiles> duplicates;

  const DeduplicatePage(this.duplicates, {Key? key}) : super(key: key);

  @override
  State<DeduplicatePage> createState() => _DeduplicatePageState();
}

class _DeduplicatePageState extends State<DeduplicatePage> {
  static const crossAxisCount = 4;
  static const crossAxisSpacing = 4.0;
  static const headerRowCount = 3;
  static final selectedOverlay = Container(
    color: Colors.black.withOpacity(0.4),
    child: const Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: EdgeInsets.only(right: 4, bottom: 4),
        child: Icon(
          Icons.check_circle,
          size: 24,
          color: Colors.white,
        ),
      ),
    ),
  );

  final Set<File> _selectedFiles = <File>{};
  final Map<int?, int> _fileSizeMap = {};
  late List<DuplicateFiles> _duplicates;
  bool _shouldClubByCaptureTime = true;
  bool _shouldClubByFileName = false;
  bool toastShown = false;

  SortKey sortKey = SortKey.size;

  @override
  void initState() {
    _duplicates =
        DeduplicationService.instance.clubDuplicatesByTime(widget.duplicates);
    _selectAllFilesButFirst();

    super.initState();
  }

  void _selectAllFilesButFirst() {
    _selectedFiles.clear();
    for (final duplicate in _duplicates) {
      for (int index = 0; index < duplicate.files.length; index++) {
        // Select all items but the first
        if (index != 0) {
          _selectedFiles.add(duplicate.files[index]);
        }
        // Maintain a map of fileID to fileSize for quick "space freed" computation
        _fileSizeMap[duplicate.files[index].uploadedFileID] = duplicate.size;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!toastShown) {
      toastShown = true;
      showShortToast(
        context,
        S.of(context).longpressOnAnItemToViewInFullscreen,
      );
    }
    _sortDuplicates();
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(S.of(context).deduplicateFiles),
        actions: <Widget>[
          PopupMenuButton(
            constraints: const BoxConstraints(minWidth: 180),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(8),
              ),
            ),
            onSelected: (dynamic value) {
              setState(() {
                _selectedFiles.clear();
              });
            },
            offset: const Offset(0, 50),
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: true,
                height: 32,
                child: Row(
                  children: [
                    const Icon(
                      Icons.remove_circle_outline,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 1),
                      child: Text(
                        S.of(context).deselectAll,
                        style: Theme.of(context)
                            .textTheme
                            .subtitle1!
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              )
            ],
          )
        ],
      ),
      body: _getBody(),
    );
  }

  void _sortDuplicates() {
    _duplicates.sort((first, second) {
      if (sortKey == SortKey.size) {
        final aSize = first.files.length * first.size;
        final bSize = second.files.length * second.size;
        return bSize - aSize;
      } else if (sortKey == SortKey.count) {
        return second.files.length - first.files.length;
      } else {
        return second.files.first.creationTime! -
            first.files.first.creationTime!;
      }
    });
  }

  Widget _getBody() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: ListView.builder(
            itemBuilder: (context, index) {
              if (index == 0) {
                return _getHeader();
              } else if (index == 1) {
                return _getClubbingConfig();
              } else if (index == 2) {
                if (_duplicates.isNotEmpty) {
                  return _getSortMenu(context);
                } else {
                  return const Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: EmptyState(),
                  );
                }
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _getGridView(
                  _duplicates[index - headerRowCount],
                  index - headerRowCount,
                ),
              );
            },
            itemCount: _duplicates.length + headerRowCount,
            shrinkWrap: true,
          ),
        ),
        _selectedFiles.isEmpty
            ? const SizedBox.shrink()
            : Column(
                children: [
                  _getDeleteButton(),
                  const SizedBox(height: crossAxisSpacing / 2),
                ],
              ),
      ],
    );
  }

  Padding _getHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).reviewDeduplicateItems,
            style: Theme.of(context).textTheme.subtitle2,
          ),
          const Padding(
            padding: EdgeInsets.all(12),
          ),
          const Divider(
            height: 0,
          ),
        ],
      ),
    );
  }

  Widget _getClubbingConfig() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Column(
        children: [
          CheckboxListTile(
            value: _shouldClubByFileName,
            onChanged: (value) {
              _shouldClubByFileName = value!;
              if (_shouldClubByFileName) {
                _shouldClubByCaptureTime = false;
              }
              _resetEntriesAndSelection();
              setState(() {});
            },
            title: Text(S.of(context).clubByFileName),
          ),
          CheckboxListTile(
            value: _shouldClubByCaptureTime,
            onChanged: (value) {
              _shouldClubByCaptureTime = value!;
              if (_shouldClubByCaptureTime) {
                _shouldClubByFileName = false;
              }
              _resetEntriesAndSelection();
              setState(() {});
            },
            title: Text(S.of(context).clubByCaptureTime),
          ),
          const Padding(
            padding: EdgeInsets.all(8),
          ),
          const Divider(
            height: 0,
          ),
          const Padding(
            padding: EdgeInsets.all(4),
          ),
        ],
      ),
    );
  }

  void _resetEntriesAndSelection() {
    _duplicates = widget.duplicates;
    if (_shouldClubByCaptureTime) {
      _duplicates =
          DeduplicationService.instance.clubDuplicatesByTime(_duplicates);
    }
    if (_shouldClubByFileName) {
      _duplicates =
          DeduplicationService.instance.clubDuplicatesByName(_duplicates);
    }
    _selectAllFilesButFirst();
  }

  Widget _getSortMenu(BuildContext context) {
    Text sortOptionText(SortKey key) {
      String text = key.toString();
      switch (key) {
        case SortKey.count:
          text = S.of(context).count;
          break;
        case SortKey.size:
          text = S.of(context).totalSize;
          break;
        case SortKey.time:
          text = S.of(context).time;
          break;
      }
      return Text(
        text,
        style: Theme.of(context).textTheme.subtitle1!.copyWith(
              fontSize: 14,
              color: Theme.of(context).iconTheme.color!.withOpacity(0.7),
            ),
      );
    }

    return Row(
      // h4ck to align PopupMenuItems to end
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(),
        PopupMenuButton(
          initialValue: sortKey.index,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                sortOptionText(sortKey),
                const Padding(padding: EdgeInsets.only(left: 4)),
                Icon(
                  Icons.sort,
                  color: Theme.of(context).colorScheme.iconColor,
                  size: 20,
                ),
              ],
            ),
          ),
          onSelected: (int index) {
            setState(() {
              sortKey = SortKey.values[index];
            });
          },
          itemBuilder: (context) {
            return List.generate(SortKey.values.length, (index) {
              return PopupMenuItem(
                value: index,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: sortOptionText(SortKey.values[index]),
                ),
              );
            });
          },
        ),
      ],
    );
  }

  Widget _getDeleteButton() {
    String text;
    if (_selectedFiles.length == 1) {
      text = "Delete 1 item";
    } else {
      text = "Delete " + _selectedFiles.length.toString() + " items";
    }
    int size = 0;
    for (final file in _selectedFiles) {
      size += _fileSizeMap[file.uploadedFileID]!;
    }
    return SizedBox(
      width: double.infinity,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: crossAxisSpacing / 2),
          child: TextButton(
            style: OutlinedButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.inverseBackgroundColor,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Padding(padding: EdgeInsets.all(4)),
                Text(
                  text,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.inverseTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Padding(padding: EdgeInsets.all(2)),
                Text(
                  formatBytes(size),
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .inverseTextColor
                        .withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                const Padding(padding: EdgeInsets.all(2)),
              ],
            ),
            onPressed: () async {
              await deleteFilesFromRemoteOnly(context, _selectedFiles.toList());
              Bus.instance.fire(UserDetailsChangedEvent());
              Navigator.of(context)
                  .pop(DeduplicationResult(_selectedFiles.length, size));
            },
          ),
        ),
      ),
    );
  }

  Widget _getGridView(DuplicateFiles duplicates, int itemIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 4, 4, 12),
          child: Text(
            duplicates.files.length.toString() +
                " files, " +
                formatBytes(duplicates.size) +
                " each",
            style: Theme.of(context).textTheme.subtitle2,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: crossAxisSpacing / 2),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            // to disable GridView's scrolling
            itemBuilder: (context, index) {
              return _buildFile(context, duplicates.files[index], itemIndex);
            },
            itemCount: duplicates.files.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: crossAxisSpacing,
              childAspectRatio: 0.75,
            ),
            padding: const EdgeInsets.all(0),
          ),
        ),
      ],
    );
  }

  Widget _buildFile(BuildContext context, File file, int index) {
    return GestureDetector(
      onTap: () {
        if (_selectedFiles.contains(file)) {
          _selectedFiles.remove(file);
        } else {
          _selectedFiles.add(file);
        }
        setState(() {});
      },
      onLongPress: () {
        HapticFeedback.lightImpact();
        final files = _duplicates[index].files;
        routeToPage(
          context,
          DetailPage(
            DetailPageConfiguration(
              files,
              null,
              files.indexOf(file),
              "deduplicate_",
              mode: DetailPageMode.minimalistic,
            ),
          ),
          forceCustomPageRoute: true,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            //the numerator will give the width of the screen excuding the whitespaces in the the grid row
            height: (MediaQuery.of(context).size.width -
                    (crossAxisSpacing * crossAxisCount)) /
                crossAxisCount,
            child: Stack(
              children: [
                Hero(
                  tag: "deduplicate_" + file.tag,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: ThumbnailWidget(
                      file,
                      diskLoadDeferDuration: thumbnailDiskLoadDeferDuration,
                      serverLoadDeferDuration: thumbnailServerLoadDeferDuration,
                      shouldShowLivePhotoOverlay: true,
                      key: Key("deduplicate_" + file.tag),
                    ),
                  ),
                ),
                _selectedFiles.contains(file)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: selectedOverlay,
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Text(
              CollectionsService.instance
                  .getCollectionByID(file.collectionID!)!
                  .displayName,
              style:
                  Theme.of(context).textTheme.caption!.copyWith(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

enum SortKey {
  size,
  count,
  time,
}

class DeduplicationResult {
  final int count;
  final int size;

  DeduplicationResult(this.count, this.size);
}
