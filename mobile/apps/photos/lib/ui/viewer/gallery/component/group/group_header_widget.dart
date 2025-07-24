import "package:flutter/material.dart";
import 'package:photos/core/constants.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/selected_files.dart";
import "package:photos/theme/ente_theme.dart";

class GroupHeaderWidget extends StatefulWidget {
  final String title;
  final int gridSize;
  final double? height;
  final List<EnteFile> filesInGroup;
  final SelectedFiles? selectedFiles;
  final bool showSelectAll;

  const GroupHeaderWidget({
    super.key,
    required this.title,
    required this.gridSize,
    required this.filesInGroup,
    required this.selectedFiles,
    required this.showSelectAll,
    this.height,
  });

  @override
  State<GroupHeaderWidget> createState() => _GroupHeaderWidgetState();
}

class _GroupHeaderWidgetState extends State<GroupHeaderWidget> {
  late final ValueNotifier<bool> _areAllFromGroupSelectedNotifier;

  @override
  void initState() {
    super.initState();
    _areAllFromGroupSelectedNotifier =
        ValueNotifier(_areAllFromGroupSelected());

    widget.selectedFiles?.addListener(_selectedFilesListener);
  }

  @override
  void didUpdateWidget(covariant GroupHeaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title) {
      _areAllFromGroupSelectedNotifier.value = _areAllFromGroupSelected();
    }
  }

  @override
  void dispose() {
    _areAllFromGroupSelectedNotifier.dispose();
    widget.selectedFiles?.removeListener(_selectedFilesListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final textStyle =
        widget.gridSize < photoGridSizeMax ? textTheme.body : textTheme.small;
    final double horizontalPadding =
        widget.gridSize < photoGridSizeMax ? 12.0 : 8.0;
    final double verticalPadding =
        widget.gridSize < photoGridSizeMax ? 12.0 : 14.0;

    return SizedBox(
      height: widget.height,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Row(
          children: [
            Container(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.title,
                style: (widget.title == S.of(context).dayToday ||
                        widget.title == S.of(context).thisWeek ||
                        widget.title == S.of(context).thisMonth ||
                        widget.title == S.of(context).thisYear)
                    ? textStyle
                    : textStyle.copyWith(color: colorScheme.textMuted),
                maxLines: 1,
                // TODO: Make it possible to see the full title if overflowing
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(child: Container()),
            !widget.showSelectAll
                ? const SizedBox.shrink()
                : GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    child: ValueListenableBuilder(
                      valueListenable: _areAllFromGroupSelectedNotifier,
                      builder: (context, dynamic value, _) {
                        return value
                            ? const Icon(
                                Icons.check_circle,
                                size: 18,
                              )
                            : Icon(
                                Icons.check_circle_outlined,
                                color: getEnteColorScheme(context).strokeMuted,
                                size: 18,
                              );
                      },
                    ),
                    onTap: () {
                      widget.selectedFiles?.toggleGroupSelection(
                        widget.filesInGroup.toSet(),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  void _selectedFilesListener() {
    if (widget.selectedFiles == null) return;
    _areAllFromGroupSelectedNotifier.value =
        widget.selectedFiles!.files.containsAll(widget.filesInGroup.toSet());
  }

  bool _areAllFromGroupSelected() {
    if (widget.selectedFiles != null &&
        widget.selectedFiles!.files.length >= widget.filesInGroup.length) {
      return widget.selectedFiles!.files.containsAll(widget.filesInGroup);
    } else {
      return false;
    }
  }
}
