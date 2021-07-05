
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CustomAppBar extends PreferredSize {
  final Widget child;
  final double height;

  CustomAppBar(this.child, {this.height = kToolbarHeight});

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