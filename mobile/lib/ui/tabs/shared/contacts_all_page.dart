import "dart:async";

import "package:collection/collection.dart";
import "package:dotted_border/dotted_border.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/search/generic_search_result.dart";
import "package:photos/models/search/search_result.dart";
import "package:photos/services/search_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/viewer/search/result/searchable_item.dart";
import "package:photos/utils/share_util.dart";

class ContactsSectionAllPage extends StatefulWidget {
  const ContactsSectionAllPage({super.key});

  @override
  State<ContactsSectionAllPage> createState() => _ContactsSectionAllPageState();
}

class _ContactsSectionAllPageState extends State<ContactsSectionAllPage> {
  late Future<List<SearchResult>> resutls;
  final streamSubscriptions = <StreamSubscription>[];

  @override
  void initState() {
    super.initState();
    resutls = SearchService.instance.getAllContactsSearchResults(null);
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
                  title: S.of(context).contacts,
                ),
                FutureBuilder(
                  future: resutls,
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
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 20,
                horizontal: 16,
              ),
              child: FutureBuilder(
                future: resutls,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final sectionResults = snapshot.data!;

                    sectionResults.sort(
                      (a, b) =>
                          compareAsciiLowerCaseNatural(b.name(), a.name()),
                    );

                    return ListView.separated(
                      itemBuilder: (context, index) {
                        if (sectionResults.length == index) {
                          return const _SearchableItemPlaceholder();
                        }

                        final result =
                            sectionResults[index] as GenericSearchResult;
                        return SearchableItemWidget(
                          sectionResults[index],
                          onResultTap: result.onResultTap != null
                              ? () => result.onResultTap!(context)
                              : null,
                        );
                      },
                      separatorBuilder: (context, index) {
                        return const SizedBox(height: 10);
                      },
                      itemCount: sectionResults.length + 1,
                      physics: const BouncingScrollPhysics(),
                    )
                        .animate()
                        .fadeIn(
                          duration: const Duration(milliseconds: 225),
                          curve: Curves.easeIn,
                        )
                        .slide(
                          begin: const Offset(0, -0.01),
                          curve: Curves.easeIn,
                          duration: const Duration(
                            milliseconds: 225,
                          ),
                        );
                  } else {
                    return const EnteLoadingWidget();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchableItemPlaceholder extends StatelessWidget {
  const _SearchableItemPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return Padding(
      padding: const EdgeInsets.only(right: 1),
      child: GestureDetector(
        onTap: () async {
          await shareText(
            S.of(context).shareTextRecommendUsingEnte,
          );
        },
        child: DottedBorder(
          strokeWidth: 2,
          borderType: BorderType.RRect,
          radius: const Radius.circular(4),
          padding: EdgeInsets.zero,
          dashPattern: const [4, 4],
          color: colorScheme.strokeFainter,
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(4)),
                  color: colorScheme.fillFaint,
                ),
                child: Icon(
                  Icons.adaptive.share,
                  color: colorScheme.strokeMuted,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                S.of(context).invite,
                style: textTheme.body,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
