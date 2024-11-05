import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/email_input.dart";

class SavePerson extends StatefulWidget {
  final String clusterID;
  final bool isEditing;

  const SavePerson(this.clusterID, {super.key, this.isEditing = false});

  @override
  State<SavePerson> createState() => _SavePersonState();
}

class _SavePersonState extends State<SavePerson> {
  bool isKeypadOpen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: isKeypadOpen,
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? S.of(context).addViewer
              : S.of(context).addCollaborator,
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            TextFormField(
              // controller: controller,
              // focusNode: focusNode,
              // onChanged: onChanged,
              decoration: InputDecoration(
                focusedBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                  borderSide: BorderSide(
                    color: getEnteColorScheme(context).strokeMuted,
                  ),
                ),
                fillColor: getEnteColorScheme(context).fillFaint,
                filled: true,
                hintText: "Enter name",
                hintStyle: getEnteTextTheme(context).bodyFaint,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: UnderlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            EmailInputField(
              suggestions: [
                "a@example.com",
                "b@example.com",
                "c@example.com",
                "dc@example.com",
                "ec@example.com",
                "fc@example.com",
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "aasdas",
              style: getEnteTextTheme(context).body,
            ),
          ],
        ),
      ),
    );
  }
}
