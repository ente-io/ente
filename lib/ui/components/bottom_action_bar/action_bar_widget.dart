import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/selected_files.dart';
import 'package:photos/theme/ente_theme.dart';

class ActionBarWidget extends StatefulWidget {
  final SelectedFiles? selectedFiles;
  final VoidCallback? onCancel;

  const ActionBarWidget({
    required this.onCancel,
    this.selectedFiles,
    super.key,
  });

  @override
  State<ActionBarWidget> createState() => _ActionBarWidgetState();
}

class _ActionBarWidgetState extends State<ActionBarWidget> {
  final ValueNotifier<int> _selectedFilesNotifier = ValueNotifier(0);
  final ValueNotifier<int> _selectedOwnedFilesNotifier = ValueNotifier(0);
  final int currentUserID = Configuration.instance.getUserID()!;

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
    return SizedBox(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 64),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ValueListenableBuilder(
              valueListenable: _selectedFilesNotifier,
              builder: (context, value, child) {
                return Text(
                  _selectedOwnedFilesNotifier.value !=
                          _selectedFilesNotifier.value
                      ? S.of(context).selectedPhotosWithYours(
                            _selectedFilesNotifier.value,
                            _selectedOwnedFilesNotifier.value,
                          )
                      : S.of(context).selectedPhotos(
                            _selectedFilesNotifier.value,
                          ),
                  style: textTheme.body.copyWith(
                    color: colorScheme.blurTextBase,
                  ),
                );
              },
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                widget.onCancel?.call();
              },
              child: Center(
                child: Text(
                  S.of(context).cancel,
                  style: textTheme.bodyBold
                      .copyWith(color: colorScheme.blurTextBase),
                ),
              ),
            ),
          ],
        ),
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
