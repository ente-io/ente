import 'package:flutter/material.dart';
import "package:photos/core/event_bus.dart";
import "package:photos/events/clear_and_unfocus_search_bar_event.dart";
import "package:photos/theme/ente_theme.dart";

class SearchSuffixIcon extends StatefulWidget {
  final bool shouldShowSpinner;
  const SearchSuffixIcon(this.shouldShowSpinner, {super.key});

  @override
  State<SearchSuffixIcon> createState() => _SearchSuffixIconState();
}

class _SearchSuffixIconState extends State<SearchSuffixIcon> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
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
                    color: colorScheme.strokeMuted,
                  ),
                ),
              ),
            )
          : IconButton(
              splashRadius: 1,
              visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
              onPressed: () {
                Bus.instance.fire(ClearAndUnfocusSearchBar());
              },
              icon: Icon(
                Icons.close,
                color: colorScheme.strokeMuted,
              ),
            ),
    );
  }
}
