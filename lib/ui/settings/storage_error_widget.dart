import 'package:flutter/material.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/ente_theme.dart';

class StorageErrorWidget extends StatelessWidget {
  const StorageErrorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(
            Icons.error_outline_outlined,
            color: strokeBaseDark,
          ),
          const SizedBox(height: 8),
          Text(
            "Your storage details could not be fetched",
            style: getEnteTextTheme(context).small.copyWith(
                  color: textMutedDark,
                ),
          ),
        ],
      ),
    );
  }
}
