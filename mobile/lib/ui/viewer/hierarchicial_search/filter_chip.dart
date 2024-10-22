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

  const GenericFilterChip({
    required this.label,
    required this.apply,
    required this.remove,
    required this.isApplied,
    this.leadingIcon,
    super.key,
  });

  @override
  State<GenericFilterChip> createState() => _GenericFilterChipState();
}

class _GenericFilterChipState extends State<GenericFilterChip> {
  late bool _isApplied;

  @override
  void initState() {
    super.initState();
    _isApplied = widget.isApplied;
  }

  @override
  void didUpdateWidget(covariant GenericFilterChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    _isApplied = widget.isApplied;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_isApplied) {
            widget.remove();
          } else {
            widget.apply();
          }
          _isApplied = !_isApplied;
        });
      },
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
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
                ],
              ),
            ),
          ),
          _isApplied
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
                      borderRadius: const BorderRadius.all(
                        Radius.circular(8),
                      ),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: getEnteColorScheme(context).textBase,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class FaceFilterChip extends StatelessWidget {
  final String? personId;
  final String? clusterId;
  final EnteFile faceThumbnailFile;
  final String name;
  final VoidCallback onTap;

  const FaceFilterChip({
    required this.personId,
    required this.clusterId,
    required this.faceThumbnailFile,
    required this.name,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap.call,
      child: Container(
        decoration: BoxDecoration(
          color: getEnteColorScheme(context).fillFaint,
          borderRadius:
              const BorderRadius.all(Radius.circular(kFilterChipHeight / 2)),
          border: Border.all(
            color: getEnteColorScheme(context).strokeFaint,
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(right: name.isNotEmpty ? 8.0 : 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipOval(
                child: SizedBox(
                  width: kFilterChipHeight,
                  height: kFilterChipHeight,
                  child: PersonFaceWidget(
                    faceThumbnailFile,
                    personId: personId,
                    clusterID: clusterId,
                    thumbnailFallback: false,
                  ),
                ),
              ),
              name.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        name,
                        style: getEnteTextTheme(context).miniBold,
                      ),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}
