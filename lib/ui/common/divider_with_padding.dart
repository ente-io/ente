import 'package:flutter/material.dart';

class DividerWithPadding extends StatelessWidget {
  final double left, top, right, bottom, thickness;

  const DividerWithPadding({
    Key? key,
    this.left = 0,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
    this.thickness = 0.5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(left, top, right, bottom),
      child: Divider(
        thickness: thickness,
      ),
    );
  }
}
