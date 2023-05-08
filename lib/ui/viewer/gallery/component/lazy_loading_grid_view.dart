import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/clear_selections_event.dart";
import "package:photos/models/file.dart";
import "package:photos/models/selected_files.dart";
import "package:photos/ui/viewer/gallery/component/non_recyclable_view_widget.dart";
import "package:photos/ui/viewer/gallery/component/recyclable_view_widget.dart";
import "package:photos/ui/viewer/gallery/gallery.dart";

class LazyLoadingGridView extends StatefulWidget {
  final String tag;
  final List<File> filesInDay;
  final GalleryLoader asyncLoader;
  final SelectedFiles? selectedFiles;
  final bool shouldRender;
  final bool shouldRecycle;
  final ValueNotifier toggleSelectAllFromDay;
  final ValueNotifier areAllFilesSelected;
  final int? photoGridSize;
  final bool limitSelectionToOne;

  LazyLoadingGridView(
    this.tag,
    this.filesInDay,
    this.asyncLoader,
    this.selectedFiles,
    this.shouldRender,
    this.shouldRecycle,
    this.toggleSelectAllFromDay,
    this.areAllFilesSelected,
    this.photoGridSize, {
    this.limitSelectionToOne = false,
    Key? key,
  }) : super(key: key ?? UniqueKey());

  @override
  State<LazyLoadingGridView> createState() => _LazyLoadingGridViewState();
}

class _LazyLoadingGridViewState extends State<LazyLoadingGridView> {
  late bool _shouldRender;
  int? _currentUserID;
  late StreamSubscription<ClearSelectionsEvent> _clearSelectionsEvent;

  @override
  void initState() {
    _shouldRender = widget.shouldRender;
    _currentUserID = Configuration.instance.getUserID();
    widget.selectedFiles?.addListener(_selectedFilesListener);
    _clearSelectionsEvent =
        Bus.instance.on<ClearSelectionsEvent>().listen((event) {
      if (mounted) {
        setState(() {});
      }
    });
    widget.toggleSelectAllFromDay.addListener(_toggleSelectAllFromDayListener);
    super.initState();
  }

  @override
  void dispose() {
    widget.selectedFiles?.removeListener(_selectedFilesListener);
    _clearSelectionsEvent.cancel();
    widget.toggleSelectAllFromDay
        .removeListener(_toggleSelectAllFromDayListener);
    super.dispose();
  }

  @override
  void didUpdateWidget(LazyLoadingGridView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.filesInDay, oldWidget.filesInDay)) {
      _shouldRender = widget.shouldRender;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.shouldRecycle) {
      return RecyclableViewWidget(
        shouldRender: _shouldRender,
        filesInDay: widget.filesInDay,
        photoGridSize: widget.photoGridSize!,
        limitSelectionToOne: widget.limitSelectionToOne,
        tag: widget.tag,
        asyncLoader: widget.asyncLoader,
        selectedFiles: widget.selectedFiles,
        currentUserID: _currentUserID,
      );
    } else {
      return NonRecyclableViewWidget(
        shouldRender: _shouldRender,
        filesInDay: widget.filesInDay,
        photoGridSize: widget.photoGridSize!,
        limitSelectionToOne: widget.limitSelectionToOne,
        tag: widget.tag,
        asyncLoader: widget.asyncLoader,
        selectedFiles: widget.selectedFiles,
        currentUserID: _currentUserID,
      );
    }
  }

  void _selectedFilesListener() {
    if (widget.selectedFiles!.files.containsAll(widget.filesInDay.toSet())) {
      widget.areAllFilesSelected.value = true;
    } else {
      widget.areAllFilesSelected.value = false;
    }
    bool shouldRefresh = false;
    for (final file in widget.filesInDay) {
      if (widget.selectedFiles!.isPartOfLastSelected(file)) {
        shouldRefresh = true;
      }
    }
    if (shouldRefresh && mounted) {
      setState(() {});
    }
  }

  void _toggleSelectAllFromDayListener() {
    if (widget.selectedFiles!.files.containsAll(widget.filesInDay.toSet())) {
      setState(() {
        widget.selectedFiles!.unSelectAll(widget.filesInDay.toSet());
      });
    } else {
      widget.selectedFiles!.selectAll(widget.filesInDay.toSet());
    }
  }
}
