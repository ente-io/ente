import 'dart:ui';

import 'package:ente_auth/theme/colors.dart';
import 'package:ente_auth/theme/effects.dart';
import 'package:ente_auth/ui/components/action_sheet_widget.dart';
import 'package:ente_auth/ui/components/buttons/button_widget.dart';
import 'package:ente_auth/ui/components/components_constants.dart';
import 'package:ente_auth/ui/components/models/button_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

///Returns null if dismissed
Future<ButtonResult?> showGridActionSheet({
  required BuildContext context,
  required List<ButtonWidget> buttons,
  ActionSheetType actionSheetType = ActionSheetType.defaultActionSheet,
  bool enableDrag = true,
  bool isDismissible = true,
  bool isCheckIconGreen = false,
}) {
  return showMaterialModalBottomSheet(
    backgroundColor: Colors.transparent,
    barrierColor: backdropFaintDark,
    useRootNavigator: true,
    context: context,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    builder: (_) {
      return GridActionSheetWidget(
        actionButtons: buttons,
        actionSheetType: actionSheetType,
        isCheckIconGreen: isCheckIconGreen,
      );
    },
  );
}

class GridActionSheetWidget extends StatelessWidget {
  final List<ButtonWidget> actionButtons;
  final ActionSheetType actionSheetType;
  final bool isCheckIconGreen;

  const GridActionSheetWidget({
    required this.actionButtons,
    required this.actionSheetType,
    required this.isCheckIconGreen,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final blur = MediaQuery.of(context).platformBrightness == Brightness.light
        ? blurMuted
        : blurBase;
    final extraWidth = MediaQuery.of(context).size.width - restrictedMaxWidth;
    final double? horizontalPadding = extraWidth > 0 ? extraWidth / 2 : null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding ?? 12,
        0,
        horizontalPadding ?? 12,
        32,
      ),
      child: Container(
        decoration: BoxDecoration(boxShadow: shadowMenuLight),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              color: backdropMutedDark,
              child: AlignedGridView.count(
                padding: const EdgeInsets.all(24),
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                physics: const AlwaysScrollableScrollPhysics(),
                itemBuilder: (_, index) => actionButtons[index % 6],
                itemCount: actionButtons.length,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
