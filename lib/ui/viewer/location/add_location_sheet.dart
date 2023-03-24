import 'package:flutter/material.dart';
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";
import "package:photos/core/constants.dart";
import "package:photos/services/location_service.dart";
import "package:photos/states/add_location_state.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/components/bottom_of_title_bar_widget.dart";
import "package:photos/ui/components/divider_widget.dart";
import "package:photos/ui/components/keyboard/keybiard_oveylay.dart";
import "package:photos/ui/components/keyboard/keyboard_top_button.dart";
import "package:photos/ui/components/text_input_widget.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/viewer/location/add_location_gallery_widget.dart";
import "package:photos/ui/viewer/location/radius_picker_widget.dart";

showAddLocationSheet(BuildContext context, List<double> coordinates) {
  showBarModalBottomSheet(
    context: context,
    builder: (context) {
      return LocationTagDataStateProvider(
        coordinates,
        const AddLocationSheet(),
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
    enableDrag: false,
  );
}

class AddLocationSheet extends StatefulWidget {
  const AddLocationSheet({super.key});

  @override
  State<AddLocationSheet> createState() => _AddLocationSheetState();
}

class _AddLocationSheetState extends State<AddLocationSheet> {
  //When memoriesCountNotifier is null, we show the loading widget in the
  //memories count section which also means the gallery is loading.
  ValueNotifier<int?> memoriesCountNotifier = ValueNotifier(null);
  //The value of this notifier has no significance.
  ValueNotifier<bool> submitNotifer = ValueNotifier(false);
  ValueNotifier<bool> cancelNotifier = ValueNotifier(false);
  final _focusNode = FocusNode();
  Widget? keyboardTopButtons;

  @override
  void initState() {
    _focusNode.addListener(_focusNodeListener);
    super.initState();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_focusNodeListener);
    submitNotifer.dispose();
    cancelNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 32, 0, 8),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: BottomOfTitleBarWidget(
              title: TitleBarTitleWidget(title: "Add location"),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        TextInputWidget(
                          hintText: "Location name",
                          borderRadius: 2,
                          focusNode: _focusNode,
                          submitNotifier: submitNotifer,
                          cancelNotifier: cancelNotifier,
                          onSubmit: (string) async {
                            final locationData =
                                InheritedLocationTagData.of(context);
                            final coordinates = locationData.coordinates;
                            final radius =
                                radiusValues[locationData.selectedRadiusIndex];
                            LocationService.instance.addLocation(
                              string,
                              coordinates.first,
                              coordinates.last,
                              radius,
                            );
                          },
                          shouldUnfocusOnClearOrSubmit: true,
                          alwaysShowSuccessState: true,
                        ),
                        const SizedBox(height: 24),
                        RadiusPickerWidget(memoriesCountNotifier),
                        const SizedBox(height: 24),
                        Text(
                          "A location tag groups all photos that were taken within some radius of a photo",
                          style: textTheme.smallMuted,
                        ),
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
                        valueListenable: memoriesCountNotifier,
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
                            widget = Text(
                              value == 1 ? "1 memory" : "$value memories",
                              style: textTheme.body,
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
                  AddLocationGalleryWidget(memoriesCountNotifier),
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
    keyboardTopButtons ??= KeyboardTopButton(
      onDoneTap: () {
        submitNotifer.value = !submitNotifer.value;
      },
      onCancelTap: () {
        cancelNotifier.value = !cancelNotifier.value;
      },
    );
    if (hasFocus) {
      KeyboardOverlay.showOverlay(context, keyboardTopButtons!);
    } else {
      KeyboardOverlay.removeOverlay();
    }
  }
}
