import "package:flutter/material.dart";
import "package:photos/core/constants.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/search/hierarchical/face_filter.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/search/result/person_face_widget.dart";

class OnlyThemFilterChip extends StatelessWidget {
  final List<FaceFilter> faceFilters;
  final VoidCallback apply;
  final VoidCallback remove;
  final bool isApplied;
  final bool isInAllFiltersView;
  const OnlyThemFilterChip({
    required this.faceFilters,
    required this.apply,
    required this.remove,
    required this.isApplied,
    this.isInAllFiltersView = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isApplied) {
          remove();
        } else {
          apply();
        }
      },
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
          padding: const EdgeInsets.only(right: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _OnlyThemFilterThumbnail(
                faceFilters: faceFilters,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  S.of(context).onlyThem,
                  style: getEnteTextTheme(context).miniBold,
                ),
              ),
              isApplied ? const SizedBox(width: 2) : const SizedBox.shrink(),
              isApplied
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
    );
  }
}

class _OnlyThemFilterThumbnail extends StatelessWidget {
  final List<FaceFilter> faceFilters;
  const _OnlyThemFilterThumbnail({
    required this.faceFilters,
  }) : assert(faceFilters.length > 0 && faceFilters.length <= 4);

  @override
  Widget build(BuildContext context) {
    final numberOfFaces = faceFilters.length;
    if (numberOfFaces == 1) {
      return ClipOval(
        child: SizedBox(
          width: kFilterChipHeight,
          height: kFilterChipHeight,
          child: PersonFaceWidget(
            faceFilters.first.faceFile,
            personId: faceFilters.first.personId,
            clusterID: faceFilters.first.clusterId,
            thumbnailFallback: false,
            useFullFile: false,
            cannotTrustFile: true,
          ),
        ),
      );
    } else if (numberOfFaces == 2) {
      return ClipOval(
        child: Row(
          children: [
            SizedBox(
              width: kFilterChipHeight / 2,
              height: kFilterChipHeight,
              child: PersonFaceWidget(
                faceFilters.first.faceFile,
                personId: faceFilters.first.personId,
                clusterID: faceFilters.first.clusterId,
                thumbnailFallback: false,
                useFullFile: false,
                cannotTrustFile: true,
              ),
            ),
            const SizedBox(width: 1),
            SizedBox(
              width: kFilterChipHeight / 2,
              height: kFilterChipHeight,
              child: PersonFaceWidget(
                faceFilters.last.faceFile,
                personId: faceFilters.last.personId,
                clusterID: faceFilters.last.clusterId,
                thumbnailFallback: false,
                useFullFile: false,
                cannotTrustFile: true,
              ),
            ),
          ],
        ),
      );
    } else if (faceFilters.length == 3) {
      return ClipOval(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: kFilterChipHeight,
              width: kFilterChipHeight / 2 - 0.5,
              child: PersonFaceWidget(
                faceFilters[0].faceFile,
                personId: faceFilters[0].personId,
                clusterID: faceFilters[0].clusterId,
                thumbnailFallback: false,
                useFullFile: false,
                cannotTrustFile: true,
              ),
            ),
            const SizedBox(width: 1),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: kFilterChipHeight / 2 - 0.5,
                  height: kFilterChipHeight / 2 - 0.5,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(1),
                    ),
                    child: PersonFaceWidget(
                      faceFilters[1].faceFile,
                      personId: faceFilters[1].personId,
                      clusterID: faceFilters[1].clusterId,
                      thumbnailFallback: false,
                      useFullFile: false,
                      cannotTrustFile: true,
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                SizedBox(
                  width: kFilterChipHeight / 2 - 0.5,
                  height: kFilterChipHeight / 2 - 0.5,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(1),
                    ),
                    child: PersonFaceWidget(
                      faceFilters[2].faceFile,
                      personId: faceFilters[2].personId,
                      clusterID: faceFilters[2].clusterId,
                      thumbnailFallback: false,
                      useFullFile: false,
                      cannotTrustFile: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return ClipOval(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: kFilterChipHeight / 2 - 0.5,
                  height: kFilterChipHeight / 2 - 0.5,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(1),
                    ),
                    child: PersonFaceWidget(
                      faceFilters[0].faceFile,
                      personId: faceFilters[0].personId,
                      clusterID: faceFilters[0].clusterId,
                      thumbnailFallback: false,
                      useFullFile: false,
                      cannotTrustFile: true,
                    ),
                  ),
                ),
                const SizedBox(width: 1),
                SizedBox(
                  width: kFilterChipHeight / 2 - 0.5,
                  height: kFilterChipHeight / 2 - 0.5,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(1),
                    ),
                    child: PersonFaceWidget(
                      faceFilters[1].faceFile,
                      personId: faceFilters[1].personId,
                      clusterID: faceFilters[1].clusterId,
                      thumbnailFallback: false,
                      useFullFile: false,
                      cannotTrustFile: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: kFilterChipHeight / 2 - 0.5,
                  height: kFilterChipHeight / 2 - 0.5,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(1),
                    ),
                    child: PersonFaceWidget(
                      faceFilters[2].faceFile,
                      personId: faceFilters[2].personId,
                      clusterID: faceFilters[2].clusterId,
                      thumbnailFallback: false,
                      useFullFile: false,
                      cannotTrustFile: true,
                    ),
                  ),
                ),
                const SizedBox(width: 1),
                SizedBox(
                  width: kFilterChipHeight / 2 - 0.5,
                  height: kFilterChipHeight / 2 - 0.5,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(1),
                    ),
                    child: PersonFaceWidget(
                      faceFilters[3].faceFile,
                      personId: faceFilters[3].personId,
                      clusterID: faceFilters[3].clusterId,
                      thumbnailFallback: false,
                      useFullFile: false,
                      cannotTrustFile: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }
}
