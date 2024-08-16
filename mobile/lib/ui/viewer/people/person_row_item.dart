import "package:flutter/material.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/ui/viewer/search/result/person_face_widget.dart";

class PersonRowItem extends StatelessWidget {
  final PersonEntity person;
  final EnteFile personFile;
  final VoidCallback onTap;

  const PersonRowItem({
    Key? key,
    required this.person,
    required this.personFile,
    required this.onTap,
  }) : super(key: key);

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
