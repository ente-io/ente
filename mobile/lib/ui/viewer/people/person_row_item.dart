import "package:flutter/material.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/ui/viewer/search/result/person_face_widget.dart";

class PersonRowItem extends StatelessWidget {
  final PersonEntity person;
  final EnteFile personFile;
  final VoidCallback onTap;

  const PersonRowItem({
    super.key,
    required this.person,
    required this.personFile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: false,
      minLeadingWidth: 0,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      leading: SizedBox(
        width: 56,
        height: 56,
        child: ClipRRect(
          borderRadius: const BorderRadius.all(
            Radius.elliptical(16, 12),
          ),
          child: PersonFaceWidget(personFile, personId: person.remoteID),
        ),
      ),
      title: Text(person.data.name),
      onTap: onTap,
    );
  }
}

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
                child: PersonFaceWidget(personFile, personId: person.remoteID),
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
