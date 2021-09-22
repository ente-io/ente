import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/email_util.dart';
import 'package:photos/utils/toast_util.dart';

class ChangeCollectionNameDialog extends StatefulWidget {
  final String name;

  const ChangeCollectionNameDialog({Key key, this.name}) : super(key: key);

  @override
  _ChangeCollectionNameDialogState createState() =>
      _ChangeCollectionNameDialogState();
}

class _ChangeCollectionNameDialogState
    extends State<ChangeCollectionNameDialog> {
  String _newCollectionName;

  @override
  void initState() {
    super.initState();
    _newCollectionName = widget.name;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("enter new album name"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              decoration: InputDecoration(
                hintText: 'album name',
                hintStyle: TextStyle(
                  color: Colors.white30,
                ),
                contentPadding: EdgeInsets.all(12),
              ),
              onChanged: (value) {
                setState(() {
                  _newCollectionName = value;
                });
              },
              autocorrect: false,
              keyboardType: TextInputType.text,
              initialValue: _newCollectionName,
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
              color: Colors.white,
            ),
          ),
          onPressed: () {
            if (_newCollectionName.trim().isEmpty) {
              showErrorDialog(
                  context, "empty name", "album name cannot be empty");
              return;
            }
            if (_newCollectionName.trim().length > 100) {
              showErrorDialog(context, "too large",
                  "album name should be less than 100 characters");
              return;
            }
            if (_newCollectionName.trim() == widget.name.trim()) {
              Navigator.of(context).pop(null);
              return;
            }
            Navigator.of(context).pop(_newCollectionName.trim());
          },
        ),
      ],
    );
  }
}
