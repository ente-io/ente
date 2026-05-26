import "package:ente_components/ente_components.dart";
import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/search/hierarchical/face_filter.dart";
import "package:photos/ui/viewer/people/person_face_widget.dart";

class OnlyThemFilterChip extends StatelessWidget {
  final List<FaceFilter> faceFilters;
  final VoidCallback apply;
  final VoidCallback remove;
  final bool isApplied;
  const OnlyThemFilterChip({
    required this.faceFilters,
    required this.apply,
    required this.remove,
    required this.isApplied,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChipComponent(
      label: AppLocalizations.of(context).onlyThem,
      avatar: _OnlyThemFilterThumbnail(
        faceFilters: faceFilters,
        size: FilterChipComponent.avatarSizeForTextScale(context),
      ),
      state: isApplied
          ? FilterChipComponentState.selected
          : FilterChipComponentState.unselected,
      onChanged: (_) => isApplied ? remove() : apply(),
      scaleAvatarWithText: true,
    );
  }
}

class _OnlyThemFilterThumbnail extends StatelessWidget {
  final List<FaceFilter> faceFilters;
  final double size;
  const _OnlyThemFilterThumbnail({
    required this.faceFilters,
    required this.size,
  }) : assert(faceFilters.length > 0 && faceFilters.length <= 4);

  @override
  Widget build(BuildContext context) {
    final numberOfFaces = faceFilters.length;
    if (numberOfFaces == 1) {
      return ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: PersonFaceWidget(
            personId: faceFilters.first.personId,
            clusterID: faceFilters.first.clusterId,
            useFullFile: false,
          ),
        ),
      );
    } else if (numberOfFaces == 2) {
      return ClipOval(
        child: Row(
          children: [
            SizedBox(
              width: size / 2 - 0.5,
              height: size,
              child: PersonFaceWidget(
                personId: faceFilters.first.personId,
                clusterID: faceFilters.first.clusterId,
                useFullFile: false,
              ),
            ),
            const SizedBox(width: 1),
            SizedBox(
              width: size / 2 - 0.5,
              height: size,
              child: PersonFaceWidget(
                personId: faceFilters.last.personId,
                clusterID: faceFilters.last.clusterId,
                useFullFile: false,
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
              height: size,
              width: size / 2 - 0.5,
              child: PersonFaceWidget(
                personId: faceFilters[0].personId,
                clusterID: faceFilters[0].clusterId,
                useFullFile: false,
              ),
            ),
            const SizedBox(width: 1),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: size / 2 - 0.5,
                  height: size / 2 - 0.5,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(1),
                    ),
                    child: PersonFaceWidget(
                      personId: faceFilters[1].personId,
                      clusterID: faceFilters[1].clusterId,
                      useFullFile: false,
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                SizedBox(
                  width: size / 2 - 0.5,
                  height: size / 2 - 0.5,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(1),
                    ),
                    child: PersonFaceWidget(
                      personId: faceFilters[2].personId,
                      clusterID: faceFilters[2].clusterId,
                      useFullFile: false,
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
                  width: size / 2 - 0.5,
                  height: size / 2 - 0.5,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(1),
                    ),
                    child: PersonFaceWidget(
                      personId: faceFilters[0].personId,
                      clusterID: faceFilters[0].clusterId,
                      useFullFile: false,
                    ),
                  ),
                ),
                const SizedBox(width: 1),
                SizedBox(
                  width: size / 2 - 0.5,
                  height: size / 2 - 0.5,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(1),
                    ),
                    child: PersonFaceWidget(
                      personId: faceFilters[1].personId,
                      clusterID: faceFilters[1].clusterId,
                      useFullFile: false,
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
                  width: size / 2 - 0.5,
                  height: size / 2 - 0.5,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(1),
                    ),
                    child: PersonFaceWidget(
                      personId: faceFilters[2].personId,
                      clusterID: faceFilters[2].clusterId,
                      useFullFile: false,
                    ),
                  ),
                ),
                const SizedBox(width: 1),
                SizedBox(
                  width: size / 2 - 0.5,
                  height: size / 2 - 0.5,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(1),
                    ),
                    child: PersonFaceWidget(
                      personId: faceFilters[3].personId,
                      clusterID: faceFilters[3].clusterId,
                      useFullFile: false,
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
