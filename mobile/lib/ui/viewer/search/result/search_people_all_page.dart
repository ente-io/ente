import "dart:async";

import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:photos/events/event.dart";
import "package:photos/models/search/generic_search_result.dart";
import "package:photos/models/search/search_result.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/viewer/search/result/searchable_item.dart";

class PeopleAllPage extends StatefulWidget {
  final SectionType sectionType;
  const PeopleAllPage({required this.sectionType, super.key});

  @override
  State<PeopleAllPage> createState() => _PeopleAllPageState();
}

class _PeopleAllPageState extends State<PeopleAllPage> {
  late Future<List<SearchResult>> sectionData;
  final streamSubscriptions = <StreamSubscription>[];

  @override
  void initState() {
    super.initState();
    sectionData = widget.sectionType.getData(context);
    final streamsToListenTo = widget.sectionType.viewAllUpdateEvents();
    for (Stream<Event> stream in streamsToListenTo) {
      streamSubscriptions.add(
        stream.listen((event) async {
          setState(() {
            sectionData = widget.sectionType.getData(context);
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
    return Scaffold(
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
        title: Text(widget.sectionType.sectionTitle(context)),
      ),
      body: Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: FutureBuilder(
            future: sectionData,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final List<SearchResult> sectionResults = snapshot.data!;
                if (widget.sectionType.sortByName) {
                  sectionResults.sort(
                    (a, b) => compareAsciiLowerCaseNatural(b.name(), a.name()),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 600
                        ? 4
                        : 3, // Dynamically adjust columns based on screen width
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio:
                        0.85, // Adjust this value to control item height ratio
                  ),
                  itemCount: sectionResults.length,
                  physics: const BouncingScrollPhysics(),
                  cacheExtent:
                      widget.sectionType == SectionType.album ? 400 : null,
                  itemBuilder: (context, index) {
                    Widget resultWidget;
                    if (sectionResults[index] is GenericSearchResult) {
                      final result =
                          sectionResults[index] as GenericSearchResult;
                      resultWidget = SearchableItemWidget(
                        sectionResults[index],
                        onResultTap: result.onResultTap != null
                            ? () => result.onResultTap!(context)
                            : null,
                      );
                    } else {
                      resultWidget = SearchableItemWidget(
                        sectionResults[index],
                      );
                    }
                    return resultWidget
                        .animate()
                        .fadeIn(
                          duration: const Duration(milliseconds: 225),
                          curve: Curves.easeIn,
                        )
                        .slide(
                          begin: const Offset(0, -0.01),
                          curve: Curves.easeIn,
                          duration: const Duration(milliseconds: 225),
                        );
                  },
                );
              } else {
                return const EnteLoadingWidget();
              }
            },
          ),
        ),
      ),
    );
  }
}
