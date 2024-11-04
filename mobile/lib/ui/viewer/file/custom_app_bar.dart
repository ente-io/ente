import 'package:flutter/material.dart';

class CustomAppBar extends PreferredSize {
  @override
  final Widget child;
  @override
  final Size preferredSize;
  final double height;

  const CustomAppBar(
    this.child,
    this.preferredSize, {
    super.key,
    this.height = kToolbarHeight,
  }) : super(child: child, preferredSize: preferredSize);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      alignment: Alignment.center,
      child: child,
    );
  }
}
