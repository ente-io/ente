import "package:flutter/material.dart";
import "package:photos/core/constants.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/people/person_face_widget.dart";

class FaceFilterChip extends StatefulWidget {
  final String? personId;
  final String? clusterId;
  final VoidCallback apply;
  final VoidCallback remove;
  final bool isApplied;
  final bool isInAllFiltersView;

  const FaceFilterChip({
    required this.personId,
    required this.clusterId,
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipOval(
                  child: SizedBox(
                    width: kFilterChipHeight * scale,
                    height: kFilterChipHeight * scale,
                    child: PersonFaceWidget(
                      personId: widget.personId,
                      clusterID: widget.clusterId,
                      useFullFile: false,
                    ),
                  ),
                ),
                widget.isApplied && !widget.isInAllFiltersView
                    ? const SizedBox(width: 4)
                    : const SizedBox.shrink(),
                widget.isApplied && !widget.isInAllFiltersView
                    ? Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: getEnteColorScheme(context).textMuted,
                      )
                    : const SizedBox.shrink(),
                widget.isApplied && !widget.isInAllFiltersView
                    ? const SizedBox(width: 8)
                    : const SizedBox.shrink(),
              ],
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
