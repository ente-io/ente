import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/ente_theme_data.dart";
import "package:photos/events/files_updated_event.dart";
import "package:photos/models/file.dart";
import "package:photos/models/selected_files.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/huge_listview/huge_listview.dart";
import 'package:photos/ui/viewer/gallery/component/group/lazy_group_gallery.dart';
import "package:photos/ui/viewer/gallery/gallery.dart";
import "package:photos/utils/local_settings.dart";
import "package:scrollable_positioned_list/scrollable_positioned_list.dart";

/*
MultipleGroupsGalleryView is a widget that displays a list of grouped/collated
files when grouping is enabled.
For each group, it displays a header and use LazyGroupGallery to display a
particular group of files.
If a group has more than 400 files, LazyGroupGallery internally divides the
group into multiple grid views during rendering.
 */
class MultipleGroupsGalleryView extends StatelessWidget {
  final GlobalKey<HugeListViewState<dynamic>> hugeListViewKey;
  final ItemScrollController itemScroller;
  final List<List<File>> collatedFiles;
  final bool disableScroll;
  final Widget? header;
  final Widget? footer;
  final Widget emptyState;
  final GalleryLoader asyncLoader;
  final Stream<FilesUpdatedEvent>? reloadEvent;
  final Set<EventType> removalEventTypes;
  final String tagPrefix;
  final double scrollBottomSafeArea;
  final bool limitSelectionToOne;
  final SelectedFiles? selectedFiles;
  final bool enableFileGrouping;
  final String logTag;
  final Logger logger;
  final bool sortOrderAsc;

  const MultipleGroupsGalleryView({
    required this.hugeListViewKey,
    required this.itemScroller,
    required this.collatedFiles,
    required this.disableScroll,
    this.header,
    this.footer,
    required this.emptyState,
    required this.asyncLoader,
    this.reloadEvent,
    required this.removalEventTypes,
    required this.tagPrefix,
    required this.scrollBottomSafeArea,
    required this.limitSelectionToOne,
    this.selectedFiles,
    required this.enableFileGrouping,
    required this.logTag,
    required this.logger,
    required this.sortOrderAsc,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return HugeListView<List<File>>(
      key: hugeListViewKey,
      controller: itemScroller,
      startIndex: 0,
      totalCount: collatedFiles.length,
      isDraggableScrollbarEnabled: collatedFiles.length > 10,
      disableScroll: disableScroll,
      waitBuilder: (_) {
        return const EnteLoadingWidget();
      },
      emptyResultBuilder: (_) {
        final List<Widget> children = [];
        if (header != null) {
          children.add(header!);
        }
        children.add(
          Expanded(
            child: emptyState,
          ),
        );
        if (footer != null) {
          children.add(footer!);
        }
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: children,
        );
      },
      itemBuilder: (context, index) {
        Widget gallery;
        gallery = LazyGroupGallery(
          collatedFiles[index],
          index,
          reloadEvent,
          removalEventTypes,
          asyncLoader,
          sortOrderAsc,
          selectedFiles,
          tagPrefix,
          Bus.instance
              .on<GalleryIndexUpdatedEvent>()
              .where((event) => event.tag == tagPrefix)
              .map((event) => event.index),
          enableFileGrouping,
          logTag: logTag,
          photoGridSize: LocalSettings.instance.getPhotoGridSize(),
          limitSelectionToOne: limitSelectionToOne,
        );
        if (header != null && index == 0) {
          gallery = Column(children: [header!, gallery]);
        }
        if (footer != null && index == collatedFiles.length - 1) {
          gallery = Column(children: [gallery, footer!]);
        }
        return gallery;
      },
      labelTextBuilder: (int index) {
        try {
          return DateFormat.yMMM(Localizations.localeOf(context).languageCode)
              .format(
            DateTime.fromMicrosecondsSinceEpoch(
              collatedFiles[index][0].creationTime!,
            ),
          );
        } catch (e) {
          logger.severe("label text builder failed", e);
          return "";
        }
      },
      thumbBackgroundColor:
          Theme.of(context).colorScheme.galleryThumbBackgroundColor,
      thumbDrawColor: Theme.of(context).colorScheme.galleryThumbDrawColor,
      thumbPadding: header != null
          ? const EdgeInsets.only(top: 60)
          : const EdgeInsets.all(0),
      bottomSafeArea: scrollBottomSafeArea,
      firstShown: (int firstIndex) {
        Bus.instance.fire(GalleryIndexUpdatedEvent(tagPrefix, firstIndex));
      },
    );
  }
}
