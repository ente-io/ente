import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/clear_selections_event.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/models/selected_files.dart";
import "package:photos/ui/viewer/gallery/component/grid/non_recyclable_grid_view_widget.dart";
import "package:photos/ui/viewer/gallery/component/grid/recyclable_grid_view_widget.dart";
import "package:photos/ui/viewer/gallery/gallery.dart";

class LazyGridView extends StatefulWidget {
  final String tag;
  final List<EnteFile> filesInGroup;
  final GalleryLoader asyncLoader;
  final SelectedFiles? selectedFiles;
  final bool shouldRender;
  final bool shouldRecycle;
  final int? photoGridSize;
  final bool limitSelectionToOne;

  const LazyGridView(
    this.tag,
    this.filesInGroup,
    this.asyncLoader,
    this.selectedFiles,
    this.shouldRender,
    this.shouldRecycle,
    this.photoGridSize, {
    this.limitSelectionToOne = false,
    super.key,
  });

  @override
  State<LazyGridView> createState() => _LazyGridViewState();
}

class _LazyGridViewState extends State<LazyGridView> {
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
    super.initState();
  }

  @override
  void dispose() {
    widget.selectedFiles?.removeListener(_selectedFilesListener);
    _clearSelectionsEvent.cancel();

    super.dispose();
  }

  @override
  void didUpdateWidget(LazyGridView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.filesInGroup, oldWidget.filesInGroup)) {
      _shouldRender = widget.shouldRender;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.shouldRecycle) {
      return RecyclableGridViewWidget(
        shouldRender: _shouldRender,
        filesInGroup: widget.filesInGroup,
        photoGridSize: widget.photoGridSize!,
        limitSelectionToOne: widget.limitSelectionToOne,
        tag: widget.tag,
        asyncLoader: widget.asyncLoader,
        selectedFiles: widget.selectedFiles,
        currentUserID: _currentUserID,
      );
    } else {
      return NonRecyclableGridViewWidget(
        shouldRender: _shouldRender,
        filesInGroup: widget.filesInGroup,
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
    bool shouldRefresh = false;
    for (final file in widget.filesInGroup) {
      if (widget.selectedFiles!.isPartOfLastSelected(file)) {
        shouldRefresh = true;
      }
    }
    if (shouldRefresh && mounted) {
      setState(() {});
    }
  }
}
