import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/user_details_changed_event.dart';
import 'package:photos/models/duplicate_files.dart';
import 'package:photos/models/file.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/ui/detail_page.dart';
import 'package:photos/ui/thumbnail_widget.dart';
import 'package:photos/utils/data_util.dart';
import 'package:photos/utils/delete_file_util.dart';
import 'package:photos/utils/navigation_util.dart';

class DeduplicatePage extends StatefulWidget {
  final List<DuplicateFiles> duplicates;

  DeduplicatePage(this.duplicates, {Key key}) : super(key: key);

  @override
  _DeduplicatePageState createState() => _DeduplicatePageState();
}

class _DeduplicatePageState extends State<DeduplicatePage> {
  static final kDeleteIconOverlay = Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.black.withOpacity(0.6),
        ],
        stops: const [0.75, 1],
      ),
    ),
    child: Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 4),
        child: Icon(
          Icons.delete_forever,
          size: 18,
          color: Colors.red[700],
        ),
      ),
    ),
  );

  final Set<File> _selectedFiles = <File>{};

  SortKey sortKey = SortKey.size;

  @override
  void initState() {
    super.initState();
    for (final duplicate in widget.duplicates) {
      for (int index = 0; index < duplicate.files.length; index++) {
        if (index != 0) {
          _selectedFiles.add(duplicate.files[index]);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _sortDuplicates();
    return Scaffold(
      appBar: AppBar(
        title: Hero(
          tag: "deduplicate",
          child: Material(
            type: MaterialType.transparency,
            child: Text(
              "deduplicate files",
              style: TextStyle(
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
      body: _getBody(),
    );
  }

  void _sortDuplicates() {
    widget.duplicates.sort((first, second) {
      if (sortKey == SortKey.size) {
        final aSize = first.files.length * first.size;
        final bSize = second.files.length * second.size;
        return bSize - aSize;
      } else if (sortKey == SortKey.count) {
        return second.files.length - first.files.length;
      } else {
        return second.files.first.creationTime - first.files.first.creationTime;
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
                return _getSortMenu();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: _getGridView(widget.duplicates[index - 2], index - 2),
              );
            },
            itemCount: widget.duplicates.length,
            shrinkWrap: true,
          ),
        ),
        Padding(padding: EdgeInsets.all(6)),
        _getDeleteButton(),
        Padding(padding: EdgeInsets.all(6)),
      ],
    );
  }

  Padding _getHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Text(
            "the following files were clubbed based on their sizes and creation times",
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              height: 1.2,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(4),
          ),
          Text(
            "please review and delete the items you believe are duplicates",
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getSortMenu() {
    Text sortOptionText(SortKey key) {
      String text = key.toString();
      switch (key) {
        case SortKey.count:
          text = "count";
          break;
        case SortKey.size:
          text = "total size";
          break;
        case SortKey.time:
          text = "time";
          break;
      }
      return Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.white.withOpacity(0.6),
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
          initialValue: sortKey?.index ?? 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                sortOptionText(sortKey),
                Padding(padding: EdgeInsets.only(left: 5.0)),
                Icon(
                  Icons.sort,
                  color: Theme.of(context).buttonColor,
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
                  alignment: Alignment.topRight,
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
    if (_selectedFiles.isEmpty) {
      text = "delete";
    } else if (_selectedFiles.length == 1) {
      text = "delete 1 item";
    } else {
      text = "delete " + _selectedFiles.length.toString() + " items";
    }
    return button(
      text,
      color: Colors.red[700],
      onPressed: _selectedFiles.isEmpty
          ? null
          : () async {
              await deleteFilesFromRemoteOnly(context, _selectedFiles.toList());
              Bus.instance.fire(UserDetailsChangedEvent());
              Navigator.of(context).pop(_selectedFiles.length);
            },
    );
  }

  Widget _getGridView(DuplicateFiles duplicates, int itemIndex) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 4, 4),
          child: Text(
            duplicates.files.length.toString() +
                " files, " +
                formatBytes(duplicates.size) +
                " each",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics:
              NeverScrollableScrollPhysics(), // to disable GridView's scrolling
          itemBuilder: (context, index) {
            return _buildFile(context, duplicates.files[index], itemIndex);
          },
          itemCount: duplicates.files.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
          ),
          padding: EdgeInsets.all(0),
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
        final files = widget.duplicates[index].files;
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
        );
      },
      child: Container(
        margin: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          border: _selectedFiles.contains(file)
              ? Border.all(
                  width: 3,
                  color: Colors.red[700],
                )
              : null,
        ),
        child: Stack(children: [
          Hero(
            tag: "deduplicate_" + file.tag(),
            child: ThumbnailWidget(
              file,
              diskLoadDeferDuration: kThumbnailDiskLoadDeferDuration,
              serverLoadDeferDuration: kThumbnailServerLoadDeferDuration,
              shouldShowLivePhotoOverlay: true,
              key: Key("deduplicate_" + file.tag()),
            ),
          ),
          _selectedFiles.contains(file) ? kDeleteIconOverlay : Container(),
        ]),
      ),
    );
  }
}

enum SortKey {
  size,
  count,
  time,
}
