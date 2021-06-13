import 'package:flutter/material.dart';

class ListDialog extends StatefulWidget {
  const ListDialog({
    Key? key,
    required this.children,
  }) : super(key: key);

  final List<Widget> children;

  @override
  _ListDialogState createState() => _ListDialogState();
}

class _ListDialogState extends State<ListDialog> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ListView(
        children: widget.children,
        shrinkWrap: true,
      ),
    );
  }
}
