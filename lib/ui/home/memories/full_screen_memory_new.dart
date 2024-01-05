import "dart:io";

import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:photos/core/configuration.dart";
import "package:photos/models/memory.dart";
import "package:photos/ui/actions/file/file_actions.dart";
import "package:photos/ui/viewer/file/file_widget.dart";
import "package:photos/ui/viewer/file_details/favorite_widget.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/share_util.dart";

class FullScreenMemoryDataUpdater extends StatefulWidget {
  final List<Memory> memories;
  final int initialIndex;
  final Widget child;
  const FullScreenMemoryDataUpdater({
    required this.memories,
    required this.initialIndex,
    required this.child,
    super.key,
  });

  @override
  State<FullScreenMemoryDataUpdater> createState() =>
      _FullScreenMemoryDataUpdaterState();
}

class _FullScreenMemoryDataUpdaterState
    extends State<FullScreenMemoryDataUpdater> {
  late ValueNotifier<int> indexNotifier;

  @override
  void initState() {
    super.initState();
    indexNotifier = ValueNotifier(widget.initialIndex);
  }

  @override
  void dispose() {
    indexNotifier.dispose();
    super.dispose();
  }

  void removeCurrentMemory() {
    setState(() {
      widget.memories.removeAt(indexNotifier.value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FullScreenMemoryData(
      memories: widget.memories,
      indexNotifier: indexNotifier,
      removeCurrentMemory: removeCurrentMemory,
      child: widget.child,
    );
  }
}

class FullScreenMemoryData extends InheritedWidget {
  final List<Memory> memories;
  final ValueNotifier<int> indexNotifier;
  final VoidCallback removeCurrentMemory;

  const FullScreenMemoryData({
    required this.memories,
    required this.indexNotifier,
    required this.removeCurrentMemory,
    required Widget child,
    Key? key,
  }) : super(child: child, key: key);

  static FullScreenMemoryData? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FullScreenMemoryData>();
  }

  @override
  bool updateShouldNotify(FullScreenMemoryData oldWidget) {
    // Checking oldWidget.memories.length != memories.length here doesn't work
    //because the old widget and new widget reference the same memories list.
    return true;
  }
}

class FullScreenMemoryNew extends StatefulWidget {
  final String title;
  final int initialIndex;
  const FullScreenMemoryNew(
    this.title,
    this.initialIndex, {
    super.key,
  });

  @override
  State<FullScreenMemoryNew> createState() => _FullScreenMemoryNewState();
}

class _FullScreenMemoryNewState extends State<FullScreenMemoryNew> {
  PageController? _pageController;
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inheritedData = FullScreenMemoryData.of(context)!;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(),
      body: PageView.builder(
        controller: _pageController ??= PageController(
          initialPage: widget.initialIndex,
        ),
        itemBuilder: (context, index) {
          if (index < inheritedData.memories.length - 1) {
            final nextFile = inheritedData.memories[index + 1].file;
            preloadThumbnail(nextFile);
            preloadFile(nextFile);
          }
          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              FileWidget(
                inheritedData.memories[index].file,
                autoPlay: false,
                tagPrefix: "memories",
                backgroundDecoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
              ),
              BottomIcons(index),
              Padding(
                padding: const EdgeInsets.all(120),
                child: Container(
                  color: Colors.black,
                  child: Text(
                    inheritedData.memories[index].file.generatedID.toString(),
                  ),
                ),
              ),
            ],
          );
        },
        onPageChanged: (index) {
          inheritedData.indexNotifier.value = index;
        },
        itemCount: inheritedData.memories.length,
      ),
    );
  }
}

class BottomIcons extends StatelessWidget {
  final int pageViewIndex;
  const BottomIcons(this.pageViewIndex, {super.key});

  @override
  Widget build(BuildContext context) {
    final inheritedData = FullScreenMemoryData.of(context)!;
    final currentFile = inheritedData.memories[pageViewIndex].file;

    final List<Widget> rowChildren = [
      IconButton(
        icon: Icon(
          Platform.isAndroid ? Icons.info_outline : CupertinoIcons.info,
          color: Colors.white, //same for both themes
        ),
        onPressed: () {
          showDetailsSheet(context, currentFile);
        },
      ),
    ];
    rowChildren.add(
      Padding(
        padding: const EdgeInsets.all(8),
        child: Text(currentFile.generatedID.toString()),
      ),
    );
    if (currentFile.ownerID == null ||
        (Configuration.instance.getUserID() ?? 0) == currentFile.ownerID) {
      rowChildren.addAll([
        IconButton(
          icon: Icon(
            Platform.isAndroid ? Icons.delete_outline : CupertinoIcons.delete,
            color: Colors.white, //same for both themes
          ),
          onPressed: () async {
            await showSingleFileDeleteSheet(
              context,
              inheritedData.memories[inheritedData.indexNotifier.value].file,
              onFileRemoved: (file) => {
                inheritedData.removeCurrentMemory.call(),
                if (inheritedData.memories.isEmpty)
                  {
                    Navigator.of(context).pop(),
                  },
              },
            );
          },
        ),
        SizedBox(
          height: 32,
          child: FavoriteWidget(currentFile),
        ),
      ]);
    }
    rowChildren.add(
      IconButton(
        icon: Icon(
          Icons.adaptive.share,
          color: Colors.white, //same for both themes
        ),
        onPressed: () {
          share(context, [currentFile]);
        },
      ),
    );

    return SafeArea(
      child: Container(
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: rowChildren,
        ),
      ),
    );
  }
}
