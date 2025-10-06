import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/selected_files.dart';
import 'package:photos/theme/ente_theme.dart';

class ActionBarWidget extends StatefulWidget {
  final Color? backgroundColor;
  final SelectedFiles? selectedFiles;
  final VoidCallback? onCancel;

  const ActionBarWidget({
    required this.onCancel,
    this.selectedFiles,
    super.key,
    required this.backgroundColor,
  });

  @override
  State<ActionBarWidget> createState() => _ActionBarWidgetState();
}

class _ActionBarWidgetState extends State<ActionBarWidget> {
  final ValueNotifier<int> _selectedFilesNotifier = ValueNotifier(0);
  final ValueNotifier<int> _selectedOwnedFilesNotifier = ValueNotifier(0);

  //User ID will be null if the user is not logged in (links-in-app)
  final int currentUserID = Configuration.instance.getUserID() ?? -1;

  @override
  void initState() {
    widget.selectedFiles?.addListener(_selectedFilesListener);
    super.initState();
  }

  @override
  void dispose() {
    _selectedFilesNotifier.dispose();
    _selectedOwnedFilesNotifier.dispose();
    widget.selectedFiles?.removeListener(_selectedFilesListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? colorScheme.backgroundElevated2,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder(
            valueListenable: _selectedFilesNotifier,
            builder: (context, value, child) {
              return Text(
                _selectedOwnedFilesNotifier.value !=
                        _selectedFilesNotifier.value
                    ? AppLocalizations.of(context).selectedPhotosWithYours(
                        count: _selectedFilesNotifier.value,
                        yourCount: _selectedOwnedFilesNotifier.value,
                      )
                    : AppLocalizations.of(context).selectedPhotos(
                        count: _selectedFilesNotifier.value,
                      ),
                style: textTheme.mini,
              );
            },
          ),
          const SizedBox(width: 4),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              widget.onCancel?.call();
            },
            child: Align(
              alignment: Alignment.centerRight,
              child: Icon(
                Icons.close,
                size: 16,
                color: textTheme.mini.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectedFilesListener() {
    if (widget.selectedFiles!.files.isNotEmpty) {
      _selectedFilesNotifier.value = widget.selectedFiles!.files.length;
      _selectedOwnedFilesNotifier.value = widget.selectedFiles!.files
          .where((f) => f.ownerID == null || f.ownerID! == currentUserID)
          .length;
    }
  }
}
