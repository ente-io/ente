import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:photos/ente_theme_data.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:pro_image_editor/pro_image_editor.dart";

class ContactPhotoAdjustPage extends StatefulWidget {
  final Uint8List imageBytes;

  const ContactPhotoAdjustPage({
    required this.imageBytes,
    super.key,
  });

  @override
  State<ContactPhotoAdjustPage> createState() => _ContactPhotoAdjustPageState();
}

class _ContactPhotoAdjustPageState extends State<ContactPhotoAdjustPage> {
  bool _isReturningBytes = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final isLightMode = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: colorScheme.backgroundBase,
      body: CropRotateEditor.memory(
        widget.imageBytes,
        initConfigs: CropRotateEditorInitConfigs(
          theme: ThemeData(
            scaffoldBackgroundColor: colorScheme.backgroundBase,
            appBarTheme: AppBarTheme(
              titleTextStyle: textTheme.body,
              backgroundColor: colorScheme.backgroundBase,
            ),
            bottomAppBarTheme: BottomAppBarTheme(
              color: colorScheme.backgroundBase,
            ),
            brightness: isLightMode ? Brightness.light : Brightness.dark,
          ),
          convertToUint8List: true,
          callbacks: ProImageEditorCallbacks(
            onImageEditingComplete: (bytes) async {
              if (mounted) {
                Navigator.of(context).pop(bytes);
              }
            },
          ),
          configs: ProImageEditorConfigs(
            imageGeneration: const ImageGenerationConfigs(
              jpegQuality: 100,
              enableIsolateGeneration: true,
              pngLevel: 0,
            ),
            cropRotateEditor: CropRotateEditorConfigs(
              showRotateButton: false,
              showFlipButton: false,
              showAspectRatioButton: false,
              showResetButton: false,
              initAspectRatio: 1.0,
              aspectRatios: const [
                AspectRatioItem(text: "1*1", value: 1.0),
              ],
              style: CropRotateEditorStyle(
                background: colorScheme.backgroundBase,
                cropCornerColor:
                    Theme.of(context).colorScheme.imageEditorPrimaryColor,
              ),
              widgets: CropRotateEditorWidgets(
                appBar: (editor, rebuildStream) => ReactiveAppbar(
                  stream: rebuildStream,
                  builder: (_) => AppBar(
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    backgroundColor: colorScheme.backgroundBase,
                    titleSpacing: 0,
                    title: Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            AppLocalizations.of(context).cancel,
                            style: textTheme.body,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _isReturningBytes
                              ? null
                              : () async {
                                  setState(() {
                                    _isReturningBytes = true;
                                  });
                                  await editor.done();
                                },
                          child: Text(
                            AppLocalizations.of(context).useSelectedPhoto,
                            style: textTheme.body.copyWith(
                              color: _isReturningBytes
                                  ? colorScheme.textMuted
                                  : Theme.of(context)
                                      .colorScheme
                                      .imageEditorPrimaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                bottomBar: (_, rebuildStream) => ReactiveWidget<Widget>(
                  stream: rebuildStream,
                  builder: (_) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
