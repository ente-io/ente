import "dart:async";

import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/core/constants.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/files_updated_event.dart";
import "package:photos/models/search/search_result.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/utils/debouncer.dart";

class AllSectionsExamplesProvider extends StatefulWidget {
  final Widget child;
  const AllSectionsExamplesProvider({super.key, required this.child});

  @override
  State<AllSectionsExamplesProvider> createState() =>
      _AllSectionsExamplesProviderState();
}

class _AllSectionsExamplesProviderState
    extends State<AllSectionsExamplesProvider> {
  //Some section results in [allSectionsExamplesFuture] can be out of sync
  //with what is displayed on UI. This happens when some section is
  //independently listening to some set of events and is rebuilt. Sections
  //can listen to a list of events and rebuild (see sectionUpdateEvents()
  //in search_types.dart) and new results will not reflect in
  //[allSectionsExamplesFuture] unless reloadAllSections() is called.
  Future<List<List<SearchResult>>> allSectionsExamplesFuture = Future.value([]);

  late StreamSubscription<FilesUpdatedEvent> _filesUpdatedEvent;
  final _logger = Logger("AllSectionsExamplesProvider");

  final _debouncer =
      Debouncer(const Duration(seconds: 3), executionInterval: 6000);
  @override
  void initState() {
    super.initState();
    //add all common events for all search sections to reload to here.
    _filesUpdatedEvent = Bus.instance.on<FilesUpdatedEvent>().listen((event) {
      reloadAllSections();
    });
    reloadAllSections();
  }

  void reloadAllSections() {
    _debouncer.run(() async {
      setState(() {
        _logger.info("reloading all sections in search tab");
        final allSectionsExamples = <Future<List<SearchResult>>>[];
        for (SectionType sectionType in SectionType.values) {
          if (sectionType == SectionType.face ||
              sectionType == SectionType.content) {
            continue;
          }
          allSectionsExamples.add(
            sectionType.getData(context, limit: searchSectionLimit),
          );
        }
        allSectionsExamplesFuture =
            Future.wait<List<SearchResult>>(allSectionsExamples);
      });
    });
  }

  @override
  void dispose() {
    _filesUpdatedEvent.cancel();
    _debouncer.cancelDebounce();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InheritedAllSectionsExamples(
      allSectionsExamplesFuture,
      _debouncer.debounceActiveNotifier,
      child: widget.child,
    );
  }
}

class InheritedAllSectionsExamples extends InheritedWidget {
  final Future<List<List<SearchResult>>> allSectionsExamplesFuture;
  final ValueNotifier<bool> isDebouncingNotifier;
  const InheritedAllSectionsExamples(
    this.allSectionsExamplesFuture,
    this.isDebouncingNotifier, {
    super.key,
    required super.child,
  });

  static InheritedAllSectionsExamples of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<InheritedAllSectionsExamples>()!;
  }

  @override
  bool updateShouldNotify(covariant InheritedAllSectionsExamples oldWidget) {
    return !identical(
      oldWidget.allSectionsExamplesFuture,
      allSectionsExamplesFuture,
    );
  }
}
