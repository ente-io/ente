import 'package:flutter/material.dart';
import "package:photos/service_locator.dart";
import "package:photos/ui/common/backup_flow_helper.dart";
import 'package:photos/ui/components/buttons/icon_button_widget.dart';

class HomeHeaderWidget extends StatefulWidget {
  final Widget centerWidget;
  const HomeHeaderWidget({required this.centerWidget, super.key});

  @override
  State<HomeHeaderWidget> createState() => _HomeHeaderWidgetState();
}

class _HomeHeaderWidgetState extends State<HomeHeaderWidget> {
  @override
  Widget build(BuildContext context) {
    final showAddAlbumAction =
        !isOfflineMode || permissionService.hasGrantedLimitedPermissions();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButtonWidget(
              iconButtonType: IconButtonType.primary,
              icon: Icons.menu_outlined,
              onTap: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ],
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: widget.centerWidget,
        ),
        showAddAlbumAction
            ? IconButtonWidget(
                icon: Icons.add_photo_alternate_outlined,
                iconButtonType: IconButtonType.primary,
                onTap: () async => handleFullPermissionBackupFlow(context),
              )
            : const SizedBox(width: 48, height: 48),
      ],
    );
  }
}
