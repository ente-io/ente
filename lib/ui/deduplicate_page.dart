import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/models/duplicate_files.dart';
import 'package:photos/models/file.dart';
import 'package:photos/ui/thumbnail_widget.dart';
import 'package:photos/utils/data_util.dart';

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

  final Set<File> selectedFiles = <File>{};

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
                  padding: EdgeInsets.fromLTRB(12, 4, 12, 4),
                  child: Column(
                    children: [
                      Text(
                        "we've clubbed the following files based on their sizes",
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
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: _getGridView(widget.duplicates[index - 1]),
              );
            },
            itemCount: widget.duplicates.length,
            shrinkWrap: true,
          ),
        ),
        Padding(padding: EdgeInsets.all(4)),
        Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            "delete",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _getGridView(DuplicateFiles duplicates) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
          child: Text(
            duplicates.files.length.toString() +
                " files, " +
                formatBytes(duplicates.size) +
                " each",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics:
              NeverScrollableScrollPhysics(), // to disable GridView's scrolling
          itemBuilder: (context, index) {
            return _buildFile(context, duplicates.files[index], index);
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
        if (selectedFiles.contains(file)) {
          selectedFiles.remove(file);
        } else {
          selectedFiles.add(file);
        }
        setState(() {});
      },
      onLongPress: () {
        HapticFeedback.lightImpact();
      },
      child: Container(
        margin: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          border: selectedFiles.contains(file)
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
          selectedFiles.contains(file) ? kDeleteIconOverlay : Container(),
        ]),
      ),
    );
  }
}
