import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/events/force_reload_home_gallery_event.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/icon_button_widget.dart';
import 'package:photos/ui/components/menu_item_widget.dart';
import 'package:photos/ui/components/title_bar_title_widget.dart';
import 'package:photos/ui/components/title_bar_widget.dart';
import 'package:photos/utils/local_settings.dart';

class AdvancedSettingsScreen extends StatefulWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  State<AdvancedSettingsScreen> createState() => _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends State<AdvancedSettingsScreen> {
  late int _albumGridSize, _chosenGridSize;

  @override
  void initState() {
    _albumGridSize = LocalSettings.instance.getAlbumGridSize();
    _chosenGridSize = _albumGridSize;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          TitleBarWidget(
            flexibleSpaceTitle: const TitleBarTitleWidget(
              title: "Advanced",
            ),
            actionIcons: [
              IconButtonWidget(
                icon: Icons.close_outlined,
                iconButtonType: IconButtonType.secondary,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                _showAlbumGridSizePicker();
                              },
                              child: MenuItemWidget(
                                captionedTextWidget: const CaptionedTextWidget(
                                  title: "Album grid size",
                                ),
                                menuItemColor: colorScheme.fillFaint,
                                trailingWidget: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      _albumGridSize.toString(),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: colorScheme.strokeMuted,
                                    ),
                                  ],
                                ),
                                borderRadius: 8,
                                alignCaptionedTextToLeft: true,
                                // isBottomBorderRadiusRemoved: true,
                                isGestureDetectorDisabled: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: 1,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAlbumGridSizePicker() async {
    final List<Text> options = [];
    options.add(
      Text("2", style: Theme.of(context).textTheme.subtitle1),
    );
    options.add(
      Text("3", style: Theme.of(context).textTheme.subtitle1),
    );
    options.add(
      Text("4", style: Theme.of(context).textTheme.subtitle1),
    );
    return showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.cupertinoPickerTopColor,
                border: const Border(
                  bottom: BorderSide(
                    color: Color(0xff999999),
                    width: 0.0,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  CupertinoButton(
                    onPressed: () {
                      Navigator.of(context).pop('cancel');
                    },
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 5.0,
                    ),
                    child: Text(
                      'Cancel',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ),
                  CupertinoButton(
                    onPressed: () async {
                      await LocalSettings.instance
                          .setAlbumGridSize(_chosenGridSize);
                      Bus.instance.fire(
                        ForceReloadHomeGalleryEvent("grid size changed"),
                      );
                      _albumGridSize = _chosenGridSize;
                      setState(() {});
                      Navigator.of(context).pop('');
                    },
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 2.0,
                    ),
                    child: Text(
                      'Confirm',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  )
                ],
              ),
            ),
            Container(
              height: 220.0,
              color: const Color(0xfff7f7f7),
              child: CupertinoPicker(
                backgroundColor:
                    Theme.of(context).backgroundColor.withOpacity(0.95),
                onSelectedItemChanged: (index) {
                  _chosenGridSize = _getAlbumGridSizeFromIndex(index);
                  setState(() {});
                },
                scrollController: FixedExtentScrollController(
                  initialItem: _getIndexFromAlbumGridSize(_chosenGridSize),
                ),
                magnification: 1.3,
                useMagnifier: true,
                itemExtent: 25,
                diameterRatio: 1,
                children: options,
              ),
            )
          ],
        );
      },
    );
  }

  int _getAlbumGridSizeFromIndex(int index) {
    return index + 2;
  }

  int _getIndexFromAlbumGridSize(int gridSize) {
    return gridSize - 2;
  }
}
