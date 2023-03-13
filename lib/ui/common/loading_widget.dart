import 'package:flutter/material.dart';
import 'package:photos/theme/ente_theme.dart';

class EnteLoadingWidget extends StatelessWidget {
  final Color? color;
  final double size;
  final double padding;
  const EnteLoadingWidget({
    this.color,
    this.size = 14,
    this.padding = 5,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: SizedBox.fromSize(
          size: Size.square(size),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: color ?? getEnteColorScheme(context).strokeBase,
          ),
        ),
      ),
    );
  }
}
