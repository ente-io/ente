import 'package:flutter/material.dart';
import 'package:photos/ui/loading_widget.dart';

class LoadingPhotosWidget extends StatefulWidget {
  @override
  _LoadingPhotosWidgetState createState() => _LoadingPhotosWidgetState();
}

class _LoadingPhotosWidgetState extends State<LoadingPhotosWidget> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          loadWidget,
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Hang on tight, your photos will appear in a jiffy! 🐣",
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
