import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/scheduler.dart";
import "package:photos/core/constants.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/sync_status_update_event.dart";
import "package:photos/models/search/search_result.dart";
import "package:photos/models/search/search_types.dart";

class AllSectionsExamplesProvider extends StatefulWidget {
  final Widget child;
  const AllSectionsExamplesProvider({super.key, required this.child});

  @override
  State<AllSectionsExamplesProvider> createState() =>
      _AllSectionsExamplesProviderState();
}

class _AllSectionsExamplesProviderState
    extends State<AllSectionsExamplesProvider> {
  Future<List<List<SearchResult>>> allSectionsExamplesFuture = Future.value([]);

  final allSectionsExamples = <Future<List<SearchResult>>>[];
  late StreamSubscription<SyncStatusUpdate> _syncStatusSubscription;
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      _syncStatusSubscription =
          Bus.instance.on<SyncStatusUpdate>().listen((event) {
        if (event.status == SyncStatus.completedBackup) {
          setState(() {
            allSectionsExamples.clear();
            aggregateSectionsExamples();
          });
        }
      });
      setState(() {
        aggregateSectionsExamples();
      });
    });
  }

  void aggregateSectionsExamples() {
    for (SectionType sectionType in SectionType.values) {
      if (sectionType == SectionType.face ||
          sectionType == SectionType.content) {
        continue;
      }
      allSectionsExamples.add(
        sectionType.getData(limit: searchSectionLimit, context: context),
      );
    }
    allSectionsExamplesFuture =
        Future.wait<List<SearchResult>>(allSectionsExamples);
  }

  @override
  void dispose() {
    _syncStatusSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InheritedAllSectionsExamples(
      allSectionsExamplesFuture,
      child: widget.child,
    );
  }
}

class InheritedAllSectionsExamples extends InheritedWidget {
  final Future<List<List<SearchResult>>> allSectionsExamplesFuture;
  const InheritedAllSectionsExamples(
    this.allSectionsExamplesFuture, {
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
