import 'package:flutter/material.dart';
import "package:flutter_svg/svg.dart";
import "package:photos/ente_theme_data.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:pro_image_editor/models/editor_configs/pro_image_editor_configs.dart";

class ImageEditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ImageEditorAppBar({
    super.key,
    required this.configs,
    this.undo,
    this.redo,
    required this.done,
    required this.close,
    this.enableUndo = false,
    this.enableRedo = false,
    this.isMainEditor = false,
  });

  final ProImageEditorConfigs configs;
  final Function()? undo;
  final Function()? redo;
  final Function() done;
  final Function() close;
  final bool enableUndo;
  final bool enableRedo;
  final bool isMainEditor;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return AppBar(
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () {
              enableUndo ? close() : Navigator.of(context).pop();
            },
            child: Text(
              AppLocalizations.of(context).cancel,
              style: getEnteTextTheme(context).body,
            ),
          ),
          if (undo != null && redo != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  tooltip: AppLocalizations.of(context).undo,
                  onPressed: () {
                    undo != null ? undo!() : null;
                  },
                  icon: SvgPicture.asset(
                    "assets/image-editor/image-editor-undo.svg",
                    colorFilter: ColorFilter.mode(
                      enableUndo ? colorScheme.textBase : colorScheme.textMuted,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: AppLocalizations.of(context).redo,
                  onPressed: () {
                    redo != null ? redo!() : null;
                  },
                  icon: SvgPicture.asset(
                    'assets/image-editor/image-editor-redo.svg',
                    colorFilter: ColorFilter.mode(
                      enableRedo ? colorScheme.textBase : colorScheme.textMuted,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ],
            ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: TextButton(
              key: ValueKey(isMainEditor ? 'save_copy' : 'done'),
              onPressed: done,
              child: Text(
                isMainEditor
                    ? AppLocalizations.of(context).saveCopy
                    : AppLocalizations.of(context).done,
                style: getEnteTextTheme(context).body.copyWith(
                      color: isMainEditor
                          ? (enableUndo
                              ? Theme.of(context)
                                  .colorScheme
                                  .imageEditorPrimaryColor
                              : colorScheme.textMuted)
                          : Theme.of(context)
                              .colorScheme
                              .imageEditorPrimaryColor,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
