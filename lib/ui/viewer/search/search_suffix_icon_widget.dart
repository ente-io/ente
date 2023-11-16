import 'package:flutter/material.dart';
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/viewer/search/search_widget.dart';

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
                final searchWidgetState =
                    context.findAncestorStateOfType<SearchWidgetState>()!;
                searchWidgetState.textController.clear();
                searchWidgetState.focusNode.unfocus();
              },
              icon: Icon(
                Icons.close,
                color: colorScheme.strokeMuted,
              ),
            ),
    );
  }
}
