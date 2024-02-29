import "package:fade_indexed_stack/fade_indexed_stack.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:photos/models/search/album_search_result.dart";
import "package:photos/models/search/generic_search_result.dart";
import "package:photos/models/search/index_of_indexed_stack.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/states/all_sections_examples_state.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/viewer/search/result/no_result_widget.dart";
import "package:photos/ui/viewer/search/search_suggestions.dart";
import "package:photos/ui/viewer/search/tab_empty_state.dart";
import 'package:photos/ui/viewer/search_tab/albums_section.dart';
import "package:photos/ui/viewer/search_tab/contacts_section.dart";
import "package:photos/ui/viewer/search_tab/descriptions_section.dart";
import "package:photos/ui/viewer/search_tab/file_type_section.dart";
import "package:photos/ui/viewer/search_tab/locations_section.dart";
import "package:photos/ui/viewer/search_tab/moments_section.dart";

class SearchTab extends StatefulWidget {
  const SearchTab({Key? key}) : super(key: key);

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  late int index;
  final indexOfStackNotifier = IndexOfStackNotifier();

  @override
  void initState() {
    super.initState();
    index = indexOfStackNotifier.index;
    indexOfStackNotifier.addListener(indexNotifierListener);
  }

  void indexNotifierListener() {
    setState(() {
      index = indexOfStackNotifier.index;
    });
  }

  @override
  void dispose() {
    indexOfStackNotifier.removeListener(indexNotifierListener);
    indexOfStackNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AllSectionsExamplesProvider(
      child: FadeIndexedStack(
        lazy: false,
        duration: const Duration(milliseconds: 150),
        index: index,
        children: const [
          AllSearchSections(),
          SearchSuggestionsWidget(),
          NoResultWidget(),
        ],
      ),
    );
  }
}

class AllSearchSections extends StatefulWidget {
  const AllSearchSections({super.key});

  @override
  State<AllSearchSections> createState() => _AllSearchSectionsState();
}

class _AllSearchSectionsState extends State<AllSearchSections> {
  @override
  Widget build(BuildContext context) {
    final searchTypes = SectionType.values.toList(growable: true);
    // remove face and content sectionType
    searchTypes.remove(SectionType.face);
    searchTypes.remove(SectionType.content);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Stack(
        children: [
          FutureBuilder(
            future: InheritedAllSectionsExamples.of(context)
                .allSectionsExamplesFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                if (snapshot.data!.every((element) => element.isEmpty)) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 72),
                    child: SearchTabEmptyState(),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 180),
                  physics: const BouncingScrollPhysics(),
                  itemCount: searchTypes.length,
                  itemBuilder: (context, index) {
                    switch (searchTypes[index]) {
                      case SectionType.album:
                        return AlbumsSection(
                          snapshot.data!.elementAt(index)
                              as List<AlbumSearchResult>,
                        );
                      case SectionType.moment:
                        return MomentsSection(
                          snapshot.data!.elementAt(index)
                              as List<GenericSearchResult>,
                        );
                      case SectionType.fileCaption:
                        return DescriptionsSection(
                          snapshot.data!.elementAt(index)
                              as List<GenericSearchResult>,
                        );
                      case SectionType.location:
                        return LocationsSection(
                          snapshot.data!.elementAt(index)
                              as List<GenericSearchResult>,
                        );
                      case SectionType.contacts:
                        return ContactsSection(
                          snapshot.data!.elementAt(index)
                              as List<GenericSearchResult>,
                        );
                      case SectionType.fileTypesAndExtension:
                        return FileTypeSection(
                          snapshot.data!.elementAt(index)
                              as List<GenericSearchResult>,
                        );
                      default:
                        const SizedBox.shrink();
                    }
                  },
                )
                    .animate(
                      delay: const Duration(milliseconds: 150),
                    )
                    .slide(
                      begin: const Offset(0, -0.015),
                      end: const Offset(0, 0),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    )
                    .fadeIn(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOut,
                    );
              } else if (snapshot.hasError) {
                //Errors are handled and this else if condition will be false always
                //is the understanding.
                return const Padding(
                  padding: EdgeInsets.only(bottom: 72),
                  child: EnteLoadingWidget(),
                );
              } else {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 72),
                  child: EnteLoadingWidget(),
                );
              }
            },
          ),
          ValueListenableBuilder(
            valueListenable:
                InheritedAllSectionsExamples.of(context).isDebouncingNotifier,
            builder: (context, value, _) {
              return value
                  ? const EnteLoadingWidget(
                      alignment: Alignment.topRight,
                    )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
