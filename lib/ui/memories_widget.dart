import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/memory_service.dart';
import 'package:photos/models/memory.dart';
import 'package:photos/ui/thumbnail_widget.dart';

class MemoriesWidget extends StatefulWidget {
  MemoriesWidget({Key key}) : super(key: key);

  @override
  _MemoriesWidgetState createState() => _MemoriesWidgetState();
}

class _MemoriesWidgetState extends State<MemoriesWidget> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Memory>>(
      future: MemoryService.instance.getMemories(),
      builder: (context, snapshot) {
        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data.length == 0) {
          return Container();
        } else {
          return _buildMemories(snapshot.data);
        }
      },
    );
  }

  Widget _buildMemories(List<Memory> memories) {
    final collatedMemories = _collateMemories(memories);
    final memoryWidgets = List<Widget>();
    for (final memories in collatedMemories) {
      memoryWidgets.add(MemoryWidget(memories: memories));
    }
    return Row(children: memoryWidgets);
  }

  List<List<Memory>> _collateMemories(List<Memory> memories) {
    final yearlyMemories = List<Memory>();
    final collatedMemories = List<List<Memory>>();
    for (int index = 0; index < memories.length; index++) {
      if (index > 0 &&
          !_areMemoriesFromSameYear(memories[index - 1], memories[index])) {
        final collatedYearlyMemories = List<Memory>();
        collatedYearlyMemories.addAll(yearlyMemories);
        collatedMemories.add(collatedYearlyMemories);
        yearlyMemories.clear();
      }
      yearlyMemories.add(memories[index]);
    }
    if (yearlyMemories.isNotEmpty) {
      collatedMemories.add(yearlyMemories);
    }
    return collatedMemories;
  }

  bool _areMemoriesFromSameYear(Memory first, Memory second) {
    var firstDate =
        DateTime.fromMicrosecondsSinceEpoch(first.file.creationTime);
    var secondDate =
        DateTime.fromMicrosecondsSinceEpoch(second.file.creationTime);
    return firstDate.year == secondDate.year;
  }
}

class MemoryWidget extends StatelessWidget {
  const MemoryWidget({
    Key key,
    @required this.memories,
  }) : super(key: key);

  final List<Memory> memories;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 120,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            ClipOval(
              child: Container(
                width: 76,
                height: 76,
                child: ThumbnailWidget(memories[0].file),
              ),
            ),
            Padding(padding: EdgeInsets.all(2)),
            _getTitle(memories[0]),
          ],
        ),
      ),
    );
  }

  Text _getTitle(Memory memory) {
    final present = DateTime.now();
    final then = DateTime.fromMicrosecondsSinceEpoch(memory.file.creationTime);
    final diffInYears = present.year - then.year;
    if (diffInYears == 1) {
      return Text("1 year ago");
    } else {
      return Text(diffInYears.toString() + " years ago");
    }
  }
}
