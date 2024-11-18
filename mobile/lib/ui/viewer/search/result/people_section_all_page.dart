import "dart:async";

import 'package:flutter/material.dart';
import "package:flutter_animate/flutter_animate.dart";
import "package:photos/events/event.dart";
import "package:photos/models/search/search_result.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
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
    const horizontalEdgePadding = 20.0;
    const gridPadding = 16.0;
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(S.of(context).people),
      //   centerTitle: false,
      // ),
      appBar: AppBar(
        toolbarHeight: 48,
        leadingWidth: 48,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(
            Icons.arrow_back_outlined,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TitleBarTitleWidget(
                  title: SectionType.face.sectionTitle(context),
                ),
                FutureBuilder(
                  future: sectionData,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final sectionResults = snapshot.data!;
                      return Text(sectionResults.length.toString())
                          .animate()
                          .fadeIn(
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeIn,
                          );
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<SearchResult>>(
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
                              ((crossAxisCount - 1) * gridPadding))) /
                      crossAxisCount;

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      horizontalEdgePadding,
                      16,
                      horizontalEdgePadding,
                      96,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      mainAxisSpacing: gridPadding,
                      crossAxisSpacing: gridPadding,
                      crossAxisCount: crossAxisCount,
                      childAspectRatio:
                          itemSize / (itemSize + (24 * textScaleFactor)),
                    ),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      return PersonSearchExample(
                        searchResult: results[index],
                        size: itemSize,
                      )
                          .animate(delay: Duration(milliseconds: index * 12))
                          .fadeIn(
                            duration: const Duration(milliseconds: 225),
                            curve: Curves.easeIn,
                          )
                          .slide(
                            begin: const Offset(0, -0.05),
                            curve: Curves.easeInOut,
                            duration: const Duration(
                              milliseconds: 225,
                            ),
                          );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
