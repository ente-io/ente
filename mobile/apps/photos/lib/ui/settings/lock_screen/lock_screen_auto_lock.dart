import "package:ente_components/ente_components.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/ui/settings/components/settings_page_scaffold.dart";
import "package:photos/utils/lock_screen_settings.dart";

class LockScreenAutoLock extends StatefulWidget {
  const LockScreenAutoLock({super.key});

  @override
  State<LockScreenAutoLock> createState() => _LockScreenAutoLockState();
}

class _LockScreenAutoLockState extends State<LockScreenAutoLock> {
  @override
  Widget build(BuildContext context) {
    return SettingsPageScaffold(
      title: AppLocalizations.of(context).autoLock,
      children: const [AutoLockItems()],
    );
  }
}

class AutoLockItems extends StatefulWidget {
  const AutoLockItems({super.key});

  @override
  State<AutoLockItems> createState() => _AutoLockItemsState();
}

class _AutoLockItemsState extends State<AutoLockItems> {
  final autoLockDurations = LockScreenSettings.autoLockDurations;
  final autoLockTimeInMilliseconds = LockScreenSettings.instance
      .getAutoLockTime();
  late Duration currentAutoLockTime;

  @override
  void initState() {
    super.initState();
    for (Duration autoLockDuration in autoLockDurations) {
      if (autoLockDuration.inMilliseconds == autoLockTimeInMilliseconds) {
        currentAutoLockTime = autoLockDuration;
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MenuGroupComponent(
      items: [
        for (final autoLockDuration in autoLockDurations)
          _menuItemForPicker(autoLockDuration),
      ],
    );
  }

  MenuComponent _menuItemForPicker(Duration autoLockTime) {
    final colors = context.componentColors;
    return MenuComponent(
      key: ValueKey(autoLockTime),
      title: _formatTime(autoLockTime),
      trailing: currentAutoLockTime == autoLockTime
          ? HugeIcon(
              icon: HugeIcons.strokeRoundedTick02,
              color: colors.primary,
              size: IconSizes.medium,
            )
          : null,
      showOnlyLoadingState: true,
      onTap: () async {
        await LockScreenSettings.instance.setAutoLockTime(autoLockTime);
        if (!mounted) {
          return;
        }
        setState(() {
          currentAutoLockTime = autoLockTime;
        });
      },
    );
  }

  String _formatTime(Duration duration) {
    if (duration.inHours != 0) {
      return "${duration.inHours}hr";
    } else if (duration.inMinutes != 0) {
      return "${duration.inMinutes}m";
    } else if (duration.inSeconds != 0) {
      return "${duration.inSeconds}s";
    } else {
      return "Immediately";
    }
  }
}
