import "dart:async";

import 'package:flutter/material.dart';
import "package:photos/events/event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/search/search_result.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/search_tab/people_section.dart";

class PeopleSectionAllPage extends StatefulWidget {
  const PeopleSectionAllPage({
    super.key,
  });

  @override
  State<PeopleSectionAllPage> createState() => _PeopleSectionAllPageState();
}

class _PeopleSectionAllPageState extends State<PeopleSectionAllPage> {
  late Future<List<SearchResult>> sectionData;
  final streamSubscriptions = <StreamSubscription>[];

  @override
  void initState() {
    super.initState();
    sectionData = SectionType.face.getData(context);

    final streamsToListenTo = SectionType.face.viewAllUpdateEvents();
    for (Stream<Event> stream in streamsToListenTo) {
      streamSubscriptions.add(
        stream.listen((event) async {
          setState(() {
            sectionData = SectionType.face.getData(context);
          });
        }),
      );
    }
  }

  @override
  void dispose() {
    for (var subscriptions in streamSubscriptions) {
      subscriptions.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final smallFontSize = getEnteTextTheme(context).small.fontSize!;
    final textScaleFactor =
        MediaQuery.textScalerOf(context).scale(smallFontSize) / smallFontSize;
    const horizontalEdgePadding = 4.0;
    const gridPadding = 16.0;
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).people),
      ),
      body: FutureBuilder<List<SearchResult>>(
        future: sectionData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No results found.'));
          } else {
            final results = snapshot.data!;
            final screenWidth = MediaQuery.of(context).size.width;
            final crossAxisCount = (screenWidth / 100).floor();

            final itemSize = (screenWidth -
                    ((horizontalEdgePadding * 2) +
                        (crossAxisCount * gridPadding))) /
                crossAxisCount;

            return GridView.builder(
              padding: const EdgeInsets.all(horizontalEdgePadding),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                mainAxisSpacing: gridPadding,
                crossAxisSpacing: gridPadding,
                crossAxisCount: crossAxisCount,
                childAspectRatio:
                    itemSize / (itemSize + (18 * textScaleFactor)),
              ),
              itemCount: results.length,
              itemBuilder: (context, index) {
                return PersonSearchExample(
                  searchResult: results[index],
                  size: itemSize,
                );
              },
            );
          }
        },
      ),
    );
  }
}
