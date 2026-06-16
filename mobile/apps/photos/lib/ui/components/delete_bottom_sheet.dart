import "dart:async";

import "package:ente_components/ente_components.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

/// Header used by Photos delete confirmation bottom sheets.
class DeleteBottomSheetHeader extends StatelessWidget {
  const DeleteBottomSheetHeader({
    super.key,
    required this.title,
    required this.closeTooltip,
    this.closeResult,
    this.onClose,
  });

  final String title;
  final String closeTooltip;
  final Object? closeResult;
  final FutureOr<void> Function()? onClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButtonComponent(
              tooltip: closeTooltip,
              variant: IconButtonComponentVariant.circular,
              shouldSurfaceExecutionStates: false,
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedCancel01,
                size: IconSizes.small,
              ),
              onTap: () => _handleClose(context),
            ),
          ],
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: 117,
          height: 78,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Image.asset("assets/warning-red.png"),
          ),
        ),
        const SizedBox(height: Spacing.lg),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyles.h2.copyWith(color: colors.textBase),
        ),
      ],
    );
  }

  Future<void> _handleClose(BuildContext context) async {
    await Future.sync(onClose ?? () {});
    if (!context.mounted) return;
    final route = ModalRoute.of(context);
    if (route == null || route.isCurrent) {
      Navigator.of(context).pop(closeResult);
    }
  }
}
