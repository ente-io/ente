import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';

class SearchSuffixIcon extends StatefulWidget {
  final bool shouldShowSpinner;
  const SearchSuffixIcon(this.shouldShowSpinner, {Key? key}) : super(key: key);

  @override
  State<SearchSuffixIcon> createState() => _SearchSuffixIconState();
}

class _SearchSuffixIconState extends State<SearchSuffixIcon>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 175),
      child: widget.shouldShowSpinner
          ? Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                height: 20,
                width: 20,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context)
                        .colorScheme
                        .iconColor
                        .withOpacity(0.5),
                  ),
                ),
              ),
            )
          : IconButton(
              visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(
                Icons.close,
                color: Theme.of(context).colorScheme.iconColor.withOpacity(0.5),
              ),
            ),
    );
  }
}
