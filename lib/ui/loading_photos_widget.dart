import 'package:flutter/material.dart';
import 'package:photos/ui/loading_widget.dart';

class LoadingPhotosWidget extends StatelessWidget {
  const LoadingPhotosWidget({Key key}) : super(key: key);

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
              "hang on tight, your photos will appear in a jiffy! 🐣",
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
