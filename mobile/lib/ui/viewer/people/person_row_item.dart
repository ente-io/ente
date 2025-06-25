import "package:flutter/material.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/ui/viewer/people/person_face_widget.dart";

class PersonGridItem extends StatelessWidget {
  final PersonEntity person;
  final EnteFile personFile;
  final VoidCallback onTap;

  const PersonGridItem({
    super.key,
    required this.person,
    required this.personFile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 112,
              height: 112,
              child: ClipPath(
                clipper: ShapeBorderClipper(
                  shape: ContinuousRectangleBorder(
                    borderRadius: BorderRadius.circular(80),
                  ),
                ),
                child: PersonFaceWidget(
                  personId: person.remoteID,
                  key: ValueKey(person.remoteID),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              person.data.name,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
