import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/ui/components/captioned_text_widget.dart';
import 'package:ente_auth/ui/components/menu_item_widget.dart';
import 'package:ente_auth/ui/components/toggle_switch_widget.dart';
import 'package:ente_auth/ui/settings/data/local_backup/local_backup_experience.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LocalBackupSettingsPage extends StatelessWidget {
  const LocalBackupSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LocalBackupExperience(
      builder: (context, controller) {
        final l10n = context.l10n;
        final textTheme = getEnteTextTheme(context);
        final colorScheme = getEnteColorScheme(context);
        return _LocalBackupVariantShell(
          controller: controller,
          title: l10n.localBackupSettingsTitle,
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MenuItemWidget(
                  captionedTextWidget: CaptionedTextWidget(
                    title: l10n.enableAutomaticBackups,
                  ),
                  alignCaptionedTextToLeft: true,
                  singleBorderRadius: 12,
                  menuItemColor: colorScheme.fillFaint,
                  trailingWidget: ToggleSwitchWidget(
                    value: () => controller.isBackupEnabled,
                    onChanged: () async {
                      await controller.toggleBackup(
                        !controller.isBackupEnabled,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
                  child: Text(
                    l10n.localBackupDailyManualCopy,
                    style: textTheme.miniFaint,
                  ),
                ),
                const SizedBox(height: 28),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: controller.isBackupEnabled
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder<bool>(
                              future: controller.hasPasswordConfigured(),
                              builder: (context, snapshot) {
                                final hasPassword = snapshot.data ?? false;
                                final tileTitle = hasPassword
                                    ? l10n.updateBackupPassword
                                    : l10n.setBackupPassword;
                                return MenuItemWidget(
                                  captionedTextWidget: CaptionedTextWidget(
                                    title: tileTitle,
                                  ),
                                  singleBorderRadius: 12,
                                  alignCaptionedTextToLeft: true,
                                  menuItemColor: colorScheme.fillFaint,
                                  trailingIcon: Icons.chevron_right_outlined,
                                  trailingIconIsMuted: true,
                                  onTap: () async {
                                    await controller.updatePassword(context);
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            _BackupLocationCard(
                              controller: controller,
                              colorScheme: colorScheme,
                              textTheme: textTheme,
                            ),
                            const SizedBox(height: 12),
                            MenuItemWidget(
                              captionedTextWidget: CaptionedTextWidget(
                                title: l10n.createBackupNow,
                              ),
                              alignCaptionedTextToLeft: true,
                              singleBorderRadius: 12,
                              menuItemColor: colorScheme.fillFaint,
                              trailingWidget: controller.isManualBackupRunning
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.chevron_right_outlined,
                                      color: Colors.grey,
                                    ),
                              onTap: () async {
                                if (controller.isManualBackupRunning) return;
                                await controller.runManualBackup();
                              },
                            ),
                          ],
                        )
                      : (kDebugMode
                          ? Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Column(
                                children: [
                                  _BackupButton(
                                    onPressed: controller.resetBackupLocation,
                                    label: l10n.clearBackupFolder,
                                    colorScheme: colorScheme,
                                    textTheme: textTheme,
                                  ),
                                  const SizedBox(height: 10),
                                  _BackupButton(
                                    onPressed: controller.clearBackupPassword,
                                    label: l10n.clearBackupPassword,
                                    colorScheme: colorScheme,
                                    textTheme: textTheme,
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LocalBackupVariantShell extends StatelessWidget {
  const _LocalBackupVariantShell({
    required this.controller,
    required this.title,
    required this.body,
  });

  final LocalBackupExperienceController controller;
  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: controller.hasLoaded
                    ? SafeArea(bottom: false, child: body)
                    : const _LocalBackupLoading(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocalBackupLoading extends StatelessWidget {
  const _LocalBackupLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _LocationPreview extends StatelessWidget {
  const _LocationPreview({required this.controller});

  final LocalBackupExperienceController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final path = controller.backupPath;
    final treeUri = controller.backupTreeUri;
    final muted = textTheme.miniFaint.copyWith(color: Colors.grey);

    if (path != null) {
      return Text(controller.simplifyPath(path), style: textTheme.miniFaint);
    }
    if (treeUri != null) {
      return Text(
        controller.simplifyPath(treeUri),
        style: textTheme.miniFaint,
      );
    }

    return Text(context.l10n.selectBackupFolder, style: muted);
  }
}

class _BackupLocationCard extends StatelessWidget {
  const _BackupLocationCard({
    required this.controller,
    required this.colorScheme,
    required this.textTheme,
  });

  final LocalBackupExperienceController controller;
  final dynamic colorScheme;
  final dynamic textTheme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.fillFaint,
      borderRadius: BorderRadius.circular(12),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          await controller.changeLocation();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.setBackupFolder,
                  style: textTheme.body,
                ),
                const SizedBox(height: 6),
                _LocationPreview(controller: controller),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackupButton extends StatelessWidget {
  const _BackupButton({
    required this.onPressed,
    required this.label,
    required this.colorScheme,
    required this.textTheme,
  });

  final Future<void> Function() onPressed;
  final String label;
  final dynamic colorScheme;
  final dynamic textTheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.textBase,
          backgroundColor: colorScheme.fillFaint,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          label,
          style: textTheme.bodyBold,
        ),
      ),
    );
  }
}
