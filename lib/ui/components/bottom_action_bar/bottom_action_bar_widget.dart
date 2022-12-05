import 'dart:ui';

import 'package:expandable/expandable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/theme/effects.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/bottom_action_bar/action_bar_widget.dart';
import 'package:photos/ui/components/icon_button_widget.dart';
import 'package:photos/utils/delete_file_util.dart';
import 'package:photos/utils/share_util.dart';
import 'package:photos/utils/toast_util.dart';

class BottomActionBarWidget extends StatelessWidget {
  final String? text;
  final List<Widget>? iconButtons;
  final Widget expandedMenu;
  final SelectedFiles? selectedFiles;
  final VoidCallback? onCancel;
  final GlobalKey shareButtonKey = GlobalKey();

  BottomActionBarWidget({
    required this.expandedMenu,
    this.selectedFiles,
    this.text,
    this.iconButtons,
    this.onCancel,
    super.key,
  });

  final ExpandableController _expandableController =
      ExpandableController(initialExpanded: false);

  @override
  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    //todo : restrict width of column
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurBase, sigmaY: blurBase),
        child: Container(
          color: colorScheme.backdropBase,
          padding: const EdgeInsets.only(
            top: 4,
            // bottom: !_expandableController.expanded &&
            //         ((widget.selectedFiles?.files.isNotEmpty) ?? false)
            //     ? 24
            //     : 36,
            bottom: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExpandableNotifier(
                controller: _expandableController,
                child: ExpandablePanel(
                  theme: _getExpandableTheme(),
                  header: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: text == null ? 12 : 0,
                    ),
                    child: ActionBarWidget(
                      selectedFiles: selectedFiles,
                      text: text,
                      iconButtons: _iconButtons(context),
                    ),
                  ),
                  expanded: expandedMenu,
                  collapsed: const SizedBox.shrink(),
                  controller: _expandableController,
                ),
              ),
              GestureDetector(
                onTap: () {
                  //unselect all files here
                  //or collapse the expansion panel
                  onCancel?.call();
                  _expandableController.value = false;
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Center(
                    child: Text(
                      "Cancel",
                      style: textTheme.bodyBold
                          .copyWith(color: colorScheme.blurTextBase),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _iconButtons(BuildContext context) {
    final iconButtonsWithExpansionIcon = <Widget?>[
      IconButtonWidget(
        icon: Icons.delete_outlined,
        iconButtonType: IconButtonType.primary,
        onTap: () => _showDeleteSheet(context),
      ),
      IconButtonWidget(
        icon: Icons.ios_share_outlined,
        iconButtonType: IconButtonType.primary,
        onTap: () => _shareSelected(context),
      ),
      ExpansionIconWidget(expandableController: _expandableController)
    ];
    iconButtonsWithExpansionIcon.removeWhere((element) => element == null);
    return iconButtonsWithExpansionIcon as List<Widget>;
  }

  void _showDeleteSheet(BuildContext context) {
    final count = selectedFiles!.files.length;
    bool containsUploadedFile = false, containsLocalFile = false;
    for (final file in selectedFiles!.files) {
      if (file.uploadedFileID != null) {
        containsUploadedFile = true;
      }
      if (file.localID != null) {
        containsLocalFile = true;
      }
    }
    final actions = <Widget>[];
    if (containsUploadedFile && containsLocalFile) {
      actions.add(
        CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () async {
            Navigator.of(context, rootNavigator: true).pop();
            await deleteFilesOnDeviceOnly(
              context,
              selectedFiles!.files.toList(),
            );
            _clearSelectedFiles();
            showToast(context, "Files deleted from device");
          },
          child: const Text("Device"),
        ),
      );
      actions.add(
        CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () async {
            Navigator.of(context, rootNavigator: true).pop();
            await deleteFilesFromRemoteOnly(
              context,
              selectedFiles!.files.toList(),
            );
            _clearSelectedFiles();
            showShortToast(context, "Moved to trash");
          },
          child: const Text("ente"),
        ),
      );
      actions.add(
        CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () async {
            Navigator.of(context, rootNavigator: true).pop();
            await deleteFilesFromEverywhere(
              context,
              selectedFiles!.files.toList(),
            );
            _clearSelectedFiles();
          },
          child: const Text("Everywhere"),
        ),
      );
    } else {
      actions.add(
        CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () async {
            Navigator.of(context, rootNavigator: true).pop();
            await deleteFilesFromEverywhere(
              context,
              selectedFiles!.files.toList(),
            );
            _clearSelectedFiles();
          },
          child: const Text("Delete"),
        ),
      );
    }
    final action = CupertinoActionSheet(
      title: Text(
        "Delete " +
            count.toString() +
            " file" +
            (count == 1 ? "" : "s") +
            (containsUploadedFile && containsLocalFile ? " from" : "?"),
      ),
      actions: actions,
      cancelButton: CupertinoActionSheetAction(
        child: const Text("Cancel"),
        onPressed: () {
          Navigator.of(context, rootNavigator: true).pop();
        },
      ),
    );
    showCupertinoModalPopup(
      context: context,
      builder: (_) => action,
      barrierColor: Colors.black.withOpacity(0.75),
    );
  }

  void _shareSelected(BuildContext context) {
    share(
      context,
      selectedFiles!.files.toList(),
      shareButtonKey: shareButtonKey,
    );
  }

  void _clearSelectedFiles() {
    selectedFiles!.clearAll();
  }

  ExpandableThemeData _getExpandableTheme() {
    return const ExpandableThemeData(
      hasIcon: false,
      useInkWell: false,
      tapBodyToCollapse: false,
      tapBodyToExpand: false,
      tapHeaderToExpand: false,
      animationDuration: Duration(milliseconds: 400),
    );
  }
}

class ExpansionIconWidget extends StatefulWidget {
  final ExpandableController expandableController;
  const ExpansionIconWidget({required this.expandableController, super.key});

  @override
  State<ExpansionIconWidget> createState() => _ExpansionIconWidgetState();
}

class _ExpansionIconWidgetState extends State<ExpansionIconWidget> {
  @override
  void initState() {
    widget.expandableController.addListener(_expandableListener);
    super.initState();
  }

  @override
  void dispose() {
    widget.expandableController.removeListener(_expandableListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeInOutExpo,
      child: widget.expandableController.value
          ? IconButtonWidget(
              key: const ValueKey<bool>(false),
              onTap: () {
                widget.expandableController.value = false;
                setState(() {});
              },
              icon: Icons.expand_more_outlined,
              iconButtonType: IconButtonType.primary,
            )
          : IconButtonWidget(
              key: const ValueKey<bool>(true),
              onTap: () {
                widget.expandableController.value = true;
                setState(() {});
              },
              icon: Icons.more_horiz_outlined,
              iconButtonType: IconButtonType.primary,
            ),
    );
  }

  _expandableListener() {
    if (mounted) {
      setState(() {});
    }
  }
}
