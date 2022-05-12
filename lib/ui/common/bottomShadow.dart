import 'package:flutter/material.dart';

class BottomShadowWidget extends StatelessWidget {
  final double offsetDy;
  const BottomShadowWidget({this.offsetDy = 28, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
              color: Theme.of(context).backgroundColor,
              spreadRadius: 42,
              blurRadius: 42,
              offset: Offset(0, offsetDy) // changes position of shadow
              ),
        ],
      ),
    );
  }
}
