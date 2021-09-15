import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/models/duplicate_files.dart';
import 'package:photos/models/file.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/ui/detail_page.dart';
import 'package:photos/ui/thumbnail_widget.dart';
import 'package:photos/utils/data_util.dart';
import 'package:photos/utils/navigation_util.dart';

class DeduplicatePage extends StatefulWidget {
  final List<DuplicateFiles> duplicates;

  DeduplicatePage(this.duplicates, {Key key}) : super(key: key);

  @override
  _DeduplicatePageState createState() => _DeduplicatePageState();
}

class _DeduplicatePageState extends State<DeduplicatePage> {
  final kDeleteIconOverlay = Container(
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

  Widget _getBody() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: ListView.builder(
            itemBuilder: (context, index) {
              if (index == 0) {
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
              return Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: _getGridView(widget.duplicates[index - 1], index - 1),
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
      onPressed: _selectedFiles.isEmpty ? null : () {},
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
            DetailPage(DetailPageConfiguration(
                files, null, files.indexOf(file), "deduplicate_")));
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
