import "package:ente_components/ente_components.dart";
import "package:flutter/material.dart";
import "package:photos/ui/viewer/people/person_face_widget.dart";

class FaceFilterChip extends StatelessWidget {
  final String? personId;
  final String? clusterId;
  final VoidCallback apply;
  final VoidCallback remove;
  final bool isApplied;

  const FaceFilterChip({
    required this.personId,
    required this.clusterId,
    required this.apply,
    required this.remove,
    required this.isApplied,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChipComponent(
      avatar: PersonFaceWidget(
        personId: personId,
        clusterID: clusterId,
        useFullFile: false,
      ),
      state: isApplied
          ? FilterChipComponentState.selected
          : FilterChipComponentState.unselected,
      onChanged: (_) => isApplied ? remove() : apply(),
      scaleAvatarWithText: true,
    );
  }
}
