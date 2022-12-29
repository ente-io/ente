// @dart=2.9

import 'package:flutter/material.dart';
import 'package:photos/ui/components/dialog_widget.dart';

class RenameDialog extends StatefulWidget {
  final String name;
  final String type;
  final int maxLength;

  const RenameDialog(this.name, this.type, {Key key, this.maxLength = 100})
      : super(key: key);

  @override
  State<RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<RenameDialog> {
  String _newName;

  @override
  void initState() {
    super.initState();
    _newName = widget.name;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Enter a new name"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              decoration: InputDecoration(
                hintText: '${widget.type} name',
                hintStyle: const TextStyle(
                  color: Colors.white30,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              onChanged: (value) {
                setState(() {
                  _newName = value;
                });
              },
              autocorrect: false,
              keyboardType: TextInputType.text,
              initialValue: _newName,
              autofocus: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text(
            "Cancel",
            style: TextStyle(
              color: Colors.redAccent,
            ),
          ),
          onPressed: () {
            Navigator.of(context).pop(null);
          },
        ),
        TextButton(
          child: Text(
            "Rename",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          onPressed: () {
            if (_newName.trim().isEmpty) {
              showErrorDialog(
                context,
                "Empty name",
                "${widget.type} name cannot be empty",
              );
              return;
            }
            if (_newName.trim().length > widget.maxLength) {
              showErrorDialog(
                context,
                "Name too large",
                "${widget.type} name should be less than ${widget.maxLength} characters",
              );
              return;
            }
            Navigator.of(context).pop(_newName.trim());
          },
        ),
      ],
    );
  }
}
