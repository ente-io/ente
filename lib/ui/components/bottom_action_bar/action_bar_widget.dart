import 'package:flutter/material.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/theme/ente_theme.dart';

class ActionBarWidget extends StatefulWidget {
  final String? text;
  final List<Widget> iconButtons;
  final SelectedFiles? selectedFiles;
  const ActionBarWidget({
    required this.iconButtons,
    this.text,
    this.selectedFiles,
    super.key,
  });

  @override
  State<ActionBarWidget> createState() => _ActionBarWidgetState();
}

class _ActionBarWidgetState extends State<ActionBarWidget> {
  final ValueNotifier<int> _selectedFilesNotifier = ValueNotifier(0);

  @override
  void initState() {
    widget.selectedFiles?.addListener(_selectedFilesListener);
    super.initState();
  }

  @override
  void dispose() {
    widget.selectedFiles?.removeListener(_selectedFilesListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _actionBarWidgets(context),
      ),
    );
  }

  List<Widget> _actionBarWidgets(BuildContext context) {
    final actionBarWidgets = <Widget>[];
    final initialLength = widget.iconButtons.length;
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);

    actionBarWidgets.addAll(widget.iconButtons);
    if (widget.text != null) {
      //adds 12 px spacing at the start and between iconButton elements
      for (var i = 0; i < initialLength; i++) {
        actionBarWidgets.insert(
          2 * i,
          const SizedBox(
            width: 12,
          ),
        );
      }
      actionBarWidgets.insertAll(0, [
        const SizedBox(width: 20),
        Flexible(
          child: Row(
            children: [
              widget.selectedFiles != null
                  ? ValueListenableBuilder(
                      valueListenable: _selectedFilesNotifier,
                      builder: (context, value, child) {
                        return Text(
                          "${_selectedFilesNotifier.value} selected",
                          style: textTheme.small.copyWith(
                            color: colorScheme.blurTextBase,
                          ),
                        );
                      },
                    )
                  : Text(
                      widget.text!,
                      style: textTheme.small
                          .copyWith(color: colorScheme.textMuted),
                    ),
            ],
          ),
        ),
      ]);
      //to add whitespace of 8pts or 12 pts at the end
      if (widget.iconButtons.length > 1) {
        actionBarWidgets.add(
          const SizedBox(width: 8),
        );
      } else {
        actionBarWidgets.add(
          const SizedBox(width: 12),
        );
      }
    }
    return actionBarWidgets;
  }

  void _selectedFilesListener() {
    if (widget.selectedFiles!.files.isNotEmpty) {
      _selectedFilesNotifier.value = widget.selectedFiles!.files.length;
    }
  }
}
