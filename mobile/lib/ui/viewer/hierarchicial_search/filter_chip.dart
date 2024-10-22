import "package:flutter/material.dart";
import "package:flutter/widgets.dart";
import "package:photos/core/constants.dart";
import "package:photos/models/file/file.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/search/result/person_face_widget.dart";

class GenericFilterChip extends StatelessWidget {
  final String label;
  final IconData? leadingIcon;
  final VoidCallback onTap;

  const GenericFilterChip({
    required this.label,
    required this.onTap,
    this.leadingIcon,
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
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              leadingIcon != null
                  ? Icon(
                      leadingIcon,
                      size: 16,
                    )
                  : const SizedBox.shrink(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  label,
                  style: getEnteTextTheme(context).miniBold,
                ),
              ),
            ],
          ),
        ),
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
