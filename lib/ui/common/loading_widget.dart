import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photos/theme/ente_theme.dart';

class EnteLoadingWidget extends StatelessWidget {
  final Color? color;
  const EnteLoadingWidget({this.color, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox.fromSize(
          size: const Size.square(16),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: color ?? getEnteColorScheme(context).strokeBase,
          ),
        ),
      ),
    );
  }
}
