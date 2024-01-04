import "dart:io";

import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:photos/models/memory.dart";
import "package:photos/ui/actions/file/file_actions.dart";
import "package:photos/ui/viewer/file/file_widget.dart";

class FullScreenMemoryNew extends StatefulWidget {
  final String title;
  final List<Memory> memories;
  final int index;
  const FullScreenMemoryNew(this.title, this.memories, this.index, {super.key});

  @override
  State<FullScreenMemoryNew> createState() => _FullScreenMemoryNewState();
}

class _FullScreenMemoryNewState extends State<FullScreenMemoryNew> {
  late final ValueNotifier<int> _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = ValueNotifier(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(),
      body: PageView.builder(
        itemBuilder: (context, index) {
          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              FileWidget(
                widget.memories[index].file,
                autoPlay: false,
                tagPrefix: "memories",
                backgroundDecoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
              ),
              IconButton(
                icon: Icon(
                  Platform.isAndroid
                      ? Icons.delete_outline
                      : CupertinoIcons.delete,
                  color: Colors.white, //same for both themes
                ),
                onPressed: () async {
                  await showSingleFileDeleteSheet(
                    context,
                    widget.memories[_currentIndex.value].file,
                    onFileRemoved: (file) =>
                        {onFileDeleted(widget.memories[_currentIndex.value])},
                  );
                },
              ),
            ],
          );
        },
        onPageChanged: (index) {
          _currentIndex.value = index;
        },
        itemCount: widget.memories.length,
      ),
    );
  }

  Future<void> onFileDeleted(Memory removedMemory) async {
    setState(() {
      widget.memories.remove(removedMemory);
    });
  }
}
