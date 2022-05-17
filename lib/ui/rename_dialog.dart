import 'package:flutter/material.dart';
import 'package:photos/utils/dialog_util.dart';

class RenameDialog extends StatefulWidget {
  final String name;
  final String type;
  final int maxLength;

  const RenameDialog(this.name, this.type, {Key key, this.maxLength = 100})
      : super(key: key);

  @override
  _RenameDialogState createState() => _RenameDialogState();
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
      title: Text("Enter a new name"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              decoration: InputDecoration(
                hintText: '${widget.type} name',
                hintStyle: TextStyle(
                  color: Colors.white30,
                ),
                contentPadding: EdgeInsets.all(12),
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
          child: Text(
            "cancel",
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
            "rename",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          onPressed: () {
            if (_newName.trim().isEmpty) {
              showErrorDialog(
                  context, "empty name", "${widget.type} name cannot be empty");
              return;
            }
            if (_newName.trim().length > widget.maxLength) {
              showErrorDialog(context, "name too large",
                  "${widget.type} name should be less than ${widget.maxLength} characters");
              return;
            }
            Navigator.of(context).pop(_newName.trim());
          },
        ),
      ],
    );
  }
}
