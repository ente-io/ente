import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';

class SearchSuffixIcon extends StatelessWidget {
  final Timer debounce;
  const SearchSuffixIcon(this.debounce, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (debounce == null || !debounce.isActive) {
      return IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: Icon(
          Icons.close,
          color: Theme.of(context).colorScheme.iconColor.withOpacity(0.5),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: 6,
          width: 6,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.iconColor.withOpacity(0.5),
            ),
          ),
        ),
      );
    }
  }
}
