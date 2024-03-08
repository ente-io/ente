import "package:flutter/material.dart";
import "package:photos/face/model/person.dart";

class PersonRowItem extends StatelessWidget {
  final Person person;
  final VoidCallback onTap;

  const PersonRowItem({
    Key? key,
    required this.person,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(person.attr.name.substring(0, 1)),
      ),
      title: Text(person.attr.name),
      onTap: onTap,
    );
  }
}
