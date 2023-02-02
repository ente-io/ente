import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/force_reload_home_gallery_event.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/icon_button_widget.dart';
import 'package:photos/ui/components/menu_item_widget.dart';
import 'package:photos/ui/components/title_bar_title_widget.dart';
import 'package:photos/ui/components/title_bar_widget.dart';
import 'package:photos/ui/tools/debug/app_storage_viewer.dart';
import 'package:photos/utils/local_settings.dart';
import 'package:photos/utils/navigation_util.dart';

class AdvancedSettingsScreen extends StatefulWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  State<AdvancedSettingsScreen> createState() => _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends State<AdvancedSettingsScreen> {
  late int _photoGridSize, _chosenGridSize;

  @override
  void initState() {
    _photoGridSize = LocalSettings.instance.getPhotoGridSize();
    _chosenGridSize = _photoGridSize;
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
              (delegateBuildContext, index) {
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
                                _showPhotoGridSizePicker(delegateBuildContext);
                              },
                              child: MenuItemWidget(
                                captionedTextWidget: CaptionedTextWidget(
                                  title: "Photo grid size",
                                  subTitle: _photoGridSize.toString(),
                                ),
                                menuItemColor: colorScheme.fillFaint,
                                trailingWidget: Icon(
                                  Icons.chevron_right_outlined,
                                  color: colorScheme.strokeBase,
                                ),
                                singleBorderRadius: 8,
                                alignCaptionedTextToLeft: true,
                                // isBottomBorderRadiusRemoved: true,
                                isGestureDetectorDisabled: true,
                              ),
                            ),
                            const SizedBox(
                              height: 24,
                            ),
                            MenuItemWidget(
                              captionedTextWidget: const CaptionedTextWidget(
                                title: "Manage device storage",
                              ),
                              menuItemColor: colorScheme.fillFaint,
                              trailingWidget: Icon(
                                Icons.chevron_right_outlined,
                                color: colorScheme.strokeBase,
                              ),
                              singleBorderRadius: 8,
                              alignCaptionedTextToLeft: true,
                              onTap: () {
                                routeToPage(context, const AppStorageViewer());
                              },
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

  Future<void> _showPhotoGridSizePicker(BuildContext buildContext) async {
    final textTheme = getEnteTextTheme(buildContext);
    final List<Text> options = [];
    for (int gridSize = photoGridSizeMin;
        gridSize <= photoGridSizeMax;
        gridSize++) {
      options.add(
        Text(
          gridSize.toString(),
          style: textTheme.body,
        ),
      );
    }
    return showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: getEnteColorScheme(buildContext).backgroundElevated2,
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
                      style: textTheme.body,
                    ),
                  ),
                  CupertinoButton(
                    onPressed: () async {
                      await LocalSettings.instance
                          .setPhotoGridSize(_chosenGridSize);
                      Bus.instance.fire(
                        ForceReloadHomeGalleryEvent("grid size changed"),
                      );
                      _photoGridSize = _chosenGridSize;
                      setState(() {});
                      Navigator.of(context).pop('');
                    },
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 2.0,
                    ),
                    child: Text(
                      'Confirm',
                      style: textTheme.body,
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
                    getEnteColorScheme(buildContext).backgroundElevated,
                onSelectedItemChanged: (index) {
                  _chosenGridSize = _getPhotoGridSizeFromIndex(index);
                  setState(() {});
                },
                scrollController: FixedExtentScrollController(
                  initialItem: _getIndexFromPhotoGridSize(_chosenGridSize),
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

  int _getPhotoGridSizeFromIndex(int index) {
    return index + 2;
  }

  int _getIndexFromPhotoGridSize(int gridSize) {
    return gridSize - 2;
  }
}
