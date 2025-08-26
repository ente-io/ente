import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import 'package:photos/core/constants.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/selected_files.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/gallery/gallery.dart";
import "package:photos/ui/viewer/gallery/layout_settings.dart";

class GroupHeaderWidget extends StatefulWidget {
  final String title;
  final int gridSize;
  final double? height;
  final List<EnteFile> filesInGroup;
  final SelectedFiles? selectedFiles;
  final bool showSelectAll;
  final bool showGalleryLayoutSettingCTA;
  final bool showTrailingIcons;
  final bool isPinnedHeader;
  final bool fadeInTrailingIcons;

  const GroupHeaderWidget({
    super.key,
    required this.title,
    required this.gridSize,
    required this.filesInGroup,
    required this.selectedFiles,
    required this.showSelectAll,
    this.showGalleryLayoutSettingCTA = false,
    this.height,
    this.showTrailingIcons = true,
    this.isPinnedHeader = false,
    this.fadeInTrailingIcons = false,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Container(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.title,
                style: (widget.title == AppLocalizations.of(context).dayToday ||
                        widget.title == AppLocalizations.of(context).thisWeek ||
                        widget.title ==
                            AppLocalizations.of(context).thisMonth ||
                        widget.title == AppLocalizations.of(context).thisYear)
                    ? textStyle
                    : textStyle.copyWith(color: colorScheme.textMuted),
                maxLines: 1,
                // TODO: Make it possible to see the full title if overflowing
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(child: Container()),
          !widget.showSelectAll
              ? const SizedBox.shrink()
              : widget.showTrailingIcons
                  ? GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: ValueListenableBuilder(
                          valueListenable: _areAllFromGroupSelectedNotifier,
                          builder: (context, dynamic value, _) {
                            return value
                                ? widget.fadeInTrailingIcons
                                    ? const Icon(
                                        Icons.check_circle,
                                        size: 22,
                                      ).animate().fadeIn(
                                          duration: const Duration(
                                            milliseconds: PinnedGroupHeader
                                                .kTrailingIconsFadeInDurationMs,
                                          ),
                                          delay: const Duration(
                                            milliseconds: PinnedGroupHeader
                                                    .kScaleDurationInMilliseconds +
                                                PinnedGroupHeader
                                                    .kTrailingIconsFadeInDelayMs,
                                          ),
                                          curve: Curves.easeOut,
                                        )
                                    : const Icon(
                                        Icons.check_circle,
                                        size: 22,
                                      )
                                : widget.fadeInTrailingIcons
                                    ? Icon(
                                        Icons.check_circle_outlined,
                                        color: colorScheme.strokeMuted,
                                        size: 22,
                                      ).animate().fadeIn(
                                          duration: const Duration(
                                            milliseconds: PinnedGroupHeader
                                                .kTrailingIconsFadeInDurationMs,
                                          ),
                                          delay: const Duration(
                                            milliseconds: PinnedGroupHeader
                                                    .kScaleDurationInMilliseconds +
                                                PinnedGroupHeader
                                                    .kTrailingIconsFadeInDelayMs,
                                          ),
                                          curve: Curves.easeOut,
                                        )
                                    : Icon(
                                        Icons.check_circle_outlined,
                                        color: colorScheme.strokeMuted,
                                        size: 22,
                                      );
                          },
                        ),
                      ),
                      onTap: () {
                        widget.selectedFiles?.toggleGroupSelection(
                          widget.filesInGroup.toSet(),
                        );
                      },
                    )
                  : const SizedBox.shrink(),
          widget.showGalleryLayoutSettingCTA
              ? const SizedBox(width: 8)
              : const SizedBox.shrink(),
          widget.showGalleryLayoutSettingCTA
              ? widget.showTrailingIcons
                  ? GestureDetector(
                      onTap: () => _showLayoutSettingsOverflowMenu(context),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: widget.fadeInTrailingIcons
                            ? Icon(
                                Icons.more_vert_outlined,
                                // color: colorScheme.blurStrokeBase,
                                color: colorScheme.strokeMuted,
                              ).animate().fadeIn(
                                  duration: const Duration(
                                    milliseconds: PinnedGroupHeader
                                        .kTrailingIconsFadeInDurationMs,
                                  ),
                                  delay: const Duration(
                                    milliseconds: PinnedGroupHeader
                                            .kScaleDurationInMilliseconds +
                                        PinnedGroupHeader
                                            .kTrailingIconsFadeInDelayMs,
                                  ),
                                  curve: Curves.easeOut,
                                )
                            : Icon(
                                Icons.more_vert_outlined,
                                // color: colorScheme.blurStrokeBase,
                                color: colorScheme.strokeMuted,
                              ),
                      ),
                    )
                  : const SizedBox.shrink()
              : const SizedBox.shrink(),
          SizedBox(width: horizontalPadding - 4.0),
        ],
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

  void _showLayoutSettingsOverflowMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: getEnteColorScheme(context).backgroundElevated,
      builder: (BuildContext context) {
        return const GalleryLayoutSettings();
      },
    );
  }
}
