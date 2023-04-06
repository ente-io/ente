import 'package:flutter/material.dart';
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";
import "package:photos/core/constants.dart";
import "package:photos/models/local_entity_data.dart";
import "package:photos/models/location_tag/location_tag.dart";
import "package:photos/services/location_service.dart";
import "package:photos/states/location_state.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/components/bottom_of_title_bar_widget.dart";
import "package:photos/ui/components/divider_widget.dart";
import "package:photos/ui/components/keyboard/keybiard_oveylay.dart";
import "package:photos/ui/components/keyboard/keyboard_top_button.dart";
import "package:photos/ui/components/text_input_widget.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import 'package:photos/ui/viewer/location/dynamic_location_gallery_widget.dart';
import "package:photos/ui/viewer/location/edit_center_point_tile_widget.dart";
import "package:photos/ui/viewer/location/radius_picker_widget.dart";

showEditLocationSheet(
  BuildContext context,
  LocalEntity<LocationTag> locationTagEntity,
) {
  showBarModalBottomSheet(
    context: context,
    builder: (context) {
      return LocationTagStateProvider(
        locationTagEntity: locationTagEntity,
        const EditLocationSheet(),
      );
    },
    shape: const RoundedRectangleBorder(
      side: BorderSide(width: 0),
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(5),
      ),
    ),
    topControl: const SizedBox.shrink(),
    backgroundColor: getEnteColorScheme(context).backgroundElevated,
    barrierColor: backdropFaintDark,
  );
}

class EditLocationSheet extends StatefulWidget {
  const EditLocationSheet({
    super.key,
  });

  @override
  State<EditLocationSheet> createState() => _EditLocationSheetState();
}

class _EditLocationSheetState extends State<EditLocationSheet> {
  //The value of these notifiers has no significance.
  //When memoriesCountNotifier is null, we show the loading widget in the
  //memories count section which also means the gallery is loading.
  final ValueNotifier<int?> _memoriesCountNotifier = ValueNotifier(null);
  final ValueNotifier<bool> _submitNotifer = ValueNotifier(false);
  final ValueNotifier<bool> _cancelNotifier = ValueNotifier(false);
  final ValueNotifier<int> _selectedRadiusIndexNotifier =
      ValueNotifier(defaultRadiusValueIndex);
  final _focusNode = FocusNode();
  final _textEditingController = TextEditingController();
  Widget? _keyboardTopButtons;

  @override
  void initState() {
    _focusNode.addListener(_focusNodeListener);
    _selectedRadiusIndexNotifier.addListener(_selectedRadiusIndexListener);
    super.initState();
  }

  @override
  void deactivate() {
    final locationTagState = InheritedLocationTagData.of(context);
    LocationService.instance.updateLocationTag(
      locationTagEntity: locationTagState.locationTagEntity!,
      newRadius: radiusValues[locationTagState.selectedRadiusIndex],
      newName: _textEditingController.text,
    );
    super.deactivate();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_focusNodeListener);
    _submitNotifer.dispose();
    _cancelNotifier.dispose();
    _selectedRadiusIndexNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    final locationName =
        InheritedLocationTagData.of(context).locationTagEntity!.item.name;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 32, 0, 8),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: BottomOfTitleBarWidget(
              title: TitleBarTitleWidget(title: "Edit location"),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                decelerationRate: ScrollDecelerationRate.fast,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        TextInputWidget(
                          //todo: get location name from location tag here
                          hintText: "Location name",
                          borderRadius: 2,
                          focusNode: _focusNode,
                          submitNotifier: _submitNotifer,
                          cancelNotifier: _cancelNotifier,
                          popNavAfterSubmission: true,
                          onSubmit: (locationName) async {
                            // await _addLocationTag(locationName);
                            //todo: Edit location tag here
                          },
                          shouldUnfocusOnClearOrSubmit: true,
                          alwaysShowSuccessState: true,
                          initialValue: locationName,
                          onCancel: () {
                            _focusNode.unfocus();
                            _textEditingController.value =
                                TextEditingValue(text: locationName);
                          },
                          textEditingController: _textEditingController,
                        ),
                        const SizedBox(height: 20),
                        const EditCenterPointTileWidget(),
                        const SizedBox(height: 20),
                        RadiusPickerWidget(
                          _selectedRadiusIndexNotifier,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  const DividerWidget(
                    dividerType: DividerType.solid,
                    padding: EdgeInsets.only(top: 24, bottom: 20),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ValueListenableBuilder(
                        valueListenable: _memoriesCountNotifier,
                        builder: (context, value, _) {
                          Widget widget;
                          if (value == null) {
                            widget = RepaintBoundary(
                              child: EnteLoadingWidget(
                                size: 14,
                                color: colorScheme.strokeMuted,
                                alignment: Alignment.centerLeft,
                                padding: 3,
                              ),
                            );
                          } else {
                            widget = Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  value == 1 ? "1 memory" : "$value memories",
                                  style: textTheme.body,
                                ),
                                if (value as int > 1000)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      "Up to 1000 memories shown in gallery",
                                      style: textTheme.miniMuted,
                                    ),
                                  ),
                              ],
                            );
                          }
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              switchInCurve: Curves.easeInOutExpo,
                              switchOutCurve: Curves.easeInOutExpo,
                              child: widget,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  DynamicLocationGalleryWidget(
                    _memoriesCountNotifier,
                    "Edit_location",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _focusNodeListener() {
    final bool hasFocus = _focusNode.hasFocus;
    _keyboardTopButtons ??= KeyboardTopButton(
      onDoneTap: () {
        _submitNotifer.value = !_submitNotifer.value;
      },
      onCancelTap: () {
        _cancelNotifier.value = !_cancelNotifier.value;
      },
    );
    if (hasFocus) {
      KeyboardOverlay.showOverlay(context, _keyboardTopButtons!);
    } else {
      KeyboardOverlay.removeOverlay();
    }
  }

  void _selectedRadiusIndexListener() {
    InheritedLocationTagData.of(
      context,
    ).updateSelectedIndex(
      _selectedRadiusIndexNotifier.value,
    );
    _memoriesCountNotifier.value = null;
  }
}
