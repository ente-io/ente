import 'dart:ui';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/models/file.dart';
import 'package:photos/ui/thumbnail_widget.dart';

class BlurredFileBackdrop extends StatelessWidget {
  final File file;

  BlurredFileBackdrop(this.file, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FadeIn(
      duration: Duration(milliseconds: 500),
      child: Stack(children: [
        ThumbnailWidget(
          file,
          fit: BoxFit.cover,
          key: Key("memory_backdrop" + file.tag()),
        ),
        BackdropFilter(
          filter: new ImageFilter.blur(sigmaX: 64.0, sigmaY: 64.0),
          child: new Container(
            decoration: new BoxDecoration(color: Colors.white.withOpacity(0.0)),
          ),
        ),
      ]),
    );
  }
}
