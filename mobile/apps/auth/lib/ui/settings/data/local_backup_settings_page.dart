import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/ui/components/captioned_text_widget.dart';
import 'package:ente_auth/ui/components/menu_item_widget.dart';
import 'package:ente_auth/ui/components/toggle_switch_widget.dart';
import 'package:ente_auth/ui/settings/data/local_backup/local_backup_experience.dart';
import 'package:flutter/material.dart';

const _autoBackupToggleCopy =
    'Backs up your 2FA codes locally. The backup updates automatically whenever you add, edit, or delete a code.';

class LocalBackupSettingsPage extends StatelessWidget {
  const LocalBackupSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LocalBackupAppLockVariantPage();
  }
}

class LocalBackupAppLockVariantPage extends StatelessWidget {
  const LocalBackupAppLockVariantPage({super.key});

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
                    _autoBackupToggleCopy,
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
                                    ? 'Update backup password'
                                    : 'Set backup password';
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
                                    await controller.updatePassword();
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            Material(
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
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Backup location',
                                              style: textTheme.body,
                                            ),
                                            const SizedBox(height: 6),
                                            _LocationPreview(
                                              controller: controller,
                                            ),
                                          ],
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          await controller.changeLocation();
                                        },
                                        style: TextButton.styleFrom(
                                          backgroundColor:
                                              colorScheme.fillMuted,
                                          shape: const StadiumBorder(),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 18,
                                            vertical: 12,
                                          ),
                                          minimumSize: const Size(0, 44),
                                        ),
                                        child: Text(
                                          'Change folder',
                                          style: textTheme.smallBold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
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
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: controller.hasLoaded
                ? SafeArea(bottom: false, child: body)
                : const _LocalBackupLoading(),
          ),
          if (controller.isBusy && controller.shouldShowBusyOverlay)
            const _LocalBackupBusyOverlay(),
        ],
      ),
    );
  }
}

class _LocalBackupBusyOverlay extends StatelessWidget {
  const _LocalBackupBusyOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: _scaleAlpha(Colors.black, 0.05),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
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
    final muted = textTheme.miniFaint.copyWith(color: Colors.grey);

    if (path != null) {
      return Text(controller.simplifyPath(path), style: textTheme.miniFaint);
    }

    return FutureBuilder<String>(
      future: controller.resolveDefaultPath(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text(context.l10n.loadDefaultLocation, style: muted);
        }
        if (snapshot.hasError) {
          return Text(
            context.l10n.couldNotDetermineLocation,
            style: muted.copyWith(color: Colors.redAccent),
          );
        }
        return Text(
          controller.simplifyPath(snapshot.data ?? ''),
          style: textTheme.miniFaint,
        );
      },
    );
  }
}

Color _scaleAlpha(Color color, double factor) {
  final normalized = (color.a * factor).clamp(0.0, 1.0);
  return color.withValues(alpha: normalized);
}
