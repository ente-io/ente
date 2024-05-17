import "package:ente_auth/l10n/l10n.dart";
import "package:flutter/material.dart";

class AddTagDialog extends StatefulWidget {
  const AddTagDialog({
    super.key,
    required this.onTap,
  });

  final void Function(String) onTap;

  @override
  State<AddTagDialog> createState() => _AddTagDialogState();
}

class _AddTagDialogState extends State<AddTagDialog> {
  String _tag = "";

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.createNewTag),
      content: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              maxLength: 100,
              decoration: InputDecoration(
                hintText: l10n.tag,
                hintStyle: const TextStyle(
                  color: Colors.white30,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              onChanged: (value) {
                setState(() {
                  _tag = value;
                });
              },
              autocorrect: false,
              initialValue: _tag,
              autofocus: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text(
            l10n.cancel,
            style: const TextStyle(
              color: Colors.redAccent,
            ),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        TextButton(
          child: Text(
            l10n.create,
            style: const TextStyle(
              color: Colors.purple,
            ),
          ),
          onPressed: () {
            if (_tag.trim().isEmpty) return;

            widget.onTap(_tag);
          },
        ),
      ],
    );
  }
}
