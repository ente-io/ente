import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/ente_theme_data.dart";
import "package:photos/events/files_updated_event.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/models/selected_files.dart";
import "package:photos/service_locator.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/huge_listview/huge_listview.dart";
import 'package:photos/ui/viewer/gallery/component/group/lazy_group_gallery.dart';
import "package:photos/ui/viewer/gallery/component/group/type.dart";
import "package:photos/ui/viewer/gallery/gallery.dart";
import "package:photos/ui/viewer/gallery/state/gallery_context_state.dart";
import "package:photos/utils/standalone/data.dart";
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
  final ItemScrollController itemScroller;
  final List<List<EnteFile>> groupedFiles;
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
  final bool showSelectAllByDefault;
  final bool isScrollablePositionedList;

  const MultipleGroupsGalleryView({
    required this.itemScroller,
    required this.groupedFiles,
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
    required this.showSelectAllByDefault,
    required this.isScrollablePositionedList,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final gType = GalleryContextState.of(context)!.type;
    return HugeListView<List<EnteFile>>(
      controller: itemScroller,
      startIndex: 0,
      totalCount: groupedFiles.length,
      isDraggableScrollbarEnabled: groupedFiles.length > 10,
      disableScroll: disableScroll,
      isScrollablePositionedList: isScrollablePositionedList,
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
          groupedFiles[index],
          index,
          reloadEvent,
          removalEventTypes,
          asyncLoader,
          selectedFiles,
          tagPrefix,
          Bus.instance
              .on<GalleryIndexUpdatedEvent>()
              .where((event) => event.tag == tagPrefix)
              .map((event) => event.index),
          enableFileGrouping,
          showSelectAllByDefault,
          logTag: logTag,
          photoGridSize: localSettings.getPhotoGridSize(),
          limitSelectionToOne: limitSelectionToOne,
        );
        if (header != null && index == 0) {
          gallery = Column(children: [header!, gallery]);
        }
        if (footer != null && index == groupedFiles.length - 1) {
          gallery = Column(children: [gallery, footer!]);
        }
        return gallery;
      },
      labelTextBuilder: (int index) {
        try {
          final EnteFile file = groupedFiles[index][0];
          if (gType == GroupType.size) {
            return file.fileSize != null
                ? convertBytesToReadableFormat(file.fileSize!)
                : "";
          }

          return DateFormat.yMMM(Localizations.localeOf(context).languageCode)
              .format(
            DateTime.fromMicrosecondsSinceEpoch(
              file.creationTime!,
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
