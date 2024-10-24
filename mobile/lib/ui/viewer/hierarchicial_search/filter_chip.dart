import "package:flutter/material.dart";
import "package:photos/core/constants.dart";
import "package:photos/models/file/file.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/search/result/person_face_widget.dart";

class GenericFilterChip extends StatefulWidget {
  final String label;
  final IconData? leadingIcon;
  final VoidCallback apply;
  final VoidCallback remove;
  final bool isApplied;
  final bool isInAllFiltersView;

  const GenericFilterChip({
    required this.label,
    required this.apply,
    required this.remove,
    required this.isApplied,
    this.leadingIcon,
    this.isInAllFiltersView = false,
    super.key,
  });

  @override
  State<GenericFilterChip> createState() => _GenericFilterChipState();
}

class _GenericFilterChipState extends State<GenericFilterChip> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.isApplied) {
          widget.remove();
        } else {
          widget.apply();
        }
      },
      child: SizedBox(
        // +1 to account for the filter's outer stroke width
        height: kFilterChipHeight + 1,
        child: Container(
          decoration: BoxDecoration(
            color: getEnteColorScheme(context).fillFaint,
            borderRadius: const BorderRadius.all(
              Radius.circular(kFilterChipHeight / 2),
            ),
            border: Border.all(
              color: getEnteColorScheme(context).strokeFaint,
              width: 0.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                widget.leadingIcon != null
                    ? Icon(
                        widget.leadingIcon,
                        size: 16,
                      )
                    : const SizedBox.shrink(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    widget.label,
                    style: getEnteTextTheme(context).miniBold,
                  ),
                ),
                widget.isApplied
                    ? const SizedBox(width: 2)
                    : const SizedBox.shrink(),
                widget.isApplied
                    ? Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: getEnteColorScheme(context).textMuted,
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FaceFilterChip extends StatefulWidget {
  final String? personId;
  final String? clusterId;
  final EnteFile faceThumbnailFile;
  final String name;
  final VoidCallback apply;
  final VoidCallback remove;
  final bool isApplied;
  final bool isInAllFiltersView;

  const FaceFilterChip({
    required this.personId,
    required this.clusterId,
    required this.faceThumbnailFile,
    required this.name,
    required this.apply,
    required this.remove,
    required this.isApplied,
    this.isInAllFiltersView = false,
    super.key,
  });

  @override
  State<FaceFilterChip> createState() => _FaceFilterChipState();
}

class _FaceFilterChipState extends State<FaceFilterChip> {
  double scale = 1.0;

  @override
  void initState() {
    super.initState();
    if (widget.isInAllFiltersView) {
      scale = 1.75;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () {
            if (widget.isApplied) {
              widget.remove();
            } else {
              widget.apply();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: getEnteColorScheme(context).fillFaint,
              borderRadius: BorderRadius.all(
                Radius.circular(kFilterChipHeight * scale / 2),
              ),
              border: Border.all(
                color: getEnteColorScheme(context).strokeFaint,
                width: widget.isInAllFiltersView ? 1 : 0.5,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                right: !widget.isInAllFiltersView && widget.name.isNotEmpty
                    ? 8.0
                    : 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: kFilterChipHeight * scale,
                      height: kFilterChipHeight * scale,
                      child: PersonFaceWidget(
                        widget.faceThumbnailFile,
                        personId: widget.personId,
                        clusterID: widget.clusterId,
                        thumbnailFallback: false,
                      ),
                    ),
                  ),
                  !widget.isInAllFiltersView && widget.name.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            widget.name,
                            style: getEnteTextTheme(context).miniBold,
                          ),
                        )
                      : const SizedBox.shrink(),
                  widget.isApplied && !widget.isInAllFiltersView
                      ? SizedBox(width: widget.name.isNotEmpty ? 2 : 4)
                      : const SizedBox.shrink(),
                  widget.isApplied && !widget.isInAllFiltersView
                      ? Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: getEnteColorScheme(context).textMuted,
                        )
                      : const SizedBox.shrink(),
                  widget.isApplied &&
                          widget.name.isEmpty &&
                          !widget.isInAllFiltersView
                      ? const SizedBox(width: 8)
                      : const SizedBox.shrink(),
                ],
              ),
            ),
          ),
        ),
        widget.isApplied && widget.isInAllFiltersView
            ? Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: getEnteColorScheme(context).backgroundElevated2,
                    border: Border.all(
                      color: getEnteColorScheme(context).strokeMuted,
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.all(
                      Radius.circular(8 * scale),
                    ),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: getEnteColorScheme(context).textMuted,
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}
