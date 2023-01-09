import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';

class FileInfoCollectionWidget extends StatelessWidget {
  final String? name;
  final Function? onTap;
  const FileInfoCollectionWidget({this.name, this.onTap, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap as void Function()?,
      child: Container(
        margin: const EdgeInsets.only(
          top: 10,
          bottom: 18,
          right: 8,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .inverseBackgroundColor
              .withOpacity(0.025),
          borderRadius: const BorderRadius.all(
            Radius.circular(8),
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              name!,
              style: Theme.of(context).textTheme.subtitle2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
