import 'package:flutter/material.dart';
import 'package:photos/theme/ente_theme.dart';

class EnteLoadingWidget extends StatelessWidget {
  final Color? color;
  final bool is20pts;
  const EnteLoadingWidget({this.is20pts = false, this.color, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(is20pts ? 3 : 5),
        child: SizedBox.fromSize(
          size: const Size.square(14),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: color ?? getEnteColorScheme(context).strokeBase,
          ),
        ),
      ),
    );
  }
}
