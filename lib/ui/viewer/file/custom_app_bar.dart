import 'package:flutter/material.dart';

class CustomAppBar extends PreferredSize {
  @override
  final Widget child;
  final double height;

  const CustomAppBar(this.child, {Key key, this.height = kToolbarHeight})
      : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      alignment: Alignment.center,
      child: child,
    );
  }
}
